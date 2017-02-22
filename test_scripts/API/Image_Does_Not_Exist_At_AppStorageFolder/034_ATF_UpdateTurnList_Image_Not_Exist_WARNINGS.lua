-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

------------------------------------ Common Variables ---------------------------------------
local app_storage_folder = common_functions:GetValueFromIniFile("AppStorageFolder")
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
common_steps:PutFile("PutFile", "icon.png")

--------------------------------------------BODY---------------------------------------------
-- Verify: when all params are correct and image of cmdIcon doesn't exist
-- SDL->MOB: RPC (success:false, resultCode:"WARNINGS", info:"Reference image(s) not found")
---------------------------------------------------------------------------------------------
function Test:Verify_AllParamsCorrect_ImageNotExist_WARNINGS()
  local cid = self.mobileSession:SendRPC("UpdateTurnList", {
      turnList =
      {
        {
          navigationText ="Text",
          turnIcon =
          {
            value = "action.png",
            imageType ="DYNAMIC"
          }
        }
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
        }
      }
    })
  EXPECT_HMICALL("Navigation.UpdateTurnList",
    {
      turnList = {
        {
          navigationText =
          {
            fieldText = "Text",
            fieldName = "turnText"
          },
          turnIcon =
          {
            value = storagePath.. "invalidImage.png",
            imageType ="DYNAMIC"
          }
        }
      },
      softButtons =
      {
        {
          type = "BOTH",
          text = "Close",
          image =
          {
            value = storagePath .. "invalidImage.png",
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
            value = storagePath .. "invalidImage.png",
            imageType = "DYNAMIC"
          },
          softButtonID = 5,
          systemAction = "DEFAULT_ACTION"
        }
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
common_steps:RestoreIniFile("Postcondition_Restore_PreloadedPT", "sdl_preloaded_pt.json")
