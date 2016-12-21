-- This script verifies case: MOB -> SDL: SetGlobalProperties(without keyboardProperties) in 10s
require('user_modules/all_common_modules')
local TIMEOUT_PROMPT = {{text = "Timeout prompt", type = "TEXT"}}
local HELP_PROMPT = {{text = "Help prompt", type = "TEXT"}}
local MENU_TITLE = "Menu Title"
local VRHELP = {{position = 1, text = "VR help item"}}
local VRHELP_TITLE = "VR help title"
local SUCCESS_RESULTCODES = {"SUCCESS", "WARNINGS", "WRONG_LANGUAGE", "RETRY", "SAVED", "UNSUPPORTED_RESOURCE"}
local ERROR_RESULTCODES = {"UNSUPPORTED_REQUEST", "DISALLOWED", "USER_DISALLOWED", "REJECTED", "ABORTED", "IGNORED", "IN_USE", "DATA_NOT_AVAILABLE", "TIMED_OUT", "INVALID_DATA", "CHAR_LIMIT_EXCEEDED", "INVALID_ID", "DUPLICATE_NAME", "APPLICATION_NOT_REGISTERED", "OUT_OF_MEMORY", "TOO_MANY_PENDING_REQUESTS", "GENERIC_ERROR", "TRUNCATED_DATA"}

-- MOB -> SDL: SetGlobalProperties(without keyboardProperties) in 10s
-- SDL -> HMI: UI.SetGlobalProperties(omitted <keyboardProperties>)
-- HMI -> SDL: UI.SetGlobalProperties(resultCode)
-- SDL -> MOB: SetGlobalProperties(resultCode)

local function Precondition()
  common_steps:StopSDL("Precondition_StopSDL")
  common_steps:RemoveFileInSdlBinFolder("Precondition_Remove_app_info.dat", "app_info.dat")
  common_steps:StartSDL("Precondition_StartSDL")
  common_steps:InitializeHmi("Precondition_InitHMI")
  common_steps:HmiRespondOnReady("Precondition_InitHMI_onReady")
  common_steps:AddMobileConnection("Precondition_AddDefaultMobileConnection", "mobileConnection")
  common_steps:AddMobileSession("Precondition_AddDefaultMobileConnect")
  common_steps:RegisterApplication("Precondition_Register_App")
  common_steps:ActivateApplication("ActivateApplication", config.application1.registerAppInterfaceParams.appName)
end

local function UiRespondsSuccessfulResultCodes(successful_result_code, test_case_suffix)
  Test["Sgp_UI_" .. successful_result_code .. "_" .. test_case_suffix] = function(self)
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

    EXPECT_RESPONSE(cid, {success = true, resultCode = successful_result_code})
    :ValidIf(function(_,data)
        return not data.payload.info
      end)

    EXPECT_NOTIFICATION("OnHashChange")
  end
end

local function TtsRespondsSuccessfulResultCodes(successful_result_code, test_case_suffix)
  Test["Sgp_TTS_" .. successful_result_code .. "_" .. test_case_suffix] = function(self)
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

    EXPECT_RESPONSE(cid, {success = true, resultCode = successful_result_code})
    :ValidIf(function(_,data)
        return not data.payload.info
      end)
    EXPECT_NOTIFICATION("OnHashChange")
  end
end

local function UiRespondsErrorResultCodes(error_result_code, test_case_suffix)
  Test["Sgp_UI_" .. error_result_code .. "_" .. test_case_suffix] = function(self)
    common_functions:DelayedExp(500)
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
    if error_result_code == "DATA_NOT_AVAILABLE" then
      EXPECT_RESPONSE(cid, {success = false, resultCode = "VEHICLE_DATA_NOT_AVAILABLE", info = "error_message"})
    else
      EXPECT_RESPONSE(cid, {success = false, resultCode = error_result_code, info = "error_message"})
    end
    EXPECT_NOTIFICATION("OnHashChange")
    :Times(0)
  end
end

local function TtsRespondsErrorResultCodes(error_result_code, test_case_suffix)
  Test["Sgp_TTS_" .. error_result_code .. "_" .. test_case_suffix] = function(self)
    common_functions:DelayedExp(500)
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

    if error_result_code == "DATA_NOT_AVAILABLE" then
      EXPECT_RESPONSE(cid, {success = false, resultCode = "VEHICLE_DATA_NOT_AVAILABLE", info = "error_message"})
    else
      EXPECT_RESPONSE(cid, {success = false, resultCode = error_result_code, info = "error_message"})
    end
    EXPECT_NOTIFICATION("OnHashChange")
    :Times(0)
  end
end

-- Test case 1: SetGlobalProperties(without <keyboardProperties> ) during 10 sec timer after this app registration
local test_case_suffix = "during_timeout_10s"
-- UI responds successful resultCodes
for i = 1, #SUCCESS_RESULTCODES do
  common_steps:AddNewTestCasesGroup("Test case: UI responds SetGlobalProperties with resultCode " .. SUCCESS_RESULTCODES[i])
  Precondition()
  UiRespondsSuccessfulResultCodes(SUCCESS_RESULTCODES[i], test_case_suffix)
end

-- TTS responds successful resultCodes
for i = 1, #SUCCESS_RESULTCODES do
  common_steps:AddNewTestCasesGroup("Test case: TTS responds SetGlobalProperties with resultCode " .. SUCCESS_RESULTCODES[i])
  Precondition()
  TtsRespondsSuccessfulResultCodes(SUCCESS_RESULTCODES[i], test_case_suffix)
end

-- UI responds error resultCodes
for i = 1, #ERROR_RESULTCODES do
  common_steps:AddNewTestCasesGroup("Test case: UI responds SetGlobalProperties with resultCode " .. ERROR_RESULTCODES[i])
  Precondition()
  UiRespondsErrorResultCodes(ERROR_RESULTCODES[i], test_case_suffix)
end

-- TTS responds error resultCodes
for i = 1, #ERROR_RESULTCODES do
  common_steps:AddNewTestCasesGroup("Test case: TTS responds SetGlobalProperties with resultCode " .. ERROR_RESULTCODES[i])
  Precondition()
  TtsRespondsErrorResultCodes(ERROR_RESULTCODES[i], test_case_suffix)
end

-- Test case 2: SetGlobalProperties(without <keyboardProperties>) during ignition cycle
common_steps:AddNewTestCasesGroup("Test case: Mobile sends SetGlobalProperties(without <keyboardProperties>) during ignition cycle and HMI responds with different resultCodes")
Precondition()
-- Sleep 10 seconds as precondition to test case: SetGlobalProperties after 10s timeout
common_steps:Sleep("Sleep_10_seconds", 10)
test_case_suffix = "after_finishing_timeout_10s"
-- UI responds successful resultCodes
for i = 1, #SUCCESS_RESULTCODES do
  UiRespondsSuccessfulResultCodes(SUCCESS_RESULTCODES[i], test_case_suffix)
end

-- TTS responds successful resultCodes
for i = 1, #SUCCESS_RESULTCODES do
  TtsRespondsSuccessfulResultCodes(SUCCESS_RESULTCODES[i], test_case_suffix)
end

-- UI responds error resultCodes
for i = 1, #ERROR_RESULTCODES do
  UiRespondsErrorResultCodes(ERROR_RESULTCODES[i], test_case_suffix)
end

-- TTS responds error resultCodes
for i = 1, #ERROR_RESULTCODES do
  TtsRespondsErrorResultCodes(ERROR_RESULTCODES[i], test_case_suffix)
end
