-----------------------------------Test cases----------------------------------------
-- Checks resumption of HMI Level when application is running on SDL in LIMITED
-- and disconnects due to activation of CarPlay an then re-connects after its deactivation.
-- The HMI level is stored and postponed 
-- when SDL receives BasicCommunication.OnEventChanged ("DEACTIVATE_HMI","isActive":true) notification 
-- and then resumed after SDL receives BasicCommunication.OnEventChanged ("eventName":"DEACTIVATE_HMI","isActive":false) notification.
-- SDL must send BC.ActivateApp to HMI in case app must be resumed to LIMITED
-- Precondition:
-- -- 1. SDL is started
-- -- 2. HMI is started
-- -- 3. App is registered
-- -- 4. App is in "LIMITED" and "AUDIBLE" HMI Level. 
-- Steps:
-- -- 1. Activate Carplay/GAL
-- -- 2. Device disconnects
-- -- 3. Device reconnects
-- -- 4. Deactivate Activate Carplay/GAL
-- -- 5. Device disconnects
-- -- 6. Device reconnects
-- Expected result
-- -- 1. SDL receives BasicCommunication.OnEventChanged("eventName":"DEACTIVATE_HMI","isActive":true) from HMI.
-- -- -- SDL sends OnHMIStatus (“HMILevel: BACKGROUND, audioStreamingState: NOT_AUDIBLE”) 
-- -- 2. SDL sends BasicCommunication.OnAppUnregistered ("unexpectedDisconnect = true)"
-- -- 3. SDL receives RegisterAppInterface (SUCCESS)
-- -- -- SDL sends OnAppRegistered
-- -- -- SDL sends OnHMIStatus (“HMILevel: NONE, audioStreamingState: NOT_AUDIBLE”) this is the default HMI level (NONE)
-- -- -- SDL postpones HMI level resumption and stores postponedHMILevel=LIMITED (not current)
-- -- 4. SDL receives BasicCommunication.OnEventChanged("eventName":"DEACTIVATE_HMI","isActive":false) from HMI
-- -- -- SDL sends OnHMIStatus (“HMILevel: LIMITED, audioStreamingState: NOT_AUDIBLE)
-- -- 5. SDL sends BasicCommunication.OnAppUnregistered ("unexpectedDisconnect = true"
-- -- 6. SDL receives RegisterAppInterface (SUCCESS)
-- -- -- SDL sends OnAppRegistered
-- -- -- SDL resumes (stored) postponed HMILevel LIMITED
-- -- -- SDL sends BasicCommunication.ActivateApp
-- -- -- SDL sends OnHMIStatus (“HMILevel: LIMITED, audioStreamingState: AUDIBLE”)
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
-- update ApplicationResumingTimeout with the time enough to check app is (not) resumed
common_steps:SetValuesInIniFile("Update ApplicationResumingTimeout value", 
    "%p?ApplicationResumingTimeout%s? = %s-[%d]-%s-\n", "ApplicationResumingTimeout", resume_timeout)
common_steps:PreconditionSteps("Precondition", 5)
common_steps:RegisterApplication("Precondition_Register_App", mobile_session, media_app)
common_steps:ActivateApplication("Precondition_Activate_App", media_app.appName)
common_steps:ChangeHMIToLimited("Precondition_Change_App_To_LIMITED", media_app.appName)
-----------------------------------------------Steps------------------------------------------
-- 1. Activate Carplay/GAL
function Test:Start_DeactivateHmi()
  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",
	    {isActive= true, eventName="DEACTIVATE_HMI"})
end

-- 2. Device disconnects
common_steps:CloseMobileSession("Close_Mobile_Session",mobile_session)

-- 3. Device reconnects
common_steps:AddMobileSession("Add_Mobile_Session", _, mobile_session)
common_steps:RegisterApplication("Register_App", mobile_session, media_app)

function Test:Check_App_Is_Not_Resumed_After_ResumingTimeout()
  common_functions:DelayedExp(resume_timeout + 1000)
  self[mobile_session]:ExpectNotification("OnHMIStatus"):Times(0)
end

-- 4. Deactivate Activate Carplay/GAL
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
  self[mobile_session]:ExpectNotification("OnHMIStatus", 
	    {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
end

-- 5. Device disconnects
common_steps:CloseMobileSession("Close_Mobile_Session",mobile_session)

-- 6. Device reconnects
common_steps:AddMobileSession("Add_Mobile_Session", _, mobile_session)
common_steps:RegisterApplication("Register_App", mobile_session, media_app)

function Test:Check_App_Is_Resumed_Successful()
  EXPECT_HMICALL("BasicCommunication.OnResumeAudioSource")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id,"BasicCommunication.OnResumeAudioSource", "SUCCESS", {})
    end)
  self[mobile_session]:ExpectNotification("OnHMIStatus", 
	    {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
end
-------------------------------------------Postcondition-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegister_App", media_app.appName)
common_steps:StopSDL("Postcondition_StopSDL")
common_steps:RestoreIniFile("Postcondition_Restore_Ini_file")
