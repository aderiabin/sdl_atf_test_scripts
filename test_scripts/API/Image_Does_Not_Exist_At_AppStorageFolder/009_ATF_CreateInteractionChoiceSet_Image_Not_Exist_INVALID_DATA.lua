-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

------------------------------------ Common Variables ---------------------------------------
local storagePath = config.pathToSDL .. "storage/"
..config.application1.registerAppInterfaceParams.appID.. "_" .. config.deviceMAC.. "/"
local appName = config.application1.registerAppInterfaceParams.appName

-------------------------------------------Preconditions-------------------------------------
-- Register App -> Activate App
common_steps:PreconditionSteps("PreconditionSteps", 7)

--------------------------------------------BODY---------------------------------------------
-- Verify: when interactionChoiceSetID param is invalid and image of choiceSet doesn't exist
-- SDL->MOB: RPC (success:false, resultCode:"INVALID_DATA")
---------------------------------------------------------------------------------------------
function Test:Verify_InteractionChoiceSetIDIncorrect_ImageNotExist_INVALID_DATA()
  local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
    {
      -- interactionChoiceSetID = 1001,
      interactionChoiceSetID = "abc",
      choiceSet =
      {

        {
          choiceID = 1001,
          menuName ="Choice1001",
          vrCommands =
          {
            "Choice1001",
          },
          image =
          {
            value = storagePath.."icon888.png",
            imageType ="DYNAMIC",
          },
        }
      }
    })

  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
end

-------------------------------------------Postconditions-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegisterApp", appName)
common_steps:StopSDL("Postcondition_StopSDL")
