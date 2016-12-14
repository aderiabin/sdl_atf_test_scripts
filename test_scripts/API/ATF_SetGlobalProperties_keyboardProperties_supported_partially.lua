-- This script verifies case: MOB -> SDL: SetGlobalProperties(at least one param of <keyboardProperties> is not supported per capabilities file) during 10s
require('user_modules/all_common_modules')
local TIMEOUT_PROMPT = {{text = "Timeout prompt", type = "TEXT"}}
local HELP_PROMPT = {{text = "Help prompt", type = "TEXT"}}
local MENU_TITLE = "Menu Title"
local VRHELP = {{position = 1, text = "VR help item"}}
local VRHELP_TITLE = "VR help title"
local SUCCESS_RESULTCODES = {"SUCCESS", "WARNINGS", "WRONG_LANGUAGE", "RETRY", "SAVED", "UNSUPPORTED_RESOURCE"}
local ERROR_RESULTCODES = {"UNSUPPORTED_REQUEST", "DISALLOWED", "USER_DISALLOWED", "REJECTED", "ABORTED", "IGNORED", "IN_USE", "VEHICLE_DATA_NOT_AVAILABLE", "TIMED_OUT", "INVALID_DATA", "CHAR_LIMIT_EXCEEDED", "INVALID_ID", "DUPLICATE_NAME", "APPLICATION_NOT_REGISTERED", "OUT_OF_MEMORY", "TOO_MANY_PENDING_REQUESTS", "GENERIC_ERROR", "TRUNCATED_DATA"}

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
-- Test keyboardProperties with the last values on list of supported values from hmi_capabilities.json
local supported_keyboard_properties = {
  language = kps.languageSupported[#kps.languageSupported],
  keyboardLayout = kps.keyboardLayoutSupported[#kps.keyboardLayoutSupported],
  keypressMode = kps.keypressModeSupported[#kps.keypressModeSupported],
}
if kps.limitedCharactersListSupported then
  supported_keyboard_properties.limitedCharacterList = {"a"}
end
if kps.autoCompleteTextSupported then
  supported_keyboard_properties.autoCompleteText = "Daemon, Freedom"
end

-- MOB -> SDL: SetGlobalProperties_request during 10s (some params of <keyboardProperties> structure are NOT supported at 'HMI_capabilities.json' file)
-- SDL -> HMI: UI.SetGlobalProperties(omitted only unsupported params in <keyboardProperties>)
-- HMI -> SDL: UI.SetGlobalProperties(SUCCESS)
-- SDL -> MOB: SetGlobalProperties("UNSUPPORTED_RESOURCE, success:true, info: Requested "keyboardProperties" is not supported by system")

local function Precondition()
  local app = config.application1.registerAppInterfaceParams
  common_steps:StopSDL("Precondition_StopSDL")
  common_steps:StartSDL("Precondition_StartSDL")
  common_steps:InitializeHmi("Precondition_InitHMI")
  common_steps:HmiRespondOnReady("Precondition_InitHMI_onReady")
  common_steps:AddMobileConnection("Precondition_AddDefaultMobileConnection", "mobileConnection")
  common_steps:AddMobileSession("Precondition_AddDefaultMobileConnect")
  common_steps:RegisterApplication("Precondition_Register_App")
  common_steps:ActivateApplication("ActivateApplication", config.application1.registerAppInterfaceParams.appName)  
end

local function UiRespondsSuccessfulResultCodes(unsupported_one_param_in_keyboard_properties, successful_result_code, unsuported_parameter)
  Test["Sgp_UI_" .. successful_result_code] = function(self)
    local cid = self.mobileSession:SendRPC("SetGlobalProperties",
      {
        helpPrompt = HELP_PROMPT,
        timeoutPrompt = TIMEOUT_PROMPT,
        menuTitle = MENU_TITLE,
        vrHelp = VRHELP,
        vrHelpTitle = VRHELP_TITLE,
        keyboardProperties = unsupported_one_param_in_keyboard_properties
      })

    EXPECT_HMICALL("TTS.SetGlobalProperties",
      {
        helpPrompt = HELP_PROMPT,
        timeoutPrompt = TIMEOUT_PROMPT
      })
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)

    local keyboard_properties = common_functions:CloneTable(unsupported_one_param_in_keyboard_properties)
    keyboard_properties[unsuported_parameter] = nil
    EXPECT_HMICALL("UI.SetGlobalProperties",
      {
        menuTitle = MENU_TITLE,
        vrHelp = VRHELP,
        vrHelpTitle = VRHELP_TITLE,
        keyboardProperties = keyboard_properties
      })
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, successful_result_code, {})
      end)
    :ValidIf(function(_,data)
        print("expected: data.params.keyboardProperties = nil. Actual: " .. tostring(data.params.keyboardProperties[unsuported_parameter]))
        return not data.params.keyboardProperties[unsuported_parameter]
      end)

    EXPECT_RESPONSE(cid, {success = true, resultCode = "UNSUPPORTED_RESOURCE", info = "Requested " .. unsuported_parameter .." is not supported by system."})
    EXPECT_NOTIFICATION("OnHashChange")
  end
end

local function TtsRespondsSuccessfulResultCodes(unsupported_one_param_in_keyboard_properties, successful_result_code, unsuported_parameter)
  Test["Sgp_TTS_" .. successful_result_code] = function(self)
    local cid = self.mobileSession:SendRPC("SetGlobalProperties",
      {
        helpPrompt = HELP_PROMPT,
        timeoutPrompt = TIMEOUT_PROMPT,
        menuTitle = MENU_TITLE,
        vrHelp = VRHELP,
        vrHelpTitle = VRHELP_TITLE,
        keyboardProperties = unsupported_one_param_in_keyboard_properties
      })

    EXPECT_HMICALL("TTS.SetGlobalProperties",
      {
        helpPrompt = HELP_PROMPT,
        timeoutPrompt = TIMEOUT_PROMPT
      })
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, successful_result_code, {})
      end)

    local keyboard_properties = common_functions:CloneTable(unsupported_one_param_in_keyboard_properties)
    keyboard_properties[unsuported_parameter] = nil
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
    :ValidIf(function(_,data)
        print("expected: data.params.keyboardProperties = nil. Actual: " .. tostring(data.params.keyboardProperties[unsuported_parameter]))
        return not data.params.keyboardProperties[unsuported_parameter]
      end)

    EXPECT_RESPONSE(cid, {success = true, resultCode = "UNSUPPORTED_RESOURCE", info = "Requested " .. unsuported_parameter .. " is not supported by system."})
    EXPECT_NOTIFICATION("OnHashChange")
  end
end

local function UiRespondsErrorResultCodes(unsupported_one_param_in_keyboard_properties, error_result_code, unsuported_parameter)
  Test["Sgp_UI_" .. error_result_code] = function(self)
    common_functions:DelayedExp(500)
    local cid = self.mobileSession:SendRPC("SetGlobalProperties",
      {
        helpPrompt = HELP_PROMPT,
        timeoutPrompt = TIMEOUT_PROMPT,
        menuTitle = MENU_TITLE,
        vrHelp = VRHELP,
        vrHelpTitle = VRHELP_TITLE,
        keyboardProperties = unsupported_one_param_in_keyboard_properties
      })

    EXPECT_HMICALL("TTS.SetGlobalProperties",
      {
        helpPrompt = HELP_PROMPT,
        timeoutPrompt = TIMEOUT_PROMPT
      })
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)

    local keyboard_properties = common_functions:CloneTable(unsupported_one_param_in_keyboard_properties)
    keyboard_properties[unsuported_parameter] = nil
    EXPECT_HMICALL("UI.SetGlobalProperties",
      {
        menuTitle = MENU_TITLE,
        vrHelp = VRHELP,
        vrHelpTitle = VRHELP_TITLE,
        keyboardProperties = keyboard_properties
      })
    :Do(function(_,data)
        self.hmiConnection:SendError(data.id, data.method, error_result_code, "error_message")
      end)
    :ValidIf(function(_,data)
        print("expected: data.params.keyboardProperties = nil. Actual: " .. tostring(data.params.keyboardProperties[unsuported_parameter]))
        return not data.params.keyboardProperties[unsuported_parameter]
      end)

    EXPECT_RESPONSE(cid, {success = false, resultCode = error_result_code, info = "error_message"})
    EXPECT_NOTIFICATION("OnHashChange")
    :Times(0)
  end
end

local function TtsRespondsErrorResultCodes(unsupported_one_param_in_keyboard_properties, error_result_code, unsuported_parameter)
  Test["Sgp_TTS_" .. error_result_code] = function(self)
    common_functions:DelayedExp(500)
    local cid = self.mobileSession:SendRPC("SetGlobalProperties",
      {
        helpPrompt = HELP_PROMPT,
        timeoutPrompt = TIMEOUT_PROMPT,
        menuTitle = MENU_TITLE,
        vrHelp = VRHELP,
        vrHelpTitle = VRHELP_TITLE,
        keyboardProperties = unsupported_one_param_in_keyboard_properties
      })

    EXPECT_HMICALL("TTS.SetGlobalProperties",
      {
        helpPrompt = HELP_PROMPT,
        timeoutPrompt = TIMEOUT_PROMPT
      })
    :Do(function(_,data)
        self.hmiConnection:SendError(data.id, data.method, error_result_code, "error_message")
      end)

    local keyboard_properties = common_functions:CloneTable(unsupported_one_param_in_keyboard_properties)
    keyboard_properties[unsuported_parameter] = nil
    EXPECT_HMICALL("UI.SetGlobalProperties",
      {
        menuTitle = MENU_TITLE,
        vrHelp = VRHELP,
        vrHelpTitle = VRHELP_TITLE,
        keyboardProperties = keyboard_properties
      })
    :Do(function(_,data)
        self.hmiConnection:SendError(data.id, data.method, error_result_code, "error_message")
      end)
    :ValidIf(function(_,data)
        print("expected: data.params.keyboardProperties = nil. Actual: " .. tostring(data.params.keyboardProperties[unsuported_parameter]))
        return not data.params.keyboardProperties[unsuported_parameter]
      end)

    EXPECT_RESPONSE(cid, {success = false, resultCode = error_result_code, info = "error_message"})
    EXPECT_NOTIFICATION("OnHashChange")
    :Times(0)
  end
end

local function TCs_For_An_UnsportedParameter(unsupported_one_param_in_keyboard_properties, unsuported_parameter)

  -- Test case 1: SetGlobalProperties(at least one param of <keyboardProperties> is not supported per capabilities file) during 10 sec timer after this app registration

  -- UI responds successful resultCodes
  for i = 1, #SUCCESS_RESULTCODES do
    Precondition()
    UiRespondsSuccessfulResultCodes(unsupported_one_param_in_keyboard_properties, SUCCESS_RESULTCODES[i], unsuported_parameter)
  end

  -- TTS responds successful resultCodes
  for i = 1, #SUCCESS_RESULTCODES do
    Precondition()
    TtsRespondsSuccessfulResultCodes(unsupported_one_param_in_keyboard_properties, SUCCESS_RESULTCODES[i], unsuported_parameter)
  end

  -- UI responds error resultCodes
  for i = 1, #ERROR_RESULTCODES do
    Precondition()
    UiRespondsErrorResultCodes(unsupported_one_param_in_keyboard_properties, ERROR_RESULTCODES[i], unsuported_parameter)
  end

  -- TTS responds error resultCodes
  for i = 1, #ERROR_RESULTCODES do
    Precondition()
    TtsRespondsErrorResultCodes(unsupported_one_param_in_keyboard_properties, ERROR_RESULTCODES[i], unsuported_parameter)
  end

  -- Test case 2: SetGlobalProperties(at least one param of <keyboardProperties> is not supported per capabilities file) during ignition cycle
  Precondition()
  common_steps:Sleep("Sleep_15_seconds_to_test_case_SetGlobalProperties_during_ignition_cycle", 15)

  -- UI responds successful resultCodes
  for i = 1, #SUCCESS_RESULTCODES do
    UiRespondsSuccessfulResultCodes(unsupported_one_param_in_keyboard_properties, SUCCESS_RESULTCODES[i])
  end

  -- TTS responds successful resultCodes
  for i = 1, #SUCCESS_RESULTCODES do
    TtsRespondsSuccessfulResultCodes(unsupported_one_param_in_keyboard_properties, SUCCESS_RESULTCODES[i])
  end

  -- UI responds error resultCodes
  for i = 1, #ERROR_RESULTCODES do
    UiRespondsErrorResultCodes(unsupported_one_param_in_keyboard_properties, ERROR_RESULTCODES[i])
  end

  -- TTS responds error resultCodes
  for i = 1, #ERROR_RESULTCODES do
    TtsRespondsErrorResultCodes(unsupported_one_param_in_keyboard_properties, ERROR_RESULTCODES[i])
  end

end

-- TC for language is unsupported
common_steps:AddNewTestCasesGroup("Test cases: language is unsupported")
local language_unsupported = common_functions:CloneTable(supported_keyboard_properties)
language_unsupported.language = "RU-RU"
TCs_For_An_UnsportedParameter(language_unsupported, "language")

-- TC for keyboardLayout is unsupported
common_steps:AddNewTestCasesGroup("Test cases: keyboardLayout is unsupported")
local keyboardLayout_unsupported = common_functions:CloneTable(supported_keyboard_properties)
keyboardLayout_unsupported.keyboardLayout = "AZERTY"
TCs_For_An_UnsportedParameter(keyboardLayout_unsupported, "keyboardLayout")

-- TC for keypressMode is unsupported
common_steps:AddNewTestCasesGroup("Test cases: keypressMode is unsupported")
local keypressMode_unsupported = common_functions:CloneTable(supported_keyboard_properties)
keypressMode_unsupported.keypressMode = "RESEND_CURRENT_ENTRY"
TCs_For_An_UnsportedParameter(keypressMode_unsupported, "keypressMode")

-- TC for limitedCharactersList is unsupported
if kps.limitedCharactersListSupported == false then
  common_steps:AddNewTestCasesGroup("Test cases: limitedCharactersList is unsupported")
  local limitedCharactersList_unsupported = common_functions:CloneTable(supported_keyboard_properties)
  limitedCharactersList_unsupported.limitedCharacterList = {"a"}
  TCs_For_An_UnsportedParameter(limitedCharactersList_unsupported, "limitedCharacterList")
end

-- TC for autoCompleteText is unsupported
if kps.autoCompleteText == false then
  common_steps:AddNewTestCasesGroup("Test cases: autoCompleteText is unsupported")
  local autoCompleteText_unsupported = common_functions:CloneTable(supported_keyboard_properties)
  autoCompleteText_unsupported.autoCompleteText = "Daemon, Freedom"
  TCs_For_An_UnsportedParameter(autoCompleteText_unsupported, "autoCompleteText")
end
