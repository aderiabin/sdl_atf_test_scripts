---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0158-cloud-app-transport-adapter.md
-- Description: Activation of Cloud App secure connection sequence. Succeed sequence.
--
--  Precondition:
--  1) SDL is started with enabled cloud application cloudApp_1 in local policy table
--  2) HMI is started and receives information about enabled cloud application
--     (Application with hmiAppId_1 represents cloudApp_1 on HMI )
--  3) Cloud application server is started and waits connection from SDL
--
-- Steps:
-- 1) In case:
--    - HMI sends request SDL.ActivateApp (appID: hmiAppId_1) to SDL
--    SDL does:
--    - Connect securely to Cloud application server using endpoint of cloudApp_1 and certificate from policy table
--    - Send UpdateAppList(appID: hmiAppId_1, CloudConnectionStatus: CONNECTED) to HMI
-- 2) In case:
--    - Cloud application server starts mobile session with RPC service
--    SDL does:
--    - Respond to Cloud application server with StartServiceAck
-- 3) In case:
--    - Cloud application server sends RegisterAppInterface request
--    SDL does:
--    - Send response on RegisterAppInterface(SUCCESS) to Cloud application server
--    - Send notification OnHMIStatus(hmiLevel : NONE) to Cloud application server
--    - Send notification BasicCommunication.OnAppRegistered to HMI
--    - Send response on SDL.ActivateApp with SUCCESS resultcode to HMI
--    - Send notification OnHMIStatus(hmiLevel : FULL) to Cloud application server
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
    appID = "spt",
    fullAppID = "spt"
  }
}

local cloudServerParams = {
  host = "127.0.0.1",
  port = 5432,
  protocol = "wss",
  certPath = "./files/cloud_app_wss/cert.pem",
  keyPath = "./files/cloud_app_wss/privatekey.key",
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
  policyAppParams.cloud_transport_type = "WSS"
  policyAppParams.hybrid_app_preference = "CLOUD"
  -- This is certificate which SDL use to validate cloud application certificate
  policyAppParams.certificate = [[-----BEGIN CERTIFICATE-----
MIID2TCCAsGgAwIBAgIJAONGdmNf2pYrMA0GCSqGSIb3DQEBCwUAMIGCMQswCQYD
VQQGEwJVQTEPMA0GA1UECAwGT2Rlc3NhMQ8wDQYDVQQHDAZPZGVzc2ExDzANBgNV
BAoMBkx1eG9mdDERMA8GA1UECwwIRm9yZCBUQ04xDTALBgNVBAMMBEZUQ04xHjAc
BgkqhkiG9w0BCQEWD2Z0Y25AbHV4b2Z0LmNvbTAeFw0xOTA0MTExOTI0NTJaFw0y
MjA0MTAxOTI0NTJaMIGCMQswCQYDVQQGEwJVQTEPMA0GA1UECAwGT2Rlc3NhMQ8w
DQYDVQQHDAZPZGVzc2ExDzANBgNVBAoMBkx1eG9mdDERMA8GA1UECwwIRm9yZCBU
Q04xDTALBgNVBAMMBEZUQ04xHjAcBgkqhkiG9w0BCQEWD2Z0Y25AbHV4b2Z0LmNv
bTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAOiyiXJo+qC1YbcLkaT4
B2IZb8GlpyfSiX1KPoMHcB0YiPRr4snjbiaJVs1lRJb8+N96uE4hn1NYuUqngeRP
1U9Me1lSqt0l0byASjppykRIz7CHElKx9tfHmL5syi58KbNNjARGMh0aKx7jzFaw
k4Q3RjTedXqVTLwJDgTDbgyVedM2Wj+PluCo9LHbITC7kPw4U73wi18GOj63thk3
rBAfmASriYlNsD+5ucbGEWUdVz7iBymq6fEwaP3wm0dQOfbXfno4zDtw37OYxbBz
RprwvxiXBDXapu45o/OBk3REQJDvA+Kt94SP7pc/ToS2tHAJPIjanEoCgVLv58pj
tzUCAwEAAaNQME4wHQYDVR0OBBYEFLwY3+JDOAB2ZhEwoS91aFdHeWGcMB8GA1Ud
IwQYMBaAFLwY3+JDOAB2ZhEwoS91aFdHeWGcMAwGA1UdEwQFMAMBAf8wDQYJKoZI
hvcNAQELBQADggEBAJzCTsRtiFCD8Gh+IA6unogHccqQohIQwlpsZdfC0/4raJuC
/w2KwxplTlkilLqYU/oSzQUJ0bjVnc5o/21adVwQbAAWq05XdyBp9Gn04vgsGhuz
qP4sBYPh2Neb3I1qDreBwxdVCP90AnO9la63NscswPvzqtqfkWEHL2mvcDVj9uwR
6Hph/HRSu0dFVth5yPzZTxr6WOfOFO8I0ZKb8z2qHb99Oai2AbtKDW8e2aiN7Xq3
CyYDqNBTdqj1vbeijlIAbVSEdyJ1ze7TeHr5AEdHsEyyc7FULPmoiDlqd6x3jV7S
adPbB8t/CF9qKNB9vAHwC8DOaJmHUzW1/MsT+cQ=
-----END CERTIFICATE-----
]]

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
runner.Step("Start cloud application server in secure mode", common.mobile.createConnection,
    {1, cloudServerParams.host, cloudServerParams.port, "CLOUD",
        {isSecured = true, certPath = cloudServerParams.certPath, keyPath = cloudServerParams.keyPath}})
runner.Step("Add CloudApp into SDL policy table", common.modifyPreloadedPt, {addCloudAppIntoPT})
runner.Step("Start SDL, HMI", common.startWithoutMobile)

runner.Title("Test")
runner.Step("Activate CloudApp from HMI", activateCloudApp, {appParams[1]})


runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
