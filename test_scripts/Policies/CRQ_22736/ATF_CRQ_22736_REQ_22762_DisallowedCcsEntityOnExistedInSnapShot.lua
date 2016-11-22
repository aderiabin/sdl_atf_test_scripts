--[[This script covers requirement APPLINK-22762: [Policies] CCS: PreloadedPT with "disallowed_by_ccs_entities_on" structure
In case
SDL trigger to create SnapShot file from PreloadedPT with “disallowed_by_ccs_entities_on: [entityType: <Integer>, entityId: <Integer>]” -> of "<functional grouping>" -> from "functional_groupings" section
SDL must
a. consider this PreloadedPT as valid (with the pre-conditions of all other valid PreloadedPT content)
b. include "disallowed_by_ccs_entities_on: [entityType: <Integer>, entityId: <Integer>]" field of the corresponding "<functional grouping>" in the SnapShot file.

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

-- Verify case disallowed_by_ccs_entities_on parameter is existed
local test_case_id = "TC_1"
local test_case_name = test_case_id .. ": disallowed_by_ccs_entities_on is existed in Preloaded_PT.json"
common_functions:AddEmptyTestForNewTestCase(test_case_name)

local error_message = "'disallowed_by_ccs_entities_on' is not saved in SnapShot although it is existed in PreloadedPT"
local testing_value = {
	disallowed_by_ccs_entities_on = {{
		entityType = 100,
		entityID = 20
	}}
}


common_functions:CheckNewParameterExistedInSnapShot(test_case_id, test_data.parent_item, file_name, testing_value, true, error_message) 

-------------------------------------- Postconditions ----------------------------------------
Test["Postcondition_RestoreDefaultPreloadedPt"] = function (self)
	common_functions:RestoreFile("sdl_preloaded_pt.json")	
end