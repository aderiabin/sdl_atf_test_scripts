-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

------------------------------------ Common Variables ---------------------------------------
local app_storage_folder = common_functions:GetValueFromIniFile"AppStorageFolder"
local storagePath = config.pathToSDL .. app_storage_folder .. "/"
..config.application1.registerAppInterfaceParams.appID.. "_" .. config.deviceMAC.. "/"
local appName = config.application1.registerAppInterfaceParams.appName

------------------------------------ Precondition -------------------------------------------
--1. Delete app_info.dat, logs and policy table
common_functions:DeleteLogsFileAndPolicyTable()
--2. Backup sdl_preloaded_pt.json then updatePolicy
common_functions:BackupFile("sdl_preloaded_pt.json")
update_policy:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/PTU_For_Image_Not_Exist.json")
--3. Activate application
common_steps:PreconditionSteps("PreconditionSteps", 7)
--4. PutFiles
common_steps:PutFile("PreconditionSteps_PutFile_action.png", "action.png")
common_steps:PutFile("PreconditionSteps_PutFile_icon.png", "icon.png")

--------------------------------------------BODY---------------------------------------------
-- Verify: when all params are correct and image of turnIcon does not exist
-- SDL->MOB: RPC (success:false, resultCode:"WARNINGS", info:"Reference image(s) not found")
---------------------------------------------------------------------------------------------
function Test:Verify_AllParamsCorrect_ImageNotExist_WARNINGS()
  local request_paramters = {
    navigationText1 ="navigationText1",
    navigationText2 ="navigationText2",
    eta ="12:34",
    totalDistance ="100miles",
    turnIcon =
    {
      value =storagePath.."invalidImage.png",
      imageType ="DYNAMIC"
    },
    nextTurnIcon =
    {
      value = storagePath.."action.png",
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
          value =storagePath.."icon.png",
          imageType ="DYNAMIC"
        },
        isHighlighted = true,
        softButtonID = 44,
        systemAction ="DEFAULT_ACTION"
      },
    },
  }
  local cid = self.mobileSession:SendRPC("ShowConstantTBT", request_paramters)
  EXPECT_HMICALL("Navigation.ShowConstantTBT", request_paramters)
  :Do(function(_,data)
      self.hmiConnection:SendError(data.id, data.method, "WARNINGS","Reference image(s) not found")
    end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", info = "Reference image(s) not found"})
end

-------------------------------------------Postconditions-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegisterApp", appName)
common_steps:StopSDL("Postcondition_StopSDL")
common_steps:RestoreIniFile("Postcondition_Restore_PreloadedPT", "sdl_preloaded_pt.json")
