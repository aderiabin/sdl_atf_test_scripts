-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')
-----------------------------Common Variables------------------------------------------------
local apps = {}
apps[1] = common_functions:CreateRegisterAppParameters(
{appID = "1", appName = "Application1", isMediaApplication = false, appHMIType = {"DEFAULT"}})
apps[2] = common_functions:CreateRegisterAppParameters(
{appID = "2", appName = "Application2", isMediaApplication = true, appHMIType = {"MEDIA"}})
apps[3] = common_functions:CreateRegisterAppParameters(
{appID = "3", appName = "Application3", isMediaApplication = false, appHMIType = {"NAVIGATION"}})
apps[4] = common_functions:CreateRegisterAppParameters(
{appID = "4", appName = "Application4", isMediaApplication = false, appHMIType = {"COMMUNICATION"}})
------------------------------------ Common Functions ---------------------------------------
-----------------------------------------------------------------------------
-- Register and Activate apps
-- @param test_case_name: main test name
-- @param register_app: list of the apps will be register
-- @param activate_app: list of the apps will be activate
-----------------------------------------------------------------------------
function RegisterAndActivateApp(test_case_name, register_app, activate_app)
  for i = 1, #register_app do
    local mobile_session_name = "mobile_session" .. register_app[i].appID	
    common_steps:AddMobileSession(test_case_name .. "_AddMobileSession" .. register_app[i].appID,_, 
    mobile_session_name)
    common_steps:RegisterApplication(test_case_name .. "_RegisterApplication" .. register_app[i].appID, 
    mobile_session_name, apps[tonumber(register_app[i].appID)])
  end
  for i = 1, #activate_app do 
    common_steps:ActivateApplication(test_case_name .. "_ActivateApplication" .. activate_app[i].appID, 
    activate_app[i].appName)
  end
end

-----------------------------------------------------------------------------
-- Activate phone call on HMI and verify the HMILevel of app is changed
-- @param test_case_name: main test name
-- @param expected_on_hmi_status_for_other_applications: HMIStatus of apps want to check
-- @param apps_do_not_change_level: list of apps do not change HMIStatus after activate phone call
-----------------------------------------------------------------------------
function ActivatePhoneCallAndVerifyHmiLevelIsChanged(test_case_name, 
  expected_on_hmi_status_for_other_applications, apps_do_not_change_level)
  Test[test_case_name .. "_ActivatePhoneCall_AndVerifyHmiLevelIsChanged"] = function(self) 
    self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", 
    {isActive = true, eventName = "PHONE_CALL"})	
    for k_app_name, v in pairs(expected_on_hmi_status_for_other_applications) do
      local mobile_connection_name, other_mobile_session_name = common_functions:GetMobileConnectionNameAndSessionName(k_app_name, self)
      self[other_mobile_session_name]:ExpectNotification("OnHMIStatus", v)
      :Do(function(_, data)
        common_functions:StoreHmiStatus(k_app_name, data.payload, self)
      end)
    end 
    for i = 1, #apps_do_not_change_level do
      self.apps_do_not_change_level[i]:ExpectNotification("OnHMIStatus")
      :Times(0)
    end	
  end
end

-----------------------------------------------------------------------------
-- Send invalid deactivate notifications phone call on HMI and verify HMILevel of app is not changed
-- @param test_case_name: main test name
-- @param apps_do_not_change_level: list of apps do not change HMIStatus after deactivate phone call with invalid params, invalid json
-----------------------------------------------------------------------------
function DeactivatePhoneCallWithInvalidParamsAndVerifyHmiLevelIsNotChanged
  (test_case_name, apps_do_not_change_level)
  Test[test_case_name .. "_DeactivatePhoneCallWithInvalidParam"] = function(self)
    self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", {isActive = "abcd", 
    eventName = "PHONE_CALL"})		
    for i = 1, #apps_do_not_change_level do
      self.apps_do_not_change_level[i]:ExpectNotification("OnHMIStatus")
      :Times(0)
    end	
  end
  
  Test[test_case_name .. "_DeactivatePhoneCallWithInvalidJson"] = function(self)
    --self.hmiConnection:Send('{"jsonrpc":"2.0","method":"BasicCommunication.OnEventChanged","params":{"isActive":true,"eventName":"PHONE_CALL"}}')
    self.hmiConnection:Send('{"jsonrpc":"2.0","params":{"method":"BasicCommunication.OnEventChanged","isActive":true,"eventName":"PHONE_CALL"}}')
    for i = 1, #apps_do_not_change_level do
      self.apps_do_not_change_level[i]:ExpectNotification("OnHMIStatus")
      :Times(0)
    end	
  end
end

-----------------------------------------------------------------------------
-- Deactivate phone call on HMI with valid param and verify the HMILevel of app will be changed
-- @param test_case_name: main test name
-- @param expected_on_hmi_status_for_other_applications: HMIStatus of apps want to check
-----------------------------------------------------------------------------
function DeactivatePhoneCallAndVerifyHmiLevelIsChanged(test_case_name, expected_on_hmi_status_for_other_applications)
  Test[test_case_name .. "_DeactivatePhoneCall"] = function(self)
    self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", {isActive = false, eventName = "PHONE_CALL"})	
    for k_app_name, v in pairs(expected_on_hmi_status_for_other_applications) do
      local mobile_connection_name, other_mobile_session_name = common_functions:GetMobileConnectionNameAndSessionName(k_app_name, self)
      self[other_mobile_session_name]:ExpectNotification("OnHMIStatus", v)
      :Do(function(_, data)
        common_functions:StoreHmiStatus(k_app_name, data.payload, self)
      end)
    end 
  end
end

-----------------------------------------------------------------------------
-- Activate application and verify the HMIStatus of applications
-- @param test_case_name: main test name
-- @param app_name: name of the app will be activate
-- @param expected_on_hmi_status_for_other_applications: HMIStatus of apps want to check
-----------------------------------------------------------------------------
function ActivateApplicationAndVerifyHmiLevelChanged
  (test_case_name, app_name, expected_on_hmi_status_for_other_applications)
  Test[test_case_name] = function(self)
    local hmi_app_id = common_functions:GetHmiAppId(app_name, self)
    local audio_streaming_state = "NOT_AUDIBLE"
    if common_functions:IsMediaApp(app_name, self) then
      audio_streaming_state = "AUDIBLE"
    end
    local mobile_connect_name, mobile_session_name = common_functions:GetMobileConnectionNameAndSessionName(app_name, self)
    local cid = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = hmi_app_id})
    EXPECT_HMIRESPONSE(cid)
    :Do(function(_,data)
      -- if application is disallowed, HMI has to send SDL.OnAllowSDLFunctionality notification to allow before activation
      -- If isSDLAllowed is false, consent for sending policy table through specified device is required.
      if data.result.isSDLAllowed ~= true then
        self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
        EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function(_,data)
          self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)
      end
    end) 	
    -- Verify OnHMIStatus for other applications
    if not expected_on_hmi_status_for_other_applications then
      expected_on_hmi_status_for_other_applications = {}
      expected_on_hmi_status_for_other_applications[app_name] = 
      {hmiLevel = "FULL", audioStreamingState = audio_streaming_state, systemContext = "MAIN"}
    end 
    for k_app_name, v in pairs(expected_on_hmi_status_for_other_applications) do
      local mobile_connection_name, other_mobile_session_name = common_functions:GetMobileConnectionNameAndSessionName(k_app_name, self)
      self[other_mobile_session_name]:ExpectNotification("OnHMIStatus", v)
      :Do(function(_,data)
        common_functions:StoreHmiStatus(k_app_name, data.payload, self)
      end)
    end -- for k_app_name, v 
  end
end

-----------------------------------------------------------------------------
-- To close session
-- @param test_case_name: main test name
-- @param apps: list of apps need to close
-----------------------------------------------------------------------------
function PostConditionCloseAllSession(test_case_name, apps)
  for i = 1, #apps do
    common_steps:UnregisterApp(test_case_name .. "_Unregister_App" .. apps[i].appID, apps[i].appName )
    common_steps:CloseMobileSession(test_case_name .. "_CloseSession_App" .. apps[i].appID, "mobile_session" .. apps[i].appID) 
  end	
end
-------------------------------------------Preconditions-------------------------------------
common_functions:DeleteLogsFileAndPolicyTable()
common_steps:PreconditionSteps("Precondition",4)

-----------------------------------------------Body------------------------------------------
---------------------------------------------------------------------------------------------
-- Requirement summary: Check Media app will be FULL-NOT_AUDIBLE when activate phone call
-- and become FULL-AUDIBLE when deactivate. Non-media app is still BACKGROUND-NOT_AUDIBLE after deactivate phone call
-- 1.Preconditions:
-- -- 1.1. Create 2 apps (1st: Non-media app in BG, 2nd: Media app in FULL)
-- 2.Steps:
-- -- 2.1. Activate phone call and verify HMILevel of 2nd app
-- -- 2.2. Activate 2nd app
-- -- 2.3. Deactivate phone call with invalid and valid params to verify HMILevel of app is changed or not
-- 3.Expected Result:
-- -- 3.1. 2nd app become BG-NOT AUDIBLE
-- -- 3.2. 2nd app become FULL-NOT AUDIBLE
-- -- 3.3. 2nd app become FULL-audible when there is valid param. In case invalid, HMILevel is not changed
-- 4.Postconditions:
-- -- 4.1. Close sessions
---------------------------------------------------------------------------------------------
local test_case_name = "Case_1"

-- Precondition
common_steps:AddNewTestCasesGroup("Case 1: Check Media app will be FULL-NOT_AUDIBLE " ..
"when there is active phone call and become FULL-audible when phone call active = false.")
RegisterAndActivateApp(test_case_name, {apps[1], apps[2]}, {apps[1], apps[2]})
-- Body
local HMIStatus1_1 = {}
HMIStatus1_1[apps[2].appName] = {hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"}
ActivatePhoneCallAndVerifyHmiLevelIsChanged(test_case_name, HMIStatus1_1, {mobile_session1})
local HMIStatus1_2 = {}
HMIStatus1_2[apps[2].appName] = {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"}
ActivateApplicationAndVerifyHmiLevelChanged(test_case_name .. "_ActivateApp_VerifyHmiLevelIsChanged_App" .. apps[2].appID, apps[2].appName, HMIStatus1_2)
DeactivatePhoneCallWithInvalidParamsAndVerifyHmiLevelIsNotChanged(test_case_name, {mobile_session1, mobile_session2})
local HMIStatus1_3 = {}
HMIStatus1_3[apps[2].appName] = {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}
DeactivatePhoneCallAndVerifyHmiLevelIsChanged(test_case_name, HMIStatus1_3)
-- PostCondition
PostConditionCloseAllSession(test_case_name, {apps[1], apps[2]})

---------------------------------------------------------------------------------------------
-- Requirement summary: Check Navi app will be FULL-NOT_AUDIBLE when activate phone call
-- and become FULL-AUDIBLE when deactivate. Non-media app is still BACKGROUND-NOT_AUDIBLE after deactivate phone call
-- 1.Preconditions:
-- -- 1.1. Create 2 apps (1st: Non-media app in BG, 2nd: Navi app in FULL)
-- 2.Steps:
-- -- 2.1. Activate phone call and verify HMILevel of 2nd app
-- -- 2.2. Activate 2nd app
-- -- 2.3. Deactivate phone call with invalid and valid params to verify HMILevel of app is changed or not
-- 3.Expected Result:
-- -- 3.1. 2nd app become LIMITED-NOT AUDIBLE
-- -- 3.2. 2nd app become FULL-NOT AUDIBLE
-- -- 3.3. 2nd app become FULL-audible when there is valid param. In case invalid, HMILevel is not changed
-- 4.Postconditions:
-- -- 4.1. Close sessions
---------------------------------------------------------------------------------------------
local test_case_name = "Case_2"

-- Precondition
common_steps:AddNewTestCasesGroup("Case 2: Check Navi app will be FULL-NOT_AUDIBLE when " ..
"there is active phone call and become FULL-audible when phone call active = false.")
RegisterAndActivateApp(test_case_name,{apps[1],apps[3]},{apps[1],apps[3]})
-- Body
local HMIStatus2_1 = {}
HMIStatus2_1[apps[3].appName] = {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"}
ActivatePhoneCallAndVerifyHmiLevelIsChanged(test_case_name, HMIStatus2_1, {mobile_session1})
local HMIStatus2_2 = {}
HMIStatus2_2[apps[3].appName] = {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"}
ActivateApplicationAndVerifyHmiLevelChanged(test_case_name .. "_ActivateApp_VerifyHmiLevelIsChanged_App" .. apps[3].appID,apps[3].appName, HMIStatus2_2)
DeactivatePhoneCallWithInvalidParamsAndVerifyHmiLevelIsNotChanged(test_case_name, {mobile_session1, mobile_session3})
local HMIStatus2_3 = {}
HMIStatus2_3[apps[3].appName] = {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}
DeactivatePhoneCallAndVerifyHmiLevelIsChanged(test_case_name, HMIStatus2_3)
-- PostCondition
PostConditionCloseAllSession(test_case_name, {apps[1], apps[3]})

---------------------------------------------------------------------------------------------
-- Requirement summary: Check Communication app will be FULL-NOT_AUDIBLE when activate phone call
-- and become FULL-AUDIBLE when deactivate. Non-media app is still BACKGROUND-NOT_AUDIBLE after deactivate phone call
-- 1.Preconditions:
-- -- 1.1. Create 2 apps (1st: Non-media app in BG, 2nd: Communication app in FULL)
-- 2.Steps:
-- -- 2.1. Activate phone call and verify HMILevel of 2nd app
-- -- 2.2. Activate 2nd app
-- -- 2.3. Deactivate phone call with invalid and valid params to verify HMILevel of app is changed or not
-- 3.Expected Result:
-- -- 3.1. 2nd app become BG-NOT AUDIBLE
-- -- 3.2. 2nd app become FULL-NOT AUDIBLE
-- -- 3.3. 2nd app become FULL-audible when there is valid param. In case invalid, HMILevel is not changed
-- 4.Postconditions:
-- -- 4.1. Close sessions
---------------------------------------------------------------------------------------------
local test_case_name = "Case_3"

-- Precondition
common_steps:AddNewTestCasesGroup("Case 3: Check Communication app will be FULL-NOT_AUDIBLE " ..
"when there is active phone call and become FULL-audible when phone call active = false.")
RegisterAndActivateApp(test_case_name,{apps[1],apps[4]},{apps[1],apps[4]})
-- Body
local HMIStatus3_1 = {}
HMIStatus3_1[apps[4].appName] = {hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"}
ActivatePhoneCallAndVerifyHmiLevelIsChanged(test_case_name, HMIStatus3_1, {mobile_session1})
local HMIStatus3_2 = {}
HMIStatus3_2[apps[4].appName] = {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"}
ActivateApplicationAndVerifyHmiLevelChanged(test_case_name .. "_ActivateApp_VerifyHmiLevelIsChanged_App" .. apps[4].appID,apps[4].appName, HMIStatus3_2)
local HMIStatus3_3 = {}
HMIStatus3_3[apps[4].appName] = {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}
DeactivatePhoneCallAndVerifyHmiLevelIsChanged(test_case_name, HMIStatus3_3)
-- PostCondition
PostConditionCloseAllSession(test_case_name, {apps[1], apps[4]})

--------------------------------------------------------------------------------------------
-- Requirement summary: Check Media app will be FULL-NOT_AUDIBLE when activate phone call
-- and become FULL-AUDIBLE when deactivate. 
-- 1.Preconditions:
-- -- 1.1. Create 4 apps (1st: Non-media app in BG, 2nd: Media app in FULL, 3rd: Navigation app in LIMITED, 4th: Communication app in LIMITED)
-- 2.Steps:
-- -- 2.1. Activate phone call and verify HMILevel of 2nd app
-- -- 2.2. Activate 2nd app
-- -- 2.3. Deactivate phone call with invalid and valid params to verify HMILevel of app is changed or not
-- 3.Expected Result:
-- -- 3.1. 2nd app become BG-NOT AUDIBLE, 3rd app become LIMITED-NOT AUDIBLE, 4th app become BG-NOT AUDIBLE
-- -- 3.2. 2nd app become FULL-NOT AUDIBLE
-- -- 3.3. 2nd app become FULL-audible when there is valid param. In case invalid, HMILevel is not changed
-- 4.Postconditions:
-- -- 4.1. Close sessions
---------------------------------------------------------------------------------------------
local test_case_name = "Case_4"

-- Precondition
common_steps:AddNewTestCasesGroup("Case 4: Check Media app will be FULL-NOT_AUDIBLE" .. 
"when activate phone call and become FULL-AUDIBLE when deactivate.")
RegisterAndActivateApp(test_case_name,{apps[1], apps[2], apps[3], apps[4]}, {apps[1], apps[3], apps[4], apps[2]})
-- Body
local HMIStatus4_1 = {}
HMIStatus4_1[apps[2].appName] = {hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"}
HMIStatus4_1[apps[3].appName] = {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"}
HMIStatus4_1[apps[4].appName] = {hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"}
ActivatePhoneCallAndVerifyHmiLevelIsChanged(test_case_name, HMIStatus4_1, {mobile_session1, mobile_session3, mobile_session4})
local HMIStatus4_2 = {}
HMIStatus4_2[apps[2].appName] = {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"}
ActivateApplicationAndVerifyHmiLevelChanged(test_case_name .. "_ActivateApp_VerifyHmiLevelIsChanged_App" .. apps[2].appID,apps[2].appName, HMIStatus4_2)
DeactivatePhoneCallWithInvalidParamsAndVerifyHmiLevelIsNotChanged
(test_case_name, {mobile_session1, mobile_session2, mobile_session3, mobile_session4})
local HMIStatus4_3 = {}
HMIStatus4_3[apps[2].appName] = {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}
HMIStatus4_3[apps[3].appName] = {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}
HMIStatus4_3[apps[4].appName] = {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}
DeactivatePhoneCallAndVerifyHmiLevelIsChanged(test_case_name, HMIStatus4_3)
-- PostCondition
PostConditionCloseAllSession(test_case_name, {apps[1], apps[2], apps[3], apps[4]})

---------------------------------------------------------------------------------------------
-- Requirement summary: Check Media app with HMILevel NONE will be FULL-NOT_AUDIBLE when activate app after phone call
-- and become FULL-AUDIBLE when deactivate phone call.
-- 1.Preconditions:
-- -- 1.1. Create 2 apps (1st: Non-media app in None, 2nd: Communication app in FULL)
-- 2.Steps:
-- -- 2.1. Activate phone call and verify HMILevel of 2 apps 
-- -- 2.2. Activate 1st app
-- -- 2.3. Deactivate phone call with invalid and valid params to verify HMILevel of app is changed or not
-- 3.Expected Result:
-- -- 3.1. 1st app is still NONE, 2nd app become LIMITED-NOT AUDIBLE
-- -- 3.2. 1st app become FULL-NOT AUDIBLE
-- -- 3.3. 2nd app become LIMITED-audible when there is valid param. In case invalid, HMILevel is not changed
-- 4.Postconditions:
-- -- 4.1. Close sessions
---------------------------------------------------------------------------------------------
local test_case_name = "Case_5"

-- Precondition
common_steps:AddNewTestCasesGroup("Case 5: Check app with HMILevel NONE will be " ..
"FULL-NOT_AUDIBLE when activate phone call and become FULL-AUDIBLE when deactivate.")
RegisterAndActivateApp(test_case_name, {apps[1], apps[2]}, {apps[1]})
-- Body
local HMIStatus5_1 = {}
HMIStatus5_1[apps[1].appName] = {hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"}
ActivatePhoneCallAndVerifyHmiLevelIsChanged(test_case_name, HMIStatus5_1, {mobile_session2})
local HMIStatus5_2 = {}
HMIStatus5_2[apps[2].appName] = {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"}
ActivateApplicationAndVerifyHmiLevelChanged(test_case_name .. "_ActivateApp_VerifyHmiLevelIsChanged_App" .. apps[2].appID, apps[2].appName, HMIStatus5_2)
DeactivatePhoneCallWithInvalidParamsAndVerifyHmiLevelIsNotChanged(test_case_name, {mobile_session1, mobile_session2})
local HMIStatus5_3 = {}
HMIStatus5_3[apps[2].appName] = {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}
DeactivatePhoneCallAndVerifyHmiLevelIsChanged(test_case_name, HMIStatus5_3)
-- PostCondition
PostConditionCloseAllSession(test_case_name, {apps[1], apps[2]})

return Test
          
