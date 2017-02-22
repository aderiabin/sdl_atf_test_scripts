-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

------------------------------------ Common Variables ---------------------------------------
local app_storage_folder = common_functions:GetValueFromIniFile("AppStorageFolder")
local storagePath = config.pathToSDL .. app_storage_folder .. "/"
..config.application1.registerAppInterfaceParams.appID.. "_" .. config.deviceMAC.. "/"
local appName = config.application1.registerAppInterfaceParams.appName

-------------------------------------------Preconditions-------------------------------------
-- Activate application
common_steps:PreconditionSteps("PreconditionSteps", 7)
function Test:Verify_CreateInteractionChoiceSet_SUCCESS()
  local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
    {
      interactionChoiceSetID = 100,
      choiceSet =
      {
        {
          choiceID = 100,
          menuName = "Choice100",
          vrCommands =
          {
            "Choice100",
          },
          image =
          {
            value = "invalidImage_1.png",
            imageType ="DYNAMIC",
          },
          secondaryImage=
          {
            value = "invalidImage_2.png",
            imageType ="DYNAMIC",
          }
        }
      }
    })
  EXPECT_HMICALL("VR.AddCommand",
    {
      cmdID = 100,
      appID = applicationID,
      type = "Choice",
      vrCommands = {"Choice100" }
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  EXPECT_NOTIFICATION("OnHashChange")
end

--------------------------------------------BODY---------------------------------------------
-- Verify: when all params are correct and image of vrHelp doesn't exist
-- SDL->MOB: RPC (success:false, resultCode:"WARNINGS", info:"Reference image(s) not found")
---------------------------------------------------------------------------------------------
function Test:Verify_AllParamsCorrect_ImageNotExist_WARNINGS()
  local cid = self.mobileSession:SendRPC("PerformInteraction",{
      initialText = "StartPerformInteraction",
      initialPrompt = {
        {
          text = "Make your choice",
          type = "TEXT"
        }
      },
      interactionMode = "BOTH",
      interactionChoiceSetIDList =
      {
        100
      },
      helpPrompt = {
        {
          text = "Help Promptv ",
          type = "TEXT"
        }
      },
      timeoutPrompt = {
        {
          text = "Timeoutv",
          type = "TEXT"
        }
      },
      timeout = 5000,
      vrHelp = {
        {
          image =
          {
            imageType = "DYNAMIC",
            value = "invalidImage.png"
          },
          text = "NewVRHelpv",
          position = 1
        }
      },
      interactionLayout = "ICON_ONLY"
    })
  EXPECT_HMICALL("VR.PerformInteraction",
    {
      helpPrompt = {
        {
          text = "Help Promptv ",
          type = "TEXT"
        }
      },
      initialPrompt = {
        {
          text = "Make your choice",
          type = "TEXT"
        }
      },
      timeout = 5000,
      timeoutPrompt = {
        {
          text = "Timeoutv",
          type = "TEXT"
        }
      }
    })
  :Do(function(_,data)
      appID = common_functions:GetHmiAppId(appName, self)
      self.hmiConnection:SendNotification("VR.Started")
      self.hmiConnection:SendNotification("TTS.Started")
      self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = appID, systemContext = "VRSESSION"})
      local function firstSpeakTimeOut()
        self.hmiConnection:SendNotification("TTS.Stopped")
        self.hmiConnection:SendNotification("TTS.Started")
      end
      RUN_AFTER(firstSpeakTimeOut, 5)
      local function vrResponse()
        self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
        self.hmiConnection:SendNotification("VR.Stopped")
      end
      RUN_AFTER(vrResponse, 20)
    end)
  EXPECT_HMICALL("UI.PerformInteraction",
    {
      timeout = 5000,
      choiceSet = {
        choiceID = 100,
        image =
        {
          value = storagePath .. "invalidImage_1.png",
          imageType ="DYNAMIC",
        },
        secondaryImage=
        {
          value = "invalidImage_2.png",
          imageType ="DYNAMIC",
        },
        menuName = "Choice100"
      },
      initialText =
      {
        fieldName = "initialInteractionText",
        fieldText = "StartPerformInteraction"
      },
      vrHelp = {
        {
          image =
          {
            imageType = "DYNAMIC",
            value = storagePath .. "invalidImage.png"
          },
          text = "NewVRHelpv",
          position = 1
        }
      },
      vrHelpTitle = "StartPerformInteraction"
    })
  :Do(function(_,data)
      local function choiceIconDisplayed()
        self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = appID, systemContext = "HMI_OBSCURED"})
      end
      RUN_AFTER(choiceIconDisplayed, 25)

      local function uiResponse()
        self.hmiConnection:SendNotification("TTS.Stopped")
        self.hmiConnection:SendError(data.id, data.method, "WARNINGS","Reference image(s) not found")
        self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = appID, systemContext = "MAIN"})
      end
      RUN_AFTER(uiResponse, 30)
    end)
  EXPECT_NOTIFICATION("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
    { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION"},
    { hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "VRSESSION"},
    { hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "HMI_OBSCURED"},
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED"},
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  :Times(6)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", info = "Reference image(s) not found"})
end

-------------------------------------------Postconditions-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegisterApp", appName)
common_steps:StopSDL("Postcondition_StopSDL")
