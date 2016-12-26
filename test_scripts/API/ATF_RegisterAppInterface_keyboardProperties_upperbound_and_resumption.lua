-- This script verifies case: SDL -> MOB: RegisterAppInterface(keyboardProperties)
-- Specific cases:
-- TC1: RegisterAppInterface(keyboardProperties is upper bound)
-- TC2: Resume UI.SetGlobalProperties(keyboardProperties is different from default value)
require('user_modules/all_common_modules')
local TIMEOUT_PROMPT = {{text = "Timeout prompt", type = "TEXT"}}
local HELP_PROMPT = {{text = "Help prompt", type = "TEXT"}}
local MENU_TITLE = "Menu Title"
local VRHELP = {{position = 1, text = "VR help item"}}
local VRHELP_TITLE = "VR help title"
local hmi_capabilities_file = config.pathToSDL .. "hmi_capabilities.json"
local app = config.application1.registerAppInterfaceParams
local start_time
local end_time

-- TC1
-- common_steps:AddNewTestCasesGroup("TC1: Check RegisterAppInterface(keyboardProperties value is upper bound)")
-- local kbp_supported = common_functions:GetParameterValueInJsonFile(
-- hmi_capabilities_file,
-- {"UI", "keyboardPropertiesSupported"})
-- if not kbp_supported then
-- common_functions:PrintError("UI.keyboardPropertiesSupported parameter does not exist in hmi_capabilities.json. Stop ATF script.")
-- os.exit()
-- end

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
Test["Precondition_update_keyboardProperties_upperbound_on_hmi_capabilities.json"] = function(self)
  common_functions:AddItemsIntoJsonFile(hmi_capabilities_file, {"UI"}, added_json_items)
end
-- Precondition: a session is added
common_steps:PreconditionSteps("Precondition", 5)
-- Generate expected result from new values on hmi_capabilities.json
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
-- Check SDL -> MOB: RegisterAppInterface(keyboardProperties value is got from "hmi_capabilities.json")
Test["RegisterAppInterface_keyboardProperties_upperbound_from_HMI_capabilities.json"] = function(self)
  local app = config.application1.registerAppInterfaceParams
  local cid = self.mobileSession:SendRPC("RegisterAppInterface", app)
  common_functions:StoreApplicationData("mobileSession", app.appName, app, _, self)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
    {application = {appName = app.appName}})
  :Do(function(_,data)
      common_functions:StoreHmiAppId(app.appName, data.params.application.appID, self)
    end)
  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS",
      keyboardProperties = custom_keyboard_properties})
  EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "NONE",
      audioStreamingState = "NOT_AUDIBLE"})
end

-- TC2
common_steps:AddNewTestCasesGroup("TC2: Check resumption with keyboardProperties is different from default value.")
common_steps:ActivateApplication("ActivateApplication", config.application1.registerAppInterfaceParams.appName)

Test["GetCurrentTime"] = function(self)
  start_time = timestamp()
  print("Time when app is activated: " .. tostring(start_time))
end

-- Mobile does not send send <keyboardProperties> during 10 sec
-- Check SDL sends UI.SetGlobalProperties with keyboardProperties is default value
Test["UI.SetGlobalProperties with keyboardProperties is default value in 10 seconds"] = function(self)
  local keyboard_properties_default = common_functions:GetParameterValueInJsonFile(
    hmi_capabilities_file,
    {"UI", "keyboardPropertiesDefault"})
  local keyboard_properties = {
    language = keyboard_properties_default.languageDefault,
    keyboardLayout = keyboard_properties_default.keyboardLayoutDefault,
    keypressMode = keyboard_properties_default.keypressModeDefault
  }
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

Test["WaitForTTS.SetGlobalProperties_to_avoid_effect_next_test"] = function(self)
  EXPECT_HMICALL("TTS.SetGlobalProperties", {})
  :Timeout(1000)
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :Times(AnyNumber())
end

Test["Precondition_SetGlobalProperties_keyboardProperties_different_from_default"] = function(self)
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
common_steps:IgnitionOff("Precondition_IgnitionOff")
common_steps:IgnitionOn("Precondition_IgnitionOn")
common_steps:AddMobileSession("Precondition_AddMobileSession")
-- Register app again, check SDL -> HMI: UI.SetGlobalProperties(keyboardProperties = value from resumption)
Test["RegisterAppInterface_keyboardProperties_from_resumption_data"] = function(self)
  app.hashID = self.currentHashID
  local cid = self.mobileSession:SendRPC("RegisterAppInterface", app)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {})
  EXPECT_RESPONSE(cid, { success = true , resultCode = "SUCCESS",
      info = "Resume succeeded.", keyboardProperties = custom_keyboard_properties})
  EXPECT_HMICALL("BasicCommunication.ActivateApp")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
    end)

  EXPECT_NOTIFICATION("OnHMIStatus",
    {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
    {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}
  )
  :Times(2)
  local keyboard_properties = custom_keyboard_properties[#custom_keyboard_properties]
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
