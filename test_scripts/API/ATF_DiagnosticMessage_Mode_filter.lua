 Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
--local config = require('config')
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"


---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
--Begin Precondition.1 
--Description: Activation of applivation

	function Test:ActivationApp()
		  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})

			EXPECT_HMIRESPONSE(RequestId)
			:Do(function(_,data)
		    	if
		        	data.result.isSDLAllowed ~= true then
		            	local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})

		    			  --EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
		    			  	  EXPECT_HMIRESPONSE(RequestId)
			              :Do(function(_,data)
			    			    --hmi side: send request SDL.OnAllowSDLFunctionality
			    			    self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

			    			    --hmi side: expect BasicCommunication.ActivateApp
			    			    EXPECT_HMICALL("BasicCommunication.ActivateApp")
		            				:Do(function(_,data)
				          				self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
				        			end)
				        			:Times(2)
			              end)
				end
		      end)

		  	EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})	

	end

--End Precondition.1

---------------------------------------------------------------------------------------------


--Tests for checking CRQ APPLINK-13293: SDL should filter first element of 'messageData' according with allowed 'supportedDiagModes' param of .ini file.
--In .ini file: SupportedDiagModes = 0x01, 0x02, 0x03, 0x05, 0x06, 0x07, 0x09, 0x0A, 0x18, 0x19, 0x22, 0x3E (in hex, which corresponds with dec: 1, 2, 3, 5, 6, 7, 9, 10, 24, 25, 34, 62)
				
			--Begin Test case DiagnosticMessage.1
				-- All requests should be allowed by SDL and successfuly transfered to HMI
				local messageData = {1, 2, 3, 5, 6, 7, 9, 10, 24, 25, 34, 62}
				for i=1,#messageData do
					randomElement = math.random(255)

				Test["DiagnosticMessage with specified messageData : "..messageData[i]] = function(self)

					--mobile side: sending DiagnosticMessage request
					local cid = self.mobileSession:SendRPC("DiagnosticMessage",
															{
																targetID = 1000,
																messageLength = 500,
																messageData = {messageData[i], randomElement}
															})
					--hmi side: expect VehicleInfo.DiagnosticMessage request
					EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", 
									{ 
										appID = self.applications["Test Application"],
										targetID = 1000,
										messageLength = 500,
										messageData = {messageData[i], randomElement}
									})
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.DiagnosticMessage response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {messageDataResult = {55}})
					end)
						
					--mobile side: expect DiagnosticMessage response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
					
					end

				end
			--End Test case DiagnosticMessage.1
						

		-----------------------------------------------------------------------------------------


			--Begin Test case DiagnosticMessage.2
				-- All requests with not specified first element in .ini file should be REJECTED by SDL
				local messageData = {1, 2, 3, 5, 6, 7, 9, 10, 24, 25, 34, 62}
				for i=1,#messageData do
					randomElement = math.random(255)

					for i=1,#messageData do
						if randomElement == messageData[i] then 
							randomElement = math.random(255)
						end
					end

				Test["DiagnosticMessage with not specified messageData : "..randomElement] = function(self)

					--mobile side: sending DiagnosticMessage request
					local cid = self.mobileSession:SendRPC("DiagnosticMessage",
															{
																targetID = 1000,
																messageLength = 500,
																messageData = {randomElement, messageData[i]}
															})
						
					--mobile side: expect DiagnosticMessage response
					EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED" })
					
					end

				end
			--End Test case DiagnosticMessage.2
						

		-----------------------------------------------------------------------------------------