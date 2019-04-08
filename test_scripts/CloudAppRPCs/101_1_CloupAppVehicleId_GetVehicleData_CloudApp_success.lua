---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0158-cloud-app-transport-adapter.md
-- Description: Check retrieving of cloudAppVehicleID by Cloud App via GetVehicleData RPC
--
--  Precondition:
--  1) SDL is started with enabled cloud application cloudApp_1 in local policy table
--  2) HMI is started and has information about cloudAppVehicleID
--  3) Cloud application server is activated (hmiLevel: FULL)
--
-- Steps:
-- 1) In case:
--    - Cloud application sends request GetVehicleData (cloudAppVehicleID: true) to SDL
--    SDL does:
--    - Send request VehicleInfo.GetVehicleData (cloudAppVehicleID: true) to HMI
-- 2) In case:
--    - HMI sends response VehicleInfo.GetVehicleData with cloudAppVehicleID to SDL
--    SDL does:
--    - Respond to Cloud application with cloudAppVehicleID received from HMI
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
    appName = "Cloud Application",
    isMediaApplication = true,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appHMIType = { "NAVIGATION" },
    appID = "1002",
    fullAppID = "0001002"
  }
}

local cloudServerParams = {
  host = "127.0.0.1",
  port = 5432,
  protocol = "ws",
  getUrl = function(self) return self.protocol .. "://" .. self.host .. ":" .. tostring(self.port) end
}

local cloudAppVehicleID = "bYg8789o"

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

local function processGetVehicleData()
  local mobileSession = common.mobile.getSession(1)
  local hmiConnection = common.hmi.getConnection()
  local cid = mobileSession:SendRPC("GetVehicleData", {cloudAppVehicleID = true})
  hmiConnection:ExpectRequest("VehicleInfo.GetVehicleData", {cloudAppVehicleID = true})
  :Do(function(_, data)
      hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {cloudAppVehicleID = cloudAppVehicleID} )
    end)
  mobileSession:ExpectResponse(cid, {success = true, resultCode = "SUCCESS", cloudAppVehicleID = cloudAppVehicleID})
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
runner.Step("Retrieving of cloudAppVehicleID via GetVehicleData", processGetVehicleData)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
