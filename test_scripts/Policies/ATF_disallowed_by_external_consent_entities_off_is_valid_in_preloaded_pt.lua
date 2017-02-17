-------------------------------General Settings for Configuration----------------------------
require('user_modules/all_common_modules')

-------------------------------------- Preconditions ----------------------------------------
common_steps:BackupFile("Precondition_Backup_PreloadedPT", "sdl_preloaded_pt.json")

------------------------------------------- BODY ---------------------------------------------
-- Precondition: valid entityType and entityID parameter existed in PreloadedPT
-- Verification criteria:
-- 1. SDL considers PreloadedPT as valid
-- 2. Start successfully
-- 3. Send OnAppPermissionConsent to verify entities saved in LPT
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
      disallowed_by_external_consent_entities_off = {
        {
          entityType = valid_entity_type_cases[i].value,
          entityID = valid_entity_id_cases[j].value
        }
      }
    }
    local test_case_id = "TC_disallowed_by_external_consent_entities_off"
    local test_case_name = test_case_id .. "_EntityType_" .. valid_entity_type_cases[i].description .."_EntityID_"..valid_entity_id_cases[j].description
    
    common_steps:AddNewTestCasesGroup(test_case_name)
    
    Test[tostring(test_case_name) .. "_Precondition_StopSDL"] = function(self)
      StopSDL()
    end
    
    Test[test_case_name .. "_Precondition_RemoveExistedLPT"] = function (self)
      common_functions:DeletePolicyTable()
    end
    
    common_steps:RestoreIniFile("PostCondition_Restore_PreloadedPT", "sdl_preloaded_pt.json")
    
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
      data.policy_table.app_policies["0000001"] = {
        keep_context = false,
        steal_focus = false,
        priority = "NONE",
        default_hmi = "NONE",
        groups = {"Base-4","Location-1"}
      }
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
    
    common_steps:IgnitionOn("IgnitionOn_"..test_case_name)
    common_steps:AddMobileSession("AddMobileSession_"..test_case_name)
    common_steps:RegisterApplication("RegisterApp_"..test_case_name)
    common_steps:ActivateApplication("ActivateApp_"..test_case_name, config.application1.registerAppInterfaceParams.appName)
    
    -- Verify valid entityType and entityID are inserted into entities table in LPT
    Test[test_case_name .. "_HMI_sends_OnAppPermissionConsent_externalConsentStatus"] = function(self)
      -- hmi side: sending SDL.OnAppPermissionConsent for applications
      self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
        source = "GUI",
        externalConsentStatus = {{entityType = valid_entity_type_cases[i].value, entityID = valid_entity_id_cases[j].value, status = "ON"}}
      })
      self.mobileSession:ExpectNotification("OnPermissionsChange")
    end
  end
end

-------------------------------------- Postconditions ----------------------------------------
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")
