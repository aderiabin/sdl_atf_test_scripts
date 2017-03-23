---------------------------------------------------------------------------------------------
-- Requirements:
-- [APPLINK-16133]: [GeneralResultCodes] INVALID_DATA empty String parameter

-- Description:
-- In case the request comes to SDL with empty value"" in "String" type parameters (including
-- parameters of the structures), SDL must respond with resultCode "INVALID_DATA" and
-- success: "false" value.

-- Preconditons:
-- 1. Mobile application is registered and activated on HMI
-- 2. Icon file is uploaded to HMI

-- Performed steps
-- 1. Application sends "AddCommand" request with an empty string parameter

-- Expected result:
-- 1. SDL responds with resultCode:"INVALID_DATA" and success:"false" value

-- Note:
-- In every test case valid arguments (valid_args) are cloned to local variable then a string
-- value is changed to an empty string then its value is passed to local
-- SendAddCommandExpectInvalidData() function where "AddCommand" RPC is sent and response is
-- checked

-------------------------------------Required Shared Libraries--------------------------------
require('user_modules/all_common_modules')
local consts = require('user_modules/consts')
------------------------------------ Common Functions ----------------------------------------
local function SendAddCommandExpectInvalidData(self, rpc_args)
  local cid = self.mobileSession:SendRPC("AddCommand", rpc_args)
  self.mobileSession:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
  :Timeout(consts.sdl_to_mobile_default_timeout)
end

local Clone = common_functions.CloneTable
------------------------------------ Common Variables ----------------------------------------
local app = config.application1.registerAppInterfaceParams

local valid_args = {
  cmdID = 0,
  menuParams =
  {
    parentID = 0,
    position = 0,
    menuName ="Command1"
  },
  vrCommands =
  {
    "VoiceRecognitionCommandOne",
    "VoiceRecognitionCommandTwo",
    "VoiceRecognitionCommandThree"
  },
  cmdIcon =
  {
    value ="icon.png",
    imageType ="DYNAMIC"
  }
}
--------------------------------------Preconditions-------------------------------------------
common_steps:PreconditionSteps("Start_SDL_To_Activate_Application", 7)
common_steps:PutFile("Precondition_Put_File", "icon.png")
------------------------------------------Tests-----------------------------------------------
function Test:AddCommand_menuParamsMenuNameEmpty()
  local empty_string_args = Clone(nil, valid_args)
  empty_string_args.menuParams.menuName = ""
  SendAddCommandExpectInvalidData(self, empty_string_args)
end

function Test:AddCommand_vrCommandEmpty()
  local empty_string_args = Clone(nil, valid_args)
  empty_string_args.vrCommands[1] = ""
  SendAddCommandExpectInvalidData(self, empty_string_args)
end

function Test:AddCommand_cmdIconValueEmpty()
  local empty_string_args = Clone(nil, valid_args)
  empty_string_args.cmdIcon.value = ""
  SendAddCommandExpectInvalidData(self, empty_string_args)
end

function Test:AddCommand_cmdIconImageTypeEmpty()
  local empty_string_args = Clone(nil, valid_args)
  empty_string_args.cmdIcon.imageType = ""
  SendAddCommandExpectInvalidData(self, empty_string_args)
end
-------------------------------------------Postcondition--------------------------------------
common_steps:UnregisterApp("UnRegister_App", app.appName)
common_steps:StopSDL("StopSDL")
