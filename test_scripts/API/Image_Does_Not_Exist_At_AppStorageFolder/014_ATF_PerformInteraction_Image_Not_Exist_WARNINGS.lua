-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

------------------------------------ Common Variables ---------------------------------------
local storagePath = config.SDLStoragePath
..config.application1.registerAppInterfaceParams.appID.. "_" .. config.deviceMAC.. "/"
local appName = config.application1.registerAppInterfaceParams.appName

-------------------------------------------Preconditions-------------------------------------
-- Activate application
common_steps:PreconditionSteps("PreconditionSteps", 7)

--------------------------------------------BODY---------------------------------------------
-- Verify: when all params are correct and image of vrHelp doesn't exist
-- SDL->MOB: RPC (success:false, resultCode:"WARNINGS", info:"Reference image(s) not found")
---------------------------------------------------------------------------------------------
function performInteractionAllParams()
  local temp = {
    initialText = "StartPerformInteraction",
    initialPrompt = {{
        text = "Make your choice",
        type = "TEXT"
        --type = 123
    }},
    interactionMode = "BOTH",
    interactionChoiceSetIDList =
    {
      100, 200, 300
    },
    helpPrompt = {
      {
        text = "Help Promptv ",
        type = "TEXT"
      },
      {
        text = "Help Promptvv ",
        type = "TEXT"
    }},
    timeoutPrompt = {{
        text = "Timeoutv",
        type = "TEXT"
      },
      {
        text = "Timeoutvv",
        type = "TEXT"
    }},
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
      },
      {
        image =
        {
          imageType = "DYNAMIC",
          value = "invalidImage.png"
        },
        text = "NewVRHelpvv",
        position = 2
      },
      {
        image =
        {
          imageType = "DYNAMIC",
          value = "invalidImage.png"
        },
        text = "NewVRHelpvvv",
        position = 3
      }
    },
    interactionLayout = "ICON_ONLY"
  }
  return temp
end

function setChoiseSet(choiceIDValue, size)
  if (size == nil) then
    local temp = {{
        choiceID = choiceIDValue,
        menuName ="Choice" .. tostring(choiceIDValue),
        vrCommands =
        {
          "VrChoice" .. tostring(choiceIDValue),
        },
        image =
        {
          value ="invalidImage.png",
          imageType ="STATIC"
        }
    }}
    return temp
  else
    local temp = {}
    for i = 1, size do
      temp[i] = {
        choiceID = choiceIDValue+i-1,
        menuName ="Choice" .. tostring(choiceIDValue+i-1),
        vrCommands =
        {
          "VrChoice" .. tostring(choiceIDValue+i-1),
        },
        image =
        {
          value ="invalidImage.png",
          imageType ="STATIC"
        }
      }
    end
    return temp
  end
end

function setExChoiseSet(choiceIDValues)
  local exChoiceSet = {}
  for i = 1, #choiceIDValues do
    exChoiceSet[i] = {
      choiceID = choiceIDValues[i],
      image =
      {
        value = "invalidImage.png",
        imageType = "STATIC",
      },
      menuName = Choice100
    }
  end
  return exChoiceSet
end

function Test:createInteractionChoiceSet(choiceSetID, choiceID)
  cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
    {
      interactionChoiceSetID = choiceSetID,
      choiceSet = setChoiseSet(choiceID),
    })
  EXPECT_HMICALL("VR.AddCommand",
    {
      cmdID = choiceID,
      type = "Choice",
      vrCommands = {"VrChoice"..tostring(choiceID) }
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  EXPECT_RESPONSE(cid, { resultCode = "SUCCESS", success = true })
end
choice_set_id_values = {100, 200, 300}

for i=1, #choice_set_id_values do
  Test["CreateInteractionChoiceSet" .. choice_set_id_values[i]] = function(self)
    self:createInteractionChoiceSet(choice_set_id_values[i], choice_set_id_values[i])
  end
end

local request_parameters = performInteractionAllParams()
function Test:Verify_AllParamsCorrect_ImageNotExist_WARNINGS()
  request_parameters.interactionMode = "BOTH"
  cid = self.mobileSession:SendRPC("PerformInteraction",request_parameters)

  EXPECT_HMICALL("VR.PerformInteraction",
    {
      helpPrompt = request_parameters.helpPrompt,
      initialPrompt = request_parameters.initialPrompt,
      timeout = request_parameters.timeout,
      timeoutPrompt = request_parameters.timeoutPrompt
    })
  :Do(function(_,data)
      appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
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
        --self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        self.hmiConnection:SendNotification("VR.Stopped")
      end
      RUN_AFTER(vrResponse, 20)
    end)

  EXPECT_HMICALL("UI.PerformInteraction",
    {
      timeout = request_parameters.timeout,
      choiceSet = setExChoiseSet(request_parameters.interactionChoiceSetIDList),
      initialText =
      {
        fieldName = "initialInteractionText",
        fieldText = request_parameters.initialText
      },
      vrHelp = request_parameters.vrHelp,
      vrHelpTitle = request_parameters.initialText
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
