---------------------------------------------------------------------------------------------
-- Requirements:
-- [APPLINK-16110]: [GeneralResultCodes] INVALID_DATA out of bounds

-- Description:
-- In case the request comes to SDL with out-of-bounds array ranges or out-of-bounds
-- parameters values (including parameters of the structures) of any type, SDL must respond
-- with resultCode "INVALID_DATA" and success:"false" value.

-- Preconditons:
-- 1. Mobile application is registered and activated on HMI
-- 2. Icon file is uploaded to HMI

-- Performed steps
-- 1. Application sends "AddCommand" request which contains parameter with out-of-bounds
-- array ranges or out-of-bounds values (for a single parameter or as the part of the
-- structure)

-- Expected result:
-- 1. SDL responds with resultCode:"INVALID_DATA" and success:"false" value

-- Note:
-- 1. Determined bounds of values are loaded directly from "MOBILE_API.xml" file
-- 2. In every test case valid arguments (valid_args) are cloned to local variable then some
-- value is changed to one that falls out of determined bounds then its value is passed to
-- local SendAddCommandExpectInvalidData() function where "AddCommand" RPC is sent and response is
-- checked.
-------------------------------------Required Shared Libraries--------------------------------
require('user_modules/all_common_modules')
local consts = require('user_modules/consts')
local utils = require('user_modules/utils')
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
    "VoiceRecognitionCommandDone"
  },
  cmdIcon =
  {
    value ="icon.png",
    imageType ="DYNAMIC"
  }
}
local wrong_image_type = "UNKNOWN_IMAGE_TYPE"
--------------------------------------Preconditions-------------------------------------------
common_steps:PreconditionSteps("Start_SDL_To_Activate_Application", 7)
common_steps:PutFile("Precondition_Put_File", "icon.png")
-- ------------------------------------------Tests-----------------------------------------------
function Test:AddCommand_cmdID_BelowMin()
  local out_of_bounds_args = Clone(nil, valid_args)
  out_of_bounds_args.cmdID = utils.GetFunctionValueFromMobileApi("request", "AddCommand", "cmdID", "minvalue") - 1
  SendAddCommandExpectInvalidData(self, out_of_bounds_args)
end

function Test:AddCommand_cmdID_OverMax()
  local out_of_bounds_args = Clone(nil, valid_args)
  out_of_bounds_args.cmdID = utils.GetFunctionValueFromMobileApi("request", "AddCommand", "cmdID", "maxvalue") + 1
  SendAddCommandExpectInvalidData(self, out_of_bounds_args)
end

function Test:AddCommand_menuParamParentID_BelowMin()
  local out_of_bounds_args = Clone(nil, valid_args)
  out_of_bounds_args.cmdID = utils.GetStructValueFromMobileApi("MenuParams", "parentID", "minvalue") - 1
  SendAddCommandExpectInvalidData(self, out_of_bounds_args)
end

function Test:AddCommand_menuParamParentID_OverMax()
  local out_of_bounds_args = Clone(nil, valid_args)
  out_of_bounds_args.menuParams.parentID = utils.GetStructValueFromMobileApi("MenuParams", "parentID", "maxvalue") + 1
  SendAddCommandExpectInvalidData(self, out_of_bounds_args)
end

function Test:AddCommand_menuParamPosition_BelowMin()
  local out_of_bounds_args = Clone(nil, valid_args)
  out_of_bounds_args.cmdID = utils.GetStructValueFromMobileApi("MenuParams", "position", "minvalue") - 1
  SendAddCommandExpectInvalidData(self, out_of_bounds_args)
end

function Test:menuParamPosition_OverMax()
  local out_of_bounds_args = Clone(nil, valid_args)
  out_of_bounds_args.cmdID = utils.GetStructValueFromMobileApi("MenuParams", "position", "maxvalue") + 1
  SendAddCommandExpectInvalidData(self, out_of_bounds_args)
end

function Test:AddCommand_menuParamNameLength_OverMax()
  local out_of_bounds_args = Clone(nil, valid_args)
  local menu_name_length_over_max = utils.GetStructValueFromMobileApi("MenuParams", "menuName", "maxlength") + 1
  out_of_bounds_args.menuParams.menuName = common_functions:CreateString(menu_name_length_over_max)
  SendAddCommandExpectInvalidData(self, out_of_bounds_args)
end

function Test:AddCommand_vrCommandsArraySize_BelowMin()
  local out_of_bounds_args = Clone(nil, valid_args)
  out_of_bounds_args.vrCommands = {}
  SendAddCommandExpectInvalidData(self, out_of_bounds_args)
end

function Test:AddCommand_vrCommandsArraySize_OverMax()
  local out_of_bounds_args = Clone(nil, valid_args)
  vr_commands_array_size_over_max = utils.GetFunctionValueFromMobileApi("request", "AddCommand", "vrCommands", "maxsize") + 1

  out_of_bounds_args.vrCommands = {}
  for i = 1, vr_commands_array_size_over_max do
    out_of_bounds_args.vrCommands[i] = table.concat({ i, "thVoiceCommand" })
  end
  SendAddCommandExpectInvalidData(self, out_of_bounds_args)
end

function Test:AddCommand_vrCommandLength_OverMax()
  local out_of_bounds_args = Clone(nil, valid_args)
  vr_command_length_over_max = utils.GetFunctionValueFromMobileApi("request", "AddCommand", "vrCommands", "maxlength") + 1
  out_of_bounds_args.vrCommands = { common_functions:CreateString(vr_command_length_over_max) }
  SendAddCommandExpectInvalidData(self, out_of_bounds_args)
end

function Test:AddCommand_cmdIconValueLength_OverMax()
  local out_of_bounds_args = Clone(nil, valid_args)
  local cmd_icon_value_length_over_max = utils.GetStructValueFromMobileApi("Image", "value", "maxlength") + 1
  out_of_bounds_args.cmdIcon.value = common_functions:CreateString(cmd_icon_value_length_over_max)
  SendAddCommandExpectInvalidData(self, out_of_bounds_args)
end

function Test:AddCommand_imageType_NotInEnum()
  local out_of_bounds_args = Clone(nil, valid_args)
  out_of_bounds_args.cmdIcon.imageType = wrong_image_type
  SendAddCommandExpectInvalidData(self, out_of_bounds_args)
end
-------------------------------------------Postcondition--------------------------------------
common_steps:UnregisterApp("UnRegister_App", app.appName)
common_steps:StopSDL("StopSDL")
