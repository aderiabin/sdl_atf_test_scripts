
----------------------------------------------------------------------------------------------
-- ATF verstion: 2.2
local commonSteps   = require('/user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('/user_modules/shared_testcases/commonPreconditions')
local commonFunctions = require ('/user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require('/user_modules/shared_testcases/testCasesForPolicyTable')
local enumerationParameterInResponse = require('user_modules/shared_testcases/testCasesForEnumerationParameterInResponse')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
require('user_modules/AppTypes')

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

APIName = "UnsubscribeVehicleData" -- set request name

local AllVehicleDataResultCode = {"SUCCESS", "TRUNCATED_DATA", "DISALLOWED", "USER_DISALLOWED", "INVALID_ID", "VEHICLE_DATA_NOT_AVAILABLE", "DATA_ALREADY_SUBSCRIBED",  "DATA_NOT_SUBSCRIBED", "IGNORED"}

local USVDValues = {gps="VEHICLEDATA_GPS", 
					speed="VEHICLEDATA_SPEED",
					rpm="VEHICLEDATA_RPM",
					fuelLevel="VEHICLEDATA_FUELLEVEL",
					fuelLevel_State="VEHICLEDATA_FUELLEVEL_STATE",
					instantFuelConsumption="VEHICLEDATA_FUELCONSUMPTION",
					externalTemperature="VEHICLEDATA_EXTERNTEMP",
					prndl="VEHICLEDATA_PRNDL",
					tirePressure="VEHICLEDATA_TIREPRESSURE",
					odometer="VEHICLEDATA_ODOMETER",
					beltStatus="VEHICLEDATA_BELTSTATUS",
					bodyInformation="VEHICLEDATA_BODYINFO",
					deviceStatus="VEHICLEDATA_DEVICESTATUS",
					driverBraking="VEHICLEDATA_BRAKING",
					wiperStatus="VEHICLEDATA_WIPERSTATUS",
					headLampStatus="VEHICLEDATA_HEADLAMPSTATUS",
					engineTorque="VEHICLEDATA_ENGINETORQUE",
					accPedalPosition="VEHICLEDATA_ACCPEDAL",
					steeringWheelAngle="VEHICLEDATA_STEERINGWHEEL",
					eCallInfo="VEHICLEDATA_ECALLINFO",
					airbagStatus="VEHICLEDATA_AIRBAGSTATUS",
					emergencyEvent="VEHICLEDATA_EMERGENCYEVENT",
					clusterModeStatus="VEHICLEDATA_CLUSTERMODESTATUS",
					myKey="VEHICLEDATA_MYKEY",
					fuelRange="VEHICLEDATA_FUELRANGE",
					abs_State="VEHICLEDATA_ABS_STATE",
					tirePressureValue="VEHICLEDATA_TIREPRESSURE_VALUE",
					tpms="VEHICLEDATA_TPMS",
					turnSignal="VEHICLEDATA_TURNSIGNAL"}

local allVehicleData = {"fuelRange", "abs_State", "tirePressureValue", "tpms", "turnSignal", "gps", "speed", "rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption", "externalTemperature", "prndl", "tirePressure", "odometer", "beltStatus", "bodyInformation", "deviceStatus", "driverBraking", "wiperStatus", "headLampStatus", "engineTorque", "accPedalPosition", "steeringWheelAngle", "eCallInfo", "airbagStatus", "emergencyEvent", "clusterModeStatus", "myKey"}

local vehicleData = {"gps"}
local infoMessageValue = string.rep("a",1000)

function DelayedExp(time)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  	:Timeout(time+1000)
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, time)
end


function setUSVDRequest(paramsSend)
	local temp = {}	
	for i = 1, #paramsSend do		
		temp[paramsSend[i]] = true
	end	
	return temp
end
function setUSVDResponse(paramsSend, vehicleDataResultCode)
	local temp = {}
	local vehicleDataResultCodeValue = ""
	
	if vehicleDataResultCode ~= nil then
		vehicleDataResultCodeValue = vehicleDataResultCode
	else
		vehicleDataResultCodeValue = "SUCCESS"
	end
	
	for i = 1, #paramsSend do
		if  paramsSend[i] == "clusterModeStatus" then
			temp["clusterModes"] = {					
						resultCode = vehicleDataResultCodeValue, 
						dataType = USVDValues[paramsSend[i]]
				}
		else
			temp[paramsSend[i]] = {					
						resultCode = vehicleDataResultCodeValue, 
						dataType = USVDValues[paramsSend[i]]
				}
		end
	end	
	return temp
end
function createSuccessExpectedResult(response, infoMessage)
	response["success"] = true
	response["resultCode"] = "SUCCESS"
	
	if info ~= nil then
		response["info"] = infoMessage
	end
	
	return response
end
function createExpectedResult(bSuccess, sResultCode, infoMessage, response)
	response["success"] = bSuccess
	response["resultCode"] = sResultCode
	
	if infoMessage ~= nil then
		response["info"] = infoMessage
	end
	
	return response
end
function Test:unsubscribeVehicleDataSuccess(paramsSend, infoMessage)
	local request = setUSVDRequest(paramsSend)
	local response = setUSVDResponse(paramsSend)
	
	if infoMessage ~= nil then
		response["info"] = infoMessage
	end
	
	--mobile side: sending UnsubscribeVehicleData request
	local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",request)
	
	--hmi side: expect UnsubscribeVehicleData request
	EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",request)
	:Do(function(_,data)
		--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)	
	end)
	
	
	local expectedResult = createSuccessExpectedResult(response, infoMessage)
	
	--mobile side: expect UnsubscribeVehicleData response
	EXPECT_RESPONSE(cid, expectedResult)
	
	--mobile side: expect OnHashChange notification
	EXPECT_NOTIFICATION("OnHashChange")
	
	DelayedExp(2000)
end
function Test:unsubscribeVehicleDataInvalidData(paramsSend)
	--mobile side: sending UnsubscribeVehicleData request
	local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",paramsSend)
	
	--mobile side: expected UnsubscribeVehicleData response
	EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
	
	--mobile side: expect OnHashChange notification
	EXPECT_NOTIFICATION("OnHashChange")
	:Times(0)
end
function Test:subscribeVehicleDataSuccess(paramsSend)
	local request = setUSVDRequest(paramsSend)
	local response = setUSVDResponse(paramsSend)
		
	--mobile side: sending SubscribeVehicleData request
	local cid = self.mobileSession:SendRPC("SubscribeVehicleData",request)
	
	--hmi side: expect SubscribeVehicleData request
	EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",request)
	:Do(function(_,data)
		--hmi side: sending VehicleInfo.SubscribeVehicleData response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)	
	end)
	
	local expectedResult = createSuccessExpectedResult(response)
	
	--mobile side: expect SubscribeVehicleData response
	--EXPECT_RESPONSE(cid, expectedResult)
	self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
	
	--mobile side: expect OnHashChange notification
	EXPECT_NOTIFICATION("OnHashChange")
end
function Test:unsubscribeVehicleDataIgnored(paramsSend, bSuccess)	
	-- UnsubscribeVehicleData previously subscribed
	local request = setUSVDRequest(paramsSend)
	local response = setUSVDResponse(paramsSend, "DATA_NOT_SUBSCRIBED")						
	local messageValue = "Already subscribed on some provided VehicleData."
	
	--mobile side: sending UnsubscribeVehicleData request
	local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",request)
	
	local expectedResult = createExpectedResult(bSuccess, "IGNORED", messageValue, response)
	
	--mobile side: expect UnsubscribeVehicleData response
	EXPECT_RESPONSE(cid, expectedResult)
	
	--mobile side: expect OnHashChange notification
	EXPECT_NOTIFICATION("OnHashChange")
	:Times(0)

	DelayedExp(2000)
end

--This function sends a request from mobile and verify result on HMI and mobile for SUCCESS resultCode cases.
function Test:verify_SUCCESS_Case(Request)

	--mobile side: sending the request
	local cid = self.mobileSession:SendRPC(APIName, Request)

	--hmi side: expect VehicleInfo.UnsubscribeVehicleData request
	local Response = setUSVDResponse(vehicleData)
	EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData", Request)
	:Do(function(_,data)
		--hmi side: sending response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)
	end)

	--mobile side: expect the response
	local ExpectedResponse = commonFunctions:cloneTable(Response)
	ExpectedResponse["success"] = true
	ExpectedResponse["resultCode"] = "SUCCESS"
	EXPECT_RESPONSE(cid, ExpectedResponse)

end
--This function is used to send default request and response with specific valid data and verify SUCCESS resultCode
function Test:verify_SUCCESS_Response_Case(Response)

	--mobile side: sending the request
	local Request = setUSVDRequest(vehicleData)
	local cid = self.mobileSession:SendRPC(APIName, Request)

	--hmi side: expect VehicleInfo.UnsubscribeVehicleData request
	EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData", Request)
	:Do(function(_,data)
		--hmi side: sending response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)
	end)

	--mobile side: expect the response
	local ExpectedResponse = commonFunctions:cloneTable(Response)
	ExpectedResponse["success"] = true
	ExpectedResponse["resultCode"] = "SUCCESS"
	EXPECT_RESPONSE(cid, ExpectedResponse)

end
--This function is used to send default request and response with specific invalid data and verify GENERIC_ERROR resultCode
function Test:verify_GENERIC_ERROR_Response_Case(Response)

	--mobile side: sending the request
	local Request = setUSVDRequest(vehicleData)
	local cid = self.mobileSession:SendRPC(APIName, Request)

	--hmi side: expect VehicleInfo.UnsubscribeVehicleData request
	EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData", Request)
	:Do(function(_,data)
		--hmi side: sending response
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)
	end)

	--mobile side: expect the response
	EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle" })

end

local function Verify_UnsubscribeVehicleData_Enum_String_Parameter_In_Response(ParameterName, DataType)

				--Print new line to separate new test cases group
				commonFunctions:newTestCasesGroup("PositiveResponseCheck: "..ParameterName)	
				
				local Response = setUSVDResponse(vehicleData)						
				Response[ParameterName] = {
					dataType = DataType,
					resultCode = "SUCCESS"
				}

				---------------------------------
				----Verify Parameter
				local Parameter = {ParameterName}
				--1.1. IsMissed
				Test["PreCondition_SubscribeVehicleData_"..ParameterName.."_IsMissed"] = function(self)				
					self:subscribeVehicleDataSuccess(vehicleData)						
				end	
				commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsMissed", nil, "SUCCESS")		
				
				--1.2. IsWrongDataType
				Test["PreCondition_SubscribeVehicleData_"..ParameterName.."_IsWrongDataType"] = function(self)				
					self:subscribeVehicleDataSuccess(vehicleData)						
				end					
				commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsWrongDataType", 123, "GENERIC_ERROR")

				
				--1.3. IsEmpty
				Test["PreCondition_SubscribeVehicleData_"..ParameterName.."_IsEmpty"] = function(self)				
					self:subscribeVehicleDataSuccess(vehicleData)						
				end				
				commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsEmpty", "", "GENERIC_ERROR")

				
				---------------------------------				
				----Verify Parameter.dataType
				local Parameter = {ParameterName, "dataType"}
				--2.1. IsMissed
				Test["PreCondition_SubscribeVehicleData_"..ParameterName.."_DataType_IsMissed"] = function(self)				
					self:subscribeVehicleDataSuccess(vehicleData)						
				end				
				commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsMissed", nil, "GENERIC_ERROR")		
				
				--2.2. IsWrongDataType
				Test["PreCondition_SubscribeVehicleData_"..ParameterName.."_DataType_IsWrongDataType"] = function(self)				
					self:subscribeVehicleDataSuccess(vehicleData)						
				end				
				commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsWrongDataType", 123, "GENERIC_ERROR")
				
				--2.3. IsEmpty
				Test["PreCondition_SubscribeVehicleData_"..ParameterName.."_DataType_IsEmpty"] = function(self)				
					self:subscribeVehicleDataSuccess(vehicleData)						
				end				
				commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsEmpty", "", "GENERIC_ERROR")

				--2.4. IsExistentValue
				Test["PreCondition_SubscribeVehicleData_"..ParameterName.."_DataType_IsExistentValue"] = function(self)				
					self:subscribeVehicleDataSuccess(vehicleData)						
				end				
				commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsExistentValue_"..DataType, DataType, "SUCCESS")
				
				--2.5. IsNonexistentValue
				Test["PreCondition_SubscribeVehicleData_"..ParameterName.."_DataType_IsNonExistentValue"] = function(self)				
					self:subscribeVehicleDataSuccess(vehicleData)						
				end	
				commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsNonexistentValue", "ANY", "GENERIC_ERROR")				
				
				--2.6. DataTypeOfAnother
				Test["PreCondition_SubscribeVehicleData_"..ParameterName.."_DataType_ValueOfAnother"] = function(self)				
					self:subscribeVehicleDataSuccess(vehicleData)						
				end			
				commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsExistentValue_DataTypeOfAnother", "VEHICLEDATA_GPS", "SUCCESS")

				---------------------------------
				----Verify Parameter.resultCode
				local Parameter = {ParameterName, "resultCode"}
				--3.1. IsMissed
				Test["PreCondition_SubscribeVehicleData_"..ParameterName.."_ResultCode_IsMissed"] = function(self)				
					self:subscribeVehicleDataSuccess(vehicleData)						
				end				
				commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsMissed", nil, "GENERIC_ERROR")
				
				--3.2. IsWrongDataType
				Test["PreCondition_SubscribeVehicleData_"..ParameterName.."_ResultCode_IsWrongDataType"] = function(self)				
					self:subscribeVehicleDataSuccess(vehicleData)						
				end				
				commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsWrongDataType", 123, "GENERIC_ERROR")
				
				--3.3. IsEmpty
				Test["PreCondition_SubscribeVehicleData_"..ParameterName.."_ResultCode_IsEmpty"] = function(self)				
					self:subscribeVehicleDataSuccess(vehicleData)						
				end			
				commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsEmpty", "", "GENERIC_ERROR")
		
	
				--3.4. IsExistentValue
				for i = 1, #AllVehicleDataResultCode do
					Test["PreCondition_SubscribeVehicleData_"..ParameterName.."_ResultCode_Is_"..AllVehicleDataResultCode[i]] = function(self)				
						self:subscribeVehicleDataSuccess(vehicleData)						
					end					
					commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsExistentValue_"..AllVehicleDataResultCode[i], AllVehicleDataResultCode[i], "SUCCESS")
				end
				
				--3.5. IsNonexistentValue
				Test["PreCondition_SubscribeVehicleData_"..ParameterName.."_ResultCode_IsNoneExistentValue"] = function(self)				
					self:subscribeVehicleDataSuccess(vehicleData)						
				end				
				commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsNonexistentValue", "ANY", "GENERIC_ERROR")				
		
end
---------------------------------------------------------------------------------------------
-------------------------------------------PreConditions-------------------------------------
---------------------------------------------------------------------------------------------
	--Print new line to separate Preconditions
	commonFunctions:newTestCasesGroup("Preconditions")

	--Delete app_info.dat, logs and policy table
	commonSteps:DeleteLogsFileAndPolicyTable()


	--1. Activate application
	commonSteps:ActivationApp()

	--2. Update policy to allow request
	testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/PTU_ForVehicleData.json")

---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
--CommonRequestCheck: Check of mandatory/conditional request's parameters (mobile protocol)--
---------------------------------------------------------------------------------------------

	--Begin Test suit CommonRequestCheck
	--Description:
		-- request with all parameters
        -- request with only mandatory parameters
        -- request with all combinations of conditional-mandatory parameters (if exist)
        -- request with one by one conditional parameters (each case - one conditional parameter)
        -- request with missing mandatory parameters one by one (each case - missing one mandatory parameter)
        -- request with all parameters are missing
        -- request with fake parameters (fake - not from protocol, from another request)
        -- request is sent with invalid JSON structure
        -- different conditions of correlationID parameter (invalid, several the same etc.)

    	--Begin Test case CommonRequestCheck.1
    	--Description: This test is intended to check request with all parameters
		-- commonFunctions:newTestCasesGroup("CommonRequestCheck.1")
			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-93

			--Verification criteria: SubsribeVehicleData request subscribes application for specific published vehicle data items. The data is sent upon being changed on HMI. The application is notified by the onVehicleData notification whenever the new data is available.
			function Test:PreCondition_SubscribeVehicleData()				
				self:subscribeVehicleDataSuccess(allVehicleData)
				
			end
			function Test:UnsubscribeVehicleData_Positive() 				
				self:unsubscribeVehicleDataSuccess(allVehicleData)				
			end
		--End Test case CommonRequestCheck.1
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case CommonRequestCheck.2
		--Description: This test is intended to check request with mandatory and conditional parameters
		commonFunctions:newTestCasesGroup("CommonRequestCheck.2 - Not applicable")		
			--Not applicable
		--End Test case CommonRequestCheck.2
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case CommonRequestCheck.3
		--Description: This test is intended to check processing requests without mandatory parameters
		commonFunctions:newTestCasesGroup("CommonRequestCheck.3")
			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-598

			--Verification criteria:
				--The request sent with NO parameters receives INVALID_DATA response code.
				function Test:UnsubscribeVehicleData_AllParamsMissing() 
					self:unsubscribeVehicleDataInvalidData({})
				end			
		--End Test case CommonRequestCheck.3
		
		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.4
		--Description: Check processing request with different fake parameters
		commonFunctions:newTestCasesGroup("CommonRequestCheck.4")
			--Requirement id in JAMA/or Jira ID: APPLINK-4518

			--Verification criteria: According to xml tests by Ford team all fake params should be ignored by SDL

			--Begin Test case CommonRequestCheck4.1
			--Description: With fake parameters
				function Test:PreCondition_SubscribeVehicleData()				
					self:subscribeVehicleDataSuccess({"gps"})
				end
				function Test:UnsubscribeVehicleData_FakeParams()										
					--mobile side: sending UnsubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																				{
																					gps = true,
																					fakeParam ="fakeParam"
																				})
					
					--hmi side: expect UnsubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})	
					end)
					:ValidIf(function(_,data)
						if data.params.fakeParam then							
							print(" \27[36m SDL re-sends fakeParam parameters to HMI \27[0m")							
							return false
						else 
							return true
						end
					end)
					
					--mobile side: expect UnsubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})
					
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end
			--End Test case CommonRequestCheck4.1
			
			-----------------------------------------------------------------------------------------

			--Begin Test case CommonRequestCheck.4.2
			--Description: Parameters from another request
				function Test:PreCondition_SubscribeVehicleData()				
					self:subscribeVehicleDataSuccess({"gps"})
				end
				function Test:UnsubscribeVehicleData_ParamsAnotherRequest()
					--mobile side: sending UnsubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																				{
																					gps = true,
																					ttsChunks = 
																					{ 
																						{ 
																							text = "TTSChunk",
																							type = "TEXT",
																						} 
																					}
																				})
					
					--hmi side: expect UnsubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})	
					end)
					:ValidIf(function(_,data)
						if data.params.ttsChunks then							
							print(" \27[36m SDL re-sends fakeParam parameters to HMI \27[0m")							
							return false
						else 
							return true
						end
					end)
					
					--mobile side: expect UnsubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})
					
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end
			--End Test case CommonRequestCheck4.2
		--End Test case CommonRequestCheck.4
		
		-----------------------------------------------------------------------------------------

		--Begin Test case CommonRequestCheck.5
		--Description: Check processing request with invalid JSON syntax 
		commonFunctions:newTestCasesGroup("CommonRequestCheck.5")
			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-598

			--Verification criteria:  The request with wrong JSON syntax is sent, the response with INVALID_DATA result code is returned.
			function Test:UnsubscribeVehicleData_InvalidJSON()
				  self.mobileSession.correlationId = self.mobileSession.correlationId + 1

				  local msg = 
				  {
					serviceType      = 7,
					frameInfo        = 0,
					rpcType          = 0,
					rpcFunctionId    = 21,
					rpcCorrelationId = self.mobileSession.correlationId,
				--<<!-- missing ':'
					payload          = '{"gps"  true}'
				  }
				  
				  self.mobileSession:Send(msg)
				  self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })
				  
				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
			end
		--End Test case CommonRequestCheck.5

		-----------------------------------------------------------------------------------------
		
		--Begin Test case CommonRequestCheck.6
		--Description: Check processing requests with duplicate correlationID value
		commonFunctions:newTestCasesGroup("CommonRequestCheck.6")
			--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-597

			--Verification criteria: 
				--The request is executed successfully
			function Test:PreCondition_SubscribeVehicleData()				
				self:subscribeVehicleDataSuccess({"gps", "speed"})
				DelayedExp(2000)
			end
			function Test:UnsubscribeVehicleData_correlationIdDuplicateValue()
				--mobile side: send UnsubscribeVehicleData request 
				local CorIdUnsubscribeVehicleData = self.mobileSession:SendRPC("UnsubscribeVehicleData", {gps = true})
				
				local msg = 
				  {
					serviceType      = 7,
					frameInfo        = 0,
					rpcType          = 0,
					rpcFunctionId    = 21,
					rpcCorrelationId = CorIdUnsubscribeVehicleData,				
					payload          = '{"speed" : true}'
				  }
				
				--hmi side: expect UnsubscribeVehicleData request
				EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",
					{gps = true},
					{speed = true}
				)
				:Do(function(exp,data)
					if exp.occurences == 1 then 
						self.mobileSession:Send(msg)
						
						--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})
					else
						--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {speed= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"}})
					end				
				end)
				:Times(2)
								
				--mobile side: expect UnsubscribeVehicleData response
				EXPECT_RESPONSE(CorIdUnsubscribeVehicleData, 
						{success = true, resultCode = "SUCCESS", gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}},
						{success = true, resultCode = "SUCCESS", speed= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"}})       
				:Times(2)
				
				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(2)
			end
		--End Test case CommonRequestCheck.6
	--End Test suit CommonRequestCheck

---------------------------------------------------------------------------------------------
----------------------------------------II TEST BLOCK----------------------------------------
----------------------------------------Positive cases---------------------------------------
---------------------------------------------------------------------------------------------

	--=================================================================================--
	--------------------------------Positive request check-------------------------------
	--=================================================================================--

		--Begin Test suit PositiveRequestCheck
		--Description: check of each request parameter value in bound and boundary conditions

			--Begin Test case PositiveRequestCheck.1
			--Description: Check processing request with lower and upper bound values
			commonFunctions:newTestCasesGroup("PositiveRequestCheck.1")
				--Requirement id in JAMA: 
					-- SDLAQ-CRS-93,
					-- SDLAQ-CRS-597
				
				--Verification criteria: 
					--Checking all VehicleData parameter. The request is executed successfully				
				function Test:PreCondition_SubscribeVehicleData()				
					self:subscribeVehicleDataSuccess(allVehicleData)										
				end	
				for i=1, #allVehicleData do
					Test["UnsubscribeVehicleData_"..allVehicleData[i]] = function(self)
						self:unsubscribeVehicleDataSuccess({allVehicleData[i]})					
					end
				end
			--End Test case PositiveRequestCheck.1	
		--End Test suit PositiveRequestCheck

	--=================================================================================--
	--------------------------------Positive response check------------------------------
	--=================================================================================--
		
		--------Checks-----------
		-- parameters with values in boundary conditions

		--Begin Test suit PositiveResponseCheck
		--Description: Checking parameters boundary conditions

			--Begin Test case PositiveResponseCheck.1
			--Description: Checking info parameter boundary conditions
			commonFunctions:newTestCasesGroup("PositiveResponseCheck.1")
				--Requirement id in JAMA:
					--SDLAQ-CRS-94
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The corresponding parameters sent within the request are returned with the data about unsubscription.  
	
				--Begin Test case PositiveResponseCheck.1.1
				--Description: Response with info parameter lower bound
					function Test:PreCondition_SubscribeVehicleData()				
						self:subscribeVehicleDataSuccess(vehicleData)						
					end
					function Test:UnsubscribeVehicleData_ResponseInfoLowerBound()						
						self:unsubscribeVehicleDataSuccess(vehicleData, "a")
					end
				--End Test case PositiveResponseCheck.1.1
				
				-----------------------------------------------------------------------------------------

				--Begin Test case PositiveResponseCheck.1.2
				--Description:  Response with info parameter upper bound
					function Test:PreCondition_SubscribeVehicleData()				
						self:subscribeVehicleDataSuccess(vehicleData)						
					end
					function Test:UnsubscribeVehicleData_ResponseInfoLowerBound()						
						self:unsubscribeVehicleDataSuccess(vehicleData, string.rep("a",1000))						
					end
				--End Test case PositiveResponseCheck.1.2				

				--Begin Test case PositiveResponseCheck.1.3
				--Requirement: APPLINK-21379				
				--Description:  Response with different values of fuelRange			
				--<param name="fuelRange" type="Common.VehicleDataResult" mandatory="false">	
				Test["Precondition_PositiveResponseCheck_fuelRange"] = function(self)
					vehicleData = {"gps", "fuelRange"}
				end				
				Verify_UnsubscribeVehicleData_Enum_String_Parameter_In_Response("fuelRange", "VEHICLEDATA_FUELRANGE")
				--End Test case PositiveResponseCheck.1.3

				-----------------------------------------------------------------------------------------
			
				--Begin Test case PositiveResponseCheck.1.4
				--Requirement: APPLINK-21379				
				--Description:  Response with different values of abs_State			
				--<param name="abs_State" type="Common.VehicleDataResult" mandatory="false">
				Test["Precondition_PositiveResponseCheck_abs_State"] = function(self)
					vehicleData = {"gps", "abs_State"}
				end					
				Verify_UnsubscribeVehicleData_Enum_String_Parameter_In_Response("abs_State", "VEHICLEDATA_ABS_STATE")	
				--End Test case PositiveResponseCheck.1.4	
				
				-----------------------------------------------------------------------------------------
			
				--Begin Test case PositiveResponseCheck.1.5
				--Requirement: APPLINK-21379
				--Description:  Response with different values of tirePressureValue			
				--<param name="tirePressureValue" type="Common.VehicleDataResult" mandatory="false">
				Test["Precondition_PositiveResponseCheck_tirePressureValue"] = function(self)
					vehicleData = {"gps", "tirePressureValue"}
				end	
				Verify_UnsubscribeVehicleData_Enum_String_Parameter_In_Response("tirePressureValue", "VEHICLEDATA_TIREPRESSURE_VALUE")	
				--End Test case PositiveResponseCheck.1.5
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case PositiveResponseCheck.1.6
				--Requirement: APPLINK-21379
				--Description:  Response with different values of tpms			
				--<param name="tpms" type="Common.VehicleDataResult" mandatory="false">
				Test["Precondition_PositiveResponseCheck_tpms"] = function(self)
					vehicleData = {"gps", "tpms"}
				end	
				Verify_UnsubscribeVehicleData_Enum_String_Parameter_In_Response("tpms", "VEHICLEDATA_TPMS")	
				--End Test case PositiveResponseCheck.1.6	

				-----------------------------------------------------------------------------------------				
				
				--Begin Test case PositiveResponseCheck.1.7
				--Requirement: APPLINK-21379
				--Description:  Response with different values of turnSignal			
				--<param name="turnSignal" type="Common.VehicleDataResult" mandatory="false">
				Test["Precondition_PositiveResponseCheck_turnSignal"] = function(self)
					vehicleData = {"gps", "turnSignal"}
				end	
				Verify_UnsubscribeVehicleData_Enum_String_Parameter_In_Response("turnSignal", "VEHICLEDATA_TURNSIGNAL")
				--End Test case PositiveResponseCheck.1.7			
				
				Test["Postcondition_PositiveResponseCheck.1"] = function(self)
					vehicleData = {"gps"}
				end
			--End Test case PositiveResponseCheck.1			
			
		--End Test suit PositiveResponseCheck				

----------------------------------------------------------------------------------------------
----------------------------------------III TEST BLOCK----------------------------------------
----------------------------------------Negative cases----------------------------------------
----------------------------------------------------------------------------------------------

	--=================================================================================--
	---------------------------------Negative request check------------------------------
	--=================================================================================--

	--Begin Test suit NegativeRequestCheck
		--Description: check of each request parameter value out of bound, missing, with wrong type, empty, duplicate etc.

			--Begin Test case NegativeRequestCheck.1
			--Description: Check processing requests with out of lower and upper bound values 
			commonFunctions:newTestCasesGroup("NegativeRequestCheck.1")				
				--Not applicable
				
			--End Test case NegativeRequestCheck.1

			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeRequestCheck.2
			--Description: Check processing requests with empty values
			commonFunctions:newTestCasesGroup("NegativeRequestCheck.2")
				--Requirement id in JAMA/or Jira ID: 
					--SDLAQ-CRS-598

				--Verification criteria: 
					--[[
						6.1 The request with empty "gps" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.2 The request with empty "speed" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.3 The request with empty "rpm" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.4 The request with empty "fuelLevel" parameter value is sent, the response with INVALID_DATA result code is returned. 
						6.5 The request with empty "instantFuelConsumption" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.6 The request with empty "externalTemperature" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.7 The request with empty "prndl" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.8 The request with empty "tirePressure" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.9 The request with empty "odometer" parameter value is sent, the response with INVALID_DATA result code is returned. 
						6.10 The request with empty "beltStatus" parameter value is sent, the response with INVALID_DATA result code is returned. 
						6.11 The request with empty "bodyInformation" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.12 The request with empty "deviceStatus" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.13 The request with empty "driverBraking" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.14 The request with empty "wiperStatus" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.15 The request with empty "headLampStatus" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.16 The request with empty "engineTorque" parameter value is sent, the response with INVALID_DATA result code is returned. 
						6.17 The request with empty "steeringWheelAngle" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.18 The request with empty "eCallInfo" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.19 The request with empty "airbagStatus" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.20 The request with empty "emergencyEvent" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.21 The request with empty "clusterModeStatus" parameter value is sent, the response with INVALID_DATA result code is returned.
						6.22 The request with empty "myKey" parameter value is sent, the response with INVALID_DATA result code is returned.
					]]
					
				--Covered by INVALID_JSON case
					
			--End Test case NegativeRequestCheck.2
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeRequestCheck.3
			--Description: Check processing requests with wrong type of parameters
			commonFunctions:newTestCasesGroup("NegativeRequestCheck.3")
				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-598

				--Verification criteria: 
					-- The request with wrong type of parameter value is sent, the response with INVALID_DATA result code is returned.
					for i=1, #allVehicleData do
						Test["UnsubscribeVehicleData_WrongType_"..allVehicleData[i]] = function(self)
							local temp = {}
							temp[allVehicleData[i]] = 123
							self:unsubscribeVehicleDataInvalidData(temp)
						end
					end											
			--End Test case NegativeRequestCheck.3

			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeRequestCheck.4
			--Description: Check processing request with Special characters
			commonFunctions:newTestCasesGroup("NegativeRequestCheck.4 - Not applicable")
				-- Not applicable
			
			--End Test case NegativeRequestCheck.4
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeRequestCheck.5
			--Description: Check processing request with value not existed
			commonFunctions:newTestCasesGroup("NegativeRequestCheck.5")			
				--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-598

				--Verification criteria: 
					--The request with the wrong name parameter (the one that does not exist in the list of valid parameters for UnsubscribeVehicleData) is processed by SDL as the invalid request even if such parameter is the only one in. The response returned contains the INVALID_DATA code. General result is "success"=false.
				function Test:UnsubscribeVehicleData_DataNotExisted()
					self:unsubscribeVehicleDataInvalidData({abc = true})
				end								
			--End Test case NegativeRequestCheck.5			
		--End Test suit NegativeRequestCheck

	--=================================================================================--
	---------------------------------Negative response check-----------------------------
	--=================================================================================--

		--------Checks-----------
		-- outbound values
		-- invalid values(empty, missing, nonexistent, invalid characters)
		-- parameters with wrong type
		-- invalid json
		
		--Begin Test suit NegativeResponseCheck
		--Description: Check of each response parameter value out of bound, missing, with wrong type, empty, duplicate etc.
--[[TODO: Check after APPLINK-14765 is resolved
			--Begin Test case NegativeResponseCheck.1
			--Description: Check processing response with outbound values

				--Requirement id in JAMA:
					--SDLAQ-CRS-94
					--SDLAQ-CRS-1100
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The corresponding parameters sent within the request are returned with the data about unsubscription. 
					-- SDL re-sends vehicleDataResult received from HMI for every of parameters being subscribed (that is, parameters that are present in corresponding UnsubscribeVehicleData request).

				--Begin Test case NegativeResponseCheck.1.1
				--Description: Check response with nonexistent resultCode 
					function Test:UnsubscribeVehicleData_ResponseResultCodeNotExist()
						--mobile side: sending UnsubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect UnsubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "ANY", {gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})	
						end)
						
						--mobile side: expect UnsubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})		
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeResponseCheck.1.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.1.2
				--Description: Check response with nonexistent VehicleData parameter 
					function Test:UnsubscribeVehicleData_ResponseVehicleDataNotExist()
						--mobile side: sending UnsubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect UnsubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {abc= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})	
						end)
						
						--mobile side: expect UnsubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeResponseCheck.1.2
								
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.1.3
				--Description: Check response with nonexistent VehicleDataResultCode 
					function Test:UnsubscribeVehicleData_ResponseVehicleDataResultCodeNotExist()
						--mobile side: sending UnsubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect UnsubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps= {resultCode = "ANY", dataType = "VEHICLEDATA_GPS"}})	
						end)
						
						--mobile side: expect UnsubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeResponseCheck.1.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.1.4
				--Description: Check response with nonexistent VehicleDataType 
					function Test:UnsubscribeVehicleData_ResponseVehicleDataTypeNotExist()
						--mobile side: sending UnsubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect UnsubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps= {resultCode = "SUCCESS", dataType = "ANY"}})	
						end)
						
						--mobile side: expect UnsubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End Test case NegativeResponseCheck.1.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.1.5
				--Description: Check response out bound of vehicleData
					function Test:UnsubscribeVehicleData_ResponseVehicleDataOutLowerBound()					
						--mobile side: sending UnsubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect UnsubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps= {}})	
						end)
						
						--mobile side: expect UnsubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})			
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End NegativeResponseCheck.1.5
			--End Test case NegativeResponseCheck.1
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeResponseCheck.2
			--Description: Check processing responses with invalid values (empty, missing, nonexistent, invalid characters)

				--Requirement id in JAMA:
					--SDLAQ-CRS-94
					--SDLAQ-CRS-1100
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The corresponding parameters sent within the request are returned with the data about unsubscription. 
					-- SDL re-sends vehicleDataResult received from HMI for every of parameters being subscribed (that is, parameters that are present in corresponding UnsubscribeVehicleData request).

				--Begin NegativeResponseCheck.2.1
				--Description: Check response with empty method
					function Test:UnsubscribeVehicleData_ResponseEmptyMethodEmpty()					
						--mobile side: sending UnsubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect UnsubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, "", "SUCCESS", {gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})	
						end)
						
						--mobile side: expect UnsubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})			
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End NegativeResponseCheck.2.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.2
				--Description: Check response with empty resultCode
					function Test:UnsubscribeVehicleData_ResponseEmptyResultCode()					
						--mobile side: sending UnsubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect UnsubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "", {gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})	
						end)
						
						--mobile side: expect UnsubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})			
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End NegativeResponseCheck.2.2	
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.3
				--Description: Check response with empty VehicleDataResultCode
					function Test:UnsubscribeVehicleData_ResponseEmptyVehicleDataResultCode()					
						--mobile side: sending UnsubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect UnsubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps= {resultCode = "", dataType = "VEHICLEDATA_GPS"}})	
						end)
						
						--mobile side: expect UnsubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})			
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End NegativeResponseCheck.2.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.4
				--Description: Check response with empty VehicleDataType
					function Test:UnsubscribeVehicleData_ResponseEmptyVehicleDataType()					
						--mobile side: sending UnsubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect UnsubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps= {resultCode = "SUCCESS", dataType = ""}})	
						end)
						
						--mobile side: expect UnsubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})			
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End NegativeResponseCheck.2.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.5
				--Description: Check response missing all parameter
					function Test:UnsubscribeVehicleData_ResponseMissingAllParams()					
						--mobile side: sending UnsubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect UnsubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
							self.hmiConnection:Send({})
						end)
						
						--mobile side: expect UnsubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})			
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End NegativeResponseCheck.2.5
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.6
				--Description: Check response without method
					function Test:UnsubscribeVehicleData_ResponseMissingMethod()					
						--mobile side: sending UnsubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect UnsubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0,"gps":{"dataType":"VEHICLEDATA_GPS","resultCode":"SUCCESS"}}')							
						end)
						
						--mobile side: expect UnsubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})			
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End NegativeResponseCheck.2.6
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.7
				--Description: Check response without resultCode
					function Test:UnsubscribeVehicleData_ResponseMissingResultCode()					
						--mobile side: sending UnsubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect UnsubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"gps":{"dataType":"VEHICLEDATA_GPS","resultCode":"SUCCESS"},"method":"VehicleInfo.UnsubscribeVehicleData"}}')
						end)
						
						--mobile side: expect UnsubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})			
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End NegativeResponseCheck.2.7
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.8
				--Description: Check response without VehicleDataResultCode
					function Test:UnsubscribeVehicleData_ResponseMissingVehicleDataResultCode()					
						--mobile side: sending UnsubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect UnsubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0,"gps":{"dataType":"VEHICLEDATA_GPS"},"method":"VehicleInfo.UnsubscribeVehicleData"}}')
						end)
						
						--mobile side: expect UnsubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})			
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End NegativeResponseCheck.2.8
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.9
				--Description: Check response without VehicleDataType
					function Test:UnsubscribeVehicleData_ResponseMissingVehicleDataType()					
						--mobile side: sending UnsubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect UnsubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0,"gps":{"resultCode":"SUCCESS"},"method":"VehicleInfo.UnsubscribeVehicleData"}}')
						end)
						
						--mobile side: expect UnsubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})			
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End NegativeResponseCheck.2.9				
				
				-----------------------------------------------------------------------------------------
				
				--Begin NegativeResponseCheck.2.10
				--Description: Check response without mandatory parameter
					function Test:UnsubscribeVehicleData_ResponseMissingMandatory()					
						--mobile side: sending UnsubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect UnsubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
							self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{info = "abc"}}')
						end)
						
						--mobile side: expect UnsubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})			
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				--End NegativeResponseCheck.2.10
			--End Test case NegativeResponseCheck.2

			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeResponseCheck.3
			--Description: Check processing response with parameters with wrong data type 

				--Requirement id in JAMA:
					--SDLAQ-CRS-94
					--SDLAQ-CRS-1100
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The corresponding parameters sent within the request are returned with the data about unsubscription. 
					-- SDL re-sends vehicleDataResult received from HMI for every of parameters being subscribed (that is, parameters that are present in corresponding UnsubscribeVehicleData request).

				--Begin Test case NegativeResponseCheck.3.1
				--Description: Check response with wrong type of method
					function Test:UnsubscribeVehicleData_ResponseWrongTypeMethod() 
						--mobile side: sending UnsubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect UnsubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, 1234, "SUCCESS", {gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})	
						end)
						
						--mobile side: expect UnsubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end				
				--End Test case NegativeResponseCheck.3.1
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.2
				--Description: Check response with wrong type of resultCode
					function Test:UnsubscribeVehicleData_ResponseWrongTypeResultCode() 
						--mobile side: sending UnsubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect UnsubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, 123, {gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})	
						end)
						
						--mobile side: expect UnsubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end				
				--End Test case NegativeResponseCheck.3.2
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.3
				--Description: Check response with wrong type of vehicleData
					function Test:UnsubscribeVehicleData_ResponseWrongTypeVehicleData() 
						--mobile side: sending UnsubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect UnsubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps= 123})	
						end)
						
						--mobile side: expect UnsubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end				
				--End Test case NegativeResponseCheck.3.3
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.4
				--Description: Check response with wrong type of VehicleDataResultCode
					function Test:UnsubscribeVehicleData_ResponseWrongTypeVehicleDataResultCode() 
						--mobile side: sending UnsubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect UnsubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps= {resultCode = 123, dataType = "VEHICLEDATA_GPS"}})	
						end)
						
						--mobile side: expect UnsubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end				
				--End Test case NegativeResponseCheck.3.4
				
				-----------------------------------------------------------------------------------------
				
				--Begin Test case NegativeResponseCheck.3.5
				--Description: Check response with wrong type of VehicleDataType
					function Test:UnsubscribeVehicleData_ResponseWrongTypeVehicleDataType() 
						--mobile side: sending UnsubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect UnsubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {gps= {resultCode = "SUCCESS", dataType = 123}})	
						end)
						
						--mobile side: expect UnsubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end				
				--End Test case NegativeResponseCheck.3.5				
			--End Test case NegativeResponseCheck.3

			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeResponseCheck.4
			--Description: Invalid JSON

				--Requirement id in JAMA:
					--SDLAQ-CRS-94
					--SDLAQ-CRS-1100
					
				--Verification criteria:
					-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The corresponding parameters sent within the request are returned with the data about unsubscription. 
					-- SDL re-sends vehicleDataResult received from HMI for every of parameters being subscribed (that is, parameters that are present in corresponding UnsubscribeVehicleData request).
	
					function Test:UnsubscribeVehicleData_ResponseInvalidJson()	
						--mobile side: sending UnsubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect UnsubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
							--<<!-- missing ':'
							self.hmiConnection:Send('{"id" '..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0,"gps":{"dataType":"VEHICLEDATA_GPS","resultCode":"SUCCESS"},"method":"VehicleInfo.UnsubscribeVehicleData"}}')
						end)
						
						--mobile side: expect UnsubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})						
						
						--mobile side: expect OnHashChange notification is not send to mobile
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end				
				
			--End Test case NegativeResponseCheck.4
--]]			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case NegativeResponseCheck.5
			--Description: SDL behaviour: cases when SDL must transfer "info" parameter via corresponding RPC to mobile app
			commonFunctions:newTestCasesGroup("NegativeResponseCheck.5")
				--Requirement id in JAMA/or Jira ID: 
					--SDLAQ-CRS-94
					--APPLINK-13276
					--APPLINK-14551
					
				--Description:
					-- In case "message" is empty - SDL should not transfer it as "info" to the app ("info" needs to be omitted)
					-- In case info out of upper bound it should truncate to 1000 symbols
					-- SDL should not send "info" to app if received "message" is invalid
					-- SDL should not send "info" to app if received "message" contains newline "\n" or tab "\t" symbols.
					
				--Begin Test Case NegativeResponseCheck5.1
				--Description: Check response with empty info
					function Test:PreCondition_SubscribeVehicleData()				
						self:subscribeVehicleDataSuccess(vehicleData)						
					end
					function Test:UnsubscribeVehicleData_ResponseInfoOutLowerBound()	
						--mobile side: sending UnsubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect UnsubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = "", gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})	
						end)
						
						--mobile side: expect UnsubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m")
								return false
							else 
								return true
							end
						end)						
						
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test Case NegativeResponseCheck5.1
				
				-----------------------------------------------------------------------------------------
			--TODO: update after resolving APPLINK-14551 
			--[=[
				--Begin Test Case NegativeResponseCheck5.2
				--Description: Check response with info out upper bound
					function Test:PreCondition_SubscribeVehicleData()				
						self:subscribeVehicleDataSuccess(vehicleData)						
					end
					function Test:UnsubscribeVehicleData_ResponseInfoOutUpperBound()	
						--mobile side: sending UnsubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect UnsubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = infoMessageValue.."a",gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})	
						end)
						
						--mobile side: expect UnsubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}, info = infoMessageValue})						
						
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test Case NegativeResponseCheck5.2
			]=]
						
				-----------------------------------------------------------------------------------------
					
				--Begin Test Case NegativeResponseCheck5.3
				--Description: Check response with wrong type info
					function Test:PreCondition_SubscribeVehicleData()				
						self:subscribeVehicleDataSuccess(vehicleData)						
					end
					function Test:UnsubscribeVehicleData_ResponseInfoWrongType()	
						--mobile side: sending UnsubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect UnsubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = 1234, gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})	
						end)
						
						--mobile side: expect UnsubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m")
								return false
							else 
								return true
							end
						end)						
						
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test Case NegativeResponseCheck5.3
								
				-----------------------------------------------------------------------------------------
					
				--Begin Test Case NegativeResponseCheck5.4
				--Description: Check response with info have escape sequence \n 
					function Test:PreCondition_SubscribeVehicleData()				
						self:subscribeVehicleDataSuccess(vehicleData)						
					end
					function Test:UnsubscribeVehicleData_ResponseInfoNewLineChar()	
						--mobile side: sending UnsubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect UnsubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = "New line \n", gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})	
						end)
						
						--mobile side: expect UnsubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m")
								return false
							else 
								return true
							end
						end)						
						
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test Case NegativeResponseCheck5.4
								
				-----------------------------------------------------------------------------------------
					
				--Begin Test Case NegativeResponseCheck5.5
				--Description: Check response with info have escape sequence \t
					function Test:PreCondition_SubscribeVehicleData()				
						self:subscribeVehicleDataSuccess(vehicleData)						
					end
					function Test:UnsubscribeVehicleData_ResponseInfoNewTabChar()	
						--mobile side: sending UnsubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																					{
																						gps = true
																					})
						
						--hmi side: expect UnsubscribeVehicleData request
						EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})					
						:Do(function(_,data)
							--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
							self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = "New tab \t", gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})	
						end)
						
						--mobile side: expect UnsubscribeVehicleData response
						EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})
						:ValidIf (function(_,data)
							if data.payload.info then
								print(" \27[36m SDL resend invalid info to mobile app \27[0m")
								return false
							else 
								return true
							end
						end)
						
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
					end
				--End Test Case NegativeResponseCheck5.5									
			--End Test case NegativeResponseCheck.5
		--End Test suit NegativeResponseCheck

----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result codes check--------------------------------------
----------------------------------------------------------------------------------------------

		--------Checks-----------
		-- check all pairs resultCode+success
		-- check should be made sequentially (if it is possible):
		-- case resultCode + success true
		-- case resultCode + success false
			--For example:
				-- first case checks ABORTED + true
				-- second case checks ABORTED + false
			    -- third case checks REJECTED + true
				-- fourth case checks REJECTED + false

	--Begin Test suit ResultCodeCheck
	--Description:TC's check all resultCodes values in pair with success value

		--Begin Test case ResultCodeCheck.1
		--Description: Check OUT_OF_MEMORY result code
			commonFunctions:newTestCasesGroup("ResultCodeCheck.1 - Not applicable")
			--Requirement id in JAMA: SDLAQ-CRS-599

			--Verification criteria: 
				--A request UnsubscribeVehicleData is sent under conditions of RAM deficit for executing it. The OUT_OF_MEMORY response code is returned. 
			
			--Not applicable
			
		--End Test case ResultCodeCheck.1
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case ResultCodeCheck.2
		--Description: Check of TOO_MANY_PENDING_REQUESTS result code
			commonFunctions:newTestCasesGroup("ResultCodeCheck.2")
			--Requirement id in JAMA: SDLAQ-CRS-600

			--Verification criteria: 
				--The system has more than 1000 requests  at a time that haven't been responded yet.
				--The system sends the responses with TOO_MANY_PENDING_REQUESTS error code for all further requests until there are less than 1000 requests at a time that haven't been responded by the system yet.
			
			--Moved to ATF_UnsubscribeVehicleData_TOO_MANY_PENDING_REQUESTS.lua
			
		--End Test case ResultCodeCheck.2

		-----------------------------------------------------------------------------------------
		
		--Begin Test case ResultCodeCheck.3
		--Description: Check APPLICATION_NOT_REGISTERED result code 
			commonFunctions:newTestCasesGroup("ResultCodeCheck.3")
			--Requirement id in JAMA: SDLAQ-CRS-601

			--Verification criteria: 
				-- SDL returns APPLICATION_NOT_REGISTERED code for the request sent within the same connection before RegisterAppInterface has been performed yet.
			function Test:PreCondition_CreationNewSession()
				-- Connected expectation
			  	self.mobileSession2 = mobile_session.MobileSession(
			    self,
			    self.mobileConnection)			   
			end
			for i=1, #allVehicleData do
				Test["UnsubscribeVehicleData_ApplicationNotRegister_"..allVehicleData[i]] = function(self)					
					local temp = {}
					temp[allVehicleData[i]] = true
					--mobile side: sending UnsubscribeVehicleData request					
					local cid = self.mobileSession2:SendRPC("UnsubscribeVehicleData",temp)
					
					--mobile side: expected UnsubscribeVehicleData response
					self.mobileSession2:ExpectResponse(cid, { success = false, resultCode = "APPLICATION_NOT_REGISTERED" })
						
					--mobile side: expect OnHashChange notification is not send to mobile
					self.mobileSession2:ExpectNotification("OnHashChange",{})
					:Times(0)
				end
			end					
		--End Test case ResultCodeCheck.3			
		
		-----------------------------------------------------------------------------------------
	
		--Begin Test case ResultCodeCheck.4
		--Description: Check IGNORED result code with success false/true
			commonFunctions:newTestCasesGroup("ResultCodeCheck.4")
			--Requirement id in JAMA: SDLAQ-CRS-602, APPLINK-8673

			--Verification criteria: 
			--[[
				1. In case an application sends UnsubscribeVehicleData request for previously subscribed VehicleData, SDL returns the IGNORED resultCode to mobile side. General result is success=false.

				2.
				Pre-conditions:
				a) HMI and SDL are started.
				b) Device is consented by the User.
				c) App (running on this device) is registered.
				d) "<appID>" section in Local PT has "DrivingCharacteristics-3" in "groups" section.
				e) "DrivingCharacteristics-3" has "UnsubscribeVehicleData":sub-section with the following parameters (meaning only these params are allowed by Policies):
				"parameters": ["accPedalPosition", "beltStatus", "driverBraking", "myKey", "prndl", "rpm", "steeringWheelAngle"]

				app->SDL: UnsubscribeVehicleData("prndl", "speed") //prndl is subscribed already
				SDL->app: UnsubscribeVehicleData (speed: (dataType: VEHICLEDATA_PRNDL, resultCode: DATA_NOT_SUBSCRIBED), gps: (dataType: VEHICLEDATA_SPEED, resultCode: DISALLOWED), resultCode: IGNORED, success: false, info: "'prndl' is subscribed already, 'speed' is disallowed by policies")
			--]]
			--Begin Test Case ResultCodeCheck.4.1
			--Description: UnsubscribeVehicleData request for previously subscribed VehicleData
				function Test:PreCondition_SubscribeVehicleData()				
					self:subscribeVehicleDataSuccess(allVehicleData)					
				end
				for i=1, #allVehicleData do
					Test["PreCondition_Unsubscribe_"..allVehicleData[i]] = function(self)						
						self:unsubscribeVehicleDataSuccess({allVehicleData[i]})
					end				
					Test["UnsubscribeVehicleData_PreviouslyUnsubscribed_"..allVehicleData[i]] = function(self)			
						--print("\27[31m DEFECT: APPLINK-22732\27[0m")		
						self:unsubscribeVehicleDataIgnored({allVehicleData[i]}, false)
					end
				end				
			--End Test Case ResultCodeCheck.4.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test Case ResultCodeCheck.4.2
			--Description: UnsubscribeVehicleData request for previously subscribed VehicleData and non-subscribed 				
				function Test:PreCondition_SubscribeGPS()					
					self:subscribeVehicleDataSuccess({"speed"})					
				end				
				function Test:UnsubscribeVehicleData_SubscribedAndNonSubscribed()
					--mobile side: sending UnsubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																				{
																					gps = true,
																					speed = true
																				})					
					
					--hmi side: expect UnsubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{
																		speed = true
																	})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.UnsubscribeVehicleData response						
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {speed= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"}})	
					end)
					:ValidIf (function(_,data)
			    		if data.params.gps then
			    			print(" \27[36m SDL send unsubscribed vehicleData to HMI \27[0m")
			    			return false
			    		else 
			    			return true
			    		end
			    	end)
					
					--print("\27[31m DEFECT: APPLINK-17738\27[0m")
					--mobile side: expect UnsubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "IGNORED", 
											gps= {resultCode = "DATA_NOT_SUBSCRIBED", dataType = "VEHICLEDATA_GPS"},
											speed= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"},
											info = "Some provided VehicleData was not subscribed."})					
						
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end
			--End Test Case ResultCodeCheck.4.2
			
			-----------------------------------------------------------------------------------------
--[==[TODO: check after ATF defect APPLINK-13101 resolved			
			--Begin Test Case ResultCodeCheck.4.3
			--Description: UnsubscribeVehicleData request for previously subscribed VehicleData and disallowed by policies
				function Test:PreCondition_PolicyUpdate()
					--hmi side: sending SDL.GetURLS request
					local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
					
					--hmi side: expect SDL.GetURLS response from HMI
					EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {{url = "http://policies.telematics.ford.com/api/policies"}}}})
					:Do(function(_,data)
						--print("SDL.GetURLS response is received")
						--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
						self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
							{
								requestType = "PROPRIETARY",
								fileName = "filename"
							}
						)
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
							"files/PTU_ForSubscribeVehicleData.json")
							
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
									}
								)
								function to_run()
									--hmi side: sending SystemRequest response
									self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
								end
								
								RUN_AFTER(to_run, 500)
							end)
							
							--hmi side: expect SDL.OnStatusUpdate
							EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status =  "UP_TO_DATE"})
							:Do(function(_,data)
								--print("SDL.OnStatusUpdate is received")
								
								--hmi side: expect SDL.OnAppPermissionChanged
								
								
							end)
							:Timeout(2000)
							
							--mobile side: expect SystemRequest response
							EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
							:Do(function(_,data)
								--print("SystemRequest is received")
								--hmi side: sending SDL.GetUserFriendlyMessage request to SDL
								local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})
								
								--hmi side: expect SDL.GetUserFriendlyMessage response
								EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
								:Do(function(_,data)
									--print("SDL.GetUserFriendlyMessage is received")
									
									--hmi side: sending SDL.GetListOfPermissions request to SDL
									local RequestIdGetListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = self.applications["Test Application"]})
									
									-- hmi side: expect SDL.GetListOfPermissions response
									EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions,{result = {code = 0, method = "SDL.GetListOfPermissions", allowedFunctions = {{ id = 193465391, name = "New"}}}})
									:Do(function(_,data)
										--print("SDL.GetListOfPermissions response is received")
										
										--hmi side: sending SDL.OnAppPermissionConsent
										self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = true, id = 193465391, name = "New"}}, source = "GUI"})
										end)
								end)
							end)
							:Timeout(2000)
							
						end)
					end)
				end
				
				function Test: PreCondition_Subscribe_prndl()					
					self:subscribeVehicleDataSuccess({"prndl"})					
					
				end
				
				function Test:UnsubscribeVehicleData_SubscribedAndDisallowed()
					--mobile side: sending UnsubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																				{
																					prndl = true,
																					speed = true
																				})					
										
					--hmi side: expect UnsubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{
																		prndl = true,
																		speed = true
																	})					
					:Times(0)
					
					--mobile side: expect UnsubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "IGNORED", 
											prndl= {resultCode = "DATA_NOT_SUBSCRIBED", dataType = "VEHICLEDATA_PRNDL"},
											speed= {resultCode = "DISALLOWED", dataType = "VEHICLEDATA_SPEED"},
											info = "'prndl' is subscribed already, 'speed' is disallowed by policies"})	
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End Test Case ResultCodeCheck.4.3
		--End Test case ResultCodeCheck.4
--]==]
		-----------------------------------------------------------------------------------------
		
		--Begin Test case ResultCodeCheck.5
		--Description: Check GENERIC_ERROR result code with success false
			commonFunctions:newTestCasesGroup("ResultCodeCheck.5")
			--Requirement id in JAMA: SDLAQ-CRS-603

			--Verification criteria: 
				-- GENERIC_ERROR comes as a result code in response when all other codes aren't applicable or the unknown issue occurred.
				-- In case SubbscribeVehicleData is allowed by policies with less than supported by protocol parameters AND the app assigned with such policies requests UnsubscribeVehicleData with one and-or more allowed params and with one and-or more NOT-allowed params, SDL must process the allowed params of UnsubscribeVehicleData and return appropriate error code AND add the individual results of DISALLOWED for NOT-allowed params of UnsubscribeVehicleData to response to mobile app + "ResultCode: <applicable-result-code>, success: <applicable flag>" + "info" parameter listing the params disallowed by policies and the information about allowed params processing.
				
			--Begin Test Case ResultCodeCheck.5.1
			--Description: Check GENERIC_ERROR result code for the RPC from HMI				

			
				function Test:PreCondition_SubscribeVehicleData()	
					-- UPDATED: Ford Specific - myKey
					-- self:subscribeVehicleDataSuccess({"myKey"})					
					self:subscribeVehicleDataSuccess({"headLampStatus"})					
				end
				function Test:UnsubscribeVehicleData_GENERIC_ERROR_FromHMI()
					--mobile side: sending UnsubscribeVehicleData request

					local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																				{
																					-- UPDATED: Ford Specific - myKey
																					--myKey = true
																					headLampStatus = true
																				})					
					
					
					--hmi side: expect UnsubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{
																		-- UPDATED: Ford Specific - myKey
																		-- myKey = true
																		headLampStatus = true
																	})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.UnsubscribeVehicleData response	
						-- UPDATED: Ford Specific - myKey				
						--self.hmiConnection:SendResponse(data.id, data.method, "GENERIC_ERROR", {myKey= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_MYKEY"}})	
						self.hmiConnection:SendResponse(data.id, data.method, "GENERIC_ERROR", {headLampStatus = {resultCode = "SUCCESS", dataType = "VEHICLEDATA_HEADLAMPSTATUS"}})	
					end)					
					
					--mobile side: expect UnsubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", 
						-- UPDATED: Ford Specific - myKey	
						--myKey= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_MYKEY"}})
						headLampStatus= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_HEADLAMPSTATUS"}})
					
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end			
			--End Test Case ResultCodeCheck.5.1




			-----------------------------------------------------------------------------------------
--[==[TODO: check after ATF defect APPLINK-13101 resolved				
			--Begin Test Case ResultCodeCheck.5.2
			--Description: Check GENERIC_ERROR result code for the RPC from HMI with individual results of DISALLOWED 
				function Test:PreCondition_SubscribeVehicleData()				
					self:subscribeVehicleDataSuccess({"myKey"})
					
				end
				function Test:UnsubscribeVehicleData_GENERIC_ERROR()
					--mobile side: sending UnsubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																				{																					
																					speed = true,
																					myKey = true
																				})					
					
					
					--hmi side: expect UnsubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{
																		myKey = true
																	})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.UnsubscribeVehicleData response						
						self.hmiConnection:SendResponse(data.id, data.method, "GENERIC_ERROR", {myKey= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_MYKEY"}})	
					end)
					:ValidIf (function(_,data)
			    		if data.params.speed then
			    			print(" \27[36m SDL send disallowed vehicleData to HMI \27[0m")
			    			return false
			    		else 
			    			return true
			    		end
			    	end)
					
					--mobile side: expect UnsubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", 
						myKey= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_MYKEY"},
						speed= {resultCode = "DISALLOWED", dataType = "VEHICLEDATA_SPEED"},
						info = "'speed' is disallowed by policies."})
					:Timeout(5000)
					
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End Test Case ResultCodeCheck.5.2	
		--End Test case ResultCodeCheck.5
		
		-----------------------------------------------------------------------------------------
	
		--Begin Test case ResultCodeCheck.6
		--Description: Check DISALLOWED when UnsubscribeVehicleData is not present in the DB. 
		--Other cases such as SUCCESS, USER_DISALOWED, DISALLOWED and combination of these codes are checked in the BLOCK VI

			--Requirement id in JAMA: SDLAQ-CRS-604, SDLAQ-CRS-2396, SDLAQ-CRS-2397, APPLINK-8673

			--Verification criteria: 
				--  SDL must return "resultCode: DISALLOWED, success:false" to the RPC in case this RPC is omitted in the PolicyTable group(s) assigned to the app that requests this RPC.
			
			--Begin Test Case ResultCodeCheck.6.1
			--Description: UnsubscribeVehicleData is omitted in the PolicyTable group(s) assigned to the app that requests this RPC.
				function Test:PreCondition_PolicyUpdate()
					--hmi side: sending SDL.GetURLS request
					local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
					
					--hmi side: expect SDL.GetURLS response from HMI
					EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {{url = "http://policies.telematics.ford.com/api/policies"}}}})
					:Do(function(_,data)
						--print("SDL.GetURLS response is received")
						--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
						self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
							{
								requestType = "PROPRIETARY",
								fileName = "filename"
							}
						)
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
							"files/PTU_OmittedUnsubscribeVehicleData.json")
							
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
									}
								)
								function to_run()
									--hmi side: sending SystemRequest response
									self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
								end
								
								RUN_AFTER(to_run, 500)
							end)
							
							--hmi side: expect SDL.OnStatusUpdate
							EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status =  "UP_TO_DATE"})
							:Do(function(_,data)
								--print("SDL.OnStatusUpdate is received")
								
								--hmi side: expect SDL.OnAppPermissionChanged
								
								
							end)
							:Timeout(2000)
							
							--mobile side: expect SystemRequest response
							EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
							:Do(function(_,data)
								--print("SystemRequest is received")
								--hmi side: sending SDL.GetUserFriendlyMessage request to SDL
								local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})
								
								--hmi side: expect SDL.GetUserFriendlyMessage response
								EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
								:Do(function(_,data)
									--print("SDL.GetUserFriendlyMessage is received")
									
									--hmi side: sending SDL.GetListOfPermissions request to SDL
									local RequestIdGetListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = self.applications["Test Application"]})
									
									-- hmi side: expect SDL.GetListOfPermissions response
									EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions,{result = {code = 0, method = "SDL.GetListOfPermissions", allowedFunctions = {{ id = 193465391, name = "New"}}}})
									:Do(function(_,data)
										--print("SDL.GetListOfPermissions response is received")
										
										--hmi side: sending SDL.OnAppPermissionConsent
										self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = true, id = 193465391, name = "New"}}, source = "GUI"})
										end)
								end)
							end)
							:Timeout(2000)
							
						end)
					end)
				end
				
				function Test:UnsubscribeVehicleData_RPCOmitted()
					--mobile side: sending UnsubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																				{
																					speed = true,
																					gps = true
																				})					
										
					--hmi side: expect UnsubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{
																		speed = true,
																		gps = true
																	})					
					:Times(0)
					
					--mobile side: expect UnsubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "DISALLOWED"})	
						
					--mobile side: expect OnHashChange notification is not send to mobile
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)				
				end	

				--PostCondition: Update policy
				local PermissionLinesForBase4 = PermissionLinesSubscribeVehicleDataAllParam..PermissionLinesUnsubscribeVehicleDataAllParam
				local PTName = testCasesForPolicyTable:createPolicyTableFile(PermissionLinesForBase4, nil, nil, {"SubscribeVehicleData","UnsubscribeVehicleData"})	
				testCasesForPolicyTable:updatePolicy(PTName)
			--End Test Case ResultCodeCheck.6.1
			
--]==]		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case ResultCodeCheck.7
		--Description: Check REJECTED result code with success false
			commonFunctions:newTestCasesGroup("ResultCodeCheck.7")
			--Requirement id in JAMA: SDLAQ-CRS-2278

			--Verification criteria: 
				-- In case SDL receives REJECTED result code for the RPC from HMI, SDL must transfer REJECTED resultCode with adding "success:false" to mobile app.
				-- In case SubbscribeVehicleData is allowed by policies with less than supported by protocol parameters AND the app assigned with such policies requests UnsubscribeVehicleData with one and-or more allowed params and with one and-or more NOT-allowed params, SDL must process the allowed params of UnsubscribeVehicleData and return appropriate error code AND add the individual results of DISALLOWED for NOT-allowed params of UnsubscribeVehicleData to response to mobile app + "ResultCode: <applicable-result-code>, success: <applicable flag>" + "info" parameter listing the params disallowed by policies and the information about allowed params processing.
				
			--Begin Test Case ResultCodeCheck.7.1
			--Description: Check REJECTED result code for the RPC from HMI
				function Test:PreCondition_UserAllowedUnsubscribeVehicleData()	
					
					self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = true, id = 193465391, name = "New"}}, source = "GUI"})					
				end

				--UPDATED
				function Test:PreCondition_Subscribe_headLampStatus()				
					self:subscribeVehicleDataSuccess(allVehicleData)
				end
				function Test:UnsubscribeVehicleData_REJECTED_FromHMI()
					--mobile side: sending UnsubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																				{
																					-- UPDATED: Ford Specific - myKey				
																					--myKey = true
																					headLampStatus = true
																				})					
					
					
					--hmi side: expect UnsubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{
																		--UPDATED: Ford Specific - myKey				
																		--myKey = true
																		headLampStatus = true
																	})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.UnsubscribeVehicleData response						
						--UPDATED: Ford Specific - myKey				
						--self.hmiConnection:SendResponse(data.id, data.method, "REJECTED", {myKey= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_MYKEY"}})	
						self.hmiConnection:SendResponse(data.id, data.method, "REJECTED", {headLampStatus= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_HEADLAMPSTATUS"}})	
					end)					
					
					--mobile side: expect UnsubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "REJECTED", 
								--UPDATED: Ford Specific - myKey
								--myKey= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_MYKEY"}})
								headLampStatus= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_HEADLAMPSTATUS"}})
					
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End Test Case ResultCodeCheck.7.1
			
			-----------------------------------------------------------------------------------------
--[[TODO: Check after APPLINK-14765 is resolved
			--Begin Test Case ResultCodeCheck.7.2
			--Description: Check REJECTED result code for the RPC from HMI with individual results of DISALLOWED 		
				function Test:UnsubscribeVehicleData_REJECTED()
					--mobile side: sending UnsubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																				{																					
																					odometer = true,
																					myKey = true
																				})					
					
					
					--hmi side: expect UnsubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{																		
																		myKey = true
																	})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.UnsubscribeVehicleData response						
						self.hmiConnection:SendResponse(data.id, data.method, "REJECTED", {myKey= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_MYKEY"}})	
					end)
					:ValidIf(function(_, data)
						if data.params.odometer then
							print(" \27[36m SDL re-sends disallowed parameters to HMI \27[0m")							
							return false
						else
							return true
						end
					end)
					
					
					--mobile side: expect UnsubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = false, resultCode = "REJECTED", 
						myKey= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_MYKEY"},
						odometer= {resultCode = "DISALLOWED", dataType = "VEHICLEDATA_ODOMETER"},
						info = "'odometer' disallowed by policies."})
					:Timeout(5000)
					
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
					:Times(0)
				end
			--End Test Case ResultCodeCheck.7.2
]]
		--End Test case ResultCodeCheck.7
		----------------------------------------------------------------------------------------------------------------------------------------------

		local function Task_APPLINK_15934()

		--Begin Test Case ResultCodeCheck.8
			--Description: Check SUCCESS result code 
			commonFunctions:newTestCasesGroup("ResultCodeCheck.8")			
				--Precondition: Update Policy
				function Test:PreCondition_PolicyUpdate()
					--hmi side: sending SDL.GetURLS request
					local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
					
					--hmi side: expect SDL.GetURLS response from HMI
					EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {
																												url = "http://policies.telematics.ford.com/api/policies",
																												--UPDATED
																												appID = self.applications["Test Application"]
																												}}})
					:Do(function(_,data)
						--print("SDL.GetURLS response is received")
						--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
						self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
							{
								requestType = "PROPRIETARY",
								fileName = "filename"
							}
						)
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
							"files/PTU_ForSubscribeVehicleData.json")
							
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
									}
								)
								function to_run()
									--hmi side: sending SystemRequest response
									self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
								end
								
								RUN_AFTER(to_run, 500)
							end)
							
							--hmi side: expect SDL.OnStatusUpdate
							EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status =  "UP_TO_DATE"})
							:Do(function(_,data)
								--print("SDL.OnStatusUpdate is received")
								
								--hmi side: expect SDL.OnAppPermissionChanged
								
								
							end)
							:Timeout(2000)
							
							--mobile side: expect SystemRequest response
							EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
							:Do(function(_,data)
								--print("SystemRequest is received")
								--hmi side: sending SDL.GetUserFriendlyMessage request to SDL
								local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})
								
								--hmi side: expect SDL.GetUserFriendlyMessage response
								EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
								:Do(function(_,data)
									--print("SDL.GetUserFriendlyMessage is received")
									
									--hmi side: sending SDL.GetListOfPermissions request to SDL
									local RequestIdGetListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = self.applications["Test Application"]})
									
									-- hmi side: expect SDL.GetListOfPermissions response
									EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions,{result = {code = 0, method = "SDL.GetListOfPermissions", allowedFunctions = {{ id = 193465391, name = "New"}}}})
									:Do(function(_,data)
										--print("SDL.GetListOfPermissions response is received")
										
										--hmi side: sending SDL.OnAppPermissionConsent
										self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = true, id = 193465391, name = "New"}}, source = "GUI"})
										end)
								end)
							end)
							:Timeout(2000)
							
						end)
					end)
				end
				-------------------------------------------------------------------------------------------------------------------------------------
				--Begin Test Case ResultCodeCheck.8.1
				--Description: General resultCode is SUCCESS if one of personal resultCode of parameter is SUCCESS and another is DISALLOWED by policy
				function Test: PreCondition_Subscribe_prndl()					
					self:subscribeVehicleDataSuccess({"prndl"})					
					
				end
				
				function Test:UnsubscribeVehicleData_SuccessAndDisallowed()
					--mobile side: sending UnsubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																				{
																					prndl = true,
																					speed = true
																				})					
										
					--hmi side: expect UnsubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{
																		prndl = true
																	})	
					--UPDATED
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.UnsubscribeVehicleData response						
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {speed= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_PRNDL"}})	
					end)		
					
					--mobile side: expect UnsubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", 
											prndl= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_PRNDL"},
											speed= {resultCode = "DISALLOWED", dataType = "VEHICLEDATA_SPEED"},
											info = "'speed' is disallowed by policies"})	

					--mobile side: expect OnHashChange notification is sent to mobile
					EXPECT_NOTIFICATION("OnHashChange")
				end
			--End Test Case ResultCodeCheck.8.1
			------------------------------------------------------------------------------------------------------
			--Begin Test Case ResultCodeCheck.8.2
				--Description: General resultCode is SUCCESS if one personal resultCode of parameter is "DATA_NOT_SUBSCRIBED" and another is "SUCCESS".
				
				function Test: PreCondition_Subscribe_prndl()					
					self:subscribeVehicleDataSuccess({"prndl"})					
					
				end
				
				function Test:UnsubscribeVehicleData_SuccessAndDataNotSubscribed()
					--mobile side: sending UnsubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																				{
																					prndl = true,
																					rpm = true
																				})					
										
					--hmi side: expect UnsubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{
																		prndl = true,
																		rpm = true
																	})					
					
					--mobile side: expect UnsubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", 
											prndl= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_PRNDL"},
											rpm= {resultCode = "DATA_NOT_SUBSCRIBED", dataType = "VEHICLEDATA_RPM"}})	
						
					--mobile side: expect OnHashChange notification is sent to mobile
					EXPECT_NOTIFICATION("OnHashChange")
				end
			--End Test case ResultCodeCheck.8.2
				
		--End Test case ResultCodeCheck.8
		end
	
	--ToDo: Shall be uncommented when APPLINK-25363: "[Genivi]Service ID for endpoints are incorrectly written in DB after ignition off/on" is fixed
	--Task_APPLINK_15934()
	
	--End Test suit ResultCodeCheck

----------------------------------------------------------------------------------------------
-----------------------------------------V TEST BLOCK-----------------------------------------
---------------------------------------HMI negative cases-------------------------------------
----------------------------------------------------------------------------------------------
	--------Checks-----------
	-- requests without responses from HMI
	-- invalid structure of response
	-- several responses from HMI to one request
	-- fake parameters
	-- HMI correlation id check 
	-- wrong response with correct HMI id

	--Begin Test suit HMINegativeCheck
	--Description: Check processing responses with invalid structure, fake parameters, HMI correlation id check, wrong response with correct HMI correlation id, check sdl behaviour in case of absence the response from HMI

		--Begin Test case HMINegativeCheck.1
		--Description: 
			-- Check SDL behaviour in case of absence of responses from HMI
			commonFunctions:newTestCasesGroup("HMINegativeCheck.1")
			--Requirement id in JAMA:
				--SDLAQ-CRS-603
				--APPLINK-8585				
			
			--Verification criteria:
				-- SDL must return GENERIC_ERROR result to mobile app in case one of HMI components does not respond being supported and active.

			--ToDo: Shall be uncommented when APPLINK-25363: "[Genivi]Service ID for endpoints are incorrectly written in DB after ignition off/on" is fixed
			--and Task_APPLINK_15934() is run
			-- function Test:PreCondition_SubscribeVehicleData()				
			-- 	self:subscribeVehicleDataSuccess({"gps"})				
			-- end
			function Test:UnsubscribeVehicleData_NoResponseFromHMI()
				--mobile side: sending UnsubscribeVehicleData request
				local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																			{
																				gps = true
																			})					
									
				
				--hmi side: expect UnsubscribeVehicleData request
				EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{
																	gps = true
																})					
				:Do(function(_,data)
					--hmi side: sending VehicleInfo.UnsubscribeVehicleData response						
					
				end)
				
				--mobile side: expect UnsubscribeVehicleData response
				EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR"})
				:Timeout(12000)
				
				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
			end
		--End Test case HMINegativeCheck.1	
		
		-----------------------------------------------------------------------------------------
--[[TODO: update according to APPLINK-14765
		--Begin Test case HMINegativeCheck.2
		--Description: 
			-- Check processing responses with invalid structure

			--Requirement id in JAMA:
				--SDLAQ-CRS-94
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The corresponding parameters sent within the request are returned with the data about unsubscription.  
			function Test:PreCondition_SubscribeVehicleData()				
				self:subscribeVehicleDataSuccess({"speed"})
				
			end
			function Test:UnsubscribeVehicleData_ResponseInvalidStructure()
				--mobile side: sending UnsubscribeVehicleData request
				local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																			{
																				speed = true
																			})					
									
				
				--hmi side: expect UnsubscribeVehicleData request
				EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{
																	speed = true
																})					
				:Do(function(_,data)
					--hmi side: sending VehicleInfo.UnsubscribeVehicleData response						
					--Correct structure:self.hmiConnection:Send('"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"speed":{"dataType":"VEHICLEDATA_SPEED","resultCode":"SUCCESS"},"code":0, "method":"VehicleInfo.UnsubscribeVehicleData"}}')
					self.hmiConnection:Send('"id":'..tostring(data.id)..',"jsonrpc":"2.0","code":0,"result":{"speed":{"dataType":"VEHICLEDATA_SPEED","resultCode":"SUCCESS"},"method":"VehicleInfo.UnsubscribeVehicleData"}}')					
				end)
					
				--mobile side: expect UnsubscribeVehicleData response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
				:Timeout(12000)
				
				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
			end						
		--End Test case HMINegativeCheck.2
]]		
		-----------------------------------------------------------------------------------------
	
		--Begin Test case HMINegativeCheck.3
		--Description: 
			-- Several response to one request
			commonFunctions:newTestCasesGroup("HMINegativeCheck.3")
			--Requirement id in JAMA:
				--SDLAQ-CRS-94
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
			
			--ToDo: Shall be uncommented when APPLINK-25363: "[Genivi]Service ID for endpoints are incorrectly written in DB after ignition off/on" is fixed
			--and Task_APPLINK_15934() is run
			-- function Test:PreCondition_SubscribeVehicleData()				
			-- 	self:subscribeVehicleDataSuccess({"speed"})				
			-- end

			function Test:UnsubscribeVehicleData_SeveralResponseToOneRequest()
				--mobile side: sending UnsubscribeVehicleData request
				local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																			{
																				speed = true
																			})
				
				--hmi side: expect UnsubscribeVehicleData request
				EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{speed = true})					
				:Do(function(_,data)
					--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {speed= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"}})	
					self.hmiConnection:SendResponse(data.id, data.method, "REJECTED", {speed= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"}})	
					self.hmiConnection:SendResponse(data.id, data.method, "GENERIC_ERROR", {speed= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"}})	
				end)
				
				--mobile side: expect UnsubscribeVehicleData response
				EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", speed= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"}})
				
				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
			end
		--End Test case HMINegativeCheck.3
		
		-----------------------------------------------------------------------------------------

		--Begin Test case HMINegativeCheck.4
		--Description: 
			-- Check processing response with fake parameters
			commonFunctions:newTestCasesGroup("HMINegativeCheck.4")
			--Requirement id in JAMA:
				--SDLAQ-CRS-94
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
			
			--Begin Test case HMINegativeCheck.4.1
			--Description: Parameter not from API
				function Test:PreCondition_SubscribeVehicleData()				
					self:subscribeVehicleDataSuccess({"gps"})					
				end			
				function Test:UnsubscribeVehicleData_FakeParamsInResponse()
					--mobile side: sending UnsubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																				{
																					gps = true
																				})
					
					--hmi side: expect UnsubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {fake = "fakeParams", gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})							
					end)
					
					--mobile side: expect UnsubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})				
					:ValidIf (function(_,data)
			    		if data.payload.fake then
			    			print(" SDL resend fake parameter to mobile app ")
			    			return false
			    		else 
			    			return true
			    		end
			    	end)
					
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end
			--End Test case HMINegativeCheck.4.1
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case HMINegativeCheck.4.2
			--Description: Parameter from another API
				function Test:PreCondition_SubscribeVehicleData()				
					self:subscribeVehicleDataSuccess({"gps"})					
				end			
				function Test:UnsubscribeVehicleData_ParamsFromOtherAPIInResponse()
					--mobile side: sending UnsubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																				{
																					gps = true
																				})
					
					--hmi side: expect UnsubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 5, gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})							
					end)
					
					--mobile side: expect UnsubscribeVehicleData response
					EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})				
					:ValidIf (function(_,data)
			    		if data.payload.sliderPosition then
			    			print(" SDL resend fake parameter to mobile app ")
			    			return false
			    		else 
			    			return true
			    		end
			    	end)
					
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end
			--End Test case HMINegativeCheck.4.2			
		--End Test case HMINegativeCheck.4
		
		-----------------------------------------------------------------------------------------
	
		--Begin Test case HMINegativeCheck.5
		--Description: 
			-- Wrong response with correct HMI correlation id
			commonFunctions:newTestCasesGroup("HMINegativeCheck.5")
			--Requirement id in JAMA:
				--SDLAQ-CRS-94
				
			--Verification criteria:
				--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.			
			function Test:PreCondition_SubscribeVehicleData()				
				self:subscribeVehicleDataSuccess({"gps"})				
			end			
			function Test:UnsubscribeVehicleData_WrongResponseToCorrectID()
				--mobile side: sending UnsubscribeVehicleData request
				local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																			{
																				gps = true
																			})
				
				--hmi side: expect UnsubscribeVehicleData request
				EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{gps = true})					
				:Do(function(_,data)
					--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
					self.hmiConnection:SendResponse(data.id, "UI.AddCommand", "SUCCESS", {gps= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_GPS"}})							
				end)					
					
				--mobile side: expect UnsubscribeVehicleData response
				EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
				:Timeout(12000)
				
				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
			end
		--End Test case HMINegativeCheck.5		
	--End Test suit HMINegativeCheck		
-----------------------------------------VI TEST BLOCK----------------------------------------
-------------------------Sequence with emulating of user's action(s)------------------------
----------------------------------------------------------------------------------------------
	--Begin Test suit SequenceCheck
	
	-- Begin Test case SequenceCheck.1
	-- CRQ: APPLINK-24201
	-- Description: Check allowance of parameters in Policies
		commonFunctions:newTestCasesGroup("Test Suite for coverage of APPLINK-24201")
	local function UnsubscribeVehicleData_PoliciesAllowanceChecking()
	
		function Test:PreCondition_SubscribeVehicleData_AllowedAllParams()				
			self:subscribeVehicleDataSuccess(allVehicleData)
		end
		
		-- Requirement: APPLINK-21166 
		-- Description: Parameters is empty
		commonFunctions:newTestCasesGroup("PoliciesAllowanceChecking.1: Parameters are emtpy at Base4 in Polices")
		local PermissionLines_ParametersIsEmpty = 
			[[					
				"UnsubscribeVehicleData": {
					"hmi_levels": [
						"BACKGROUND",
						"FULL",
						"LIMITED"
					],
					"parameters": [

					]
				}
			]]
		local PermissionLinesForApp1=
			[[			"]].."0000001" ..[[":{
					"keep_context": true,
					"steal_focus": true,
					"priority": "NONE",
					"default_hmi": "BACKGROUND",
					"groups": ["Base-4"]
				}
			]]	
		local PermissionLinesForBase4 = PermissionLines_ParametersIsEmpty .. ", \n" 
		local PermissionLinesForGroup1 = nil
		local PermissionLinesForApplication = PermissionLinesForApp1.. ", \n"
		local PTName = testCasesForPolicyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication)	
		testCasesForPolicyTable:updatePolicy(PTName, nil, "UpdatePolicy_UnsubscribeVehicleData_WithEmptyParameters")
		
		-- SDL responds "DISALLOWED", info = "Requested parameters are disallowed by Policies" when parameter is empty in Policies
		function Test:UnsubscribeVehicleData_EmptyParameters_InBase4()
			
			local request = setUSVDRequest(allVehicleData)
			--mobile side: sending UnsubscribeVehicleData request
			local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",request)
			
			--hmi side: expect UnsubscribeVehicleData request
			EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{})
			:Times(0)	
			
			EXPECT_RESPONSE(cid, {  success = false, resultCode = "DISALLOWED", info = "Requested parameters are disallowed by Policies"})
			commonTestCases:DelayedExp(1000)
		
		end
		-------------------------------------------------------------------------------------------------------------
		
		-- RequirementID: APPLINK-20034
		-- Description: "myKey" is not present in Base4 and other presents in Base 4
		commonFunctions:newTestCasesGroup("PoliciesAllowanceChecking.2: 1 param is disallowed at Base 4 in Policies")
		local PermissionLines_SubscribeVehicleData_DisallowedMyKey = 
			[[				
				"SubscribeVehicleData": {
					"hmi_levels": [
						"BACKGROUND",
						"FULL",
						"LIMITED"
				],
					"parameters": [
						"gps", "speed", "rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption",
						"externalTemperature", "prndl", "tirePressure", "odometer", "beltStatus", "bodyInformation",
						"deviceStatus", "driverBraking", "wiperStatus", "headLampStatus", "engineTorque", "accPedalPosition",
						"steeringWheelAngle", "eCallInfo", "airbagStatus", "emergencyEvent", "clusterModeStatus","abs_State", "turnSignal", "fuelRange", "tirePressureValue", "tpms" 
					]
				}
			]]
		local PermissionLines_UnsubscribeVehicleData_DisallowedMyKey = 
			[[					
				"UnsubscribeVehicleData": {
					"hmi_levels": [
						"BACKGROUND",
						"FULL",
						"LIMITED"
					],
					"parameters": [
						"gps", "speed", "rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption",
						"externalTemperature", "prndl", "tirePressure", "odometer", "beltStatus", "bodyInformation",
						"deviceStatus", "driverBraking", "wiperStatus", "headLampStatus", "engineTorque", "accPedalPosition",
						"steeringWheelAngle", "eCallInfo", "airbagStatus", "emergencyEvent", "clusterModeStatus","abs_State", "turnSignal", "fuelRange", "tirePressureValue", "tpms" 
					]
				}
			]]
		local PermissionLinesForApp1=
			[[			"]].."0000001" ..[[":{
							"keep_context": true,
							"steal_focus": true,
							"priority": "NONE",
							"default_hmi": "BACKGROUND",
							"groups": ["Base-4"]
						}
			]]	
		local PermissionLinesForBase4 = PermissionLines_SubscribeVehicleData_DisallowedMyKey .. ", \n" .. PermissionLines_UnsubscribeVehicleData_DisallowedMyKey ..", \n"
		local PermissionLinesForGroup1 = nil
		local PermissionLinesForApplication = PermissionLinesForApp1.. ", \n"
		local PTName = testCasesForPolicyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication)
		testCasesForPolicyTable:updatePolicy(PTName, nil, "UpdatePolicy_UnsubscribeVehicleData_InBase4_WithDisallowedMyKey")
		
		-- SDL responds "DISALLOWED" with info when send UnsubscribeVehicleData request with only one disallowed param in Base4 by Policies.
		local Request = {myKey = true}
		function Test:UnsubscribeVehicleData_InBase4_WithOnlyOneDisallowedParam()
			
			--mobile side: sending the request
			local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData", Request)									
			--hmi side: not expect VehicleInfo.UnsubscribeVehicleData
			EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData", {})				
			:Times(0)																
			--mobile side: expect response 
			EXPECT_RESPONSE(cid, {resultCode = "DISALLOWED", info = "Requested parameters are disallowed by Policies",  success = false})
			commonTestCases:DelayedExp(1000)
			
		end	

		 -- SDL responds "SUCCESS" when send UnsubscribeVehicleData request with some allowed params in Base4 by Policies.
		local AllVehicleParams_InBase4_Without_MyKey = {"gps", "speed", "rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption", "externalTemperature", "prndl", "tirePressure", "odometer", "beltStatus", "bodyInformation", "deviceStatus", "driverBraking", "wiperStatus", "headLampStatus", "engineTorque", "accPedalPosition", "steeringWheelAngle", "eCallInfo", "airbagStatus", "emergencyEvent", "clusterModeStatus", "abs_State", "turnSignal", "fuelRange", "tirePressureValue", "tpms"}
		
		function Test:UnsubscribeVehicleData_AllVehicleParams_InBase4_Without_MyKey() 				
			self:unsubscribeVehicleDataSuccess(AllVehicleParams_InBase4_Without_MyKey)				
		end
		
		function Test:PostCondition_SubscribeVehicleData_AllVehicleParams_InBase4_Without_MyKey1()				
			self:subscribeVehicleDataSuccess(AllVehicleParams_InBase4_Without_MyKey)
		end
		
		-- SDL responds "SUCCESS" with info about disallowed param (myKey) for UnsubscribeVehicleData request with allowed params and 1 disallowed param.
		function Test:UnsubscribeVehicleData_InBase4_WithAllowedParams_DisallowedMyKey()
		
			local request_FromApp = setUSVDRequest(allVehicleData)
			
			local request_HMIExpect = setUSVDRequest(AllVehicleParams_InBase4_Without_MyKey)
			
			local response = setUSVDResponse(AllVehicleParams_InBase4_Without_MyKey)
			
			--mobile side: sending UnsubscribeVehicleData request
			local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",request_FromApp)
		
			--hmi side: expect UnsubscribeVehicleData request
			EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",request_HMIExpect)
			:Do(function(_,data)
				--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)	
			end)
			:ValidIf(function(_,data)
					if data.params.myKey then
						commonFunctions:userPrint(31,"VehicleInfo.UnsubscribeVehicleData contain myKey parameter in request when should be omitted")
						return false
					else
						return true
					end
				end)
			--mobile side: expect SubscribeVehicleData response
			EXPECT_RESPONSE(cid, 
					{
						success = true, 
						info = "'myKey' is disallowed by policies", 
						resultCode = "SUCCESS",
						
						odometer={resultCode="SUCCESS",dataType="VEHICLEDATA_ODOMETER"},
						accPedalPosition={resultCode="SUCCESS",dataType = "VEHICLEDATA_ACCPEDAL"},
						airbagStatus={resultCode="SUCCESS",dataType="VEHICLEDATA_AIRBAGSTATUS"},
						fuelRange={resultCode= "SUCCESS",dataType="VEHICLEDATA_FUELRANGE"},
						tirePressure={resultCode = "SUCCESS",dataType="VEHICLEDATA_TIREPRESSURE"},
						clusterModes = {resultCode= "SUCCESS",dataType="VEHICLEDATA_CLUSTERMODESTATUS"},
						tirePressureValue={resultCode="SUCCESS",dataType="VEHICLEDATA_TIREPRESSURE_VALUE"},
						fuelLevel={resultCode="SUCCESS",dataType="VEHICLEDATA_FUELLEVEL"},
						eCallInfo={resultCode="SUCCESS",dataType="VEHICLEDATA_ECALLINFO"},
						prndl={resultCode="SUCCESS",dataType="VEHICLEDATA_PRNDL"},
						steeringWheelAngle={resultCode="SUCCESS",dataType="VEHICLEDATA_STEERINGWHEEL"},
						turnSignal={resultCode="SUCCESS",dataType="VEHICLEDATA_TURNSIGNAL"},
						wiperStatus={resultCode="SUCCESS",dataType="VEHICLEDATA_WIPERSTATUS"},
						rpm={resultCode="SUCCESS",dataType="VEHICLEDATA_RPM"},
						tpms={resultCode="SUCCESS",dataType="VEHICLEDATA_TPMS"},
						abs_State={resultCode="SUCCESS",dataType="VEHICLEDATA_ABS_STATE"},
						speed={resultCode="SUCCESS",dataType="VEHICLEDATA_SPEED"},
						instantFuelConsumption={resultCode="SUCCESS",dataType="VEHICLEDATA_FUELCONSUMPTION"},
						myKey={resultCode="DISALLOWED",dataType="VEHICLEDATA_MYKEY"},
						deviceStatus={resultCode="SUCCESS",dataType="VEHICLEDATA_DEVICESTATUS"},
						headLampStatus={resultCode="SUCCESS",dataType="VEHICLEDATA_HEADLAMPSTATUS"},
						gps={resultCode="SUCCESS",dataType="VEHICLEDATA_GPS"},
						fuelLevel_State={resultCode="SUCCESS",dataType="VEHICLEDATA_FUELLEVEL_STATE"},
						engineTorque={resultCode="SUCCESS",dataType="VEHICLEDATA_ENGINETORQUE"},
						externalTemperature={resultCode="SUCCESS",dataType="VEHICLEDATA_EXTERNTEMP"},
						driverBraking={resultCode="SUCCESS",dataType="VEHICLEDATA_BRAKING"},
						bodyInformation={resultCode="SUCCESS",dataType="VEHICLEDATA_BODYINFO"},
						emergencyEvent={resultCode="SUCCESS",dataType="VEHICLEDATA_EMERGENCYEVENT"},
						beltStatus={resultCode="SUCCESS",dataType="VEHICLEDATA_BELTSTATUS"}
					})					
			
			--mobile side: expect OnHashChange notification
			EXPECT_NOTIFICATION("OnHashChange")
		end
		
		function Test:PostCondition_SubscribeVehicleData_AllVehicleParams_InBase4_Without_MyKey2()				
			self:subscribeVehicleDataSuccess(AllVehicleParams_InBase4_Without_MyKey)
		end
		-------------------------------------------------------------------------------------------------------------
		
		-- RequirementID: APPLINK-20034
		--TODO: expected result needs to update when APPLINK-26935 is DONE
		--Description: SubscribeVehicleData is present in Base4 with some allowed params and some disallowed params by policies.
	
		commonFunctions:newTestCasesGroup("PoliciesAllowanceChecking.2: Some params are disallowed at Base 4 in Policies")		
		local PermissionLines_SubscribeVehicleData_AllowedForBase4_SomeParams = 
			[[				
				"SubscribeVehicleData": {
					"hmi_levels": [
						"BACKGROUND",
						"FULL",
						"LIMITED"
					],
					"parameters": [	
						"gps", "speed", "rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption",
						"externalTemperature", "prndl", "tirePressure", "odometer", "beltStatus", "bodyInformation", "abs_State", "turnSignal", "fuelRange", "tirePressureValue", "tpms"						
					]
				}
			]]
		local PermissionLines_UnsubscribeVehicleDataAllowedForBase4_SomeParams = 
			[[				
				"UnsubscribeVehicleData": {
					"hmi_levels": [
						"BACKGROUND",
						"FULL",
						"LIMITED"
					],
					"parameters": [	
						"gps", "speed", "rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption",
						"externalTemperature", "prndl", "tirePressure", "odometer", "beltStatus", "bodyInformation", "abs_State", "turnSignal", "fuelRange", "tirePressureValue", "tpms"						
					]
				}
			]]
		local PermissionLinesForApp1=
			[[			"]].."0000001" ..[[":{
					"keep_context": true,
					"steal_focus": true,
					"priority": "NONE",
					"default_hmi": "BACKGROUND",
					"groups": ["Base-4"]
				}
			]]					  
		local PermissionLinesForBase4 = PermissionLines_SubscribeVehicleData_AllowedForBase4_SomeParams .. ", \n" .. PermissionLines_UnsubscribeVehicleDataAllowedForBase4_SomeParams ..", \n"
		local PermissionLinesForGroup1 = nil 
		local PermissionLinesForApplication = PermissionLinesForApp1 .. ", \n"
		local PTName = testCasesForPolicyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication)
		testCasesForPolicyTable:updatePolicy(PTName, nil, "UpdatePolicy_UnsubscribeVehicleData_DisallowedSomeParams_AllowBase4")
		
		
		local Request_WithDisallowedParams_InBase4 = {"deviceStatus", "driverBraking", "wiperStatus", "headLampStatus", "engineTorque", "accPedalPosition", "steeringWheelAngle", "eCallInfo", "airbagStatus", "emergencyEvent", "clusterModeStatus", "myKey"}
		local Request_WithAllowedParams_InBase4 = {"gps", "speed", "rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption",
								"externalTemperature", "prndl", "tirePressure", "odometer", "beltStatus", "bodyInformation","abs_State", "turnSignal", "fuelRange", "tirePressureValue", "tpms"}
								
		-- SDL responds "DISALLOWED" with info when send UnsubscribeVehicleData request with some disallowed parameters.
		function Test:UnsubscribeVehicleData_With_SomeDisallowedParams_Base4()
			--mobile side: sending UnsubscribeVehicleData request
			local request_FromApp = setUSVDRequest(Request_WithDisallowedParams_InBase4)
			local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData", request_FromApp)
		
			--hmi side: not expect VehicleInfo.UnsubscribeVehicleData
			EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData", {})
			:Times(0)
			
			--mobile side: expect response 
			EXPECT_RESPONSE(cid, {success = false, resultCode = "DISALLOWED", info = "Requested parameters are disallowed by Policies"})
			commonTestCases:DelayedExp(1000)
		
		end	
		
		-- SDL should respond "SUCCESS" with info of some disallowed params for UnsubscribeVehicleData request with some allowed parameters and some disallowed parameters by policies.
		function Test:UnsubscribeVehicleData_InBase4_With_SomeAllowedParams_And_SomeDisallowedParams()
		
			local request_FromApp = setUSVDRequest(allVehicleData)
			local request_HMIExpect = setUSVDRequest(Request_WithAllowedParams_InBase4)
			local response = setUSVDResponse(request_HMIExpect)
			
			--mobile side: sending UnsubscribeVehicleData request
			local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",request_FromApp)
		
			--hmi side: expect UnsubscribeVehicleData request
			EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",request_HMIExpect)
			:Do(function(_,data)
				--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)	
			end)
			:ValidIf(function(_,data)
					if data.params.deviceStatus or data.params.driverBraking or data.params.wiperStatus or data.params.headLampStatus or data.params.engineTorque or data.params.accPedalPosition or data.params.steeringWheelAngle or data.params.eCallInfo or data.params.airbagStatus or data.params.emergencyEvent or data.params.clusterModeStatus or data.params.myKey then
						commonFunctions:userPrint(31,"VehicleInfo.UnsubscribeVehicleData contain some parameters in request when should be omitted")
						return false
					else
						return true
					end
				end)
			--mobile side: expect UnsubscribeVehicleData response	
			
			EXPECT_RESPONSE(cid, 
					{
						success = true, 
						info = "'accPedalPosition', 'airbagStatus', 'clusterModeStatus', 'deviceStatus', 'driverBraking', 'eCallInfo', 'emergencyEvent', 'engineTorque', 'headLampStatus', 'myKey', 'steeringWheelAngle', 'wiperStatus' are disallowed by policies", 
						resultCode = "SUCCESS",
						
						wiperStatus={resultCode="DISALLOWED",dataType="VEHICLEDATA_WIPERSTATUS"},
						accPedalPosition={resultCode="DISALLOWED",dataType = "VEHICLEDATA_ACCPEDAL"},
						steeringWheelAngle={resultCode="DISALLOWED",dataType="VEHICLEDATA_STEERINGWHEEL"},
						headLampStatus={resultCode="DISALLOWED",dataType="VEHICLEDATA_HEADLAMPSTATUS"},
						deviceStatus={resultCode="DISALLOWED",dataType="VEHICLEDATA_DEVICESTATUS"},
						eCallInfo={resultCode="DISALLOWED",dataType="VEHICLEDATA_ECALLINFO"},
						airbagStatus={resultCode="DISALLOWED",dataType="VEHICLEDATA_AIRBAGSTATUS"},
						driverBraking={resultCode="DISALLOWED",dataType="VEHICLEDATA_BRAKING"},
						engineTorque={resultCode="DISALLOWED",dataType="VEHICLEDATA_ENGINETORQUE"},	
						myKey={resultCode="DISALLOWED",dataType="VEHICLEDATA_MYKEY"},
						clusterModes = {resultCode= "DISALLOWED",dataType="VEHICLEDATA_CLUSTERMODESTATUS"},
						emergencyEvent={resultCode="DISALLOWED",dataType="VEHICLEDATA_EMERGENCYEVENT"},
						
						gps={resultCode="SUCCESS",dataType="VEHICLEDATA_GPS"},
						speed={resultCode="SUCCESS",dataType="VEHICLEDATA_SPEED"},
						rpm={resultCode="SUCCESS",dataType="VEHICLEDATA_RPM"},
						fuelLevel={resultCode="SUCCESS",dataType="VEHICLEDATA_FUELLEVEL"},
						fuelLevel_State={resultCode="SUCCESS",dataType="VEHICLEDATA_FUELLEVEL_STATE"},
						instantFuelConsumption={resultCode="SUCCESS",dataType="VEHICLEDATA_FUELCONSUMPTION"},
						externalTemperature={resultCode="SUCCESS",dataType="VEHICLEDATA_EXTERNTEMP"},
						prndl={resultCode="SUCCESS",dataType="VEHICLEDATA_PRNDL"},
						tirePressure={resultCode = "SUCCESS",dataType="VEHICLEDATA_TIREPRESSURE"},
						odometer={resultCode="SUCCESS",dataType="VEHICLEDATA_ODOMETER"},
						bodyInformation={resultCode="SUCCESS",dataType="VEHICLEDATA_BODYINFO"},
						beltStatus={resultCode="SUCCESS",dataType="VEHICLEDATA_BELTSTATUS"},
						tpms={resultCode="SUCCESS",dataType="VEHICLEDATA_TPMS"},
						abs_State={resultCode="SUCCESS",dataType="VEHICLEDATA_ABS_STATE"},
						turnSignal={resultCode="SUCCESS",dataType="VEHICLEDATA_TURNSIGNAL"},
						tirePressureValue={resultCode="SUCCESS",dataType="VEHICLEDATA_TIREPRESSURE_VALUE"},
						fuelRange= {resultCode= "SUCCESS",dataType="VEHICLEDATA_FUELRANGE"}	
				})					
						
			--mobile side: expect OnHashChange notification
			EXPECT_NOTIFICATION("OnHashChange")
		end
		
		function Test:PostCondition_SubscribeVehicleData_WithSomeParams_AllowedInBase4()				
			self:subscribeVehicleDataSuccess(Request_WithAllowedParams_InBase4)
		end
		-------------------------------------------------------------------------------------------------------------
		
		-- RequirementID: APPLINK-19584 and APPLINK-23497
		-- TODO: expected result needs to update when APPLINK-26935 is DONE
		-- Description: UnsubscribeVehicleData with some params exists at Base4, group1 in Policies and some params are not presented in Policies.
	commonFunctions:newTestCasesGroup("PoliciesAllowanceChecking.2: Some params are in Base 4, Group1 and some params are disallowed in Policies")
		
		local PermissionLines_AllowedForBase4 = 
			[[				
				"SubscribeVehicleData": {
					"hmi_levels": [
						"BACKGROUND",
						"FULL",
						"LIMITED"
					],
					"parameters": [	
						"deviceStatus", "driverBraking", "wiperStatus", "headLampStatus", "engineTorque", "accPedalPosition", "steeringWheelAngle", "eCallInfo", "airbagStatus", "abs_State", "turnSignal", "fuelRange", "tirePressureValue", "tpms"			
					]
				},
				"UnsubscribeVehicleData": {
					"hmi_levels": [
						"BACKGROUND",
						"FULL",
						"LIMITED"
					],
					"parameters": [	
						"deviceStatus", "driverBraking", "wiperStatus", "headLampStatus", "engineTorque", "accPedalPosition", "steeringWheelAngle", "eCallInfo", "airbagStatus", "abs_State", "turnSignal", "fuelRange", "tirePressureValue", "tpms"		
					]
				}
			]]
		local PermissionLines_AllowedForGroup1 = 
			[[				
				"SubscribeVehicleData": {
					"hmi_levels": [
						"BACKGROUND",
						"FULL",
						"LIMITED"
					],
					"parameters": [		
						"gps", "speed", "rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption",
						"externalTemperature", "prndl"						
					]
				},
				"UnsubscribeVehicleData": {
					"hmi_levels": [
						"BACKGROUND",
						"FULL",
						"LIMITED"
					],
					"parameters": [		
						"gps", "speed", "rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption",
						"externalTemperature", "prndl"						
					]
				}
			]]

		local PermissionLinesForApp1=
			[[			"]].."0000001" ..[[":{
					"keep_context": true,
					"steal_focus": true,
					"priority": "NONE",
					"default_hmi": "BACKGROUND",
					"groups": ["group1","Base-4"]
				}
			]]	
				
		local PermissionLinesForBase4 = PermissionLines_AllowedForBase4 .. ", \n" 
		local PermissionLinesForGroup1 = PermissionLines_AllowedForGroup1  
		local PermissionLinesForApplication = PermissionLinesForApp1 ..", \n"
		local PTName = testCasesForPolicyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication)	
		testCasesForPolicyTable:updatePolicy(PTName, nil, "UpdatePolicy_UnsubscribeVehicleData_PresentGroup1AndBase4_AssignedToApp")
		
		local Request_WithParams_InBase4 = {"deviceStatus", "driverBraking", "wiperStatus", "headLampStatus", "engineTorque", "accPedalPosition", "steeringWheelAngle", "eCallInfo", "airbagStatus", "abs_State", "turnSignal", "fuelRange", "tirePressureValue", "tpms"}
		local Request_WithParams_InGroup1 = {"gps", "speed", "rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption",
								"externalTemperature", "prndl"}
		local Request_WithParams_NotPresented = {"emergencyEvent", "clusterModeStatus", "myKey", "tirePressure", "odometer", "beltStatus", "bodyInformation"}	
		
		-- RequirementID: APPLINK-19318
		-- SDL responds "DISALLOWED" when send UnsubscribeVehicleData request with disallowed params in un-consent group
		function Test:UnsubscribeVehicleData_ParamsInGroup1_User_Not_Answer_Consent()
		
			--mobile side: sending UnsubscribeVehicleData request
			local request_FromApp = setUSVDRequest(Request_WithParams_InGroup1)
			local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData", request_FromApp)					

			--hmi side: not expect VehicleInfo.UnsubscribeVehicleData
			EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData", {})
			:Times(0)
			--mobile side: expect UnsubscribeVehicleData response
			EXPECT_RESPONSE(cid, {success = false, resultCode = "DISALLOWED", info = "Requested parameters are disallowed by Policies"})
			commonTestCases:DelayedExp(1000)
		
		end
		-- SDL responds "SUCCESS" when sending UnsubscribeVehicleData with allowed params in Base4 when user answer NO for consent.
		function Test:UnsubscribeVehicleData_WithAllowedParamsInBase4_UserAnswerNoForConsent()				
				self:unsubscribeVehicleDataSuccess(Request_WithParams_InBase4)
			end
		function Test:PostCondition_SubscribeVehicleData_WithAllowedParamsInBase4_UserAnswerNoForConsent()				
			self:subscribeVehicleDataSuccess(Request_WithParams_InBase4)
		end
		-- SDL responds "SUCCESS" with info about disallowed params when send UnsubscribeVehicleData with allowed params in Base4 and params in group1 when user does not answer consent for group1.
		local Request_ParamsInBase4_ParamInGroup1 = {"deviceStatus", "driverBraking", "wiperStatus", "headLampStatus", "engineTorque", "accPedalPosition", "steeringWheelAngle", "eCallInfo", "airbagStatus", "abs_State", "turnSignal", "fuelRange", "tirePressureValue", "tpms", "gps", "speed", "rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption",
								"externalTemperature", "prndl"}
		function Test:UnsubscribeVehicleData_AllowedParamsInBase4_NotAnswerForUserConsentForGroup1()

			local request_FromApp = setUSVDRequest(Request_ParamsInBase4_ParamInGroup1)
			local request_HMIExpect = setUSVDRequest(Request_WithParams_InBase4)
			local response = setUSVDResponse(Request_WithParams_InBase4)
			--mobile side: sending UnsubscribeVehicleData request
			local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",request_FromApp)
		
			--hmi side: expect UnsubscribeVehicleData request
			EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",request_HMIExpect)
			:Do(function(_,data)
				--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)	
			end)
			:ValidIf(function(_,data)
					if data.params.gps or data.params.speed or data.params.rpm or data.params.fuelLevel or data.params.fuelLevel_State or data.params.instantFuelConsumption or data.params.externalTemperature or data.params.prndl then
						commonFunctions:userPrint(31,"VehicleInfo.UnsubscribeVehicleData contain some parameters in request when should be omitted")
						return false
					else
						return true
					end
				end)
				
			--mobile side: expect UnsubscribeVehicleData response	
			EXPECT_RESPONSE(cid, 
					{	
						success = true, 
						info = "'externalTemperature', 'fuelLevel', 'fuelLevel_State', 'gps', 'instantFuelConsumption', 'prndl', 'rpm', 'speed' are disallowed by policies", 
						resultCode = "SUCCESS",
						
						gps={resultCode="DISALLOWED",dataType="VEHICLEDATA_GPS"},
						speed={resultCode="DISALLOWED",dataType="VEHICLEDATA_SPEED"},
						rpm={resultCode="DISALLOWED",dataType="VEHICLEDATA_RPM"},
						fuelLevel={resultCode="DISALLOWED",dataType="VEHICLEDATA_FUELLEVEL"},
						fuelLevel_State={resultCode="DISALLOWED",dataType="VEHICLEDATA_FUELLEVEL_STATE"},
						instantFuelConsumption={resultCode="DISALLOWED",dataType="VEHICLEDATA_FUELCONSUMPTION"},
						externalTemperature={resultCode="DISALLOWED",dataType="VEHICLEDATA_EXTERNTEMP"},
						prndl={resultCode="DISALLOWED",dataType="VEHICLEDATA_PRNDL"},
						
						deviceStatus={resultCode="SUCCESS",dataType="VEHICLEDATA_DEVICESTATUS"},
						driverBraking={resultCode="SUCCESS",dataType="VEHICLEDATA_BRAKING"},
						wiperStatus={resultCode="SUCCESS",dataType="VEHICLEDATA_WIPERSTATUS"},
						headLampStatus={resultCode="SUCCESS",dataType="VEHICLEDATA_HEADLAMPSTATUS"},
						engineTorque={resultCode="SUCCESS",dataType="VEHICLEDATA_ENGINETORQUE"},									
						accPedalPosition={resultCode="SUCCESS",dataType = "VEHICLEDATA_ACCPEDAL"},
						steeringWheelAngle={resultCode="SUCCESS",dataType="VEHICLEDATA_STEERINGWHEEL"},
						eCallInfo={resultCode="SUCCESS",dataType="VEHICLEDATA_ECALLINFO"},
						airbagStatus={resultCode="SUCCESS",dataType="VEHICLEDATA_AIRBAGSTATUS"},
						abs_State={resultCode="SUCCESS",dataType="VEHICLEDATA_ABS_STATE"},
						turnSignal={resultCode="SUCCESS",dataType="VEHICLEDATA_TURNSIGNAL"},
						fuelRange= {resultCode= "SUCCESS",dataType="VEHICLEDATA_FUELRANGE"}	,
						tirePressureValue={resultCode="SUCCESS",dataType="VEHICLEDATA_TIREPRESSURE_VALUE"},
						tpms={resultCode="SUCCESS",dataType="VEHICLEDATA_TPMS"}
					})					
			--mobile side: expect OnHashChange notification
			EXPECT_NOTIFICATION("OnHashChange")
		end
		
		function Test:PostCondition_SubscribeVehicleData_AllowedParamsInBase4_1()				
			self:subscribeVehicleDataSuccess(Request_WithParams_InBase4)
		end
		
		-- SDL responds SUCCESS with info about disallowed params when send UnsubscribeVehicleData with allowed params in Base4, disallowed params by policies and params in group1 when user does not answer consent for group1.
		function Test:UnsubscribeVehicleData_AllowedParamsBase4_ParamsNotPresentedInPolicies_NotAnswerForConsentGroup1()
			local request_FromApp = setUSVDRequest(allVehicleData)
			local request_HMIExpect = setUSVDRequest(Request_WithParams_InBase4)
			local response = setUSVDResponse(Request_WithParams_InBase4)
			--mobile side: sending UnsubscribeVehicleData request
			local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",request_FromApp)
		
			--hmi side: expect UnsubscribeVehicleData request
			EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",request_HMIExpect)
			:Do(function(_,data)
				--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)	
			end)
			:ValidIf(function(_,data)
					if data.params.gps or data.params.speed or data.params.rpm or data.params.fuelLevel or data.params.fuelLevel_State or data.params.instantFuelConsumption or data.params.externalTemperature or data.params.prndl  or data.params.emergencyEvent or data.params.clusterModeStatus or data.params.myKey or data.params.tirePressure or data.params.odometer or data.params.beltStatus or data.params.bodyInformation then
						commonFunctions:userPrint(31,"VehicleInfo.UnsubscribeVehicleData contain some parameters in request when should be omitted")
						return false
					else
						return true
					end
				end)
			--mobile side: expect UnsubscribeVehicleData response		
			EXPECT_RESPONSE(cid, 
					{
						success = true, 
						info = "'beltStatus', 'bodyInformation', 'clusterModeStatus', 'emergencyEvent', 'externalTemperature', 'fuelLevel', 'fuelLevel_State', 'gps', 'instantFuelConsumption', 'myKey', 'odometer', 'prndl', 'rpm', 'speed', 'tirePressure' are disallowed by policies", 
						resultCode = "SUCCESS",
						gps={resultCode="DISALLOWED",dataType="VEHICLEDATA_GPS"},
						speed={resultCode="DISALLOWED",dataType="VEHICLEDATA_SPEED"},
						rpm={resultCode="DISALLOWED",dataType="VEHICLEDATA_RPM"},
						fuelLevel={resultCode="DISALLOWED",dataType="VEHICLEDATA_FUELLEVEL"},
						fuelLevel_State={resultCode="DISALLOWED",dataType="VEHICLEDATA_FUELLEVEL_STATE"},
						instantFuelConsumption={resultCode="DISALLOWED",dataType="VEHICLEDATA_FUELCONSUMPTION"},
						externalTemperature={resultCode="DISALLOWED",dataType="VEHICLEDATA_EXTERNTEMP"},
						prndl={resultCode="DISALLOWED",dataType="VEHICLEDATA_PRNDL"},
						emergencyEvent={resultCode="DISALLOWED",dataType="VEHICLEDATA_EMERGENCYEVENT"},
						clusterModes = {resultCode= "DISALLOWED",dataType="VEHICLEDATA_CLUSTERMODESTATUS"},
						myKey={resultCode="DISALLOWED",dataType="VEHICLEDATA_MYKEY"},
						tirePressure={resultCode = "DISALLOWED",dataType="VEHICLEDATA_TIREPRESSURE"},
						odometer={resultCode="DISALLOWED",dataType="VEHICLEDATA_ODOMETER"},
						beltStatus={resultCode="DISALLOWED",dataType="VEHICLEDATA_BELTSTATUS"},
						
						bodyInformation={resultCode="SUCCESS",dataType="VEHICLEDATA_BODYINFO"},
						deviceStatus={resultCode="SUCCESS",dataType="VEHICLEDATA_DEVICESTATUS"},
						driverBraking={resultCode="SUCCESS",dataType="VEHICLEDATA_BRAKING"},
						wiperStatus={resultCode="SUCCESS",dataType="VEHICLEDATA_WIPERSTATUS"},
						headLampStatus={resultCode="SUCCESS",dataType="VEHICLEDATA_HEADLAMPSTATUS"},
						engineTorque={resultCode="SUCCESS",dataType="VEHICLEDATA_ENGINETORQUE"},									
						accPedalPosition={resultCode="SUCCESS",dataType = "VEHICLEDATA_ACCPEDAL"},
						steeringWheelAngle={resultCode="SUCCESS",dataType="VEHICLEDATA_STEERINGWHEEL"},
						eCallInfo={resultCode="SUCCESS",dataType="VEHICLEDATA_ECALLINFO"},
						airbagStatus={resultCode="SUCCESS",dataType="VEHICLEDATA_AIRBAGSTATUS"},
						abs_State={resultCode="SUCCESS",dataType="VEHICLEDATA_ABS_STATE"},
						turnSignal={resultCode="SUCCESS",dataType="VEHICLEDATA_TURNSIGNAL"},
						fuelRange= {resultCode= "SUCCESS",dataType="VEHICLEDATA_FUELRANGE"},	
						tirePressureValue={resultCode="SUCCESS",dataType="VEHICLEDATA_TIREPRESSURE_VALUE"},
						tpms={resultCode="SUCCESS",dataType="VEHICLEDATA_TPMS"}
				})					
			--mobile side: expect OnHashChange notification
			EXPECT_NOTIFICATION("OnHashChange")
		end
		
		function Test:PostCondition_SubscribeVehicleData_AllowedParamsInBase4_2()				
			self:subscribeVehicleDataSuccess(Request_WithParams_InBase4)
		end
		
		testCasesForPolicyTable:userConsent(false, "group1", "UserConsent_Answer_No")
		-- SDL responds "SUCCESS" when sending UnsubscribeVehicleData with allowed params in Base4 when user does not answer for consent.
		function Test:UnsubscribeVehicleData_WithAllowedParamsInBase4_UserNotAnswerForConsent()				
				self:unsubscribeVehicleDataSuccess(Request_WithParams_InBase4)
			end
		function Test:PostCondition_SubscribeVehicleData_WithAllowedParamsInBase4_UserNotAnswerForConsent()				
			self:subscribeVehicleDataSuccess(Request_WithParams_InBase4)
		end
		--RequirementID: APPLINK-19584 	
		--SDL responds "USER_DISALLOWED" with info when send UnsubscribeVehicleData with params are disallowed by user
		function Test:UnsubscribeVehicleData_ParamsInGroup1_User_Answer_NO()
				
			--mobile side: sending UnsubscribeVehicleData request
			local request_FromApp = setUSVDRequest(Request_WithParams_InGroup1)
			local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData", request_FromApp)					

			--hmi side: not expect VehicleInfo.UnsubscribeVehicleData
			EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData", {})
			:Times(0)
			--mobile side: expect UnsubscribeVehicleData response
			EXPECT_RESPONSE(cid, {success = false, resultCode = "USER_DISALLOWED", info = "RPC is disallowed by the user"})
			commonTestCases:DelayedExp(1000)
			
		end
		
		-- SDL responds "SUCCESS" with info about disallowed params when send UnsubscribeVehicleData with some params are allowed by Policies and some params are disallowed by User.
		function Test:UnsubscribeVehicleData_ParamsInBase4_ParamInGroup1_User_Answer_NO()

			local request_FromApp = setUSVDRequest(Request_ParamsInBase4_ParamInGroup1)
			local request_HMIExpect = setUSVDRequest(Request_WithParams_InBase4)
			local response = setUSVDResponse(Request_WithParams_InBase4)
			--mobile side: sending UnsubscribeVehicleData request
			local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",request_FromApp)
		
			--hmi side: expect UnsubscribeVehicleData request
			EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",request_HMIExpect)
			:Do(function(_,data)
				--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)	
			end)
			:ValidIf(function(_,data)
					if data.params.gps or data.params.speed or data.params.rpm or data.params.fuelLevel or data.params.fuelLevel_State or data.params.instantFuelConsumption or data.params.externalTemperature or data.params.prndl then
						commonFunctions:userPrint(31,"VehicleInfo.UnsubscribeVehicleData contain some parameters in request when should be omitted")
						return false
					else
						return true
					end
				end)
				
			--mobile side: expect UnsubscribeVehicleData response		
			EXPECT_RESPONSE(cid, 
						{	
							success = true,
							info = "'externalTemperature', 'fuelLevel', 'fuelLevel_State', 'gps', 'instantFuelConsumption', 'prndl', 'rpm', 'speed' are disallowed by user", 
							resultCode = "SUCCESS",	
							
							gps={resultCode="USER_DISALLOWED",dataType="VEHICLEDATA_GPS"},
							speed={resultCode="USER_DISALLOWED",dataType="VEHICLEDATA_SPEED"},
							rpm={resultCode="USER_DISALLOWED",dataType="VEHICLEDATA_RPM"},
							fuelLevel={resultCode="USER_DISALLOWED",dataType="VEHICLEDATA_FUELLEVEL"},
							fuelLevel_State={resultCode="USER_DISALLOWED",dataType="VEHICLEDATA_FUELLEVEL_STATE"},
							instantFuelConsumption={resultCode="USER_DISALLOWED",dataType="VEHICLEDATA_FUELCONSUMPTION"},
							externalTemperature={resultCode="USER_DISALLOWED",dataType="VEHICLEDATA_EXTERNTEMP"},
							prndl={resultCode="USER_DISALLOWED",dataType="VEHICLEDATA_PRNDL"},
							
							deviceStatus={resultCode="SUCCESS",dataType="VEHICLEDATA_DEVICESTATUS"},
							driverBraking={resultCode="SUCCESS",dataType="VEHICLEDATA_BRAKING"},
							wiperStatus={resultCode="SUCCESS",dataType="VEHICLEDATA_WIPERSTATUS"},
							headLampStatus={resultCode="SUCCESS",dataType="VEHICLEDATA_HEADLAMPSTATUS"},
							engineTorque={resultCode="SUCCESS",dataType="VEHICLEDATA_ENGINETORQUE"},									
							accPedalPosition={resultCode="SUCCESS",dataType = "VEHICLEDATA_ACCPEDAL"},
							steeringWheelAngle={resultCode="SUCCESS",dataType="VEHICLEDATA_STEERINGWHEEL"},
							eCallInfo={resultCode="SUCCESS",dataType="VEHICLEDATA_ECALLINFO"},
							airbagStatus={resultCode="SUCCESS",dataType="VEHICLEDATA_AIRBAGSTATUS"},
							abs_State={resultCode="SUCCESS",dataType="VEHICLEDATA_ABS_STATE"},
							turnSignal={resultCode="SUCCESS",dataType="VEHICLEDATA_TURNSIGNAL"},
							fuelRange= {resultCode= "SUCCESS",dataType="VEHICLEDATA_FUELRANGE"}	,
							tirePressureValue={resultCode="SUCCESS",dataType="VEHICLEDATA_TIREPRESSURE_VALUE"},
							tpms={resultCode="SUCCESS",dataType="VEHICLEDATA_TPMS"}
							
						})		
			--mobile side: expect OnHashChange notification
			EXPECT_NOTIFICATION("OnHashChange")
		end
		
		function Test:PostCondition_SubscribeVehicleData_AllowedParamsInBase4_3()				
			self:subscribeVehicleDataSuccess(Request_WithParams_InBase4)
		end
		
		-- RequirementID: APPLINK-19584 	
		-- SDL responds "DISALLOWED" when send UnsubscribeVehicleData with some params are disallowed by Policies and some params are disallowed by User. 
		-- Expected result is confirmed by question APPLINK-27002
		local Request_ParamsNotPresented_ParamInGroup1 = {"gps", "speed", "rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption",
								"externalTemperature", "prndl", "emergencyEvent", "clusterModeStatus", "myKey", "tirePressure", "odometer", "beltStatus", "bodyInformation"}
		function Test:UnsubscribeVehicleData_With_DisallowedParamsByPolicies_ParamInGroup1_UserAnswerNO()

			local request_FromApp = setUSVDRequest(Request_ParamsNotPresented_ParamInGroup1)
			local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData", request_FromApp)					

			--hmi side: not expect VehicleInfo.UnsubscribeVehicleData
			EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData", {})
			:Times(0)
			
			--mobile side: expect UnsubscribeVehicleData response		
			EXPECT_RESPONSE(cid, 
					{
						success = false, 
						resultCode = "DISALLOWED", 
						info = "'beltStatus', 'bodyInformation', 'clusterModeStatus', 'emergencyEvent', 'myKey', 'odometer', 'tirePressure' are disallowed by policies, 'externalTemperature', 'fuelLevel', 'fuelLevel_State', 'gps', 'instantFuelConsumption', 'prndl', 'rpm', 'speed' are disallowed by user",
						
						gps={resultCode="USER_DISALLOWED",dataType="VEHICLEDATA_GPS"},
						speed={resultCode="USER_DISALLOWED",dataType="VEHICLEDATA_SPEED"},
						rpm={resultCode="USER_DISALLOWED",dataType="VEHICLEDATA_RPM"},
						fuelLevel={resultCode="USER_DISALLOWED",dataType="VEHICLEDATA_FUELLEVEL"},
						fuelLevel_State={resultCode="USER_DISALLOWED",dataType="VEHICLEDATA_FUELLEVEL_STATE"},
						instantFuelConsumption={resultCode="USER_DISALLOWED",dataType="VEHICLEDATA_FUELCONSUMPTION"},
						externalTemperature={resultCode="USER_DISALLOWED",dataType="VEHICLEDATA_EXTERNTEMP"},
						prndl={resultCode="USER_DISALLOWED",dataType="VEHICLEDATA_PRNDL"},
						
						emergencyEvent={resultCode="DISALLOWED",dataType="VEHICLEDATA_EMERGENCYEVENT"},
						clusterModeStatus = {resultCode= "DISALLOWED",dataType="VEHICLEDATA_CLUSTERMODESTATUS"},
						myKey={resultCode="DISALLOWED",dataType="VEHICLEDATA_MYKEY"},
						tirePressure={resultCode = "DISALLOWED",dataType="VEHICLEDATA_TIREPRESSURE"},
						odometer={resultCode="DISALLOWED",dataType="VEHICLEDATA_ODOMETER"},
						beltStatus={resultCode="DISALLOWED",dataType="VEHICLEDATA_BELTSTATUS"},
						bodyInformation={resultCode="DISALLOWED",dataType="VEHICLEDATA_BODYINFO"},
						
					})
			
			commonTestCases:DelayedExp(1000)
				
		end
		
		-- SDL responds "SUCCESS" with info about disallowed params when send UnsubscribeVehicleData with some params are allowed, disallowed by Policies and some params are disallowed by User.
		function Test:UnsubscribeVehicleData_AlowedParamsInBase4_ParamsNotPresentedInPolicies_DisallowedParamsByUser()

			local request_FromApp = setUSVDRequest(allVehicleData)
			local request_HMIExpect = setUSVDRequest(Request_WithParams_InBase4)
			local response = setUSVDResponse(Request_WithParams_InBase4)
			--mobile side: sending UnsubscribeVehicleData request
			local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",request_FromApp)
		
			--hmi side: expect UnsubscribeVehicleData request
			EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",request_HMIExpect)
			:Do(function(_,data)
				--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)	
			end)
			:ValidIf(function(_,data)
					if data.params.gps or data.params.speed or data.params.rpm or data.params.fuelLevel or data.params.fuelLevel_State or data.params.instantFuelConsumption or data.params.externalTemperature or data.params.prndl or data.params.emergencyEvent or data.params.clusterModeStatus or data.params.myKey or data.params.tirePressure or data.params.odometer or data.params.beltStatus or data.params.bodyInformation then
						commonFunctions:userPrint(31,"VehicleInfo.UnsubscribeVehicleData contain some parameters in request when should be omitted")
						return false
					else
						return true
					end
				end)
				
			--mobile side: expect UnsubscribeVehicleData response			
			EXPECT_RESPONSE(cid, 
			{
				success = true, 
				info = "'beltStatus', 'bodyInformation', 'clusterModeStatus', 'emergencyEvent', 'myKey', 'odometer', 'tirePressure' are disallowed by policies, 'externalTemperature', 'fuelLevel', 'fuelLevel_State', 'gps', 'instantFuelConsumption', 'prndl', 'rpm', 'speed' are disallowed by user", 
				resultCode = "SUCCESS",
				
				gps={resultCode="USER_DISALLOWED",dataType="VEHICLEDATA_GPS"},
				speed={resultCode="USER_DISALLOWED",dataType="VEHICLEDATA_SPEED"},
				rpm={resultCode="USER_DISALLOWED",dataType="VEHICLEDATA_RPM"},
				fuelLevel={resultCode="USER_DISALLOWED",dataType="VEHICLEDATA_FUELLEVEL"},
				fuelLevel_State={resultCode="USER_DISALLOWED",dataType="VEHICLEDATA_FUELLEVEL_STATE"},
				instantFuelConsumption={resultCode="USER_DISALLOWED",dataType="VEHICLEDATA_FUELCONSUMPTION"},
				externalTemperature={resultCode="USER_DISALLOWED",dataType="VEHICLEDATA_EXTERNTEMP"},
				prndl={resultCode="USER_DISALLOWED",dataType="VEHICLEDATA_PRNDL"},
				
				emergencyEvent={resultCode="DISALLOWED",dataType="VEHICLEDATA_EMERGENCYEVENT"},
				clusterModeStatus = {resultCode= "DISALLOWED",dataType="VEHICLEDATA_CLUSTERMODESTATUS"},
				myKey={resultCode="DISALLOWED",dataType="VEHICLEDATA_MYKEY"},
				tirePressure={resultCode = "DISALLOWED",dataType="VEHICLEDATA_TIREPRESSURE"},
				odometer={resultCode="DISALLOWED",dataType="VEHICLEDATA_ODOMETER"},
				beltStatus={resultCode="DISALLOWED",dataType="VEHICLEDATA_BELTSTATUS"},
				bodyInformation={resultCode="DISALLOWED",dataType="VEHICLEDATA_BODYINFO"},
				
				deviceStatus={resultCode="SUCCESS",dataType="VEHICLEDATA_DEVICESTATUS"},
				driverBraking={resultCode="SUCCESS",dataType="VEHICLEDATA_BRAKING"},
				wiperStatus={resultCode="SUCCESS",dataType="VEHICLEDATA_WIPERSTATUS"},
				headLampStatus={resultCode="SUCCESS",dataType="VEHICLEDATA_HEADLAMPSTATUS"},
				engineTorque={resultCode="SUCCESS",dataType="VEHICLEDATA_ENGINETORQUE"},									
				accPedalPosition={resultCode="SUCCESS",dataType = "VEHICLEDATA_ACCPEDAL"},
				steeringWheelAngle={resultCode="SUCCESS",dataType="VEHICLEDATA_STEERINGWHEEL"},
				eCallInfo={resultCode="SUCCESS",dataType="VEHICLEDATA_ECALLINFO"},
				airbagStatus={resultCode="SUCCESS",dataType="VEHICLEDATA_AIRBAGSTATUS"},
				abs_State={resultCode="SUCCESS",dataType="VEHICLEDATA_ABS_STATE"},
				turnSignal={resultCode="SUCCESS",dataType="VEHICLEDATA_TURNSIGNAL"},
				fuelRange= {resultCode= "SUCCESS",dataType="VEHICLEDATA_FUELRANGE"}	,
				tirePressureValue={resultCode="SUCCESS",dataType="VEHICLEDATA_TIREPRESSURE_VALUE"},
				tpms={resultCode="SUCCESS",dataType="VEHICLEDATA_TPMS"}
			
			})			
			--mobile side: expect OnHashChange notification
			EXPECT_NOTIFICATION("OnHashChange")
		end
		
		function Test:PostCondition_SubscribeVehicleData_AllowedParamsInBase4_4()				
			self:subscribeVehicleDataSuccess(Request_WithParams_InBase4)
		end
		
		testCasesForPolicyTable:userConsent(true, "group1", "UserConsent_ANSWER_YES")
		
		-- RequirementID: APPLINK-19584
		-- SDL responds "SUCCESS" with info about disallowed params when send UnsubscribeVehicleData with some allowed params (in Base 4 and consent group) and disallowed params by policies		
		function Test:UnsubscribeVehicleData_AllowedParamsInBase4_ParamsNotPresentedInPolicies_AllowedParamsInGroup1()

			local request_FromApp = setUSVDRequest(allVehicleData)
			local request_HMIExpect = setUSVDRequest(Request_ParamsInBase4_ParamInGroup1)
			local response = setUSVDResponse(Request_ParamsInBase4_ParamInGroup1)
			--mobile side: sending UnsubscribeVehicleData request
			local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",request_FromApp)
		
			--hmi side: expect UnsubscribeVehicleData request
			EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",request_HMIExpect)
			:Do(function(_,data)
				--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)	
			end)
			:ValidIf(function(_,data)
					if data.params.emergencyEvent or data.params.clusterModeStatus or data.params.myKey or data.params.tirePressure or data.params.odometer or data.params.beltStatus or data.params.bodyInformation then
						commonFunctions:userPrint(31,"VehicleInfo.UnsubscribeVehicleData contain some parameters in request when should be omitted")
						return false
					else
						return true
					end
				end)
				
			--mobile side: expect UnsubscribeVehicleData response
					
			EXPECT_RESPONSE(cid,
					{
						success = true, 
						info = "'beltStatus', 'bodyInformation', 'clusterModeStatus', 'emergencyEvent', 'myKey', 'odometer', 'tirePressure' are disallowed by policies", 
						resultCode = "SUCCESS",
						
						gps={resultCode="SUCCESS",dataType="VEHICLEDATA_GPS"},
						speed={resultCode="SUCCESS",dataType="VEHICLEDATA_SPEED"},
						rpm={resultCode="SUCCESS",dataType="VEHICLEDATA_RPM"},
						fuelLevel={resultCode="SUCCESS",dataType="VEHICLEDATA_FUELLEVEL"},
						fuelLevel_State={resultCode="SUCCESS",dataType="VEHICLEDATA_FUELLEVEL_STATE"},
						instantFuelConsumption={resultCode="SUCCESS",dataType="VEHICLEDATA_FUELCONSUMPTION"},
						externalTemperature={resultCode="SUCCESS",dataType="VEHICLEDATA_EXTERNTEMP"},
						prndl={resultCode="SUCCESS",dataType="VEHICLEDATA_PRNDL"},
						
						emergencyEvent={resultCode="DISALLOWED",dataType="VEHICLEDATA_EMERGENCYEVENT"},
						clusterModeStatus = {resultCode= "DISALLOWED",dataType="VEHICLEDATA_CLUSTERMODESTATUS"},
						myKey={resultCode="DISALLOWED",dataType="VEHICLEDATA_MYKEY"},
						tirePressure={resultCode = "DISALLOWED",dataType="VEHICLEDATA_TIREPRESSURE"},
						odometer={resultCode="DISALLOWED",dataType="VEHICLEDATA_ODOMETER"},
						beltStatus={resultCode="DISALLOWED",dataType="VEHICLEDATA_BELTSTATUS"},
						bodyInformation={resultCode="DISALLOWED",dataType="VEHICLEDATA_BODYINFO"},
						
						deviceStatus={resultCode="SUCCESS",dataType="VEHICLEDATA_DEVICESTATUS"},
						driverBraking={resultCode="SUCCESS",dataType="VEHICLEDATA_BRAKING"},
						wiperStatus={resultCode="SUCCESS",dataType="VEHICLEDATA_WIPERSTATUS"},
						headLampStatus={resultCode="SUCCESS",dataType="VEHICLEDATA_HEADLAMPSTATUS"},
						engineTorque={resultCode="SUCCESS",dataType="VEHICLEDATA_ENGINETORQUE"},									
						accPedalPosition={resultCode="SUCCESS",dataType = "VEHICLEDATA_ACCPEDAL"},
						steeringWheelAngle={resultCode="SUCCESS",dataType="VEHICLEDATA_STEERINGWHEEL"},
						eCallInfo={resultCode="SUCCESS",dataType="VEHICLEDATA_ECALLINFO"},
						airbagStatus={resultCode="SUCCESS",dataType="VEHICLEDATA_AIRBAGSTATUS"},
						abs_State={resultCode="SUCCESS",dataType="VEHICLEDATA_ABS_STATE"},
						turnSignal={resultCode="SUCCESS",dataType="VEHICLEDATA_TURNSIGNAL"},
						fuelRange= {resultCode= "SUCCESS",dataType="VEHICLEDATA_FUELRANGE"}	,
						tirePressureValue={resultCode="SUCCESS",dataType="VEHICLEDATA_TIREPRESSURE_VALUE"},
						tpms={resultCode="SUCCESS",dataType="VEHICLEDATA_TPMS"}
						
					})			
			
			--mobile side: expect OnHashChange notification
			EXPECT_NOTIFICATION("OnHashChange")
		end
		
		function Test:PostCondition_SubscribeVehicleData_AllowedParamsInBase4_InGroup1()				
			self:subscribeVehicleDataSuccess(Request_ParamsInBase4_ParamInGroup1)
		end
		
		-- SDL responds "SUCCESS" for UnsubscribeVehicleData request with allowed params by user.
		
		function Test:UnsubscribeVehicleData_AllParamsInGroup1_UserAnswerYES()
			self:unsubscribeVehicleDataSuccess(Request_WithParams_InGroup1)
		end
		
		function Test:PostCondition_SubscribeVehicleData_AllParamsInGroup1()				
			self:subscribeVehicleDataSuccess(Request_WithParams_InGroup1)
		end
		
		-- SDL responds "SUCCESS" for UnsubscribeVehicleData request with allowed params by user and allowed params by policies
		function Test:UnsubscribeVehicleData_AllowedParamsBase4_ParamsInGroup1_UserAnswerYES()
			self:unsubscribeVehicleDataSuccess(Request_ParamsInBase4_ParamInGroup1)
		end
		
		function Test:PostCondition_AllowedParamsBase4_ParamsInGroup1_UserAnswerYES()				
			self:subscribeVehicleDataSuccess(Request_ParamsInBase4_ParamInGroup1)
		end
		-------------------------------------------------------------------------------------------------------------
		
		-- Description: All parameters are presented at Base4 in Policy
		commonFunctions:newTestCasesGroup("PoliciesAllowanceChecking.2: All params are in Base 4 and sallowed in Policies")
	
		local PermissionLines_AllParameters = 
			[[					
				"SubscribeVehicleData": {
					"hmi_levels": [
						"BACKGROUND",
						"FULL",
						"LIMITED"
				],
					"parameters": [
						"gps", "speed", "rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption",
						"externalTemperature", "prndl", "tirePressure", "odometer", "beltStatus", "bodyInformation",
						"deviceStatus", "driverBraking", "wiperStatus", "headLampStatus", "engineTorque", "accPedalPosition",
						"steeringWheelAngle", "eCallInfo", "airbagStatus", "emergencyEvent", "clusterModeStatus", "myKey", "abs_State", "turnSignal", "fuelRange", "tirePressureValue", "tpms"
					]
				},
				"UnsubscribeVehicleData": {
					"hmi_levels": [
						"BACKGROUND",
						"FULL",
						"LIMITED"
				],
					"parameters": [
						"gps", "speed", "rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption",
						"externalTemperature", "prndl", "tirePressure", "odometer", "beltStatus", "bodyInformation",
						"deviceStatus", "driverBraking", "wiperStatus", "headLampStatus", "engineTorque", "accPedalPosition",
						"steeringWheelAngle", "eCallInfo", "airbagStatus", "emergencyEvent", "clusterModeStatus", "myKey", "abs_State", "turnSignal", "fuelRange", "tirePressureValue", "tpms"
					]
				}
			]]
		local PermissionLinesForBase4 = PermissionLines_AllParameters .. ", \n" 
		local PermissionLinesForGroup1 = nil
		local PermissionLinesForApplication = nil
		local PTName = testCasesForPolicyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication)	
		
		testCasesForPolicyTable:updatePolicy(PTName, nil, "UpdatePolicy_UnsubscribeVehicleData_Base4_WithAllParams")
		
		-- SDL responds "SUCCESS" for UnsubscribeVehicleData request with allowed params by Policy.
		function Test:UnsubscribeVehicleData_AllowedAllParams()
			self:unsubscribeVehicleDataSuccess(allVehicleData)
		end
		
		function Test:PostCondition_SubscribeVehicleData_AllowedAllParams()				
			self:subscribeVehicleDataSuccess(allVehicleData)
		end
		-------------------------------------------------------------------------------------------------------------
		
		-- RequirementID: APPLINK-24224
		-- Description: All parameters are omitted on Policy. SDL must allow all parameter.
		commonFunctions:newTestCasesGroup("PoliciesAllowanceChecking.2: Parameters are omitted in Policies")
	
		local PermissionLines_OmittedParameters = 
			[[				
				"SubscribeVehicleData": {
					"hmi_levels": [
						"BACKGROUND",
						"FULL",
						"LIMITED"
					]
				},
				"UnsubscribeVehicleData": {
					"hmi_levels": [
						"BACKGROUND",
						"FULL",
						"LIMITED"
					]
				},
				"OnVehicleData" : {
					"hmi_levels" : ["BACKGROUND",
					"FULL",
					"LIMITED"],
					"parameters" : ["airbagStatus",
					"gps", 
					"speed",  
					"rpm", 
					"fuelLevel", 
					"fuelLevel_State", 
					"instantFuelConsumption", 
					"externalTemperature", 
					"prndl", 
					"tirePressure", 
					"odometer", 
					"beltStatus", 
					"bodyInformation", 
					"deviceStatus", 
					"driverBraking", 
					"wiperStatus", 
					"headLampStatus", 
					"engineTorque", 
					"accPedalPosition", 
					"steeringWheelAngle", 
					"eCallInfo", 
					"airbagStatus", 
					"emergencyEvent", 
					"clusterModeStatus", 
					"myKey",
					"fuelRange",
					"abs_State",
					"tirePressureValue",
					"tpms",
					"turnSignal"]
				}
			]]
		local PermissionLinesForBase4 = PermissionLines_OmittedParameters .. ", \n" 
		local PermissionLinesForGroup1 = nil
		local PermissionLinesForApplication = nil
		local PTName = testCasesForPolicyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication)	
		testCasesForPolicyTable:updatePolicy(PTName, nil, "UpdatePolicy_UnsubscribeVehicleData_OmittedAllParam")
		
		-- SDL responds "SUCCESS" for UnsubscribeVehicleData request when parameters are committed in policy
		function Test:UnsubscribeVehicleDataSuccess_OmitedAllParams_InBase4()
			self:unsubscribeVehicleDataSuccess(allVehicleData)
		end
		
		function Test:PostCondition_SubscribeVehicleData_OmitedAllParams_InBase4()				
			self:subscribeVehicleDataSuccess(allVehicleData)
		end
		-------------------------------------------------------------------------------------------------------------
		
		commonFunctions:newTestCasesGroup("End Test Suite for coverage of APPLINK-24201")
	end
	UnsubscribeVehicleData_PoliciesAllowanceChecking()
	
	--Description: TC's checks SDL behaviour by processing
		-- different request sequence with timeout
		-- with emulating of user's actions
		--Begin Test case SequenceCheck.2
		--Description: Checking VEHICLE_DATA_NOT_AVAILABLE of VehicleDataResultCode
			commonFunctions:newTestCasesGroup("SequenceCheck.1")			
			--Requirement id in JAMA: 
				-- SDLAQ-CRS-1100

			--Verification criteria:
				--VEHICLE_DATA_NOT_AVAILABLE Should be returned by HMI to SDL in case the requested VehicleData cannot be subscribed because it is not available on the bus or via whatever appropriate channel. SDL must re-send this value to the corresponding app.
			
			--ToDo: Shall be uncommented when APPLINK-25363: "[Genivi]Service ID for endpoints are incorrectly written in DB after ignition off/on" is fixed
			--and Task_APPLINK_15934() is run
			-- function Test:PreCondition_SubscribeVehicleData()				
			-- 	self:subscribeVehicleDataSuccess({"prndl"})				
			-- end			
			function Test:UnsubscribeVehicleData_VehicleDataNotAvailable()
				--mobile side: sending UnsubscribeVehicleData request
				local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																			{
																				prndl = true
																			})
				
				--hmi side: expect UnsubscribeVehicleData request
				EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{prndl = true})					
				:Do(function(_,data)
					--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {prndl= {resultCode = "VEHICLE_DATA_NOT_AVAILABLE", dataType = "VEHICLEDATA_PRNDL"}})							
				end)					
					
				--mobile side: expect UnsubscribeVehicleData response
				EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", prndl= {resultCode = "VEHICLE_DATA_NOT_AVAILABLE", dataType = "VEHICLEDATA_PRNDL"}})
				
				--mobile side: expect OnHashChange notification
				EXPECT_NOTIFICATION("OnHashChange")
				:Times(0)
			end	
		--End Test case SequenceCheck.2
		
		-----------------------------------------------------------------------------------------

		--Begin Test case SequenceCheck.3
		--Description: Subscription to the parameter already subscribed by other application
			commonFunctions:newTestCasesGroup("SequenceCheck.2")		
			--Requirement id in JAMA: 
				-- SDLAQ-CRS-3127
				-- APPLINK-13345
				-- SDLAQ-CRS-3128
				-- SDLAQ-CRS-3129
				-- SDLAQ-CRS-3130

			--Verification criteria:
				--[[ In case app_2 sends UnsubscribeVehicleData (param_1, param_2) to SDL AND SDL has successfully already subscribed param_1 and param_2 via UnsubscribeVehicleData to app_1 SDL must:
						1)  NOT send UnsubscribeVehicleData(param_1, param_2) to HMI.
						2) respond via UnsubscribeVehicleData (SUCCESS) to app_2
					In case app_1 sends UnsubscribeVehicleData (param_1) to SDL AND SDL does not have this param_1 in list of stored successfully subscribing params SDL must:
						transfer UnsubscribeVehicleData(param_1) to HMI
						in case SDL receives SUCCESS from HMI for param_1 SDL must store this param in list AND respond UnsubscribeVehicleData (SUCCESS) to app_1						
						respond corresponding result SUCCESS received from HMI to app_1
					In case app_2 sends UnsubscribeVehicleData (param_1, param_3) to SDL AND SDL already subscribes param_1 viaUnsubscribeVehicleData to app_1 SDL must send UnsubscribeVehicleData ONLY with param_3 to HMI.
					In case app_1 sends UnsubscribeVehicleData (param_1) to SDL AND SDL does not have this param_1 in list of stored successfully subscribing params SDL must:
						transfer UnsubscribeVehicleData(param_1) to HMI
						NOT store the parameter in SDL list in case SDL receives erroneous result for param_1
						respond UnsubscribeVehicleData (Result Code, success:false) to app_1
				]]
			function Test:PreCondition_SecondSession()
				--mobile side: start new session
			  self.mobileSession1 = mobile_session.MobileSession(
				self,
				self.mobileConnection)
			end
					
			function Test:PreCondition_AppRegistrationInSecondSession()
				--mobile side: start new 
				self.mobileSession1:StartService(7)
				:Do(function()
					local CorIdRegister = self.mobileSession1:SendRPC("RegisterAppInterface",
					{
					  syncMsgVersion =
					  {
						majorVersion = 3,
						minorVersion = 0
					  },
					  appName = "Test Application2",
					  isMediaApplication = true,
					  languageDesired = 'EN-US',
					  hmiDisplayLanguageDesired = 'EN-US',
					  appHMIType = { "NAVIGATION" },
					  appID = "456"
					})
					
					--hmi side: expect BasicCommunication.OnAppRegistered request
					EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
					{
					  application = 
					  {
						appName = "Test Application2"
					  }
					})
					:Do(function(_,data)
					  self.applications["Test Application2"] = data.params.application.appID
					end)
					
					--mobile side: expect response
					self.mobileSession1:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
					:Timeout(2000)

					self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})					
				end)
			end
			
			function Test:PreCondition_ActivateSecondApp()
				--hmi side: sending SDL.ActivateApp request
				local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application2"]})

				--hmi side: expect SDL.ActivateApp response
				EXPECT_HMIRESPONSE(RequestId)
				:Do(function(_,data)
					if
						data.result.isSDLAllowed ~= true then
						local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
						
						--hmi side: expect SDL.GetUserFriendlyMessage message response
						EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
						:Do(function(_,data)						
							--hmi side: send request SDL.OnAllowSDLFunctionality
							self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

							--hmi side: expect BasicCommunication.ActivateApp request
							EXPECT_HMICALL("BasicCommunication.ActivateApp")
							:Do(function(_,data)
								--hmi side: sending BasicCommunication.ActivateApp response
								self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
							end)
							:Times(2)
						end)

					end
				end)
				
				--mobile side: expect notification from 2 app
				self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND"})
				self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL"})					
			end
			
			--ToDo: Shall be removed when APPLINK-25363: "[Genivi]Service ID for endpoints are incorrectly written in DB after ignition off/on" is fixed
			--when Task_APPLINK_15934() is run
			function Test:PreconditionUnsubscribe_rpm() 				
				--self:unsubscribeVehicleDataSuccess({"speed","rpm"})				
				self:unsubscribeVehicleDataSuccess({"rpm"})				
			end


			function Test:PreCondition_SubscribeVehicleData_App1()
					--mobile side: sending UnsubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("SubscribeVehicleData",
																				{
																					speed = true,
																					rpm = true
																				})
					
					--hmi side: expect SubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{speed = true, rpm = true})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.SubscribeVehicleData response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
									speed= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"},
									rpm= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_RPM"}})							
					end)					
						
					--mobile side: expect SubscribeVehicleData response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", 
									speed= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"},
									rpm= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_RPM"}})			
					
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end	
		
			function Test:PreCondition_SubscribeVehicleData_App2()
				--mobile side: sending SubscribeVehicleData request
				local cid = self.mobileSession1:SendRPC("SubscribeVehicleData",
																			{
																				prndl = true,
																				speed = true,
																				rpm = true
																			})
				
				--hmi side: expect SubscribeVehicleData request
				EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",{prndl=true})					
				:Do(function(_,data)
					--hmi side: sending VehicleInfo.SubscribeVehicleData response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
								prndl= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_PRNDL"}})							
				end)
				:ValidIf(function(_,data)
					if data.params.speed or data.params.rpm then
						print(" \27[36m SDL send subscribed parameter to HMI \27[0m")
						return false
					else
						return true
					end
				end)
				
				--print("\27[31m DEFECT: APPLINK-17738\27[0m")
				--mobile side: expect UnsubscribeVehicleData response
				self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS",
					speed= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"},
					rpm= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_RPM"},							
					prndl= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_PRNDL"}})
				
				--mobile side: expect OnHashChange notification
				self.mobileSession1:ExpectNotification("OnHashChange",{})
			end


			
			--Begin Test case SequenceCheck.3.1
			--Description: App1 unsubscribe one params			
				function Test:CheckOnVehicleData_Speed()
					--hmi side: sending VehicleInfo.OnVehicleData notification					
					self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {speed = 100.05})	  
					
					--mobile side: expected OnVehicleData notification
					self.mobileSession1:ExpectNotification("OnVehicleData", {speed = 100.05})
					self.mobileSession:ExpectNotification("OnVehicleData", {speed = 100.05})			
				end
				
				function Test:UnsubscribeVehicleData_Speed()				
					--mobile side: sending UnsubscribeVehicleData request
					local cid1 = self.mobileSession:SendRPC("UnsubscribeVehicleData",{speed = true})					
					
					--hmi side: expect UnsubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{speed = true})					
					:Times(0)
					
					--mobile side: expect UnsubscribeVehicleData response
					self.mobileSession:ExpectResponse(cid1, { success = true, resultCode = "SUCCESS", speed= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"}})
					
					--mobile side: expect OnHashChange notification
					--self.mobileSession:ExpectNotification("OnHashChange",{})

					--print("\27[31m DEFECT: APPLINK-25609\27[0m")
					EXPECT_NOTIFICATION("OnHashChange")
				end			
			
			
				function Test:CheckOnVehicleData_Speed_RPM()
					--hmi side: sending VehicleInfo.OnVehicleData notification					
					self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {speed = 100.05, rpm = 1000})	  
					
					
					--mobile side: expected OnVehicleData response
					self.mobileSession1:ExpectNotification("OnVehicleData", {speed = 100.05, rpm = 1000})
					self.mobileSession:ExpectNotification("OnVehicleData", {rpm = 1000})					
					:ValidIf(function(_,data)
						if data.payload.speed then
							print(" \27[36m SDL send OnVehicleData to app that unsubscribe vehicleData \27[0m")
							return false
						else
							return true
						end
					end)
				end
			--End Test case SequenceCheck.3.1
			
			-----------------------------------------------------------------------------------------

			--Begin Test case SequenceCheck.3.2
			--Description: App1 and App2 unsubscribe the same parameter
				function Test:UnsubscribeVehicleData_App1()
					--mobile side: sending UnsubscribeVehicleData request
					local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",
																				{
																					rpm = true																					
																				})
					
					--hmi side: expect UnsubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{rpm = true})					
					:Times(0)				
						
					--mobile side: expect UnsubscribeVehicleData response
					EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", 
									rpm= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_RPM"}})		
					
					--print("\27[31m DEFECT: APPLINK-25609\27[0m")
					--mobile side: expect OnHashChange notification
					EXPECT_NOTIFICATION("OnHashChange")
				end	
				
				function Test:UnsubscribeVehicleData_App2()
					--mobile side: sending UnsubscribeVehicleData request
					local cid = self.mobileSession1:SendRPC("UnsubscribeVehicleData",
																				{
																					rpm = true
																				})
										
					--hmi side: expect UnsubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{rpm = true})					
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
									rpm= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_RPM"}})							
					end)
					
					--mobile side: expect UnsubscribeVehicleData response
					self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS",							
									rpm= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_RPM"}})									
					
					--mobile side: expect OnHashChange notification
					self.mobileSession1:ExpectNotification("OnHashChange",{})
				end
				
				function Test:CheckOnVehicleData_RPM()
					--hmi side: sending VehicleInfo.OnVehicleData notification					
					self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {rpm = 1000})	  
					
					--mobile side: expected OnVehicleData response
					self.mobileSession1:ExpectNotification("OnVehicleData", {rpm = 1000})
					:Times(0)
					
					self.mobileSession:ExpectNotification("OnVehicleData", {rpm = 1000})					
					:Times(0)

					DelayedExp(2000)
				end
				
				function Test:PostCondition_UnsubscribeVehicleData()				
					--mobile side: sending UnsubscribeVehicleData request
					local cid1 = self.mobileSession1:SendRPC("UnsubscribeVehicleData",{prndl = true, speed = true})
					
					
					--hmi side: expect UnsubscribeVehicleData request
					EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",{prndl = true, speed = true})
					:Do(function(_,data)
						--hmi side: sending VehicleInfo.UnsubscribeVehicleData response
						self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{
											speed= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"},
											prndl= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_PRNDL"}})	
					end)
					
					
					--mobile side: expect UnsubscribeVehicleData response
					self.mobileSession1:ExpectResponse(cid1, { success = true, resultCode = "SUCCESS",
													speed= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_SPEED"},
													prndl= {resultCode = "SUCCESS", dataType = "VEHICLEDATA_PRNDL"}})	
													
					--mobile side: expect OnHashChange notification
					self.mobileSession1:ExpectNotification("OnHashChange",{})								
				end
		--End Test case SequenceCheck.3
		
		-----------------------------------------------------------------------------------------
		
		--Begin Test case SequenceCheck.4
		--Description: Check Unsubscribe on PRNDL vehicle data
			commonFunctions:newTestCasesGroup("SequenceCheck.3")		
			--Requirement id in JAMA: 
				-- SDLAQ-CRS-93

			--Verification criteria:
				-- OnVehicleData will not be send to mobile after unsubscribed
				local prndlValue = {"PARK","REVERSE","NEUTRAL","DRIVE","SPORT","LOWGEAR","FIRST","SECOND","THIRD","FOURTH","FIFTH","SIXTH"}
				for i=1, #prndlValue do
					Test["SubbscribeVehicleData_NotSubcribedChangingPRNDL_"..prndlValue[i]] = function(self)											
						--hmi side: sending VehicleInfo.OnVehicleData notification					
						self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {prndl = prndlValue[i]})	  
						
						--mobile side: expected UnsubscribeVehicleData response
						EXPECT_NOTIFICATION("OnVehicleData", {prndl = prndlValue[i]})
						:Times(0)
					end
				end	
		--End Test case SequenceCheck.4
	--End Test suit SequenceCheck

----------------------------------------------------------------------------------------------
-----------------------------------------VII TEST BLOCK----------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------
	--Description: processing of request/response in different HMIlevels, SystemContext, AudioStreamingState

	--Begin Test suit DifferentHMIlevel
	--Description: processing API in different HMILevel
	
		--Begin Test case DifferentHMIlevel.1
		--Description: 
			commonFunctions:newTestCasesGroup("DifferentHMIlevel.1")
			--Requirement id in JAMA:
				-- SDLAQ-CRS-799
				
			--Verification criteria: 
				-- SDL rejects UnsubscribeVehicleData request with REJECTED resultCode when current HMI level is NONE.
				-- SDL doesn't reject UnsubscribeVehicleData request when current HMI is FULL.
				-- SDL doesn't reject UnsubscribeVehicleData request when current HMI is LIMITED.
				-- SDL doesn't reject UnsubscribeVehicleData request when current HMI is BACKGROUND.

--[==[TODO: check after ATF defect APPLINK-13101 is resolved
					function Test:PreCondition_PolicyUpdate()
						--hmi side: sending SDL.GetURLS request
						local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
						
						--hmi side: expect SDL.GetURLS response from HMI
						EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {{url = "http://policies.telematics.ford.com/api/policies"}}}})
						:Do(function(_,data)
							--print("SDL.GetURLS response is received")
							--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
							self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
								{
									requestType = "PROPRIETARY",
									fileName = "filename"
								}
							)
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
								"files/PTU_AllowedUSVDAllVehicleData.json")
								
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
										}
									)
									function to_run()
										--hmi side: sending SystemRequest response
										self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
									end
									
									RUN_AFTER(to_run, 500)
								end)
								
								--hmi side: expect SDL.OnStatusUpdate
								EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status =  "UP_TO_DATE"})
								:Do(function(_,data)
									--print("SDL.OnStatusUpdate is received")
									
									--hmi side: expect SDL.OnAppPermissionChanged
									
									
								end)
								:Timeout(2000)
								
								--mobile side: expect SystemRequest response
								EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
								:Do(function(_,data)
									--print("SystemRequest is received")
									--hmi side: sending SDL.GetUserFriendlyMessage request to SDL
									local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})
									
									--hmi side: expect SDL.GetUserFriendlyMessage response
									EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
									:Do(function(_,data)
										--print("SDL.GetUserFriendlyMessage is received")
										
										--hmi side: sending SDL.GetListOfPermissions request to SDL
										local RequestIdGetListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = self.applications["Test Application"]})
										
										-- hmi side: expect SDL.GetListOfPermissions response
										EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions,{result = {code = 0, method = "SDL.GetListOfPermissions", allowedFunctions = {{ id = 193465391, name = "New"}}}})
										:Do(function(_,data)
											--print("SDL.GetListOfPermissions response is received")
											
											--hmi side: sending SDL.OnAppPermissionConsent
											self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = false, id = 193465391, name = "New"}}, source = "GUI"})
											end)
									end)
								end)
								:Timeout(2000)
								
							end)
						end)
					end
						
			--Begin Test case DifferentHMIlevel.1.1
			--Description: SDL process UnsubscribeVehicleData request on LIMITED HMI level		
				function Test:PreCondition_DeactivateToNone()
					--hmi side: sending BasicCommunication.OnExitApplication notification
					self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application"], reason = "USER_EXIT"})

					EXPECT_NOTIFICATION("OnHMIStatus",
						{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
				end
				
				for i=1, #allVehicleData do
					Test["UnsubscribeVehicleData_HMILevelNone_"..allVehicleData[i]] = function(self)
						--mobile side: sending UnsubscribeVehicleData request
						local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",{allVehicleData[i]})
						
						--mobile side: expected UnsubscribeVehicleData response
						EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED" })
						
						--mobile side: expect OnHashChange notification
						EXPECT_NOTIFICATION("OnHashChange")
						:Times(0)
					end
				end
				
				function Test:PostCondition_ActivateApp()				
					--hmi side: sending SDL.ActivateApp request
					local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})

					--hmi side: expect SDL.ActivateApp response
					EXPECT_HMIRESPONSE(RequestId)
						:Do(function(_,data)
							--In case when app is not allowed, it is needed to allow app
							if
								data.result.isSDLAllowed ~= true then

									--hmi side: sending SDL.GetUserFriendlyMessage request
									local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", 
														{language = "EN-US", messageCodes = {"DataConsent"}})

									--hmi side: expect SDL.GetUserFriendlyMessage response
									EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
										:Do(function(_,data)

											--hmi side: send request SDL.OnAllowSDLFunctionality
											self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", 
												{allowed = true, source = "GUI", device = {id = 1, name = "127.0.0.1"}})

										end)

									--hmi side: expect BasicCommunication.ActivateApp request
									EXPECT_HMICALL("BasicCommunication.ActivateApp")
									:Do(function(_,data)

										--hmi side: sending BasicCommunication.ActivateApp response
										self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})

									end)
									:Times(2)
							end
						  end)

					--mobile side: expect OnHMIStatus notification
					EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL"})	
				end	
				
			--End Test case DifferentHMIlevel.1.1
]==]			
			-----------------------------------------------------------------------------------------

			--Begin Test case DifferentHMIlevel.1.2
			--Description: SDL process UnsubscribeVehicleData request on LIMITED HMI level(only for media app)			
				function Test:PreCondition_ActivateFirstApp()
					--hmi side: sending SDL.ActivateApp request
					local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
					
					--mobile side: expect notification
					self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL"})										
				end

			if 
				Test.isMediaApplication == true or 
				Test.appHMITypes["NAVIGATION"] == true then
			
				function Test:PreCondition_DeactivateToLimited()
					--hmi side: sending BasicCommunication.OnAppDeactivated request
					local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
					{
						appID = self.applications["Test Application"],
						reason = "GENERAL"
					})
					
					--mobile side: expect OnHMIStatus notification
					EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE"})
				end
				

				function Test:PreCondition_SubscribeVehicleData()				
					--UPDATED: in the test only parameteres below are Unsubscribed before this test.
					--self:subscribeVehicleDataSuccess(allVehicleData)
					--{"gps", "speed", "rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption", "externalTemperature", "prndl", "tirePressure", "odometer", "beltStatus", "bodyInformation", "deviceStatus", "driverBraking", "wiperStatus", "headLampStatus", "engineTorque", "accPedalPosition", "steeringWheelAngle"}
					
				 	--self:subscribeVehicleDataSuccess({"gps", "speed", "rpm", "prndl", "headLampStatus"})
					self:subscribeVehicleDataSuccess(allVehicleData)
				end
			
				for i=1, #allVehicleData do
					Test["UnsubscribeVehicleData_HMILevelLimited_"..allVehicleData[i]] = function(self)						
						self:unsubscribeVehicleDataSuccess({allVehicleData[i]})
						DelayedExp(2000)
					end
				end
			--End Test case DifferentHMIlevel.1.2
			
			-----------------------------------------------------------------------------------------
			
			--Begin Test case DifferentHMIlevel.1.3
			--Description: SDL process UnsubscribeVehicleData request on BACKGROUND HMI level
				function Test:PreCondition_ActivateSecondApp()
					--hmi side: sending SDL.ActivateApp request
					local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application2"]})
					
					--mobile side: expect notification from 2 app
					self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})
					self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})					
				end

			elseif
				Test.isMediaApplication == false then

					-- Precondition for non-media app
					function Test:Precondition_DeactivateToBackground()
						--hmi side: sending BasicCommunication.OnAppDeactivated request
						local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
						{
							appID = self.applications["Test Application"],
							reason = "GENERAL"
						})
						
						--mobile side: expect OnHMIStatus notification
						EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})
					end
			end

				function Test:PreCondition_SubscribeVehicleData()				
					self:subscribeVehicleDataSuccess(allVehicleData)
				end
						
				for i=1, #allVehicleData do
					Test["UnsubscribeVehicleData_HMILevelBackground_"..allVehicleData[i]] = function(self)						
						self:unsubscribeVehicleDataSuccess({allVehicleData[i]})	
						DelayedExp(3000)
					end
				end
			--End Test case DifferentHMIlevel.1.3
		--End Test case DifferentHMIlevel.1
	--End Test suit DifferentHMIlevel



---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
-------------------------------------------Postconditions------------------------------------
---------------------------------------------------------------------------------------------


	--Print new line to separate Postconditions
	commonFunctions:newTestCasesGroup("Postconditions")
	testCasesForPolicyTable:Restore_preloaded_pt()
	Test["Stop_SDL"] = function(self)
		StopSDL()
	end 

