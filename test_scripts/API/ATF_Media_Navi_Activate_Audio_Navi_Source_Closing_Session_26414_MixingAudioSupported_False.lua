--------------------------------------------------------------------------------
-- This script covers requirement APPLINK-26414 [HMILevel resumption] Navigation app must be resumed to FULL or LIMITED and AUDIBLE in case of active embedded audio source . The reason for closing the app to resumption is closing session
--------------------------------------------------------------------------------
--[[In case
navigation app registers during active embedded audio source (e.g. active radio, CD)
and satisfies all conditions for HMILevel resumption
SDL must:
set AUDIBLE audioStreamingState to this app and send via OnHMIStatus together with resumed HMILevel (FULL or LIMITED)

Information:
1. The value of "MixingAudioSupported" at .ini file can be <any> for this case
2. Embedded audio source should be still active -> expected that HMI will attenuate embedded audio source when navi app starts streaming (SDL sends OnAudioDataStreaming notification to HMI)
3. Req for navi app resumption during active embedded navigation is still actual -> please see APPLINK-18871
]]
-- Case 1: Check Navi app is resumed to FULL Audible when there is activate audio source. Value of MixingAudioSupported is false. Reason off is closing session
-- Case 2: Check Navi app is resumed to LIMITED Audible when there is activate audio source. Value of MixingAudioSupported is false. Reason off is closing session

-- Author: Hoang Quang Nghi
-- ATF version: 2.2

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local common_preconditions = require('user_modules/shared_testcases/commonPreconditions')
local common_functions = require('user_modules/shared_testcases/commonFunctions')
local common_steps = require('user_modules/shared_testcases/commonSteps')
local function_crq_26401 = require('user_modules/commonFunctionsForCRQ26401')
-- Prepare connecttest_resumption.lua
common_preconditions:Connecttest_without_ExitBySDLDisconnect("connecttest_resumption.lua")
Test = require('user_modules/connecttest_resumption')
require('cardinalities')
require('user_modules/AppTypes')

---------------------------------------------------------------------------------------------
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 3

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
common_preconditions:BackupFile("smartDeviceLink.ini")
function_crq_26401:PreconditionSetMixingAudioSupportedValueInIniFile(false)
common_steps:DeleteLogsFileAndPolicyTable()

---------------------------------------------------------------------------------------------
-----------------------------------------------Body------------------------------------------
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
-- Case 1: App is resumed to FULL HMI level in case closing session and MixingAudioSupported = false
---------------------------------------------------------------------------------------------
local test_case_name = "Case_1"
local full_test_case_name = "Case 1: Closing session and create session again, Navi app is resumed to FULL, Audible in case audio source is activate. MixingAudioSupported = false."
-- 1. Print new line to separate new test cases group
common_functions:newTestCasesGroup(full_test_case_name)
-- 2. Change app to Navi app
function_crq_26401:ChangeAppType(test_case_name, {"NAVIGATION"}, false)
-- 3. Restart SDL, HMI and Mobile, register and active app to FULL
function_crq_26401:CloseConnectionConnectMobileActivateApp(test_case_name)
-- 4. Close session
function_crq_26401:CloseSession(test_case_name)
-- 5. Send audio source
function_crq_26401:ActiveEmbeddedSource(test_case_name,"AUDIO_SOURCE",true)
-- 6. Check app is resumed to FULL
function_crq_26401:ResumeApp(test_case_name, "FULL")
-- 7. Start Audio, Video service to check the app become Attenuated and stop to check it resumes to Audible
function_crq_26401:StartAudioServiceAndStreaming(test_case_name)
function_crq_26401:StopAudioStreaming(test_case_name)
function_crq_26401:StartVideoServiceAndStreaming(test_case_name)
function_crq_26401:StopVideoStreaming(test_case_name)

---------------------------------------------------------------------------------------------
-- Case 2: App is resumed to LIMITED HMI level in case closing session and MixingAudioSupported = false
---------------------------------------------------------------------------------------------
local test_case_name = "Case_2"
local full_test_case_name = "Case 2: Closing session and create session again, Navi app is resumed to LIMITED, Audible in case audio source is activate. MixingAudioSupported = false."
-- 1. Print new line to separate new test cases group
common_functions:newTestCasesGroup(full_test_case_name)
-- 2. Change app to Navi app
function_crq_26401:ChangeAppType(test_case_name,{"NAVIGATION"},false)
-- 3. Restart SDL, HMI and Mobile, register and active app to FULL
function_crq_26401:CloseConnectionConnectMobileActivateApp(test_case_name)
-- 4. Bring app to LIMITED
function_crq_26401:ChangeHmiLevelToLimited(test_case_name)
-- 5. Close session
function_crq_26401:CloseSession(test_case_name)
-- 6. Send audio source
function_crq_26401:ActiveEmbeddedSource(test_case_name,"AUDIO_SOURCE",true)
-- 7. Check app is resumed to LIMITED
function_crq_26401:ResumeApp(test_case_name, "LIMITED")
-- 8. Start Audio, Video service to check the app become Attenuated and stop to check it resumes to Audible
function_crq_26401:StartAudioServiceAndStreaming(test_case_name)
function_crq_26401:StopAudioStreaming(test_case_name)
function_crq_26401:StartVideoServiceAndStreaming(test_case_name)
function_crq_26401:StopVideoStreaming(test_case_name)

---------------------------------------------------------------------------------------------
-------------------------------------------Postconditions-------------------------------------
---------------------------------------------------------------------------------------------
function_crq_26401:RestoreFile("smartDeviceLink.ini")

return Test
