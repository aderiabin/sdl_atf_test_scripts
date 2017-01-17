require('user_modules/all_common_modules')

---------------------------------------Preconditions--------------------------------------------------
common_functions:DeleteLogsFileAndPolicyTable()

common_steps:PreconditionSteps("Start_SDL_To_Activate_Application", 7)

------------------------------------------Tests-------------------------------------------------------
-- Description:
--   HMI sends OnExitAllApplications with reason MASTER_RESET:
--   1. SDL deletes Apps folder
--     => file (which had been put to application and stored in application folder) is removed. 
--   2. SDL clears app info in Policy DB and "resume_app_list" in app_info.dat file 
--     => SDL will not resume application when the same application registers.

--------------------------------------------------------------------------
--   PutFile icon.png. This file will be stored in application folder.
--------------------------------------------------------------------------
function Test:PutFile_icon_png()
  local cid = self.mobileSession:SendRPC(
    "PutFile", {
      syncFileName = "icon.png",
      fileType = "GRAPHIC_PNG",
      persistentFile = true,
      systemFile = false,
    }, "files/icon.png")
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
end

--------------------------------------------------------------------------
--   Shutdown with reason = "MASTER_RESET".
--------------------------------------------------------------------------
function Test:ShutDown_MASTER_RESET()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", 
    { reason = "MASTER_RESET" })
  EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", { reason = "MASTER_RESET" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  -- [TODO][nhphi] Temporary remove until defect about OnSDLClose is fixed.
  -- EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
  common_functions:DelayedExp(1800)
end

function Test:Stop_SDL_After_ShutDown_MASTER_RESET()
  StopSDL()
end

--------------------------------------------------------------------------
--   Start SDL again then add mobile session
--------------------------------------------------------------------------
common_steps:PreconditionSteps("Start_SDL_To_Add_Mobile_Session", 5)

--------------------------------------------------------------------------
--  Check SDL will not resume application when the same application registers.
--------------------------------------------------------------------------
function Test:Check_Application_Not_Resume_When_Register_Again()
  local cid = self.mobileSession:SendRPC("RegisterAppInterface", 
    config.application1.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
    { application = {appName = config.application1.registerAppInterfaceParams.appName} })
  self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  EXPECT_HMICALL("BasicCommunication.UpdateAppList")
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, "BasicCommunication.UpdateAppList", "SUCCESS", {})
  end)
  EXPECT_NOTIFICATION("OnHMIStatus")
  :ValidIf(function(_,data)
    return data.payload.hmiLevel == "NONE" and 
            data.payload.systemContext == "MAIN" and 
            data.payload.audioStreamingState == "NOT_AUDIBLE"
  end)
  EXPECT_HMICALL("BasicCommunication.ActivateApp")
  :Times(0)
end

--------------------------------------------------------------------------
--   Check all files (included icon.png) are removed.
--------------------------------------------------------------------------
function Test:Check_File_icon_png_Is_Removed()
  local cid = self.mobileSession:SendRPC("ListFiles", {})
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  :ValidIf (function(_,data)
    return not data.payload.filenames
  end)
end

------------------------------------Postcondition-----------------------------------------------------
function Test:Stop_SDL()
  StopSDL()
end
