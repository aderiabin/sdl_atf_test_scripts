Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')


local commonSteps = require('user_modules/shared_testcases/commonSteps')
local SDLConfig = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')


local TooManyPenReqCount = 0

APIName = "GetWayPoints" -- set request name

function DelayedExp()
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, 5000)
end

--UPDATED 
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

local storagePath = config.pathToSDL .. SDLConfig:GetValue("AppStorageFolder") .. "/" .. tostring(config.application1.registerAppInterfaceParams.appID .. "_" .. tostring(config.deviceMAC) .. "/")

---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
	
	--Update policy to allow request
	policyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED"})


	--Begin Precondition.1
	--Description: Activation App by sending SDL.ActivateApp	
		commonSteps:ActivationApp()
	--End Precondition.1
	
	-----------------------------------------------------------------------------------------
	
	
---------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------
----------------------------------------VIII TEST BLOCK-----------------------------------------
---------------------------------------Result codes check--------------------------------------
----------------------------------------------------------------------------------------------

--Begin Test suit ResultCodeCheck
--Description:TC check TOO_MANY_PENDING_REQUESTS resultCode

	--Requirement id in JAMA: SDLAQ-CRS-406

    --Verification criteria: The system has more than M (M defined in smartDeviceLink.ini) requests  at a timethat haven't been responded yet.
	function Test:GetWayPoints_TooManyPendingRequests()
		for i = 1, 20 do
			 --mobile side: sending GetWayPoints request
						local cid = self.mobileSession:SendRPC("GetWayPoints", {wayPointType = "ALL"})
		end
		
		EXPECT_RESPONSE("GetWayPoints")
	      :ValidIf(function(exp,data)
	      	if 
	      		data.payload.resultCode == "TOO_MANY_PENDING_REQUESTS" then
	            TooManyPenReqCount = TooManyPenReqCount+1
	            print(" \27[32m GetWayPoints response came with resultCode TOO_MANY_PENDING_REQUESTS \27[0m")
	      		return true
	        elseif 
	           exp.occurences == 30 and TooManyPenReqCount == 0 then 
	          print(" \27[36m Response GetWayPoints with resultCode TOO_MANY_PENDING_REQUESTS did not came \27[0m")
	          return false
	        elseif 
	          data.payload.resultCode == "GENERIC_ERROR" then
	            print(" \27[32m GetWayPoints response came with resultCode GENERIC_ERROR \27[0m")
	            return true
	        else
	            print(" \27[36m GetWayPoints response came with resultCode "..tostring(data.payload.resultCode .. "\27[0m" ))
	            return false
	        end
	      end)
			:Times(20)
			:Timeout(150000)

		--expect absence of OnAppInterfaceUnregistered
		EXPECT_NOTIFICATION("OnAppInterfaceUnregistered")
		:Times(0)

		--expect absence of BasicCommunication.OnAppUnregistered
		EXPECT_HMICALL("BasicCommunication.OnAppUnregistered")
		:Times(0)

		DelayedExp()
	end	
--End Test suit ResultCodeCheck

policyTable:Restore_preloaded_pt()











