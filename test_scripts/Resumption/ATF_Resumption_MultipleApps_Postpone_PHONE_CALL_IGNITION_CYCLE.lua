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
apps[1] = common_functions:CreateRegisterAppParameters({appID = "1", appName = "NAVIGATION", isMediaApplication = false, appHMIType = {"NAVIGATION"}})
apps[2] = common_functions:CreateRegisterAppParameters({appID = "2", appName = "COMMUNICATION", isMediaApplication = false, appHMIType = {"COMMUNICATION"}})
apps[3] = common_functions:CreateRegisterAppParameters({appID = "3", appName = "MEDIA", isMediaApplication = true, appHMIType = {"MEDIA"}})
apps[4] = common_functions:CreateRegisterAppParameters({appID = "4", appName = "NON_MEDIA", isMediaApplication = false, appHMIType = {"DEFAULT"}})
-- Expected hmi status for multiple apps (FULL,LIMITED,LIMITED,BACKGROUND)		
local expected_hmi_status_3apps = {
	mobileSession1 = {hmiLevel = "FULL",    systemContext = "MAIN", audioStreamingState = "AUDIBLE"},
	mobileSession2 = {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"},
	mobileSession3 = {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}
}
-- Expected hmi status for multiple apps (FULL,LIMITED,LIMITED,LIMITED)		
local expected_hmi_status_4apps = {
	mobileSession1 = {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"},
	mobileSession2 = {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"},
	mobileSession3 = {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}--,
	--mobileSession4 = {hmiLevel = "FULL",    systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"}
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
	isActiveValue = {
	{isActive= "", eventName="EMERGENCY_EVENT"},
	{isActive= 123, eventName="EMERGENCY_EVENT"},
	{eventName="EMERGENCY_EVENT"}
	}
	invalid_type ={"IsActiveEmpty", "IsActiveWrongType", "IsActiveMissed"}
	for i=1, #isActiveValue do	
		Test[test_case_name .. invalid_type[i]] = function(self)				
			function to_run()
			self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", isActiveValue[i])	
			end
			RUN_AFTER(to_run,6000)
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
		self[mobile_session_name]:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL",    systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
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
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Requirement summary: Resumption for multiple applications FULL/LIMITED/LIMITED/BACKGROUND) is postponed in case IGNITION_CYCLE and PHONE_CALL is active BEFORE applications are connected
-- 1.Preconditions: 
-- -- 1.1. Applications (NAVIGATION/COMMUNICATION/MEDIA/NON_MEDIA) are (FULL/LIMITED/LIMITED/BACKGROUND)
-- -- 1.2. Close session
-- 2.Steps: 
-- -- 2.1. Start PHONE_CALL 
-- -- 2.1. Register applications
-- -- 2.3. Stop PHONE_CALL
-- 3.Expected Result: Resumption success when PHONE_CALL ended
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
local function CheckMultipleAppsFullLimitedLimitedBackgroundArePostponedWhenPhoneCallIsStartedBeforeRegisteredApp()
	common_steps:AddNewTestCasesGroup("Multiple apps (Full-Limited-Limited-Background) are postponed" ..
	" in case IGNITION_CYCLE and PHONE_CALL is active BEFORE apps are connected")
	-- Precondition
	for i = 1, #apps do					
		common_steps:AddMobileSession("TC_1_Add_Mobile_Session_" .. tostring(i), _, MOBILE_SESSION[i])		
		common_steps:RegisterApplication("TC_1_Register_App_" .. apps[i].appName, MOBILE_SESSION[i], apps[i])				
	end		
	-- Activate Apps: App["NAVIGATION"]-FULL, App["COMMUNICATION"]-LIMITED, App["MEDIA"]-LIMITED, App["NON_MEDIA"]-BACKGROUND
	for i = #apps, 1, -1 do
			common_steps:ActivateApplication("TC_1_Activate_App_" .. apps[i].appName, apps[i].appName)
	end	
	common_steps:IgnitionOff("TC_1_Ignition_Off")
	common_steps:IgnitionOn("TC_1_Ignition_On")
	-- Body
	StartPhoneCall("TC_1_Start_Phone_Call")
	for i = #apps, 1, -1 do 
		common_steps:AddMobileSession("TC_1_Add_Mobile_Session_" .. tostring(i), _, MOBILE_SESSION[i])
		common_steps:RegisterApplication("TC_1_Register_App_" .. apps[i].appName, MOBILE_SESSION[i], apps[i])	
	end	
	StopPhoneCallWithDelayTime("TC_1_Stop_Phone_Call", 10000)	
	CheckAppsResumptionUnsuccessWhenIsActiveInvalid("TC_1_Verify_Resumption_MultipleApps_Unsucess_When_IsActive_InValid")
	CheckAppsResumptionSuccessful("TC_1_Verify_Resumption_MultipleApps_Sucess_When_IsActive_Valid", expected_hmi_status_3apps)		
	-- Post condition
	for i = 1, #apps do			
		common_steps:UnregisterApp("TC_1_Unregister_App_" .. apps[i].appName, apps[i].appName)		
	end 	
end
CheckMultipleAppsFullLimitedLimitedBackgroundArePostponedWhenPhoneCallIsStartedBeforeRegisteredApp()
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Requirement summary: Resumption for multiple applications FULL/LIMITED/LIMITED/BACKGROUND) is postponed in case IGNITION_CYCLE and PHONE_CALL is active AFTER applications are connected
-- 1.Preconditions: 
-- -- 1.1. Applications (NAVIGATION/COMMUNICATION/MEDIA/NON_MEDIA) are (FULL/LIMITED/LIMITED/BACKGROUND)
-- -- 1.2. Close session
-- 2.Steps: 
-- -- 2.1. Register applications
-- -- 2.2. Start PHONE_CALL 
-- -- 2.3. Stop PHONE_CALL
-- 3.Expected Result: Resumption success when PHONE_CALL ended
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
local function CheckMultipleAppsFullLimitedLimitedBackgroundArePostponedWhenPhoneCallIsStartedAfterRegisteredApp()
	common_steps:AddNewTestCasesGroup("Multiple apps (Full-Limited-Limited-Background) are postponed" ..
	" in case IGNITION_CYCLE and PHONE_CALL is active BEFORE apps are connected")
	--Precondition
	for i = 1, #apps do					
		common_steps:AddMobileSession("TC_2_Add_Mobile_Session_" .. tostring(i), _, MOBILE_SESSION[i])		
		common_steps:RegisterApplication("TC_2_Register_App_" .. apps[i].appName, MOBILE_SESSION[i], apps[i])				
	end		
	-- Activate Apps: App["NAVIGATION"]-FULL, App["COMMUNICATION"]-LIMITED, App["MEDIA"]-LIMITED, App["NON_MEDIA"]-BACKGROUND
	for i = #apps, 1, -1 do
			common_steps:ActivateApplication("TC_2_Activate_App_" .. apps[i].appName, apps[i].appName)
	end	
	common_steps:IgnitionOff("TC_2_Ignition_Off")
	common_steps:IgnitionOn("TC_2_Ignition_On")
	--Body
	for i = #apps, 1, -1 do 
		common_steps:AddMobileSession("TC_2_Add_Mobile_Session_" .. tostring(i), _, MOBILE_SESSION[i])
		common_steps:RegisterApplication("TC_2_Register_App_" .. apps[i].appName, MOBILE_SESSION[i], apps[i])	
	end	
	StartPhoneCall("TC_2_Start_Phone_Call")
	StopPhoneCallWithDelayTime("TC_2_Stop_Phone_Call", 10000)	
	CheckAppsResumptionUnsuccessWhenIsActiveInvalid("TC_2_Verify_Resumption_MultipleApps_Unsucess_When_IsActive_InValid")
	CheckAppsResumptionSuccessful("TC_2_Verify_Resumption_MultipleApps_Sucess_When_IsActive_Valid", expected_hmi_status_3apps)		
	-- Post condition
	for i = 1, #apps do			
		common_steps:UnregisterApp("TC_2_Unregister_App_" .. apps[i].appName, apps[i].appName)		
	end 	
end
CheckMultipleAppsFullLimitedLimitedBackgroundArePostponedWhenPhoneCallIsStartedAfterRegisteredApp()
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Requirement summary: Resumption for multiple applications FULL/LIMITED/LIMITED/LIMITED) is postponed in case IGNITION_CYCLE and PHONE_CALL is active BEFORE applications are connected
-- 1.Preconditions: 
-- -- 1.1. Applications (NAVIGATION/COMMUNICATION/MEDIA/NON_MEDIA) are (FULL/LIMITED/LIMITED/LIMITED)
-- -- 1.2. Close session
-- 2.Steps: 
-- -- 2.1. Start PHONE_CALL 
-- -- 2.1. Register applications
-- -- 2.3. Stop PHONE_CALL
-- 3.Expected Result: Resumption success when PHONE_CALL ended
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
local function CheckMultipleAppsFullLimitedLimitedLimitedArePostponedWhenPhoneCallIsStartedBeforeRegisteredApp()
	common_steps:AddNewTestCasesGroup("Multiple apps (Full-Limited-Limited-Limited) are postponed" ..
	" in case IGNITION_CYCLE and PHONE_CALL is active BEFORE apps are connected")
	-- Precondition
	for i = 1, #apps do					
		common_steps:AddMobileSession("TC_3_Add_Mobile_Session_" .. tostring(i), _, MOBILE_SESSION[i])		
		common_steps:RegisterApplication("TC_3_Register_App_" .. apps[i].appName, MOBILE_SESSION[i], apps[i])				
	end		
	-- Activate Apps: App["NON_MEDIA"]-FULL, App["MEDIA"]-LIMITED, App["COMMUNICATION"]-LIMITED, App["NAVIGATION"]-LIMITED
	for i = 1, #apps do
			common_steps:ActivateApplication("TC_3_Activate_App_" .. apps[i].appName, apps[i].appName)
	end	
	common_steps:IgnitionOff("TC_3_Ignition_Off")
	common_steps:IgnitionOn("TC_3_Ignition_On")
	-- Body
	StartPhoneCall("TC_3_Start_Phone_Call")
	for i = #apps, 1, -1 do 
		common_steps:AddMobileSession("TC_3_Add_Mobile_Session_" .. tostring(i), _, MOBILE_SESSION[i])
		common_steps:RegisterApplication("TC_3_Register_App_" .. apps[i].appName, MOBILE_SESSION[i], apps[i])	
	end	
	CheckNoneMediaResumeSuccessWithoutPhoneCallEnded("TC_3_Verify_Non_Media_Is_Resumed_Without_Phone_Call_Ended", MOBILE_SESSION[4])
	StopPhoneCallWithDelayTime("TC_3_Stop_Phone_Call", 10000)
	CheckAppsResumptionUnsuccessWhenIsActiveInvalid("TC_3_Verify_Resumption_MultipleApps_Unsucess_When_IsActive_InValid")
	CheckAppsResumptionSuccessful("TC_3_Verify_Resumption_MultipleApps_Sucess_When_IsActive_Valid", expected_hmi_status_4apps)		
	-- Post condition
	for i = 1, #apps do			
		common_steps:UnregisterApp("TC_3_Unregister_App_" .. apps[i].appName, apps[i].appName)		
	end 	
end
CheckMultipleAppsFullLimitedLimitedLimitedArePostponedWhenPhoneCallIsStartedBeforeRegisteredApp()
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Requirement summary: Resumption for multiple applications FULL/LIMITED/LIMITED/LIMITED) is postponed in case IGNITION_CYCLE and PhoneCall is active AFTER applications are connected
-- 1.Preconditions: 
-- -- 1.1. Applications (NAVIGATION/COMMUNICATION/MEDIA/NON_MEDIA) are (FULL/LIMITED/LIMITED/LIMITED)
-- -- 1.2. Close session
-- 2.Steps: 
-- -- 2.1. Register applications
-- -- 2.2. Start PhoneCall 
-- -- 2.3. Stop PhoneCall
-- 3.Expected Result: Resumption success when PhoneCall ended
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
local function CheckMultipleAppsFullLimitedLimitedLimitedArePostponedWhenPhoneCallIsStartedAfterRegisteredApp()
	common_steps:AddNewTestCasesGroup("Multiple apps (Full-Limited-Limited-Limited) are postponed" ..
	" in case IGNITION_CYCLE and PhoneCall is active BEFORE apps are connected")
	--Precondition
	for i = 1, #apps do					
		common_steps:AddMobileSession("TC_4_Add_Mobile_Session_" .. tostring(i), _, MOBILE_SESSION[i])		
		common_steps:RegisterApplication("TC_4_Register_App_" .. apps[i].appName, MOBILE_SESSION[i], apps[i])				
	end		
	-- Activate Apps: App["NON_MEDIA"]-FULL, App["MEDIA"]-LIMITED, App["COMMUNICATION"]-LIMITED, App["NAVIGATION"]-LIMITED
	for i = 1, #apps do
			common_steps:ActivateApplication("TC_4_Activate_App_" .. apps[i].appName, apps[i].appName)
	end		
	common_steps:IgnitionOff("TC_4_Ignition_Off")
	common_steps:IgnitionOn("TC_4_Ignition_On")
	--Body
	for i = #apps, 1, -1 do 
		common_steps:AddMobileSession("TC_4_Add_Mobile_Session_" .. tostring(i), _, MOBILE_SESSION[i])
		common_steps:RegisterApplication("TC_4_Register_App_" .. apps[i].appName, MOBILE_SESSION[i], apps[i])	
	end	
	StartPhoneCall("TC_4_Start_Phone_Call")
	CheckNoneMediaResumeSuccessWithoutPhoneCallEnded("TC_4_Verify_Non_Media_Is_Resumed_Without_Phone_Call_Ended", MOBILE_SESSION[4])
	StopPhoneCallWithDelayTime("TC_4_Stop_Phone_Call", 10000)	
	CheckAppsResumptionUnsuccessWhenIsActiveInvalid("TC_4_Verify_Resumption_MultipleApps_Unsucess_When_IsActive_InValid")
	CheckAppsResumptionSuccessful("TC_4_Verify_Resumption_MultipleApps_Sucess_When_IsActive_Valid", expected_hmi_status_4apps)		
	-- Post condition
	for i = 1, #apps do			
		common_steps:UnregisterApp("TC_4_Unregister_App_" .. apps[i].appName, apps[i].appName)		
	end 	
end
CheckMultipleAppsFullLimitedLimitedLimitedArePostponedWhenPhoneCallIsStartedAfterRegisteredApp()
-------------------------------------------Postcondition-------------------------------------
common_steps:RestoreIniFile("Restore_Ini_file")
