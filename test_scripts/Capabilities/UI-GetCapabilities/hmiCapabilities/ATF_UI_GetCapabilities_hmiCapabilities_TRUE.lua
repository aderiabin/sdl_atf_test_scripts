---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-23626]: response from HMI and RegisterAppInterface

-- Description:
-- SDL will send value TRUE of UI.GetCapabilities from HMI to mobile

-- Preconditions:
-- 1. HMI -> SDL: value TRUE of hmiCapabilities.navigation and phonecall in UI.GetCapabilities

-- Steps:
-- 1. Register App

-- Expected result:
-- SDL -> Mob: value TRUE of hmiCapabilities.navigation and phonecall
---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

--[[ Local variables]]
local functions_UIGetCapabilities = require('test_scripts/Capabilities/UI-GetCapabilities/common_functions_for_UI_GetCapabilities')

--[[ Preconditions ]]
common_steps:AddNewTestCasesGroup("Preconditions")
common_steps:PreconditionSteps("Preconditions", 2)
function Test:Preconditions_InitHMI_OnReady()
  functions_UIGetCapabilities:InitHMI_onReady_without_UI_GetCapabilities(self)
  local send_hmiCapabilities =
  {
    phoneCall = true,
    navigation = true
  }

  EXPECT_HMICALL("UI.GetCapabilities")
  :Do(function(_,data)
      send_hmi_capabilities.hmiCapabilities = send_hmiCapabilities
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
  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", hmiCapabilities = {navigation = true, phoneCall = true}})
  EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
end

--[[ Postconditions ]]
common_steps:AddNewTestCasesGroup("Postconditions")
common_steps:StopSDL("Postcondition_Stop_SDL")
