-----------------Precondition: Create connecttest for adding PLAY_PAUSE button---------------
function Connecttest_Adding_PlayPause_Button()
  local FileName = "connecttest_playpause.lua"		
  os.execute(  'cp ./modules/connecttest.lua  ./user_modules/'  .. tostring(FileName))		
  f = assert(io.open('./user_modules/'  .. tostring(FileName), "r"))
  fileContent = f:read("*all")
  f:close()
  local pattern1 = "button_capability%s-%(%s-\"PRESET_0\"%s-[%w%s%{%}.,\"]-%),"                    		
  local pattern1Result = fileContent:match(pattern1)
  local StringToReplace = 'button_capability("PRESET_0"),' .. "\n " .. 'button_capability("PLAY_PAUSE"),'	
  if pattern1Result == nil then 
    print(" \27[31m button_capability function is not found in /user_modules/" .. tostring(FileName) .. " \27[0m ")
  else	
    fileContent  =  string.gsub(fileContent, pattern1, StringToReplace)
  end
  f = assert(io.open('./user_modules/' .. tostring(FileName), "w+"))
  f:write(fileContent)
  f:close()
end
Connecttest_Adding_PlayPause_Button()

-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')
Test = require('user_modules/connecttest_playpause')
-- Remove default precondition from connecttest_playpause.lua
common_functions:RemoveTest("RunSDL", Test)
common_functions:RemoveTest("InitHMI", Test)
common_functions:RemoveTest("InitHMI_onReady", Test)
common_functions:RemoveTest("ConnectMobile", Test)
common_functions:RemoveTest("StartSession", Test)
------------------------------------ Common Variables ---------------------------------------
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
    EXPECT_NOTIFICATION("OnHashChange")
  end
end

local function UnSubcribeButton(test_case_name, unsubscribe_param, expect_hmi_notification, expect_response)
  Test[test_case_name] = function(self)
    unsubscribe_param = unsubscribe_param or {buttonName = BUTTON_NAME}
    local cid = self[MOBILE_SESSION]:SendRPC("UnsubscribeButton",unsubscribe_param)
    expect_hmi_notification = expect_hmi_notification or {appID = self.applications[MEDIA_APP.appName], isSubscribed = false, name = BUTTON_NAME}
    EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", expect_hmi_notification)
    expect_response = expect_response or {success = true, resultCode = "SUCCESS"}
    EXPECT_RESPONSE(cid, expect_response)
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

----------------------------------------Postcondition----------------------------------------
common_steps:UnregisterApp("Postcondition_UnregisterApp", MEDIA_APP.appName)
common_steps:StopSDL("Postcondition_StopSDL")