require('user_modules/all_common_modules')

-------------------------------------- Variables --------------------------------------------
-- n/a

------------------------------------ Common functions ---------------------------------------
-- n/a

-------------------------------------- Preconditions ----------------------------------------
common_steps:BackupFile("Precondition_Backup_PreloadedPT", "sdl_preloaded_pt.json")

------------------------------------------- BODY ---------------------------------------------
-- Precondition: disallowed_ccs_entities_on existed in PreloadedPT
-- Verification criteria: 
-- 1. SDL considers PreloadedPT as valid
-- 2. Start successfully
-- 3. Triggered to create a SnapshotPolicyTable contains disallowed_ccs_entities_on

local test_case_id = "TC_1"
local test_case_name = test_case_id .. ": disallowed_by_ccs_entities_on is existed in Preloaded_PT.json"
common_steps:AddNewTestCasesGroup(test_case_name)

local testing_value = {
		disallowed_by_ccs_entities_on = {{
			entityType = 100,
			entityID = 20
	}}
}

Test["Precondition_RemoveExistedLPT_"..test_case_name ] = function (self)
	common_functions:DeletePolicyTable()
end 

Test["AddNewItemIntoPreloadedPT_"..test_case_name] = function (self) 
	local json_file = config.pathToSDL .. "sdl_preloaded_pt.json"
	local parent_item = {"policy_table", "functional_groupings", "Location-1"}
	local testing_value = {
		{
			disallowed_by_ccs_entities_on = {
				{
					entityType = 128,
					entityID = 70
				}
			}
		}
	}
	local match_result = "null"
	local temp_replace_value = "\"Thi123456789\""
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

common_steps:IgnitionOn("StartSDL")
common_steps:AddMobileSession("AddMobileSession")
common_steps:RegisterApplication("RegisterApp")
common_steps:ActivateApplication("ActivateApp", config.application1.registerAppInterfaceParams.appName)

function Test:Precondition_TriggerSDLSnapshotCreation_UpdateSDL()
	local RequestIdUpdateSDL = self.hmiConnection:SendRequest("SDL.UpdateSDL")
	--hmi side: expect SDL.UpdateSDL response from HMI
	EXPECT_HMIRESPONSE(RequestIdUpdateSDL,{result = {code = 0, method = "SDL.UpdateSDL", result = "UPDATE_NEEDED" }})
end

function Test:VerifyDisallowedByCcsEntitiesOnInSnapShot()
	local ivsu_cache_folder = common_functions:GetValueFromIniFile("SystemFilesPath")
  local file_name = ivsu_cache_folder.."/".."sdl_snapshot.json"
	local new_param = "disallowed_by_ccs_entities_on"
	local file_json = io.open(file_name, "r")
	local json_snap_shot = file_json:read("*all")
	if type(new_param) == "table" then
		new_param = json.encode(new_param)
	end
	-- Add new items as child items of parent item.
	item = json_snap_shot:match(new_param)
	
	if item == nil then
    self:FailTestCase("disallowed_by_ccs_entities_on is not found in SnapShot although is existed in PreloadedPT file")
		return false
	else
		print ( " \27[31m disallowed_by_ccs_entities_on is found in SnapShot \27[0m " )
		return true
	end
	file_json:close()
end

-------------------------------------- Postconditions ----------------------------------------
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")
