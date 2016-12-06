------------------------------------------------------------------------------------------------------
------------------------------------General Settings for Configuration--------------------------------
------------------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')
local common_functions_ccs_on = require('user_modules/ATF_Policies_CCS_ON_OFF_common_functions')
------------------------------------------------------------------------------------------------------
---------------------------------------Common Variables-----------------------------------------------
------------------------------------------------------------------------------------------------------
local policy_file = config.pathToSDL .. "storage/policy.sqlite"
------------------------------------------------------------------------------------------------------
---------------------------------------Preconditions--------------------------------------------------
------------------------------------------------------------------------------------------------------
-- Start SDL and register application
common_functions_ccs_on:PreconditonSteps("mobileConnection","mobileSession")
-- Activate application
common_steps:ActivateApplication("Activate_Application_1", config.application1.registerAppInterfaceParams.appName) 
------------------------------------------------------------------------------------------------------
------------------------------------------Tests-------------------------------------------------------
------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------
-- TEST 08: 
  -- In case
  -- SDL gets SDL.OnAppPermissionConsent with ccsStatus change from "ON" to "OFF"
  -- and this changes the "<functional grouping>" permissions to "user_allowed",
  -- SDL must 
  -- for all impacted apps
  -- update "consent_groups" to status "true"
  -- update "ccs_consent_groups" to status "true" 
  -- send OnPermissionsChange ("RPCs from assigned "functional_groupings" "hmiPermission": (<current assigned permissions>)", allowed) notification
--------------------------------------------------------------------------
-- Test 08.01:  
-- Description: 
--   "functional grouping" is user_disallowed by CCS "ON" 
--     (disallowed_by_ccs_entities_on exists. HMI -> SDL: OnAppPermissionConsent(ccsStatus ON))
--   HMI -> SDL: OnAppPermissionConsent(ccsStatus OFF)
-- Expected Result: 
--   Update: "consent_group"'s is_consented = 1. 
--   Update: "ccs_consent_group"'s is_consented = 1. 
--   OnPermissionsChange is sent.
--   Process RPCs from such "<functional_grouping>" as user allowed
--------------------------------------------------------------------------
-- Precondition:
--   Prepare JSON file with consent groups. Add all consent group names into app_polices of applications
--   Request Policy Table Update.
--------------------------------------------------------------------------
Test[TEST_NAME_ON.."Precondition_Update_Policy_Table"] = function(self)
  -- create PTU from sdl_preloaded_pt.json
	local data = common_functions_ccs_on:ConvertPreloadedToJson()
  -- insert Group001 into "functional_groupings"
  data.policy_table.functional_groupings.Group001 = {
    user_consent_prompt = "ConsentGroup001",
    disallowed_by_ccs_entities_on = {{
      entityType = 2, 
      entityID = 5
    }},
    rpcs = {
      SubscribeWayPoints = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
      }
    }  
  }
  --insert application "0000001" which belong to functional group "Group001" into "app_policies"
  data.policy_table.app_policies["0000001"] = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = {"Base-4", "Group001"}
  }
  --insert "ConsentGroup001" into "consumer_friendly_messages"
  data.policy_table.consumer_friendly_messages.messages["ConsentGroup001"] = {languages = {}}
  data.policy_table.consumer_friendly_messages.messages.ConsentGroup001.languages["en-us"] = {
        tts = "tts_test",
        label = "label_test",
        textBody = "textBody_test"
  }
  -- create json file for Policy Table Update  
  common_functions_ccs_on:CreateJsonFileForPTU(data, "/tmp/ptu_update.json", "/tmp/ptu_update_debug.json")
  -- update policy table
  common_functions_ccs_on:UpdatePolicy(self, "/tmp/ptu_update.json")
end

--------------------------------------------------------------------------
-- Precondition:
--   Check GetListOfPermissions response with empty ccsStatus array list. Get group id.
--------------------------------------------------------------------------
Test[TEST_NAME_ON.."Precondition_GetListOfPermissions"] = function(self)
  --hmi side: sending SDL.GetListOfPermissions request to SDL
  local request_id = self.hmiConnection:SendRequest("SDL.GetListOfPermissions") 
  -- hmi side: expect SDL.GetListOfPermissions response
  EXPECT_HMIRESPONSE(request_id,{
    result = {
      code = 0, 
      method = "SDL.GetListOfPermissions", 
      allowedFunctions = {{name = "ConsentGroup001", allowed = nil}},
      ccsStatus = {}
    }
  })
end

--------------------------------------------------------------------------
-- Precondition:
--   HMI sends OnAppPermissionConsent with ccs status = ON
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "Precondition_HMI_sends_OnAppPermissionConsent_ccsStatus_ON"] = function(self)
  -- hmi side: sending SDL.OnAppPermissionConsent for applications
	self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
    source = "GUI",
    ccsStatus = {{entityType = 2, entityID = 5, status = "ON"}}
  })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
  :Times(1)  
  common_functions:DelayedExp(2000) 
end

--------------------------------------------------------------------------
-- Precondition:
--   Check consent_group in Policy Table: is_consented = 0
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "Precondition_Check_Consent_Group"] = function(self)
  local sql_query = "SELECT is_consented FROM consent_group WHERE application_id = '0000001' and functional_group_id = 'Group001';"
  local result = common_functions_ccs_on:QueryPolicyTable(policy_file, sql_query)
  print(" \27[33m group consent = " .. tostring(result) .. ". \27[0m ")
  if result ~= "0" then
    self.FailTestCase("Incorrect consent status.")    
  end
end

--------------------------------------------------------------------------
-- Precondition:
--   Check ccs_consent_group in Policy Table: is_consented = 0
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "Precondition_Check_Ccs_Consent_Group"] = function(self)
  local sql_query = "SELECT is_consented FROM ccs_consent_group WHERE application_id = '0000001' and functional_group_id = 'Group001';"
  local result = common_functions_ccs_on:QueryPolicyTable(policy_file, sql_query)
  print(" \27[33m ccs consent = " .. tostring(result) .. ". \27[0m ")
  if result ~= "0" then
    self.FailTestCase("Incorrect ccs consent status.")    
  end
end

--------------------------------------------------------------------------
-- Main check:
--   OnAppPermissionChanged is sent
--   when HMI sends OnAppPermissionConsent with ccsStatus = OFF
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "MainCheck_HMI_sends_OnAppPermissionConsent_ccsStatus_OFF"] = function(self)
  hmi_app_id_1 = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
  -- hmi side: sending SDL.OnAppPermissionConsent for applications
	self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
    source = "GUI",
    ccsStatus = {{entityType = 2, entityID = 5, status = "OFF"}}
  })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
  :Times(1)
  common_functions:DelayedExp(2000) 
end

--------------------------------------------------------------------------
-- Main check:
--   Check consent_group in Policy Table: is_consented = 1 (updated)
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "MainCheck_Check_Consent_Group"] = function(self)
  local sql_query = "SELECT is_consented FROM consent_group WHERE application_id = '0000001' and functional_group_id = 'Group001';"
  local result = common_functions_ccs_on:QueryPolicyTable(policy_file, sql_query)
  print(" \27[33m group consent = " .. tostring(result) .. ". \27[0m ")
  if result ~= "1" then
    self.FailTestCase("Incorrect consent status.")    
  end
end

--------------------------------------------------------------------------
-- Main check:
--   Check ccs_consent_group in Policy Table: is_consented = 1 (updated)
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "MainCheck_Check_Ccs_Consent_Group"] = function(self)
  local sql_query = "SELECT is_consented FROM ccs_consent_group WHERE application_id = '0000001' and functional_group_id = 'Group001';"
  local result = common_functions_ccs_on:QueryPolicyTable(policy_file, sql_query)
  print(" \27[33m ccs consent = " .. tostring(result) .. ". \27[0m ")
  if result ~= "1" then
    self.FailTestCase("Incorrect ccs consent status.")    
  end
end

--------------------------------------------------------------------------
-- Main check:
--   RPC is allowed to process.
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "MainCheck_RPC_is_allowed"] = function(self)
	--mobile side: send SubscribeWayPoints request
  local corid = self.mobileSession:SendRPC("SubscribeWayPoints",{})
  --hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Do(function(_,data)
    --hmi side: sending Navigation.SubscribeWayPoints response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
  end)
  --mobile side: SubscribeWayPoints response
  EXPECT_RESPONSE("SubscribeWayPoints", {success = true , resultCode = "SUCCESS"})
  EXPECT_NOTIFICATION("OnHashChange")
end

-- end Test 08.01
----------------------------------------------------
---------------------------------------------------------------------------------------------
--------------------------------------Postcondition------------------------------------------
---------------------------------------------------------------------------------------------
-- Stop SDL
Test["Stop_SDL"] = function(self)
  StopSDL()
end
