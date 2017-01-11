require('user_modules/all_common_modules')

---------------------------------------Preconditions--------------------------------------------------
common_functions:DeleteLogsFileAndPolicyTable()

common_steps:PreconditionSteps("Start_SDL_To_Activate_Application", 7)

------------------------------------------Tests-------------------------------------------------------
-- Description:
--   HMI sends OnExitAllApplications with reason IGNITION_OFF:
--   1. SDL sends to HMI OnSDLClose
--   2. SDL sends to app OnAppInterfaceUnregistered
-------------------------------------------------------
function Test:ShutDown_IGNITION_OFF()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
    { reason = "IGNITION_OFF" })
  EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false }) 
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
end

------------------------------------Postcondition-----------------------------------------------------
function Test:Stop_SDL()
  StopSDL()
end
