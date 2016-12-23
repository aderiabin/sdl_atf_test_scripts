--------------------------------------------------------------------------------
--[[ This script covers requirement APPLINK-26473 and 26503:
[HMILevel resumption] Media app and navi app both must get AUDIBLE streaming state after successful resumption.
[HMI Status] Media app must get ATTENUATED streaming state when navi app starts streaming.
The reason for closing the app to resumption is closing session]]
--------------------------------------------------------------------------------
--[[APPLINK-26473:
In case
media app registers and gets FULL/LIMITED and AUDIBLE
and navigation app registers and satisfies all conditions for HMILevel resumption
SDL must:
resume navi app to appropriate <HMILevel> (according to existing req-s) and AUDIBLE audioStreamingState (by sending OnHMIStatus notification to mobile app)

Information:
1. The value of "MixingAudioSupported" at .ini file can be <any> for this case
2. Embedded audio source should be still active -> expected that HMI will attenuate embedded audio source when navi app starts streaming (SDL sends OnAudioDataStreaming notification to HMI)
3. Req for navi app resumption during active embedded navigation is still actual -> please see APPLINK-18871]]

--[[APPLINK-26503:
In case
media app is running in FULL (or LIMITED) and AUDIBLE at SDL
and navigation app is running in LIMITED (or FULL when no any apps in FULL now) and AUDIBLE on SDL (due to APPLINK-26473)
and navigation app starts streaming
and "MixingAudioSupported" = true at .ini file
SDL must:
send OnHMIStatus (<current_HMILevel>, ATTENUATED) to media app (and return media app to AUDIBLE right after navi app stops streaming)

Information
a. SDL sends OnAudioDataStreaming (please see APPLINK-19957, APPLINK-19958) to HMI when navi app starts/stops audio streaming
]]

-- Case 1: Check Media app is resumed to FULL audible and Navi app to LIMITED audible. Value of MixingAudioSupported is true. Reason off is closing session
-- Case 2: Check Media app is resumed to LIMITED audible and Navi app to FULL audible. Value of MixingAudioSupported is true. Reason off is closing session
-- Case 3: Check Media app is resumed to LIMITED audible and Navi app to LIMITED audible. Value of MixingAudioSupported is true. Reason off is closing session

-- Author: Hoang Quang Nghi
-- ATF version: 2.2

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local common_preconditions = require('user_modules/shared_testcases/commonPreconditions')
local common_functions = require('user_modules/shared_testcases/commonFunctions')
local common_steps = require('user_modules/shared_testcases/commonSteps')
local function_crq_26401 = require('user_modules/commonFunctionsForCRQ26401')
-- prepare connecttest_resumption.lua
common_preconditions:Connecttest_without_ExitBySDLDisconnect("connecttest_resumption.lua")
Test = require('user_modules/connecttest_resumption')
require('cardinalities')
require('user_modules/AppTypes')

---------------------------------------------------------------------------------------------
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.defaultProtocolVersion = 3
---------------------------------------------------------------------------------------------
----------------------------------- Local Common Functions-----------------------------------
---------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Activate the media app. This media app will be FULL and the navi app will become LIMITED
-- @param test_case_name: main test name
-----------------------------------------------------------------------------
function ActivateMediaAppFullNaviAppLimited(test_case_name)
  Test[test_case_name.."ActiveMediaApp"] = function(self)
    local input_appid = self.applications[config.application1.registerAppInterfaceParams.appName]
    --hmi side: sending SDL.ActivateApp request
    local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = input_appid})
    EXPECT_HMIRESPONSE(RequestId)
    :Do(function(_,data)
        if
        data.result.isSDLAllowed ~= true then
          local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
          EXPECT_HMIRESPONSE(RequestId)
          :Do(function(_,data)
              -- hmi side: send request SDL.OnAllowSDLFunctionality
              self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
              -- hmi side: expect BasicCommunication.ActivateApp request
              EXPECT_HMICALL("BasicCommunication.ActivateApp")
              :Do(function(_,data)
                  -- hmi side: sending BasicCommunication.ActivateApp response
                  self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
                end)
              :Times(AnyNumber())
            end) -- end do
        end -- end if
      end) -- end do
    -- mobile side: expect notification FULL for media app and LIMITED for navi app
    EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
    self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  end
end

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
common_preconditions:BackupFile("smartDeviceLink.ini")
-- Set value MixingAudioSupported to true
function_crq_26401:PreconditionSetMixingAudioSupportedValueInIniFile( true)
common_steps:DeleteLogsFileAndPolicyTable()

---------------------------------------------------------------------------------------------
-----------------------------------------------Body------------------------------------------
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
-- Case 1: Check Media app is resumed to FULL audible and Navi app to LIMITED audible. Value of MixingAudioSupported is true. Reason off is closing session
---------------------------------------------------------------------------------------------
local test_case_name = "Case_1"
local full_test_case_name = "Case 1: Closing session and create session again, Media app is resumed to FULL, Navi app is resumed to LIMITED. MixingAudioSupported = true."

-- 1. Print new line to separate new test cases group
common_functions:newTestCasesGroup(full_test_case_name)
-- 2. Change app to Media app in config file
function_crq_26401:ChangeAppType(test_case_name,{"MEDIA"},true)
-- 3. Register a media app
function_crq_26401:CloseConnectionConnectMobile(test_case_name)
-- 4. Active a navi app. HMIlevel of this app will be FULL
function_crq_26401:AddSession2(test_case_name)
function_crq_26401:RegisterTheSecondNaviApp(test_case_name)
function_crq_26401:ActivateTheSecondNaviApp(test_case_name)
-- 5. Active a media app. HMIlevel of this app will become FULL. HMIlevel of navi app will become LIMITED
ActivateMediaAppFullNaviAppLimited(test_case_name)
-- 6. Close sessions of 2 apps
function_crq_26401:CloseSession(test_case_name)
function_crq_26401:CloseSession2(test_case_name)
-- 7. Check media app is resumed to FULL
function_crq_26401:ResumeMediaApp("FULL")
-- 8. Check navi app is resumed to LIMITED
function_crq_26401:ResumeNaviApp("LIMITED")
-- 9. Check media app get Attenuated when navi app starts streaming. When navi app stops streaming, the media become Audible. These steps covers APPLINK-26503.
function_crq_26401:StartAudioServiceAndStreaming(test_case_name,2,"FULL")
function_crq_26401:StopAudioStreaming(test_case_name,2,"FULL")
function_crq_26401:StartVideoServiceAndStreaming(test_case_name,2,"FULL")
function_crq_26401:StopVideoStreaming(test_case_name,2,"FULL")

---------------------------------------------------------------------------------------------
-- Case 2: Check Media app is resumed to LIMITED audible and Navi app to FULL audible. Value of MixingAudioSupported is true. Reason off is closing session
---------------------------------------------------------------------------------------------
local test_case_name = "Case_2"
local full_test_case_name = "Case 2: Closing session and create session again, Media app is resumed to LIMITED, Navi app is resumed to FULL. MixingAudioSupported = true."

-- 1. Print new line to separate new test cases group
common_functions:newTestCasesGroup(full_test_case_name)
-- 2. Change app to Media app in config file
function_crq_26401:ChangeAppType(test_case_name,{"MEDIA"},true)
-- 3. Active a media app. HMIlevel of this app will be FULL
function_crq_26401:CloseConnectionConnectMobileActivateApp(test_case_name)
-- 4. Active a navi app. HMIlevel of this app will be FULL. HMIlevel of media app will be LIMITED
function_crq_26401:AddSession2(test_case_name)
function_crq_26401:RegisterTheSecondNaviApp(test_case_name)
function_crq_26401:ActivateTheSecondNaviApp(test_case_name)
-- 5. Close sessions of 2 apps
function_crq_26401:CloseSession(test_case_name)
function_crq_26401:CloseSession2(test_case_name)
-- 6. Check media app is resumed to LIMITED
function_crq_26401:ResumeMediaApp("LIMITED")
-- 7. Check navi app is resumed to FULL
function_crq_26401:ResumeNaviApp("FULL")
-- 8. Check media app get Attenuated when navi app starts streaming. When navi app stops streaming, the media become Audible. These steps covers APPLINK-26503.
function_crq_26401:StartAudioServiceAndStreaming(test_case_name,2,"LIMITED")
function_crq_26401:StopAudioStreaming(test_case_name,2,"LIMITED")
function_crq_26401:StartVideoServiceAndStreaming(test_case_name,2,"LIMITED")
function_crq_26401:StopVideoStreaming(test_case_name,2,"LIMITED")

---------------------------------------------------------------------------------------------
-- Case 3: Check Media app is resumed to LIMITED audible and Navi app to LIMITED audible. Value of MixingAudioSupported is true. Reason off is closing session
---------------------------------------------------------------------------------------------
local test_case_name = "Case_3"
local full_test_case_name = "Case 3: Closing session and create session again, Media app is resumed to LIMITED, Navi app is resumed to LIMITED. MixingAudioSupported = true."

-- 1. Print new line to separate new test cases group
common_functions:newTestCasesGroup(full_test_case_name)
-- 2. Change app to Media app in config file
function_crq_26401:ChangeAppType(test_case_name, {"MEDIA"}, true)
-- 3. Active a media app. HMIlevel of this app will be FULL
function_crq_26401:CloseConnectionConnectMobileActivateApp(test_case_name)
-- 4. Active a navi app. HMIlevel of this app will be FULL.
function_crq_26401:AddSession2(test_case_name)
function_crq_26401:RegisterTheSecondNaviApp(test_case_name)
function_crq_26401:ActivateTheSecondNaviApp(test_case_name)
-- 5. Bring the navi app to LIMITED
function_crq_26401:ChangeHmiLevelToLimited2(test_case_name)
-- 6. Close sessions of 2 apps
function_crq_26401:CloseSession(test_case_name)
function_crq_26401:CloseSession2(test_case_name)
-- 7. Check media app is resumed to LIMITED
function_crq_26401:ResumeMediaApp("LIMITED")
-- 8. Check navi app is resumed to LIMITED
function_crq_26401:ResumeNaviApp("LIMITED")
-- 9. Check media app get Attenuated when navi app starts streaming. When navi app stops streaming, the media become Audible. These steps covers APPLINK-26503.
function_crq_26401:StartAudioServiceAndStreaming(test_case_name,2,"LIMITED")
function_crq_26401:StopAudioStreaming(test_case_name,2,"LIMITED")
function_crq_26401:StartVideoServiceAndStreaming(test_case_name,2,"LIMITED")
function_crq_26401:StopVideoStreaming(test_case_name,2,"LIMITED")

---------------------------------------------------------------------------------------------
-------------------------------------------Postconditions-------------------------------------
---------------------------------------------------------------------------------------------
function_crq_26401:RestoreFile("smartDeviceLink.ini")

return Test
