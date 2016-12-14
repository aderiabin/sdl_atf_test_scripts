-- This script verifies case: MOB -> SDL: There is no SetGlobalProperties() in 10s and keyboardProperties is not resumed.
require('user_modules/all_common_modules')
local current_time

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

local keyboard_properties_default = GetParameterValueInJsonFile(
  config.pathToSDL .. "hmi_capabilities.json",
  {"UI", "displayCapabilities", "keyboardPropertiesDefault"})
local keyboard_properties = {
  language = keyboard_properties_default.languageDefault,
  keyboardLayout = keyboard_properties_default.keyboardLayoutDefault,
  keypressMode = keyboard_properties_default.keypressModeDefault
}
-- Precondition: an application is registered
common_steps:PreconditionSteps("Precondition", 6)

Test["SDL does not send UI.SetGlobalProperties to HMI if app is NONE HMI level in 12 seconds"] = function(self)
  common_functions:DelayedExp(12000)
  EXPECT_HMICALL("UI.SetGlobalProperties",
    {
      menuTitle = MENU_TITLE,
      vrHelp = VRHELP,
      menuTitle = MENU_TITLE,
      keyboardProperties = keyboard_properties
    })
  :Times(0)
end

common_steps:ActivateApplication("ActivateApplication", config.application1.registerAppInterfaceParams.appName) 
  
Test["GetCurrentTime"] = function(self)
  current_time = timestamp()
  print("Time when app is activated: " .. tostring(current_time))
end

-- Mobile does not send send <keyboardProperties> during 10 sec
-- Check SDL sends UI.SetGlobalProperties with keyboardProperties is default value
Test["UI.SetGlobalProperties with keyboardProperties is default value in 10 seconds"] = function(self)
  EXPECT_HMICALL("UI.SetGlobalProperties",
    {
      menuTitle = MENU_TITLE,
      vrHelp = VRHELP,
      menuTitle = MENU_TITLE,
      keyboardProperties = keyboard_properties
    })
  :Timeout(15000)
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :ValidIf(function(_,data)
      local current_time1 = timestamp()
      print("GetCurrentTime: " .. tostring(current_time1))
      if current_time1 - current_time > 9000 and current_time1 - current_time < 11000 then
        return true
      else
        common_functions:printError("Expected timeout for SDL sends UI.SetGlobalProperties to HMI is 10000 milliseconds. Actual timeout is " .. tostring(current_time1 - current_time))
        return false
      end
    end)
end
