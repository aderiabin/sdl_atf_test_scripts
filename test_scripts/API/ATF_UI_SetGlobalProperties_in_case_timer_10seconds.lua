-- This script verifies case: MOB -> SDL: There is no SetGlobalProperties() in 10s and keyboardProperties is not resumed.
require('user_modules/all_common_modules')
local start_time
local end_time

local kbp_supported = common_functions:GetParameterValueInJsonFile(
  config.pathToSDL .. "hmi_capabilities.json",
  {"UI", "keyboardPropertiesDefault"})
if not kbp_supported then
  common_functions:PrintError("UI.keyboardPropertiesDefault parameter does not exist in hmi_capabilities.json. Stop ATF script.")
  os.exit()
end
local keyboard_properties = {
  language = kbp_supported.languageDefault,
  keyboardLayout = kbp_supported.keyboardLayoutDefault,
  keypressMode = kbp_supported.keypressModeDefault
}

-- TC1: Check timer 10s is started when app is activated
common_steps:AddNewTestCasesGroup("Check timer 10s is started when app is activated")
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
  start_time = timestamp()
  print("Time when app is activated: " .. tostring(start_time))
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
