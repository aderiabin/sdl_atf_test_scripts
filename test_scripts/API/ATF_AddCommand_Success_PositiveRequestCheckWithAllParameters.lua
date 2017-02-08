-- This test script is intended to check positive cases for function AddCommand with all
-- parameters. These parameters are in boundary conditions.

-- -------------------------------------------Required Resources-------------------------------

require('user_modules/all_common_modules')

-- -------------------------------------------Preconditions-------------------------------------

common_steps:PreconditionSteps("Preconditions",7)
common_steps:PutFile("PutFile", "icon.png")

-- -----------------------------------------Body---------------------------------------

function Test:AddCommand_PositiveCaseWithAllParameters()
  local cid = self.mobileSession:SendRPC("AddCommand",
    { cmdID = 11,
      menuParams =
      {
        parentID = 0,
        position = 0,
        menuName ="Commandpositive"
      },
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
      menuParams =
      {
        parentID = 0,
        position = 0,
        menuName ="Commandpositive"
      }
    })
  :ValidIf(function(_, data)

if(data.params.cmdIcon.imageType == "DYNAMIC") then
        return true
      else
        userPrint("[31m imageType of menuIcon is WRONG. Expected: DYNAMIC; Real: " .. data.params.cmdIcon.imageType .. " ")
        return false
      end
if(string.find(data.params.cmdIcon.value, value_Icon) ) then
        return true
      else
        userPrint("[31m value of menuIcon is WRONG. Expected: ~".. value_Icon .. "; Real: " .. data.params.cmdIcon.value .. " ")
        return false
      end
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
