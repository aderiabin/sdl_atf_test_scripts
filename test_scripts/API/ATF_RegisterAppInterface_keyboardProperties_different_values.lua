-- This script verifies case: SDL -> MOB: RegisterAppInterface(keyboardProperties)
-- Specific cases:
-- TC1: RegisterAppInterface(keyboardProperties) in case languageSupported has more values then other parameters
-- TC2: RegisterAppInterface(keyboardProperties) in case keyboardLayoutSupported has more values then other parameters
-- TC3: RegisterAppInterface(keyboardProperties) in case keypressModeSupported has more values then other parameters

require('user_modules/all_common_modules')
local hmi_capabilities_file = config.pathToSDL .. "hmi_capabilities.json"
local app = config.application1.registerAppInterfaceParams

common_functions:DeleteLogsFileAndPolicyTable()
local  file_name  = "app_info.dat"
if common_functions:IsFileExist(config.pathToSDL .. file_name) then
  os.remove(config.pathToSDL .. file_name)
end

-- TC1
common_steps:AddNewTestCasesGroup("TC1: RegisterAppInterface(keyboardProperties) in case languageSupported has more values then other parameters")
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
Test["Precondition_update_keyboardProperties_languageSupported_upperbound_on_hmi_capabilities.json"] = function(self)
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
Test["RegisterAppInterface_keyboardProperties_languageSupported"] = function(self)
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

common_steps:IgnitionOff("Postcondition_IgnitionOff")

-- TC2: RegisterAppInterface(keyboardProperties) in case keyboardLayoutSupported has more values then other parameters
common_steps:AddNewTestCasesGroup("TC2: RegisterAppInterface(keyboardProperties) in case keyboardLayoutSupported has more values then other parameters")
-- Update keyboardPropertiesSupported in hmi_capabilities.json
local added_json_items = {
  keyboardPropertiesSupported =
  {
    languageSupported = {"SK-SK"},
    keyboardLayoutSupported = {
      "QWERTY",
      "QWERTZ",
      "AZERTY"
    },
    keypressModeSupported = {"RESEND_CURRENT_ENTRY"},
    limitedCharactersListSupported = true,
    autoCompleteTextSupported = true
  }
}

Test["Precondition_update_keyboardProperties_keyboardLayoutSupported_upperbound_on_hmi_capabilities.json"] = function(self)
  common_functions:AddItemsIntoJsonFile(hmi_capabilities_file, {"UI"}, added_json_items)
end

-- Generate expected result from new values on hmi_capabilities.json
local keyboard_layout_supported_values = {}
local kbp_supported = added_json_items.keyboardPropertiesSupported
for i = 1, #kbp_supported.keyboardLayoutSupported do
  keyboard_layout_supported_values[i] = {}
  keyboard_layout_supported_values[i].keyboardLayout = kbp_supported.keyboardLayoutSupported[i]
  if i <= #kbp_supported.languageSupported then
    keyboard_layout_supported_values[i].language = kbp_supported.languageSupported[i]
  else
    keyboard_layout_supported_values[i].language = kbp_supported.languageSupported[#kbp_supported.languageSupported]
  end
  if i <= #kbp_supported.keypressModeSupported then
    keyboard_layout_supported_values[i].keypressMode = kbp_supported.keypressModeSupported[i]
  else
    keyboard_layout_supported_values[i].keypressMode = kbp_supported.keypressModeSupported[#kbp_supported.keypressModeSupported]
  end
end

common_steps:IgnitionOn("Precondition_IgnitionOn")
common_steps:AddMobileSession("Precondition_AddMobileSession")
-- Check SDL -> MOB: RegisterAppInterface(keyboardProperties value is got from "hmi_capabilities.json")
Test["RegisterAppInterface_keyboardProperties_keyboardLayoutSupported"] = function(self)
  local app = config.application1.registerAppInterfaceParams
  local cid = self.mobileSession:SendRPC("RegisterAppInterface", app)
  common_functions:StoreApplicationData("mobileSession", app.appName, app, _, self)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
    {application = {appName = app.appName}})
 :Do(function(_,data)
    common_functions:StoreHmiAppId(app.appName, data.params.application.appID, self)
  end)

  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS",
      keyboardProperties = keyboard_layout_supported_values})
  EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "NONE",
      audioStreamingState = "NOT_AUDIBLE"})
end

common_steps:IgnitionOff("Postcondition_IgnitionOff")

-- TC3: RegisterAppInterface(keyboardProperties) in case keypressModeSupported has more values then other parameters
common_steps:AddNewTestCasesGroup("TC3: RegisterAppInterface(keyboardProperties) in case keypressModeSupported has more values then other parameters")
-- Update keyboardPropertiesSupported in hmi_capabilities.json
local added_json_items = {
  keyboardPropertiesSupported =
  {
    languageSupported = {"SK-SK"},
    keyboardLayoutSupported = {
      "QWERTY",
      "QWERTZ"
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

Test["Precondition_update_keyboardProperties_keypressModeSupported_upperbound_on_hmi_capabilities.json"] = function(self)
  common_functions:AddItemsIntoJsonFile(hmi_capabilities_file, {"UI"}, added_json_items)
end

-- Generate expected result from new values on hmi_capabilities.json
local keypress_mode_supported_values = {}
local kbp_supported = added_json_items.keyboardPropertiesSupported
for i = 1, #kbp_supported.keypressModeSupported do
  keypress_mode_supported_values[i] = {}
  keypress_mode_supported_values[i].keypressMode = kbp_supported.keypressModeSupported[i]
  if i <= #kbp_supported.keypressModeSupported then
    keypress_mode_supported_values[i].language = kbp_supported.languageSupported[i]
  else
    keypress_mode_supported_values[i].language = kbp_supported.languageSupported[#kbp_supported.languageSupported]
  end
  if i <= #kbp_supported.keypressModeSupported then
    custom_keyboard_properties[i].keyboardLayout = kbp_supported.keyboardLayoutSupported[i]
  else
    custom_keyboard_properties[i].keyboardLayout = kbp_supported.keyboardLayoutSupported[#kbp_supported.keyboardLayoutSupported]
  end
end

common_steps:IgnitionOn("Precondition_IgnitionOn")
common_steps:AddMobileSession("Precondition_AddMobileSession")
-- Check SDL -> MOB: RegisterAppInterface(keyboardProperties value is got from "hmi_capabilities.json")
Test["RegisterAppInterface_keyboardProperties_keypressModeSupported"] = function(self)
  local app = config.application1.registerAppInterfaceParams
  local cid = self.mobileSession:SendRPC("RegisterAppInterface", app)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
    {application = {appName = app.appName}})
  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS",
      keyboardProperties = keypress_mode_supported_values})
  EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "NONE",
      audioStreamingState = "NOT_AUDIBLE"})
end
