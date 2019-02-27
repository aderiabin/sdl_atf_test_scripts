---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Description: Registration of two mobile apps from different devices having different appIDs and same appNames.
-- App_1 uses name from its "nickname" field,
-- App_2 has no "nickname"
--   Precondition:
-- 1) PT contains entity ( appID = 1, nicknames = "Test Application" )
-- 2) SDL and HMI are started
-- 3) Mobile №1 and №2 are connected to SDL
--   Steps:
-- 1) Mobile №1 sends RegisterAppInterface request (appID = 1, appName = "Test Application") to SDL
--   CheckSDL:
--     SDL sends RegisterAppInterface response( resultCode = SUCCESS  ) to Mobile №1
--     BasicCommunication.OnAppRegistered(...) notification to HMI
-- 2) Mobile №2 sends RegisterAppInterface request (appID = 2, appName = "Test Application") to SDL
--   CheckSDL:
--     SDL sends RegisterAppInterface response( resultCode = SUCCESS  ) to Mobile №2
--     BasicCommunication.OnAppRegistered(...) notification to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/TheSameApp/commonTheSameApp')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local json = require("modules/json")
local utils = require('user_modules/utils')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Data ]]
local devices = {
  [1] = { host = "1.0.0.1",         port = config.mobilePort },
  [2] = { host = "192.168.100.199", port = config.mobilePort }
}

local appParams = {
	[1] = { appName = "Test Application", appID = "0001",  fullAppID = "0000001" },
	[2] = { appName = "Test Application", appID = "00022", fullAppID = "00000022" }
}

local preloadedPT = commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")

--[[ Local Functions ]]
local function setNickname()
  local preloadedFile = commonPreconditions:GetPathToSDL() .. preloadedPT
  local pt = utils.jsonFileToTable(preloadedFile)

  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  pt.policy_table.app_policies["0000001"] = utils.cloneTable(pt.policy_table.app_policies.default)
  pt.policy_table.app_policies["0000001"].nicknames = { "Test Application" }
  utils.tableToJsonFile(pt, preloadedFile)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update of the default PT", setNickname)
runner.Step("Start SDL and HMI", common.start)
runner.Step("Connect two mobile devices to SDL", common.connectMobDevices, {devices})

runner.Title("Test")
runner.Step("Register App1 from device 1", common.registerAppEx, {1, appParams[1], 1})
runner.Step("Register App2 from device 2", common.registerAppEx, {2, appParams[2], 2})

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
