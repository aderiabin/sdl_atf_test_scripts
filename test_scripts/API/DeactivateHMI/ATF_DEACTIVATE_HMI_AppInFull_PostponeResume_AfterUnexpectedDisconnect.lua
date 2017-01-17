-----------------------------------Test cases----------------------------------------
-- Checks that SDL postpones resumption of media app that was in FULL
-- before unexpected disconnect if SDL receives BasicCommunication.OnEventChanged("DEACTIVATE_HMI","isActive":true)
-- notification during "ApplicationResumingTimeout" and receives BasicCommunication.OnEventChanged("DEACTIVATE_HMI","isActive":false)
-- notification after "ApplicationResumingTimeout".
-- Precondition:
-- -- 1. Default HMI level = NONE.
-- -- 2. Core and HMI are started.
-- -- 3. These values are configured in .ini file:
-- -- -- AppSavePersistentDataTimeout =10;
-- -- -- ResumptionDelayBeforeIgn = 30;
-- -- -- ResumptionDelayAfterIgn = 30;
-- Steps:
-- -- 1. Register media app and activate it
-- -- 2. Disconnect and then connect transport
-- -- 3. After app registration Activate Carplay/GAL(during 3 seconds after RAI)
-- -- 4. Wait more than 5 seconds and deactivate Carplay/GAL
-- Expected result
-- -- 1. SDL sends UpdateDeviceList with appropriate deviceID
-- -- 2. App is unexpected disconnected and than connected
-- -- 3. App is registered with default HMI level NONE,
-- -- -- HMI sends BasicCommunication.OnEventChanged("eventName":"DEACTIVATE_HMI","isActive":true) to SDL.
-- -- 4. ApplicationResumingTimeout is expired.
-- -- -- SDL postpones resumption. HMI sends BasicCommunication.OnEventChanged("eventName":"DEACTIVATE_HMI","isActive":false) to SDL.
-- -- -- App is resumed to HMI level FULL
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

-- 2. App is unexpected disconnected and than connected
common_steps:CloseMobileSession("Close_Mobile_Session",mobile_session)

-- 3. After app registration Activate Carplay/GAL (during 3 seconds after RAI)
common_steps:AddMobileSession("Add_Mobile_Session", _, mobile_session)
common_steps:RegisterApplication("Register_App", mobile_session, media_app)

function Test:Start_DeactivateHmi()
  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="DEACTIVATE_HMI"})
end

function Test:Check_App_Is_Not_Resumed_After_ResumingTimeout()
  common_functions:DelayedExp(resume_timeout + 1000)
  EXPECT_HMICALL("BasicCommunication.ActivateApp"):Times(0)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource"):Times(0)
  local mobile_conenction_name, mobile_session = common_functions:GetMobileConnectionNameAndSessionName(media_app.appName, self)
  self[mobile_session]:ExpectNotification("OnHMIStatus"):Times(0)
end

-- 4. Wait more than 5 seconds and deactivate Carplay/GAL
function Test:Stop_DeactivateHmi()  
	self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="DEACTIVATE_HMI"})
end

function Test:Check_App_Is_Resumed_Successful()
  EXPECT_HMICALL("BasicCommunication.ActivateApp")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
    end)
  self[mobile_session]:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
end

-------------------------------------------Postcondition-------------------------------------
common_steps:UnregisterApp("UnRegister_App", media_app.appName)
common_steps:StopSDL("StopSDL")
common_steps:RestoreIniFile("Restore_Ini_file")
