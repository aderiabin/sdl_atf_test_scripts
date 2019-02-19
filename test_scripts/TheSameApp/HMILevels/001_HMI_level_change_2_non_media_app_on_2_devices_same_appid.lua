---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Description: Registration of two mobile applications with the same appName and same appID from different mobile devices
-- Precondition:
-- 1)SDL and HMI are started
-- 2) Mobile №1 and №2 are connected to SDL
-- 3) Application 1 (isMediaApplication = false, appID = 0000001, appName = "Test Application1")  is registered from Mobile №1
-- 4) Application 2 (isMediaApplication = false, appID = 0000001, appName = "Test Application1")  is registered from Mobile №2
-- In case:
-- 1)Activate Application 1
-- 2)Activate Application 2
-- 3)Deactivate Application 2
-- 4)Exit Application 2
-- 5)Activate Application 2
-- SDL does:
-- 1)SDL sends OnHMIStatus(hmiLevel = FULL) to Mobile №1
--   SDL does not send OnHMIStatus to Mobile №2
-- 2)SDL sends OnHMIStatus(hmiLevel = BACKGROUND) to Mobile №1
--   SDL sends OnHMIStatus(hmiLevel = FULL) to Mobile №2
-- 3)SDL does not send OnHMIStatus to Mobile №1
--   SDL sends OnHMIStatus(hmiLevel = BACKGROUND) to Mobile №2
-- 4)SDL does not send OnHMIStatus to Mobile №1
--   SDL sends OnHMIStatus(hmiLevel = NONE) to Mobile №2
-- 5)SDL does not send OnHMIStatus to Mobile №1
--   SDL sends OnHMIStatus(hmiLevel = FULL) to Mobile №2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/TheSameApp/commonTheSameApp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Data ]]
local devices = {
  [1] = { host = "1.0.0.1", port = config.mobilePort },
  [2] = { host = "192.168.100.199", port = config.mobilePort },
}

local appParams = {
  [1] = {
    syncMsgVersion =
    {
      majorVersion = 5,
      minorVersion = 0
    },
    appName = "Test Application1",
    isMediaApplication = false,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appHMIType = { "DEFAULT" },
    appID = "0001",
    fullAppID = "0000001",
    deviceInfo =
    {
      os = "Android",
      carrier = "Megafon",
      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
      osVersion = "4.4.2",
      maxNumberRFCOMMPorts = 1
    }
  },
  [2] = {
    syncMsgVersion =
    {
      majorVersion = 5,
      minorVersion = 0
    },
    appName = "Test Application1",
    isMediaApplication = false,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appHMIType = { "DEFAULT" },
    appID = "0001",
    fullAppID = "0000001",
    deviceInfo =
    {
      os = "Android",
      carrier = "Megafon",
      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
      osVersion = "4.4.2",
      maxNumberRFCOMMPorts = 1
    }
  },
}

--[[ Local Functions ]]
local function activateApp1()
  common.mobile.getSession(2):ExpectNotification("OnHMIStatus"):Times(0)
  common.app.activate(1)
  common.run.wait(10000)
end

local function activateApp2()
  common.mobile.getSession(1):ExpectNotification("OnHMIStatus",
    { hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
  common.app.activate(2)
end

local function deactivateApp2()
  common.mobile.getSession(1):ExpectNotification("OnHMIStatus"):Times(0)
  local app2HMIStatusParams = {
    hmiLevel = "BACKGROUND",
    audioStreamingState = "NOT_AUDIBLE",
    systemContext = "MAIN"
  }
  common.deactivateApp(2, app2HMIStatusParams)
  common.run.wait(10000)
end

local function exitApp2()
  common.mobile.getSession(1):ExpectNotification("OnHMIStatus"):Times(0)
  common.exitApp(2)
  common.run.wait(10000)
end

local function reActivateApp2()
  common.mobile.getSession(1):ExpectNotification("OnHMIStatus"):Times(0)
  common.app.activate(2)
  common.run.wait(10000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL and HMI", common.start)
runner.Step("Connect two mobile devices to SDL", common.connectMobDevices, {devices})
runner.Step("Register App1 from device 1", common.registerAppEx, {1, appParams[1], 1})
runner.Step("Register App2 from device 2", common.registerAppEx, {2, appParams[2], 2})

runner.Title("Test")
runner.Step("Activate App 1", activateApp1)
runner.Step("Activate App 2", activateApp2)
runner.Step("Deactivate App 2", deactivateApp2)
runner.Step("Exit App 2", exitApp2)
runner.Step("Activate App 2 again", reActivateApp2)

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
