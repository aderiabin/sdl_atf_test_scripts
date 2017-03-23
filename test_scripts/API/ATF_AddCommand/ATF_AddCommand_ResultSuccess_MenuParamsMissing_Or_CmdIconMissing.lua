--Requirements: APPLINK-19333

--Description:
--In case the request comes to SDL when the command has only VR menu. There are two cases in this
--script: only VR menu and cnmId are present in the first way and in the second one cmdIcon
--additionally present. The command should be added only to VR Commands Menu.
--All parameters are in boundary conditions
--SDL must respond with resultCode "Success" and success:"true" value.

-- Performed steps:
-- 1. Application sends "AddCommand" request which contains such parameters: cmdId, vrCommands,
-- cmdIcon for the first case and cmdId, vrCommands for another case

-- Expected result:
-- 1. SDL responds with resultCode:"Success" and success: "true" value

require('user_modules/all_common_modules')
local const = require('user_modules/consts')
-- -------------------------------------------Preconditions-------------------------------------
common_steps:PreconditionSteps("Preconditions",7)
common_steps:PutFile("PutFile", const.image_icon_png)
-- ------------------------------------------Body-----------------------------------------------
function MissingParams(self, full_name, cid_parameters)
local functionName = "AddCommand_" .. full_name
    Test[functionName] = function(self)
      local cid = self.mobileSession:SendRPC("AddCommand", cid_parameters)
      --we don't expect that this parameters comes in order to absence MenuParams
      cid_parameters.cmdIcon = nil
      EXPECT_HMICALL("VR.AddCommand", cid_parameters)
      :Do(function(_,data)
         self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        end)
      EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
      EXPECT_NOTIFICATION("OnHashChange")
    end
  end
function AddCommand_VRCommandsOnly()
  for i = 1,2 do
    local cid_parameters =
    {
      cmdID = i,
      vrCommands =
      {
        "OnlyVRCommand" .. i
      },
      cmdIcon =
      {
        value ="icon.png",
        imageType ="DYNAMIC"
      }
    }
    if i == 1 then
      full_name = "MenuParamsMissing"
    elseif i == 2 then
      full_name = "MenuParamsMissingCmdIconMissing"
      cid_parameters.cmdIcon = nil
    end
   MissingParams(self, full_name, cid_parameters)  
  end
end
AddCommand_VRCommandsOnly()
-- -------------------------------------------Postcondition-------------------------------------
common_steps:StopSDL("StopSDL")
