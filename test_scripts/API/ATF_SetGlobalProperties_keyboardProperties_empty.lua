-- This script verifies case: MOB -> SDL: ResetGlobalProperties(empty "KEYBOARDPROPERTIES")
require('user_modules/all_common_modules')

local TIMEOUT_PROMPT = {{text = "Timeout prompt", type = "TEXT"}}
local HELP_PROMPT = {{text = "Help prompt", type = "TEXT"}}
local MENU_TITLE = "Menu Title"
local VRHELP = {{position = 1, text = "VR help item"}}
local VRHELP_TITLE = "VR help title"

-- Precondition: an app is registered
common_steps:PreconditionSteps("Precondition", 6)

local function TC_SetGlobalProperties_keyboardProperties_empty(test_case_name)
  Test[test_case_name] = function(self)
    local cid = self.mobileSession:SendRPC("SetGlobalProperties",
      {
        keyboardProperties = {},
        helpPrompt = HELP_PROMPT,
        timeoutPrompt = TIMEOUT_PROMPT,
        menuTitle = MENU_TITLE,
        vrHelp = VRHELP,
        vrHelpTitle = VRHELP_TITLE
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
        vrHelpTitle = VRHELP_TITLE
      })
    :ValidIf(function(_,data)
        return not data.params.keyboardProperties
      end)
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)

    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
    EXPECT_NOTIFICATION("OnHashChange")
  end
end

TC_SetGlobalProperties_keyboardProperties_empty("TC1_SetGlobalProperties_keyboardProperties_empty_during_10s")
common_steps:Sleep("Sleep_15_seconds_to_test_case_SetGlobalProperties_during_ignition_cycle", 15)
TC_SetGlobalProperties_keyboardProperties_empty("TC2_SetGlobalProperties_keyboardProperties_empty_during_ignition_cycle")
