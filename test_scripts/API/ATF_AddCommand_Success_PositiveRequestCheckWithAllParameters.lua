-- This test script is intended to check positive cases for function AddCommand with all
-- parameters. These parameters are in boundary conditions.

-- -------------------------------------------Required Resources-------------------------------

require('user_modules/all_common_modules')

-- -------------------------------------------Common Variables----------------------------------

local image_file_name = "icon.png"

-- -------------------------------------------Preconditions-------------------------------------

common_steps:PreconditionSteps("Preconditions",7)
common_steps:PutFile("PutFile", image_file_name)
common_preconditions:SendLocationPreconditionUpdateHMICap()

-- -----------------------------------------------Body-------------------------------------------

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
        value =image_file_name,
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

    local full_path_icon  = table.concat({config.pathToSDL, "storage/", config.application1.registerAppInterfaceParams.appID, 
          "_", config.deviceMAC, "/", image_file_name})
 
    if data.params.cmdIcon.value ~= full_path_icon then
        local color = 31
        local msg1 = "value of menuIcon is WRONG. Expected: ~".. value_icon .. "; Real: " .. data.params.cmdIcon.value 
        common_functions:UserPrint(color, msg1)
        return false
     end   
    
    if not (data.params.cmdIcon.imageType == "DYNAMIC") then
        local color = 31
        local msg = "imageType of menuIcon is WRONG. Expected: DYNAMIC; Real: " .. data.params.cmdIcon.imageType
        common_functions:UserPrint(color, msg)
        return false
   end
    return true
  end)
  :Do(function(a, data)
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
