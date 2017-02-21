-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

------------------------------------ Common Variables ---------------------------------------
local appName = config.application1.registerAppInterfaceParams.appName

------------------------------------ Preconditions ------------------------------------------
--1. Delete app_info.dat, logs and policy table
common_functions:DeleteLogsFileAndPolicyTable()
--2. Backup sdl_preloaded_pt.json then updatePolicy
common_functions:BackupFile("sdl_preloaded_pt.json")
update_policy:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/PTU_For_Image_Not_Exist.json")
--3. Activate application
common_steps:PreconditionSteps("PreconditionSteps", 7)

--------------------------------------------BODY---------------------------------------------
-- Verify: when text param is invalid and image of softButtons doesn't exist
-- SDL->MOB: RPC (success:false, resultCode:"INVALID_DATA")
---------------------------------------------------------------------------------------------
function Test:Verify_TextInvalid_ImageNotExist_INVALID_DATA()
  common_functions:DelayedExp(2000)
  local cor_id = self.mobileSession:SendRPC("AlertManeuver", {
      ttsChunks =
      {
        {
          --text ="FirstAlert",
          text =123,
          type ="TEXT"
        },
        {
          text ="SecondAlert",
          type ="TEXT"
        },
      },
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
          softButtonID = 821,
          systemAction = "DEFAULT_ACTION"
        },
        {
          type = "BOTH",
          text = "AnotherClose",
          image =
          {
            value = "invalidImage.png",
            imageType = "DYNAMIC"
          },
          isHighlighted = false,
          softButtonID = 822,
          systemAction = "DEFAULT_ACTION"
        },
      }
    })
  EXPECT_RESPONSE(cor_id, { success = false, resultCode = "INVALID_DATA" })
  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)
end

-------------------------------------------Postconditions-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegisterApp", appName)
common_steps:StopSDL("Postcondition_StopSDL")
common_steps:RestoreIniFile("Postcondition_Restore_PreloadedPT", "sdl_preloaded_pt.json")
