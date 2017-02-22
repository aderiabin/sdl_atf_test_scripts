-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

------------------------------------ Common Variables ---------------------------------------
local app_storage_folder = common_functions:GetValueFromIniFile("AppStorageFolder")
local storagePath = config.pathToSDL .. app_storage_folder .. "/"
..config.application1.registerAppInterfaceParams.appID.. "_" .. config.deviceMAC.. "/"
local appName = config.application1.registerAppInterfaceParams.appName

-------------------------------------------Preconditions-------------------------------------
-- Register App -> Activate App
common_steps:PreconditionSteps("PreconditionSteps", 7)

--------------------------------------------BODY---------------------------------------------
-- Verify: when all params are correct and all images do not exist
-- SDL->MOB: RPC (success:false, resultCode:"WARNINGS", info:"Reference image(s) not found")
---------------------------------------------------------------------------------------------
function Test:Verify_AllParamsCorrect_ImageNotExist_WARNINGS()
  local cid = self.mobileSession:SendRPC("Show", {
      mainField1 = "a",
      statusBar= "a",
      mediaClock = "a",
      mediaTrack = "a",
      alignment = "CENTERED",
      graphic =
      {
        imageType = "DYNAMIC",
        value = "invalidImage_1.png"
      },
      secondaryGraphic =
      {
        imageType = "DYNAMIC",
        value = "invalidImage_2.png"
      },
      softButtons =
      {
        {
          type = "BOTH",
          text = "Close",
          image =
          {
            value = "invalidImage_3.png",
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
            value = "invalidImage_4.png",
            imageType = "DYNAMIC"
          },
          softButtonID = 5,
          systemAction = "DEFAULT_ACTION"
        },
      }
    })
  EXPECT_HMICALL("UI.Show", {
      showStrings =
      {
        {
          fieldName = "mainField1",
          fieldText = "a"
        },
        {
          fieldName = "mediaClock",
          fieldText = "a"
        },
        {
          fieldName = "mediaTrack",
          fieldText = "a"
        },
        {
          fieldName = "statusBar",
          fieldText = "a"
        }
      },
      graphic =
      {
        imageType = "DYNAMIC",
        value = storagePath .. "invalidImage_1.png"
      },
      alignment = "CENTERED",
      secondaryGraphic =
      {
        imageType = "DYNAMIC",
        value = storagePath .. "invalidImage_2.png"
      },
      softButtons =
      {
        {
          type = "BOTH",
          text = "Close",
          image =
          {
            value = storagePath .. "invalidImage_3.png",
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
            value = storagePath .. "invalidImage_4.png",
            imageType = "DYNAMIC"
          },
          softButtonID = 5,
          systemAction = "DEFAULT_ACTION"
        },
      }
    })
  :Do(function(_,data)
      self.hmiConnection:SendError(data.id, data.method, "WARNINGS","Reference image(s) not found")
    end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", info = "Reference image(s) not found"})
end

-------------------------------------------Postconditions-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegisterApp", appName)
common_steps:StopSDL("Postcondition_StopSDL")
