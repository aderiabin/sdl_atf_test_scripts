---------------------------------------------------------------------------------------------
-- Requirements:
-- [APPLINK-16109]: [GeneralResultCodes] INVALID_DATA wrong characters

-- Description:
-- In case the request comes with '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s)
-- at any "String" type parameter in the request structure, SDL must respond with resultCode
-- "INVALID_DATA" and success: "false" value.

-- Preconditons:
-- 1. Mobile application is registered and activated on HMI
-- 2. Icon file is uploaded to HMI

-- Performed steps
-- 1. Application sends "AddCommand" request with new line or tab char or
-- whitespace-as-the-only characters.

-- Expected result:
-- 1. SDL responds with resultCode:"INVALID_DATA" and success: "false" value

-- Note:
-- For each string-type parameter of "AddCommand" request 3 types of strings from
-- "wrong_strings" table are checked inside for-loops.
-- At first test case valid arguments (valid_args) are cloned to local variable then checked
-- value is changed to invalid one then its value is passed to local
-- SendAddCommandExpectInvalidData() function where "AddCommand" RPC is sent and response is checked.

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

local valid_args =
{
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
local wrong_strings =
{
  { name = "NewLineChar", value = "Some\nString" },
  { name = "TabChar", value = "Some\tString" },
  { name = "SpacesOnly", value = " " }
}
local test_prefix = "AddCommand_"
--------------------------------------Preconditions-------------------------------------------
common_steps:PreconditionSteps("Start_SDL_To_Activate_Application", 7)
common_steps:PutFile("Precondition_Put_File", "icon.png")
------------------------------------------Tests-----------------------------------------------
-- Wrong characters in menuParams -> menuName
for i = 1, #wrong_strings do
  local test_name = test_prefix .. "menuParamsMenuName_" .. wrong_strings[i].name
  Test[test_name] = function(self)
    local wrong_chars_args = Clone(nil, valid_args)
    wrong_chars_args.menuParams.menuName = wrong_strings[i].value
    SendAddCommandExpectInvalidData(self, wrong_chars_args)
  end
end

-- Wrong characters in vrCommand
for i = 1, #wrong_strings do
  local test_name = test_prefix .. "vrCommand_" .. wrong_strings[i].name
  Test[test_name] = function(self)
    local wrong_chars_args = Clone(nil, valid_args)
    wrong_chars_args.vrCommands[i] = wrong_strings[i].value
    SendAddCommandExpectInvalidData(self, wrong_chars_args)
  end
end

-- Wrong characters in cmdIcon -> value
for i = 1, #wrong_strings do
  local test_name = test_prefix .. "cmdIconValue_" .. wrong_strings[i].name
  Test[test_name] = function(self)
    local wrong_chars_args = Clone(nil, valid_args)
    wrong_chars_args.cmdIcon.value = wrong_strings[i].value
    SendAddCommandExpectInvalidData(self, wrong_chars_args)
  end
end
-------------------------------------------Postcondition--------------------------------------
common_steps:UnregisterApp("UnRegister_App", app.appName)
common_steps:StopSDL("StopSDL")
