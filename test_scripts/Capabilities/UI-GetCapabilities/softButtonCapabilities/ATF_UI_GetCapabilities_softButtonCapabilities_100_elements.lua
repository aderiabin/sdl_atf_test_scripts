---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-23626]: response from HMI and RegisterAppInterface

-- Description:
-- SDL will send value of UI.GetCapabilities.softButtonCapabilities from HMI to mobile in case it contains 100 elements

-- Preconditions:
-- 1. HMI -> SDL: UI.GetCapabilities.softButtonCapabilities contains 100 elements

-- Steps:
-- 1. Register App

-- Expected result:
-- SDL -> Mob: value of UI.GetCapabilities.softButtonCapabilities from HMI
---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

--[[ Local variables]]
local functions_UIGetCapabilities = require('test_scripts/Capabilities/UI-GetCapabilities/common_functions_for_UI_GetCapabilities')
local send = {}

--[[ Preconditions ]]
function Test:PrepareTestData()
  for i = 1, 100 do
    send[i] =
    {
      shortPressAvailable = math.random()>0.5,
      longPressAvailable = math.random()>0.5,
      upDownAvailable = math.random()>0.5,
      imageSupported = math.random()>0.5
    }
  end
end
common_steps:AddNewTestCasesGroup("Preconditions")
common_steps:PreconditionSteps("Preconditions", const.precondition.INIT_HMI)
function Test:Preconditions_InitHMI_OnReady()
  functions_UIGetCapabilities:InitHMI_onReady_without_UI_GetCapabilities(self)

  EXPECT_HMICALL("UI.GetCapabilities")
  :Do(function(_,data)
      send_hmi_capabilities.softButtonCapabilities = send
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
  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", softButtonCapabilities = send})
  EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
end

--[[ Postconditions ]]
common_steps:AddNewTestCasesGroup("Postconditions")
common_steps:StopSDL("Postconditions_Stop_SDL")
