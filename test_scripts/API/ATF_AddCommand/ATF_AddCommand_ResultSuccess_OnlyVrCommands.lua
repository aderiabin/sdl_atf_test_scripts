--Requirements: APPLINK-19333

--Description:
--In case the request comes to SDL when the command has only VR menu.
--The command should be added only to VR Commands Menu.
--SDL must respond with resultCode "Success" and success:"true" value.

-- Performed steps:
-- 1. Application sends "AddCommand" request which contains such parameters: cmdId and vrCommands

-- Expected result:
-- 1. SDL responds with resultCode:"Success" and success: "true" value

require('user_modules/all_common_modules')
-- -------------------------------------------Preconditions-------------------------------------
common_steps:PreconditionSteps("Preconditions",7)
-- ------------------------------------------Body-----------------------------------------------
function MissingParams(self, cid_parameters)
  local functionName = "AddCommand_OnlyVrCommands"
  Test[functionName] = function(self)
    local cid = self.mobileSession:SendRPC("AddCommand", cid_parameters)
    EXPECT_HMICALL("VR.AddCommand", cid_parameters)
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
    EXPECT_NOTIFICATION("OnHashChange")
  end
end
function AddCommand_VRCommandsOnly()
  local cid_parameters =
  {
    cmdID = 1000,
    vrCommands =
    {
      "OnlyVRCommand"
    }
  }
  MissingParams(self, cid_parameters)
end
AddCommand_VRCommandsOnly()
-- -------------------------------------------Postcondition-------------------------------------
common_steps:StopSDL("StopSDL")
