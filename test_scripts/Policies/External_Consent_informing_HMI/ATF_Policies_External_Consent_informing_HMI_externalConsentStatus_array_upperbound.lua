------------------------------------General Settings for Configuration--------------------------------
require('user_modules/all_common_modules')
local common_functions_external_consent_informing_hmi = require('user_modules/ATF_Policies_External_Consent_informing_HMI_common_functions')

---------------------------------------Common Variables-----------------------------------------------
local max_external_consent_status_array = 100
local max_allowedfunctions_array = 100
local external_consent_status_list = {}
local allowedfunctions_list = {}
local status_values = {"ON","OFF"}

---------------------------------------Preconditions--------------------------------------------------
PreconditonSteps("mobileConnection","mobileSession" , "mobileSession_2")

------------------------------------------Body--------------------------------------------------------
-- TEST-05: Upperbound of number externalConsentStatus arrays.
--------------------------------------------------------------------------
-- Test-05.01:  
-- Description: Maximum number of externalConsentStatus arrays in GetListOfPermissions is 100. Maximum number of allowedFunctions arrays in GetListOfPermissions is 100.
-- Expected Result: SDL successfully sends GetListOfPermissions response to HMI with maximum number of externalConsentStatus and allowedFunctions arrays.
--------------------------------------------------------------------------
-- Precondition:
--   Prepare JSON file with consent groups. Add all consent group names into app_polices of applications
--   Request Policy Table Update.
--------------------------------------------------------------------------
Test[TEST_NAME .. "Precondition_Update_Policy_Table"] = function(self)
  -- create PTU from sdl_preloaded_pt.json
	local data = common_functions_external_consent_informing_hmi:ConvertPreloadedToJson()
  -- insert max number of groups into "functional_groupings"  
  for i =1, max_allowedfunctions_array do
    data.policy_table.functional_groupings["Group"..tostring(i)] = {
      user_consent_prompt = "ConsentGroup"..tostring(i),
      disallowed_by_external_consent_entities_off = {{
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
  common_functions_external_consent_informing_hmi:CreateJsonFileForPTU(data, "/tmp/ptu_update.json")
  -- remove preload_pt from json file
  local parent_item = {"policy_table","module_config"}
  local removed_json_items = {"preloaded_pt"}
  common_functions:RemoveItemsFromJsonFile("/tmp/ptu_update.json", parent_item, removed_json_items)
  local removed_json_items_preloaded_date = {"preloaded_date"}
  common_functions:RemoveItemsFromJsonFile("/tmp/ptu_update.json", parent_item, removed_json_items_preloaded_date)
  -- update policy table
  common_functions_external_consent_informing_hmi:UpdatePolicy(self, "/tmp/ptu_update.json")
end

--------------------------------------------------------------------------
-- Precondition:
--   Prepare list with maximum arrays of externalConsentStatus and allowedFunctions
--------------------------------------------------------------------------
Test[TEST_NAME .. "Precondition_Prepare_externalConsentStatus_and_allowedFunctions_arrays"] = function(self)
  for i = 1, max_external_consent_status_array do
    table.insert(external_consent_status_list,i,{entityType = i, entityID = i, status = status_values[math.random(1,2)]})
  end
  for i = 1, max_allowedfunctions_array do
    table.insert(allowedfunctions_list,i,{name = "ConsentGroup"..tostring(i), allowed = nil})
  end  
end 

--------------------------------------------------------------------------
-- Precondition:
--   HMI sends OnAppPermissionConsent with externalConsentStatus arrays
-------------------------------------------------------------------------- 
Test[TEST_NAME .. "Precondition_HMI_sends_OnAppPermissionConsent"] = function(self)  
  hmi_app_id = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
	-- hmi side: sending SDL.OnAppPermissionConsent for application 1
	self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", 
      {externalConsentStatus = external_consent_status_list, appID = hmi_app_id, source = "GUI"})
  -- delay to make sure database is already updated
  common_functions:DelayedExp(2000)    
end

--------------------------------------------------------------------------
-- Main check:
--   Check GetListOfPermissions response with maximum of externalConsentStatus and allowedFunctions arrays
--------------------------------------------------------------------------
Test[TEST_NAME .. "MainCheck_GetListOfPermissions_with_maximum_of_externalConsentStatus_and_allowedFunctions_arrays"] = function(self)
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
    return #data.result.externalConsentStatus == max_external_consent_status_array and 
        #data.result.allowedFunctions == max_allowedfunctions_array
  end)
end
-- end Test-05.01

--------------------------------------Postcondition------------------------------------------
Test["Stop_SDL"] = function(self)
  StopSDL()
end 
