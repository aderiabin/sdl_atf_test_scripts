---------------------------------------------------------------------------------------------
-- Requirements:
-- [APPLINK-16118]: [GeneralResultCodes] INVALID_DATA wrong type

-- Description:
-- In case the request comes to SDL with wrong type parameters (including parameters of 
-- the structures), SDL must respond with resultCode "INVALID_DATA" and success:"false" 
-- value.
-- Exception: Sending enum values as "Integer" ones must be process successfully as the
-- position number in the enum (in case not out of range, otherwise the rule above is 
-- applied).
-- Example: sending "String" type values instead of "Integer" ones.

-- Preconditons:
-- 1. Mobile application is registered and activated on HMI
-- 2. Icon file is uploaded to HMI

-- Performed steps
-- 1. Application sends "AddCommand" request with wrong type parameters

-- Expected result:
-- 1. SDL responds with resultCode:"INVALID_DATA" and success: "false" value

-- Note:
-- In every test case valid arguments (valid_args) are cloned to local variable then some
-- value is changed to invalid one then its value is passed to local 
-- SendAddCommandExpectInvalidData() function where "AddCommand" RPC is sent and response is 
-- checked.

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
local a_number = 45
local a_string = "SomeString"
local a_structure = { 1, 2, 3 }
local wrong_image_type_enum_value = 3
--------------------------------------Preconditions-------------------------------------------
common_steps:PreconditionSteps("Start_SDL_To_Activate_Application", 7)
common_steps:PutFile("Precondition_Put_File", "icon.png")
------------------------------------------Tests-----------------------------------------------
function Test:AddCommand_cmdId_notInt()
  local wrong_type_args = Clone(nil, valid_args)
  wrong_type_args.cmdID = a_string
  SendAddCommandExpectInvalidData(self, wrong_type_args)
end

function Test:AddCommand_menuParamsParentId_notInt()
  local wrong_type_args = Clone(nil, valid_args)
  wrong_type_args.menuParams.parentID = a_string
  SendAddCommandExpectInvalidData(self, wrong_type_args)
end

function Test:AddCommand_menuParams_notStucture()
  local wrong_type_args = Clone(nil, valid_args)
  wrong_type_args.menuParams = a_number
  SendAddCommandExpectInvalidData(self, wrong_type_args)
end

function Test:AddCommand_menuParamsPosition_notInt()
  local wrong_type_args = Clone(nil, valid_args)
  wrong_type_args.menuParams.position = a_string
  SendAddCommandExpectInvalidData(self, wrong_type_args)
end

function Test:AddCommand_menuParamsMenuName_notString()
  local wrong_type_args = Clone(nil, valid_args)
  wrong_type_args.menuParams.menuName = a_number
  SendAddCommandExpectInvalidData(self, wrong_type_args)
end

function Test:AddCommand_vrCommands_notStructure()
  local wrong_type_args = Clone(nil, valid_args)
  wrong_type_args.vrCommands = a_number
  SendAddCommandExpectInvalidData(self, wrong_type_args)
end

function Test:AddCommand_vrCommand_notString()
  local wrong_type_args = Clone(nil, valid_args)
  wrong_type_args.vrCommands[4] = a_number
  SendAddCommandExpectInvalidData(self, wrong_type_args)
end

function Test:AddCommand_cmdIcon_notStructure()
  local wrong_type_args = Clone(nil, valid_args)
  wrong_type_args.cmdIcon = a_string
  SendAddCommandExpectInvalidData(self, wrong_type_args)
end

function Test:AddCommand_cmdIconValue_notString()
  local wrong_type_args = Clone(nil, valid_args)
  wrong_type_args.cmdIcon.value = a_structure
  SendAddCommandExpectInvalidData(self, wrong_type_args)
end

function Test:AddCommand_cmdIconImageType_WrongType()
  local wrong_type_args = Clone(nil, valid_args)
  wrong_type_args.cmdIcon.imageType = a_structure
  SendAddCommandExpectInvalidData(self, wrong_type_args)
end

function Test:AddCommand_cmdIconImageType_IntNotInEnum()
  local wrong_type_args = Clone(nil, valid_args)
  wrong_type_args.cmdIcon.imageType = wrong_image_type_enum_value
  SendAddCommandExpectInvalidData(self, wrong_type_args)
end
-------------------------------------------Postcondition--------------------------------------
common_steps:UnregisterApp("UnRegister_App", app.appName)
common_steps:StopSDL("StopSDL")
