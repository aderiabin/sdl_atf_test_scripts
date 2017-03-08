--------------------------------------------------------------------------------------------
-- Requirement summary:
--[APPLINK-16309][RegisterAppInterface]: AppHMITypes is completely coincide with Policy data or not provided at all

-- Description:
-- In case:
--  SDL receives RegisterAppInterface RPC from mobile app with appHMIType(s) coincide with Policy data, SDL must:
--	1. Register application successfuly
--	2. Return resultCode SUCCESS, success:"true" value to mobile application.

-- Preconditions:
-- 1. Established Mobile connection
-- 2. Local PT has values in AppHMIType = {DEFAULT} for application_id = testApp
-- Steps:
-- 1. Mob -> SDL: SendRPC RegisterAppInterface(appID = "testApp", appHMIType = {"DEFAULT"})

-- Expected result:
-- SDL -> HMI: Send Notification OnAppRegistered
-- SDL -> Mob: Send Response with success = true, resultCode = "SUCCSESS"
---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

---------------------------------------------------------------------------------------------
--[[ Preconditions ]]
common_functions:BackupFile("sdl_preloaded_pt.json")

local jsonData = {
  testApp = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = {
      "Base-4"
    },
    AppHMIType = {
      "DEFAULT"
    }
  }
}

local jsonFile = config.pathToSDL .. "sdl_preloaded_pt.json"
common_functions:AddItemsIntoJsonFile(jsonFile, {"policy_table", "app_policies"}, jsonData)
common_steps:PreconditionSteps("Preconditions", 5)

---------------------------------------------------------------------------------------------
--[[ Test ]]
function Test:RegisterAppInterface_with_valid_appHMIApp()
  local msg = {
    syncMsgVersion =
    {
      majorVersion = 2,
      minorVersion = 2
    },
    appName = "Test Application",
    isMediaApplication = true,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appHMIType = {
      "DEFAULT"
    },
    appID = "testApp",
    deviceInfo =
    {
      os = "Android",
      carrier = "Megafon",
      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
      osVersion = "4.4.2",
      maxNumberRFCOMMPorts = 1
    }
  }

  local cid = self.mobileSession:SendRPC("RegisterAppInterface", msg)

  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
    {
      application =
      {
        appName = "Test Application",
        deviceInfo =
        {
          name = "127.0.0.1",
          id = config.deviceMAC,
        },
        appType =
        {
          "DEFAULT"
        },
        policyAppID = "testApp",
        hmiDisplayLanguageDesired ="EN-US",
      }
    })
end

---------------------------------------------------------------------------------------------
--[[ Postconditions ]]
common_steps:AddNewTestCasesGroup("Postconditions")
function Test:Postconditions_Restore_sdl_preloaded_pt()
  common_functions:RestoreFile("sdl_preloaded_pt.json", true)
end
common_steps:StopSDL("StopSDL")
