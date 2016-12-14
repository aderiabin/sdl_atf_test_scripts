-- This script verifies case: MOB -> SDL: There is no SetGlobalProperties() in 10s but keyboardProperties is resumed.
require('user_modules/all_common_modules')
local TIMEOUT_PROMPT = {{text = "Timeout prompt", type = "TEXT"}}
local HELP_PROMPT = {{text = "Help prompt", type = "TEXT"}}
local MENU_TITLE = "Menu Title"
local VRHELP = {{position = 1, text = "VR help item"}}
local VRHELP_TITLE = "VR help title"
local app = config.application1.registerAppInterfaceParams
local current_time
--------------------------------------------------------------------------------
-- Get parameter's value from json file
-- @param json_file: file name of a JSON file
-- @param path_to_parameter: full path of parameter
-- Example: path for Location1 parameter: {"policy", functional_groupings, "Location1"}
--------------------------------------------------------------------------------
local function GetParameterValueInJsonFile(json_file, path_to_parameter)
  local file = io.open(json_file, "r")
  local json_data = file:read("*all")
  file:close()
  local json = require("modules/json")
  local data = json.decode(json_data)
  local parameter = data
  for i = 1, #path_to_parameter do
    parameter = parameter[path_to_parameter[i]]
  end
  return parameter
end

local kps = GetParameterValueInJsonFile(
  config.pathToSDL .. "hmi_capabilities.json",
  {"UI", "displayCapabilities", "keyboardPropertiesSupported"})
if not kps.languageSupported then
  common_functions:PrintError("keyboardPropertiesSupported.languageSupported parameter is not exist in hmi_capabilities.json. Stop ATF script.")
  quit(1)
end
local keyboard_properties = {
  keyboardLayout = kps.keyboardLayoutSupported[1],
  keypressMode = kps.keypressModeSupported[1],
  language = kps.languageSupported[1]
}
if kps.limitedCharactersListSupported then
  keyboard_properties.limitedCharacterList = {"a"}
end
if kps.autoCompleteTextSupported then
  keyboard_properties.autoCompleteText = "Daemon, Freedom"
end

-- Precondition: application is activated.
common_steps:PreconditionSteps("Precondition", 8)

Test["SetGlobalProperties"] = function(self)
  local cid = self.mobileSession:SendRPC("SetGlobalProperties",
    {
      helpPrompt = HELP_PROMPT,
      timeoutPrompt = TIMEOUT_PROMPT,
      menuTitle = MENU_TITLE,
      vrHelp = VRHELP,
      vrHelpTitle = VRHELP_TITLE,
      keyboardProperties = keyboard_properties
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
      vrHelpTitle = VRHELP_TITLE,
      keyboardProperties = keyboard_properties
    })
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
      vrHelpTitle = VRHELP_TITLE,
      keyboardProperties = keyboard_properties
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :Timeout(3000)
end
