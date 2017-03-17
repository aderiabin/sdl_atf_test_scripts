---------------------------------------------------------------------------------------------
-- Author: I.Stoimenova
-- Creation date: 19.07.2016
-- Last update date: 27.09.2016
-- Script is updated according to APPLINK-19025
-- ATF version: 2.2

---------------------------------------------------------------------------------------------
----------------------------- General Preparation -------------------------------------------
---------------------------------------------------------------------------------------------
	local commonSteps   = require('user_modules/shared_testcases/commonSteps')
	local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

	commonSteps:DeleteLogsFileAndPolicyTable()

	if ( commonSteps:file_exists(config.pathToSDL .. "policy.sqlite") == true ) then
		print("policy.sqlite is found in bin folder")
  		os.remove(config.pathToSDL .. "policy.sqlite")
	end
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
---------------------- require system ATF files for script like -----------------------------
---------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------
	--Precondition: preparation connecttest_resumption.lua
	commonPreconditions:Connecttest_without_ExitBySDLDisconnect("connecttest_resumption.lua")
	
	Test = require('user_modules/connecttest_resumption')
	require('cardinalities')
	local events 			   = require('events')
	local mobile_session  	   = require('mobile_session')
	local mobile  			   = require('mobile_connection')
	local tcp 				   = require('tcp_connection')
	local file_connection  	   = require('file_connection')
	local json 				   = require("json")

	-- Postcondition: removing user_modules/connecttest_resumption.lua
	function Test:Postcondition_remove_user_connecttest()
	  os.execute( "rm -f ./user_modules/connecttest_resumption.lua" )
	end
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
	require('user_modules/AppTypes')
	local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
	local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------
	--ToDo: shall be removed when APPLINK-16610 is fixed
	config.defaultProtocolVersion = 2

	config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

	local TimeHMILevel = 0

	-- Will be used for check is command is added within 10 sec after RAI; True - added
	local AddCmdSuccess = {}
	local TimeAddCmdSuccess = 0

	-- Will be used for check is command is deleted within 10 sec after RAI; True - added
	local DeleteCmdSuccess = {}
	local TimeDeleteCmdSuccess = 0

	local SGP_helpPrompt = {}
	local SGP_vrHelp = {}

	--ToDo: shall be removed when APPLINK-16610 is fixed
	config.defaultProtocolVersion = 2

	local strAppFolder = config.pathToSDL .. "storage/" ..config.application1.registerAppInterfaceParams.appID.. "_" .. config.deviceMAC.. "/"
	strMaxLengthFileName255 = string.rep("a", 251)  .. ".png" -- set max length file name

	local notsplit_default_HelpPrompt 
	local temp_HelpPrompt = {}
	local default_HelpPrompt = {}
	-- Requirement id in JIRA: APPLINK-19475
	-- Read default value of HelpPrompt in .ini file
	f = assert(io.open(config.pathToSDL.. "/smartDeviceLink.ini", "r"))
 
 	fileContent = f:read("*all")
 	DefaultContant = fileContent:match('HelpPrompt.?=.?([^\n]*)')
 	print("DefaultContant = " ..DefaultContant) 	

	if not DefaultContant then
		print ( " \27[31m HelpPrompt is not found in smartDeviceLink.ini \27[0m " )
		default_HelpPrompt = "Default Help Prompt"
	else
		local i = 1
		for notsplit_default_HelpPrompt in string.gmatch(DefaultContant,"[^,]*") do

			if( (notsplit_default_HelpPrompt ~= nil) and (#notsplit_default_HelpPrompt > 1) ) then
				temp_HelpPrompt[i] = notsplit_default_HelpPrompt
				print(i .. ": temp_HelpPrompt = " ..temp_HelpPrompt[i] ..",")
				i = i + 1

			end
		end
		local count = 1

		for i = 1, #temp_HelpPrompt do
			default_HelpPrompt[count] = { 
											text = temp_HelpPrompt[i] ..",",
										 	type = "TEXT"
										}
			if (#temp_HelpPrompt > 1) then
				default_HelpPrompt[count + 1] = {
													text = "300",
													type = "SILENCE"
												}
			end
			count = count + 2
		end
	end

	f:close()

---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
-----------------------------------Backup, updated preloaded file ---------------------------
---------------------------------------------------------------------------------------------
 	commonSteps:DeleteLogsFileAndPolicyTable()

 	os.execute(" cp " .. config.pathToSDL .. "/sdl_preloaded_pt.json " .. config.pathToSDL .. "/sdl_preloaded_pt_origin.json" )

 	f = assert(io.open(config.pathToSDL.. "/sdl_preloaded_pt.json", "r"))

 	-- SystemRequest
 	fileContent = f:read("*all")
 	--DefaultContant = fileContent:match('"rpcs".?:.?.?%{')
 	DefaultContant = fileContent:match('"SystemRequest".?:.?.?%{.-%}')

 	if not DefaultContant then
  	print ( " \27[31m  SystemRequest is not found in sdl_preloaded_pt.json \27[0m " )
 	else
   	DefaultContant =  string.gsub(DefaultContant, '"SystemRequest".?:.?.?%{.-%}', '"SystemRequest":  {\n "hmi_levels": [\n  "BACKGROUND",\n   "FULL",\n   "LIMITED" ,\n   "NONE" \n]\n}')
   	fileContent  =  string.gsub(fileContent,'"SystemRequest".?:.?.?%{.-%}',DefaultContant)
 	end
	
	--[--[TODO: Shall be removed when APPLINK-26629: PASA_Ubuntu: Policy table can't be loaded when RPCs added in functional_group is greater than 50. is fixed
		Content_OnEncodedSyncPData = fileContent:match('"OnEncodedSyncPData".?:.?.?%{.-%},')
		if not Content_OnEncodedSyncPData then
			print ( " \27[31m  rpc OnEncodedSyncPData is not found in sdl_preloaded_pt.json \27[0m " )
		else
			Content_OnEncodedSyncPData = string.gsub(Content_OnEncodedSyncPData,'"OnEncodedSyncPData".?:.?.?%{.-%},','')
			fileContent = string.gsub(fileContent,'"OnEncodedSyncPData".?:.?.?%{.-%},',Content_OnEncodedSyncPData)
		end
	--]]

	-- Policy SetGlobalProperties
 		Content_SetGlobalProperties = fileContent:match('"SetGlobalProperties".?:.?.?%{.-%}')
 		if not Content_SetGlobalProperties then
 			print ( " \27[31m  SetGlobalProperties is not found in sdl_preloaded_pt.json \27[0m " )
 		else
 			Content_SetGlobalProperties =  string.gsub(Content_SetGlobalProperties, '"SetGlobalProperties".?:.?.?%{.-%}', '"SetGlobalProperties":  {\n "hmi_levels": [\n  "BACKGROUND",\n   "FULL",\n   "LIMITED" ,\n   "NONE" \n]\n}')
 			fileContent = string.gsub(fileContent,'"SetGlobalProperties".?:.?.?%{.-%}',Content_SetGlobalProperties)
 		end

 	-- Policy ResetGlobalProperties
 		Content_ResetGlobalProperties = fileContent:match('"ResetGlobalProperties".?:.?.?%{.-%}')
 		if not Content_ResetGlobalProperties then
 			print ( " \27[31m  ResetGlobalProperties is not found in sdl_preloaded_pt.json \27[0m " )
 		else
 			Content_ResetGlobalProperties =  string.gsub(Content_ResetGlobalProperties, '"ResetGlobalProperties".?:.?.?%{.-%}', '"ResetGlobalProperties":  {\n "hmi_levels": [\n  "BACKGROUND",\n   "FULL",\n   "LIMITED" ,\n   "NONE" \n]\n}')
 			fileContent = string.gsub(fileContent,'"ResetGlobalProperties".?:.?.?%{.-%}',Content_ResetGlobalProperties)
 		end

 	-- Policy AddCommand
 		Content_AddCommand = fileContent:match('"AddCommand".?:.?.?%{.-%}')
 		if not Content_AddCommand then
	 		print ( " \27[31m  AddCommand is not found in sdl_preloaded_pt.json \27[0m " )
 		else
 			Content_AddCommand =  string.gsub(Content_AddCommand, '"AddCommand".?:.?.?%{.-%}', '"AddCommand":  {\n "hmi_levels": [\n  "BACKGROUND",\n   "FULL",\n   "LIMITED" ,\n   "NONE" \n]\n}')
 			fileContent = string.gsub(fileContent,'"AddCommand".?:.?.?%{.-%}',Content_AddCommand)
 		end

 	-- Policy DeleteCommand
 		Content_DeleteCommand = fileContent:match('"DeleteCommand".?:.?.?%{.-%}')
 		if not Content_DeleteCommand then
 			print ( " \27[31m  DeleteCommand is not found in sdl_preloaded_pt.json \27[0m " )
 		else
 			Content_DeleteCommand =  string.gsub(Content_DeleteCommand, '"DeleteCommand".?:.?.?%{.-%}', '"DeleteCommand":  {\n "hmi_levels": [\n  "BACKGROUND",\n   "FULL",\n   "LIMITED" ,\n   "NONE" \n]\n}')
 			fileContent = string.gsub(fileContent,'"DeleteCommand".?:.?.?%{.-%}',Content_DeleteCommand)
 		end
 	

 	f = assert(io.open(config.pathToSDL.. "/sdl_preloaded_pt.json", "w+"))
 
 	f:write(fileContent)
 	f:close()
 	-- End SystemRequest

 	-- -- SetGlobalProperties
 	-- fileContent = f:read("*all")
 	-- DefaultContant = fileContent:match('"rpcs".?:.?.?%{')

 	-- if not DefaultContant then
  -- 	print ( " \27[31m  rpcs is not found in sdl_preloaded_pt.json \27[0m " )
 	-- else
  --  	DefaultContant =  string.gsub(DefaultContant, '"rpcs".?:.?.?%{', '"rpcs": { \n"SetGlobalProperties": {\n "hmi_levels": [\n  "BACKGROUND",\n   "FULL",\n   "LIMITED" ,\n   "NONE" \n]\n},')
  --  	fileContent  =  string.gsub(fileContent, '"rpcs".?:.?.?%{', DefaultContant)
 	-- end
	
 	-- f = assert(io.open(config.pathToSDL.. "/sdl_preloaded_pt.json", "w+"))
 
 	-- f:write(fileContent)
 	-- f:close()
 	-- -- End SetGlobalProperties

  os.execute(" cp " .. config.pathToSDL .. "sdl_preloaded_pt.json " .. config.pathToSDL .. "sdl_preloaded_pt_corrected.json" )
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
-----------------------------------Local functions ------------------------------------------
---------------------------------------------------------------------------------------------
	function DelayedExp(time)
		local event = events.Event()
		event.matches = function(self, e) return self == e end
		EXPECT_EVENT(event, "Delayed event")
		:Timeout(time+1000)
		
		RUN_AFTER(function()
			RAISE_EVENT(event, event)
		end, time)
	end

	local function userPrint( color, message)

		print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
	end	

	local function TextPrint(message)
		if(message == "Precondition") then
			function Test:PrintPrecondition()
				userPrint(35,"======================================= Precondition =============================================")
			end
		elseif (message == "Test Case") then
			function Test:PrintTestCase()
				userPrint(35,"========================================= Test Case ==============================================")
			end
		else
			function Test:PrintMessage()
				userPrint(35,"==============================".. message .."==========================================")
			end
		end
	end

	function Putfile(self, arrFileName)
		
		Test["Precondition_PutFile_"..arrFileName] = function(self)
		
			--mobile side: sending Futfile request
			local cid = self.mobileSession:SendRPC("PutFile",
													{
														syncFileName = arrFileName,
														fileType	= "GRAPHIC_PNG",
														persistentFile = false,
														systemFile = false
													},
													"files/action.png")

			--mobile side: expect Futfile response
			EXPECT_RESPONSE(cid, { success = true})
			
		end	
	end	

	local function RegisterApp_HMILevelResumption(self, HMILevel)
				
		config.application1.registerAppInterfaceParams.hashID = self.currentHashID
			
		self.mobileSession:StartService(7)
		:Do(function()
			local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
			-- got time after RAI request
			time =  timestamp()


			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {	application = { appID = HMIAppID } })
			:Do(function(_,data)
				HMIAppID = data.params.application.appID
				self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
			end)

			EXPECT_HMICALL("BasicCommunication.ActivateApp")
			:Do(function(_,data)
		  		self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
			end)

			self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })		

			EXPECT_NOTIFICATION("OnHMIStatus", 
											{hmiLevel = "NONE", systemContext = "MAIN"},
											{hmiLevel = "FULL", systemContext = "MAIN"})
			:Do(function(exp,data)
				if(exp.occurences == 2) then 
					TimeHMILevel = timestamp()
					print("HMI LEVEL is resumed")
					return TimeHMILevel
				end
			end)
			:Times(2)
		end)

		if(TimeHMILevel == nil) then
			TimeHMILevel = 0
			userPrint(31, "TimeHMILevel is nil. Will be assigned 0")
		end
	end	
	
	--local function Precondition_RegisterApp(self, nameTC)
	function Precondition_RegisterApp(self, nameTC)
		TextPrint(nameTC .."_Precondition")
		commonSteps:UnregisterApplication(nameTC .."_UnregisterApplication")	

		commonSteps:StartSession(nameTC .."_StartSession")

		Test[nameTC .."_RegisterApp"] = function(self)

			self.mobileSession:StartService(7)
			:Do(function()	

				local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
				EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
																{
				  												application = {	appName = config.application1.registerAppInterfaceParams.appName }
																})
				:Do(function(_,data)
			  		HMIAppID = data.params.application.appID
					self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID	
				end)

				self.mobileSession:ExpectResponse(CorIdRegister, { success = true })--, resultCode = "SUCCESS" })
				:ValidIf(function(_,data)
					if ( data.payload.resultCode == "SUCCESS" or data.payload.resultCode == "RESUME_FAILED") then
			    		return true
			    	else
			    		userPrint(31, "result Code of RAI is " ..data.payload.resultCode)
			    		return false
			    	end
				end)
				:Timeout(2000)

				self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
				--self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
			end)
		end		

		Putfile(self, "action.png")
	end

	local function Update_AppInfoDat(self, nameTC)
		
		Test[nameTC .. "_Update_AppInfoDat"] = function(self)
 			--os.execute(" cp " .. config.pathToSDL .. "/app_info.dat " .. config.pathToSDL .. "/app_info.dat_before_"..nameTC )
			
			local DefaultContent_helpPrompt
			local DefaultContent_vrHelp
			local DefaultContent_vrHelpTitle

			f = assert(io.open(config.pathToSDL.. "/app_info.dat", "r"))

		 	fileContent = f:read("*all")
		 	
		 	-- helpPrompt
				--DefaultContent_helpPrompt1 = fileContent:match('"helpPrompt".?:.?.?%[.-%],')
				DefaultContent_helpPrompt = fileContent:match('"helpPrompt".?:.?.?%[.-%].?')

			    if (not DefaultContent_helpPrompt)then
			      print ( " \27[31m helpPrompt is not found in app_info.dat \27[0m " )
			    else
			       fileContent  =  string.gsub(fileContent, '"helpPrompt".?:.?.?%[.-%].?', '')
			    end		

			-- vrHelp
				DefaultContent_vrHelp = fileContent:match('"vrHelp".?:.?.?%[.-%].?')

			    if ( not DefaultContent_vrHelp ) then
			      print ( " \27[31m vrHelp is not found in app_info.dat \27[0m " )
			    else
			       fileContent  =  string.gsub(fileContent, '"vrHelp".?:.?.?%[.-%].?', '')
			    end				

			-- vrHelpTitle
				DefaultContent_vrHelpTitle = fileContent:match('"vrHelpTitle".?:.?.?%".-%".?')

			    if (not DefaultContent_vrHelpTitle)   then
			      print ( " \27[31m vrHelpTitle is not found in app_info.dat \27[0m " )
			    else
			       fileContent  =  string.gsub(fileContent, '"vrHelpTitle".?:.?.?%".-%".?','"vrHelpTitle": null')
			    end		
	
    		f = assert(io.open(config.pathToSDL.. "/app_info.dat", "w+"))
			f:write(fileContent)
			f:close()
 			--os.execute(" cp " .. config.pathToSDL .. "/app_info.dat " .. config.pathToSDL .. "/app_info.dat_after_"..nameTC )
		end
	end

	function Precondition_ResumeAppRegister(self, nameTC)
		Test[nameTC .."_Precondition_Suspend"] = function(self)
			self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
												{ reason = "SUSPEND" })
						--Requirement id in JAMA/or Jira ID: APPLINK-15702
						--Send BC.OnPersistanceComplete to HMI on data persistance complete			
						-- hmi side: expect OnSDLPersistenceComplete notification
			EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
		end

		Test[nameTC .."_Precondition_Ignion_OFF"] = function(self)

			StopSDL()
						
			-- hmi side: sends OnExitAllApplications (IGNITION_OFF)
			self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
																								{ reason = "IGNITION_OFF"	})

			-- hmi side: expect OnSDLClose notification
			EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")

			-- hmi side: expect OnAppUnregistered notification
			EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
		end

		Update_AppInfoDat(self, nameTC)

		Test[nameTC .."_Precondition_StartSDL"] = function(self)
					
			StartSDL(config.pathToSDL, config.ExitOnCrash)
		end

		Test[nameTC .."_Precondition_InitHMI"] = function(self)
					
			self:initHMI()
		end

		Test[nameTC .."_Precondition_InitHMIOnReady"] = function(self)

			self:initHMI_onReady()
		end

		Test[nameTC .."_Precondition_ConnectMobile"] = function (self)

			self:connectMobile()
		end

		Test[nameTC .."_Precondition_StartSession"] = function(self)
						
			self.mobileSession = mobile_session.MobileSession(
																self,
																self.mobileConnection)
		end
	end
		
	function Precondition_ActivationApp(self, nameTC)	

		TextPrint(nameTC .."_Precondition")
		
		Test[nameTC .."_ActivationApp"] = function(self)
			
			local Input_AppId
			
			Input_AppId = self.applications[config.application1.registerAppInterfaceParams.appName]
			
			
			--hmi side: sending SDL.ActivateApp request
			local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = Input_AppId})
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
			EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
			:Do(function(_,data)
				TimeHMILevel = timestamp()
				return TimeHMILevel
			end)

			if(TimeHMILevel == nil) then
				TimeHMILevel = 0
				userPrint(31, "TimeHMILevel is nil. Will be assigned 0")
			end

		end
	end

	local function AddCommand(self, icmdID)
		TimeAddCmdSuccess = 0
		
		--mobile side: sending AddCommand request
		local cid = self.mobileSession:SendRPC("AddCommand",
		{
			cmdID = icmdID,
			menuParams = 	
			{
				position = 0,
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
				position = 0,
				menuName ="Command" .. tostring(icmdID)
			}
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
			vrCommands = 
			{
				"VRCommand" .. tostring(icmdID)
			}
		})
		:Do(function(_,data)
			--hmi side: sending VR.AddCommand response 
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)	
	
		if(TimeHMILevel == nil ) then
			TimeHMILevel = 0
			userPrint(31, "TimeHMILevel is nil. Will be assigned 0")
		end
		--mobile side: expect AddCommand response 
		EXPECT_RESPONSE(cid, {  success = true, resultCode = "SUCCESS"  })
		:Do(function(_,data)			
			
			if(data.payload.resultCode ~= "SUCCESS") then
				userPrint(33,"SUCCESS of AddCommand is not received!")
				AddCmdSuccess[icmdID] = false
			else
				TimeAddCmdSuccess = timestamp()
			
				--mobile side: expect OnHashChange notification
				if( 
					 (TimeAddCmdSuccess - TimeHMILevel) <= 10000 and
				 	 (TimeAddCmdSuccess > 0) )then
					userPrint(32, "Time of SUCCESS AddCommand is within 10 sec; Real: " ..(TimeAddCmdSuccess - TimeHMILevel))
					AddCmdSuccess[icmdID] = true
				else
					userPrint(33,"Time to success of AddCommand expired after RAI. Expected 10sec; Real: " ..(TimeAddCmdSuccess - TimeHMILevel) )
					--self:FailTestCase("Time to success of AddCommand expired after RAI. Expected 10sec; Real: " ..(TimeAddCmdSuccess - TimeHMILevel))
					AddCmdSuccess[icmdID] = false
				end
			

				EXPECT_NOTIFICATION("OnHashChange")
				:Do(function(_, data)
					self.currentHashID = data.payload.hashID
				end)
			end
		end)
	end

	local function DeleteCommand(self, icmdID)
		TimeDeleteCmdSuccess = 0
		if(TimeHMILevel == nil ) then
			TimeHMILevel = 0
			userPrint(31, "TimeHMILevel is nil. Will be assigned 0")
		end
		--mobile side: sending DeleteCommand request
		local cid = self.mobileSession:SendRPC("DeleteCommand",
		{
			cmdID = icmdID
		})
	
		--hmi side: expect UI.DeleteCommand request
		EXPECT_HMICALL("UI.DeleteCommand", 
		{ 
			cmdID = icmdID,
			appID = self.applications[config.application1.registerAppInterfaceParams.appName]
		})
		:Do(function(_,data)
			--hmi side: sending UI.DeleteCommand response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
	
		--hmi side: expect VR.DeleteCommand request
		EXPECT_HMICALL("VR.DeleteCommand", 
		{ 
			cmdID = icmdID,
			type = "Command"
		})
		:Do(function(_,data)
			--hmi side: sending VR.DeleteCommand response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
				
		--mobile side: expect DeleteCommand response 
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
		:Do(function(_,data)
			if(data.payload.resultCode ~= "SUCCESS") then
				userPrint(33,"SUCCESS of DeleteCommand is not received!")
				DeleteCmdSuccess[icmdID] = false
			else
				TimeDeleteCmdSuccess  = timestamp()		
				if( 
					(TimeDeleteCmdSuccess - TimeHMILevel) <= 10000  and
					(TimeDeleteCmdSuccess > 0) 	) then
					userPrint(32, "Time of SUCCESS DeleteCommand is within 10 sec; Real: " ..(TimeDeleteCmdSuccess - TimeHMILevel))
					DeleteCmdSuccess[icmdID] = true
				else
					userPrint(33,"Time to success of DeleteCommand expired after RAI. Expected 10sec; Real: " ..(TimeDeleteCmdSuccess - TimeHMILevel))
					DeleteCmdSuccess[icmdID] = false
				end

				EXPECT_NOTIFICATION("OnHashChange")
				:Do(function(_, data)
					self.currentHashID = data.payload.hashID
				end)
			end

		end)
	end

	local function CheckUpdateFile(self, SGP_helpPrompt, SGP_vrHelp)
		local cid = self.mobileSession:SendRPC("SetGlobalProperties",{ menuTitle = "Menu Title"})

		--hmi side: expect UI.SetGlobalProperties request
		EXPECT_HMICALL("UI.SetGlobalProperties",
										{
											vrHelpTitle = config.application1.registerAppInterfaceParams.appName,
											vrHelp =  SGP_vrHelp ,
											appID = self.applications[config.application1.registerAppInterfaceParams.appName]
										})
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)

		--hmi side: expect TTS.SetGlobalProperties request
		EXPECT_HMICALL("TTS.SetGlobalProperties",
												{
														helpPrompt =  SGP_helpPrompt ,
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
		:Do(function(_,data)
			--hmi side: sending UI.SetGlobalProperties response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)		

		--mobile side: expect SetGlobalProperties response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
			
		--mobile side: expect OnHashChange notification
		EXPECT_NOTIFICATION("OnHashChange")
		:Do(function(_, data)			
			self.currentHashID = data.payload.hashID
			
		end)
	end
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	--Begin Precondition.1
		TextPrint("General Precondition")
		commonSteps:ActivationApp(_,"ActivationApp_GeneralPrecondition")
	--End Precondition.1

	--Begin Precondition.2
		--Description: Update Policy with SetGlobalProperties API in FULL, LIMITED, BACKGROUND is allowed
		function Test:Precondition_PolicyUpdate_GeneralPrecondition()
			--hmi side: sending SDL.GetURLS reqeuest
			local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
		
			--hmi side: expect SDL.GetURLS response from HMI
			EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {{url = "https://policies.telematics.ford.com/api/policies"}}}})
			:Do(function(_,data)
				--print("SDL.GetURLS response is received")
				--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
				self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
																				{
																					requestType = "PROPRIETARY",
																					fileName = "filename"
																				} )
			
				--mobile side: expect OnSystemRequest notification 
				EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
				:Do(function(_,data)
					--print("OnSystemRequest notification is received")
					--mobile side: sending SystemRequest request 
					local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
																															{
																																fileName = "PolicyTableUpdate",
																																requestType = "PROPRIETARY"
																															},
																															"files/PTU_SetGlobalProperties.json"
																															--[[TODO: Uncomment when APPLINK-28296 is clarified.
																															"files/ptu_general.json"
																															]]
																														)
				
					local systemRequestId
					--hmi side: expect SystemRequest request
					EXPECT_HMICALL("BasicCommunication.SystemRequest")
					:Do(function(_,data)
						systemRequestId = data.id
						--print("BasicCommunication.SystemRequest is received")
						
						--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
						self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
																								{
																									policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
																								}	)
						function to_run()
							--hmi side: sending SystemRequest response
							self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
						end
					
						RUN_AFTER(to_run, 500)
					end)
				
					--hmi side: expect SDL.OnStatusUpdate
					EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
					:ValidIf(function(exp,data)
						if ( exp.occurences == 1 and data.params.status == "UP_TO_DATE" ) then
							return true
						elseif ( exp.occurences == 1 and data.params.status == "UPDATING" ) then
							return true
						elseif ( exp.occurences == 2 and data.params.status == "UP_TO_DATE" ) then
							return true
						else 
							if (exp.occurences == 1) then
								print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in first occurrences status 'UP_TO_DATE' or 'UPDATING', got '" .. tostring(data.params.status) .. "' \27[0m")
							elseif (exp.occurences == 2) then
								print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in second occurrences status 'UP_TO_DATE', got '" .. tostring(data.params.status) .. "' \27[0m")
							end
							return false
						end
					end)
					:Times(Between(1,2))
				
					--mobile side: expect SystemRequest response
					EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
					:Do(function(_,data)
						--print("SystemRequest is received")
						--hmi side: sending SDL.GetUserFriendlyMessage request to SDL
						local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})
				
						--hmi side: expect SDL.GetUserFriendlyMessage response
						-- TODO: update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
						EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage)
						:Do(function(_,data)
							--print("SDL.GetUserFriendlyMessage is received")			
						end)
					end)
				end)
			end)
		end
	--End Precondition.2

	--Begin Precondition.3

		Putfile(self, "action.png")
	--End Precondition.3
---------------------------------------------------------------------------------------------	

---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--CommonRequestCheck: Check of mandatory/conditional request's parameters (mobile protocol)--
---------------------------------------------------------------------------------------------
	--Begin Test suit PositiveRequestCheck

		--Description: TC's checks processing 
			-- request with all parameters
      -- request with only vrHelp and helpPrompts
      -- request with only vrHelp and helpPrompts and fake parameters (fake - not from protocol)
      -- request without any parameters
      -- request with only VrHelp
      -- request with only helpPrompts

		--Begin Test case CommonRequestCheck.1
			--Description:Positive case and request with all parameters in boundary conditions; 5 elements of helpPrompt[]
			--Requirement id in JIRA: APPLINK-19476
			--Verification criteria:
				-- SDL must transfer TTS.SetGlobalProperties (<helpPrompts>, params) to HMI with adding period of silence between each command "helpPrompt" to HMI 
				-- SDL must transfer UI.SetGlobalProperties (<vrHelp, params>) to HMI
				-- SDL must respond with <resultCode_received_from_HMI> to mobile app
				Test["TC1_SetGlobalProperties_AllValidParametes"] = function(self)

					xmlReporter.AddMessage("Test Case 1")
					userPrint(35,"======================================= Test Case 1 =============================================")
					--mobile side: sending SetGlobalProperties request
					local cid = self.mobileSession:SendRPC("SetGlobalProperties",
																									{
																										helpPrompt = 
																																{
																																	{
																																		text = "Help prompt 1",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 2",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 3",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 4",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 5",
																																		type = "TEXT"
																																	}

																																},
																										timeoutPrompt = 
																																{
																																	{
																																		text = "Timeout prompt",
																																		type = "TEXT"
																																	}
																																},
																										vrHelpTitle = "VR help title",
																										vrHelp = 
																																{
																																	{
																																		text = "VR help item",
																																		image = {
																																							value = "action.png",
																																							imageType = "DYNAMIC"
																																						},
																																		position = 1
																																	}
																																},
																										menuTitle = "Menu Title",
																										menuIcon = 
																																{
																																	value = "action.png",
																																	imageType = "DYNAMIC"
																																},
																										keyboardProperties = 
																																{
																																	keyboardLayout = "QWERTY",
																																	keypressMode = "SINGLE_KEYPRESS",
																																	limitedCharacterList = { "a" },
																																	language = "EN-US",
																																	autoCompleteText = "Daemon, Freedom"
																																}
																									})
					
					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties",
													{
														vrHelpTitle = "VR help title",
														vrHelp = 
																		{
																			{
																				text = "VR help item",
																				image = 
																								{
																									imageType = "DYNAMIC",
																									value = strAppFolder .. "action.png"
																								},--
																				position = 1
																		}	},
														menuTitle = "Menu Title",
														menuIcon = 
																			{
																				imageType = "DYNAMIC",
																				value = strAppFolder .. "action.png"
																			},
														keyboardProperties = 
																			{
																				keyboardLayout = "QWERTY",
																				keypressMode = "SINGLE_KEYPRESS",
																				limitedCharacterList = { "a" },
																				language = "EN-US",
																				autoCompleteText = "Daemon, Freedom"
																			},
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties",
													{
														helpPrompt = 
																				{
																					{
																						text = "Help prompt 1",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 2",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 3",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 4",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 5",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					}
																				},
														timeoutPrompt = 
																				{
																					{
																						text = "Timeout prompt",
																						type = "TEXT"
																				}	},
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
					:Do(function(_,data)
			 			--hmi side: sending UI.SetGlobalProperties response
			 			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)		

					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
			
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
					:Do(function(_, data)
						
						self.currentHashID = data.payload.hashID
					end)
				end
		--End Test case CommonRequestCheck.1

		--Begin Test case CommonRequestCheck.2
			--Preconditions Test case CommonRequestCheck.2
			Precondition_RegisterApp(self, "TC2")
			Precondition_ActivationApp(self, "TC2")
		
			--Description:Positive case and request with only helpPrompt and vrHelp; 5 elements of helpPrompt[]
			--Requirement id in JIRA: APPLINK-19476
			--Verification criteria:
				-- SDL must transfer TTS.SetGlobalProperties (<helpPrompts>, params) to HMI with adding period of silence between each command "helpPrompt" to HMI 
				-- SDL must transfer UI.SetGlobalProperties (<vrHelp, params>) to HMI
				-- SDL must respond with <resultCode_received_from_HMI> to mobile app
				Test["TC2_SetGlobalProperties_onlyparams_helpPrompt_vrHelp"] = function(self)
					xmlReporter.AddMessage("Test Case 2")
					userPrint(35,"======================================= Test Case 2 =============================================")
					--mobile side: sending SetGlobalProperties request
					local cid = self.mobileSession:SendRPC("SetGlobalProperties",
																									{
																										helpPrompt = 
																																{
																																	{
																																		text = "Help prompt 1",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 2",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 3",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 4",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 5",
																																		type = "TEXT"
																																	}

																																},
																										vrHelpTitle = "VR Help Title",
																										vrHelp = 
																																{
																																	{
																																		text = "VR help item",
																																		image = {
																																							value = "action.png",
																																							imageType = "DYNAMIC"
																																						},
																																		position = 1
																																	}
																																}
																									})
					
					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties",
													{
														vrHelpTitle = "VR Help Title",
														vrHelp = 
																		{
																			{
																				text = "VR help item",
																				image = 
																								{
																									imageType = "DYNAMIC",
																									value = strAppFolder .. "action.png"
																								},--
																				position = 1
																		}	},
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties",
													{
														helpPrompt = 
																				{
																					{
																						text = "Help prompt 1",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 2",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 3",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 4",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 5",
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
			 			--hmi side: sending UI.SetGlobalProperties response
			 			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)		

					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
			
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
					:Do(function(_, data)
						
						self.currentHashID = data.payload.hashID
					end)
				end
		--End Test case CommonRequestCheck.2

		--Begin Test case CommonRequestCheck.3
			--Preconditions Test case CommonRequestCheck.3
				Precondition_RegisterApp(self,"TC3")
				Precondition_ActivationApp(self, "TC3")
		
			--Description:Positive case and request with all params and 1 fake param; 5 elements of helpPrompt[]
			--Requirement id in JIRA: APPLINK-19476
			--Verification criteria:
				-- SDL must transfer TTS.SetGlobalProperties (<helpPrompts>, params) to HMI with adding period of silence between each command "helpPrompt" to HMI 
				-- SDL must transfer UI.SetGlobalProperties (<vrHelp, params>) to HMI
				-- SDL must respond with <resultCode_received_from_HMI> to mobile app
				Test["TC3_SetGlobalProperties_AllParams_AdditionalFake"] = function(self)					
					xmlReporter.AddMessage("Test Case 3")
					userPrint(35,"======================================= Test Case 3 =============================================")
					--mobile side: sending SetGlobalProperties request
					local cid = self.mobileSession:SendRPC("SetGlobalProperties",
																									{
																										fakeParam = "fakeParam",
																										helpPrompt = 
																																{
																																	{
																																		text = "Help prompt 1",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 2",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 3",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 4",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 5",
																																		type = "TEXT"
																																	}

																																},
																										timeoutPrompt = 
																																{
																																	{
																																		text = "Timeout prompt",
																																		type = "TEXT"
																																	}
																																},
																										vrHelpTitle = "VR help title",
																										vrHelp = 
																																{
																																	{
																																		text = "VR help item",
																																		image = {
																																							value = "action.png",
																																							imageType = "DYNAMIC"
																																						},
																																		position = 1
																																	}
																																},
																										menuTitle = "Menu Title",
																										menuIcon = 
																																{
																																	value = "action.png",
																																	imageType = "DYNAMIC"
																																},
																										keyboardProperties = 
																																{
																																	keyboardLayout = "QWERTY",
																																	keypressMode = "SINGLE_KEYPRESS",
																																	limitedCharacterList = { "a" },
																																	language = "EN-US",
																																	autoCompleteText = "Daemon, Freedom"
																																}
																									})
					
					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties",
													{
														vrHelpTitle = "VR help title",
														vrHelp = 
																		{
																			{
																				text = "VR help item",
																				image = 
																								{
																									imageType = "DYNAMIC",
																									value = strAppFolder .. "action.png"
																								},--
																				position = 1
																		}	},
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties",
													{
														helpPrompt = 
																				{
																					{
																						text = "Help prompt 1",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 2",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 3",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 4",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 5",
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
			 			--hmi side: sending UI.SetGlobalProperties response
			 			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)		

					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
			
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
					:Do(function(_, data)
						
						self.currentHashID = data.payload.hashID
					end)
				end
		--End Test case CommonRequestCheck.3

		--Begin Test case CommonRequestCheck.4
			--Preconditions Test case CommonRequestCheck.4
				Precondition_RegisterApp(self,"TC4")
				Precondition_ActivationApp(self, "TC4")

			--Description:Positive case and request without any params, as result default values of VrHelp and helpPrompt shall be used.
			--Requirement id in JIRA: APPLINK-19475; APPLINK-23962; APPLINK-23728
			--Verification criteria:
				--In case mobile app has NO registered AddCommands and/or DeleteCommands requests (previously added or resumed within data resumption process)
				-- SDL must use current appName as default value for "vrHelp" parameter
				-- SDL must retrieve value of "helpPrompt" from .ini file ([GLOBAL PROPERTIES] section -> "HelpPrompt" param)
				Test["TC4_SetGlobalProperties_NoParams"] = function (self)					
					xmlReporter.AddMessage("Test Case 4")
					userPrint(35,"======================================= Test Case 4 =============================================")
					--mobile side: sending SetGlobalProperties request
					local cid = self.mobileSession:SendRPC("SetGlobalProperties",{ menuTitle = "Menu Title"})
					
					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties",
													{
														vrHelpTitle = config.application1.registerAppInterfaceParams.appName,
													  -- Clarification is done: APPLINK-26638
														vrHelp = { 
																	{
																		text = config.application1.registerAppInterfaceParams.appName,
																		position = 1
																}	},
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties",
													{
														helpPrompt = default_HelpPrompt,																		
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
					:Do(function(_,data)
			 			--hmi side: sending UI.SetGlobalProperties response
			 			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)		

					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
			
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
					:Do(function(_, data)
						
						self.currentHashID = data.payload.hashID
						
					end)										
				end
		--End Test case CommonRequestCheck.4

		--Begin Test case CommonRequestCheck.5
			--Preconditions Test case CommonRequestCheck.5
				Precondition_RegisterApp(self,"TC5")
				Precondition_ActivationApp(self, "TC5")

			--Description:Positive case and request with only VrHelp, as result default values of helpPrompt shall be used.
			--Requirement id in JIRA: APPLINK-19475; APPLINK-23962; APPLINK-23728
			--Verification criteria:
				--In case mobile app has NO registered AddCommands and/or DeleteCommands requests (previously added or resumed within data resumption process)
				-- SDL must use current appName as default value for "vrHelp" parameter
				-- SDL must retrieve value of "helpPrompt" from .ini file ([GLOBAL PROPERTIES] section -> "HelpPrompt" param)
				Test["TC5_SetGlobalProperties_onlyparam_VrHelp"] = function(self)
					xmlReporter.AddMessage("Test Case 5")
					userPrint(35,"======================================= Test Case 5 =============================================")
					--mobile side: sending SetGlobalProperties request
					local cid = self.mobileSession:SendRPC("SetGlobalProperties",{ 
																																					vrHelpTitle = "VR help title", 
																																					vrHelp = {
																																											{
																																												text = "VR help item",
																																												image = {
																																																	value = "action.png",
																																																	imageType = "DYNAMIC"
																																																},
																																												position = 1
																																											}
																																										}
																																				})
																													
					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties",
													{
													 	-- Clarification is done: APPLINK-26638
														vrHelpTitle = "VR help title",
														vrHelp ={ 
																	{
																		--text = config.application1.registerAppInterfaceParams.appName,
																		--APPLINK-20610 vrHelpTitle can't be sent without vrHelp
																		text = "VR help item",
																		position = 1
																}	},
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties",
													{
														helpPrompt = default_HelpPrompt,	
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
					:Do(function(_,data)
			 			--hmi side: sending UI.SetGlobalProperties response
			 			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)		

					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
			
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
					:Do(function(_, data)
						
						self.currentHashID = data.payload.hashID
					end)
				end
		--End Test case CommonRequestCheck.5

		--Begin Test case CommonRequestCheck.6
			--Preconditions Test case CommonRequestCheck.6
			Precondition_RegisterApp(self,"TC6")
			Precondition_ActivationApp(self, "TC6")

			--Description:Positive case and request with only helpPrompt, as result default values of helpPrompt shall be used.
			--Requirement id in JIRA: APPLINK-19475; APPLINK-23962; APPLINK-23728
			--Verification criteria:
				--In case mobile app has NO registered AddCommands and/or DeleteCommands requests (previously added or resumed within data resumption process)
				-- SDL must use current appName as default value for "vrHelp" parameter
				-- SDL must retrieve value of "helpPrompt" from .ini file ([GLOBAL PROPERTIES] section -> "HelpPrompt" param)
				Test["TC6_SetGlobalProperties_onlyparam_helpPrompt"] = function(self)
					xmlReporter.AddMessage("Test Case 6")
					userPrint(35,"======================================= Test Case 6 =============================================")
					--mobile side: sending SetGlobalProperties request
					local cid = self.mobileSession:SendRPC("SetGlobalProperties", {
																									--vrHelpTitle = "VR help title",
																									helpPrompt = 
																													{
																														{
																															text = "Help prompt 1",
																															type = "TEXT"
																														},
																														{
																															text = "Help prompt 2",
																															type = "TEXT"
																														},
																														{
																															text = "Help prompt 3",
																															type = "TEXT"
																														},
																														{
																															text = "Help prompt 4",
																															type = "TEXT"
																														},
																														{
																															text = "Help prompt 5",
																															type = "TEXT"
																														}
																													}
																					}		)
					
					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties",
													{
														vrHelpTitle = config.application1.registerAppInterfaceParams.appName,
														-- Clarification is done in APPLINK-26638
														vrHelp ={
																			{
																				text = config.application1.registerAppInterfaceParams.appName,
																				position = 1
																		}	},
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties",
													{
														helpPrompt = 
																				{
																					{
																						text = "Help prompt 1",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 2",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 3",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 4",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 5",
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
			 			--hmi side: sending UI.SetGlobalProperties response
			 			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)		

					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
			
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
					:Do(function(_, data)
						
						self.currentHashID = data.payload.hashID
					end)				
				end
		--End Test case CommonRequestCheck.6
	--End Test suit PositiveRequestCheck
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
----------------------------------------II TEST BLOCK----------------------------------------
----------------------------------------Positive cases---------------------------------------
--Positive cases: Check of positive value of request/response parameters (mobile protocol, HMI protocol)
---------------------------------------------------------------------------------------------
	--Begin Test suit PositiveResponseCheck

		--Description: Positive case without request but with update of internal list with helpPrompts, vrHelp
			--Requirement id in JIRA: APPLINK-19477
			--Verification criteria:
				-- In case SDL already transfers UI/TTS.SetGlobalProperties with <vrHelp> and <helpPrompt> received from mobile app to HMI
				-- and and 10 sec timer is NOT expired yet
				-- and mobile app sends AddCommand and/or DeleteCommand requests to SDL 
				-- SDL must update internal list with new values of "vrHelp" and "helpPrompt" params ONLY after successfull response from HMI
				-- SDL must NOT: send updated values of "vrHelp" and "helpPrompt" via TTS/UI.SetGlobalProperties requests to HMI
				-- PositivaResponseCheck.1 and PositivaResponseCheck.2 are added -> deleted commands one by one.

				--Preconditions Test case PositiveResponseCheck.1
					Precondition_RegisterApp(self, "TC7")
					Precondition_ActivationApp(self, "TC7")

				--Begin PositivaResponseCheck.1 and PositivaResponseCheck.2
					--for cmdCount = 1, 10 do
					--Begin Test case PositiveResponseCheck.1
					
					for cmdCount = 1, 1 do

						Test["TC7_SetGlobalProperties_NoRequestToHMI_AddCommand" .. cmdCount] = function(self)

							xmlReporter.AddMessage("Test Case 7")
							userPrint(35,"======================================= Test Case 7_Command"..cmdCount.." ==========================================")

							AddCommand(self, cmdCount)				

							EXPECT_HMICALL("UI.SetGlobalProperties",{})
							:Times(0)
							:Timeout(7000)
							:Do(function(_,data)
								local time_UI_SGP = timestamp()
								userPrint(31,"Time to receive UI.SetGlobalProperties from HMI level not NONE is " .. tostring(time_UI_SGP - TimeHMILevel) .." msec")
							end)

							EXPECT_HMICALL("TTS.SetGlobalProperties",{})
							:Times(0)
							:Timeout(7000)
							:Do(function(_,data)
								local time_TTS_SGP = timestamp()
								userPrint(31,"Time to receive TTS.SetGlobalProperties from HMI level not NONE is " .. tostring(time_TTS_SGP - TimeHMILevel) .." msec")
							end)
						end		

						Precondition_ResumeAppRegister(self, "TC7")

						Test["TC7_Resumption_data"] = function(self)	
							
							local SGP_helpPrompt = {}
							local SGP_vrHelp = {}
							
							if(AddCmdSuccess[cmdCount] == true) then
								SGP_helpPrompt[1] ={
																		text = "VRCommand" .. tostring(cmdCount),
																		type = "TEXT" }
								
								SGP_vrHelp[1] = { 
																	text = "VRCommand" .. tostring(cmdCount), 
																	position = 1
																}
							else
								SGP_helpPrompt = default_HelpPrompt
								SGP_vrHelp[1] = { 
																	text = config.application1.registerAppInterfaceParams.appName,
																	position = 1
																}
							end

							config.application1.registerAppInterfaceParams.hashID = self.currentHashID

							RegisterApp_HMILevelResumption(self, "FULL")

							--hmi side: expect UI.AddCommand request 
							EXPECT_HMICALL("UI.AddCommand", 
							{ 
								cmdID = cmdCount,		
								menuParams = 
								{
									position = 0,
									menuName ="Command" .. tostring(cmdCount)
								}
							})
							:Do(function(_,data)
								--hmi side: sending UI.AddCommand response 
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
							end)

							-- Updated because of APPLINK-15683
							--hmi side: expect VR.AddCommand request 
							EXPECT_HMICALL("VR.AddCommand", {})
							:Times(0)
						end

						Test["TC7_CheckInternalList_AddCommand" .. cmdCount] = function(self)
							local SGP_helpPrompt = {}
							local SGP_vrHelp = {}
							
							if(AddCmdSuccess[cmdCount] == true) then
								SGP_helpPrompt[1] ={
																		text = "VRCommand" .. tostring(cmdCount),
																		type = "TEXT" }
								
								SGP_vrHelp[1] = { 
																	text = "VRCommand" .. tostring(cmdCount), 
																	position = 1
																}
							else
								SGP_helpPrompt = default_HelpPrompt
								SGP_vrHelp[1] = { 
																	text = config.application1.registerAppInterfaceParams.appName,
																	position = 1
																}
							end
							
							CheckUpdateFile(self, SGP_helpPrompt, SGP_vrHelp)
						end

						--End Test case PositiveResponseCheck.1			

						--Begin Test case PositiveResponseCheck.2
						Test["TC8_SetGlobalProperties_NoRequestToHMI_DeleteCommand" .. cmdCount] = function(self)

							xmlReporter.AddMessage("Test Case 8")
							userPrint(35,"======================================= Test Case 8_Command"..cmdCount.." =============================================")
							DeleteCommand(self, cmdCount)
							

							EXPECT_HMICALL("UI.SetGlobalProperties",{})
							:Times(0)
							:Timeout(7000)
							:Do(function(_,data)
								local time_UI_SGP = timestamp()
								userPrint(31, "Time to receive UI.SetGlobalProperties from HMI level not NONE is " .. tostring(time_UI_SGP - TimeHMILevel) .." msec")
							end)

							EXPECT_HMICALL("TTS.SetGlobalProperties",{})
							:Times(0)
							:Timeout(7000)
							:Do(function(_,data)
								local time_TTS_SGP = timestamp()
								userPrint(31, "Time to receive TTS.SetGlobalProperties from HMI level not NONE is " .. tostring(time_TTS_SGP - TimeHMILevel) .." msec")
							end)
						end

						Precondition_ResumeAppRegister(self, "TC8")

						Test["TC8_Resumption_data"] = function(self)	
							local SGP_helpPrompt = {}
							local SGP_vrHelp = {}

							if(
								( (AddCmdSuccess[cmdCount] == true) and (DeleteCmdSuccess[cmdCount] == true) ) or
								  (AddCmdSuccess[cmdCount] == false) )then
								SGP_helpPrompt = default_HelpPrompt
							
								SGP_vrHelp[1] = {
																	text = config.application1.registerAppInterfaceParams.appName,
																	position = 1
																}
							elseif( (AddCmdSuccess[cmdCount] == true) and (DeleteCmdSuccess[cmdCount] == false) ) then
								SGP_helpPrompt[1] ={
																			text = "VRCommand" .. tostring(cmdCount),
																			type = "TEXT" }								
								SGP_vrHelp[1] = { 
																	text = "VRCommand" .. tostring(cmdCount), 
																	position = 1
																}
							end
							config.application1.registerAppInterfaceParams.hashID = self.currentHashID

							RegisterApp_HMILevelResumption(self, "FULL")

							--hmi side: expect UI.AddCommand request 
							EXPECT_HMICALL("UI.AddCommand", {})
							:Times(0)

							--hmi side: expect VR.AddCommand request 
							EXPECT_HMICALL("VR.AddCommand", {})
							:Times(0)
						end

						Test["TC8_CheckInternalList_DeleteCommand" .. cmdCount] = function(self)
							local SGP_helpPrompt = {}
							local SGP_vrHelp = {}

							if(
								( (AddCmdSuccess[cmdCount] == true) and (DeleteCmdSuccess[cmdCount] == true) ) or
								  (AddCmdSuccess[cmdCount] == false) )then
								SGP_helpPrompt = default_HelpPrompt						
								SGP_vrHelp[1] = {
																	text = config.application1.registerAppInterfaceParams.appName,
																	position = 1
																}
							elseif( (AddCmdSuccess[cmdCount] == true) and (DeleteCmdSuccess[cmdCount] == false) ) then
								SGP_helpPrompt[1] ={
																			text = "VRCommand" .. tostring(cmdCount),
																			type = "TEXT" }
								SGP_vrHelp[1] = { 
																	text = "VRCommand" .. tostring(cmdCount), 
																	position = 1
																}
							end
							CheckUpdateFile(self, SGP_helpPrompt, SGP_vrHelp)						
						end

					end
					--End Test case PositiveResponseCheck.2		
				--End PositivaResponseCheck.1 and PositivaResponseCheck.2

				--Preconditions Test case PositiveResponseCheck.3
					Precondition_RegisterApp(self, "TC9")
					Precondition_ActivationApp(self, "TC9")

					Test["TC9_Precondition_SetGlobalProperties_AllValidParametes"] = function(self)

						--mobile side: sending SetGlobalProperties request
						local cid = self.mobileSession:SendRPC("SetGlobalProperties",
																									{
																										helpPrompt = 
																																{
																																	{
																																		text = "Help prompt 1",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 2",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 3",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 4",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 5",
																																		type = "TEXT"
																																	}

																																},
																										timeoutPrompt = 
																																{
																																	{
																																		text = "Timeout prompt",
																																		type = "TEXT"
																																	}
																																},
																										vrHelpTitle = "VR help title",
																										vrHelp = 
																																{
																																	{
																																		text = "VR help item",
																																		image = {
																																							value = "action.png",
																																							imageType = "DYNAMIC"
																																						},
																																		position = 1
																																	}
																																},
																										menuTitle = "Menu Title",
																										menuIcon = 
																																{
																																	value = "action.png",
																																	imageType = "DYNAMIC"
																																},
																										keyboardProperties = 
																																{
																																	keyboardLayout = "QWERTY",
																																	keypressMode = "SINGLE_KEYPRESS",
																																	limitedCharacterList = { "a" },
																																	language = "EN-US",
																																	autoCompleteText = "Daemon, Freedom"
																																}
																									})
					
						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
													{
														vrHelpTitle = "VR help title",
														vrHelp = 
																		{
																			{
																				text = "VR help item",
																				image = 
																								{
																									imageType = "DYNAMIC",
																									value = strAppFolder .. "action.png"
																								},--
																				position = 1
																		}	},
														menuTitle = "Menu Title",
														menuIcon = 
																			{
																				imageType = "DYNAMIC",
																				value = strAppFolder .. "action.png"
																			},
														keyboardProperties = 
																			{
																				keyboardLayout = "QWERTY",
																				keypressMode = "SINGLE_KEYPRESS",
																				limitedCharacterList = { "a" },
																				language = "EN-US",
																				autoCompleteText = "Daemon, Freedom"
																			},
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
													{
														helpPrompt = 
																				{
																					{
																						text = "Help prompt 1",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 2",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 3",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 4",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 5",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					}
																				},
														timeoutPrompt = 
																				{
																					{
																						text = "Timeout prompt",
																						type = "TEXT"
																				}	},
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
						:Do(function(_,data)
			 				--hmi side: sending UI.SetGlobalProperties response
			 				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)		

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
			
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
						:Do(function(_, data)
							
							self.currentHashID = data.payload.hashID
						end)
					end

				-- Added 10 commands and after that delete 10 commands one by one
				-- Precondition Test case PositiveResponseCheck.3
					for cmdCount = 1, 10 do

						Test["TC9_Precondition_NoRequestToHMI_AddManyCommands" .. cmdCount] = function(self)
							AddCommand(self, cmdCount)

							EXPECT_HMICALL("UI.SetGlobalProperties",{})
							:Times(0)
							:Timeout(7000)
							:Do(function(_,data)
								local time_UI_SGP = timestamp()
								userPrint(31, "Time to receive UI.SetGlobalProperties from HMI level not NONE is " .. tostring(time_UI_SGP - TimeHMILevel) .." msec")
							end)

							EXPECT_HMICALL("TTS.SetGlobalProperties",{})
							:Times(0)
							:Timeout(7000)
							:Do(function(_,data)
								local time_TTS_SGP = timestamp()
								userPrint(31, "Time to receive TTS.SetGlobalProperties from HMI level not NONE is " .. tostring(time_TTS_SGP - TimeHMILevel) .." msec")
							end)
						end
					end		
					
					Precondition_ResumeAppRegister(self, "TC9")

					Test["TC9_Resumption_data"] = function(self)	
						local SGP_helpPrompt = {}
						local SGP_vrHelp = {}
						local cmdCount = 10
						local cnt_cmd = 1
						local i, j
						
						j = 1
						for i = 1, cmdCount*2, 2 do
							if(AddCmdSuccess[i] == true) then
								SGP_helpPrompt[j] = {
																			text = "VRCommand" .. tostring(cnt_cmd), --menuName}
																			type = "TEXT" 
																		}
								SGP_helpPrompt[j + 1] =
																				{
																					text = "300",
																					type = "SILENCE" 
																				}

								cnt_cmd = cnt_cmd + 1
								j = j + 2
							end
						end

						j = 1
						for i = 1, cmdCount do
							if(AddCmdSuccess[i] == true) then
								SGP_vrHelp[j] = {	text = "VRCommand" .. tostring(i) }
								j = j + 1
							end

						end

						config.application1.registerAppInterfaceParams.hashID = self.currentHashID

						RegisterApp_HMILevelResumption(self, "FULL")

						
						--hmi side: expect UI.AddCommand request 
						EXPECT_HMICALL("UI.AddCommand", {})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response 
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						:Times(cmdCount)

						-- Updated because of APPLINK-15683
						--hmi side: expect VR.AddCommand request 
						EXPECT_HMICALL("VR.AddCommand", {})
						:Times(0)
					end

					Test["TC9_CheckInternalList10commands"] = function(self)
						local SGP_helpPrompt = {}
						local SGP_vrHelp = {}
						local cmdCount = 10
						local cnt_cmd = 1
						local i, j
						
						j = 1
						for i = 1, cmdCount do
							SGP_helpPrompt[j] = {
																			text = "VRCommand" .. tostring(i),
																			type = "TEXT" 
																		}
							SGP_helpPrompt[j + 1] =
																				{
																					text = "300",
																					type = "SILENCE" 
																				}
							j = j + 2
						end

						j = 1
						for i = 1, cmdCount do
							SGP_vrHelp[j] = {	text = "VRCommand" .. tostring(i) }
							j = j + 1
						end

						CheckUpdateFile(self, SGP_helpPrompt, SGP_vrHelp)
					end
				
					--Begin Test case PositiveResponseCheck.3
					for cmdCount = 1, 10 do
						Test["TC10_SetGlobalProperties_NoRequestToHMI_DelCommand_After10Added_Delete" .. (cmdCount)] = function(self)
							xmlReporter.AddMessage("Test Case 10")
							userPrint(35,"======================================= Test Case 10 =============================================")
							DeleteCommand(self, cmdCount)
							
							EXPECT_HMICALL("UI.SetGlobalProperties",{})
							:Times(0)
							:Timeout(7000)
							:Do(function(_,data)
								local time_UI_SGP = timestamp()
								userPrint(31, "Time to receive UI.SetGlobalProperties from HMI level not NONE is " .. tostring(time_UI_SGP - TimeHMILevel) .." msec")
							end)

							EXPECT_HMICALL("TTS.SetGlobalProperties",{})
							:Times(0)
							:Timeout(7000)
							:Do(function(_,data)
								local time_TTS_SGP = timestamp()
								userPrint(31, "Time to receive TTS.SetGlobalProperties from HMI level not NONE is " .. tostring(time_TTS_SGP - TimeHMILevel) .." msec")
							end)
						end
						
						Precondition_ResumeAppRegister(self, "TC10")

						Test["TC10_Resumption_data"] = function(self)	

							config.application1.registerAppInterfaceParams.hashID = self.currentHashID

							RegisterApp_HMILevelResumption(self, "FULL")

							--hmi side: expect UI.AddCommand request 
							EXPECT_HMICALL("UI.AddCommand", {})
							:Do(function(_,data)
								--hmi side: sending UI.AddCommand response 
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
							end)
							:Times(10 - cmdCount)

							-- Updated because of APPLINK-15683
							--hmi side: expect VR.AddCommand request 
							EXPECT_HMICALL("VR.AddCommand", {})
							:Times(0)
						end
						
						Test["TC10_CheckInternalListDelete10commands"] = function(self)
							local j = 1

							local SGP_helpPrompt = {}
							local SGP_vrHelp = {}
							
							if(cmdCount < 10) then
								for i = cmdCount+1 ,10 do
									SGP_helpPrompt[j] = {
																					text = "VRCommand" .. tostring(i),
																					type = "TEXT" 
																				}
									if(cmdCount < 9) then 
										SGP_helpPrompt[j + 1] =
																						{
																							text = "300",
																							type = "SILENCE" 
																						}
									end
									j = j + 2
								end
							end

							j = 1

							for i = cmdCount+1 ,10 do
								SGP_vrHelp[j] = {	text = "VRCommand" .. tostring(i) }
								j = j + 1
							end

							CheckUpdateFile(self, SGP_helpPrompt, SGP_vrHelp)
						end
					end
				--End Test case PositiveResponseCheck.3
		--Description: Positive case with request and update of internal list with helpPrompts, vrHelp
			--Requirement id in JIRA: APPLINK-23727; APPLINK-19474
			--Verification criteria:
				-- In case mobile app successfully registers and gets any HMILevel other than NONE SDL must:
					-- create internal list with "vrHelp" and "helpPrompt" based on successfully registered AddCommands and/or DeleteCommands requests
					-- start 10 sec timer right after app`s registration for waiting SetGlobalProperties_request from mobile app
			-- Precondition PositiveResponseCheck.4 
					Precondition_RegisterApp(self,"TC11")
					Precondition_ActivationApp(self, "TC11")

					Test["TC11_Precondition_SetGlobalProperties_AllValidParametes"] = function(self)

						--mobile side: sending SetGlobalProperties request
						local cid = self.mobileSession:SendRPC("SetGlobalProperties",
																									{
																										helpPrompt = 
																																{
																																	{
																																		text = "Help prompt 1",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 2",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 3",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 4",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 5",
																																		type = "TEXT"
																																	}

																																},
																										timeoutPrompt = 
																																{
																																	{
																																		text = "Timeout prompt",
																																		type = "TEXT"
																																	}
																																},
																										vrHelpTitle = "VR help title",
																										vrHelp = 
																																{
																																	{
																																		text = "VR help item",
																																		image = {
																																							value = "action.png",
																																							imageType = "DYNAMIC"
																																						},
																																		position = 1
																																	}
																																},
																										menuTitle = "Menu Title",
																										menuIcon = 
																																{
																																	value = "action.png",
																																	imageType = "DYNAMIC"
																																},
																										keyboardProperties = 
																																{
																																	keyboardLayout = "QWERTY",
																																	keypressMode = "SINGLE_KEYPRESS",
																																	limitedCharacterList = { "a" },
																																	language = "EN-US",
																																	autoCompleteText = "Daemon, Freedom"
																																}
																									})
					
						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
													{
														vrHelpTitle = "VR help title",
														vrHelp = 
																		{
																			{
																				text = "VR help item",
																				image = 
																								{
																									imageType = "DYNAMIC",
																									value = strAppFolder .. "action.png"
																								},--
																				position = 1
																		}	},
														menuTitle = "Menu Title",
														menuIcon = 
																			{
																				imageType = "DYNAMIC",
																				value = strAppFolder .. "action.png"
																			},
														keyboardProperties = 
																			{
																				keyboardLayout = "QWERTY",
																				keypressMode = "SINGLE_KEYPRESS",
																				limitedCharacterList = { "a" },
																				language = "EN-US",
																				autoCompleteText = "Daemon, Freedom"
																			},
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
													{
														helpPrompt = 
																				{
																					{
																						text = "Help prompt 1",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 2",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 3",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 4",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 5",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					}
																				},
														timeoutPrompt = 
																				{
																					{
																						text = "Timeout prompt",
																						type = "TEXT"
																				}	},
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
						:Do(function(_,data)
			 				--hmi side: sending UI.SetGlobalProperties response
			 				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)		

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
			
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
						:Do(function(_, data)
							
							self.currentHashID = data.payload.hashID
						end)
					end
					
					for cmdCount = 1, 5 do
						Test["TC11_Precondition_NoRequestToHMI_AddCommandInitial_" .. cmdCount] = function(self)

							AddCommand(self, cmdCount)

							EXPECT_HMICALL("UI.SetGlobalProperties",{})
							:Times(0)
							:Timeout(7000)
							:Do(function(_,data)
								local time_UI_SGP = timestamp()
								userPrint(31, "Time to receive UI.SetGlobalProperties from HMI level not NONE is " .. tostring(time_UI_SGP - TimeHMILevel) .." msec")
							end)

							EXPECT_HMICALL("TTS.SetGlobalProperties",{})
							:Times(0)
							:Timeout(7000)
							:Do(function(_,data)
								local time_TTS_SGP = timestamp()
								userPrint(31, "Time to receive TTS.SetGlobalProperties from HMI level not NONE is " .. tostring(time_TTS_SGP - TimeHMILevel) .." msec")
							end)
						end
					end 

					Precondition_ResumeAppRegister(self, "TC11")

					Test["TC11_Resumption_data"] = function(self)	
						local cmdCount = 5
						local time = timestamp()
						local cnt_cmd = 1;
						local SGP_helpPrompt = {}
						local SGP_vrHelp = {}
						local j = 1
							
						for i = 1, cmdCount do
							if(AddCmdSuccess[i] == true) then
								SGP_helpPrompt[j] ={
																			text = "VRCommand" .. tostring(i),
																			type = "TEXT" }
								SGP_helpPrompt[j+1] ={
																			text = "300",
																			type = "SILENCE" }
								j = j +2
								
								SGP_vrHelp[i] = { 
																	text = "VRCommand" .. tostring(i), 
																	position = 1
																}
							end
						end

						config.application1.registerAppInterfaceParams.hashID = self.currentHashID

						RegisterApp_HMILevelResumption(self, "FULL")

						--hmi side: expect UI.AddCommand request 
						EXPECT_HMICALL("UI.AddCommand", {})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response 
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						:Times(cmdCount)							
						
						-- Updated because of APPLINK-15683
						--hmi side: expect VR.AddCommand request 
						EXPECT_HMICALL("VR.AddCommand", {})
						:Times(0)
					end
				--Begin Test case PositiveResponseCheck.4
					--Internal list is updated
					Test["TC11_SetGlobalProperties_Without_vrHelp_helpPrompt"] = function(self)				
						local cmdCount = 5
						local time = timestamp()
						local cnt_cmd = 1;
						local SGP_helpPrompt = {}
						local SGP_vrHelp = {}
						local j = 1
							
						for i = 1, cmdCount do
							SGP_helpPrompt[j] ={
																			text = "VRCommand" .. tostring(i),
																			type = "TEXT" }
							SGP_helpPrompt[j+1] ={
																			text = "300",
																			type = "SILENCE" }
							j = j +2
								
							SGP_vrHelp[i] = { 
												text = "VRCommand" .. tostring(i), 
												position = i
											}
						end
							
						xmlReporter.AddMessage("Test Case 11")
						userPrint(35,"======================================= Test Case 11 =============================================")

						local cid = self.mobileSession:SendRPC("SetGlobalProperties",{ menuTitle = "Menu Title"})

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
																{
																	vrHelpTitle = config.application1.registerAppInterfaceParams.appName,
																	vrHelp = SGP_vrHelp ,
																	appID = self.applications[config.application1.registerAppInterfaceParams.appName]
																})
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
															{
																helpPrompt =  SGP_helpPrompt ,
																appID = self.applications[config.application1.registerAppInterfaceParams.appName]
															})
						:Do(function(_,data)
					 		--hmi side: sending UI.SetGlobalProperties response
					 		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)		

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
						:Do(function(_, data)
							
							self.currentHashID = data.payload.hashID
						end)
					end	
				--End Test case PositiveResponseCheck.4

				--Precondition PositiveResponseCheck.5
				--
					TextPrint("TC12_Precondition")
					--commonSteps:ActivationApp(_,"TC12_ActivationApp")
				
					Test["TC12_Precondition_Suspend"] = function(self)
						self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
																{ reason = "SUSPEND" })
						--Requirement id in JAMA/or Jira ID: APPLINK-15702
						--Send BC.OnPersistanceComplete to HMI on data persistance complete			
						-- hmi side: expect OnSDLPersistenceComplete notification
						EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
					end

					Test["TC12_Precondition_Ignion_OFF"] = function(self)

						StopSDL()
						
						-- hmi side: sends OnExitAllApplications (IGNITION_OFF)
						self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
																								{ reason = "IGNITION_OFF"	})

						-- hmi side: expect OnSDLClose notification
						EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")

						-- hmi side: expect OnAppUnregistered notification
						EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
					end

					Update_AppInfoDat(self, "TC12")
					
					Test["TC12_Precondition_StartSDL"] = function(self)
					
						StartSDL(config.pathToSDL, config.ExitOnCrash)
					end

					Test["TC12_Precondition_InitHMI"] = function(self)
					
						self:initHMI()
					end

					Test["TC12_Precondition_InitHMIOnReady"] = function(self)

						self:initHMI_onReady()
					end

					Test["TC12_Precondition_ConnectMobile"] = function (self)

						self:connectMobile()
					end

					Test["TC12_Precondition_StartSession"] = function(self)
						
						self.mobileSession = mobile_session.MobileSession(
																																self,
																																self.mobileConnection)
					end

					Test["TC12_Precondition_RegisterAppResumption"] = function (self)
						
						config.application1.registerAppInterfaceParams.hashID = self.currentHashID

						self.mobileSession:StartService(7)
						:Do(function()	
							local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
							EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
																	{
					  													application = {	appName = config.application1.registerAppInterfaceParams.appName }
																	})
							:Do(function(_,data)
				  				HMIAppID = data.params.application.appID
								self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
							end)

							
							EXPECT_HMICALL("BasicCommunication.ActivateApp")
							:Do(function(_,data)
							  	self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
							end)

							self.mobileSession:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })		

							EXPECT_NOTIFICATION("OnHMIStatus", 
											{hmiLevel = "NONE", systemContext = "MAIN"},
											{hmiLevel = "FULL", systemContext = "MAIN"})
							:Do(function(exp,data)
								if(exp.occurences == 2) then 
									TimeHMILevel = timestamp()
									print("HMI LEVEL is resumed")
									return TimeHMILevel
								end
							end)
							:Times(2)

						end)

						local UIAddCommandValues = {}
						for m = 1,5 do
							UIAddCommandValues[m] = {cmdID = m, menuParams = { menuName ="Command" .. tostring(m)}}
						end

						EXPECT_HMICALL("UI.AddCommand")
						:ValidIf(function(_,data)
							for i=1, #UIAddCommandValues do
								if (data.params.cmdID == UIAddCommandValues[i].cmdID ) and
									 (data.params.menuParams.position == 0 ) and 
									 (data.params.menuParams.menuName == UIAddCommandValues[i].menuParams.menuName ) then
										
										return true
								elseif (i == #UIAddCommandValues) then
									userPrint(31, "Any matches")
									userPrint(31, "Actual values cmdID ='" .. tostring(data.params.cmdID) .. "', position = '" .. tostring(data.params.menuParams.position) .. "', menuName = '" .. tostring(data.params.menuParams.menuName ) .. "'"  )
									return false
								end
							end
						end)
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response 
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						:Times(5)

						-- Updated because of APPLINK-15683
						--hmi side: expect VR.AddCommand request 
						EXPECT_HMICALL("VR.AddCommand", {})
						:Times(0)
					end

				--Begin Test case PositiveResponseCheck.5
					Test["TC12_SetGlobalPropertiesAfterResumption"] = function(self)
						local cnt_cmd = 1

						xmlReporter.AddMessage("Test Case 12")
						userPrint(35,"======================================= Test Case 12 =============================================")

						for i = 1, 10, 2 do
							SGP_helpPrompt[i] ={
													text = "VRCommand" .. tostring(cnt_cmd), --menuName}
													type = "TEXT" }
							SGP_helpPrompt[i + 1] ={
														text = "300",
														type = "SILENCE" }

							cnt_cmd = cnt_cmd + 1
						end
						for i = 1, 5 do
							SGP_vrHelp[i] = {	text = "VRCommand" .. tostring(i), position = i }
						end

						local cid = self.mobileSession:SendRPC("SetGlobalProperties",{menuTitle = "Menu Title"})

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
															{
																vrHelpTitle = config.application1.registerAppInterfaceParams.appName,
																-- Clarification is done in APPLINK-26638
																vrHelp = SGP_vrHelp,
																appID = self.applications[config.application1.registerAppInterfaceParams.appName]
															})
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
															{
																helpPrompt = SGP_helpPrompt,
																appID = self.applications[config.application1.registerAppInterfaceParams.appName]
															})
						:Do(function(_,data)
					 		--hmi side: sending UI.SetGlobalProperties response
					 		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)		

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")			
						:Do(function(_, data)
							
							self.currentHashID = data.payload.hashID
						end)		
					end
				--End Test case PositiveResponseCheck.5

		--Description: Positive case with request and update of internal list with helpPrompts, vrHelp
			--Requirement id in JIRA: APPLINK-23730
			--Verification criteria: In case ResetGlobalProperties_request SDL must continue update internal list with "vrHelp" and "helpPrompt" parameters
			--SDL must update internal list with "vrHelp" and "helpPrompt" parameters with new requested AddCommands till mobile app sends SetGlobalProperties 
			--                                                                                      request with valid <vrHelp> and <helpPrompt> params to SDL
				--Preconditions Test case PositiveResponseCheck.6
					Precondition_RegisterApp(self, "TC13")
					Precondition_ActivationApp(self, "TC13")

					Test["TC13_Precondition_SetGlobalProperties_AllValidParametes"] = function(self)

						--mobile side: sending SetGlobalProperties request
						local cid = self.mobileSession:SendRPC("SetGlobalProperties",
																									{
																										helpPrompt = 
																																{
																																	{
																																		text = "Help prompt 1",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 2",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 3",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 4",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 5",
																																		type = "TEXT"
																																	}

																																},
																										timeoutPrompt = 
																																{
																																	{
																																		text = "Timeout prompt",
																																		type = "TEXT"
																																	}
																																},
																										vrHelpTitle = "VR help title",
																										vrHelp = 
																																{
																																	{
																																		text = "VR help item",
																																		image = {
																																							value = "action.png",
																																							imageType = "DYNAMIC"
																																						},
																																		position = 1
																																	}
																																},
																										menuTitle = "Menu Title",
																										menuIcon = 
																																{
																																	value = "action.png",
																																	imageType = "DYNAMIC"
																																},
																										keyboardProperties = 
																																{
																																	keyboardLayout = "QWERTY",
																																	keypressMode = "SINGLE_KEYPRESS",
																																	limitedCharacterList = { "a" },
																																	language = "EN-US",
																																	autoCompleteText = "Daemon, Freedom"
																																}
																									})
					
						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
													{
														vrHelpTitle = "VR help title",
														vrHelp = 
																		{
																			{
																				text = "VR help item",
																				image = 
																								{
																									imageType = "DYNAMIC",
																									value = strAppFolder .. "action.png"
																								},--
																				position = 1
																		}	},
														menuTitle = "Menu Title",
														menuIcon = 
																			{
																				imageType = "DYNAMIC",
																				value = strAppFolder .. "action.png"
																			},
														keyboardProperties = 
																			{
																				keyboardLayout = "QWERTY",
																				keypressMode = "SINGLE_KEYPRESS",
																				limitedCharacterList = { "a" },
																				language = "EN-US",
																				autoCompleteText = "Daemon, Freedom"
																			},
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
													{
														helpPrompt = 
																				{
																					{
																						text = "Help prompt 1",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 2",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 3",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 4",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 5",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					}
																				},
														timeoutPrompt = 
																				{
																					{
																						text = "Timeout prompt",
																						type = "TEXT"
																				}	},
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
						:Do(function(_,data)
			 				--hmi side: sending UI.SetGlobalProperties response
			 				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)		

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
			
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
						:Do(function(_, data)
							
							self.currentHashID = data.payload.hashID
						end)
					end

					for cmdCount = 1, 5 do
						Test["TC13_Precondition_NoRequestToHMI_AddManyCommands" .. cmdCount] = function(self)
							AddCommand(self, cmdCount)						

							EXPECT_HMICALL("UI.SetGlobalProperties",{})
							:Times(0)
							:Timeout(7000)
							:Do(function(_,data)
								local time_UI_SGP = timestamp()
								userPrint(31, "Time to receive UI.SetGlobalProperties from HMI level not NONE is " .. tostring(time_UI_SGP - TimeHMILevel) .." msec")
							end)

							EXPECT_HMICALL("TTS.SetGlobalProperties",{})
							:Times(0)
							:Timeout(7000)
							:Do(function(_,data)
								local time_TTS_SGP = timestamp()
								userPrint(31, "Time to receive TTS.SetGlobalProperties from HMI level not NONE is " .. tostring(time_TTS_SGP - TimeHMILevel) .." msec")
							end)
						end
					end							
					
					Precondition_ResumeAppRegister(self, "TC13")

					Test["TC13_Resumption_data"] = function(self)	
						
						config.application1.registerAppInterfaceParams.hashID = self.currentHashID

						RegisterApp_HMILevelResumption(self, "FULL")

						--hmi side: expect UI.AddCommand request 
						EXPECT_HMICALL("UI.AddCommand", {})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response 
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						:Times(5)

						--hmi side: expect VR.AddCommand request 
						EXPECT_HMICALL("VR.AddCommand", {})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response 
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)						
						:Times(0)
					end
				
					Test["TC13_SetGlobalProperties_Without_vrHelp_helpPrompt"] = function(self)				
						local SGP_helpPrompt = {}
						local SGP_vrHelp = {}
						local cmdCount = 5
						local i
						local j =1
							
						for i = 1, cmdCount do
							SGP_helpPrompt[j] ={
													text = "VRCommand" .. tostring(i),
													type = "TEXT" }
							SGP_helpPrompt[j+1] ={
																					text = "300",
																					type = "SILENCE" }
							j = j + 2

							SGP_vrHelp[i] = { 
												text = "VRCommand" .. tostring(i), 
												position = i }
						end
							
						xmlReporter.AddMessage("Test Case 13")
						userPrint(35,"======================================= Test Case 13 =============================================")

						local cid = self.mobileSession:SendRPC("SetGlobalProperties",{ menuTitle = "Menu Title"})

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
																{
																	vrHelpTitle = config.application1.registerAppInterfaceParams.appName,
																	vrHelp = SGP_vrHelp ,
																	appID = self.applications[config.application1.registerAppInterfaceParams.appName]
																})
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
															{
																helpPrompt =  SGP_helpPrompt ,
																appID = self.applications[config.application1.registerAppInterfaceParams.appName]
															})
						:Do(function(_,data)
					 		--hmi side: sending UI.SetGlobalProperties response
					 		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)		

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
						:Do(function(_, data)
							
							self.currentHashID = data.payload.hashID
						end)
					end	

				--Begin Test case PositiveResponseCheck.6
					Test["TC13_ResetGlobalProperties"] = function(self)

						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",{
																							properties = 
																								{	
																									"VRHELPTITLE",
																									"MENUNAME",
																									"MENUICON",
																									"KEYBOARDPROPERTIES",
																									"VRHELPITEMS",
																									"HELPPROMPT",
																									"TIMEOUTPROMPT"
																								}
																							})
			  			
						EXPECT_HMICALL("UI.SetGlobalProperties",
													{
														vrHelpTitle = config.application1.registerAppInterfaceParams.appName,
													  -- Clarification is done: APPLINK-26638
														vrHelp = { 
																	{
																		text = config.application1.registerAppInterfaceParams.appName,
																		position = 1
																}	},
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
													{
														helpPrompt = default_HelpPrompt,		
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
						:Do(function(_,data)
			 				--hmi side: sending UI.SetGlobalProperties response
			 				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)								

						--mobile side: expect ResetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
						:Do(function(_, data)
							
							self.currentHashID = data.payload.hashID
						end)					
					end
				--End Test case PositiveResponseCheck.6

				Precondition_ResumeAppRegister(self, "TC14")

				Test["TC14_Resumption_data_5Commands"] = function(self)	
					local SGP_helpPrompt = {}
					local SGP_vrHelp = {}
					local cmdCount = 5
					local i
					local j =1
						
					config.application1.registerAppInterfaceParams.hashID = self.currentHashID

					RegisterApp_HMILevelResumption(self, "FULL")

					--hmi side: expect UI.AddCommand request 
					EXPECT_HMICALL("UI.AddCommand", {})
					:Do(function(_,data)
						--hmi side: sending UI.AddCommand response 
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)
					:Times(cmdCount)

					-- Updated because of APPLINK-15683
					--hmi side: expect VR.AddCommand request 
					EXPECT_HMICALL("VR.AddCommand", {})
					:Times(0)					
				end

				--Precondition Test case PositiveResponseCheck.7
				  -- Add another 5 commands as sequence from PositiveResponseCheck.6
					for cmdCount = 6, 10 do
						Test["TC14_Precondition_NoRequestToHMI_AddManyCommands" .. cmdCount] = function(self)
							AddCommand(self, cmdCount)

							EXPECT_HMICALL("UI.SetGlobalProperties",{})
							:Times(0)
							:Timeout(7000)
							:Do(function(_,data)
								local time_UI_SGP = timestamp()
								print("Time to receive UI.SetGlobalProperties from HMI level not NONE is " .. tostring(time_UI_SGP - TimeHMILevel) .." msec")
							end)

							EXPECT_HMICALL("TTS.SetGlobalProperties",{})
							:Times(0)
							:Timeout(7000)
							:Do(function(_,data)
								local time_TTS_SGP = timestamp()
								print("Time to receive TTS.SetGlobalProperties from HMI level not NONE is " .. tostring(time_TTS_SGP - TimeHMILevel) .." msec")
							end)
						end
					end		

					Precondition_ResumeAppRegister(self, "TC14")

					Test["TC14_Resumption_data_10Commands"] = function(self)	
						local SGP_helpPrompt = {}
						local SGP_vrHelp = {}
						local cmdCount = 10
						local i
						local j =1
							
						for i = 1, cmdCount do
							if(AddCmdSuccess[i] == true) then
						
								SGP_helpPrompt[j] ={
																			text = "VRCommand" .. tostring(i),
																			type = "TEXT" }
								SGP_helpPrompt[j+1] ={
																					text = "300",
																					type = "SILENCE" }
								j = j + 2

								SGP_vrHelp[i] = { 
																		text = "VRCommand" .. tostring(i), 
																		position = i
																	}
								end
						end

						config.application1.registerAppInterfaceParams.hashID = self.currentHashID

						RegisterApp_HMILevelResumption(self, "FULL")

						--hmi side: expect UI.AddCommand request 
						EXPECT_HMICALL("UI.AddCommand", {})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response 
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						:Times(cmdCount)
						
						-- Updated because of APPLINK-15683
						--hmi side: expect VR.AddCommand request 
						EXPECT_HMICALL("VR.AddCommand", {})
						:Times(0)	
					end

				--Begin Test case PositiveResponseCheck.7
					Test["TC14_ResetGlobalProperties_AdditionalCommand"] = function(self)
					  	local SGP_helpPrompt = {}
					  	local SGP_vrHelp = {}
						local cmdCount = 10
						local i
						local j =1
						
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",{
																							properties = 
																										{
																											"VRHELPTITLE",
																											"MENUNAME",
																											"MENUICON",
																											"KEYBOARDPROPERTIES",
																											"VRHELPITEMS",
																											"HELPPROMPT",
																											"TIMEOUTPROMPT"
																										}})
			  			
						EXPECT_HMICALL("UI.SetGlobalProperties",
													{
														vrHelpTitle = config.application1.registerAppInterfaceParams.appName,
													  -- Clarification is done: APPLINK-26638
														vrHelp = { 
																	{
																		text = config.application1.registerAppInterfaceParams.appName,
																		position = 1
																}	},
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
													{
														helpPrompt = default_HelpPrompt,
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
						:Do(function(_,data)
			 				--hmi side: sending UI.SetGlobalProperties response
			 				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)								

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
						:Do(function(_, data)
							
							self.currentHashID = data.payload.hashID
						end)
					end
				--End Test case PositiveResponseCheck.7

				--Preconditions Test case PositiveResponseCheck.8
					Precondition_RegisterApp(self, "TC15")
					Precondition_ActivationApp(self, "TC15")

				--Begin Test case PositiveResponseCheck.8
					Test["TC15_SetGlobalProperties_Reset_vrHelp_helpPrompt"] = function (self)
						xmlReporter.AddMessage("Test Case 15")
						userPrint(35,"======================================= Test Case 15 =============================================")
						--mobile side: sending SetGlobalProperties request
						local cid = self.mobileSession:SendRPC("SetGlobalProperties",
																										{
																											helpPrompt = 
																																	{
																																		{
																																			text = "Help prompt 1",
																																			type = "TEXT"
																																		},
																																		{
																																			text = "Help prompt 2",
																																			type = "TEXT"
																																		},
																																		{
																																			text = "Help prompt 3",
																																			type = "TEXT"
																																		},
																																		{
																																			text = "Help prompt 4",
																																			type = "TEXT"
																																		},
																																		{
																																			text = "Help prompt 5",
																																			type = "TEXT"
																																		}

																																	},
																											timeoutPrompt = 
																																	{
																																		{
																																			text = "Timeout prompt",
																																			type = "TEXT"
																																		}
																																	},
																											vrHelpTitle = "VR help title",
																											vrHelp = 
																																	{
																																		{
																																			text = "VR help item",
																																			image = {
																																								value = "action.png",
																																								imageType = "DYNAMIC"
																																							},
																																			position = 1
																																		}
																																	},
																											menuTitle = "Menu Title",
																											menuIcon = 
																																	{
																																		value = "action.png",
																																		imageType = "DYNAMIC"
																																	},
																											keyboardProperties = 
																																	{
																																		keyboardLayout = "QWERTY",
																																		keypressMode = "SINGLE_KEYPRESS",
																																		limitedCharacterList = { "a" },
																																		language = "EN-US",
																																		autoCompleteText = "Daemon, Freedom"
																																	}
																										})
						
						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
														{
															vrHelpTitle = "VR help title",
															vrHelp = 
																			{
																				{
																					text = "VR help item",
																					image = 
																									{
																										imageType = "DYNAMIC",
																										value = strAppFolder .. "action.png"
																									},
																					position = 1
																			}	},
															menuTitle = "Menu Title",
															menuIcon = 
																				{
																					imageType = "DYNAMIC",
																					value = strAppFolder .. "action.png"
																				},
															keyboardProperties = 
																				{
																					keyboardLayout = "QWERTY",
																					keypressMode = "SINGLE_KEYPRESS",
																					limitedCharacterList = { "a" },
																					language = "EN-US",
																					autoCompleteText = "Daemon, Freedom"
																				},
															appID = self.applications[config.application1.registerAppInterfaceParams.appName]
														})
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
														{
															helpPrompt = 
																					{
																						{
																							text = "Help prompt 1",
																							type = "TEXT"
																						},
																						{
																							text = "300",
																							type = "SILENCE"
																						},
																						{
																							text = "Help prompt 2",
																							type = "TEXT"
																						},
																						{
																							text = "300",
																							type = "SILENCE"
																						},
																						{
																							text = "Help prompt 3",
																							type = "TEXT"
																						},
																						{
																							text = "300",
																							type = "SILENCE"
																						},
																						{
																							text = "Help prompt 4",
																							type = "TEXT"
																						},
																						{
																							text = "300",
																							type = "SILENCE"
																						},
																						{
																							text = "Help prompt 5",
																							type = "TEXT"
																						},
																						{
																							text = "300",
																							type = "SILENCE"
																						}
																					},
															timeoutPrompt = 
																					{
																						{
																							text = "Timeout prompt",
																							type = "TEXT"
																					}	},
															appID = self.applications[config.application1.registerAppInterfaceParams.appName]
														})
						:Do(function(_,data)
				 			--hmi side: sending UI.SetGlobalProperties response
				 			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)		

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
						:Do(function(_, data)
							
							self.currentHashID = data.payload.hashID
						end)						
					end
				--End Test case PositiveResponseCheck.8

				
			--Verification criteria: In case ResetGlobalProperties_request SDL must continue update internal list with "vrHelp" and "helpPrompt" parameters
			--SDL must update internal list with "vrHelp" and "helpPrompt" parameters with new requested DeleteCommands till mobile app sends SetGlobalProperties 
			--                                                                                      request with valid <vrHelp> and <helpPrompt> params to SDL
				--Preconditions Test case PositiveResponseCheck.9
					-- Precondition_RegisterApp(self, "TC16")
					-- Precondition_ActivationApp(self, "TC16")
				
				--Begin Test case PositiveResponseCheck.9
				Test["TC16_ResetGlobalPropertiesAfterSetGlobalProp"] = function(self)
						local cid = self.mobileSession:SendRPC("ResetGlobalProperties",{
																						properties = 
																									{
																										"VRHELPTITLE",
																										"MENUNAME",
																										"MENUICON",
																										"KEYBOARDPROPERTIES",
																										"VRHELPITEMS",
																										"HELPPROMPT",
																										"TIMEOUTPROMPT"
																									}
																									})
			  			
						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
														{
															vrHelpTitle = config.application1.registerAppInterfaceParams.appName,
														  -- Clarification is done: APPLINK-26638
															vrHelp = { 
																		{
																			text = config.application1.registerAppInterfaceParams.appName,
																			position = 1
																	}	},
															appID = self.applications[config.application1.registerAppInterfaceParams.appName]
														})
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
														{
															helpPrompt = default_HelpPrompt,																		
															appID = self.applications[config.application1.registerAppInterfaceParams.appName]
														})
						:Do(function(_,data)
				 			--hmi side: sending UI.SetGlobalProperties response
				 			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)		

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
						:Do(function(_, data)
							
							self.currentHashID = data.payload.hashID
						end)
						
					end
				--End Test case PositiveResponseCheck.9

				--Preconditions Test case PositiveResponseCheck.10
					Precondition_RegisterApp(self, "TC17")
					Precondition_ActivationApp(self, "TC17")
					
					Test["TC17_Precondition_SetGlobalProperties_AllValidParametes"] = function(self)

						--mobile side: sending SetGlobalProperties request
						local cid = self.mobileSession:SendRPC("SetGlobalProperties",
																									{
																										helpPrompt = 
																																{
																																	{
																																		text = "Help prompt 1",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 2",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 3",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 4",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 5",
																																		type = "TEXT"
																																	}

																																},
																										timeoutPrompt = 
																																{
																																	{
																																		text = "Timeout prompt",
																																		type = "TEXT"
																																	}
																																},
																										vrHelpTitle = "VR help title",
																										vrHelp = 
																																{
																																	{
																																		text = "VR help item",
																																		image = {
																																							value = "action.png",
																																							imageType = "DYNAMIC"
																																						},
																																		position = 1
																																	}
																																},
																										menuTitle = "Menu Title",
																										menuIcon = 
																																{
																																	value = "action.png",
																																	imageType = "DYNAMIC"
																																},
																										keyboardProperties = 
																																{
																																	keyboardLayout = "QWERTY",
																																	keypressMode = "SINGLE_KEYPRESS",
																																	limitedCharacterList = { "a" },
																																	language = "EN-US",
																																	autoCompleteText = "Daemon, Freedom"
																																}
																									})
					
						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
													{
														vrHelpTitle = "VR help title",
														vrHelp = 
																		{
																			{
																				text = "VR help item",
																				image = 
																								{
																									imageType = "DYNAMIC",
																									value = strAppFolder .. "action.png"
																								},--
																				position = 1
																		}	},
														menuTitle = "Menu Title",
														menuIcon = 
																			{
																				imageType = "DYNAMIC",
																				value = strAppFolder .. "action.png"
																			},
														keyboardProperties = 
																			{
																				keyboardLayout = "QWERTY",
																				keypressMode = "SINGLE_KEYPRESS",
																				limitedCharacterList = { "a" },
																				language = "EN-US",
																				autoCompleteText = "Daemon, Freedom"
																			},
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
													{
														helpPrompt = 
																				{
																					{
																						text = "Help prompt 1",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 2",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 3",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 4",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 5",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					}
																				},
														timeoutPrompt = 
																				{
																					{
																						text = "Timeout prompt",
																						type = "TEXT"
																				}	},
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
						:Do(function(_,data)
			 				--hmi side: sending UI.SetGlobalProperties response
			 				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)		

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
			
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
						:Do(function(_, data)
							
							self.currentHashID = data.payload.hashID
						end)
					end

					for cmdCount = 1, 7 do
						Test["TC17_Precondition_NoRequestToHMI_AddManyCommands" .. cmdCount] = function(self)
							AddCommand(self, cmdCount)

							EXPECT_HMICALL("UI.SetGlobalProperties",{})
							:Times(0)
							:Timeout(7000)
							:Do(function(_,data)
								local time_UI_SGP = timestamp()
								print("Time to receive UI.SetGlobalProperties from HMI level not NONE is " .. tostring(time_UI_SGP - TimeHMILevel) .." msec")
							end)

							EXPECT_HMICALL("TTS.SetGlobalProperties",{})
							:Times(0)
							:Timeout(7000)
							:Do(function(_,data)
								local time_TTS_SGP = timestamp()
								print("Time to receive TTS.SetGlobalProperties from HMI level not NONE is " .. tostring(time_TTS_SGP - TimeHMILevel) .." msec")
							end)
						end
					end		

					Precondition_ResumeAppRegister(self, "TC17")

					Test["TC17_Resumption_data"] = function(self)	
						local SGP_helpPrompt = {}
						local SGP_vrHelp = {}
						local cmdCount = 7
						local i
						local j =1
							
						config.application1.registerAppInterfaceParams.hashID = self.currentHashID

						RegisterApp_HMILevelResumption(self, "FULL")

						--hmi side: expect UI.AddCommand request 
						EXPECT_HMICALL("UI.AddCommand", {})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response 
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
						:Times(cmdCount)
						
						-- Updated because of APPLINK-15683
						--hmi side: expect VR.AddCommand request 
						EXPECT_HMICALL("VR.AddCommand", {})
						:Times(0)
					end

					Putfile(self, "action.png")

					Test["TC17_Precondition_SetGlobalProperties_AllValidParametes"] = function(self)

						--mobile side: sending SetGlobalProperties request
						local cid = self.mobileSession:SendRPC("SetGlobalProperties",
																						{
																										helpPrompt = 
																																{
																																	{
																																		text = "Help prompt 1",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 2",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 3",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 4",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 5",
																																		type = "TEXT"
																																	}

																																},
																										timeoutPrompt = 
																																{
																																	{
																																		text = "Timeout prompt",
																																		type = "TEXT"
																																	}
																																},
																										vrHelpTitle = "VR help title",
																										vrHelp = 
																																{
																																	{
																																		text = "VR help item",
																																		image = {
																																							value = "action.png",
																																							imageType = "DYNAMIC"
																																						},
																																		position = 1
																																	}
																																},
																										menuTitle = "Menu Title",
																										menuIcon = 
																																{
																																	value = "action.png",
																																	imageType = "DYNAMIC"
																																},
																										keyboardProperties = 
																																{
																																	keyboardLayout = "QWERTY",
																																	keypressMode = "SINGLE_KEYPRESS",
																																	limitedCharacterList = { "a" },
																																	language = "EN-US",
																																	autoCompleteText = "Daemon, Freedom"
																																}
																									})
					
						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
													{
														vrHelpTitle = "VR help title",
														vrHelp = 
																		{
																			{
																				text = "VR help item",
																				image = 
																								{
																									imageType = "DYNAMIC",
																									value = strAppFolder .. "action.png"
																								},--
																				position = 1
																		}	},
														menuTitle = "Menu Title",
														menuIcon = 
																			{
																				imageType = "DYNAMIC",
																				value = strAppFolder .. "action.png"
																			},
														keyboardProperties = 
																			{
																				keyboardLayout = "QWERTY",
																				keypressMode = "SINGLE_KEYPRESS",
																				limitedCharacterList = { "a" },
																				language = "EN-US",
																				autoCompleteText = "Daemon, Freedom"
																			},
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
														{
															helpPrompt = 
																				{
																					{
																						text = "Help prompt 1",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 2",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 3",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 4",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 5",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					}
																				},
														timeoutPrompt = 
																				{
																					{
																						text = "Timeout prompt",
																						type = "TEXT"
																				}	},
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
						:Do(function(_,data)
				 			--hmi side: sending UI.SetGlobalProperties response
				 			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)		

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
						:Do(function(_, data)
							
							self.currentHashID = data.payload.hashID
						end)
					end

					--Begin Test case PositiveResponseCheck.10
					Test["TC17_ResetGlobalProperties_ContinueAddCommands"] = function(self)

							local cid = self.mobileSession:SendRPC("ResetGlobalProperties",{
																								properties = 
																									{
																										"VRHELPTITLE",
																										"MENUNAME",
																										"MENUICON",
																										"KEYBOARDPROPERTIES",
																										"VRHELPITEMS",
																										"HELPPROMPT",
																										"TIMEOUTPROMPT"
																									}
																							})

							--hmi side: expect UI.SetGlobalProperties request
							EXPECT_HMICALL("UI.SetGlobalProperties",
															{
																vrHelpTitle = config.application1.registerAppInterfaceParams.appName,
															  -- Clarification is done: APPLINK-26638
																vrHelp = { 
																			{
																				text = config.application1.registerAppInterfaceParams.appName,
																				position = 1
																		}	},
																appID = self.applications[config.application1.registerAppInterfaceParams.appName]
															})
							:Do(function(_,data)
								--hmi side: sending UI.SetGlobalProperties response
								self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
							end)

							--hmi side: expect TTS.SetGlobalProperties request
							EXPECT_HMICALL("TTS.SetGlobalProperties",
															{
																helpPrompt = default_HelpPrompt,																		
																appID = self.applications[config.application1.registerAppInterfaceParams.appName]
															})
							:Do(function(_,data)
					 			--hmi side: sending UI.SetGlobalProperties response
					 			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
							end)	

							--mobile side: expect SetGlobalProperties response
							EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
						
							--mobile side: expect OnHashChange notification
							EXPECT_NOTIFICATION("OnHashChange")
							:Do(function(_, data)
								
								self.currentHashID = data.payload.hashID
							end)						
					end
				--End Test case PositiveResponseCheck.10

				--Preconditions Test case PositiveResponseCheck.11
				  -- Test checks that after ResetGlobalProperties and again send SetGlobalProperties parameters are updated correctly.
				
				--Begin Test case PositiveResponseCheck.11
					Test["TC18_SetGlobalProperties_AgainReset_vrHelp_helpPrompt_TC"] = function(self)
						xmlReporter.AddMessage("Test Case 18")
						userPrint(35,"======================================= Test Case 18 =============================================")
						--mobile side: sending SetGlobalProperties request
						local cid = self.mobileSession:SendRPC("SetGlobalProperties",
																									{
																										helpPrompt = 
																																{
																																	{
																																		text = "Help prompt 1",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 2",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 3",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 4",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 5",
																																		type = "TEXT"
																																	}

																																},
																										timeoutPrompt = 
																																{
																																	{
																																		text = "Timeout prompt",
																																		type = "TEXT"
																																	}
																																},
																										vrHelpTitle = "VR help title",
																										vrHelp = 
																																{
																																	{
																																		text = "VR help item",
																																		image = {
																																							value = "action.png",
																																							imageType = "DYNAMIC"
																																						},
																																		position = 1
																																	}
																																},
																										menuTitle = "Menu Title",
																										menuIcon = 
																																{
																																	value = "action.png",
																																	imageType = "DYNAMIC"
																																},
																										keyboardProperties = 
																																{
																																	keyboardLayout = "QWERTY",
																																	keypressMode = "SINGLE_KEYPRESS",
																																	limitedCharacterList = { "a" },
																																	language = "EN-US",
																																	autoCompleteText = "Daemon, Freedom"
																																}
																									})

						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
														{
															vrHelpTitle = "VR help title",
															vrHelp = 
																			{
																				{
																					text = "VR help item",
																					image = 
																									{
																										imageType = "DYNAMIC",
																										value = strAppFolder .. "action.png"
																									},--
																					position = 1
																			}	},
															menuTitle = "Menu Title",
															menuIcon = 
																				{
																					imageType = "DYNAMIC",
																					value = strAppFolder .. "action.png"
																				},
															keyboardProperties = 
																				{
																					keyboardLayout = "QWERTY",
																					keypressMode = "SINGLE_KEYPRESS",
																					limitedCharacterList = { "a" },
																					language = "EN-US",
																					autoCompleteText = "Daemon, Freedom"
																				},
															appID = self.applications[config.application1.registerAppInterfaceParams.appName]
														})
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
														{
															helpPrompt = 
																					{
																						{
																							text = "Help prompt 1",
																							type = "TEXT"
																						},
																						{
																							text = "300",
																							type = "SILENCE"
																						},
																						{
																							text = "Help prompt 2",
																							type = "TEXT"
																						},
																						{
																							text = "300",
																							type = "SILENCE"
																						},
																						{
																							text = "Help prompt 3",
																							type = "TEXT"
																						},
																						{
																							text = "300",
																							type = "SILENCE"
																						},
																						{
																							text = "Help prompt 4",
																							type = "TEXT"
																						},
																						{
																							text = "300",
																							type = "SILENCE"
																						},
																						{
																							text = "Help prompt 5",
																							type = "TEXT"
																						},
																						{
																							text = "300",
																							type = "SILENCE"
																						}
																					},
															timeoutPrompt = 
																					{
																						{
																							text = "Timeout prompt",
																							type = "TEXT"
																					}	},
															appID = self.applications[config.application1.registerAppInterfaceParams.appName]
														})
						:Do(function(_,data)
				 			--hmi side: sending UI.SetGlobalProperties response
				 			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)		

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
				
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
						:Do(function(_, data)
							
							self.currentHashID = data.payload.hashID
						end)						
					end
				--End Test case PositiveResponseCheck.11

	--End Test suit PositiveResponseCheck
---------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------
----------------------------------------III TEST BLOCK----------------------------------------
------------------------------------Negative request cases------------------------------------
--Check of negative value of request/response parameters (mobile protocol, HMI protocol)------
----------------------------------------------------------------------------------------------
  --Begin Test suit NegativeRequestCheck
  	--Preconditions Test case NegativeRequestCheck.1

			Precondition_RegisterApp(self, "TC19")
			Precondition_ActivationApp(self, "TC19")

		--Begin Test case NegativeRequestCheck.1
			--Description: SDL receives REJECTED at response from HMI and shall not update internal list
				--Requirement id in JIRA: APPLINK-23729
				--Verification criteria:
					-- SDL must: transfer received REJECTED from HMI to mobile app
					-- SDL must NOT: update internal list with "vrHelp" and "helpPrompt" params
					Test["TC19_AddCommand_HMI_REJECTED"] = function(self)
						local cid = self.mobileSession:SendRPC("AddCommand",{
																				cmdID = 1,
																				menuParams = 	
																							{
																								position = 0,
																								menuName ="Command1"
																							}, 
																				vrCommands = {"VRCommand1"}
																			})
			
						--hmi side: expect UI.AddCommand request 
						EXPECT_HMICALL("UI.AddCommand",{})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response 
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

						--hmi side: expect VR.AddCommand request 
						EXPECT_HMICALL("VR.AddCommand", {})
						:Do(function(_,data)
							--hmi side: sending VR.AddCommand response 
							self.hmiConnection:SendResponse(data.id, data.method, "REJECTED", {})
						end)

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED"})
						
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
						
					end

					Test["TC19_NoUpdateFile_HMI_REJECTEDAddCommand"] = function(self)
						local cid = self.mobileSession:SendRPC("SetGlobalProperties",{menuTitle = "Menu Title"})
					
						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
													{
														vrHelpTitle = config.application1.registerAppInterfaceParams.appName,
														-- Clarification is done in APPLINK-26638
														vrHelp ={
																			{
																				text = config.application1.registerAppInterfaceParams.appName,
																				position = 1
																		} },	
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
													{
														helpPrompt = default_HelpPrompt,																		
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
						:Do(function(_,data)
			 				--hmi side: sending UI.SetGlobalProperties response
			 				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)		

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
			
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
						:Do(function(_, data)
							
							self.currentHashID = data.payload.hashID
						end)

					end
		--End Test case NegativeRequestCheck.1

		--Preconditions Test case NegativeRequestCheck.2
			Precondition_RegisterApp(self, "TC20")
			Precondition_ActivationApp(self, "TC20")

		--Begin Test case NegativeRequestCheck.2
			--Description: SDL receives any UNSUPPORTED_RESOURCE at response from HMI and shall not update internal list
				--Requirement id in JIRA: APPLINK-23729
				--Verification criteria:
					-- SDL must: transfer received UNSUPPORTED_RESOURCE from HMI to mobile app
					-- SDL must NOT: update internal list with "vrHelp" and "helpPrompt" params
					Test["TC20_AddCommand_HMI_UNSUPPORTED_RESOURCE"] = function(self)
						local cid = self.mobileSession:SendRPC("AddCommand",
																{
																	cmdID = 1,
																	menuParams = 	
																								{
																									position = 0,
																									menuName ="Command1"
																								}
																})
			
						--hmi side: expect UI.AddCommand request 
						EXPECT_HMICALL("UI.AddCommand", {})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response 
							self.hmiConnection:SendError(data.id, data.method, "UNSUPPORTED_RESOURCE", "Error Messages")
						end)

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE"})	
											
					end

					Test["TC20_NoUpdateFile_HMI_UnsupportedAddCommand"] = function(self)
						local cid = self.mobileSession:SendRPC("SetGlobalProperties",{menuTitle = "Menu Title"})
					
						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
													{
														vrHelpTitle = config.application1.registerAppInterfaceParams.appName,
														-- Clarification is done in APPLINK-26638
														vrHelp ={
																			{
																				text = config.application1.registerAppInterfaceParams.appName,
																				position = 1
																		}	},	
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
													{
														helpPrompt = default_HelpPrompt,																		
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
						:Do(function(_,data)
			 				--hmi side: sending UI.SetGlobalProperties response
			 				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)		

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
			
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
						:Do(function(_, data)
							
							self.currentHashID = data.payload.hashID
						end)

					end
		--End Test case NegativeRequestCheck.2

		--Preconditions Test case NegativeRequestCheck.3
			Precondition_RegisterApp(self, "TC21")
			Precondition_ActivationApp(self, "TC21")

			Test["TC21_Precondition_SetGlobalProperties_AllValidParametes"] = function(self)

						--mobile side: sending SetGlobalProperties request
						local cid = self.mobileSession:SendRPC("SetGlobalProperties",
																									{
																										helpPrompt = 
																																{
																																	{
																																		text = "Help prompt 1",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 2",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 3",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 4",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 5",
																																		type = "TEXT"
																																	}

																																},
																										timeoutPrompt = 
																																{
																																	{
																																		text = "Timeout prompt",
																																		type = "TEXT"
																																	}
																																},
																										vrHelpTitle = "VR help title",
																										vrHelp = 
																																{
																																	{
																																		text = "VR help item",
																																		image = {
																																							value = "action.png",
																																							imageType = "DYNAMIC"
																																						},
																																		position = 1
																																	}
																																},
																										menuTitle = "Menu Title",
																										menuIcon = 
																																{
																																	value = "action.png",
																																	imageType = "DYNAMIC"
																																},
																										keyboardProperties = 
																																{
																																	keyboardLayout = "QWERTY",
																																	keypressMode = "SINGLE_KEYPRESS",
																																	limitedCharacterList = { "a" },
																																	language = "EN-US",
																																	autoCompleteText = "Daemon, Freedom"
																																}
																									})
					
						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
													{
														vrHelpTitle = "VR help title",
														vrHelp = 
																		{
																			{
																				text = "VR help item",
																				image = 
																								{
																									imageType = "DYNAMIC",
																									value = strAppFolder .. "action.png"
																								},--
																				position = 1
																		}	},
														menuTitle = "Menu Title",
														menuIcon = 
																			{
																				imageType = "DYNAMIC",
																				value = strAppFolder .. "action.png"
																			},
														keyboardProperties = 
																			{
																				keyboardLayout = "QWERTY",
																				keypressMode = "SINGLE_KEYPRESS",
																				limitedCharacterList = { "a" },
																				language = "EN-US",
																				autoCompleteText = "Daemon, Freedom"
																			},
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
													{
														helpPrompt = 
																				{
																					{
																						text = "Help prompt 1",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 2",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 3",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 4",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 5",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					}
																				},
														timeoutPrompt = 
																				{
																					{
																						text = "Timeout prompt",
																						type = "TEXT"
																				}	},
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
						:Do(function(_,data)
			 				--hmi side: sending UI.SetGlobalProperties response
			 				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)		

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
			
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
						:Do(function(_, data)
							
							self.currentHashID = data.payload.hashID
						end)
			end

		--Begin Test case NegativeRequestCheck.3
			--Description: SDL receives REJECTED at response from HMI and shall not update internal list
				--Requirement id in JIRA: APPLINK-23729
				--Verification criteria:
					-- SDL must: transfer received REJECTED from HMI to mobile app
					-- SDL must NOT: update internal list with "vrHelp" and "helpPrompt" params
					--Precondition
					Test["TC21_Precondition_AddCommand_HMI_NegativeResp"] = function(self)
						AddCommand(self, 202)

						EXPECT_HMICALL("UI.SetGlobalProperties",{})
						:Times(0)

						EXPECT_HMICALL("TTS.SetGlobalProperties",{})
						:Times(0)
					end

					Precondition_ResumeAppRegister(self, "TC21")

					Test["TC21_Resumption_data"] = function(self)	
						local SGP_helpPrompt = {}
						local SGP_vrHelp = {}
							
						SGP_helpPrompt[1] ={
																text = "VRCommand" .. tostring(202),
																type = "TEXT" }
						SGP_helpPrompt[2] ={
																text = "300",
																type = "SILENCE" }
								
						SGP_vrHelp[1] = { text = "VRCommand" .. tostring(202) }

						config.application1.registerAppInterfaceParams.hashID = self.currentHashID

						RegisterApp_HMILevelResumption(self, "FULL")
					
						--hmi side: expect UI.AddCommand request 
						EXPECT_HMICALL("UI.AddCommand", 
								{ 
									cmdID = 202,		
									menuParams = 
									{
										position = 0,
										menuName ="Command" .. tostring(202)
									}
								})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response 
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

						-- Updated because of APPLINK-15683
						--hmi side: expect VR.AddCommand request 
						EXPECT_HMICALL("VR.AddCommand", {})
						:Times(0)
					end

					Test["TC21_CheckInternalList_OneCommand"] = function(self)
						
						local SGP_helpPrompt = {}
						local SGP_vrHelp = {}
							
						SGP_helpPrompt[1] ={
																text = "VRCommand" .. tostring(202),
																type = "TEXT" }
							
						SGP_vrHelp[1] = { text = "VRCommand" .. tostring(202) }
							
						CheckUpdateFile(self, SGP_helpPrompt, SGP_vrHelp)
					end
					
					Test["TC21_DeleteCommand_HMI_REJECTED"] = function(self)
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																										{
																											cmdID = 202
																										})
			
						--hmi side: expect UI.AddCommand request 
						EXPECT_HMICALL("UI.DeleteCommand", {})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response 
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

						--hmi side: expect UI.AddCommand request 
						EXPECT_HMICALL("VR.DeleteCommand", {})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response 
							self.hmiConnection:SendResponse(data.id, data.method, "REJECTED", {})
						end)

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED"})
						
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)						
					end

					Precondition_ResumeAppRegister(self, "TC21")

					Test["TC21_Resumption_data"] = function(self)	
						local SGP_helpPrompt = {}
						local SGP_vrHelp = {}
							
						SGP_helpPrompt[1] ={
																text = "VRCommand" .. tostring(202),
																type = "TEXT" }
						SGP_helpPrompt[2] ={
																text = "300",
																type = "SILENCE" }
								
						SGP_vrHelp[1] = { text = "VRCommand" .. tostring(202) }

						config.application1.registerAppInterfaceParams.hashID = self.currentHashID

						RegisterApp_HMILevelResumption(self, "FULL")
					
						--hmi side: expect UI.AddCommand request 
						EXPECT_HMICALL("UI.AddCommand", 
								{ 
									cmdID = 202,		
									menuParams = 
									{
										position = 0,
										menuName ="Command" .. tostring(202)
									}
								})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response 
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

						--hmi side: expect VR.AddCommand request 
						EXPECT_HMICALL("VR.AddCommand", {})
						:Times(0)
							
						
					end

					Test["TC21_NoUpdateFile_HMI_REJECTEDDeletCommand"] = function(self)
							local SGP_helpPrompt = {}
							local SGP_vrHelp = {}

							SGP_helpPrompt[1] ={
																		text = "VRCommand" .. tostring(202),
																		type = "TEXT" }
								
							SGP_vrHelp[1] = { text = "VRCommand" .. tostring(202) }
							
							CheckUpdateFile(self, SGP_helpPrompt, SGP_vrHelp)
					end
		--End Test case NegativeRequestCheck.3

		--Preconditions Test case NegativeRequestCheck.4
			Precondition_RegisterApp(self, "TC22")
			Precondition_ActivationApp(self, "TC22")

			Test["TC22_Precondition_SetGlobalProperties_AllValidParametes"] = function(self)

				--mobile side: sending SetGlobalProperties request
				local cid = self.mobileSession:SendRPC("SetGlobalProperties",
																									{
																										helpPrompt = 
																																{
																																	{
																																		text = "Help prompt 1",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 2",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 3",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 4",
																																		type = "TEXT"
																																	},
																																	{
																																		text = "Help prompt 5",
																																		type = "TEXT"
																																	}

																																},
																										timeoutPrompt = 
																																{
																																	{
																																		text = "Timeout prompt",
																																		type = "TEXT"
																																	}
																																},
																										vrHelpTitle = "VR help title",
																										vrHelp = 
																																{
																																	{
																																		text = "VR help item",
																																		image = {
																																							value = "action.png",
																																							imageType = "DYNAMIC"
																																						},
																																		position = 1
																																	}
																																},
																										menuTitle = "Menu Title",
																										menuIcon = 
																																{
																																	value = "action.png",
																																	imageType = "DYNAMIC"
																																},
																										keyboardProperties = 
																																{
																																	keyboardLayout = "QWERTY",
																																	keypressMode = "SINGLE_KEYPRESS",
																																	limitedCharacterList = { "a" },
																																	language = "EN-US",
																																	autoCompleteText = "Daemon, Freedom"
																																}
																									})
					
						--hmi side: expect UI.SetGlobalProperties request
						EXPECT_HMICALL("UI.SetGlobalProperties",
													{
														vrHelpTitle = "VR help title",
														vrHelp = 
																		{
																			{
																				text = "VR help item",
																				image = 
																								{
																									imageType = "DYNAMIC",
																									value = strAppFolder .. "action.png"
																								},--
																				position = 1
																		}	},
														menuTitle = "Menu Title",
														menuIcon = 
																			{
																				imageType = "DYNAMIC",
																				value = strAppFolder .. "action.png"
																			},
														keyboardProperties = 
																			{
																				keyboardLayout = "QWERTY",
																				keypressMode = "SINGLE_KEYPRESS",
																				limitedCharacterList = { "a" },
																				language = "EN-US",
																				autoCompleteText = "Daemon, Freedom"
																			},
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
						:Do(function(_,data)
							--hmi side: sending UI.SetGlobalProperties response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

						--hmi side: expect TTS.SetGlobalProperties request
						EXPECT_HMICALL("TTS.SetGlobalProperties",
													{
														helpPrompt = 
																				{
																					{
																						text = "Help prompt 1",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 2",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 3",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 4",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					},
																					{
																						text = "Help prompt 5",
																						type = "TEXT"
																					},
																					{
																						text = "300",
																						type = "SILENCE"
																					}
																				},
														timeoutPrompt = 
																				{
																					{
																						text = "Timeout prompt",
																						type = "TEXT"
																				}	},
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
						:Do(function(_,data)
			 				--hmi side: sending UI.SetGlobalProperties response
			 				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)		

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
			
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
						:Do(function(_, data)
							
							self.currentHashID = data.payload.hashID
						end)
			end

			Test["TC22_Precondition_AddCommand_HMI_NegativeResp"] = function(self)
				AddCommand(self, 202)
			end
			
			Precondition_ResumeAppRegister(self, "TC22")

			Test["TC22_Resumption_data"] = function(self)	
						

				config.application1.registerAppInterfaceParams.hashID = self.currentHashID

				RegisterApp_HMILevelResumption(self, "FULL")

					
				--hmi side: expect UI.AddCommand request 
				EXPECT_HMICALL("UI.AddCommand", 
								{ 
									cmdID = 202,		
									menuParams = 
									{
										position = 0,
										menuName ="Command" .. tostring(202)
									}
								})
				:Do(function(_,data)
					--hmi side: sending UI.AddCommand response 
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)				
							
						-- Updated because of APPLINK-15683
						--hmi side: expect VR.AddCommand request 
						EXPECT_HMICALL("VR.AddCommand", {})
						:Times(0)
			end

			Test["TC22_CheckInternalList_OneCommand"] = function(self)
				local SGP_helpPrompt = {}
				local SGP_vrHelp     = {}

				SGP_helpPrompt[1] ={
																text = "VRCommand" .. tostring(202),
																type = "TEXT" }								
				SGP_vrHelp[1] = { text = "VRCommand" .. tostring(202) }
							
				CheckUpdateFile(self, SGP_helpPrompt, SGP_vrHelp)
			end

		--Begin Test case NegativeRequestCheck.4
			--Description: SDL receives any UNSUPPORTED_RESOURCE at response from HMI and shall not update internal list
				--Requirement id in JIRA: APPLINK-23729
				--Verification criteria:
					-- SDL must: transfer received UNSUPPORTED_RESOURCE from HMI to mobile app
					-- SDL must NOT: update internal list with "vrHelp" and "helpPrompt" params
					Test["TC22_DeleteCommand_HMI_UNSUPPORTED_RESOURCE"] = function(self)
						local cid = self.mobileSession:SendRPC("DeleteCommand",
																				{
																					cmdID = 202
																				})
			
						--hmi side: expect UI.AddCommand request 
						EXPECT_HMICALL("UI.DeleteCommand", {})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response 
							self.hmiConnection:SendError(data.id, data.method, "UNSUPPORTED_RESOURCE", "ERROR_MESSAGE")
							--self.hmiConnection:SendError(data.id, data.method, "SUCCESS")
						end)

						EXPECT_HMICALL("VR.DeleteCommand", {})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response 
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)

						--mobile side: expect SetGlobalProperties response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE"})
						
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)				
					
					end

					Precondition_ResumeAppRegister(self, "TC22")


					Test["TC22_Resumption_data"] = function(self)	
								

						config.application1.registerAppInterfaceParams.hashID = self.currentHashID

						RegisterApp_HMILevelResumption(self, "FULL")

							
								--hmi side: expect UI.AddCommand request 
						EXPECT_HMICALL("UI.AddCommand", 
										{ 
											cmdID = 202,		
											menuParams = 
											{
												position = 0,
												menuName ="Command" .. tostring(202)
											}
										})
						:Do(function(_,data)
							--hmi side: sending UI.AddCommand response 
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
						end)
								-- Updated because of APPLINK-15683
								--hmi side: expect VR.AddCommand request 
								EXPECT_HMICALL("VR.AddCommand", {})
								:Times(0)							
					end

					Test["TC22_NoUpdateFile_HMI_UnsupportedDeletCommand"] = function(self)
						
						local SGP_helpPrompt = {}
						local SGP_vrHelp = {}
						
						SGP_helpPrompt[1] ={
																text = "VRCommand" .. tostring(202), --menuName}
																type = "TEXT" }
								
						SGP_vrHelp[1] = { text = "VRCommand" .. tostring(202) }
							
						CheckUpdateFile(self, SGP_helpPrompt, SGP_vrHelp)
					end
		--End Test case NegativeRequestCheck.4

  --End Test suit NegativeRequestCheck
----------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result codes check-------------------------------------
------------------Check of each resultCode + success (true, false)----------------------------
	--These test shall be performed in tests for testing API SetGlobalProperties. 
	--Begin Test suit ResultCodesCheck
	--End Test suit ResultCodesCheck

----------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------
----------------------------------------V TEST BLOCK------------------------------------------
------------------------------------ HMI negative cases---------------------------------------
----------------------------------incorrect data from HMI-------------------------------------
  --These test shall be performed in tests for testing API SetGlobalProperties.
  --See ATF_SetGlobalProperties.lua
  --Begin Test suit HMINegativeCases
  --End Test suit HMINegativeCases

----------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------
----------------------------------------VI TEST BLOCK-----------------------------------------
--------------------------Sequence with emulating of user's action(s)-------------------------
----------------------------------------------------------------------------------------------
  --Begin Test suit EmulatingUserAction
		--Begin Test case EmulatingUserAction.1
			--Precondition
			Precondition_RegisterApp(self,"TC23")
			Precondition_ActivationApp(self, "TC23")

			Test["TC23_Precondition_NoRespUpdateList"] = function(self)
			
				--mobile side: sending SetGlobalProperties request
				local cid = self.mobileSession:SendRPC("SetGlobalProperties",
																											{
																												helpPrompt = 
																																		{
																																			{
																																				text = "Help prompt 1",
																																				type = "TEXT"
																																			},
																																			{
																																				text = "Help prompt 2",
																																				type = "TEXT"
																																			},
																																			{
																																				text = "Help prompt 3",
																																				type = "TEXT"
																																			},
																																			{
																																				text = "Help prompt 4",
																																				type = "TEXT"
																																			},
																																			{
																																				text = "Help prompt 5",
																																				type = "TEXT"
																																			}

																																		},
																												timeoutPrompt = 
																																		{
																																			{
																																				text = "Timeout prompt",
																																				type = "TEXT"
																																			}
																																		},
																												vrHelpTitle = "VR help title",
																												vrHelp = 
																																		{
																																			{
																																				text = "VR help item",
																																				image = {
																																									value = "action.png",
																																									imageType = "DYNAMIC"
																																								},
																																				position = 1
																																			}
																																		},
																												menuTitle = "Menu Title",
																												menuIcon = 
																																		{
																																			value = "action.png",
																																			imageType = "DYNAMIC"
																																		},
																												keyboardProperties = 
																																		{
																																			keyboardLayout = "QWERTY",
																																			keypressMode = "SINGLE_KEYPRESS",
																																			limitedCharacterList = { "a" },
																																			language = "EN-US",
																																			autoCompleteText = "Daemon, Freedom"
																																		}
																											})
							
				--hmi side: expect UI.SetGlobalProperties request
				EXPECT_HMICALL("UI.SetGlobalProperties",
															{
																vrHelpTitle = "VR help title",
																vrHelp = 
																				{
																					{
																						text = "VR help item",
																						image = 
																										{
																											imageType = "DYNAMIC",
																											value = strAppFolder .. "action.png"
																										},--
																						position = 1
																				}	},
																menuTitle = "Menu Title",
																menuIcon = 
																					{
																						imageType = "DYNAMIC",
																						value = strAppFolder .. "action.png"
																					},
																keyboardProperties = 
																					{
																						keyboardLayout = "QWERTY",
																						keypressMode = "SINGLE_KEYPRESS",
																						limitedCharacterList = { "a" },
																						language = "EN-US",
																						autoCompleteText = "Daemon, Freedom"
																					},
																appID = self.applications[config.application1.registerAppInterfaceParams.appName]
															})
				:Do(function(_,data)
					--hmi side: sending UI.SetGlobalProperties response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)

				--hmi side: expect TTS.SetGlobalProperties request
				EXPECT_HMICALL("TTS.SetGlobalProperties",
															{
																helpPrompt = 
																						{
																							{
																								text = "Help prompt 1",
																								type = "TEXT"
																							},
																							{
																								text = "300",
																								type = "SILENCE"
																							},
																							{
																								text = "Help prompt 2",
																								type = "TEXT"
																							},
																							{
																								text = "300",
																								type = "SILENCE"
																							},
																							{
																								text = "Help prompt 3",
																								type = "TEXT"
																							},
																							{
																								text = "300",
																								type = "SILENCE"
																							},
																							{
																								text = "Help prompt 4",
																								type = "TEXT"
																							},
																							{
																								text = "300",
																								type = "SILENCE"
																							},
																							{
																								text = "Help prompt 5",
																								type = "TEXT"
																							},
																							{
																								text = "300",
																								type = "SILENCE"
																							}
																						},
																timeoutPrompt = 
																						{
																							{
																								text = "Timeout prompt",
																								type = "TEXT"
																						}	},
																appID = self.applications[config.application1.registerAppInterfaceParams.appName]
															})
				:Do(function(_,data)
			 		--hmi side: sending UI.SetGlobalProperties response
			 		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				end)		

				--mobile side: expect SetGlobalProperties response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
					
				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
				:Do(function(_, data)
							
							self.currentHashID = data.payload.hashID
				end)
			end
			
			for cmdCount = 1, 1 do				
				Test["TC23_Precondition_NoRequestToHMI_AddCommand" .. cmdCount] = function(self)
				
					AddCommand(self, cmdCount)

					EXPECT_HMICALL("UI.SetGlobalProperties",{})
					:Times(0)
							:Timeout(7000)
					:Do(function(_,data)
						local time_UI_SGP = timestamp()
						userPrint(31,"Time to receive UI.SetGlobalProperties from HMI level not NONE is " .. tostring(time_UI_SGP - TimeHMILevel) .." msec")
					end)

					EXPECT_HMICALL("TTS.SetGlobalProperties",{})
					:Times(0)
					:Timeout(7000)
					:Do(function(_,data)
						local time_TTS_SGP = timestamp()
						print("Time to receive TTS.SetGlobalProperties from HMI level not NONE is " .. tostring(time_TTS_SGP - TimeHMILevel) .." msec")
					end)
				end						
						
				Precondition_ResumeAppRegister(self, "TC23")


				Test["TC23_Resumption_data"] = function(self)	
					
					config.application1.registerAppInterfaceParams.hashID = self.currentHashID

					RegisterApp_HMILevelResumption(self, "FULL")

					--hmi side: expect UI.AddCommand request 
					EXPECT_HMICALL("UI.AddCommand", {})
					:Do(function(_,data)
						--hmi side: sending UI.AddCommand response 
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

					
					-- Updated because of APPLINK-15683
					--hmi side: expect VR.AddCommand request 
					EXPECT_HMICALL("VR.AddCommand", {})
					:Times(0)
				end

				Test["TC23_Precondition_CheckInternalList_AddCommand" .. cmdCount] = function(self)
					local SGP_helpPrompt = {}
					local SGP_vrHelp = {}

					SGP_helpPrompt[1] ={
											text = "VRCommand1", 
											type = "TEXT" }
										
					SGP_vrHelp[1] = { text = "VRCommand1"  }
							
					CheckUpdateFile(self, SGP_helpPrompt, SGP_vrHelp)
				end

				Precondition_ResumeAppRegister(self, "TC23")

				Test["TC23_Resumption_data"] = function(self)	
										
					config.application1.registerAppInterfaceParams.hashID = self.currentHashID

					RegisterApp_HMILevelResumption(self, "FULL")			
					
					--hmi side: expect UI.AddCommand request 
					EXPECT_HMICALL("UI.AddCommand", {})
					:Do(function(_,data)
						--hmi side: sending UI.AddCommand response 
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)				
					
					-- Updated because of APPLINK-15683
					--hmi side: expect VR.AddCommand request 
					EXPECT_HMICALL("VR.AddCommand", {})
					:Times(0)			
				end

						
				Test["TC23_Precondition_NoRequestToHMI_DeleteCommand" .. cmdCount] = function(self)
					DeleteCommand(self, cmdCount)
							
					EXPECT_HMICALL("UI.SetGlobalProperties",{})
					:Times(0)
					:Timeout(7000)
					:Do(function(_,data)
						local time_UI_SGP = timestamp()
						userPrint(31,"Time to receive UI.SetGlobalProperties from HMI level not NONE is " .. tostring(time_UI_SGP - TimeHMILevel) .." msec")
					end)

					EXPECT_HMICALL("TTS.SetGlobalProperties",{})
					:Times(0)
					:Timeout(7000)
					:Do(function(_,data)
						local time_TTS_SGP = timestamp()
						print("Time to receive TTS.SetGlobalProperties from HMI level not NONE is " .. tostring(time_TTS_SGP - TimeHMILevel) .." msec")
					end)
				end
			end

				Precondition_ResumeAppRegister(self, "TC23")

				Test["TC23_Resumption_data"] = function(self)	
					
					config.application1.registerAppInterfaceParams.hashID = self.currentHashID

					RegisterApp_HMILevelResumption(self, "FULL")

					--hmi side: expect UI.AddCommand request 
					EXPECT_HMICALL("UI.AddCommand", {})
					:Times(0)

				end

				Test["TC23_SetGlobalProperties_NoParams_DefaultvrHelp_HelpPrompt"] = function (self)					
					xmlReporter.AddMessage("Test Case 4")
					userPrint(35,"======================================= Test Case 23 =============================================")
					--mobile side: sending SetGlobalProperties request
					local cid = self.mobileSession:SendRPC("SetGlobalProperties",{ menuTitle = "Menu Title"})
					
					--hmi side: expect UI.SetGlobalProperties request
					EXPECT_HMICALL("UI.SetGlobalProperties",
													{
														vrHelpTitle = config.application1.registerAppInterfaceParams.appName,
													  -- Clarification is done: APPLINK-26638
														vrHelp = { 
																	{
																		text = config.application1.registerAppInterfaceParams.appName,
																		position = 1
																}	},
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
					:Do(function(_,data)
						--hmi side: sending UI.SetGlobalProperties response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)

					--hmi side: expect TTS.SetGlobalProperties request
					EXPECT_HMICALL("TTS.SetGlobalProperties",
													{
														helpPrompt = default_HelpPrompt,																		
														appID = self.applications[config.application1.registerAppInterfaceParams.appName]
													})
					:Do(function(_,data)
			 			--hmi side: sending UI.SetGlobalProperties response
			 			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
					end)		

					--mobile side: expect SetGlobalProperties response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
			
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
					:Do(function(_, data)
						
						self.currentHashID = data.payload.hashID
					end)										
				end
		--End Test case EmulatingUserAction.2
  --End Test suit EmulatingUserAction 
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
----------------------------------------VII TEST BLOCK----------------------------------------
-------------------------------------Different HMIStatus--------------------------------------
--Not applicable in scope of CRQ
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
-------------------------------------------Postconditions------------------------------------
---------------------------------------------------------------------------------------------
	function Test:Postcondition_remove_user_connecttest_restore_preloaded_file()
  	os.execute(" cp " .. config.pathToSDL .. "sdl_preloaded_pt_origin.json " .. config.pathToSDL .. "sdl_preloaded_pt.json" )
  	os.execute(" rm -f " .. config.pathToSDL .. "/sdl_preloaded_pt_origin.json" ) 
	end
---------------------------------------------------------------------------------------------

return Test