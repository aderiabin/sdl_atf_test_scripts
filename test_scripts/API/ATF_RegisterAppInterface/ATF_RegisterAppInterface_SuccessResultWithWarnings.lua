
--Requirements: [APPLINK-16307][RegisterAppInterface] WARNINGS AppHMIType(s) partially coincide
--or not coincide with current non-empty data stored in PolicyTable

--Description: In case SDL receives RegisterAppInterface RPC from mobile app with AppHMIType(s)
--partially or not coincided with current non-empty data stored in PolicyTable for the specified 
--application, SDL must:
--1. Allow AppHMIType(s) registered in PT ONLY.
--2. Register an application successfuly and return resultCode "WARNINGS, success: true" value
--3. Provide an additional information to mobile application in the "info" parameter about AppHMITypes
-- received not listed in PT.

--Preconditions
--1.Run  PreconditionSteps, which include next function: StartSDL, InitHMI, InitHMI_onReady,
--AddDefaultMobileConnection, AddDefaultMobileConnect 
--2.Local PT has values in app_type ={MESSAGING} for application_id = default

--Performed steps
--1.Mobile app sends RegisterAppInterface rpc with value of AppHMIType {"MESSAGING", "TESTING"}

-- Postconditions:
-- 1. Restore sdl_preloaded_pt.json
-- 2. Stop SDL

-- Expected result:
--1. SDL->apps: (WARNINGS, success: true, 'info': "all HMI types that are got in request but
--disallowed: <TESTING>):RegisterAppInterface()
-- ------------------------------------------Required Resources---------------------------------
require('user_modules/all_common_modules')
-- -------------------------------------------Preconditions-------------------------------------
common_functions:BackupFile("sdl_preloaded_pt.json")
local added_json_items = 
{
  AppHMIType = 
  {
  "MESSAGING"
  }
}
local json_file = config.pathToSDL .. "sdl_preloaded_pt.json"
common_functions:AddItemsIntoJsonFile(json_file, {"policy_table", "app_policies", "default"}, added_json_items)
common_steps:PreconditionSteps("Preconditions", 5)
-- -----------------------------------------------Body------------------------------------------
function Test:RegisterAppInterface_SuccessResultWithWarnings()
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
      AppHMIType =
      {
        "MESSAGING",
        "TESTING"
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
          "MESSAGING"
        }
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
  EXPECT_RESPONSE(CorIdRAI, {success = true, resultCode = "WARNINGS", info = '"HMI types that are got in request but disallowed: "TESTING"'})
  :Do(function(_,data)
      EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    end)
  EXPECT_NOTIFICATION("OnPermissionsChange")
end
-- -------------------------------------------Postcondition-------------------------------------
Test["Restore file"] = function(self)
  common_functions:RestoreFile("sdl_preloaded_pt.json", 1)
end
common_steps:StopSDL("StopSDL")
