-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

------------------------------------ Precondition -------------------------------------------
common_functions:BackupFile("sdl_preloaded_pt.json")
update_policy:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/PTU_For_Image_Not_Exist.json")
-- Activate application
common_steps:PreconditionSteps("PreconditionSteps", 7)
common_steps:PutFile("PreconditionSteps_PutFile_action.png", "action.png")

--------------------------------------------BODY---------------------------------------------
-- Verify: when all params are correct and image of turnIcon does not exist
-- SDL->MOB: RPC (success:true, resultCode:"WARNINGS", info:"Reference image(s) not found")
---------------------------------------------------------------------------------------------
function Test:Verify_AllParamsCorrect_ImageNotExist_WARNINGS()
  local invalid_image_full_path = common_functions:GetFullPathIcon("invalidImage.png")
  local action_image_full_path = common_functions:GetFullPathIcon("action.png")
  local cid = self.mobileSession:SendRPC("ShowConstantTBT", {
      navigationText1 ="navigationText1",
      navigationText2 ="navigationText2",
      eta ="12:34",
      totalDistance ="100miles",
      turnIcon =
      {
        value = "action.png",
        imageType ="DYNAMIC"
      },
      nextTurnIcon =
      {
        value = "invalidImage.png",
        imageType ="DYNAMIC"
      },
      distanceToManeuver = 50.5,
      distanceToManeuverScale = 100.5,
      maneuverComplete = false,
      softButtons =
      {
        {
          type ="BOTH",
          text ="Close",
          image =
          {
            value = "icon.png",
            imageType ="DYNAMIC"
          },
          isHighlighted = true,
          softButtonID = 44,
          systemAction ="DEFAULT_ACTION"
        },
      },
    })
  EXPECT_HMICALL("Navigation.ShowConstantTBT", {
      navigationText1 ="navigationText1",
      navigationText2 ="navigationText2",
      eta ="12:34",
      totalDistance ="100miles",
      turnIcon =
      {
        value = action_image_full_path,
        imageType ="DYNAMIC"
      },
      nextTurnIcon =
      {
        value = action_image_full_path,
        imageType ="DYNAMIC"
      },
      distanceToManeuver = 50.5,
      distanceToManeuverScale = 100.5,
      maneuverComplete = false,
      softButtons =
      {
        {
          type ="BOTH",
          text ="Close",
          image =
          {
            value = invalid_image_full_path,
            imageType ="DYNAMIC"
          },
          isHighlighted = true,
          softButtonID = 44,
          systemAction ="DEFAULT_ACTION"
        },
      },
    })
  :Do(function(_,data)
      self.hmiConnection:SendError(data.id, data.method, "WARNINGS","Reference image(s) not found")
    end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", info = "Reference image(s) not found"})
end

-------------------------------------------Postconditions-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegisterApp", const.default_app_name)
common_steps:StopSDL("Postcondition_StopSDL")
common_steps:RestoreIniFile("Postcondition_Restore_PreloadedPT", "sdl_preloaded_pt.json")
