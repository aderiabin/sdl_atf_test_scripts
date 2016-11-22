--[[This script covers requirement APPLINK-28632: [Policies] CCS: PTU without "ccs_consent_groups" struct
In case
SDL receives PolicyTableUpdate without "ccs_consent_groups: [<functional_grouping>: <Boolean>]” -> of "device_data" -> "<device identifier>" -> "user_consent_records" -> "<app id>" section
SDL must:
a. consider this PTU as valid (with the pre-conditions of all other valid PTU content)
b. do not create this "ccs_consent_groups" field of the corresponding "appID" section in the Policies database.

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
local parent_item = {"policy_table", "module_config"}

local added_json_items = 
[[
{
	"device_data": {
		"HUU40DAS7F970UEI17A73JH32L41K32JH4L1K234H3K4": {
			"user_consent_records": {
				"0000001": {
					"consent_groups": {
						"Location": true
					},
					"input": "GUI",
					"time_stamp": "2015-10-09T18:07:21Z"
				}
			}
		}
	}
}
]]

common_functions:AddItemsIntoJsonFile(config.pathToSDL .. 'sdl_preloaded_pt.json', parent_item, added_json_items)
local test_case_id = "TC_1"
local test_case_name = test_case_id .. ": ccs_consent_groups is existed in PTU file"
common_functions:AddEmptyTestForNewTestCase(test_case_name)
common_functions_for_crq_22736:Precondition_StartSdlWithout_ccs_consent_groups("Precondition_StartSdlWithout_ccs_consent_groups")
common_functions:VerifyPTUFailedWithInvalidData("PtuFailedWhenExistedCcsConsentGroup", "files/ptu_withCcsConsentGroups.json")
common_functions:CheckPolicyTable(test_case_name .. "_CheckPolicyTable", test_data.ccs_consent_groups.sdl_query, false, error_message)

-------------------------------------- Postconditions ----------------------------------------
Test["Postcondition_restore_sdl_preloaded_pt.json"] = function(self)
	common_functions:RestoreFile("sdl_preloaded_pt.json")
end
