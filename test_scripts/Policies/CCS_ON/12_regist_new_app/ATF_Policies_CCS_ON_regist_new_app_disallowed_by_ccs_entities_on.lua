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
-------------------------------------------Functions--------------------------------------------------
------------------------------------------------------------------------------------------------------
local function RegistAndActivateApp(test_case_name, mobile_session, application_params)
  common_steps:AddMobileSession("Precondition_Add_Mobile_Session_" .. test_case_name, "mobileConnection",mobile_session)
  common_steps:RegisterApplication("Precondition_Register_Application_" .. test_case_name, mobile_session, application_params)
  common_steps:ActivateApplication("Precondition_Activate_Application_" .. test_case_name, application_params.appName)
  Test["Precondition_Wait_For_Database_After_Activate_Application_" .. test_case_name] = function(self)
      common_functions:DelayedExp(3000)
  end  
end
------------------------------------------------------------------------------------------------------
------------------------------------------Tests-------------------------------------------------------
------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------
-- TEST 12: 
  -- In case
  -- SDL received SDL.OnAppPermissionConsent (ccsStatus) that changed user's permissions for a "<functional_grouping>"
  -- and new app that has this "<functional_grouping>" assigned connects
  -- SDL must 
  -- 1. apply CCS User Consent Settings to this app
  -- 2. send corresponding OnPermissionsChange
  -- 3. add corresponding records to PolicyTable -> "<deviceID>" section
--------------------------------------------------------------------------
-- Test 12.02:  
-- Description: disallowed_by_ccs_entities_on. HMI -> SDL: OnAppPermissionConsent(ccsStatus ON). Register new applications.
-- Expected Result: ccs_consent is created automatically.
--------------------------------------------------------------------------
-- Precondition:
--   Prepare JSON file with consent groups. Add all consent group names into app_polices of applications
--   Request Policy Table Update.
--------------------------------------------------------------------------
Test[TEST_NAME_ON.."Precondition_Update_Policy_Table"] = function(self)
  -- create json for PTU from sdl_preloaded_pt.json
  local data = common_functions_ccs_on:ConvertPreloadedToJson()
  data.policy_table.module_config.preloaded_pt = false
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
  --insert application "0000001" into "app_policies"
  data.policy_table.app_policies["0000001"] = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = {"Base-4", "Group001"}
  }
  --insert application "0000002" into "app_policies"
  data.policy_table.app_policies["0000002"] = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = {"Base-4", "Group001"}
  }
  --insert application "0000003" into "app_policies"
  data.policy_table.app_policies["0000003"] = {
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
--   Check GetListOfPermissions response with empty ccsStatus array list.
--------------------------------------------------------------------------
Test[TEST_NAME_ON.."Precondition_GetListOfPermissions"] = function(self)
  --hmi side: sending SDL.GetListOfPermissions request to SDL
  local request_id = self.hmiConnection:SendRequest("SDL.GetListOfPermissions") 
  -- hmi side: expect SDL.GetListOfPermissions response
  EXPECT_HMIRESPONSE(request_id,{
    result = {
      code = 0, 
      method = "SDL.GetListOfPermissions", 
      allowedFunctions = {
        {name = "ConsentGroup001", allowed = nil}
      },
      ccsStatus = {}
    }
  })
end

--------------------------------------------------------------------------
-- Precondition:
--   HMI sends OnAppPermissionConsent with ccs status = ON
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "Precondition_HMI_sends_OnAppPermissionConsent"] = function(self)
  hmi_app_id_1 = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
  -- hmi side: sending SDL.OnAppPermissionConsent for applications
	self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
    appID = hmi_app_id_1, source = "GUI",
    ccsStatus = {{entityType = 2, entityID = 5, status = "ON"}}
  })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
  :Times(1)  
  common_functions:DelayedExp(3000)  
end

--------------------------------------------------------------------------
-- Precondition:
--   Check consent_group in Policy Table of application "0000001": is_consented = 0
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "Precondition_Check_Consent_Group_Of_Appllication_1"] = function(self)
  local sql_query = "SELECT is_consented FROM consent_group WHERE application_id = '0000001' and functional_group_id = 'Group001';"
  local result = common_functions_ccs_on:QueryPolicyTable(policy_file, sql_query)
  print(" \27[33m group consent = " .. tostring(result) .. ". \27[0m ")
  if result ~= "0" then
    self.FailTestCase("Incorrect consent status.")    
  end
end

--------------------------------------------------------------------------
-- Precondition:
--   Check ccs_consent_group in Policy Table of application "0000001": is_consented = 0
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "Precondition_Check_Ccs_Consent_Group_Of_Appllication_1"] = function(self)
  local sql_query = "SELECT is_consented FROM ccs_consent_group WHERE application_id = '0000001' and functional_group_id = 'Group001';"
  local result = common_functions_ccs_on:QueryPolicyTable(policy_file, sql_query)
  print(" \27[33m ccs consent = " .. tostring(result) .. ". \27[0m ")
  if result ~= "0" then
    self.FailTestCase("Incorrect ccs consent status.")    
  end
end  

--------------------------------------------------------------------------
-- Precondition:
--   Register and activate application 2
--------------------------------------------------------------------------
RegistAndActivateApp("2", "mobileSession2", config.application2.registerAppInterfaceParams)

--------------------------------------------------------------------------
-- Main check:
--   Check consent_group in Policy Table of application "0000002": is_consented = 0
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "MainCheck_Consent_Group_Of_Appllication_2_Group001"] = function(self)
  local sql_query = "SELECT is_consented FROM consent_group WHERE application_id = '0000002' and functional_group_id = 'Group001';"
  local result = common_functions_ccs_on:QueryPolicyTable(policy_file, sql_query)
  print(" \27[33m group consent = " .. tostring(result) .. ". \27[0m ")
  if result ~= "0" then
    self.FailTestCase("Incorrect consent status.")    
  end
end

--------------------------------------------------------------------------
-- Main check:
--   Check ccs_consent_group in Policy Table of application "0000002": is_consented = 0
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "MainCheck_Ccs_Consent_Group_Of_Appllication_2_Group001"] = function(self)
  local sql_query = "SELECT is_consented FROM ccs_consent_group WHERE application_id = '0000002' and functional_group_id = 'Group001';"
  local result = common_functions_ccs_on:QueryPolicyTable(policy_file, sql_query)
  print(" \27[33m ccs consent = " .. tostring(result) .. ". \27[0m ")
  if result ~= "0" then
    self.FailTestCase("Incorrect ccs consent status.")    
  end
end  

--------------------------------------------------------------------------
-- Main check:
--   RPC of Group001 is disallowed to process.
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "MainCheck_RPC_of_Application_2_Group001_is_disallowed"] = function(self)
  --mobile side: send SubscribeWayPoints request
  local corid = self.mobileSession2:SendRPC("SubscribeWayPoints",{})
  --mobile side: SubscribeWayPoints response
  self.mobileSession2:ExpectResponse("SubscribeWayPoints", {success = fail , resultCode = "USER_DISALLOWED"})
  self.mobileSession2:ExpectNotification("OnHashChange")
  :Times(0)
  :Timeout(RESPONSE_TIMEOUT)
end

--------------------------------------------------------------------------
-- Precondition:
--   Activate application 1 to update policy
--------------------------------------------------------------------------
common_steps:ActivateApplication("Precondition_Activate_Application_1", config.application1.registerAppInterfaceParams.appName)

--------------------------------------------------------------------------
-- Precondition:
--   Prepare JSON file with consent groups. Add all consent group names into app_polices of applications
--   Request Policy Table Update. Change disallowed_by_ccs_entities_off to disallowed_by_ccs_entities_on
--------------------------------------------------------------------------
Test[TEST_NAME_ON.."Precondition_Update_Policy_Table"] = function(self)
  -- create json for PTU from sdl_preloaded_pt.json
  local data = common_functions_ccs_on:ConvertPreloadedToJson()
  data.policy_table.module_config.preloaded_pt = false
  -- insert Group001 into "functional_groupings"
  data.policy_table.functional_groupings.Group001 = {
    user_consent_prompt = "ConsentGroup001",
    disallowed_by_ccs_entities_off = {{
      entityType = 2, 
      entityID = 5
    }},
    rpcs = {
      SubscribeWayPoints = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
      }
    }  
  }
  --insert application "0000001" into "app_policies"
  data.policy_table.app_policies["0000001"] = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = {"Base-4", "Group001"}
  }
  --insert application "0000002" into "app_policies"
  data.policy_table.app_policies["0000002"] = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = {"Base-4", "Group001"}
  }
  --insert application "0000003" into "app_policies"
  data.policy_table.app_policies["0000003"] = {
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
--   Check consent_group in Policy Table of application "0000002": is_consented = 1
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "Precondition_Check_Consent_Group_Of_Appllication_2"] = function(self)
  local sql_query = "SELECT is_consented FROM consent_group WHERE application_id = '0000002' and functional_group_id = 'Group001';"
  local result = common_functions_ccs_on:QueryPolicyTable(policy_file, sql_query)
  print(" \27[33m group consent = " .. tostring(result) .. ". \27[0m ")
  if result ~= "1" then
    self.FailTestCase("Incorrect consent status.")    
  end
end

--------------------------------------------------------------------------
-- Precondition:
--   Check ccs_consent_group in Policy Table of application "0000002": is_consented = 1
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "Precondition_Check_Ccs_Consent_Group_Of_Appllication_2"] = function(self)
  local sql_query = "SELECT is_consented FROM ccs_consent_group WHERE application_id = '0000002' and functional_group_id = 'Group001';"
  local result = common_functions_ccs_on:QueryPolicyTable(policy_file, sql_query)
  print(" \27[33m ccs consent = " .. tostring(result) .. ". \27[0m ")
  if result ~= "1" then
    self.FailTestCase("Incorrect ccs consent status.")    
  end
end  

--------------------------------------------------------------------------
-- Precondition:
--   Register and activate application 3
--------------------------------------------------------------------------
RegistAndActivateApp("3", "mobileSession3", config.application3.registerAppInterfaceParams)

--------------------------------------------------------------------------
-- Precondition:
--   Check consent_group in Policy Table of application "0000003": is_consented = 1
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "Precondition_Check_Consent_Group_Of_Appllication_3"] = function(self)
  local sql_query = "SELECT is_consented FROM consent_group WHERE application_id = '0000003' and functional_group_id = 'Group001';"
  local result = common_functions_ccs_on:QueryPolicyTable(policy_file, sql_query)
  print(" \27[33m group consent = " .. tostring(result) .. ". \27[0m ")
  if result ~= "1" then
    self.FailTestCase("Incorrect consent status.")    
  end
end

--------------------------------------------------------------------------
-- Precondition:
--   Check ccs_consent_group in Policy Table of application "0000003": is_consented = 1
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "Precondition_Check_Ccs_Consent_Group_Of_Appllication_3"] = function(self)
  local sql_query = "SELECT is_consented FROM ccs_consent_group WHERE application_id = '0000003' and functional_group_id = 'Group001';"
  local result = common_functions_ccs_on:QueryPolicyTable(policy_file, sql_query)
  print(" \27[33m ccs consent = " .. tostring(result) .. ". \27[0m ")
  if result ~= "1" then
    self.FailTestCase("Incorrect ccs consent status.")    
  end
end

--------------------------------------------------------------------------
-- Main check:
--   RPC of Group001 is allowed to process.
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "MainCheck_RPC_of_Application_3_Group001_is_allowed"] = function(self)
  --mobile side: send SubscribeWayPoints request
  local corid = self.mobileSession3:SendRPC("SubscribeWayPoints",{})
  --hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Do(function(_,data)
    --hmi side: sending Navigation.SubscribeWayPoints response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
  end)
  --mobile side: SubscribeWayPoints response
  self.mobileSession3:ExpectResponse("SubscribeWayPoints", {success = true , resultCode = "SUCCESS"})
  self.mobileSession3:ExpectNotification("OnHashChange")
end
  
-- end Test 12.02
----------------------------------------------------
---------------------------------------------------------------------------------------------
--------------------------------------Postcondition------------------------------------------
---------------------------------------------------------------------------------------------
-- Stop SDL
Test["Stop_SDL"] = function(self)
  StopSDL()
end
