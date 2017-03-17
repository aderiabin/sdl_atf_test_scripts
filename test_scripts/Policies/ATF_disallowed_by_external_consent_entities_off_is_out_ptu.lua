--------------------------------General Settings for Configuration---------------------------
require('user_modules/all_common_modules')

----------------------------------- Common Variables ---------------------------------------
local storagePath = config.pathToSDL .. "storage/"..config.application1.registerAppInterfaceParams.appID.. "_" .. config.deviceMAC.. "/"

------------------------------------ Common functions ---------------------------------------
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
          exp.occurences == 1 or exp.occurences == 2 and
          data.params.status == "UP_TO_DATE" then
            return true
          elseif
          exp.occurences == 1 and
          data.params.status == "UPDATING" then
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

------------------------------------------- BODY ---------------------------------------------
------------------------------------------- TC_01 ---------------------------------------------
-- Precondition:
-- 1.SDL starts without disallowed_by_external_consent_entities_off in PreloadedPT
-- 2.disallowed_by_external_consent_entities_off is omitted in PTU
-- Verification criteria:
-- 1. SDL considers this PTU as valid
-- 2. Does not saved disallowed_by_external_consent_entities_off in LocalPT
local test_case_id = "TC_1"
local test_case_name = test_case_id .. "_PTUSuccessWithoutDisallowedExternalConsentEntityOnLPT"
Test["Precondition_RemoveExistedLPT"] = function(self)
  common_functions:DeletePolicyTable()
end

-- Change temp_sdl_preloaded_pt_without_entity_on.json to sdl_preloaded_pt.json
-- To make sure it does not contain dissallowed_disallowed_external_consent_entities_on_entity_on param
Test["Precondition_ChangedPreloadedPt"] = function(self)
  os.execute(" cp " .. "files/temp_sdl_preloaded_pt_without_entity_on.json".. " " .. config.pathToSDL .. "sdl_preloaded_pt.json")
end

common_steps:AddNewTestCasesGroup(test_case_name)
common_steps:IgnitionOn("IgnitionOn_"..test_case_name)
common_steps:AddMobileSession("AddMobileSession_"..test_case_name)
common_steps:RegisterApplication("RegisterApplication_"..test_case_name)
common_steps:ActivateApplication("ActivateApp_"..test_case_name, config.application1.registerAppInterfaceParams.appName)
-- Add icon.png to use in UpdateTurnList API
common_steps:PutFile("Putfile_Icon.png", "icon.png")
UpdatePolicy(test_case_name, "files/ptu_without_dissallowed_external_consent_entity_on.json", config.application1.registerAppInterfaceParams.appName)

-- UpdateTurnList ("Navigation-1") is assigned to default in ptu_without_dissallowed_external_consent_entity_on.json
-- Send UpdateTurnList to verify PTU success without disallowed_bu_external_consent_entities_on in ptu file
function Test:UpdateTurnList_PositiveCase()
  local request = {
    turnList =
    {
      {
        navigationText ="Text",
        turnIcon =
        {
          value ="icon.png",
          imageType ="DYNAMIC"
        }
      }
    },
    softButtons =
    {
      {
        type ="BOTH",
        text ="Close",
        image =
        {
          value ="icon.png",
          imageType ="DYNAMIC"
        },
        isHighlighted = true,
        softButtonID = 111,
        systemAction ="DEFAULT_ACTION"
      }
    }
  }
  local cor_id_update_turn_list = self.mobileSession:SendRPC("UpdateTurnList", request)
  request.softButtons[1].image.value = storagePath..request.softButtons[1].image.value
  EXPECT_HMICALL("Navigation.UpdateTurnList",
  {
    turnList = {
      {
        navigationText =
        {
          fieldText = "Text",
          fieldName = "turnText"
        },
        turnIcon =
        {
          value =storagePath.."icon.png",
          imageType ="DYNAMIC"
        }
      }
    },
    softButtons = request.softButtons
  })
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
  end)
  EXPECT_RESPONSE(cor_id_update_turn_list, { success = true, resultCode = "SUCCESS" })
end
------------------------------------------- TC_02 ------------------------------
-- Precondition:
-- 1.SDL starts with disallowed_by_external_consent_entities_off in PreloadedPT
-- 2.disallowed_by_external_consent_entities_off is omitted in PTU
-- Verification criteria:
-- 1. SDL considers this PTU as valid
-- 2. Does not merge disallowed_by_external_consent_entities_off from PTU to LocalPT

local test_case_id = "TC_2"
local test_case_name = test_case_id .. "_PTUSuccessWithDisallowedExternalConsentEntityOnExistedLPT"
common_steps:AddNewTestCasesGroup(test_case_name)
common_steps:StopSDL("StopSDL")
Test[test_case_name .. "_Remove_Existed_LPT"] = function(self)
  common_functions:DeletePolicyTable()
end

function Test:AddItemsIntoJsonFile()
  local parent_item = {"policy_table", "functional_groupings", "Location-1"}
  local testing_value = {
    disallowed_by_external_consent_entities_off = {
      {
        entityType = 120,
        entityID = 70
      }
    }
  }
  local json_file = config.pathToSDL .. "sdl_preloaded_pt.json"
  local match_result = "null"
  local temp_replace_value = "\"Thi123456789\""
  local file = assert(io.open(json_file, "r"))
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
  file = assert(io.open(json_file, "w"))
  file:write(data_revert)
  file:close()
end

common_steps:IgnitionOn("IgnitionOn_"..test_case_name)
common_steps:AddMobileSession("AddMobileSession_"..test_case_name)
common_steps:RegisterApplication("RegisterApplication_"..test_case_name)
common_steps:ActivateApplication("ActivateApplication_"..test_case_name, config.application1.registerAppInterfaceParams.appName)
-- Add icon.png to use in UpdateTurnList API
common_steps:PutFile("Putfile_Icon.png", "icon.png")
UpdatePolicy(test_case_name, "files/ptu_without_dissallowed_external_consent_entity_on.json", config.application1.registerAppInterfaceParams.appName)
-- Send OnAppPermissionConsent to verify entity removed from LPT after PTU successfully
Test[test_case_name .. "Precondition_HMI_sends_OnAppPermissionConsent_externalConsentStatus"] = function(self)
  -- hmi side: sending SDL.OnAppPermissionConsent for applications
  self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
    source = "GUI",
    externalConsentStatus = {{entityType = 120, entityID = 70, status = "ON"}}
  })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
  :Times(0)
end

-- UpdateTurnList ("Navigation-1") is assigned to default in ptu_without_dissallowed_external_consent_entity_on.json
-- Send UpdateTurnList to verify PTU success without disallowed_bu_external_consent_entities_on in ptu file
function Test:UpdateTurnList_PositiveCase()
  local request = {
    turnList =
    {
      {
        navigationText ="Text",
        turnIcon =
        {
          value ="icon.png",
          imageType ="DYNAMIC"
        }
      }
    },
    softButtons =
    {
      {
        type ="BOTH",
        text ="Close",
        image =
        {
          value ="icon.png",
          imageType ="DYNAMIC"
        },
        isHighlighted = true,
        softButtonID = 111,
        systemAction ="DEFAULT_ACTION"
      }
    }
  }
  local cor_id_update_turn_list = self.mobileSession:SendRPC("UpdateTurnList", request)
  request.softButtons[1].image.value = storagePath..request.softButtons[1].image.value
  EXPECT_HMICALL("Navigation.UpdateTurnList",
  {
    turnList = {
      {
        navigationText =
        {
          fieldText = "Text",
          fieldName = "turnText"
        },
        turnIcon =
        {
          value =storagePath.."icon.png",
          imageType ="DYNAMIC"
        }
      }
    },
    softButtons = request.softButtons
  })
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
  end)
  EXPECT_RESPONSE(cor_id_update_turn_list, { success = true, resultCode = "SUCCESS" })
end
-------------------------------------- Postconditions ----------------------------------------
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")
