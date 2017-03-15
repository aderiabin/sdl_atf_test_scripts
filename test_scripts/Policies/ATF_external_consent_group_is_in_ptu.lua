-----------------------------------General Settings for Configuration------------------------
require('user_modules/all_common_modules')

------------------------------------ Common functions ---------------------------------------
local function AddNewParamIntoJSonFile(json_file, parent_item, testing_value, test_case_name)
  Test["AddNewParamInto_"..test_case_name] = function(self)
    local match_result = "null"
    local temp_replace_value = "\"temp_replace_value123456789\""
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
end

-------------------------------------- Preconditions ----------------------------------------
common_functions:BackupFile("sdl_preloaded_pt.json")

------------------------------------------- BODY ---------------------------------------------
-- Precondition:
-- 1. external_consent_status_groups is not existed in PreloadedPT
-- 2. external_consent_status_groups is existed in PTU
-- Verification criteria:
-- 1. SDL starts successfully
-- 2. SDL considers PTU as invalid
-- 3. PTU failed
-- 3. Does not save external_consent_status_groups from PTU to LPT
Test["RemoveExistedLPT"] = function(self)
  common_functions:DeletePolicyTable()
end

local parent_item = {"policy_table", "module_config"}
-- Add device_data into sdl_preloaded_pt.json file
local added_item_into_preloadedpt =
[[
{
  "device_data": {
    "HUU40DAS7F970UEI17A73JH32L41K32JH4L1K234H3K4": {
      "user_consent_records": {
        "0000001": {
          "consent_groups": {
            "Location": true
          },
          "input": "GUI",
          "time_stamp": "2015-10-09T18:07:21Z"
        }
      }
    }
  }
}
]]
AddNewParamIntoJSonFile(config.pathToSDL .. "sdl_preloaded_pt.json", parent_item, added_item_into_preloadedpt, "IntoPreloadedPT")
common_steps:IgnitionOn("StartSDL")
common_steps:AddMobileSession("AddMobileSession")
common_steps:RegisterApplication("RegisterApp")
common_steps:ActivateApplication("ActivateApp", config.application1.registerAppInterfaceParams.appName)
-- Add icon.png to use in UpdateTurnList API
common_steps:PutFile("Putfile_Icon.png", "icon.png")

-- Verify PTU failed when external_consent_param existed in PTU file
function Test:Verify_PTU_Failed_With_Existed_External_Status_Consent_Groups()
  local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
    EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", 
  urls = {{url = "https://policies.telematics.ford.com/api/policies"}}}})
  :Do(function(_,data)
    self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",{
      requestType = "PROPRIETARY",
    fileName = "filename"})
    EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY" })
    :Do(function(_,data) 
      local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
      {
        fileName = "PolicyTableUpdate",
        requestType = "PROPRIETARY"
      }, "files/ptu_with_external_consent_group.json")
      local systemRequestId
      EXPECT_HMICALL("BasicCommunication.SystemRequest")
      :Do(function(_,data)
        systemRequestId = data.id
        self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", {
          policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
        }
        )
        function to_run()
          self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
        end
        RUN_AFTER(to_run, 500)
      end)
      
      --mobile side: expect SystemRequest response
      EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
    end)
    --hmi side: expect SDL.OnStatusUpdate
    EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATING"}, {status = "UPDATE_NEEDED"}):Times(2)
  end)		
end

-- UpdateTurnList ("Navigation-1") is assigned to application with appid = "0000001" in ptu_with_external_consent_group.json
-- Send UpdateTurnList to verify PTU failed with external_consent_group existed in ptu file
function Test:UpdateTurnList_Disallowed()
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
  --mobile side: expect UpdateTurnList response
  self.mobileSession:ExpectResponse(cor_id_update_turn_list, {success = false, resultCode = "DISALLOWED"})
end
-------------------------------------- Postconditions ----------------------------------------
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")
--------------------------------------Postcondition------------------------------------------
Test["Stop_SDL"] = function(self)
  StopSDL()
end
