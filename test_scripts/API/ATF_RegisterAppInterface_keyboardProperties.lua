-- This script verifies case: SDL -> MOB: RegisterAppInterface(keyboardProperties)
-- Specific case: RegisterAppInterface(keyboardProperties, SUCCESS) and default HMI level is NONE
require('user_modules/all_common_modules')
local TIMEOUT_PROMPT = {{text = "Timeout prompt", type = "TEXT"}}
local HELP_PROMPT = {{text = "Help prompt", type = "TEXT"}}
local MENU_TITLE = "Menu Title"
local VRHELP = {{position = 1, text = "VR help item"}}
local VRHELP_TITLE = "VR help title"
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
