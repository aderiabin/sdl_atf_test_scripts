---------------------------------General Settings for Configuration--------------------------
require('user_modules/all_common_modules')

-------------------------------------- Variables --------------------------------------------
local parent_item = {"policy_table", "functional_groupings", "Location-1"}

------------------------------------ Common functions ---------------------------------------
local function AddItemsIntoJsonFile(json_file, parent_item, added_json_items, test_case_name)
  Test["AddedValidExternalConsentOnInto_"..test_case_name] = function (self)
    local match_result = "null"
    local temp_replace_value = "\"Thi123456789\""
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
      groups = {"Base-4","Navigation-1"}
    }
    -- Go to parent item
    local parent = data
    for i = 1, #parent_item do
      if not parent[parent_item[i]] then
        parent[parent_item[i]] = {}
      end
      parent = parent[parent_item[i]]
    end
    if type(added_json_items) == "string" then
      added_json_items = json.decode(added_json_items)
    end
    
    for k, v in pairs(added_json_items) do
      parent[k] = v
    end
    
    data = json.encode(data)
    data_revert = string.gsub(data, temp_replace_value, match_result)
    file = io.open(json_file, "w")
    file:write(data_revert)
    file:close()
  end
end

-- Verify PTU failed when invalid parameter existed in PTU file
local function VerifyPTUFailedWithInvalidData(test_case_name, ptu_file)
  Test["VerifyPTUFailedWithExistedInvalidExternalConsentOn"] = function (self)
    local appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
    local ptu_file = config.pathToSDL .. "update_policy_table.json"
    local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
    {
      fileName = "PolicyTableUpdate",
      requestType = "PROPRIETARY",
      appID = appID
    },
    ptu_file)
    
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
end

-------------------------------------- Preconditions ----------------------------------------
common_functions:BackupFile("sdl_preloaded_pt.json")

------------------------------------------- BODY ---------------------------------------------
-- Precondition: invalid disallowed_by_external_consent_entities_on parameter existed in PTU
-- Verification criteria: SDL considers PTU as invalid and does not merge PTU to LPT
-------------------------------------------------------------------------------
-- Define disallowed_by_external_consent_entities_on contains 101 entities
local out_upper_bound = {}
out_upper_bound.disallowed_by_external_consent_entities_on = {}
for i = 1, 101 do
  table.insert(out_upper_bound.disallowed_by_external_consent_entities_on,
  {
    entityType = i,
    entityID = i
  }
  )
end
-- Define disallowed_by_external_consent_entities_on contains 0 entity
local out_lower_bound = {
  disallowed_by_external_consent_entities_on,
  {
  }
}
-- Define disallowed_by_external_consent_entities_on is invalid type (not array)
local invalid_type = {
  disallowed_by_external_consent_entities_on = {
    {
      10
    }
  }
}
-- Define disallowed_by_external_consent_entities_on contains valid entity and invalid entity
local valid_invalid_param = {
  disallowed_by_external_consent_entities_on = {
    {entityType = 100,
      entityID = 15
    },
    {entityType = "HELLO",
      entityID = 15
    }
  }
}

local test_data = {
  {description = "Out_Upper_Bound", value = out_upper_bound},
  {description = "Out_Lower_Bound", value = out_lower_bound},
  {description = "Invalid_Type", value = invalid_type},
  {description = "Existed_Valid_Invalid_Parm", value = valid_invalid_param}
}
for j=1, #test_data do
  local test_case_name = "TC_" ..test_data[j].description
  
  common_steps:AddNewTestCasesGroup(test_case_name)
  
  Test[test_case_name .. "_Precondition_copy_sdl_preloaded_pt.json"] = function (self)
    os.execute(" cp " .. config.pathToSDL .. "sdl_preloaded_pt.json_origin".. " " .. config.pathToSDL .. "update_policy_table.json")
    -- remove preload_pt from json file
    local parent_item = {"policy_table","module_config"}
    local removed_json_items = {"preloaded_pt"}
    common_functions:RemoveItemsFromJsonFile(config.pathToSDL .. "update_policy_table.json", parent_item, removed_json_items) 
  end
  
  AddItemsIntoJsonFile(config.pathToSDL .. 'update_policy_table.json', parent_item, test_data[j].value, "PTU_"..test_case_name)
  common_steps:StopSDL(test_case_name)
  
  Test[test_case_name .. "_Precondition_RemoveExistedLPT"] = function (self)
    common_functions:DeletePolicyTable()
  end
  
  common_steps:IgnitionOn(test_case_name)
  common_steps:AddMobileSession("AddMobileSession_"..test_case_name)
  common_steps:RegisterApplication("RegisterApp_"..test_case_name)
  VerifyPTUFailedWithInvalidData(test_case_name, config.pathToSDL .. 'update_policy_table.json')
  -- UpdateTurnList ("Navigation-1") is assigned to application with appid = "0000001" in update_policy_table.json
  -- Send UpdateTurnList to verify PTU failed with invalid value in ptu file
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
    self.mobileSession:ExpectResponse(cor_id_update_turn_list, { success = false, resultCode = "DISALLOWED" })
  end
------------------------------------ Postconditions ----------------------------------------
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")
end
