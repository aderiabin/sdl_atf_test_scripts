---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Description:
-- User consent for functional groups of two consented mobile devices
-- with the same mobile applications registered
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) Mobile №1 and №2 are connected to SDL and are consented
-- 3) RPC SendLocation exists only in Group001 according policies and requires user consent ConsentGroup001
-- 4) Application App1 is registered on Mobile №1 and Mobile №2 (two copies of one application)
--
-- Steps:
-- 1) Applications App1 from both devices (Mobile №1 and Mobile №2) send to SDL valid SendLocation RPC request
--   Check:
--   SDL sends SendLocation(resultCode = DISALLOWED) response to Mobile №1
--   SDL sends SendLocation(resultCode = DISALLOWED) response to Mobile №2
-- 2) User allows ConsentGroup001 for App1 on Mobile №2
-- Applications App1 from both devices (Mobile №1 and Mobile №2) send to SDL valid SendLocation RPC request
--   Check:
--    SDL sends SendLocation(resultCode = DISALLOWED) response to Mobile №1
--    SDL sends SendLocation(resultCode = SUCCESS) response to Mobile №2
-- 3) User allows ConsentGroup001 for App1 on Mobile №1
-- Applications App1 from both devices (Mobile №1 and Mobile №2) send to SDL valid SendLocation RPC request
--   Check:
--    SDL sends SendLocation(resultCode = SUCCESS) response to Mobile №1
--    SDL sends SendLocation(resultCode = SUCCESS) response to Mobile №2
-- 4) User disallows ConsentGroup001 for App1 on Mobile №1
-- Applications App1 from both devices (Mobile №1 and Mobile №2) send to SDL valid SendLocation RPC request
--   Check:
--    SDL sends SendLocation(resultCode = USER_DISALLOWED) response to Mobile №1
--    SDL sends SendLocation(resultCode = SUCCESS) response to Mobile №2
-- 5) User disallows ConsentGroup001 for App1 on Mobile №2
-- Applications App1 from both devices (Mobile №1 and Mobile №2) send to SDL valid SendLocation RPC request
--   Check:
--    SDL sends SendLocation(resultCode = USER_DISALLOWED) response to Mobile №1
--    SDL sends SendLocation(resultCode = USER_DISALLOWED) response to Mobile №2
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
    appName = "Test App",
    isMediaApplication = true,
    appHMIType = { "NAVIGATION" },
    appID = "0008",
    fullAppID = "0000008"
  }
}

local ptFuncGroup = {
  AddCommandGroup = {
    rpcs = {
      AddCommand = {
        hmi_levels = {"FULL", "LIMITED"}
      }
    }
  }
}

local contentData = {
  [1] = {
    addCommand = {
      mob = { cmdID = 1, vrCommands = { "OnlyVR" }},
      hmi = { cmdID = 1, type = "Command", vrCommands = { "OnlyVR" }}
    },
    addSubMenu = {
      mob = { menuID = 1, position = 500, menuName = "NewSubMenu" },
      hmi = { menuID = 1, menuParams = { position = 500, menuName = "NewSubMenu" }}
    }
  },
  [2] = {
    addCommand = {
      mob = { cmdID = 1, vrCommands = { "vrCommand" }},
      hmi = { cmdID = 1, type = "Command", vrCommands = { "vrCommand" }}
    },
    addSubMenu = {
      mob = { menuID = 1, position = 300, menuName = "ReactiveSubMenu" },
      hmi = { menuID = 1, menuParams = { position = 300, menuName = "ReactiveSubMenu" }}
    }
  }
}

--[[ Local Functions ]]
local function modificationOfPreloadedPT(pPolicyTable)
  local pt = pPolicyTable.policy_table

  for funcGroupName in pairs(pt.functional_groupings) do
    if type(pt.functional_groupings[funcGroupName].rpcs) == "table" then
      pt.functional_groupings[funcGroupName].rpcs["AddCommand"] = nil
    end
  end

  pt.functional_groupings["DataConsent-2"].rpcs = common.json.null

  pt.functional_groupings["AddCommandGroup"] = ptFuncGroup.AddCommandGroup

  pt.app_policies[appParams[1].fullAppID] =
      common.cloneTable(pt.app_policies["default"])
  pt.app_policies[appParams[1].fullAppID].groups = {"Base-4"}
end

local function processAddCommand(pAppId, pResultCode)
  local data = common.cloneTable(contentData[pAppId].addCommand)
  data.resultCode = pResultCode
  common.addCommand(pAppId, data)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Prepare preloaded PT", common.modifyPreloadedPt, {modificationOfPreloadedPT})
runner.Step("Start SDL and HMI", common.start)
runner.Step("Connect two mobile devices to SDL", common.connectMobDevices, {devices})
runner.Step("Register App1 from device 1", common.registerAppEx, {1, appParams[1], 1})
runner.Step("Register App1 from device 2", common.registerAppEx, {2, appParams[1], 2})

runner.Title("Test")
runner.Step("Activate App1 from device 1", common.app.activate, {1})
runner.Step("Disallowed AddCommand from App1 from device 1", processAddCommand, {1, "DISALLOWED"})
runner.Step("Activate App2 from device 2", common.app.activate, {2})
runner.Step("Disallowed AddCommand from App1 from device 2", processAddCommand, {2, "DISALLOWED"})
runner.Step("Check count_of_rejected_rpc_calls in PTS", common.checkCounter,
    {appParams[1].fullAppID, "count_of_rejected_rpc_calls", 2})

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
