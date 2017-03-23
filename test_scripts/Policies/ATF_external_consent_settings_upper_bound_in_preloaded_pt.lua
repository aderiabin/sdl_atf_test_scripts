------------------------------------General Settings for Configuration-----------------------
require('user_modules/all_common_modules')

------------------------------------ Common functions ---------------------------------------
local function AddNewItemIntoPreloadedPt(test_case_name, parent_item, testing_value)
  Test[test_case_name .. "_AddNewItemIntoPreloadedPt"] = function(self)
    local match_result = "null"
    local temp_replace_value = "\"Thi123456789\""
    local json_file = config.pathToSDL .. 'sdl_preloaded_pt.json'
    local file = assert(io.open(json_file, "r"))
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
    file = assert(io.open(json_file, "w"))
    file:write(data_revert)
    file:close()
  end
end
-------------------------------------- Preconditions ----------------------------------------
common_steps:BackupFile("Precondition_Backup_PreloadedPT", "sdl_preloaded_pt.json")

------------------------------------------- TC_1 ---------------------------------------------
-- Precondition: disallowed_by_external_consent_entities_on/ disallowed_by_external_consent_entities_off contains 100 entityType and entityID parameter existed in PreloadedPT
-- Verification criteria:
-- 1. SDL considers PreloadedPT as valid
-- 2. Start successfully
-- 3. Saves valid entityType/entityID in entities table in LPT
local parent_item_entities = {"policy_table", "functional_groupings", "Location-1"}
local testing_value_entities_upper_bound = {}
testing_value_entities_upper_bound.disallowed_by_external_consent_entities_off = {}
testing_value_entities_upper_bound.disallowed_by_external_consent_entities_on = {}
for i = 1, 100 do
  table.insert(testing_value_entities_upper_bound.disallowed_by_external_consent_entities_off,
  {
    entityType = i,
    entityID = i
  }
  )
  table.insert(testing_value_entities_upper_bound.disallowed_by_external_consent_entities_on,
  {
    entityType = i,
    entityID = i
  }
  )
end

local test_case_name = "TC1_SDLStarts_With_UpperBoundForEnitiesOnOff"

common_steps:AddNewTestCasesGroup(test_case_name)

Test[test_case_name .. "_Precondition_StopSDL"] = function(self)
  StopSDL()
end

Test[test_case_name .. "_Precondition_RemoveExistedLPT"] = function(self)
  common_functions:DeletePolicyTable()
end

-- Add disallowed_by_external_consent_entities_off with 100 entities
AddNewItemIntoPreloadedPt (test_case_name, parent_item_entities, testing_value_entities_upper_bound)

common_steps:IgnitionOn("IgnitionOn_"..test_case_name)
common_steps:AddMobileSession("AddMobileSession_"..test_case_name)
common_steps:RegisterApplication("RegisterApp_"..test_case_name)
common_steps:ActivateApplication("ActivateApp_"..test_case_name, config.application1.registerAppInterfaceParams.appName)

-- Send OnAppPermissionConsent to verify entityType and entityId merged in LPT
Test[test_case_name .. "_HMI_sends_OnAppPermissionConsent_externalConsentStatus"] = function(self)
  -- hmi side: sending SDL.OnAppPermissionConsent for applications
  self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
    source = "GUI",
    externalConsentStatus = {{entityType = 100, entityID = 100, status = "ON"}, {entityType = 1, entityID = 1, status = "ON"}, {entityType = 100, entityID = 100, status = "OFF"}, {entityType = 1, entityID = 1, status = "OFF"}}
  })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
end
------------------------------------------- TC_2 ---------------------------------------------
-- Precondition: disallowed_by_external_consent_entities_on contains 100 entityType and entityID parameter existed in PreloadedPT
-- Verification criteria:
-- 1. SDL considers PreloadedPT as valid
-- 2. Start successfully
-- 3. Saves valid entityType/entityID in entities table in LPT
local parent_item_entities_on = {"policy_table", "functional_groupings", "Location-1"}
local testing_value_entities_on = {}
testing_value_entities_on.disallowed_by_external_consent_entities_on = {}
for i = 1, 100 do
  table.insert(testing_value_entities_on.disallowed_by_external_consent_entities_on,
  {
    entityType = i,
    entityID = i
  }
  )
end

local test_case_name = "TC2_SDLStarts_With_UpperBoundForEnitiesOn"

common_steps:AddNewTestCasesGroup(test_case_name)

Test[test_case_name .. "_Precondition_StopSDL"] = function(self)
  StopSDL()
end

Test[test_case_name .. "_Precondition_RemoveExistedLPT"] = function(self)
  common_functions:DeletePolicyTable()
end

common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")

-- Add disallowed_by_external_consent_entities_on with 100 entities
AddNewItemIntoPreloadedPt (test_case_name, parent_item_entities_on, testing_value_entities_on)

common_steps:IgnitionOn("IgnitionOn_"..test_case_name)
common_steps:AddMobileSession("AddMobileSession_"..test_case_name)
common_steps:RegisterApplication("RegisterApp_"..test_case_name)
common_steps:ActivateApplication("ActivateApp_"..test_case_name, config.application1.registerAppInterfaceParams.appName)

-- Send OnAppPermissionConsent to verify entityType and entityId merged in LPT
Test[test_case_name .. "_HMI_sends_OnAppPermissionConsent_externalConsentStatus"] = function(self)
  -- hmi side: sending SDL.OnAppPermissionConsent for applications
  self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
    source = "GUI",
    externalConsentStatus = {{entityType = 100, entityID = 100, status = "OFF"}, {entityType = 1, entityID = 1, status = "OFF"}}
  })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
end

------------------------------------------- TC_3 ---------------------------------------------
-- Precondition: disallowed_by_external_consent_entities_on and disallowed_by_external_consent_entities_off are existed in the same group in PreloadedPT
-- Verification criteria:
-- 1. SDL considers PreloadedPT as valid
-- 2. Start successfully
-- 3. Saves valid entityType/entityID in entities table in LPT
local parent_item = {"policy_table", "functional_groupings", "Location-1"}
local testing_value = {
  disallowed_by_external_consent_entities_on = {
    {
      entityType = 128,
      entityID = 128
    }
  },
  disallowed_by_external_consent_entities_off = {
    {
      entityType = 0,
      entityID = 0
    }
  }
}

local test_case_name = "TC3_SDLStarts_With_EnitiesOn_Off_In_The_Same_Group"

common_steps:AddNewTestCasesGroup(test_case_name)

Test[test_case_name .. "_Precondition_StopSDL"] = function(self)
  StopSDL()
end

Test[test_case_name .. "_Precondition_RemoveExistedLPT"] = function(self)
  common_functions:DeletePolicyTable()
end

common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")

-- Add disallowed_by_external_consent_entities_on and disallowed_by_external_consent_entities_off into the same group
AddNewItemIntoPreloadedPt (test_case_name, parent_item, testing_value)

common_steps:IgnitionOn("IgnitionOn_"..test_case_name)
common_steps:AddMobileSession("AddMobileSession_"..test_case_name)
common_steps:RegisterApplication("RegisterApp_"..test_case_name)
common_steps:ActivateApplication("ActivateApp_"..test_case_name, config.application1.registerAppInterfaceParams.appName)

-- Send OnAppPermissionConsent to verify entityType and entityId merged in LPT
Test[test_case_name .. "_HMI_sends_OnAppPermissionConsent_externalConsentStatus"] = function(self)
  -- hmi side: sending SDL.OnAppPermissionConsent for applications
  self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
    source = "GUI",
    externalConsentStatus = {{entityType = 128, entityID = 128, status = "OFF"}, {entityType = 0, entityID = 0, status = "ON"}}
  })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
end
-------------------------------------- Postconditions ----------------------------------------
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")
