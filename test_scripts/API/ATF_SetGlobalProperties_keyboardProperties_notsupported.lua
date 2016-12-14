-- This script verifies case: MOB -> SDL: ResetGlobalProperties(unsupported "KEYBOARDPROPERTIES")
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

local kbp_supported = GetParameterValueInJsonFile(
  config.pathToSDL .. "hmi_capabilities.json",
  {"UI", "keyboardPropertiesSupported"})
if not kbp_supported then
  common_functions:PrintError("UI.keyboardPropertiesSupported parameter is not exist in hmi_capabilities.json. Stop ATF script.")
  quit(1)
end

local Unsupported_keyboardProperties = {
  language = "RU-RU",
  keyboardLayout = "AZERTY",
  keypressMode = "RESEND_CURRENT_ENTRY",
}
if kbp_supported.limitedCharactersListSupported == false then
  Unsupported_keyboardProperties.limitedCharacterList = {"a"}
end
if kbp_supported.autoCompleteTextSupported == false then
  Unsupported_keyboardProperties.autoCompleteText = "Daemon, Freedom"
end

local function Precondition()
  local mobile_connection_name = "mobileConnection"
  local mobile_session_name = "mobileSession"
  local app = config.application1.registerAppInterfaceParams
  common_steps:StopSDL("Precondition_StopSDL")
  common_steps:StartSDL("Precondition_StartSDL")
  common_steps:InitializeHmi("Precondition_InitHMI")
  common_steps:HmiRespondOnReady("Precondition_InitHMI_onReady")
  common_steps:AddMobileConnection("Precondition_AddDefaultMobileConnection", mobile_connection_name)
  common_steps:AddMobileSession("Precondition_AddDefaultMobileConnect")
  common_steps:RegisterApplication("Precondition_Register_App")
  common_steps:ActivateApplication("ActivateApplication", config.application1.registerAppInterfaceParams.appName)
end

local function UiRespondsSuccessfulResultCodes(successful_result_code)
  Test["Sgp_UI_" .. successful_result_code] = function(self)
    local cid = self.mobileSession:SendRPC("SetGlobalProperties",
      {
        helpPrompt = HELP_PROMPT,
        timeoutPrompt = TIMEOUT_PROMPT,
        menuTitle = MENU_TITLE,
        vrHelp = VRHELP,
        vrHelpTitle = VRHELP_TITLE,
        keyboardProperties = Unsupported_keyboardProperties
      })

    EXPECT_HMICALL("TTS.SetGlobalProperties",
      {
        helpPrompt = HELP_PROMPT,
        timeoutPrompt = TIMEOUT_PROMPT
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
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, successful_result_code, {})
      end)
    :ValidIf(function(_,data)
        return not data.params.keyboardProperties
      end)

    EXPECT_RESPONSE(cid, {success = true, resultCode = "UNSUPPORTED_RESOURCE", info = "Requested keyboardProperties is not supported by system."})
    EXPECT_NOTIFICATION("OnHashChange")
  end
end

local function TtsRespondsSuccessfulResultCodes(successful_result_code)
  Test["Sgp_TTS_" .. successful_result_code] = function(self)
    local cid = self.mobileSession:SendRPC("SetGlobalProperties",
      {
        helpPrompt = HELP_PROMPT,
        timeoutPrompt = TIMEOUT_PROMPT,
        menuTitle = MENU_TITLE,
        vrHelp = VRHELP,
        vrHelpTitle = VRHELP_TITLE,
        keyboardProperties = Unsupported_keyboardProperties
      })

    EXPECT_HMICALL("TTS.SetGlobalProperties",
      {
        helpPrompt = HELP_PROMPT,
        timeoutPrompt = TIMEOUT_PROMPT
      })
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, successful_result_code, {})
      end)

    EXPECT_HMICALL("UI.SetGlobalProperties",
      {
        menuTitle = MENU_TITLE,
        vrHelp = VRHELP,
        vrHelpTitle = VRHELP_TITLE
      })
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
    :ValidIf(function(_,data)
        return not data.params.keyboardProperties
      end)

    EXPECT_RESPONSE(cid, {success = true, resultCode = "UNSUPPORTED_RESOURCE", info = "Requested keyboardProperties is not supported by system."})
    EXPECT_NOTIFICATION("OnHashChange")
  end
end

local function UiRespondsErrorResultCodes(error_result_code)
  Test["Sgp_UI_" .. error_result_code] = function(self)
    common_functions:DelayedExp(500)
    local cid = self.mobileSession:SendRPC("SetGlobalProperties",
      {
        helpPrompt = HELP_PROMPT,
        timeoutPrompt = TIMEOUT_PROMPT,
        menuTitle = MENU_TITLE,
        vrHelp = VRHELP,
        vrHelpTitle = VRHELP_TITLE,
        keyboardProperties = Unsupported_keyboardProperties
      })

    EXPECT_HMICALL("TTS.SetGlobalProperties",
      {
        helpPrompt = HELP_PROMPT,
        timeoutPrompt = TIMEOUT_PROMPT
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
    :Do(function(_,data)
        self.hmiConnection:SendError(data.id, data.method, error_result_code, "error_message")
      end)
    :ValidIf(function(_,data)
        return not data.params.keyboardProperties
      end)

    EXPECT_RESPONSE(cid, {success = false, resultCode = error_result_code, info = "error_message"})
    EXPECT_NOTIFICATION("OnHashChange")
    :Times(0)
  end
end

local function TtsRespondsErrorResultCodes(error_result_code)
  Test["Sgp_TTS_" .. error_result_code] = function(self)
    common_functions:DelayedExp(500)
    local cid = self.mobileSession:SendRPC("SetGlobalProperties",
      {
        helpPrompt = HELP_PROMPT,
        timeoutPrompt = TIMEOUT_PROMPT,
        menuTitle = MENU_TITLE,
        vrHelp = VRHELP,
        vrHelpTitle = VRHELP_TITLE,
        keyboardProperties = Unsupported_keyboardProperties
      })

    EXPECT_HMICALL("TTS.SetGlobalProperties",
      {
        helpPrompt = HELP_PROMPT,
        timeoutPrompt = TIMEOUT_PROMPT
      })
    :Do(function(_,data)
        self.hmiConnection:SendError(data.id, data.method, error_result_code, "error_message")
      end)

    EXPECT_HMICALL("UI.SetGlobalProperties",
      {
        menuTitle = MENU_TITLE,
        vrHelp = VRHELP,
        vrHelpTitle = VRHELP_TITLE
      })
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
    :ValidIf(function(_,data)
        return not data.params.keyboardProperties
      end)

    EXPECT_RESPONSE(cid, {success = false, resultCode = error_result_code, info = "error_message"})
    EXPECT_NOTIFICATION("OnHashChange")
    :Times(0)
  end
end

-- Test case 1: SetGlobalProperties(all params of <keyboardProperties> struct are NOT supported) during 10 sec timer after this app registration

-- UI responds successful resultCodes
for i = 1, #SUCCESS_RESULTCODES do
  Precondition()
  UiRespondsSuccessfulResultCodes(SUCCESS_RESULTCODES[i])
end

-- TTS responds successful resultCodes
for i = 1, #SUCCESS_RESULTCODES do
  Precondition()
  TtsRespondsSuccessfulResultCodes(SUCCESS_RESULTCODES[i])
end

-- UI responds error resultCodes
for i = 1, #ERROR_RESULTCODES do
  Precondition()
  UiRespondsErrorResultCodes(ERROR_RESULTCODES[i])
end

-- TTS responds error resultCodes
for i = 1, #ERROR_RESULTCODES do
  Precondition()
  TtsRespondsErrorResultCodes(ERROR_RESULTCODES[i])
end

-- Test case 2: SetGlobalProperties(all params of <keyboardProperties> struct are NOT supported) during ignition cycle
Precondition()
common_steps:Sleep("Sleep_15_seconds_to_test_case_SetGlobalProperties_during_ignition_cycle", 15)

-- UI responds successful resultCodes
for i = 1, #SUCCESS_RESULTCODES do
  UiRespondsSuccessfulResultCodes(SUCCESS_RESULTCODES[i])
end

-- TTS responds successful resultCodes
for i = 1, #SUCCESS_RESULTCODES do
  TtsRespondsSuccessfulResultCodes(SUCCESS_RESULTCODES[i])
end

-- UI responds error resultCodes
for i = 1, #ERROR_RESULTCODES do
  UiRespondsErrorResultCodes(ERROR_RESULTCODES[i])
end

-- TTS responds error resultCodes
for i = 1, #ERROR_RESULTCODES do
  TtsRespondsErrorResultCodes(ERROR_RESULTCODES[i])
end
