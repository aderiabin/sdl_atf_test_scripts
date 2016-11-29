-------------------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

-----------------------------------------Common Variables--------------------------------------------
local MEDIA_APP = config.application1.registerAppInterfaceParams
MEDIA_APP.appName = "MEDIA"
MEDIA_APP.isMediaApplication = true
MEDIA_APP.appHMIType = {"MEDIA"}
MEDIA_APP.appID = "1"
local BUTTON_NAME = "PLAY_PAUSE"
local MOBILE_SESSION = "mobileSession"
local BUTTON_PRESS_MODES = {"SHORT", "LONG"}
local BUTTON_EVENT_MODES = {"BUTTONDOWN","BUTTONUP"}
local InvalidModes = {
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
    EXPECT_NOTIFICATION("OnHashChange")
  end
end

local function OnButtonEventOnButtonPressSuccess(test_case_name)
  for i =1, #BUTTON_PRESS_MODES do
    Test[test_case_name .. BUTTON_PRESS_MODES[i] .. "_Success"] = function(self)
      self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = BUTTON_NAME, mode = "BUTTONDOWN"})
      self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = BUTTON_NAME, mode = "BUTTONUP"})
      self.hmiConnection:SendNotification("Buttons.OnButtonPress",{name = BUTTON_NAME, mode = BUTTON_PRESS_MODES[i]})
      EXPECT_NOTIFICATION("OnButtonEvent",
        {buttonName = BUTTON_NAME, buttonEventMode = "BUTTONDOWN"},
        {buttonName = BUTTON_NAME, buttonEventMode = "BUTTONUP"})
      :Times(2)
      EXPECT_NOTIFICATION("OnButtonPress", {buttonName = BUTTON_NAME, buttonPressMode = BUTTON_PRESS_MODES[i]})
    end
  end
end

local function OnButtonEventOnButtonPressSuccessWithFakeParam(test_case_name)
  for i =1, #BUTTON_PRESS_MODES do
    Test[test_case_name .. BUTTON_PRESS_MODES[i] .. "_With_Fake_Params"] = function(self)
      subscribe_param = subscribe_param or {buttonName = BUTTON_NAME}
      self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{fakeParameter = "fakeParameter", name = BUTTON_NAME, mode = "BUTTONDOWN"})
      self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{fakeParameter = "fakeParameter", name = BUTTON_NAME, mode = "BUTTONUP"})
      self.hmiConnection:SendNotification("Buttons.OnButtonPress",{fakeParameter = "fakeParameter", name = BUTTON_NAME, mode = BUTTON_PRESS_MODES[i]})
      EXPECT_NOTIFICATION("OnButtonEvent",
        {buttonName = BUTTON_NAME, buttonEventMode = "BUTTONDOWN"},
        {buttonName = BUTTON_NAME, buttonEventMode = "BUTTONUP"})
      :Times(2)
      EXPECT_NOTIFICATION("OnButtonPress", {buttonName = BUTTON_NAME, buttonPressMode = BUTTON_PRESS_MODES[i]})
    end
  end
end

local function OnButtonEventWithEventModeInvalid(test_case_name)
  for i=1, #InvalidModes do
    Test[test_case_name .. InvalidModes[i].name] = function(self)
      self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = BUTTON_NAME, mode = InvalidModes[i]})
      EXPECT_NOTIFICATION("OnButtonEvent")
      :Times(0)
    end
  end
end

local function OnButtonPressWithPressModeInvalid(test_case_name)
  for i=1, #InvalidModes do
    Test[test_case_name .. InvalidModes[i].name] = function(self)
      self.hmiConnection:SendNotification("Buttons.OnButtonPress",{name = BUTTON_NAME, mode = InvalidModes[i]})
      EXPECT_NOTIFICATION("OnButtonEvent")
      :Times(0)
    end
  end
end

-------------------------------------------Preconditions---------------------------------------------
common_steps:PreconditionSteps("Precondition", 5)
common_steps:RegisterApplication("RegisterApplication", _, MEDIA_APP, {success = true, resultCode = "SUCCESS"}, {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
common_steps:ActivateApplication("ActivateApplication", MEDIA_APP.appName)

------------------------------------------Body--------------------------------------------------------
------------------------------------------------------------------------------------------------------
-- Precondition: SubscribleButton(PLAY_PAUSE)
-- 1. HMI-SDL: Send OnButtonEvent(PLAY_PAUSE) with valid value and OnButtonPress(PLAY_PAUSE) with buttonPressMode = SHORT
-- Expected result: SDL must send OnButtonEvent() and OnButtonPress(SHORT) to application

-- 2. HMI-SDL: Send OnButtonEvent(PLAY_PAUSE) with valid value and OnButtonPress(PLAY_PAUSE) with buttonPressMode = LONG
-- Expected result: SDL must send OnButtonEvent() and OnButtonPress(LONG) to application

-- 3. HMI-SDL: Send OnButtonEvent(PLAY_PAUSE), OnButtonPress(PLAY_PAUSE) with fake params
-- Expected result: SDL ignore fake params and send OnButtonEvent() and OnButtonPress() to application

-- 4. HMI-SDL: Send OnButtonEvent(PLAY_PAUSE)/ OnButtonPress() with mode is invalid value
-- Expected result: SDL must not send OnButtonEvent/OnButtonPress() to application
------------------------------------------------------------------------------------------------------
function TestOnButtonEventOnButtonPress()
  common_steps:AddNewTestCasesGroup("TC_OnButton_Event_And_OnButton_Press" )
  -- Precondition
  SubcribeButton("Precondition_SubcribeButton")
  -- Body
  OnButtonEventOnButtonPressSuccess(BUTTON_NAME .. "_Button_With_Press_Mode_Is_")
  OnButtonEventOnButtonPressSuccessWithFakeParam(BUTTON_NAME .. "_Button_With_Press_Mode_Is_")
  OnButtonEventWithEventModeInvalid(BUTTON_NAME .. "_Button_With_Event_Mode_Invalid: ")
  OnButtonPressWithPressModeInvalid(BUTTON_NAME .. "_Button_With_Press_Mode_Invalid: ")
end
TestOnButtonEventOnButtonPress()
