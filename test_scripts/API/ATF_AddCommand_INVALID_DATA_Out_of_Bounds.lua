-------------------------------------Required Shared Libraries--------------------------------
require('user_modules/all_common_modules')
local consts = require('user_modules/consts')
------------------------------------ Common Functions ----------------------------------------
local function SendRpcExpectResponse(self, rpc_args)
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
--------------------------------------Preconditions-------------------------------------------
common_steps:PreconditionSteps("Start_SDL_To_Activate_Application", 7)
common_steps:PutFile("Precondition_Put_File", "icon.png")
------------------------------------------Tests-----------------------------------------------
-- This script covers the following requirement:
-- In case:
-- the request comes to SDL with out-of-bounds array ranges or out-of-bounds parameters
-- values (including parameters of the structures) of any type
-- SDL must:
-- respond with resultCode:"INVALID_DATA" and success:"false" value.

-- Note:
-- In every test case valid arguments (valid_args) are cloned to local variable then some
-- value is changed to one that falls out of determined bounds then its value is passed to
-- local SendRpcExpectResponse() function where "AddCommand" RPC is sent and response is
-- checked.
----------------------------------------------------------------------------------------------
function Test:AddCommand_cmdIDBelowMin()
  local out_of_bounds_args = Clone(_, valid_args)
  out_of_bounds_args.cmdID = -1
  SendRpcExpectResponse(self, out_of_bounds_args)
end

function Test:AddCommand_cmdIDOverMax()
  local out_of_bounds_args = Clone(_, valid_args)
  out_of_bounds_args.cmdID = 2000000001
  SendRpcExpectResponse(self, out_of_bounds_args)
end

function Test:AddCommand_menuParamParentIDBelowMin()
  local out_of_bounds_args = Clone(_, valid_args)
  out_of_bounds_args.menuParams.parentID = -1
  SendRpcExpectResponse(self, out_of_bounds_args)
end

function Test:AddCommand_menuParamParentIDOverMax()
  local out_of_bounds_args = Clone(_, valid_args)
  out_of_bounds_args.menuParams.parentID = 2000000001
  SendRpcExpectResponse(self, out_of_bounds_args)
end

function Test:AddCommand_menuParamPositonBelowMin()
  local out_of_bounds_args = Clone(_, valid_args)
  out_of_bounds_args.menuParams.position = -1
  SendRpcExpectResponse(self, out_of_bounds_args)
end

function Test:menuParamPositionOverMax()
  local out_of_bounds_args = Clone(_, valid_args)
  out_of_bounds_args.menuParams.position = 1001
  SendRpcExpectResponse(self, out_of_bounds_args)
end

function Test:AddCommand_menuParamNameLengthOverMax()
  local out_of_bounds_args = Clone(_, valid_args)
  local menu_name_length_over_max = 501
  out_of_bounds_args.menuParams.menuName = common_functions:CreateString(menu_name_length_over_max)
  SendRpcExpectResponse(self, out_of_bounds_args)
end

function Test:AddCommand_vrCommandsArraySizeBelowMin()
  local out_of_bounds_args = Clone(_, valid_args)
  out_of_bounds_args.vrCommands = {}
  SendRpcExpectResponse(self, out_of_bounds_args)
end

function Test:AddCommand_vrCommandsArraySizeOverMax()
  local out_of_bounds_args = Clone(_, valid_args)
  local vr_commands_array_size_over_max = 101

  out_of_bounds_args.vrCommands = {}
  for i = 1, vr_commands_array_size_over_max do
    out_of_bounds_args.vrCommands[i] = table.concat({ i, "thVoiceCommand" })
  end
  SendRpcExpectResponse(self, out_of_bounds_args)
end

function Test:AddCommand_vrCommandLenghtOverMax()
  local out_of_bounds_args = Clone(_, valid_args)
  local vr_command_length_over_max = 100
  out_of_bounds_args.vrCommands = { common_functions:CreateString(vr_command_length_over_max) }
  SendRpcExpectResponse(self, out_of_bounds_args)
end

function Test:AddCommand_cmdIconValueLengthOverMax()
  local out_of_bounds_args = Clone(_, valid_args)
  local cmd_icon_value_length_over_max = 65536
  out_of_bounds_args.cmdIcon.value = common_functions:CreateString(cmd_icon_value_length_over_max)
  SendRpcExpectResponse(self, out_of_bounds_args)
end

function Test:AddCommand_imageTypeNotInEnum()
  local out_of_bounds_args = Clone(_, valid_args)
  out_of_bounds_args.cmdIcon.imageType = "ANY"
  SendRpcExpectResponse(self, out_of_bounds_args)
end
-------------------------------------------Postcondition--------------------------------------
common_steps:UnregisterApp("UnRegister_App", app.appName)
common_steps:StopSDL("StopSDL")
