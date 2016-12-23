------------------------------------General Settings for Configuration--------------------------------
require('user_modules/all_common_modules')
local common_functions_ccs_off = require('user_modules/ATF_Policies_CCS_ON_OFF_common_functions')

---------------------------------------Common Variables-----------------------------------------------
local policy_file = config.pathToSDL .. "storage/policy.sqlite"

---------------------------------------Preconditions--------------------------------------------------
-- Start SDL and register application
common_functions_ccs_off:PreconditonSteps("mobileConnection","mobileSession")
-- Activate application
common_steps:ActivateApplication("Activate_Application_1", config.application1.registerAppInterfaceParams.appName)

------------------------------------------Tests-------------------------------------------------------
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
-- Test 11.04:
-- Description: Both disallowed_by_ccs_entities_off and disallowed_by_ccs_entities_on exist with same pair of entities.
-- HMI -> SDL: OnAppPermissionConsent(ccsStatus ON) match that entities pair.
-- Expected Result: requested RPC is disallowed by ccs
--------------------------------------------------------------------------
-- Precondition:
-- Prepare JSON file with consent groups. Add all consent group names into app_polices of applications
-- Request Policy Table Update.
--------------------------------------------------------------------------
Test[TEST_NAME_OFF.."Precondition_Update_Policy_Table"] = function(self)
  -- create PTU from localPT
  local data = common_functions_ccs_off:ConvertPreloadedToJson()
  data.policy_table.module_config.preloaded_pt = false
  -- insert Group001 into "functional_groupings"
  data.policy_table.functional_groupings.Group001 = {
    user_consent_prompt = "ConsentGroup001",
    disallowed_by_ccs_entities_on = {
      {entityType = 1, entityID = 2}
    },
    disallowed_by_ccs_entities_off = {
      {entityType = 1, entityID = 2}
    },
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
  --insert "ConsentGroup001" into "consumer_friendly_messages"
  data.policy_table.consumer_friendly_messages.messages["ConsentGroup001"] = {languages = {}}
  data.policy_table.consumer_friendly_messages.messages.ConsentGroup001.languages["en-us"] = {
    tts = "tts_test",
    label = "label_test",
    textBody = "textBody_test"
  }
  -- create json file for Policy Table Update
  common_functions_ccs_off:CreateJsonFileForPTU(data, "/tmp/ptu_update.json", "/tmp/ptu_update_debug.json")
  -- update policy table
  common_functions_ccs_off:UpdatePolicy(self, "/tmp/ptu_update.json")
end

--------------------------------------------------------------------------
-- Precondition:
-- Check GetListOfPermissions response with empty ccsStatus array list.
--------------------------------------------------------------------------
Test[TEST_NAME_OFF.."Precondition_GetListOfPermissions"] = function(self)
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
-- Check ccs_consent_group in Policy Table: empty
--------------------------------------------------------------------------
Test[TEST_NAME_OFF .. "Precondition_Check_Ccs_Consent_Group"] = function(self)
  local sql_query = "SELECT is_consented FROM ccs_consent_group WHERE application_id = '0000001' and functional_group_id = 'Group001';"
  local result = common_functions_ccs_off:QueryPolicyTable(policy_file, sql_query)
  print(" \27[33m ccs consent = " .. tostring(result) .. ". \27[0m ")
  if result ~= nil then
    self.FailTestCase("Incorrect ccs consent status.")
  end
end

--------------------------------------------------------------------------
-- Precondition:
-- Check consent_group in Policy Table: empty
--------------------------------------------------------------------------
Test[TEST_NAME_OFF .. "Precondition_Check_Consent_Group"] = function(self)
  local sql_query = "SELECT is_consented FROM consent_group WHERE application_id = '0000001' and functional_group_id = 'Group001';"
  local result = common_functions_ccs_off:QueryPolicyTable(policy_file, sql_query)
  print(" \27[33m group consent = " .. tostring(result) .. ". \27[0m ")
  if result ~= nil then
    self.FailTestCase("Incorrect consent status.")
  end
end

--------------------------------------------------------------------------
-- Precondition:
-- HMI sends OnAppPermissionConsent
--------------------------------------------------------------------------
Test[TEST_NAME_OFF .. "Precondition_HMI_sends_OnAppPermissionConsent"] = function(self)
  -- hmi side: sending SDL.OnAppPermissionConsent for applications
  self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
      source = "GUI",
      ccsStatus = {
        {entityType = 1, entityID = 2, status = "OFF"}
      }
    })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
  :ValidIf(function(_,data)
      local validate_result = common_functions_ccs_off:ValidateHMIPermissions(data,
        "SubscribeWayPoints", {allowed = {}, userDisallowed = {"BACKGROUND","FULL","LIMITED"}})
      return validate_result
    end)
  :Times(1)
  common_functions:DelayedExp(2000)
end

--------------------------------------------------------------------------
-- Main check:
-- Check ccs_consent_group in Policy Table of Group001: is_consented = 0
--------------------------------------------------------------------------
Test[TEST_NAME_OFF .. "MainCheck_Check_Ccs_Consent_Group"] = function(self)
  local sql_query = "SELECT is_consented FROM ccs_consent_group WHERE application_id = '0000001' and functional_group_id = 'Group001';"
  local result = common_functions_ccs_off:QueryPolicyTable(policy_file, sql_query)
  print(" \27[33m ccs consent = " .. tostring(result) .. ". \27[0m ")
  if result ~= "0" then
    self.FailTestCase("Incorrect ccs consent status.")
  end
end

--------------------------------------------------------------------------
-- Main check:
-- Check consent_group in Policy Table of Group001: is_consented = 0
--------------------------------------------------------------------------
Test[TEST_NAME_OFF .. "MainCheck_Check_Consent_Group"] = function(self)
  local sql_query = "SELECT is_consented FROM consent_group WHERE application_id = '0000001' and functional_group_id = 'Group001';"
  local result = common_functions_ccs_off:QueryPolicyTable(policy_file, sql_query)
  print(" \27[33m group consent = " .. tostring(result) .. ". \27[0m ")
  if result ~= "0" then
    self.FailTestCase("Incorrect consent status.")
  end
end

--------------------------------------------------------------------------
-- Main check:
-- RPC is disallowed to process.
--------------------------------------------------------------------------
Test[TEST_NAME_OFF .. "MainCheck_RPC_is_disallowed"] = function(self)
  --mobile side: send SubscribeWayPoints request
  local corid = self.mobileSession:SendRPC("SubscribeWayPoints",{})
  --mobile side: SubscribeWayPoints response
  EXPECT_RESPONSE("SubscribeWayPoints", {success = false , resultCode = "USER_DISALLOWED"})
  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)
end

--------------------------------------Postcondition------------------------------------------
Test["Stop_SDL"] = function(self)
  StopSDL()
end
