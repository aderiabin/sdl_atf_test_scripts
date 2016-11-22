--[[This script covers requirement APPLINK-22759: [Policies] CCS: PTU without "disallowed_by_ccs_entities_on" structure
In case
SDL receives PolicyTableUpdate without “disallowed_by_ccs_entities_on: [entityType: <Integer>, entityId: <Integer>]” -> of "<functional grouping>" -> from "functional_groupings" section
SDL must
a. consider this PTU as valid (with the pre-conditions of all other valid PTU content)
b. do not create this "disallowed_by_ccs_entities_on" field of the corresponding "<functional grouping>" in the Policies database.

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

-- Case 1: Update PT without disallowed_by_ccs_entities_on but local policy table does not contain disallowed_by_ccs_entities_on
-- Verify case disallowed_by_ccs_entities_on parameter is omitted
local test_case_id = "TC_1:"
local test_case_name = test_case_id .. " disallowed_by_ccs_entities_on is omitted in PolicyTableUpdate"
common_functions:AddEmptyTestForNewTestCase(test_case_name)
local sdl_query =  "select entity_type, entity_id from entities, functional_group where entities.group_id = functional_group.id"
local error_message = "error_message"
common_functions_for_crq_22736:Precondition_StartSdlWithout_disallowed_by_ccs_entities_on("Precondition_WithoutEntityOnInPreloadedPT")
common_functions:CheckNewParameterOmittedInPolicyUpdate(test_case_id, test_data.parent_item, {"disallowed_by_ccs_entities_on"}, sdl_query, false, error_message)  


-- Case 2: Update PT without disallowed_by_ccs_entities_on but local policy table has already contained disallowed_by_ccs_entities_on
-- Verify case disallowed_by_ccs_entities_on parameter is omitted
local test_case_id = "TC_2:"
local test_case_name = test_case_id .. " disallowed_by_ccs_entities_on is existed in PreloadedPT"
common_functions:AddEmptyTestForNewTestCase(test_case_name)
local sdl_query = "select entity_type, entity_id from entities, functional_group where entities.group_id = functional_group.id and entities.entity_Type ="..test_data.entityTypes.valid_value.. " ".. "and".. " ".. "entities.entity_id="..test_data.entityID.valid_value
local error_message = "error_message"
common_functions_for_crq_22736:Precondition_StartSdlWith_disallowed_by_ccs_entities_on("Precondition_WithEntityOnInPreloadedPT")
common_functions:CheckNewParameterOmittedInPolicyUpdate(test_case_id, test_data.parent_item, {"disallowed_by_ccs_entities_on"}, sdl_query, false, error_message)  


-------------------------------------- Postconditions ----------------------------------------
Test["Postcondition_restore_sdl_preloaded_pt.json"] = function(self)
	common_functions:RestoreFile("sdl_preloaded_pt.json")
end



