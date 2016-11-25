-------------------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

-----------------------------------------Common Variables--------------------------------------------
local iTimeout = 5000
local MEDIA_APP = config.application1.registerAppInterfaceParams
MEDIA_APP.appName = "MEDIA"
MEDIA_APP.isMediaApplication = true
MEDIA_APP.appHMIType = {"MEDIA"}
MEDIA_APP.appID = "1"
local BUTTON_NAME = "PLAY_PAUSE"
local MOBILE_SESSION = "mobileSession"
local BUTTON_PRESS_MODES = {"SHORT", "LONG"}
local BUTTON_EVENT_MODES = {"BUTTONDOWN","BUTTONUP"}
local InvalidButtonEventModes = {
  {value = {""}, name = "IsEmtpy"},
  {value = "ANY", name = "NonExist"},
  {value = 123, name = "WrongDataType"}
}

-----------------------------------------Local Functions---------------------------------------------
local function SubcribeButton(test_case_name, subscribe_param, expect_hmi_notification, expect_response)
  Test[test_case_name] = function(self)
    subscribe_param = subscribe_param or {buttonName = BUTTON_NAME}
    local cid = self[MOBILE_SESSION]:SendRPC("SubscribeButton",subscribe_param)
    expect_hmi_notification = expect_hmi_notification or {appID = self.applications[MEDIA_APP.appName], isSubscribed = true, name = BUTTON_NAME}
    EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", expect_hmi_notification)
    expect_response = expect_response or {success = true, resultCode = "SUCCESS"}
    EXPECT_RESPONSE(cid, expect_response)
    :Timeout(iTimeout)
    EXPECT_NOTIFICATION("OnHashChange")
  end
end

local function OnButtonEventSuccess(test_case_name, button_press_mode)
  Test[test_case_name] = function(self)
    button_up = "BUTTONUP"
    button_down = "BUTTONDOWN"
    self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = BUTTON_NAME, mode = button_down})
    self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = BUTTON_NAME, mode = button_up})
    self.hmiConnection:SendNotification("Buttons.OnButtonPress",{name = BUTTON_NAME, mode = button_press_mode})
    EXPECT_NOTIFICATION("OnButtonEvent",
      {buttonName = BUTTON_NAME, buttonEventMode = button_down},
      {buttonName = BUTTON_NAME, buttonEventMode = button_up},
      {buttonName = BUTTON_NAME, buttonPressMode = button_press_mode})
    :Times(2)
    EXPECT_NOTIFICATION("OnButtonPress", {buttonName = BUTTON_NAME, buttonPressMode = button_press_mode})
  end
end

local function OnButtonEventWithButtonDownInvalid(test_case_name, button_press_mode, invalid_event_mode)
  Test[test_case_name] = function(self)
    self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = BUTTON_NAME, mode = invalid_event_mode})
    self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = BUTTON_NAME, mode = "BUTTONUP"})
    self.hmiConnection:SendNotification("Buttons.OnButtonPress",{name = BUTTON_NAME, mode = button_press_mode})
    EXPECT_NOTIFICATION("OnButtonEvent",
      {buttonName = BUTTON_NAME, buttonEventMode = "BUTTONUP"},
      {buttonName = BUTTON_NAME, buttonPressMode = button_press_mode})
    :Times(1)
    EXPECT_NOTIFICATION("OnButtonPress", {buttonName = BUTTON_NAME, buttonPressMode = button_press_mode})
  end
end

local function OnButtonEventWithButtonUpInvalid(test_case_name, button_press_mode, invalid_event_mode)
  Test[test_case_name] = function(self)
    self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = BUTTON_NAME, mode = "BUTTONDOWN"})
    self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = BUTTON_NAME, mode = invalid_event_mode})
    self.hmiConnection:SendNotification("Buttons.OnButtonPress",{name = BUTTON_NAME, mode = button_press_mode})
    EXPECT_NOTIFICATION("OnButtonEvent",
      {buttonName = BUTTON_NAME, buttonEventMode = "BUTTONDOWN"},
      {buttonName = BUTTON_NAME, buttonPressMode = button_press_mode})
    :Times(1)
    EXPECT_NOTIFICATION("OnButtonPress", {buttonName = BUTTON_NAME, buttonPressMode = button_press_mode})
  end
end

-------------------------------------------Preconditions---------------------------------------------
common_steps:PreconditionSteps("Precondition", 5)
common_steps:RegisterApplication("RegisterApplication", _, MEDIA_APP, {success = true, resultCode = "SUCCESS"}, {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
common_steps:ActivateApplication("ActivateApplication", MEDIA_APP.appName)

------------------------------------------Body--------------------------------------------------------
------------------------------------------------------------------------------------------------------
-- 1. HMI-SDL: Send OnButtonEvent(PLAY_PAUSE) with valid value: buttonPressMode = SHORT
-- Expected result: SDL must send OnButtonEvent(SUCCESS) to application

-- 2. HMI-SDL: Send OnButtonEvent(PLAY_PAUSE) with valid value: buttonPressMode = LONG
-- Expected result: SDL must send OnButtonEvent(SUCCESS) to application

-- 3. HMI-SDL: Send OnButtonEvent(PLAY_PAUSE) with buttonPressMode = SHORT and BUTTONDOWN is invalid
-- Expected result: SDL ignore invalid value and send OnButtonEvent(SUCCESS) to application

-- 4. HMI-SDL: Send OnButtonEvent(PLAY_PAUSE) with buttonPressMode = SHORT and BUTTONUP is invalid
-- Expected result: SDL ignore invalid value and send OnButtonEvent(SUCCESS) to application
------------------------------------------------------------------------------------------------------
function TestOnButtonEventOnButtonPress()
  common_steps:AddNewTestCasesGroup("TC_OnButton_Event_And_OnButton_Press" )
  SubcribeButton("SubcribeButton")

  for i=1 ,#BUTTON_PRESS_MODES do
    OnButtonEventSuccess(BUTTON_NAME .. "_Button_With_Press_Mode_Is_" .. BUTTON_PRESS_MODES[i] .. "_Success ", BUTTON_PRESS_MODES[i])
  end
  for i=1 ,#BUTTON_PRESS_MODES do
    for j=1, #InvalidButtonEventModes do
      tc_name = BUTTON_NAME .. "_Button_" .. BUTTON_PRESS_MODES[i] .. "_Mode"
      OnButtonEventWithButtonDownInvalid(tc_name .. "_And_BUTTON_UP_Valid_BUTTON_DOWN_" .. InvalidButtonEventModes[j].name, BUTTON_PRESS_MODES[i], InvalidButtonEventModes[j])
      OnButtonEventWithButtonUpInvalid(tc_name .. "_And_BUTTON_DOWN_Valid_BUTTON_UP_" .. InvalidButtonEventModes[j].name, BUTTON_PRESS_MODES[i], InvalidButtonEventModes[j])
    end
  end
end
TestOnButtonEventOnButtonPress()
