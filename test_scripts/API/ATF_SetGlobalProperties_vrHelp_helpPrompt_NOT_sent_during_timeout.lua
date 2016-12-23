-- ATF version: 2.2
-- CRQ: APPLINK-23652 [F-S] UI/TTS.SetGlobalProperties: mobile app does NOT send <vrHelp> and <helpPrompt> during 10 sec timer
-- Specified by: 
--		APPLINK-23759 [SetGlobalProperties] Mobile app does NOT send request and has registered Add/DeleteCommands
--		APPLINK-23760 [SetGlobalProperties] Mobile app does NOT send request and has NO registered Add/DeleteCommands
--		APPLINK-23761 [SetGlobalProperties] Conditions for SDL to send updated values of "vrHelp" and/or "helpPrompt" to HMI
--		APPLINK-23762 [SetGlobalProperties] SDL sends request by itself and HMI respond with any errorCode
--		APPLINK-23763 [SetGlobalProperties] SDL sends request by itself and HMI does NOT respond during <DefaultTimeout>


-- Related reqs and questions:
--	APPLINK-19475 [SetGlobalProperties]: Default values of <vrHelp> and <helpPrompt>
-- 	APPLINK-25897 Period of silence for "helpPrompt"
--	APPLINK-26640 What internal list with "vrHelp" and "helpPrompt" means?
--	APPLINK-28443 Is internal list with "vrHelp" and "helpPrompt" created only at Add/DeleteCommand succeeded by resumption?
--	APPLINK-26640 As mentioned in by TMelnyk: https://adc.luxoft.com/jira/browse/APPLINK-25897 It’s added to CRQ and specified with requirement- https://adc.luxoft.com/jira/browse/APPLINK-19476 from this CRQ. Note: If it’s single default value it shouldn’t be added.
--	APPLINK-28160 Should SDL separate  "helpPrompt" from .ini file for using as default.
--	APPLINK-6953 Optional Separation For Default Generated Prompts
--	APPLINK-13235 ResetGlobalProperties: send TTS.SetGlobalProperties with a redundant comma at the end of text value in timeoutPrompt parameter


---------------------------------------------------
os.execute("ps aux | grep -e smartDeviceLinkCore | awk '{print$2}'")
os.execute("kill -9 $(ps aux | grep -e smartDeviceLinkCore | awk '{print$2}')")

Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection = require('file_connection')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
require('user_modules/AppTypes')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

APIName = "SetGlobalProperties" -- set for required scripts
strMaxLengthFileName255 = string.rep("a", 251) .. ".png" -- set max length file name

local iTimeout = 5000
config.defaultProtocolVersion = 2
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
local strAppFolder = config.pathToSDL .. "storage/" ..config.application1.registerAppInterfaceParams.appID.. "_" .. config.deviceMAC.. "/"

local TimeActivateAppSuccess -- It is used to store time when app is registered

---------------------------------------------------------------------------------------------
--------------------------------------Delete/update files------------------------------------
---------------------------------------------------------------------------------------------
--Print new line to separate Preconditions
commonFunctions:newTestCasesGroup("Preconditions")

--Delete app_info.dat, logs and policy table
commonSteps:DeleteLogsFileAndPolicyTable()

function UpdatePolicy()
	commonPreconditions:BackupFile("sdl_preloaded_pt.json")
	local src_preloaded_json = config.pathToSDL .."sdl_preloaded_pt.json"
	local dest = "files/SetGlobalProperties_DISALLOWED.json"
	
	local filecopy = "cp " .. dest .." " .. src_preloaded_json
	
	os.execute(filecopy)
end

UpdatePolicy()

---------------------------------------------------------------------------------------------
---------------------------------------Common functions--------------------------------------
--------------------------------------------------------------------------------------------- 


local function GetTimeActivateApp(TestCaseName)
	Test[TestCaseName] = function(self)
		TimeActivateAppSuccess = timestamp()
		print("***[INFO] Time: " .. tostring(TimeActivateAppSuccess))
	end
end


local function AddCommand(self, icmdID)
	local TimeAddCmdSuccess = 0
	local cid = self.mobileSession:SendRPC("AddCommand",
	{
		cmdID = icmdID,
		menuParams = 
		{
			menuName ="Command" .. tostring(icmdID)
		}, 
		vrCommands = {"VRCommand" .. tostring(icmdID)}
	})
	
	--hmi side: expect UI.AddCommand request 
	EXPECT_HMICALL("UI.AddCommand", 
	{ 
		cmdID = icmdID,
		menuParams = 
		{
			menuName ="Command" .. tostring(icmdID)
		}, 
		--vrCommands = {"VRCommand" .. tostring(icmdID)}
	})
	:Do(function(_,data)
		--hmi side: sending UI.AddCommand response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	
	--hmi side: expect VR.AddCommand request 
	EXPECT_HMICALL("VR.AddCommand", 
	{ 
		cmdID = icmdID,
		type = "Command",
		vrCommands = {
			"VRCommand" .. tostring(icmdID)
		}
	})
	:Do(function(_,data)
		--hmi side: sending VR.AddCommand response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end) 
	--mobile side: expect AddCommand response
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
	
	--mobile side: expect OnHashChange notification
	EXPECT_NOTIFICATION("OnHashChange")
	:Do(function(_, data)
		self.currentHashID = data.payload.hashID
	end)
	
end

local function IGNITION_OFF(self, appNumber)
	
	-- if appNumber == nil then 
		-- appNumber = 1
	-- end
	
	-- -- hmi side: sends OnExitAllApplications (SUSPENDED)
	-- self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
	-- {
		-- reason = "IGNITION_OFF"
	-- })
	
	-- -- hmi side: expect OnSDLClose notification
	-- EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
	
	-- -- hmi side: expect OnAppUnregistered notification
	-- EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
	-- :Times(appNumber)
	
	StopSDL()
end


-- APPLINK-25897 Period of silence for "helpPrompt"
-- APPLINK-23760 [SetGlobalProperties] Mobile app does NOT send request and has NO registered Add/DeleteCommands
local function Verify_UI_TTS_SetGlobalProperties_InCase_NoSGP_from_App_SDL_Sends_SGP_After_10secTimer(TestCaseName)

	-- APPLINK-25897 Period of silence for "helpPrompt"
	Test[TestCaseName] = function(self)
		
		--hmi side: expect UI.SetGlobalProperties request
		EXPECT_HMICALL("UI.SetGlobalProperties",
		{
			vrHelpTitle = config.application1.registerAppInterfaceParams.appName,
			vrHelp = { 
				{
					text = config.application1.registerAppInterfaceParams.appName,
					position = 1
				} 
			},
			appID = self.applications[config.application1.registerAppInterfaceParams.appName]
		})	
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:ValidIf(function(_,data)
			local currentTime  = timestamp() 
			if currentTime - TimeActivateAppSuccess < 10000 or currentTime - TimeActivateAppSuccess > 12000 then -- because we cannot get exactly time so we accept timeout is from 10 to 12 seconds.
				commonFunctions:printError(" SDL sends UI.SetGlobalProperties to HMI before timeout 10000. Actual timeout is " .. tostring(currentTime - TimeActivateAppSuccess)  .. " milliseconds.  Time for  activating app is around " .. TimeActivateAppSuccess  .. " milliseconds, time for HMI receiving UI.SetGlobalProperties is " .. currentTime  .. " milliseconds")
				return false
			else
				print("******[INFO]: Timeout for SDL sends UI.SetGlobalProperties to HMI is " .. tostring(currentTime - TimeActivateAppSuccess)  .. " milliseconds")
				return true
			end
		end)
		
		-- APPLINK-25897 Period of silence for "helpPrompt"
		--hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties",
		{
			helpPrompt = 
			{
				{
					text = default_HelpPromt1,
					type = "TEXT"
				},
				{
					text = "300",
					type = "SILENCE"
				},
				{
					text = default_HelpPromt2,
					type = "TEXT"
				},
				{
					text = "300",
					type = "SILENCE"
				}		
			},
			appID = self.applications[config.application1.registerAppInterfaceParams.appName]
		})
		:Do(function(_,data)
			--hmi side: sending TTS.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end) 
		:ValidIf(function(_,data)
			local currentTime  = timestamp() 
			if currentTime - TimeActivateAppSuccess < 10000 or currentTime - TimeActivateAppSuccess > 12000 then -- because we cannot get exactly time so we accept timeout is from 10 to 12 seconds. 
				commonFunctions:printError(" SDL sends TTS.SetGlobalProperties to HMI before timeout 10000. Actual timeout is " .. tostring(currentTime - TimeActivateAppSuccess)  .. " milliseconds.  Time for  activating app is around " .. TimeActivateAppSuccess  .. " milliseconds, time for HMI receiving TTS.SetGlobalProperties is " .. currentTime  .. " milliseconds")
				return false
			else
				print("******[INFO]: Timeout for SDL sends TTS.SetGlobalProperties to HMI is " .. tostring(currentTime - TimeActivateAppSuccess)  .. " milliseconds")
				return true
			end
		end)		
		
	end
	
end



---------------------------------------------------------------------------------------------
-------------------------------------------PreConditions-------------------------------------
---------------------------------------------------------------------------------------------

function GetValueInIniFile(FindExpression)
	
	local SDLini = config.pathToSDL .. "smartDeviceLink.ini"
	
	f = assert(io.open(SDLini, "r"))
	if f then
		fileContent = f:read("*all")
		
		fileContentFind = fileContent:match(FindExpression)
		
		if fileContentFind then
			--Get the first line
			local temp = fileContentFind:match("[^\n]*") 
			
			--Return message from the end of line to "="
			return temp:match("[^=]*$") 
		else
			commonFunctions:printError("Parameter is not found")
		end
		f:close()
	else
		commonFunctions:printError("Cannot open file")
	end
	
	
end

-- ToDo: Using "HelpPrompt" parameter when APPLINK-28270 (Help promt parameter name is not correct in smartDeviceLink.ini) is fixed.
--local default_HelpPromt = GetValueInIniFile("HelpPrompt*%s*=[%s*%a*%p*]*")
local default_HelpPromt = GetValueInIniFile("HelpProm%a*%s*=[%s*%a*%p*]*")
print("*** [INFO]: Value of HelpPrompt in ini file is '" .. default_HelpPromt .. "'")

local default_HelpPromt1 = default_HelpPromt:match("([^ ][^,]+)")
default_HelpPromt1 = default_HelpPromt1 .. "," 

local default_HelpPromt2 = default_HelpPromt:match("[^,]*$")
default_HelpPromt2 = default_HelpPromt2 .. ","
print("*** [INFO]: The default HelpPrompt is '" .. default_HelpPromt1 .. "'")
print("*** [INFO]: The default default_HelpPromt2 is '" .. default_HelpPromt2 .. "'")



---------------------------------------------------------------------------------------------
----------------------------------------------Body-------------------------------------------
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
-- req #1: value from list
-- APPLINK-23759 [SetGlobalProperties] Mobile app does NOT send request and has registered Add/DeleteCommands
-- Verification criteria:
-- In case:
-- 		mobile app does NOT send SetGlobalProperties_request at all with <vrHelp> and <helpPrompt> during 10 sec timer
-- 		and this mobile app has successfully registered AddCommands 
-- 		and/or DeleteCommands requests (previously added OR resumed within data resumption)
-- SDL must:
-- 		provide the value of <helpPrompt> and <vrHelp> from internal list based on registered AddCommands and DeleteCommands requests to HMI (please see APPLINK-19474)

---------------------------------------------------------------------------------------------

local function Req1_APPLINK_23759_ResumeAddCommand_NOT_ResumeSetGlobalProperties(TestName)
	
	
	commonSteps:UnregisterApplication(TestName .. "_Precondition_UnregisterApp")
	commonSteps:RegisterAppInterface(TestName .. "_RegisterApp")
	commonSteps:ActivationApp(_, TestName .. "_ActivationApp")	


	Test[TestName .. "_Precondition_AddCommandInitial_1"] = function(self)
		
		
		local cid = self.mobileSession:SendRPC("AddCommand",
		{
			cmdID = 1,
			menuParams = 
			{
				menuName ="Command_1"
			}, 
			vrCommands = {"VRCommand_1"}
		})
		
		--hmi side: expect UI.AddCommand request 
		EXPECT_HMICALL("UI.AddCommand", 
		{ 
			cmdID = 1,
			menuParams = 
			{
				menuName ="Command_1"
			}
		})
		:Do(function(_,data)
			--hmi side: sending UI.AddCommand response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		
		--hmi side: expect VR.AddCommand request 
		EXPECT_HMICALL("VR.AddCommand", 
		{ 
			cmdID = 1,
			type = "Command",
			vrCommands = {"VRCommand_1"}
		})
		:Do(function(_,data)
			--hmi side: sending VR.AddCommand response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end) 

		--mobile side: expect AddCommand response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
		
		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		
		commonTestCases:DelayedExp(2000)
		
		--hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties", {})
		:Times(0)
		
		--hmi side: expect UI.SetGlobalProperties request
		EXPECT_HMICALL("UI.SetGlobalProperties", {})
		:Times(0)	
				

	end
		

	-- IGN_OFF: 1. SUSPEND, 2. IGN_OFF
	Test[TestName .. "_Precondition_SuspendFromHMI"] = function(self)
		self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "SUSPEND"})
		
		-- hmi side: expect OnSDLPersistenceComplete notification
		EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
	end
	
	Test[TestName .. "_Precondition_IGN_OFF"] = function(self)
		IGNITION_OFF(self, 1)
	end
	
	-- Start SDL
	Test[TestName .. "_Precondition_StartSDL"] = function(self)
		StartSDL(config.pathToSDL, config.ExitOnCrash)
		commonTestCases:DelayedExp(1000)
	end
	
	Test[TestName .. "_Precondition_InitHMI"] = function(self)
		self:initHMI()
	end
	
	Test[TestName .. "_Precondition_InitHMI_onReady"] = function(self)
		self:initHMI_onReady()
	end
	
	Test[TestName .. "_Precondition_ConnectMobile"] = function(self)
		self:connectMobile()
	end
	
	Test[TestName .. "_Precondition_StartSession"] = function(self)
		self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
	end
	
	
	--APPLINK-28296 SDL cannot resume persisted data (AddCommand)
	--APPLINK-15683 [Data Resumption]: SDL data resumption SUCCESS sequence
	Test[TestName .. "_RegisterApp"] = function(self)
	
		TimeActivateAppSuccess = timestamp() -- Time when starting register app
		print("***[INFO] Time when app is registered: " .. tostring(TimeActivateAppSuccess))
				
		commonTestCases:DelayedExp(2000)
		
		config.application1.registerAppInterfaceParams.hashID = self.currentHashID
				
		self.mobileSession:StartService(7)
		:Do(function() 
			-- mobile side: sends RegisterAppInterface with hashID parameter
			local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
			
			--hmi side: expect BasicCommunication.OnAppRegistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
			{ application = { appName = config.application1.registerAppInterfaceParams.appName }})
			:Do(function(_,data)
				self.applications[data.params.application.appName] = data.params.application.appID
			end)
			
			
			--hmi side: expect BasicCommunication.ActivateApp
			EXPECT_HMICALL("BasicCommunication.ActivateApp", {})
			:Do(function(_,data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				TimeActivateAppSuccess = timestamp()
				print("***[INFO] Time when app is activated: " .. tostring(TimeActivateAppSuccess))
			end)
			:Timeout(40000)
			
			
			--hmi side: expect UI.AddCommand according to resumption requirement 
			EXPECT_HMICALL("UI.AddCommand", 
			{
				cmdID = 1,
				menuParams = {
					menuName = "Command_1",
					parentID = 0
				}
			})
			:Do(function(_,data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			
			--hmi side: expect VR.AddCommand is not sent to VR. VR.AddCommands should be resumed on HMI side (SDL just remember VR portion and resume without sending to HMI) 
			EXPECT_HMICALL("VR.AddCommand", {})
			:Times(0)
			

			--hmi side: expect UI.SetGlobalProperties according to resumption requirement
			EXPECT_HMICALL("UI.SetGlobalProperties", 
			{
				vrHelp = {
					{
						position = 1,
						text = "VRCommand_1"
					}
				}
			})
			:Do(function(_,data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			:ValidIf(function(_,data)
				local currentTime  = timestamp() 
				if currentTime - TimeActivateAppSuccess < 10000 or currentTime - TimeActivateAppSuccess > 12000 then -- because we cannot get exactly time so we accept timeout is from 10 to 12 seconds.
					commonFunctions:printError(" SDL sends UI.SetGlobalProperties to HMI before timeout 10000. Actual timeout is " .. tostring(currentTime - TimeActivateAppSuccess) .. ".  Time for  activating app is around " .. TimeActivateAppSuccess .. ", time for HMI receiving UI.SetGlobalProperties is " .. currentTime)
					return false
				else
					print("******[INFO]: Timeout for SDL sends UI.SetGlobalProperties to HMI is " .. tostring(currentTime - TimeActivateAppSuccess))
					return true
				end
			end)	
			:Timeout(15000)			

			--hmi side: expect TTS.SetGlobalProperties according to resumption requirement so timeout is about 3s instead of 10s
			EXPECT_HMICALL("TTS.SetGlobalProperties", 
			{
				helpPrompt = {
					{
						text = "VRCommand_1",
						type = "TEXT"
					}		
				}
			})
			:Do(function(_,data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			:ValidIf(function(_,data)
				local currentTime  = timestamp() 
				if currentTime - TimeActivateAppSuccess < 10000 or currentTime - TimeActivateAppSuccess > 12000 then -- because we cannot get exactly time so we accept timeout is from 10 to 12 seconds. 
					commonFunctions:printError(" SDL sends TTS.SetGlobalProperties to HMI before timeout 10000. Actual timeout is " .. tostring(currentTime - TimeActivateAppSuccess) .. ".  Time for  activating app is around " .. TimeActivateAppSuccess .. ", time for HMI receiving TTS.SetGlobalProperties is " .. currentTime)
					return false
				else
					print("******[INFO]: Timeout for SDL sends TTS.SetGlobalProperties to HMI is " .. tostring(currentTime - TimeActivateAppSuccess))
					return true
				end
			end)
			:Timeout(15000)
			

			
			--mobile side: expect RegisterAppInterface response
			self.mobileSession:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS", info = "Resume succeeded."})
			
			--mobile side: expect notification
			self.mobileSession:ExpectNotification("OnHMIStatus", 
			{systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"},
			{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"}
			)
			:Times(2)
		
		end)
		
		
	end 
end


 --Print new line to separate Preconditions
 commonFunctions:newTestCasesGroup("Req1_APPLINK_23759_case_1_ResumeAddCommand_NOT_ResumeSetGlobalProperties")		
 Req1_APPLINK_23759_ResumeAddCommand_NOT_ResumeSetGlobalProperties("Req1_case_1")
 
 

-- Defect APPLINK-28296 SDL cannot resume persisted data (AddCommand)
-- SDL sends SetGlobalProperties to UI and TTS after registering because of resumption function 
local function Req1_APPLINK_23759_ResumeAddCommand_And_SetGlobalProperties(TestName)
	
	
	commonSteps:UnregisterApplication(TestName .. "_Precondition_UnregisterApp")
	commonSteps:RegisterAppInterface(TestName .. "_RegisterApp")
	GetTimeActivateApp(TestName .. "_GetTimeWhenAppIsActivated")
	commonSteps:ActivationApp(_, TestName .. "_ActivationApp")	
	
	Verify_UI_TTS_SetGlobalProperties_InCase_NoSGP_from_App_SDL_Sends_SGP_After_10secTimer(TestName .. "_NoSGP_from_App_SDL_Sends_SGP_After_10secTimer")
	
	-- App has registered, add 2 commands
	for cmdCount = 1, 2 do
		Test[TestName .. "_Precondition_AddCommandInitial_" .. cmdCount] = function(self)
			AddCommand(self, cmdCount)
		end
	end 
	

	-- IGN_OFF: 1. SUSPEND, 2. IGN_OFF
	Test[TestName .. "_Precondition_SuspendFromHMI"] = function(self)
		self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "SUSPEND"})
		
		-- hmi side: expect OnSDLPersistenceComplete notification
		EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
	end
	
	Test[TestName .. "_Precondition_IGN_OFF"] = function(self)
		IGNITION_OFF(self, 1)
	end
	
	-- Start SDL
	Test[TestName .. "_Precondition_StartSDL"] = function(self)
		StartSDL(config.pathToSDL, config.ExitOnCrash)
		commonTestCases:DelayedExp(1000)
	end
	
	Test[TestName .. "_Precondition_InitHMI"] = function(self)
		self:initHMI()
	end
	
	Test[TestName .. "_Precondition_InitHMI_onReady"] = function(self)
		self:initHMI_onReady()
	end
	
	Test[TestName .. "_Precondition_ConnectMobile"] = function(self)
		self:connectMobile()
	end
	
	Test[TestName .. "_Precondition_StartSession"] = function(self)
		self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
	end
	
	-- Register App and app is resumed to FULL hmi level, 
	-- APPLINK-15683 [Data Resumption]: SDL data resumption SUCCESS sequence
	-- Defect: APPLINK-28296 SDL cannot resume persisted data (AddCommand)
	Test[TestName .. "_RegisterApp_SDL_Resumes_AddCommand_SGP"] = function(self)
	
		commonTestCases:DelayedExp(2000)
		
		config.application1.registerAppInterfaceParams.hashID = self.currentHashID
				
		self.mobileSession:StartService(7)
		:Do(function() 
			-- mobile side: sends RegisterAppInterface with hashID parameter
			local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
			
			--hmi side: expect BasicCommunication.OnAppRegistered
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
			{ application = { appName = config.application1.registerAppInterfaceParams.appName }})
			:Do(function(_,data)
				self.applications[data.params.application.appName] = data.params.application.appID
			end)
			
			
			--hmi side: expect BasicCommunication.ActivateApp
			EXPECT_HMICALL("BasicCommunication.ActivateApp", {})
			:Do(function(_,data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				TimeActivateAppSuccess = timestamp()
				print("***[INFO] Time when app is registered: " .. tostring(TimeActivateAppSuccess))
			end)
			:Timeout(40000)
			
			
			--hmi side: expect UI.AddCommand according to resumption requirement 
			EXPECT_HMICALL("UI.AddCommand", 
			{
				cmdID = 1,
				menuParams = {
					menuName = "Command1",
					parentID = 0
				}
			},
			{
				cmdID = 2,
				menuParams = {
					menuName = "Command2",
					parentID = 0
				}
			})
			:Times(2)
			:Do(function(_,data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			
			--hmi side: expect VR.AddCommand is not sent to VR. VR.AddCommands should be resumed on HMI side (SDL just remember VR portion and resume without sending to HMI) 
			EXPECT_HMICALL("VR.AddCommand", {})
			:Times(0)

			--hmi side: expect UI.SetGlobalProperties according to resumption requirement so timeout is about 3s instead of 10s
			EXPECT_HMICALL("UI.SetGlobalProperties", 
			{
				vrHelp = {
					{
						position = 1,
						text = "VRCommand1"
					},
					{
						position = 2,
						text = "VRCommand2"
					}					
				}
			})
			:Do(function(_,data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			:Timeout(3000)

			--hmi side: expect TTS.SetGlobalProperties according to resumption requirement so timeout is about 3s instead of 10s
			EXPECT_HMICALL("TTS.SetGlobalProperties", 
			{
				helpPrompt = {
					{
						text = "VRCommand1",
						type = "TEXT"
					},
					{
						text = "300",
						type = "SILENCE"
					},
					{
						text = "VRCommand2",
						type = "TEXT"
					},
					{
						text = "300",
						type = "SILENCE"
					}					
				}
			})
			:Do(function(_,data)
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end)
			:Timeout(3000)			
 
			
			--mobile side: expect RegisterAppInterface response
			self.mobileSession:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS", info = "Resume succeeded."})
			
			--mobile side: expect notification
			self.mobileSession:ExpectNotification("OnHMIStatus", 
			{systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"},
			{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"}
			)
			:Times(2)
		
		end)
		
		
	end 

	-- Question APPLINK-28334
	Test[TestName .. "_SDL_DoesNotSend_SGP_again_if_ItWasSentByResumption"] = function(self)
		
		commonTestCases:DelayedExp(15000)
		
		--hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties", {})
		:Times(0)
		
		--hmi side: expect UI.SetGlobalProperties request
		EXPECT_HMICALL("UI.SetGlobalProperties", {})
		:Times(0)
		
	end
	
	
end

 --Print new line to separate Preconditions
 commonFunctions:newTestCasesGroup("Req1_APPLINK_23759_case_2_ResumeAddCommand_And_SetGlobalProperties")		
 Req1_APPLINK_23759_ResumeAddCommand_And_SetGlobalProperties("Req1_case_2")


 
---------------------------------------------------------------------------------------------
-- req #2: Default value 
-- req: Happy Path
-- APPLINK-23760 [SetGlobalProperties] Mobile app does NOT send request and has NO registered Add/DeleteCommands
-- Verification criteria:
-- In case:
-- 		mobile app does NOT send SetGlobalProperties_request at all with <vrHelp> and <helpPrompt> during 10 sec timer
-- 		and this mobile app has NO registered AddCommands 
-- 		and/or DeleteCommands requests (resumed during data resumption)
-- SDL must:
-- 		provide the default values of <helpPrompt> and <vrHelp> to HMI (Please see APPLINK-19475)

--	APPLINK-19475 [SetGlobalProperties]: Default values of <vrHelp> and <helpPrompt> 
---------------------------------------------------------------------------------------------

local function Req2_APPLINK_23760(TestCaseName)
	
	commonSteps:UnregisterApplication(TestCaseName .. "_Precondition_UnregisterApp")

	commonSteps:RegisterAppInterface(TestCaseName .. "_RegisterApp")
	GetTimeActivateApp(TestCaseName .. "_GetTimeWhenAppIsActivated")
	commonSteps:ActivationApp(_, TestCaseName .. "_ActivationApp")	

	Verify_UI_TTS_SetGlobalProperties_InCase_NoSGP_from_App_SDL_Sends_SGP_After_10secTimer(TestCaseName .. "_NoSGP_from_App_SDL_Sends_SGP_After_10secTimer")

end

--Print new line to separate Preconditions
commonFunctions:newTestCasesGroup("Req2_APPLINK_23760_case_1_Mobile app does NOT send request and has NO registered Add/DeleteCommands")		
Req2_APPLINK_23760("Req2_case_1")


local function Req2_APPLINK_23760_unclearPoint(TestName)
		
	commonSteps:UnregisterApplication(TestName .. "_Precondition_UnregisterApp")
	commonSteps:RegisterAppInterface(TestName .. "_RegisterApp")
	GetTimeActivateApp(TestName .. "_GetTimeWhenAppIsActivated")
	commonSteps:ActivationApp(_, TestName .. "_ActivationApp")	
	
	Test[TestName .. "_AddCommand_Success_WaitForTimeoutForSDLSendsSetGlobalProperties"] = function(self)
		
		
		local cid = self.mobileSession:SendRPC("AddCommand",
		{
			cmdID = 1,
			menuParams = 
			{
				menuName ="Command_1"
			}, 
			vrCommands = {"vrCommand_1"}
		})
		
		--hmi side: expect UI.AddCommand request 
		EXPECT_HMICALL("UI.AddCommand", 
		{ 
			cmdID = 1,
			menuParams = 
			{
				menuName ="Command_1"
			}
		})
		:Do(function(_,data)
			--hmi side: sending UI.AddCommand response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		
		--hmi side: expect VR.AddCommand request 
		EXPECT_HMICALL("VR.AddCommand", 
		{ 
			cmdID = 1,
			type = "Command",
			vrCommands = {"vrCommand_1"}
		})
		:Do(function(_,data)
			--hmi side: sending VR.AddCommand response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end) 

		--mobile side: expect AddCommand response
		EXPECT_RESPONSE(cid, { success = true, resultCode = Mobile_ResultCode })
				
		--hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties",
		{
			helpPrompt = 
			{
				{
					text = "vrCommand_1",
					type = "TEXT"
				}
			},
			appID = self.applications[config.application1.registerAppInterfaceParams.appName]
		})
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:ValidIf(function(_,data)
			local currentTime  = timestamp() 
			if currentTime - TimeActivateAppSuccess < 10000 or currentTime - TimeActivateAppSuccess > 12000 then -- because we cannot get exactly time so we accept timeout is from 10 to 12 seconds. 
				commonFunctions:printError(" SDL sends TTS.SetGlobalProperties to HMI before timeout 10000. Actual timeout is " .. tostring(currentTime - TimeActivateAppSuccess) .. ".  Time for  activating app is around " .. TimeActivateAppSuccess .. ", time for HMI receiving TTS.SetGlobalProperties is " .. currentTime)
				return false
			else
				print("******[INFO]: Timeout for SDL sends TTS.SetGlobalProperties to HMI is " .. tostring(currentTime - TimeActivateAppSuccess))
				return true
			end
		end)
		
		--hmi side: expect UI.SetGlobalProperties request
		EXPECT_HMICALL("UI.SetGlobalProperties",
		{
			vrHelpTitle = config.application1.registerAppInterfaceParams.appName,
			vrHelp = { 
				{
					text = "vrCommand_1",
					position = 1
				} 
			}, 
		})		
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		:ValidIf(function(_,data)
			local currentTime  = timestamp() 
			if currentTime - TimeActivateAppSuccess < 10000 or currentTime - TimeActivateAppSuccess > 12000 then -- because we cannot get exactly time so we accept timeout is from 10 to 12 seconds.
				commonFunctions:printError(" SDL sends UI.SetGlobalProperties to HMI before timeout 10000. Actual timeout is " .. tostring(currentTime - TimeActivateAppSuccess) .. ".  Time for  activating app is around " .. TimeActivateAppSuccess .. ", time for HMI receiving UI.SetGlobalProperties is " .. currentTime)
				return false
			else
				print("******[INFO]: Timeout for SDL sends UI.SetGlobalProperties to HMI is " .. tostring(currentTime - TimeActivateAppSuccess))
				return true
			end
		end)		
				

	end
	
end

 --Print new line to separate Preconditions
 commonFunctions:newTestCasesGroup("Req2_APPLINK_23760_case_2_AddCommandIsSentBeforeTimeout")		
 -- Defect APPLINK-28301: [PASA_Ubuntu]SDL sends UI/TTS.SetGlobalProperties without waiting 10 sec timeout at AddCommand(SUCCESS) if SetGlobalProperties isn't sent be mobile.
 Req2_APPLINK_23760_unclearPoint("Req2_case_2")


 
 
---------------------------------------------------------------------------------------------
-- req #3: update list condition
-- APPLINK-23761 [SetGlobalProperties] Conditions for SDL to send updated values of "vrHelp" and/or "helpPrompt" to HMI
-- Verification criteria:
-- In case:
-- 		mobile app does NOT send SetGlobalProperties with <vrHelp> and <helpPrompt> to SDL during 10 sec timer
-- 		and SDL already sends by itself UI/TTS.SetGlobalProperties with values of <vrHelp> and <helpPrompt> to HMI
-- 		and mobile app sends AddCommand 
-- 		and/or DeleteCommand requests to SDL
-- SDL must:
-- 		update internal list with new values of "vrHelp" and "helpPrompt" params ONLY after successful response from HMI
-- 		send updated values of "vrHelp" and "helpPrompt" via TTS/UI.SetGlobalProperties to HMI till mobile app sends SetGlobalProperties request with valid <vrHelp> and <helpPrompt> params to SDL
---------------------------------------------------------------------------------------------


local function Req3_APPLINK_23761_AddCommand_SUCCESS(TestCaseName)
	
	
	commonSteps:UnregisterApplication(TestCaseName .. "_Precondition_UnregisterApp")
	
	
	commonSteps:RegisterAppInterface(TestCaseName .. "_RegisterApp")
	GetTimeActivateApp(TestCaseName)
	commonSteps:ActivationApp(_, TestCaseName .. "_ActivationApp")	
	
	Verify_UI_TTS_SetGlobalProperties_InCase_NoSGP_from_App_SDL_Sends_SGP_After_10secTimer(TestCaseName .. "_NoSGP_from_App_SDL_Sends_SGP_After_10secTimer")

	local Interfaces = {"UI", "VR"}
	
	local ResultCodes = {	
		{HMI_resultCode = "SUCCESS", 				Mobile_resultCode = "SUCCESS"},
		{HMI_resultCode = "WARNINGS", 				Mobile_resultCode = "WARNINGS"},
		{HMI_resultCode = "UNSUPPORTED_RESOURCE", 	Mobile_resultCode = "UNSUPPORTED_RESOURCE"} --defect APPLINK-28416
	}	

	--local CommandIDs = {}
	local icmdNumber = 0
	local Expected_helpPrompt = {}
	local Expected_vrHelp = {}
	for j =1, #ResultCodes do

		local ResultCode = ResultCodes[j].HMI_resultCode
		local Mobile_ResultCode = ResultCodes[j].Mobile_resultCode
			
		for i = 1, #Interfaces do
		
			local Interface = Interfaces[i]
			
			Test[TestCaseName .. "_" .. Interface .. "_" .. ResultCode .. "_SDL_Sends_SetGlobalProperties"] = function(self)
				
				icmdNumber = icmdNumber + 1
				local icmdID = 2000 + icmdNumber
				vrCommand = "VRCommand" .. tostring(icmdNumber)
				-- APPLINK-26640 As mentioned in by TMelnyk: https://adc.luxoft.com/jira/browse/APPLINK-25897 It’s added to CRQ and specified with requirement- https://adc.luxoft.com/jira/browse/APPLINK-19476 from this CRQ. Note: If it’s single default value it shouldn’t be added.
				
				if icmdNumber == 1 then
					Expected_helpPrompt[1] = {
						text = vrCommand,
						type = "TEXT"
					}
				elseif icmdNumber == 2 then
					Expected_helpPrompt[2] = {
						text = "300",
						type = "SILENCE"
					}				
					Expected_helpPrompt[3] = {
						text = vrCommand,
						type = "TEXT"
					}
					Expected_helpPrompt[4] = {
						text = "300",
						type = "SILENCE"
					}
				else
					Expected_helpPrompt[2*icmdNumber -1 ] = {
						text = vrCommand,
						type = "TEXT"
					}
					Expected_helpPrompt[2*icmdNumber] = {
						text = "300",
						type = "SILENCE"
					}				
				end

				Expected_vrHelp[icmdNumber]	= {
						position = icmdNumber,
						text = vrCommand
				} 				
				
				local cid = self.mobileSession:SendRPC("AddCommand",
				{
					cmdID = icmdID,
					menuParams = 
					{
						menuName ="Command" .. tostring(icmdID)
					}, 
					vrCommands = {vrCommand}
				})
				
				--hmi side: expect UI.AddCommand request 
				EXPECT_HMICALL("UI.AddCommand", 
				{ 
					cmdID = icmdID,
					menuParams = 
					{
						menuName ="Command" .. tostring(icmdID)
					}
				})
				:Do(function(_,data)
					--hmi side: sending UI.AddCommand response
					if Interface == "UI" then 
						self.hmiConnection:SendResponse(data.id, data.method, ResultCode, {})
					else
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end	
					
				end)
				
				--hmi side: expect VR.AddCommand request 
				EXPECT_HMICALL("VR.AddCommand", 
				{ 
					cmdID = icmdID,
					type = "Command",
					vrCommands = {vrCommand}
				})
				:Do(function(_,data)
					--hmi side: sending VR.AddCommand response
					if Interface == "VR" then 
						self.hmiConnection:SendResponse(data.id, data.method, ResultCode, {})
					else
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end	
				end) 
				
				
		
				--mobile side: expect AddCommand response
				EXPECT_RESPONSE(cid, { success = true, resultCode = Mobile_ResultCode })
				
				--Verify SDL sends SetGlobalProperties to UI/TTS until mobile sends SetGlobalProperties valid request (in next test)
				
				--hmi side: expect UI.SetGlobalProperties request
				EXPECT_HMICALL("UI.SetGlobalProperties", 
				{
					vrHelp = Expected_vrHelp
				})
				:Do(function(_,data)
					--hmi side: sending UI.SetGlobalProperties response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end) 
				
				--hmi side: expect TTS.SetGlobalProperties request
				EXPECT_HMICALL("TTS.SetGlobalProperties", 
				{
					helpPrompt = Expected_helpPrompt
				})
				:Do(function(_,data)
					--hmi side: sending TTS.SetGlobalProperties response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end) 

				
				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
				:Do(function(_, data)
					self.currentHashID = data.payload.hashID
				end)
				
				
			end
		
		end		
	end
		
	
	
	Test[TestCaseName .. "_SetGlobalProperties_valid_vrHelp_helpPrompt"] = function(self)	
	
	
		--mobile side: sending SetGlobalProperties request
		local cid = self.mobileSession:SendRPC("SetGlobalProperties",
		{
			vrHelpTitle = "VR help title",
			vrHelp = 
			{
				{
					position = 1,
					text = "VR help item"
				}
			},			
			helpPrompt = 
			{
				{
					text = "Help prompt",
					type = "TEXT"
				}
			}
		
		})
	

		--hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties",
		{
			helpPrompt = 
			{
				{
					text = "Help prompt",
					type = "TEXT"
				}
			}
		})
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)

	

		--hmi side: expect UI.SetGlobalProperties request
		EXPECT_HMICALL("UI.SetGlobalProperties",
		{
			vrHelpTitle = "VR help title",			
			vrHelp = 
			{
				{
					position = 1,
					text = "VR help item"
				}
			}
		})
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)

		--mobile side: expect SetGlobalProperties response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
		
		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
	end


	Test[TestCaseName .. "_SDL_DOES_NOT_Send_SetGlobalProperties_When_AddCommand_Is_SUCCESS"] = function(self)
		

		local cid = self.mobileSession:SendRPC("AddCommand",
		{
			cmdID = 60,
			menuParams = 
			{
				menuName ="Command_60"
			}, 
			vrCommands = {"VRCommand_60"}
		})
		
		--hmi side: expect UI.AddCommand request 
		EXPECT_HMICALL("UI.AddCommand", 
		{ 
			cmdID = 60,
			menuParams = 
			{
				menuName ="Command_60"
			}
		})
		:Do(function(_,data)
			--hmi side: sending UI.AddCommand response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		
		--hmi side: expect VR.AddCommand request 
		EXPECT_HMICALL("VR.AddCommand", 
		{ 
			cmdID = 60,
			type = "Command",
			vrCommands = {
				"VRCommand_60"
			}
		})
		:Do(function(_,data)
			--hmi side: sending VR.AddCommand response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end) 
		
		
		--mobile side: expect AddCommand response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
		
		
		--Verify SDL does not send SetGlobalProperties to UI/TTS when mobile has already sent SetGlobalProperties with valid <vrHelp> and <helpPrompt> params 
		commonTestCases:DelayedExp(5000)
		
		--hmi side: expect UI.SetGlobalProperties request
		EXPECT_HMICALL("UI.SetGlobalProperties", {})
		:Times(0)
		
		--hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties", {})
		:Times(0)

		
		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		
	end
						
end


local function Req3_APPLINK_23761_AddCommand_FAILED(TestCaseName)
	
	local Interfaces = {"UI", "VR"}

	local ErrorCodes = {
		{HMI_resultCode = "REJECTED", 						Mobile_resultCode = "REJECTED"},
		{HMI_resultCode = "GENERIC_ERROR", 					Mobile_resultCode = "GENERIC_ERROR"},
		{HMI_resultCode = "INVALID_DATA", 					Mobile_resultCode = "GENERIC_ERROR"},
		{HMI_resultCode = "INVALID_ID", 					Mobile_resultCode = "GENERIC_ERROR"},
		{HMI_resultCode = "OUT_OF_MEMORY", 					Mobile_resultCode = "GENERIC_ERROR"},
		{HMI_resultCode = "TOO_MANY_PENDING_REQUESTS", 		Mobile_resultCode = "GENERIC_ERROR"},
		{HMI_resultCode = "APPLICATION_NOT_REGISTERED", 	Mobile_resultCode = "GENERIC_ERROR"},	
	}	
		
	--Print new line to separate Preconditions
	commonFunctions:newTestCasesGroup(TestCaseName)		
	
	commonSteps:UnregisterApplication(TestCaseName .. "_Precondition_UnregisterApp")
	commonSteps:RegisterAppInterface(TestCaseName .. "_RegisterApp")
	GetTimeActivateApp(TestCaseName )
	commonSteps:ActivationApp(_, TestCaseName .. "_ActivationApp")	
	
	Verify_UI_TTS_SetGlobalProperties_InCase_NoSGP_from_App_SDL_Sends_SGP_After_10secTimer(TestCaseName .. "_NoSGP_from_App_SDL_Sends_SGP_After_10secTimer")
	
	for j =1, #ErrorCodes do

		local ErrorCode = ErrorCodes[j].HMI_resultCode
		local Mobile_ErrorCode = ErrorCodes[j].Mobile_resultCode
			
		for i = 1, #Interfaces do
		
			local Interface = Interfaces[i]
			
			Test[TestCaseName .. "_" .. Interface .. "_" .. ErrorCode .. "_SDL_DOES_NOT_Send_SetGlobalProperties"] = function(self)
				
				if icmdID == nil then
					icmdID = 1000
				end
				icmdID = icmdID + 1
				
				local cid = self.mobileSession:SendRPC("AddCommand",
				{
					cmdID = icmdID,
					menuParams = 
					{
						menuName ="Command" .. tostring(icmdID)
					}, 
					vrCommands = {"VRCommand" .. tostring(icmdID)}
				})
				
				--hmi side: expect UI.AddCommand request 
				EXPECT_HMICALL("UI.AddCommand", 
				{ 
					cmdID = icmdID,
					menuParams = 
					{
						menuName ="Command" .. tostring(icmdID)
					}
				})
				:Do(function(_,data)
					--hmi side: sending UI.AddCommand response
					if Interface == "UI" then 
						if ErrorCode == nil then
							--UI does not respond
						else
							self.hmiConnection:SendError(data.id, data.method, ErrorCode, "Error message")
						end
					else
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end	
					
				end)
				
				--hmi side: expect VR.AddCommand request 
				EXPECT_HMICALL("VR.AddCommand", 
				{ 
					cmdID = icmdID,
					type = "Command",
					vrCommands = {
						"VRCommand" .. tostring(icmdID)
					}
				})
				:Do(function(_,data)
					--hmi side: sending VR.AddCommand response
					if Interface == "VR" then 
						if ErrorCode == nil then
							--VR does not respond
						else
							self.hmiConnection:SendError(data.id, data.method, ErrorCode, "Error message")
						end
					else
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end	
				end) 
				
				
				--Verify SDL does not send SetGlobalProperties to UI/TTS when AddCommand returns not SUCCESS
				commonTestCases:DelayedExp(4000)
				
				--hmi side: expect UI.SetGlobalProperties request
				EXPECT_HMICALL("UI.SetGlobalProperties", {})
				:Times(0)
				
				--hmi side: expect TTS.SetGlobalProperties request
				EXPECT_HMICALL("TTS.SetGlobalProperties", {})
				:Times(0)
				
				--mobile side: expect AddCommand response
				EXPECT_RESPONSE(cid, { success = false, resultCode = Mobile_ErrorCode })
							
				commonTestCases:DelayedExp(2000)
				
				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
				
			end
		end		
	end
	
end

--Print new line to separate Preconditions
commonFunctions:newTestCasesGroup([[Req3_APPLINK_23761 [SetGlobalProperties] Conditions for SDL to send updated values of 'vrHelp' and/or 'helpPrompt' to HMI.
--Case 1: AddCommand_responds_success_true
--Case 2: AddCommand_responds_success_false]])

Req3_APPLINK_23761_AddCommand_SUCCESS("Req3_case_1_AddCommand_responds_success_true")
Req3_APPLINK_23761_AddCommand_FAILED("Req3_case_2_AddCommand_responds_success_false")



---------------------------------------------------------------------------------------------
-- req #4: UI/TTS responds error
-- APPLINK-23762 [SetGlobalProperties] SDL sends request by itself and HMI respond with any errorCode
-- Verification criteria:
-- In case
-- 		mobile app does NOT send SetGlobalProperties with <vrHelp> and <helpPrompt> to SDL during 10 sec timer
-- 		and SDL already sends by itself UI/TTS.SetGlobalProperties with values of <vrHelp> and <helpPrompt> from to HMI
-- 		and SDL receives any <errorCode> at response from HMI at least to one TTS/UI.SetGlobalProperties
-- SDL must:
-- 		log corresponding error internally
-- 		continue work as assigned (due to existing requirements)
---------------------------------------------------------------------------------------------


-- This function is used for req 4 and 5: UI/TTS responds errorCode or does not respond
-- ErrorCode = nil: UI/TTS does not respond.
local function UI_or_TTS_responds_SetGlobalProperties_error(TestCaseName, Interface, ErrorCode)
	
	--Print new line to separate Preconditions
	commonFunctions:newTestCasesGroup(TestCaseName)		
	
	commonSteps:UnregisterApplication(TestCaseName .. "_Precondition_UnregisterApp")
	commonSteps:RegisterAppInterface(TestCaseName .. "_RegisterApp")
	GetTimeActivateApp(TestCaseName .. "_GetTimeWhenAppIsActivated")
	commonSteps:ActivationApp(_, TestCaseName .. "_ActivationApp")	
	
	
	Test[TestCaseName .. "_NoSGP_from_App_SDL_Sends_SGP_After_10secTimer"] = function(self)
		
		--hmi side: expect UI.SetGlobalProperties request
		EXPECT_HMICALL("UI.SetGlobalProperties",
		{
			vrHelpTitle = config.application1.registerAppInterfaceParams.appName,
			vrHelp = { 
				{
					text = config.application1.registerAppInterfaceParams.appName,
					position = 1
				} 
			}
		})
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			if Interface == "UI" or Interface == "UI_TTS" then 
				if ErrorCode == nil then
					--UI does not respond
				else
					self.hmiConnection:SendError(data.id, data.method, ErrorCode, "Error message")
				end
			else
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end	
		end)
		:ValidIf(function(_,data)
			local currentTime  = timestamp() 
			if currentTime - TimeActivateAppSuccess < 10000 or currentTime - TimeActivateAppSuccess > 12000 then -- because we cannot get exactly time so we accept timeout is from 10 to 12 seconds.
				commonFunctions:printError(" SDL sends UI.SetGlobalProperties to HMI before timeout 10000. Actual timeout is " .. tostring(currentTime - TimeActivateAppSuccess)  .. " milliseconds.  Time for  activating app is around " .. TimeActivateAppSuccess  .. " milliseconds, time for HMI receiving UI.SetGlobalProperties is " .. currentTime .. " milliseconds")
				return false
			else
				print("******[INFO]: Timeout for SDL sends UI.SetGlobalProperties to HMI is " .. tostring(currentTime - TimeActivateAppSuccess)  .. " milliseconds")
				return true
			end
		end)

		
		--hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties",
		{
			helpPrompt = 
			{
				{
					text = default_HelpPromt1,
					type = "TEXT"
				} 
			}
		})
		:Do(function(_,data)
			--hmi side: sending TTS.SetGlobalProperties response
			if Interface == "TTS" or Interface == "UI_TTS" then
				if ErrorCode == nil then
					--TTS does not respond
				else			
					self.hmiConnection:SendError(data.id, data.method, ErrorCode, "Error message")
				end
			else
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end	
		end) 
		:ValidIf(function(_,data)
			local currentTime  = timestamp() 
			if currentTime - TimeActivateAppSuccess < 10000 or currentTime - TimeActivateAppSuccess > 12000 then -- because we cannot get exactly time so we accept timeout is from 10 to 12 seconds. 
				commonFunctions:printError(" SDL sends TTS.SetGlobalProperties to HMI before timeout 10000. Actual timeout is " .. tostring(currentTime - TimeActivateAppSuccess)  .. " milliseconds.  Time for  activating app is around " .. TimeActivateAppSuccess .. ", time for HMI receiving TTS.SetGlobalProperties is " .. currentTime)
				return false
			else
				print("******[INFO]: Timeout for SDL sends TTS.SetGlobalProperties to HMI is " .. tostring(currentTime - TimeActivateAppSuccess))
				return true
			end
		end)		
		
	end
	
	
	
	-- SDL continue works as assigned (due to existing requirements)
	-- Mobile sends AddCommand and success response from SDL, SDL sends SetGlobalProperties with data from internal list.
	Test[TestCaseName .. "_AddCommand_success_true_SDL_Sends_SetGlobalProperties"] = function(self)
		
		--hmi side: expect UI.AddCommand request 
		local cid = self.mobileSession:SendRPC("AddCommand",
		{
			cmdID = 1,
			menuParams = 
			{
				menuName ="Command_1"
			}, 
			vrCommands = {"VRCommand_1"}
		})
		
		--hmi side: expect UI.AddCommand request 
		EXPECT_HMICALL("UI.AddCommand", 
		{ 
			cmdID = 1,
			menuParams = 
			{
				menuName ="Command_1"
			}
		})
		:Do(function(_,data)
			--hmi side: sending UI.AddCommand response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})			
		end)
		
		--hmi side: expect VR.AddCommand request 
		EXPECT_HMICALL("VR.AddCommand", 
		{ 
			cmdID = 1,
			type = "Command",
			vrCommands = {"VRCommand_1"}
		})
		:Do(function(_,data)
			--hmi side: sending VR.AddCommand response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end) 
		

		--mobile side: expect AddCommand response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
		
		--Verify SDL sends SetGlobalProperties to UI/TTS until mobile sends SetGlobalProperties valid request (in next test)
		
		--hmi side: expect UI.SetGlobalProperties request
		EXPECT_HMICALL("UI.SetGlobalProperties", 
		{
			vrHelp = {
				{
					position = 1,
					text = "VRCommand_1"
				}
			} 
		})
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			if Interface == "UI" or Interface == "UI_TTS" then 
				if ErrorCode == nil then
					--UI does not respond
				else
					self.hmiConnection:SendError(data.id, data.method, ErrorCode, "Error message")
				end
			else
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end		
		end) 
		
		
		--hmi side: expect TTS.SetGlobalProperties request
		-- APPLINK-26640 As mentioned in by TMelnyk: https://adc.luxoft.com/jira/browse/APPLINK-25897 It’s added to CRQ and specified with requirement- https://adc.luxoft.com/jira/browse/APPLINK-19476 from this CRQ. Note: If it’s single default value it shouldn’t be added.
		EXPECT_HMICALL("TTS.SetGlobalProperties", 
		{
			helpPrompt = 
			{
			{
					text = "VRCommand_1",
					type = "TEXT"
				}		
			}
		})
		:Do(function(_,data)
			--hmi side: sending TTS.SetGlobalProperties response
			if Interface == "TTS" or Interface == "UI_TTS" then 
				if ErrorCode == nil then
					--TTS does not respond
				else
					self.hmiConnection:SendError(data.id, data.method, ErrorCode, "Error message")
				end
			else
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			end		
		end) 

		
		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)
			self.currentHashID = data.payload.hashID
		end)
		
		
	end

		

end

local function Req4_APPLINK_23762(TestCaseName)
	
	local Interfaces = {
		"UI",  -- UI interface
		"TTS", -- TTS interface
		"UI_TTS" -- Both UI and TTS interfaces
	}
	local ErrorCodes = {
		"INVALID_DATA",
		"REJECTED",
		"DISALLOWED",
		"USER_DISALLOWED",
		"OUT_OF_MEMORY",
		"TOO_MANY_PENDING_REQUESTS",
		"UNSUPPORTED_RESOURCE",
		"WARNINGS",
		"GENERIC_ERROR",
		"APPLICATION_NOT_REGISTERED",
		-- "POSTPONED (NOT YET IMPLEMENTED)"
	}
	
	for i = 1, #Interfaces do
		for j =1, #ErrorCodes do
			local TestName = TestCaseName .. "_" .. Interfaces[i] .. "_" .. ErrorCodes[j]
			UI_or_TTS_responds_SetGlobalProperties_error(TestName, Interfaces[i], ErrorCodes[j])
		end
		
	end
	
end

--Print new line to separate Preconditions
commonFunctions:newTestCasesGroup("req4_APPLINK_23762 [SetGlobalProperties] SDL sends request by itself and HMI respond with any errorCode")

Req4_APPLINK_23762("Req4")



---------------------------------------------------------------------------------------------
-- req #5: UI/TTS does not respond
-- APPLINK-23763 [SetGlobalProperties] SDL sends request by itself and HMI does NOT respond during <DefaultTimeout>
-- Verification criteria:
-- In case
-- 		mobile app does NOT send SetGlobalProperties with <vrHelp> and <helpPrompt> to SDL during 10 sec timer
-- 		and SDL already sends by itself UI/TTS.SetGlobalProperties with values of <vrHelp> and <helpPrompt> to HMI
-- 		and SDL does NOT receive response from HMI at least to one TTS/UI.SetGlobalProperties during <DefaultTimeout> (the value defined at .ini file)
-- SDL must:
-- 		log corresponding error internally
-- 		continue work as assigned (due to existing requirements)
---------------------------------------------------------------------------------------------

local function Req5_APPLINK_23763(TestCaseName)
	
	local Interfaces = {"UI", "TTS", "UI_TTS"}
	
	for i = 1, #Interfaces do
		local TestName = TestCaseName .. "_" .. Interfaces[i]
		local ErrorCode = nil -- ErrorCode = nil means UI/TTS does not respond.
		UI_or_TTS_responds_SetGlobalProperties_error(TestName, Interfaces[i], ErrorCode) 
	end
end

--Print new line to separate Preconditions
commonFunctions:newTestCasesGroup("req5_APPLINK_23763 [SetGlobalProperties] SDL sends request by itself and HMI does NOT respond during <DefaultTimeout>")

Req5_APPLINK_23763("Req5")

---------------------------------------------------------------------------------------------
-------------------------------------------Postconditions------------------------------------
---------------------------------------------------------------------------------------------

function Test:Postcondition_remove_user_connecttest_restore_preloaded_file()
	os.execute(" cp " .. config.pathToSDL .. "sdl_preloaded_pt_origin.json " .. config.pathToSDL .. "sdl_preloaded_pt.json" )
	os.execute(" rm -f " .. config.pathToSDL .. "/sdl_preloaded_pt_origin.json" ) 
end

