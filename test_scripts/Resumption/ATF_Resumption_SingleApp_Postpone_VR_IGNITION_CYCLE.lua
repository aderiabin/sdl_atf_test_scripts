--------------------------------------------------------------------------------
-- This script covers requirement[HMILevel resumption] [Ford-Specific]: Media app (navi, voice-com) is registered during active VR session
--------------------------------------------------------------------------------
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
local tc_number = 1
local delay_time = 10000
local mobile_session_name = "mobileSession"
local apps = {}
apps[1] = common_functions:CreateRegisterAppParameters(
  {appID = "1", appName = "NAVIGATION", isMediaApplication = false, appHMIType = {"NAVIGATION"}}
)
apps[2] = common_functions:CreateRegisterAppParameters(
  {appID = "2", appName = "COMMUNICATION", isMediaApplication = false, appHMIType = {"COMMUNICATION"}}
)
apps[3] = common_functions:CreateRegisterAppParameters(
  {appID = "3", appName = "MEDIA", isMediaApplication = true, appHMIType = {"MEDIA"}}
)
apps[4] = common_functions:CreateRegisterAppParameters(
  {appID = "4", appName = "NON_MEDIA", isMediaApplication = false, appHMIType = {"DEFAULT"}}
)

--------------------------------------Preconditions------------------------------------------
common_steps:BackupFile("Backup Ini file", "smartDeviceLink.ini")
common_steps:SetValuesInIniFile("Update ApplicationResumingTimeout value", "%p?ApplicationResumingTimeout%s? = %s-[%d]-%s-\n", "ApplicationResumingTimeout", 5000)
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
    RUN_AFTER(to_run, delay_time)
  end
end

---------------------------------------------------------------------------------------------
-- Checking application(s) is resumed successful
-- @param test_case_name: main test name
-- @param expected_hmi_status: expected OnHMIStatus of each mobile session
---------------------------------------------------------------------------------------------
local function CheckAppsResumption(test_case_name, expected_hmi_status)
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
-- @param expected_hmi_status: expected OnHMIStatus of each mobile session
---------------------------------------------------------------------------------------------
local function CheckAppIsNotResumedDuringTime(test_case_name, app_name, checking_time)
  Test[test_case_name] = function(self)
    common_functions:DelayedExp(checking_time)
    EXPECT_HMICALL("BasicCommunication.ActivateApp"):Times(0)
    EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource"):Times(0)
    local mobile_conenction_name, mobile_session_name = common_functions:GetMobileConnectionNameAndSessionName(app_name, self)
    self[mobile_session_name]:ExpectNotification("OnHMIStatus"):Times(0)
  end
end

---------------------------------------------------------------------------------------------
-- Checking application(s) is not resumed during a period time
-- @param test_case_name: main test name
-- @param app_name: application's name
-- @param checking_time: the period time that applications aren't resumed
---------------------------------------------------------------------------------------------
local function CheckAppIsNotResumedDuringTime(test_case_name, app_name, checking_time)
  Test[test_case_name] = function(self)
    common_functions:DelayedExp(checking_time)
    EXPECT_HMICALL("BasicCommunication.ActivateApp"):Times(0)
    EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource"):Times(0)
    local mobile_conenction_name, mobile_session_name = common_functions:GetMobileConnectionNameAndSessionName(app_name, self)
    self[mobile_session_name]:ExpectNotification("OnHMIStatus"):Times(0)
  end
end

---------------------------------------------------------------------------------------------
-- Requirement summary: Resumption for single application (hmiLevel=FULL) is postponed
-- in case IGNITION_CYCLE and VR is active BEFORE application is connected
-- 1.Preconditions:
-- -- 1.1. Application (NAVIGATION/COMMUNICATION/MEDIA/NON_MEDIA) is FULL
-- -- 1.2. Ignition Off
-- -- 1.3. Ignition On
-- 2.Steps:
-- -- 2.1. Start VR
-- -- 2.2. Register application
-- -- 2.3. Check application is not resumed during a period time (10s)
-- -- 2.4. Stop VR
-- 3.Expected Result: Resumption success when VR ended
---------------------------------------------------------------------------------------------
local function CheckAppFullIsPostponedWhenVRIsStartedBeforeRegisteredApp()
  for i=1, #apps do
    test_case_name = "TC_" .. tostring(tc_number)
    common_steps:AddNewTestCasesGroup("TC_" .. tostring(tc_number) .. "-HMILevel FULL: resumption for \"" .. apps[i].appName .. "\" app is postponed in case IGNITION_CYCLE and VR is active BEFORE application is connected")
    -- Preconditions
    common_steps:RegisterApplication(test_case_name .. "_Register_App", mobile_session_name, apps[i])
    common_steps:ActivateApplication(test_case_name .. "_Activate_App", apps[i].appName)
    common_steps:IgnitionOff(test_case_name .. "_Ignition_Off")
    common_steps:IgnitionOn(test_case_name .. "_Ignition_On")
    -- Body
    StartVR(test_case_name .. "_Start_VR")
    common_steps:AddMobileSession(test_case_name .. "_Add_Mobile_Session", _, mobile_session_name)
    common_steps:RegisterApplication(test_case_name .. "_Register_App", mobile_session_name, apps[i])
    CheckAppIsNotResumedDuringTime(test_case_name .. "_Verify_App_Is_Not_Resume_During_Time", apps[i].appName, 10000)
    StopVRWithDelayTime(test_case_name .. "_Stop_VR", 1000)
    audioStreamingState = (apps[i].appName == "NON_MEDIA") and "NOT_AUDIBLE" or "AUDIBLE"
    CheckAppsResumption(test_case_name .. "_Verify_Resumption_Success_When_VR_Ended",
      {mobileSession = {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = audioStreamingState}})
    --Post condition
    common_steps:UnregisterApp(test_case_name .. "_UnRegister_App", apps[i].appName)
    tc_number = tc_number + 1
  end
end
CheckAppFullIsPostponedWhenVRIsStartedBeforeRegisteredApp()

---------------------------------------------------------------------------------------------
-- Requirement summary: Resumption for single application (hmiLevel=FULL) is postponed
-- in case IGNITION_CYCLE and VR is active AFTER application is connected
-- 1.Preconditions:
-- -- 1.1. Application (NAVIGATION/COMMUNICATION/MEDIA/NON_MEDIA) is FULL
-- -- 1.2. Ignition Off
-- -- 1.3. Ignition On
-- 2.Steps:
-- -- 2.1. Register application
-- -- 2.2. Start VR
-- -- 2.3. Check application is not resumed during a period time (10s)
-- -- 2.4. Stop VR
-- 3.Expected Result: Resumption success when VR ended
---------------------------------------------------------------------------------------------
local function CheckAppFullIsPostponedWhenVRIsStartedAfterRegisteredApp()
  for i=1, #apps do
    test_case_name = "TC_" .. tostring(tc_number)
    common_steps:AddNewTestCasesGroup("TC_" .. tostring(tc_number) .. "-HMILevel FULL: resumption for \"" .. apps[i].appName .. "\" app is postponed in case IGNITION_CYCLE and VR is active AFTER application is connected")
    -- Preconditions
    common_steps:RegisterApplication(test_case_name .. "_Register_App", mobile_session_name, apps[i])
    common_steps:ActivateApplication(test_case_name .. "_Activate_App", apps[i].appName)
    common_steps:IgnitionOff(test_case_name .. "_Ignition_Off")
    common_steps:IgnitionOn(test_case_name .. "_Ignition_On")
    -- Body
    common_steps:AddMobileSession(test_case_name .. "_Add_Mobile_Session", _, mobile_session_name)
    common_steps:RegisterApplication(test_case_name .. "_Register_App", mobile_session_name, apps[i])
    StartVR(test_case_name .. "_Start_VR")
    CheckAppIsNotResumedDuringTime(test_case_name .. "_Verify_App_Is_Not_Resume_During_Time", apps[i].appName, 10000)
    StopVRWithDelayTime(test_case_name .. "_Stop_VR", 1000)
    audioStreamingState = (apps[i].appName == "NON_MEDIA") and "NOT_AUDIBLE" or "AUDIBLE"
    CheckAppsResumption(test_case_name .. "_Verify_Resumption_Success_When_VR_Ended",
      {mobileSession = {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = audioStreamingState}})
    --Post condition
    common_steps:UnregisterApp(test_case_name .. "_UnRegister_App", apps[i].appName)
    tc_number = tc_number + 1
  end
end
CheckAppFullIsPostponedWhenVRIsStartedAfterRegisteredApp()

---------------------------------------------------------------------------------------------
-- Requirement summary: Resumption for single application (hmiLevel=LIMITED) is postponed
-- in case IGNITION_CYCLE and VR is active BEFORE application is connected
-- 1.Preconditions:
-- -- 1.1. Application (NAVIGATION/COMMUNICATION/MEDIA/NON_MEDIA) is LIMITED
-- -- 1.2. Ignition Off
-- -- 1.3. Ignition On
-- 2.Steps:
-- -- 2.1. Start VR
-- -- 2.2. Register application
-- -- 2.3. Check application is not resumed during a period time (10s)
-- -- 2.4. Stop VR
-- 3.Expected Result: Resumption success when VR ended
---------------------------------------------------------------------------------------------
local function CheckAppLimitedIsPostponedWhenVRIsStartedBeforerRegisteredApp()
  for i=1, #apps-1 do
    test_case_name = "TC_" .. tostring(tc_number)
    common_steps:AddNewTestCasesGroup("TC_" .. tostring(tc_number) ..
      "-HMILevel LIMITED: resumption for \"" .. apps[i].appName ..
      "\" app is postponed in case IGNITION_CYCLE and VR is active BEFORE application is connected")
    -- Preconditions
    common_steps:RegisterApplication(test_case_name .. "_Register_App", mobile_session_name, apps[i])
    common_steps:ActivateApplication(test_case_name .. "_Activate_App", apps[i].appName)
    common_steps:ChangeHMIToLimited(test_case_name .. "_Change_App_To_Limited", apps[i].appName)
    common_steps:IgnitionOff(test_case_name .. "_Ignition_Off")
    common_steps:IgnitionOn(test_case_name .. "_Ignition_On")
    -- Body
    StartVR(test_case_name .. "_Start_VR")
    common_steps:AddMobileSession(test_case_name .. "_Add_Mobile_Session", _, mobile_session_name)
    common_steps:RegisterApplication(test_case_name .. "_Register_App", mobile_session_name, apps[i])
    CheckAppIsNotResumedDuringTime(test_case_name .. "_Verify_App_Is_Not_Resume_During_Time", apps[i].appName, 10000)
    StopVRWithDelayTime(test_case_name .. "_Stop_VR", 1000)
    CheckAppsResumption(test_case_name .. "_Verify_Resumption_Success_When_VR_Ended",
      {mobileSession = {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}})
    --Post condition
    common_steps:UnregisterApp(test_case_name .. "_UnRegister_App", apps[i].appName)
    tc_number = tc_number + 1
  end
end
CheckAppLimitedIsPostponedWhenVRIsStartedBeforerRegisteredApp()

---------------------------------------------------------------------------------------------
-- Requirement summary: Resumption for single application (hmiLevel=LIMITED) is postponed
-- in case IGNITION_CYCLE and VR is active AFTER application is connected
-- 1.Preconditions:
-- -- 1.1. Application (NAVIGATION/COMMUNICATION/MEDIA/NON_MEDIA) is LIMITED
-- -- 1.2. Ignition Off
-- -- 1.3. Ignition On
-- 2.Steps:
-- -- 2.1. Register application
-- -- 2.2. Start VR
-- -- 2.3. Check application is not resumed during a period time (10s)
-- -- 2.4. Stop VR
-- 3.Expected Result: Resumption success when VR ended
---------------------------------------------------------------------------------------------
local function CheckAppLimitedIsPostponedWhenVRIsStartedAfterRegisteredApp()
  for i=1, #apps-1 do
    test_case_name = "TC_" .. tostring(tc_number)
    common_steps:AddNewTestCasesGroup("TC_" .. tostring(tc_number) ..
      "-HMILevel LIMITED: resumption for \"" .. apps[i].appName ..
      "\" app is postponed in case IGNITION_CYCLE and VR is active AFTER application is connected")
    -- Preconditions
    common_steps:RegisterApplication(test_case_name .. "_Register_App", mobile_session_name, apps[i])
    common_steps:ActivateApplication(test_case_name .. "_Activate_App", apps[i].appName)
    common_steps:ChangeHMIToLimited(test_case_name .. "_Change_App_To_Limited", apps[i].appName)
    common_steps:IgnitionOff(test_case_name .. "_Ignition_Off")
    common_steps:IgnitionOn(test_case_name .. "_Ignition_On")
    -- Body
    common_steps:AddMobileSession(test_case_name .. "_Add_Mobile_Session", _, mobile_session_name)
    common_steps:RegisterApplication(test_case_name .. "_Register_App", mobile_session_name, apps[i])
    StartVR(test_case_name .. "_Start_VR")
    CheckAppIsNotResumedDuringTime(test_case_name .. "_Verify_App_Is_Not_Resume_During_Time", apps[i].appName, 10000)
    StopVRWithDelayTime(test_case_name .. "_Stop_VR", 1000)
    CheckAppsResumption(test_case_name .. "_Verify_Resumption_Success_When_VR_Ended",
      {mobileSession = {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}})
    --Post condition
    common_steps:UnregisterApp(test_case_name .. "_UnRegister_App", apps[i].appName)
    tc_number = tc_number + 1
  end
end
CheckAppLimitedIsPostponedWhenVRIsStartedAfterRegisteredApp()

-------------------------------------------Postcondition-------------------------------------
common_steps:RestoreIniFile("Restore_Ini_file")
