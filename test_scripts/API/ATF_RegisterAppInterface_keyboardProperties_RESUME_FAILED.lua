-- This script verifies case: SDL -> MOB: RegisterAppInterface(keyboardProperties)
-- Specific case: RegisterAppInterface(keyboardProperties, RESUME_FAILED)
require('user_modules/all_common_modules')
local TIMEOUT_PROMPT = {{text = "Timeout prompt", type = "TEXT"}}
local HELP_PROMPT = {{text = "Help prompt", type = "TEXT"}}
local MENU_TITLE = "Menu Title"
local VRHELP = {{position = 1, text = "VR help item"}}
local VRHELP_TITLE = "VR help title"
local hmi_capabilities_file = config.pathToSDL .. "hmi_capabilities.json"
-- Update keyboardPropertiesSupported in hmi_capabilities.json
local added_json_items = {
  keyboardPropertiesSupported =
  {
    languageSupported = {
      "EN-US",
      "ES-MX",
      "FR-CA",
      "DE-DE",
      "ES-ES",
      "EN-GB",
      "RU-RU",
      "TR-TR",
      "PL-PL",
      "FR-FR",
      "IT-IT",
      "SV-SE",
      "PT-PT",
      "NL-NL",
      "EN-AU",
      "ZH-CN",
      "ZH-TW",
      "JA-JP",
      "AR-SA",
      "KO-KR",
      "PT-BR",
      "CS-CZ",
      "DA-DK",
      "NO-NO",
      "NL-BE",
      "EL-GR",
      "HU-HU",
      "FI-FI",
      "SK-SK"
    },
    keyboardLayoutSupported = {
      "QWERTY",
      "QWERTZ",
      "AZERTY"
    },
    keypressModeSupported = {
      "SINGLE_KEYPRESS",
      "QUEUE_KEYPRESSES",
      "RESEND_CURRENT_ENTRY"
    },
    limitedCharactersListSupported = true,
    autoCompleteTextSupported = true
  }
}
Test["Precondition_Update_keyboardPropertiesSupported_in_hmi_capabilities.json"] = function(self)
  common_functions:AddItemsIntoJsonFile(hmi_capabilities_file, {"UI"}, added_json_items)
end
-- Precondition: App is activated
common_steps:PreconditionSteps("Precondition", 7)
-- Sleep 10s for timer 10s finishes.
common_steps:Sleep("Precondition_sleep_10s", 10)

-- Generate supported keyboardProperties from value in hmi_capabilities.json
local custom_keyboard_properties = {}
local kbp_supported = added_json_items.keyboardPropertiesSupported
for i = 1, #kbp_supported.languageSupported do
  custom_keyboard_properties[i] = {}
  custom_keyboard_properties[i].language = kbp_supported.languageSupported[i]
  if i <= #kbp_supported.keyboardLayoutSupported then
    custom_keyboard_properties[i].keyboardLayout = kbp_supported.keyboardLayoutSupported[i]
  else
    custom_keyboard_properties[i].keyboardLayout = kbp_supported.keyboardLayoutSupported[#kbp_supported.keyboardLayoutSupported]
  end
  if i <= #kbp_supported.keypressModeSupported then
    custom_keyboard_properties[i].keypressMode = kbp_supported.keypressModeSupported[i]
  else
    custom_keyboard_properties[i].keypressMode = kbp_supported.keypressModeSupported[#kbp_supported.keypressModeSupported]
  end
end

Test["SetGlobalProperties_keyboardProperties_different_from_default"] = function(self)
  local keyboard_properties = custom_keyboard_properties[#custom_keyboard_properties]
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

-- Step 3: Register app again, check SDL -> HMI: UI.SetGlobalProperties(without keyboardProperties)
Test["RegisterAppInterface_keyboardProperties_from_resumption_data"] = function(self)
  common_functions:DelayedExp(1000)
  local app = config.application1.registerAppInterfaceParams
  app.hashID = "invalid hashID"
  local cid = self.mobileSession:SendRPC("RegisterAppInterface", app)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {resumeVrGrammars = false})
  EXPECT_RESPONSE(cid, {success = true , resultCode = "RESUME_FAILED"})
  EXPECT_HMICALL("BasicCommunication.ActivateApp")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
    end)
  EXPECT_NOTIFICATION("OnHMIStatus",
    {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
    {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}
  )
  :Do(function(_,data)
      if data.payload.hmiLevel == "FULL" then
        start_time = timestamp()
      end
    end)

  :Times(2)
  EXPECT_HMICALL("UI.SetGlobalProperties", {})
  :Times(0)
end

-- Check SDL sends UI.SetGlobalProperties with keyboardProperties is default value
Test["UI.SetGlobalProperties with keyboardProperties is default value in 10 seconds"] = function(self)
  EXPECT_HMICALL("UI.SetGlobalProperties",
    {
      keyboardProperties = keyboard_properties
    })
  :Timeout(11000)
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :ValidIf(function(_,data)
      local end_time = timestamp()
      print("Time when SDL->HMI: UI.SetGlobalProperties(): " .. tostring(end_time))
      local interval = (end_time - start_time)
      if interval > 9000 and interval < 11000 then
        return true
      else
        common_functions:printError("Expected timeout for SDL to send UI.SetGlobalProperties to HMI is 10000 milliseconds. Actual timeout is " .. tostring(interval))
        return false
      end
    end)
end

Test["SDL_Clean_Up_keyboardProperties_In_Stored_Data"] = function(self)
  local app_info_file = config.pathToSDL .. "app_info.dat"
  local keyboard_properties = common_functions:GetParameterValueInJsonFile(
    app_info_file,
    {"resumption", "resume_app_list", 1, "globalProperties", "keyboardProperties"})
  if keyboard_properties then
    self:FailTestCase("keyboardProperties parameter is not cleaned in app_info.dat.")
  end
end
