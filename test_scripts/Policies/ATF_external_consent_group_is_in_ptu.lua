-----------------------------------General Settings for Configuration------------------------
require('user_modules/all_common_modules')

------------------------------------ Common functions ---------------------------------------
local function AddNewParamIntoJSonFile(json_file, parent_item, testing_value, test_case_name)
  Test["AddNewParamInto_"..test_case_name] = function(self)
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

Test["Precondition_ChangedPreloadedPt"] = function(self)
  os.execute(" cp " .. config.pathToSDL .. "sdl_preloaded_pt.json".. " " .. config.pathToSDL .. "update_sdl_preloaded_pt.json")
  -- remove preload_pt from json file
  local parent_item = {"policy_table","module_config"}
  local removed_json_items = {"preloaded_pt"}
  common_functions:RemoveItemsFromJsonFile(config.pathToSDL .. "update_sdl_preloaded_pt.json", parent_item, removed_json_items)   
end

local parent_item = {"policy_table", "module_config"}
local added_item_into_ptu =
[[
{
  "device_data": {
    "HUU40DAS7F970UEI17A73JH32L41K32JH4L1K234H3K4": {
      "user_consent_records": {
        "0000001": {
          "consent_groups": {
            "Location": true
          },
          "external_consent_status_groups": {
            "Location": false
          },
          "input": "GUI",
          "time_stamp": "2015-10-09T18:07:21Z"
        }
      }
    }
  }
}
]]
-- Add valid entityType and entityID into PTU
AddNewParamIntoJSonFile(config.pathToSDL .. "update_sdl_preloaded_pt.json", parent_item, added_item_into_ptu, "IntoPTU")

-- Add valid entityType and entityID into PreloadedPT
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

-- Verify PTU failed when external_consent_param existed in PTU file
Test["VerifyPTUFailedWithExistedExternalConsentStatusGroups"] = function(self)
  local appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
  local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
    {
      fileName = "PolicyTableUpdate",
      requestType = "PROPRIETARY",
      appID = appID
    },
    config.pathToSDL .. "update_sdl_preloaded_pt.json")

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
  :Times(0)

  --mobile side: expect SystemRequest response
  EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
end

-- Verify external_consent_status_groups is not saved in LPT after PTU failed
Test["VerifyExternalConsentStatusGroupsNotSavedInLPTWhenPTUFailed"] = function(self)
  local sql_query = "select * from external_consent_status_groups"
  -- Look for policy.sqlite file
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
    if(result == nil or result == "") then
      print ( " \27[32m external_consent_status_groups is not updated in LPT \27[0m " )
      return true
    else
      self:FailTestCase("external_consent_status_groups is updated in LPT")
      return false
    end
  end
end
-------------------------------------- Postconditions ----------------------------------------
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")
