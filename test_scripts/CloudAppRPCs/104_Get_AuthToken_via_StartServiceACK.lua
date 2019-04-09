---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0158-cloud-app-transport-adapter.md
-- Description: Activation of Cloud App sequence. Succeed sequence.
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
--    - Connect to Cloud application server using endpoint of cloudApp_1 from policy table
-- 2) In case:
--    - Cloud application server starts mobile session with RPC service
--    SDL does:
--    - Respond to Cloud application server with StartServiceACK with authToken in BSON payload
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/CloudAppRPCs/commonCloudAppRPCs')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
if not common.setP5Configuration() then
  runner.skipTest("'bson4lua' library is not available in ATF")
end
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

local authToken = "Auth3142Token"

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
  policyAppParams.auth_token = authToken
  policyAppParams.icon_url  = "https://noiconurl.org"
  policyAppParams.cloud_transport_type = "WS"
  policyAppParams.hybrid_app_preference = "CLOUD"

  pt.app_policies[appParams[1].fullAppID] = policyAppParams
end

local function activateCloudApp(pAppParams)
  local function getAuthToken(pData)
    local payload = common.bson.to_table(pData.binaryData)
    return payload.authToken.value
  end

  local appParams = common.app.getParams(1)
  for k, v in pairs(pAppParams) do
    appParams[k] = v
  end

  common.hmi.getConnection():SendRequest("SDL.ActivateApp", {appID = common.getCloudAppHmiId(appParams.appName)})
  common.mobile.getConnection(1):ExpectEvent(common.connectedEvent, "Connected")
  :Do(function()
    common.mobile.createSession(1, 1):StartService(7)
    :ValidIf(function(_, data)
      local actualAuthToken = getAuthToken(data)
      if actualAuthToken ~= authToken then
        return false, " Auth token: " .. tostring(actualAuthToken) .. "is invalid. Expected: "
            .. authToken .. ", Actual: " .. actualAuthToken
      end
      return true
      end)
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start cloud application server", common.mobile.createConnection,
    {1, cloudServerParams.host, cloudServerParams.port, "CLOUD"})
runner.Step("Add CloudApp into SDL policy table", common.modifyPreloadedPt, {addCloudAppIntoPT})
runner.Step("Start SDL, HMI", common.startWithoutMobile)

runner.Title("Test")
runner.Step("Retrieving of authToken during Activate CloudApp from HMI", activateCloudApp, {appParams[1]})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
