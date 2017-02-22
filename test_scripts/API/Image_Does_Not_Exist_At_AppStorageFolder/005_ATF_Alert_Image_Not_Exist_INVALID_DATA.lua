-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

------------------------------------ Common Variables ---------------------------------------
local appName = config.application1.registerAppInterfaceParams.appName

-------------------------------------------Preconditions-------------------------------------
-- Register App -> Activate App
common_steps:PreconditionSteps("PreconditionSteps", 7)

--------------------------------------------BODY---------------------------------------------
-- Verify: when alertText1 param is invalid and image of softButtons doesn't exist
-- SDL->MOB: RPC (success:false, resultCode:"INVALID_DATA")
---------------------------------------------------------------------------------------------
function Test:Verify_AlertText1Incorrect_ImageNotExist_INVALID_DATA()
  local cid = self.mobileSession:SendRPC("Alert",
    {
      --alertText1 = "alertText1",
      alertText1 = 123,
      alertText2 = "alertText2",
      alertText3 = "alertText3",
      ttsChunks =
      {
        {
          text = "TTSChunk",
          type = "TEXT"
        }
      },
      duration = 3000,
      playTone = true,
      progressIndicator = true,
      softButtons =
      {
        {
          type = "BOTH",
          text = "Close",
          image =
          {
            value = "invalidImage.png",
            imageType = "DYNAMIC"
          },
          isHighlighted = true,
          softButtonID = 3,
          systemAction = "DEFAULT_ACTION"
        },
        {
          type = "TEXT",
          text = "Keep",
          isHighlighted = true,
          softButtonID = 4,
          systemAction = "DEFAULT_ACTION"
        },
        {
          type = "IMAGE",
          image =
          {
            value = "invalidImage.png",
            imageType = "DYNAMIC"
          },
          softButtonID = 5,
          systemAction = "DEFAULT_ACTION"
        },
      }
    })
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
end

-------------------------------------------Postconditions-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegisterApp", appName)
common_steps:StopSDL("Postcondition_StopSDL")
