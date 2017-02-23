-- Requirements: APPLINK-32689, APPLINK-19333

-- Description:
-- In case the request comes to SDL when the command has only VR menu, cmdId and cmdIcon
-- All parameters are in boundary conditions. The command should be added to VR Commands Menu.
-- SDL should send UI.AddCommand to HMI, the command should be added to the end of the list of commands.

-- Performed steps:
-- 1. Application sends "AddCommand" request which contains such parameters: cmdId, vrCommands,
-- cmdIcon.

-- Expected result:
-- 1. SDL responds with resultCode:"Success" and success: "true" value for VR.AddCommand and
-- send UI.AddCommand to HMI; the command should be added to the end of the list of commands.

require('user_modules/all_common_modules')
local const = require('user_modules/consts')
-- -------------------------------------------Preconditions-------------------------------------
common_functions:CheckSdlPath()
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
        value ="icon.png",
        imageType ="DYNAMIC"
      }
    })
  EXPECT_HMICALL("UI.AddCommand",
    {
      cmdID = 11,
    })

  :ValidIf(function(_, data)
      local full_path_icon = common_functions:GetFullPathIcon(const.image_icon_png )
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
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  EXPECT_NOTIFICATION("OnHashChange")
end
-- -------------------------------------------Postcondition-------------------------------------
common_steps:StopSDL("StopSDL")
