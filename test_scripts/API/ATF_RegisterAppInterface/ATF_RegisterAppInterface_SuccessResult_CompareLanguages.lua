---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-20706]: [RegisterAppInterface]: App registers at the first ignition
---- cycle with languages matches to default ones

-- Description:
-- In case:
---- mobile app registers at the very first ignition cycle (or after Master Reset)
---- and SDL does NOT receive at VR and TTS GetLanguage_response from HMI (SDL`s watchdog
---- timeout is NOT expired yet) and UI, VR and TTS languages from RegisterAppInterface
---- matches to default languages from 'HMI_capabilities.json' file
-- SDL must:
---- respond RegisterAppInterface (SUCCESS) to mobile app

-- Preconditions:
-- 1. SDL, HMI are initialized, Basic Communication is ready, UI module is ready
-- 2. SDL -> HMI: UI.GetLanguage, VR.GetLanguage, TTS.GetLanguage

-- Steps:
-- 1. HMI -> SDL UI.GetLanguage response with language param, no response from HMI to SDL
---- for VR.GetLanguage and TTS.GetLanguage
-- 2. Mob -> SDL: Application with appID is registering on SDL; request data satisfies
---- the conditions for successfull registration. Language from RegisterAppInterface 
---- matches the UI language

-- Expected result:
-- SDL -> Mob: success = true, resultCode = "SUCCESS"

---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')
Test = require("user_modules/dummy_connecttest")
hmi_values = require("user_modules/hmi_values")

--[[ Local Variables ]]
local hmi_table = hmi_values.getDefaultHMITable()
hmi_table.UI.GetLanguage.params =
{
  language = "EN-US"
}
hmi_table.VR.GetLanguage = nil
hmi_table.TTS.GetLanguage = nil

---------------------------------------------------------------------------------------------
--[[ Preconditions ]]
common_functions:DeleteLogsFileAndPolicyTable()
common_steps:PreconditionSteps("Preconditions", 2)

common_steps:AddNewTestCasesGroup("HMI Response with no VR.GetLanguage and TTS.GetLanguage responses")

function Test:InitHMI_onReady()
  self:initHMI_onReady(hmi_table)
end

common_steps:AddNewTestCasesGroup("Preconditions After HMI Response")
common_steps:AddMobileConnection("Precondition_AddMobileConnection")
common_steps:AddMobileSession("Precondition_AddMobileSession")

--[[ Test ]]
common_steps:AddNewTestCasesGroup('Verify SDL resonds with "success = true" and "resultCode = SUCCESS" values\n' ..
  "to RegisterAppInterface RPC" )

function Test:RegisterAppInterface_ResultSuccess_No_GetLanguage_VR_TTS()
  local cor_id = self.mobileSession:SendRPC("RegisterAppInterface",
  {
    syncMsgVersion =
    {
      majorVersion = 2,
      minorVersion = 2
    },
    appName ="SyncProxyTester",
    ttsName =
    {
      { text ="SyncProxyTester",
        type ="TEXT"
      }
    },
    ngnMediaScreenAppName ="SPT",
    vrSynonyms =
    {
      "VRSyncProxyTester"
    },
    isMediaApplication = true,
    languageDesired ="EN-US",
    hmiDisplayLanguageDesired ="EN-US",
    appHMIType =
    {
      "DEFAULT"
    },
    appID ="123456",
    deviceInfo =
    {
      hardware = "hardware",
      firmwareRev = "firmwareRev",
      os = "os",
      osVersion = "osVersion",
      carrier = "carrier",
      maxNumberRFCOMMPorts = 5
    }
  })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
  {
    application =
    {
      appName = "SyncProxyTester",
      ngnMediaScreenAppName ="SPT",
      deviceInfo =
      {
        name = "127.0.0.1",
        id = config.deviceMAC,
        isSDLAllowed = false
      },
      policyAppID = "123456",
      hmiDisplayLanguageDesired ="EN-US",
      isMediaApplication = true,
      appType =
      {
        "DEFAULT"
      },
    },
    ttsName =
    {
      {
        text ="SyncProxyTester",
        type ="TEXT"
      }
    },
    vrSynonyms =
    {
      "VRSyncProxyTester"
    }
  })
  EXPECT_RESPONSE(cor_id, { success = true, resultCode = "SUCCESS" })
  :Do(function(_,data)
      EXPECT_NOTIFICATION("OnHMIStatus", { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
  end)
  EXPECT_NOTIFICATION("OnPermissionsChange")
end

---------------------------------------------------------------------------------------------
--[[ Postconditions ]]
function Test:Postcondition_UnregisterApplication()
  local cor_id = self.mobileSession:SendRPC("UnregisterAppInterface", {})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { appID = self.applications[app_name], unexpectedDisconnect = false })
  self.mobileSession:ExpectResponse(cor_id, { success = true, resultCode = "SUCCESS"})
end

common_steps:StopSDL("StopSDL")
