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
-- Verify: when scrollableMessageBody param is invalid and image of softButtons doesn't exist
-- SDL->MOB: RPC (success:false, resultCode:"INVALID_DATA")
---------------------------------------------------------------------------------------------
function Test:Verify_ScrollableMessageBodyIncorrect_ImageNotExist_INVALID_DATA()
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
            value = storagePath.."icon888.png",
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
            value = storagePath.."icon888.png",
            imageType = "DYNAMIC"
          },
          isHighlighted = false,
          systemAction = "DEFAULT_ACTION"
        }
      },
    })
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
end

-------------------------------------------Postconditions-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegisterApp", appName)
common_steps:StopSDL("Postcondition_StopSDL")
