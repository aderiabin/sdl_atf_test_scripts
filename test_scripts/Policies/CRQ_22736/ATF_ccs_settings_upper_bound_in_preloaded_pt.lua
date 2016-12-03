require('user_modules/all_common_modules')

-------------------------------------- Variables --------------------------------------------
-- n/a

------------------------------------ Common functions ---------------------------------------
local function AddNewItemIntoPreloadedPt(test_case_name, parent_item, testing_value)
	Test[test_case_name .. "_AddNewItemIntoPreloadedPt"] = function (self)
		local match_result = "null"
		local temp_replace_value = "\"Thi123456789\""
		local json_file = config.pathToSDL .. 'sdl_preloaded_pt.json'
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
		if type(testing_value) == "string" then
			testing_value = json.decode(testing_value)
		end
		
		for k, v in pairs(testing_value) do
			parent[k] = v
		end
		
		data = json.encode(data)	
		local data_revert = string.gsub(data, temp_replace_value, match_result)
		file = io.open(json_file, "w")
		file:write(data_revert)
		file:close()	
	end
end
local function VerifySDLSavedUpperBoundEntitiesInLPT(test_case_name)
	Test[test_case_name.."_VerifySDLSavedUpperBoundEntitiesInLPT"] = function(self)
		-- Look for policy.sqlite file
		local sql_query = "select entity_type, entity_id from entities, functional_group where entities.group_id = functional_group.id"
		local policy_file1 = config.pathToSDL .. "storage/policy.sqlite"
		local policy_file2 = config.pathToSDL .. "policy.sqlite"
		local policy_file
		if common_steps:FileExisted(policy_file1) then
			policy_file = policy_file1
		elseif common_steps:FileExisted(policy_file2) then
			policy_file = policy_file2
		else
			common_functions:PrintError(" \27[32m policy.sqlite file is not exist \27[0m ")
		end
		if policy_file then
			local ful_sql_query = "sqlite3 " .. policy_file .. " \"" .. sql_query .. "\""
			local handler = io.popen(ful_sql_query, 'r')
			os.execute("sleep 1")
			local result = handler:read( '*a' )
			handler:close()
			if(result ~= nil) then
				common_functions:PrintError(" \27[32m Entities have ready save in LPT \27[0m ")
				return true
			else
				self:FailTestCase("entities value is not saved in LPT although valid param existed in PreloadedPT file")
				return false
			end
		end
	end
end
-------------------------------------- Preconditions ----------------------------------------
common_steps:BackupFile("Precondition_Backup_PreloadedPT", "sdl_preloaded_pt.json")

------------------------------------------- TC_1 ---------------------------------------------
-- Precondition: disallowed_by_ccs_entities_on/ disallowed_by_ccs_entities_off contains 100 entityType and entityID parameter existed in PreloadedPT 
-- Verification criteria: 
-- 1. SDL considers PreloadedPT as valid
-- 2. Start successfully
-- 3. Saves valid entityType/entityID in entities table in LPT
local parent_item_entities = {"policy_table", "functional_groupings", "Location-1"}
local testing_value_entities_upper_bound = {}
testing_value_entities_upper_bound.disallowed_by_ccs_entities_off = {}
testing_value_entities_upper_bound.disallowed_by_ccs_entities_on = {}
for i = 1, 100 do
	table.insert(testing_value_entities_upper_bound.disallowed_by_ccs_entities_off, 
	{
		entityType = i,
		entityID = i
	}
	)
	table.insert(testing_value_entities_upper_bound.disallowed_by_ccs_entities_on, 
	{
		entityType = i,
		entityID = i
	}
	)
end

local test_case_name = "TC1_SDLStarts_With_UpperBoundForEnitiesOff"

common_steps:AddNewTestCasesGroup(test_case_name)

Test[tostring(test_case_name) .. "_Precondition_StopSDL"] = function(self)
	StopSDL()
end	

Test[test_case_name .. "_Precondition_RemoveExistedLPT"] = function (self)
	common_functions:DeletePolicyTable()
end

-- Add disallowed_by_ccs_entities_off with 100 entities 
AddNewItemIntoPreloadedPt (test_case_name, parent_item_entities, testing_value_entities_upper_bound)

Test[test_case_name .. "_StartSDL_WithValidEntityOnInPreloadedPT"] = function(self)
	StartSDL(config.pathToSDL, config.ExitOnCrash)
end	

VerifySDLSavedUpperBoundEntitiesInLPT(test_case_name)

------------------------------------------- TC_2 ---------------------------------------------
-- Precondition: disallowed_by_ccs_entities_on contains 100 entityType and entityID parameter existed in PreloadedPT 
-- Verification criteria: 
-- 1. SDL considers PreloadedPT as valid
-- 2. Start successfully
-- 3. Saves valid entityType/entityID in entities table in LPT
local parent_item_entities_on = {"policy_table", "functional_groupings", "Location-1"}
local testing_value_entities_on = {}
testing_value_entities_on.disallowed_by_ccs_entities_on = {}
for i = 1, 100 do
	table.insert(testing_value_entities_on.disallowed_by_ccs_entities_on, 
	{
		entityType = i,
		entityID = i
	}
	)
end

local test_case_name = "TC2_SDLStarts_With_UpperBoundForEnitiesOn"

common_steps:AddNewTestCasesGroup(test_case_name)

Test[tostring(test_case_name) .. "_Precondition_StopSDL"] = function(self)
	StopSDL()
end	

Test[test_case_name .. "_Precondition_RemoveExistedLPT"] = function (self)
	common_functions:DeletePolicyTable()
end

common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")

-- Add disallowed_by_ccs_entities_on with 100 entities 
AddNewItemIntoPreloadedPt (test_case_name, parent_item_entities_on, testing_value_entities_on)

Test[test_case_name .. "_StartSDL_WithValidEntityOnInPreloadedPT"] = function(self)
	StartSDL(config.pathToSDL, config.ExitOnCrash)
end	

VerifySDLSavedUpperBoundEntitiesInLPT(test_case_name)

------------------------------------------- TC_3 ---------------------------------------------
-- Precondition: disallowed_by_ccs_entities_on and disallowed_by_ccs_entities_off are existed in the same group in PreloadedPT 
-- Verification criteria: 
-- 1. SDL considers PreloadedPT as valid
-- 2. Start successfully
-- 3. Saves valid entityType/entityID in entities table in LPT
local parent_item = {"policy_table", "functional_groupings", "Location-1"}
local testing_value = {
	disallowed_by_ccs_entities_on = {
		{
			entityType = 128,
			entityID = 128
		}
	},
	disallowed_by_ccs_entities_off = {
		{
			entityType = 0,
			entityID = 0
		}
	}
}

local test_case_name = "TC3_SDLStarts_With_EnitiesOn_Off_In_The_Same_Group"

common_steps:AddNewTestCasesGroup(test_case_name)

Test[tostring(test_case_name) .. "_Precondition_StopSDL"] = function(self)
	StopSDL()
end	

Test[test_case_name .. "_Precondition_RemoveExistedLPT"] = function (self)
	common_functions:DeletePolicyTable()
end

common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")

-- Add disallowed_by_ccs_entities_on and disallowed_by_ccs_entities_off into the same group 
AddNewItemIntoPreloadedPt (test_case_name, parent_item, testing_value)

Test[test_case_name .. "_StartSDL_WithValidEntityOnInPreloadedPT"] = function(self)
	StartSDL(config.pathToSDL, config.ExitOnCrash)
end	

VerifySDLSavedUpperBoundEntitiesInLPT(test_case_name)
-------------------------------------- Postconditions ----------------------------------------
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")