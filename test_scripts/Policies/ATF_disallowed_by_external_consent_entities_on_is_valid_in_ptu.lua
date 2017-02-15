--------------------------------General Settings for Configuration---------------------------
require('user_modules/all_common_modules')
-------------------------------------- Variables --------------------------------------------
local parent_item = {"policy_table", "functional_groupings", "Location-1"}
local valid_entity_type_cases = {
  {description = "LowerBound", value = 0},
  {description = "UpperBound", value = 128}
}
local valid_entity_id_cases = {
  {description = "LowerBound", value = 0},
  {description = "UpperBound", value = 128}
}

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
    EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {{url = "http://policies.telematics.ford.com/api/policies"}}}})
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

-- Verify new parameter is in LPT after PTU success
local function VerifyEntityOnInLPTAfterPTUSuccess(sql_query, test_case_name)
  Test["VerifyEntityOnInLPTAfterPTUSuccess_"..test_case_name] = function(self)
    -- Look for policy.sqlite file
    local policy_file1 = config.pathToSDL .. "storage/policy.sqlite"
    local policy_file2 = config.pathToSDL .. "policy.sqlite"
    local policy_file
    if common_functions:IsFileExist(policy_file1) then
      policy_file = policy_file1
    elseif common_functions:IsFileExist(policy_file2) then
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
        self:FailTestCase("disallowed_by_external_consent_entities_on on parameter is not updated in LPT")
        return false
      else
        print ( " \27[32m disallowed_by_external_consent_entities_on is updated in LPT \27[0m " )
        return true
      end
    end
  end
end

-------------------------------------- Preconditions --------------------------
common_functions:BackupFile("sdl_preloaded_pt.json")

------------------------------------------- Body I ----------------------------
-- Precondition:
-- 1. entityType and entityID parameters are not existed in PreloadedPT
-- 2. valid entityType and entityID parameter existed in PTU
-- Verification criteria:
-- 1. SDL considers PTU as valid
-- 2. PTU success
-- 3. Saves valid entityType/entityID in entities table in LPT
for i=1, #valid_entity_type_cases do
  for j=1, #valid_entity_id_cases do
    local testing_value = {
      disallowed_by_external_consent_entities_on = {
        {
          entityType = valid_entity_type_cases[i].value,
          entityID = valid_entity_id_cases[j].value
        }
      }
    }
    local test_case_id = "TC_entityType_" .. tostring(i).."_".."_entityTID_" .. tostring(j)
    local test_case_name = test_case_id .. "_disallowed_by_external_consent_entities_on.entityType_" .. valid_entity_type_cases[i].description .."_".. valid_entity_id_cases[j].description
    
    common_steps:AddNewTestCasesGroup(test_case_name)
    common_steps:StopSDL("StopSDL")
    Test[test_case_name .. "_Remove_Existed_LPT"] = function(self)
      common_functions:DeletePolicyTable()
    end
    
    Test[test_case_name .. "_Precondition_Created_PTU"] = function(self)
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
    
    Test[test_case_name .. "_DelayedExp"] = function(self)
      common_functions:DelayedExp(5000)
    end
    
    UpdatePolicy(test_case_name, config.pathToSDL .. "update_sdl_preloaded_pt.json", config.application1.registerAppInterfaceParams.appName)
    local sql_query = "select entity_type, entity_id from entities, functional_group where entities.group_id = functional_group.id and entities.entity_Type ="..valid_entity_type_cases[i].value.. " and entities.entity_id="..valid_entity_id_cases[j].value
    VerifyEntityOnInLPTAfterPTUSuccess(sql_query, test_case_name)
    -------------------------------------- Postconditions -------------------------
    common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")
  end
end
------------------------------------------- Body II ----------------------------
-- Precondition:
-- 1. entityType and entityID parameters are existed in "Location-1" group in PreloadedPT
-- 2. valid entityType and entityID parameter existed in PTU
-- Verification criteria:
-- 1. SDL considers PTU as valid
-- 2. PTU success
-- 3. Saves valid entityType/entityID in entities table in LPT

local parent_item = {"policy_table", "functional_groupings", "Location-1"}
for i=1, #valid_entity_type_cases do
  for j=1, #valid_entity_id_cases do
    local testing_value = {
      disallowed_by_external_consent_entities_on = {
        {
          entityType = valid_entity_type_cases[i].value,
          entityID = valid_entity_id_cases[j].value
        }
      }
    }
    
    local test_case_name = "TC_entityType_" .. tostring(i).."_".. valid_entity_type_cases[i].description .."_entityTID_" .. tostring(j).."_".. valid_entity_id_cases[j].description
    common_steps:AddNewTestCasesGroup(test_case_name)
    
    common_steps:StopSDL("StopSDL")
    
    Test[test_case_name .. "_Precondition_RemovedExistedLPT"] = function(self)
      common_functions:DeletePolicyTable()
    end
    
    Test[test_case_name .. "_Precondition_Create_PTU_File"] = function(self)
      os.execute(" cp " .. config.pathToSDL .. "sdl_preloaded_pt.json".. " " .. config.pathToSDL .. "update_sdl_preloaded_pt.json")
      -- remove preload_pt from json file
      local parent_item = {"policy_table","module_config"}
      local removed_json_items = {"preloaded_pt"}
      common_functions:RemoveItemsFromJsonFile(config.pathToSDL .. "update_sdl_preloaded_pt.json", parent_item, removed_json_items)       
    end
    
    -- Add valid entityType and entityID into PTU
    AddNewParamIntoJSonFile(config.pathToSDL .. "update_sdl_preloaded_pt.json", parent_item, testing_value, "InPTU")
    
    -- Add valid entityType and entityID into PreloadedPT
    local testing_value_in_preloaded = {
      disallowed_by_external_consent_entities_on = {
        {
          entityType = 70,
          entityID = 80
        }
      }
    }
    AddNewParamIntoJSonFile(config.pathToSDL .. "sdl_preloaded_pt.json", parent_item, testing_value_in_preloaded, "InPreloadedPT")
    common_steps:IgnitionOn(test_case_name)
    common_steps:AddMobileSession("AddMobileSession_"..test_case_name)
    common_steps:RegisterApplication("RegisterApp_"..test_case_name)
    common_steps:ActivateApplication("ActivateApp_"..test_case_name, config.application1.registerAppInterfaceParams.appName)
    
    Test[test_case_name .. "_DelayedExp"] = function(self)
      common_functions:DelayedExp(5000)
    end
    
    UpdatePolicy(test_case_name, config.pathToSDL .. "update_sdl_preloaded_pt.json", config.application1.registerAppInterfaceParams.appName)
    local sql_query = "select entity_type, entity_id from entities, functional_group where entities.group_id = functional_group.id and entities.entity_Type ="..valid_entity_type_cases[i].value.. " and entities.entity_id="..valid_entity_id_cases[j].value
    VerifyEntityOnInLPTAfterPTUSuccess(sql_query, test_case_name)
    
    -------------------------------------- Postconditions -------------------------
    common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")
  end
end
