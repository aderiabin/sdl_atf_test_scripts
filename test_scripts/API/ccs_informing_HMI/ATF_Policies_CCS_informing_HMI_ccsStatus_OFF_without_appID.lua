--[[
This script purpose: Checking GetListOfPermissions response when HMI request without appID. Status = OFF.
--]]
------------------------------------------------------------------------------------------------------
------------------------------------General Settings for Configuration--------------------------------
------------------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')
local common_functions_ccs_informing_hmi = require('user_modules/ATF_Policies_CCS_informing_HMI_common_functions')
------------------------------------------------------------------------------------------------------
---------------------------------------Common Variables-----------------------------------------------
------------------------------------------------------------------------------------------------------
local hmi_app_id_1
local hmi_app_id_2
------------------------------------------------------------------------------------------------------
----------------------------------Preconditions-------------------------------------------------------
------------------------------------------------------------------------------------------------------
PreconditonSteps("mobileConnection","mobileSession" , "mobileSession_2")
------------------------------------------------------------------------------------------------------
------------------------------------------Tests-------------------------------------------------------
------------------------------------------------------------------------------------------------------
----------------------------------------------------
-- TEST-03: ccsStatus.status is OFF.
----------------------------------------------------
-- Test-03.01:  
-- Description: HMI provides <ccsStatus> to SDL with status = OFF. HMI -> SDL: GetListOfPermissions without appID
-- Expected result: SDL reponds to HMI list of all ccsStatus
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
      entityType = 0, 
      entityID = 128
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
      entityType = 128, 
      entityID = 0
    }},
    rpcs = {
      SubscribeWayPoints = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
      }
    }  
  }  
  -- insert Group003 into "functional_groupings"
  data.policy_table.functional_groupings.Group003 = {
    user_consent_prompt = "ConsentGroup003",
    disallowed_by_ccs_entities_off = {{
      entityType = 128, 
      entityID = 128
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
    groups = {"Base-4", "Group001", "Group002"}
  }
  --insert application "0000002" which belong to functional groups "Group002" and "Group003" into "app_policies"
  data.policy_table.app_policies["0000002"] = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = {"Base-4", "Group003"}
  }  
  -- create json file for Policy Table Update  
  common_functions_ccs_informing_hmi:CreateJsonFileForPTU(data, "/tmp/ptu_update.json", "/tmp/ptu_update_debug.json")
  -- update policy table
  common_functions_ccs_informing_hmi:UpdatePolicy(self, "/tmp/ptu_update.json")
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
  hmi_app_id_1 = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
  hmi_app_id_2 = common_functions:GetHmiAppId(config.application2.registerAppInterfaceParams.appName, self)  
	-- hmi side: sending SDL.OnAppPermissionConsent for application 1
	self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
    ccsStatus = {
      {entityType = 0, entityID = 128, status = "OFF"},
      {entityType = 128, entityID = 0, status = "OFF"}
    }, 
    appID = hmi_app_id_1, consentedFunctions = nil, source = "VUI"
  })
	-- hmi side: sending SDL.OnAppPermissionConsent for application 2  
	self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", 
   {ccsStatus = {{entityType = 128, entityID = 128, status = "OFF"}}, appID = hmi_app_id_2, consentedFunctions = nil, source = "VUI"})     
end
--]]
--------------------------------------------------------------------------
-- Precondition:
--   Emulate HMI sends OnAppPermissionConsent with ccsStatus arrays by insert dirrectly data into database
--------------------------------------------------------------------------
Test[TEST_NAME .. "Precondition_Emulate_ccsStatus_added_into_database"] = function(self)
  hmi_app_id_1 = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
  hmi_app_id_2 = common_functions:GetHmiAppId(config.application2.registerAppInterfaceParams.appName, self)
  local policy_file = config.pathToSDL .. "storage/policy.sqlite"
  local policy_file_temp = "/tmp/policy.sqlite"
	os.execute("cp " .. policy_file .. " " .. policy_file_temp)
  -- insert ccsStatus = {entityType = 128, entityID = 128, status = "OFF"}
  sql_query = "insert into _internal_ccs_status (entity_type, entity_id, on_off) values (128,128,'OFF'); "
  ful_sql_query = "sqlite3 " .. policy_file_temp .. " \"" .. sql_query .. "\""
  handler = io.popen(ful_sql_query, 'w')
  handler:close()
  -- insert ccsStatus = {entityType = 128, entityID = 0, status = "OFF"}
  sql_query = "insert into _internal_ccs_status (entity_type, entity_id, on_off) values (128,0,'OFF'); "
  ful_sql_query = "sqlite3 " .. policy_file_temp .. " \"" .. sql_query .. "\""
  handler = io.popen(ful_sql_query, 'w')
  handler:close()
  -- insert ccsStatus = {entityType = 0, entityID = 128, status = "OFF"}
  sql_query = "insert into _internal_ccs_status (entity_type, entity_id, on_off) values (0,128,'OFF'); "
  ful_sql_query = "sqlite3 " .. policy_file_temp .. " \"" .. sql_query .. "\""
  handler = io.popen(ful_sql_query, 'w')
  handler:close()  
  os.execute("sleep 1")
	os.execute("cp " .. policy_file_temp .. " " .. policy_file)
end

--------------------------------------------------------------------------
-- Main check:
--   Check GetListOfPermissions response with ccsStatus array list
-------------------------------------------------------------------------- 
Test[TEST_NAME .. "MainCheck_ccsStatus_is_OFF_&_GetListOfPermissions_without_appID"] = function(self)
  --hmi side: sending SDL.GetListOfPermissions request to SDL
  local request_id = self.hmiConnection:SendRequest("SDL.GetListOfPermissions") 
  -- hmi side: expect SDL.GetListOfPermissions response
  EXPECT_HMIRESPONSE(request_id,{
    result = {
      code = 0, 
      method = "SDL.GetListOfPermissions", 
      allowedFunctions = {
        {name = "ConsentGroup001", allowed = nil}, 
        {name = "ConsentGroup002", allowed = nil},
        {name = "ConsentGroup003", allowed = nil}     
      },
      ccsStatus = {{status = "OFF"}, {status = "OFF"}, {status = "OFF"}}
    }
  })
  :ValidIf(function(_,data)
    if #data.result.ccsStatus == 3 then validate = true else validate = false end
    validate1 = common_functions_ccs_informing_hmi:Validate_ccsStatus_EntityType_EntityId(data, 128, 128)
    validate2 = common_functions_ccs_informing_hmi:Validate_ccsStatus_EntityType_EntityId(data, 0, 128)
    validate3 = common_functions_ccs_informing_hmi:Validate_ccsStatus_EntityType_EntityId(data, 128, 0)
    return (validate and validate1 and validate2 and validate3)
  end)
end

-- end Test-03.01
---------------------------------------------------------------------------------------------
-------------------------------------------Postcondition-------------------------------------
---------------------------------------------------------------------------------------------
-- Stop SDL
Test["Stop_SDL"] = function(self)
  StopSDL()
end
