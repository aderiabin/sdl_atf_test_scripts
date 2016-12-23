---------------------------------------------------------------------------------------------
-- Author: I.Stoimenova
-- Creation date: 29.07.2016
-- Last update date: 10.08.2016
-- ATF version: 2.2

---------------------------------------------------------------------------------------------
----------------------------- General Preparation -------------------------------------------
---------------------------------------------------------------------------------------------
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

commonSteps:DeleteLogsFileAndPolicyTable()


---------------------------------------------------------------------------------------------
---------------------- require system ATF files for script like -----------------------------
---------------------------------------------------------------------------------------------
Test = require('connecttest')
require('cardinalities')
local events 				 = require('events')
local mobile_session = require('mobile_session')
local mobile 			 = require('mobile_connection')
local tcp 						 = require('tcp_connection')
local file_connection = require('file_connection')
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
config.application1.registerAppInterfaceParams.isMediaApplication = true

local app_audioStreaming = ""
local app_HMIlevel = ""
-------------------------------------------------------------------------------------------
local MixingAudioSupported = ""

-- Read default value of MixingAudioSupported in .ini file
f = assert(io.open(config.pathToSDL.. "/smartDeviceLink.ini", "r"))

fileContent = f:read("*all")
DefaultContant = fileContent:match('MixingAudioSupported.?=.?([^\n]*)')

if not DefaultContant then
	print ( " \27[31m MixingAudioSupported is not found in smartDeviceLink.ini \27[0m " )
else
	MixingAudioSupported = DefaultContant
	--print("MixingAudioSupported = " ..MixingAudioSupported)
end
f:close()


---------------------------------------------------------------------------------------------
-----------------------------------Local functions ------------------------------------------
---------------------------------------------------------------------------------------------
local function userPrint( color, message)
	
	print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
end

local function ActivationApp(self)
	
	--hmi side: sending SDL.ActivateApp request
	local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
	
	EXPECT_HMIRESPONSE(RequestId)
	:Do(function(_,data)
		if
		data.result.isSDLAllowed ~= true then
			local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
			
			--hmi side: expect SDL.GetUserFriendlyMessage message response
			--TODO: update after resolving APPLINK-16094.
			--EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
			EXPECT_HMIRESPONSE(RequestId)
			:Do(function(_,data)						
				--hmi side: send request SDL.OnAllowSDLFunctionality
				self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = deviceMAC, name = "127.0.0.1"}})
				
				--hmi side: expect BasicCommunication.ActivateApp request
				EXPECT_HMICALL("BasicCommunication.ActivateApp")
				:Do(function(_,data)
					--hmi side: sending BasicCommunication.ActivateApp response
					self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
				end)
				:Times(AnyNumber())
			end)
		end
	end)
	
	--mobile side: expect notification
	EXPECT_NOTIFICATION("OnHMIStatus", 
	{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"}) 
	:Do(function(_,data)
		app_HMIlevel = data.payload.hmiLevel
		app_audioStreaming = data.payload.audioStreamingState
	end)
end


---------------------------------------------------------------------------------------------
--Description: MixingAudioSupported is checked in smartDeviceLink.ini
--Requirement id in JIRA: APPLINK-21529
--Verification criteria: Parameter MixingAudioSupported is present in file smartDeviceLink.ini
Test["TC01_INIfile_MixingAudioSupported"] = function(self)
	userPrint(35,"======================================= Test Case 01 =============================================")
	if(MixingAudioSupported == "true") then
		print ("\27[32m Tests will be executed for MixingAudioSupported = true.\27[0m")
	else
		self.FailTestCase("MixingAudioSupported = " ..MixingAudioSupported ..". Pay attention in test execution")
	end
end

---------------------------------------------------------------------------------------------	

---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--CommonRequestCheck: Check of mandatory/conditional request's parameters (mobile protocol)--
---------------------------------------------------------------------------------------------
--Not applicable because CRQ tests OnHMIStatus notification
--Begin Test suit PositiveRequestCheck		
--End Test suit PositiveRequestCheck
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
----------------------------------------II TEST BLOCK----------------------------------------
----------------------------------------Positive cases---------------------------------------
--Positive cases: Check of positive value of request/response parameters (mobile protocol, HMI protocol)
---------------------------------------------------------------------------------------------
--Not applicable because CRQ tests OnHMIStatus notification
--Begin Test suit PositiveResponseCheck
--End Test suit PositiveResponseCheck
---------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------
----------------------------------------III TEST BLOCK----------------------------------------
------------------------------------Negative request cases------------------------------------
--Check of negative value of request/response parameters (mobile protocol, HMI protocol)------
----------------------------------------------------------------------------------------------
--Not applicable because CRQ tests OnHMIStatus notification
--Begin Test suit NegativeRequestCheck
--End Test suit NegativeRequestCheck
----------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result codes check-------------------------------------
------------------Check of each resultCode + success (true, false)----------------------------
--Not applicable because CRQ tests OnHMIStatus notification
--Begin Test suit ResultCodesCheck
--End Test suit ResultCodesCheck

----------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------
----------------------------------------V TEST BLOCK------------------------------------------
------------------------------------ HMI negative cases---------------------------------------
----------------------------------incorrect data from HMI-------------------------------------
--Not applicable because CRQ tests OnHMIStatus notification
--Begin Test suit HMINegativeCases
--End Test suit HMINegativeCases

----------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------
----------------------------------------VI TEST BLOCK-----------------------------------------
--------------------------Sequence with emulating of user's action(s)-------------------------
----------------------------------------------------------------------------------------------
--Tests are implemented in VII TEST BLOCK: Different HMIStatus
--Begin Test suit EmulatingUserAction
--End Test suit EmulatingUserAction
----------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------
----------------------------------------VII TEST BLOCK----------------------------------------
-------------------------------------Different HMIStatus--------------------------------------
--processing of request/response in different HMIlevels, SystemContext, AudioStreamingState---
--Begin Test suit Different HMIStatus

--Precondition Test case DifferentHMIStatus.1
Test["TC02_Precondition_ActivationApp"] = function(self)
	
	--hmi side: sending SDL.ActivateApp request
	local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
	
	--hmi side: expect SDL.ActivateApp response
	EXPECT_HMIRESPONSE(RequestId)
	:Do(function(_,data)
		--In case when app is not allowed, it is needed to allow app
		if (data.result.isSDLAllowed ~= true) then
			
			--hmi side: sending SDL.GetUserFriendlyMessage request
			local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", 
			{language = "EN-US", messageCodes = {"DataConsent"}})
			
			--hmi side: expect SDL.GetUserFriendlyMessage response
			--TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
			EXPECT_HMIRESPONSE(RequestId)
			:Do(function(_,data)
				--hmi side: send request SDL.OnAllowSDLFunctionality
				self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", 
				{allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
				
				--hmi side: expect BasicCommunication.ActivateApp request
				EXPECT_HMICALL("BasicCommunication.ActivateApp")
				:Do(function(_,data)
					
					--hmi side: sending BasicCommunication.ActivateApp response
					self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
				end)
				:Times(AnyNumber())
			end)
		end
	end)
	
	--mobile side: expect notification
	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
	:Do(function(_,data)
		app_HMIlevel = data.payload.hmiLevel
		app_audioStreaming = data.payload.audioStreamingState
	end)
end

--Begin Test case DifferentHMIStatus.1
--Description: In case media app is (FULL, AUDIBLE) at activation of EMBEDDED_NAVI, SDL
--shall send OnHMIStatus(LIMITED and AUDIBLE)
--Requirement id in JIRA: APPLINK-20340
--Verification criteria:
--SDL must set media app to LIMITED and AUDIBLE due to active embedded navigation
Test["TC02_MediaApp_ActivateEmbeddedNAVI"] = function(self) 			
	userPrint(35,"======================================= Test Case 02 =============================================")
	
	if(app_HMIlevel ~= "FULL") then
		self:FailTestCase("Test can't be executed because hmiLevel is not FULL, real: " ..app_HMIlevel)
	elseif(app_audioStreaming ~= "AUDIBLE") then
		self:FailTestCase("Test can't be executed because audioStreamingState is not AUDIBLE, real: " ..app_audioStreaming)
	elseif( (app_HMIlevel == "FULL") and (app_audioStreaming == "AUDIBLE")) then
		
		--Send HMI notification
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive = true, eventName = "EMBEDDED_NAVI"})
		
		-- --Expect HMI notification OnAppDeactivated
		-- EXPECT_HMINOTIFICATION("BasicCommunication.OnAppDeactivated", { appID = self.applications[config.application1.registerAppInterfaceParams.appName] } )
		-- :Do(function(_,data) 
		
		--Expect mobile notification OnHMIStatus
		EXPECT_NOTIFICATION ("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})
		:Do(function(_,data)
			app_audioStreaming = data.payload.audioStreamingState
			app_HMIlevel = data.payload.hmiLevel
		end)
		-- end)					
	end 			
end
--End Test case DifferentHMIStatus.1

--Begin Test case DifferentHMIStatus.2
--Description: In case media app is (LIMITED, AUDIBLE) due to EMBEDDED_NAVI, SDL
--shall send correct audioStreamingState according to TTS.Started
--Requirement id in JIRA: APPLINK-20342
--Verification criteria:
--SDL must send OnHMINotification(LIMITED,ATTENUATED) in case receives TTS.Started
--and HMIStatus before that was (LIMITED, AUDIBLE)
Test["TC03_MediaApp_TTS_Started"] = function(self)
	userPrint(35,"======================================= Test Case 03 =============================================")
	
	if(app_HMIlevel ~= "LIMITED") then
		self:FailTestCase("Test can't be executed because hmiLevel is not LIMITED, real: " ..app_HMIlevel)
	elseif(app_audioStreaming ~= "AUDIBLE") then
		self:FailTestCase("Test can't be executed because audioStreamingState is not AUDIBLE, real: " ..app_audioStreaming)
	elseif( (app_HMIlevel == "LIMITED") and (app_audioStreaming == "AUDIBLE")) then
		
		--Send HMI notification
		self.hmiConnection:SendNotification("TTS.Started")
		
		--Expect mobile notification OnHMIStatus
		EXPECT_NOTIFICATION ("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "ATTENUATED"})
		:Do(function (_,data)
			app_audioStreaming = data.payload.audioStreamingState
			app_HMIlevel = data.payload.hmiLevel
		end)
	end
end
--End Test case DifferentHMIStatus.2

--Begin Test case DifferentHMIStatus.3
--Description: In case media app is (LIMITED, ATTENUATED) due to EMBEDDED_NAVI, SDL
--shall send correct audioStreamingState according to TTS.Stopped
--Requirement id in JIRA: APPLINK-20342
--Verification criteria:
--SDL must send OnHMINotification(LIMITED,AUDIBLE) in case receives TTS.Stopped
-- and HMIStatus before that was (LIMITED, ATTENUATED)
Test["TC04_MediaApp_TTS_Stopped"] = function(self)
	userPrint(35,"======================================= Test Case 04 =============================================")
	
	if(app_HMIlevel ~= "LIMITED") then
		self:FailTestCase("Test can't be executed because hmiLevel is not LIMITED, real: " ..app_HMIlevel)
	elseif(app_audioStreaming ~= "ATTENUATED") then
		self:FailTestCase("Test can't be executed because audioStreamingState is not ATTENUATED, real: " ..app_audioStreaming)
	else
		
		local time_TTS_Stopped = timestamp()
		
		--Send HMI notification
		self.hmiConnection:SendNotification("TTS.Stopped")
		
		--Expect mobile notification OnHMIStatus
		EXPECT_NOTIFICATION ("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})
		:Do(function (_,data)
			local time_OnHMIStatus = timestamp()
			
			userPrint(33, "Mobile receives OnHMIStatus = {systemContext = \"MAIN\", hmiLevel = \"LIMITED\", audioStreamingState = \"AUDIBLE\"} after "..(time_OnHMIStatus - time_TTS_Stopped) .. " milliseconds since HMI sends TTS.Stopped() to SDL")
			
			app_audioStreaming = data.payload.audioStreamingState
			app_HMIlevel = data.payload.hmiLevel
		end)
	end
end
--End Test case DifferentHMIStatus.3

--Begin Test case DifferentHMIStatus.4
--Description: In case media app is (LIMITED, AUDIBLE) due to EMBEDDED_NAVI after receiving TTS.Started -> TTS.Stopped, 
-- SDL shall set app to (FULL, AUDIBLE) in case receives SDL.ActivateApp from HMI(user activates media app)
--Requirement id in JIRA: APPLINK-20341
--Verification criteria: 
--SDL must send OnHMIStatus(FULL, AUDIBLE) in case user activates media app
Test["TC05_MediaApp_UserActivateApp"] = function(self)
	userPrint(35,"======================================= Test Case 05 =============================================")
	
	if(app_HMIlevel ~= "LIMITED") then
		self:FailTestCase("Test can't be executed because hmiLevel is not LIMITED, real: " ..app_HMIlevel)
	elseif(app_audioStreaming ~= "AUDIBLE") then
		self:FailTestCase("Test can't be executed because audioStreamingState is not AUDIBLE, real: " ..app_audioStreaming)
	else
		
		--Send HMI request SDL.ActivateApp
		local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
		
		-- Expect HMI response
		EXPECT_HMIRESPONSE(RequestId, {result = {code = 0, method = "SDL.ActivateApp"}})
		
		
		EXPECT_NOTIFICATION ("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})
		:Do(function (_,data)
			app_audioStreaming = data.payload.audioStreamingState
			app_HMIlevel = data.payload.hmiLevel
		end)
		
		
		
	end
end
--End Test case DifferentHMIStatus.4

--Precondition Test case DifferentHMIStatus.5
Test["TC06_Precondition_UserActivateApp_NoTTS"] = function(self)
	userPrint(35,"======================================= Precondition TC06 =============================================")
	
	if(app_HMIlevel ~= "FULL") then
		self:FailTestCase("Test can't be executed because hmiLevel is not FULL, real: " ..app_HMIlevel)
	elseif(app_audioStreaming ~= "AUDIBLE") then
		self:FailTestCase("Test can't be executed because audioStreamingState is not AUDIBLE, real: " ..app_audioStreaming)
	else
		
		--Send HMI notification
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive = true, eventName = "EMBEDDED_NAVI"})
		
		-- --Expect HMI notification OnAppDeactivated
		-- EXPECT_HMINOTIFICATION("BasicCommunication.OnAppDeactivated", { appID = self.applications[config.application1.registerAppInterfaceParams.appName] } )
		-- :Do(function(_,data) 
		
		--Expect mobile notification OnHMIStatus
		EXPECT_NOTIFICATION ("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})
		:Do(function(_,data)
			app_audioStreaming = data.payload.audioStreamingState
			app_HMIlevel = data.payload.hmiLevel
		end)
		-- end)					
	end 		
end

--Begin Test case DifferentHMIStatus.5
--Description: In case media app is (LIMITED, AUDIBLE) without receiving TTS.Started -> TTS.Stopped, SDL
--shall set app to (FULL, AUDIBLE) in case receives SDL.ActivateApp from HMI(user activates media app)
--Requirement id in JIRA: APPLINK-20341
--Verification criteria: 
--SDL must send OnHMIStatus(FULL, AUDIBLE) in case user activates media app
Test["TC06_UserActivateApp_NoTTS"] = function(self)
	userPrint(35,"======================================= Test Case 06 =============================================")
	
	if(app_HMIlevel ~= "LIMITED") then
		self:FailTestCase("Test can't be executed because hmiLevel is not LIMITED, real: " ..app_HMIlevel)
	elseif(app_audioStreaming ~= "AUDIBLE") then
		self:FailTestCase("Test can't be executed because audioStreamingState is not AUDIBLE, real: " ..app_audioStreaming)
	else
		
		--Send HMI request SDL.ActivateApp
		local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
		
		-- Expect HMI response
		EXPECT_HMIRESPONSE(RequestId, {result = {code = 0, method = "SDL.ActivateApp"}})
		
		EXPECT_NOTIFICATION ("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})
		:Do(function (_,data)
			app_audioStreaming = data.payload.audioStreamingState
			app_HMIlevel = data.payload.hmiLevel
		end)
		
	end
end

--End Test case DifferentHMIStatus.5

--Precondition Test case DifferentHMIStatus.6
Test["TC07_Precondition_UserActivateApp_EmbeddedAudio_FULL"] = function(self)
	userPrint(35,"======================================= Precondition TC07 =============================================")
	
	if(app_HMIlevel ~= "FULL") then
		self:FailTestCase("Test can't be executed because hmiLevel is not FULL, real: " ..app_HMIlevel)
	elseif(app_audioStreaming ~= "AUDIBLE") then
		self:FailTestCase("Test can't be executed because audioStreamingState is not AUDIBLE, real: " ..app_audioStreaming)
	else
		
		--Send HMI notification
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive = true, eventName = "AUDIO_SOURCE"})
		
		--Expect mobile notification OnHMIStatus
		EXPECT_NOTIFICATION ("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})
		:Do(function(_,data)
			app_audioStreaming = data.payload.audioStreamingState
			app_HMIlevel = data.payload.hmiLevel
		end)
	end 	
end

--Begin Test case DifferentHMIStatus.6
--Description: In case media app is (BACKGROUND, NOT_AUDIBLE) due to embedded audio, SDL
--shall set app to (FULL, AUDIBLE) in case receives BC.OnEventChanged(isActive = false)
--Requirement id in JIRA: APPLINK-20338
--Verification criteria:
--SDL must send OnHMIStatus(FULL, AUDIBLE) in case user activates media app
Test["TC07_UserActivateApp_EmbeddedAudio_FULL"] = function(self)
	userPrint(35,"======================================= Test Case 07 =============================================")
	
	if(app_HMIlevel ~= "BACKGROUND") then
		self:FailTestCase("Test can't be executed because hmiLevel is not BACKGROUND, real: " ..app_HMIlevel)
	elseif(app_audioStreaming ~= "NOT_AUDIBLE") then
		self:FailTestCase("Test can't be executed because audioStreamingState is not NOT_AUDIBLE, real: " ..app_audioStreaming)
	else
		
		--Send HMI notification
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive = false, eventName = "AUDIO_SOURCE"})
		
		--Send HMI request SDL.ActivateApp
		local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
		
		-- Expect HMI response
		EXPECT_HMIRESPONSE(RequestId, {result = {code = 0, method = "SDL.ActivateApp"}})						
		
		
		--Expect mobile notification OnHMIStatus
		EXPECT_NOTIFICATION ("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})
		:Do(function (_,data)
			app_audioStreaming = data.payload.audioStreamingState
			app_HMIlevel = data.payload.hmiLevel
		end)						
		
	end
end
--End Test case DifferentHMIStatus.6

--Precondition Test case DifferentHMIStatus.7
Test["TC08_Precondition_UserActivateApp_EmbeddedAudio_LIMITED"] = function(self)
	userPrint(35,"======================================= Precondition TC08 =============================================")
	
	if(app_HMIlevel ~= "FULL") then
		self:FailTestCase("Test can't be executed because hmiLevel is not FULL, real: " ..app_HMIlevel)
	elseif(app_audioStreaming ~= "AUDIBLE") then
		self:FailTestCase("Test can't be executed because audioStreamingState is not AUDIBLE, real: " ..app_audioStreaming)
	else
		
		--Send HMI notification
		self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
		
		--Expect mobile notification OnHMIStatus
		EXPECT_NOTIFICATION ("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"},
		{systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})
		:Do(function(_,data)
			
			--Send HMI notification
			self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive = true, eventName = "AUDIO_SOURCE"})
			
			app_audioStreaming = data.payload.audioStreamingState
			app_HMIlevel = data.payload.hmiLevel
		end)
		:Times(2)
		
	end 	
end

--Begin Test case DifferentHMIStatus.7
--Description: In case media app is (BACKGROUND, NOT_AUDIBLE) due to embeded audio, SDL
--shall set app to (FULL, AUDIBLE) in case receives BC.OnEventChanged(isActive = false)
--Requirement id in JIRA: APPLINK-20338
--Verification criteria:
--SDL must send OnHMIStatus(FULL, AUDIBLE) in case user activates media app
Test["TC08_UserActivateApp_EmbeddedAudio_LIMITED"] = function(self)
	userPrint(35,"======================================= Test Case 08 =============================================")
	
	if(app_HMIlevel ~= "BACKGROUND") then
		self:FailTestCase("Test can't be executed because hmiLevel is not BACKGROUND, real: " ..app_HMIlevel)
	elseif(app_audioStreaming ~= "NOT_AUDIBLE") then
		self:FailTestCase("Test can't be executed because audioStreamingState is not NOT_AUDIBLE, real: " ..app_audioStreaming)
	else
		
		--Send HMI notification
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive = false, eventName = "AUDIO_SOURCE"})
		
		--Send HMI request SDL.ActivateApp
		local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
		
		-- Expect HMI response
		EXPECT_HMIRESPONSE(RequestId, {result = {code = 0, method = "SDL.ActivateApp"}})						
		
		--Expect mobile notification OnHMIStatus
		EXPECT_NOTIFICATION ("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})
		:Do(function (_,data)
			app_audioStreaming = data.payload.audioStreamingState
			app_HMIlevel = data.payload.hmiLevel
		end)
		
		
	end
end
--End Test case DifferentHMIStatus.7

--End Test suit Different HMIStatus
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
-------------------------------------------Postconditions------------------------------------
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------

return Test