--------------------------------------------------------------------------------
-- Preconditions
--------------------------------------------------------------------------------
local Preconditions = require('user_modules/shared_testcases/commonPreconditions')

--------------------------------------------------------------------------------
--Precondition: preparation connecttest_Navigation_isReady_unavailable.lua
Preconditions:Connecttest_Navigation_IsReady_available_false("connecttest_Navigation_isReady_unavailable.lua", true)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

Test = require('user_modules/connecttest_Navigation_isReady_unavailable')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
require('user_modules/AppTypes')

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

APIName = "SendLocation"
---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

	-- Postcondition: removing user_modules/connecttest_Navigation_isReady_unavailable.lua,
	function Test:Postcondition_remove_user_connecttest()
	 	os.execute( "rm -f ./user_modules/connecttest_Navigation_isReady_unavailable.lua" )
	end

	--Print new line to separate Preconditions
	commonFunctions:newTestCasesGroup("Preconditions")

	--1. Delete app_info.dat, logs and policy table
	commonSteps:DeleteLogsFileAndPolicyTable()

	--2. Activation App by sending SDL.ActivateApp
	commonSteps:ActivationApp()

	--3. Update policy to allow request
	policyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED", "NONE"})


---------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result codes check--------------------------------------
----------------------------------------------------------------------------------------------

--Begin Test suit ResultCodeCheck

--Print new line to separate test suite
commonFunctions:newTestCasesGroup("Test suit For ResultCodeChecks")

--Description:TC check UNSUPPORTED_RESOURCE resultCode

	--Requirement id in JAMA: APPLINK-9735

    --Verification criteria:  In case UI is not supported (UI.IsReady returned 'available:false') SDL must respond with UNSUPPORTED_RESOURCE 'success:false' to mobile app and not transfer the RPC to HMI.

		function Test:SendLocation_UNSUPPORTED_RESOURCE()

			--request from mobile side
			local CorIdSendLocation= self.mobileSession:SendRPC("SendLocation",
			{
				longitudeDegrees = 1.1,
			latitudeDegrees = 1.1
			})

			--response on mobile side
			EXPECT_RESPONSE(CorIdSendLocation, { success = false, resultCode = "UNSUPPORTED_RESOURCE"})
			:Timeout(2000)
		end
--End Test suit ResultCodeCheck


---------------------------------------------------------------------------------------------
-------------------------------------------Postcondition-------------------------------------
---------------------------------------------------------------------------------------------

	--Print new line to separate Postconditions
	commonFunctions:newTestCasesGroup("Postconditions")


	--Restore sdl_preloaded_pt.json
	policyTable:Restore_preloaded_pt()



 return Test
