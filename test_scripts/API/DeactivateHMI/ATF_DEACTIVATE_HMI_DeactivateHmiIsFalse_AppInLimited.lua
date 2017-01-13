-----------------------------------Test cases----------------------------------------
-- Check that In case an application (Media) was in LIMITED
-- when SDL got BasicCommunication.OnEventChanged("DEACTIVATE_HMI","isActive":true) from HMI
-- and SDL receives BasicCommunication.OnEventChanged("DEACTIVATE_HMI","isActive":false) ,
-- SDL must send OnHMIStatus (“HMILevel: LIMITED, audioStreamingState: NOT_AUDIBLE”) to such application.
-- and SDL receives BasicCommunication.OnEventChanged("DEACTIVATE_HMI","isActive":true)
-- from HMI, SDL must send OnHMIStatus (“HMILevel: BACKGROUND, audioStreamingState: NOT_AUDIBLE”) to such application.
-- Precondition:
-- -- 1. SDL is started
-- -- 2. HMI is started
-- -- 3. App is registered via BT
-- -- 4. App is in "LIMITED" HMI Level
-- Steps:
-- -- 1. Connect mobile via USB.
-- -- 2. Activate Carplay/GAL on HU
-- -- 3. Deactivate Carplay/GAL on HU.
-- Expected result
-- -- 1. Connect mobile via USB.
-- -- 2. SDL receives BasicCommunication.OnEventChanged("eventName":"DEACTIVATE_HMI","isActive":true) from HMI.
-- -- -- SDL sends OnHMIStatus (“HMILevel: BACKGROUND, audioStreamingState: NOT_AUDIBLE”)
-- -- 3. SDL sends OnHMIStatus (“HMILevel: LIMITED, audioStreamingState: AUDIBLE)
-- Postcondition
-- -- 1.UnregisterApp
-- -- 2.StopSDL
-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

--------------------------------------- Local Variables--------------------------------------
local media_app = common_functions:CreateRegisterAppParameters
({appID = "1", appName = "MEDIA", isMediaApplication = true, appHMIType = {"MEDIA"}})
local mobile_session = "mobileSession"

--------------------------------------Preconditions------------------------------------------
common_steps:PreconditionSteps("Precondition",4)

common_steps:AddMobileSession("Precontition_AddMobileSession", _, mobile_session)
common_steps:RegisterApplication("Precondition_Register_MediaApp", mobile_session, media_app)
common_steps:ActivateApplication("Precondition_Activate_MediaApp", media_app.appName)
common_steps:ChangeHMIToLimited("Precondition_Change_App_To_LIMITED", media_app.appName )

-----------------------------------------------Steps------------------------------------------
function Test:VerifyAppChangeToBACKGROUND_Incase_HmiLevelIsFULL_AndDeactiveHmiIsTrue()
  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="DEACTIVATE_HMI"})
  self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel="BACKGROUND", audioStreamingState="NOT_AUDIBLE", systemContext = "MAIN"})
end

function Test:VerifyAppChangeToLIMITED_Incase_HmiLevelIsBACKGROUND_AndDeactiveHmiIsFalse()
  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="DEACTIVATE_HMI"})
  self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel="LIMITED", audioStreamingState="AUDIBLE", systemContext = "MAIN"})
end

-------------------------------------------Postcondition-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegisterApp", media_app.appName)
common_steps:StopSDL("Postcondition_StopSDL")
