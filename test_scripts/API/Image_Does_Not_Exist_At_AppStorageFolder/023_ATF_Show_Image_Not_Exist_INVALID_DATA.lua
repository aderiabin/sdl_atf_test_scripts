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
-- Verify: when mainField1 param is invalid and all images do not exist
-- SDL->MOB: RPC (success:false, resultCode:"INVALID_DATA")
---------------------------------------------------------------------------------------------
function Test:Verify_MainField1Incorrect_ImageNotExist_INVALID_DATA()
  local request_params =
  {
    --mainField1 = "a",
    mainField1 = 1,
    mainField2 = "a",
    mainField3 = "a",
    mainField4 = "a",
    statusBar= "a",
    mediaClock = "a",
    mediaTrack = "a",
    alignment = "CENTERED",
    graphic =
    {
      imageType = "DYNAMIC",
      value = storagePath.."icon888.png"
    },
    secondaryGraphic =
    {
      imageType = "DYNAMIC",
      value = storagePath.."icon888.png"
    }
  }
  local cid = self.mobileSession:SendRPC("Show", request_params)
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)
end
-------------------------------------------Postconditions-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegisterApp", appName)
common_steps:StopSDL("Postcondition_StopSDL")
