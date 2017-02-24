-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

-------------------------------------------Preconditions-------------------------------------
-- Register App -> Activate App
common_steps:PreconditionSteps("PreconditionSteps", 7)

--------------------------------------------BODY---------------------------------------------
-- Verify: when menuTitle param is invalid and all images do not exist
-- SDL->MOB: RPC (success:false, resultCode:"INVALID_DATA")
---------------------------------------------------------------------------------------------
function Test:Verify_MenuTitleIncorrect_ImageNotExist_INVALID_DATA()
  common_functions:DelayedExp(2000)
  local cid = self.mobileSession:SendRPC("SetGlobalProperties",
    {
      --menuTitle = "Menu Title",
      menuTitle = 123,
      timeoutPrompt =
      {
        {
          text = "Timeout prompt",
          type = "TEXT"
        }
      },
      vrHelp =
      {
        {
          position = 1,
          image =
          {
            value = "invalidImage.png",
            imageType = "DYNAMIC"
          },
          text = "VR help item"
        }
      },
      menuIcon =
      {
        value = "invalidImage.png",
        imageType = "DYNAMIC"
      },
      helpPrompt =
      {
        {
          text = "Help prompt",
          type = "TEXT"
        }
      },
      vrHelpTitle = "VR help title",
      keyboardProperties =
      {
        keyboardLayout = "QWERTY",
        keypressMode = "SINGLE_KEYPRESS",
        language = "EN-US"
      }
    })
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)
end

-------------------------------------------Postconditions-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegisterApp", const.default_app_name)
common_steps:StopSDL("Postcondition_StopSDL")
