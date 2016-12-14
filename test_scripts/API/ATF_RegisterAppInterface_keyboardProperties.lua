-- This script verifies case: SDL -> MOB: RegisterAppInterface(keyboardProperties)
require('user_modules/all_common_modules')

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
-- Check SDL -> MOD: RegisterAppInterface(keyboardProperties value is got from "HMI_capabilities.json")
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
