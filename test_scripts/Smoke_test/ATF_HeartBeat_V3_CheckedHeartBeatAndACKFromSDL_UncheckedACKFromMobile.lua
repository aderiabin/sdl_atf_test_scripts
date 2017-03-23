---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-17602]: [Services]: HeartBeat: mobile app sends data that doesn`t require a response from SDL

-- Description:
-- In case mobile app sends data that doesn`t require response from SDL side
-- SDL must: send HeartBeat_request to mobile app every <Heartbeat> ms
-- (meaning: SDL must NOT close session in this case)

-- Preconditions:
-- 1. HeartBeatTimeout = 5000 and MaxSupportedProtocolVersion = 3 in smartDeviceLink.ini
-- 2. SDL is started

-- Steps:
-- 1. App is registered with specify protocols min=1 and max=3
------ Check "HeartBeat" checkbox and ACK From SDL, uncheck ACK from mobile
-- 2. Waiting 20 seconds
-- 3. Send PutFile

-- Expected result:
-- 1. App with protocol version = 3 is registered.
-- 2. SDL -> Mob: SDL does not send BasicCommunication.OnAppUnregistered
-- 3. PutFile is processed successfully

-----------------------------------General Settings for Configuration------------------------
require('user_modules/all_common_modules')

-------------------------------------- Preconditions ----------------------------------------
config.defaultProtocolVersion = 3
common_steps:SetValuesInIniFile("Precondition_Update_HeartBeatTimeout_Is_5000", "%p?HeartBeatTimeout%s? = %s-[%d]-%s-\n", "HeartBeatTimeout", 5000)
common_steps:SetValuesInIniFile("Precondition_Update_MaxSupportedProtocolVersion_Is_3", "%p?MaxSupportedProtocolVersion%s? = %s-[%d]-%s-\n", "MaxSupportedProtocolVersion", 3)
common_steps:PreconditionSteps("Precondition", 4)

------------------------------------------- BODY ---------------------------------------------
Test["StartSession_And_RegisterApp_V3_Without_HB"] = function(self)
  self.mobileSession= mobile_session.MobileSession(self, self.mobileConnection)
  --configure HB
  self.mobileSession.sendHeartbeatToSDL = true
  self.mobileSession.answerHeartBeatFromSDL = false
  self.mobileSession.ignoreSDLHeartBeatACK = false
  self.mobileSession:StartService(7)
  :Do(function()
      local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface",
        {
          syncMsgVersion =
          {
            majorVersion = 3,
            minorVersion = 1
          },
          appName = "Application_V3",
          isMediaApplication = true,
          languageDesired = 'EN-US',
          hmiDisplayLanguageDesired = 'EN-US',
          appHMIType = { "DEFAULT" },
          appID = "App_003"
        })
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
      self.mobileSession:ExpectResponse("RegisterAppInterface", {success = true, resultCode = "SUCCESS" })

      self.mobileSession:ExpectNotification("OnHMIStatus",
        {systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
    end)
end

Test["Wait_14_seconds_to_verify_App_is_not_unregistered"] = function(self)
  common_functions:UserPrint(const.color.green, "Please wait in 14 seconds, application is still connected!!!")
  common_functions:DelayedExp(14000)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
  :Times(0)
end

-- Send PutFile to verify that application is still alive.
common_steps:PutFile("Check_app_is_alive_by_PutFile", "icon.png")

-----------------------------------Postcondition-------------------------------
common_steps:AddNewTestCasesGroup("Postconditions")
common_steps:RestoreIniFile("Postcondition_Restore_SmartDeviceLink", "smartDeviceLink.ini")
common_steps:StopSDL("Postcondition_StopSDL")
