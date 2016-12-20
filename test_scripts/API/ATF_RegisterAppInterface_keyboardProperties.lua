-- This script verifies case: SDL -> MOB: RegisterAppInterface(keyboardProperties)
require('user_modules/all_common_modules')

local hmi_capabilities_file = config.pathToSDL .. "hmi_capabilities.json"
-- TC1: Check RegisterAppInterface(keyboardProperties value is gotten from "hmi_capabilities.json")
local kbp_supported = common_functions:GetParameterValueInJsonFile(
  hmi_capabilities_file,
  {"UI", "keyboardPropertiesSupported"})
if not kbp_supported then
  common_functions:PrintError("UI.keyboardPropertiesSupported parameter does not exist in hmi_capabilities.json. Stop ATF script.")
  os.exit()
end
local keyboard_properties = {
  {
    language = kbp_supported.languageSupported[1],
    keyboardLayout = kbp_supported.keyboardLayoutSupported[1],
    keypressMode = kbp_supported.keypressModeSupported[1]
  }
}

-- Precondition: new session is added.
common_steps:PreconditionSteps("Precondition", 5)
-- Step 1: Mobile sends RegisterAppInterface
-- Check SDL -> MOB: RegisterAppInterface(keyboardProperties value is got from "hmi_capabilities.json")
Test["RegisterAppInterface_keyboardProperties_from_HMI_capabilities.json"] = function(self)
  local app = config.application1.registerAppInterfaceParams
  local cid = self.mobileSession:SendRPC("RegisterAppInterface", app)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
    {application = {appName = app.appName}})

  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS",
      keyboardProperties = keyboard_properties})

  EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "NONE",
      audioStreamingState = "NOT_AUDIBLE"})
end

-- TC2: Check RegisterAppInterface(keyboardProperties) with different setting values on "hmi_capabilities.json"
common_steps:StopSDL("Stop SDL")

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
common_functions:AddItemsIntoJsonFile(hmi_capabilities_file, {"UI"}, added_json_items)

common_steps:StartSDL("StartSDL")
common_steps:InitializeHmi("InitHMI")
common_steps:HmiRespondOnReady("InitHMI_onReady")
common_steps:AddMobileConnection("AddDefaultMobileConnection")
common_steps:AddMobileSession("AddDefaultMobileConnect") 

-- Generate expected result from new values on hmi_capabilities.json
local keyboard_properties2 = {}
local kbp_supported = added_json_items.keyboardPropertiesSupported
for i = 1, #kbp_supported.languageSupported do
  keyboard_properties2[i] = {}
  keyboard_properties2[i].language = kbp_supported.languageSupported[i]
  if i <= #kbp_supported.keyboardLayoutSupported then
    keyboard_properties2[i].keyboardLayout = kbp_supported.keyboardLayoutSupported[i]
  else
    keyboard_properties2[i].keyboardLayout = kbp_supported.keyboardLayoutSupported[#kbp_supported.keyboardLayoutSupported]
  end
  if i <= #kbp_supported.keypressModeSupported then
    keyboard_properties2[i].keypressMode = kbp_supported.keypressModeSupported[i]
  else
    keyboard_properties2[i].keypressMode = kbp_supported.keypressModeSupported[#kbp_supported.keypressModeSupported]
  end
end

-- Check SDL -> MOB: RegisterAppInterface(keyboardProperties value is got from "hmi_capabilities.json")
Test["RegisterAppInterface_keyboardProperties_upperbound_from_HMI_capabilities.json"] = function(self)
  local app = config.application1.registerAppInterfaceParams
  local cid = self.mobileSession:SendRPC("RegisterAppInterface", app)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
    {application = {appName = app.appName}})

  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS",
      keyboardProperties = keyboard_properties2})

  EXPECT_NOTIFICATION("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "NONE",
      audioStreamingState = "NOT_AUDIBLE"})
end
