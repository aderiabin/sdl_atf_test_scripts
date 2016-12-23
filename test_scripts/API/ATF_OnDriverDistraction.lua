Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

local module = require('testbase')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
require('user_modules/AppTypes')


---------------------------------------------------------------------------------------------
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------
APIName = "OnDriverDistraction" -- set request name

local notificationState = {VRSession = false, EmergencyEvent = false, PhoneCall = false}
local AppValuesOnHMIStatusDEFAULT = {hmiLevel = "NONE", systemContext = "MAIN"}
local AppValuesOnHMIStatusFULL = {hmiLevel = "FULL", systemContext = "MAIN"}
local AppValuesOnHMIStatusLIMITED = {hmiLevel = "LIMITED", systemContext = "MAIN"}
---------------------------------------------------------------------------------------------
-------------------------- Overwrite These Functions For This Script-------------------------
---------------------------------------------------------------------------------------------
--Specific functions for this script
--1. createRequest()
--2. createUIParameters
--3. verify_SUCCESS_Case(Request)
---------------------------------------------------------------------------------------------


--Create default request
function Test:createRequest()

	return 	{
				state = "DD_ON"
			}

end

---------------------------------------------------------------------------------------------
function DelayedExp(time)
  time = time or 2000

  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  :Timeout(time+500)
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, time)
end
--This function sends a valid notification from HMI and then the notification is sent to mobile
function Test:verify_SUCCESS_Case(Request)
	--hmi side: sending OnDriverDistraction notification
	self.hmiConnection:SendNotification("UI.OnDriverDistraction",Request)

	if
		Request.fake or
		Request.syncFileName then
		local state = Request.state
		Request = {}
		Request =
			{
				state = state
			}
	end

	--mobile side: expect the response
	EXPECT_NOTIFICATION("OnDriverDistraction", Request)
	:ValidIf (function(_,data)
		if data.payload.fake ~= nil or data.payload.syncFileName ~= nil then
			print(" \27[36m SDL resend fake parameter to mobile app \27[0m")
			return false
		else
			return true
		end
	end)
end

--This function sends a invalid notification from HMI and then the notification is not sent to mobile
function Test:verify_INVALID_Case(Request)
	--hmi side: sending OnDriverDistraction notification
	self.hmiConnection:SendNotification("UI.OnDriverDistraction",Request)

	--mobile side: expect the response
	EXPECT_NOTIFICATION("OnDriverDistraction")
	:Times(0)
end

--This function is used in SUSPEND function
local function ActivationApp(self)

  if 
    notificationState.VRSession == true then
      self.hmiConnection:SendNotification("VR.Stopped", {})
  elseif 
    notificationState.EmergencyEvent == true then
      self.hmiConnection:SendNotification("BasicCommunication.OnEmergencyEvent", {enabled = false})
  elseif
    notificationState.PhoneCall == true then
      self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = false})
  end

    -- hmi side: sending SDL.ActivateApp request
      local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

    -- hmi side: expect SDL.ActivateApp response
    EXPECT_HMIRESPONSE(RequestId)
      	:Do(function(_,data)
        -- In case when app is not allowed, it is needed to allow app
          	if
              data.result.isSDLAllowed ~= true then

                -- hmi side: sending SDL.GetUserFriendlyMessage request
                  local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", 
                          {language = "EN-US", messageCodes = {"DataConsent"}})

                -- hmi side: expect SDL.GetUserFriendlyMessage response
                -- TODO: comment until resolving APPLINK-16094
                -- EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
                EXPECT_HMIRESPONSE(RequestId)
                    :Do(function(_,data)

	                    -- hmi side: send request SDL.OnAllowSDLFunctionality
	                    self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", 
                      		{allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

	                    -- hmi side: expect BasicCommunication.ActivateApp request
	                      EXPECT_HMICALL("BasicCommunication.ActivateApp")
	                        :Do(function(_,data)

	                          -- hmi side: sending BasicCommunication.ActivateApp response
	                          self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})

	                      end)
	                      :Times(2)
                      end)

        	end
        end)

end

--This function is used in RestartSDL function
local function CreateSession( self)
	self.mobileSession = mobile_session.MobileSession(
        self,
        self.mobileConnection)
end

--This function is used in RestartSDL function
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
	--TODO: defect APPLINK-19717 [Service] SDL doesn't send onSDLClose to HMI upon ignition Off
	EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")

	-- hmi side: expect OnAppUnregistered notification
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
	:Times(appNumber)
end

--This function is used in RestartSDL function
local function SUSPEND(self, targetLevel)

   if 
      targetLevel == "FULL" and
      self.hmiLevel ~= "FULL" then
            ActivationApp(self)
            EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
              :Do(function(_,data)
                self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
                  {
                    reason = "SUSPEND"
                  })

                -- hmi side: expect OnSDLPersistenceComplete notification
                EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")

              end)
    elseif 
      targetLevel == "LIMITED" and
      self.hmiLevel ~= "LIMITED" then
        if self.hmiLevel ~= "FULL" then
          ActivationApp(self)
          EXPECT_NOTIFICATION("OnHMIStatus",
            {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"},
            {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
            :Do(function(exp,data)
              if exp.occurences == 2 then
                self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
                  {
                    reason = "SUSPEND"
                  })

                -- hmi side: expect OnSDLPersistenceComplete notification
                EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
              end
            end)

            -- hmi side: sending BasicCommunication.OnAppDeactivated notification
            self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})
        else 
            -- hmi side: sending BasicCommunication.OnAppDeactivated notification
            self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = self.applications["Test Application"], reason = "GENERAL"})

            EXPECT_NOTIFICATION("OnHMIStatus",
            {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
            :Do(function(exp,data)
                self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
                  {
                    reason = "SUSPEND"
                  })

                -- hmi side: expect OnSDLPersistenceComplete notification
                EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
            end)
        end
    elseif 
      (targetLevel == "LIMITED" and
      self.hmiLevel == "LIMITED") or
      (targetLevel == "FULL" and
      self.hmiLevel == "FULL") or
      targetLevel == nil then
        self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
          {
            reason = "SUSPEND"
          })

        -- hmi side: expect OnSDLPersistenceComplete notification
        EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
    end

end

--This function to restart SDL
local function RestartSDL( prefix, level, appNumberForIGNOFF)

	Test["Precondition_SUSPEND_" .. tostring(prefix)] = function(self)
		SUSPEND(self, level)
	end

	Test["Precondition_IGNITION_OFF_" .. tostring(prefix)] = function(self)
		IGNITION_OFF(self,appNumberForIGNOFF)
	end

	Test["Precondition_StartSDL_" .. tostring(prefix)] = function(self)
		StartSDL(config.pathToSDL, config.ExitOnCrash)
	end

	Test["Precondition_InitHMI_" .. tostring(prefix)] = function(self)
		self:initHMI()
	end

	Test["Precondition_InitHMI_onReady_" .. tostring(prefix)] = function(self)
		self:initHMI_onReady()
	end

	Test["Precondition_ConnectMobile_" .. tostring(prefix)] = function(self)
		self:connectMobile()
	end

	Test["Precondition_StartSession_" .. tostring(prefix)] = function(self)
		CreateSession(self)
	end
end

--This function to register app after restart SDL with corressponding resumption's HMI level
local function RegisterApp_HMILevelResumption(self, HMILevel, reason)

	if HMILevel == "FULL" then
		local AppValuesOnHMIStatus = AppValuesOnHMIStatusFULL
	elseif HMILevel == "LIMITED" then
		local AppValuesOnHMIStatus = AppValuesOnHMIStatusLIMITED
	end

	local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)


	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
		:Do(function(_,data)
			HMIAppID = data.params.application.appID
			self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
		end)

	self.mobileSession:ExpectResponse(correlationId, { success = true })

			
	if HMILevel == "FULL" then
		EXPECT_HMICALL("BasicCommunication.ActivateApp")
			:Do(function(_,data)
		      	self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
			end)
	elseif HMILevel == "LIMITED" then
		EXPECT_HMINOTIFICATION("BasicCommunication.OnResumeAudioSource", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
	end
	

	EXPECT_NOTIFICATION("OnHMIStatus",AppValuesOnHMIStatusDEFAULT)
		:Do(function(_,data)
			if HMILevel == "FULL" then				
				EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusFULL)
			elseif HMILevel == "LIMITED" then
				EXPECT_NOTIFICATION("OnHMIStatus", AppValuesOnHMIStatusLIMITED)
			end
		end)

end

--This function to update resuming time out value in .ini file
local function UpdateApplicationResumingTimeoutValue(ApplicationResumingTimeoutValueToReplace)
	findresult = string.find (config.pathToSDL, '.$')

	if string.sub(config.pathToSDL,findresult) ~= "/" then
		config.pathToSDL = config.pathToSDL..tostring("/")
	end
  
	SDLStoragePath = config.pathToSDL .. "storage/"
	
	local SDLini = config.pathToSDL .. tostring("smartDeviceLink.ini")
	
  if ApplicationResumingTimeoutValueToReplace ~= nil then
    Test["Precondition_ApplicationResumingTimeoutChange_" .. tostring(prefix)] = function(self)
      local StringToReplace = "ApplicationResumingTimeout = " .. tostring(ApplicationResumingTimeoutValueToReplace) .. "\n"
      f = assert(io.open(SDLini, "r"))
      if f then
        fileContent = f:read("*all")
        local MatchResult = string.match(fileContent, "ApplicationResumingTimeout%s-=%s-.-%s-\n")
        if MatchResult ~= nil then
          fileContentUpdated = string.gsub(fileContent, MatchResult, StringToReplace)
          f = assert(io.open(SDLini, "w"))
          f:write(fileContentUpdated)
        else
          userPrint(31, "Finding of 'ApplicationResumingTimeout = value' is failed. Expect string finding and replacing of value to " .. tostring(ApplicationResumingTimeoutValueToReplace))
        end
        f:close()
      end
    end
  end
	
end

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Preconditions
	commonFunctions:newTestCasesGroup("Preconditions")

	--Delete app_info.dat, logs and policy table
	commonSteps:DeleteLogsFileAndPolicyTable()


	--1. Activate application
	commonSteps:ActivationApp()

	--2. Update policy to allow request
	policyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/ptu_general.json")


---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--CommonRequestCheck: Check of mandatory/conditional request's parameters (mobile protocol)--
---------------------------------------------------------------------------------------------


	--Print new line to separate test suite
	commonFunctions:newTestCasesGroup("Test Suite For mandatory/conditional request's parameters (mobile protocol)")

	--Begin Test suit PositiveRequestCheck

	--Description: TC's checks processing
		-- request with all parameters
        -- request with only mandatory parameters
        -- request with all combinations of conditional-mandatory parameters (if exist)
        -- request with one by one conditional parameters (each case - one conditional parameter)
        -- request with missing mandatory parameters one by one (each case - missing one mandatory parameter)
        -- request with all parameters are missing
        -- request with fake parameters (fake - not from protocol, from another request)
        -- request is sent with invalid JSON structure
        -- different conditions of correlationID parameter (invalid, several the same etc.)

		--Begin Test case CommonRequestCheck.1
		--Description: This test is intended to check positive cases and when all parameters are in boundary conditions

			--Requirement id in JAMA:
					-- SDLAQ-CRS-182
					-- SDLAQ-CRS-909

			--Verification criteria:
					-- When DD_ON notification is invoked, SDL sends notification to all connected applications on any device if current app HMI Level corresponds to the allowed one in policy table.
					-- When DD_OFF notification is invoked, SDL sends notification to all connected applications on any device if current app HMI Level corresponds to the allowed one in policy table.
					-- DriverDistractionState describes possible states of driver distraction.
						-- DD_ON
						-- DD_OFF
			local onDriverDistractionValue = {"DD_ON", "DD_OFF"}
			for i=1,#onDriverDistractionValue do
				Test["OnDriverDistraction_State_" .. onDriverDistractionValue[i]] = function(self)
					local request = {state = onDriverDistractionValue[i]}
					self:verify_SUCCESS_Case(request)
				end
			end
		--End Test case CommonRequestCheck.1

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.2
		--Description: This test is intended to check request with mandatory and with or without conditional parameters

			-- Not Applicable

		--End Test case CommonRequestCheck.2

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.3
		--Description: This test is intended to check processing requests without mandatory parameters
			function Test:OnDriverDistraction_WithoutState()
				self:verify_INVALID_Case({})
			end

		--End Test case CommonRequestCheck.3

		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.4
		--Description: Check processing request with different fake parameters

			--Requirement id in JAMA:
					--APPLINK-14765
			--Verification criteria:
					--SDL must cut off the fake parameters from requests, responses and notifications received from HMI

			--Begin Test case CommonRequestCheck.4.1
			--Description: Parameter not from protocol
				function Test:OnDriverDistraction_FakeParam()
					local request = {
										state = "DD_ON",
										fake = "fake"
									}
					self:verify_SUCCESS_Case(request)
				end
			--Begin Test case CommonRequestCheck.4.1

			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.4.2
			--Description: Parameters from another request
				function Test:OnDriverDistraction_ParamsAnotherRequest()
					local request = {
										state = "DD_ON",
										syncFileName = "a"
									}
					self:verify_SUCCESS_Case(request)
				end
			--End Test case CommonRequestCheck.4.2
		--End Test case CommonRequestCheck.4
		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.5
		--Description: Invalid JSON

			function Test:OnDriverDistraction_InvalidJsonSyntax()
				--hmi side: send UI.OnDriverDistraction
				--":" is changed by ";" after "jsonrpc"
				--self.hmiConnection:Send('{"jsonrpc":"2.0","method":"UI.OnDriverDistraction","params":{"state":"DD_ON"}}')
				self.hmiConnection:Send('{"jsonrpc";"2.0","method":"UI.OnDriverDistraction","params":{"state":"DD_ON"}}')

				--mobile side: expect OnDriverDistraction notification
				EXPECT_NOTIFICATION("OnDriverDistraction", {state = "DD_ON"})
				:Times(0)
			end

			function Test:OnDriverDistraction_InvalidStructure()

				--hmi side: send UI.OnDriverDistraction
				--self.hmiConnection:Send('{"jsonrpc":"2.0","method":"UI.OnDriverDistraction","params":{"state":"DD_ON"}}')
				  self.hmiConnection:Send('{"jsonrpc":"2.0","params":{"method":"UI.OnDriverDistraction","state":"DD_ON"}}')

				--mobile side: expect OnDriverDistraction notification
				EXPECT_NOTIFICATION("OnDriverDistraction", {state = "DD_ON"})
				:Times(0)
			end
		--End Test case CommonRequestCheck.5
	--End Test suit CommonRequestCheck

---------------------------------------------------------------------------------------------
----------------------------------------II TEST BLOCK----------------------------------------
----------------------------------------Positive cases---------------------------------------
---------------------------------------------------------------------------------------------

	--=================================================================================--
	--------------------------------Positive request check-------------------------------
	--=================================================================================--

		--Begin Test suit PositiveRequestCheck
		--Description: Check of each request parameter value in bound and boundary conditions

			-- Not Applicable

		--End Test suit PositiveRequestCheck

	--=================================================================================--
	--------------------------------Positive response check------------------------------
	--=================================================================================--
		--Begin Test suit PositiveResponseCheck
		--Description: check of each response parameter value in bound and boundary conditions

			-- Not Applicable

		--End Test suit PositiveRequestCheck


----------------------------------------------------------------------------------------------
----------------------------------------III TEST BLOCK----------------------------------------
----------------------------------------Negative cases----------------------------------------
----------------------------------------------------------------------------------------------

	--=================================================================================--
	---------------------------------Negative request check------------------------------
	--=================================================================================--

		--------Checks-----------
		-- outbound values
		-- invalid values(empty, missing, non existent, duplicate, invalid characters)
		-- parameters with wrong type
		-- invalid json

		--Begin Test suit NegativeRequestCheck
		--Description: check of each request parameter value out of bound, missing, with wrong type, empty, duplicate etc.

			--Begin Test case NegativeResponseCheck.1
			--Description: Request with nonexistent state
				function Test:OnDriverDistraction_NonexistentState()
					local request = {
										state = "DD_STATE",
									}
					self:verify_INVALID_Case(request)
				end
			--End Test case NegativeRequestCheck.1

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.2
			--Description: Request without method
				function Test:OnDriverDistraction_WithoutMethod()
					--hmi side: send UI.OnDriverDistraction
					self.hmiConnection:Send('{"jsonrpc":"2.0","params":{"state":"DD_ON"}}')

					--mobile side: expect OnDriverDistraction notification
					EXPECT_NOTIFICATION("OnDriverDistraction", {state = "DD_ON"})
					:Times(0)
				end
			--End Test case NegativeRequestCheck.2

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.3
			--Description: Request without params
				function Test:OnDriverDistraction_WithoutParams()
					--hmi side: send UI.OnDriverDistraction
					self.hmiConnection:Send('{"jsonrpc":"2.0","method":"UI.OnDriverDistraction"}')

					--mobile side: expect OnDriverDistraction notification
					EXPECT_NOTIFICATION("OnDriverDistraction")
					:Times(0)
				end
			--End Test case NegativeRequestCheck.3

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.4
			--Description: Request without state
				function Test:OnDriverDistraction_WithoutState()
					--hmi side: send UI.OnDriverDistraction
					self.hmiConnection:Send('{"jsonrpc":"2.0","method":"UI.OnDriverDistraction","params":{}}')

					--mobile side: expect OnDriverDistraction notification
					EXPECT_NOTIFICATION("OnDriverDistraction")
					:Times(0)
				end
			--End Test case NegativeRequestCheck.4

			-----------------------------------------------------------------------------------------

			--Begin Test case NegativeResponseCheck.5
			--Description: Request with state is empty
				function Test:OnDriverDistraction_StateEmpty()
					--hmi side: send UI.OnDriverDistraction
					self.hmiConnection:Send('{"jsonrpc":"2.0","method":"UI.OnDriverDistraction","params":{"state":""}}')

					--mobile side: expect OnDriverDistraction notification
					EXPECT_NOTIFICATION("OnDriverDistraction")
					:Times(0)
				end
			--End Test case NegativeRequestCheck.5
		--End Test suit NegativeRequestCheck


----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result code check--------------------------------------
----------------------------------------------------------------------------------------------

--Not Applicable


----------------------------------------------------------------------------------------------
-----------------------------------------V TEST BLOCK-----------------------------------------
---------------------------------------HMI negative cases-------------------------------------
----------------------------------------------------------------------------------------------

--Not Applicable


----------------------------------------------------------------------------------------------
-----------------------------------------VI TEST BLOCK----------------------------------------
-------------------------Sequence with emulating of user's action(s)------------------------
----------------------------------------------------------------------------------------------

	--Begin Test suit SequenceCheck
	--Description: TC's checks SDL behaviour by processing
		-- different request sequence with timeout
		-- with emulating of user's actions

		--Begin Test case SequenceCheck.1
		--Description:
			--Requirement id in JAMA:
					-- SDLAQ-CRS-182

			--Verification criteria:
					-- When the state is changed (DD_ON/DD_OFF) the notification is sent to all applicabe apps (according to policy table restrictions).

			commonFunctions:newTestCasesGroup("Test case: Check OnDriverDistraction notification with several app")
			-- Precondition 1: Register new media app
			function Test:AddNewSession()
				-- Connected expectation
				self.mobileSession3 = mobile_session.MobileSession(
				self,
				self.mobileConnection)

				self.mobileSession3:StartService(7)
			end

			function Test:RegisterAppInterface_MediaApp()
				--mobile side: RegisterAppInterface request
				local CorIdRAI = self.mobileSession3:SendRPC("RegisterAppInterface",
															{
																syncMsgVersion =
																{
																	majorVersion = 2,
																	minorVersion = 2,
																},
																appName ="MediaApp",
																isMediaApplication = true,
																languageDesired ="EN-US",
																hmiDisplayLanguageDesired ="EN-US",
																appID ="6",
																ttsName =
																{
																	{
																		text ="MediaApp",
																		type ="TEXT",
																	},
																},
																vrSynonyms =
																{
																	"vrMediaApp",
																}
															})

				--hmi side: expect BasicCommunication.OnAppRegistered request
				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
				{
					application =
					{
						appName = "MediaApp"
					}
				})
				:Do(function(_,data)
					self.applications["MediaApp"] = data.params.application.appID
				end)

				--mobile side: RegisterAppInterface response
				self.mobileSession3:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
				:Timeout(2000)

				self.mobileSession3:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			end

			-- Precondition 2: Register new non-media app 1
			function Test:AddNewSession()
				-- Connected expectation
				self.mobileSession4 = mobile_session.MobileSession(
				self,
				self.mobileConnection)

				self.mobileSession4:StartService(7)
			end

			function Test:RegisterAppInterface_NonMediaApp1()
				--mobile side: RegisterAppInterface request
				local CorIdRAI = self.mobileSession4:SendRPC("RegisterAppInterface",
															{
																syncMsgVersion =
																{
																	majorVersion = 2,
																	minorVersion = 2,
																},
																appName ="NonMediaApp1",
																isMediaApplication = false,
																languageDesired ="EN-US",
																hmiDisplayLanguageDesired ="EN-US",
																appID ="3",
																ttsName =
																{
																	{
																		text ="NonMediaApp1",
																		type ="TEXT",
																	},
																},
																vrSynonyms =
																{
																	"vrNonMediaApp1",
																}
															})

				--hmi side: expect BasicCommunication.OnAppRegistered request
				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
				{
					application =
					{
						appName = "NonMediaApp1"
					}
				})
				:Do(function(_,data)
					self.applications["NonMediaApp1"] = data.params.application.appID
				end)

				--mobile side: RegisterAppInterface response
				self.mobileSession4:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
					:Timeout(2000)

				self.mobileSession4:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			end

			-- Precondition 3: Register new non-media app 2
			function Test:AddNewSession()
				-- Connected expectation
				self.mobileSession5 = mobile_session.MobileSession(
				self,
				self.mobileConnection)

				self.mobileSession5:StartService(7)
			end

			function Test:RegisterAppInterface_NonMediaApp2()
				--mobile side: RegisterAppInterface request
				local CorIdRAI = self.mobileSession5:SendRPC("RegisterAppInterface",
															{
																syncMsgVersion =
																{
																	majorVersion = 2,
																	minorVersion = 2,
																},
																appName ="NonMediaApp2",
																isMediaApplication = false,
																languageDesired ="EN-US",
																hmiDisplayLanguageDesired ="EN-US",
																appID ="4",
																ttsName =
																{
																	{
																		text ="NonMediaApp2",
																		type ="TEXT",
																	},
																},
																vrSynonyms =
																{
																	"vrNonMediaApp2",
																}
															})

				--hmi side: expect BasicCommunication.OnAppRegistered request
				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
				{
					application =
					{
						appName = "NonMediaApp2"
					}
				})
				:Do(function(_,data)
					self.applications["NonMediaApp2"] = data.params.application.appID
				end)

				--mobile side: RegisterAppInterface response
				self.mobileSession5:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
					:Timeout(2000)

				self.mobileSession5:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			end

			-- Precondition 4: Register new non-media app 3
			function Test:AddNewSession()
				-- Connected expectation
				self.mobileSession6 = mobile_session.MobileSession(
				self,
				self.mobileConnection)

				self.mobileSession6:StartService(7)
			end

			function Test:RegisterAppInterface_NonMediaApp3()
				--mobile side: RegisterAppInterface request
				local CorIdRAI = self.mobileSession6:SendRPC("RegisterAppInterface",
															{
																syncMsgVersion =
																{
																	majorVersion = 2,
																	minorVersion = 2,
																},
																appName ="NonMediaApp3",
																isMediaApplication = false,
																languageDesired ="EN-US",
																hmiDisplayLanguageDesired ="EN-US",
																appID ="5",
																ttsName =
																{
																	{
																		text ="NonMediaApp3",
																		type ="TEXT",
																	},
																},
																vrSynonyms =
																{
																	"vrNonMediaApp3",
																}
															})

				--hmi side: expect BasicCommunication.OnAppRegistered request
				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
				{
					application =
					{
						appName = "NonMediaApp3"
					}
				})
				:Do(function(_,data)
					self.applications["NonMediaApp3"] = data.params.application.appID
				end)

				--mobile side: RegisterAppInterface response
				self.mobileSession6:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
					:Timeout(2000)

				self.mobileSession6:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			end


			--Precondition 5: Activate application to make sure HMI status of 4 apps: FULL, BACKGROUND, LIMITED and NONE
			function Test:Activate_MediaApp()
				--hmi side: sending SDL.ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["MediaApp"]})

				--hmi side: expect SDL.ActivateApp response
				EXPECT_HMIRESPONSE(RequestId)
					:Do(function(_,data)
						--In case when app is not allowed, it is needed to allow app
						if
							data.result.isSDLAllowed ~= true then

								--hmi side: sending SDL.GetUserFriendlyMessage request
								local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
													{language = "EN-US", messageCodes = {"DataConsent"}})

								--hmi side: expect SDL.GetUserFriendlyMessage response
								EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
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
										:Times(2)
									end)

						end
					end)

				self.mobileSession3:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
				:Timeout(12000)
			end

			function Test:ChangeMediaAppToLimited()
				--hmi side: sending BasicCommunication.OnAppDeactivated request
				local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
				{
					appID = self.applications["MediaApp"],
					reason = "GENERAL"
				})

				--mobile side: expect OnHMIStatus notification
				self.mobileSession3:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
			end

			function Test:Activate_NonMedia_App1()
				--hmi side: sending SDL.ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["NonMediaApp1"]})

				--hmi side: expect SDL.ActivateApp response
				EXPECT_HMIRESPONSE(RequestId)
					:Do(function(_,data)
						--In case when app is not allowed, it is needed to allow app
						if
							data.result.isSDLAllowed ~= true then

								--hmi side: sending SDL.GetUserFriendlyMessage request
								local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
													{language = "EN-US", messageCodes = {"DataConsent"}})

								--hmi side: expect SDL.GetUserFriendlyMessage response
								EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
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
									:Times(2)
								end)
						end
					end)

				self.mobileSession4:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				:Timeout(12000)
			end

			function Test:Activate_NonMedia_App2()
			--hmi side: sending SDL.ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["NonMediaApp2"]})

				--hmi side: expect SDL.ActivateApp response
				EXPECT_HMIRESPONSE(RequestId)
					:Do(function(_,data)
						--In case when app is not allowed, it is needed to allow app
						if
							data.result.isSDLAllowed ~= true then

								--hmi side: sending SDL.GetUserFriendlyMessage request
								local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
													{language = "EN-US", messageCodes = {"DataConsent"}})

								--hmi side: expect SDL.GetUserFriendlyMessage response
								EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
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
											:Times(2)

									end)

						end
					end)
				self.mobileSession4:ExpectNotification("OnHMIStatus", {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				self.mobileSession5:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				:Timeout(12000)
			end

			--Sending OnDriverDistraction notification
			function Test:OnDriverDistraction_SeveralApp()
				--hmi side: sending OnDriverDistraction notification
				self.hmiConnection:SendNotification("UI.OnDriverDistraction",{state = "DD_ON"})

				--mobile side: expect the response
				self.mobileSession3:ExpectNotification("OnDriverDistraction",{state = "DD_ON"})			--App with HMI level = LIMITED
				self.mobileSession4:ExpectNotification("OnDriverDistraction",{state = "DD_ON"})			--App with HMI level = BACKGROUND
				self.mobileSession5:ExpectNotification("OnDriverDistraction",{state = "DD_ON"})			--App with HMI level = FULL
				self.mobileSession6:ExpectNotification("OnDriverDistraction",{state = "DD_ON"}):Times(0)--App with HMI level = NONE				
			end
		
		--End Test case SequenceCheck.1

		--Begin Test case SequenceCheck.2
		--Requirement: [APPLINK-23806]
		--Description: SDL must send OnDriverDistraction to app right after this app changes HMILevel from NONE to any other
		--Scenario:
		--			(continue the SequenceCheck.1)
		--			1. Activate App with HMI level = NONE (mobileSession6)
		-- 				=> OnDriverDistraction comes to app (mobileSession6)
		--			2. Send OnDriverDistraction
		-- 				=> OnDriverDistraction comes to all apps
		--			3. Exit app by app and send OnDriverDistraction to check that OnDriverDistraction comes to exited apps

			--2.1. Activate App with HMI level = NONE (mobileSession6) => OnDriverDistraction comes to app (mobileSession6)
			Test[APIName.."_SeveralApp_Active_NONE_App"] = function(self)
			    -- hmi side: sending SDL.ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["NonMediaApp3"]})
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
							--self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
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
				self.mobileSession6:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})

				--mobile side: expect the response
				self.mobileSession3:ExpectNotification("OnDriverDistraction",{state = "DD_ON"}):Times(0)
				self.mobileSession4:ExpectNotification("OnDriverDistraction",{state = "DD_ON"}):Times(0)			
				self.mobileSession5:ExpectNotification("OnDriverDistraction",{state = "DD_ON"}):Times(0)			
				self.mobileSession6:ExpectNotification("OnDriverDistraction",{state = "DD_ON"})
				
			end
			
			--2.2. Sending OnDriverDistraction notification => OnDriverDistraction comes to all apps
			Test[APIName.."_SeveralApp_Send_OnDriverDistraction_To_All_App"] = function(self)
				--hmi side: sending OnDriverDistraction notification
				self.hmiConnection:SendNotification("UI.OnDriverDistraction",{state = "DD_ON"})

				--mobile side: expect the response
				self.mobileSession3:ExpectNotification("OnDriverDistraction",{state = "DD_ON"})			--App with HMI level = LIMITED
				self.mobileSession4:ExpectNotification("OnDriverDistraction",{state = "DD_ON"})			--App with HMI level = BACKGROUND
				self.mobileSession5:ExpectNotification("OnDriverDistraction",{state = "DD_ON"})			--App with HMI level = FULL
				self.mobileSession6:ExpectNotification("OnDriverDistraction",{state = "DD_ON"})			--App with HMI level = NONE	has been activated			
			end			
			
		
			--2.3. Exit app by app and send OnDriverDistraction
			Test[APIName.."SeveralApp_After_Exit_Media_App"] = function(self)
				--hmi side: send OnExitApplication
				self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",	{reason = "USER_EXIT", appID = self.applications["MediaApp"]})
				
				--hmi side: sending OnDriverDistraction notification
				self.hmiConnection:SendNotification("UI.OnDriverDistraction",{state = "DD_ON"})

				--mobile side: expect the response
				self.mobileSession3:ExpectNotification("OnDriverDistraction",{state = "DD_ON"}):Times(0)
				self.mobileSession4:ExpectNotification("OnDriverDistraction",{state = "DD_ON"})			
				self.mobileSession5:ExpectNotification("OnDriverDistraction",{state = "DD_ON"})			
				self.mobileSession6:ExpectNotification("OnDriverDistraction",{state = "DD_ON"})				
			end

		
			Test[APIName.."SeveralApp_After_Exit_NonMedia_App"] = function(self)
				--hmi side: send OnExitApplication
				self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",	{reason = "USER_EXIT", appID = self.applications["NonMediaApp1"]})
				self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",	{reason = "USER_EXIT", appID = self.applications["NonMediaApp2"]})				
				self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",	{reason = "USER_EXIT", appID = self.applications["NonMediaApp3"]})
				
				--hmi side: sending OnDriverDistraction notification
				self.hmiConnection:SendNotification("UI.OnDriverDistraction",{state = "DD_ON"})

				--mobile side: expect the response
				self.mobileSession3:ExpectNotification("OnDriverDistraction",{state = "DD_ON"}):Times(0)
				self.mobileSession4:ExpectNotification("OnDriverDistraction",{state = "DD_ON"}):Times(0)
				self.mobileSession5:ExpectNotification("OnDriverDistraction",{state = "DD_ON"}):Times(0)
				self.mobileSession6:ExpectNotification("OnDriverDistraction",{state = "DD_ON"}):Times(0)				
			end	
			
		--End Test case SequenceCheck.2
		
		--Postcondition: Unregister applications of Mobilesession3..6
			Test["Unregister_Applications_Of_SeveralApp_Checking"] = function(self)		
		
				local cid3 = self.mobileSession3:SendRPC("UnregisterAppInterface",{})
				--mobile side: expect the response				
				self.mobileSession3:ExpectResponse(cid3, { success = true, resultCode = "SUCCESS"})
				:Timeout(2000)

				local cid4 = self.mobileSession4:SendRPC("UnregisterAppInterface",{})
				--mobile side: expect the response
				self.mobileSession4:ExpectResponse(cid4, { success = true, resultCode = "SUCCESS"})
				:Timeout(2000)		

				local cid5 = self.mobileSession5:SendRPC("UnregisterAppInterface",{})
				--mobile side: expect the response				
				self.mobileSession5:ExpectResponse(cid5, { success = true, resultCode = "SUCCESS"})
				:Timeout(2000)

				local cid6 = self.mobileSession6:SendRPC("UnregisterAppInterface",{})
				--mobile side: expect the response
				self.mobileSession6:ExpectResponse(cid6, { success = true, resultCode = "SUCCESS"})
				:Timeout(2000)
			
			end 
		--End Postcondition
		
	--End Test suit SequenceCheck

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------
	--Description: processing of request/response in different HMIlevels, SystemContext, AudioStreamingState

	--Begin Test suit DifferentHMIlevel
	--Description: processing API in different HMILevel
	commonFunctions:newTestCasesGroup("Test case: Check OnDriverDistraction notification in different HMILevel")
		--Begin Test case DifferentHMIlevel.1
		--Description: Check OnDriverDistraction notification when HMI level is NONE

			--Requirement id in JAMA:
				-- SDLAQ-CRS-1309

			--Verification criteria:
				-- SDL doesn't send OnDriverDistraction notification to the app when current app's HMI level is NONE.

			commonSteps:DeactivateAppToNoneHmiLevel("DeactivateApp_DifferentHMIlevel_1")

			function Test:OnDriverDistraction_HMIStatus_NONE()
				local request = {
									state = "DD_ON",
								}
				self:verify_INVALID_Case(request)
			end

			--Postcondition: Activate app
			commonSteps:ActivationApp(_,"ActivationApp_Postcondition_DifferentHMIlevel_1")
		--End Test case DifferentHMIlevel.1

		-----------------------------------------------------------------------------------------

		--Begin Test case DifferentHMIlevelChecks.2
		--Description: Check OnDriverDistraction notification when HMI level is LIMITED
			if commonFunctions:isMediaApp() then
				--Precondition: Deactivate app to LIMITED HMI level
				commonSteps:ChangeHMIToLimited("ChangeHMIToLimited_DifferentHMIlevelChecks_2")

				for i=1,#onDriverDistractionValue do
					Test["OnDriverDistraction_LIMITED_State_" .. onDriverDistractionValue[i]] = function(self)
						local request = {state = onDriverDistractionValue[i]}
						self:verify_SUCCESS_Case(request)
					end
				end
		--End Test case DifferentHMIlevelChecks.2

		-- Precondition 1: Opening new session
			function Test:AddNewSession()
			  -- Connected expectation
				self.mobileSession2 = mobile_session.MobileSession(
				self,
				self.mobileConnection)

				self.mobileSession2:StartService(7)
			end
			-- Precondition 2: Register app2
			function Test:RegisterAppInterface_App2()
				--mobile side: RegisterAppInterface request
				local CorIdRAI = self.mobileSession2:SendRPC("RegisterAppInterface",
															{
																syncMsgVersion =
																{
																	majorVersion = 2,
																	minorVersion = 2,
																},
																appName ="SPT2",
																isMediaApplication = true,
																languageDesired ="EN-US",
																hmiDisplayLanguageDesired ="EN-US",
																appID ="2",
																ttsName =
																{
																	{
																		text ="SyncProxyTester2",
																		type ="TEXT",
																	},
																},
																vrSynonyms =
																{
																	"vrSPT2",
																}
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
					:Timeout(2000)

				self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			end

			-- Precondition 3: Activate an other media app to change app to BACKGROUND
			function Test:Activate_Media_App2()
				--hmi side: sending SDL.ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = appId2})

				--hmi side: expect SDL.ActivateApp response
				EXPECT_HMIRESPONSE(RequestId)
					:Do(function(_,data)
						--In case when app is not allowed, it is needed to allow app
						if
							data.result.isSDLAllowed ~= true then

								--hmi side: sending SDL.GetUserFriendlyMessage request
								local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
													{language = "EN-US", messageCodes = {"DataConsent"}})

								--hmi side: expect SDL.GetUserFriendlyMessage response
								EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
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
											:Times(2)

									end)

						end
					end)

				self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
				:Timeout(12000)

				self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})

			end

		elseif Test.isMediaApplication == false then
			--Precondition: Deactivate app to BACKGROUND HMI level
			commonSteps:DeactivateToBackground(self)
		end
		-----------------------------------------------------------------------------------------

		--Begin Test case DifferentHMIlevelChecks.3
		--Description: Check OnDriverDistraction notification when HMI level is BACKGROUND
			for i=1,#onDriverDistractionValue do
				Test["OnDriverDistraction_BACKGROUND_State_" .. onDriverDistractionValue[i]] = function(self)
					local request = {state = onDriverDistractionValue[i]}
					self:verify_SUCCESS_Case(request)
				end
			end
		--End Test case DifferentHMIlevelChecks.3
	--End Test suit DifferentHMIlevel

	--Begin Test suit App changes HMI level from NONE
	--Requirement: [APPLINK-23806]
	--Description: SDL must send OnDriverDistraction to app right after this app changes HMILevel from NONE to any other	
	commonFunctions:newTestCasesGroup("Test case: SDL must sends OnDriverDistraction to app right after this app changes HMILevel from NONE to any other")	
		--Precondition: Unregister the application on mobileSession of previous TestCase and Register a new application
		--commonSteps:UnregisterApplication("Unregister_Application_of_MobileSession_in_DifferentHMIlevelChecks")
		Test["Unregister_Application_of_MobileSession_in_DifferentHMIlevelChecks"] = function(self)		
		
				local cid = self.mobileSession:SendRPC("UnregisterAppInterface",{})
				--mobile side: expect the response				
				self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
				:Timeout(2000)

				local cid2 = self.mobileSession2:SendRPC("UnregisterAppInterface",{})
				--mobile side: expect the response
				self.mobileSession2:ExpectResponse(cid2, { success = true, resultCode = "SUCCESS"})
				:Timeout(2000)	
		end
		
		function Test:AddNewSession()
				-- Connected expectation
				self.mobileSession = mobile_session.MobileSession(
				self,
				self.mobileConnection)

				self.mobileSession:StartService(7)
		end
		commonSteps:RegisterAppInterface("RegisterAppInterface_MediaApp_for_TC_AppChangesHMILevelFromNONE")
		commonSteps:ActivationApp(_,"ActivationApp_for_TC_AppChangesHMILevelFromNONE")
		
		--Begin Test case [App changes HMI level from NONE].1
		--Description: 1 App - NONE - FULL - OnDriverDistraction -> OnDriverDistraction comes		
		--This Test Case is already covered by Test["OnDriverDistraction_State_" .. onDriverDistractionValue[i]] in TEST BLOCK I
			Test["Start TC1: This Test case is already covered in Suite_2"] = function(self)
				print ("\27[33m TC1. 1 App - NONE - FULL - OnDriverDistraction -> OnDriverDistraction comes \27[0m")
			end
		--End Test case [App changes HMI level from NONE].1

		--Begin Test case [App changes HMI level from NONE].2
		--Description: 1 App - NONE - OnDriverDistraction - FULL -> OnDriverDistraction comes	
			Test["Start TC2:"] = function(self)
				print ("\27[33m TC2. 1 App - NONE - OnDriverDistraction - FULL -> OnDriverDistraction comes \27[0m")
			end
			
			for i=1,#onDriverDistractionValue do
				local request = {state = onDriverDistractionValue[i]}
				commonSteps:DeactivateAppToNoneHmiLevel("DeactivateApp_App_changes_HMI_level_from_NONE_TC2_time:"..tostring(i))
				Test["TC2:_"..APIName.."_1 App_NONE_OnDriverDistraction_FULL_(state:"..onDriverDistractionValue[i]..")"] = function(self)	
					--hmi side: sending OnDriverDistraction notification
					self.hmiConnection:SendNotification("UI.OnDriverDistraction",request)
					
					ActivationApp(self)
					
					--mobile side: expect the response
					self.mobileSession:ExpectNotification("OnDriverDistraction", request)		
				end
			end
		--End Test case [App changes HMI level from NONE].2		
	
			Test["Start TC3:"] = function(self)
				print ("\27[33m TC3. 1 App - NONE - LIMITED - OnDriverDistraction -> OnDriverDistraction come (in case of Resumption) \27[0m")
			end
		
		--Begin Test case [App changes HMI level from NONE].3
		--Description: 1 App - NONE - LIMITED - OnDriverDistraction -> OnDriverDistraction come (in case of Resumption)			
			commonSteps:ChangeHMIToLimited("ChangeHMIToLimited_TC3")
			for i=1,#onDriverDistractionValue do
				local request = {state = onDriverDistractionValue[i]}
				RestartSDL( "Resumption_LIMITED_ByIGN_OFF_TC3_time:"..tostring(i), "LIMITED")				
				Test["Resumption_LIMITED_ByIGN_OFF_AppChangesHMILevelFromNONE_TC3_time:"..tostring(i)] = function(self)
						self.mobileSession:StartService(7)
							:Do(function(_,data)
								RegisterApp_HMILevelResumption(self, "LIMITED", "IGN_OFF")
							end)
				end

				Test["TC3:_"..APIName.."1App_NONE_LIMITED_OnDriverDistraction_(state:"..onDriverDistractionValue[i]..")"] = function(self)
					self:verify_SUCCESS_Case(request)
				end

			end

		--End Test case [App changes HMI level from NONE].3	
	
			Test["Start TC4:"] = function(self)
				print ("\27[33m TC4. 1 App - NONE - OnDriverDistraction - LIMITED -> OnDriverDistraction come (in case of Resumption) \27[0m")
			end		
		
		--Begin Test case [App changes HMI level from NONE].4
		--Description: 1 App - NONE - OnDriverDistraction - LIMITED -> OnDriverDistraction come (in case of Resumption)
			--Precondition: change the Timeout Value to delay the HMI level in NONE 10 seconds before change to LIMITED
			UpdateApplicationResumingTimeoutValue(10000)

			for i=1,#onDriverDistractionValue do
				local request = {state = onDriverDistractionValue[i]}
				RestartSDL( "Resumption_LIMITED_ByIGN_OFF_TC4_time:"..tostring(i), "LIMITED")				
				Test["Resumption_LIMITED_ByIGN_OFF_AppChangesHMILevelFromNONE_TC4_time:"..tostring(i)] = function(self)
					self.mobileSession:StartService(7)
						:Do(function(_,data)
								local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

								--hmi side: sending OnAppRegistered notification
								EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
									:Do(function(_,data)
										HMIAppID = data.params.application.appID
										self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
									end)
									
								--mobile side: expect response
								self.mobileSession:ExpectResponse(correlationId, { success = true })						
							
								--mobile side: expect response
								EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE"})
									:Do(function(_,data)
											--hmi side: sending OnDriverDistraction notification
											self.hmiConnection:SendNotification("UI.OnDriverDistraction",request)
									end)
						end)								
				end
		
				Test["TC4:_"..APIName.."1App_NONE_OnDriverDistraction_LIMITED_(state:"..onDriverDistractionValue[i]..")"] = function(self)	
				
					DelayedExp(10000)
					
					--mobile side: expect response
					EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "LIMITED"})	

					--mobile side: expect the response
					EXPECT_NOTIFICATION("OnDriverDistraction", request)
				
				end
			end

			--Postcondition: return the Resume Timeout value
			UpdateApplicationResumingTimeoutValue(3000)

		--End Test case [App changes HMI level from NONE].4	

			Test["Start TC5:"] = function(self)
				print ("\27[33m TC5. 1 App - OnDriverDistraction - NONE - LIMITED -> OnDriverDistraction come (in case of Resumption) \27[0m")
			end	
		
		--Begin Test case [App changes HMI level from NONE].5
		--Description: 1 App - OnDriverDistraction - NONE - LIMITED -> OnDriverDistraction come (in case of Resumption)

		for i=1,#onDriverDistractionValue do
			local request = {state = onDriverDistractionValue[i]}
			RestartSDL( "Resumption_LIMITED_ByIGN_OFF_TC5_time:"..tostring(i), "LIMITED")						
			Test["TC5:_"..APIName.."1App_OnDriverDistraction_NONE_LIMITED_(state:"..onDriverDistractionValue[i]..")"] = function(self)				
				self.mobileSession:StartService(7)
				:Do(function(_,data)
					--hmi side: sending OnDriverDistraction notification
					self.hmiConnection:SendNotification("UI.OnDriverDistraction",request)	
					RegisterApp_HMILevelResumption(self, "LIMITED", "IGN_OFF")
				end)
				--mobile side: expect the response
				EXPECT_NOTIFICATION("OnDriverDistraction", request)
			end
		end
		--End Test case [App changes HMI level from NONE].5	
	
			Test["Start TC6:"] = function(self)
				print ("\27[33m TC6. 1 App - OnDriverDistraction - NONE - FULL -> OnDriverDistraction come \27[0m")
			end	
			
		--Begin Test case [App changes HMI level from NONE].6
		--Description: 1 App - OnDriverDistraction - NONE - FULL -> OnDriverDistraction come
		for i=1,#onDriverDistractionValue do
			local request = {state = onDriverDistractionValue[i]}
			--Precondition: Unregister application of mobileSession and add new session
			commonSteps:UnregisterApplication("Unregister_Application_of_previous_check_time:"..tostring(i))
			Test["Add_New_Session_time:"..tostring(i)] = function(self)
					-- Connected expectation
					self.mobileSession = mobile_session.MobileSession(
					self,
					self.mobileConnection)

					self.mobileSession:StartService(7)
			end
			--hmi side: sending OnDriverDistraction notification
			Test["Send_OnDriverDistraction_state:"..onDriverDistractionValue[i]] = function(self)				
				self.hmiConnection:SendNotification("UI.OnDriverDistraction",request)	
			
			end
			commonSteps:RegisterAppInterface("RegisterAppInterface_MediaApp_for_AppChangesHMILevelFromNONE_TC6_time:"..tostring(i))
			Test["TC6:_"..APIName.."1App_OnDriverDistraction_NONE_FULL_(state:"..onDriverDistractionValue[i]..")"] = function(self)				
				ActivationApp(self)
				self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL"})
				:Do(function(_,data)
					--mobile side: expect the response
					EXPECT_NOTIFICATION("OnDriverDistraction", request)		
				end)	
			end
		end
		--End Test case [App changes HMI level from NONE].6			

	--End Test suit App changes HMI level from NONE	
	
	--Test suite OnDriverDistraction is allowed for NONE in Policy table
	
		--Requirement: [APPLINK-20886]
		--Description: Whether the app receives the notification in current HMILevel is defined by app's assigned Policies.
		commonFunctions:newTestCasesGroup("Test case: OnDriverDistraction is allowed for NONE in Policy table")
		--Precondition: Unregister the application on mobileSession of previous TestCase and Register a new application (HMI status = NONE)		
		commonSteps:UnregisterApplication("Unregister_Application_of_MobileSession_OnDriverDistractionIsAllowedForNONE")
		Test["AddNewSession_OnDriverDistractionIsAllowedForNONE"] =function(self)
				-- Connected expectation
				self.mobileSession = mobile_session.MobileSession(
				self,
				self.mobileConnection)

				self.mobileSession:StartService(7)
		end
		commonSteps:RegisterAppInterface("RegisterAppInterface_MediaApp_for_TC_OnDriverDistractionIsAllowedForNONE")
		--Precondition: Update Policy table
		local PermissionLinesForBase4 = 
[[							"OnDriverDistraction": {
							"hmi_levels": ["BACKGROUND",
							"FULL", 
							"LIMITED", 
							"NONE"
							]
						  }]].. ", \n"						  
		local PermissionLinesForGroup1 = nil
		local PermissionLinesForApplication = nil
		local PTName = policyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication, {"OnDriverDistraction"})	
		policyTable:updatePolicy(PTName)
	
		for i=1,#onDriverDistractionValue do	
			local request = {state = onDriverDistractionValue[i]}
			Test[APIName.." is_allowed_for_NONE_in_Policy_table_(state:"..onDriverDistractionValue[i]..")"] = function(self)
				self:verify_SUCCESS_Case(request)
			end		
		end

	--End Test suite OnDriverDistraction is allowed for NONE in Policy table		
---------------------------------------------------------------------------------------------
-------------------------------------------Postcondition-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Postconditions
	commonFunctions:newTestCasesGroup("Postconditions")
	
	Test["Stop_SDL"] = function(self)
		StopSDL()
	end 
