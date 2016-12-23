----------------------------------------------------------------------------------------------------------
--ATF version 2.2
----------------------------------------------------------------------------------------------------------
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
APIName = "OnEventChanged" -- use for above required scripts.

---------------------------------------------------------------------------------------------
----------------------------------- Common Functions------------------------------------------
function Test:onEventChanged(enable, OnHMIStatus)
	--hmi side: send OnEventChanged (EMBEDDED_NAVI,isActive: ON/OFF) notification to SDL
	self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= enable, eventName="EMBEDDED_NAVI"})
	self.mobileSession:ExpectNotification("OnHMIStatus",OnHMIStatus)
end
-----------------------------------------------------------------------------------------

function Test:change_App_Params(appType,isMedia)
	config.application1.registerAppInterfaceParams.isMediaApplication = isMedia
	config.application1.registerAppInterfaceParams.appHMIType = appType
end
------------------------------------------------------------------------------------------------

function Test:bring_App_To_LIMITED()
	local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
		{
			appID = self.applications[config.application1.registerAppInterfaceParams.appName]
		})

	self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	
end
------------------------------------------------------------------------------------------------

function Test:start_VRSESSION(hmiLevel)
	
	self.hmiConnection:SendNotification("VR.Started")
    if hmiLevel=="FULL" then 
		self.hmiConnection:SendNotification("UI.OnSystemContext", {systemContext = "VRSESSION",appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
		self.mobileSession:ExpectNotification("OnHMIStatus",
															{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
															{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION"}
		): Times(2)
	end
	if hmiLevel=="LIMITED" then 
		self.hmiConnection:SendNotification("UI.OnSystemContext", {systemContext = "VRSESSION"})
		self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}
		)
	end
end
------------------------------------------------------------------------------------------------

function Test:stop_VRSESSION(hmiLevel)
	
	--hmi side: send OnSystemContext
	self.hmiConnection:SendNotification("VR.Stopped")
	self.hmiConnection:SendNotification("UI.OnSystemContext", {systemContext = "MAIN",appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
	if hmiLevel=="FULL" then 
		self.mobileSession:ExpectNotification("OnHMIStatus",
															{hmiLevel = hmiLevel, audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
															{hmiLevel = hmiLevel, audioStreamingState = "AUDIBLE", systemContext = "MAIN"}
		): Times(2)
	end
	if hmiLevel=="LIMITED" then 
		self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = hmiLevel, audioStreamingState = "AUDIBLE", systemContext = "MAIN"}
		)
	end
end
------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

	--1. Print new line to separate Preconditions
	commonFunctions:newTestCasesGroup("Preconditions")

	--2. Delete app_info.dat, logs and policy table
	commonSteps:DeleteLogsFileAndPolicyTable()

	--3.Unregister app
	commonSteps:UnregisterApplication("UnregisterApplication_Precondition")

	--4. Update policy to allow request
	policyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/ptu_general.json")

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK I----------------------------------------
--------------------------------Check normal cases of Mobile request---------------------------
-----------------------------------------------------------------------------------------------

--Not Applicable

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK II----------------------------------------
-----------------------------Check special cases of Mobile request----------------------------
----------------------------------------------------------------------------------------------

--Not Applicable

-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK III--------------------------------------
----------------------------------Check normal cases of HMI notification-----------------------
-----------------------------------------------------------------------------------------------
-- Requirements:
	-- 1. CRQ APPLINK-17839: APPLINK-18877, APPLINK-18950 for Navi App 
-- NOTE:
	-- 2. Coverage for Media app must be worked in scope of CRQ APPLINK-20783 (Task APPLINK-20788),
	-- 3. Coverage for Communication app must be worked in scope of CRQ APPLINK-20807 (Task APPLINK-20812)
	-- 3. Coverage for Non media app must be worked in scope of CRQ APPLINK-20344 (Task APPLINK-20349)
------------------------------------------------------------------------------------------------

-- Verify OnEventChanged(EMBEDDED_NAVI):
	-- 1."isActive" is true/false
	-- 2.Without "isActive" value
	-- 3.With "isActive" is invalid/not existed/empty/wrongtype
	
	-- NOTE: Remove two below code lines when APPLINK-26394 is fixed
	commonSteps:RegisterAppInterface("RegisterAgain_DueTo_Defect_APPLINK-26394")
	commonSteps:UnregisterApplication("UnregisterAgain_DueTo_Defect_APPLINK-26394")
	
	commonFunctions:newTestCasesGroup("Check normal cases of HMI notification")
	
	--1. SDL must deactivates Navigation app from (FULL, AUDIBLE) to (BACKGROUND, NOT_AUDIBLE) when EMBEDDED_NAVI is ON then restore HMI Status if EMBEDDED_NAVI is OFF
	----------------------------------------------------------------------------------------------------------------------
	commonFunctions:newTestCasesGroup("NAVIGATION App is FULL. HMI sends OnEventChanged(EMBEDDED_NAVI) is On then Off")

	local function App_IsFull_EMBEDDED_NAVI_IsOnThenOFF()

		Test["CaseAppIsFULL_EMBEDDED_NAVI_IsOnThenOFF_Precondition_ChangeAppParams"] = function(self)
			self:change_App_Params({"NAVIGATION"},false)
		end

		commonSteps:RegisterAppInterface("CaseAppIsFULL_EMBEDDED_NAVI_IsOnThenOFF_RegisterApp")
		commonSteps:ActivationApp(_,"CaseAppIsFULL_EMBEDDED_NAVI_IsOnThenOFF_ActivateApp")

		Test["CaseAppIsFULL_EMBEDDED_NAVI_IsOnThenOFF_Activate_EMBEDDED_NAVI"] = function(self)
			self:onEventChanged(true, {hmiLevel="BACKGROUND", audioStreamingState="NOT_AUDIBLE", systemContext = "MAIN"})
		end
		
		Test["CaseAppIsFULL_EMBEDDED_NAVI_IsOnThenOFF_DeActivate_EMBEDDED_NAVI"] = function(self)
			self:onEventChanged(false, {hmiLevel="FULL", audioStreamingState="AUDIBLE", systemContext = "MAIN"})
		end
	end
	App_IsFull_EMBEDDED_NAVI_IsOnThenOFF()
	
	--2. SDL doesn't deactivate app when receives BasicCommunication.OnEventChanged(EMBEDDED_NAVI) from HMI with invalid "isActive" when app is FULL
	---------------------------------------------------------------------------------------------------------------------------
	commonFunctions:newTestCasesGroup("NAVIGATION App is FULL. HMI sends OnEventChanged(EMBEDDED_NAVI) when isActive is Invalid")
	local invalidValues = 
		{	
			{value = nil,	name = "IsMissed"},
			{value = "", 	name = "IsEmtpy"},
			{value = "ANY", name = "NonExist"},
			{value = 123, 	name = "IsWrongDataType"}
		}
	for i = 1, #invalidValues  do

		Test["CaseAppIsFULL_EMBEDDED_NAVI_isActive" .. invalidValues[i].name] = function(self)
			commonTestCases:DelayedExp(1000)
			--hmi side: send OnEventChanged
			self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= invalidValues[i].value, eventName="EMBEDDED_NAVI"})

			--mobile side: not expected OnHMIStatus
			self.mobileSession:ExpectNotification("OnHMIStatus",{})
			:Times(0)
		end	
	end
	
	--3. SDL must deactivates Navigation app from (LIMITED, AUDIBLE) to (BACKGROUND, NOT_AUDIBLE) when EMBEDDED_NAVI is ON then restore HMI Status if EMBEDDED_NAVI is OFF
	---------------------------------------------------------------------------------------------------------------------
	commonFunctions:newTestCasesGroup("NAVIGATION App is LIMITED. HMI sends OnEventChanged(EMBEDDED_NAVI) is On then Off")
	local function App_IsLIMITED_EMBEDDED_NAVI_IsOnThenOFF()
		
		Test["CaseAppIsLIMITED_BringAppToLimited"]= function(self)
			self:bring_App_To_LIMITED()
		end

		Test["CaseAppIsLIMITED_EMBEDDED_NAVI_IsOn"]= function(self)
			self:onEventChanged(true, {hmiLevel="BACKGROUND", audioStreamingState="NOT_AUDIBLE", systemContext = "MAIN"})
		end
		
		Test["CaseAppIsLIMITED_EMBEDDED_NAVI_IsOFF"]= function(self)
			self:onEventChanged(false, {hmiLevel="LIMITED", audioStreamingState="AUDIBLE", systemContext = "MAIN"})
		end
	end
	App_IsLIMITED_EMBEDDED_NAVI_IsOnThenOFF()
	
	--4. SDL doesn't deactivate app when receives BasicCommunication.OnEventChanged(EMBEDDED_NAVI) from HMI with invalid "isActive" when app is LIMITED
	---------------------------------------------------------------------------------------------------------------------------
	-- commonFunctions:newTestCasesGroup("NAVIGATION App is LIMITED. HMI sends OnEventChanged(EMBEDDED_NAVI) when isActive is Invalid")
	
	local invalidValues = 
						{	
							{value = nil,	name = "IsMissed"},
							{value = "", 	name = "IsEmtpy"},
							{value = "ANY", name = "NonExist"},
							{value = 123, 	name = "IsWrongDataType"}
						}
	
	for i = 1, #invalidValues  do

		Test["CaseAppIsLIMITED_EMBEDDED_NAVI_isActive" .. invalidValues[i].name] = function(self)
			commonTestCases:DelayedExp(1000)
			--hmi side: send OnEventChanged
			self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= invalidValues[i].value, eventName="EMBEDDED_NAVI"})

			--mobile side: not expected OnHMIStatus
			self.mobileSession:ExpectNotification("OnHMIStatus",{})
			:Times(0)
		end	
	end
	
	--PostCondition: Activate app
	Test["CaseAppIsLIMITED_PostCondition_ActivateApp"] = function(self)
		local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

		EXPECT_HMIRESPONSE(rid)
		:Do(function(_,data)
			if data.result.code ~= 0 then
			quit()
			end
		end)

		self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	
	end
-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK IV--------------------------------------
----------------------------------Check special cases of HMI notification-----------------------
-----------------------------------------------------------------------------------------------
-- Verify OnEventChanged() with:
	-- 1.InvalidJsonSyntax
	-- 2.InvalidStructure
	-- 3.Fake Params
	-- 3.Fake Params from another API
	-- 5.Missed mandatory Parameters
	-- 6.Several Notifications with the same values
	-- 7.Several notifications with different values

--Write TEST BLOCK IV to ATF log
commonFunctions:newTestCasesGroup("****************************** TEST BLOCK IV: Check special cases of HMI notification ******************************")
        
	-- 1.InvalidJsonSyntax
	---------------------------------------------------------------------------------------------
	Test["CaseOnEventChanged_IsInvalidJSonSyntax"] = function(self)
		commonTestCases:DelayedExp(1000)

		--self.hmiConnection:Send('{"jsonrpc":"2.0","method":"BasicCommunication.OnEventChanged","params":{"isActive":true,"eventName":"EMBEDDED_NAVI"}}')
		self.hmiConnection:Send('{"jsonrpc";"2.0","method":"BasicCommunication.OnEventChanged","params":{"isActive":true,"eventName":"EMBEDDED_NAVI"}}')

		--mobile side: not expected OnHMIStatus
		self.mobileSession:ExpectNotification("OnHMIStatus",{})
		:Times(0)
	end
			
	-- 2.InvalidStructure
	-----------------------------------------------------------------------------------------------
	Test["CaseOnEventChanged_InvalidStructure"] = function(self)
		commonTestCases:DelayedExp(1000)

		--method is moved into params parameter
		--self.hmiConnection:Send('{"jsonrpc":"2.0","method":"BasicCommunication.OnEventChanged","params":{"isActive":true,"eventName":"EMBEDDED_NAVI"}}')
		self.hmiConnection:Send('{"jsonrpc":"2.0","params":{"method":"BasicCommunication.OnEventChanged","isActive":true,"eventName":"EMBEDDED_NAVI"}}')

		--mobile side: not expected OnHMIStatus
		self.mobileSession:ExpectNotification("OnHMIStatus",{})
		:Times(0)
	end

	-- 3.Fake Params
	-----------------------------------------------------------------------------------------------
	Test["CaseOnEventChanged_WithFakeParam"] = function(self)
		--HMI side: sending BasicCommunication.OnEventChanged with fake param
        self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true,eventName="EMBEDDED_NAVI",fakeparam="123"})
		--mobile side: expected OnHMIStatus
		self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel="BACKGROUND", audioStreamingState="NOT_AUDIBLE", systemContext = "MAIN"})
	end

	--Postcondition for fake param: Send BC.OnEventChanged(EMBEDDED_NAVI,OFF)
	Test["CaseOnEventChanged_WithFakeParam_Postcondition"] = function(self)
		self:onEventChanged(true, {hmiLevel="FULL", audioStreamingState="AUDIBLE", systemContext = "MAIN"})
	end
	
	-- 4.Fake Params from another API
	-----------------------------------------------------------------------------------------------
	Test["CaseOnEventChanged_WithFakeParamFromAnotherAPI"] = function(self)
		--HMI side: sending BasicCommunication.OnEventChanged with fake param
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true,eventName="EMBEDDED_NAVI",sliderHeader="123"})
		--mobile side: expected OnHMIStatus
		self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel="BACKGROUND", audioStreamingState="NOT_AUDIBLE", systemContext = "MAIN"})
	end

	-- Postcondition for fake param: Send BC.OnEventChanged(EMBEDDED_NAVI,OFF)
	Test["CaseOnEventChanged_WithFakeParamFromAnotherAPI_Postcondition"] = function(self)
		self:onEventChanged(true, {hmiLevel="FULL", audioStreamingState="AUDIBLE", systemContext = "MAIN"})
	end
			
	-- 5.Missed mandatory Parameters
	-----------------------------------------------------------------------------------------------
	Test["CaseOnEventChanged_WithoutParams"] = function(self)
		commonTestCases:DelayedExp(1000)
		--HMI side: sending BasicCommunication.OnEventChanged without any params
		self.hmiConnection:Send('{"jsonrpc":"2.0","method":"BasicCommunication.OnEventChanged","params":{}}')

		--mobile side: not expected OnHMIStatus
		self.mobileSession:ExpectNotification("OnHMIStatus",{})
		:Times(0)
	end
	
	-- 6.Several Notifications with the same values
	-----------------------------------------------------------------------------------------------
	-- Send several BasicCommunication.OnEventChanged(EMBEDDED_NAVI,true)
	Test["Case_Send_OnEventChanged_EMBEDDED_NAVIOn_SeveralTimes"] = function(self)
		--HMI side: sending several BasicCommunication.OnEventChanged (ON)
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMBEDDED_NAVI"})
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMBEDDED_NAVI"})
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMBEDDED_NAVI"})

		--mobile side: expected OnHMIStatus
		self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel="BACKGROUND", audioStreamingState="NOT_AUDIBLE", systemContext = "MAIN"})
		commonTestCases:DelayedExp(2000)
	end

	-- Send several BasicCommunication.OnEventChanged(EMBEDDED_NAVI,false)
	Test["Case_Send_OnEventChanged_EMBEDDED_NAVIOff_SeveralTimes"] = function(self)
		--HMI side: sending several BasicCommunication.OnEventChanged
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMBEDDED_NAVI"})
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMBEDDED_NAVI"})
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMBEDDED_NAVI"})

		--mobile side: expect OnHMIStatus
		self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel="FULL", audioStreamingState="AUDIBLE", systemContext = "MAIN"})
		commonTestCases:DelayedExp(2000)
	end
	
	-- 7.Several notifications with different values
	-----------------------------------------------------------------------------------------------
	-- Send several BasicCommunication.OnEventChanged(EMBEDDED_NAVI) with different "isActive" param
	Test["Case_SendOnEventChanged_EMBEDDED_NAVIOnOffOn"] = function(self)
		--HMI side: sending several BasicCommunication.OnEventChanged
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMBEDDED_NAVI"})
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMBEDDED_NAVI"})
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMBEDDED_NAVI"})

		--mobile side:  expected OnHMIStatus
		self.mobileSession:ExpectNotification("OnHMIStatus",
												{hmiLevel="BACKGROUND", audioStreamingState="NOT_AUDIBLE", systemContext = "MAIN"},
												{hmiLevel="FULL", audioStreamingState="AUDIBLE", systemContext = "MAIN"},
												{hmiLevel="BACKGROUND", audioStreamingState="NOT_AUDIBLE", systemContext = "MAIN"}
											):Times(3)
	end
	
	commonSteps:UnregisterApplication("CheckSpecialCases_HMI_Notification_Postcondition_UnregisterApp")
	
	-- Postcondition: Send BC.OnEventChanged(EMBEDDED_NAVI,false)
	Test["CheckSpecialCases_HMI_Notification_Postcondition_EMBEDDED_NAVI_OF"] = function(self)
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMBEDDED_NAVI"})
	end

	
-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK V----------------------------------------
-------------------------------------Checks All Result Codes-----------------------------------
-----------------------------------------------------------------------------------------------

--Not Applicable

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VI----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("****************************** TEST BLOCK VI: Sequence with emulating of user's action ******************************")
-- Requirement: APPLINK-20377
-- Verification:
	-- 1. Activate app when App is BACKGROUND during EMBEDDED_NAVI Is ON 
	-- 2. Activate app when App is NONE during EMBEDDED_NAVI Is ON 
	-- 3. Activate app when App is BACKGROUND during EMBEDDED_NAVI Is ON but HMI doesn't send OnEventChanged(EMBEDDED_NAVI,isActive:false)
	-- 4. Activate app when App is BACKGROUND during EMBEDDED_NAVI Is ON but HMI send OnEventChanged(EMBEDDED_NAVI, isActive:invalidValue)

 
	commonFunctions:newTestCasesGroup("Activate Navigation app during EMBEDDED_NAVI")
	-- 1. Activate app when App is BACKGROUND during EMBEDDED_NAVI Is ON 
	--------------------------------------------------------------------------------------------------------------------------
	local function AppIsFull_ActivateApp_During_EMBEDDED_NAVI()

		Test["CaseAppIsFULL_ActivateApp_During_EMBEDDED_NAVI_IsON_ActivateApp_Precondition_ChangeAppParams"] = function(self)
			self:change_App_Params({"NAVIGATION"},false)
		end

		commonSteps:RegisterAppInterface("CaseAppIsFULL_ActivateApp_During_EMBEDDED_NAVI_IsON_ActivateApp_Precondition_RegisterApp")
		commonSteps:ActivationApp(_,"CaseAppIsFULL_ActivateApp_During_EMBEDDED_NAVI_IsON_ActivateApp_Precondition_ActivateApp")
		
		Test["CaseAppIsFULL_ActivateApp_During_EMBEDDED_NAVI_IsON"] = function(self)
			self:onEventChanged(true, {hmiLevel="BACKGROUND", audioStreamingState="NOT_AUDIBLE", systemContext = "MAIN"})
		end

		Test["CaseAppIsFULL_ActivateApp_During_EMBEDDED_NAVI_IsON_ActivateApp"]= function(self)
			self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMBEDDED_NAVI"})
			local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
			
			EXPECT_HMIRESPONSE(rid)
			:Do(function(_,data)
				if data.result.code ~= 0 then
				quit()
				end
			end)
			
			self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState ="AUDIBLE", systemContext = "MAIN"})
		end
		
	end
	AppIsFull_ActivateApp_During_EMBEDDED_NAVI()
	
	-- 2. Activate app when App is NONE during EMBEDDED_NAVI Is ON 
	--------------------------------------------------------------------------------------------------------------------------
	
	local function AppIsNONE_ActivateApp_During_EMBEDDED_NAVI()
		
		commonSteps:UnregisterApplication("CaseAppIsNONE_ActivateApp_During_EMBEDDED_NAVI_Precondition_UnregisterApp")
		
		Test["CaseAppIsNONE_ActivateApp_During_EMBEDDED_NAVI_Precondition_ChangeAppParams"] = function(self)
			self:change_App_Params({"NAVIGATION"},false)
		end
		
		commonSteps:RegisterAppInterface("CaseAppIsNONE_ActivateApp_During_EMBEDDED_NAVI_Precondition_RegisterApp")
		
		Test["CaseAppIsNONE_ActivateApp_During_EMBEDDED_NAVI_Precondition_EMBEDDED_NAVI_IsON"] = function(self)
			self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMBEDDED_NAVI"})
		end				

		Test["CaseAppIsNONE_ActivateApp_During_EMBEDDED_NAVI_ActivateApp"]= function(self)
		
			self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMBEDDED_NAVI"})
			local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
						
			EXPECT_HMIRESPONSE(rid)
			:Do(function(_,data)
				if
					data.result.isSDLAllowed ~= true then
					local rid = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
					EXPECT_HMIRESPONSE(rid)
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
		
			self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState ="AUDIBLE", systemContext = "MAIN"})
		end
		
		commonSteps:UnregisterApplication("CaseAppIsNONE_ActivateApp_During_EMBEDDED_NAVI_Postcondition_UnregisterApp")
	end
	AppIsNONE_ActivateApp_During_EMBEDDED_NAVI()	
	
	-- 3. Activate app when App is BACKGROUND during EMBEDDED_NAVI Is ON but HMI doesn't send OnEventChanged(EMBEDDED_NAVI,isActive:false)
	--------------------------------------------------------------------------------------------------------------------------

	local function ActivateApp_During_EMBEDDED_NAVI_And_AbsentOnEventChange_FromHMI()

		Test["ActivateApp_During_EMBEDDED_NAVI_And_AbsentOnEventChange_FromHMI_Precondition_ChangeAppParams"] = function(self)
			self:change_App_Params({"NAVIGATION"},false)
		end
		
		commonSteps:RegisterAppInterface("ActivateApp_During_EMBEDDED_NAVI_And_AbsentOnEventChange_FromHMI_Precondition_RegisterApp")
		commonSteps:ActivationApp(_,"ActivateApp_During_EMBEDDED_NAVI_And_AbsentOnEventChange_FromHMI_Precondition_ActivateApp")
		
		Test["ActivateApp_During_EMBEDDED_NAVI_And_AbsentOnEventChange_FromHMI_Precondition_IsON"] = function(self)
			self:onEventChanged(true, {hmiLevel="BACKGROUND", audioStreamingState="NOT_AUDIBLE", systemContext = "MAIN"})
		end
		
		-- User activates app but HMI doesn't send OnEventChanged(EMBEDDED_NAVI, false)
		Test["ActivateApp_During_EMBEDDED_NAVI_And_AbsentOnEventChange_FromHMI_ActivateApp"]= function(self)
		
			local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
			
			EXPECT_HMIRESPONSE(rid)
			:Do(function(_,data)
				if data.result.code ~= 0 then
				quit()
				end
			end)
			
			self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState ="AUDIBLE", systemContext = "MAIN"}):Times(0)
			commonTestCases:DelayedExp(1000)
		end
		
		commonSteps:UnregisterApplication("ActivateApp_During_EMBEDDED_NAVI_And_AbsentOnEventChange_FromHMI_Postcondition_UnregisterApp")
		
		Test["ActivateApp_During_EMBEDDED_NAVI_And_AbsentOnEventChange_FromHMI_Postcondition_IsOFF"] = function(self)
			self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMBEDDED_NAVI"})
		end
		
	end

	ActivateApp_During_EMBEDDED_NAVI_And_AbsentOnEventChange_FromHMI()
	
	-- 4. Activate app when App is BACKGROUND during EMBEDDED_NAVI Is ON but HMI send OnEventChanged(EMBEDDED_NAVI, isActive:invalidValue)
	--------------------------------------------------------------------------------------------------------------------------
	-- commonFunctions:newTestCasesGroup("Activate Navigation app during EMBEDDED_NAVI and HMI sends OnEventChanged(EMBEDDED_NAVI) when isActive is Invalid")
	
	for i = 1, #invalidValues  do
	
		local function ActivateApp_During_EMBEDDED_NAVI_And_OnEventChange_isActiveIsInvalid()
			Test["ActivateApp_During_EMBEDDED_NAVI_And_OnEventChange_isActive_"..invalidValues[i].name.."_Precondition_ChangeAppParams"] = function(self)
				self:change_App_Params({"NAVIGATION"},false)
			end
			
			commonSteps:RegisterAppInterface("ActivateApp_During_EMBEDDED_NAVI_And_OnEventChange_isActive_"..invalidValues[i].name.."_Precondition_RegisterApp")
			commonSteps:ActivationApp(_,"ActivateApp_During_EMBEDDED_NAVI_And_OnEventChange_isActive_"..invalidValues[i].name.."_Precondition_ActivateApp")
			
			Test["ActivateApp_During_EMBEDDED_NAVI_And_OnEventChange_isActive_"..invalidValues[i].name.."_Precondition_IsON"] = function(self)
				self:onEventChanged(true, {hmiLevel="BACKGROUND", audioStreamingState="NOT_AUDIBLE", systemContext = "MAIN"})
			end

			Test["ActivateApp_During_EMBEDDED_NAVI_And_OnEventChange_isActive" .. invalidValues[i].name] = function(self)
				self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= invalidValues[i].value, eventName="EMBEDDED_NAVI"})
				local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
				
				EXPECT_HMIRESPONSE(rid)
				:Do(function(_,data)
					if data.result.code ~= 0 then
					quit()
					end
				end)

				self.mobileSession:ExpectNotification("OnHMIStatus",{}):Times(0)
				commonTestCases:DelayedExp(1000)

			end	
			
			commonSteps:UnregisterApplication("ActivateApp_During_EMBEDDED_NAVI_And_OnEventChange_isActive".. invalidValues[i].name.."_Postcondition_UnregisterApp")
			
			Test["ActivateApp_During_EMBEDDED_NAVI_And_OnEventChange_isActive_"..invalidValues[i].name.."_Postcondition_IsOFF"] = function(self)
				self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMBEDDED_NAVI"})
			end
		end
		ActivateApp_During_EMBEDDED_NAVI_And_OnEventChange_isActiveIsInvalid()
	end
---------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------
--Verification:
	-- 1.(FULL,NOT_AUDIBLE,VRSESSION)
	-- 2.(LIMITED,NOT_AUDBILE,VRSESSION)
	-- 3.(BACKGROUND,NOT_AUDIBLE,MAIN)

	--Write TEST BLOCK VII to ATF log
	commonFunctions:newTestCasesGroup("****************************** TEST BLOCK VII: Check with Different HMIStatus ******************************")
	
	-- Precondition
	Test["TestBlockVII_Precondition_ChangeAppParams"] = function(self)
		self:change_App_Params({"NAVIGATION"},false)
	end
	commonSteps:RegisterAppInterface("TestBlockVII_Precondition_Precondition_RegisterApp")
	commonSteps:ActivationApp(_,"TestBlockVII_Precondition_ActivateApp")
	
	--1. App is at(FULL,NOT_AUDIBLE,VRSESSION)
	-- TODO: Need to be updated when APPLINK-27235 is DONE
	--------------------------------------------------------------------------------------------
    local function CaseAppIsFULL_VRSESSION()
		Test["CaseAppIsFULL_VRSESSION_StartVRSESSION"] = function(self)
			self:start_VRSESSION("FULL")
		end

		--Send OnventChanged(EMBEDDED_NAVI,ON) to SDL: App is changed to (BACKGROUND,NOT_AUDIBLE,VRSESSION)
		Test["CaseAppIsFULL_VRSESSION_EMBEDDED_NAVI_IsON"] = function(self)
			self:onEventChanged(true,{hmiLevel="BACKGROUND", audioStreamingState="NOT_AUDIBLE", systemContext = "VRSESSION"})
		end

		--Send OnventChanged(EMBEDDED_NAVI,OFF) to SDL: App is changed to (FULL,NOT_AUDIBLE,VRSESSION)
		Test["CaseAppIsFULL_VRSESSION_EMBEDDED_NAVI_IsOFF"] = function(self)
			self:onEventChanged(false,{hmiLevel="FULL", audioStreamingState="NOT_AUDIBLE", systemContext = "VRSESSION"})
		end
		
		commonSteps:UnregisterApplication("NAVIGATION_CaseAppIsFULL_EMBEDDED_NAVI_IsOnthen_UnregisterApp")
		
		Test["CaseAppIsFULL_VRSESSION_StopVRSESSION_PostCondition"] = function(self)
			self.hmiConnection:SendNotification("VR.Stopped")
		end
		
	end
	-- CaseAppIsFULL_VRSESSION()
	
	-- 2. App is at(LIMITED,NOT_AUDIBLE,VRSESSION)
	-- TODO: Need to be updated when APPLINK-27235 is DONE
	----------------------------------------------------------------------------------------------------------
	local function CaseAppIsLIMITED_VRSESSION()
		Test["CaseAppIsLIMITED_VRSESSION_StartVRSESSION"] = function(self)
			self:start_VRSESSION("LIMITED")
		end
		
		--Send OnventChanged(EMBEDDED_NAVI,ON) to SDL: App is changed to (BACKGROUND,NOT_AUDIBLE,VRSESSION)
		Test["CaseAppIsLIMITED_VRSESSION_EMBEDDED_NAVI_IsON"] = function(self)
			self:onEventChanged(true,{hmiLevel="BACKGROUND", audioStreamingState="NOT_AUDIBLE", systemContext = "VRSESSION"})
		end

		--Send OnventChanged(EMBEDDED_NAVI,OFF) to SDL: App is changed to (LIMITED,NOT_AUDIBLE,VRSESSION)
		Test["CaseAppIsFULL_VRSESSION_EMBEDDED_NAVI_IsOFF"] = function(self)
			self:onEventChanged(false,{hmiLevel="LIMITED", audioStreamingState="NOT_AUDIBLE", systemContext = "VRSESSION"})
		end
		
		commonSteps:UnregisterApplication("CaseAppIsLIMITED_VRSESSION_UnregisterApp")
		
		Test["CaseAppIsLIMITED_VRSESSION_StopVRSESSION_PostCondition"] = function(self)
			self.hmiConnection:SendNotification("VR.Stopped")
		end
	end	
	-- CaseAppIsLIMITED_VRSESSION()

	--3. App is at(BACKGROUND,NOT_AUDIBLE,MAIN)
	----------------------------------------------------------------------------------------------------------
    commonFunctions:newTestCasesGroup("NAVI App is at (BACKGROUND,NOT_AUDIBLE,MAIN), HMI sends OnEventChanged(EMBEDDED_NAVI) with isActive:true/false")
	
	function Test:CaseNaviAppIsBackground_Precondition_AddSecondSession()
		self.mobileSession1 = mobile_session.MobileSession(
		self,
		self.mobileConnection)
		self.mobileSession1:StartService(7)
	end
	
	function Test:CaseNaviAppIsBackground_Precondition_ChangeAppParams()
		config.application2.registerAppInterfaceParams.isMediaApplication = false
		config.application2.registerAppInterfaceParams.appHMIType = {"NAVIGATION"}
	end

	function Test:CaseNaviAppIsBackground_Precondition_Register_SecondNaviApp()
		--mobile side: sending request
		local CorIdRegister = self.mobileSession1:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)

		--hmi side: expect BasicCommunication.OnAppRegistered request
		EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
			{
				application =
				{
					appName = config.application2.registerAppInterfaceParams.appName
				}
			})
			:Do(function(_,data)
				self.applications[config.application2.registerAppInterfaceParams.appName] = data.params.application.appID
			end)

		--mobile side: expect response
		self.mobileSession1:ExpectResponse(CorIdRegister,
			{
				syncMsgVersion = config.syncMsgVersion
			})
			:Timeout(2000)

		--mobile side: expect notification
		self.mobileSession1:ExpectNotification("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
		:Timeout(2000)
	end
	
	Test["CaseNaviAppIsBackground_PreconditionActivateSeconApp"]= function(self)
			local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application2.registerAppInterfaceParams.appName]})
			EXPECT_HMIRESPONSE(rid)
			:Do(function(_,data)
				if data.result.code ~= 0 then
				quit()
				end
			end)

			self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
			self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	end

	function Test:CaseNaviAppIsBackground_EMBEDDEDNAVI_IsON()
		--hmi side: send OnEventChanged(EMBEDDED_NAVI, isActive= true) notification to SDL
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="EMBEDDED_NAVI"})

		--Expect OnHMIStatus notification is not sent to BACKGROUND app
		self.mobileSession:ExpectNotification("OnHMIStatus",{})
		:Times(0)
		commonTestCases:DelayedExp(1000)
		
		--Expect OnHMIStatus notification is sent to FULL app
		self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	end

	function Test:CaseNaviAppIsBackground_EMBEDDEDNAVI_IsOFF()
	
		--hmi side: send OnEventChanged(EMBEDDED_NAVI, isActive= true) notification to SDL
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="EMBEDDED_NAVI"})

		--Expect OnHMIStatus notification is not sent to BACKGROUND app
		self.mobileSession:ExpectNotification("OnHMIStatus",{})
		:Times(0)
		commonTestCases:DelayedExp(1000)
		
		-- Expect OnHMIStatus notification is sent to FULL app
		self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	end

	----------------------------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------------
	-------------------------------------------Postcondition-------------------------------------
	---------------------------------------------------------------------------------------------

	--Print new line to separate Postconditions
	commonFunctions:newTestCasesGroup("Postconditions")


	--Restore sdl_preloaded_pt.json
	policyTable:Restore_preloaded_pt()
