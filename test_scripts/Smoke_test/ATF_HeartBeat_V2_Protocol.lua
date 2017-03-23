---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-17216]: [Services]: SDL must support Heartbeat over protocol v3 or higher.

-- Description:
-- App with specify protocols min=1 and max=2 is still alive and no unexpected disconnect occurs due to HeartBeat timeout

-- Preconditions:
-- 1. HeartBeatTimeout = 5000 and MaxSupportedProtocolVersion = 3 in smartDeviceLink.ini
-- 2. SDL is started

-- Steps:
-- 1. App is registered with specify protocols min=1 and max=2
-- 2. Waiting 20 seconds
-- 3. Send PutFile

-- Expected result:
-- 1. App with protocol version = 2 is registered.
-- 2. BasicCommunication.OnAppUnregistered is not sent in 20 seconds
-- 3. PutFile is processed successfully
---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')
-------------------------------------- Preconditions ----------------------------------------
common_steps:AddNewTestCasesGroup("Preconditions")
common_steps:BackupFile("Precondition_Backup_PreloadedPT", "smartDeviceLink.ini")
config.defaultProtocolVersion = 2
common_steps:SetValuesInIniFile("Precondition_Update_HeartBeatTimeout_Is_5000", "%p?HeartBeatTimeout%s? = %s-[%d]-%s-\n", "HeartBeatTimeout", 5000)
common_steps:SetValuesInIniFile("Precondition_Update_MaxSupportedProtocolVersion_Is_3", "%p?MaxSupportedProtocolVersion%s? = %s-[%d]-%s-\n", "MaxSupportedProtocolVersion", 3)
common_steps:PreconditionSteps("Precondition", 6)
------------------------------------------- BODY ---------------------------------------------
Test["SDL_does_not_send_HeartBeat_in_20s_check_app_is_not_unregistered"] = function(self)
  common_functions:UserPrint(const.color.green, "Please wait in 20 seconds, application with protocol v2 should be still alive!!!")
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
  :Times(0)
  common_functions:DelayedExp(20000)
end

-- Send PutFile to verify that application is still alive.
common_steps:PutFile("Putfile_Icon.png", "icon.png")

-----------------------------------Postcondition-------------------------------
common_steps:AddNewTestCasesGroup("Postconditions")
common_steps:RestoreIniFile("Postcondition_Restore_SmartDeviceLink", "smartDeviceLink.ini")
common_steps:StopSDL("Postcondition_StopSDL")
