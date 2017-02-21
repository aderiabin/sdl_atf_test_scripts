-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

------------------------------------ Common Variables ---------------------------------------
local appName = config.application1.registerAppInterfaceParams.appName

-------------------------------------------Preconditions-------------------------------------
-- Register App -> Activate App
common_steps:PreconditionSteps("PreconditionSteps", 7)

--------------------------------------------BODY---------------------------------------------
-- Verify: when scrollableMessageBody param is invalid and image of softButtons doesn't exist
-- SDL->MOB: RPC (success:false, resultCode:"INVALID_DATA")
---------------------------------------------------------------------------------------------
function Test:Verify_ScrollableMessageBodyIncorrect_ImageNotExist_INVALID_DATA()
  common_functions:DelayedExp(2000)
  local cid = self.mobileSession:SendRPC("ScrollableMessage", {
      --scrollableMessageBody = "abc",
      scrollableMessageBody = abc,
      softButtons =
      {
        {
          softButtonID = 1,
          text = "Button1",
          type = "BOTH",
          image =
          {
            value = "invalidImage.png",
            imageType = "DYNAMIC"
          },
          isHighlighted = false,
          systemAction = "DEFAULT_ACTION"
        },
        {
          softButtonID = 2,
          text = "Button2",
          type = "BOTH",
          image =
          {
            value = "invalidImage.png",
            imageType = "DYNAMIC"
          },
          isHighlighted = false,
          systemAction = "DEFAULT_ACTION"
        }
      },
    })
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)
end

-------------------------------------------Postconditions-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegisterApp", appName)
common_steps:StopSDL("Postcondition_StopSDL")
