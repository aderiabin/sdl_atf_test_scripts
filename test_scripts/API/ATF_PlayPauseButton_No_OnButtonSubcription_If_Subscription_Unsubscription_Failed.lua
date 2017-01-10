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
local MEDIA_APP = config.application1.registerAppInterfaceParams
MEDIA_APP.appName = "MEDIA"
MEDIA_APP.isMediaApplication = true
MEDIA_APP.appHMIType = {"MEDIA"}
MEDIA_APP.appID = "1"
local MOBILE_SESSION = "mobileSession"

-------------------------------------------Local Functions-----------------------------------
local function SubscribeButtonSuccess(test_case_name)
  Test[test_case_name] = function(self)
    local CorIdSubscribeButton = self.mobileSession:SendRPC("SubscribeButton",
      {
        buttonName = "PLAY_PAUSE"
      })
    EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription")
    :Times(1)
    EXPECT_RESPONSE(CorIdSubscribeButton, { success = true, resultCode = "SUCCESS"})
  end
end

local function SubscribeButtonIgnored(test_case_name)
  Test[test_case_name] = function(self)
    local CorIdSubscribeButton = self.mobileSession:SendRPC("SubscribeButton",
      {
        buttonName = "PLAY_PAUSE"
      })
    EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription")
    :Times(0)
    EXPECT_RESPONSE(CorIdSubscribeButton, { success = false, resultCode = "IGNORED"})
  end
end

local function UnsubscribeButtonSuccess(test_case_name)
  Test[test_case_name] = function(self)
    local CorIdUnsubscribeButton = self.mobileSession:SendRPC("UnsubscribeButton",
      {
        buttonName = "PLAY_PAUSE"
      })
    EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription")
    :Times(1)
    EXPECT_RESPONSE(CorIdUnsubscribeButton, { success = true, resultCode = "SUCCESS"})
  end
end

local function UnsubscribeButtonIgnored(test_case_name)
  Test[test_case_name] = function(self)
    local CorIdUnsubscribeButton = self.mobileSession:SendRPC("UnsubscribeButton",
      {
        buttonName = "PLAY_PAUSE"
      })
    EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription")
    :Times(0)
    EXPECT_RESPONSE(CorIdUnsubscribeButton, { success = false, resultCode = "IGNORED"})
  end
end

-------------------------------------------Preconditions-------------------------------------
common_steps:PreconditionSteps("Precondition", 5)
common_steps:RegisterApplication("RegisterApplication", MOBILE_SESSION, MEDIA_APP,
  {success = true, resultCode = "SUCCESS"},
  {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}
)
common_steps:ActivateApplication("ActivateApplication", MEDIA_APP.appName)

-------------------------------------------Body----------------------------------------------
-- Precondition: SubscribleButton(PLAY_PAUSE)
-- 1. MOB-SDL: Send SubscribleButton(PLAY_PAUSE) with valid value
-- Expected result: No OnButtonSubscription is sent to HMI and SDL responds "IGNORED" to app
-- Postcondition: UnsubscribeButton(PLAY_PAUSE)
---------------------------------------------------------------------------------------------
function TestSubscribleButton_IGNORED()
  common_steps:AddNewTestCasesGroup("TC_SubscribleButton_IGNORED" )
  SubscribeButtonSuccess("Precondition_SubscribleButton_PLAY_PAUSE_Success")
  SubscribeButtonIgnored("Verify_SubscribleButton_PLAY_PAUSE_Ignored")
  UnsubscribeButtonSuccess("Postcondition_UnsubscribleButton_PLAY_PAUSE_Success")
end
TestSubscribleButton_IGNORED()

---------------------------------------------------------------------------------------------
-- 1. MOB-SDL: Send UnsubscribleButton(PLAY_PAUSE) with valid value
-- Expected result: No OnButtonSubscription is sent to HMI and SDL responds "IGNORED" to app
---------------------------------------------------------------------------------------------
function TestUnsubscribleButton_IGNORED()
  common_steps:AddNewTestCasesGroup("TC_UnsubscribleButton_IGNORED")
  UnsubscribeButtonIgnored("Verify_UnsubscribleButton_PLAY_PAUSE_Ignored")
end
TestUnsubscribleButton_IGNORED()

----------------------------------------Postcondition----------------------------------------
common_steps:UnregisterApp("Postcondition_UnregisterApp", MEDIA_APP.appName)
common_steps:StopSDL("Postcondition_StopSDL")
