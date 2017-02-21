--Task: APPLINK-32670

--Description: In case RegisterAppInterface request comes to SDL with correct structure and data
--with all app parameters and successfuly registered on SDL, SDL must:
--1. notify HMI with OnAppRegistered notification about application registering
--2. respond with resultCode "SUCCESS" and success:"true" value to mobile application.

--Performed steps
--1. Application with appID is registering on SDL; request data satisfies the conditions for
--successfull registration

-- Expected result:
--1. SDL successfully registers application and notifies HMI, also send a response to mobile
--application with result: Success, success:"true"

-- ------------------------------------------Required Resources---------------------------------
require('user_modules/all_common_modules')
-- -------------------------------------------Preconditions-------------------------------------
common_steps:PreconditionSteps("Preconditions",5)
-- -----------------------------------------------Body------------------------------------------
function Test:RegisterAppInterface()
  local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
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
  EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
  :Timeout(2000)
  :Do(function(_,data)
      EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    end)
  EXPECT_NOTIFICATION("OnPermissionsChange")
end
-- -------------------------------------------Postcondition-------------------------------------
common_steps:StopSDL("StopSDL")
