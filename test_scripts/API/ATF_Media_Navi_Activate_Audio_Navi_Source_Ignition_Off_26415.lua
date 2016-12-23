--------------------------------------------------------------------------------
-- This script covers requirement APPLINK-26415 [HMILevel resumption] Media app must get AUDIBLE if it's successfully resuming during active embedded navigation. Resumption in case IGNITION_OFF
--------------------------------------------------------------------------------
--[[In case
media app registers during active embedded navigation
and satisfies all conditions for HMILevel resumption
SDL must:
set AUDIBLE audioStreamingState to this media app and send via OnHMIStatus together with resumed HMILevel (FULL or LIMITED)

Information:
1. The value of "MixingAudioSupported"=true at .ini file for this case
2. Embedded navigation should be still active -> SDL must attenuate media app when embedded navigation starts streaming (per APPLINK-24164)
3. Req for media app resumption during active embedded audio source should be still actual -> please see APPLINK-18866
]]

-- Case 1: Check Media app is resumed to FULL Audible when there is activate navigation source. Value of MixingAudioSupported is true. Reason off is IGNITION_OFF
-- Case 2: Check Media app is resumed to LIMITED Audible when there is activate navigation source. Value of MixingAudioSupported is true. Reason off is IGNITION_OFF

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
config.defaultProtocolVersion = 2

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
common_preconditions:BackupFile("smartDeviceLink.ini")
common_steps:DeleteLogsFileAndPolicyTable()
common_steps:DeletePolicyTable()

---------------------------------------------------------------------------------------------
-----------------------------------------------Body------------------------------------------
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
-- Case 1: App is resumed to FULL Audible in case IGNITION_OFF and MixingAudioSupported = true
---------------------------------------------------------------------------------------------
local test_case_name = "Case_1"
local full_test_case_name = "Case 1: IGNITION_OFF, IGNITION_ON, Media app is resumed to FULL, Audible in case navi source is activate. MixingAudioSupported = true."
-- Print new line to separate new test cases group
common_functions:newTestCasesGroup(full_test_case_name)
-- 1. Set value MixingAudioSupported to true
function_crq_26401:SetMixingAudioSupportedValueInIniFile(test_case_name, true)
-- 2. Change app to Media app
function_crq_26401:ChangeAppType(test_case_name,{"MEDIA"},true)
-- 3. Active a new app to FULL
function_crq_26401:RestartSdlInitHmiConnectMobileActivateApp(test_case_name)
-- 4. Close app by IGNITION_OFF
function_crq_26401:IgnitionOff(test_case_name)
-- 5. Start SDL again
function_crq_26401:StopStartSdlInitHmiConnectMobile(test_case_name)
-- 6. Send navi source
function_crq_26401:ActiveEmbeddedSource(test_case_name,"EMBEDDED_NAVI",true)
-- 7. Check app is resumed to FULL
function_crq_26401:ResumeApp(test_case_name, "FULL")

---------------------------------------------------------------------------------------------
-- Case 2: App is resumed to LIMITED Audible in case IGNITION_OFF and MixingAudioSupported = true
---------------------------------------------------------------------------------------------
local test_case_name = "Case_2"
local full_test_case_name = "Case 2: IGNITION_OFF, IGNITION_ON, Media app is resumed to LIMITED, Audible in case navi source is activate. MixingAudioSupported = true."
-- Print new line to separate new test cases group
common_functions:newTestCasesGroup(full_test_case_name)
-- 1. Set value MixingAudioSupported to true
function_crq_26401:SetMixingAudioSupportedValueInIniFile(test_case_name, true)
-- 2. Change app to Media app
function_crq_26401:ChangeAppType(test_case_name,{"MEDIA"},true)
-- 3. Active a new app to FULL
function_crq_26401:RestartSdlInitHmiConnectMobileActivateApp(test_case_name)
-- 4. Bring app to LIMITED
function_crq_26401:ChangeHmiLevelToLimited(test_case_name)
-- 5. Close app by IGNITION_OFF
function_crq_26401:IgnitionOff(test_case_name)
-- 6. Start SDL again
function_crq_26401:StopStartSdlInitHmiConnectMobile(test_case_name)
-- 7. Send navi source
function_crq_26401:ActiveEmbeddedSource(test_case_name,"EMBEDDED_NAVI",true)
-- 8. Check app is resumed to LIMITED
function_crq_26401:ResumeApp(test_case_name, "LIMITED")

---------------------------------------------------------------------------------------------
-------------------------------------------Postconditions-------------------------------------
---------------------------------------------------------------------------------------------
function_crq_26401:RestoreFile("smartDeviceLink.ini")

return Test
