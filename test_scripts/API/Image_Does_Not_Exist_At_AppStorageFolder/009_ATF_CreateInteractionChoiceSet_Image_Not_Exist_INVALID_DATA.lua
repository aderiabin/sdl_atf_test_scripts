-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

-------------------------------------------Preconditions-------------------------------------
-- Register App -> Activate App
common_steps:PreconditionSteps("PreconditionSteps", 7)

--------------------------------------------BODY---------------------------------------------
-- Verify: when interactionChoiceSetID param is invalid and image of choiceSet doesn't exist
-- SDL->MOB: RPC (success:false, resultCode:"INVALID_DATA")
---------------------------------------------------------------------------------------------
function Test:Verify_InteractionChoiceSetIDIncorrect_ImageNotExist_INVALID_DATA()
  common_functions:DelayedExp(2000)
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
            value = "invalidImage_1.png",
            imageType ="DYNAMIC",
          },
          secondaryImage=
          {
            value = "invalidImage_2.png",
            imageType ="DYNAMIC",
          }
        }
      }
    })

  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)
end

-------------------------------------------Postconditions-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegisterApp", const.default_app_name)
common_steps:StopSDL("Postcondition_StopSDL")
