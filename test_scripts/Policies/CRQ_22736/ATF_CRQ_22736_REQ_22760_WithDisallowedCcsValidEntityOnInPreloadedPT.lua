--[[This script covers requirement APPLINK-22760: [Policies] CCS: PreloadedPT with "disallowed_by_ccs_entities_on" structure with valid type of parameters
In case
SDL uploads PreloadedPolicyTable (either as result of first SDL run, or after PreloadedPT update, or after FactoryDefaults) with “disallowed_by_ccs_entities_on: [entityType: <any_Type_except_Integer>, entityId: <any_Type_except_Integer>]” -> of "<functional grouping>" -> from "functional_groupings" section
SDL must
a. consider this PreloadedPT as valid
b. start SDL successfully
c. add "disallowed_by_ccs_entities_on" in LPT

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
  
-- Verify cases entityType and entity_id parameters are valid

for i=1,#test_data.entityType.valid_values do
  for j=1, #test_data.entityID.valid_values do
    local testing_value = {
      disallowed_by_ccs_entities_on = {{
        entityType = test_data.entityType.valid_values[i].value,
        entityID = test_data.entityID.valid_values[j].value
      }}
    }
    local test_case_id = "TC_entityType_" .. tostring(i).."TC_entityTID_" .. tostring(j)
    local test_case_name = test_case_id .. "_disallowed_by_ccs_entities_on.entityType_" .. test_data.entityType.valid_values[i].description .. test_data.entityID.valid_values[j].description
    common_functions:AddEmptyTestForNewTestCase(test_case_name)
    local sdl_query = "select entity_type, entity_id from entities, functional_group where entities.group_id = functional_group.id and entities.entity_Type ="..test_data.entityType.valid_values[i].value.. " ".. "and".. " ".. "entities.entity_id="..test_data.entityID.valid_values[j].value
    common_functions:CheckNewParameterInPreloadedPt(test_case_id, test_data.parent_item, testing_value, sdl_query, false, test_data.entityType.error_message)  
  end
end
-------------------------------------- Postconditions ----------------------------------------
Test["RestoreFile"] = function (self)
  common_functions:RestoreFile("sdl_preloaded_pt.json")
end