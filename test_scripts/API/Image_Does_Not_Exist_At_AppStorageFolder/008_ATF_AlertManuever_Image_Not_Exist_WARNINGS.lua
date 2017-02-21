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

--------------------------------------------BODY---------------------------------------------
-- Verify: when all params are correct and image of softButtons doesn't exist
-- SDL->MOB: RPC (success:false, resultCode:"WARNINGS", info:"Reference image(s) not found")
---------------------------------------------------------------------------------------------
function Test:Verify_AllParamsCorrect_ImageNotExist_WARNINGS()
  local cid = self.mobileSession:SendRPC("AlertManeuver",
    {
      ttsChunks =
      {
        {
          text ="FirstAlert",
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
  EXPECT_HMICALL("Navigation.AlertManeuver",
    {
      appID = self.applications["Test Application"],
      softButtons =
      {
        {
          type = "BOTH",
          text = "Close",
          image =
          {
            value = storagePath.."invalidImage.png",
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
            value = storagePath.."invalidImage.png",
            imageType = "DYNAMIC"
          },
          isHighlighted = false,
          softButtonID = 822,
          systemAction = "DEFAULT_ACTION"
        }
      }
    })
  :Do(function(_,data)
      local function alert_response()
        self.hmiConnection:SendError(data.id, data.method, "WARNINGS","Reference image(s) not found")
      end
      RUN_AFTER(alert_response, 2000)
    end)
  local speak_id
  EXPECT_HMICALL("TTS.Speak",
    {
      ttsChunks =
      {
        {
          text ="FirstAlert",
          type ="TEXT"
        },
        {
          text ="SecondAlert",
          type ="TEXT"
        }
      },
      speakType = "ALERT_MANEUVER"
    })
  :Do(function(_,data)
      self.hmiConnection:SendNotification("TTS.Started")
      speak_id = data.id
      local function speakResponse()
        self.hmiConnection:SendResponse(speak_id, "TTS.Speak", "SUCCESS", { })
        self.hmiConnection:SendNotification("TTS.Stopped")
      end
      RUN_AFTER(speakResponse, 1000)
    end)
  EXPECT_NOTIFICATION("OnHMIStatus",
    { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "ATTENUATED" },
    { systemContext = "MAIN", hmiLevel = level, audioStreamingState = "AUDIBLE" })
  :Times(2)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", info = "Reference image(s) not found"})
end

-------------------------------------------Postconditions-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegisterApp", appName)
common_steps:StopSDL("Postcondition_StopSDL")
common_steps:RestoreIniFile("Postcondition_Restore_PreloadedPT", "sdl_preloaded_pt.json")
