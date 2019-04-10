---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0158-cloud-app-transport-adapter.md
-- Description: Activation of Cloud App sequence. Retry sequence.
--
--  Precondition:
--  1) SDL is started with enabled cloud application cloudApp_1 in local policy table
--  2) HMI is started and receives information about enabled cloud application
--     (Application with hmiAppId_1 represents cloudApp_1 on HMI )
--  3) Cloud application server is not started
--
-- Steps:
-- 1) In case:
--    - HMI sends request SDL.ActivateApp (appID: hmiAppId_1) to SDL
--    SDL does:
--    - Try to connect to Cloud application server using endpoint of cloudApp_1 from policy table
--    - Send UpdateAppList(appID: hmiAppId_1, CloudConnectionStatus: RETRY) to HMI
--    - Start retry sequence with lenth equals CloudAppRetryTimeout * CloudAppMaxRetryAttempts
--      (CloudAppRetryTimeout and CloudAppMaxRetryAttempts are SDL parameters set in smartDeviceLink.ini)
-- 2) In case:
--    - Cloud application server does not start inbound CloudAppRetryTimeout * CloudAppMaxRetryAttempts timeout
--    SDL does:
--    - Stop tries to connect to Cloud application server
--    - Send UpdateAppList(appID: hmiAppId_1, CloudConnectionStatus: NOT_CONNECTED) to HMI
-- 3) In case:
--    - Cloud application server starts after CloudAppRetryTimeout * CloudAppMaxRetryAttempts timeout
--    SDL does:
--    - Does not connect to Cloud application server
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/CloudAppRPCs/commonCloudAppRPCs')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local appParams = {
  [1] = {
    syncMsgVersion =
    {
      majorVersion = 5,
      minorVersion = 1,
      patchVersion = 0
    },
    appName = "Cloud App",
    isMediaApplication = true,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appHMIType = { "MEDIA" },
    appID = "1001",
    fullAppID = "0001001"
  }
}

local cloudServerParams = {
  host = "127.0.0.1",
  port = 5432,
  protocol = "ws",
  getUrl = function(self) return self.protocol .. "://" .. self.host .. ":" .. tostring(self.port) end
}

--[[ Local Functions ]]
local function addCloudAppIntoPT(pPolicyTable)
  local pt = pPolicyTable.policy_table
  pt.functional_groupings["DataConsent-2"].rpcs = common.json.null

  local policyAppParams = common.cloneTable(pt.app_policies["default"])
  policyAppParams.AppHMIType = appParams[1].appHMIType
  policyAppParams.groups = { "Base-4", "CloudApp" }
  policyAppParams.nicknames = {appParams[1].appName}
  policyAppParams.enabled = true
  policyAppParams.endpoint = cloudServerParams:getUrl()
  policyAppParams.auth_token = "Auth3124Token"
  policyAppParams.icon_url  = "https://noiconurl.org"
  policyAppParams.cloud_transport_type = "WS"
  policyAppParams.hybrid_app_preference = "CLOUD"

  pt.app_policies[appParams[1].fullAppID] = policyAppParams
end

local function activateCloudApp(pAppParams)
  local appParams = common.app.getParams(1)
  for k, v in pairs(pAppParams) do
    appParams[k] = v
  end

  local cloudAppHmiId = common.getCloudAppHmiId(appParams.appName)
  local requestId = common.hmi.getConnection():SendRequest("SDL.ActivateApp", {appID = cloudAppHmiId})
  local cloudConnection = common.mobile.getConnection(1)
  local sdlConnectedEvent = cloudConnection:ExpectEvent(common.connectedEvent, "Connected")
  sdlConnectedEvent:Do(function()
    local session = common.mobile.createSession(1, 1)
    session:StartService(7)
    :Do(function()
        local corId = session:SendRPC("RegisterAppInterface", appParams)
        common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
          { application = { appName = appParams.appName } })
        :Do(function(_, d1)
            common.app.setHMIId(d1.params.application.appID, 1)
          end)
        session:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
        :Do(function()
            session:ExpectNotification("OnHMIStatus",
              { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
              { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
              :Times(2)
          end)
      end)
  end)

  common.hmi.getConnection():ExpectRequest("BasicCommunication.UpdateAppList")
  :Times(AnyNumber())
  :Do(function(_, data)
      common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :ValidIf(function(_, data)
      for _, app in ipairs(data.params.applications) do
        if app.appID == cloudAppHmiId then
          if app.cloudConnectionStatus == "CONNECTED" then
            return true
          end
          return false, "cloudConnectionStatus of app: " .. app.appID
              .. " Expected: CONNECTED, Actual: " .. app.cloudConnectionStatus
        end
      end
      return false, "App: " .. cloudAppHmiId .. " is not contained in BC.UpdateAppList request"
    end)

  common.hmi.getConnection():ExpectResponse(requestId, {result = {code = 0, method = "SDL.ActivateApp"}})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start cloud application server", common.mobile.createConnection,
    {1, cloudServerParams.host, cloudServerParams.port, "CLOUD"})
runner.Step("Add CloudApp into SDL policy table", common.modifyPreloadedPt, {addCloudAppIntoPT})
runner.Step("Start SDL, HMI", common.startWithoutMobile)

runner.Title("Test")
runner.Step("Activate CloudApp from HMI", activateCloudApp, {appParams[1]})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
