------------------------------------General Settings for Configuration-----------------------
require('user_modules/all_common_modules')

----------------------------------- Common Variables ---------------------------------------
local storagePath = config.pathToSDL .. "storage/"..config.application1.registerAppInterfaceParams.appID.. "_" .. config.deviceMAC.. "/"

-------------------------------------- Preconditions ----------------------------------------
common_functions:BackupFile("sdl_preloaded_pt.json")

------------------------------------------- BODY ---------------------------------------------
-- Precondition:
-- 1.SDL starts without external_consent_status_groups in PreloadedPT
-- 2.external_consent_status_groups is omitted in PTU
-- Verification criteria:
-- 1. SDL considers this PTU as valid
-- 2. Does not saved external_consent_status_groups in LocalPT
Test["Precondition_RestoreDefaultPreloadedPt"] = function(self)
  common_functions:DeletePolicyTable()
end

-- Change temp_sdl_preloaded_pt_without_external_consent_status_groups.json to sdl_preloaded_pt.json
-- To make sure it does not contain external_consent_status_groups param
Test["Precondition_ChangedPreloadedPt"] = function(self)
  os.execute(" cp files/temp_sdl_preloaded_pt_without_external_consent_status_groups.json ".. config.pathToSDL .. "sdl_preloaded_pt.json")
end

common_steps:IgnitionOn("IgnitionOn")
common_steps:AddMobileSession("AddMobileSession")
common_steps:RegisterApplication("RegisterApp")
common_steps:ActivateApplication("ActivateApp", config.application1.registerAppInterfaceParams.appName)
-- Add icon.png to use in UpdateTurnList API
common_steps:PutFile("Putfile_Icon.png", "icon.png")
Test["PTUSuccessWithoutExternalConsentStatusGroups"] = function(self)
  --hmi side: sending SDL.GetURLS request
  local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  
  --hmi side: expect SDL.GetURLS response from HMI
  EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {{url = "http://policies.telematics.ford.com/api/policies"}}}})
  :Do(function(_,data)
    --hmi side: sending BasicCommunication.OnSystemRequest request to SDL
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
        requestType = "PROPRIETARY"
      },
      "files/ptu_without_external_consent_group.json")
      
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
end

-- UpdateTurnList ("Navigation-1") is assigned to default in ptu_withConsentGroup.json
-- Send UpdateTurnList to verify PTU success without external_consent_group
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
