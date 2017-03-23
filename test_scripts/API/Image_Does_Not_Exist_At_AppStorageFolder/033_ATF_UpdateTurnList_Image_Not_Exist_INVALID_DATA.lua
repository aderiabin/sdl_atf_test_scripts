-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

------------------------------------ Precondition -------------------------------------------
common_functions:BackupFile("sdl_preloaded_pt.json")
update_policy:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/PTU_For_Image_Not_Exist.json")
-- Activate application
common_steps:PreconditionSteps("PreconditionSteps", 7)

--------------------------------------------BODY---------------------------------------------
-- Verify: when navigationText param is invalid and image of cmdIcon doesn't exist
-- SDL->MOB: RPC (success:false, resultCode:"INVALID_DATA")
---------------------------------------------------------------------------------------------
function Test:Verify_NavigationTextIncorrect_ImageNotExist_INVALID_DATA()
  local cid = self.mobileSession:SendRPC("UpdateTurnList", {
      turnList =
      {
        {
          --navigationText ="Text",
          navigationText = 123,
          turnIcon =
          {
            value = "invalidImage.png",
            imageType ="DYNAMIC"
          }
        }
      },
      softButtons =
      {
        {
          type ="BOTH",
          text ="Close",
          image =
          {
            value = "invalidImage.png",
            imageType ="DYNAMIC"
          },
          isHighlighted = true,
          softButtonID = 111,
          systemAction ="DEFAULT_ACTION"
        }
      }
    })
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
end

-------------------------------------------Postconditions-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegisterApp", const.default_app_name)
common_steps:StopSDL("Postcondition_StopSDL")
common_steps:RestoreIniFile("Postcondition_Restore_PreloadedPT", "sdl_preloaded_pt.json")
