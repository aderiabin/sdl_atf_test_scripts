--[[This script covers requirement APPLINK-22761: [Policies] CCS: PreloadedPT without "disallowed_by_ccs_entities_on" structure
In case
SDL uploads PreloadedPolicyTableewithout “disallowed_by_ccs_entities_on: [entityType: <Integer>, entityId: <Integer>]” -> of "<functional grouping>" -> from "functional_groupings" section
SDL must
a. consider this PreloadedPT as valid
b. does not create "disallowed_by_ccs_entities_on" field of the corresponding "<functional grouping>" in LPT.

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
local test_case_name = test_case_id .. " disallowed_by_ccs_entities_on is omitted in PreloadedPT"
common_functions:AddEmptyTestForNewTestCase(test_case_name)
local error_message = "error_message"
common_functions_for_crq_22736:Precondition_StartSdlWithout_disallowed_by_ccs_entities_on("SDL_Starts_WithoutEntityOnInPreloadedPT")
common_functions:CheckNewParameterOmittedInPreloadedPt(test_case_id, test_data.parent_item, testing_value, test_data.entityType.sdl_query, false, test_data.entityType.error_message)  

-------------------------------------- Postconditions ----------------------------------------
Test["Postcondition_restore_sdl_preloaded_pt.json"] = function(self)
	common_functions:RestoreFile("sdl_preloaded_pt.json")
end


