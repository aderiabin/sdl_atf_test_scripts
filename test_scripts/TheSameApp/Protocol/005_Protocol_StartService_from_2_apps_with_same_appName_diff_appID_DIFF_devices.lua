---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
-- Description: Registration of two mobile applications with the same appIDs and appNames which are match to the
-- nickname contained in PT from different mobiles.
--   Precondition:
--   Precondition:
-- 1) SDL and HMI are started
-- 2) Mobile №1 and №2 are connected to SDL
-- 3) Mobile №1 sends RegisterAppInterface request (appID = 0001,  appName = "Test Application", api version = 4.5)
-- to SDL
-- 4) Mobile №2 sends RegisterAppInterface request (appID = 00022, appName = "Test Application", api version = 5.0)
-- to SDL
--   In case:
-- 1) Mobile №1 App1 send StartService request for Video streaming
--   CheckSDL:
--     responds with StartServiceNACK to Mobile №1
-- 2) Mobile №2 App2 send StartService request for Video streaming
--   CheckSDL:
--     sends Navigation.StartStream Video streaming request to HMI
--     responds with StartServiceACK to Mobile №2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
require('atf.util')
local test = require("user_modules/dummy_connecttest")
local runner = require('user_modules/script_runner')
local common = require('test_scripts/TheSameApp/commonTheSameApp')
local events = require('events')
local Event = events.Event
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")
local utils = require('user_modules/utils')
-- local common = require('test_scripts/TheSameApp/Security/commonSecurity')
local constants = require('protocol_handler/ford_protocol_constants')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

config.defaultProtocolVersion = 2

--[[ Local Data ]]
local m = {}
m.frameInfo   = constants.FRAME_INFO
m.frameType   = constants.FRAME_TYPE
m.serviceType = constants.SERVICE_TYPE

local devices = {
  [1] = { host = "1.0.0.1",         port = config.mobilePort },
  [2] = { host = "192.168.100.199", port = config.mobilePort }
}

local appParams = {
  [1] = { syncMsgVersion     = { majorVersion = 2, minorVersion = 0 },
          isMediaApplication = true,
          appName            = "Test Application",
          appID              = "0001",
          fullAppID          = "0000001"
        },
  [2] = { syncMsgVersion     = { majorVersion = 3, minorVersion = 0 },
          isMediaApplication = true,
          appName            = "Test Application",
          appID              = "00022",
          fullAppID          = "00000022"
        }
}

--[[ Local Functions ]]
-- local function StartVideoServiceNACK(pAppId)
--   local mobSession = common.getMobileSession(pAppId)
--   mobSession:StartService( 11 )
--   -- mobSession:ExpectControlMessage
-- end

local function StartVideoService(pAppId)
  local mobSession = common.getMobileSession(pAppId)
  mobSession:StartService( 11 )
  :ValidIf(function(_, data)
      if data.frameInfo == common.frameInfo.START_SERVICE_ACK then
        print("\t   --> StartService ACK received")
        return true
      else
        return false, print("\t   --> StartService NACK received")
      end
    end)
  common.hmi.getConnection():ExpectNotification("Navigation.StartStream")
    :Do(function(_,data)
      common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
end

local function startVideoServiceNACK()
  -- local startServiceMessage =
  -- {
  --   serviceType = m.serviceType.VIDEO,
  --   frameInfo =  m.frameInfo.START_SERVICE,
  --   sessionId = self.mobileSession.sessionId,
  --   frameType = m.frameType.CONTROL_FRAME
  -- }

  local startServiceEvent = Event()
  startServiceEvent.matches = function(_, data)
    return data.frameType == m.frameInfo.CONTROL_FRAME --and
         -- data.sessionId == common.getMobileSession().SessionId.get()-- and --.get()
        --  data.serviceType == m.serviceType.VIDEO and
        -- (data.frameInfo == m.frameInfo.START_SERVICE_NACK or
        --  data.frameInfo == m.frameInfo.START_SERVICE_ACK)
  end

  -- Send Video service start from mobile app to SDL
  -- Expect StartServiceNACK on mobile app from SDL, it means service is not started
  local ret = common.getMobileSession():ExpectEvent(startServiceEvent, "Expect StartServiceNACK")
  ret:ValidIf(function(_, data)
      if data.frameInfo == m.frameInfo.START_SERVICE_NACK then
        return true
      else
        return false, "StartService ACK received"
      end
    end)

  common.getMobileSession():Send({
      serviceType = m.serviceType.VIDEO,
      frameInfo = m.frameInfo.START_SERVICE,
      frameType = m.frameType.CONTROL_FRAME
    })

  -- self:Send(startServiceMessage)
  -- commonTestCases.delayedExp()
  return ret
end

local function TestFunc ()
  -- utils.printTable(common.getMobileSession())
  print(tostring(common.getMobileSession().SessionId.get()))

end
-- function delayedExp(timeout)
--   if not timeout then timeout = commonDefect.timeout end
--   commonTestCases:DelayedExp(timeout)
-- end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL and HMI", common.start)
runner.Step("Connect two mobile devices to SDL", common.connectMobDevices, {devices})
runner.Step("Register App1 from device 1", common.registerAppEx, { 1, appParams[1], 1 })
runner.Step("Set protocol version to 3", common.setProtocolVersion, { 3 })
runner.Step("Register App2 from device 2", common.registerAppEx, { 2, appParams[2], 2 })

runner.Title("Test")
runner.Step("Activate App 1", common.app.activate, { 1 })
-- runner.Step("sdfdsds", TestFunc)
runner.Step("App1 from Mobile 1 requests StartService request for Video streaming", startVideoServiceNACK, { })
runner.Step("Activate App 2", common.app.activate, { 2 })
runner.Step("App2 from Mobile 2 requests StartService request for Video streaming", StartVideoService, { 2 })

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
