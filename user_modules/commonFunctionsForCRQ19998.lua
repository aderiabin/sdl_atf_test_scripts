--------------------------------------------------------------------------------
-- This script contains common functions that are used in testing APPLINK-19998: [HMILevel Resumption] Conditions for SDL to postpone HMILevel resumption for navigation and voice-communication apps
--------------------------------------------------------------------------------
--[[Covered cases:
-> Verify Single/Multiple app(s) is(are) resumed when VR is started before/after app(s) connected in case Igniton Off and Ignition On and VR.Stop
-> Verify Single/Multiple app(s) is(are) resumed when VR is started before/after app(s) connected in case Session Stop and Session Start and VR.Stop
-> Verify Single/Multiple app(s) is(are) resumed when Phone Call is started before/after app(s) connected in case Igniton Off and Ignition On and Phone Call.Stop
-> Verify Single/Multiple app(s) is(are) resumed when Phone Call is started before/after app(s) connected in case Session Stop and Session Start and Phone Call.Stop
-> Verify Single/Multiple app(s) is(are) resumed when Emergency is started before/after app(s) connected in case Igniton Off and Ignition On and Emergency.Stop
-> Verify Single/Multiple app(s) is(are) resumed when Emergency is started before/after app(s) connected in case Session Stop and Session Start and Emergency.Stop
]]
-- This library is used for below scripts:
-- test_scripts/Resumption/ATF_Resumption_HMI_level_postpone_APPLINK_19998_VR_IGNITION_OFF.lua
-- test_scripts/Resumption/ATF_Resumption_HMI_level_postpone_APPLINK_19998_VR_UNEXPECTED_DISCONNECT.lua
-- test_scripts/Resumption/ATF_Resumption_HMI_level_postpone_APPLINK_19998_PHONECALL_IGNITION_OFF.lua
-- test_scripts/Resumption/ATF_Resumption_HMI_level_postpone_APPLINK_19998_PHONECALL_UNEXPECTED_DISCONNECT.lua
-- test_scripts/Resumption/ATF_Resumption_HMI_level_postpone_APPLINK_19998_EMERGENCY_IGNITION_OFF.lua
-- test_scripts/Resumption/ATF_Resumption_HMI_level_postpone_APPLINK_19998_EMERGENCY_UNEXPECTED_DISCONNECT.lua
-- Author: Truong Thi Kim Hanh
-- ATF version: 2.2

local commonFunctionsForCRQ19998 = {}
Test = require('user_modules/connect_without_mobile_connection')
local common_steps = require('user_modules/common_multi_mobile_connections')
local common_test_cases = require('user_modules/shared_testcases/commonTestCases')
local mobile_session = require('mobile_session')
local common_preconditions = require('user_modules/shared_testcases/commonPreconditions')
local common_functions = require('user_modules/shared_testcases/commonFunctions')

---------------------------------------------------------------------------------------------
----------------------- Common Variables For CRQ 19998 Only----------------------------------
---------------------------------------------------------------------------------------------
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.defaultProtocolVersion = 2
local TIME_FOR_STOP_EVENT = 5000
mobile_session_name = "mobileSession"
RESUMED_HMI_LEVEL = {"FULL", "LIMITED"}
START_EVENT_BEFORE_AFTER_REGISTER_APP = {true, false}
MOBILE_SESSION = {"mobileSession1", "mobileSession2", "mobileSession3", "mobileSession4"}

apps = {}
apps[1] = config.application1.registerAppInterfaceParams
apps[1].appName = "NAVIGATION"
apps[1].isMediaApplication = false
apps[1].appHMIType = { "NAVIGATION" }
apps[1].appID = "1"

apps[2] = config.application2.registerAppInterfaceParams
apps[2].appName = "MEDIA"
apps[2].isMediaApplication = true
apps[2].appHMIType = { "MEDIA" }
apps[2].appID = "2"

apps[3] = config.application3.registerAppInterfaceParams
apps[3].appName = "COMMUNICATION"
apps[3].isMediaApplication = false
apps[3].appHMIType = { "COMMUNICATION" }
apps[3].appID = "3"

apps[4] = config.application4.registerAppInterfaceParams
apps[4].appName = "NON_MEDIA"
apps[4].isMediaApplication = false
apps[4].appHMIType = { "DEFAULT" }
apps[4].appID = "4"

-- Expected hmi status for multiple apps (FULL,LIMITED,LIMITED,BACKGROUND)		
 expected_hmi_status_3apps = {
	mobileSession4 = {hmiLevel = "FULL",    systemContext = "MAIN", audioStreamingState = "AUDIBLE"},
	mobileSession3 = {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"},
	mobileSession2 = {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}
}
-- Expected hmi status for multiple apps (FULL,LIMITED,LIMITED,LIMITED)		
 expected_hmi_status_4apps = {
	mobileSession4 = {hmiLevel = "FULL",    systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"},
	mobileSession3 = {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"},
	mobileSession2 = {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"},
	mobileSession1 = {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}
}
---------------------------------------------------------------------------------------------
--------------------------- Common Functions For CRQ 19998 Only -----------------------------
---------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Resume unsuccess when inActive is invalid
-- @param test_case_name: main test name
-- @param mobile_sessions: mobile session of apps
-- @param event_stopped: resumption will be postponed when this event is actived
-----------------------------------------------------------------------------
function commonFunctionsForCRQ19998:ResumeUnsuccessWhenParamOfEventInvalid(test_case_name, mobile_sessions, event_stopped)		
	isActiveValue = {{isActive= "", eventName="EMERGENCY_EVENT"}, {isActive= 123, eventName="EMERGENCY_EVENT"}, {eventName="EMERGENCY_EVENT"}}
	invalid_type ={"IsActiveEmpty", "IsActiveWrongType", "IsActiveMissed"}
	for i=1, #isActiveValue do	
		Test[test_case_name .. invalid_type[i]] = function(self)				
			self.hmiConnection:SendNotification(event_stopped.event_name,isActiveValue[i])
			EXPECT_HMICALL("BasicCommunication.ActivateApp"):Times(0)
			common_test_cases:DelayedExp(TIME_FOR_STOP_EVENT)	
		-- Resumption can't start
			for i = 1, #mobile_sessions do
				self[mobile_sessions[i]]:ExpectNotification("OnHMIStatus"):Times(0)
			end
		end
	end
end
-----------------------------------------------------------------------------
-- Resume 4 apps
-- @param test_case_name: main test name
-- @param event_stopped: resumption will be postponed when this event is actived
-- @param expected_hmi_status: expect hmi status after resuming
-----------------------------------------------------------------------------
function commonFunctionsForCRQ19998:Resume4Apps(test_case_name, event_stopped, expected_hmi_status)	
	Test[test_case_name] = function(self) 		
		print ("\27[" .. tostring(35) .. "m " .. "================= Test Case ==================" .. " \27[0m")		
		common_test_cases:DelayedExp(TIME_FOR_STOP_EVENT)		
		self.hmiConnection:SendNotification(event_stopped.event_name,event_stopped.event_params)				
		for k,v in pairs(expected_hmi_status) do 			
			if v.hmiLevel == "FULL" then
				EXPECT_HMICALL("BasicCommunication.ActivateApp")
				:Do(function(_,data)			  
				  self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
				end)
			end		
			self[tostring(k)]:ExpectNotification("OnHMIStatus", v)			
		end			
	end
end
-----------------------------------------------------------------------------
-- Resume App
-- @param test_case_name: main test name
-- @param event_stopped: resumption will be postponed when this event is actived
-- @param mobile_session: mobile session of app
-- @param expected_hmi_status: expect hmi status after resuming
-----------------------------------------------------------------------------
function commonFunctionsForCRQ19998:ResumeApp(test_case_name, event_stopped, mobile_session, expected_hmi_status)	
	Test[test_case_name] = function(self) 		
		print ("\27[" .. tostring(35) .. "m " .. "================= Test Case ==================" .. " \27[0m")				
		common_test_cases:DelayedExp(TIME_FOR_STOP_EVENT)		
		self.hmiConnection:SendNotification(event_stopped.event_name, event_stopped.event_params)				
		if expected_hmi_status.hmiLevel == "FULL" then
			EXPECT_HMICALL("BasicCommunication.ActivateApp")
			:Do(function(_,data)				
					self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
			end)
		end
		self[mobile_session]:ExpectNotification("OnHMIStatus", expected_hmi_status)
	end
end
---------------------------------------------------------------------------------------------
-- Check single app is resumed
-- @param test_case_name: main test name
-- @param hmil_level: value "FULL" or "LIMITED"
-- @param is_event_started_before_registering: value true: before, false: afteron_
-- @param app: value TEST_DATA_FOR_SINGLE_APP
-- @param events: events (PHONE_CALL, VR, EMERGENCY) are started or stopped
-- @param is_ignition_off: true-IGNITION_OFF; false-UNEXPECTED DISCONNECT
---------------------------------------------------------------------------------------------
function commonFunctionsForCRQ19998:CheckSingleAppIsResumed(test_case_name, hmil_level, is_event_started_before_registering, app, events, is_ignition_off)		
	common_steps:RegisterApplication(test_case_name .. "_Register_App", mobile_session_name, app)		
	common_steps:ActivateApplication(test_case_name .. "_Activate_App", app.appName)		
	if hmil_level == "LIMITED" then
		common_steps:ChangeHMIToLimited(test_case_name .. "_Change_App_To_Limited", app.appName)
	end		
	if is_ignition_off == true then
		common_steps:IgnitionOff(test_case_name .. "_Ignition_Off")
		common_steps:IgnitionOn(test_case_name .. "_Ignition_On")
	else  -- Unexpected Disconnect
	common_steps:CloseMobileSession(test_case_name .. "_Close_Mobile_Session", mobile_session_name)
	end
	if is_event_started_before_registering == true then			
		commonFunctionsForCRQ19998:StartEvent(test_case_name .. "_Start_Phone_Call", events.start)
	end		
	common_steps:AddMobileSession(test_case_name .. "_Add_Mobile_Session", _, mobile_session_name)
	common_steps:RegisterApplication(test_case_name .. "_Register_App", mobile_session_name, app)						
	if is_event_started_before_registering == false then			
		commonFunctionsForCRQ19998:StartEvent(test_case_name .. "_Start_Phone_Call", events.start)
	end			
	if events.start.event_params.eventName == "PHONE_CALL" then
		if app.appName == "NON_MEDIA" then
			commonFunctionsForCRQ19998:NoneMediaResumeSuccessWithoutPhoneCallEnded(test_case_name .. "_Resume_Success_Without_Event_End", mobile_session_name)			
		else
			commonFunctionsForCRQ19998:ResumeUnsuccessWhenParamOfEventInvalid(test_case_name .. "_Resumption_SingleApp_Unsucess_When_IsActive_Invalid: ", {mobile_session_name}, events.stop)		
			commonFunctionsForCRQ19998:ResumeApp(test_case_name .. "_Verify_Resumption_Success_When_Event_Ended", events.stop, mobile_session_name, {hmiLevel = hmil_level, systemContext = "MAIN", audioStreamingState = audio_streaming_state})	
		end		
	end
	if events.start.event_name == "VR.Started" then
		if app.appName == "NON_MEDIA" then
			audio_streaming_state = "NOT_AUDIBLE"
		end
		commonFunctionsForCRQ19998:ResumeApp(test_case_name .. "_Verify_Resumption_Success_When_Event_Ended", events.stop, mobile_session_name, {hmiLevel = hmil_level, systemContext = "MAIN", audioStreamingState = audio_streaming_state})	
	end
	if events.start.event_params.eventName == "EMERGENCY_EVENT" then
		if app.appName == "NON_MEDIA" then
			audio_streaming_state = "NOT_AUDIBLE"
		end
		commonFunctionsForCRQ19998:ResumeUnsuccessWhenParamOfEventInvalid(test_case_name .. "_Resumption_SingleApp_Unsucess_When_IsActive_Invalid: ", {mobile_session_name}, events.stop)		
		commonFunctionsForCRQ19998:ResumeApp(test_case_name .. "_Verify_Resumption_Success_When_Event_Ended", events.stop, mobile_session_name, {hmiLevel = hmil_level, systemContext = "MAIN", audioStreamingState = audio_streaming_state})	
	end
	common_steps:UnregisterApp(test_case_name .. "_UnRegister_App", app.appName)
end
---------------------------------------------------------------------------------------------
-- Check multiple apps are resumed
-- @param test_case_name: main test name
-- @param expected_hmi_status: expected hmi status of 4pps after resuming 
-- @param is_event_started_before_registering: value true: before, false: after
-- @param is_apps_contain_backgound_level: true or false
-- @param events: events (PHONE_CALL, VR, EMERGENCY) are started or stopped
-- @param is_ignition_off: true-IGNITION_OFF; false-UNEXPECTED DISCONNECT
---------------------------------------------------------------------------------------------
function commonFunctionsForCRQ19998:CheckMultipleAppsAreResumed(test_case_name, expected_hmi_status, is_event_started_before_registering, is_apps_contain_backgound_level, events, is_ignition_off)		
	-- Precondition: Add new session/ Register App/ Activate App		
	for i = 1, #apps do					
		common_steps:AddMobileSession(test_case_name .. "_Add_Mobile_Session_" .. tostring(i), _, MOBILE_SESSION[i])		
		common_steps:RegisterApplication(test_case_name .. "_Register_App_" .. apps[i].appName, MOBILE_SESSION[i], apps[i])				
	end	
	if is_apps_contain_backgound_level == true then
		for i = #apps, 1, -1 do
			common_steps:ActivateApplication(test_case_name .. "_Activate_App_" .. apps[i].appName, apps[i].appName)
		end
	else
		for i = 1, #apps do
			common_steps:ActivateApplication(test_case_name .. "_Activate_App_" .. apps[i].appName, apps[i].appName)
		end
	end
	if is_ignition_off == true then
		common_steps:IgnitionOff(test_case_name .. "_Ignition_Off")
		common_steps:IgnitionOn(test_case_name .. "_Ignition_On")
	else
		for i = 1, #MOBILE_SESSION do
			common_steps:CloseMobileSession(test_case_name .. "_Close_Mobile_Session_" .. tostring(i), MOBILE_SESSION[i])
		end
	end
	if is_event_started_before_registering == true then
		commonFunctionsForCRQ19998:StartEvent(test_case_name .. "_Start_Phone_Call", events.start)
	end
	for i = 1, #apps do 
		common_steps:AddMobileSession(test_case_name .. "_Add_Mobile_Session_" .. tostring(i), _, MOBILE_SESSION[i])
		common_steps:RegisterApplication(test_case_name .. "_Register_App_" .. apps[i].appName, MOBILE_SESSION[i], apps[i])	
	end
	if is_event_started_before_registering == false then
		commonFunctionsForCRQ19998:StartEvent(test_case_name .. "_Start_Phone_Call", events.start)
	end	
	commonFunctionsForCRQ19998:ResumeUnsuccessWhenParamOfEventInvalid(test_case_name .. "_Resumption_MultipleApps_Unsucess_When_IsActive_Invalid: ", MOBILE_SESSION, events.stop)		
	commonFunctionsForCRQ19998:Resume4Apps(test_case_name .. "_Resumption_MultipleApps_Sucess_When_IsActive_Valid", events.stop, expected_hmi_status)		
	-- Post condition
	for i = 1, #apps do			
		common_steps:UnregisterApp(test_case_name .. "_Unregister_App_" .. apps[i].appName, apps[i].appName)		
	end 				
end	
-----------------------------------------------------------------------------
-- None Media is resumed success without phone call is ended
-- @param test_case_name: main test name 
-- @param mobile_session_name: mobile session
-----------------------------------------------------------------------------
function commonFunctionsForCRQ19998:NoneMediaResumeSuccessWithoutPhoneCallEnded(test_case_name, mobile_session_name)	
	Test[test_case_name] = function(self)
			EXPECT_HMICALL("BasicCommunication.ActivateApp")
			:Do(function(_,data)
					self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
			end)
		self[mobile_session_name]:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL",    systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
	end
end
-----------------------------------------------------------------------------
-- Start event
-- @param test_case_name: main test name 
-- @param event: event is started
-----------------------------------------------------------------------------
function commonFunctionsForCRQ19998:StartEvent(test_case_name, event)	
	Test[test_case_name] = function(self)  	
		self.hmiConnection:SendNotification(event.event_name,event.event_params)	
	end	
end
-----------------------------------------------------------------------------
-- Restore smartDeviceLink.ini File
-- @param test_case_name: main test name 
-----------------------------------------------------------------------------
function commonFunctionsForCRQ19998:RestoreIniFile(test_case_name)
  Test[test_case_name] = function(self)  
		common_preconditions:RestoreFile("smartDeviceLink.ini")
	end
end
---------------------------------------------------------------------------------------------
-------------------------------------------Common preconditions------------------------------
---------------------------------------------------------------------------------------------
common_preconditions:BackupFile("smartDeviceLink.ini")
-- Set the time that application will be resumed (ApplicationResumingTimeout in smartDeviceLink.ini)
common_functions:SetValuesInIniFile("%p?ApplicationResumingTimeout%s? = %s-[%d]-%s-\n", "ApplicationResumingTimeout", 3000)
common_steps:PreconditionSteps("Precondition", 4)

return commonFunctionsForCRQ19998
