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
-- TEST 11: 
  -- In case
  -- SDL received SDL.OnAppPermissionConsent (ccsStatus) with {entityType [];entityID []}
  -- and in Policy Table "functional_groupings" -> "functional_group" with "disallowed_by_ccs_entities_on/off" param has a few pairs of {entityType; entityID}
  -- and if at least one pair of {entityType[]; entityID[]} from "disallowed_by_ccs_entities_on/off" param matches with the received one in "externalConsentStatus" 
  -- and this status disallows "functional_grouping"
  -- SDL must 
  -- apply externalConsentStatus for the whole "functional_group" that contains pair of {entityType []; entityID []} received with On.AppPermissionsConsent (ccsStatus) 
  -- and disallow RPCs from such functional grouping
--------------------------------------------------------------------------
-- Test 11.01:  
-- Description: There are 2 pairs of entities in 1 group. 
--              HMI -> SDL: OnAppPermissionConsent(ccsStatus ON) with entities pair only match one entities pair in group. 
-- Expected Result: ccsStatus can find and apply for right group.
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
    disallowed_by_ccs_entities_on = {
      {entityType = 1, entityID = 1},
      {entityType = 2, entityID = 2},
      {entityType = 3, entityID = 3}
    },    
    rpcs = {
      SubscribeWayPoints = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
      }
    }  
  }
  -- insert Group002 into "functional_groupings"
  data.policy_table.functional_groupings.Group002 = {
    user_consent_prompt = "ConsentGroup002",
    disallowed_by_ccs_entities_off = {
      {entityType = 4, entityID = 4},
      {entityType = 5, entityID = 5},      
      {entityType = 6, entityID = 6}
    },    
    rpcs = {
      Alert = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
      }
    }  
  }  
  -- insert Group003 into "functional_groupings"
  data.policy_table.functional_groupings.Group003 = {
    user_consent_prompt = "ConsentGroup003",
    disallowed_by_ccs_entities_off = {
      {entityType = 7, entityID = 7}     
    },
    disallowed_by_ccs_entities_on = {
      {entityType = 8, entityID = 8}     
    },    
    rpcs = {
      SendLocation = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
      }
    }  
  }
  -- insert Group004 into "functional_groupings"  
  data.policy_table.functional_groupings.Group004 = {
    user_consent_prompt = "ConsentGroup004",
    disallowed_by_ccs_entities_on = {
      {entityType = 1, entityID = 2}      
    },
    rpcs = {
      SubscribeVehicleData = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
      }
    }  
  }
  -- insert Group005 into "functional_groupings"
  data.policy_table.functional_groupings.Group005 = {
    user_consent_prompt = "ConsentGroup005",
    disallowed_by_ccs_entities_off = {
      {entityType = 2, entityID = 1}     
    },  
    rpcs = {
      UnsubscribeVehicleData = {
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
    groups = {"Base-4", "Group001", "Group002", "Group003", "Group004", "Group005"}
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
      allowedFunctions = {{name = "ConsentGroup001", allowed = nil}},
      ccsStatus = {}
    }
  })
end

--------------------------------------------------------------------------
-- Precondition:
--   Check ccs_consent_group in Policy Table: empty
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "Precondition_Check_Ccs_Consent_Group"] = function(self)
  local sql_query = "SELECT is_consented FROM ccs_consent_group WHERE application_id = '0000001';"
  local result = common_functions_ccs_on:QueryPolicyTable(policy_file, sql_query)
  print(" \27[33m ccs consent = " .. tostring(result) .. ". \27[0m ")
  if result ~= nil then
    self.FailTestCase("Incorrect ccs consent status.")    
  end
end

--------------------------------------------------------------------------
-- Precondition:
--   HMI sends OnAppPermissionConsent
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "Precondition_HMI_sends_OnAppPermissionConsent"] = function(self)
  -- hmi side: sending SDL.OnAppPermissionConsent for applications
	self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
    source = "GUI",
    ccsStatus = {
      {entityType = 1, entityID = 1, status = "ON"},
      {entityType = 6, entityID = 6, status = "ON"}, 
      {entityType = 7, entityID = 7, status = "ON"},
      {entityType = 9, entityID = 9, status = "ON"}      
    }
  })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
  :Times(3) 
  common_functions:DelayedExp(2000)
end

--------------------------------------------------------------------------
-- Main check:
--   Check ccs_consent_group in Policy Table of Group001: is_consented = 0
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "MainCheck_Check_Ccs_Consent_Group"] = function(self)
  local sql_query = "SELECT is_consented FROM ccs_consent_group WHERE application_id = '0000001' and functional_group_id = 'Group001';"
  local result = common_functions_ccs_on:QueryPolicyTable(policy_file, sql_query)
  print(" \27[33m ccs consent = " .. tostring(result) .. ". \27[0m ")
  if result ~= "0" then
    self.FailTestCase("Incorrect ccs consent status.")    
  end
end

--------------------------------------------------------------------------
-- Main check:
--   Check ccs_consent_group in Policy Table of Group002: is_consented = 1
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "MainCheck_Check_Ccs_Consent_Group"] = function(self)
  local sql_query = "SELECT is_consented FROM ccs_consent_group WHERE application_id = '0000001' and functional_group_id = 'Group002';"
  local result = common_functions_ccs_on:QueryPolicyTable(policy_file, sql_query)
  print(" \27[33m ccs consent = " .. tostring(result) .. ". \27[0m ")
  if result ~= "1" then
    self.FailTestCase("Incorrect ccs consent status.")    
  end
end

--------------------------------------------------------------------------
-- Main check:
--   Check ccs_consent_group in Policy Table of Group003: is_consented = 1
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "MainCheck_Check_Ccs_Consent_Group"] = function(self)
  local sql_query = "SELECT is_consented FROM ccs_consent_group WHERE application_id = '0000001' and functional_group_id = 'Group003';"
  local result = common_functions_ccs_on:QueryPolicyTable(policy_file, sql_query)
  print(" \27[33m ccs consent = " .. tostring(result) .. ". \27[0m ")
  if result ~= "1" then
    self.FailTestCase("Incorrect ccs consent status.")    
  end
end

--------------------------------------------------------------------------
-- Precondition:
--   Check ccs_consent_group in Policy Table of Group004: empty
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "Precondition_Check_Ccs_Consent_Group"] = function(self)
  local sql_query = "SELECT is_consented FROM ccs_consent_group WHERE application_id = '0000001' and functional_group_id = 'Group004';"
  local result = common_functions_ccs_on:QueryPolicyTable(policy_file, sql_query)
  print(" \27[33m ccs consent = " .. tostring(result) .. ". \27[0m ")
  if result ~= nil then
    self.FailTestCase("Incorrect ccs consent status.")    
  end
end

--------------------------------------------------------------------------
-- Precondition:
--   Check ccs_consent_group in Policy Table of Group005: empty
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "Precondition_Check_Ccs_Consent_Group"] = function(self)
  local sql_query = "SELECT is_consented FROM ccs_consent_group WHERE application_id = '0000001' and functional_group_id = 'Group005';"
  local result = common_functions_ccs_on:QueryPolicyTable(policy_file, sql_query)
  print(" \27[33m ccs consent = " .. tostring(result) .. ". \27[0m ")
  if result ~= nil then
    self.FailTestCase("Incorrect ccs consent status.")    
  end
end

-- end Test 11.01
----------------------------------------------------
---------------------------------------------------------------------------------------------
--------------------------------------Postcondition------------------------------------------
---------------------------------------------------------------------------------------------
-- Stop SDL
Test["Stop_SDL"] = function(self)
  StopSDL()
end
