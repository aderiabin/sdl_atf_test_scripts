-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

-------------------------------------------Preconditions-------------------------------------
-- Register App -> Activate App
common_steps:PreconditionSteps("PreconditionSteps", 7)
common_steps:PutFile("PreconditionSteps_PutFile_action.png", "action.png")

--------------------------------------------BODY---------------------------------------------
-- Verify: when all params are correct and image of graphic does not exist
-- SDL->MOB: RPC (success:false, resultCode:"WARNINGS", info:"Reference image(s) not found")
---------------------------------------------------------------------------------------------
function Test:Verify_AllParamsCorrect_ImageNotExist_WARNINGS()
  local invalid_image_full_path = common_functions:GetFullPathIcon("invalidImage.png")
  local action_image_full_path = common_functions:GetFullPathIcon("action.png")
  local cid = self.mobileSession:SendRPC("Show", {
      mainField1 = "a",
      statusBar= "a",
      mediaClock = "a",
      mediaTrack = "a",
      alignment = "CENTERED",
      graphic =
      {
        imageType = "DYNAMIC",
        value = "invalidImage.png"
      },
      secondaryGraphic =
      {
        imageType = "DYNAMIC",
        value = "action.png"
      },
      softButtons =
      {
        {
          type = "BOTH",
          text = "Close",
          image =
          {
            value = "action.png",
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
            value = "action.png",
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
        value = invalid_image_full_path
      },
      alignment = "CENTERED",
      secondaryGraphic =
      {
        imageType = "DYNAMIC",
        value = action_image_full_path
      },
      softButtons =
      {
        {
          type = "BOTH",
          text = "Close",
          image =
          {
            value = action_image_full_path,
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
            value = action_image_full_path,
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
common_steps:UnregisterApp("Postcondition_UnRegisterApp", const.default_app_name)
common_steps:StopSDL("Postcondition_StopSDL")
