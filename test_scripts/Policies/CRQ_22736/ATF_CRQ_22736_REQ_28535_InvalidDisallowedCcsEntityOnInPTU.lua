--[[This script covers requirement APPLINK-28535: [Policies] CCS: PTU with "disallowed_by_ccs_entities_on" struct with invalid type of params
In case
SDL receives PolicyTableUpdate with “disallowed_by_ccs_entities_on: [entityType: <any_type_except_Integer>, entityId: <any_type_except_Integer>]” -> of "<functional grouping>" -> from "functional_groupings" section
SDL must
a. consider this PTU as invalid
b. do not merge this invalid PTU to LocalPT.

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
  
-- Case 1: Update PT with invalid structure of disallowed_by_ccs_entities_on but local policy table does not contain disallowed_by_ccs_entities_on
common_functions_for_crq_22736:Precondition_StartSdlWithout_disallowed_by_ccs_entities_on("Precondition_StartSdlWithout_disallowed_by_ccs_entities_on")

-- Verify cases entityType parameter is invalid
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
  common_functions:CheckNewParameterInPolicyUpdate(test_case_id, test_data.parent_item, testing_value, test_data.entityType.sdl_query, false, test_data.entityType.error_message)  
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
  common_functions:CheckNewParameterInPolicyUpdate(test_case_id, test_data.parent_item, testing_value, test_data.entityID.sdl_query, false, test_data.entityID.error_message)  
end



-- Case 2: Update PT with invalid structure of disallowed_by_ccs_entities_on but local policy table has already contained disallowed_by_ccs_entities_on
common_functions_for_crq_22736:Precondition_StartSdlWith_disallowed_by_ccs_entities_on("Precondition_StartSdlWith_disallowed_by_ccs_entities_on")
local sdl_query = "select entity_type, entity_id from entities, functional_group where entities.group_id = functional_group.id and entities.entity_Type ="..test_data.entityType.valid_value.. " ".. "and".. " ".. "entities.entity_id="..test_data.entityID.valid_value
-- Verify cases entityType parameter is invalid
for i=1,#test_data.entityType.invalid_values do
  local testing_value = {
    disallowed_by_ccs_entities_on = {{
      entityType = test_data.entityType.invalid_values[i].value,
      entityID = test_data.entityID.valid_value
    }}
  }
  local test_case_id = "TC_entityType_" .. tostring(i)
  local test_case_name = test_case_id .. "_disallowed_by_ccs_entities_on.entityType_" .. test_data.entityType.invalid_values[i].description
  local test_case_name = test_case_id .. "_disallowed_by_ccs_entities_on.entityType_"
  common_functions:AddEmptyTestForNewTestCase(test_case_name)
  common_functions:CheckNewParameterInPreloadedPt(test_case_id, test_data.parent_item, testing_value, sdl_query, true, test_data.entityType.error_message)  
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
  common_functions:CheckNewParameterInPolicyUpdate(test_case_id, test_data.parent_item, testing_value, sdl_query, true, test_data.entityID.error_message)  
end



-------------------------------------- Postconditions ----------------------------------------
Test["Postcondition_restore_sdl_preloaded_pt.json"] = function(self)
	common_functions:RestoreFile("sdl_preloaded_pt.json")
end