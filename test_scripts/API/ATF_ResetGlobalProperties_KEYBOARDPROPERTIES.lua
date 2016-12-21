-- This script verifies case: MOB -> SDL: ResetGlobalProperties("KEYBOARDPROPERTIES")
require('user_modules/all_common_modules')
local SUCCESS_RESULTCODES = {"SUCCESS"}
local ERROR_RESULTCODES = {"INVALID_DATA", "REJECTED", "DISALLOWED", "USER_DISALLOWED", "WARNINGS", "OUT_OF_MEMORY", "TOO_MANY_PENDING_REQUESTS", "GENERIC_ERROR", "APPLICATION_NOT_REGISTERED"}

local kbp_default = common_functions:GetParameterValueInJsonFile(
  config.pathToSDL .. "hmi_capabilities.json",
  {"UI", "keyboardPropertiesDefault"})

if not kbp_default then
  common_functions:PrintError("UI.keyboardPropertiesDefault parameter does not exist in hmi_capabilities.json. Stop ATF script.")
  os.exit()
end

local default_keyboard_properties = {
  language = kbp_default.languageDefault,
  keyboardLayout = kbp_default.keyboardLayoutDefault,
  keypressMode = kbp_default.keypressModeDefault,
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
    common_functions:DelayedExp(500)
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
