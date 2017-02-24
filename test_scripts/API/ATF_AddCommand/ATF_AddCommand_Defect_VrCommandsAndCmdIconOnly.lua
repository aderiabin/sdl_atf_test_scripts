--Requirements: [APPLINK-19334]: [AddCommand] SUCCESS: getting SUCCESS on VR and UI.AddCommand()
--[APPLINK-32689]: Absence of information about SDL behaviour when UI part absent, VR present and cmdicon is sent.

-- Description:
-- In case the request comes to SDL when the command has only VR menu, cmdId and cmdIcon
-- All parameters are in boundary conditions. The command should be added to VR Commands Menu.
-- SDL should send UI.AddCommand to HMI, the command should be added to the end of the list of commands.

-- Performed steps:
-- 1. Application sends "AddCommand" request which contains such parameters: cmdId, vrCommands,
-- cmdIcon.

-- Expected result:
-- 1. SDL sends VR.AddCommand with VR part and UI.AddCommand with cmdIcon of AddCommand received 
-- from mobile and sends resultCode:"Success" and success: "true" value to the mobile after receiving 
-- sucessful responses for UI.AddCommand and VR.AddCommand from HMI.

require('user_modules/all_common_modules')
local const = require('user_modules/consts')
-- -------------------------------------------Preconditions-------------------------------------
common_steps:PreconditionSteps("Preconditions",7)
common_steps:PutFile("PutFile", const.image_icon_png)
-- ------------------------------------------Body-----------------------------------------------
function Test:AddCommand_OnlyVrCommandAndCmdIcon()
  local cid = self.mobileSession:SendRPC("AddCommand",
    { cmdID = 11,
      vrCommands =
      {
        "VRCommandonepositive",
        "VRCommandonepositivedouble"
      },
      cmdIcon =
      {
        value = const.image_icon_png,
        imageType ="DYNAMIC"
      }
    })
  EXPECT_HMICALL("UI.AddCommand",
    {
      cmdID = 11,
    })
  :ValidIf(function(_, data)
      local full_path_icon = common_functions:GetFullPathIcon(const.image_icon_png)
      if data.params.cmdIcon.value ~= full_path_icon then
        local msg = "value of menuIcon is WRONG. Expected: ".. full_path_icon.. "; Real: " .. data.params.cmdIcon.value
        common_functions:UserPrint(const.color.red, msg)
        return false
      end
      if data.params.cmdIcon.imageType ~= "DYNAMIC" then
        local msg = "imageType of menuIcon is WRONG. Expected: DYNAMIC; Real: " .. data.params.cmdIcon.imageType
        common_functions:UserPrint(const.color.red, msg)
        return false
      end
      return true
    end)
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  EXPECT_HMICALL("VR.AddCommand",
    {
      cmdID = 11,
      type = "Command",
      vrCommands =
      {
        "VRCommandonepositive",
        "VRCommandonepositivedouble"
      }
    })
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS" })
  EXPECT_NOTIFICATION("OnHashChange")
end
-- -------------------------------------------Postcondition-------------------------------------
common_steps:StopSDL("StopSDL")
