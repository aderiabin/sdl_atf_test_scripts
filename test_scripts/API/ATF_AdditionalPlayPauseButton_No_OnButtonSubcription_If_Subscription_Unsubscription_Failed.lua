-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

------------------------------------ Common Variables ---------------------------------------
local MEDIA_APP = config.application1.registerAppInterfaceParams
MEDIA_APP.appName = "MEDIA"
MEDIA_APP.isMediaApplication = true
MEDIA_APP.appHMIType = {"MEDIA"}
MEDIA_APP.appID = "1"
local BUTTON_NAME = "PLAY_PAUSE"
local MOBILE_SESSION = "mobileSession"

-------------------------------------------Local Functions-----------------------------------
local function SubcribeButton(test_case_name)
  Test[test_case_name] = function(self)
    local cid = self[MOBILE_SESSION]:SendRPC("SubscribeButton",{buttonName = BUTTON_NAME})
    EXPECT_RESPONSE("SubscribeButton")
    :ValidIf(function(_,data)
        if data.payload.resultCode == "SUCCESS" then
          EXPECT_NOTIFICATION("OnHashChange")
          return true
        elseif (data.payload.resultCode == "IGNORED") then
          print("\27[32m" .. BUTTON_NAME .. " button has been Subscribed before. resultCode = "..tostring(data.payload.resultCode) .. "\27[0m")
          return true
        else
          print(" \27[36m SubscribeButton response came with wrong resultCode "..tostring(data.payload.resultCode) .. "\27[0m")
          return false
        end
      end)
  end
end

local function UnSubcribeButton(test_case_name)
  Test[test_case_name] = function(self)
    local cid = self[MOBILE_SESSION]:SendRPC("UnsubscribeButton",{buttonName = BUTTON_NAME})
    EXPECT_RESPONSE("UnsubscribeButton")
    :ValidIf(function(_,data)
        if data.payload.resultCode == "SUCCESS" then
          EXPECT_NOTIFICATION("OnHashChange")
          return true
        elseif (data.payload.resultCode == "IGNORED") then
          print("\27[32m" .. BUTTON_NAME .. " button has been UnSubscribed before. resultCode = "..tostring(data.payload.resultCode) .. "\27[0m")
          return true
        else
          print(" \27[36m UnsubscribeButton response came with wrong resultCode "..tostring(data.payload.resultCode) .. "\27[0m")
          return false
        end
      end)
  end
end

-------------------------------------------Preconditions-------------------------------------
common_steps:PreconditionSteps("Precondition", 5)
common_steps:RegisterApplication("RegisterApplication", MOBILE_SESSION, MEDIA_APP, {success = true, resultCode = "SUCCESS"}, {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
common_steps:ActivateApplication("ActivateApplication", MEDIA_APP.appName)

-------------------------------------------Body----------------------------------------------
---------------------------------------------------------------------------------------------
-- Precondition: SubscribleButton(PLAY_PAUSE)
-- 1. MOB-SDL: Send SubscribleButton(PLAY_PAUSE) with valid value
-- Expected result: No OnButtonSubscription is sent to HMI and SDL responds "IGNORED" to app
---------------------------------------------------------------------------------------------
function TestSubscribleButton_IGNORED()
  common_steps:AddNewTestCasesGroup("TC_SubscribleButton_IGNORED" )
  SubcribeButton("Precondition_SubscribleButton_" .. BUTTON_NAME)
  SubcribeButton("SubscribleButton_" .. BUTTON_NAME .. "_IGNORED")
end
TestSubscribleButton_IGNORED()

---------------------------------------------------------------------------------------------
-- Precondition: UnsubscribleButton(PLAY_PAUSE)
-- 1. MOB-SDL: Send UnsubscribleButton(PLAY_PAUSE) with valid value
-- Expected result: No OnButtonSubscription is sent to HMI and SDL responds "IGNORED" to app
---------------------------------------------------------------------------------------------
function TestUnsubscribleButton_IGNORED()
  common_steps:AddNewTestCasesGroup("TC_SubscribleButton_IGNORED")
  UnSubcribeButton("Precondition_UnsubscribleButton_" .. BUTTON_NAME)
  UnSubcribeButton("UnsubscribleButton_" .. BUTTON_NAME .. "_IGNORED")
end
TestUnsubscribleButton_IGNORED()
