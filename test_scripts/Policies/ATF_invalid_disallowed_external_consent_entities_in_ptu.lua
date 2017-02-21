--------------------------------General Settings for Configuration---------------------------
require('user_modules/all_common_modules')

-------------------------------------- Variables --------------------------------------------
local parent_item = {"policy_table", "functional_groupings", "Location-1"}

------------------------------------ Common functions ---------------------------------------
local function AddItemsIntoJsonFile(json_file, parent_item, added_json_items, test_case_name)
  Test["AddItemsIntoJsonFile_"..test_case_name] = function(self)
    local match_result = "null"
    local temp_replace_value = "\"Thi123456789\""
    local file = assert(io.open(json_file, "r"))
    local json_data = file:read("*all")
    file:close()
    json_data_update = string.gsub(json_data, match_result, temp_replace_value)
    local json = require("modules/json")
    local data = json.decode(json_data_update)
    if (json_file == config.pathToSDL .. "update_policy_table.json") then
      data.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID] = {
        keep_context = false,
        steal_focus = false,
        priority = "NONE",
        default_hmi = "NONE",
        groups = {"Base-4","Navigation-1"}
      }
    end
    if (json_file == config.pathToSDL .. "sdl_preloaded_pt.json") then
      data.policy_table.app_policies[config.application1.registerAppInterfaceParams.appID] = {
        keep_context = false,
        steal_focus = false,
        priority = "NONE",
        default_hmi = "NONE",
        groups = {"Base-4", "DrivingCharacteristics-3"}
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
    if type(added_json_items) == "string" then
      added_json_items = json.decode(added_json_items)
    end
    
    for k, v in pairs(added_json_items) do
      parent[k] = v
    end
    
    data = json.encode(data)
    data_revert = string.gsub(data, temp_replace_value, match_result)
    file = assert(io.open(json_file, "w"))
    file:write(data_revert)
    file:close()
  end
end
-- Verify PTU failed when invalid parameter existed in PTU file
local function VerifyPTUFailedWithInvalidData(test_case_name, ptu_file)
  Test[test_case_name.."_VerifyPTUFailed"] = function(self)
    local appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
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
-- Precondition:
-- 1.SDL starts without disallowed_by_external_consent_entities_on in PreloadedPT
-- 2.Invalid entityType existed in PTU file
-- Verification criteria:
-- 1. SDL considers this PTU as invalid
-- 2. Does not merge this invalid PTU to LocalPT
local invalid_entity_type_cases = {
  {description = "WrongType_String", value = "1"},
  {description = "OutUpperBound", value = 129},
  {description = "OutLowerBound", value = -1},
  {description = "WrongType_Float", value = 10.5},
  {description = "WrongType_EmptyTable", value = {}},
  {description = "WrongType_Table", value = {entityType = 1, entityID = 1}},
  {description = "Missed", value = nil}
}
for i=1, #invalid_entity_type_cases do
  local testing_value = {
    disallowed_by_external_consent_entities_on = {
      {
        entityType = invalid_entity_type_cases[i].value,
        entityID = 50
      }
    }
  }
  local test_case_id = "TC_entityType_" .. tostring(i)
  local test_case_name = test_case_id .."_".. invalid_entity_type_cases[i].description.."_entityID_50"
  
  common_steps:AddNewTestCasesGroup(test_case_name)
  
  Test[test_case_name .. "_Precondition_copy_sdl_preloaded_pt.json"] = function(self)
    os.execute(" cp " .. config.pathToSDL .. "sdl_preloaded_pt.json_origin".. " " .. config.pathToSDL .. "update_policy_table.json")
    -- remove preload_pt from json file
    local parent_item = {"policy_table","module_config"}
    local removed_json_items = {"preloaded_pt"}
    common_functions:RemoveItemsFromJsonFile(config.pathToSDL .. "update_policy_table.json", parent_item, removed_json_items) 
  end
  
  AddItemsIntoJsonFile(config.pathToSDL .. 'update_policy_table.json', parent_item, testing_value, "PTU_"..test_case_name)
  
  common_steps:StopSDL(test_case_name)
  
  Test[test_case_name .. "_Precondition_RemoveExistedLPT"] = function(self)
    common_functions:DeletePolicyTable()
  end
  
  common_steps:IgnitionOn(test_case_name)
  common_steps:AddMobileSession("AddMobileSession_"..test_case_name)
  common_steps:RegisterApplication("RegisterApp_"..test_case_name)
  common_steps:ActivateApplication("ActivateApp", config.application1.registerAppInterfaceParams.appName)
  -- Add icon.png to use in UpdateTurnList API
  common_steps:PutFile("Putfile_Icon.png", "icon.png")
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
end

-- Precondition:
-- 1.SDL starts without disallowed_by_external_consent_entities_on in PreloadedPT
-- 2.Invalid entityID existed in PTU file
-- Verification criteria:
-- 1. SDL considers this PTU as invalid
-- 2. Does not merge this invalid PTU to LocalPT
local invalid_entity_id_cases = {
  {description = "WrongType_String", value = "1"},
  {description = "OutUpperBound", value = 129},
  {description = "OutLowerBound", value = -1},
  {description = "WrongType_Float", value = 10.5},
  {description = "WrongType_EmptyTable", value = {}},
  {description = "WrongType_Table", value = {entityType = 1, entityID = 1}},
  {description = "Missed", value = nil}
}
for i=1, #invalid_entity_id_cases do
  local testing_value = {
    disallowed_by_external_consent_entities_on = {
      {
        entityType = 128,
        entityID = invalid_entity_id_cases[i].value
      }
    }
  }
  local test_case_id = "TC_entityID_" .. tostring(i)
  local test_case_name = test_case_id.."_" .. invalid_entity_id_cases[i].description.."_entityType_128"
  
  common_steps:AddNewTestCasesGroup(test_case_name)
  
  Test[test_case_name .. "_Precondition_copy_sdl_preloaded_pt.json"] = function(self)
    os.execute(" cp " .. config.pathToSDL .. "sdl_preloaded_pt.json_origin".. " " .. config.pathToSDL .. "update_policy_table.json")
    -- remove preload_pt from json file
    local parent_item = {"policy_table","module_config"}
    local removed_json_items = {"preloaded_pt"}
    common_functions:RemoveItemsFromJsonFile(config.pathToSDL .. "update_policy_table.json", parent_item, removed_json_items)
  end
  
  AddItemsIntoJsonFile(config.pathToSDL .. 'update_policy_table.json', parent_item, testing_value, "PTU_"..test_case_name)
  common_steps:StopSDL(test_case_name)
  
  Test[test_case_name .. "_Remove_Existed_LPT"] = function(self)
    common_functions:DeletePolicyTable()
  end
  
  common_steps:IgnitionOn(test_case_name)
  common_steps:AddMobileSession("AddMobileSession_"..test_case_name)
  common_steps:RegisterApplication("RegisterApp_"..test_case_name)
  common_steps:ActivateApplication("ActivateApp", config.application1.registerAppInterfaceParams.appName)
  -- Add icon.png to use in UpdateTurnList API
  common_steps:PutFile("Putfile_Icon.png", "icon.png")
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
end

-- Precondition:
-- 1.SDL starts with disallowed_by_external_consent_entities_on in PreloadedPT
-- 2.Invalid entityType existed in PTU file
-- Verification criteria:
-- 1. SDL considers this PTU as invalid
-- 2. Does not merge this invalid PTU to LocalPT
for i=1,#invalid_entity_type_cases do
  local testing_value = {
    disallowed_by_external_consent_entities_on = {
      {
        entityType = invalid_entity_type_cases[i].value,
        entityID = 50
      }
    }
  }
  local test_case_id = "TC_entityType_" .. tostring(i)
  local test_case_name = test_case_id .."_".. invalid_entity_type_cases[i].description.."_entityID_50"
  
  local parent_item_in_preloadedpt = {"policy_table", "functional_groupings", "DrivingCharacteristics-3"}
  local valid_testing_value_preloadedpt = {
    disallowed_by_external_consent_entities_on = {
      {
        entityType = 0,
        entityID = 128
      }
    }
  }
  
  Test[test_case_name .. "_Precondition_copy_sdl_preloaded_pt.json"] = function(self)
    os.execute(" cp " .. config.pathToSDL .. "sdl_preloaded_pt.json_origin".. " " .. config.pathToSDL .. "update_policy_table.json")
    -- remove preload_pt from json file
    local parent_item = {"policy_table","module_config"}
    local removed_json_items = {"preloaded_pt"}
    common_functions:RemoveItemsFromJsonFile(config.pathToSDL .. "update_policy_table.json", parent_item, removed_json_items)
  end
  
  AddItemsIntoJsonFile(config.pathToSDL .. 'sdl_preloaded_pt.json', parent_item_in_preloadedpt, valid_testing_value_preloadedpt, "PreloadedPT_"..test_case_name)
  
  AddItemsIntoJsonFile(config.pathToSDL .. 'update_policy_table.json', parent_item, testing_value, "PTU_"..test_case_name)
  
  common_steps:StopSDL("StopSDL_"..test_case_name)
  
  Test[test_case_name .. "_Remove_Existed_LPT"] = function(self)
    common_functions:DeletePolicyTable()
  end
  
  Test[test_case_name .. "_Precondition_RemoveExistedLPT"] = function(self)
    common_functions:DeletePolicyTable()
  end
  
  common_steps:IgnitionOn(test_case_name)
  common_steps:AddMobileSession("AddMobileSession_"..test_case_name)
  common_steps:RegisterApplication("RegisterApp_"..test_case_name)
  common_steps:ActivateApplication("ActivateApp", config.application1.registerAppInterfaceParams.appName)
  -- Add icon.png to use in UpdateTurnList API
  common_steps:PutFile("Putfile_Icon.png", "icon.png")
  VerifyPTUFailedWithInvalidData(test_case_name, config.pathToSDL .. 'update_policy_table.json')
  -- Verify valid entityType and entityID are still existed in entities table in LPT
  Test[test_case_name .. "_HMI_sends_OnAppPermissionConsent_externalConsentStatus"] = function(self)
    -- hmi side: sending SDL.OnAppPermissionConsent for applications
    self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
      source = "GUI",
      externalConsentStatus = {{entityType = 0, entityID = 128, status = "OFF"}}
    })
    self.mobileSession:ExpectNotification("OnPermissionsChange")
  end
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
end

-- Precondition:
-- 1.SDL starts with disallowed_by_external_consent_entities_on in PreloadedPT
-- 2.Invalid entityID existed in PTU file
-- Verification criteria:
-- 1. SDL considers this PTU as invalid
-- 2. Does not merge this invalid PTU to LocalPT
for i=1,#invalid_entity_id_cases do
  local testing_value = {
    disallowed_by_external_consent_entities_on = {
      {
        entityType = 128,
        entityID = invalid_entity_id_cases[i].value
      }
    }
  }
  local test_case_id = "TC_entityID_" .. tostring(i)
  local test_case_name = test_case_id .."_".. invalid_entity_id_cases[i].description.."_entityType_128"
  
  local parent_item_in_preloadedpt = {"policy_table", "functional_groupings", "DrivingCharacteristics-3"}
  local valid_testing_value_preloadedpt = {
    disallowed_by_external_consent_entities_on = {
      {
        entityType = 128,
        entityID = 50
      }
    }
  }
  
  Test[test_case_name .. "_Precondition_copy_sdl_preloaded_pt.json"] = function(self)
    os.execute(" cp " .. config.pathToSDL .. "sdl_preloaded_pt.json_origin".. " " .. config.pathToSDL .. "update_policy_table.json")
    -- remove preload_pt from json file
    local parent_item = {"policy_table","module_config"}
    local removed_json_items = {"preloaded_pt"}
    common_functions:RemoveItemsFromJsonFile(config.pathToSDL .. "update_policy_table.json", parent_item, removed_json_items)
  end
  
  AddItemsIntoJsonFile(config.pathToSDL .. 'sdl_preloaded_pt.json', parent_item_in_preloadedpt, valid_testing_value_preloadedpt, "PreloadedPT_"..test_case_name)
  AddItemsIntoJsonFile(config.pathToSDL .. 'update_policy_table.json', parent_item, testing_value, "PTU_"..test_case_name)
  
  common_steps:StopSDL(test_case_name)
  
  Test[test_case_name .. "_Removed_Existed_LPT"] = function(self)
    common_functions:DeletePolicyTable()
  end
  
  common_steps:IgnitionOn(test_case_name)
  common_steps:AddMobileSession("AddMobileSession_"..test_case_name)
  common_steps:RegisterApplication("RegisterApp_"..test_case_name)
  common_steps:ActivateApplication("ActivateApp", config.application1.registerAppInterfaceParams.appName)
  -- Add icon.png to use in UpdateTurnList API
  common_steps:PutFile("Putfile_Icon.png", "icon.png")
  
  VerifyPTUFailedWithInvalidData(test_case_name, config.pathToSDL .. 'update_policy_table.json')
  
  -- Verify valid entityType and entityID are still existed in entities table in LPT
  Test[test_case_name .. "_HMI_sends_OnAppPermissionConsent_externalConsentStatus"] = function(self)
    -- hmi side: sending SDL.OnAppPermissionConsent for applications
    self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
      source = "GUI",
      externalConsentStatus = {{entityType = 128, entityID = 50, status = "OFF"}}
    })
    self.mobileSession:ExpectNotification("OnPermissionsChange")
  end
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
end

------------------------------------ Postconditions ----------------------------------------
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")
