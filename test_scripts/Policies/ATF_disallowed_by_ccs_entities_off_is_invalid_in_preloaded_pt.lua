require('user_modules/all_common_modules')
--------------------------------- Variables -----------------------------------
local parent_item = {"policy_table", "functional_groupings", "Location-1"}
local sql_query = "select * from entities, functional_group where entities.group_id = functional_group.id"
local error_message = "SDL saved disallowed_by_ccs_entities_off although existed invalid parameters in PreloadedPT."
------------------------------- Common functions -------------------------------
local match_result = "null"
local temp_replace_value = "\"Thi123456789\""
-- Add new structure into json_file
local function AddItemsIntoJsonFile(json_file, parent_item, added_json_items)
	local file = io.open(json_file, "r")
	local json_data = file:read("*all")
	file:close()
	json_data_update = string.gsub(json_data, match_result, temp_replace_value)
	local json = require("modules/json")
	local data = json.decode(json_data_update)
	-- Go to parent item
	local parent = data
	for i = 1, #parent_item do
		if not parent[parent_item[i]] then
			parent[parent_item[i]] = {}
		end
		parent = parent[parent_item[i]]
	end
	if type(added_json_items) == "string" then
		added_json_items = json.decode(added_json_items)
	end
	
	for k, v in pairs(added_json_items) do
		parent[k] = v
	end
	
	data = json.encode(data)	
	data_revert = string.gsub(data, temp_replace_value, match_result)
	file = io.open(json_file, "w")
	file:write(data_revert)
	file:close()	
end

-- Verify new parameter is not saved in LPT
local function CheckPolicyTable(test_case_name, sql_query, error_message)
	Test[test_case_name] = function (self)
		-- Look for policy.sqlite file
		local policy_file1 = config.pathToSDL .. "storage/policy.sqlite"
		local policy_file2 = config.pathToSDL .. "policy.sqlite"
		local policy_file
		if common_functions:IsFileExist(policy_file1) then
			policy_file = policy_file1
		elseif common_functions:IsFileExist(policy_file2) then
			policy_file = policy_file2
		else
			common_functions:PrintError(" \27[32m policy.sqlite file is not exist \27[0m ")
		end
		if policy_file then
			local ful_sql_query = "sqlite3 " .. policy_file .. " \"" .. sql_query .. "\""
			local handler = io.popen(ful_sql_query, 'r')
			os.execute("sleep 1")
			local result = handler:read( '*l' )
			handler:close()
			if(result == nil or result == "") then
				common_functions:PrintError(" \27[32m entities value in DB is not saved in local policy table \27[0m ")
				return true
			else
				self:FailTestCase("entities value in DB is also saved in local policy table although invalid param existed in PreloadedPT file")
				return false
			end
		end
	end
end

-- Verify SDL can't start with invalid parameter in PreloadedPT
local function VerifySDLShutDownWithInvalidParamInPreloadedPT(test_case_name)
	Test["SDLShutDownWith"..test_case_name] = function (self)
		os.execute(" sleep 1 ")
		-- Remove sdl.pid file on ATF folder in case SDL is stopped not by script.
		os.execute("rm sdl.pid") 
		local status = sdl:CheckStatusSDL()
		if (status == 1) then
			self:FailTestCase(" smartDeviceLinkCore process is not stopped ")
			return false
		end
		common_functions:PrintError(" \27[32m SDL has already stoped.")
		return true
	end
end

------------------------------- Preconditions ---------------------------------
common_steps:BackupFile("Precondition_Backup_PreloadedPT", "sdl_preloaded_pt.json")

--------------------------------- BODY ----------------------------------------
-- Precondition: invalid entityType parameter existed in PreloadedPT 
-- Verification criteria: SDL considers PreloadedPT as invalid and shut SDL down
local invalid_entity_type_cases = {
	{description = "WrongType_String", value = "1"},
	{description = "OutUpperBound", value = 129},
	{description = "OutLowerBound", value = -1},
	{description = "WrongType_Float", value = 10.5},
	{description = "WrongType_EmptyTable", value = {}},
	{description = "WrongType_Table", value = {entityType = 1, entityID = 1}},
	{description = "Missed", value = nil}
}

for i=1,#invalid_entity_type_cases do
	local test_case_id = "TC_entityType_" .. tostring(i)
	local test_case_name = test_case_id .. "_disallowed_by_ccs_entities_off.entityType_" .. invalid_entity_type_cases[i].description
	
	common_steps:AddNewTestCasesGroup(test_case_name)	
	
	Test[test_case_name .. "_Precondition_StopSDL"] = function(self)
		StopSDL()
	end	
	
	Test[test_case_name .. "_RemoveExistedLPT"] = function (self)
		common_functions:DeletePolicyTable()
	end 	
	
	local testing_value = {
		disallowed_by_ccs_entities_off= {
			{
				entityType = invalid_entity_type_cases[i].value,
				entityID = 50
			}
		}
	} 
	AddItemsIntoJsonFile(config.pathToSDL .. 'sdl_preloaded_pt.json', parent_item, testing_value)
	
	Test[test_case_name .. "_StartSDL_WithInvalidParamInPreloadedPT"] = function(self)
		sdl.exitOnCrash = false
		StartSDL(config.pathToSDL, false)
	end	
	
	VerifySDLShutDownWithInvalidParamInPreloadedPT("_disallowed_by_ccs_entities_off.entityType_".. invalid_entity_type_cases[i].description)
	CheckPolicyTable("CheckPolicyTable_"..test_case_name, sql_query, error_message)
	-------------------------------------- Postconditions ----------------------------------------
	common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")
end

-- Precondition: invalid entityID parameter existed in PreloadedPT 
-- Verification criteria: SDL considers PreloadedPT as invalid and shut SDL down
local invalid_entity_id_cases = {
	{description = "WrongType_String", value = "1"},
	{description = "OutUpperBound", value = 129},
	{description = "OutLowerBound", value = -1},
	{description = "WrongType_Float", value = 10.5},
	{description = "WrongType_EmptyTable", value = {}},
	{description = "WrongType_Table", value = {entityID = 1, entityType = 1}}, 
	{description = "Missed", value = nil}
}

for i=1,#invalid_entity_id_cases do
	
	local test_case_id = "TC_entityID_" .. tostring(i) 
	local test_case_name = test_case_id .. "_disallowed_by_ccs_entities_off.entityId_" .. invalid_entity_id_cases[i].description
	
	common_steps:AddNewTestCasesGroup(test_case_name)
	
	Test[tostring(test_case_name) .. "_Precondition_StopSDL"] = function(self)
		StopSDL()
	end
	
	Test[test_case_name .. "_Precondition_RemoveExistedLPT"] = function (self)
		common_functions:DeletePolicyTable()
	end 
	
	local testing_value = {
		disallowed_by_ccs_entities_off= {
			{
				entityType = 100, 
				entityID = invalid_entity_id_cases[i].value
			}
		}
	}
	AddItemsIntoJsonFile(config.pathToSDL .. 'sdl_preloaded_pt.json', parent_item, testing_value)
	
	Test[test_case_name .. "_StartSDL_WithInvalidParamInPreloadedPT"] = function(self)
		StartSDL(config.pathToSDL, config.ExitOnCrash)
	end
	
	VerifySDLShutDownWithInvalidParamInPreloadedPT("_disallowed_by_ccs_entities_off.entityId_" .. invalid_entity_id_cases[i].description)
	CheckPolicyTable("CheckPolicyTable_"..test_case_name, sql_query, error_message)
  
	-------------------------------------- Postconditions ----------------------------------------
	common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")
end
