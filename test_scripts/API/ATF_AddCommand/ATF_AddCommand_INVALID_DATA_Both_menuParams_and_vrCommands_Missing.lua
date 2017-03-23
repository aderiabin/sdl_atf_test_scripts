---------------------------------------------------------------------------------------------
-- Requirements:
-- [APPLINK-19326]: [AddCommand] INVALID_DATA: "vrCommand" and "MenuParams" are not provided
-- by an application

-- Description:
-- In case an application sends AddCommand request and both "menuParams" and "vrCommands"
-- parameters are not provided, SDL must respond with "resultCode:INVALID_DATA",
-- "success:false" and DO NOT transfer data to HMI via UI/VR.AddCommand.

-- Preconditons:
-- 1. Mobile application is registered and activated on HMI
-- 2. Icon file is uploaded to HMI

-- Performed steps
-- 1. Application sends "AddCommand" request and both "menuParams" and "vrCommands"
-- parameters missing
-- 2. Application sends "DeleteCommand" request with the same ID as was in "AddCommand"
-- request

-- Expected result:
-- 1. SDL responds with resultCode:"INVALID_DATA" and success: "false" value
-- 2. SDL repsonds with resultCode:"INVALID_ID" and success: "false" value to the following
-- "DeleteCommand" request with the same ID as was in "AddCommand" which proves that
-- "AddCommand" with posted ID wasn't transfered to HMI.

-------------------------------------Required Shared Libraries-------------------------------
require('user_modules/all_common_modules')
local consts = require('user_modules/consts')
------------------------------------ Common Variables ---------------------------------------
local app = config.application1.registerAppInterfaceParams
local cmdIdValue = 123
--------------------------------------Preconditions------------------------------------------
common_steps:PreconditionSteps("Start_SDL_To_Activate_Application", 7)
common_steps:PutFile("Precondition_Put_File", "icon.png")
------------------------------------------Tests-----------------------------------------------
function Test:AddCommand_INVALID_DATA_Both_menuParams_and_vrCommands_Missing()
  local cid = self.mobileSession:SendRPC("AddCommand",
    {
      cmdID = cmdIdValue,
      cmdIcon =
      {
        value ="icon.png",
        imageType ="DYNAMIC"
      }
    })
  self.mobileSession:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
end

function Test:DeleteCommand_INVALID_ID()
  local cid = self.mobileSession:SendRPC("DeleteCommand", { cmdID = cmdIdValue })
  self.mobileSession:ExpectResponse(cid, { success = false, resultCode = "INVALID_ID" })
end
-------------------------------------------Postcondition-------------------------------------
common_steps:UnregisterApp("UnRegister_App", app.appName)
common_steps:StopSDL("StopSDL")
