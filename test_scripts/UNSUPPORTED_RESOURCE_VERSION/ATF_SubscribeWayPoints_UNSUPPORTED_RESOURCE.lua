--------------------------------------------------------------------------------
-- Preconditions
--------------------------------------------------------------------------------
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--------------------------------------------------------------------------------
--Precondition: preparation connecttest_Navigation_isReady_unavailable.lua
commonPreconditions:Connecttest_Navigation_IsReady_available_false("connecttest_Navigation_isReady_unavailable.lua", true)

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2
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

APIName = "SubscribeWayPoints"

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------


	--1. Delete app_info.dat, logs and policy table
	commonSteps:DeleteLogsFileAndPolicyTable()

	--2 Removing user_modules/connecttest_Navigation_isReady_unavailable.lua, restore hmi_capabilities
	function Test:Precondition_remove_user_connecttest_restore_preloaded()
	 	os.execute( "rm -f ./user_modules/connecttest_Navigation_isReady_unavailable.lua" )
	 	commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
	end

	--3. Activation App by sending SDL.ActivateApp
	commonSteps:ActivationApp()

	--4. Update policy to allow request
	policyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED", "NONE"})


---------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result codes check--------------------------------------
----------------------------------------------------------------------------------------------

--Begin Test suit ResultCodeCheck

--Description:TC check UNSUPPORTED_RESOURCE resultCode

	--Requirement id in JAMA: APPLINK-25187

    --Verification criteria:  HMI respond Navi.IsReady (false) -> SDL must return 'UNSUPPORTED_RESOURCE, success:false' to all Navi-related RPC

		function Test:SubscribeWayPoints_UNSUPPORTED_RESOURCE_IsReadyFalse()

			--request from mobile side
			local CorIdSWP= self.mobileSession:SendRPC("SubscribeWayPoints", {})

			--response on mobile side
			EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "UNSUPPORTED_RESOURCE"})
			:Timeout(2000)
		end
--End Test suit ResultCodeCheck


---------------------------------------------------------------------------------------------
-------------------------------------------Postcondition-------------------------------------
---------------------------------------------------------------------------------------------


 return Test
