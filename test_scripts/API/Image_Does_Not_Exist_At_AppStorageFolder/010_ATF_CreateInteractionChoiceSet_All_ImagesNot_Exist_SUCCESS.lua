-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

-------------------------------------------Preconditions-------------------------------------
-- Register App -> Activate App
common_steps:PreconditionSteps("PreconditionSteps", 7)

--------------------------------------------BODY---------------------------------------------
-- Verify: when all params are correct and image and secondaryImage of choiceSet doesn't exist
-- SDL->MOB: RPC (success:true, resultCode:"SUCCESS")
---------------------------------------------------------------------------------------------
function Test:Verify_AllParamsCorrect_ImageNotExist_SUCCESS()
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
  EXPECT_HMICALL("VR.AddCommand",
    {
      cmdID = 1001,
      appID = applicationID,
      type = "Choice",
      vrCommands = {"Choice1001" }
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
    end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  EXPECT_NOTIFICATION("OnHashChange")
end

-------------------------------------------Postconditions-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegisterApp", const.default_app_name)
common_steps:StopSDL("Postcondition_StopSDL")
