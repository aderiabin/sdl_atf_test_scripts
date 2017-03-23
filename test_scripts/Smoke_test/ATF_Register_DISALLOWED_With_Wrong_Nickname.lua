---------------------------------------------------------------------------------------------
-- Requirement summary: 
-- [APPLINK-16252]: [RegisterAppInterface] DISALLOWED app`s nickname does not match ones listed in Policy Table

-- Description:
-- PoliciesManager must disallow the app`s registration IN CASE the app`s nickname does not match those listed in Policy Table under the appID this app registers with.

-- Preconditions:
-- 1. Local Policy Table has section <appID=12345> in "app_policies"
-- 2. section <appID> has sub-section "nicknames": ["Ford","FordMotorCompany", "FordFocus""]

-- Steps:
-- 1. Mob -> SDL: Start mobile app with the name "Avevo" and appID = 12345 ( different value in PT).

-- Expected result:
-- SDL -> Mob: RegisterAppInterface(DISALLOWED, success:false)
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

common_steps:AddNewTestCasesGroup("Tests") 

-- Register with appName not listed in nicknames of app_policies
function Test:Register_App_With_Wrong_Nickname_DISALLOWED()
	local cor_id = self.mobileSession:SendRPC("RegisterAppInterface",
	{
		syncMsgVersion = 
		{ 
			majorVersion = 3,
			minorVersion = 1
		}, 
		appName ="Avevo",
		isMediaApplication = true,
		languageDesired ="EN-US",
		hmiDisplayLanguageDesired ="EN-US",
		appID ="12345"
	})
	EXPECT_RESPONSE(cor_id, { success = false, resultCode = "DISALLOWED"})
end

common_steps:AddNewTestCasesGroup("Postconditions")
common_steps:StopSDL("Postconditions_StopSDL")
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")
