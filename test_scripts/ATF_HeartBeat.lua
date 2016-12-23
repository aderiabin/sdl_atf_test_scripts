-- Script creation date: 10/May/2016
-- ATF version: 2.2
-------------------------------------------------------------------------------------
Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local config = require('config')

-------------------------------------------------------------------------------------
-----------------------------------Local functions-----------------------------------
-------------------------------------------------------------------------------------

local function DelayedExp(time)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  :Timeout(time + 1000)
  RUN_AFTER(function()
      RAISE_EVENT(event, event)
      end, time)
  end

local function userPrint( color, message, nsession )
  print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " " .. tostring(nsession) .. " \27[0m")
end

local function userPrint2 ( color, message )
  print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
end
-------------------------------------------------------------------------------------
-----------------------------------Test cases----------------------------------------
-------------------------------------------------------------------------------------

   --Begin Check 1
   --Related CRQs: APPLINK-23725 [F-S] SDL must start HeartBeat process only after first HeartBeat request from mobile app

	   --Begin Check 1.1
	   --Verification criteria: SDL must not start Heartbeat process right after first StartService_request from app
	   	--Note: in TC could be observed incorrect behavior due to ATF defect APPLINK-16054 "ATF continue send heartbeat to SDL in case ignoring HB Ack from SDL"
		
		  function Test:RegisterAppSession2()

			    userPrint2(35, "===============================Test1==============================")
			    self.mobileSession2 = mobile_session.MobileSession(
			    self,
			    self.mobileConnection,
			    config.application2.registerAppInterfaceParams)
			    self.mobileSession2.version = 3
			    self.mobileSession2.sendHeartbeatToSDL = false
			    self.mobileSession2.answerHeartbeatFromSDL = false
			    self.mobileSession2.ignoreHeartBeatAck = true
			    self.mobileSession2:Start()
			    self.mobileSession2:StartService(7)
			    DelayedExp(20000)  
			    self.mobileSession2.sendHeartbeatToSDL = false
			    DelayedExp(20000)
		  end

		  function Test:NoHBToSDLNoDisconnect()
			 DelayedExp(20000)
		
			 -- hmi side: expect OnAppUnregistered notification
			 EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = HMIAppID})
			 :Times(0)
		
			 userPrint (33,"Log: AppSession2 started, HB disabled", self.mobileSession)		
			 userPrint (33, "Log: App v.3 disconnection not expected since no HB ACK and timer should be started by SDL till the HB request from app first", "(in TC NoHBToSDLNoDisconnect)") 

		  end
 
	   --End Check1.1


--------------------------------------------------------------------------------------------------------------

	   --Begin Check 1.2
	   --Verification criteria: SDL must respond Heartbeat ACK over control service to app and start Heartbeat timeout after Heartbeat_request from app
			   	
			function Test:RegisterAppSession3()
			    userPrint2(35, "===============================Test2==============================")   
			    self.mobileSession3 = mobile_session.MobileSession(
			    self,
			    self.mobileConnection,
			    config.application2.registerAppInterfaceParams)
			    self.mobileSession3.version = 3
			    self.mobileSession3:StartHeartbeat()
			    self.mobileSession3.sendHeartbeatToSDL = true
			    self.mobileSession3.answerHeartbeatFromSDL = false
			    self.mobileSession3.ignoreHeartBeatAck = true
			    self.mobileSession3:StartService(7)
			 end
 			
			  function Test:DisconnectDueToHeartbeat()
			         DelayedExp(20000)

                                 userPrint(33, "AppSession3 started, HB enabled", self.mobileSession3) 
				 userPrint2(33, "In DisconnectDueToHeartbeat TC disconnection is expected because HB process started by SDL after app's HB request")
			      
			  end

             --End Check1.2
    --End Check1



