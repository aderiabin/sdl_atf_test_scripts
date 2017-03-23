-----------------------------------Test cases----------------------------------------
-- Check that in case an application_1 (Media) is in LIMITED HMILevel
-- and application_2 (Non-Media) is in FULL HMILevel
-- and SDL receives BasicCommunication.OnEventChanged("DEACTIVATE_HMI","isActive":true) from HMI
-- SDL must send OnHMIStatus (“HMILevel: BACKGROUND, audioStreamingState: NOT_AUDIBLE”) to such applications.
-- and SDL receives BasicCommunication.OnEventChanged("DEACTIVATE_HMI","isActive":false) from HMI
-- SDL must send OnHMIStatus (“HMILevel: LIMITED, audioStreamingState: NOT_AUDIBLE”) to application 1.
-- SDL must send OnHMIStatus (“HMILevel: FULL, audioStreamingState: NOT_AUDIBLE”) to application 2.
-- Precondition:
-- -- 1. SDL is started
-- -- 2. HMI is started
-- -- 3. App_1 (Media) and App_2 (Non-Media)
-- -- 4. App_1 is in "FULL" HMI Level
-- -- 5. App_2 - Non-Media (NAVIGATION non-media, COMMUNICATION non-media) is in "LIMITED" HMI Level.
-- Steps:
-- -- 1. Connect mobile
-- -- 2. Activate Carplay/GAL
-- -- 3. Deactivate Carplay/GAL
-- Expected result
-- -- 1. SDL sends UpdateDeviceList with appropriate deviceID
-- -- 2. SDL receives BC.OnEventChanged("eventName":"DEACTIVATE_HMI","isActive":true) from HMI.
-- -- -- SDL send OnHMIStatus (“HMILevel: BACKGROUND, audioStreamingState: NOT_AUDIBLE”) to both apps
-- -- -- SDL sends OnHMIStatus (“HMILevel: BACKGROUND, audioStreamingState: NOT_AUDIBLE”))
-- -- 3. SDL send to App_1 OnHMIStatus (HMILevel: LIMITED, audioStreamingState:<current_state>)
-- -- -- SDL send to App_2 OnHMIStatus (HMILevel: FULL, audioStreamingState:<current_state>)
-- Postcondition
-- -- 1.UnregisterApp
-- -- 2.StopSDL
-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

--------------------------------------- Local Variables--------------------------------------
local mobile_sessions = {"mobileSession1", "mobileSession2"}
local media_app = common_functions:CreateRegisterAppParameters
    ({appID = "1", appName = "MEDIA", isMediaApplication = true, appHMIType = {"MEDIA"}})
local non_media_app = common_functions:CreateRegisterAppParameters
    ({appID = "2", appName = "NAVIGATION", isMediaApplication = false, appHMIType = {"NAVIGATION"}})

--------------------------------------Preconditions------------------------------------------
common_steps:PreconditionSteps("Precondition",4)

common_steps:AddMobileSession("Precontition_AddMobileSession", _, mobile_sessions[1])
common_steps:RegisterApplication("Precondition_Register_MediaApp", mobile_sessions[1], media_app)
common_steps:ActivateApplication("Precondition_Activate_MediaApp", media_app.appName)

common_steps:AddMobileSession("Precontition_AddMobileSession", _, mobile_sessions[2])
common_steps:RegisterApplication("Precondition_Register_NonMediaApp", mobile_sessions[2], non_media_app)
common_steps:ActivateApplication("Precondition_Activate_NonMediaApp", non_media_app.appName)

----------------------------------------- Steps----------------------------------------------
function Test:VerifyAppChangeToBACKGROUND_Incase_HmiLevelIsFULLorLIMITED_AndDeactiveHmiIsTrue()
  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",
	    {isActive= true, eventName="DEACTIVATE_HMI"})
  self[mobile_sessions[1]]:ExpectNotification("OnHMIStatus",
	    {hmiLevel="BACKGROUND", audioStreamingState="NOT_AUDIBLE", systemContext = "MAIN"})
  self[mobile_sessions[2]]:ExpectNotification("OnHMIStatus",
	    {hmiLevel="BACKGROUND", audioStreamingState="NOT_AUDIBLE", systemContext = "MAIN"})
end

function Test:VerifyAppChangeToFULLorLIMITED_Incase_HmiLevelIsBACKGROUND_AndDeactiveHmiIsFalse()
  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",
	    {isActive= false, eventName="DEACTIVATE_HMI"})
  self[mobile_sessions[1]]:ExpectNotification("OnHMIStatus",
	    {hmiLevel="LIMITED", audioStreamingState="AUDIBLE", systemContext = "MAIN"})
  self[mobile_sessions[2]]:ExpectNotification("OnHMIStatus",
	    {hmiLevel="FULL", audioStreamingState="AUDIBLE", systemContext = "MAIN"})
end

-------------------------------------------Postcondition-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegister_MediaApp", media_app.appName)
common_steps:UnregisterApp("Postcondition_UnRegister_NonMediaApp", non_media_app.appName)
common_steps:StopSDL("Postcondition_StopSDL")
