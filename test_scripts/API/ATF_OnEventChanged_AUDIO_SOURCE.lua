----------------------------------------------------------------------------------------------------------
-- NOTE: APPLINK-21529: The value of "MixingAudioSupported" is always "true" for Ford-Specific implementation
--ATF version 2.2
-- TODO: Need to be updated when APPLINK-27318 is DONE
----------------------------------------------------------------------------------------------------------
Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection = require('file_connection')
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
-- TODO: Need to be updated when APPLINK-27318 is DONE
function Test:onEventChanged(enable, OnHMIStatus)
	--hmi side: send OnEventChanged (ON/OFF) notification to SDL
	self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= enable, eventName="AUDIO_SOURCE"})
	
	if OnHMIStatus==nil
	then 
		self.mobileSession:ExpectNotification("OnHMIStatus",{}): Times(0)
		commonTestCases:DelayedExp(1000)
	else 
		self.mobileSession:ExpectNotification("OnHMIStatus",OnHMIStatus)
	end 
	
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
		{hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION"}): Times(2)
	end
	if hmiLevel=="LIMITED" then 
		self.hmiConnection:SendNotification("UI.OnSystemContext", {systemContext = "VRSESSION"})
		self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
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
-- 1. CRQ APPLINK-20794: APPLINK-20371 for Navi App 
-- NOTE:
-- 2. Coverage for Media app must be worked in scope of CRQ APPLINK-20783 (Task APPLINK-20788),
-- 3. Coverage for Communication app must be worked in scope of CRQ APPLINK-20807 (Task APPLINK-20812)
-- 3. Coverage for Non media app must be worked in scope of CRQ APPLINK-20344 (Task APPLINK-20349)
------------------------------------------------------------------------------------------------

-- Verify OnEventChanged(AUDIO_SOURCE):
-- 1."isActive" is true/false
-- 2.Without "isActive" value
-- 3.With "isActive" is invalid/not existed/empty/wrongtype

-- TODO: Remove two below code lines when APPLINK-26394 is fixed
commonSteps:RegisterAppInterface("RegisterAgain_DueTo_Defect_APPLINK-26394")
commonSteps:UnregisterApplication("UnregisterAgain_DueTo_Defect_APPLINK-26394")

commonFunctions:newTestCasesGroup("Check normal cases of HMI notification")

--1. SDL must deactivates Navigation app from (FULL, AUDIBLE) to (LIMITED, NOT_AUDIBLE) when AUDIO_SOURCE is ON then restore HMI Status if AUDIO_SOURCE is OFF
----------------------------------------------------------------------------------------------------------------------

commonFunctions:newTestCasesGroup("NAVIGATION App is FULL. HMI sends OnEventChanged(AUDIO_SOURCE) is On then Off")
local function App_IsFull_AUDIO_SOURCE_IsOnThenOFF()
	
	Test["CaseAppIsFULL_AUDIO_SOURCE_IsOnThenOFF_Precondition_ChangeAppParams"] = function(self)
		self:change_App_Params({"NAVIGATION"},false)
	end
	
	commonSteps:RegisterAppInterface("CaseAppIsFULL_AUDIO_SOURCE_IsOnThenOFF_Precondition_RegisterApp")
	commonSteps:ActivationApp(_,"CaseAppIsFULL_AUDIO_SOURCE_IsOnThenOFF_Precondition_ActivateApp")
	
	Test["CaseAppIsFULL_AUDIO_SOURCE_IsOnThenOFF_Activate_AUDIO_SOURCE"] = function(self)
		self:onEventChanged(true, {hmiLevel="LIMITED", audioStreamingState="AUDIBLE", systemContext = "MAIN"})
	end
	
	Test["CaseAppIsFULL_AUDIO_SOURCE_IsOnThenOFF_DeActivate_AUDIO_SOURCE"] = function(self)
		self:onEventChanged(false, {hmiLevel="FULL", audioStreamingState="AUDIBLE", systemContext = "MAIN"})
	end
end
App_IsFull_AUDIO_SOURCE_IsOnThenOFF()

--2. SDL doesn't deactivate app when receives BasicCommunication.OnEventChanged(AUDIO_SOURCE) from HMI with invalid "isActive"
---------------------------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("NAVIGATION App is FULL. HMI sends OnEventChanged(AUDIO_SOURCE) when isActive is Invalid")

local invalidValues = 
{	
	{value = nil,	name = "IsMissed"},
	{value = "", 	name = "IsEmtpy"},
	{value = "ANY", name = "NonExist"},
	{value = 123, 	name = "IsWrongDataType"}
}

for i = 1, #invalidValues do
	
	Test["CaseAppIsFULL_AUDIO_SOURCE_isActive" .. invalidValues[i].name] = function(self)
		commonTestCases:DelayedExp(1000)
		--hmi side: send OnEventChanged
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= invalidValues[i].value, eventName="AUDIO_SOURCE"})
		
		--mobile side: not expected OnHMIStatus
		self.mobileSession:ExpectNotification("OnHMIStatus",{})
		:Times(0)
	end	
end

--3. SDL doesn't change app's HMIStatus when app is (LIMITED,AUDIBLE) and AUDIO_SOURCE is ON then OFF
---------------------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("NAVIGATION App is LIMITED. HMI sends OnEventChanged(AUDIO_SOURCE) is On then Off")
local function App_IsLIMITED_AUDIO_SOURCE_IsOnThenOFF()
	
	Test["CaseAppIsLIMITED_BringAppToLimited"]= function(self)
		self:bring_App_To_LIMITED()
	end
	
	Test["CaseAppIsLIMITED_AUDIO_SOURCE_IsOn"]= function(self)
		self:onEventChanged(true, nil)
	end
	
	Test["CaseAppIsLIMITED_AUDIO_SOURCE_IsOFF"]= function(self)
		self:onEventChanged(false, nil)
	end
end
App_IsLIMITED_AUDIO_SOURCE_IsOnThenOFF()

--4. SDL doesn't change app's HMIStatus when app is (LIMITED,AUDIBLE) and received BasicCommunication.OnEventChanged(AUDIO_SOURCE) from HMI with invalid "isActive"
---------------------------------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("NAVIGATION App is LIMITED. HMI sends OnEventChanged(AUDIO_SOURCE) when isActive is Invalid")

local invalidValues = 
{	
	{value = nil,	name = "IsMissed"},
	{value = "", 	name = "IsEmtpy"},
	{value = "ANY", name = "NonExist"},
	{value = 123, 	name = "IsWrongDataType"}
}

for i = 1, #invalidValues do
	
	Test["CaseAppIsLIMITED_AUDIO_SOURCE_isActive" .. invalidValues[i].name] = function(self)
		commonTestCases:DelayedExp(1000)
		--hmi side: send OnEventChanged
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= invalidValues[i].value, eventName="AUDIO_SOURCE"})
		
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
-- -- 1.InvalidJsonSyntax
-- -- 2.InvalidStructure
-- -- 3.Fake Params
-- -- 3.Fake Params from another API
-- -- 5.Missed mandatory Parameters
-- -- 6.Several Notifications with the same values
-- -- 7.Several notifications with different values

--Write TEST BLOCK IV to ATF log
commonFunctions:newTestCasesGroup("****************************** TEST BLOCK IV: Check special cases of HMI notification ******************************")

-- 1.InvalidJsonSyntax
-----------------------------------------------------------------------------------------------
Test["CaseOnEventChanged_IsInvalidJSonSyntax"] = function(self)
	commonTestCases:DelayedExp(1000)
	--self.hmiConnection:Send('{"jsonrpc":"2.0","method":"BasicCommunication.OnEventChanged","params":{"isActive":true,"eventName":"AUDIO_SOURCE"}}')
	self.hmiConnection:Send('{"jsonrpc";"2.0","method":"BasicCommunication.OnEventChanged","params":{"isActive":true,"eventName":"AUDIO_SOURCE"}}')
	--mobile side: not expected OnHMIStatus
	self.mobileSession:ExpectNotification("OnHMIStatus",{})
	:Times(0)
end

-- 2.InvalidStructure
-----------------------------------------------------------------------------------------------
Test["CaseOnEventChanged_InvalidStructure"] = function(self)
	commonTestCases:DelayedExp(1000)
	--method is moved into params parameter
	--self.hmiConnection:Send('{"jsonrpc":"2.0","method":"BasicCommunication.OnEventChanged","params":{"isActive":true,"eventName":"AUDIO_SOURCE"}}')
	self.hmiConnection:Send('{"jsonrpc":"2.0","params":{"method":"BasicCommunication.OnEventChanged","isActive":true,"eventName":"AUDIO_SOURCE"}}')
	--mobile side: not expected OnHMIStatus
	self.mobileSession:ExpectNotification("OnHMIStatus",{})
	:Times(0)
end

-- 3.Fake Params
-----------------------------------------------------------------------------------------------
Test["CaseOnEventChanged_WithFakeParam"] = function(self)
	--HMI side: sending BasicCommunication.OnEventChanged with fake param
	self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true,eventName="AUDIO_SOURCE",fakeparam="123"})
	--mobile side: expected OnHMIStatus
	self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel="LIMITED", audioStreamingState="AUDIBLE", systemContext = "MAIN"})
end

--Postcondition for fake param: Send BC.OnEventChanged(AUDIO_SOURCE,OFF)
Test["CaseOnEventChanged_WithFakeParam_Postcondition"] = function(self)
	self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="AUDIO_SOURCE"})
	--mobile side: expected OnHMIStatus
	self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel="FULL", audioStreamingState="AUDIBLE", systemContext = "MAIN"})
end

-- 4.Fake Params from another API
-----------------------------------------------------------------------------------------------
Test["CaseOnEventChanged_WithFakeParamFromAnotherAPI"] = function(self)
	--HMI side: sending BasicCommunication.OnEventChanged with fake param
	self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true,eventName="AUDIO_SOURCE",sliderHeader="123"})
	--mobile side: expected OnHMIStatus
	self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel="LIMITED", audioStreamingState="AUDIBLE", systemContext = "MAIN"})
end

--Postcondition for fake param: Send BC.OnEventChanged(AUDIO_SOURCE,OFF)
Test["CaseOnEventChanged_WithFakeParamFromAnotherAPI_Postcondition"] = function(self)
	self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="AUDIO_SOURCE"})
	--mobile side: expected OnHMIStatus
	self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel="FULL", audioStreamingState="AUDIBLE", systemContext = "MAIN"})
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
--Send several BasicCommunication.OnEventChanged(AUDIO_SOURCE,true)
Test["Case_Send_OnEventChanged_AUDIO_SOURCEOn_SeveralTimes"] = function(self)
	--HMI side: sending several BasicCommunication.OnEventChanged (ON)
	self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="AUDIO_SOURCE"})
	self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="AUDIO_SOURCE"})
	self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="AUDIO_SOURCE"})
	--mobile side: expected OnHMIStatus
	self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel="LIMITED", audioStreamingState="AUDIBLE", systemContext = "MAIN"})
	commonTestCases:DelayedExp(2000)
end

--Send several BasicCommunication.OnEventChanged(AUDIO_SOURCE,false)
Test["Case_Send_OnEventChanged_AUDIO_SOURCEOff_SeveralTimes"] = function(self)
	--HMI side: sending several BasicCommunication.OnEventChanged
	self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="AUDIO_SOURCE"})
	self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="AUDIO_SOURCE"})
	self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="AUDIO_SOURCE"})
	--mobile side: expect OnHMIStatus
	self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel="FULL", audioStreamingState="AUDIBLE", systemContext = "MAIN"})
	commonTestCases:DelayedExp(2000)
end

-- 7.Several notifications with different values
-----------------------------------------------------------------------------------------------
--Send several BasicCommunication.OnEventChanged(AUDIO_SOURCE) with different "isActive" param
Test["Case_SendOnEventChanged_AUDIO_SOURCEOnOffOn"] = function(self)
	--HMI side: sending several BasicCommunication.OnEventChanged
	self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="AUDIO_SOURCE"})
	self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="AUDIO_SOURCE"})
	self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="AUDIO_SOURCE"})
	--mobile side: expected OnHMIStatus
	self.mobileSession:ExpectNotification("OnHMIStatus",
	{hmiLevel="LIMITED", audioStreamingState="AUDIBLE", systemContext = "MAIN"},
	{hmiLevel="FULL", audioStreamingState="AUDIBLE", systemContext = "MAIN"},
	{hmiLevel="LIMITED", audioStreamingState="AUDIBLE", systemContext = "MAIN"}
	):Times(3)
end

--Postcondition: Send BC.OnEventChanged(AUDIO_SOURCE,false)
Test["Case_SendOnEventChanged_AUDIO_SOURCE_IsOnOffOn_Postcondition"] = function(self)
	self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="AUDIO_SOURCE"})
	--mobile side: expected OnHMIStatus
	self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel="FULL", audioStreamingState="AUDIBLE", systemContext = "MAIN"})
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
-- Requirement: APPLINK-20372
-- Verification:
-- 1. Activate app when App is LIMITED during EMBEDDED_NAVI Is ON 
-- 2. Activate app when App is NONE during EMBEDDED_NAVI Is ON 
-- 3. Activate app when App is BACKGROUND during EMBEDDED_NAVI Is ON 

commonFunctions:newTestCasesGroup("Activate Navigation app during AUDIO_SOURCE")

-- 1. Activate app when App is LIMITED during EMBEDDED_NAVI Is ON	
-----------------------------------------------------------------------------------------------
local function AppIsLIMITED_ActivateApp_During_AUDIO_SOURCE()
	
	Test["CaseAppIsLIMITED_ActivateApp_During_AUDIO_SOURCE_IsON"] = function(self)
		self:onEventChanged(true, {hmiLevel="LIMITED", audioStreamingState="AUDIBLE", systemContext = "MAIN"})
	end
	
	Test["CaseAppIsLIMITED_ActivateApp_During_AUDIO_SOURCE_IsON_ActivateApp"]= function(self)
		local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
		EXPECT_HMIRESPONSE(rid)
		:Do(function(_,data)
			if data.result.code ~= 0 then
				quit()
			end
		end)
		
		self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState ="AUDIBLE", systemContext = "MAIN"})
	end
	
	Test["CaseAppIsLIMITED_ActivateApp_During_AUDIO_SOURCE_IsON_Postcondition_AUDIO_SOURCE_IsOFF"]= function(self)
		self:onEventChanged(false, nil)
	end
	
end
AppIsLIMITED_ActivateApp_During_AUDIO_SOURCE()

-- 2. Activate app when App is NONE during EMBEDDED_NAVI Is ON 
-----------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("Navigation is registered during AUDIO_SOURCE then try to activate this app")

local function AppIsNONE_ActivateApp_During_AUDIO_SOURCE()
	
	commonSteps:UnregisterApplication("CaseAppIsNONE_ActivateApp_During_AUDIO_SOURCE_Precondition_UnregisterApp")
	
	Test["CaseAppIsNONE_ActivateApp_During_AUDIO_SOURCE_IsON_Precondition_ChangeAppParams"] = function(self)
		self:change_App_Params({"NAVIGATION"},false)
	end
	
	commonSteps:RegisterAppInterface("CaseAppIsNONE_ActivateApp_During_AUDIO_SOURCE_RegisterApp")	
	
	Test["CaseAppIsNONE_ActivateApp_During_AUDIO_SOURCE_IsON"] = function(self)
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="AUDIO_SOURCE"})
		self.mobileSession:ExpectNotification("OnHMIStatus",{}):Times(0)
		commonTestCases:DelayedExp(1000)
	end
	
	Test["CaseAppIsNONE_ActivateApp_During_AUDIO_SOURCE_ActivateApp"]= function(self)
		local deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
		local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
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
		
		--mobile side: expect notification
		self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	end
	
	Test["CaseAppIsNONE_ActivateApp_During_AUDIO_SOURCE_IsON_Postcondition_AUDIO_SOURCE_IsOFF"]= function(self)
		self:onEventChanged(false, nil)
	end
end

AppIsNONE_ActivateApp_During_AUDIO_SOURCE()

-- 3. Activate app when App is BACKGROUND during EMBEDDED_NAVI Is ON 
----------------------------------------------------------------------------------------------------
commonFunctions:newTestCasesGroup("Navigation is BACKGROUND and try to activate this app during AUDIO_SOURCE")

local function AppIsBACKGROUND_ActivateApp_During_AUDIO_SOURCE()
	
	function Test:AppIsBACKGROUND_Precondition_AddSecondSession()
		self.mobileSession1 = mobile_session.MobileSession(
		self,
		self.mobileConnection)
		self.mobileSession1:StartService(7)
	end
	
	function Test:AppIsBACKGROUND_Precondition_Precondition_ChangeApp2Params()
		config.application2.registerAppInterfaceParams.isMediaApplication = false
		config.application2.registerAppInterfaceParams.appHMIType = {"NAVIGATION"}
	end
	
	function Test:AppIsBACKGROUND_Precondition_Precondition_Register_SecondNaviApp()
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
	
	function Test:AppIsBACKGROUND_Precondition_Precondition_Activate_SecondNaviApp()
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
	
	Test["AppIsBACKGROUND_Precondition_ActivateApp_During_AUDIO_SOURCE_IsON"] = function(self)
		self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= true, eventName="AUDIO_SOURCE"})
		self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		self.mobileSession:ExpectNotification("OnHMIStatus",{}): Times(0)
		commonTestCases:DelayedExp(2000)
	end
	
	Test["AppIsBACKGROUND_ActivateApp_During_AUDIO_SOURCE_ActivateApp"]= function(self)
		local rid = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
		EXPECT_HMIRESPONSE(rid)
		:Do(function(_,data)
			if data.result.code ~= 0 then
				quit()
			end
		end)
		self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
		self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
	end
	
	Test["AppIsBACKGROUND_ActivateApp_During_AUDIO_SOURCE_Postcondition_UnregisterApp2"]= function(self)
		local cid = self.mobileSession1:SendRPC("UnregisterAppInterface",{})
		self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
		:Timeout(2000)
	end
	
	Test["AppIsBACKGROUND_ActivateApp_During_AUDIO_SOURCE_Postcondition_"]= function(self)
		self:onEventChanged(false, nil)
	end
end

AppIsBACKGROUND_ActivateApp_During_AUDIO_SOURCE()
---------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------
--Verification:
-- 1.(FULL,NOT_AUDIBLE,VRSESSION)

--Write TEST BLOCK VII to ATF log
commonFunctions:newTestCasesGroup("****************************** TEST BLOCK VII: Check with Different HMIStatus ******************************")

--1. App is at(FULL,NOT_AUDIBLE,VRSESSION)
-- TODO: Need to updated when APPLINK-27235 is DONE
--------------------------------------------------------------------------------------------
local function CaseAppIsFULL_VRSESSION()
	Test["CaseAppIsFULL_VRSESSION_StartVRSESSION"] = function(self)
		self:start_VRSESSION("FULL")
	end
	
	--Send OnEventChanged(AUDIO_SOURCE,ON) to SDL: App is changed to (LIMITED,NOT_AUDIBLE,VRSESSION)
	Test["CaseAppIsFULL_VRSESSION_AUDIO_SOURCE_IsON"] = function(self)
		self:onEventChanged(true,{hmiLevel="LIMITED", audioStreamingState="NOT_AUDIBLE", systemContext = "VRSESSION"})
	end
	
	--Send OnEventChanged(AUDIO_SOURCE,OFF) to SDL: App is changed to (FULL,NOT_AUDIBLE,VRSESSION)
	Test["CaseAppIsFULL_VRSESSION_AUDIO_SOURCE_IsOFF"] = function(self)
		self:onEventChanged(false,{hmiLevel="FULL", audioStreamingState="NOT_AUDIBLE", systemContext = "VRSESSION"})
	end
	
	commonSteps:UnregisterApplication("NAVIGATION_CaseAppIsFULL_AUDIO_SOURCE_IsOnthen_UnregisterApp")
	
	Test["CaseAppIsFULL_VRSESSION_StopVRSESSION_PostCondition"] = function(self)
		self.hmiConnection:SendNotification("VR.Stopped")
	end
	
end
--CaseAppIsFULL_VRSESSION()

---------------------------------------------------------------------------------------------
-------------------------------------------Postcondition-------------------------------------
---------------------------------------------------------------------------------------------

--Print new line to separate Postconditions
commonFunctions:newTestCasesGroup("Postconditions")


--Restore sdl_preloaded_pt.json
policyTable:Restore_preloaded_pt()