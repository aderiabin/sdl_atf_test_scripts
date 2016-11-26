require('user_modules/all_common_modules')
-------------------------------------- Variables --------------------------------------------
local parent_item = {"policy_table", "functional_groupings", "Location-1"}
local group_name = "Location-1"
local sql_query = "select entity_type, entity_id from entities, functional_group where entities.group_id = functional_group.id and functional_group = " ..group_name
local error_message = "invalid entity type is updated in LPT"
------------------------------------ Common functions ---------------------------------------
local function AddItemsIntoJsonFile(json_file, parent_item, added_json_items)
  local match_result = "null"
local temp_replace_value = "\"Thi123456789\""
	local file = io.open(json_file, "r")
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

-- Verify PTU failed when invalid parameter existed in PTU file
 local function VerifyPTUFailedWithInvalidData(test_case_name, ptu_file, mobile_session_name)
  mobile_session_name = mobile_session_name or "mobileSession"
  Test[test_case_name .. "_VerifyPTUFailedWithInvalidData"] = function (self)
  
  local CorIdSystemRequest = self[mobile_session_name]:SendRPC("SystemRequest",
    {
      fileName = "PolicyTableUpdate",
      requestType = "PROPRIETARY"
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
  --Todo:
  --hmi side: expect SDL.OnStatusUpdate
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
  :ValidIf(function(exp,data)
      if 
        exp.occurences == 1 and
        data.params.status == "UPDATE_NEEDED" then
          print ("\27[31m SDL.OnStatusUpdate came with wrong values. PTU file validation failed. Exchange wasn't successful")
          return true
      elseif
        exp.occurences == 1 and
        data.params.status == "UP_TO_DATE" then
            print ("\27[31m SDL.OnStatusUpdate came with wrong values. Exchange should not be successful.Expected in first occurrences status 'UPDATE_NEEDED', got '" .. tostring(data.params.status) .. "' \27[0m")
          return false
      elseif
        exp.occurences == 3 and
        data.params.status == "UPDATING" then
        print ("\27[31m SDL.OnStatusUpdate came with wrong values. Exchange should not be successful.Expected in second occurrences status 'UPDATE_NEEDED', got '" .. tostring(data.params.status) .. "' \27[0m")
          return true
      end

    end)
    :Times(Between(1,2))

  --mobile side: expect SystemRequest response
  EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
  :Times(0)
  end
end

-- Verify new parameter is not saved in LPT
local function VerifyInvalidEntityOnNotSavedInLPT(test_case_name, sql_query, error_message)
	Test[test_case_name] = function (self)
		-- Look for policy.sqlite file
		local policy_file1 = config.pathToSDL .. "storage/policy.sqlite"
		local policy_file2 = config.pathToSDL .. "policy.sqlite"
		local policy_file
		if old_common_steps:file_exists(policy_file1) then
			policy_file = policy_file1
		elseif old_common_steps:file_exists(policy_file2) then
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
			if(result==nil) then
				return true
			else
				self:FailTestCase("Invalid paramter is updated in LPT")
				return false
			end
		end
	end
end

-------------------------------------- Preconditions ----------------------------------------
common_functions:BackupFile("sdl_preloaded_pt.json")

------------------------------------------- BODY ---------------------------------------------
-- Precondition: 
  -- 1.SDL starts without disallowed_by_ccs_entities_on in PreloadedPT  
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
for i=1,#invalid_entity_type_cases do
  local testing_value = {
    disallowed_by_ccs_entities_on = {
      {
        entityType = invalid_entity_type_cases[i].value,
        entityID = 50
      }
    }
  }
  local test_case_id = "TC_entityType_" .. tostring(i)
  local test_case_name = test_case_id .. "_disallowed_by_ccs_entities_on.entityType_" .. invalid_entity_type_cases[i].description
  
  common_steps:AddNewTestCasesGroup(test_case_name)	

  Test[test_case_name .. "_Precondition_copy_sdl_preloaded_pt.json"] = function (self)
    os.execute(" cp " .. config.pathToSDL .. "origin_sdl_preloaded_pt.json".. " " .. config.pathToSDL .. "update_policy_table.json")
	end  
  
  Test[test_case_name .. "_UpdatePolicyTableJSONFile"] = function (self)
    AddItemsIntoJsonFile(config.pathToSDL .. 'update_policy_table.json', parent_item, testing_value)
  end 

  Test["PTUFailedWith_"..test_case_name] = function (self)
    AddItemsIntoJsonFile(config.pathToSDL .. 'update_policy_table.json', parent_item, testing_value)
  end  

  Test["VerifyInvalidEntityOnNotSavedInLPT"..test_case_name] = function (self)
    VerifyInvalidEntityOnNotSavedInLPT(test_case_name, sql_query, error_message)
  end  
end

-- Precondition: 
  -- 1.SDL starts without disallowed_by_ccs_entities_on in PreloadedPT  
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
for i=1,#invalid_entity_id_cases do
  local testing_value = {
    disallowed_by_ccs_entities_on = {
      {
        entityType = 128,
        entityID = invalid_entity_id_cases[i].value
      }
    }
  }
  local test_case_id = "TC_entityID_" .. tostring(i)
  local test_case_name = test_case_id .. "_disallowed_by_ccs_entities_on.entityID" .. invalid_entity_id_cases[i].description
  
  common_steps:AddNewTestCasesGroup(test_case_name)	

  Test[test_case_name .. "_Precondition_copy_sdl_preloaded_pt.json"] = function (self)
    os.execute(" cp " .. config.pathToSDL .. "origin_sdl_preloaded_pt.json".. " " .. config.pathToSDL .. "update_policy_table.json")
	end  
  
  Test[test_case_name .. "_UpdatePolicyTableJSONFile"] = function (self)
    AddItemsIntoJsonFile(config.pathToSDL .. 'update_policy_table.json', parent_item, testing_value)
  end 

  Test["PTUFailedWith_"..test_case_name] = function (self)
    AddItemsIntoJsonFile(config.pathToSDL .. 'update_policy_table.json', parent_item, testing_value)
  end  

  Test["VerifyInvalidEntityOnNotSavedInLPT"..test_case_name] = function (self)
    VerifyInvalidEntityOnNotSavedInLPT(test_case_name, sql_query, error_message)
  end  
end

-- Precondition: 
  -- 1.SDL starts with disallowed_by_ccs_entities_on in PreloadedPT  
  -- 2.Invalid entityType existed in PTU file
-- Verification criteria: 
  -- 1. SDL considers this PTU as invalid
  -- 2. Does not merge this invalid PTU to LocalPT
for i=1,#invalid_entity_type_cases do
  local testing_value = {
    disallowed_by_ccs_entities_on = {
      {
        entityType = invalid_entity_type_cases[i].value,
        entityID = 50
      }
    }
  }
  local test_case_id = "TC_entityType_" .. tostring(i)
  local test_case_name = test_case_id .. "_disallowed_by_ccs_entities_on.entityType_" .. invalid_entity_type_cases[i].description
  Test[tostring(test_case_name) .. "_Precondition_StopSDL"] = function(self)
		StopSDL()
	end
	
	Test[test_case_name .. "_Precondition_RestoreDefaultPreloadedPt"] = function (self)
		common_functions:DeletePolicyTable()
	end 
	
	Test[test_case_name .. "_AddedValidEntityOnIntoPreloadedPt"] = function (self)
    local parent_item_in_preloadedpt = {"policy_table", "functional_groupings", "DrivingCharacteristics-3"}
    local valid_testing_value_preloadedpt = {
    disallowed_by_ccs_entities_on = {
      {
        entityType = 150,
        entityID = 50
      }
    }
    }
		AddItemsIntoJsonFile(config.pathToSDL .. 'sdl_preloaded_pt.json', parent_item_in_preloadedpt, valid_testing_value_preloadedpt)
	end 
	
	Test[test_case_name .. "_StartSDL_WithInvalidParamInPreloadedPT"] = function(self)
		StartSDL(config.pathToSDL, config.ExitOnCrash)
	end

  Test[test_case_name .. "_Precondition_copy_sdl_preloaded_pt.json"] = function (self)
    os.execute(" cp " .. config.pathToSDL .. "origin_sdl_preloaded_pt.json".. " " .. config.pathToSDL .. "update_policy_table.json")
	end  
  
  Test[test_case_name .. "_AddedInvalidEntityOnIntoPTU"] = function (self)
    AddItemsIntoJsonFile(config.pathToSDL .. 'update_policy_table.json', parent_item, testing_value)
  end 

  Test["PTUFailedWith_"..test_case_name] = function (self)
    AddItemsIntoJsonFile(config.pathToSDL .. 'update_policy_table.json', parent_item, testing_value)
  end  

  Test["VerifyInvalidEntityOnNotSavedInLPT"..test_case_name] = function (self)
    VerifyInvalidEntityOnNotSavedInLPT(test_case_name, sql_query, error_message)
  end  
end

-- Precondition: 
  -- 1.SDL starts with disallowed_by_ccs_entities_on in PreloadedPT  
  -- 2.Invalid entityID existed in PTU file
-- Verification criteria: 
  -- 1. SDL considers this PTU as invalid
  -- 2. Does not merge this invalid PTU to LocalPT
for i=1,#invalid_entity_id_cases do
  local testing_value = {
    disallowed_by_ccs_entities_on = {
      {
        entityType = 128,
        entityID = invalid_entity_id_cases[i].value
      }
    }
  }
  local test_case_id = "TC_entityType_" .. tostring(i)
  local test_case_name = test_case_id .. "_disallowed_by_ccs_entities_on.entityType_" .. invalid_entity_id_cases[i].description
  Test[tostring(test_case_name) .. "_Precondition_StopSDL"] = function(self)
		StopSDL()
	end
	
	Test[test_case_name .. "_Precondition_RestoreDefaultPreloadedPt"] = function (self)
		common_functions:DeletePolicyTable()
	end 
	
	Test[test_case_name .. "_AddedValidEntityOnIntoPreloadedPt"] = function (self)
    local parent_item_in_preloadedpt = {"policy_table", "functional_groupings", "DrivingCharacteristics-3"}
    local valid_testing_value_preloadedpt = {
    disallowed_by_ccs_entities_on = {
      {
        entityType = 150,
        entityID = 50
      }
    }
    }
		AddItemsIntoJsonFile(config.pathToSDL .. 'sdl_preloaded_pt.json', parent_item_in_preloadedpt, valid_testing_value_preloadedpt)
	end 
	
	Test[test_case_name .. "_StartSDL_WithInvalidParamInPreloadedPT"] = function(self)
		StartSDL(config.pathToSDL, config.ExitOnCrash)
	end

  Test[test_case_name .. "_Precondition_copy_sdl_preloaded_pt.json"] = function (self)
    os.execute(" cp " .. config.pathToSDL .. "origin_sdl_preloaded_pt.json".. " " .. config.pathToSDL .. "update_policy_table.json")
	end  
  
  Test[test_case_name .. "_AddedInvalidEntityOnIntoPTU"] = function (self)
    AddItemsIntoJsonFile(config.pathToSDL .. 'update_policy_table.json', parent_item, testing_value)
  end 

  Test["PTUFailedWith_"..test_case_name] = function (self)
    AddItemsIntoJsonFile(config.pathToSDL .. 'update_policy_table.json', parent_item, testing_value)
  end  

  Test["VerifyInvalidEntityOnNotSavedInLPT"..test_case_name] = function (self)
    VerifyInvalidEntityOnNotSavedInLPT(test_case_name, sql_query, error_message)
  end  
end

------------------------------------ Postconditions ----------------------------------------
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")