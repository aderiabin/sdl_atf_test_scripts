--[[
This script purpose: Checking GetListOfPermissions response when HMI requests with nonexistent appID
--]]
------------------------------------------------------------------------------------------------------
------------------------------------General Settings for Configuration--------------------------------
------------------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')
local common_functions_ccs_informing_hmi = require('user_modules/ATF_Policies_CCS_informing_HMI_common_functions')
------------------------------------------------------------------------------------------------------
---------------------------------------Common Variables-----------------------------------------------
------------------------------------------------------------------------------------------------------
-- Not available
------------------------------------------------------------------------------------------------------
---------------------------------------Preconditions--------------------------------------------------
------------------------------------------------------------------------------------------------------
PreconditonSteps("mobileConnection","mobileSession" , "mobileSession_2")
------------------------------------------------------------------------------------------------------
------------------------------------------Tests-------------------------------------------------------
------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------
-- TEST-06: HMI request contains nonexistent appID.
--------------------------------------------------------------------------
-- Test-06.01:  
-- Description: HMI does NOT provide <ccsStatus> to SDL. HMI -> SDL: GetListOfPermissions with appID of nonexistent app
-- Expected Result:
--   nonexistent appID will be ignored and the request from HMI is the same as without appID
--   allowedFunctions: display consent groups of all registered apps
--   ccsStatus: display all ccsStatus which is sent by OnAppPermissionConsent from HMI
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
    disallowed_by_ccs_entities_off = {{
      entityType = 1, 
      entityID = 1
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
      entityID = 2
    }},
    rpcs = {
      SubscribeWayPoints = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
      }
    }  
  }  
  -- insert Group003 into "functional_groupings"
  data.policy_table.functional_groupings.Group003 = {
    --user_consent_prompt = "ConsentGroup003",
    disallowed_by_ccs_entities_off = {{
      entityType = 3, 
      entityID = 3
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
  --insert application "0000002" which belong to functional groups "Group002" and "Group003" into "app_policies"
  data.policy_table.app_policies["0000002"] = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = {"Base-4", "Group002", "Group003"}
  }  
  -- create json file for Policy Table Update  
  common_functions_ccs_informing_hmi:CreateJsonFileForPTU(data, "/tmp/ptu_update.json", "/tmp/ptu_update_debug.json")
  -- update policy table
  common_functions_ccs_informing_hmi:UpdatePolicy(self, "/tmp/ptu_update.json")
end

--------------------------------------------------------------------------
-- Precondition:
--   HMI sends OnAppPermissionConsent with ccsStatus arrays
--------------------------------------------------------------------------
Test[TEST_NAME .. "Precondition_HMI_sends_OnAppPermissionConsent"] = function(self)
	self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
    ccsStatus = {
      {entityType = 1, entityID = 1, status = "ON"}, 
      {entityType = 2, entityID = 2, status = "OFF"},
      {entityType = 3, entityID = 3, status = "ON"}}, 
    source = "GUI"})  
end

--------------------------------------------------------------------------
-- Main check:
--   Check GetListOfPermissions response when HMI request with nonexistent appID.
--------------------------------------------------------------------------
Test[TEST_NAME.."MainCheck_GetListOfPermissions_with_nonexistent_appID"] = function(self)
  --hmi side: sending SDL.GetListOfPermissions request to SDL
  local request_id = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = 9999999})
  -- hmi side: expect SDL.GetListOfPermissions response
  EXPECT_HMIRESPONSE(request_id,{
    result = {
      code = 0, 
      method = "SDL.GetListOfPermissions", 
      allowedFunctions = {
        {name = "ConsentGroup001", allowed = nil}, 
        {name = "ConsentGroup002", allowed = nil}
        -- ConsentGroup003 is not included because user_consent_prompt does not exist in group.       
      }
    }
  })
  :ValidIf(function(_,data)
    return #data.result.ccsStatus == 3 and
    common_functions_ccs_informing_hmi:Validate_ccsStatus_EntityType_EntityId(data, 1, 1) and
    common_functions_ccs_informing_hmi:Validate_ccsStatus_EntityType_EntityId(data, 2, 2) and
    common_functions_ccs_informing_hmi:Validate_ccsStatus_EntityType_EntityId(data, 3, 3) 
  end)       
end

-- end Test-06.01
----------------------------------------------------
---------------------------------------------------------------------------------------------
--------------------------------------Postcondition------------------------------------------
---------------------------------------------------------------------------------------------
-- Stop SDL
Test["Stop_SDL"] = function(self)
  StopSDL()
end
