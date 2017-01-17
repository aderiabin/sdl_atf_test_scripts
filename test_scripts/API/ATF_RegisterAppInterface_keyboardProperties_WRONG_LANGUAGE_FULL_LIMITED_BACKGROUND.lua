-- This script verifies case: MOB -> SDL: There is no SetGlobalProperties() in 10s and keyboardProperties is not resumed.
-- Specific case: RegisterAppInterface(keyboardProperties, WRONG_LANGUAGE) and default HMI level is FULL, LIMITED, BACKGROUND
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

local hmi_levels = {"LIMITED", "FULL", "BACKGROUND"}
for i = 1, #hmi_levels do
  common_steps:AddNewTestCasesGroup("Check timer 10s is started when RegisterAppInterface responds WRONG_LANGUAGE and default hmi level is " .. hmi_levels[i])
  Test["Precondition_Update_sdl_preloaded_pt.json"] = function (self)
    local json_file = config.pathToSDL .. "sdl_preloaded_pt.json"
    local parent_item = {"policy_table", "app_policies"}
    local added_json_items = {}
    local app = config.application1.registerAppInterfaceParams
    added_json_items[app.appID] = {
      keep_context = false,
      steal_focus = false,
      priority = "NONE",
      appHMIType = {"NAVIGATION"},
      default_hmi = hmi_levels[i],
      groups = {"Base-4"}
    }
    common_functions:AddItemsIntoJsonFile(json_file, parent_item, added_json_items)
    -- delay to make sure sdl_preloaded_pt.json is already updated
    common_functions:DelayedExp(1000)
  end
  
  common_steps:StopSDL("Precondition_Stop_SDL")
  common_steps:RemoveFileInSdlBinFolder("Precondition_Remove_app_info.dat", "app_info.dat")
  Test["Precondition_RemoveExistedLPT"] = function (self)
    common_functions:DeletePolicyTable()
  end

  -- a session is added.
  common_steps:PreconditionSteps("Precondition", 5)
  Test["Device_Consent"] = function(self)
    self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
  end

  -- Check SDL starts timer 10s when RegisterAppInterface response WRONG_LANGUAGE
  -- and default hmi level is not NONE
  Test["RegisterAppInterface_WRONG_LANGUAGE_default_hmi_level_" .. hmi_levels[i]] = function(self)
    local app = config.application1.registerAppInterfaceParams
    app.appHMIType = { "NAVIGATION" }
    app.isMediaApplication = true
    app.languageDesired = "FR-CA"
    local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface", app)
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = {appName = app.appName}})
    self.mobileSession:ExpectResponse(CorIdRAI, {success = true, resultCode = "WRONG_LANGUAGE"})
    local audio_streaming_state = "AUDIBLE"
    if hmi_levels[i] == "BACKGROUND" then
      audio_streaming_state = "NOT_AUDIBLE"
    end
    self.mobileSession:ExpectNotification("OnHMIStatus",
      {hmiLevel = hmi_levels[i], audioStreamingState = audio_streaming_state, systemContext = "MAIN"})
    :Do(function(_,data)
        start_time = timestamp()
        print("Time when app is changed to " .. hmi_levels[i] .. ": " .. tostring(start_time))
      end)
  end
  -- Mobile does not send <keyboardProperties> after 10 sec
  -- Check SDL sends UI.SetGlobalProperties with keyboardProperties is default value
  Test["UI.SGP with default keyboardProperties in 10s in case RegisterAppInterface_WRONG_LANGUAGE and hmi level " .. hmi_levels[i]] = function(self)
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
end
