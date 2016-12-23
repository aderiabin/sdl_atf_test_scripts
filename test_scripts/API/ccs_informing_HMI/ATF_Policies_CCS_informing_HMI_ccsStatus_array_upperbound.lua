--[[
This script purpose: Checking upperbound number of arrays in GetListOfPermissions response
--]]
------------------------------------------------------------------------------------------------------
------------------------------------General Settings for Configuration--------------------------------
------------------------------------------------------------------------------------------------------
config.defaultProtocolVersion = 2
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
Test = require('user_modules/connect_without_mobile_connection')
require('cardinalities')
local mobile_session = require('mobile_session')
local tcp = require('tcp_connection')
local file_connection = require('file_connection')
local mobile = require('mobile_connection')
local common_functions = require('user_modules/shared_testcases/commonFunctions')
local common_steps = require('user_modules/shared_testcases/commonSteps')
local common_preconditions = require('user_modules/shared_testcases/commonPreconditions')
local common_testcases = require('user_modules/shared_testcases/commonTestCases')
local sdl_storage_path = config.pathToSDL .. "storage/"
local policy_table = require('user_modules/shared_testcases/testCasesForPolicyTable')
local common_multi_mobile_connections = require('user_modules/common_multi_mobile_connections')
local common_functions_ccs_informing_hmi = require('user_modules/ATF_Policies_CCS_informing_HMI_common_functions')
------------------------------------------------------------------------------------------------------
---------------------------------------Common Variables-----------------------------------------------
------------------------------------------------------------------------------------------------------
local max_ccsstatus_array = 100
local max_allowedfunctions_array = 100
local ccsstatus_list = {}
local allowedfunctions_list = {}
local status_values = {"ON","OFF"}
------------------------------------------------------------------------------------------------------
---------------------------------------Preconditions--------------------------------------------------
------------------------------------------------------------------------------------------------------
PreconditonSteps("mobileConnection","mobileSession" , "mobileSession_2")
------------------------------------------------------------------------------------------------------
------------------------------------------Tests-------------------------------------------------------
------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------
-- TEST-05: Upperbound of number ccsStatus arrays.
--------------------------------------------------------------------------
-- Test-05.01:  
-- Description: Maximum number of ccsStatus arrays in GetListOfPermissions is 100. Maximum number of allowedFunctions arrays in GetListOfPermissions is 100.
-- Expected Result: SDL successfully sends GetListOfPermissions response to HMI with maximum number of ccsStatus and allowedFunctions arrays.
--------------------------------------------------------------------------
-- Precondition:
--   Prepare JSON file with consent groups. Add all consent group names into app_polices of applications
--   Request Policy Table Update.
--------------------------------------------------------------------------
Test[TEST_NAME .. "Precondition_Update_Policy_Table"] = function(self)
  -- create PTU from sdl_preloaded_pt.json
	local data = common_functions_ccs_informing_hmi:ConvertPreloadedToJson()
  -- insert max number of groups into "functional_groupings"  
  for i =1, max_allowedfunctions_array do
    data.policy_table.functional_groupings["Group"..tostring(i)] = {
      user_consent_prompt = "ConsentGroup"..tostring(i),
      disallowed_by_ccs_entities_off = {{
        entityType = i, 
        entityID = i
      }},
      rpcs = {
        SubscribeWayPoints = {
          hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
        }
      }  
    }  
  end  
  --insert application "0000001" into "app_policies"
  data.policy_table.app_policies["0000001"] = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = {"Base-4"}
  }
  -- insert created groups into "groups" array of app_policies["0000001"]
  for i = 1, max_allowedfunctions_array do
    table.insert(data.policy_table.app_policies["0000001"].groups,i,"Group"..tostring(i))
  end   
  -- create json file for Policy Table Update  
  common_functions_ccs_informing_hmi:CreateJsonFileForPTU(data, "/tmp/ptu_update.json", "/tmp/ptu_update_debug.json")
  -- update policy table
  common_functions_ccs_informing_hmi:UpdatePolicy(self, "/tmp/ptu_update.json")
end

--------------------------------------------------------------------------
-- Precondition:
--   Prepare list with maximum arrays of ccsStatus and allowedFunctions
--------------------------------------------------------------------------
Test[TEST_NAME .. "Precondition_Prepare_ccsStatus_and_allowedFunctions_arrays"] = function(self)
  for i = 1, max_ccsstatus_array do
    table.insert(ccsstatus_list,i,{entityType = i, entityID = i, status = status_values[math.random(1,2)]})
  end
  for i = 1, max_allowedfunctions_array do
    table.insert(allowedfunctions_list,i,{name = "ConsentGroup"..tostring(i), allowed = nil})
  end  
end 

-- TODO[nhphi]: 
-- Replace Test[TEST_NAME .. "Precondition_Emulate_ccsStatus_added_into_database"] function
-- by Test[TEST_NAME .. "Precondition_HMI_sends_OnAppPermissionConsent"] function
-- when ccsStatus is supported by OnAppPermissionConsent
--[[
--------------------------------------------------------------------------
-- Precondition:
--   HMI sends OnAppPermissionConsent with ccsStatus arrays
-------------------------------------------------------------------------- 
Test[TEST_NAME .. "Precondition_HMI_sends_OnAppPermissionConsent"] = function(self)  
  hmi_app_id = common_multi_mobile_connections:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
	-- hmi side: sending SDL.OnAppPermissionConsent for application 1
	self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {ccsStatus = ccsstatus_list, appID = hmi_app_id, consentedFunctions = nil, source = "GUI"})  
end
--]]
--------------------------------------------------------------------------
-- Precondition:
--   Emulate HMI sends OnAppPermissionConsent with ccsStatus arrays by insert dirrectly data into database
--------------------------------------------------------------------------
Test[TEST_NAME .. "Precondition_Emulate_ccsStatus_added_into_database"] = function(self)
  common_functions:printError("Adding data into database. Please wait...")
  local policy_file = config.pathToSDL .. "storage/policy.sqlite"
  local policy_file_temp = "/tmp/policy.sqlite"
	os.execute("cp " .. policy_file .. " " .. policy_file_temp)
  for i=1, max_ccsstatus_array do
    sql_query = "insert into _internal_ccs_status (entity_type, entity_id, on_off) values (" .. tostring(ccsstatus_list[i].entityType) .. "," .. tostring(ccsstatus_list[i].entityID) .. ",'" .. tostring(ccsstatus_list[i].status) .. "'); "
    ful_sql_query = "sqlite3 " .. policy_file_temp .. " \"" .. sql_query .. "\""
    handler = io.popen(ful_sql_query, 'w')
    handler:close()
  end
  os.execute("sleep 1")  
	os.execute("cp " .. policy_file_temp .. " " .. policy_file) 
  common_multi_mobile_connections:DelayedExp(2000)  
end

--------------------------------------------------------------------------
-- Precondition:
--   Check _internal_ccs_status is not empty after ccsStatus is added
--------------------------------------------------------------------------
local sql_query = "select * from _internal_ccs_status"
local error_message = "Couldn't find ccsStatus info in Local Policy Table."
common_multi_mobile_connections:CheckPolicyTable(TEST_NAME .. "Precondition_Check_ccsStatus_is_saved_into_LocalPolicyTable", sql_query, true, error_message)

--------------------------------------------------------------------------
-- Main check:
--   Check GetListOfPermissions response with maximum of ccsStatus and allowedFunctions arrays
--------------------------------------------------------------------------
Test[TEST_NAME .. "MainCheck_GetListOfPermissions_with_maximum_of_ccsStatus_and_allowedFunctions_arrays"] = function(self)
  --hmi side: sending SDL.GetListOfPermissions request to SDL
  local request_id = self.hmiConnection:SendRequest("SDL.GetListOfPermissions")
  -- hmi side: expect SDL.GetListOfPermissions response
  EXPECT_HMIRESPONSE(request_id,{
    result = {
      code = 0, 
      method = "SDL.GetListOfPermissions"
    }
  })
  :ValidIf(function(_,data)  
      if #data.result.ccsStatus == max_ccsstatus_array and #data.result.allowedFunctions == max_allowedfunctions_array
      then 
        return true 
      else
        common_functions:printError("Number of ccsStatus arrays = " .. tostring(#data.result.ccsStatus) .. " and number of allowedFunctions arrays = " .. tostring(#data.result.allowedFunctions))
        return false
      end
  end)
end

-- end Test-05.01
----------------------------------------------------
---------------------------------------------------------------------------------------------
--------------------------------------Postcondition------------------------------------------
---------------------------------------------------------------------------------------------
-- Stop SDL
Test["Stop_SDL"] = function(self)
  StopSDL()
end 
