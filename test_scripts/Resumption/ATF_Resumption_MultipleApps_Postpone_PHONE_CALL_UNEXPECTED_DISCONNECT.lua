--------------------------------------------------------------------------------
-- This script covers requirement[HMILevel resumption] [Ford-Specific]: The media app (or navi, voice-com) is registered and SDL receives OnEventChanged (PHONE_CALL, isActive=true) notification from HMI
--------------------------------------------------------------------------------
--In case the media app (or navi, voice-com) satisfies the conditions of successful HMILevel resumption (unexpected disconnect, next ignition cycle, short ignition cycle, low voltage) and SDL receives PHONE_CALL.Started notification
-- SDL must:
-- postpone resuming HMILevel of media app till PHONE_CALL.Stopped notification
-- assign <default_HMI_level> to this media app (meaning: by sending OnHMIStatus notification to mobile app per current req-s)
-- resume HMILevel after event ends (SDL receives PHONE_CALL.Stopped notification)
-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')
------------------------------------ Common Variables ---------------------------------------
local MOBILE_SESSION = {"mobileSession1", "mobileSession2", "mobileSession3", "mobileSession4"}
local apps = {}
apps[1] = common_functions:CreateRegisterAppParameters(
  {appID = "1", appName = "NAVIGATION", isMediaApplication = false, appHMIType = {"NAVIGATION"}}
)
apps[2] = common_functions:CreateRegisterAppParameters(
  {appID = "2", appName = "MEDIA", isMediaApplication = true, appHMIType = {"MEDIA"}}
)
apps[3] = common_functions:CreateRegisterAppParameters(
  {appID = "3", appName = "COMMUNICATION", isMediaApplication = false, appHMIType = {"COMMUNICATION"}}
)
apps[4] = common_functions:CreateRegisterAppParameters(
  {appID = "4", appName = "NON_MEDIA", isMediaApplication = false, appHMIType = {"DEFAULT"}}
)
-- Expected hmi status for multiple apps (FULL,LIMITED,LIMITED,BACKGROUND)
local expected_hmi_status_3apps = {
  mobileSession1 = {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"},
  mobileSession2 = {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"},
  mobileSession3 = {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}
}
-- Expected hmi status for multiple apps (FULL,LIMITED,LIMITED,LIMITED)
local expected_hmi_status_4apps = {
  mobileSession1 = {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"},
  mobileSession2 = {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"},
  mobileSession3 = {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}
}
-------------------------------------------Preconditions-------------------------------------
common_steps:BackupFile("Backup Ini file", "smartDeviceLink.ini")
common_steps:SetValuesInIniFile("Update ApplicationResumingTimeout value", "%p?ApplicationResumingTimeout%s? = %s-[%d]-%s-\n", "ApplicationResumingTimeout", 5000)
common_steps:PreconditionSteps("Precondition", 5)

-----------------------------------------------Body------------------------------------------
-- Start Phone Call
-- @param test_case_name: main test name
-- @param mobile_session_name: mobile session
---------------------------------------------------------------------------------------------
function StartPhoneCall(test_case_name)
  Test[test_case_name] = function(self)
    self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", {isActive = true, eventName = "PHONE_CALL"})
  end
end

---------------------------------------------------------------------------------------------
-- Stop Phone Call with delay time
-- @param test_case_name: main test name
-- @param delay_time: the time that Phone Call will be stopped
---------------------------------------------------------------------------------------------
function StopPhoneCallWithDelayTime(test_case_name, delay_time)
  Test[test_case_name] = function(self)
    function to_run()
      self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", {isActive = false, eventName = "PHONE_CALL"})
    end
    RUN_AFTER(to_run,delay_time)
  end
end

---------------------------------------------------------------------------------------------
-- Checking application(s) is resumed unsuccessful if isActive parameter is invalid
-- @param test_case_name: main test name
---------------------------------------------------------------------------------------------
function CheckAppsResumptionUnsuccessWhenIsActiveInvalid(test_case_name)
  local isActiveValue = {
    {isActive= "", eventName="EMERGENCY_EVENT"},
    {isActive= 123, eventName="EMERGENCY_EVENT"},
    {eventName="EMERGENCY_EVENT"}
  }
  local invalid_type ={"IsActiveEmpty", "IsActiveWrongType", "IsActiveMissed"}
  for i=1, #isActiveValue do
    Test[test_case_name .. invalid_type[i]] = function(self)
      common_functions:DelayedExp(2000)
      self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", isActiveValue[i])
      EXPECT_HMICALL("BasicCommunication.ActivateApp"):Times(0)
      for i = 1, #MOBILE_SESSION do
        self[MOBILE_SESSION[i]]:ExpectNotification("OnHMIStatus"):Times(0)
      end
    end
  end
end

---------------------------------------------------------------------------------------------
-- Non Media application will resume without waiting Phone Call end
-- @param test_case_name: main test name
-- @param mobile_session_name: mobile session of non media application
---------------------------------------------------------------------------------------------
function CheckNoneMediaResumeSuccessWithoutPhoneCallEnded(test_case_name, mobile_session_name)
  Test[test_case_name] = function(self)
    EXPECT_HMICALL("BasicCommunication.ActivateApp")
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
      end)
    self[mobile_session_name]:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
  end
end

---------------------------------------------------------------------------------------------
-- Checking application(s) is resumed successful
-- @param test_case_name: main test name
-- @param expected_hmi_status: expected OnHMIStatus of each mobile session
---------------------------------------------------------------------------------------------
local function CheckAppsResumptionSuccessful(test_case_name, expected_hmi_status)
  Test[test_case_name] = function(self)
    local count_limited_apps = 0
    -- Expected SDL sends BasicCommunication.ActivateApp for FULL application
    -- And SDL sends OnHMIStatus mobile applications
    for k,v in pairs(expected_hmi_status) do
      if v.hmiLevel == "FULL" then
        EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Timeout(15000)
        :Do(function(_,data)
            self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
          end)
      else
        count_limited_apps = count_limited_apps + 1
      end
      self[tostring(k)]:ExpectNotification("OnHMIStatus", v)
      :Timeout(15000)
    end
    -- Expected SDL sends BasicCommunication.OnResumeAudioSource for LIMITED applications
    EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource")
    :Times(count_limited_apps)
  end
end

---------------------------------------------------------------------------------------------
-- Checking application(s) is not resumed during time
-- @param test_case_name: main test name
-- @param checking_time: the period time that applications aren't resumed
---------------------------------------------------------------------------------------------
local function CheckAppsAreNotResumedDuringTime(test_case_name, checking_time)
  Test[test_case_name] = function(self)
    common_functions:DelayedExp(checking_time)
    EXPECT_HMICALL("BasicCommunication.ActivateApp"):Times(0)
    EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource"):Times(0)
    for i=1, #MOBILE_SESSION-1 do --except for NON_MEDIA
      self[MOBILE_SESSION[i]]:ExpectNotification("OnHMIStatus"):Times(0)
    end
  end
end

---------------------------------------------------------------------------------------------
-- Requirement summary: Resumption for multiple applications FULL/LIMITED/LIMITED/BACKGROUND)
-- is postponed in case UNEXPECTED_DISCONNECT and PHONE_CALL is active BEFORE applications are connected
-- 1.Preconditions:
-- -- 1.1. Applications (NAVIGATION/COMMUNICATION/MEDIA/NON_MEDIA) are (FULL/LIMITED/LIMITED/BACKGROUND)
-- -- 1.2. Close session
-- 2.Steps:
-- -- 2.1. Start PHONE_CALL
-- -- 2.2. Register applications
-- -- 2.3. With App is NON_MEDIA: Check application is resumed without waiting ended phone call
-- -- 2.4. With Apps aren't NON_MEDIA - Check applications aren't resumed during a period time (10s)
-- -- 2.5. With Apps aren't NON_MEDIA - Check applications aren't resumed when isActive invalid
-- -- 2.6. Stop PHONE_CALL
-- 3.Expected Result: Resumption success when PHONE_CALL ended
---------------------------------------------------------------------------------------------
local function CheckMultipleAppsFullLimitedLimitedBackgroundArePostponedWhenPhoneCallIsStartedBeforeRegisteredApp()
  common_steps:AddNewTestCasesGroup("Multiple apps (Full-Limited-Limited-Background) are postponed" ..
  " in case UNEXPECTED_DISCONNECT and PHONE_CALL is active BEFORE apps are connected")
  local tc_name = "TC_1"
  -- Precondition
  for i = 1, #apps do
    common_steps:AddMobileSession(tc_name .. "_Add_Mobile_Session_" .. tostring(i), _, MOBILE_SESSION[i])
    common_steps:RegisterApplication(tc_name .. "_Register_App_" .. apps[i].appName, MOBILE_SESSION[i], apps[i])
  end
  -- Activate Apps: App["NAVIGATION"]-FULL, App["COMMUNICATION"]-LIMITED, App["MEDIA"]-LIMITED, App["NON_MEDIA"]-BACKGROUND
  for i = #apps, 1, -1 do
    common_steps:ActivateApplication(tc_name .. "_Activate_App_" .. apps[i].appName, apps[i].appName)
  end
  for i = 1, #MOBILE_SESSION do
    common_steps:CloseMobileSession(tc_name .. "_Close_Mobile_Session_" .. tostring(i), MOBILE_SESSION[i])
  end
  -- Body
  StartPhoneCall(tc_name .. "_Start_Phone_Call")
  for i = 1, #apps do
    common_steps:AddMobileSession(tc_name .. "_Add_Mobile_Session_" .. tostring(i), _, MOBILE_SESSION[i])
    common_steps:RegisterApplication(tc_name .. "_Register_App_" .. apps[i].appName, MOBILE_SESSION[i], apps[i])
  end
  CheckAppsAreNotResumedDuringTime(tc_name .. "_Verify_MultipleApps_Are_Not_Resumed_During_Time", 10000)
  CheckAppsResumptionUnsuccessWhenIsActiveInvalid(tc_name .. "_Verify_Resumption_MultipleApps_Unsuccess_When_IsActive_InValid: ")
  StopPhoneCallWithDelayTime(tc_name .. "_Stop_Phone_Call", 1000)
  CheckAppsResumptionSuccessful(tc_name .. "_Verify_Resumption_MultipleApps_Sucess_When_IsActive_Valid", expected_hmi_status_3apps)
  -- Post condition
  for i = 1, #apps do
    common_steps:UnregisterApp(tc_name .. "_Unregister_App_" .. apps[i].appName, apps[i].appName)
  end
end
CheckMultipleAppsFullLimitedLimitedBackgroundArePostponedWhenPhoneCallIsStartedBeforeRegisteredApp()

---------------------------------------------------------------------------------------------
-- Requirement summary: Resumption for multiple applications FULL/LIMITED/LIMITED/BACKGROUND)
-- is postponed in case UNEXPECTED_DISCONNECT and PHONE_CALL is active AFTER applications are connected
-- 1.Preconditions:
-- -- 1.1. Applications (NAVIGATION/COMMUNICATION/MEDIA/NON_MEDIA) are (FULL/LIMITED/LIMITED/BACKGROUND)
-- -- 1.2. Close session
-- 2.Steps:
-- -- 2.1. Register applications
-- -- 2.2. Start PHONE_CALL
-- -- 2.3. With App is NON_MEDIA: Check application is resumed without waiting ended phone call
-- -- 2.4. With Apps aren't NON_MEDIA - Check applications aren't resumed during a period time (10s)
-- -- 2.5. With Apps aren't NON_MEDIA - Check applications aren't resumed when isActive invalid
-- -- 2.6. Stop PHONE_CALL
-- 3.Expected Result: Resumption success when PHONE_CALL ended
---------------------------------------------------------------------------------------------
local function CheckMultipleAppsFullLimitedLimitedBackgroundArePostponedWhenPhoneCallIsStartedAfterRegisteredApp()
  common_steps:AddNewTestCasesGroup("Multiple apps (Full-Limited-Limited-Background) are postponed" ..
  " in case UNEXPECTED_DISCONNECT and PHONE_CALL is active BEFORE apps are connected")
  local tc_name = "TC_2"
  --Precondition
  for i = 1, #apps do
    common_steps:AddMobileSession(tc_name .. "_Add_Mobile_Session_" .. tostring(i), _, MOBILE_SESSION[i])
    common_steps:RegisterApplication(tc_name .. "_Register_App_" .. apps[i].appName, MOBILE_SESSION[i], apps[i])
  end
  -- Activate Apps: App["NAVIGATION"]-FULL, App["COMMUNICATION"]-LIMITED, App["MEDIA"]-LIMITED, App["NON_MEDIA"]-BACKGROUND
  for i = #apps, 1, -1 do
    common_steps:ActivateApplication(tc_name .. "_Activate_App_" .. apps[i].appName, apps[i].appName)
  end
  for i = 1, #MOBILE_SESSION do
    common_steps:CloseMobileSession(tc_name .. "_Close_Mobile_Session_" .. tostring(i), MOBILE_SESSION[i])
  end
  --Body
  for i = 1, #apps do
    common_steps:AddMobileSession(tc_name .. "_Add_Mobile_Session_" .. tostring(i), _, MOBILE_SESSION[i])
    common_steps:RegisterApplication(tc_name .. "_Register_App_" .. apps[i].appName, MOBILE_SESSION[i], apps[i])
  end
  StartPhoneCall(tc_name .. "_Start_Phone_Call")
  CheckAppsAreNotResumedDuringTime(tc_name .. "_Verify_MultipleApps_Are_Not_Resumed_During_Time", 10000)
  CheckAppsResumptionUnsuccessWhenIsActiveInvalid(tc_name .. "_Verify_Resumption_MultipleApps_Unsuccess_When_IsActive_InValid: ")
  StopPhoneCallWithDelayTime(tc_name .. "_Stop_Phone_Call", 1000)
  CheckAppsResumptionSuccessful(tc_name .. "_Verify_Resumption_MultipleApps_Sucess_When_IsActive_Valid", expected_hmi_status_3apps)
  -- Post condition
  for i = 1, #apps do
    common_steps:UnregisterApp(tc_name .. "_Unregister_App_" .. apps[i].appName, apps[i].appName)
  end
end
CheckMultipleAppsFullLimitedLimitedBackgroundArePostponedWhenPhoneCallIsStartedAfterRegisteredApp()
-- Stop and Start SDL again to avoid an ATF issue related to corID
common_steps:IgnitionOff("Ignition_Off")
common_steps:IgnitionOn("Ignition_On")

---------------------------------------------------------------------------------------------
-- Requirement summary: Resumption for multiple applications FULL/LIMITED/LIMITED/LIMITED)
-- is postponed in case UNEXPECTED_DISCONNECT and PHONE_CALL is active BEFORE applications are connected
-- 1.Preconditions:
-- -- 1.1. Applications (NAVIGATION/COMMUNICATION/MEDIA/NON_MEDIA) are (FULL/LIMITED/LIMITED/LIMITED)
-- -- 1.2. Close session
-- 2.Steps:
-- -- 2.1. Start PHONE_CALL
-- -- 2.2. Register applications
-- -- 2.3. With App is NON_MEDIA: Check application is resumed without waiting ended phone call
-- -- 2.4. With Apps aren't NON_MEDIA - Check applications aren't resumed during a period time (10s)
-- -- 2.5. With Apps aren't NON_MEDIA - Check applications aren't resumed when isActive invalid
-- -- 2.6. Stop PHONE_CALL
-- 3.Expected Result: Resumption success when PHONE_CALL ended
---------------------------------------------------------------------------------------------
local function CheckMultipleAppsFullLimitedLimitedLimitedArePostponedWhenPhoneCallIsStartedBeforeRegisteredApp()
  common_steps:AddNewTestCasesGroup("Multiple apps (Full-Limited-Limited-Limited) are postponed" ..
  " in case UNEXPECTED_DISCONNECT and PHONE_CALL is active BEFORE apps are connected")
  local tc_name = "TC_3"
  -- Precondition
  for i = 1, #apps do
    common_steps:AddMobileSession(tc_name .. "_Add_Mobile_Session_" .. tostring(i), _, MOBILE_SESSION[i])
    common_steps:RegisterApplication(tc_name .. "_Register_App_" .. apps[i].appName, MOBILE_SESSION[i], apps[i])
  end
  -- Activate Apps: App["NON_MEDIA"]-FULL, App["MEDIA"]-LIMITED, App["COMMUNICATION"]-LIMITED, App["NAVIGATION"]-LIMITED
  for i = 1, #apps do
    common_steps:ActivateApplication(tc_name .. "_Activate_App_" .. apps[i].appName, apps[i].appName)
  end
  for i = 1, #MOBILE_SESSION do
    common_steps:CloseMobileSession(tc_name .. "_Close_Mobile_Session_" .. tostring(i), MOBILE_SESSION[i])
  end
  -- Body
  StartPhoneCall(tc_name .. "_Start_Phone_Call")
  for i = 1, #apps do
    common_steps:AddMobileSession(tc_name .. "_Add_Mobile_Session_" .. tostring(i), _, MOBILE_SESSION[i])
    common_steps:RegisterApplication(tc_name .. "_Register_App_" .. apps[i].appName, MOBILE_SESSION[i], apps[i])
  end
  CheckNoneMediaResumeSuccessWithoutPhoneCallEnded(tc_name .. "_Verify_Non_Media_Is_Resumed_Without_Phone_Call_Ended", MOBILE_SESSION[4])
  CheckAppsAreNotResumedDuringTime(tc_name .. "_Verify_MultipleApps_Are_Not_Resumed_During_Time", 10000)
  CheckAppsResumptionUnsuccessWhenIsActiveInvalid(tc_name .. "_Verify_Resumption_MultipleApps_Unsuccess_When_IsActive_InValid: ")
  StopPhoneCallWithDelayTime(tc_name .. "_Stop_Phone_Call", 1000)
  CheckAppsResumptionSuccessful(tc_name .. "_Verify_Resumption_MultipleApps_Sucess_When_IsActive_Valid", expected_hmi_status_4apps)
  -- Post condition
  for i = 1, #apps do
    common_steps:UnregisterApp(tc_name .. "_Unregister_App_" .. apps[i].appName, apps[i].appName)
  end
end
CheckMultipleAppsFullLimitedLimitedLimitedArePostponedWhenPhoneCallIsStartedBeforeRegisteredApp()
---------------------------------------------------------------------------------------------
-- Requirement summary: Resumption for multiple applications FULL/LIMITED/LIMITED/LIMITED)
-- is postponed in case UNEXPECTED_DISCONNECT and PhoneCall is active AFTER applications are connected
-- 1.Preconditions:
-- -- 1.1. Applications (NAVIGATION/COMMUNICATION/MEDIA/NON_MEDIA) are (FULL/LIMITED/LIMITED/LIMITED)
-- -- 1.2. Close session
-- 2.Steps:
-- -- 2.1. Register applications
-- -- 2.2. Start PhoneCall
-- -- 2.3. With App is NON_MEDIA: Check application is resumed without waiting ended phone call
-- -- 2.4. With Apps aren't NON_MEDIA - Check applications aren't resumed during a period time (10s)
-- -- 2.5. With Apps aren't NON_MEDIA - Check applications aren't resumed when isActive invalid
-- -- 2.6. Stop PHONE_CALL
-- 3.Expected Result: Resumption success when PhoneCall ended
---------------------------------------------------------------------------------------------
local function CheckMultipleAppsFullLimitedLimitedLimitedArePostponedWhenPhoneCallIsStartedAfterRegisteredApp()
  common_steps:AddNewTestCasesGroup("Multiple apps (Full-Limited-Limited-Limited) are postponed" ..
  " in case UNEXPECTED_DISCONNECT and PhoneCall is active AFTER apps are connected")
  local tc_name = "TC_4"
  --Precondition
  for i = 1, #apps do
    common_steps:AddMobileSession(tc_name .. "_Add_Mobile_Session_" .. tostring(i), _, MOBILE_SESSION[i])
    common_steps:RegisterApplication(tc_name .. "_Register_App_" .. apps[i].appName, MOBILE_SESSION[i], apps[i])
  end
  -- Activate Apps: App["NON_MEDIA"]-FULL, App["MEDIA"]-LIMITED, App["COMMUNICATION"]-LIMITED, App["NAVIGATION"]-LIMITED
  for i = 1, #apps do
    common_steps:ActivateApplication(tc_name .. "_Activate_App_" .. apps[i].appName, apps[i].appName)
  end
  for i = 1, #MOBILE_SESSION do
    common_steps:CloseMobileSession(tc_name .. "_Close_Mobile_Session_" .. tostring(i), MOBILE_SESSION[i])
  end
  --Body
  for i = 1, #apps do
    common_steps:AddMobileSession(tc_name .. "_Add_Mobile_Session_" .. tostring(i), _, MOBILE_SESSION[i])
    common_steps:RegisterApplication(tc_name .. "_Register_App_" .. apps[i].appName, MOBILE_SESSION[i], apps[i])
  end
  StartPhoneCall(tc_name .. "_Start_Phone_Call")
  CheckNoneMediaResumeSuccessWithoutPhoneCallEnded(tc_name .. "_Verify_Non_Media_Is_Resumed_Without_Phone_Call_Ended", MOBILE_SESSION[4])
  CheckAppsAreNotResumedDuringTime(tc_name .. "_Verify_MultipleApps_Are_Not_Resumed_During_Time", 10000)
  CheckAppsResumptionUnsuccessWhenIsActiveInvalid(tc_name .. "_Verify_Resumption_MultipleApps_Unsuccess_When_IsActive_InValid: ")
  StopPhoneCallWithDelayTime(tc_name .. "_Stop_Phone_Call", 1000)
  CheckAppsResumptionSuccessful(tc_name .. "_Verify_Resumption_MultipleApps_Sucess_When_IsActive_Valid", expected_hmi_status_4apps)
  -- Post condition
  for i = 1, #apps do
    common_steps:UnregisterApp(tc_name .. "_Unregister_App_" .. apps[i].appName, apps[i].appName)
  end
end
CheckMultipleAppsFullLimitedLimitedLimitedArePostponedWhenPhoneCallIsStartedAfterRegisteredApp()

-------------------------------------------Postcondition-------------------------------------
common_steps:RestoreIniFile("Restore_Ini_file")
