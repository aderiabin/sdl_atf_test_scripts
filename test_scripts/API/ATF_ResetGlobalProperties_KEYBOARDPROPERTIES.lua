-- This script verifies case: MOB -> SDL: ResetGlobalProperties("KEYBOARDPROPERTIES")
require('user_modules/all_common_modules')

local SUCCESS_RESULTCODES = {"SUCCESS"}
local ERROR_RESULTCODES = {"INVALID_DATA", "REJECTED", "DISALLOWED", "USER_DISALLOWED", "OUT_OF_MEMORY", "TOO_MANY_PENDING_REQUESTS", "WARNINGS", "GENERIC_ERROR", "APPLICATION_NOT_REGISTERED"}

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

local kp_default = GetParameterValueInJsonFile(
  config.pathToSDL .. "hmi_capabilities.json",
  {"UI", "displayCapabilities", "keyboardPropertiesDefault"})

if kp_default.languageDefault == nil  then
  common_functions:PrintError("keyboardPropertiesDefault.languageDefault parameter is not exist in hmi_capabilities.json. Stop ATF script.")
  quit(1)
end

local default_keyboard_properties = {
  language = kp_default.languageDefault,
  keyboardLayout = kp_default.keyboardLayoutDefault,
  keypressMode = kp_default.keypressModeDefault,
}

-- Precondition: an application is registered
common_steps:PreconditionSteps("Precondition", 6)

-- MOB -> SDL: ResetGlobalProperties("KEYBOARDPROPERTIES")
-- SDL -> HMI: UI.SetGlobalProperties(keyboardProperties retrieved from 'HMI_capabilities.json' file)
for i = 1, #SUCCESS_RESULTCODES do
  Test["ResetGlobalProperties_KEYBOARDPROPERTIES_resultCode_" .. SUCCESS_RESULTCODES[i]] = function(self)
    local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
      {properties = {"KEYBOARDPROPERTIES"}})

    EXPECT_HMICALL("UI.SetGlobalProperties",
      {keyboardProperties = default_keyboard_properties})
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, SUCCESS_RESULTCODES[i], {})
      end)
    EXPECT_RESPONSE(cid, {success = true, resultCode = SUCCESS_RESULTCODES[i]})
    EXPECT_NOTIFICATION("OnHashChange")
  end
end

for i = 1, #ERROR_RESULTCODES do
  Test["ResetGlobalProperties_KEYBOARDPROPERTIES_resultCode_" .. ERROR_RESULTCODES[i]] = function(self)
    common_functions:DelayedExp(1000)
    local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
      {properties = {"KEYBOARDPROPERTIES"}})

    EXPECT_HMICALL("UI.SetGlobalProperties",
      {keyboardProperties = default_keyboard_properties})
    :Do(function(_,data)
        self.hmiConnection:SendError(data.id, data.method, ERROR_RESULTCODES[i], "error message")
      end)
    EXPECT_RESPONSE(cid, {success = false, resultCode = ERROR_RESULTCODES[i]})
    EXPECT_NOTIFICATION("OnHashChange")
    :Times(0)
  end
end
