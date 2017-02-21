-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

------------------------------------ Common Variables ---------------------------------------
local storagePath = config.SDLStoragePath
..config.application1.registerAppInterfaceParams.appID.. "_" .. config.deviceMAC.. "/"
local appName = config.application1.registerAppInterfaceParams.appName

-------------------------------------------Preconditions-------------------------------------
-- Register App -> Activate App
common_steps:PreconditionSteps("PreconditionSteps", 7)
common_steps:PutFile("PreconditionSteps_PutFile_action.png", "action.png")

--------------------------------------------BODY---------------------------------------------
-- Verify: when all params are correct and image of choiceSet doesn't exist
-- SDL->MOB: RPC (success:false, resultCode:"WARNINGS", info:"Reference image(s) not found")
---------------------------------------------------------------------------------------------
function Test:Verify_AllParamsCorrect_ImageNotExist_WARNINGS()
  local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
    {
      interactionChoiceSetID = 1001,
      choiceSet =
      {
        {
          choiceID = 1001,
          menuName = "Choice1001",
          vrCommands =
          {
            "Choice1001",
          },
          image =
          {
            value = "invalidImage.png",
            imageType ="DYNAMIC",
          },
          secondaryImage=
          {
            value = "action.png",
            imageType ="DYNAMIC",
          }
        }
      }
    })
  EXPECT_HMICALL("VR.AddCommand",
    {
      cmdID = 1001,
      appID = applicationID,
      type = "Choice",
      vrCommands = {"Choice1001" }
    })
  :Do(function(_,data)
      self.hmiConnection:SendError(data.id, data.method, "WARNINGS","Reference image(s) not found")
    end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", info = "Reference image(s) not found"})
  EXPECT_NOTIFICATION("OnHashChange")
end

-------------------------------------------Postconditions-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegisterApp", appName)
common_steps:StopSDL("Postcondition_StopSDL")
