------------------------------------General Settings for Configuration-----------------------
require('user_modules/all_common_modules')

------------------------------------ Common functions ---------------------------------------
local function AddNewParamIntoJSonFile(json_file, parent_item, testing_value, test_case_name)
  Test["AddNewParamIntoJSonFile_"..test_case_name] = function(self)
    local match_result = "null"
    local temp_replace_value = "\"Thi123456789\""
    local file = assert(io.open(json_file, "r"))
    local json_data = file:read("*all")
    file:close()
    json_data_update = string.gsub(json_data, match_result, temp_replace_value)
    local json = require("modules/json")
    local data = json.decode(json_data_update)
    if (json_file == config.pathToSDL .. "update_sdl_preloaded_pt.json") then
      data.policy_table.app_policies["0000001"] = {
        keep_context = false,
        steal_focus = false,
        priority = "NONE",
        default_hmi = "NONE",
        groups = {"Base-4","DrivingCharacteristics-3"}
      }
    end
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
    file = assert(io.open(json_file, "w"))
    file:write(data_revert)
    file:close()
  end
end

local function UpdatePolicy(test_case_name, PTName, appName)
  Test[test_case_name .. "_PTUSuccessWithoutEntitiesOn"] = function(self)
    local appID = common_functions:GetHmiAppId(appName, self)
    --hmi side: sending SDL.GetURLS request
    local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
    --hmi side: expect SDL.GetURLS response from HMI
    EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {{url = "https://policies.telematics.ford.com/api/policies"}}}})
    :Do(function(_,data)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
      {
        requestType = "PROPRIETARY",
        fileName = "filename"
      }
      )
      --mobile side: expect OnSystemRequest notification
      EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function(_,data)
        --mobile side: sending SystemRequest request
        local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
        {
          fileName = "PolicyTableUpdate",
          requestType = "PROPRIETARY",
          appID = appID
        },
        PTName)
        
        local systemRequestId
        --hmi side: expect SystemRequest request
        EXPECT_HMICALL("BasicCommunication.SystemRequest")
        :Do(function(_,data)
          systemRequestId = data.id
          
          --hmi side: sending BasicCommunication.OnSystemRequest request to SDL
          self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
          {
            policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
          }
          )
          function to_run()
            --hmi side: sending SystemRequest response
            self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
          end
          
          RUN_AFTER(to_run, 500)
        end)
        
        --hmi side: expect SDL.OnStatusUpdate
        EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
        :ValidIf(function(exp,data)
          if
          exp.occurences == 1 and
          data.params.status == "UP_TO_DATE" then
            return true
          elseif
          exp.occurences == 1 and
          data.params.status == "UPDATING" then
            return true
          elseif
          exp.occurences == 2 and
          data.params.status == "UP_TO_DATE" then
            return true
          else
            if
            exp.occurences == 1 then
              print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in first occurrences status 'UP_TO_DATE' or 'UPDATING', got '" .. tostring(data.params.status) .. "' \27[0m")
            elseif exp.occurences == 2 then
              print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in second occurrences status 'UP_TO_DATE', got '" .. tostring(data.params.status) .. "' \27[0m")
            end
            return false
          end
        end)
        :Times(Between(1,2))
        
        --mobile side: expect SystemRequest response
        EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
        :Do(function(_,data)
          --hmi side: sending SDL.GetUserFriendlyMessage request to SDL
          local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})
          
          --hmi side: expect SDL.GetUserFriendlyMessage response
          EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
        end)
      end)
    end)
    common_functions:DelayedExp(5000)
  end
end

-------------------------------------- Preconditions ----------------------------------------
common_steps:BackupFile("Precondition_Backup_PreloadedPT", "sdl_preloaded_pt.json")

------------------------------------------- TC_1 ---------------------------------------------
-- Precondition:
--1. SDL start without ExternalConsent in PreloadedPT
--2. Existed disallowed_by_external_consent_entities_on/ disallowed_by_external_consent_entities_off with 100 entityType and entityID parameter existed in PTU
-- Verification criteria:
-- 1. SDL considers PTU as valid
-- 2. PTU success
-- 3. Saves valid entityType/entityID in entities table in LPT
local parent_item_entities = {"policy_table", "functional_groupings", "DrivingCharacteristics-3"}
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
local test_case_name = "TC1_Existed_100_Entities_In_External_Consent_On_Off"
common_steps:AddNewTestCasesGroup(test_case_name)
common_steps:StopSDL("StopSDL")
Test[test_case_name .. "_Remove_Existed_LPT"] = function(self)
  common_functions:DeletePolicyTable()
end

common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")

Test[test_case_name .. "_Precondition_Created_PTU"] = function(self)
  os.execute(" cp " .. config.pathToSDL .. "sdl_preloaded_pt.json".. " " .. config.pathToSDL .. "update_sdl_preloaded_pt.json")
  -- remove preload_pt from json file
  local parent_item = {"policy_table","module_config"}
  local removed_json_items = {"preloaded_pt"}
  common_functions:RemoveItemsFromJsonFile(config.pathToSDL .. "update_sdl_preloaded_pt.json", parent_item, removed_json_items) 
end

AddNewParamIntoJSonFile(config.pathToSDL .. "update_sdl_preloaded_pt.json", parent_item_entities, testing_value_entities_upper_bound, "InPTU")
common_steps:IgnitionOn(test_case_name)
common_steps:AddMobileSession("AddMobileSession_"..test_case_name)
common_steps:RegisterApplication("RegisterApp_"..test_case_name)
common_steps:ActivateApplication("ActivateApp_"..test_case_name, config.application1.registerAppInterfaceParams.appName)
UpdatePolicy(test_case_name, config.pathToSDL .. "update_sdl_preloaded_pt.json", config.application1.registerAppInterfaceParams.appName)
-- Send OnAppPermissionConsent to verify entityType and entityId merged in LPT
Test[test_case_name .. "_HMI_sends_OnAppPermissionConsent_externalConsentStatus"] = function(self)
  -- hmi side: sending SDL.OnAppPermissionConsent for applications
  self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
    source = "GUI",
    externalConsentStatus = {{entityType = 100, entityID = 100, status = "OFF"}, {entityType = 1, entityID = 1, status = "OFF"}, {entityType = 100, entityID = 100, status = "ON"}, {entityType = 1, entityID = 1, status = "ON"}}
  })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
end
------------------------------------------- TC_2 ---------------------------------------------
-- Precondition:
-- 1. SDL start without External Consent in PreloadedPT
-- 2. Existed disallowed_by_external_consent_entities_on/ disallowed_by_external_consent_entities_off in the same group in PTU
-- Verification criteria:
-- 1. SDL considers PTU as valid
-- 2. PTU success
-- 3. Saves valid entityType/entityID in entities table in LPT
local parent_item = {"policy_table", "functional_groupings", "DrivingCharacteristics-3"}
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
local test_case_name = "TC2_Existed_External_Consent_On_Off_In_The_Same_Group"

common_steps:AddNewTestCasesGroup(test_case_name)
common_steps:StopSDL("StopSDL")
Test[test_case_name .. "_Remove_Existed_LPT"] = function(self)
  common_functions:DeletePolicyTable()
end

common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")

Test[test_case_name .. "_Precondition_Created_PTU"] = function (self)
  os.execute(" cp " .. config.pathToSDL .. "sdl_preloaded_pt.json".. " " .. config.pathToSDL .. "update_sdl_preloaded_pt.json")
  -- remove preload_pt from json file
  local parent_item = {"policy_table","module_config"}
  local removed_json_items = {"preloaded_pt"}
  common_functions:RemoveItemsFromJsonFile(config.pathToSDL .. "update_sdl_preloaded_pt.json", parent_item, removed_json_items) 
end
AddNewParamIntoJSonFile(config.pathToSDL .. "update_sdl_preloaded_pt.json", parent_item, testing_value, "InPTU")
common_steps:IgnitionOn(test_case_name)
common_steps:AddMobileSession("AddMobileSession_"..test_case_name)
common_steps:RegisterApplication("RegisterApp_"..test_case_name)
common_steps:ActivateApplication("ActivateApp_"..test_case_name, config.application1.registerAppInterfaceParams.appName)
UpdatePolicy(test_case_name, config.pathToSDL .. "update_sdl_preloaded_pt.json", config.application1.registerAppInterfaceParams.appName)
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
