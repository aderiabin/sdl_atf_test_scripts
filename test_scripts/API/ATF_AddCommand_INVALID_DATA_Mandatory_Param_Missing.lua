-------------------------------------Required Shared Libraries-------------------------------
require('user_modules/all_common_modules')

------------------------------------ Common Variables ---------------------------------------
local app = config.application1.registerAppInterfaceParams

--------------------------------------Preconditions------------------------------------------
common_steps:PreconditionSteps("Start_SDL_To_Activate_Application", 7)
common_steps:PutFile("Precondition_Put_File", "icon.png")
------------------------------------------Tests-----------------------------------------------
-- This script covers the following requirement:
-- In case:
-- the request "AddCommand" comes without parameters defined as mandatory in mobile API or
-- with optional parameter present but without its parameter difined as mandatory
-- SDL must:
-- respond with resultCode:"INVALID_DATA" and success:"false" value. 
-----------------------------------------------------------------------------------------
function Test:AddCommand_INVALID_DATA_cmdIDMissing()
  local cid = self.mobileSession:SendRPC("AddCommand",
  {
    menuParams =  
    { 
      -- parentID = 1,
      position = 0,
      menuName ="Command1"
    }, 
    vrCommands = 
    { 
      "Voicerecognitioncommandone"
    }, 
    cmdIcon =   
    { 
      value ="icon.png",
      imageType ="DYNAMIC"
    }
  })    
  
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
end
-----------------------------------------------------------------------------------------
function Test:AddCommand_INVALID_DATA_menuParamsMenuNameMissing()
  local cid = self.mobileSession:SendRPC("AddCommand",
  {
    cmdID = 123,
    menuParams =  
    { 
      parentID = 1,
      position = 0
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
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
end
-----------------------------------------------------------------------------------------
function Test:AddCommand_INVALID_DATA_cmdIconValueMissing()
  local cid = self.mobileSession:SendRPC("AddCommand",
  {
    cmdID = 224,
    menuParams =  
    { 
      parentID = 1,
      position = 0,
      menuName ="Command224"
    }, 
    vrCommands = 
    { 
      "CommandTwoTwoFour"
    },
    cmdIcon =   
    {
      imageType ="DYNAMIC"
    }
  })
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
end         
-----------------------------------------------------------------------------------------
function Test:AddCommand_INVALID_DATA_cmdIconImageTypeMissing()
  local cid = self.mobileSession:SendRPC("AddCommand",
  {
    cmdID = 225,
    menuParams =  
    { 
      parentID = 1,
      position = 0,
      menuName ="Command225"
    }, 
    vrCommands = 
    { 
      "CommandTwoTwoFive"
    },
    cmdIcon =   
    {
      value ="icon.png"
    }
  })
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
end
-------------------------------------------------------------------------------------------
function Test:AddCommand_INVALID_DATA_AllParamsMissing()
  local cid = self.mobileSession:SendRPC("AddCommand",
  {
  })    
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
end
---------------------------------------------------------------------------------------------

-------------------------------------------Postcondition-------------------------------------
common_steps:UnregisterApp("UnRegister_App", app.appName)
common_steps:StopSDL("StopSDL")