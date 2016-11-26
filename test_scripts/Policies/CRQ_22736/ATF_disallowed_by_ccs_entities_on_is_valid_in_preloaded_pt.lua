require('user_modules/all_common_modules')

-------------------------------------- Variables --------------------------------------------

------------------------------------ Common functions ---------------------------------------


-------------------------------------- Preconditions ----------------------------------------
common_steps:BackupFile("Precondition_Backup_PreloadedPT", "sdl_preloaded_pt.json")

------------------------------------------- BODY ---------------------------------------------

-- Precondition: valid entityType and entityID parameter existed in PreloadedPT 
-- Verification criteria: 
-- 1. SDL considers PreloadedPT as valid
-- 2. Start successfully
-- 3. Saves valid entityType/entityID in entities table in LPT
local parent_item = {"policy_table", "functional_groupings", "Location-1"}
local valid_entity_type_cases = {
	{description = "LowerBound", value = 0},
	{description = "UpperBound", value = 128}
}
local valid_entity_id_cases = {
	{description = "LowerBound", value = 0},
	{description = "UpperBound", value = 128}
}
for i=1,#valid_entity_type_cases do
	for j=1, #valid_entity_id_cases do
		local testing_value = {
			disallowed_by_ccs_entities_on = {
				{
					entityType = valid_entity_type_cases[i].value,
					entityID = valid_entity_id_cases[j].value
				}
			}
		}
		local test_case_id = "TC_entityType_" .. tostring(i).."_".."_entityTID_" .. tostring(j)
		local test_case_name = test_case_id .. "_disallowed_by_ccs_entities_on.entityType_" .. valid_entity_type_cases[i].description .."_".. valid_entity_id_cases[j].description
		
		common_steps:AddNewTestCasesGroup(test_case_name)
		
		-- Precondition
		common_steps:AddNewTestCasesGroup(test_case_name)	
		
		Test[tostring(test_case_name) .. "_Precondition_StopSDL"] = function(self)
			StopSDL()
		end	
		
		Test[test_case_name .. "_Precondition_RestoreDefaultPreloadedPt"] = function (self)
			common_functions:DeletePolicyTable()
		end
		
		-- Add valid entityType and entityID into PreloadedPT 
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
			data_revert = string.gsub(data, temp_replace_value, match_result)
			file = io.open(json_file, "w")
			file:write(data_revert)
			file:close()	
		end
		
		Test[test_case_name .. "_StartSDL_WithInvalidParamInPreloadedPT"] = function(self)
			StartSDL(config.pathToSDL, config.ExitOnCrash)
		end	
		
		-- Verify valid entityType and entityID are inserted into entities table in LPT
		Test["VerifySDLSavedValidParamInLPT"..test_case_name] = function(self)
			-- Look for policy.sqlite file
			local sql_query = "select entity_type, entity_id from entities, functional_group where entities.group_id = functional_group.id and entities.entity_Type ="..valid_entity_type_cases[i].value.. " ".. "and".. " ".. "entities.entity_id="..valid_entity_id_cases[j].value
			print(sql_query)
			local policy_file1 = config.pathToSDL .. "storage/policy.sqlite"
			local policy_file2 = config.pathToSDL .. "policy.sqlite"
			local policy_file
			if common_steps:FileExisted(policy_file1) then
				policy_file = policy_file1
			elseif common_steps:FileExisted(policy_file2) then
				policy_file = policy_file2
			else
				common_functions:PrintError("policy.sqlite file is not exist")
			end
			if policy_file then
				local ful_sql_query = "sqlite3 " .. policy_file .. " \"" .. sql_query .. "\""
				local handler = io.popen(ful_sql_query, 'r')
				os.execute("sleep 1")
				local result = handler:read( '*l' )
				handler:close()
				if(result ~= nil) then
					return true
				else
					self:FailTestCase("entities value in DB is not saved in local policy table although valid param existed in PreloadedPT file")
					return false
					
				end
			end
		end
	end
end

-------------------------------------- Postconditions ----------------------------------------
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")