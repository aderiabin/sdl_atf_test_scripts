---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-19635]: SDL must use the default values in case HMI does not provide values
-- [APPLINK-23264]: [HMI_capabilities] The 'hmi_capabilities' struct

-- Description:
-- SDL will use default hmiCapabilities when value hmiCapabilities is empty

-- Preconditions:
-- 1. HMI -> SDL: value of hmiCapabilities in UI.GetCapabilities is empty

-- Steps:
-- 1. Register App

-- Expected result:
-- SDL -> Mob: default value hmiCapabilities
---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

--[[ Local variables]]
local functions_UIGetCapabilities = require('test_scripts/Capabilities/UI-GetCapabilities/common_functions_for_UI_GetCapabilities')
-- TODO: below sentence will be added when CRQ APPLINK-32267 is implemented.
-- local default = common_functions:GetItemsFromJsonFile(config.pathToSDL .. "hmi_capabilities.json", {"UI", "hmiCapabilities"})

--[[ Preconditions ]]
common_steps:AddNewTestCasesGroup("Preconditions")
common_steps:PreconditionSteps("Preconditions", 2)
function Test:Preconditions_InitHMI_OnReady()
  functions_UIGetCapabilities:InitHMI_onReady_without_UI_GetCapabilities(self)

  EXPECT_HMICALL("UI.GetCapabilities")
  :Do(function(_,data)
      send_hmi_capabilities.hmiCapabilities = {}
      self.hmiConnection:SendResponse(data.id, "UI.GetCapabilities", "SUCCESS", send_hmi_capabilities)
    end)
end

common_steps:AddMobileConnection("Preconditions_Add_Mobile_Connection")
common_steps:AddMobileSession("Preconditions_Add_Mobile_Session")

--[[ Test ]]
common_steps:AddNewTestCasesGroup("Tests")
function Test:Register_App()
  local cid = self.mobileSession:SendRPC("RegisterAppInterface", const.default_app)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = {appName = const.default_app_name}})
  -- TODO: below Expected should be updated when CRQ APPLINK-32267 is implemented.
  -- EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", hmiCapabilities = default})
  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
  EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
end

--[[ Postconditions ]]
common_steps:AddNewTestCasesGroup("Postconditions")
common_steps:StopSDL("Postcondition_Stop_SDL")
