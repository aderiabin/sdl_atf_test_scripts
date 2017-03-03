-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

------------------------------------ Precondition -------------------------------------------
common_functions:BackupFile("sdl_preloaded_pt.json")
update_policy:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/PTU_For_Image_Not_Exist.json")
-- Activate application
common_steps:PreconditionSteps("PreconditionSteps", 7)

--------------------------------------------BODY---------------------------------------------
-- Verify: when navigationText1 param is invalid and all images do not exist
-- SDL->MOB: RPC (success:false, resultCode:"INVALID_DATA")
---------------------------------------------------------------------------------------------
function Test:Verify_NavigationText1Incorrect_ImageNotExist_INVALID_DATA()
  local request_paramters = {
    --navigationText1 ="navigationText1",
    navigationText1 =123,
    navigationText2 ="navigationText2",
    eta ="12:34",
    totalDistance ="100miles",
    turnIcon =
    {
      value ="invalidImage.png",
      imageType ="DYNAMIC"
    },
    nextTurnIcon =
    {
      value = "action.png",
      imageType ="DYNAMIC"
    },
    distanceToManeuver = 50.5,
    distanceToManeuverScale = 100.5,
    maneuverComplete = false,
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
  }
  local cid = self.mobileSession:SendRPC("ShowConstantTBT", request_paramters)
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
end

-------------------------------------------Postconditions-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegisterApp", const.default_app_name)
common_steps:StopSDL("Postcondition_StopSDL")
common_steps:RestoreIniFile("Postcondition_Restore_PreloadedPT", "sdl_preloaded_pt.json")
