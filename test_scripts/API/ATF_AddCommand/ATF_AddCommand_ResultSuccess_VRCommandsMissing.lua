--Requirements: APPLINK-19329

--Description:
--In case the request comes to SDL when the command has all parameters, exception
--vrCommands. The command should be added to UI Commands Menu.
--All parameters are in boundary conditions.
--SDL must respond with resultCode "Success" and success:"true" value.

-- Performed steps
-- 1. Application sends "AddCommand" request which contains all parameters, exception
-- vrCommands
-- 2. Validation the image type and the path to image

-- Expected result:
-- 1. SDL responds with resultCode:"Success" and success: "true" value

-- -------------------------------------------Required Resources-------------------------------
require('user_modules/all_common_modules')
local const = require('user_modules/consts')
-- -------------------------------------------Preconditions-------------------------------------
common_functions:CheckSdlPath()
common_steps:PreconditionSteps("Preconditions",7)
common_steps:PutFile("PutFile", const.image_icon_png)
-- ------------------------------------------Body-----------------------------------------------
function Test:AddCommand_vrCommandsMissing()
  local cid = self.mobileSession:SendRPC("AddCommand",
    {
      cmdID = 501,
      menuParams =
      {
        parentID = 0,
        position = 0,
        menuName ="Command501"
      },
      cmdIcon =
      {
        value ="icon.png",
        imageType ="DYNAMIC"
      }
    })
  EXPECT_HMICALL("UI.AddCommand",
    {
      cmdID = 501,
      menuParams =
      {
        parentID = 0,
        position = 0,
        menuName ="Command501"
      },
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
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  EXPECT_NOTIFICATION("OnHashChange")
end
-- -------------------------------------------Postcondition-------------------------------------
common_steps:StopSDL("StopSDL")
