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
-- Verify: when all params are correct and image of softButtons doesn't exist
-- SDL->MOB: RPC (success:false, resultCode:"WARNINGS", info:"Reference image(s) not found")
---------------------------------------------------------------------------------------------
function Test:Verify_AllParamsCorrect_ImageNotExist_WARNINGS()
  local cid = self.mobileSession:SendRPC("ScrollableMessage", {
      scrollableMessageBody = "abc",
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
    }
  )
  EXPECT_HMICALL("UI.ScrollableMessage",{
      messageText = {
        fieldName = "scrollableMessageBody",
        fieldText = "abc"
      },
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
    } )
  :Do(function(_,data)
      self.hmiConnection:SendError(data.id, data.method, "WARNINGS","Reference image(s) not found")
    end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", info = "Reference image(s) not found"})
end

-------------------------------------------Postconditions-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegisterApp", appName)
common_steps:StopSDL("Postcondition_StopSDL")
