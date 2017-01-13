-----------------------------------Test cases----------------------------------------
-- Checks that SDL postpones resumption of media app that was in LIMITE
-- and satisfies the conditions of successful HMILevel resumption
-- if SDL receives BasicCommunication.OnEventChanged("DEACTIVATE_HMI","isActive":true)
-- notification before app's RAI and receives BasicCommunication.OnEventChanged("DEACTIVATE_HMI","isActive":false)
-- notification after "ApplicationResumingTimeout".
-- Precondition:
-- -- 1. Default HMI level = NONE.
-- -- 2. Core and HMI are started.
-- -- 3. These values are configured in .ini file:
-- -- -- AppSavePersistentDataTimeout =10;
-- -- -- ResumptionDelayBeforeIgn = 30;
-- -- -- ResumptionDelayAfterIgn = 30;
-- -- 4. The conditions of successful HMILevel resumption:
-- -- -- app unregisters during the time frame of 30 sec (inclusive) before BC.OnExitAllApplications(SUSPEND) from HMI
-- -- -- and it registers during 30 sec. after BC.OnReady from HMI
-- Steps:
-- -- 1. Register media app and activate it
-- -- 2. Make IGN_OFF-ON
-- -- 3. Activate Carplay/GAL on HU
-- -- 4. Register app from step 1 and wait 5 seconds
-- -- 5. Deactivate Carplay/GAL on HU
-- Expected result
-- -- 1. SDL sends UpdateDeviceList with appropriate deviceID
-- -- 2. SDL is reloaded
-- -- 3. HMI sends BasicCommunication.OnEventChanged("eventName":"DEACTIVATE_HMI","isActive":true) to SDL
-- -- 4. App is registered, ApplicationResumingTimeout is expired. SDL postpones resumption.
-- -- 5. HMI sends BasicCommunication.OnEventChanged("eventName":"DEACTIVATE_HMI","isActive":false) to SDL.
-- -- -- SDL resumes app to HMI level LIMITED
-- Postcondition
-- -- 1.UnregisterApp
-- -- 2.StopSDL
-------------------------------------Required Shared Libraries-------------------------------
require('user_modules/all_common_modules')
------------------------------------ Common Variables ---------------------------------------
resume_timeout = 5000
local mobile_session = "mobileSession"
media_app = common_functions:CreateRegisterAppParameters(
  {appID = "1", appName = "MEDIA", isMediaApplication = true, appHMIType = {"MEDIA"}})
--------------------------------------Preconditions------------------------------------------
common_steps:BackupFile("Backup Ini file", "smartDeviceLink.ini")
common_steps:SetValuesInIniFile("Update ApplicationResumingTimeout value", "%p?ApplicationResumingTimeout%s? = %s-[%d]-%s-\n", "ApplicationResumingTimeout", resume_timeout)
common_steps:PreconditionSteps("Precondition", 5)
-----------------------------------------------Steps------------------------------------------
--1. Register media app and activate it
common_steps:RegisterApplication("Precondition_Register_App", mobile_session, media_app)
common_steps:ActivateApplication("Precondition_Activate_App", media_app.appName)
common_steps:ChangeHMIToLimited("Precondition_Change_App_To_LIMITED", media_app.appName)

-- 2. Make IGN_OFF-ON
common_steps:IgnitionOff("Precondition_Ignition_Off")
common_steps:IgnitionOn("Precondition_Ignition_On")

-- 3. Activate Carplay/GAL on HU
function Test:Start_DeactivateHmi()
  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="DEACTIVATE_HMI"})
end

--4. Register app from step 1 and wait 5 seconds
common_steps:AddMobileSession("Add_Mobile_Session", _, mobile_session)
common_steps:RegisterApplication("Register_App", mobile_session, media_app)

function Test:Check_App_Is_Not_Resumed_After_ResumingTimeout()
  common_functions:DelayedExp(resume_timeout + 1000)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource"):Times(0)
  local mobile_conenction_name, mobile_session = common_functions:GetMobileConnectionNameAndSessionName(media_app.appName, self)
  self[mobile_session]:ExpectNotification("OnHMIStatus"):Times(0)
end

-- 5. Deactivate Carplay/GAL on HU
function Test:Stop_DeactivateHmi()
  function to_run()
    self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="DEACTIVATE_HMI"})
  end
  RUN_AFTER(to_run, 1000)
end

function Test:Check_App_Is_Resumed_Successful()
  EXPECT_HMICALL("BasicCommunication.OnResumeAudioSource")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id,"BasicCommunication.OnResumeAudioSource", "SUCCESS", {})
    end)
  self[mobile_session]:ExpectNotification("OnHMIStatus", {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
end

-------------------------------------------Postcondition-------------------------------------
common_steps:UnregisterApp("UnRegister_App", media_app.appName)
common_steps:StopSDL("StopSDL")
common_steps:RestoreIniFile("Restore_Ini_file")
