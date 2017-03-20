---------------------------------------------------------------------------------------------
-- Requirement summary: 
-- [APPLINK-19856]: [RegisterAppInterface] Successful nickname validation

-- Description:
-- In case the application sends RegisterAppInterface request with 
-- the "appName" value that is listed in this app's specific policies
-- other valid parameters
-- SDL must:
-- successfully register such application: RegisterAppInterface_response (<applicable resultCode>, success: true)

-- Preconditions:
-- 1. Local Policy Table has section <appID=12345> in "app_policies"
-- 2. section <appID> has sub-section "nicknames": ["Ford", "FordMotorCompany", "FordFocus"]

-- Steps:
-- 1. Mob -> SDL: Start mobile app with the name "Ford" or "FordMotorCompany" or "FordFocus"and appID = 12345 ( different value in PT).

-- Expected result:
-- SDL -> Mob: RegisterAppInterface_response(<applicable resultCode>, *success:true*)
-----------------------------------------------------------------------------------------
require('user_modules/all_common_modules')
------------------------------------------------------------------------------------------
common_steps:AddNewTestCasesGroup("Preconditions")
common_steps:BackupFile("Precondition_BackupPreloadedPT", "sdl_preloaded_pt.json")

function Test:Precondition_Set_NickName_Permissions_For_Specific_AppId()
	local jsonFile = config.pathToSDL .. "sdl_preloaded_pt.json"
	local added_json_items = {}
	added_json_items["12345"] = {
		keep_context = false,
		steal_focus = false,
		priority = "NONE",
		default_hmi = "NONE",
		groups = {
			"Base-4"
		},
		nicknames = {"Ford",
			"FordMotorCompany",
		"FordFocus"}
	}
	common_functions:AddItemsIntoJsonFile(jsonFile, {"policy_table", "app_policies"}, added_json_items)
	-- delay to make sure sdl_preloaded_pt.json is already updated
	common_functions:DelayedExp(1000)
end

-- Start SDL and add new session
common_steps:PreconditionSteps("Precondition", 5)
app_with_Ford_name = common_functions:CreateRegisterAppParameters(
{appID = "12345", appName = "Ford"})
app_with_FordMotorCompany_name = common_functions:CreateRegisterAppParameters(
{appID = "12345", appName = "FordMotorCompany"})
app_with_FordFocus_name = common_functions:CreateRegisterAppParameters(
{appID = "12345", appName = "FordFocus"})

common_steps:AddNewTestCasesGroup("Tests") 
-- Register with specify app in nicknames (FordMotorCompany)
common_steps:RegisterApplication("RegisterApplication_app_with_Ford_name", 
"mobileSession", app_with_Ford_name)
common_steps:UnregisterApp("UnregisterApplication_app_with_Ford_name", "Ford")

-- Register with specify app in nicknames (FordMotorCompany)
common_steps:RegisterApplication("RegisterApplication_app_with_FordMotorCompany_name", 
"mobileSession", app_with_FordMotorCompany_name)
common_steps:UnregisterApp("UnregisterApplication_app_with_FordMotorCompany_name", "FordMotorCompany")

-- Register with specify app in nicknames (FordFocus)
common_steps:RegisterApplication("RegisterApplication_app_with_FordFocus_name", 
"mobileSession", app_with_FordFocus_name)
common_steps:UnregisterApp("UnregisterApplication_app_with_FordFocus_names", "FordFocus")

common_steps:AddNewTestCasesGroup("Postconditions")
common_steps:StopSDL("Postconditions_StopSDL")
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")
