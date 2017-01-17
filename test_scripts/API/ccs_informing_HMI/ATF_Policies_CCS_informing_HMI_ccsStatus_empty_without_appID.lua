--[[
This script purpose: Checking GetListOfPermissions response when HMI request without appID. HMI didn't send ccsStatus in OnAppPermissionConsent before.
--]]
------------------------------------------------------------------------------------------------------
------------------------------------General Settings for Configuration--------------------------------
------------------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')
local common_functions_ccs_informing_hmi = require('user_modules/ATF_Policies_CCS_informing_HMI_common_functions')
------------------------------------------------------------------------------------------------------
---------------------------------------Common Variables-----------------------------------------------
------------------------------------------------------------------------------------------------------
local id_group
------------------------------------------------------------------------------------------------------
---------------------------------------Preconditions--------------------------------------------------
------------------------------------------------------------------------------------------------------
PreconditonSteps("mobileConnection","mobileSession" , "mobileSession_2")
------------------------------------------------------------------------------------------------------
------------------------------------------Tests-------------------------------------------------------
------------------------------------------------------------------------------------------------------
----------------------------------------------------
-- TEST-01: ccsStatus is EMPTY.
----------------------------------------------------
-- Test-01.01:  
-- Description: HMI does NOT provide <ccsStatus> to SDL. HMI -> SDL: GetListOfPermissions without appID
-- Expected result:
--   allowedFunctions: display Consent groups of all registered apps, allowed = nil (because User Consent is yet found for apps)
--   ccsStatus: empty array (because  HMI did NOT provide <ccsStatus> to SDL)
--------------------------------------------------------------------------
-- Precondition:
--   Prepare JSON file with consent groups. Add all consent group names into app_polices of applications
--   Request Policy Table Update.
--------------------------------------------------------------------------
Test[TEST_NAME.."Precondition_Update_Policy_Table"] = function(self)
  -- create PTU from sdl_preloaded_pt.json
	local data = common_functions_ccs_informing_hmi:ConvertPreloadedToJson()
  -- insert Group001 into "functional_groupings"
  data.policy_table.functional_groupings.Group001 = {
    user_consent_prompt = "ConsentGroup001",
    rpcs = {
      SubscribeWayPoints = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
      }
    }  
  }
  -- insert Group002 into "functional_groupings"
  data.policy_table.functional_groupings.Group002 = {
    user_consent_prompt = "ConsentGroup002",
    rpcs = {
      SubscribeWayPoints = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
      }
    }  
  }  
  -- insert Group003 into "functional_groupings"
  data.policy_table.functional_groupings.Group003 = {
    --user_consent_prompt = "ConsentGroup003",
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
    groups = {"Base-4","Group001"}
  }
  --insert application "0000002" which belong to functional groups "Group002" and "Group003" into "app_policies"
  data.policy_table.app_policies["0000002"] = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = {"Base-4","Group002", "Group003"}
  }
  --insert "ConsentGroup001" into "consumer_friendly_messages"
  data.policy_table.consumer_friendly_messages.messages["ConsentGroup001"] = {languages = {}}
  data.policy_table.consumer_friendly_messages.messages.ConsentGroup001.languages["en-us"] = {
        tts = "tts_test",
        label = "label_test",
        textBody = "textBody_test"
  }   
  -- create json file for Policy Table Update  
  common_functions_ccs_informing_hmi:CreateJsonFileForPTU(data, "/tmp/ptu_update.json")
  -- update policy table
  common_functions_ccs_informing_hmi:UpdatePolicy(self, "/tmp/ptu_update.json")
end

--------------------------------------------------------------------------
-- Main check 1:
--   Check GetListOfPermissions response with empty ccsStatus array list
--------------------------------------------------------------------------
Test[TEST_NAME.."MainCheck_1_ccsStatus_EMPTY_And_GetListOfPermissions_without_appID"] = function(self)
  --hmi side: sending SDL.GetListOfPermissions request to SDL
  local request_id = self.hmiConnection:SendRequest("SDL.GetListOfPermissions") 
  -- hmi side: expect SDL.GetListOfPermissions response
  EXPECT_HMIRESPONSE(request_id,{
    result = {
      code = 0, 
      method = "SDL.GetListOfPermissions", 
      allowedFunctions = {
        {name = "ConsentGroup001", allowed = nil}, 
        {name = "ConsentGroup002", allowed = nil}
        -- ConsentGroup003 is not included because user_consent_prompt does not exist in group.       
      },
      ccsStatus = {}
    }
  })
  :ValidIf(function(_,data)
    return common_functions_ccs_informing_hmi:Validate_AllowedFunctions_Id(data, "ConsentGroup001") and
        common_functions_ccs_informing_hmi:Validate_AllowedFunctions_Id(data, "ConsentGroup002")
  end)
  :Do(function(_,data)
    id_group = data.result.allowedFunctions[1].id
  end)
end

--------------------------------------------------------------------------
-- Precondition:
--   HMI sends OnAppPermissionConsent without ccsStatus
--------------------------------------------------------------------------
Test[TEST_NAME .. "Precondition_HMI_sends_OnAppPermissionConsent"] = function(self)
	-- hmi side: sending SDL.OnAppPermissionConsent for application 1
	self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent",
      {consentedFunctions = {{name = "ConsentGroup001", id = id_group, allowed = true}}, source = "GUI"})
  -- delay to make sure database is already updated
  common_functions:DelayedExp(2000)
end

--------------------------------------------------------------------------
-- Main check 2:
--   Check GetListOfPermissions response with empty ccsStatus array list
--------------------------------------------------------------------------
Test[TEST_NAME.."MainCheck_2_ccsStatus_EMPTY_And_GetListOfPermissions_without_appID"] = function(self)
  --hmi side: sending SDL.GetListOfPermissions request to SDL
  local request_id = self.hmiConnection:SendRequest("SDL.GetListOfPermissions") 
  -- hmi side: expect SDL.GetListOfPermissions response
  EXPECT_HMIRESPONSE(request_id,{
    result = {
      code = 0, 
      method = "SDL.GetListOfPermissions", 
      allowedFunctions = {
        {name = "ConsentGroup001", allowed = true}, 
        {name = "ConsentGroup002", allowed = nil}
        -- ConsentGroup003 is not included because user_consent_prompt does not exist in group.       
      },
      ccsStatus = {}
    }
  })
  :ValidIf(function(_,data)
    return common_functions_ccs_informing_hmi:Validate_AllowedFunctions_Id(data, "ConsentGroup001") and
        common_functions_ccs_informing_hmi:Validate_AllowedFunctions_Id(data, "ConsentGroup002")
  end)
end

-- end Test-01.01
----------------------------------------------------
---------------------------------------------------------------------------------------------
--------------------------------------Postcondition------------------------------------------
---------------------------------------------------------------------------------------------
-- Stop SDL
Test["Stop_SDL"] = function(self)
  StopSDL()
end
