--------------------------------------------------------------------------------
-- This script covers requirement[HMILevel resumption] [Ford-Specific]: Media app (navi, voice-com) is registered during active VR session
--In case
-- the media app (or navi, voice-com) satisfies the conditions of successful HMILevel resumption (unexpected disconnect, next ignition cycle, short ignition cycle, low voltage)
-- and SDL receives VR.Started notification
-- SDL must:
-- postpone resuming HMILevel of media app till VR.Stopped notification
-- assign <default_HMI_level> to this media app (meaning: by sending OnHMIStatus notification to mobile app per current req-s)
-- resume HMILevel after event ends (SDL receives VR.Stopped notification)
-------------------------------------Required Shared Libraries-------------------------------
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
  mobileSession3 = {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"},
  mobileSession4 = {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"}
}

-------------------------------------------Preconditions-------------------------------------
common_steps:BackupFile("Backup Ini file", "smartDeviceLink.ini")
common_steps:SetValuesInIniFile("Update ApplicationResumingTimeout value", "%p?ApplicationResumingTimeout%s? = %s-[%d]-%s-\n", "ApplicationResumingTimeout", 8000)
common_steps:PreconditionSteps("Precondition", 5)

-----------------------------------------------Body------------------------------------------
-- Start VR
-- @param test_case_name: main test name
---------------------------------------------------------------------------------------------
local function StartVR(test_case_name)
  Test[test_case_name] = function(self)
    self.hmiConnection:SendNotification("VR.Started", {})
  end
end

---------------------------------------------------------------------------------------------
-- Stop VR with delay time
-- @param test_case_name: main test name
-- @param delay_time: the time that VR will be stopped
---------------------------------------------------------------------------------------------
local function StopVRWithDelayTime(test_case_name, delay_time)
  Test[test_case_name] = function(self)
    function to_run()
      self.hmiConnection:SendNotification("VR.Stopped", {})
    end
    RUN_AFTER(to_run,delay_time)
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
    for i=1, #MOBILE_SESSION do
      self[MOBILE_SESSION[i]]:ExpectNotification("OnHMIStatus"):Times(0)
    end
  end
end

---------------------------------------------------------------------------------------------
-- Requirement summary: Resumption for multiple applications FULL/LIMITED/LIMITED/BACKGROUND)
-- is postponed in case IGNITION_OFF and VR is active BEFORE applications are connected
-- 1.Preconditions:
-- -- 1.1. Applications (NAVIGATION/COMMUNICATION/MEDIA/NON_MEDIA) are (FULL/LIMITED/LIMITED/BACKGROUND)
-- -- 1.2. Ignition Off
-- -- 1.3. Ignition On
-- 2.Steps:
-- -- 2.1. Start VR
-- -- 2.2. Register applications
-- -- 2.3. Check applications are not resumed in during time
-- -- 2.4. Stop VR
-- 3.Expected Result: Resumption success when VR ended
---------------------------------------------------------------------------------------------
local function CheckMultipleAppsFullLimitedLimitedBackgroundArePostponedWhenVRIsStartedBeforeRegisteredApp()
  common_steps:AddNewTestCasesGroup("Multiple apps (Full-Limited-Limited-Background) are postponed in case IGNITION_OFF and VR is active BEFORE apps are connected")
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
  common_steps:IgnitionOff(tc_name .. "_Ignition_Off")
  common_steps:IgnitionOn(tc_name .. "_Ignition_On")
  -- Body
  StartVR(tc_name .. "_Start_VR")
  for i=1, #apps do
    common_steps:AddMobileSession(tc_name .. "_Add_Mobile_Session_" .. tostring(i), _, MOBILE_SESSION[i])
    common_steps:RegisterApplication(tc_name .. "_Register_App_" .. apps[i].appName, MOBILE_SESSION[i], apps[i])
  end
  CheckAppsAreNotResumedDuringTime(tc_name .. "_Verify_MultipleApps_Are_Not_Resumed_During_Time", 10000)
  StopVRWithDelayTime(tc_name .. "_Stop_VR", 1000)
  CheckAppsResumptionSuccessful(tc_name .. "_Verify_Resumption_MultipleApps_Sucess_When_IsActive_Valid", expected_hmi_status_3apps)
  -- Post condition
  for i = 1, #apps do
    common_steps:UnregisterApp(tc_name .. "_Unregister_App_" .. apps[i].appName, apps[i].appName)
  end
end
CheckMultipleAppsFullLimitedLimitedBackgroundArePostponedWhenVRIsStartedBeforeRegisteredApp()

---------------------------------------------------------------------------------------------
-- Requirement summary: Resumption for multiple applications FULL/LIMITED/LIMITED/BACKGROUND)
-- is postponed in case IGNITION_OFF and VR is active AFTER applications are connected
-- 1.Preconditions:
-- -- 1.1. Applications (NAVIGATION/COMMUNICATION/MEDIA/NON_MEDIA) are (FULL/LIMITED/LIMITED/BACKGROUND)
-- -- 1.2. Ignition Off
-- -- 1.3. Ignition On
-- 2.Steps:
-- -- 2.1. Register applications
-- -- 2.2. Start VR
-- -- 2.3. Check applications are not resumed in during time
-- -- 2.4. Stop VR
-- 3.Expected Result: Resumption success when VR ended
---------------------------------------------------------------------------------------------
local function CheckMultipleAppsFullLimitedLimitedBackgroundArePostponedWhenVRIsStartedAfterRegisteredApp()
  common_steps:AddNewTestCasesGroup("Multiple apps (Full-Limited-Limited-Background) are postponed in case IGNITION_OFF and VR is active BEFORE apps are connected")
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
  common_steps:IgnitionOff(tc_name .. "_Ignition_Off")
  common_steps:IgnitionOn(tc_name .. "_Ignition_On")
  --Body
  for i=1, #apps do
    common_steps:AddMobileSession(tc_name .. "_Add_Mobile_Session_" .. tostring(i), _, MOBILE_SESSION[i])
    common_steps:RegisterApplication(tc_name .. "_Register_App_" .. apps[i].appName, MOBILE_SESSION[i], apps[i])
  end
  StartVR(tc_name .. "_Start_VR")
  CheckAppsAreNotResumedDuringTime(tc_name .. "_Verify_MultipleApps_Are_Not_Resumed_During_Time", 10000)
  StopVRWithDelayTime(tc_name .. "_Stop_VR", 1000)
  CheckAppsResumptionSuccessful(tc_name .. "_Verify_Resumption_MultipleApps_Sucess_When_IsActive_Valid", expected_hmi_status_3apps)
  -- Post condition
  for i = 1, #apps do
    common_steps:UnregisterApp(tc_name .. "_Unregister_App_" .. apps[i].appName, apps[i].appName)
  end
end
CheckMultipleAppsFullLimitedLimitedBackgroundArePostponedWhenVRIsStartedAfterRegisteredApp()

---------------------------------------------------------------------------------------------
-- Requirement summary: Resumption for multiple applications FULL/LIMITED/LIMITED/LIMITED)
-- is postponed in case IGNITION_OFF and VR is active BEFORE applications are connected
-- 1.Preconditions:
-- -- 1.1. Applications (NAVIGATION/COMMUNICATION/MEDIA/NON_MEDIA) are (FULL/LIMITED/LIMITED/LIMITED)
-- -- 1.2. Ignition Off
-- -- 1.3. Ignition On
-- 2.Steps:
-- -- 2.1. Start VR
-- -- 2.2. Register applications
-- -- 2.3. Check applications are not resumed in during time
-- -- 2.4. Stop VR
-- 3.Expected Result: Resumption success when VR ended
---------------------------------------------------------------------------------------------
local function CheckMultipleAppsFullLimitedLimitedLimitedArePostponedWhenVRIsStartedBeforeRegisteredApp()
  common_steps:AddNewTestCasesGroup("Multiple apps (Full-Limited-Limited-Limited) are postponed in case IGNITION_OFF and VR is active BEFORE apps are connected")
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
  common_steps:IgnitionOff(tc_name .. "_Ignition_Off")
  common_steps:IgnitionOn(tc_name .. "_Ignition_On")
  -- Body
  StartVR(tc_name .. "_Start_VR")
  for i=1, #apps do
    common_steps:AddMobileSession(tc_name .. "_Add_Mobile_Session_" .. tostring(i), _, MOBILE_SESSION[i])
    common_steps:RegisterApplication(tc_name .. "_Register_App_" .. apps[i].appName, MOBILE_SESSION[i], apps[i])
  end
  CheckAppsAreNotResumedDuringTime(tc_name .. "_Verify_MultipleApps_Are_Not_Resumed_During_Time", 10000)
  StopVRWithDelayTime(tc_name .. "_Stop_VR", 1000)
  CheckAppsResumptionSuccessful(tc_name .. "_Verify_Resumption_MultipleApps_Sucess_When_IsActive_Valid", expected_hmi_status_4apps)
  -- Post condition
  for i = 1, #apps do
    common_steps:UnregisterApp(tc_name .. "_Unregister_App_" .. apps[i].appName, apps[i].appName)
  end
end
CheckMultipleAppsFullLimitedLimitedLimitedArePostponedWhenVRIsStartedBeforeRegisteredApp()

---------------------------------------------------------------------------------------------
-- Requirement summary: Resumption for multiple applications FULL/LIMITED/LIMITED/LIMITED)
-- is postponed in case IGNITION_OFF and VR is active AFTER applications are connected
-- 1.Preconditions:
-- -- 1.1. Applications (NAVIGATION/COMMUNICATION/MEDIA/NON_MEDIA) are (FULL/LIMITED/LIMITED/LIMITED)
-- -- 1.2. Ignition Off
-- -- 1.3. Ignition On
-- 2.Steps:
-- -- 2.1. Register applications
-- -- 2.2. Start VR
-- -- 2.3. Check applications are not resumed in during time
-- -- 2.4. Stop VR
-- 3.Expected Result: Resumption success when VR ended
---------------------------------------------------------------------------------------------
local function CheckMultipleAppsFullLimitedLimitedLimitedArePostponedWhenVRIsStartedAfterRegisteredApp()
  common_steps:AddNewTestCasesGroup("Multiple apps (Full-Limited-Limited-Limited) are postponed in case IGNITION_OFF and VR is active AFTER apps are connected")
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
  common_steps:IgnitionOff(tc_name .. "_Ignition_Off")
  common_steps:IgnitionOn(tc_name .. "_Ignition_On")
  --Body
  for i=1, #apps do
    common_steps:AddMobileSession(tc_name .. "_Add_Mobile_Session_" .. tostring(i), _, MOBILE_SESSION[i])
    common_steps:RegisterApplication(tc_name .. "_Register_App_" .. apps[i].appName, MOBILE_SESSION[i], apps[i])
  end
  StartVR(tc_name .. "_Start_VR")
  CheckAppsAreNotResumedDuringTime(tc_name .. "_Verify_MultipleApps_Are_Not_Resumed_During_Time", 10000)
  StopVRWithDelayTime(tc_name .. "_Stop_VR", 1000)
  CheckAppsResumptionSuccessful(tc_name .. "_Verify_Resumption_MultipleApps_Sucess_When_IsActive_Valid", expected_hmi_status_4apps)
  -- Post condition
  for i = 1, #apps do
    common_steps:UnregisterApp(tc_name .. "_Unregister_App_" .. apps[i].appName, apps[i].appName)
  end
end
CheckMultipleAppsFullLimitedLimitedLimitedArePostponedWhenVRIsStartedAfterRegisteredApp()

-------------------------------------------Postcondition-------------------------------------
common_steps:StopSDL("StopSDL")
common_steps:RestoreIniFile("Restore_Ini_file")
