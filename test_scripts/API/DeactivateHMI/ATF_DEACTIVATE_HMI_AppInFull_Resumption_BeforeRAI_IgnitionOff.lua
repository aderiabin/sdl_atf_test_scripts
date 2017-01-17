-----------------------------------Test cases----------------------------------------
-- Checks resumption of media app that was in FULL and
-- satisfies the conditions of successful HMILevel resumption after "ApplicationResumingTimeout"
-- if SDL receives BasicCommunication.OnEventChanged("DEACTIVATE_HMI","isActive":true)
-- before app's RAI and receives BasicCommunication.OnEventChanged("DEACTIVATE_HMI","isActive":false)
-- notifications during "ApplicationResumingTimeout".".
-- Precondition:
-- -- 1. Default HMI level = NONE.
-- -- 2. Core and HMI are started.
-- -- 3. These values are configured in .ini file:
-- -- -- AppSavePersistentDataTimeout =10;
-- -- -- ResumptionDelayBeforeIgn = 30;
-- -- -- ResumptionDelayAfterIgn = 30;
-- -- 4. The conditions of successful HMILevel resumption:
-- -- -- app unregisters during the time frame of 30 sec (inclusive) before BC.OnExitAllApplications(SUSPEND) from HMI
-- -- - and it registers during 30 sec. after BC.OnReady from HMIl
-- Steps:
-- -- 1. Register media app and activate it
-- -- 2. Make IGN_OFF-ON
-- -- 3. Activate Carplay/GAL on HU
-- -- 4. Register app and deactivate Carplay/GAL (during 3 seconds after RAI)
-- Expected result
-- -- 1. SDL sends UpdateDeviceList with appropriate deviceID
-- -- 2. SDL is reloaded
-- -- 3. HMI send BasicCommunication.OnEventChanged("eventName":"DEACTIVATE_HMI","isActive":true) to SDL
-- -- 4. App is registered with default HMI level NONE,
-- -- -- HMI sends BasicCommunication.OnEventChanged("eventName":"DEACTIVATE_HMI","isActive":false) to SDL.
-- -- -- After expiration ApplicationResumingTimeout SDL resumes app to HMI level FULL

-- Postcondition
-- -- 1.UnregisterApp
-- -- 2.StopSDL
-------------------------------------Required Shared Libraries-------------------------------
require('user_modules/all_common_modules')
------------------------------------ Common Variables ---------------------------------------
resume_timeout = 7000
local mobile_session = "mobileSession"
media_app = common_functions:CreateRegisterAppParameters(
    {appID = "1", appName = "MEDIA", isMediaApplication = true, appHMIType = {"MEDIA"}})
--------------------------------------Preconditions------------------------------------------
common_steps:BackupFile("Backup Ini file", "smartDeviceLink.ini")
common_steps:SetValuesInIniFile("Update ApplicationResumingTimeout value", 
    "%p?ApplicationResumingTimeout%s? = %s-[%d]-%s-\n", "ApplicationResumingTimeout", resume_timeout)
common_steps:PreconditionSteps("Precondition", 5)
-----------------------------------------------Steps------------------------------------------
--1. Register media app and activate it
common_steps:RegisterApplication("Precondition_Register_App", mobile_session, media_app)
common_steps:ActivateApplication("Precondition_Activate_App", media_app.appName)

-- 2. Make IGN_OFF-ON
common_steps:IgnitionOff("Precondition_Ignition_Off")
common_steps:IgnitionOn("Precondition_Ignition_On")

-- 3. Activate Carplay/GAL on HU
function Test:Start_DeactivateHmi()
  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",
	    {isActive= true, eventName="DEACTIVATE_HMI"})
end

-- 4. Register app and deactivate Carplay/GAL (during 3 seconds after RAI)
common_steps:AddMobileSession("Add_Mobile_Session", _, mobile_session)
common_steps:RegisterApplication("Register_App", mobile_session, media_app)

function Test:Stop_DeactivateHmi()
  function to_run()
    self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="DEACTIVATE_HMI"})
  end
  RUN_AFTER(to_run, 1000)
end

function Test:Check_App_Is_Resumed_Successful()
  EXPECT_HMICALL("BasicCommunication.ActivateApp")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
    end)
  self[mobile_session]:ExpectNotification("OnHMIStatus", 
	    {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
end

-------------------------------------------Postcondition-------------------------------------
common_steps:UnregisterApp("UnRegister_App", media_app.appName)
common_steps:StopSDL("StopSDL")
common_steps:RestoreIniFile("Restore_Ini_file")
