require('user_modules/all_common_modules')
-------------------------------------- Variables ------------------------------
-- n/a

------------------------------------ Common functions -------------------------
local function UnregisterApplicationSessionOne(self)
	--mobile side: UnregisterAppInterface request 
	local CorIdUAI = self.mobileSession:SendRPC("UnregisterAppInterface",{}) 
	
	--hmi side: expect OnAppUnregistered notification 
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = false})
	
	--mobile side: UnregisterAppInterface response 
	EXPECT_RESPONSE(CorIdUAI, { success = true, resultCode = "SUCCESS"})
	:Timeout(2000) 
end

-- copy table
function copy_table(t)
	local t2 = {}
	for k,v in pairs(t) do
		t2[k] = v
	end
	return t2
end

-- copy register parameters from config.lua to local variable
local RAIParams = copy_table(config.application1.registerAppInterfaceParams)
AppMediaType = RAIParams.isMediaApplication
---------------------------------------------------------------------------------------------
-------------------------------------------Postconditions-------------------------------------
---------------------------------------------------------------------------------------------
common_steps:AddNewTestCasesGroup("Preconditions")

common_functions:DeleteLogsFileAndPolicyTable()

-- Start SDL, HMI and Connect mobile
common_steps:PreconditionSteps("PreconditionSteps", 5)
---------------------------------------------------------------------------------------------
-----------------------------------------Body----------------------------------------
--Check lower bound of all String parameters in DeviceInfo
---------------------------------------------------------------------------------------------
-- <struct name="DeviceInfo">
-- <description>Various information abount connecting device.</description>
-- <param name="hardware" type="String" minlength="0" maxlength="500" mandatory="false">
-- <description>Device model</description>
-- </param>
-- <param name="firmwareRev" type="String" minlength="0" maxlength="500" mandatory="false">
-- <description>Device firmware revision</description>
-- </param>
-- <param name="os" type="String" minlength="0" maxlength="500" mandatory="false">
-- <description>Device OS</description>
-- </param>
-- <param name="osVersion" type="String" minlength="0" maxlength="500" mandatory="false">
-- <description>Device OS version</description>
-- </param>
-- <param name="carrier" type="String" minlength="0" maxlength="500" mandatory="false">
-- <description>Device mobile carrier (if applicable)</description>	

-- Case1: Check lower bound for all string parameters in DeviceInfo
function Test:RegisterAppInterface_All_Params_In_DeviceInfo_Are_LowerBound()
	--mobile side: RegisterAppInterface request 
	local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
	{
		syncMsgVersion = 
		{ 
			majorVersion = 1,
			minorVersion = 2,
		}, 
		appName ="S",
		ttsName = 
		{ 
			{ 
				text ="S",
				type ="TEXT",
			}, 
		}, 
		ngnMediaScreenAppName ="S",
		vrSynonyms = 
		{ 
			"V",
		}, 
		isMediaApplication = AppMediaType,
		languageDesired ="EN-US",
		hmiDisplayLanguageDesired ="EN-US",
		appHMIType = 
		{ 
			"DEFAULT",
		}, 
		appID ="1",
		deviceInfo = 
		{
			hardware = "",
			firmwareRev = "",
			os = "",
			osVersion = "",
			carrier = "",
			maxNumberRFCOMMPorts = 0
		}
		
	})
	--hmi side: expected BasicCommunication.OnAppRegistered
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
	{
		application = 
		{
			appName = "S",
			policyAppID = "1",
			hmiDisplayLanguageDesired ="EN-US",
			isMediaApplication = AppMediaType,
			deviceInfo = {
				name = "127.0.0.1",
				id = config.deviceMAC,
				transportType = "WIFI",
				isSDLAllowed = false
			}
		}
	})
	--mobile side: RegisterAppInterface response 
	EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
	:Timeout(2000) 
	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
end

-- Postcondition: The application should be unregistered before next test.
function Test:Case1_Postcondition_UnregisterAppInterface() 
	 UnregisterApplicationSessionOne(self) 
end
-------------------------------------------------------------------------------

-- Case2: DeviceInfo.hardware: lower bound = 0
function Test:RegisterAppInterface_hardwareIsLowerBound() 
	--mobile side: RegisterAppInterface request 
	local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
	{
		syncMsgVersion = 
		{ 
			majorVersion = 2,
			minorVersion = 2,
		}, 
		appName ="SyncProxyTester",
		isMediaApplication = AppMediaType,
		languageDesired ="EN-US",
		hmiDisplayLanguageDesired ="EN-US",
		appID ="123456",
		deviceInfo = {hardware = ""}
	}) 
	--hmi side: expected BasicCommunication.OnAppRegistered
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
	{
		application = 
		{
			appName = "SyncProxyTester",
			policyAppID = "123456",
			hmiDisplayLanguageDesired ="EN-US",
			isMediaApplication = AppMediaType,
			
			deviceInfo = 
			{
				name = "127.0.0.1",
				id = config.deviceMAC,
				transportType = "WIFI",
				isSDLAllowed = false
			}
		}
	})
	--mobile side: RegisterAppInterface response 
	EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
	:Timeout(2000) 
	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
end

-- Postcondition: The application should be unregistered before next test.
function Test:Case2_Postcondition_UnregisterAppInterface() 
	UnregisterApplicationSessionOne(self) 
end
-----------------------------------------------------------------------------------

-- Case3: Check lower bound for firmwareRev
function Test:RegisterAppInterface_firmwareIsRevLowerBound() 
	--mobile side: RegisterAppInterface request 
	local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
	{
		syncMsgVersion = 
		{ 
			majorVersion = 2,
			minorVersion = 2,
		}, 
		appName ="SyncProxyTester",
		isMediaApplication = AppMediaType,
		languageDesired ="EN-US",
		hmiDisplayLanguageDesired ="EN-US",
		appID ="123456",
		deviceInfo = {firmwareRev = ""}
	}) 
	--hmi side: expected BasicCommunication.OnAppRegistered
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
	{
		application = 
		{
			appName = "SyncProxyTester",
			policyAppID = "123456",
			hmiDisplayLanguageDesired ="EN-US",
			isMediaApplication = AppMediaType,
			deviceInfo = {
				name = "127.0.0.1",
				id = config.deviceMAC,
				transportType = "WIFI",
				isSDLAllowed = false
			}
		}
	})
	--mobile side: RegisterAppInterface response 
	EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
	:Timeout(2000) 
	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
end

-- Postcondition: The application should be unregistered before next test.
function Test:Case3_Postcondition_UnregisterAppInterface() 
	UnregisterApplicationSessionOne(self) 
end
-------------------------------------------------------------------------------

-- Case4: Check lower bound for os param
function Test:RegisterAppInterface_osIsLowerBound() 
	--mobile side: RegisterAppInterface request 
	local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
	{
		syncMsgVersion = 
		{ 
			majorVersion = 2,
			minorVersion = 2,
		}, 
		appName ="SyncProxyTester",
		isMediaApplication = AppMediaType,
		languageDesired ="EN-US",
		hmiDisplayLanguageDesired ="EN-US",
		appID ="123456",
		deviceInfo = {os = ""}
		
	}) 
	--hmi side: expected BasicCommunication.OnAppRegistered
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
	{
		application = 
		{
			appName = "SyncProxyTester",
			policyAppID = "123456",
			hmiDisplayLanguageDesired ="EN-US",
			isMediaApplication = AppMediaType,
			deviceInfo = {
				name = "127.0.0.1",
				id = config.deviceMAC,
				transportType = "WIFI",
				isSDLAllowed = false
			}
		}
	})
	--mobile side: RegisterAppInterface response 
	EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
	:Timeout(2000) 
	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
end

-- Postcondition: The application should be unregistered before next test.
function Test:Case4_Postcondition_UnregisterAppInterface() 
	UnregisterApplicationSessionOne(self) 
end
-------------------------------------------------------------------------------

-- Case5: Check lower bound osVersion param
function Test:RegisterAppInterface_osVersionIsLowerBound() 
	--mobile side: RegisterAppInterface request 
	local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
	{
		syncMsgVersion = 
		{ 
			majorVersion = 2,
			minorVersion = 2,
		}, 
		appName ="SyncProxyTester",
		isMediaApplication = AppMediaType,
		languageDesired ="EN-US",
		hmiDisplayLanguageDesired ="EN-US",
		appID ="123456",
		deviceInfo = {osVersion = ""
			
		}
	}) 
	--hmi side: expected BasicCommunication.OnAppRegistered
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
	{
		application = 
		{
			appName = "SyncProxyTester",
			policyAppID = "123456",
			hmiDisplayLanguageDesired ="EN-US",
			isMediaApplication = AppMediaType,
			deviceInfo = {
				name = "127.0.0.1",
				id = config.deviceMAC,
				transportType = "WIFI",
				isSDLAllowed = false
			}
		}
	})
	--mobile side: RegisterAppInterface response 
	EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
	:Timeout(2000) 
	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
end

-- Postcondition: The application should be unregistered before next test.
function Test:Case5_Postcondition_UnregisterAppInterface() 
	UnregisterApplicationSessionOne(self) 
end
-------------------------------------------------------------------------------

-- Case6: Check lower bound for carrier param
function Test:RegisterAppInterface_carrierIsLowerBound() 
	--mobile side: RegisterAppInterface request 
	local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
	{
		
		syncMsgVersion = 
		{ 
			majorVersion = 2,
			minorVersion = 2,
		}, 
		appName ="SyncProxyTester",
		isMediaApplication = AppMediaType,
		languageDesired ="EN-US",
		hmiDisplayLanguageDesired ="EN-US",
		appID ="123456",
		deviceInfo = {carrier = ""}
		
	}) 
	--hmi side: expected BasicCommunication.OnAppRegistered
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
	{
		application = 
		{
			appName = "SyncProxyTester",
			policyAppID = "123456",
			hmiDisplayLanguageDesired ="EN-US",
			isMediaApplication = AppMediaType,
			deviceInfo = {
				name = "127.0.0.1",
				id = config.deviceMAC,
				transportType = "WIFI",
				isSDLAllowed = false
			}
		}
	})
	--mobile side: RegisterAppInterface response 
	EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
	:Timeout(2000) 
	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
end
