---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0158-cloud-app-transport-adapter.md
-- Description: Check application exit with CLOSE_CLOUD_CONNECTION reason for Cloud App
--
--  Precondition:
--  1) SDL is started with enabled cloud application cloudApp_1 in local policy table
--  2) HMI is started and has information about enabled cloud application
--  3) Cloud application server is activated (hmiLevel: FULL)
--
-- Steps:
-- 1) In case:
--    - HMI sends notification BC.OnExitApplication(reason: CLOSE_ClOUD_CONNECTION) to SDL
--    SDL does:
--    - SDL sends notification BC.OnAppUnregistered(appID: cloudApp_1 , unexpectedDisconnect:false) to HMI
--    - Send notification OnAppInterfaceUnregistered(reason: APP_UNAUTHORIZED) to cloud application
--    - Send EndService control message to cloud application
--    - Close connection with Cloud application server
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
    appName = "Cloud X",
    isMediaApplication = true,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appHMIType = { "MEDIA" },
    appID = "1014",
    fullAppID = "0001014"
  }
}

local cloudServerParams = {
  host = "127.0.0.1",
  port = 5000,
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

local function processOnExitApplication()
  local RPC = 7
  local CloudAppId = 1
  local cloudAppHmiId = common.app.getHMIId(CloudAppId)
  local hmiConnection = common.hmi.getConnection()
  hmiConnection:SendNotification("BasicCommunication.OnExitApplication",
      {appID = cloudAppHmiId, reason = "CLOSE_CLOUD_CONNECTION"})
  common.mobile.getSession(CloudAppId):ExpectNotification("OnAppInterfaceUnregistered", {reason = "APP_UNAUTHORIZED"})
  hmiConnection:ExpectNotification("BasicCommunication.OnAppUnregistered",
      {appID = cloudAppHmiId, unexpectedDisconnect = false})
  common.ExpectEndService(CloudAppId,RPC)
  common.mobile.getConnection(CloudAppId):ExpectEvent(common.disconnectedEvent, "Disconnected")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start cloud application server", common.mobile.createConnection,
		{1, cloudServerParams.host, cloudServerParams.port, "CLOUD"})
runner.Step("Add CloudApp into SDL policy table", common.modifyPreloadedPt, {addCloudAppIntoPT})
runner.Step("Start SDL, HMI", common.startWithoutMobile)
runner.Step("Activate CloudApp from HMI", common.activateCloudApp, {1, 1, appParams[1]})

runner.Title("Test")
runner.Step("Exit cloud application", processOnExitApplication)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
