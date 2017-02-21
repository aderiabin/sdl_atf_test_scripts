-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

------------------------------------ Common Variables ---------------------------------------
local appName = config.application1.registerAppInterfaceParams.appName

------------------------------------ Precondition -------------------------------------------
--1. Delete app_info.dat, logs and policy table
common_functions:DeleteLogsFileAndPolicyTable()
--2. Backup sdl_preloaded_pt.json then updatePolicy
common_functions:BackupFile("sdl_preloaded_pt.json")
update_policy:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/PTU_For_Image_Not_Exist.json")
--3. Activate application
common_steps:PreconditionSteps("PreconditionSteps", 7)

--------------------------------------------BODY---------------------------------------------
-- Verify: when navigationText param is invalid and image of cmdIcon doesn't exist
-- SDL->MOB: RPC (success:false, resultCode:"INVALID_DATA")
---------------------------------------------------------------------------------------------
function Test:Verify_NavigationTextIncorrect_ImageNotExist_INVALID_DATA()
  common_functions:DelayedExp(2000)
  local request = {
    turnList =
    {
      {
        --navigationText ="Text",
        navigationText =123,
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
  }
  local cid = self.mobileSession:SendRPC("UpdateTurnList", request)
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)
end

-------------------------------------------Postconditions-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegisterApp", appName)
common_steps:StopSDL("Postcondition_StopSDL")
common_steps:RestoreIniFile("Postcondition_Restore_PreloadedPT", "sdl_preloaded_pt.json")
