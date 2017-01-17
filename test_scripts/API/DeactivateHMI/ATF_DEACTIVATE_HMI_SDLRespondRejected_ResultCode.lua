-----------------------------------Test cases----------------------------------------
-- Check that in case SDL has received BasicCommunication.OnEventChanged("DEACTIVATE_HMI","isActive":true)
-- and then receives SDL.ActivateApp (<appID-of-any-registered-application>) from HMI
-- SDL must respond with REJECTED resultCode to HMI.
-- Precondition:
-- -- 1. SDL is started
-- -- 2. HMI is started
-- -- 3. App is registered
-- -- 4. App is in "FULL" HMI Level
-- Steps:
-- -- 1. Connect mobile
-- -- 2. Activate Carplay/GAL
-- -- 3. Send from HMI SDL.ActivateApp
-- Expected result
-- -- 1. Connect mobile
-- -- 2. SDL receives BasicCommunication.OnEventChanged("eventName":"DEACTIVATE_HMI","isActive":true) from HMI.
-- -- -- SDL sends OnHMIStatus (“HMILevel: BACKGROUND, audioStreamingState: NOT_AUDIBLE”)
-- -- 3. SDL respond SDL.ActivateApp (REJECTED)
-- Postcondition
-- -- 1.UnregisterApp
-- -- 2.StopSDL
-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

--------------------------------------- Local Variables--------------------------------------
local app_name = config.application1.registerAppInterfaceParams.appName

--------------------------------------- Precondition-----------------------------------------
common_steps:PreconditionSteps("Precondition",7)

----------------------------------------- Steps----------------------------------------------
function Test:Verify_App_Change_To_BACKGROUND_Incase_HmiLevel_Is_FULL_And_DeactiveHmi_Is_True()
  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",
	    {isActive= true, eventName="DEACTIVATE_HMI"})
  self.mobileSession:ExpectNotification("OnHMIStatus",
	    {hmiLevel="BACKGROUND", audioStreamingState="NOT_AUDIBLE", systemContext = "MAIN"})
end

function Test:Verify_REJECTED_resultCode_When_Deactivate_Is_True_And_Register_App()
  local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface", 
	    config.application1.registerAppInterfaceParams)
  self.mobileSession:ExpectResponse(CorIdRAI, 
	    {success = false, resultCode = "APPLICATION_REGISTERED_ALREADY"})
end

-------------------------------------------Postcondition-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegisterApp", app_name)
common_steps:StopSDL("Postcondition_StopSDL")
