--[[This script covers requirement APPLINK-28536: [Policies] CCS: PreloadedPT with "disallowed_by_ccs_entities_on" structure with invalid type of parameters
In case
SDL uploads PreloadedPolicyTable (either as result of first SDL run, or after PreloadedPT update, or after FactoryDefaults) with “disallowed_by_ccs_entities_on: [entityType: <any_Type_except_Integer>, entityId: <any_Type_except_Integer>]” -> of "<functional grouping>" -> from "functional_groupings" section
SDL must
a. consider this PreloadedPT as invalid
b. log corresponding error internally
c. shut SDL down

Information: the only valid type of "entityType" and "entityID" is Integer per Data Dictionary

-- Author: Thi Nguyen
-- Created date: 03.Nov.2016
-- ATF version: 2.2
]]

local common_functions_for_crq_22736 = require('user_modules/CommonFunctionsForCRQ22736')
local common_functions = require('user_modules/common_multi_mobile_connections')

-------------------------------------- Variables --------------------------------------------
-- Use test_data variable in CommonFunctionsForCRQ22736.lua 

------------------------------------ Common functions ---------------------------------------
-- n/a

-------------------------------------- Preconditions ----------------------------------------
-- Use common precondition in commonFunctionsForCRQ22736.lua

------------------------------------------- BODY ---------------------------------------------
  
-- Verify cases entityTypes parameter is invalid
for i=1,#test_data.entityType.invalid_values do
  local testing_value = {
    disallowed_by_ccs_entities_on = {{
      entityType = test_data.entityType.invalid_values[i].value,
      entityID = test_data.entityID.valid_value
    }}
  }
  local test_case_id = "TC_entityType_" .. tostring(i)
  local test_case_name = test_case_id .. "_disallowed_by_ccs_entities_on.entityType_" .. test_data.entityType.invalid_values[i].description
  common_functions:AddEmptyTestForNewTestCase(test_case_name)
  common_functions:CheckNewParameterInPreloadedPt(test_case_id, test_data.parent_item, testing_value, test_data.entityType.sdl_query, false, test_data.entityType.error_message)  
end

-- Verify cases entityID parameter is invalid
for i=1,#test_data.entityID.invalid_values do
  local testing_value = {
    disallowed_by_ccs_entities_on = {{
      entityType = test_data.entityType.valid_value, 
      entityID = test_data.entityID.invalid_values[i].value
    }}
  }
  local test_case_id = "TC_entityID_" .. tostring(i)  
  local test_case_name = test_case_id .. "_disallowed_by_ccs_entities_on.entityId_" .. test_data.entityID.invalid_values[i].description
  common_functions:AddEmptyTestForNewTestCase(test_case_name)
  common_functions:CheckNewParameterInPreloadedPt(test_case_id, test_data.parent_item, testing_value, test_data.entityID.sdl_query, false, test_data.entityID.error_message)  
end

-------------------------------------- Postconditions ----------------------------------------
Test["RestoreFile"] = function (self)
  common_functions:RestoreFile("sdl_preloaded_pt.json")
end