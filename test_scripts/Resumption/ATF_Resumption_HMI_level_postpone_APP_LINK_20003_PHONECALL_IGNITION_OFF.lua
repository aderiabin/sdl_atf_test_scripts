---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonFunctionsForCRQ20003 = require('user_modules/shared_testcases/commonFunctionsForCRQ20003')
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--------------------------------------------------------------------------------
--Precondition: preparation connecttest_resumption.lua
commonPreconditions:Connecttest_without_ExitBySDLDisconnect("connecttest_resumption.lua")

commonPreconditions:Connecttest_adding_timeOnReady("connecttest_resumption.lua")

Test = require('user_modules/connecttest_resumption')
require('cardinalities')
local mobile_session = require('mobile_session')
require('user_modules/AppTypes')

local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

local test_data ={
		{app="NAVIGATION",				appType ={"NAVIGATION"},	isMedia=false,	hmiLevel="FULL", 	audioStreamingState="AUDIBLE"},
		{app="MEDIA",					appType ={"MEDIA"},			isMedia=true,	hmiLevel="FULL", 	audioStreamingState="AUDIBLE"},
		{app="COMMUNICATION",			appType ={"COMMUNICATION"}, isMedia=false,	hmiLevel="FULL", 	audioStreamingState="AUDIBLE"},
		{app="NON MEDIA",				appType ={"DEFAULT"}, 		isMedia=false,	hmiLevel="FULL", 	audioStreamingState="NOT_AUDIBLE"}
	}
local hmi_level_FULL = "FULL"
local hmi_level_LIMITED = "LIMITED"

function Test:Postcondition_remove_user_connecttest()
  os.execute( "rm -f ./user_modules/connecttest_resumption.lua" )
end

--Precondition: backup smartDeviceLink.ini
commonPreconditions:BackupFile("smartDeviceLink.ini")

-- set ApplicationResumingTimeout in .ini file to resuming_timeout;
local resuming_timeout = 5000
commonFunctions:SetValuesInIniFile("%p?ApplicationResumingTimeout%s?=%s-[%d]-%s-\n", "ApplicationResumingTimeout", resuming_timeout)
config.defaultProtocolVersion = 2

local HMIAppID

local DefaulthmiLevel = "NONE"
local notificationState = {VRSession = false, EmergencyEvent = false, PhoneCall = false, DeactivateHMI = false}

local AppValuesOnHMIStatusFULL ={hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}
local AppValuesOnHMIStatusLIMITED ={hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}

local function userPrint( color, message)
  print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
end

function Test:precondition_AddNewSession3(TestCaseName)
	local TCName
	if TestCaseName ==nil then
		TCName = "Precondition_Add_New_Session"
	else
		TCName = TestCaseName
	end
	
	Test[TCName] = function(self)
	
	  -- Connected expectation
		self.mobileSession3 = mobile_session.MobileSession(self,self.mobileConnection)		
		self.mobileSession3:StartService(7)
	end	
end	

function Test:precondition_AddNewSession4(TestCaseName)
	local TCName
	if TestCaseName ==nil then
		TCName = "Precondition_Add_New_Session"
	else
		TCName = TestCaseName
	end
	
	Test[TCName] = function(self)
	
	  -- Connected expectation
		self.mobileSession4 = mobile_session.MobileSession(self,self.mobileConnection)		
		self.mobileSession4:StartService(7)
	end	
end	

local function IGNITION_OFF(self, appNumber)

  StopSDL()

	if appNumber == nil then 
		appNumber = 1
	end

	-- hmi side: sends OnExitAllApplications (SUSPENDED)
	self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
		{
		  reason = "IGNITION_OFF"
		})

	-- hmi side: expect OnSDLClose notification
	--EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")

	-- hmi side: expect OnAppUnregistered notification
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
	:Times(appNumber)
end

local function RegisterAppThenIgnitionOff(self, prefix, level)

	if level == nil then
		level = "FULL"
	end		
	--userPrint(35, "================= IGNITION_OFF ==================")	
	commonSteps:UnregisterApplication(tostring(prefix).."_Unregister_App")
		
	commonSteps:RegisterAppInterface(tostring(prefix).."_Register_App")
		
	commonSteps:ActivationApp(_,tostring(prefix).."_Activation_App")			

	if(level=="LIMITED") then
		commonSteps:ChangeHMIToLimited(tostring(prefix).."_Change_App_To_Limited")
	end
	
	Test[tostring(prefix).."_IGNITION_OFF"] = function(self)
		IGNITION_OFF(self)
	end
end

local function RegisterAppThenCloseSession(self, prefix, level)

	if level == nil then
		level = "FULL"
	end		
	--userPrint(35, "================= IGNITION_OFF ==================")	
	commonSteps:UnregisterApplication(tostring(prefix).."_Unregister_App")
		
	-- Test[tostring(prefix).."_Close_Session"] = function(self)   
		-- RegisterApp(self,prefix)
	-- end
	commonSteps:RegisterAppInterface(tostring(prefix).."_Register_App")
		
	commonSteps:ActivationApp(_,tostring(prefix).."_Activation_App")			
		
	Test[tostring(prefix).."_Close_Session"] = function(self)   
		local appIDSession= self.applications[config.application1.registerAppInterfaceParams.appName]		
		self.mobileSession:Stop()
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = appIDSession})		
	end
end

local function StartSDLThenConnectSession(self, prefix, level)
	
	Test[tostring(prefix).."_StartSDL"] = function(self)
		userPrint(35, "================= IGNITION_ON ==================")
		StartSDL(config.pathToSDL, config.ExitOnCrash)
	end

	Test[tostring(prefix).."_InitHMI"] = function(self)
		self:initHMI()
	end

	Test[tostring(prefix).."_InitHMI_onReady"] = function(self)
		self:initHMI_onReady()
	end

	Test[tostring(prefix).."_ConnectMobile"] = function(self)
		self:connectMobile()
	end

	Test[tostring(prefix).."_StartSession"] = function(self)
		 self.mobileSession = mobile_session.MobileSession(
			self,
			self.mobileConnection,
			config.application1.registerAppInterfaceParams)
	end
end

local function StartSDLThenConnect4Session(self)
	
	Test["StartSDL"] = function(self)
		userPrint(35, "================= IGNITION_ON ==================")
		StartSDL(config.pathToSDL, config.ExitOnCrash)
	end

	Test["InitHMI"] = function(self)
		self:initHMI()
	end

	Test["InitHMI_onReady"] = function(self)
		self:initHMI_onReady()
	end

	Test["ConnectMobile"] = function(self)
		self:connectMobile()
	end
		
	Test["StartSession"] = function(self)
		
		 self.mobileSession = mobile_session.MobileSession(
			self,
			self.mobileConnection,
			config.application1.registerAppInterfaceParams)
			
		self.mobileSession2 = mobile_session.MobileSession(
			self,
			self.mobileConnection,
			appId2)
			
		self.mobileSession3 = mobile_session.MobileSession(
			self,
			self.mobileConnection,
			appId3)
			
		self.mobileSession4 = mobile_session.MobileSession(
			self,
			self.mobileConnection,
			appId4)
	end
	
end

local function CloseSession_Start4Session(self, appType)

	Test["Close_Session"] = function(self)   		
		self.mobileSession:Stop()
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = appId1})
		
		
		self.mobileSession2:Stop()
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = appId2})
		
		local appIDSession3= self.applications[appId3]		
		self.mobileSession3:Stop()
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = appId3})
		
		local appIDSession4= self.applications[appId4]		
		self.mobileSession4:Stop()
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = appId4})
		end

	Test["StartSession"] = function(self)
		
		 self.mobileSession = mobile_session.MobileSession(
			self,
			self.mobileConnection,
			config.application1.registerAppInterfaceParams)
			
		self.mobileSession2 = mobile_session.MobileSession(
			self,
			self.mobileConnection,
			appId2)
			
		self.mobileSession3 = mobile_session.MobileSession(
			self,
			self.mobileConnection,
			appId3)
			
		self.mobileSession4 = mobile_session.MobileSession(
			self,
			self.mobileConnection,
			appId4)
	end

end

local function CloseSession_StartSession(self, appType)

	Test[appType.."_Close_Session"] = function(self)   
		local appIDSession= self.applications[config.application1.registerAppInterfaceParams.appName]		
		self.mobileSession:Stop()
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = appIDSession})
		end

	Test[appType .."_Start_Session"]= function(self)
			self.mobileSession = mobile_session.MobileSession(
			self,self.mobileConnection,config.application1.registerAppInterfaceParams)
	end

end

function Test:change_App_Params(app,appType,isMedia)
 
	local session

	if app==1 then
		session = config.application1.registerAppInterfaceParams				
		if appType == {"DEFAULT"} then			
			AppValuesOnHMIStatusFULL = {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"}			
		else 
			AppValuesOnHMIStatusFULL = {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}
		end		
	end
	
	session.isMediaApplication = isMedia

	if appType=={""} then
		session.appHMIType = nil
	else
		session.appHMIType = appType
	end
end

function Test:phoneCallIsActiveAndRegisterApp(pos)

		userPrint(34, "=================== Test Case ===================")
		
		if (pos==1) then -- Phone call is active before register app
			self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
			notificationState.PhoneCall = true
		end
		
		self.mobileSession:StartService(7)
		:Do(function(_,data)
			local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)    

			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
			:Do(function(_,data)
          --HMIAppID = data.params.application.appID
				self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
			end)

			self.mobileSession:ExpectResponse(correlationId, { success = true })
			
			if (pos==2) then --Phone call is active after register app
			commonTestCases:DelayedExp(1000)
			self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
			notificationState.PhoneCall = true
			end
			
			--delay 10 seconds
			commonTestCases:DelayedExp(10000)
			
			--check resumption can't start
			EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" })
		end)

end

function Test:phoneCallIsActive()
		userPrint(34, "=================== Test Case ===================")
		
		
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
		notificationState.PhoneCall = true		
end

function Test:resumptionSuccessWhenPhoneCallEnded(level)
			--Phone call ended
			self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
			notificationState.PhoneCall = false
			
			if level=="FULL" then
				EXPECT_HMICALL("BasicCommunication.ActivateApp")
				:Do(function(_,data)
				  --hmi side: sending BasicCommunication.ActivateApp response
					  self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
				end)
									
				EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)
				
		    elseif level=="LIMITED" then			
				EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusLIMITED)
			end
end

function Test:resumptionSuccessWhenPhoneCallEnded4Apps()
	--Phone call ended
	self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
	notificationState.PhoneCall = false
	
	
	EXPECT_HMICALL("BasicCommunication.ActivateApp")
	:Do(function(_,data)
	  --hmi side: sending BasicCommunication.ActivateApp response
		  self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
	end)
	
	self.mobileSession4:ExpectNotification("OnHMIStatus",{hmiLevel="FULL",systemContext="MAIN",audioStreamingState="AUDIBLE"})
	self.mobileSession3:ExpectNotification("OnHMIStatus",{hmiLevel="LIMITED",systemContext="MAIN",audioStreamingState="AUDIBLE"})
	self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel="LIMITED",systemContext="MAIN",audioStreamingState="AUDIBLE"})
end

function Test:resumptionSuccessWhenPhoneCallEnded4Apps_2()
	--Phone call ended
	self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="PHONE_CALL"})
	notificationState.PhoneCall = false
	
	
	EXPECT_HMICALL("BasicCommunication.ActivateApp")
	:Do(function(_,data)
	  --hmi side: sending BasicCommunication.ActivateApp response
		  self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
	end)
	
	self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel="FULL",systemContext="MAIN",audioStreamingState="NOT_AUDIBLE"})
	self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel="LIMITED",systemContext="MAIN",audioStreamingState="AUDIBLE"})
	self.mobileSession3:ExpectNotification("OnHMIStatus",{hmiLevel="LIMITED",systemContext="MAIN",audioStreamingState="AUDIBLE"})
	self.mobileSession4:ExpectNotification("OnHMIStatus",{hmiLevel="LIMITED",systemContext="MAIN",audioStreamingState="AUDIBLE"})
end

function Test:resumptionUnsuccessWhenPhoneCallWithIsActiveInvalid4Apps()
			--For isActive is Invalid
			isActiveValue = {{isActive="", eventName="PHONE_CALL"}, {isActive= 123, eventName="PHONE_CALL"}, {eventName="PHONE_CALL"}}
			testCaseName ={"IsActiveEmpty", "IsActiveWrongType", "IsActiveMissed"}
						
			for i=1, #isActiveValue do
				Test["Resumption_MultiApps_HMIlevelFULL_PhoneCallIsActive_After_AppIsConnected_"..testCaseName[i]] = function(self)
					self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",isActiveValue[i])
									
				EXPECT_HMICALL("BasicCommunication.ActivateApp"):Times(0)
				--delay 10 seconds
				--commonTestCases:DelayedExp(6000)
			
				--check resumption can't start
				self.mobileSession4:ExpectNotification("OnHMIStatus"):Times(0)	
				self.mobileSession3:ExpectNotification("OnHMIStatus"):Times(0)	
				self.mobileSession2:ExpectNotification("OnHMIStatus"):Times(0)	
				self.mobileSession:ExpectNotification("OnHMIStatus"):Times(0)	
				end
			end			
end

function Test:resumptionUnsuccessWhenPhoneCallWithIsActiveInvalid(appType,level)
			--For isActive is Invalid
			isActiveValue = {{isActive= "", eventName="PHONE_CALL"}, {isActive= 123, eventName="PHONE_CALL"}, {eventName="PHONE_CALL"}}
			testCaseName ={"IsActiveEmpty", "IsActiveWrongType", "IsActiveMissed"}
						
			for i=1, #isActiveValue do
				Test[appType .."_Resumption_SingleApp_HMIlevel"..level.."_PhoneCallIsActive_After_AppIsConnected_"..testCaseName[i]] = function(self)
					self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",isActiveValue[i])
									
				EXPECT_HMICALL("BasicCommunication.ActivateApp"):Times(0)
				--delay 10 seconds
				commonTestCases:DelayedExp(10000)
			
				--check resumption can't start
				EXPECT_NOTIFICATION("OnHMIStatus"):Times(0)		
				end
			end
end

function Test:noneMedia_ResumptionSuccessWithoutPhoneCallEnded(pos)
	userPrint(34, "=================== Test Case ===================")
	if (pos==1) then --if phone call is active before register app
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
		notificationState.PhoneCall = true
	end

	self.mobileSession:StartService(7)
	:Do(function(_,data)
	local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)    

	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
	:Do(function(_,data)
	--HMIAppID = data.params.application.appID
		self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
	end)

	self.mobileSession:ExpectResponse(correlationId, { success = true })
	
	if (pos==2) then --if phone call is active after register app
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="PHONE_CALL"})
		notificationState.PhoneCall = true
	end
	
	EXPECT_HMICALL("BasicCommunication.ActivateApp")
		:Do(function(_,data)
		  --hmi side: sending BasicCommunication.ActivateApp response
			  self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
		end)
		
	commonTestCases:DelayedExp(resuming_timeout)
	
	if (level==hmi_level_FULL) then				
		EXPECT_NOTIFICATION("OnHMIStatus", 
		{hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
		{hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" })
		:Times(2)		
	elseif (level==hmi_level_LIMITED) then	
		EXPECT_NOTIFICATION("OnHMIStatus",
		{hmiLevel = DefaultHMILevel, systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" },
		{hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" })
		:Times(2)
	end				
	end)    
end

function Test:registerTheFirstApp(appType)		
	
	Test["Register_The_First_App"]  = function(self)
		
		--mobile side: RegisterAppInterface request 
		local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
													{
														syncMsgVersion = 
														{ 
															majorVersion = 3,
															minorVersion = 2,
														}, 
														appName ="SPT1",
														isMediaApplication = false,
														languageDesired ="EN-US",
														hmiDisplayLanguageDesired ="EN-US",
														appID ="1",														
														appHMIType = {"DEFAULT"}
					
													}) 
	 
		--hmi side: expect BasicCommunication.OnAppRegistered request
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
		{
			application = 
			{
				appName = "SPT1"
			}
		})
		:Do(function(_,data)
			appId1 = data.params.application.appID
		end)
		
		--mobile side: RegisterAppInterface response 
		self.mobileSession:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
		self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	end
end

function Test:registerTheSecondApp(appType)		
	
	Test["Register_The_Second_App"]  = function(self)
		
		--mobile side: RegisterAppInterface request 
		local CorIdRAI = self.mobileSession2:SendRPC("RegisterAppInterface",
													{
														syncMsgVersion = 
														{ 
															majorVersion = 4,
															minorVersion = 2,
														}, 
														appName ="SPT2",
														isMediaApplication = false,
														languageDesired ="EN-US",
														hmiDisplayLanguageDesired ="EN-US",
														appID ="2",														
														appHMIType = {appType}
					
													}) 
	 
		--hmi side: expect BasicCommunication.OnAppRegistered request
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
		{
			application = 
			{
				appName = "SPT2"
			}
		})
		:Do(function(_,data)
			appId2 = data.params.application.appID
		end)
		
		--mobile side: RegisterAppInterface response 
		self.mobileSession2:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})


		self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	end
end

function Test:registerTheThirdApp(appType)		
	
	Test["Register_The_Third_App"]  = function(self)

		--mobile side: RegisterAppInterface request 
		local CorIdRAI = self.mobileSession3:SendRPC("RegisterAppInterface",
													{
														syncMsgVersion = 
														{ 
															majorVersion = 4,
															minorVersion = 2,
														}, 
														appName ="SPT3",
														isMediaApplication = true,
														languageDesired ="EN-US",
														hmiDisplayLanguageDesired ="EN-US",
														appID ="3",														
														appHMIType = {appType}
					
													}) 
	 
		--hmi side: expect BasicCommunication.OnAppRegistered request
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
		{
			application = 
			{
				appName = "SPT3"
			}
		})
		:Do(function(_,data)
			appId3 = data.params.application.appID
		end)
		
		--mobile side: RegisterAppInterface response 
		self.mobileSession3:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
		self.mobileSession3:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	end
end

function Test:registerTheFourthApp(appType)		
	
	Test["Register_The_Fourth_App"]  = function(self)

		--mobile side: RegisterAppInterface request 
		local CorIdRAI = self.mobileSession4:SendRPC("RegisterAppInterface",
													{
														syncMsgVersion = 
														{ 
															majorVersion = 4,
															minorVersion = 2,
														}, 
														appName ="SPT4",
														isMediaApplication = false,
														languageDesired ="EN-US",
														hmiDisplayLanguageDesired ="EN-US",
														appID ="4",														
														appHMIType = {appType}
					
													}) 
	 
		--hmi side: expect BasicCommunication.OnAppRegistered request
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
		{
			application = 
			{
				appName = "SPT4"
			}
		})
		:Do(function(_,data)
			appId4 = data.params.application.appID
		end)
		
		--mobile side: RegisterAppInterface response 
		self.mobileSession4:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})			
		self.mobileSession4:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	end
end

function Test:registerTheFifthApp(appType)		
	
	Test["Register_The_Fifth_App"]  = function(self)
		
		--mobile side: RegisterAppInterface request 
		local CorIdRAI = self.mobileSession5:SendRPC("RegisterAppInterface",
													{
														syncMsgVersion = 
														{ 
															majorVersion = 4,
															minorVersion = 2,
														}, 
														appName ="SPT5",
														isMediaApplication = false,
														languageDesired ="EN-US",
														hmiDisplayLanguageDesired ="EN-US",
														appID ="5",														
														appHMIType = {appType}
					
													}) 
	 
		--hmi side: expect BasicCommunication.OnAppRegistered request
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
		{
			application = 
			{
				appName = "SPT5"
			}
		})
		:Do(function(_,data)
			appId5 = data.params.application.appID
		end)
		
		--mobile side: RegisterAppInterface response 
		self.mobileSession5:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})


		self.mobileSession5:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	end
end

function Test:activateTheFirstApp()		
	
	Test["Activate_The_First_App"]  = function(self)

		local deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
	
		--HMI send ActivateApp request			
		local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = appId1})
		EXPECT_HMIRESPONSE(RequestId)
		:Do(function(_,data)

			if data.result.isSDLAllowed ~= true then
				local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
				EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
				:Do(function(_,data)
					--hmi side: send request SDL.OnAllowSDLFunctionality
					self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = deviceMAC, name = "127.0.0.1"}})
				end)

				EXPECT_HMICALL("BasicCommunication.ActivateApp")
				:Do(function(_,data)
					self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
				end)
				:Times(AnyNumber())
			else
				self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
			end
		end)

		self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}) 
		
	end	
end

function Test:activateTheSecondApp()		
	
	Test["Activate_The_Second_App"]  = function(self)

		local deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
	
		--HMI send ActivateApp request			
		local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = appId2})
		EXPECT_HMIRESPONSE(RequestId)
		:Do(function(_,data)

			if data.result.isSDLAllowed ~= true then
				local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
				EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
				:Do(function(_,data)
					--hmi side: send request SDL.OnAllowSDLFunctionality
					self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = deviceMAC, name = "127.0.0.1"}})
				end)

				EXPECT_HMICALL("BasicCommunication.ActivateApp")
				:Do(function(_,data)
					self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
				end)
				:Times(AnyNumber())
			else
				self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
			end
		end)

		-- self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 
		
		-- self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}) 
	end	
end

function Test:activateTheThirdApp()		
	
	Test["Activate_The_Third_App"]  = function(self)

		local deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
	
		--HMI send ActivateApp request			
		local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = appId3})
		EXPECT_HMIRESPONSE(RequestId)
		:Do(function(_,data)

			if data.result.isSDLAllowed ~= true then
				local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
				EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
				:Do(function(_,data)
					--hmi side: send request SDL.OnAllowSDLFunctionality
					self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = deviceMAC, name = "127.0.0.1"}})
				end)

				EXPECT_HMICALL("BasicCommunication.ActivateApp")
				:Do(function(_,data)
					self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
				end)
				:Times(AnyNumber())
			else
				self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
			end
		end)

		-- self.mobileSession3:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 
		-- --:Timeout(2000)
		
		-- self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		
		-- --:Timeout(2000)
		-- self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
		-- :Times(0)
	
	end
end

function Test:activateTheFourthApp()		
	
	Test["Activate_The_Fourth_App"]  = function(self)
		
		--commonTestCases:DelayedExp(3000)
		
		local deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
	
		--HMI send ActivateApp request			
		local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = appId4})
		EXPECT_HMIRESPONSE(RequestId)
		:Do(function(_,data)

			if data.result.isSDLAllowed ~= true then
				local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
				EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
				:Do(function(_,data)
					--hmi side: send request SDL.OnAllowSDLFunctionality
					self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = deviceMAC, name = "127.0.0.1"}})
				end)

				EXPECT_HMICALL("BasicCommunication.ActivateApp")
				:Do(function(_,data)
					self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
				end)
				:Times(AnyNumber())
			else
				self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
			end
		end)

		-- self.mobileSession4:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}) 		
		
		-- self.mobileSession3:ExpectNotification("OnHMIStatus", {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		
		-- self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		-- :Times(0)
				
		-- self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}) 
		-- :Times(0)
	
	end
end

local function Register4Apps_Full_Limited_Limited_Background()

	-- precondition: 		
		commonSteps:UnregisterApplication("Unregister_App")		
			
		-------App1		
		Test:registerTheFirstApp(test_data[4].app)
		Test:activateTheFirstApp()
		
		-------App2
		commonSteps:precondition_AddNewSession("AddNewSession")	
		Test:registerTheSecondApp(test_data[3].app)
		Test:activateTheSecondApp()
		-------App3
		Test:precondition_AddNewSession3("AddNewSession")
		Test:registerTheThirdApp(test_data[2].app)
		Test:activateTheThirdApp()
		
		-------App4
		Test:precondition_AddNewSession4("AddNewSession")
		Test:registerTheFourthApp(test_data[1].app)
		Test:activateTheFourthApp()	
		
end

local function PhoneCall_IsActive_And_Register4Apps(pos)
	if (pos==1) then
		Test["Phone_Call_Is_Active_Before_Register_App"] = function(self)				
			self:phoneCallIsActive()
		end
	end
		
	-------App1
	Test["StartService_App1"] = function(self)
	
	self.mobileSession:StartService(7)
	end
	Test:registerTheFirstApp(test_data[4].app)
	
	-------App2
	Test["StartService_App2"] = function(self)
	self.mobileSession2:StartService(7)
	end
	Test:registerTheSecondApp(test_data[3].app)
	
	-------App3
	Test["StartService_App3"] = function(self)

		
	self.mobileSession3:StartService(7)
	end
	Test:registerTheThirdApp(test_data[2].app)
	
	-------App4
	Test["StartService_App3"] = function(self)		
	self.mobileSession4:StartService(7)
	end
	Test:registerTheFourthApp(test_data[1].app)
		
	if (pos==2) then
		Test["Phone_Call_Is_Active_After_Register_App"] = function(self)				
			self:phoneCallIsActive()
		end
	end
		
end

--////////////////////////////////////////////////////////////////////////////////////////////--
--APPLINK-16184-16284: PHONE CALL IS ACTIVE BEFORE OR AFTER APP IS CONNECTED
--CHECK WITH SINGLE APP
--////////////////////////////////////////////////////////////////////////////////////////////--
--------------------------------------------------------------------------------
-- Case: Resumption_HMIlevelFULL_PhoneCallTrue_Before_App_Is_Connected
-- Step1: Change App Type
-- Step2: Register/Activate app
-- Step3: IGNITION_OFF
-- Step4: Start SDL
-- Step5: PHONE_CALL.Start
-- Step6: Register App
-- Step7: In case App is None MEDIA: Resumtion success without waiting PHONE_CALL.End
-- Step8: Resumption postpone
-- Step9: PHONE_CALL.End
-- Step10: Resumption success
---------------------------------------------------------------------------------
-- local function ResumptionSingleAppFULL_PhoneCallIsActiveBeforeAppIsConnected_IGNITION_OFF()		
	-- for i =1, #test_data do
		-- commonFunctions:newTestCasesGroup("Single App (FULL) - Next IGNITION cycle: Phone call is active BEFORE app is connected and waiting for resume: " ..test_data[i].app)
		-- --Precondition:Unregister/Register/Activate App
		-- commonSteps:UnregisterApplication(test_data[i].app.."_Unregister_App")				
		-- commonFunctionsForCRQ20003:RegisterTheFirstApp(test_data[i].appType, test_data[i].isMedia,test_data[i].app.."_Register_App")
		-- commonFunctionsForCRQ20003:ActivateTheFirstApp(test_data[i].app.."_Activate_App")	

		-- --IGNITION_OFF
		-- commonFunctionsForCRQ20003:IgnitionOff(1,test_data[i].app.."_IGNITION_OFF")
				
		-- --StartSDL -IGNITION_ON
		-- commonFunctionsForCRQ20003:StartSDL(test_data[i].app)	
		
		-- --PHONE_CALL is true before app is connected
		-- commonFunctionsForCRQ20003:PhoneCallIsTrue(test_data[i].app.."_Phone_Call_Is_True")
		
		-- commonFunctionsForCRQ20003:StartService1(test_data[i].app.."_Start_Service")
		-- commonFunctionsForCRQ20003:RegisterTheFirstApp(test_data[i].appType, test_data[i].isMedia,test_data[i].app.."_Register_App")
				
		-- if test_data[i].app == "NON MEDIA" then
			-- commonFunctionsForCRQ20003:NoneMedia_ResumptionSuccessWithoutPhoneCallEnded()			
			-- commonFunctionsForCRQ20003:PhoneCallIsFalse()
		-- else			
			-- -- 3 cases: resumption unsuccesfull - isActive Invalid
			-- commonFunctionsForCRQ20003:ResumptionUnsuccessWhenPhoneCallWithIsActiveInvalid(hmi_level_FULL)			
			-- -- case: resumption successfully - isActive Valid
			-- commonFunctionsForCRQ20003:PhoneCallIsFalse(test_data[i].app.."_Phone_Call_Is_False")			
			-- commonFunctionsForCRQ20003:ResumptionSuccessWhenPhoneCallEnded(hmi_level_FULL)			
		-- end			
	-- end
-- end
-- ResumptionSingleAppFULL_PhoneCallIsActiveBeforeAppIsConnected_IGNITION_OFF()

--------------------------------------------------------------------------------
-- Case: Resumption_HMIlevelLIMITTED_PhoneCallTrue_Before_App_Is_Connected
-- Step1: Change App Type
-- Step2: Register/Activate app/ChangeHMIToLimited
-- Step3: IGNITION_OFF
-- Step4: Start SDL
-- Step5: PHONE_CALL.Start
-- Step6: Register App
-- Step7: In case App is None MEDIA: Resumtion success without waiting PHONE_CALL.End
-- Step8: Resumption postpone
-- Step9: PHONE_CALL.End
-- Step10: Resumption success
---------------------------------------------------------------------------------
-- local function ResumptionSingleAppLIMITED_PhoneCallIsActiveBeforeAppIsConnected_IGNITION_OFF()		
	-- for i =1, #test_data-1 do
		-- commonFunctions:newTestCasesGroup("Single App (LIMITED) - Next IGNITION cycle: Phone call is active BEFORE app is connected and waiting for resume: " ..test_data[i].app)
		
		-- --Precondition:Unregister/Register/Activate App
		-- commonSteps:UnregisterApplication(test_data[i].app.."_Unregister_App")				
		-- commonFunctionsForCRQ20003:RegisterTheFirstApp(test_data[i].appType, test_data[i].isMedia,test_data[i].app.."_Register_App")
		-- commonFunctionsForCRQ20003:ActivateTheFirstApp(test_data[i].app.."_Activate_App")	
		
		-- --Change to Limited
		-- commonFunctionsForCRQ20003:ChangeHMIToLimited(test_data[i].app.."_Change_App_To_Limited")
		-- --IGNITION_OFF
		-- commonFunctionsForCRQ20003:IgnitionOff(1,test_data[i].app.."_IGNITION_OFF")
				
		-- --StartSDL -IGNITION_ON
		-- commonFunctionsForCRQ20003:StartSDL(test_data[i].app)	
		
		-- --PHONE_CALL is true before app is connected
		-- commonFunctionsForCRQ20003:PhoneCallIsTrue(test_data[i].app.."_Phone_Call_Is_True")
		
		-- commonFunctionsForCRQ20003:StartService1(test_data[i].app.."_Start_Service")
		-- commonFunctionsForCRQ20003:RegisterTheFirstApp(test_data[i].appType, test_data[i].isMedia,test_data[i].app.."_Register_App")
		
		-- --In case app is Non MEDIA: resumpt without phone call ended
		-- if test_data[i].app == "NON MEDIA" then
			-- commonFunctionsForCRQ20003:NoneMedia_ResumptionSuccessWithoutPhoneCallEnded()			
			-- commonFunctionsForCRQ20003:PhoneCallIsFalse()
		-- --In case app is Not "Non MEDIA": is active invalid and valid
		-- else			
			-- -- 3 cases: resumption unsuccesfull - isActive Invalid
			-- commonFunctionsForCRQ20003:ResumptionUnsuccessWhenPhoneCallWithIsActiveInvalid(hmi_level_FULL)			
			-- -- case: resumption successfully - isActive Valid
			-- commonFunctionsForCRQ20003:PhoneCallIsFalse(test_data[i].app.."_Phone_Call_Is_False")			
			-- commonFunctionsForCRQ20003:ResumptionSuccessWhenPhoneCallEnded(hmi_level_LIMITED)			
		-- end		
	-- end
-- end
-- ResumptionSingleAppLIMITED_PhoneCallIsActiveBeforeAppIsConnected_IGNITION_OFF()

--------------------------------------------------------------------------------
-- Case: Resumption_HMIlevelFULL_PhoneCallTrue_After_App_Is_Connected
-- Step1: Change App Type
-- Step2: Register/Activate app
-- Step3: IGNITION_OFF
-- Step4: Start SDL
-- Step5: Register App
-- Step6: PHONE_CALL.Start
-- Step7: In case App is None MEDIA: Resumtion success without waiting PHONE_CALL.End
-- Step8: Resumption postpone
-- Step9: PHONE_CALL.End
-- Step10: Resumption success
---------------------------------------------------------------------------------
local function ResumptionSingleAppFULL_PhoneCallIsActiveAfterAppIsConnected_IGNITION_OFF()		
	for i =1, #test_data do
		commonFunctions:newTestCasesGroup("Single App (FULL) - Next IGNITION cycle: Phone call is active AFTER app is connected and waiting for resume: " ..test_data[i].app)
				
		--Precondition:Unregister/Register/Activate App
		commonSteps:UnregisterApplication(test_data[i].app.."_Unregister_App")				
		commonFunctionsForCRQ20003:RegisterTheFirstApp(test_data[i].appType, test_data[i].isMedia,test_data[i].app.."_Register_App")
		commonFunctionsForCRQ20003:ActivateTheFirstApp(test_data[i].app.."_Activate_App")
	
		--IGNITION_OFF
		commonFunctionsForCRQ20003:IgnitionOff(1,test_data[i].app.."_IGNITION_OFF")
				
		--StartSDL -IGNITION_ON
		commonFunctionsForCRQ20003:StartSDL(test_data[i].app)	
		
		--PHONE_CALL is true after app is connected		
		commonFunctionsForCRQ20003:StartService1(test_data[i].app.."_Start_Service")
		commonFunctionsForCRQ20003:RegisterTheFirstApp(test_data[i].appType, test_data[i].isMedia,test_data[i].app.."_Register_App")
		
		commonFunctionsForCRQ20003:PhoneCallIsTrue(test_data[i].app.."_Phone_Call_Is_True")
				
		if test_data[i].app == "NON MEDIA" then
			commonFunctionsForCRQ20003:NoneMedia_ResumptionSuccessWithoutPhoneCallEnded()			
			commonFunctionsForCRQ20003:PhoneCallIsFalse()
		else			
			-- 3 cases: resumption unsuccesfull - isActive Invalid
			commonFunctionsForCRQ20003:ResumptionUnsuccessWhenPhoneCallWithIsActiveInvalid(hmi_level_FULL)			
			-- case: resumption successfully - isActive Valid
			commonFunctionsForCRQ20003:PhoneCallIsFalse(test_data[i].app.."_Phone_Call_Is_False")			
			commonFunctionsForCRQ20003:ResumptionSuccessWhenPhoneCallEnded(hmi_level_FULL)			
		end		
	end
end
ResumptionSingleAppFULL_PhoneCallIsActiveAfterAppIsConnected_IGNITION_OFF()

-- --------------------------------------------------------------------------------
-- -- Case: Resumption_HMIlevelLIMITTED_PhoneCallTrue_Before_App_Is_Connected
-- -- Step1: Change App Type
-- -- Step2: Register/Activate app/ChangeHMIToLimited
-- -- Step3: IGNITION_OFF
-- -- Step4: Start SDL
-- -- Step5: Register App
-- -- Step6: PHONE_CALL.Start
-- -- Step7: In case App is None MEDIA: Resumtion success without waiting PHONE_CALL.End
-- -- Step8: Resumption postpone
-- -- Step9: PHONE_CALL.End
-- -- Step10: Resumption success
-- ---------------------------------------------------------------------------------
-- local function ResumptionSingleAppLIMITED_PhoneCallIsActiveAfterAppIsConnected_IGNITION_OFF()		
	-- for i =1, #test_data-1 do
		-- commonFunctions:newTestCasesGroup("Single App (LIMITED) - Next IGNITION cycle: Phone call is active AFTER app is connected and waiting for resume: " ..test_data[i].app)
		
		-- --Precondition:Unregister/Register/Activate App
		-- commonSteps:UnregisterApplication(test_data[i].app.."_Unregister_App")				
		-- commonFunctionsForCRQ20003:RegisterTheFirstApp(test_data[i].appType, test_data[i].isMedia,test_data[i].app.."_Register_App")
		-- commonFunctionsForCRQ20003:ActivateTheFirstApp(test_data[i].app.."_Activate_App")	
				
		-- --Change to Limited
		-- commonFunctionsForCRQ20003:ChangeHMIToLimited(test_data[i].app.."_Change_App_To_Limited")	

		-- --IGNITION_OFF
		-- commonFunctionsForCRQ20003:IgnitionOff(1,test_data[i].app.."_IGNITION_OFF")
				
		-- --StartSDL -IGNITION_ON
		-- commonFunctionsForCRQ20003:StartSDL(test_data[i].app)	
		
		-- --PHONE_CALL is true after app is connected		
		-- commonFunctionsForCRQ20003:StartService1(test_data[i].app.."_Start_Service")
		-- commonFunctionsForCRQ20003:RegisterTheFirstApp(test_data[i].appType, test_data[i].isMedia,test_data[i].app.."_Register_App")
		
		-- commonFunctionsForCRQ20003:PhoneCallIsTrue(test_data[i].app.."_Phone_Call_Is_True")
				
		-- if test_data[i].app == "NON MEDIA" then
			-- commonFunctionsForCRQ20003:NoneMedia_ResumptionSuccessWithoutPhoneCallEnded()			
			-- commonFunctionsForCRQ20003:PhoneCallIsFalse()
		-- else			
			-- -- 3 cases: resumption unsuccesfull - isActive Invalid
			-- commonFunctionsForCRQ20003:ResumptionUnsuccessWhenPhoneCallWithIsActiveInvalid(hmi_level_FULL)			
			-- -- case: resumption successfully - isActive Valid
			-- commonFunctionsForCRQ20003:PhoneCallIsFalse(test_data[i].app.."_Phone_Call_Is_False")			
			-- commonFunctionsForCRQ20003:ResumptionSuccessWhenPhoneCallEnded(hmi_level_FULL)			
		-- end		
		
	-- end
-- end
-- ResumptionSingleAppLIMITED_PhoneCallIsActiveAfterAppIsConnected_IGNITION_OFF()

-- --////////////////////////////////////////////////////////////////////////////////////////////--
-- --APPLINK-16184-16284: PHONE CALL IS ACTIVE BEFORE OR AFTER APP IS CONNECTED
-- --CHECK WITH MULTIPLE APPS (FULL, LIMITED, LIMITED, BACKGROUND)
-- --////////////////////////////////////////////////////////////////////////////////////////////--
-- --------------------------------------------------------------------------------
-- -- Case: Multiple Apps (FULL,LIMITED,LIMITED,BACKGROUND) - Next IGNITION cycle: Phone call is active BEFORE apps is connected and waiting for resume:
-- -- Step1: Register and activate 4 Apps
-- -- Step2: IGNITION_OFF 4 Apps
-- -- Step3: Start SDL
-- -- Step4: PhoneCall.Start
-- -- Step5: Register App
-- -- Step6: PhoneCall.End with isActive invalid
-- -- Step7: Resume postpone
-- -- Step8: PhoneCall.End with isActive valid
-- -- Step9: Resumption success
-- ---------------------------------------------------------------------------------
-- local function Resumption_MultiApps_HMIlevelFULL_PhoneCallIsActive_Before_AppIsConnected_IGNITION_OFF_1()		
	-- commonFunctions:newTestCasesGroup("Multiple Apps (FULL,LIMITED,LIMITED,BACKGROUND) - Next IGNITION cycle: Phone call is active BEFORE apps is connected and waiting for resume: ")
	-- -- Step1: Register and activate 4 Apps
	-- Register4Apps_Full_Limited_Limited_Background()
	-- -- Step2: IGNITION_OFF 4 Apps
	-- Test["IGNITION_OFF"] = function(self)
		-- IGNITION_OFF(self,4)
	-- end
	-- -- Step3: Start SDL
	-- StartSDLThenConnect4Session(self)	
	-- -- Step4&5: PhoneCall.Start
	-- PhoneCall_IsActive_And_Register4Apps(1)
			
	-- -- 3 cases: resumption can't start because isActive is invalid
	-- Test:resumptionUnsuccessWhenPhoneCallWithIsActiveInvalid4Apps()
		
	-- --case: resumption start successfully 
	-- Test["Resumption_MultiApps_HMIlevelFULL_PhoneCallIsActive_Before_AppIsConnected_IsActiveValid"] = function(self)
			-- self:resumptionSuccessWhenPhoneCallEnded4Apps() 
	-- end
-- end
-- Resumption_MultiApps_HMIlevelFULL_PhoneCallIsActive_Before_AppIsConnected_IGNITION_OFF_1()

-- --------------------------------------------------------------------------------
-- -- Case: Multiple Apps (FULL,LIMITED,LIMITED,BACKGROUND) - Next IGNITION cycle: Phone call is active AFTER apps is connected and waiting for resume:
-- -- Step1: Register and activate 4 Apps
-- -- Step2: IGNITION_OFF 4 Apps
-- -- Step3: Start SDL
-- -- Step4: PhoneCall.Start
-- -- Step5: Register App
-- -- Step6: PhoneCall.End with isActive invalid
-- -- Step7: Resume postpone
-- -- Step8: PhoneCall.End with isActive valid
-- -- Step9: Resumption success
-- ---------------------------------------------------------------------------------
-- local function Resumption_MultiApps_HMIlevelFULL_PhoneCallIsActive_After_AppIsConnected_IGNITION_OFF_1()		
	-- commonFunctions:newTestCasesGroup("Multiple Apps (FULL,LIMITED,LIMITED,BACKGROUND) - Next IGNITION cycle: Phone call is active AFTER apps is connected and waiting for resume: ")
	-- Test:activateTheFirstApp()
	-- Test:activateTheFourthApp()
	-- Test["IGNITION_OFF"] = function(self)
		-- IGNITION_OFF(self,4)
	-- end
	
	-- StartSDLThenConnect4Session(self)	
	
	-- PhoneCall_IsActive_And_Register4Apps(2)
			
	-- -- 3 cases: resumption can't start because isActive is invalid
	-- Test:resumptionUnsuccessWhenPhoneCallWithIsActiveInvalid4Apps()
		
	-- --case: resumption start successfully 
	-- Test["Resumption_MultiApps_HMIlevelFULL_PhoneCallIsActive_After_AppIsConnected_IsActiveValid"] = function(self)
			-- self:resumptionSuccessWhenPhoneCallEnded4Apps() 
	-- end
-- end
-- Resumption_MultiApps_HMIlevelFULL_PhoneCallIsActive_After_AppIsConnected_IGNITION_OFF_1()

-- --////////////////////////////////////////////////////////////////////////////////////////////--
-- --APPLINK-16184-16284: PHONE CALL IS ACTIVE BEFORE OR AFTER APP IS CONNECTED
-- --CHECK WITH MULTIPLE APPS (FULL, LIMITED, LIMITED, LIMITED)
-- --////////////////////////////////////////////////////////////////////////////////////////////--
-- --------------------------------------------------------------------------------
-- -- Case: Multiple Apps (FULL,LIMITED,LIMITED,LIMITED) - Next IGNITION cycle: Phone call is active BEFORE apps is connected and waiting for resume:
-- -- Step1: Register and activate 4 Apps
-- -- Step2: IGNITION_OFF 4 Apps
-- -- Step3: Start SDL
-- -- Step4: PhoneCall.Start
-- -- Step5: Register App
-- -- Step6: PhoneCall.End with isActive invalid
-- -- Step7: Resume postpone
-- -- Step8: PhoneCall.End with isActive valid
-- -- Step9: Resumption success
-- ---------------------------------------------------------------------------------
-- local function Resumption_MultiApps_HMIlevelFULL_PhoneCallIsActive_Before_AppIsConnected_IGNITION_OFF_2()		
	-- commonFunctions:newTestCasesGroup("Multiple Apps (FULL, LIMITED, LIMITED, LIMITED) - Next IGNITION cycle: Phone call is active AFTER apps is connected and waiting for resume")
	-- Test:activateTheFirstApp()	
	
	-- Test["IGNITION_OFF"] = function(self)
		-- IGNITION_OFF(self,4)
	-- end
	
	-- StartSDLThenConnect4Session(self)	
	
	-- PhoneCall_IsActive_And_Register4Apps(1)
			
	-- -- 3 cases: resumption can't start because isActive is invalid
	-- Test:resumptionUnsuccessWhenPhoneCallWithIsActiveInvalid4Apps()
		
	-- --case: resumption start successfully 
	-- Test["Resumption_MultiApps_HMIlevelFULL_PhoneCallIsActive_Before_AppIsConnected_IsActiveValid"] = function(self)
			-- self:resumptionSuccessWhenPhoneCallEnded4Apps_2() 
	-- end
-- end
-- Resumption_MultiApps_HMIlevelFULL_PhoneCallIsActive_Before_AppIsConnected_IGNITION_OFF_2()

-- --------------------------------------------------------------------------------
-- -- Case: Multiple Apps (FULL,LIMITED,LIMITED,LIMITED) - Next IGNITION cycle: Phone call is active AFTER apps is connected and waiting for resume
-- -- Step1: Register and activate 4 Apps
-- -- Step2: IGNITION_OFF 4 Apps
-- -- Step3: Start SDL
-- -- Step4: PhoneCall.Start
-- -- Step5: Register App
-- -- Step6: PhoneCall.End with isActive invalid
-- -- Step7: Resume postpone
-- -- Step8: PhoneCall.End with isActive valid
-- -- Step9: Resumption success
-- ---------------------------------------------------------------------------------
-- local function Resumption_MultiApps_HMIlevelFULL_PhoneCallIsActive_Before_AppIsConnected_IGNITION_OFF_2()		
	-- commonFunctions:newTestCasesGroup("Multiple Apps (FULL,LIMITED,LIMITED,LIMITED) - Next IGNITION cycle: Phone call is active AFTER apps is connected and waiting for resume")
	-- --Test:activateTheFirstApp()	
	
	-- Test["IGNITION_OFF"] = function(self)
		-- IGNITION_OFF(self,4)
	-- end
	
	-- StartSDLThenConnect4Session(self)	
	
	-- PhoneCall_IsActive_And_Register4Apps(2)
			
	-- -- 3 cases: resumption can't start because isActive is invalid
	-- Test:resumptionUnsuccessWhenPhoneCallWithIsActiveInvalid4Apps()
		
	-- --case: resumption start successfully 
	-- Test["Resumption_MultiApps_HMIlevelFULL_PhoneCallIsActive_After_AppIsConnected_IsActiveValid"] = function(self)
			-- self:resumptionSuccessWhenPhoneCallEnded4Apps_2() 
	-- end
-- end
-- Resumption_MultiApps_HMIlevelFULL_PhoneCallIsActive_Before_AppIsConnected_IGNITION_OFF_2()


---------------------------------------------------------------------------------------------
-------------------------------------------Postcondition-------------------------------------
---------------------------------------------------------------------------------------------


function Test:Postcondition_RestoreIniFile()
  commonPreconditions:RestoreFile("smartDeviceLink.ini")
end