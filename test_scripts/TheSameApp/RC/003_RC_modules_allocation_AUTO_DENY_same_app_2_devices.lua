---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Description: RC modules allocation in AUTO_DENY mode for the same applications that are registered
--  on two mobile devices
--
-- Precondition:
-- 1)SDL and HMI are started
-- 2)Mobile №1 and №2 are connected to SDL and are consented
-- 3)RC Application (HMI type = REMOTE_CONTROL) App1 is registered on Mobile №1 and Mobile №2
--   (two copies of one application)
--   App1 from Mobile №1 has hmiAppId_1 on HMI, App1 from Mobile №2 has hmiAppId_2 on HMI
-- 4)Remote control settings are: allowed:true, mode: AUTO_DENY
-- 5)RC module RADIO allocated to App1 on Mobile №1
--   RC module CLIMATE allocated to App1 on Mobile №2
--   RC module LIGHT is free
-- In case:
-- 1)Application App1 from Mobile №2 activates and sends to SDL valid SetInteriorVehicleData (module: RADIO)
--   RPC request to reallocate RADIO module
-- 2)Application App1 from Mobile №2 activates and sends to SDL valid SetInteriorVehicleData (module: LIGHT)
--   RPC request to allocate LIGHT module
-- SDL does:
-- 1)Send SetInteriorVehicleData(resultCode = IN_USE) response to App1 on Mobile №2
--   Not send OnRCStatus notification to App1 on Mobile №1
--   Not send OnRCStatus notification to App1 on Mobile №2
--   Not send RC.OnRCStatus notification to HMI
--   Not send RC.OnRCStatus notification to HMI
-- 2)Send SetInteriorVehicleData(resultCode = SUCCESS) response to App1 on Mobile №1
--   Send OnRCStatus(allocatedModules:(RADIO), freeModules: ()) notification to App1 on Mobile №1
--   Send OnRCStatus(allocatedModules:(CLIMATE, LIGHT), freeModules: ()) notification to App1 on Mobile №2
--   Send RC.OnRCStatus(appId: hmiAppId_1, allocatedModules:(RADIO), freeModules: ()) notification to HMI
--   Send RC.OnRCStatus(appId: hmiAppId_2, allocatedModules:(CLIMATE, LIGHT), freeModules: ()) notification to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/TheSameApp/commonTheSameApp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Data ]]
local devices = {
  [1] = { host = "1.0.0.1", port = config.mobilePort },
  [2] = { host = "192.168.100.199", port = config.mobilePort }
}

local appParams = {
  [1] = {
    syncMsgVersion =
    {
      majorVersion = 5,
      minorVersion = 0
    },
    appName = "Test Application",
    isMediaApplication = false,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appHMIType = { "REMOTE_CONTROL" },
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
  }
}

--[[ Local Functions ]]
local function modificationOfPreloadedPT(pPolicyTable)
  local pt = pPolicyTable.policy_table
  pt.functional_groupings["DataConsent-2"].rpcs = common.json.null

  local policyAppParams = common.cloneTable(pt.app_policies["default"])
  policyAppParams.AppHMIType = appParams[1].appHMIType
  policyAppParams.moduleType = { "RADIO", "CLIMATE", "LIGHT" }
  policyAppParams.groups = { "Base-4", "RemoteControl" }

  pt.app_policies[appParams[1].fullAppID] = policyAppParams
end

local function inUseModuleApp1Dev2()
  common.hmi.getConnection():ExpectNotification("RC.OnRCStatus"):Times(0)
  common.mobile.getSession(1):ExpectNotification("OnRCStatus"):Times(0)
  common.mobile.getSession(2):ExpectNotification("OnRCStatus"):Times(0)
  common.rpcDenied("RADIO", 2, "IN_USE")
end

local function allocateModuleApp1Dev2()
  local pHmiExpDataTable = {
    [common.app.getHMIId(1)] = {allocatedModules = {"RADIO"}, freeModules = {}, allowed = true},
    [common.app.getHMIId(2)] = {allocatedModules = {"CLIMATE", "LIGHT"}, freeModules = {}, allowed = true}
  }
  common.expectOnRCStatusOnHMI(pHmiExpDataTable)
  common.expectOnRCStatusOnMobile(1, {allocatedModules = {"RADIO"}, freeModules = {}, allowed = true})
  common.expectOnRCStatusOnMobile(2, {allocatedModules = {"CLIMATE", "LIGHT"}, freeModules = {}, allowed = true})
  common.rpcAllowed(2, "LIGHT")
end


--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Prepare preloaded PT", common.modifyPreloadedPt, {modificationOfPreloadedPT})
runner.Step("Start SDL and HMI", common.start)
runner.Step("Set AccessMode AUTO_DENY", common.defineRAMode, { true, "AUTO_DENY" })
runner.Step("Connect two mobile devices to SDL", common.connectMobDevices, {devices})
runner.Step("Register App1 from device 1", common.registerAppEx, {1, appParams[1], 1})
runner.Step("Register App1 from device 2", common.registerAppEx, {2, appParams[1], 2})
runner.Step("Activate App1 from Device 1", common.activateApp, {1})
runner.Step("App1 on Device 1 successfully allocates module RADIO", common.rpcAllowed, {1, "RADIO"})
runner.Step("Activate App1 from Device 2", common.activateApp, {2})
runner.Step("App1 on Device 2 successfully allocates module CLIMATE", common.rpcAllowed, {2, "CLIMATE"})

runner.Title("Test")
runner.Step("App1 on Device 2 denied to allocate module RADIO (IN_USE)", inUseModuleApp1Dev2)
runner.Step("App1 on Device 2 successfully allocates module LIGHT", allocateModuleApp1Dev2)

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
