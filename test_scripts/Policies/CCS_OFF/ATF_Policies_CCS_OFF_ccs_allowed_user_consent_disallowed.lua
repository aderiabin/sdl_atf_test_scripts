------------------------------------General Settings for Configuration--------------------------------
require('user_modules/all_common_modules')
local common_functions_ccs_off = require('user_modules/ATF_Policies_CCS_ON_OFF_common_functions')

---------------------------------------Common Variables-----------------------------------------------
local id_group_1
local policy_file = config.pathToSDL .. "storage/policy.sqlite"

---------------------------------------Preconditions--------------------------------------------------
common_functions_ccs_off:PreconditonSteps("mobileConnection","mobileSession")
common_steps:ActivateApplication("Activate_Application_1", config.application1.registerAppInterfaceParams.appName)

------------------------------------------Tests-------------------------------------------------------
-- TEST 06:
-- In case
-- "functional grouping" is user_allowed by CCS "OFF" notification from HMI
-- and SDL gets SDL.OnAppPermissionConsent ( "functional grouping": userDisallowed, appID)from HMI
-- SDL must
-- update "consent_groups" of specific app (change appropriate <functional_grouping> status to "false")
-- leave the same value in "ccs_consent_groups" (<functional_grouping>:true)
-- send OnPermissionsChange to all impacted apps
-- send 'USER_DISALLOWED, success:false' to mobile app on requested RPCs from this "functional grouping"
--------------------------------------------------------------------------
-- Test 06.02:
-- Description:
-- "functional grouping" is allowed by CCS "OFF"
-- (disallowed_by_ccs_entities_on exists. HMI -> SDL: OnAppPermissionConsent(ccsStatus OFF))
-- HMI -> SDL: OnAppPermissionConsent(function = disallowed)
-- Expected Result:
-- Update: "consent_group"'s is_consented = 0.
-- Not update: "ccs_consent_group"'s is_consented = 1.
-- OnPermissionsChange is sent.
-- Process RPCs from such "<functional_grouping>" as user disallowed
--------------------------------------------------------------------------
-- Precondition:
-- Prepare JSON file with consent groups. Add all consent group names into app_polices of applications
-- Request Policy Table Update.
--------------------------------------------------------------------------
Test[TEST_NAME_OFF.."Precondition_Update_Policy_Table"] = function(self)
  -- create json for PTU from sdl_preloaded_pt.json
  local data = common_functions_ccs_off:ConvertPreloadedToJson()
  data.policy_table.module_config.preloaded_pt = false
  -- insert Group001 into "functional_groupings"
  data.policy_table.functional_groupings.Group001 = {
    user_consent_prompt = "ConsentGroup001",
    disallowed_by_ccs_entities_on = {{
        entityType = 1,
        entityID = 1
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
  common_functions_ccs_off:CreateJsonFileForPTU(data, "/tmp/ptu_update.json")
  -- update policy table
  common_functions_ccs_off:UpdatePolicy(self, "/tmp/ptu_update.json")
end

--------------------------------------------------------------------------
-- Precondition:
-- Check GetListOfPermissions response with empty ccsStatus array list. Get group id.
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
  :Do(function(_,data)
      id_group_1 = common_functions_ccs_off:GetGroupId(data, "ConsentGroup001")
    end)
end

--------------------------------------------------------------------------
-- Precondition:
-- HMI sends OnAppPermissionConsent with ccs status = OFF
--------------------------------------------------------------------------
Test[TEST_NAME_OFF .. "Precondition_HMI_sends_OnAppPermissionConsent"] = function(self)
  -- hmi side: sending SDL.OnAppPermissionConsent for applications
  self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
      source = "GUI",
      ccsStatus = {{entityType = 1, entityID = 1, status = "OFF"}}
    })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
  :ValidIf(function(_,data)
      local validate_result = common_functions_ccs_off:ValidateHMIPermissions(data,
        "SubscribeWayPoints", {allowed = {"BACKGROUND","FULL","LIMITED"}, userDisallowed = {}})
      return validate_result
    end)
end

--------------------------------------------------------------------------
-- Precondition:
-- OnAppPermissionChanged is not sent
-- when HMI sends OnAppPermissionConsent with consentedFunctions allowed = false
--------------------------------------------------------------------------
Test[TEST_NAME_OFF .. "Precondition_HMI_sends_OnAppPermissionConsent"] = function(self)
  hmi_app_id_1 = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
  -- hmi side: sending SDL.OnAppPermissionConsent for applications
  self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
      appID = hmi_app_id_1, source = "GUI",
      consentedFunctions = {{name = "ConsentGroup001", id = id_group_1, allowed = false}}
    })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
  :ValidIf(function(_,data)
      local validate_result = common_functions_ccs_off:ValidateHMIPermissions(data,
        "SubscribeWayPoints", {allowed = {}, userDisallowed = {"BACKGROUND","FULL","LIMITED"}})
      return validate_result
    end)
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
