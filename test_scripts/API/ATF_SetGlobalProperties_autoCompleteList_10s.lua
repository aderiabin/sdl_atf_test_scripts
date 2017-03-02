require('user_modules/all_common_modules')
local MENU_TITLE = "Menu Title"
local app = config.application1.registerAppInterfaceParams
local VRHELP = {{position = 1, text = app.appName}}
local VRHELP_TITLE = app.appName
local start_time
local end_time
local kbp_supported
local keyboard_properties

-------------------------------------------Common functions----------------------------------
function GetDefaultKeyboardProperties()
  kbp_supported = common_functions:GetParameterValueInJsonFile(
    config.pathToSDL .. "hmi_capabilities.json",
    {"UI", "keyboardPropertiesDefault"})
  if not kbp_supported then
    common_functions:PrintError("UI.keyboardPropertiesDefault parameter does not exist in hmi_capabilities.json. Stop ATF script.")
    os.exit()
  end
  keyboard_properties = {
    language = kbp_supported.languageDefault,
    keyboardLayout = kbp_supported.keyboardLayoutDefault,
    keypressMode = kbp_supported.keypressModeDefault,
    autoCompleteList = kbp_supported.autoCompleteListDefault
  }
end

function SdlNotSendUISetGlobalProperties()
  common_functions:DelayedExp(12000)
  EXPECT_HMICALL("UI.SetGlobalProperties")
  :Times(0)
end

function GetCurrentTime()
  start_time = timestamp()
  print("Time when app is activated: " .. tostring(start_time))
end

function SdlSendDefaultValue(self)
  EXPECT_HMICALL("UI.SetGlobalProperties",
    {
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

---------------------------------------------------Body---------------------------------------
common_steps:AddNewTestCasesGroup("Check timer 10s is started when app is activated - autoCompleteListDefault value is true")
function Test:UpdateAutoCompleteListTrue()
  local pathToFile = config.pathToSDL .. 'hmi_capabilities.json'
  local parent_item = {"UI", "keyboardPropertiesDefault"}
  local added_json_items =
  [[
  {
    "languageDefault": "EN-US",
    "keyboardLayoutDefault": "QWERTY",
    "keypressModeDefault": "SINGLE_KEYPRESS",
    "autoCompleteListDefault": true
  }
  ]]
  common_functions:AddItemsIntoJsonFile(pathToFile, parent_item, added_json_items)
end

-- Precondition: an application is registered
common_steps:PreconditionSteps("Precondition", 6)

function Test:GetDefaultKeyboardProperties()
  GetDefaultKeyboardProperties()
end

function Test:SdlNotSendUISetGlobalProperties()
  SdlNotSendUISetGlobalProperties()
end

common_steps:ActivateApplication("ActivateApplication", app.appName)

function Test:GetCurrentTime()
  GetCurrentTime()
end

function Test:SdlSendDefaultValue()
  SdlSendDefaultValue(self)
end

common_steps:StopSDL("StopSDL")
common_functions:DeleteLogsFileAndPolicyTable()

common_steps:AddNewTestCasesGroup("Check timer 10s is started when app is activated - autoCompleteListDefault value is false")

function Test:UpdateAutoCompleteListFalse()
  local pathToFile = config.pathToSDL .. 'hmi_capabilities.json'
  local parent_item = {"UI", "keyboardPropertiesDefault"}
  local added_json_items =
  [[
  {
    "languageDefault": "EN-US",
    "keyboardLayoutDefault": "QWERTY",
    "keypressModeDefault": "SINGLE_KEYPRESS",
    "autoCompleteListDefault": false
  }
  ]]
  common_functions:AddItemsIntoJsonFile(pathToFile, parent_item, added_json_items)
end

-- Precondition: an application is registered
common_steps:PreconditionSteps("Precondition", 6)
function Test:GetDefaultKeyboardProperties()
  GetDefaultKeyboardProperties()
end

function Test:SdlNotSendUISetGlobalProperties()
  SdlNotSendUISetGlobalProperties()
end

common_steps:ActivateApplication("ActivateApplication", config.application1.registerAppInterfaceParams.appName)

function Test:GetCurrentTime()
  GetCurrentTime()
end

function Test:SdlSendDefaultValue()
  SdlSendDefaultValue(self)
end

------------------------------------------Postconditions-------------------------------------
common_steps:StopSDL("StopSDL")
