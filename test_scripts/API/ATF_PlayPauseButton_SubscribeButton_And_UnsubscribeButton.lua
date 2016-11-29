-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

------------------------------------ Common Variables ---------------------------------------
local iTimeout = 5000
MEDIA_APP = config.application1.registerAppInterfaceParams
MEDIA_APP.appName = "MEDIA"
MEDIA_APP.isMediaApplication = true
MEDIA_APP.appHMIType = {"MEDIA"}
MEDIA_APP.appID = "1"
local BUTTON_NAME = "PLAY_PAUSE"
local MOBILE_SESSION = "mobileSession"
local BUTTON_PRESS_MODES = {"SHORT", "LONG"}

-------------------------------------------Local Functions-----------------------------------
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

local function UnSubcribeButton(test_case_name, unsubscribe_param, expect_hmi_notification, expect_response)
  Test[test_case_name] = function(self)
    unsubscribe_param = unsubscribe_param or {buttonName = BUTTON_NAME}
    local cid = self[MOBILE_SESSION]:SendRPC("UnsubscribeButton",unsubscribe_param)
    expect_hmi_notification = expect_hmi_notification or {appID = self.applications[MEDIA_APP.appName], isSubscribed = false, name = BUTTON_NAME}
    EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", expect_hmi_notification)
    :Timeout(iTimeout)
    expect_response = expect_response or {success = true, resultCode = "SUCCESS"}
    EXPECT_RESPONSE(cid, expect_response)
    :Timeout(iTimeout)
    EXPECT_NOTIFICATION("OnHashChange")
  end
end

-------------------------------------------Preconditions-------------------------------------
common_steps:PreconditionSteps("Precondition", 5)
common_steps:RegisterApplication("RegisterApplication", MOBILE_SESSION, MEDIA_APP, {success = true, resultCode = "SUCCESS"}, {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
common_steps:ActivateApplication("ActivateApplication", MEDIA_APP.appName)

-------------------------------------------Body-------------------------------------
-------------------------------------------------------------------------------------
-- 1. MOB-SDL: Send SubscribleButton(PLAY_PAUSE) with valid value
-- Expected result: SDL must send SubscribleButton(SUCCESS) and OnHashChange() to app
-- Postcondition: UnsubscribleButton(PLAY_PAUSE)'

-- 2. MOB-SDL: Send SubscribleButton(PLAY_PAUSE) with fake param
-- Expected result: SDL must send SubscribleButton(SUCCESS) and OnHashChange() to app
-- Postcondition: UnsubscribleButton(PLAY_PAUSE)

-- 3. MOB-SDL: Send SubscribleButton(PLAY_PAUSE) with fake param from another API
-- Expected result: SDL must send SubscribleButton(SUCCESS) and OnHashChange() to app
-- Postcondition: UnsubscribleButton(PLAY_PAUSE)
-------------------------------------------------------------------------------------
function TestSubscribeButton()
  common_steps:AddNewTestCasesGroup("TC_Subscribe_Button" )

  SubcribeButton("SubcribeButton_" .. BUTTON_NAME .. "_Success")
  UnSubcribeButton("PostCondition_UnSubcribeButton")

  SubcribeButton("SubcribeButton_" .. BUTTON_NAME .. "_Fake_Param",{fakeParameter = "fakeParameter", buttonName = BUTTON_NAME})
  UnSubcribeButton("PostCondition_UnSubcribeButton")

  SubcribeButton("SubcribeButton_" .. BUTTON_NAME .. "_Parameter_Of_Other_API",{syncFileName = "icon.png",buttonName = BUTTON_NAME})
  UnSubcribeButton("PostCondition_UnSubcribeButton")
end
TestSubscribeButton()

-------------------------------------------------------------------------------------
-- Precondition: SubscribleButton(PLAY_PAUSE)
-- 1. MOB-SDL: Send UnsubscribleButton(PLAY_PAUSE) with valid value
-- Expected result: SDL must send UnsubscribleButton(SUCCESS) and OnHashChange() to app

-- Precondition: SubscribleButton(PLAY_PAUSE)
-- 2. MOB-SDL: Send UnsubscribleButton(PLAY_PAUSE) with fake param
-- Expected result: SDL must send UnsubscribleButton(SUCCESS) and OnHashChange() to app

-- Precondition: SubscribleButton(PLAY_PAUSE)
-- 3. MOB-SDL: Send UnsubscribleButton(PLAY_PAUSE) with fake param from another API
-- Expected result: SDL must send UnsubscribleButton(SUCCESS) and OnHashChange() to app
-------------------------------------------------------------------------------------
function TestUnSubscribeButton()
  common_steps:AddNewTestCasesGroup("TC_UnSubscribe_Button" )

  SubcribeButton("Precondition_SubcribeButton")
  UnSubcribeButton("UnSubcribeButton_" .. BUTTON_NAME .. "_Success")

  SubcribeButton("Precondition_SubcribeButton")
  UnSubcribeButton("UnSubcribeButton_" .. BUTTON_NAME .. "_Fake_Param",{fakeParameter = "fakeParameter", buttonName = BUTTON_NAME})

  SubcribeButton("Precondition_SubcribeButton")
  UnSubcribeButton("UnSubcribeButton_" .. BUTTON_NAME .. "_Parameter_Of_Other_API",{syncFileName = "icon.png",buttonName = BUTTON_NAME})
end
TestUnSubscribeButton()
