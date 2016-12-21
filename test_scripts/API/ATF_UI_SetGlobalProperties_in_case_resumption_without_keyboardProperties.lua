-- This script verifies case: MOB -> SDL: There is no SetGlobalProperties() in 10s but keyboardProperties is resumed.
-- Specific case: SDL -> HMI: UI.SetGlobalProperties(without keyboardProperties) due to resumption
require('user_modules/all_common_modules')
local TIMEOUT_PROMPT = {{text = "Timeout prompt", type = "TEXT"}}
local HELP_PROMPT = {{text = "Help prompt", type = "TEXT"}}
local MENU_TITLE = "Menu Title"
local VRHELP = {{position = 1, text = "VR help item"}}
local VRHELP_TITLE = "VR help title"
local app = config.application1.registerAppInterfaceParams
local current_time

local kbp_supported = common_functions:GetParameterValueInJsonFile(
  config.pathToSDL .. "hmi_capabilities.json",
  {"UI", "keyboardPropertiesSupported"})
if not kbp_supported then
  common_functions:PrintError("UI.keyboardPropertiesSupported parameter does not exist in hmi_capabilities.json. Stop ATF script.")
  os.exit()
end
local keyboard_properties = {
  keyboardLayout = kbp_supported.keyboardLayoutSupported[1],
  keypressMode = kbp_supported.keypressModeSupported[1],
  language = kbp_supported.languageSupported[1]
}
if kbp_supported.limitedCharactersListSupported then
  keyboard_properties.limitedCharacterList = {"a"}
end
if kbp_supported.autoCompleteTextSupported then
  keyboard_properties.autoCompleteText = "Daemon, Freedom"
end

-- Precondition: application is activated.
common_steps:PreconditionSteps("Precondition", 7)

Test["SetGlobalProperties_keyboardProperties_omited"] = function(self)
  local cid = self.mobileSession:SendRPC("SetGlobalProperties",
    {
      helpPrompt = HELP_PROMPT,
      timeoutPrompt = TIMEOUT_PROMPT,
      menuTitle = MENU_TITLE,
      vrHelp = VRHELP,
      vrHelpTitle = VRHELP_TITLE
    })

  EXPECT_HMICALL("TTS.SetGlobalProperties",
    {
      timeoutPrompt = TIMEOUT_PROMPT,
      helpPrompt = HELP_PROMPT
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  EXPECT_HMICALL("UI.SetGlobalProperties",
    {
      menuTitle = MENU_TITLE,
      vrHelp = VRHELP,
      vrHelpTitle = VRHELP_TITLE
    })
  :ValidIf(function(_,data)
      return not data.params.keyboardProperties
    end)
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})

  EXPECT_NOTIFICATION("OnHashChange")
  :Do(function(_, data)
      self.currentHashID = data.payload.hashID
    end)
end

common_steps:IgnitionOff("IgnitionOff")
common_steps:IgnitionOn("IgnitionOn")
common_steps:AddMobileSession("AddMobileSession")

-- Step 3: Register app again, check SDL -> HMI: UI.SetGlobalProperties(keyboardProperties = value from resumption)
Test["RegisterAppInterface_keyboardProperties_from_resumption_data"] = function(self)
  app.hashID = self.currentHashID
  local cid = self.mobileSession:SendRPC("RegisterAppInterface", app)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {})
  EXPECT_RESPONSE(cid, { success = true , resultCode = "SUCCESS", info = "Resume succeeded."})
  EXPECT_HMICALL("BasicCommunication.ActivateApp")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
    end)

  EXPECT_NOTIFICATION("OnHMIStatus",
    {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
    {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}
  )
  :Times(2)

  EXPECT_HMICALL("UI.SetGlobalProperties",
    {
      menuTitle = MENU_TITLE,
      vrHelp = VRHELP,
      vrHelpTitle = VRHELP_TITLE
    })
  :ValidIf(function(_,data)
      return not data.params.keyboardProperties
    end)
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :Timeout(3000)
end
