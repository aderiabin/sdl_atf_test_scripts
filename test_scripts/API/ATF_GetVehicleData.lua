Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')

require('user_modules/AppTypes')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local doubleParameterInResponse = require('user_modules/shared_testcases/testCasesForDoubleParameterInResponse')
local enumerationParameterInResponse = require('user_modules/shared_testcases/testCasesForEnumerationParameterInResponse')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
---------------------------------------------------------------------------------------------
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------
APIName = "GetVehicleData" -- set request name
local COMPASS_DIRECTION_VALUES = {"NORTH", "NORTHWEST", "WEST", "SOUTHWEST", "SOUTH", "SOUTHEAST", "EAST", "NORTHEAST"}
local DIMENSION_VALUES = {"NO_FIX", "2D", "3D"}
local COMPONENT_VOLUME_STATUS = {"UNKNOWN", "NORMAL", "LOW", "FAULT", "ALERT", "NOT_SUPPORTED"}
local PRNDL_VALUES = {"PARK","REVERSE","NEUTRAL","DRIVE","SPORT","LOWGEAR","FIRST","SECOND","THIRD","FOURTH","FIFTH","SIXTH", "SEVENTH", "EIGHTH", "FAULT"}
local WARNING_LIGHT_STATUS = {"OFF", "ON", "FLASH", "NOT_USED"}
local VEHICLE_DATA_EVENT_STATUS = {"NO_EVENT", "NO", "YES", "NOT_SUPPORTED", "FAULT"}
local IGNITION_STABLE_STATUS_VALUES = {"IGNITION_SWITCH_NOT_STABLE", "IGNITION_SWITCH_STABLE", "MISSING_FROM_TRANSMITTER"}
local IGNITION_STATUS_VALUES = {"UNKNOWN", "OFF", "ACCESSORY", "RUN", "START", "INVALID"}
local DEVICE_LEVEL_STATUS = {"ZERO_LEVEL_BARS", "ONE_LEVEL_BARS", "TWO_LEVEL_BARS", "THREE_LEVEL_BARS", "FOUR_LEVEL_BARS", "NOT_PROVIDED"}
local PRIMARY_AUDIO_SOURCE_VALUES = {"NO_SOURCE_SELECTED", "USB", "USB2", "BLUETOOTH_STEREO_BTST", "LINE_IN", "IPOD", "MOBILE_APP"}
local WIPER_STATUS_VALUES = {"OFF", "AUTO_OFF", "OFF_MOVING", "MAN_INT_OFF", "MAN_INT_ON", "MAN_LOW", "MAN_HIGH", "MAN_FLICK", "WASH", "AUTO_LOW", "AUTO_HIGH", "COURTESYWIPE", "AUTO_ADJUST", "STALLED", "NO_DATA_EXISTS"}
local AMBIENT_LIGHT_STATUS = {"NIGHT", "TWILIGHT_1", "TWILIGHT_2", "TWILIGHT_3", "TWILIGHT_4", "DAY", "UNKNOWN", "INVALID"}
local VEHICLE_DATA_NOTIFICATION_STATUS = {"NOT_SUPPORTED", "NORMAL", "ACTIVE", "NOT_USED"}
local ECALL_CONFIRMATION_STATUS_VALUES = {"NORMAL", "CALL_IN_PROGRESS", "CALL_CANCELLED", "CALL_COMPLETED", "CALL_UNSUCCESSFUL", "ECALL_CONFIGURED_OFF", "CALL_COMPLETE_DTMF_TIMEOUT"}
local POWER_MODE_QUALIFICATION_STATUS_VALUES = {"POWER_MODE_UNDEFINED", "POWER_MODE_EVALUATION_IN_PROGRESS", "NOT_DEFINED", "POWER_MODE_OK"}
local CAR_MODE_STATUS_VALUES = {"NORMAL", "FACTORY", "TRANSPORT", "CRASH"}
local POWER_MODE_STATUS_VALUES = {"KEY_OUT", "KEY_RECENTLY_OUT", "KEY_APPROVED_0", "POST_ACCESORY_0", "ACCESORY_1", "POST_IGNITION_1", "IGNITION_ON_2", "RUNNING_2", "CRANK_3"}
local VEHICLE_DATA_STATUS = {"NO_DATA_EXISTS", "OFF", "ON"}
local EMERGENCY_EVENT_TYPE_VALUES = {"NO_EVENT", "FRONTAL", "SIDE", "REAR", "ROLLOVER", "NOT_SUPPORTED", "FAULT"}
local FUEL_CUT_OFF_STATUS_VALUES = {"TERMINATE_FUEL", "NORMAL_OPERATION", "FAULT"}
local ABS_STATE_VALUES = {"INACTIVE", "ACTIVE"}
local TPMS_VALUES = {"UNKNOWN", "SYSTEM_FAULT", "SENSOR_FAULT", "LOW", "SYSTEM_ACTIVE", "TRAIN_LF_TIRE", "TRAIN_RF_TIRE", "TRAIN_RR_TIRE", "TRAIN_ORR_TIRE", "TRAIN_IRR_TIRE", "TRAIN_LR_TIRE", "TRAIN_OLR_TIRE", "TRAIN_ILR_TIRE", "TRAINING_COMPLETE", "TIRES_NOT_TRAINED"}
local TURN_SIGNAL_VALUES = {"OFF", "LEFT", "RIGHT", "UNUSED"}
local TIRE_PRESSURE_VALUE_PARAMS = {"leftFront", "rightFront", "leftRear", "rightRear", "innerLeftRear", "innerRightRear", "frontRecommended", "rearRecommended"}
local BELT_STATUS_PARAMS = {"driverBeltDeployed", "passengerBeltDeployed", "passengerBuckleBelted", "driverBuckleBelted", "leftRow2BuckleBelted", "passengerChildDetected", "rightRow2BuckleBelted", "middleRow2BuckleBelted", "middleRow3BuckleBelted", "leftRow3BuckleBelted", "rightRow3BuckleBelted", "leftRearInflatableBelted", "rightRearInflatableBelted", "middleRow1BeltDeployed", "middleRow1BuckleBelted"}
local AIRBAG_STATUS_PARAMS = {"driverAirbagDeployed", "driverSideAirbagDeployed", "driverCurtainAirbagDeployed", "passengerAirbagDeployed", "passengerCurtainAirbagDeployed", "driverKneeAirbagDeployed", "passengerSideAirbagDeployed", "passengerKneeAirbagDeployed"}
local integerParameterInResponse = require('user_modules/shared_testcases/testCasesForIntegerParameterInResponse')
local floatParameterInResponse = require('user_modules/shared_testcases/testCasesForFloatParameterInResponse')
local booleanParameterInResponse = require('user_modules/shared_testcases/testCasesForBooleanParameterInResponse')
local vehicleDataValues = {
  gps = {
    longitudeDegrees = 25.5,
    latitudeDegrees = 45.5
  },
  speed = 100.5,
  rpm = 1000,
  fuelLevel= 50.5,
  fuelLevel_State="NORMAL",
  instantFuelConsumption=1000.5,
  fuelRange = 50.5,
  abs_State = "ACTIVE",
  externalTemperature=55.5,
  vin = "123456",
  prndl="DRIVE",
  tirePressure={
    pressureTelltale = "ON",
  },
  tirePressureValue ={
    leftFront = 50,
    rightFront = 50,
    leftRear = 50,
    rightRear = 50,
    innerLeftRear = 50,
    innerRightRear = 50,
    frontRecommended = 50,
    rearRecommended = 50
  },
  tpms = "UNKNOWN",
  turnSignal = "UNUSED",
  odometer= 8888,
  beltStatus={
    driverBeltDeployed = "NOT_SUPPORTED"
  },
  bodyInformation={
    parkBrakeActive = true,
    ignitionStableStatus = "MISSING_FROM_TRANSMITTER",
    ignitionStatus = "UNKNOWN"
  },
  deviceStatus={
    voiceRecOn = true
  },
  driverBraking="NOT_SUPPORTED",
  wiperStatus="MAN_LOW",
  headLampStatus={
    lowBeamsOn = true,
    highBeamsOn = true,
    ambientLightSensorStatus = "NIGHT"
  },
  engineTorque=555.5,
  accPedalPosition=55.5,
  steeringWheelAngle=555.5,
  eCallInfo={
    eCallNotificationStatus = "NORMAL",
    auxECallNotificationStatus = "NORMAL",
    eCallConfirmationStatus = "NORMAL"
  },
  airbagStatus={
    driverAirbagDeployed = "NOT_SUPPORTED",
    driverSideAirbagDeployed = "NOT_SUPPORTED",
    driverCurtainAirbagDeployed = "NOT_SUPPORTED",
    passengerAirbagDeployed = "NOT_SUPPORTED",
    passengerCurtainAirbagDeployed = "NOT_SUPPORTED",
    driverKneeAirbagDeployed = "NOT_SUPPORTED",
    passengerSideAirbagDeployed = "NOT_SUPPORTED",
    passengerKneeAirbagDeployed = "NOT_SUPPORTED"
  },
  emergencyEvent={
    emergencyEventType = "NO_EVENT",
    fuelCutoffStatus = "NORMAL_OPERATION",
    rolloverEvent = "NO_EVENT",
    maximumChangeVelocity = 0,
    multipleEvents = "NO_EVENT"
  },
  clusterModeStatus={
    powerModeActive = true,
    powerModeQualificationStatus = "POWER_MODE_UNDEFINED",
    carModeStatus = "TRANSPORT",
    powerModeStatus = "KEY_OUT"
  },
  myKey={
    e911Override = "NO_DATA_EXISTS"
  }
}
local ALL_VEHICLE_DATA = {"gps", "speed", "rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption", "fuelRange", "abs_State", "externalTemperature", "prndl", "tirePressure", "tirePressureValue", "tpms", "turnSignal", "odometer", "beltStatus", "bodyInformation", "deviceStatus", "driverBraking", "wiperStatus", "headLampStatus", "engineTorque", "accPedalPosition", "steeringWheelAngle", "eCallInfo", "airbagStatus", "emergencyEvent", "clusterModeStatus", "myKey", "vin"}
local vehicleData = {"gps"}
local infoMessageValue = string.rep("a",1000)
---------------------------------------------------------------------------------------------
-------------------------- Overwrite These Functions For This Script-------------------------
---------------------------------------------------------------------------------------------
function DelayedExp(time)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  :Timeout(time + 1000)
  RUN_AFTER(function()
    RAISE_EVENT(event, event)
  end, time)
end

--Description: A deep copy copies all levels (or a specific subset of levels).
function copyTable(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[copyTable(orig_key)] = copyTable(orig_value)
    end
    setmetatable(copy, copyTable(getmetatable(orig)))
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end

--Description: Set data for GetVehicleData request
--params_send: vehicle data parameter name - table
function SetGvdRequest(params_send)
  local temp = {}
  for i = 1, #params_send do
    temp[params_send[i]] = true
  end
  return temp
end

--Description: Set data for GetVehicleData response
--params_send: vehicle data parameter name - table
function SetGvdResponse(params_send)
  local temp = {}
  for i = 1, #params_send do
    temp[params_send[i]] = copyTable(vehicleDataValues[params_send[i]])
  end
  return temp
end

--Description: Create expected result for success result
--response: response received from HMI
function CreateSuccessExpectedResult(response)
  local temp = response
  temp["success"] = true
  temp["resultCode"] = "SUCCESS"
  
  return temp
end

--Description: GetVehicleData is executed successfully
--params_send: vehicle data parameter name - table
--info_message: Provides additional human readable info regarding the result.
function Test:getVehicleDataSuccess(params_send, info_message)
  local request = SetGvdRequest(params_send)
  local response = SetGvdResponse(params_send)
  
  if info_message ~= nil then
    response["info"] = info_message
  end
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",request)
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",request)
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)
  end)
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, expectedResult)
  DelayedExp(300)
end

--Description: GetVehicleData is executed with invalid data
--params_send: vehicle data parameter name - table
function Test:getVehicleDataInvalidData(params_send)
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",params_send)
  --mobile side: expected GetVehicleData response
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
  DelayedExp(300)
end

--Description: Update policy from specific file
--policy_filename: Name of policy file
--is_b_allowed: true if want to allowed New group policy
-- false if want to disallowed New group policy
function Test:policyUpdate(policy_filename, is_b_allowed)
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
      "files/"..policy_filename)
      
      local systemRequestId
      --hmi side: expect SystemRequest request
      EXPECT_HMICALL("BasicCommunication.SystemRequest")
      :Do(function(_,data)
        systemRequestId = data.id
        
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
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
      :ValidIf(function(exp,data)
        if
        exp.occurences == 1 and
        data.params.status == "UP_TO_DATE" then
          return true
        elseif
        exp.occurences == 1 and
        data.params.status == "UPDATING" then
          return true
        elseif
        exp.occurences == 2 and
        data.params.status == "UP_TO_DATE" then
          return true
        else
          if
          exp.occurences == 1 then
            print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in first occurrences status 'UP_TO_DATE' or 'UPDATING', got '" .. tostring(data.params.status) .. "' \27[0m")
          elseif exp.occurences == 2 then
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
        EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
        :Do(function(_,data)
          --hmi side: sending SDL.GetListOfPermissions request to SDL
          local RequestIdGetListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = self.applications["Test Application"]})
          -- hmi side: expect SDL.GetListOfPermissions response
          EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions,{result = {code = 0, method = "SDL.GetListOfPermissions", allowedFunctions = {{ id = 193465391, name = "New"}}}})
          :Do(function(_,data)
            --hmi side: sending SDL.OnAppPermissionConsent
            self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID = self.applications["Test Application"], consentedFunctions = {{ allowed = is_b_allowed, id = 193465391, name = "New"}}, source = "GUI"})
          end)
        end)
      end)
    end)
  end)
end

--Description: Checking GetVehicleData response with correct value
--response: vehicle data response from HMI
function Test:getVehicleDataResponseSuccess(response)
  local request = SetGvdRequest(vehicleData)
  
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",request)
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",request)
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)
  end)
  
  if
  response.tirePressure and
  (response.tirePressure.leftFront or
  response.tirePressure.rightFront or
  response.tirePressure.leftRear or
  response.tirePressure.rightRear or
  response.tirePressure.innerLeftRear or
  response.tirePressure.innerRightRear) then
    local expectedResult = CreateSuccessExpectedResult({})
  else
    local expectedResult = CreateSuccessExpectedResult(response)
  end
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, expectedResult)
  DelayedExp(300)
end

--Description: Checking GetVehicleData response with invalid value
--response: vehicle data response from HMI
function Test:getVehicleDataResponseInvalidData(response)
  local request = SetGvdRequest(vehicleData)
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",request)
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",request)
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)
  end)
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})--change Result code from "INVALID_DATA" to "GENERIC_ERROR" according to APPLINK-15494
  DelayedExp(300)
end

--This function is used to send default request and response with specific valid data and verify SUCCESS resultCode
function Test:verify_SUCCESS_Response_Case(Response)
  --mobile side: sending the request
  local Request = SetGvdRequest(vehicleData)
  local cid = self.mobileSession:SendRPC(APIName, Request)
  
  --hmi side: expect VehicleInfo.GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData", Request)
  :Do(function(_,data)
    --hmi side: sending response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)
  end)
  --mobile side: expect the response
  local ExpectedResponse = commonFunctions:cloneTable(Response)
  ExpectedResponse["success"] = true
  ExpectedResponse["resultCode"] = "SUCCESS"
  EXPECT_RESPONSE(cid, ExpectedResponse)
  DelayedExp(500)
end
--This function is used to send default request and response with specific invalid data and verify GENERIC_ERROR resultCode
function Test:verify_GENERIC_ERROR_Response_Case(Response)
  --mobile side: sending the request
  local Request = SetGvdRequest(vehicleData)
  local cid = self.mobileSession:SendRPC(APIName, Request)
  
  --hmi side: expect VehicleInfo.GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData", Request)
  :Do(function(_,data)
    --hmi side: sending response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", Response)
  end)
  --mobile side: expect the response
  EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle" })
  DelayedExp(500)
end
---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------

--Print new line to separate Preconditions
commonFunctions:newTestCasesGroup("Preconditions")

--Delete app_info.dat, logs and policy table
commonSteps:DeleteLogsFileAndPolicyTable()
--1. Activate application
commonSteps:ActivationApp()
--2. Update policy to allow request
policyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/PTU_ForVehicleData.json")

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

--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-97

--Verification criteria: GetVehicleData request allows to receive the current data values for any of the following listed items: gps, speed, rpm, fuelLevel, fuelLevel_State, instantFuelConsumption, externalTemperature, vin, prndl, tirePressure, odometer, beltStatus, bodyInformation, deviceStatus, driverBraking, wiperStatus, headLampStatus, engineTorque, accPedalPosition, steeringWheelAngle, eCallInfo, airbagStatus, emergencyEvent, clusterModeStatus, myKey, fuelRange, abs_State, tirePressureValue, tpms, turnSignal.
--The response contains data values for requested items.
commonFunctions:newTestCasesGroup("CommonRequestCheck.1")
function Test:GetVehicleData_Positive()
  self:getVehicleDataSuccess(ALL_VEHICLE_DATA)
end
--End Test case CommonRequestCheck.1

-----------------------------------------------------------------------------------------

--Begin Test case CommonRequestCheck.2
--Description: This test is intended to check request with mandatory and with or without conditional parameters

--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-97

--Verification criteria: GetVehicleData request allows to receive the current data values for any of the following listed items: gps, speed, rpm, fuelLevel, fuelLevel_State, instantFuelConsumption, externalTemperature, vin, prndl, tirePressure, odometer, beltStatus, bodyInformation, deviceStatus, driverBraking, wiperStatus, headLampStatus, engineTorque, accPedalPosition, steeringWheelAngle, eCallInfo, airbagStatus, emergencyEvent, clusterModeStatus, myKey, fuelRange, abs_State, tirePressureValue, tpms, turnSignal.
--The response contains data values for requested items.
commonFunctions:newTestCasesGroup("CommonRequestCheck.2 - Not applicable")
--Not applicable

--End Test case CommonRequestCheck.2

-----------------------------------------------------------------------------------------

--Begin Test case CommonRequestCheck.3
--Description: This test is intended to check processing requests without mandatory parameters

--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-609

--Verification criteria:
--The request sent with NO parameters receives INVALID_DATA response code.
commonFunctions:newTestCasesGroup("CommonRequestCheck.3")
function Test:GetVehicleData_AllParamsMissing()
  self:getVehicleDataInvalidData({})
end
--End Test case CommonRequestCheck.3

-----------------------------------------------------------------------------------------

--Begin Test case CommonRequestCheck.4
--Description: Check processing request with different fake parameters

--Requirement id in JAMA/or Jira ID: APPLINK-4518

--Verification criteria: According to xml tests by Ford team all fake params should be ignored by SDL
commonFunctions:newTestCasesGroup("CommonRequestCheck.4")
--Begin Test case CommonRequestCheck4.1
--Description: With fake parameters
function Test:GetVehicleData_FakeParams()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",
  {
    speed = true,
    fakeParam ="fakeParam"
  })
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {speed = 80.5})
  end)
  :ValidIf(function(_,data)
    if data.params.fakeParam then
      print(" \27[36m SDL re-sends fakeParam parameters to HMI \27[0m")
      return false
    else
      return true
    end
  end)
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", speed = 80.5})
  
  DelayedExp(300)
end
--End Test case CommonRequestCheck4.1

-----------------------------------------------------------------------------------------

--Begin Test case CommonRequestCheck.4.2
--Description: Parameters from another request
function Test:GetVehicleData_ParamsAnotherRequest()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",
  {
    speed = true,
    ttsChunks =
    {
      {
        text ="SpeakFirst",
        type ="TEXT",
      }
    }
  })
  
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {speed = 80.5})
  end)
  :ValidIf(function(_,data)
    if data.params.ttsChunks then
      print(" \27[36m SDL re-sends fakeParam parameters to HMI \27[0m")
      return false
    else
      return true
    end
  end)
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", speed = 80.5})
  DelayedExp(300)
end
--End Test case CommonRequestCheck4.2
--End Test case CommonRequestCheck.4

-----------------------------------------------------------------------------------------

--Begin Test case CommonRequestCheck.5
--Description: Check processing request with invalid JSON syntax

--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-609

--Verification criteria: The request with wrong JSON syntax is sent, the response with INVALID_DATA result code is returned.
commonFunctions:newTestCasesGroup("CommonRequestCheck.5")
function Test:GetVehicleData_InvalidJSON()
  self.mobileSession.correlationId = self.mobileSession.correlationId + 1
  local msg =
  {
    serviceType = 7,
    frameInfo = 0,
    rpcType = 0,
    rpcFunctionId = 22,
    rpcCorrelationId = self.mobileSession.correlationId,
    --<<!-- missing ':'
    payload = '{"gps" true}'
  }
  self.mobileSession:Send(msg)
  self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })
  DelayedExp(300)
end
--End Test case CommonRequestCheck.5

-----------------------------------------------------------------------------------------
--TODO: Requirement and Verification criteria need to be updated.
--Begin Test case CommonRequestCheck.6
--Description: Check processing requests with duplicate correlationID value

--Requirement id in JAMA/or Jira ID:

--Verification criteria:
--
commonFunctions:newTestCasesGroup("CommonRequestCheck.6")
function Test:GetVehicleData_correlationIdDuplicateValue()
  --mobile side: send GetVehicleData request
  local CorIdGetVehicleData = self.mobileSession:SendRPC("GetVehicleData", {speed = true})
  local msg =
  {
    serviceType = 7,
    frameInfo = 0,
    rpcType = 0,
    rpcFunctionId = 22,
    rpcCorrelationId = CorIdGetVehicleData,
    payload = '{"rpm" : true}'
  }
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",
  {speed = true},
  {rpm = true}
  )
  :Do(function(exp,data)
    if exp.occurences == 1 then
      self.mobileSession:Send(msg)
      
      --hmi side: sending VehicleInfo.GetVehicleData response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {speed = 80.5})
    else
      --hmi side: sending VehicleInfo.GetVehicleData response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {rpm = 500})
    end
  end)
  :Times(2)
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(CorIdGetVehicleData,
  {success = true, resultCode = "SUCCESS", speed = 80.5},
  {success = true, resultCode = "SUCCESS", rpm = 500})
  :Times(2)
  DelayedExp(300)
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
commonFunctions:newTestCasesGroup("PositiveRequestCheck")
--Begin Test case PositiveRequestCheck.1
--Description: Check processing request with lower and upper bound values

--Requirement id in JAMA:
-- SDLAQ-CRS-97,
-- SDLAQ-CRS-608

--Verification criteria:
--Checking all VehicleData parameter. The request is executed successfully
for i=1, #ALL_VEHICLE_DATA do
  Test["GetVehicleData_"..ALL_VEHICLE_DATA[i]] = function(self)
    self:getVehicleDataSuccess({ALL_VEHICLE_DATA[i]})
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

--Requirement id in JAMA:
--SDLAQ-CRS-98

--Verification criteria:
-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription.
commonFunctions:newTestCasesGroup("PositiveResponseCheck.1")
--Begin Test case PositiveResponseCheck.1.1
--Description: Response with info parameter lower bound
function Test:GetVehicleData_ResponseInfoLowerBound()
  self:getVehicleDataSuccess({"speed"}, "a")
end
--End Test case PositiveResponseCheck.1.1

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.1.2
--Description: Response with info parameter upper bound
function Test:GetVehicleData_ResponseInfoUpperBound()
  self:getVehicleDataSuccess({"speed"}, infoMessageValue)
end
--End Test case PositiveResponseCheck.1.2
--End Test case PositiveResponseCheck.1

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2
--Description: Checking parameters boundary conditions

--Requirement id in JAMA:
--SDLAQ-CRS-98

--Verification criteria:
-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription.
commonFunctions:newTestCasesGroup("PositiveResponseCheck.2")
--Begin Test case PositiveResponseCheck.2.1
--Description: Response with longitudeDegrees parameter lower bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.1

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.2
--Description: Response with longitudeDegrees parameter upper bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.2

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.3
--Description: Response with latitudeDegrees parameter lower bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.3

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.4
--Description: Response with latitudeDegrees parameter upper bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.4

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.5
--Description: Response with utcYear parameter lower bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.5

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.6
--Description: Response with utcYear parameter upper bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.6

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.7
--Description: Response with utcMonth parameter lower bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.7

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.8
--Description: Response with utcMonth parameter upper bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.8

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.9
--Description: Response with utcDay parameter lower bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.9

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.10
--Description: Response with utcDay parameter upper bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.10

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.11
--Description: Response with utcHours parameter lower bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.11

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.12
--Description: Response with utcHours parameter upper bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.12

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.13
--Description: Response with utcMinutes parameter lower bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.13

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.14
--Description: Response with utcMinutes parameter upper bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.14

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.15
--Description: Response with utcSeconds parameter lower bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.15

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.16
--Description: Response with utcSeconds parameter upper bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.16

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.17
--Description: Response with compassDirection in bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.17

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.18
--Description: Response with pdop parameter lower bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.18

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.19
--Description: Response with pdop parameter upper bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.19

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.20
--Description: Response with hdop parameter lower bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.20

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.21
--Description: Response with hdop parameter upper bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.21

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.22
--Description: Response with vdop parameter lower bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.22

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.23
--Description: Response with vdop parameter upper bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.23

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.24
--Description: Response with actual parameter in bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.24

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.25
--Description: Response with satellites parameter lower bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.25

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.26
--Description: Response with satellites parameter upper bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.26

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.27
--Description: Response with dimension parameter in bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.27

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.28
--Description: Response with altitude parameter lower bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.28

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.29
--Description: Response with altitude parameter upper bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.29

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.30
--Description: Response with heading parameter lower bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.30

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.31
--Description: Response with heading parameter upper bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.31

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.32
--Description: Response with gps.speed parameter lower bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.32

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.33
--Description: Response with gps.speed parameter upper bound
-- It's already covered in function VerifyGpsParameter()
--End Test case PositiveResponseCheck.2.33

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.34
--Description: Response with speed parameter lower bound
function Test:GetVehicleData_ResponseLowerBound_speed()
  local response = SetGvdResponse({"speed"})
  response["speed"] = 0.1
  self:getVehicleDataResponseSuccess(response)
end
--End Test case PositiveResponseCheck.2.34

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.35
--Description: Response with speed parameter upper bound
function Test:GetVehicleData_ResponseUpperBound_speed()
  local response = SetGvdResponse({"speed"})
  response["speed"] = 699.9
  self:getVehicleDataResponseSuccess(response)
end
--End Test case PositiveResponseCheck.2.35

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.36
--Description: Response with rpm parameter lower bound
function Test:GetVehicleData_ResponseLowerBound_rpm()
  local response = SetGvdResponse({"rpm"})
  response["rpm"] = 0
  self:getVehicleDataResponseSuccess(response)
end
--End Test case PositiveResponseCheck.2.36

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.37
--Description: Response with rpm parameter upper bound
function Test:GetVehicleData_ResponseUpperBound_rpm()
  local response = SetGvdResponse({"rpm"})
  response["rpm"] = 20000
  self:getVehicleDataResponseSuccess(response)
end
--End Test case PositiveResponseCheck.2.37

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.38
--Description: Response with fuelLevel parameter lower bound
function Test:GetVehicleData_ResponseLowerBound_fuelLevel()
  local response = SetGvdResponse({"fuelLevel"})
  response["fuelLevel"] = -5.9
  self:getVehicleDataResponseSuccess(response)
end
--End Test case PositiveResponseCheck.2.38

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.39
--Description: Response with fuelLevel parameter upper bound
function Test:GetVehicleData_ResponseUpperBound_fuelLevel()
  local response = SetGvdResponse({"fuelLevel"})
  response["fuelLevel"] = 105.9
  self:getVehicleDataResponseSuccess(response)
end
--End Test case PositiveResponseCheck.2.39

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.40
--Description: Response with fuelLevel_State parameter in bound
for i=1, #COMPONENT_VOLUME_STATUS do
  Test["GetVehicleData_fuelLevel_State_"..COMPONENT_VOLUME_STATUS[i]] = function(self)
    local response = SetGvdResponse({"fuelLevel_State"})
    response["fuelLevel_State"] = COMPONENT_VOLUME_STATUS[i]
    self:getVehicleDataResponseSuccess(response)
  end
end
--End Test case PositiveResponseCheck.2.40

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.41
--Description: Response with instantFuelConsumption parameter lower bound
function Test:GetVehicleData_ResponseLowerBound_instantFuelConsumption()
  local response = SetGvdResponse({"instantFuelConsumption"})
  response["instantFuelConsumption"] = 0.1
  self:getVehicleDataResponseSuccess(response)
end
--End Test case PositiveResponseCheck.2.41

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.42
--Description: Response with instantFuelConsumption parameter upper bound
function Test:GetVehicleData_ResponseUpperBound_instantFuelConsumption()
  local response = SetGvdResponse({"instantFuelConsumption"})
  response["instantFuelConsumption"] = 25574.9
  self:getVehicleDataResponseSuccess(response)
end
--End Test case PositiveResponseCheck.2.42

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.43
--Description: Response with externalTemperature parameter lower bound
function Test:GetVehicleData_ResponseLowerBound_externalTemperature()
  local response = SetGvdResponse({"externalTemperature"})
  response["externalTemperature"] = -39.9
  self:getVehicleDataResponseSuccess(response)
end
--End Test case PositiveResponseCheck.2.43

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.44
--Description: Response with externalTemperature parameter upper bound
function Test:GetVehicleData_ResponseUpperBound_externalTemperature()
  local response = SetGvdResponse({"externalTemperature"})
  response["externalTemperature"] = 99.9
  self:getVehicleDataResponseSuccess(response)
end
--End Test case PositiveResponseCheck.2.44

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.45
--Description: Response with vin parameter lower bound
function Test:GetVehicleData_ResponseLowerBound_vin()
  local response = SetGvdResponse({"vin"})
  response["vin"] = "1"
  self:getVehicleDataResponseSuccess(response)
end
--End Test case PositiveResponseCheck.2.45

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.46
--Description: Response with vin parameter upper bound
function Test:GetVehicleData_ResponseUpperBound_vin()
  local response = SetGvdResponse({"vin"})
  response["vin"] = "12345678912345678"
  self:getVehicleDataResponseSuccess(response)
end
--End Test case PositiveResponseCheck.2.46

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.47
--Description: Response with prndl parameter in bound
for i=1, #PRNDL_VALUES do
  Test["GetVehicleData_prndl_"..PRNDL_VALUES[i]] = function(self)
    local response = SetGvdResponse({"prndl"})
    response["prndl"] = PRNDL_VALUES[i]
    self:getVehicleDataResponseSuccess(response)
  end
end
--End Test case PositiveResponseCheck.2.47

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.48
--Description: Response with pressureTelltale parameter in bound
-- It's already covered in function VerifyTirePressureParameter.
--End Test case PositiveResponseCheck.2.48

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.49
--Description: Response with leftFront parameter in bound
-- It's already covered in function VerifyTirePressureParameter.
--End Test case PositiveResponseCheck.2.49

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.50
--Description: Response with rightFront parameter in bound
-- It's already covered in function VerifyTirePressureParameter.
--End Test case PositiveResponseCheck.2.50

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.51
--Description: Response with leftRear parameter in bound
-- It's already covered in function VerifyTirePressureParameter.
--End Test case PositiveResponseCheck.2.51

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.52
--Description: Response with rightRear parameter in bound
-- It's already covered in function VerifyTirePressureParameter.
--End Test case PositiveResponseCheck.2.52

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.53
--Description: Response with innerLeftRear parameter in bound
-- It's already covered in function VerifyTirePressureParameter.
--End Test case PositiveResponseCheck.2.53

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.54
--Description: Response with innerRightRear parameter in bound
-- It's already covered in function VerifyTirePressureParameter.
--End Test case PositiveResponseCheck.2.54

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.55
--Description: Response with odometer parameter lower bound
function Test:GetVehicleData_ResponseLowerBound_odometer()
  local response = SetGvdResponse({"odometer"})
  response["odometer"] = 0
  self:getVehicleDataResponseSuccess(response)
end
--End Test case PositiveResponseCheck.2.55

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.56
--Description: Response with odometer parameter upper bound
function Test:GetVehicleData_ResponseUpperBound_odometer()
  local response = SetGvdResponse({"odometer"})
  response["odometer"] = 17000000
  self:getVehicleDataResponseSuccess(response)
end
--End Test case PositiveResponseCheck.2.56

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.57
--Description: Response with beltStatus parameter in bound
-- It's already covered in function VerifyBeltStatusParameter()
--End Test case PositiveResponseCheck.2.57

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.58
--Description: Response with parkBrakeActive parameter in bound
function Test:GetVehicleData_ResponseInBound_parkBrakeActive()
  local response = SetGvdResponse({"bodyInformation"})
  response.bodyInformation["parkBrakeActive"] = false
  self:getVehicleDataResponseSuccess(response)
end
--End Test case PositiveResponseCheck.2.58

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.59
--Description: Response with ignitionStableStatus parameter in bound
for i=1, #IGNITION_STABLE_STATUS_VALUES do
  Test["GetVehicleData_ignitionStableStatus_"..IGNITION_STABLE_STATUS_VALUES[i]] = function(self)
    local response = SetGvdResponse({"bodyInformation"})
    response.bodyInformation["ignitionStableStatus"] = IGNITION_STABLE_STATUS_VALUES[i]
    self:getVehicleDataResponseSuccess(response)
  end
end
--End Test case PositiveResponseCheck.2.59

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.60
--Description: Response with ignitionStatus parameter in bound
for i=1, #IGNITION_STATUS_VALUES do
  Test["GetVehicleData_ignitionStatus_"..IGNITION_STATUS_VALUES[i]] = function(self)
    local response = SetGvdResponse({"bodyInformation"})
    response.bodyInformation["ignitionStatus"] = IGNITION_STATUS_VALUES[i]
    self:getVehicleDataResponseSuccess(response)
  end
end
--End Test case PositiveResponseCheck.2.60

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.61
--Description: Response with driverDoorAjar parameter in bound
function Test:GetVehicleData_ResponseInBound_driverDoorAjar()
  local response = SetGvdResponse({"bodyInformation"})
  response.bodyInformation["driverDoorAjar"] = false
  self:getVehicleDataResponseSuccess(response)
end
--End Test case PositiveResponseCheck.2.61

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.62
--Description: Response with passengerDoorAjar parameter in bound
function Test:GetVehicleData_ResponseInBound_passengerDoorAjar()
  local response = SetGvdResponse({"bodyInformation"})
  response.bodyInformation["passengerDoorAjar"] = false
  self:getVehicleDataResponseSuccess(response)
end
--End Test case PositiveResponseCheck.2.62

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.63
--Description: Response with rearLeftDoorAjar parameter in bound
function Test:GetVehicleData_ResponseInBound_rearLeftDoorAjar()
  local response = SetGvdResponse({"bodyInformation"})
  response.bodyInformation["rearLeftDoorAjar"] = false
  self:getVehicleDataResponseSuccess(response)
end
--End Test case PositiveResponseCheck.2.63

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.64
--Description: Response with rearRightDoorAjar parameter in bound
function Test:GetVehicleData_ResponseInBound_rearRightDoorAjar()
  local response = SetGvdResponse({"bodyInformation"})
  response.bodyInformation["rearRightDoorAjar"] = false
  self:getVehicleDataResponseSuccess(response)
end
--End Test case PositiveResponseCheck.2.64

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.65
--Description: Response with voiceRecOn parameter in bound
-- It's already covered in function VerifyDeviceStatusParameter
--End Test case PositiveResponseCheck.2.65

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.66
--Description: Response with btIconOn parameter in bound
-- It's already covered in function VerifyDeviceStatusParameter
--End Test case PositiveResponseCheck.2.66

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.67
--Description: Response with callActive parameter in bound
-- It's already covered in function VerifyDeviceStatusParameter
--End Test case PositiveResponseCheck.2.67

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.68
--Description: Response with phoneRoaming parameter in bound
-- It's already covered in function VerifyDeviceStatusParameter
--End Test case PositiveResponseCheck.2.68

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.69
--Description: Response with textMsgAvailable parameter in bound
-- It's already covered in function VerifyDeviceStatusParameter
--End Test case PositiveResponseCheck.2.69

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.70
--Description: Response with battLevelStatus parameter in bound
-- It's already covered in function VerifyDeviceStatusParameter
--End Test case PositiveResponseCheck.2.70

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.71
--Description: Response with monoAudioOutputMuted parameter in bound
-- It's already covered in function VerifyDeviceStatusParameter
--End Test case PositiveResponseCheck.2.71

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.72
--Description: Response with signalLevelStatus parameter in bound
-- It's already covered in function VerifyDeviceStatusParameter
--End Test case PositiveResponseCheck.2.72

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.73
--Description: Response with primaryAudioSource parameter in bound
-- It's already covered in function VerifyDeviceStatusParameter
--End Test case PositiveResponseCheck.2.73

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.74
--Description: Response with eCallEventActive parameter in bound
-- It's already covered in function VerifyDeviceStatusParameter
--End Test case PositiveResponseCheck.2.74

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.75
--Description: Response with driverBraking parameter in bound
for i=1, #VEHICLE_DATA_EVENT_STATUS do
  Test["GetVehicleData_driverBraking_"..VEHICLE_DATA_EVENT_STATUS[i]] = function(self)
    local response = SetGvdResponse({"driverBraking"})
    response["driverBraking"] = VEHICLE_DATA_EVENT_STATUS[i]
    self:getVehicleDataResponseSuccess(response)
  end
end
--End Test case PositiveResponseCheck.2.75

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.76
--Description: Response with wiperStatus parameter in bound
for i=1, #WIPER_STATUS_VALUES do
  Test["GetVehicleData_wiperStatus_"..WIPER_STATUS_VALUES[i]] = function(self)
    local response = SetGvdResponse({"wiperStatus"})
    response["wiperStatus"] = WIPER_STATUS_VALUES[i]
    self:getVehicleDataResponseSuccess(response)
  end
end
--End Test case PositiveResponseCheck.2.76

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.77
--Description: Response with lowBeamsOn parameter in bound
function Test:GetVehicleData_ResponseInBound_lowBeamsOn()
  local response = SetGvdResponse({"headLampStatus"})
  response.headLampStatus["lowBeamsOn"] = false
  self:getVehicleDataResponseSuccess(response)
end
--End Test case PositiveResponseCheck.2.77

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.78
--Description: Response with highBeamsOn parameter in bound
function Test:GetVehicleData_ResponseInBound_highBeamsOn()
  local response = SetGvdResponse({"headLampStatus"})
  response.headLampStatus["highBeamsOn"] = false
  self:getVehicleDataResponseSuccess(response)
end
--End Test case PositiveResponseCheck.2.78

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.79
--Description: Response with ambientLightSensorStatus parameter in bound
for i=1, #AMBIENT_LIGHT_STATUS do
  Test["GetVehicleData_ambientLightSensorStatus_"..AMBIENT_LIGHT_STATUS[i]] = function(self)
    local response = SetGvdResponse({"headLampStatus"})
    response.headLampStatus["ambientLightSensorStatus"] = AMBIENT_LIGHT_STATUS[i]
    self:getVehicleDataResponseSuccess(response)
  end
end
--End Test case PositiveResponseCheck.2.79

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.80
--Description: Response with engineTorque parameter lower bound
function Test:GetVehicleData_ResponseLowerBound_engineTorque()
  local response = SetGvdResponse({"engineTorque"})
  response["engineTorque"] = -999.9
  self:getVehicleDataResponseSuccess(response)
end
--End Test case PositiveResponseCheck.2.80

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.81
--Description: Response with engineTorque parameter upper bound
function Test:GetVehicleData_ResponseUpperBound_engineTorque()
  local response = SetGvdResponse({"engineTorque"})
  response["engineTorque"] = 1999.9
  self:getVehicleDataResponseSuccess(response)
end
--End Test case PositiveResponseCheck.2.81

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.82
--Description: Response with accPedalPosition parameter lower bound
function Test:GetVehicleData_ResponseLowerBound_accPedalPosition()
  local response = SetGvdResponse({"accPedalPosition"})
  response["accPedalPosition"] = 0.1
  self:getVehicleDataResponseSuccess(response)
end
--End Test case PositiveResponseCheck.2.82

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.83
--Description: Response with accPedalPosition parameter upper bound
function Test:GetVehicleData_ResponseUpperBound_accPedalPosition()
  local response = SetGvdResponse({"accPedalPosition"})
  response["accPedalPosition"] = 99.9
  self:getVehicleDataResponseSuccess(response)
end
--End Test case PositiveResponseCheck.2.83

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.84
--Description: Response with steeringWheelAngle parameter lower bound
function Test:GetVehicleData_ResponseLowerBound_steeringWheelAngle()
  local response = SetGvdResponse({"steeringWheelAngle"})
  response["steeringWheelAngle"] = -1999.9
  self:getVehicleDataResponseSuccess(response)
end
--End Test case PositiveResponseCheck.2.84

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.85
--Description: Response with steeringWheelAngle parameter upper bound
function Test:GetVehicleData_ResponseUpperBound_steeringWheelAngle()
  local response = SetGvdResponse({"steeringWheelAngle"})
  response["steeringWheelAngle"] = 1999.9
  self:getVehicleDataResponseSuccess(response)
end
--End Test case PositiveResponseCheck.2.85

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.86
--Description: Response with eCallNotificationStatus parameter in bound
for i=1, #VEHICLE_DATA_NOTIFICATION_STATUS do
  Test["GetVehicleData_eCallNotificationStatus_"..VEHICLE_DATA_NOTIFICATION_STATUS[i]] = function(self)
    local response = SetGvdResponse({"eCallInfo"})
    response.eCallInfo["eCallNotificationStatus"] = VEHICLE_DATA_NOTIFICATION_STATUS[i]
    self:getVehicleDataResponseSuccess(response)
  end
end
--End Test case PositiveResponseCheck.2.86

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.87
--Description: Response with auxECallNotificationStatus parameter in bound
for i=1, #VEHICLE_DATA_NOTIFICATION_STATUS do
  Test["GetVehicleData_auxECallNotificationStatus_"..VEHICLE_DATA_NOTIFICATION_STATUS[i]] = function(self)
    local response = SetGvdResponse({"eCallInfo"})
    response.eCallInfo["auxECallNotificationStatus"] = VEHICLE_DATA_NOTIFICATION_STATUS[i]
    self:getVehicleDataResponseSuccess(response)
  end
end
--End Test case PositiveResponseCheck.2.87

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.88
--Description: Response with eCallConfirmationStatus parameter in bound
for i=1, #ECALL_CONFIRMATION_STATUS_VALUES do
  Test["GetVehicleData_eCallConfirmationStatus_"..ECALL_CONFIRMATION_STATUS_VALUES[i]] = function(self)
    local response = SetGvdResponse({"eCallInfo"})
    response.eCallInfo["eCallConfirmationStatus"] = ECALL_CONFIRMATION_STATUS_VALUES[i]
    self:getVehicleDataResponseSuccess(response)
  end
end
--End Test case PositiveResponseCheck.2.88

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.89
--Description: Response with airbagStatus parameter in bound
for j=1, #AIRBAG_STATUS_PARAMS do
  for i=1, #VEHICLE_DATA_EVENT_STATUS do
    Test["GetVehicleData_"..AIRBAG_STATUS_PARAMS[j].."_"..VEHICLE_DATA_EVENT_STATUS[i]] = function(self)
      local response = SetGvdResponse({"airbagStatus"})
      response.airbagStatus[AIRBAG_STATUS_PARAMS[j]] = VEHICLE_DATA_EVENT_STATUS[i]
      self:getVehicleDataResponseSuccess(response)
    end
  end
end
--End Test case PositiveResponseCheck.2.89

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.90
--Description: Response with emergencyEventType parameter in bound
for i=1, #EMERGENCY_EVENT_TYPE_VALUES do
  Test["GetVehicleData_emergencyEventType_"..EMERGENCY_EVENT_TYPE_VALUES[i]] = function(self)
    local response = SetGvdResponse({"emergencyEvent"})
    response.emergencyEvent["emergencyEventType"] = EMERGENCY_EVENT_TYPE_VALUES[i]
    self:getVehicleDataResponseSuccess(response)
  end
end
--End Test case PositiveResponseCheck.2.90

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.91
--Description: Response with fuelCutoffStatus parameter in bound
for i=1, #FUEL_CUT_OFF_STATUS_VALUES do
  Test["GetVehicleData_fuelCutoffStatus_"..FUEL_CUT_OFF_STATUS_VALUES[i]] = function(self)
    local response = SetGvdResponse({"emergencyEvent"})
    response.emergencyEvent["fuelCutoffStatus"] = FUEL_CUT_OFF_STATUS_VALUES[i]
    self:getVehicleDataResponseSuccess(response)
  end
end
--End Test case PositiveResponseCheck.2.91

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.92
--Description: Response with rolloverEvent parameter in bound
for i=1, #VEHICLE_DATA_EVENT_STATUS do
  Test["GetVehicleData_rolloverEvent_"..VEHICLE_DATA_EVENT_STATUS[i]] = function(self)
    local response = SetGvdResponse({"emergencyEvent"})
    response.emergencyEvent["rolloverEvent"] = VEHICLE_DATA_EVENT_STATUS[i]
    self:getVehicleDataResponseSuccess(response)
  end
end
--End Test case PositiveResponseCheck.2.92

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.93
--Description: Response with maximumChangeVelocity parameter in bound
local inBound = {0, 255}
for i=1, #inBound do
  Test["GetVehicleData_maximumChangeVelocity_"..inBound[i]] = function(self)
    local response = SetGvdResponse({"emergencyEvent"})
    response.emergencyEvent["maximumChangeVelocity"] = inBound[i]
    self:getVehicleDataResponseSuccess(response)
  end
end
--End Test case PositiveResponseCheck.2.93

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.94
--Description: Response with multipleEvents parameter in bound
for i=1, #VEHICLE_DATA_EVENT_STATUS do
  Test["GetVehicleData_multipleEvents_"..VEHICLE_DATA_EVENT_STATUS[i]] = function(self)
    local response = SetGvdResponse({"emergencyEvent"})
    response.emergencyEvent["multipleEvents"] = VEHICLE_DATA_EVENT_STATUS[i]
    self:getVehicleDataResponseSuccess(response)
  end
end
--End Test case PositiveResponseCheck.2.94

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.95
--Description: Response with powerModeActive parameter in bound
function Test:GetVehicleData_ResponseInBound_powerModeActive()
  local response = SetGvdResponse({"clusterModeStatus"})
  response.clusterModeStatus["powerModeActive"] = false
  self:getVehicleDataResponseSuccess(response)
end
--End Test case PositiveResponseCheck.2.95

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.96
--Description: Response with powerModeQualificationStatus parameter in bound
for i=1, #POWER_MODE_QUALIFICATION_STATUS_VALUES do
  Test["GetVehicleData_powerModeQualificationStatus_"..POWER_MODE_QUALIFICATION_STATUS_VALUES[i]] = function(self)
    local response = SetGvdResponse({"clusterModeStatus"})
    response.clusterModeStatus["powerModeQualificationStatus"] = POWER_MODE_QUALIFICATION_STATUS_VALUES[i]
    self:getVehicleDataResponseSuccess(response)
  end
end
--End Test case PositiveResponseCheck.2.96

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.97
--Description: Response with carModeStatus parameter in bound
for i=1, #CAR_MODE_STATUS_VALUES do
  Test["GetVehicleData_carModeStatus_"..CAR_MODE_STATUS_VALUES[i]] = function(self)
    local response = SetGvdResponse({"clusterModeStatus"})
    response.clusterModeStatus["carModeStatus"] = CAR_MODE_STATUS_VALUES[i]
    self:getVehicleDataResponseSuccess(response)
  end
end
--End Test case PositiveResponseCheck.2.97

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.98
--Description: Response with powerModeStatus parameter in bound
for i=1, #POWER_MODE_STATUS_VALUES do
  Test["GetVehicleData_powerModeStatus_"..POWER_MODE_STATUS_VALUES[i]] = function(self)
    local response = SetGvdResponse({"clusterModeStatus"})
    response.clusterModeStatus["powerModeStatus"] = POWER_MODE_STATUS_VALUES[i]
    self:getVehicleDataResponseSuccess(response)
  end
end
--End Test case PositiveResponseCheck.2.98

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.99
--Description: Response with monoAudioOutputMuted parameter in bound
-- It's already covered in function VerifyDeviceStatusParameter
--End Test case PositiveResponseCheck.2.99

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.100
--Description: Response with e911Override parameter in bound
for i=1, #VEHICLE_DATA_STATUS do
  Test["GetVehicleData_fuelLevel_State_"..VEHICLE_DATA_STATUS[i]] = function(self)
    local response = SetGvdResponse({"myKey"})
    response.myKey["e911Override"] = VEHICLE_DATA_STATUS[i]
    self:getVehicleDataResponseSuccess(response)
  end
end
--End Test case PositiveResponseCheck.2.100

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.101
--Requirement: APPLINK-21379
--Description: Response with fuelRange parameter
--<param name="fuelRange" type="Float" minvalue="0" maxvalue="10000" mandatory="false"
local response = SetGvdResponse({"fuelRange"})
response["fuelRange"] = 1
Test["Precondition_PositiveResponseCheck_fuelRange"] = function(self)
  vehicleData = {"fuelRange"}
end
floatParameterInResponse:verify_Float_Parameter(response, {"fuelRange"}, {0.000000, 10000.000000}, false)

--End Test case PositiveResponseCheck.2.101

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.102
--Requirement: APPLINK-21379
--Description: Response with fuelRange parameter
--<param name="abs_State" type="ABS_STATE" mandatory="false">
local response = SetGvdResponse({"abs_State"})
Test["Precondition_PositiveResponseCheck_abs_State"] = function(self)
  vehicleData = {"abs_State"}
end
response.abs_State = {}
enumerationParameterInResponse:verify_Enum_String_Parameter(response,{"abs_State"},ABS_STATE_VALUES,false)
--End Test case PositiveResponseCheck.2.102

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.103
--Requirement: APPLINK-21379
--Description: Response with fuelRange parameter
--<param name="tirePressureValue" type="TirePressureValue" mandatory="false">
commonFunctions:newTestCasesGroup("Test Suite For Parameter: tirePressureValue")
local response = SetGvdResponse({"tirePressureValue"})
response.tirePressureValue ={
  leftFront = 50,
  rightFront = 50,
  leftRear = 50,
  rightRear = 50,
  innerLeftRear = 50,
  innerRightRear = 50,
  frontRecommended = 50,
  rearRecommended = 50
}
Test["Precondition_PositiveResponseCheck_tirePressureValue"] = function(self)
  vehicleData = {"tirePressureValue"}
end
-- tirePressureValue IsEmpty
commonFunctions:TestCaseForResponse(self, response, {"tirePressureValue"}, "IsEmpty", {}, "SUCCESS")
-- tirePressureValue IsWrongType:
commonFunctions:TestCaseForResponse(self, response, {"tirePressureValue"}, "IsWrongType", 123, "GENERIC_ERROR")
-- Check for all sub-params
local paramBoundary = {{0,65533}, {0,65533}, {0,65533}, {0,65533}, {0,65533}, {0,65533}, {0,65533}, {0,65533}}

for i = 1, #TIRE_PRESSURE_VALUE_PARAMS do
  integerParameterInResponse:verify_Integer_Parameter(response, {"tirePressureValue", TIRE_PRESSURE_VALUE_PARAMS[i]}, paramBoundary[i], false)
end
--End Test case PositiveResponseCheck.2.103

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.104
--Requirement: APPLINK-21379
--Description: Response with fuelRange parameter
--<param name="tpms" type="TPMS" mandatory="false">
local response = SetGvdResponse({"tpms"})
response.tpms = {}
Test["Precondition_PositiveResponseCheck_tpms"] = function(self)
  vehicleData = {"tpms"}
end
enumerationParameterInResponse:verify_Enum_String_Parameter(response,{"tpms"},TPMS_VALUES,false)
--End Test case PositiveResponseCheck.2.104

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.2.105
--Requirement: APPLINK-21379
--Description: Response with fuelRange parameter
--<param name="turnSignal" type="TurnSignal" mandatory="false">
local response = SetGvdResponse({"turnSignal"})
response.turnSignal = {}
Test["Precondition_PositiveResponseCheck_turnSignal"] = function(self)
  vehicleData = {"turnSignal"}
end
enumerationParameterInResponse:verify_Enum_String_Parameter(response,{"turnSignal"},TURN_SIGNAL_VALUES,false)
--End Test case PositiveResponseCheck.2.105

Test["Postcondition_PositiveResponseCheck.2"] = function(self)
  vehicleData = {"gps"}
end
--End Test case PositiveResponseCheck.2

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.3
--Description: Checking process response with only mandatory or with conditional parameter

--Requirement id in JAMA:
--SDLAQ-CRS-98

--Verification criteria:
-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription.
commonFunctions:newTestCasesGroup("PositiveResponseCheck.3")
--RequirementID: APPLINK-15255
--Begin Test case PositiveResponseCheck.3.1
--Description: Response with only mandatory in gps structure
function Test:GetVehicleData_Response_OnlyMandatoryGPS()
  local response = {
    gps = {
      longitudeDegrees = 25.5,
      latitudeDegrees = 45.5
    }
  }
  self:getVehicleDataResponseSuccess(response)
end
--End Test case PositiveResponseCheck.3.1

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.3.2
--Description: Response with only mandatory in bodyInformation structure
function Test:GetVehicleData_Response_OnlyMandatoryBodyInformation()
  local response = {
    bodyInformation = {
      parkBrakeActive = true,
      ignitionStableStatus = "MISSING_FROM_TRANSMITTER",
      ignitionStatus = "UNKNOWN"
    }
  }
  self:getVehicleDataResponseSuccess(response)
end
--End Test case PositiveResponseCheck.3.2

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.3.3
--Description: Response with one parameter in tirePressure structure
local response = {
  {param = "pressureTelltale", value = {tirePressure={ pressureTelltale = "ON"}}},
  {param = "leftFront", value = {tirePressure={ leftFront = {status = "NORMAL"}}}},
  {param = "rightFront", value = {tirePressure={ rightFront = {status = "NORMAL"}}}},
  {param = "leftRear", value = {tirePressure={ leftRear = {status = "NORMAL"}}}},
  {param = "rightRear", value = {tirePressure={ rightRear = {status = "NORMAL"}}}},
  {param = "innerLeftRear", value = {tirePressure={ innerLeftRear = {status = "NORMAL"}}}},
  {param = "innerRightRear", value = {tirePressure={ innerRightRear = {status = "NORMAL"}}}},
}
for i=1, #response do
  Test["GetVehicleData_Only_"..response[i].param.."InTirePressure"] = function(self)
    self:getVehicleDataResponseSuccess(response[i].value)
    --self:getVehicleDataResponseSuccess({})
  end
end
--End Test case PositiveResponseCheck.3.3

-----------------------------------------------------------------------------------------
--RequirementID: APPLINK-15256
--Begin Test case PositiveResponseCheck.3.4
--Description: Response with one parameter in beltStatusParams structure
local BELT_STATUS_PARAMS = {"driverBeltDeployed", "passengerBeltDeployed", "passengerBuckleBelted", "driverBuckleBelted", "leftRow2BuckleBelted", "passengerChildDetected", "rightRow2BuckleBelted", "middleRow2BuckleBelted", "middleRow3BuckleBelted", "leftRow3BuckleBelted", "rightRow3BuckleBelted", "leftRearInflatableBelted", "rightRearInflatableBelted", "middleRow1BeltDeployed", "middleRow1BuckleBelted"}
for i=1, #BELT_STATUS_PARAMS do
  Test["GetVehicleData_Only_"..BELT_STATUS_PARAMS[i].."InBeltStatus"] = function(self)
    local response = {beltStatus = {}}
    response.beltStatus[BELT_STATUS_PARAMS[i]] = "NOT_SUPPORTED"
    self:getVehicleDataResponseSuccess(response)
  end
end
--End Test case PositiveResponseCheck.3.4

-----------------------------------------------------------------------------------------

--Begin Test case PositiveResponseCheck.3.5
--Description: Response with one parameter in deviceStatus structure
local DEVICE_STATUS_PARAMS = {
  {param = "voiceRecOn", value = true},
  {param = "btIconOn", value = true},
  {param = "callActive", value = true},
  {param = "phoneRoaming", value = true},
  {param = "textMsgAvailable", value = true},
  {param = "battLevelStatus", value = "THREE_LEVEL_BARS"},
  {param = "stereoAudioOutputMuted", value = true},
  {param = "monoAudioOutputMuted", value = true},
  {param = "signalLevelStatus", value = "THREE_LEVEL_BARS"},
  {param = "primaryAudioSource", value = "BLUETOOTH_STEREO_BTST"},
{param = "eCallEventActive", value = true}}
for i=1, #DEVICE_STATUS_PARAMS do
  Test["GetVehicleData_Only_"..DEVICE_STATUS_PARAMS[i].param.."InDeviceStatus"] = function(self)
    local response = {deviceStatus = {}}
    response.deviceStatus[DEVICE_STATUS_PARAMS[i].param] = DEVICE_STATUS_PARAMS[i].value
    self:getVehicleDataResponseSuccess(response)
  end
end
--End Test case PositiveResponseCheck.3.5
--End Test case PositiveResponseCheck.3
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
commonFunctions:newTestCasesGroup("NegativeRequestCheck.1 - Not applicable")
--Not applicable

--End Test case NegativeRequestCheck.1

-----------------------------------------------------------------------------------------

--Begin Test case NegativeRequestCheck.2
--Description: Check processing requests with empty values

--Requirement id in JAMA/or Jira ID:
--SDLAQ-CRS-609

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
--]]
commonFunctions:newTestCasesGroup("NegativeRequestCheck.2 - already covered")
--Covered by INVALID_JSON case

--End Test case NegativeRequestCheck.2

-----------------------------------------------------------------------------------------

--Begin Test case NegativeRequestCheck.3
--Description: Check processing requests with wrong type of parameters

--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-609

--Verification criteria:
-- The request with wrong type of parameter value is sent, the response with INVALID_DATA result code is returned.
commonFunctions:newTestCasesGroup("NegativeRequestCheck.3")
for i=1, #ALL_VEHICLE_DATA do
  Test["GetVehicleData_WrongType_"..ALL_VEHICLE_DATA[i]] = function(self)
    local temp = {}
    temp[ALL_VEHICLE_DATA[i]] = 123
    self:getVehicleDataInvalidData(temp)
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
--Description: Check processing request with wrong/correct name of parameters and with true/false value

--Requirement id in JAMA/or Jira ID: SDLAQ-CRS-608, SDLAQ-CRS-2287

--Verification criteria:
-- The request with the wrong name parameter (the one that does not exist in the list of valid parameters for GetVehicleData) and with correctly named other parameters is processed by SDL the valid request (such parameter is ignored). The responseCode is "SUCCESS" if there are no other errors. General resultCode is success="true"
-- Vehicle Data requested in GetVehicleData request with false attribute value receives the response with no data value for this VehicleData parameter. In case of no errors and getting data for other requested vehicle data attributes the response is returned with SUCCES resultCode and success="true".
commonFunctions:newTestCasesGroup("NegativeRequestCheck.5")
--Begin Test case NegativeRequestCheck.5.1
--Description: Check processing request with wrong name parameter
function Test:GetVehicleDataParameterWrongName()
  self:getVehicleDataInvalidData({abc = true})
end
--End Test case NegativeRequestCheck.5.1
-----------------------------------------------------------------------------------------

--Begin Test case NegativeRequestCheck.5.2
--Description: Check processing request with wrong name and valid name parameter
function Test:GetVehicleDataParameterWrongAndValidName()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",{abc = true, speed = true})
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {speed = 50.5})
  end)
  :ValidIf(function(_, data)
    if data.params.abc then
      print(" \27[36m SDL re-sends parameters with wrong name to HMI \27[0m")
      return false
    else
      return true
    end
  end)
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", speed = 50.5})
  DelayedExp(300)
end
--End Test case NegativeRequestCheck.5.2

-----------------------------------------------------------------------------------------

--Begin Test case NegativeRequestCheck.5.3
--Description: Check processing request with wrong value parameter
for i=1, #ALL_VEHICLE_DATA do
  Test["GetVehicleData_"..ALL_VEHICLE_DATA[i].."_false"] = function(self)
    local temp = {}
    temp[ALL_VEHICLE_DATA[i]] = false
    --mobile side: sending GetVehicleData request
    local cid = self.mobileSession:SendRPC("GetVehicleData",temp)
    --hmi side: expect GetVehicleData request
    EXPECT_HMICALL("VehicleInfo.GetVehicleData",temp)
    :Times(0)
    --mobile side: expect GetVehicleData response
    EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA"})
    DelayedExp(300)
  end
end
--End Test case NegativeRequestCheck.5.3

-----------------------------------------------------------------------------------------

--Begin Test case NegativeRequestCheck.5.4
--Description: Check processing request with wrong value and valid value parameter
function Test:GetVehicleData_ParameterWrongAndValidValue()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",{rpm = false, speed = true})
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {speed = 50.5})
  end)
  :ValidIf(function(_, data)
    if data.params.rpm then
      print(" \27[36m SDL re-sends parameters with false value to HMI \27[0m")
      return false
    else
      return true
    end
  end)
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", speed = 50.5})
  DelayedExp(300)
end
--End Test case NegativeRequestCheck.5.4
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
commonFunctions:newTestCasesGroup("NegativeResponseCheck")
--[[TODO: Check after APPLINK-14765 is resolved
--Begin Test case NegativeResponseCheck.1
--Description: Check processing response with outbound values

--Requirement id in JAMA:
--SDLAQ-CRS-98

--Verification criteria:
-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription.

--Begin Test case NegativeResponseCheck.1.1
--Description: Check response with nonexistent resultCode
function Test:GetVehicleData_ResponseResultCodeNotExist()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",
  {
    speed = true
  })
  
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
    self.hmiConnection:SendResponse(data.id, data.method, "ANY", {speed = 55.5})
  end)
  
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
end
--End Test case NegativeResponseCheck.1.1

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.1.2
--Description: Check response with nonexistent VehicleData parameter
function Test:GetVehicleData_ResponseVehicleDataNotExist()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",
  {
    speed = true
  })
  
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {abc = 55.5})
  end)
  
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
end
--End Test case NegativeResponseCheck.1.2
--End Test case NegativeResponseCheck.1
-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.2
--Description: Check processing responses with invalid values (empty, missing, nonexistent, invalid characters)

--Requirement id in JAMA:
--SDLAQ-CRS-98

--Verification criteria:
-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription.

--Begin NegativeResponseCheck.2.1
--Description: Check response with empty method
function Test:GetVehicleData_ResponseEmptyMethod()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",
  {
    speed = true
  })
  
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
    self.hmiConnection:SendResponse(data.id, "", "SUCCESS", {speed = 55.5})
  end)
  
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
end
--End NegativeResponseCheck.2.1

-----------------------------------------------------------------------------------------

--Begin NegativeResponseCheck.2.2
--Description: Check response with empty resultCode
function Test:GetVehicleData_ResponseEmptyResultCode()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",
  {
    speed = true
  })
  
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
    self.hmiConnection:SendResponse(data.id, data.method, "", {speed = 55.5})
  end)
  
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
end
--End NegativeResponseCheck.2.2

-----------------------------------------------------------------------------------------

--Begin NegativeResponseCheck.2.3
--Description: Check response missing all parameter
function Test:GetVehicleData_ResponseMissingAllParams()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",
  {
    speed = true
  })
  
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
    self.hmiConnection:Send({})
  end)
  
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
end
--End NegativeResponseCheck.2.3

-----------------------------------------------------------------------------------------

--Begin NegativeResponseCheck.2.4
--Description: Check response without method
function Test:GetVehicleData_ResponseMissingMethod()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",
  {
    speed = true
  })
  
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
      self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0,"speed":55.5}')
    end)
    
    --mobile side: expect GetVehicleData response
    EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
  end
  --End NegativeResponseCheck.2.4
  
  -----------------------------------------------------------------------------------------
  
  --Begin NegativeResponseCheck.2.5
  --Description: Check response without resultCode
  function Test:GetVehicleData_ResponseMissingResultCode()
    --mobile side: sending GetVehicleData request
    local cid = self.mobileSession:SendRPC("GetVehicleData",
    {
      speed = true
    })
    
    --hmi side: expect GetVehicleData request
    EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
    :Do(function(_,data)
      --hmi side: sending VehicleInfo.GetVehicleData response
      self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"speed":55.5,"method":"VehicleInfo.GetVehicleData"}}')
    end)
    
    --mobile side: expect GetVehicleData response
    EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
  end
  --End NegativeResponseCheck.2.5
  
  -----------------------------------------------------------------------------------------
  
  --Begin NegativeResponseCheck.2.6
  --Description: Check response without vehicleData
  function Test:GetVehicleData_ResponseMissingVehicleDataResultCode()
    --mobile side: sending GetVehicleData request
    local cid = self.mobileSession:SendRPC("GetVehicleData",
    {
      speed = true
    })
    
    --hmi side: expect GetVehicleData request
    EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
    :Do(function(_,data)
      --hmi side: sending VehicleInfo.GetVehicleData response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    
    --mobile side: expect GetVehicleData response
    EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
    :ValidIf(function(_, data)
      if data.payload.speed then
        print(" \27[36m SDL re-sends parameters even though HMI not response this parameter \27[0m")
        return false
      else
        return true
      end
    end)
  end
  --End NegativeResponseCheck.2.6
  
  -----------------------------------------------------------------------------------------
  
  --Begin NegativeResponseCheck.2.7
  --Description: Check response without mandatory parameter
  function Test:GetVehicleData_ResponseMissingMandatory()
    --mobile side: sending GetVehicleData request
    local cid = self.mobileSession:SendRPC("GetVehicleData",
    {
      speed = true
    })
    
    --hmi side: expect GetVehicleData request
    EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
    :Do(function(_,data)
      --hmi side: sending VehicleInfo.GetVehicleData response
      self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{info = "abc"}}')
    end)
    
    --mobile side: expect GetVehicleData response
    EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
  end
  --End NegativeResponseCheck.2.7
  --End Test case NegativeResponseCheck.2
  
  -----------------------------------------------------------------------------------------
  
  --Begin Test case NegativeResponseCheck.3
  --Description: Check processing response with parameters with wrong data type
  
  --Requirement id in JAMA:
  --SDLAQ-CRS-98
  
  --Verification criteria:
  -- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription.
  
  --Begin Test case NegativeResponseCheck.3.1
  --Description: Check response with wrong type of method
  function Test:GetVehicleData_ResponseWrongTypeMethod()
    --mobile side: sending GetVehicleData request
    local cid = self.mobileSession:SendRPC("GetVehicleData",
    {
      speed = true
    })
    
    --hmi side: expect GetVehicleData request
    EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
    :Do(function(_,data)
      --hmi side: sending VehicleInfo.GetVehicleData response
      self.hmiConnection:SendResponse(data.id, 1234, "SUCCESS", {speed = 55.5})
    end)
    
    --mobile side: expect GetVehicleData response
    EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
  end
  --End Test case NegativeResponseCheck.3.1
  
  -----------------------------------------------------------------------------------------
  
  --Begin Test case NegativeResponseCheck.3.2
  --Description: Check response with wrong type of resultCode
  function Test:GetVehicleData_ResponseWrongTypeResultCode()
    --mobile side: sending GetVehicleData request
    local cid = self.mobileSession:SendRPC("GetVehicleData",
    {
      speed = true
    })
    
    --hmi side: expect GetVehicleData request
    EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
    :Do(function(_,data)
      --hmi side: sending VehicleInfo.GetVehicleData response
      self.hmiConnection:SendResponse(data.id, data.method, 123, {speed = 55.5})
    end)
    
    --mobile side: expect GetVehicleData response
    EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
  end
  --End Test case NegativeResponseCheck.3.2
  --End Test case NegativeResponseCheck.3
  
  -----------------------------------------------------------------------------------------
  
  --Begin Test case NegativeResponseCheck.4
  --Description: Invalid JSON
  
  --Requirement id in JAMA:
  --SDLAQ-CRS-98
  
  --Verification criteria:
  -- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription.
  
  function Test:GetVehicleData_ResponseInvalidJson()
    --mobile side: sending GetVehicleData request
    local cid = self.mobileSession:SendRPC("GetVehicleData",
    {
      speed = true
    })
    
    --hmi side: expect GetVehicleData request
    EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
    :Do(function(_,data)
      --hmi side: sending VehicleInfo.GetVehicleData response
      --<<!-- missing ':'
      self.hmiConnection:Send('{"id" '..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0,"speed" true,"method":"VehicleInfo.GetVehicleData"}}')
    end)
    
    --mobile side: expect GetVehicleData response
    EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
  end
  --End Test case NegativeResponseCheck.4
  --]]
-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.5
--Description: SDL behaviour: cases when SDL must transfer "info" parameter via corresponding RPC to mobile app

--Requirement id in JAMA/or Jira ID:
--SDLAQ-CRS-98
--APPLINK-13276
--APPLINK-14551

--Description:
-- In case "message" is empty - SDL should not transfer it as "info" to the app ("info" needs to be omitted)
-- In case info out of upper bound it should truncate to 1000 symbols
-- SDL should not send "info" to app if received "message" is invalid
-- SDL should not send "info" to app if received "message" contains newline "\n" or tab "\t" symbols.

--Begin Test Case NegativeResponseCheck.5.1
--Description: Check response with empty info
function Test:GetVehicleDataResponseInfoOutLowerBound()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",
  {
    speed = true
  })
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = "", speed = 55.5})
  end)
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", speed = 55.5})
  :ValidIf (function(_,data)
    if data.payload.info then
      print(" \27[36m SDL resend invalid info to mobile app \27[0m")
      return false
    else
      return true
    end
  end)
  DelayedExp(300)
end
--End Test Case NegativeResponseCheck.5.1

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.5.2
--Description: Check response with info out upper bound
function Test:GetVehicleData_ResponseInfoOutUpperBound()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",
  {
    speed = true
  })
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = infoMessageValue.."a",speed = 55.5})
  end)
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", speed = 55.5, info = infoMessageValue})
  DelayedExp(300)
end
--End Test Case NegativeResponseCheck.5.2

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.5.3
--Description: Check response with wrong type info
function Test:GetVehicleData_ResponseInfoWrongType()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",
  {
    speed = true
  })
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = 1234, speed = 55.5})
  end)
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", speed = 55.5})
  :ValidIf (function(_,data)
    if data.payload.info then
      print(" \27[36m SDL resend invalid info to mobile app \27[0m")
      return false
    else
      return true
    end
  end)
  DelayedExp(300)
end
--End Test Case NegativeResponseCheck.5.3

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.5.4
--Description: Check response with info have escape sequence \n
function Test:GetVehicleData_ResponseInfoNewLineChar()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",
  {
    speed = true
  })
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = "New line \n", speed = 55.5})
  end)
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", speed = 55.5})
  :ValidIf (function(_,data)
    if data.payload.info then
      print(" \27[36m SDL resend invalid info to mobile app \27[0m")
      return false
    else
      return true
    end
  end)
  DelayedExp(300)
end
--End Test Case NegativeResponseCheck.5.4
-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.5.5
--Description: Check response with info have escape sequence \t
function Test:GetVehicleData_ResponseInfoNewTabChar()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",
  {
    speed = true
  })
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {message = "New tab \t", speed = 55.5})
  end)
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", speed = 55.5})
  :ValidIf (function(_,data)
    if data.payload.info then
      print(" \27[36m SDL resend invalid info to mobile app \27[0m")
      return false
    else
      return true
    end
  end)
  DelayedExp(300)
end
--End Test Case NegativeResponseCheck.5.5
--End Test case NegativeResponseCheck.5

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.6
--Description: Check processing response with parameters have empty value

--Requirement id in JAMA:
--SDLAQ-CRS-98

--Verification criteria:
-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription.

--Requirement id in JIRA:
-- APPLINK-15257
-- APPLINK-15258
--Begin Test Case NegativeResponseCheck6.1
--Description: Check response with gps empty
-- It's already covered in function VerifyGpsParameter()
--End Test Case NegativeResponseCheck6.1

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.2
--Description: Check response with compassDirection empty
-- It's already covered in function VerifyGpsParameter()
--End Test Case NegativeResponseCheck6.2

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.3
--Description: Check response with dimension empty
-- It's already covered in function VerifyGpsParameter()
--End Test Case NegativeResponseCheck6.3

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.4
--Description: Check response with fuelLevel_State empty
function Test:GetVehicleData_fuelLevel_StateEmpty()
  local response = SetGvdResponse({"fuelLevel_State"})
  response["fuelLevel_State"] = ""
  self:getVehicleDataResponseInvalidData(response)
end
--End Test Case NegativeResponseCheck6.4

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.5
--Description: Check response with vin empty
function Test:GetVehicleData_vinEmpty()
  local response = SetGvdResponse({"vin"})
  response["vin"] = ""
  self:getVehicleDataResponseInvalidData(response)
end
--End Test Case NegativeResponseCheck6.5

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.6
--Description: Check response with prndl empty
function Test:GetVehicleData_prndlEmpty()
  local response = SetGvdResponse({"prndl"})
  response["prndl"] = ""
  self:getVehicleDataResponseInvalidData(response)
end
--End Test Case NegativeResponseCheck6.6

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.7
--Description: Check response with tirePressure empty
-- It's already covered in function VerifyTirePressureParameter.
--End Test Case NegativeResponseCheck6.7

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.8
--Description: Check response with pressureTelltale empty
-- It's already covered in function VerifyTirePressureParameter.
--End Test Case NegativeResponseCheck6.8

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.9
--Description: Check response with parameters in tirePressure structure empty

-- -- It's already covered in function VerifyTirePressureParameter.
--End Test Case NegativeResponseCheck6.9

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.10
--Description: Check response with status of parameters in tirePressure structure empty
-- -- It's already covered in function VerifyTirePressureParameter.
--End Test Case NegativeResponseCheck6.10

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.11
-- It's already covered in function VerifyBeltStatusParameter()
--End Test Case NegativeResponseCheck6.11

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.12
--Description: Check response with parameters in beltStatus structure empty
-- It's already covered in function VerifyBeltStatusParameter()
--End Test Case NegativeResponseCheck6.12

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.13
--Description: Check response with bodyInformation empty
function Test:GetVehicleData_bodyInformationEmpty()
  local response = SetGvdResponse({"bodyInformation"})
  response["bodyInformation"] = {}
  self:getVehicleDataResponseInvalidData(response)
end
--End Test Case NegativeResponseCheck6.13

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.14
--Description: Check response with ignitionStableStatus empty
function Test:GetVehicleData_ignitionStableStatusEmpty()
  local response = SetGvdResponse({"bodyInformation"})
  response.bodyInformation["ignitionStableStatus"] = ""
  self:getVehicleDataResponseInvalidData(response)
end
--End Test Case NegativeResponseCheck6.14

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.15
--Description: Check response with ignitionStatus empty
function Test:GetVehicleData_ignitionStatusEmpty()
  local response = SetGvdResponse({"bodyInformation"})
  response.bodyInformation["ignitionStatus"] = ""
  self:getVehicleDataResponseInvalidData(response)
end
--End Test Case NegativeResponseCheck6.15

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.16
--Description: Check response with deviceStatus empty
-- It's already covered in function VerifyDeviceStatusParameter
--End Test Case NegativeResponseCheck6.16

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.17
--Description: Check response with battLevelStatus empty
-- It's already covered in function VerifyDeviceStatusParameter
--End Test Case NegativeResponseCheck6.17

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.18
--Description: Check response with signalLevelStatus empty
-- It's already covered in function VerifyDeviceStatusParameter
--End Test Case NegativeResponseCheck6.18

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.19
--Description: Check response with primaryAudioSource empty
-- It's already covered in function VerifyDeviceStatusParameter
--End Test Case NegativeResponseCheck6.19

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.20
--Description: Check response with driverBraking empty
function Test:GetVehicleDataDriverBrakingEmpty()
  local response = SetGvdResponse({"driverBraking"})
  response["driverBraking"] = ""
  self:getVehicleDataResponseInvalidData(response)
end
--End Test Case NegativeResponseCheck6.20

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.21
--Description: Check response with wiperStatus empty
function Test:GetVehicleDataWiperStatusEmpty()
  local response = SetGvdResponse({"wiperStatus"})
  response["wiperStatus"] = ""
  self:getVehicleDataResponseInvalidData(response)
end
--End Test Case NegativeResponseCheck6.21

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.22
--Description: Check response with headLampStatus empty
function Test:GetVehicleDataHeadLampStatusEmpty()
  local response = SetGvdResponse({"headLampStatus"})
  response["headLampStatus"] = {}
  self:getVehicleDataResponseInvalidData(response)
end
--End Test Case NegativeResponseCheck6.22

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.23
--Description: Check response with ambientLightSensorStatus empty
function Test:GetVehicleDataAmbientLightSensorStatusEmpty()
  local response = SetGvdResponse({"headLampStatus"})
  response.headLampStatus["ambientLightSensorStatus"] = ""
  self:getVehicleDataResponseInvalidData(response)
end
--End Test Case NegativeResponseCheck6.23

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.24
--Description: Check response with eCallInfo empty
function Test:GetVehicleDataECallInfoEmpty()
  local response = SetGvdResponse({"eCallInfo"})
  response["eCallInfo"] = {}
  self:getVehicleDataResponseInvalidData(response)
end
--End Test Case NegativeResponseCheck6.24

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.25
--Description: Check response with parameters in beltStatus structure empty
local ECALL_INFO_PARAMS = {"eCallNotificationStatus", "auxECallNotificationStatus", "eCallConfirmationStatus"}
for i=1, #ECALL_INFO_PARAMS do
  Test["GetVehicleData_"..ECALL_INFO_PARAMS[i].."Empty"] = function(self)
    local response = SetGvdResponse({"eCallInfo"})
    response.eCallInfo[ECALL_INFO_PARAMS[i]] = ""
    self:getVehicleDataResponseInvalidData(response)
  end
end
--End Test Case NegativeResponseCheck6.26

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.27
--Description: Check response with airbagStatus empty
function Test:GetVehicleDataAirbagStatusEmpty()
  local response = SetGvdResponse({"airbagStatus"})
  response["airbagStatus"] = {}
  self:getVehicleDataResponseInvalidData(response)
end
--End Test Case NegativeResponseCheck6.27

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.28
--Description: Check response with parameters in airbagStatus structure empty
for i=1, #AIRBAG_STATUS_PARAMS do
  Test["GetVehicleData_"..AIRBAG_STATUS_PARAMS[i].."Empty"] = function(self)
    local response = SetGvdResponse({"airbagStatus"})
    response.airbagStatus[AIRBAG_STATUS_PARAMS[i]] = ""
    self:getVehicleDataResponseInvalidData(response)
  end
end
--End Test Case NegativeResponseCheck6.28

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.29
--Description: Check response with emergencyEvent empty
function Test:GetVehicleDataEmergencyEventEmpty()
  local response = SetGvdResponse({"emergencyEvent"})
  response["emergencyEvent"] = {}
  self:getVehicleDataResponseInvalidData(response)
end
--End Test Case NegativeResponseCheck6.29

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.30
--Description: Check response with parameters in airbagStatus structure empty
local EMERGENCY_EVENT_PARAMS = {"emergencyEventType", "fuelCutoffStatus", "rolloverEvent", "multipleEvents"}
for i=1, #EMERGENCY_EVENT_PARAMS do
  Test["GetVehicleData_"..EMERGENCY_EVENT_PARAMS[i].."Empty"] = function(self)
    local response = SetGvdResponse({"emergencyEvent"})
    response.emergencyEvent[EMERGENCY_EVENT_PARAMS[i]] = ""
    self:getVehicleDataResponseInvalidData(response)
  end
end
--End Test Case NegativeResponseCheck6.30

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.31
--Description: Check response with clusterModeStatus empty
function Test:GetVehicleDataClusterModeStatusEmpty()
  local response = SetGvdResponse({"clusterModeStatus"})
  response["clusterModeStatus"] = {}
  self:getVehicleDataResponseInvalidData(response)
end
--End Test Case NegativeResponseCheck6.31

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.32
--Description: Check response with parameters in airbagStatus structure empty
local CLUSTER_MODE_STATUS_PARAMS = {"powerModeQualificationStatus", "carModeStatus", "powerModeStatus"}
for i=1, #CLUSTER_MODE_STATUS_PARAMS do
  Test["GetVehicleData_"..CLUSTER_MODE_STATUS_PARAMS[i].."Empty"] = function(self)
    local response = SetGvdResponse({"clusterModeStatus"})
    response.clusterModeStatus[CLUSTER_MODE_STATUS_PARAMS[i]] = ""
    self:getVehicleDataResponseInvalidData(response)
  end
end
--End Test Case NegativeResponseCheck6.32

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.33
--Description: Check response with myKey empty
function Test:GetVehicleDataMyKeyEmpty()
  local response = SetGvdResponse({"myKey"})
  response["myKey"] = {}
  self:getVehicleDataResponseInvalidData(response)
end
--End Test Case NegativeResponseCheck6.33

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck6.34
--Description: Check response with e911Override empty
function Test:GetVehicleDataE911OverrideEmpty()
  local response = SetGvdResponse({"myKey"})
  response.myKey["e911Override"] = ""
  self:getVehicleDataResponseInvalidData(response)
end
--End Test Case NegativeResponseCheck6.34
--End Test case NegativeResponseCheck.6

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.7
--Description: Check processing response with parameters missing

--Requirement id in JAMA:
--SDLAQ-CRS-98

--Verification criteria:
-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription.

--Begin Test Case NegativeResponseCheck.7.1
--Description: Check response with parameters in gps structure missing
-- It's already covered in function VerifyGpsParameter()
--End Test Case NegativeResponseCheck.7.1

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.7.2
--Description: Check response with parameters in tirePressure structure missing
-- It's already covered in function VerifyTirePressureParameter.
--End Test Case NegativeResponseCheck.7.2

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.7.3
--Description: Check response with parameters in beltStatus structure missing
-- It's already covered in function VerifyBeltStatusParameter()
--End Test Case NegativeResponseCheck.7.3

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.7.4
--Description: Check response with parameters in bodyInformation structure missing
local BODY_INFORMATION_PARAMS = {"parkBrakeActive", "ignitionStableStatus", "ignitionStatus", "driverDoorAjar", "passengerDoorAjar", "rearLeftDoorAjar", "rearRightDoorAjar"}
for i=1, #BODY_INFORMATION_PARAMS do
  if i<4 then
    Test["GetVehicleData_"..BODY_INFORMATION_PARAMS[i].."Missing"] = function(self)
      local response = SetGvdResponse({"bodyInformation"})
      response.bodyInformation[BODY_INFORMATION_PARAMS[i]] = nil
      self:getVehicleDataResponseInvalidData(response)
    end
  else
    Test["GetVehicleData_"..BODY_INFORMATION_PARAMS[i].."Missing"] = function(self)
      local response = SetGvdResponse({"bodyInformation"})
      response.bodyInformation[BODY_INFORMATION_PARAMS[i]] = nil
      self:getVehicleDataResponseSuccess(response)
    end
  end
end
--End Test Case NegativeResponseCheck.7.4

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.7.5
--Description: Check response with parameters in deviceStatus structure missing
-- It's already covered in function VerifyDeviceStatusParameter
--End Test Case NegativeResponseCheck.7.5

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.7.6
--Description: Check response with parameters in headLampStatus structure missing
local HEAD_LAMP_STATUS_PARAMS = {"lowBeamsOn", "highBeamsOn", "ambientLightSensorStatus"}
for i=1, #HEAD_LAMP_STATUS_PARAMS do
  Test["GetVehicleData_"..HEAD_LAMP_STATUS_PARAMS[i].."Missing"] = function(self)
    local response = SetGvdResponse({"headLampStatus"})
    response.headLampStatus[HEAD_LAMP_STATUS_PARAMS[i]] = nil
    self:getVehicleDataResponseInvalidData(response)
  end
end
--End Test Case NegativeResponseCheck.7.6

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.7.7
--Description: Check response with parameters in eCallInfo structure missing
for i=1, #ECALL_INFO_PARAMS do
  Test["GetVehicleData_"..ECALL_INFO_PARAMS[i].."Missing"] = function(self)
    local response = SetGvdResponse({"eCallInfo"})
    response.eCallInfo[ECALL_INFO_PARAMS[i]] = nil
    self:getVehicleDataResponseInvalidData(response)
  end
end
--End Test Case NegativeResponseCheck.7.7

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.7.8
--Description: Check response with parameters in airbagStatus structure missing
for i=1, #AIRBAG_STATUS_PARAMS do
  Test["GetVehicleData_"..AIRBAG_STATUS_PARAMS[i].."Missing"] = function(self)
    local response = SetGvdResponse({"airbagStatus"})
    response.airbagStatus[AIRBAG_STATUS_PARAMS[i]] = nil
    self:getVehicleDataResponseInvalidData(response)
  end
end
--End Test Case NegativeResponseCheck.7.8

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.7.9
--Description: Check response with parameters in emergencyEvent structure missing
local EMERGENCY_EVENT_PARAMS = {"emergencyEventType", "fuelCutoffStatus", "rolloverEvent", "maximumChangeVelocity", "multipleEvents"}
for i=1, #EMERGENCY_EVENT_PARAMS do
  Test["GetVehicleData_"..EMERGENCY_EVENT_PARAMS[i].."Missing"] = function(self)
    local response = SetGvdResponse({"emergencyEvent"})
    response.emergencyEvent[EMERGENCY_EVENT_PARAMS[i]] = nil
    self:getVehicleDataResponseInvalidData(response)
  end
end
--End Test Case NegativeResponseCheck.7.9

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.7.10
--Description: Check response with parameters in clusterModeStatus structure missing
local CLUSTER_MODE_STATUS_PARAMS = {"powerModeActive", "powerModeQualificationStatus", "carModeStatus", "powerModeStatus"}
for i=1, #CLUSTER_MODE_STATUS_PARAMS do
  Test["GetVehicleData_"..CLUSTER_MODE_STATUS_PARAMS[i].."Missing"] = function(self)
    local response = SetGvdResponse({"clusterModeStatus"})
    response.clusterModeStatus[CLUSTER_MODE_STATUS_PARAMS[i]] = nil
    self:getVehicleDataResponseInvalidData(response)
  end
end
--End Test Case NegativeResponseCheck.7.10

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.7.11
--Description: Check response with parameters in myKey structure missing
function Test:GetVehicleDataE911OverrideMissing()
  local response = SetGvdResponse({"myKey"})
  response.myKey["e911Override"] = nil
  self:getVehicleDataResponseInvalidData(response)
end
--End Test Case NegativeResponseCheck.7.11
--End Test case NegativeResponseCheck.7

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.8
--Description: Check processing response with wrong type of parameters

--Requirement id in JAMA:
--SDLAQ-CRS-98
--Requirement in JIRA:
--APPLINK-15258
--Verification criteria:
-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription.

--Begin Test Case NegativeResponseCheck.8.1
--Description: Check response with parameters in gps structure WrongType
-- It's already covered in function VerifyGpsParameter()
--End Test Case NegativeResponseCheck.8.1

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.8.2
--Description: Check response with parameters in tirePressure structure WrongType
-- It's already covered in function VerifyTirePressureParameter.
--End Test Case NegativeResponseCheck.8.2

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.8.3
--Description: Check response with parameters in beltStatus structure WrongType
-- It's already covered in function VerifyBeltStatusParameter()
--End Test Case NegativeResponseCheck.8.3

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.8.4
--Description: Check response with parameters in bodyInformation structure WrongType
local BODY_INFORMATION_PARAMS = {"parkBrakeActive", "ignitionStableStatus", "ignitionStatus", "driverDoorAjar", "passengerDoorAjar", "rearLeftDoorAjar", "rearRightDoorAjar"}
for i=1, #BODY_INFORMATION_PARAMS do
  Test["GetVehicleData_"..BODY_INFORMATION_PARAMS[i].."WrongType"] = function(self)
    local response = SetGvdResponse({"bodyInformation"})
    response.bodyInformation[BODY_INFORMATION_PARAMS[i]] = 1234
    self:getVehicleDataResponseInvalidData(response)
  end
end
--End Test Case NegativeResponseCheck.8.4

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.8.5
--Description: Check response with parameters in deviceStatus structure WrongType
-- It's already covered in function VerifyDeviceStatusParameter
--End Test Case NegativeResponseCheck.8.5

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.8.6
--Description: Check response with parameters in headLampStatus structure WrongType
local HEAD_LAMP_STATUS_PARAMS = {"lowBeamsOn", "highBeamsOn", "ambientLightSensorStatus"}
for i=1, #HEAD_LAMP_STATUS_PARAMS do
  Test["GetVehicleData_"..HEAD_LAMP_STATUS_PARAMS[i].."WrongType"] = function(self)
    local response = SetGvdResponse({"headLampStatus"})
    response.headLampStatus[HEAD_LAMP_STATUS_PARAMS[i]] = 1234
    self:getVehicleDataResponseInvalidData(response)
  end
end
--End Test Case NegativeResponseCheck.8.6

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.8.7
--Description: Check response with parameters in eCallInfo structure WrongType
for i=1, #ECALL_INFO_PARAMS do
  Test["GetVehicleData_"..ECALL_INFO_PARAMS[i].."WrongType"] = function(self)
    local response = SetGvdResponse({"eCallInfo"})
    response.eCallInfo[ECALL_INFO_PARAMS[i]] = 1234
    self:getVehicleDataResponseInvalidData(response)
  end
end
--End Test Case NegativeResponseCheck.8.7

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.8.8
--Description: Check response with parameters in airbagStatus structure WrongType
for i=1, #AIRBAG_STATUS_PARAMS do
  Test["GetVehicleData_"..AIRBAG_STATUS_PARAMS[i].."WrongType"] = function(self)
    local response = SetGvdResponse({"airbagStatus"})
    response.airbagStatus[AIRBAG_STATUS_PARAMS[i]] = 1234
    self:getVehicleDataResponseInvalidData(response)
  end
end
--End Test Case NegativeResponseCheck.8.8

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.8.9
--Description: Check response with parameters in emergencyEvent structure WrongType
for i=1, #EMERGENCY_EVENT_PARAMS do
  Test["GetVehicleData_"..EMERGENCY_EVENT_PARAMS[i].."WrongType"] = function(self)
    local response = SetGvdResponse({"emergencyEvent"})
    response.emergencyEvent[EMERGENCY_EVENT_PARAMS[i]] = 1234
    self:getVehicleDataResponseInvalidData(response)
  end
end
--End Test Case NegativeResponseCheck.8.9

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.8.10
--Description: Check response with parameters in clusterModeStatus structure WrongType
local CLUSTER_MODE_STATUS_PARAMS = {"powerModeActive", "powerModeQualificationStatus", "carModeStatus", "powerModeStatus"}
for i=1, #CLUSTER_MODE_STATUS_PARAMS do
  Test["GetVehicleData_"..CLUSTER_MODE_STATUS_PARAMS[i].."WrongType"] = function(self)
    local response = SetGvdResponse({"clusterModeStatus"})
    response.clusterModeStatus[CLUSTER_MODE_STATUS_PARAMS[i]] = 1234
    self:getVehicleDataResponseInvalidData(response)
  end
end
--End Test Case NegativeResponseCheck.8.10

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.8.11
--Description: Check response with parameters in myKey structure WrongType
function Test:GetVehicleDataE911OverrideWrongType()
  local response = SetGvdResponse({"myKey"})
  response.myKey["e911Override"] = 1234
  self:getVehicleDataResponseInvalidData(response)
end
--End Test Case NegativeResponseCheck.8.11

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.8.12
--Description: Check response with wrong type of vehicleData parameters
for i=1, #ALL_VEHICLE_DATA do
  Test["GetVehicleData_Response"..ALL_VEHICLE_DATA[i].."WrongType"] = function(self)
    local response = SetGvdResponse(ALL_VEHICLE_DATA)
    if
    ALL_VEHICLE_DATA[i] == "rpm" or
    ALL_VEHICLE_DATA[i] == "instantFuelConsumption" or
    ALL_VEHICLE_DATA[i] == "engineTorque" or
    ALL_VEHICLE_DATA[i] == "steeringWheelAngle" or
    ALL_VEHICLE_DATA[i] == "odometer" then
      response[ALL_VEHICLE_DATA[i]] = "1234"
    else
      response[ALL_VEHICLE_DATA[i]] = 1234
    end
    self:getVehicleDataResponseInvalidData(response)
  end
end
--End Test Case NegativeResponseCheck.8.12
--End Test case NegativeResponseCheck.8

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.9
--Description: Check processing response with parameters with nonexistent value

--Requirement id in JAMA:
--SDLAQ-CRS-98

--Verification criteria:
-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription.

--Begin Test Case NegativeResponseCheck.9.1
--Description: Check response with nonexistent value for compassDirection parameters
-- It's already covered in function VerifyGpsParameter()
--End Test Case NegativeResponseCheck.9.1

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.9.2
--Description: Check response with nonexistent value for fuelLevel_State parameters
function Test:GetVehicleDataFuelLevelStateNotExist()
  local response = SetGvdResponse({"fuelLevel_State"})
  response["fuelLevel_State"] = "ANY"
  self:getVehicleDataResponseInvalidData(response)
end
--End Test Case NegativeResponseCheck.9.2

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.9.3
--Description: Check response with nonexistent value for prndl parameters
function Test:GetVehicleDataPrndlNotExist()
  local response = SetGvdResponse({"prndl"})
  response["prndl"] = "ANY"
  self:getVehicleDataResponseInvalidData(response)
end
--End Test Case NegativeResponseCheck.9.3

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.9.4
--Description: Check response with nonexistent value for pressureTelltale parameters
-- It's already covered in function VerifyTirePressureParameter.
--End Test Case NegativeResponseCheck.9.4

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.9.5
--Description: Check response with nonexistent value for tirePressure status
-- It's already covered in function VerifyTirePressureParameter.
--End Test Case NegativeResponseCheck.9.5

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.9.6
--Description: Check response with nonexistent value for beltStatus status
-- It's already covered in function VerifyBeltStatusParameter()
--End Test Case NegativeResponseCheck.9.6

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.9.7
--Description: Check response with nonexistent value for ignitionStableStatus parameters
function Test:GetVehicleDataIgnitionStableStatusNotExist()
  local response = SetGvdResponse({"bodyInformation"})
  response.bodyInformation["ignitionStableStatus"] = "ANY"
  self:getVehicleDataResponseInvalidData(response)
end
--End Test Case NegativeResponseCheck.9.7

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.9.8
--Description: Check response with nonexistent value for ignitionStatus parameters
function Test:GetVehicleDataIgnitionStatusNotExist()
  local response = SetGvdResponse({"bodyInformation"})
  response.bodyInformation["ignitionStatus"] = "ANY"
  self:getVehicleDataResponseInvalidData(response)
end
--End Test Case NegativeResponseCheck.9.8

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.9.9
--Description: Check response with nonexistent value for battLevelStatus parameters
-- It's already covered in function VerifyDeviceStatusParameter
--End Test Case NegativeResponseCheck.9.9

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.9.10
--Description: Check response with nonexistent value for signalLevelStatus parameters
-- It's already covered in function VerifyDeviceStatusParameter
--End Test Case NegativeResponseCheck.9.10

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.9.11
--Description: Check response with nonexistent value for primaryAudioSource parameters
-- It's already covered in function VerifyDeviceStatusParameter
--End Test Case NegativeResponseCheck.9.11

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.9.12
--Description: Check response with nonexistent value for driverBraking parameters
function Test:GetVehicleDataDriverBrakingNotExist()
  local response = SetGvdResponse({"driverBraking"})
  response["driverBraking"] = "ANY"
  self:getVehicleDataResponseInvalidData(response)
end
--End Test Case NegativeResponseCheck.9.12

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.9.13
--Description: Check response with nonexistent value for wiperStatus parameters
function Test:GetVehicleDataWiperStatusNotExist()
  local response = SetGvdResponse({"wiperStatus"})
  response["wiperStatus"] = "ANY"
  self:getVehicleDataResponseInvalidData(response)
end
--End Test Case NegativeResponseCheck.9.13

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.9.14
--Description: Check response with nonexistent value for ambientLightSensorStatus parameters
function Test:GetVehicleDataAmbientLightSensorStatusNotExist()
  local response = SetGvdResponse({"headLampStatus"})
  response.headLampStatus["ambientLightSensorStatus"] = "ANY"
  self:getVehicleDataResponseInvalidData(response)
end
--End Test Case NegativeResponseCheck.9.14

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.9.15
--Description: Check response with nonexistent value for parameters in eCallInfo structure
for i=1, #ECALL_INFO_PARAMS do
  Test["GetVehicleData_"..ECALL_INFO_PARAMS[i].."_NotExist"] = function(self)
    local response = SetGvdResponse({"eCallInfo"})
    response.eCallInfo[ECALL_INFO_PARAMS[i]] = "ANY"
    self:getVehicleDataResponseInvalidData(response)
  end
end
--End Test Case NegativeResponseCheck.9.15

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.9.16
--Description: Check response with nonexistent value for parameters in airbagStatus structure
for i=1, #AIRBAG_STATUS_PARAMS do
  Test["GetVehicleData_"..AIRBAG_STATUS_PARAMS[i].."_NotExist"] = function(self)
    local response = SetGvdResponse({"airbagStatus"})
    response.airbagStatus[AIRBAG_STATUS_PARAMS[i]] = "ANY"
    self:getVehicleDataResponseInvalidData(response)
  end
end
--End Test Case NegativeResponseCheck.9.16

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.9.17
--Description: Check response with nonexistent value for parameters in emergencyEvent structure
local EMERGENCY_EVENT_PARAMS = {"emergencyEventType", "fuelCutoffStatus", "rolloverEvent", "multipleEvents"}
for i=1, #EMERGENCY_EVENT_PARAMS do
  Test["GetVehicleData_"..EMERGENCY_EVENT_PARAMS[i].."_NotExist"] = function(self)
    local response = SetGvdResponse({"emergencyEvent"})
    response.emergencyEvent[EMERGENCY_EVENT_PARAMS[i]] = "ANY"
    self:getVehicleDataResponseInvalidData(response)
  end
end
--End Test Case NegativeResponseCheck.9.17

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.9.18
--Description: Check response with nonexistent value for parameters in clusterModeStatus structure
local CLUSTER_MODE_STATUS_PARAMS = {"powerModeQualificationStatus", "carModeStatus", "powerModeStatus"}
for i=1, #CLUSTER_MODE_STATUS_PARAMS do
  Test["GetVehicleData_"..CLUSTER_MODE_STATUS_PARAMS[i].."_NotExist"] = function(self)
    local response = SetGvdResponse({"clusterModeStatus"})
    response.clusterModeStatus[CLUSTER_MODE_STATUS_PARAMS[i]] = "ANY"
    self:getVehicleDataResponseInvalidData(response)
  end
end
--End Test Case NegativeResponseCheck.9.18

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.9.19
--Description: Check response with nonexistent value for e911Override parameters
function Test:GetVehicleDataE911OverrideNotExist()
  local response = SetGvdResponse({"myKey"})
  response.myKey["e911Override"] = "ANY"
  self:getVehicleDataResponseInvalidData(response)
end
--End Test Case NegativeResponseCheck.9.19

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.9.20
--Description: Check response with nonexistent value for dimension parameters
-- It's already covered in function VerifyGpsParameter()
--End Test Case NegativeResponseCheck.9.20
--End Test case NegativeResponseCheck.9

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.10
--Description: Check processing response with parameters with invalid characters

--Requirement id in JAMA:
--SDLAQ-CRS-98

--Verification criteria:
-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription.

--Begin Test Case NegativeResponseCheck.10.1
--Description: Escape sequence \n in vin parameter
function Test:GetVehicleDataVinNewLineChar()
  local response = SetGvdResponse({"vin"})
  response["vin"] = "123\n"
  self:getVehicleDataResponseInvalidData(response)
end
--End Test Case NegativeResponseCheck.10.1

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.10.2
--Description: Escape sequence \t in vin parameter
function Test:GetVehicleDataVinNewTabChar()
  local response = SetGvdResponse({"vin"})
  response["vin"] = "123\t"
  self:getVehicleDataResponseInvalidData(response)
end
--End Test Case NegativeResponseCheck.10.2

-----------------------------------------------------------------------------------------

--Begin Test Case NegativeResponseCheck.10.3
--Description: White space only in vin parameter
function Test:GetVehicleDataVinWhiteSpacesOnly()
  local response = SetGvdResponse({"vin"})
  response["vin"] = " "
  self:getVehicleDataResponseInvalidData(response)
end
--End Test Case NegativeResponseCheck.10.3
--Begin Test case NegativeResponseCheck.10

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11
--Description: Check processing response with parameters with out lower bound and upper bound value

--Requirement id in JAMA:
--SDLAQ-CRS-98

--Verification criteria:
-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription.

--Begin Test case NegativeResponseCheck.11.1
--Description: Response with longitudeDegrees parameter out of lower bound
-- It's already covered in function VerifyGpsParameter()
--End Test case NegativeResponseCheck.11.1

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.2
--Description: Response with longitudeDegrees parameter out of upper bound
-- It's already covered in function VerifyGpsParameter()
--End Test case NegativeResponseCheck.11.2

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.3
--Description: Response with latitudeDegrees parameter out of lower bound
-- It's already covered in function VerifyGpsParameter()
--End Test case NegativeResponseCheck.11.3

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.4
--Description: Response with latitudeDegrees parameter out of upper bound
-- It's already covered in function VerifyGpsParameter()
--End Test case NegativeResponseCheck.11.4

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.5
--Description: Response with utcYear parameter out of lower bound
-- It's already covered in function VerifyGpsParameter()
--End Test case NegativeResponseCheck.11.5

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.6
--Description: Response with utcYear parameter out of upper bound
-- It's already covered in function VerifyGpsParameter()
--End Test case NegativeResponseCheck.11.6

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.7
--Description: Response with utcMonth parameter out of lower bound
-- It's already covered in function VerifyGpsParameter()
--End Test case NegativeResponseCheck.11.7

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.8
--Description: Response with utcMonth parameter out of upper bound
-- It's already covered in function VerifyGpsParameter()
--End Test case NegativeResponseCheck.11.8

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.9
--Description: Response with utcDay parameter out of lower bound
-- It's already covered in function VerifyGpsParameter()
--End Test case NegativeResponseCheck.11.9

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.10
--Description: Response with utcDay parameter out of upper bound
-- It's already covered in function VerifyGpsParameter()
--End Test case NegativeResponseCheck.11.10

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.11
--Description: Response with utcHours parameter out of lower bound
-- It's already covered in function VerifyGpsParameter()
--End Test case NegativeResponseCheck.11.11

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.12
--Description: Response with utcHours parameter out of upper bound
-- It's already covered in function VerifyGpsParameter()
--End Test case NegativeResponseCheck.11.12

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.13
--Description: Response with utcMinutes parameter out of lower bound
-- It's already covered in function VerifyGpsParameter()
--End Test case NegativeResponseCheck.11.13

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.14
--Description: Response with utcMinutes parameter out of upper bound
-- It's already covered in function VerifyGpsParameter()
--End Test case NegativeResponseCheck.11.14

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.15
--Description: Response with utcSeconds parameter out of lower bound
-- It's already covered in function VerifyGpsParameter()
--End Test case NegativeResponseCheck.11.15

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.16
--Description: Response with utcSeconds parameter out of upper bound
-- It's already covered in function VerifyGpsParameter()
--End Test case NegativeResponseCheck.11.16

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.17
--Description: Response with pdop parameter out of lower bound
-- It's already covered in function VerifyGpsParameter()
--End Test case NegativeResponseCheck.11.17

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.18
--Description: Response with pdop parameter out of upper bound
-- It's already covered in function VerifyGpsParameter()
--End Test case NegativeResponseCheck.11.18

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.19
--Description: Response with hdop parameter out of lower bound
-- It's already covered in function VerifyGpsParameter()
--End Test case NegativeResponseCheck.11.19

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.20
--Description: Response with hdop parameter out of upper bound
-- It's already covered in function VerifyGpsParameter()
--End Test case NegativeResponseCheck.11.20

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.21
--Description: Response with vdop parameter out of lower bound
-- It's already covered in function VerifyGpsParameter()
--End Test case NegativeResponseCheck.11.21

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.22
--Description: Response with vdop parameter out of upper bound
-- It's already covered in function VerifyGpsParameter()
--End Test case NegativeResponseCheck.11.22

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.23
--Description: Response with satellites parameter out of lower bound
-- It's already covered in function VerifyGpsParameter()
--End Test case NegativeResponseCheck.11.23

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.24
--Description: Response with satellites parameter out of upper bound
-- It's already covered in function VerifyGpsParameter()
--End Test case NegativeResponseCheck.11.24

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.25
--Description: Response with altitude parameter out of lower bound
-- It's already covered in function VerifyGpsParameter()
--End Test case NegativeResponseCheck.11.25

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.26
--Description: Response with altitude parameter out of upper bound
-- It's already covered in function VerifyGpsParameter()
--End Test case NegativeResponseCheck.11.26

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.27
--Description: Response with heading parameter out of lower bound
-- It's already covered in function VerifyGpsParameter()
--End Test case NegativeResponseCheck.11.27

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.28
--Description: Response with heading parameter out of upper bound
-- It's already covered in function VerifyGpsParameter()
--End Test case NegativeResponseCheck.11.28

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.29
--Description: Response with gps.speed parameter out of lower bound
-- It's already covered in function VerifyGpsParameter()
--End Test case NegativeResponseCheck.11.29

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.30
--Description: Response with gps.speed parameter out of upper bound
-- -- It's already covered in function VerifyGpsParameter()
--End Test case NegativeResponseCheck.11.30

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.31
--Description: Response with speed parameter out of lower bound
function Test:GetVehicleDataResponseOutLowerBoundSpeed()
  local response = SetGvdResponse({"speed"})
  response["speed"] = -0.1
  self:getVehicleDataResponseInvalidData(response)
end
--End Test case NegativeResponseCheck.11.31

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.32
--Description: Response with speed parameter out of upper bound
function Test:GetVehicleDataResponseOutUpperBoundSpeed()
  local response = SetGvdResponse({"speed"})
  response["speed"] = 700.1
  self:getVehicleDataResponseInvalidData(response)
end
--End Test case NegativeResponseCheck.11.32

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.33
--Description: Response with rpm parameter out of lower bound
function Test:GetVehicleDataResponseOutLowerBoundRpm()
  local response = SetGvdResponse({"rpm"})
  response["rpm"] = -1
  self:getVehicleDataResponseInvalidData(response)
end
--End Test case NegativeResponseCheck.11.33

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.34
--Description: Response with rpm parameter out of upper bound
function Test:GetVehicleDataResponseOutUpperBoundRpm()
  local response = SetGvdResponse({"rpm"})
  response["rpm"] = 20001
  self:getVehicleDataResponseInvalidData(response)
end
--End Test case NegativeResponseCheck.11.34

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.35
--Description: Response with fuelLevel parameter out of lower bound
function Test:GetVehicleDataResponseOutLowerBoundFuelLevel()
  local response = SetGvdResponse({"fuelLevel"})
  response["fuelLevel"] = -6.1
  self:getVehicleDataResponseInvalidData(response)
end
--End Test case NegativeResponseCheck.11.35

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.36
--Description: Response with fuelLevel parameter out of upper bound
function Test:GetVehicleDataResponseOutUpperBoundFuelLevel()
  local response = SetGvdResponse({"fuelLevel"})
  response["fuelLevel"] = 106.1
  self:getVehicleDataResponseInvalidData(response)
end
--End Test case NegativeResponseCheck.11.36

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.37
--Description: Response with instantFuelConsumption parameter out of lower bound
function Test:GetVehicleDataResponseOutLowerBoundInstantFuelConsumption()
  local response = SetGvdResponse({"instantFuelConsumption"})
  response["instantFuelConsumption"] = -0.1
  self:getVehicleDataResponseInvalidData(response)
end
--End Test case NegativeResponseCheck.11.37

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.38
--Description: Response with instantFuelConsumption parameter out of upper bound
function Test:GetVehicleDataResponseOutUpperBoundInstantFuelConsumption()
  local response = SetGvdResponse({"instantFuelConsumption"})
  response["instantFuelConsumption"] = 25575.1
  self:getVehicleDataResponseInvalidData(response)
end
--End Test case NegativeResponseCheck.11.38

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.39
--Description: Response with externalTemperature parameter out of lower bound
function Test:GetVehicleDataResponseOutLowerBoundExternalTemperature()
  local response = SetGvdResponse({"externalTemperature"})
  response["externalTemperature"] = -40.1
  self:getVehicleDataResponseInvalidData(response)
end
--End Test case NegativeResponseCheck.11.39

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.40
--Description: Response with externalTemperature parameter out of upper bound
function Test:GetVehicleDataResponseOutUpperBoundExternalTemperature()
  local response = SetGvdResponse({"externalTemperature"})
  response["externalTemperature"] = 100.1
  self:getVehicleDataResponseInvalidData(response)
end
--End Test case NegativeResponseCheck.11.40

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.41
--Description: Response with vin parameter out of lower bound
function Test:GetVehicleDataResponseOutLowerBoundVin()
  local response = SetGvdResponse({"vin"})
  response["vin"] = ""
  self:getVehicleDataResponseInvalidData(response)
end
--End Test case NegativeResponseCheck.11.41

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.42
--Description: Response with vin parameter out of upper bound
function Test:GetVehicleDataResponseOutUpperBoundVin()
  local response = SetGvdResponse({"vin"})
  response["vin"] = "123456789123456789"
  self:getVehicleDataResponseInvalidData(response)
end
--End Test case NegativeResponseCheck.11.42

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.43
--Description: Response with odometer parameter out of lower bound
function Test:GetVehicleDataResponseOutLowerBoundOdometer()
  local response = SetGvdResponse({"odometer"})
  response["odometer"] = -1
  self:getVehicleDataResponseInvalidData(response)
end
--End Test case NegativeResponseCheck.11.43

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.44
--Description: Response with odometer parameter out of upper bound
function Test:GetVehicleDataResponseOutUpperBoundOdometer()
  local response = SetGvdResponse({"odometer"})
  response["odometer"] = 17000001
  self:getVehicleDataResponseInvalidData(response)
end
--End Test case NegativeResponseCheck.11.44

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.45
--Description: Response with engineTorque parameter out of lower bound
function Test:GetVehicleDataResponseOutLowerBoundEngineTorque()
  local response = SetGvdResponse({"engineTorque"})
  response["engineTorque"] = -1000.1
  self:getVehicleDataResponseInvalidData(response)
end
--End Test case NegativeResponseCheck.11.45

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.46
--Description: Response with engineTorque parameter out of upper bound
function Test:GetVehicleDataResponseOutUpperBoundEngineTorque()
  local response = SetGvdResponse({"engineTorque"})
  response["engineTorque"] = 2000.1
  self:getVehicleDataResponseInvalidData(response)
end
--End Test case NegativeResponseCheck.11.46

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.47
--Description: Response with accPedalPosition parameter out of lower bound
function Test:GetVehicleDataResponseOutLowerBoundAccPedalPosition()
  local response = SetGvdResponse({"accPedalPosition"})
  response["accPedalPosition"] = -0.1
  self:getVehicleDataResponseInvalidData(response)
end
--End Test case NegativeResponseCheck.11.47

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.48
--Description: Response with accPedalPosition parameter out of upper bound
function Test:GetVehicleDataResponseOutUpperBoundAccPedalPosition()
  local response = SetGvdResponse({"accPedalPosition"})
  response["accPedalPosition"] = 100.1
  self:getVehicleDataResponseInvalidData(response)
end
--End Test case NegativeResponseCheck.11.48

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.49
--Description: Response with steeringWheelAngle parameter out of lower bound
function Test:GetVehicleDataResponseOutLowerBoundSteeringWheelAngle()
  local response = SetGvdResponse({"steeringWheelAngle"})
  response["steeringWheelAngle"] = -2000.1
  self:getVehicleDataResponseInvalidData(response)
end
--End Test case NegativeResponseCheck.11.49

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.50
--Description: Response with steeringWheelAngle parameter out of upper bound
function Test:GetVehicleDataResponseOutUpperBoundSteeringWheelAngle()
  local response = SetGvdResponse({"steeringWheelAngle"})
  response["steeringWheelAngle"] = 2000.1
  self:getVehicleDataResponseInvalidData(response)
end
--End Test case NegativeResponseCheck.11.50

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.51
--Description: Response with maximumChangeVelocity parameter out of lower bound
function Test:GetVehicleDataResponseOutLowerBoundMaximumChangeVelocity()
  local response = SetGvdResponse({"emergencyEvent"})
  response.emergencyEvent["maximumChangeVelocity"] = -1
  self:getVehicleDataResponseInvalidData(response)
end
--End Test case NegativeResponseCheck.11.51

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.11.52
--Description: Response with maximumChangeVelocity parameter out of upper bound
function Test:GetVehicleDataResponseOutUpperBoundMaximumChangeVelocity()
  local response = SetGvdResponse({"emergencyEvent"})
  response.emergencyEvent["maximumChangeVelocity"] = 256
  self:getVehicleDataResponseInvalidData(response)
end
--End Test case NegativeResponseCheck.11.52
--Begin Test case NegativeResponseCheck.11

local function VerifySubscribeVehicleDataEnumString_ParameterInResponse(ParameterName, DataType)
  
  --Print new line to separate new test cases group
  commonFunctions:newTestCasesGroup("PositiveResponseCheck: "..ParameterName)
  
  local Response = setSVDResponse(vehicleData)
  Response[ParameterName] = {
    dataType = DataType,
    resultCode = "SUCCESS"
  }
  Response["gps"] = {
    dataType = "VEHICLEDATA_GPS",
    resultCode = "SUCCESS"
  }
  
  ---------------------------------
  ----Verify Parameter
  local Parameter = {ParameterName}
  --1.1. IsMissed
  commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsMissed", nil, "SUCCESS")
  Test["PostCondition_UnSubscribeVehicleData_"..ParameterName.."_IsMissed"]=function(self)
    self:unSubscribeVehicleDataSuccess(vehicleData)
    DelayedExp(2000)
  end
  --1.2. IsWrongDataType
  commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsWrongDataType", 123, "GENERIC_ERROR")
  Test["PostCondition_UnSubscribeVehicleData_"..ParameterName.."_IsWrongDataType"]=function(self)
    self:unSubscribeVehicleDataSuccess(vehicleData)
    DelayedExp(2000)
  end
  --1.3. IsEmpty
  commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsEmpty", "", "GENERIC_ERROR")
  Test["PostCondition_UnSubscribeVehicleData_"..ParameterName.."_IsEmpty"]=function(self)
    self:unSubscribeVehicleDataSuccess(vehicleData)
    DelayedExp(2000)
  end
  
  ---------------------------------
  ----Verify Parameter.dataType
  local Parameter = {ParameterName, "dataType"}
  --2.1. IsMissed
  commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsMissed", nil, "GENERIC_ERROR")
  Test["PostCondition_UnSubscribeVehicleData_"..ParameterName.."_DataType_IsMissed"]=function(self)
    self:unSubscribeVehicleDataSuccess(vehicleData)
    DelayedExp(2000)
  end
  --2.2. IsWrongDataType
  commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsWrongDataType", 123, "GENERIC_ERROR")
  Test["PostCondition_UnSubscribeVehicleData_"..ParameterName.."_DataType_IsWrongDataType"]=function(self)
    self:unSubscribeVehicleDataSuccess(vehicleData)
    DelayedExp(2000)
  end
  --2.3. IsEmpty
  commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsEmpty", "", "GENERIC_ERROR")
  Test["PostCondition_UnSubscribeVehicleData_"..ParameterName.."_DataType_IsEmpty"]=function(self)
    self:unSubscribeVehicleDataSuccess(vehicleData)
    DelayedExp(2000)
  end
  --2.4. IsExistentValue
  commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsExistentValue_"..DataType, DataType, "SUCCESS")
  Test["PostCondition_UnSubscribeVehicleData_"..ParameterName.."_DataType_IsExistentValue"]=function(self)
    self:unSubscribeVehicleDataSuccess(vehicleData)
    DelayedExp(2000)
  end
  --2.5. IsNonexistentValue
  commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsNonexistentValue", "ANY", "GENERIC_ERROR")
  Test["PostCondition_UnSubscribeVehicleData_"..ParameterName.."_DataType_IsNoneExistentValue"]=function(self)
    self:unSubscribeVehicleDataSuccess(vehicleData)
    DelayedExp(2000)
  end
  
  --2.6. DataTypeOfAnother
  commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsExistentValue_DataTypeOfAnother", "VEHICLEDATA_GPS", "SUCCESS")
  Test["PostCondition_UnSubscribeVehicleData_"..ParameterName.."_DataType_IsExistentValueOfAnother"]=function(self)
    self:unSubscribeVehicleDataSuccess(vehicleData)
    DelayedExp(2000)
  end
  ---------------------------------
  ----Verify Parameter.resultCode
  local Parameter = {ParameterName, "resultCode"}
  --3.1. IsMissed
  commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsMissed", nil, "GENERIC_ERROR")
  Test["PostCondition_UnSubscribeVehicleData_"..ParameterName.."_ResultCode_IsMissed"]=function(self)
    self:unSubscribeVehicleDataSuccess(vehicleData)
    DelayedExp(2000)
  end
  --3.2. IsWrongDataType
  commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsWrongDataType", 123, "GENERIC_ERROR")
  Test["PostCondition_UnSubscribeVehicleData_"..ParameterName.."_ResultCode_IsWrongDataType"]=function(self)
    self:unSubscribeVehicleDataSuccess(vehicleData)
    DelayedExp(2000)
  end
  --3.3. IsEmpty
  commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsEmpty", "", "GENERIC_ERROR")
  Test["PostCondition_UnSubscribeVehicleData_"..ParameterName.."_ResultCode_IsEmpty"]=function(self)
    self:unSubscribeVehicleDataSuccess(vehicleData)
    DelayedExp(2000)
  end
  --3.4. IsExistentValue
  for i = 1, #AllVehicleDataResultCode do
    commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsExistentValue_"..AllVehicleDataResultCode[i], AllVehicleDataResultCode[i], "SUCCESS")
    
    Test["PostCondition_UnSubscribeVehicleData_"..ParameterName.."_resultCode_"..AllVehicleDataResultCode[i]]=function(self)
      self:unSubscribeVehicleData(vehicleData, AllVehicleDataResultCode[i], ParameterName, DataType)
      DelayedExp(2000)
    end
  end
  --3.5. IsNonexistentValue
  commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsNonexistentValue", "ANY", "GENERIC_ERROR")
  Test["PostCondition_UnSubscribeVehicleData_"..ParameterName.."_ResultCode_IsNonexistentValue"]=function(self)
    self:unSubscribeVehicleDataSuccess(vehicleData)
    DelayedExp(2000)
  end
end
--Requirement ID: APPLINK-15258
--Description: The application is not notified by the onVehicleData notification when HMI send gps with empty structure.
local function VerifyGpsParameter()
  --[[gps: type=Common.GPSData mandatory=false
  --name="longitudeDegrees" type="Float" minvalue="-180" maxvalue="180" mandatory="true",
  --name="latitudeDegrees" type="Float" minvalue="-90" maxvalue="90" mandatory="true",
  --name=pdop type=Float minvalue=0 maxvalue=10 mandatory=false
  --name=hdop type=Float minvalue=0 maxvalue=10 mandatory=false
  --name=vdop type=Float minvalue=0 maxvalue=10 mandatory=false
  --name=altitude type=Float minvalue=-10000 maxvalue=10000 mandatory=false
  --name=heading type=Float minvalue=0 maxvalue=359.99 mandatory=false
  --name=speed type=Float minvalue=0 maxvalue=500 mandatory=false
  
  --name="utcYear" type="Integer" minvalue="2010" maxvalue="2100" mandatory="false",
  --name="utcMonth" type="Integer" minvalue="1" maxvalue="12" mandatory="false",
  --name="utcDay" type="Integer" minvalue="1" maxvalue="31" mandatory="false",
  --name="utcHours" type="Integer" minvalue="0" maxvalue="23" mandatory="false",
  --name=utcMinutes type=Integer minvalue=0 maxvalue=59 mandatory=false
  --name=utcSeconds type=Integer minvalue=0 maxvalue=59 mandatory=false
  --name=satellites type=Integer minvalue=0 maxvalue=31 mandatory=false
  
  --name=actual type=Boolean mandatory=false
  --name=shifted type=Boolean mandatory=false
  --name=compassDirection type=Common.CompassDirection mandatory=false
  --name=dimension type=Common.Dimension mandatory=false
  ]]
  commonFunctions:newTestCasesGroup("Test suite for verifying: gps structure")
  
  local response = SetGvdResponse({"gps"})
  response.gps = {longitudeDegrees = 25,
    latitudeDegrees = 45,
    utcYear= 2015,
    utcMonth = 10,
    utcDay = 10,
    utcHours = 11,
    utcMinutes = 30,
    utcSeconds = 40,
    compassDirection = "NORTHEAST",
    pdop = 5,
    hdop = 5,
    vdop = 5,
    actual = true,
    satellites = 10,
    dimension = "NO_FIX",
    altitude = 10,
    heading = 100,
    speed = 250,
  shifted = false}
  --1. IsMissed
  commonFunctions:TestCaseForResponse(self, response, {"gps"}, "IsMissed", nil, "SUCCESS")
  --2. IsEmptyTable
  commonFunctions:TestCaseForResponse(self, response, {"gps"}, "IsEmptyTable", {}, "GENERIC_ERROR")
  --3. IsWrongDataType
  commonFunctions:TestCaseForResponse(self, response, {"gps"}, "IsWrongDataType", 123, "GENERIC_ERROR")
  --4. TCs for parameters
  --Description: verify parameters in GPS structure
  -- verify latitudeDegrees in case valid longitudeDegrees
  floatParameterInResponse:verify_Float_Parameter(response, {"gps", "latitudeDegrees"}, {-90.000000, 90.000000}, true)
  -- verify longitudeDegrees in case valid latitudeDegrees
  floatParameterInResponse:verify_Float_Parameter(response, {"gps", "longitudeDegrees"}, {-180.000000, 180.000000}, true)
  
  floatParameterInResponse:verify_Float_Parameter(response, {"gps", "pdop"}, {0.000000, 10.000000}, false)
  floatParameterInResponse:verify_Float_Parameter(response, {"gps", "hdop"}, {0.000000, 10.000000}, false)
  floatParameterInResponse:verify_Float_Parameter(response, {"gps", "vdop"}, {0.000000, 10.000000}, false)
  floatParameterInResponse:verify_Float_Parameter(response, {"gps", "altitude"}, {-10000.000000, 10000.000000}, false)
  floatParameterInResponse:verify_Float_Parameter(response, {"gps", "heading"}, {0.000000, 359.99}, false)
  floatParameterInResponse:verify_Float_Parameter(response, {"gps", "speed"}, {0.000000, 500.000000}, false)
  
  integerParameterInResponse:verify_Integer_Parameter(response, {"gps", "utcYear"}, {2010, 2100}, false)
  integerParameterInResponse:verify_Integer_Parameter(response, {"gps", "utcMonth"}, {1, 12}, false)
  integerParameterInResponse:verify_Integer_Parameter(response, {"gps", "utcDay"}, {1, 31}, false)
  integerParameterInResponse:verify_Integer_Parameter(response, {"gps", "utcHours"}, {0, 23}, false)
  integerParameterInResponse:verify_Integer_Parameter(response, {"gps", "utcMinutes"}, {0, 59}, false)
  integerParameterInResponse:verify_Integer_Parameter(response,{"gps", "utcSeconds"}, {0, 59}, false)
  integerParameterInResponse:verify_Integer_Parameter(response, {"gps", "satellites"}, {0, 31}, false)
  enumerationParameterInResponse:verify_Enum_String_Parameter(response, {"gps", "compassDirection"}, COMPASS_DIRECTION_VALUES, false)
  enumerationParameterInResponse:verify_Enum_String_Parameter(response, {"gps", "dimension"}, DIMENSION_VALUES, false)
  booleanParameterInResponse:verify_Boolean_Parameter(response, {"gps", "actual"}, false)
  booleanParameterInResponse:verify_Boolean_Parameter(response, {"gps", "shifted"}, false)
  
  function Test:GetVehicleData_GPS_AllMandatoryParams_Missed()
    response.gps["longitudeDegrees"] = nil
    response.gps["latitudeDegrees"] = nil
    self:getVehicleDataResponseInvalidData(response)
  end
end
VerifyGpsParameter()
local function VerifyBeltStatusParameter()
  --[[beltStatus: type=Common.BeltStatus mandatory=false
  --name="driverBeltDeployed" type="Common.VehicleDataEventStatus" mandatory="false"
  --name="passengerBeltDeployed" type="Common.VehicleDataEventStatus" mandatory="false"
  --name="passengerBuckleBelted" type="Common.VehicleDataEventStatus" mandatory="false"
  --name="driverBuckleBelted" type="Common.VehicleDataEventStatus" mandatory="false"
  --name="leftRow2BuckleBelted" type="Common.VehicleDataEventStatus" mandatory="false"
  --name="passengerChildDetected" type="Common.VehicleDataEventStatus" mandatory="false"
  --name="rightRow2BuckleBelted" type="Common.VehicleDataEventStatus" mandatory="false"
  --name="middleRow2BuckleBelted" type="Common.VehicleDataEventStatus" mandatory="false"
  --name="middleRow3BuckleBelted" type="Common.VehicleDataEventStatus" mandatory="false"
  --name="leftRow3BuckleBelted" type="Common.VehicleDataEventStatus" mandatory="false"
  --name="rightRow3BuckleBelted" type="Common.VehicleDataEventStatus" mandatory="false"
  --name="leftRearInflatableBelted" type="Common.VehicleDataEventStatus" mandatory="false"
  --name="rightRearInflatableBelted" type="Common.VehicleDataEventStatus" mandatory="false"
  --name="middleRow1BeltDeployed" type="Common.VehicleDataEventStatus" mandatory="false"
  --name="middleRow1BuckleBelted" type="Common.VehicleDataEventStatus" mandatory="false"]]
  commonFunctions:newTestCasesGroup("Test suite for verifying: beltStatus structure")
  local response = SetGvdResponse({"beltStatus"})
  response.beltStatus = {
    driverBeltDeployed = "NO_EVENT",
    passengerBeltDeployed = "NO_EVENT",
    passengerBuckleBelted = "NO_EVENT",
    driverBuckleBelted = "NO_EVENT",
    leftRow2BuckleBelted = "NO_EVENT",
    passengerChildDetected = "NO_EVENT",
    rightRow2BuckleBelted = "NO_EVENT",
    middleRow2BuckleBelted = "NO_EVENT",
    middleRow3BuckleBelted = "NO_EVENT",
    leftRow3BuckleBelted = "NO_EVENT",
    rightRow3BuckleBelted = "NO_EVENT",
    leftRearInflatableBelted = "NO_EVENT",
    rightRearInflatableBelted = "NO_EVENT",
    middleRow1BeltDeployed = "NO_EVENT",
    middleRow1BeltDeployed = "NO_EVENT"
  }
  Test["Precondition_PositiveResponseCheck_beltStatus"] = function(self)
    vehicleData = {"beltStatus"}
  end
  --1. IsMissed
  commonFunctions:TestCaseForResponse(self, response, {"beltStatus"}, "IsMissed", nil, "SUCCESS")
  
  --2. IsEmptyTable
  commonFunctions:TestCaseForResponse(self, response, {"beltStatus"}, "IsEmptyTable", {}, "SUCCESS")
  --3. IsWrongDataType
  commonFunctions:TestCaseForResponse(self, response, {"beltStatus"}, "IsWrongDataType", 123, "GENERIC_ERROR")
  --Description: verify beltStatus structure.
  enumerationParameterInResponse:verify_Enum_String_Parameter(response, {"beltStatus", "driverBeltDeployed"}, VEHICLE_DATA_EVENT_STATUS, false)
  enumerationParameterInResponse:verify_Enum_String_Parameter(response, {"beltStatus", "passengerBeltDeployed"}, VEHICLE_DATA_EVENT_STATUS, false)
  enumerationParameterInResponse:verify_Enum_String_Parameter(response, {"beltStatus", "passengerBuckleBelted"}, VEHICLE_DATA_EVENT_STATUS, false)
  enumerationParameterInResponse:verify_Enum_String_Parameter(response, {"beltStatus", "driverBuckleBelted"}, VEHICLE_DATA_EVENT_STATUS, false)
  enumerationParameterInResponse:verify_Enum_String_Parameter(response, {"beltStatus", "leftRow2BuckleBelted"}, VEHICLE_DATA_EVENT_STATUS, false)
  enumerationParameterInResponse:verify_Enum_String_Parameter(response, {"beltStatus", "passengerChildDetected"}, VEHICLE_DATA_EVENT_STATUS, false)
  enumerationParameterInResponse:verify_Enum_String_Parameter(response, {"beltStatus", "rightRow2BuckleBelted"}, VEHICLE_DATA_EVENT_STATUS, false)
  enumerationParameterInResponse:verify_Enum_String_Parameter(response, {"beltStatus", "middleRow2BuckleBelted"}, VEHICLE_DATA_EVENT_STATUS, false)
  enumerationParameterInResponse:verify_Enum_String_Parameter(response, {"beltStatus", "middleRow3BuckleBelted"}, VEHICLE_DATA_EVENT_STATUS, false)
  enumerationParameterInResponse:verify_Enum_String_Parameter(response, {"beltStatus", "leftRow3BuckleBelted"}, VEHICLE_DATA_EVENT_STATUS, false)
  enumerationParameterInResponse:verify_Enum_String_Parameter(response, {"beltStatus", "rightRow3BuckleBelted"}, VEHICLE_DATA_EVENT_STATUS, false)
  enumerationParameterInResponse:verify_Enum_String_Parameter(response, {"beltStatus", "leftRearInflatableBelted"}, VEHICLE_DATA_EVENT_STATUS, false)
  enumerationParameterInResponse:verify_Enum_String_Parameter(response, {"beltStatus", "rightRearInflatableBelted"}, VEHICLE_DATA_EVENT_STATUS, false)
  enumerationParameterInResponse:verify_Enum_String_Parameter(response, {"beltStatus", "middleRow1BeltDeployed"}, VEHICLE_DATA_EVENT_STATUS, false)
  enumerationParameterInResponse:verify_Enum_String_Parameter(response, {"beltStatus", "middleRow1BuckleBelted"}, VEHICLE_DATA_EVENT_STATUS, false)
end
VerifyBeltStatusParameter()
Test["Precondition_PositiveResponseCheck_deviceStatus"] = function(self)
  vehicleData = {"deviceStatus"}
end
local function VerifyDeviceStatusParameter()
  --[[deviceStatus: type=Common.DeviceStatus mandatory=false
  --name="voiceRecOn" type="Boolean" mandatory="false"
  --name="btIconOn" type="Boolean" mandatory="false"
  --name="callActive" type="Boolean" mandatory="false"
  --name="phoneRoaming" type="Boolean" mandatory="false"
  --name="textMsgAvailable" type="Boolean" mandatory="false"
  --name="stereoAudioOutputMuted" type="Boolean" mandatory="false"
  --name="monoAudioOutputMuted" type="Boolean" mandatory="false"
  --name="eCallEventActive" type="Boolean" mandatory="false"
  --name="primaryAudioSource" type="Common.PrimaryAudioSource" mandatory="false"
  --name="battLevelStatus" type="Common.DeviceLevelStatus" mandatory="false"
  --name="signalLevelStatus" type="Common.DeviceLevelStatus" mandatory="false"]]
  
  --Print new line to separate new test cases group
  commonFunctions:newTestCasesGroup("Test suite For Verifying: deviceStatus structure")
  local response = SetGvdResponse({"deviceStatus"})
  response.deviceStatus = {voiceRecOn = true,
    btIconOn = true,
    callActive = true,
    phoneRoaming = true,
    textMsgAvailable = true,
    battLevelStatus = "THREE_LEVEL_BARS",
    stereoAudioOutputMuted = true,
    monoAudioOutputMuted = true,
    signalLevelStatus = "THREE_LEVEL_BARS",
    primaryAudioSource = "BLUETOOTH_STEREO_BTST",
    eCallEventActive = true
  }
  --1. IsMissed
  commonFunctions:TestCaseForResponse(self, response, {"deviceStatus"}, "IsMissed", nil, "SUCCESS")
  --2. IsEmptyTable
  commonFunctions:TestCaseForResponse(self, response, {"deviceStatus"}, "IsEmptyTable", {}, "SUCCESS")
  --3. IsWrongDataType
  commonFunctions:TestCaseForResponse(self, response, {"deviceStatus"}, "IsWrongDataType", 123, "GENERIC_ERROR")
  --4. TCs for parameter: voiceRecOn
  booleanParameterInResponse:verify_Boolean_Parameter(response, {"deviceStatus", "voiceRecOn"}, false)
  --5. TCs for parameter: btIconOn, callActive, phoneRoaming, textMsgAvailable, stereoAudioOutputMuted, monoAudioOutputMuted, eCallEventActive
  booleanParameterInResponse:verify_Boolean_Parameter(response, {"deviceStatus", "btIconOn"}, false)
  booleanParameterInResponse:verify_Boolean_Parameter(response, {"deviceStatus", "callActive"}, false)
  booleanParameterInResponse:verify_Boolean_Parameter(response, {"deviceStatus", "phoneRoaming"}, false)
  booleanParameterInResponse:verify_Boolean_Parameter(response, {"deviceStatus", "textMsgAvailable"}, false)
  booleanParameterInResponse:verify_Boolean_Parameter(response, {"deviceStatus", "stereoAudioOutputMuted"}, false)
  booleanParameterInResponse:verify_Boolean_Parameter(response, {"deviceStatus", "monoAudioOutputMuted"}, false)
  booleanParameterInResponse:verify_Boolean_Parameter(response, {"deviceStatus", "eCallEventActive"}, false)
  --6. TCs for parameter: primaryAudioSource
  enumerationParameterInResponse:verify_Enum_String_Parameter(response, {"deviceStatus", "primaryAudioSource"}, PRIMARY_AUDIO_SOURCE_VALUES, false)
  --7. TCs for parameter: battLevelStatus, signalLevelStatus
  enumerationParameterInResponse:verify_Enum_String_Parameter(response, {"deviceStatus", "battLevelStatus"}, DEVICE_LEVEL_STATUS, false)
  enumerationParameterInResponse:verify_Enum_String_Parameter(response, {"deviceStatus", "signalLevelStatus"}, DEVICE_LEVEL_STATUS, false)
end
VerifyDeviceStatusParameter()

Test["Precondition_PositiveResponseCheck_tirePressure"] = function(self)
  vehicleData = {"tirePressure"}
end

local function VerifyTirePressureParameter()
  --[[tirePressure: type=Common.TireStatus mandatory=false
  --name="pressureTelltale" type="Common.WarningLightStatus" mandatory="false"
  --name="leftFront" type="Common.SingleTireStatus" mandatory="false"
  --name="rightFront" type="Common.SingleTireStatus" mandatory="false"
  --name="leftRear" type="Common.SingleTireStatus" mandatory="false"
  --name="rightRear" type="Common.SingleTireStatus" mandatory="false"
  --name="innerLeftRear" type="Common.SingleTireStatus" mandatory="false"
  --name="innerRightRear" type="Common.SingleTireStatus" mandatory="false"]]
  
  --struct name="SingleTireStatus">
  --name="status" type="Common.ComponentVolumeStatus" mandatory="true": ComponentVolumeStatus = {"UNKNOWN", "NORMAL", "LOW", "FAULT", "ALERT", "NOT_SUPPORTED"}
  --Print new line to separate new test cases group
  commonFunctions:newTestCasesGroup("Test suite For Verifying: tirePressure structure")
  
  local response = SetGvdResponse({"tirePressure"})
  response.tirePressure= {
    pressureTelltale = "ON",
    leftFront = {status = "UNKNOWN"},
    rightFront = {status = "UNKNOWN"},
    leftRear = {status = "UNKNOWN"},
    rightRear = {status = "UNKNOWN"},
    innerLeftRear = {status = "UNKNOWN"},
    innerRightRear = {status = "UNKNOWN"}
  }
  --1. IsMissed
  commonFunctions:TestCaseForResponse(self, response, {"tirePressure"}, "IsMissed", nil, "SUCCESS")
  --2. IsEmptyTable {}
  commonFunctions:TestCaseForResponse(self, response, {"tirePressure"}, "IsEmptyTable", {}, "SUCCESS")
  --3. IsWrongDataType
  commonFunctions:TestCaseForResponse(self, response, {"tirePressure"}, "IsWrongDataType", 123, "GENERIC_ERROR")
  --4. TCs for parameter: pressureTelltale
  enumerationParameterInResponse:verify_Enum_String_Parameter(response, {"tirePressure", "pressureTelltale"}, WARNING_LIGHT_STATUS, false)
  --5. TCs for parameters: "leftFront", "rightFront", "leftRear", "rightRear", "innerLeftRear", "innerRightRear"
  local function verify_SingleTireStatus_parameter_type(Parameter, response)
    --1. IsMissed
    commonFunctions:TestCaseForResponse(self, response, Parameter, "IsMissed", nil, "SUCCESS")
    --2. IsWrongDataType
    commonFunctions:TestCaseForResponse(self, response, Parameter, "IsWrongDataType", 123, "GENERIC_ERROR")
    --3. name="status" type="Common.ComponentVolumeStatus" mandatory="true"
    local Parameter_status = commonFunctions:BuildChildParameter(Parameter, "status")
    enumerationParameterInResponse:verify_Enum_String_Parameter(response, Parameter_status, COMPONENT_VOLUME_STATUS, true)
  end
  
  local response = SetGvdResponse({"tirePressure"})
  response.tirePressure= {leftFront = {}, pressureTelltale = "OFF"}
  verify_SingleTireStatus_parameter_type({"tirePressure", "leftFront"},response)
  
  local response = SetGvdResponse({"tirePressure"})
  response.tirePressure= {rightFront = {}, pressureTelltale = "OFF"}
  verify_SingleTireStatus_parameter_type({"tirePressure", "rightFront"}, response)
  
  local response = SetGvdResponse({"tirePressure"})
  response.tirePressure= {leftRear = {}, pressureTelltale = "OFF"}
  verify_SingleTireStatus_parameter_type({"tirePressure", "leftRear"}, response)
  
  local response = SetGvdResponse({"tirePressure"})
  response.tirePressure= {rightRear = {}, pressureTelltale = "OFF"}
  verify_SingleTireStatus_parameter_type({"tirePressure", "rightRear"}, response)
  
  local response = SetGvdResponse({"tirePressure"})
  response.tirePressure= {innerLeftRear = {}, pressureTelltale = "OFF"}
  verify_SingleTireStatus_parameter_type({"tirePressure", "innerLeftRear"}, response)
  
  local response = SetGvdResponse({"tirePressure"})
  response.tirePressure= {innerRightRear = {}, pressureTelltale = "OFF"}
  verify_SingleTireStatus_parameter_type({"tirePressure", "innerRightRear"}, response)
end
VerifyTirePressureParameter()
Test["Postcondition_PositiveResponseCheck_deviceStatus"] = function(self)
  vehicleData = {"gps"}
end
-----------------------------------------------------------------------------------------
--[[TODO: Check after APPLINK-14765 is resolved
--Begin Test case NegativeResponseCheck.12
--Description: Check processing response with correlationID

--Requirement id in JAMA:
--SDLAQ-CRS-98
--APPLINK-14765

--Verification criteria:
-- The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription.
-- SDL must cut off the fake parameters from requests, responses and notifications received from HMI

--Begin Test case NegativeResponseCheck.12.1
--Description: CorrelationID is missing
function Test:GetVehicleData_Response_CorrelatioIDMissing()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",
  {
    speed = true
  })
  
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
    self.hmiConnection:Send('{"jsonrpc":"2.0","result":{"code":0,"speed": 50.5,"method":"VehicleInfo.GetVehicleData"}}')
  end)
  
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
end
--End Test case NegativeResponseCheck.12.1

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.12.2
--Description: CorrelationID is wrong type
function Test:GetVehicleData_Response_CorrelatioIDWrongType()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",
  {
    speed = true
  })
  
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
    self.hmiConnection:SendResponse(tostring(data.id), data.method, "SUCCESS", {speed = 50.5})
  end)
  
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
end
--End Test case NegativeResponseCheck.12.2

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.12.3
--Description: CorrelationID is not existed
function Test:GetVehicleData_Response_CorrelatioIDNotExisted()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",
  {
    speed = true
  })
  
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
    self.hmiConnection:SendResponse(5555, data.method, "SUCCESS", {speed = 50.5})
  end)
  
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
end
--End Test case NegativeResponseCheck.12.3

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.12.4
--Description: CorrelationID is negative
function Test:GetVehicleData_Response_CorrelatioIDNegative()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",
  {
    speed = true
  })
  
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
    self.hmiConnection:SendResponse(-1, data.method, "SUCCESS", {speed = 50.5})
  end)
  
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
end
--End Test case NegativeResponseCheck.12.4

-----------------------------------------------------------------------------------------

--Begin Test case NegativeResponseCheck.12.5
--Description: CorrelationID is null
function Test:GetVehicleData_Response_CorrelatioIDNull()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",
  {
    speed = true
  })
  
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
  self.hmiConnection:Send('"id":null,"jsonrpc":"2.0","result":{"code":0,"method":"VehicleInfo.GetVehicleData"}}')
end)

--mobile side: expect GetVehicleData response
EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
end
--End Test case NegativeResponseCheck.12.5
--End Test case NegativeResponseCheck.12
--]]
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

--Requirement id in JAMA: SDLAQ-CRS-610

--Verification criteria:
--A request GetVehicleData is sent under conditions of RAM deficit for executing it. The OUT_OF_MEMORY response code is returned.

--Not applicable

--End Test case ResultCodeCheck.1

-----------------------------------------------------------------------------------------

--Begin Test case ResultCodeCheck.2
--Description: Check of TOO_MANY_PENDING_REQUESTS result code

--Requirement id in JAMA: SDLAQ-CRS-611

--Verification criteria:
--The system has more than 1000 requests at a time that haven't been responded yet.
--The system sends the responses with TOO_MANY_PENDING_REQUESTS error code for all further requests until there are less than 1000 requests at a time that haven't been responded by the system yet.

--Moved to ATF_GetVehicleData_TOO_MANY_PENDING_REQUESTS.lua

--End Test case ResultCodeCheck.2

-----------------------------------------------------------------------------------------

--Begin Test case ResultCodeCheck.3
--Description: Check APPLICATION_NOT_REGISTERED result code

--Requirement id in JAMA: SDLAQ-CRS-612

--Verification criteria:
-- SDL returns APPLICATION_NOT_REGISTERED code for the request sent within the same connection before RegisterAppInterface has been performed yet.
function Test:PreconditionCreationNewSession()
  -- Connected expectation
  self.mobileSession2 = mobile_session.MobileSession(
  self,
  self.mobileConnection)
end
for i=1, #ALL_VEHICLE_DATA do
  Test["GetVehicleData_ApplicationNotRegister_"..ALL_VEHICLE_DATA[i]] = function(self)
    local temp = {}
    temp[ALL_VEHICLE_DATA[i]] = true
    --mobile side: sending GetVehicleData request
    local cid = self.mobileSession2:SendRPC("GetVehicleData",temp)
    --mobile side: expected GetVehicleData response
    self.mobileSession2:ExpectResponse(cid, { success = false, resultCode = "APPLICATION_NOT_REGISTERED" })
    DelayedExp(300)
  end
end
--End Test case ResultCodeCheck.3

-----------------------------------------------------------------------------------------

--Begin Test case ResultCodeCheck.4
--Description: Check VEHICLE_DATA_NOT_ALLOWED result code with success false

--Requirement id in JAMA: SDLAQ-CRS-616

--Verification criteria:
--[[
1. To be defined for future implementation regarding Policies.

1.2. User blocks the access to some vehicle data from HMI. These settings are stored in Policies table.
When such vehicle data is requested by mobile app VEHICLE_DATA_NOT_ALLOWED resultCode is sent back to mobile app. General result code is success=false in case it's the only VD requested by the app.

1.3. User blocks the access to some vehicle data from HMI. These settings are stored in Policies table.
When such vehicle data is requested by mobile app VEHICLE_DATA_NOT_ALLOWED resultCode is sent back to mobile app.
General result code is success=true in case it's not the only VD requested and returned successfully to the app for the current request.
--]]

-- Not applicable

--End Test case ResultCodeCheck.4

-----------------------------------------------------------------------------------------

--Begin Test case ResultCodeCheck.5
--Description: Check VEHICLE_DATA_NOT_AVAILABLE result code
commonFunctions:newTestCasesGroup("ResultCodeCheck.5")
--Requirement id in JAMA: SDLAQ-CRS-617

--Verification criteria:
-- VEHICLE_DATA_NOT_AVAILABLE code is processed by SDL if received from HMI for some VD value not available or not published by vehicle component (in current HMI implementation), the response with VEHICLE_DATA_NOT_AVAILABLE resultCode is sent back to mobile app. General result code is success=false in case it's the only VD requested by the app.
-- VEHICLE_DATA_NOT_AVAILABLE code is processed by SDL if received from HMI for some VD value not available or not published by vehicle component (in current HMI implementation), the response with VEHICLE_DATA_NOT_AVAILABLE resultCode is sent back to mobile app. General result code is success=true in case other VD requested by the app has been returned to the app successfully.

--Begin Test Case ResultCodeCheck.5.1
--Description: General result code is success=false in case it's the only VD requested by the app.
function Test:GetVehicleDataVehicleDataNotAvailable_OnlyOneVD()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",
  {
    rpm = true
  })
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{rpm = true})
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
    self.hmiConnection:SendResponse(data.id, data.method, "DATA_NOT_AVAILABLE", {})
  end)
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, {success = false, resultCode = "VEHICLE_DATA_NOT_AVAILABLE"})
end
--End Test Case ResultCodeCheck.5.1

-----------------------------------------------------------------------------------------

--Begin Test Case ResultCodeCheck.5.2
--Description: General result code is success=true in case other VD requested by the app has been returned to the app successfully.
function Test:GetVehicleDataVehicleDataNotAvailableOtherVDAvailable()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",
  {
    rpm = true,
    speed = true
  })
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{rpm = true, speed = true})
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
    self.hmiConnection:SendResponse(data.id, data.method, "DATA_NOT_AVAILABLE", {speed = 50.5})
  end)
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, {success = true, resultCode = "VEHICLE_DATA_NOT_AVAILABLE", speed = 50.5})
end
--End Test Case ResultCodeCheck.5.2
--End Test case ResultCodeCheck.5

-----------------------------------------------------------------------------------------
--[[TODO: check after ATF defect APPLINK-13101 is resolved
--Begin Test case ResultCodeCheck.6
--Description: Check DISALLOWED result code

--Requirement id in JAMA: SDLAQ-CRS-2964, APPLINK-8673

--Verification criteria:
-- In case GetVehicleData RPC is allowed by policies with less than supported by protocol parameters AND the app assigned with such policies requests GetVehicleData with one and-or more NOT-allowed params only, SDL MUST NOT send anything to HMI, AND respond with "ResultCode:DISALLOWED, success: false" to mobile app.
function Test:Precondition_PolicyUpdate()
  self:policyUpdate("PTU_ForGetVehicleData.json", true)
end

--Begin Test Case ResultCodeCheck.6.1
--Description: Get vehicle data which is disallowed by policies
function Test:GetVehicleData_Disallowed()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",{speed = true})
  
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
  :Times(0)
  
  --mobile side: expected GetVehicleData response
  EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "'speed' is disallowed by policies."})
end
--Begin Test Case ResultCodeCheck.6.1

-----------------------------------------------------------------------------------------

--Begin Test Case ResultCodeCheck.6.2
--Description: Get vehicle data which one is disallowed and another is allowed by policies
function Test:GetVehicleData_DisallowedAndAllowed()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",
  {
    speed = true,
    rpm = true
  })
  
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{rpm = true})
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {rpm = 1000})
  end)
  :ValidIf (function(_,data)
    if data.params.speed then
      print(" \27[36m SDL resend disallowed vehicle data to mobile app \27[0m")
      return false
    else
      return true
    end
  end)
  
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", rpm = 1000, info = "'speed' is disallowed by policies."})
end
--Begin Test Case ResultCodeCheck.6.2
--End Test case ResultCodeCheck.6

-----------------------------------------------------------------------------------------

--Begin Test case ResultCodeCheck.7
--Description: Check USER_DISALLOWED result code with success false

--Requirement id in JAMA: SDLAQ-CRS-615

--Verification criteria:
-- SDL must return "resultCode: USER_DISALLOWED, success:false" to the RPC in case this RPC exists in the PolicyTable group disallowed by the user.

function Test:Precondition_UserDisallowedVehicleData()
  --hmi side: sending SDL.OnAppPermissionConsent
  self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID = self.applications["Test Application"], consentedFunctions = {{ allowed = false, id = 193465391, name = "New"}}, source = "GUI"})
end

function Test:GetVehicleData_USER_DISALLOWED()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",
  {
    speed = true
  })
  
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{
    speed = true
  })
  :Times(0)
  
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, {success = false, resultCode = "USER_DISALLOWED"})
end

function Test:Postcondition_AllowedAllVehicleData()
  self:policyUpdate("PTU_GVDAllowedAllVehicleData.json", true)
end
--End Test case ResultCodeCheck.7
--]]
-----------------------------------------------------------------------------------------

--Begin Test case ResultCodeCheck.8
--Description: Check REJECTED result code

--Requirement id in JAMA: SDLAQ-CRS-613

--Verification criteria:
-- In case SDL receives REJECTED result code for the RPC from HMI, SDL must transfer REJECTED resultCode with adding "success:false" to mobile app.
function Test:GetVehicleDataREJECTED()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",
  {
    rpm = true
  })
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{rpm = true})
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
    self.hmiConnection:SendError(data.id, data.method, "REJECTED", "Error Message")
  end)
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, {success = false, resultCode = "REJECTED", info = "Error Message"})
end
--End Test case ResultCodeCheck.8

-----------------------------------------------------------------------------------------

--Begin Test case ResultCodeCheck.9
--Description: Check GENERIC_ERROR result code with success false

--Requirement id in JAMA: SDLAQ-CRS-614

--Verification criteria:
-- In case SDL receives GENERIC_ERROR result code for the RPC from HMI, SDL must transfer GENERIC_ERROR resultCode with adding "success:false" to mobile app.
function Test:GetVehicleDataGENERIC_ERROR()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",
  {
    rpm = true
  })
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{rpm = true})
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
    self.hmiConnection:SendResponse(data.id, data.method, "GENERIC_ERROR", {})
  end)
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR"})
end
--End Test case ResultCodeCheck.9
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

--Requirement id in JAMA:
--SDLAQ-CRS-614
--APPLINK-8585

--Verification criteria:
-- SDL must return GENERIC_ERROR result to mobile app in case one of HMI components does not respond being supported and active.
function Test:GetVehicleDataNoResponseFromHMI()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",
  {
    speed = true
  })
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{
    speed = true
  })
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
  end)
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR"})
  :Timeout(12000)
end
--End Test case HMINegativeCheck.1

-----------------------------------------------------------------------------------------
--[[TODO: update according to APPLINK-14765
--Begin Test case HMINegativeCheck.2
--Description:
-- Check processing responses with invalid structure

--Requirement id in JAMA:
--SDLAQ-CRS-98

--Verification criteria:
--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode. The appropriate parameters sent in the request are returned with the data about subscription.
function Test:GetVehicleData_ResponseInvalidStructure()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",
  {
    speed = true
  })
  
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{
    speed = true
  })
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
  --Correct structure:self.hmiConnection:Send('"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"speed": 55.5,"code":0, "method":"VehicleInfo.GetVehicleData"}}')
self.hmiConnection:Send('"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"speed" 55.5,"code":0, "method":"VehicleInfo.GetVehicleData"}}')
end)

--mobile side: expect GetVehicleData response
EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
:Timeout(12000)
end
--End Test case HMINegativeCheck.2
--]]
-----------------------------------------------------------------------------------------

--Begin Test case HMINegativeCheck.3
--Description:
-- Several response to one request

--Requirement id in JAMA:
--SDLAQ-CRS-98

--Verification criteria:
--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
function Test:GetVehicleDataSeveralResponseToOneRequest()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",
  {
    speed = true
  })
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {speed= 80.5})
    self.hmiConnection:SendResponse(data.id, data.method, "REJECTED", {})
    self.hmiConnection:SendResponse(data.id, data.method, "GENERIC_ERROR", {})
  end)
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", speed=80.5})
end
--End Test case HMINegativeCheck.3
--]]
-----------------------------------------------------------------------------------------

--Begin Test case HMINegativeCheck.4
--Description:
-- Check processing response with fake parameters

--Requirement id in JAMA:
--SDLAQ-CRS-98

--Verification criteria:
--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.

--Begin Test case HMINegativeCheck.4.1
--Description: Parameter not from API
function Test:GetVehicleDataFakeParamsInResponse()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",
  {
    speed = true
  })
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {fake = "fakeParams", speed = 55.5})
  end)
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", speed = 55.5})
  :ValidIf (function(_,data)
    if data.payload.fake then
      print(" \27[36m SDL resend fake parameter to mobile app \27[0m ")
      return false
    else
      return true
    end
  end)
end
--End Test case HMINegativeCheck.4.1

-----------------------------------------------------------------------------------------

--Begin Test case HMINegativeCheck.4.2
--Description: Parameter from another API
function Test:GetVehicleDataParamsFromOtherAPIInResponse()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",
  {
    speed = true
  })
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 5, speed = 55.5})
  end)
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS", speed = 55.5})
  :ValidIf (function(_,data)
    if data.payload.sliderPosition then
      print(" \27[36m SDL resend fake parameter to mobile app \27[0m ")
      return false
    else
      return true
    end
  end)
end
--End Test case HMINegativeCheck.4.2
--End Test case HMINegativeCheck.4

-----------------------------------------------------------------------------------------

--Begin Test case HMINegativeCheck.5
--Description:
-- Wrong response with correct HMI correlation id

--Requirement id in JAMA:
--SDLAQ-CRS-98

--Verification criteria:
--The response contains 2 mandatory parameters "success" and "resultCode", "info" is sent if there is any additional information about the resultCode.
--TODO: remove Timeout(12000) after resolving APPLINK-14765.
function Test:GetVehicleDataWrongResponseToCorrectID()
  --mobile side: sending GetVehicleData request
  local cid = self.mobileSession:SendRPC("GetVehicleData",
  {
    speed = true
  })
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
    self.hmiConnection:SendResponse(data.id, "UI.AddCommand", "SUCCESS", {speed = 55.5})
  end)
  
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
  :Timeout(12000)
end
--End Test case HMINegativeCheck.5
--End Test suit HMINegativeCheck

----------------------------------------------------------------------------------------------
-----------------------------------------VI TEST BLOCK----------------------------------------
-------------------------Sequence with emulating of user's action(s)------------------------
----------------------------------------------------------------------------------------------

-- Begin Test suit SequenceCheck
-- Description: TC's checks SDL behaviour by processing
-- different request sequence with timeout
-- with emulating of user's actions

-- Begin Test case SequenceCheck.1
-- CRQ: APPLINK-24201
-- Description: Check allowance of parameters in Policies
local function GetVehicleDataPoliciesAllowanceChecking()
  
  --Requirement: APPLINK-21166
  commonFunctions:newTestCasesGroup("PoliciesAllowanceChecking.1: Parameters are empty at Base4 in Policies")
  local PermissionLines_ParametersIsEmpty =
  [[
  "GetVehicleData": {
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
  [[ "]].."0000001" ..[[":{
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
  local PTName = policyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication)
  policyTable:updatePolicy(PTName, nil, "UpdatePolicy_GetVehicleData_WithEmptyParameters")
  
  -- SDL responds "DISALLOWED" with info when all parameter are empty
  function Test:GetVehicleData_EmptyParameters_InBase4()
    local request = SetGvdRequest(ALL_VEHICLE_DATA)
    --mobile side: sending GetVehicleData request
    local cid = self.mobileSession:SendRPC("GetVehicleData",request)
    --hmi side: not expect GetVehicleData request
    EXPECT_HMICALL("VehicleInfo.GetVehicleData",{})
    :Times(0)
    EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED", info = "Requested parameters are disallowed by Policies"})
    commonTestCases:DelayedExp(1000)
  end
  -------------------------------------------------------------------------------------------------------------
  
  -- RequirementID: APPLINK-20280
  -- TODO: expected result needs to update when APPLINK-26935 is DONE
  -- Description:GetVehicleData is present in Base4 with some allowed params and disallowed myKey by policies.
  commonFunctions:newTestCasesGroup("PoliciesAllowanceChecking.2: 1 param is disallowed at Base 4 in Policies")
  
  local PermissionLines_GetVehicleData_DisallowedMyKey =
  [[
  "GetVehicleData": {
    "hmi_levels": [
    "BACKGROUND",
    "FULL",
    "LIMITED"
    ],
    "parameters": [
    "gps", "speed", "rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption", "fuelRange", "abs_State", "externalTemperature", "prndl", "tirePressure", "tirePressureValue", "tpms", "turnSignal", "odometer", "beltStatus", "bodyInformation", "deviceStatus", "driverBraking", "wiperStatus", "headLampStatus", "engineTorque", "accPedalPosition", "steeringWheelAngle", "eCallInfo", "airbagStatus", "emergencyEvent", "clusterModeStatus", "vin"
    ]
  }
  ]]
  local PermissionLinesForApp1=
  [[ "]].."0000001" ..[[":{
    "keep_context": true,
    "steal_focus": true,
    "priority": "NONE",
    "default_hmi": "BACKGROUND",
    "groups": ["Base-4"]
  }
  ]]
  local PermissionLinesForBase4 = PermissionLines_GetVehicleData_DisallowedMyKey .. ", \n"
  local PermissionLinesForGroup1 = nil
  local PermissionLinesForApplication = PermissionLinesForApp1.. ", \n"
  local PTName = policyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication)
  policyTable:updatePolicy(PTName, nil, "UpdatePolicy_GetVehicleData_InBase4_WithDisallowedMyKey")
  
  -- SDL responds "DISALLOWED" with info when send GetVehicleData request with only one disallowed param in Base4 by Policies.
  local Request = {myKey = true}
  function Test:GetVehicleData_InBase4_WithOnlyOneDisallowedParam()
    --mobile side: sending the request
    local cid = self.mobileSession:SendRPC("GetVehicleData", Request)
    --hmi side: not expect VehicleInfo.GetVehicleData
    EXPECT_HMICALL("VehicleInfo.GetVehicleData", {})
    :Times(0)
    --mobile side: expect response
    EXPECT_RESPONSE(cid, {resultCode = "DISALLOWED", info = "Requested parameters are disallowed by Policies", success = false})
    commonTestCases:DelayedExp(1000)
  end
  
  -- SDL responds "SUCCESS" when send GetVehicleData request with some allowed params in Base4 by Policies
  local AllVehicleParams_InBase4_Without_MyKey = {"gps", "speed", "rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption", "fuelRange", "abs_State", "externalTemperature", "prndl", "tirePressure", "tirePressureValue", "tpms", "turnSignal", "odometer", "beltStatus", "bodyInformation", "deviceStatus", "driverBraking", "wiperStatus", "headLampStatus", "engineTorque", "accPedalPosition", "steeringWheelAngle", "eCallInfo", "airbagStatus", "emergencyEvent", "clusterModeStatus", "vin"}
  
  function Test:GetVehicleData_AllVehicleParams_InBase4_Without_MyKey()
    self:getVehicleDataSuccess(AllVehicleParams_InBase4_Without_MyKey)
  end
  
  -- SDL responds "SUCCESS" with info about disallowed params when send GetVehicleData request with allowed params and 1 disallowed param.
  function Test:GetVehicleData_InBase4_WithAllowedParams_DisallowedMyKey()
    local request_FromApp = SetGvdRequest(ALL_VEHICLE_DATA)
    local request_HMIExpect = SetGvdRequest(AllVehicleParams_InBase4_Without_MyKey)
    local response = SetGvdResponse(AllVehicleParams_InBase4_Without_MyKey)
    --mobile side: sending GetVehicleData request
    local cid = self.mobileSession:SendRPC("GetVehicleData",request_FromApp)
    --hmi side: expect GetVehicleData request
    EXPECT_HMICALL("VehicleInfo.GetVehicleData",request_HMIExpect)
    :Do(function(_,data)
      --hmi side: sending VehicleInfo.GetVehicleData response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)
    end)
    :ValidIf(function(_,data)
      if data.params.myKey then
        commonFunctions:userPrint(31,"VehicleInfo.GetVehicleData contain myKey parameter in request when should be omitted")
        return false
      else
        return true
      end
    end)
    --mobile side: expect GetVehicleData response
    EXPECT_RESPONSE(cid, {success = true, info = "'myKey' is disallowed by policies", resultCode = "SUCCESS"})
  end
  -------------------------------------------------------------------------------------------------------------
  
  -- RequirementID: APPLINK-20280
  -- TODO: expected result need to update when APPLINK-26935 is DONE
  -- Description: GetVehicleData is present in Base4 with some allowed params and some disallowed params by policies
  commonFunctions:newTestCasesGroup("PoliciesAllowanceChecking.2: Some params are disallowed at Base 4 in Policies")
  
  local PermissionLines_GetVehicleData_AllowedForBase4_SomeParams =
  [[
  "GetVehicleData": {
    "hmi_levels": [
    "BACKGROUND",
    "FULL",
    "LIMITED"
    ],
    "parameters": [
    "gps", "speed", "rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption", "fuelRange", "abs_State", "externalTemperature", "prndl"
    ]
  }
  ]]
  local PermissionLinesForApp1=
  [[ "]].."0000001" ..[[":{
    "keep_context": true,
    "steal_focus": true,
    "priority": "NONE",
    "default_hmi": "BACKGROUND",
    "groups": ["Base-4"]
  }
  ]]
  local PermissionLinesForBase4 = PermissionLines_GetVehicleData_AllowedForBase4_SomeParams .. ", \n"
  local PermissionLinesForGroup1 = nil
  local PermissionLinesForApplication = PermissionLinesForApp1 .. ", \n"
  local PTName = policyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication)
  policyTable:updatePolicy(PTName, nil, "UpdatePolicy_GetVehicleData_DisallowedSomeParams_AllowBase4")
  -- SDL responds "DISALLOWED" with info when send GetVehicleData request with some disallowed parameters.
  local Request_WithDisallowedParams_InBase4 = {"deviceStatus", "driverBraking", "wiperStatus", "headLampStatus", "engineTorque", "accPedalPosition", "steeringWheelAngle", "eCallInfo", "airbagStatus", "emergencyEvent", "clusterModeStatus", "myKey"}
  local Request_WithAllowedParams_InBase4 = {"gps", "speed", "rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption", "fuelRange", "abs_State", "externalTemperature", "prndl"}
  
  function Test:GetVehicleData_With_SomeDisallowedParams_Base4()
    --mobile side: sending GetVehicleData request
    local request_FromApp = SetGvdRequest(Request_WithDisallowedParams_InBase4)
    local cid = self.mobileSession:SendRPC("GetVehicleData", request_FromApp)
    --hmi side: not expect VehicleInfo.GetVehicleData
    EXPECT_HMICALL("VehicleInfo.GetVehicleData", {})
    :Times(0)
    --mobile side: expect response
    EXPECT_RESPONSE(cid, {success = false, resultCode = "DISALLOWED", info = "Requested parameters are disallowed by Policies"})
    commonTestCases:DelayedExp(1000)
  end
  
  -- SDL responds "SUCCESS" with info about some disallowed params when send GetVehicleData request with some allowed parameters and some disallowed parameters by policies.
  function Test:GetVehicleData_InBase4_With_SomeAllowedParams_And_SomeDisallowedParams()
    local request_FromApp = SetGvdRequest(ALL_VEHICLE_DATA)
    local request_HMIExpect = SetGvdRequest(Request_WithAllowedParams_InBase4)
    local response = SetGvdResponse(request_HMIExpect)
    --mobile side: sending GetVehicleData request
    local cid = self.mobileSession:SendRPC("GetVehicleData",request_FromApp)
    --hmi side: expect GetVehicleData request
    EXPECT_HMICALL("VehicleInfo.GetVehicleData",request_HMIExpect)
    :Do(function(_,data)
      --hmi side: sending VehicleInfo.GetVehicleData response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)
    end)
    :ValidIf(function(_,data)
      --if data.params.tirePressure or data.params.tirePressureValue or data.params.tpms or data.params.turnSignal or data.params.odometer or data.params.beltStatus or data.params.bodyInformation or data.params.deviceStatus or data.params.driverBraking or data.params.wiperStatus or data.params.headLampStatus or data.params.engineTorque or data.params.accPedalPosition or data.params.steeringWheelAngle or data.params.eCallInfo or data.params.airbagStatus or data.params.emergencyEvent or data.params.clusterModeStatus or data.params.vin then
      if data.params.deviceStatus or data.params.driverBraking or data.params.wiperStatus or data.params.headLampStatus or data.params.engineTorque or data.params.accPedalPosition or data.params.steeringWheelAngle or data.params.eCallInfo or data.params.airbagStatus or data.params.emergencyEvent or data.params.clusterModeStatus or data.params.myKey then
        commonFunctions:userPrint(31,"VehicleInfo.GetVehicleData contain some parameters in request when should be omitted")
        return false
      else
        return true
      end
    end)
    --mobile side: expect GetVehicleData response
    EXPECT_RESPONSE(cid, {success = true, info = "'accPedalPosition', 'airbagStatus', 'beltStatus', 'bodyInformation', 'clusterModeStatus', 'deviceStatus', 'driverBraking', 'eCallInfo', 'emergencyEvent', 'engineTorque', 'headLampStatus', 'myKey', 'odometer', 'steeringWheelAngle', 'tirePressure', 'tirePressureValue', 'tpms', 'turnSignal', 'vin', 'wiperStatus' are disallowed by policies", resultCode = "SUCCESS"})
  end
  -------------------------------------------------------------------------------------------------------------
  -- RequirementID: APPLINK-20280
  -- TODO: expected result need to update when APPLINK-26935 is DONE
  -- Description: GetVehicleData with some params exists at Base4, GetVehicleData with some params exists at group1 in Policies and some params are not presented in Policies.
  commonFunctions:newTestCasesGroup("PoliciesAllowanceChecking.2: Some params are in Base 4, Group1 and some params are disallowed in Policies")
  
  local PermissionLines_AllowedForBase4 =
  [[
  "GetVehicleData": {
    "hmi_levels": [
    "BACKGROUND",
    "FULL",
    "LIMITED"
    ],
    "parameters": [
    "beltStatus", "bodyInformation", "deviceStatus", "driverBraking", "wiperStatus", "headLampStatus", "engineTorque", "accPedalPosition", "steeringWheelAngle", "eCallInfo", "airbagStatus", "emergencyEvent", "clusterModeStatus", "myKey", "vin"
    ]
  }
  ]]
  local PermissionLines_AllowedForGroup1 =
  [[
  "GetVehicleData": {
    "hmi_levels": [
    "BACKGROUND",
    "FULL",
    "LIMITED"
    ],
    "parameters": [
    "gps", "speed", "rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption", "fuelRange", "abs_State"
    ]
  }
  ]]
  local PermissionLinesForApp1=
  [[ "]].."0000001" ..[[":{
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
  local PTName = policyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication)
  policyTable:updatePolicy(PTName, nil, "UpdatePolicy_GetVehicleData_PresentGroup1AndBase4_AssignedToApp")
  
  local Request_WithParams_InBase4 = {"beltStatus", "bodyInformation", "deviceStatus", "driverBraking", "wiperStatus", "headLampStatus", "engineTorque", "accPedalPosition", "steeringWheelAngle", "eCallInfo", "airbagStatus", "emergencyEvent", "clusterModeStatus", "myKey", "vin"}
  local Request_WithParams_InGroup1 = {"gps", "speed", "rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption", "fuelRange", "abs_State"}
  local Request_WithParams_NotPresented = {"externalTemperature", "prndl", "tirePressure", "tirePressureValue", "tpms", "turnSignal", "odometer"}
  
  -- RequirementID: APPLINK-19318: RPC contains the PolicyTable group(s) assigned to the application but no user's consent
  -- SDL responds "DISALLOWED" with info when send GetVehicleData request with disallowed params by user does not answer for consent.
  function Test:GetVehicleData_ParamsInGroup1_User_Not_Answer_Consent()
    --mobile side: sending GetVehicleData request
    local request_FromApp = SetGvdRequest(Request_WithParams_InGroup1)
    local cid = self.mobileSession:SendRPC("GetVehicleData", request_FromApp)
    --hmi side: not expect VehicleInfo.GetVehicleData
    EXPECT_HMICALL("VehicleInfo.GetVehicleData", {})
    :Times(0)
    --mobile side: expect GetVehicleData response
    EXPECT_RESPONSE(cid, {success = false, resultCode = "DISALLOWED", info = "Requested parameters are disallowed by Policies"})
    commonTestCases:DelayedExp(1000)
  end
  
  -- SDL responds "SUCCESS" with info GetVehicleData with allowed params in Base4 and params in group1 when user does not answer consent for group1.
  local Request_ParamsInBase4_ParamInGroup1 = {"beltStatus", "bodyInformation", "deviceStatus", "driverBraking", "wiperStatus", "headLampStatus", "engineTorque", "accPedalPosition", "steeringWheelAngle", "eCallInfo", "airbagStatus", "emergencyEvent", "clusterModeStatus", "myKey", "vin", "gps", "speed", "rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption", "fuelRange", "abs_State"}
  --local Request_ParamsInBase4_ParamInGroup1 = {"beltStatus", "bodyInformation","gps", "speed"}
  function Test:GetVehicleData_AllowedParamsInBase4_ParamInGroup1_User_Not_Answer_Consent()
    local request_FromApp = SetGvdRequest(Request_ParamsInBase4_ParamInGroup1)
    local request_HMIExpect = SetGvdRequest(Request_WithParams_InBase4)
    local response = SetGvdResponse(Request_WithParams_InBase4)
    --mobile side: sending GetVehicleData request
    local cid = self.mobileSession:SendRPC("GetVehicleData",request_FromApp)
    
    --hmi side: expect GetVehicleData request
    EXPECT_HMICALL("VehicleInfo.GetVehicleData",request_HMIExpect)
    :Do(function(_,data)
      --hmi side: sending VehicleInfo.GetVehicleData response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)
    end)
    :ValidIf(function(_,data)
      if data.params.gps or data.params.speed or data.params.rpm or data.params.fuelLevel or data.params.fuelLevel_State or data.params.instantFuelConsumption or data.params.fuelRange or data.params.abs_State then
        commonFunctions:userPrint(31,"VehicleInfo.GetVehicleData contain some parameters in request when should be omitted")
        return false
      else
        return true
      end
    end)
    --mobile side: expect the response
    local expectedResult = CreateSuccessExpectedResult(response)
    -- EXPECT_RESPONSE(cid, {expectedResult, info = "'abs_State', 'fuelLevel', 'fuelLevel_State', 'fuelRange', 'gps', 'instantFuelConsumption', 'rpm', 'speed' are disallowed by policies"})
    EXPECT_RESPONSE(cid,expectedResult)
  end
  
  -- SDL responds "DISALLOWED" with info about disallowed params when send GetVehicleData with allowed params in Base4, disallowed params by policies and params in group1 when user does not answer consent for group1.
  function Test:GetVehicleData_AllowedParamsBase4_ParamsNotPresentedInPolicies_NotAnswerForConsentGroup1()
    local request_FromApp = SetGvdRequest(ALL_VEHICLE_DATA)
    local request_HMIExpect = SetGvdRequest(Request_WithParams_InBase4)
    local response = SetGvdResponse(Request_WithParams_InBase4)
    --mobile side: sending GetVehicleData request
    local cid = self.mobileSession:SendRPC("GetVehicleData",request_FromApp)
    --hmi side: expect GetVehicleData request
    EXPECT_HMICALL("VehicleInfo.GetVehicleData",request_HMIExpect)
    :Do(function(_,data)
      --hmi side: sending VehicleInfo.GetVehicleData response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)
    end)
    :ValidIf(function(_,data)
      if data.params.externalTemperature or data.params.prndl or data.params.tirePressure or data.params.tirePressureValue or data.params.tpms or data.params.turnSignal or data.params.odometer or data.params.gps or data.params.speed or data.params.rpm or data.params.fuelLevel or data.params.fuelLevel_State or data.params.instantFuelConsumption or data.params.fuelRange or data.params.abs_State then
        commonFunctions:userPrint(31,"VehicleInfo.GetVehicleData contain some parameters in request when should be omitted")
        return false
      else
        return true
      end
    end)
    --mobile side: expect GetVehicleData response
    EXPECT_RESPONSE(cid, {success = true, info = "'abs_State', 'externalTemperature', 'fuelLevel', 'fuelLevel_State', 'fuelRange', 'gps', 'instantFuelConsumption', 'odometer', 'prndl', 'rpm', 'speed', 'tirePressure', 'tirePressureValue', 'tpms', 'turnSignal' are disallowed by policies", resultCode = "SUCCESS"})
  end
  
  policyTable:userConsent(false, "group1", "UserConsent_Answer_No")
  
  --RequirementID: APPLINK-19584: SDL must return 'USER_DISALLOWED, success:false' to mobile app in case the requested RPC is included to the group disallowed by the user.
  -- TODO: expected result need to update when APPLINK-26935 is done
  -- SDL responds "USER_DISALLOWED" with info when send GetVehicleData with params are disallowed by user
  function Test:GetVehicleData_ParamsInGroup1_User_Answer_NO()
    --mobile side: sending GetVehicleData request
    local request_FromApp = SetGvdRequest(Request_WithParams_InGroup1)
    local cid = self.mobileSession:SendRPC("GetVehicleData", request_FromApp)
    --hmi side: not expect VehicleInfo.GetVehicleData
    EXPECT_HMICALL("VehicleInfo.GetVehicleData", {})
    :Times(0)
    --mobile side: expect GetVehicleData response
    EXPECT_RESPONSE(cid, {success = false, resultCode = "USER_DISALLOWED", info = "RPC is disallowed by the user"})
    commonTestCases:DelayedExp(1000)
  end
  
  -- TODO: expected result need to update when APPLINK-26935 is done
  -- SDL responds "SUCCESS" with info of user_disallowed param when sending GetVehicleData with some params are allowed by Policies and some params are disallowed by User.
  function Test:GetVehicleData_ParamsInBase4_ParamInGroup1_User_Answer_NO()
    local request_FromApp = SetGvdRequest(Request_ParamsInBase4_ParamInGroup1)
    local request_HMIExpect = SetGvdRequest(Request_WithParams_InBase4)
    local response = SetGvdResponse(Request_WithParams_InBase4)
    --mobile side: sending GetVehicleData request
    local cid = self.mobileSession:SendRPC("GetVehicleData",request_FromApp)
    --hmi side: expect GetVehicleData request
    EXPECT_HMICALL("VehicleInfo.GetVehicleData",request_HMIExpect)
    :Do(function(_,data)
      --hmi side: sending VehicleInfo.GetVehicleData response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)
    end)
    :ValidIf(function(_,data)
      if data.params.gps or data.params.speed or data.params.rpm or data.params.fuelLevel or data.params.fuelLevel_State or data.params.instantFuelConsumption or data.params.fuelRange or data.params.abs_State then
        commonFunctions:userPrint(31,"VehicleInfo.GetVehicleData contain some parameters in request when should be omitted")
        return false
      else
        return true
      end
    end)
    --mobile side: expect GetVehicleData response
    EXPECT_RESPONSE(cid, {success = true, info = "'abs_State', 'fuelLevel', 'fuelLevel_State', 'fuelRange', 'gps', 'instantFuelConsumption', 'rpm', 'speed' are disallowed by user", resultCode = "SUCCESS"})
  end
  
  -- TODO: expected result need to update when APPLINK-26935 is done
  -- SDL responds "USER_DISALLOWED" when send GetVehicleData with some params are disallowed by Policies and some params are disallowed by User.
  local Request_ParamsNotPresented_ParamInGroup1 = {"gps", "speed", "rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption", "fuelRange", "abs_State", "externalTemperature", "prndl", "tirePressure", "tirePressureValue", "tpms", "turnSignal", "odometer"}
  function Test:GetVehicleData_With_DisallowedParamsByPolicies_ParamInGroup1_UserAnswerNO()
    local request_FromApp = SetGvdRequest(Request_ParamsNotPresented_ParamInGroup1)
    local cid = self.mobileSession:SendRPC("GetVehicleData", request_FromApp)
    --hmi side: not expect VehicleInfo.GetVehicleData
    EXPECT_HMICALL("VehicleInfo.GetVehicleData", {})
    :Times(0)
    --mobile side: expect GetVehicleData response
    EXPECT_RESPONSE(cid, {success = false, resultCode = "DISALLOWED", info = "'externalTemperature', 'odometer', 'prndl', 'tirePressure', 'tirePressureValue', 'tpms', 'turnSignal' are disallowed by policies, 'abs_State', 'fuelLevel', 'fuelLevel_State', 'fuelRange', 'gps', 'instantFuelConsumption', 'rpm', 'speed' are disallowed by user"})
    commonTestCases:DelayedExp(1000)
  end
  
  -- TODO: expected result need to update when APPLINK-26935 is done
  -- SDL responds "SUCCESS" with info about disallowed params when send GetVehicleData with some params are allowed, disallowed by Policies and some params are disallowed by User.
  function Test:GetVehicleData_AlowedParamsInBase4_ParamsNotPresentedInPolicies_DisallowedParamsByUser()
    local request_FromApp = SetGvdRequest(ALL_VEHICLE_DATA)
    local request_HMIExpect = SetGvdRequest(Request_WithParams_InBase4)
    local response = SetGvdResponse(Request_WithParams_InBase4)
    --mobile side: sending GetVehicleData request
    local cid = self.mobileSession:SendRPC("GetVehicleData",request_FromApp)
    --hmi side: expect GetVehicleData request
    EXPECT_HMICALL("VehicleInfo.GetVehicleData",request_HMIExpect)
    :Do(function(_,data)
      --hmi side: sending VehicleInfo.GetVehicleData response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)
    end)
    :ValidIf(function(_,data)
      if data.params.gps or data.params.speed or data.params.rpm or data.params.fuelLevel or data.params.fuelLevel_State or data.params.instantFuelConsumption or data.params.fuelRange or data.params.abs_State then
        commonFunctions:userPrint(31,"VehicleInfo.GetVehicleData contain some parameters in request when should be omitted")
        return false
      else
        return true
      end
    end)
    --mobile side: expect GetVehicleData response
    EXPECT_RESPONSE(cid, {success = true, info = "'externalTemperature', 'odometer', 'prndl', 'tirePressure', 'tirePressureValue', 'tpms', 'turnSignal' are disallowed by policies, 'abs_State', 'fuelLevel', 'fuelLevel_State', 'fuelRange', 'gps', 'instantFuelConsumption', 'rpm', 'speed' are disallowed by user", resultCode = "SUCCESS"})
  end
  policyTable:userConsent(true, "group1", "UserConsent_ANSWER_YES")
  -- TODO: expected result need to update when APPLINK-26935 is DONE
  -- SDL respond "SUCCESS" with info about disalowed params when send GetVehicleData with allowed params by policies and user with info of disallowed param
  function Test:GetVehicleData_AllowedParamsInBase4_ParamsNotPresentedInPolicies_AllowedParamsInGroup1()
    local request_FromApp = SetGvdRequest(ALL_VEHICLE_DATA)
    local request_HMIExpect = SetGvdRequest(Request_ParamsInBase4_ParamInGroup1)
    local response = SetGvdResponse(Request_ParamsInBase4_ParamInGroup1)
    --mobile side: sending GetVehicleData request
    local cid = self.mobileSession:SendRPC("GetVehicleData",request_FromApp)
    --hmi side: expect GetVehicleData request
    EXPECT_HMICALL("VehicleInfo.GetVehicleData",request_HMIExpect)
    :Do(function(_,data)
      --hmi side: sending VehicleInfo.GetVehicleData response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)
    end)
    :ValidIf(function(_,data)
      if data.params.externalTemperature or data.params.prndl or data.params.tirePressure or data.params.tirePressureValue or data.params.tpms or data.params.turnSignal or data.params.odometer then
        commonFunctions:userPrint(31,"VehicleInfo.GetVehicleData contain some parameters in request when should be omitted")
        return false
      else
        return true
      end
    end)
    --mobile side: expect GetVehicleData response
    EXPECT_RESPONSE(cid, {success = true, info = "'externalTemperature', 'odometer', 'prndl', 'tirePressure', 'tirePressureValue', 'tpms', 'turnSignal' are disallowed by policies", resultCode = "SUCCESS"})
  end
  -- SDL responds "SUCCESS" when send GetVehicleData request with allowed params by user.
  function Test:GetVehicleData_AllParamsInGroup1_UserAnswerYES()
    self:getVehicleDataSuccess(Request_WithParams_InGroup1)
  end
  -- SDL responds "SUCCESS" when send GetVehicleData request with allowed params by user and allowed params by policies
  function Test:GetVehicleData_AllowedParamsBase4_ParamsInGroup1_UserAnswerYES()
    self:getVehicleDataSuccess(Request_ParamsInBase4_ParamInGroup1)
  end
  -------------------------------------------------------------------------------------------------------------
  --Description: All parameters are presented at Base4 in Policy.
  
  commonFunctions:newTestCasesGroup("PoliciesAllowanceChecking.2: All params are in Base 4 and sallowed in Policies")
  
  local PermissionLines_AllParameters =
  [[
  "GetVehicleData": {
    "hmi_levels": [
    "BACKGROUND",
    "FULL",
    "LIMITED"
    ],
    "parameters": [
    "gps", "speed", "rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption", "fuelRange", "abs_State",
    "externalTemperature", "prndl", "tirePressure", "tirePressureValue", "tpms", "turnSignal", "odometer",
    "beltStatus", "bodyInformation", "deviceStatus", "driverBraking", "wiperStatus", "headLampStatus", "engineTorque", "accPedalPosition", "steeringWheelAngle", "eCallInfo", "airbagStatus", "emergencyEvent", "clusterModeStatus", "myKey", "vin"
    ]
  }
  ]]
  local PermissionLinesForApp1=[[ "]].."0000001" ..[[":{
    "keep_context": true,
    "steal_focus": true,
    "priority": "NONE",
    "default_hmi": "BACKGROUND",
    "groups": ["Base-4"]
  }
  ]]
  local PermissionLinesForBase4 = PermissionLines_AllParameters .. ", \n"
  local PermissionLinesForGroup1 = nil
  local PermissionLinesForApplication = PermissionLinesForApp1.. ", \n"
  local PTName = policyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication)
  
  policyTable:updatePolicy(PTName, nil, "UpdatePolicy_GetVehicleData_Base4_WithAllParams")
  
  -- SDL responds "SUCCESS" when send GetVehicleData request with allowed params by Policy.
  function Test:GetVehicleData_AllowedAllParams()
    self:getVehicleDataSuccess(ALL_VEHICLE_DATA)
  end
  -------------------------------------------------------------------------------------------------------------
  --RequirementID: APPLINK-24224
  --Description: All parameters are omitted on Policy. SDL must allow all parameter.
  commonFunctions:newTestCasesGroup("PoliciesAllowanceChecking.2: All params are omitted in Policies")
  
  local PermissionLines_OmittedParameters =
  [[
  "GetVehicleData": {
    "hmi_levels": [
    "BACKGROUND",
    "FULL",
    "LIMITED"
    ]
  }
  ]]
  local PermissionLinesForApp1=
  [[ "]].."0000001" ..[[":{
    "keep_context": true,
    "steal_focus": true,
    "priority": "NONE",
    "default_hmi": "BACKGROUND",
    "groups": ["Base-4"]
  }
  ]]
  local PermissionLinesForBase4 = PermissionLines_OmittedParameters .. ", \n"
  local PermissionLinesForGroup1 = nil
  local PermissionLinesForApplication = PermissionLinesForApp1.. ", \n"
  local PTName = policyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication)
  policyTable:updatePolicy(PTName, nil, "UpdatePolicy_GetVehicleData_OmittedAllParam")
  -- SDL responds "SUCCESS" when send GetVehicleData request with allowed params by Policy.
  
  function Test:GetVehicleData_OmitedAllParams_InBase4()
    self:getVehicleDataSuccess(ALL_VEHICLE_DATA)
  end
  commonFunctions:newTestCasesGroup("End Test Suite for coverage of APPLINK-24201")
end
GetVehicleDataPoliciesAllowanceChecking()

--Requirement id in JAMA:
-- APPLINK-7616
--Verification criteria:
-- The System must not allow an application to request a single piece of data more frequently than once per second or what is allowed by the policy table.

local getVDRequest = 6
local getVDRejectedCount = 0
local getVDSuccessCount = 0
function Test:GetVehicleData_FrequencyREJECTED()
  for i=1, getVDRequest do
    --mobile side: sending GetVehicleData request
    local cid = self.mobileSession:SendRPC("GetVehicleData",{speed = true})
  end
  --hmi side: expect GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData",{speed = true})
  :Do(function(_,data)
    --hmi side: sending VehicleInfo.GetVehicleData response
    self.hmiConnection:SendResponse(data.id, data.method,"SUCCESS", {speed = 50.5})
  end)
  :Times(5)
  --mobile side: expect GetVehicleData response
  EXPECT_RESPONSE("GetVehicleData")
  :ValidIf(function(exp,data)
    if
    exp.occurences == getVDRequest and
    (data.payload.resultCode == "SUCCESS" or
    data.payload.resultCode == "REJECTED") then
      if
      data.payload.resultCode == "SUCCESS" then
        getVDSuccessCount = getVDSuccessCount + 1
      else
        getVDRejectedCount = getVDRejectedCount + 1
      end
      if getVDRejectedCount ~= 1 or getVDSuccessCount ~= getVDRequest - 1 then
        print(" \27[36m Expected GetVehicleData responses with resultCode REJECTED 1 time, actual - "..tostring(getVDRejectedCount) .. ", expected with resultCodes SUCCESS " .. tostring(getVDRequest) .. " times, actual - " .. tostring(getVDSuccessCount) .. " \27[0m" )
        return false
      else
        return true
      end
    elseif
    data.payload.resultCode == "REJECTED" then
      getVDRejectedCount = getVDRejectedCount+1
      print(" \27[32m GetVehicleData response came with resultCode REJECTED \27[0m")
      return true
    elseif
    exp.occurences == getVDRequest and getVDRejectedCount == 0 then
      print(" \27[36m Response GetVehicleData with resultCode REJECTED did not came \27[0m")
      return false
      
    elseif
    data.payload.resultCode == "SUCCESS" then
      getVDSuccessCount = getVDSuccessCount + 1
      print(" \27[32m GetVehicleData response came with resultCode SUCCESS \27[0m")
      return true
    else
      print(" \27[36m GetVehicleData response came with resultCode "..tostring(data.payload.resultCode .. "\27[0m" ))
      return false
    end
  end)
  :Times(6)
end
--End Test case SequenceCheck.1
--]]

--End Test suit SequenceCheck
----------------------------------------------------------------------------------------------
-----------------------------------------VII TEST BLOCK----------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------
--Description: processing of request/response in different HMIlevels, SystemContext, AudioStreamingState

--Begin Test suit DifferentHMIlevel
--Description: processing API in different HMILevel

--Begin Test case DifferentHMIlevel.1
--Description: Check GetVehicleData when current HMI is NONE

--Requirement id in JAMA:
--SDLAQ-CRS-2964

--Verification criteria:
-- SDL rejects GetVehicleData request with DISALLOWED resultCode when current HMI level is NONE.
function Test:Precondition_DeactivateToNone()
  --hmi side: sending BasicCommunication.OnExitApplication notification
  self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application"], reason = "USER_EXIT"})
  
  EXPECT_NOTIFICATION("OnHMIStatus",
  { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
end

for i=1, #ALL_VEHICLE_DATA do
  Test["GetVehicleData_HMILevelNone_"..ALL_VEHICLE_DATA[i]] = function(self)
    local request = SetGvdRequest({ALL_VEHICLE_DATA[i]})
    --mobile side: sending GetVehicleData request
    local cid = self.mobileSession:SendRPC("GetVehicleData",request)
    --mobile side: expected GetVehicleData response
    EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED" })
    DelayedExp(300)
  end
end

function Test:Postcondition_ActivateApp()
  --hmi side: sending SDL.ActivateApp request
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
  --mobile side: expect notification
  self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", systemContext = "MAIN"})
end
--End Test case DifferentHMIlevel.1
-----------------------------------------------------------------------------------------

--Begin Test case DifferentHMIlevel.2
--Description: Check GetVehicleData when current HMI is LIMITED

--Requirement id in JAMA:
--SDLAQ-CRS-800

--Verification criteria:
-- SDL doesn't rejects GetVehicleData when current HMI level is LIMITED.
if
Test.isMediaApplication == true or
Test.appHMITypes["NAVIGATION"] == true then
  
  function Test:Precondition_DeactivateToLimited()
    --hmi side: sending BasicCommunication.OnAppDeactivated request
    local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
    {
      appID = self.applications["Test Application"],
      reason = "GENERAL"
    })
    --mobile side: expect OnHMIStatus notification
    EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
  end
  for i=1, #ALL_VEHICLE_DATA do
    Test["GetVehicleData_HMILevelLimited_"..ALL_VEHICLE_DATA[i]] = function(self)
      self:getVehicleDataSuccess({ALL_VEHICLE_DATA[i]})
    end
  end
  --End Test case DifferentHMIlevel.2
  
  -----------------------------------------------------------------------------------------
  
  --Begin Test case DifferentHMIlevel.3
  --Description: Check GetVehicleData when current HMI is BACKGROUND
  
  --Requirement id in JAMA:
  --SDLAQ-CRS-800
  --Verification criteria:
  -- SDL doesn't rejects GetVehicleData when current HMI level is BACKGROUND.
  function Test:Precondition_SecondSession()
    --mobile side: start new session
    self.mobileSession1 = mobile_session.MobileSession(
    self,
    self.mobileConnection)
  end
  
  function Test:Precondition_AppRegistrationInSecondSession()
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
      self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    end)
  end
  
  function Test:Precondition_ActivateSecondApp()
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
    self.mobileSession:ExpectNotification("OnHMIStatus",{hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
    self.mobileSession1:ExpectNotification("OnHMIStatus",{hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
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
    EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end
end

for i=1, #ALL_VEHICLE_DATA do
  Test["GetVehicleData_HMILevelBackground_"..ALL_VEHICLE_DATA[i]] = function(self)
    self:getVehicleDataSuccess({ALL_VEHICLE_DATA[i]})
  end
end
--End Test case DifferentHMIlevel.3
--End Test suit DifferentHMIlevel
---------------------------------------------------------------------------------------------
-------------------------------------------Postcondition-------------------------------------
---------------------------------------------------------------------------------------------

--Print new line to separate Postconditions
commonFunctions:newTestCasesGroup("Postconditions")
policyTable:Restore_preloaded_pt()
Test["Stop_SDL"] = function(self)
  StopSDL()
end