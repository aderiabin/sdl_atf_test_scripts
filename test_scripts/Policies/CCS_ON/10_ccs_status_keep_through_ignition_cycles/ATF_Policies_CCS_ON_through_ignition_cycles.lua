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
local function CheckGroup001IsNotConsentedAndGroup002IsConsented()
  --------------------------------------------------------------------------
  -- Main check:
  --   Check consent_group in Policy Table of Group001: is_consented = 0
  --------------------------------------------------------------------------
  Test[TEST_NAME_ON .. "MainCheck_Check_Consent_Group_of_Group001"] = function(self) 
    local sql_query = "SELECT is_consented FROM consent_group WHERE application_id = '0000001' and functional_group_id = 'Group001';"
    local result = common_functions_ccs_on:QueryPolicyTable(policy_file, sql_query)
    print(" \27[33m group consent = " .. tostring(result) .. ". \27[0m ")
    if result ~= "0" then
      self.FailTestCase("Incorrect consent status.")    
    end
  end

  --------------------------------------------------------------------------
  -- Main check:
  --   Check consent_group in Policy Table of Group002: is_consented = 1
  --------------------------------------------------------------------------
  Test[TEST_NAME_ON .. "MainCheck_Check_Consent_Group_of_Group002"] = function(self)
    local sql_query = "SELECT is_consented FROM consent_group WHERE application_id = '0000001' and functional_group_id = 'Group002';"
    local result = common_functions_ccs_on:QueryPolicyTable(policy_file, sql_query)
    print(" \27[33m group consent = " .. tostring(result) .. ". \27[0m ")
    if result ~= "1" then
      self.FailTestCase("Incorrect consent status.")    
    end
  end

  --------------------------------------------------------------------------
  -- Main check:
  --   Check ccs_consent_group in Policy Table of Group 001: is_consented = 0
  --------------------------------------------------------------------------
  Test[TEST_NAME_ON .. "MainCheck_Check_Ccs_Consent_Group_of_Group001"] = function(self)
    local sql_query = "SELECT is_consented FROM ccs_consent_group WHERE application_id = '0000001' and functional_group_id = 'Group001';"
    local result = common_functions_ccs_on:QueryPolicyTable(policy_file, sql_query)
    print(" \27[33m ccs consent = " .. tostring(result) .. ". \27[0m ")
    if result ~= "0" then
      self.FailTestCase("Incorrect ccs consent status.")    
    end
  end

  --------------------------------------------------------------------------
  -- Main check:
  --   Check ccs_consent_group in Policy Table of Group 002: is_consented = 1
  --------------------------------------------------------------------------
  Test[TEST_NAME_ON .. "MainCheck_Check_Ccs_Consent_Group_of_Group002"] = function(self)
    local sql_query = "SELECT is_consented FROM ccs_consent_group WHERE application_id = '0000001' and functional_group_id = 'Group002';"
    local result = common_functions_ccs_on:QueryPolicyTable(policy_file, sql_query)
    print(" \27[33m ccs consent = " .. tostring(result) .. ". \27[0m ")
    if result ~= "1" then
      self.FailTestCase("Incorrect ccs consent status.")    
    end
  end

  --------------------------------------------------------------------------
  -- Main check:
  --   RPC of Group001 is disallowed to process.
  --------------------------------------------------------------------------
  Test[TEST_NAME_ON .. "MainCheck_RPC_of_Group001_is_disallowed"] = function(self)
    --mobile side: send SubscribeWayPoints request
    local corid = self.mobileSession:SendRPC("SubscribeWayPoints",{})
    --mobile side: SubscribeWayPoints response
    EXPECT_RESPONSE("SubscribeWayPoints", {success = false , resultCode = "USER_DISALLOWED"})
    EXPECT_NOTIFICATION("OnHashChange")
    :Times(0)
    common_functions:DelayedExp(2000)
  end

  --------------------------------------------------------------------------
  -- Main check:
  --   RPC of Group002 is allowed to process.
  --------------------------------------------------------------------------
  Test[TEST_NAME_ON .. "MainCheck_RPC_is_allowed"] = function(self)
    corid = self.mobileSession:SendRPC("SubscribeVehicleData", {rpm = true})
    EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData")
    :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
    end)
    EXPECT_RESPONSE("SubscribeVehicleData", {success = true , resultCode = "SUCCESS"})
    EXPECT_NOTIFICATION("OnHashChange")
  end
end -- function CheckGroup001IsNotConsentedAndGroup002IsConsented()

local function CheckGroup001IsConsentedAndGroup002IsNotConsented()
  --------------------------------------------------------------------------
  -- Main check:
  --   Check consent_group in Policy Table of Group001: is_consented = 1
  --------------------------------------------------------------------------
  Test[TEST_NAME_ON .. "MainCheck_Check_Consent_Group_of_Group001"] = function(self)
    local sql_query = "SELECT is_consented FROM consent_group WHERE application_id = '0000001' and functional_group_id = 'Group001';"
    local result = common_functions_ccs_on:QueryPolicyTable(policy_file, sql_query)
    print(" \27[33m group consent = " .. tostring(result) .. ". \27[0m ")
    if result ~= "1" then
      self.FailTestCase("Incorrect consent status.")    
    end
  end

  --------------------------------------------------------------------------
  -- Main check:
  --   Check consent_group in Policy Table of Group002: is_consented = 0
  --------------------------------------------------------------------------
  Test[TEST_NAME_ON .. "MainCheck_Check_Consent_Group_of_Group002"] = function(self)
    local sql_query = "SELECT is_consented FROM consent_group WHERE application_id = '0000001' and functional_group_id = 'Group002';"
    local result = common_functions_ccs_on:QueryPolicyTable(policy_file, sql_query)
    print(" \27[33m group consent = " .. tostring(result) .. ". \27[0m ")
    if result ~= "0" then
      self.FailTestCase("Incorrect consent status.")    
    end
  end

  --------------------------------------------------------------------------
  -- Main check:
  --   Check ccs_consent_group in Policy Table of Group 001: is_consented = 1
  --------------------------------------------------------------------------
  Test[TEST_NAME_ON .. "MainCheck_Check_Ccs_Consent_Group_of_Group001"] = function(self)
    local sql_query = "SELECT is_consented FROM ccs_consent_group WHERE application_id = '0000001' and functional_group_id = 'Group001';"
    local result = common_functions_ccs_on:QueryPolicyTable(policy_file, sql_query)
    print(" \27[33m ccs consent = " .. tostring(result) .. ". \27[0m ")
    if result ~= "1" then
      self.FailTestCase("Incorrect ccs consent status.")    
    end
  end

  --------------------------------------------------------------------------
  -- Main check:
  --   Check ccs_consent_group in Policy Table of Group 002: is_consented = 0
  --------------------------------------------------------------------------
  Test[TEST_NAME_ON .. "MainCheck_Check_Ccs_Consent_Group_of_Group002"] = function(self)
    local sql_query = "SELECT is_consented FROM ccs_consent_group WHERE application_id = '0000001' and functional_group_id = 'Group002';"
    local result = common_functions_ccs_on:QueryPolicyTable(policy_file, sql_query)
    print(" \27[33m ccs consent = " .. tostring(result) .. ". \27[0m ")
    if result ~= "0" then
      self.FailTestCase("Incorrect ccs consent status.")    
    end
  end
  
  --------------------------------------------------------------------------
  -- Main check:
  --   RPC of Group001 is allowed to process.
  --------------------------------------------------------------------------
  Test[TEST_NAME_ON .. "MainCheck_RPC_of_Group001_is_allowed"] = function(self)
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

  --------------------------------------------------------------------------
  -- Main check:
  --   RPC of Group002 is disallowed to process.
  --------------------------------------------------------------------------
  Test[TEST_NAME_ON .. "MainCheck_RPC_of_Group002_is_disallowed"] = function(self)
    local corid = self.mobileSession:SendRPC("SubscribeVehicleData",{rpm = true})
    self.mobileSession:ExpectResponse(corid, {success = false, resultCode = "USER_DISALLOWED"})
    EXPECT_NOTIFICATION("OnHashChange")
    :Times(0)
    common_functions:DelayedExp(2000)
  end
end -- function CheckGroup001IsConsentedAndGroup002IsNotConsented()

local function IgnitionOffOnActivateApp(test_case_name)
  common_steps:IgnitionOff("Precondition_Ignition_Off_" .. test_case_name)
  common_steps:IgnitionOn("Precondition_Ignition_On_" .. test_case_name)
  common_steps:AddMobileSession("Precondition_Add_Mobile_Session_1_" .. test_case_name, "mobileConnection","mobileSession")
  common_steps:RegisterApplication("Precondition_Register_Application_1_" .. test_case_name, "mobileSession", config.application1.registerAppInterfaceParams)
  common_steps:ActivateApplication("Precondition_Activate_Application_1_" .. test_case_name, config.application1.registerAppInterfaceParams.appName)
  Test["Precondition_Wait_For_Database_After_Activate_Application_1_" .. test_case_name] = function(self)
      common_functions:DelayedExp(3000)
  end  
end
------------------------------------------------------------------------------------------------------
------------------------------------------Tests-------------------------------------------------------
------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------
-- TEST 10: 
  -- In case
  -- SDL has received SDL.OnAppPermissionConsent ("ccsStatus: ON") from HMI
  -- SDL must 
  -- use this value through ignition cycles
  -- until this CCSStatus value is changed by corresponding notification from HMI.
--------------------------------------------------------------------------
-- Test 10.01:  
-- Description: disallowed_by_ccs_entities_on/off . HMI -> SDL: OnAppPermissionConsent(ccsStatus ON). Ignition Off then On.
-- Expected Result: ccsStatus is kept.
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
  -- insert Group002 into "functional_groupings"
  data.policy_table.functional_groupings.Group002 = {
    user_consent_prompt = "ConsentGroup002",
    disallowed_by_ccs_entities_off = {{
      entityType = 2, 
      entityID = 5
    }},
    rpcs = {
      SubscribeVehicleData = {
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
    groups = {"Base-4", "Group001", "Group002"}
  }
  --insert "ConsentGroup001" into "consumer_friendly_messages"
  data.policy_table.consumer_friendly_messages.messages["ConsentGroup001"] = {languages = {}}
  data.policy_table.consumer_friendly_messages.messages.ConsentGroup001.languages["en-us"] = {
        tts = "tts_test",
        label = "label_test",
        textBody = "textBody_test"
  }
  --insert "ConsentGroup002" into "consumer_friendly_messages"
  data.policy_table.consumer_friendly_messages.messages["ConsentGroup002"] = {languages = {}}
  data.policy_table.consumer_friendly_messages.messages.ConsentGroup002.languages["en-us"] = {
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
  local request_id = self.hmiConnection:SendRequest("SDL.GetListOfPermissions") 
  EXPECT_HMIRESPONSE(request_id,{
    result = {
      code = 0, 
      method = "SDL.GetListOfPermissions", 
      allowedFunctions = {
        {name = "ConsentGroup001", allowed = nil},
        {name = "ConsentGroup002", allowed = nil}
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
	self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
    appID = hmi_app_id_1, source = "GUI",
    ccsStatus = {{entityType = 2, entityID = 5, status = "ON"}}
  })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
  :ValidIf(function(_,data)
    local validate_result = common_functions_ccs_on:ValidateHMIPermissions(data, 
      "SubscribeWayPoints", {allowed = {}, userDisallowed = {"BACKGROUND","FULL","LIMITED"}})  
    local validate_result = common_functions_ccs_on:ValidateHMIPermissions(data, 
      "SubscribeVehicleData", {allowed = {"BACKGROUND","FULL","LIMITED"}, userDisallowed = {}})
    return (validate_result_1 and validate_result_2)
  end)  
  :Times(1) 
  common_functions:DelayedExp(2000)  
end

--------------------------------------------------------------------------
-- Precondition:
--   Group001: is_consented = 0
--   Group002: is_consented = 1
--------------------------------------------------------------------------
CheckGroup001IsNotConsentedAndGroup002IsConsented()

--------------------------------------------------------------------------
-- Precondition:
--   Ignition OFF then ON and activate application.
--------------------------------------------------------------------------
IgnitionOffOnActivateApp("when_ccsStatus_ON")

--------------------------------------------------------------------------
-- Main check:
--   Group001: is_consented = 0
--   Group002: is_consented = 1
--------------------------------------------------------------------------
CheckGroup001IsNotConsentedAndGroup002IsConsented()

--------------------------------------------------------------------------
-- Precondition:
--   HMI sends OnAppPermissionConsent with ccs status = OFF
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "Precondition_HMI_sends_OnAppPermissionConsent"] = function(self)
  hmi_app_id_1 = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
	self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
    appID = hmi_app_id_1, source = "GUI",
    ccsStatus = {{entityType = 2, entityID = 5, status = "OFF"}}
  })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
  :ValidIf(function(_,data)
    local validate_result = common_functions_ccs_on:ValidateHMIPermissions(data, 
      "SubscribeWayPoints", {allowed = {"BACKGROUND","FULL","LIMITED"}, userDisallowed = {}})  
    local validate_result = common_functions_ccs_on:ValidateHMIPermissions(data, 
      "SubscribeVehicleData", {allowed = {}, userDisallowed = {"BACKGROUND","FULL","LIMITED"}})
    return (validate_result_1 and validate_result_2)
  end)  
  :Times(1) 
  common_functions:DelayedExp(2000)  
end

--------------------------------------------------------------------------
-- Precondition:
--   Group001: is_consented = 1
--   Group002: is_consented = 0
--------------------------------------------------------------------------
CheckGroup001IsConsentedAndGroup002IsNotConsented()

--------------------------------------------------------------------------
-- Precondition:
--   Ignition OFF then ON and activate application.
--------------------------------------------------------------------------
IgnitionOffOnActivateApp("when_ccsStatus_OFF")

--------------------------------------------------------------------------
-- Main check:
--   Group001: is_consented = 1
--   Group002: is_consented = 0
--------------------------------------------------------------------------
CheckGroup001IsConsentedAndGroup002IsNotConsented()

-- end Test 10.01
----------------------------------------------------
---------------------------------------------------------------------------------------------
--------------------------------------Postcondition------------------------------------------
---------------------------------------------------------------------------------------------
-- Stop SDL
Test["Stop_SDL"] = function(self)
  StopSDL()
end
