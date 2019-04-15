---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0158-cloud-app-transport-adapter.md
-- Description: Activation of Cloud App sequence. Retry sequence success.
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
--    - Cloud application server starts inbound CloudAppRetryTimeout * CloudAppMaxRetryAttempts timeout
--    SDL does:
--    - Connect to Cloud application server
--    - Send UpdateAppList(appID: hmiAppId_1, CloudConnectionStatus: CONNECTED) to HMI
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

local iniParameters = {
  CloudAppRetryTimeout = 2000,
  CloudAppMaxRetryAttempts = 4
}

local tollerance = 200

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

local function modifySDLIni(pIniParameters)
  for paramName, paramValue in pairs(pIniParameters) do
    common.sdl.setSDLIniParameter(paramName, paramValue)
  end
end

local function retryToConnectSuccess(pAppParams, pRetryTimeout, pRetryAttempts)
  local function startCloudApp()
    local cloudConnection, cloudTransport = common.createCloudConnection(1, cloudServerParams.host, cloudServerParams.port)
    cloudConnection:ExpectEvent(common.connectedEvent, "Connected")
    cloudTransport:Listen()

  end

  local delta = math.floor(pRetryTimeout / 10)
  local delayBeforeStartCloud = (pRetryAttempts - 2) * pRetryTimeout + delta
  local expectedConnectionTime = (pRetryAttempts - 1) * pRetryTimeout
  local startTime = 0

  local cloudAppHmiId = common.getCloudAppHmiId(pAppParams.appName)
  common.hmi.getConnection():ExpectRequest("BasicCommunication.UpdateAppList",
      {applications = {{appID = cloudAppHmiId, cloudConnectionStatus = "RETRY"}}},
      {applications = {{appID = cloudAppHmiId, cloudConnectionStatus = "CONNECTED"}}}):Times(2)
  :Do(function(_, data)
      common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :ValidIf(function(exp, _)
      if exp.occurences == 2 then
        local connectionTime = timestamp()

        local actualConnectionTime = math.abs(connectionTime - startTime)
        print("expectedConnectionTime: " .. expectedConnectionTime .. " actualConnectionTime: " .. actualConnectionTime)
        if math.abs(expectedConnectionTime - actualConnectionTime) > tollerance then
          return false, "Wrong length of retry timeout for connect to cloud app server. Expected: " .. expectedConnectionTime
              .. ", Actual: " .. actualConnectionTime
        end
      end
      return true
    end)
  common.hmi.getConnection():SendRequest("SDL.ActivateApp", {appID = cloudAppHmiId})
  startTime = timestamp()
  common.run.runAfter(startCloudApp, delayBeforeStartCloud)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set cloud app retry parameters in INI", modifySDLIni, {iniParameters})
runner.Step("Add CloudApp into SDL policy table", common.modifyPreloadedPt, {addCloudAppIntoPT})
runner.Step("Start SDL, HMI", common.startWithoutMobile)

runner.Title("Test")
runner.Step("Check connection to cloud app server during retry sequence", retryToConnectSuccess,
    {appParams[1], iniParameters.CloudAppRetryTimeout, iniParameters.CloudAppMaxRetryAttempts})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
