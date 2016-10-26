---------------------------------------------------------------------------------------------
--ATF version: 2.2
--Created date: 12/Nov/2015
--Author: Ta Thanh Dong
---------------------------------------------------------------------------------------------
Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')

---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local integerParameterInNotification = require('user_modules/shared_testcases/testCasesForIntegerParameterInNotification')
local floatParameterInNotification = require('user_modules/shared_testcases/testCasesForFloatParameterInNotification')
local stringParameterInNotification = require('user_modules/shared_testcases/testCasesForStringParameterInNotification')
local enumParameterInNotification = require('user_modules/shared_testcases/testCasesForEnumerationParameterInNotification')
local booleanParameterInNotification = require('user_modules/shared_testcases/testCasesForBooleanParameterInNotification')
local doubleParameterInNotification = require('user_modules/shared_testcases/testCasesForDoubleParameterInNotification')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local SDLConfig = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')
local functionId = require('function_id')
require('user_modules/AppTypes')

APIName = "OnVehicleData" -- set API name
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
Apps = {}
Apps[1] = {}
Apps[1].storagePath = config.pathToSDL .. SDLConfig:GetValue("AppStorageFolder") .. "/"..config.application1.registerAppInterfaceParams.appID.. "_" .. config.deviceMAC.. "/"
Apps[1].appName = config.application1.registerAppInterfaceParams.appName 
local absStateValues = {"INACTIVE", "ACTIVE"}
local tpmsValues = {"UNKNOWN", "SYSTEM_FAULT", "SENSOR_FAULT", "LOW", "SYSTEM_ACTIVE", "TRAIN_LF_TIRE", "TRAIN_RF_TIRE", "TRAIN_RR_TIRE", "TRAIN_ORR_TIRE", "TRAIN_IRR_TIRE", "TRAIN_LR_TIRE", "TRAIN_OLR_TIRE", "TRAIN_ILR_TIRE", "TRAINING_COMPLETE", "TIRES_NOT_TRAINED"}
local turnSignalValues = {"OFF", "LEFT", "RIGHT", "UNUSED"}
local tirePressureValueParams = {"leftFront", "rightFront", "leftRear", "rightRear", "innerLeftRear", "innerRightRear", "frontRecommended", "rearRecommended"}
local PermissionLines_SubscribeVehicleData = 
[[					"SubscribeVehicleData": {
  "hmi_levels": [
  "BACKGROUND",
  "FULL",
  "LIMITED"
  ],
  "parameters": [
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
  "turnSignal"							
  ]
}]]

local PermissionLines_OnVehicleData = 
[[					"OnVehicleData": {
  "hmi_levels": [
  "BACKGROUND",
  "FULL",
  "LIMITED"
  ],
  "parameters": [
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
  "turnSignal"
  ]
}]]
---------------------------------------------------------------------------------------------
------------------------------------------Common functions-----------------------------------
---------------------------------------------------------------------------------------------

local SVDValues = {		gps						= "VEHICLEDATA_GPS", 
  speed					= "VEHICLEDATA_SPEED", 
  rpm						= "VEHICLEDATA_RPM", 
  fuelLevel				= "VEHICLEDATA_FUELLEVEL", 
  fuelLevel_State			= "VEHICLEDATA_FUELLEVEL_STATE", 
  instantFuelConsumption	= "VEHICLEDATA_FUELCONSUMPTION", 
  externalTemperature		= "VEHICLEDATA_EXTERNTEMP", 
  prndl					= "VEHICLEDATA_PRNDL", 
  tirePressure			= "VEHICLEDATA_TIREPRESSURE", 
  odometer				= "VEHICLEDATA_ODOMETER", 
  beltStatus				= "VEHICLEDATA_BELTSTATUS", 
  bodyInformation			= "VEHICLEDATA_BODYINFO", 
  deviceStatus			= "VEHICLEDATA_DEVICESTATUS", 
  driverBraking			= "VEHICLEDATA_BRAKING", 
  wiperStatus				= "VEHICLEDATA_WIPERSTATUS", 
  headLampStatus			= "VEHICLEDATA_HEADLAMPSTATUS", 
  engineTorque			= "VEHICLEDATA_ENGINETORQUE", 
  accPedalPosition		= "VEHICLEDATA_ACCPEDAL", 
  steeringWheelAngle		= "VEHICLEDATA_STEERINGWHEEL", 
  eCallInfo				= "VEHICLEDATA_ECALLINFO", 
  airbagStatus			= "VEHICLEDATA_AIRBAGSTATUS", 
  emergencyEvent			= "VEHICLEDATA_EMERGENCYEVENT", 
  clusterModeStatus		= "VEHICLEDATA_CLUSTERMODESTATUS", 
  myKey					= "VEHICLEDATA_MYKEY",
  fuelRange 				= "VEHICLEDATA_FUELRANGE",
  abs_State				= "VEHICLEDATA_ABS_STATE",
  tirePressureValue		= "VEHICLEDATA_TIREPRESSURE_VALUE",
  tpms					= "VEHICLEDATA_TPMS",
turnSignal				= "VEHICLEDATA_TURNSIGNAL"}

local allVehicleData = {	"gps", 
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
"turnSignal"}

function Test:subscribeVehicleDataSuccess(paramsSend)
  local function setSVDRequest(paramsSend)
    local temp = {}	
    for i = 1, #paramsSend do		
      temp[paramsSend[i]] = true
    end	
    return temp
  end
  
  local function setSVDResponse(paramsSend, vehicleDataResultCode)
    local temp = {}
    local vehicleDataResultCodeValue = ""
    
    if vehicleDataResultCode ~= nil then
      vehicleDataResultCodeValue = vehicleDataResultCode
    else
      vehicleDataResultCodeValue = "SUCCESS"
    end
    
    for i = 1, #paramsSend do
      if paramsSend[i] == "clusterModeStatus" then
        temp["clusterModes"] = {					
          resultCode = vehicleDataResultCodeValue, 
          dataType = SVDValues[paramsSend[i]]
        }
      else
        temp[paramsSend[i]] = {					
          resultCode = vehicleDataResultCodeValue, 
          dataType = SVDValues[paramsSend[i]]
        }
      end
    end	
    return temp
  end
  
  local function createSuccessExpectedResult(response)
    response["success"] = true
    response["resultCode"] = "SUCCESS"
    
    return response
  end
  
  local request = setSVDRequest(paramsSend)
  local response = setSVDResponse(paramsSend)
  
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
  EXPECT_RESPONSE(cid, expectedResult)
  
  --mobile side: expect OnHashChange notification
  EXPECT_NOTIFICATION("OnHashChange")
end

---------------------------------------------------------------------------------------------
-------------------------- Overwrite These Functions For This Script-------------------------
---------------------------------------------------------------------------------------------
--Specific functions for this script
--1. verify_SUCCESS_Notification_Case(Notification)
--2. verify_Notification_IsIgnored_Case(Notification)
---------------------------------------------------------------------------------------------


--This function is used to send default request and response with specific valid data and verify SUCCESS resultCode
-- Note: vin in Notification from HMI will be ignored by SDL according to APPLINK-26880
function Test:verify_SUCCESS_Notification_Case(Notification, ExpectNotification)
  
  local expNotification	
  if ExpectNotification == nil then
    expNotification = Notification
  else 
    expNotification = ExpectNotification
  end
  
  self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", Notification)	 		
  
  --mobile side: expected SubscribeVehicleData response
  EXPECT_NOTIFICATION("OnVehicleData", expNotification)	
  
end


function Test:verify_Notification_IsIgnored_Case(Notification)
  
  commonTestCases:DelayedExp(1000)
  self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", Notification)
  --mobile side: expected Notification
  EXPECT_NOTIFICATION("OnVehicleData", Notification)	
  :Times(0)
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
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/PTU_ForVehicleData.json")	

----Get appID Value on HMI side
function Test:GetAppID()
  Apps[1].appID = self.applications[Apps[1].appName]
end

function Test:SubscribeVehicleData_Positive() 				
  self:subscribeVehicleDataSuccess(allVehicleData)				
end


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
----------------------------------Check normal cases of HMI notification---------------------------
-----------------------------------------------------------------------------------------------
--Requirement id in JAMA or JIRA: 	
--SDLAQ-CRS-1052: OnVehicleData
-- APPLINK-16076: SDL must treat integer value for params of float type as valid
-- APPLINK-25603
-- APPLINK-23918
-- APPLINK-19583
-- APPLINK-25703

--Verification criteria: The application is notified by the onVehicleData notification whenever new data is available and the app is subscribed for this data type.
--Verification criteria: "Integer" value for "float" param should not be treated as an invalid_data by SDL

----------------------------------------------------------------------------------------------
--List of parameters:
--1.speed: type=Float minvalue=0 maxvalue=700 mandatory=false
--2.fuelLevel: type=Float minvalue=-6 maxvalue=106 mandatory=false
--3.instantFuelConsumption: type=Float minvalue=0 maxvalue=25575 mandatory=false
--4.externalTemperature: type=Float minvalue=-40 maxvalue=100 mandatory=false
--5.engineTorque: type=Float minvalue=-1000 maxvalue=2000 mandatory=false
--6.accPedalPosition: type=Float minvalue=0 maxvalue=100 mandatory=false
--7.steeringWheelAngle: type=Float minvalue=-2000 maxvalue=2000 mandatory=false	
--8.rpm: type=Integer minvalue=0 maxvalue=20000 mandatory=false
--9.odometer: type=Integer minvalue=0 maxvalue=17000000 mandatory=false
--10.vin: type=String maxlength=17 mandatory=false
--11.prndl: type=Common.PRNDL mandatory=false
--12.fuelLevel_State: type=Common.ComponentVolumeStatus mandatory=false
--13.driverBraking: type=Common.VehicleDataEventStatus mandatory=false
--14.wiperStatus: type=Common.WiperStatus mandatory=false
--15.headLampStatus: type=Common.HeadLampStatus mandatory=false
--16.myKey: type=Common.MyKey mandatory=false	
--17.deviceStatus: type=Common.DeviceStatus mandatory=false
--18.eCallInfo: type=Common.ECallInfo mandatory=false
--18.emergencyEvent: type=Common.EmergencyEvent mandatory=false
--20.bodyInformation: type=Common.BodyInformation mandatory=false	
--21.clusterModeStatus: type=Common.ClusterModeStatus mandatory=false
--22.beltStatus: type=Common.BeltStatus mandatory=false
--23.airbagStatus: type=Common.AirbagStatus mandatory=false
--24.gps: type=Common.GPSData mandatory=false
--25.tirePressure: type=Common.TireStatus mandatory=false
--26. fuelRange: type=Float minvalue=0 maxvalue=10000 mandatory="false"
--27. abs_State: type="ABS_STATE" mandatory="false"
--28. tirePressureValue: type="TirePressureValue" mandatory="false"
--29. tpms: type="TPMS" mandatory="false"
--30. turnSignal: type="TurnSignal" mandatory="false"
---------------------------------------------------------------------------------------------------------------------------------

--This test case is used in some places such as verify all parameters are low bound, notification in different HMI levels
local function OnVehicleData_AllParametersLowerBound_SUCCESS(TestCaseName)
  
  Test[TestCaseName] = function(self)
    
    local Notification = 
    {
      speed = 0.0,
      fuelLevel = -6.000000,
      instantFuelConsumption = 0.000000,
      externalTemperature = -40.000000,
      engineTorque = -1000.000000,
      accPedalPosition = 0.000000,
      steeringWheelAngle = -2000.000000,
      
      rpm = 0,
      odometer = 0,
      
      vin = "a",
      
      prndl = "PARK",
      fuelLevel_State = "UNKNOWN",
      driverBraking = "NO_EVENT",
      wiperStatus = "OFF",
      
      headLampStatus = {	 lowBeamsOn = false, 
        highBeamsOn = false, 
        ambientLightSensorStatus = "NIGHT"
      },
      myKey = 		{	 e911Override = "NO_DATA_EXISTS"},
      deviceStatus = 	{	 voiceRecOn = true,
        btIconOn = true,
        callActive = true,
        phoneRoaming = true,
        textMsgAvailable = true,
        stereoAudioOutputMuted = true,
        monoAudioOutputMuted = true,
        eCallEventActive = true,
        primaryAudioSource = "USB",
        battLevelStatus = "ZERO_LEVEL_BARS",
        signalLevelStatus = "ZERO_LEVEL_BARS"
      },
      eCallInfo = 	{	 eCallNotificationStatus = "NOT_SUPPORTED",
        auxECallNotificationStatus = "NOT_SUPPORTED",
        eCallConfirmationStatus = "NORMAL"
      },
      emergencyEvent ={	 emergencyEventType = "NO_EVENT",
        fuelCutoffStatus = "TERMINATE_FUEL",
        rolloverEvent = "NO_EVENT",
        maximumChangeVelocity = 0,
        multipleEvents = "NO_EVENT"
      },
      bodyInformation={	 parkBrakeActive = true, 
        driverDoorAjar = true,
        passengerDoorAjar = true,
        rearLeftDoorAjar = true,
        rearRightDoorAjar = true,
        ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
        ignitionStatus = "UNKNOWN"
      },
      clusterModeStatus={	 powerModeActive = true, 
        powerModeQualificationStatus = "POWER_MODE_UNDEFINED",
        carModeStatus = "NORMAL",
        powerModeStatus = "KEY_OUT"
      },
      beltStatus = 	{	 driverBeltDeployed = "NO_EVENT",
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
        middleRow1BuckleBelted = "NO_EVENT"
      },
      airbagStatus = {	 driverAirbagDeployed = "YES",
        driverSideAirbagDeployed = "YES",
        driverCurtainAirbagDeployed = "YES",
        passengerAirbagDeployed = "YES",
        passengerCurtainAirbagDeployed = "YES",			
        driverKneeAirbagDeployed = "YES",
        passengerSideAirbagDeployed = "YES",
        passengerKneeAirbagDeployed = "YES"
      },
      gps = 			{	 longitudeDegrees = -180.0,
        latitudeDegrees = -90.0,
        pdop = 0.0,
        hdop = 0.0,
        vdop = 0.0,
        altitude = -10000.0,
        heading = 0.0,
        speed = 0.0,
        
        utcYear = 2010,
        utcMonth = 1,
        utcDay = 1,
        utcHours = 0,
        utcMinutes = 0,
        utcSeconds = 0,
        satellites = 0,
        
        compassDirection = "NORTH",
        dimension = "NO_FIX",
        actual = true
      },
      tirePressure = 	{	 pressureTelltale = "OFF",
        leftFront = {status = "UNKNOWN"},
        rightFront = {status = "UNKNOWN"},
        leftRear = {status = "UNKNOWN"},
        rightRear = {status = "UNKNOWN"},
        innerLeftRear = {status = "UNKNOWN"},
        innerRightRear = {status = "UNKNOWN"}
      },
      fuelRange = 0.0,
      abs_State = "INACTIVE",
      tirePressureValue = {
        leftFront = 0,
        rightFront = 0,
        leftRear = 0,
        rightRear = 0,
        innerLeftRear = 0,
        innerRightRear = 0,
        frontRecommended = 0,
        rearRecommended = 0
      },
      tpms = "UNKNOWN",
      turnSignal = "OFF"
    }
    
    local ExpectNotification = 
    {
      speed = 0.0,
      fuelLevel = -6.000000,
      instantFuelConsumption = 0.000000,
      externalTemperature = -40.000000,
      engineTorque = -1000.000000,
      accPedalPosition = 0.000000,
      steeringWheelAngle = -2000.000000,
      
      rpm = 0,
      odometer = 0,
      
      --vin = "a",
      
      prndl = "PARK",
      fuelLevel_State = "UNKNOWN",
      driverBraking = "NO_EVENT",
      wiperStatus = "OFF",
      
      headLampStatus = {	 lowBeamsOn = false, 
        highBeamsOn = false, 
        ambientLightSensorStatus = "NIGHT"
      },
      myKey = 		{	 e911Override = "NO_DATA_EXISTS"},
      deviceStatus = 	{	 voiceRecOn = true,
        btIconOn = true,
        callActive = true,
        phoneRoaming = true,
        textMsgAvailable = true,
        stereoAudioOutputMuted = true,
        monoAudioOutputMuted = true,
        eCallEventActive = true,
        primaryAudioSource = "USB",
        battLevelStatus = "ZERO_LEVEL_BARS",
        signalLevelStatus = "ZERO_LEVEL_BARS"
      },
      eCallInfo = 	{	 eCallNotificationStatus = "NOT_SUPPORTED",
        auxECallNotificationStatus = "NOT_SUPPORTED",
        eCallConfirmationStatus = "NORMAL"
      },
      emergencyEvent ={	 emergencyEventType = "NO_EVENT",
        fuelCutoffStatus = "TERMINATE_FUEL",
        rolloverEvent = "NO_EVENT",
        maximumChangeVelocity = 0,
        multipleEvents = "NO_EVENT"
      },
      bodyInformation={	 parkBrakeActive = true, 
        driverDoorAjar = true,
        passengerDoorAjar = true,
        rearLeftDoorAjar = true,
        rearRightDoorAjar = true,
        ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
        ignitionStatus = "UNKNOWN"
      },
      clusterModeStatus={	 powerModeActive = true, 
        powerModeQualificationStatus = "POWER_MODE_UNDEFINED",
        carModeStatus = "NORMAL",
        powerModeStatus = "KEY_OUT"
      },
      beltStatus = 	{	 driverBeltDeployed = "NO_EVENT",
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
        middleRow1BuckleBelted = "NO_EVENT"
      },
      airbagStatus = {	 driverAirbagDeployed = "YES",
        driverSideAirbagDeployed = "YES",
        driverCurtainAirbagDeployed = "YES",
        passengerAirbagDeployed = "YES",
        passengerCurtainAirbagDeployed = "YES",			
        driverKneeAirbagDeployed = "YES",
        passengerSideAirbagDeployed = "YES",
        passengerKneeAirbagDeployed = "YES"
      },
      gps = 			{	 longitudeDegrees = -180.0,
        latitudeDegrees = -90.0,
        pdop = 0.0,
        hdop = 0.0,
        vdop = 0.0,
        altitude = -10000.0,
        heading = 0.0,
        speed = 0.0,
        
        utcYear = 2010,
        utcMonth = 1,
        utcDay = 1,
        utcHours = 0,
        utcMinutes = 0,
        utcSeconds = 0,
        satellites = 0,
        
        compassDirection = "NORTH",
        dimension = "NO_FIX",
        actual = true
      },
      tirePressure = 	{	 pressureTelltale = "OFF",
        leftFront = {status = "UNKNOWN"},
        rightFront = {status = "UNKNOWN"},
        leftRear = {status = "UNKNOWN"},
        rightRear = {status = "UNKNOWN"},
        innerLeftRear = {status = "UNKNOWN"},
        innerRightRear = {status = "UNKNOWN"}
      },
      fuelRange = 0.0,
      abs_State = "INACTIVE",
      tirePressureValue = {
        leftFront = 0,
        rightFront = 0,
        leftRear = 0,
        rightRear = 0,
        innerLeftRear = 0,
        innerRightRear = 0,
        frontRecommended = 0,
        rearRecommended = 0
      },
      tpms = "UNKNOWN",
      turnSignal = "OFF"
    }
    
    self:verify_SUCCESS_Notification_Case(Notification, ExpectNotification)
    
  end
end

---------------------------------------------------------------------------------------------------------------------------------

--This test case is used to verify all parameters are low bound when integer values for next params of float type are sent:
-- speed
-- fuelLevel
-- instantFuelConsumption
-- externalTemperature
-- engineTorque
-- accPedalPosition
-- steeringWheelAngle
-- gps params
--fuelRange

local function OnVehicleData_AllParametersLowerBoundand_IntForFloat_SUCCESS(TestCaseName2)
  
  Test[TestCaseName2] = function(self)
    
    local Notification = 
    {
      speed = 0,
      fuelLevel = -6,
      instantFuelConsumption = 0,
      externalTemperature = -40,
      engineTorque = -1000,
      accPedalPosition = 0,
      steeringWheelAngle = -2000,
      
      rpm = 0,
      odometer = 0,
      
      vin = "a",
      
      prndl = "PARK",
      fuelLevel_State = "UNKNOWN",
      driverBraking = "NO_EVENT",
      wiperStatus = "OFF",
      
      headLampStatus = {	 lowBeamsOn = false, 
        highBeamsOn = false, 
        ambientLightSensorStatus = "NIGHT"
      },
      myKey = 		{	 e911Override = "NO_DATA_EXISTS"},
      deviceStatus = 	{	 voiceRecOn = true,
        btIconOn = true,
        callActive = true,
        phoneRoaming = true,
        textMsgAvailable = true,
        stereoAudioOutputMuted = true,
        monoAudioOutputMuted = true,
        eCallEventActive = true,
        primaryAudioSource = "USB",
        battLevelStatus = "ZERO_LEVEL_BARS",
        signalLevelStatus = "ZERO_LEVEL_BARS"
      },
      eCallInfo = 	{	 eCallNotificationStatus = "NOT_SUPPORTED",
        auxECallNotificationStatus = "NOT_SUPPORTED",
        eCallConfirmationStatus = "NORMAL"
      },
      emergencyEvent ={	 emergencyEventType = "NO_EVENT",
        fuelCutoffStatus = "TERMINATE_FUEL",
        rolloverEvent = "NO_EVENT",
        maximumChangeVelocity = 0,
        multipleEvents = "NO_EVENT"
      },
      bodyInformation={	 parkBrakeActive = true, 
        driverDoorAjar = true,
        passengerDoorAjar = true,
        rearLeftDoorAjar = true,
        rearRightDoorAjar = true,
        ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
        ignitionStatus = "UNKNOWN"
      },
      clusterModeStatus={	 powerModeActive = true, 
        powerModeQualificationStatus = "POWER_MODE_UNDEFINED",
        carModeStatus = "NORMAL",
        powerModeStatus = "KEY_OUT"
      },
      beltStatus = 	{	 driverBeltDeployed = "NO_EVENT",
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
        middleRow1BuckleBelted = "NO_EVENT"
      },
      airbagStatus = {	 driverAirbagDeployed = "YES",
        driverSideAirbagDeployed = "YES",
        driverCurtainAirbagDeployed = "YES",
        passengerAirbagDeployed = "YES",
        passengerCurtainAirbagDeployed = "YES",			
        driverKneeAirbagDeployed = "YES",
        passengerSideAirbagDeployed = "YES",
        passengerKneeAirbagDeployed = "YES"
      },
      gps = 			{	 longitudeDegrees = -180,
        latitudeDegrees = -90,
        pdop = 0,
        hdop = 0,
        vdop = 0,
        altitude = -10000.0,
        heading = 0,
        speed = 0,
        
        utcYear = 2010,
        utcMonth = 1,
        utcDay = 1,
        utcHours = 0,
        utcMinutes = 0,
        utcSeconds = 0,
        satellites = 0,
        
        compassDirection = "NORTH",
        dimension = "NO_FIX",
        actual = true
      },
      tirePressure = 	{	 pressureTelltale = "OFF",
        leftFront = {status = "UNKNOWN"},
        rightFront = {status = "UNKNOWN"},
        leftRear = {status = "UNKNOWN"},
        rightRear = {status = "UNKNOWN"},
        innerLeftRear = {status = "UNKNOWN"},
        innerRightRear = {status = "UNKNOWN"}
      },
      fuelRange = 0,
      abs_State = "ACTIVE",
      tirePressureValue = {
        leftFront = 0,
        rightFront = 0,
        leftRear = 0,
        rightRear = 0,
        innerLeftRear = 0,
        innerRightRear = 0,
        frontRecommended = 0,
        rearRecommended = 0
      },
      tpms = "TIRES_NOT_TRAINED",
      turnSignal = "UNUSED"				
    }
    
    local ExpectNotification = 
    {
      speed = 0,
      fuelLevel = -6,
      instantFuelConsumption = 0,
      externalTemperature = -40,
      engineTorque = -1000,
      accPedalPosition = 0,
      steeringWheelAngle = -2000,
      
      rpm = 0,
      odometer = 0,
      
      --vin = "a",
      
      prndl = "PARK",
      fuelLevel_State = "UNKNOWN",
      driverBraking = "NO_EVENT",
      wiperStatus = "OFF",
      
      headLampStatus = {	 lowBeamsOn = false, 
        highBeamsOn = false, 
        ambientLightSensorStatus = "NIGHT"
      },
      myKey = 		{	 e911Override = "NO_DATA_EXISTS"},
      deviceStatus = 	{	 voiceRecOn = true,
        btIconOn = true,
        callActive = true,
        phoneRoaming = true,
        textMsgAvailable = true,
        stereoAudioOutputMuted = true,
        monoAudioOutputMuted = true,
        eCallEventActive = true,
        primaryAudioSource = "USB",
        battLevelStatus = "ZERO_LEVEL_BARS",
        signalLevelStatus = "ZERO_LEVEL_BARS"
      },
      eCallInfo = 	{	 eCallNotificationStatus = "NOT_SUPPORTED",
        auxECallNotificationStatus = "NOT_SUPPORTED",
        eCallConfirmationStatus = "NORMAL"
      },
      emergencyEvent ={	 emergencyEventType = "NO_EVENT",
        fuelCutoffStatus = "TERMINATE_FUEL",
        rolloverEvent = "NO_EVENT",
        maximumChangeVelocity = 0,
        multipleEvents = "NO_EVENT"
      },
      bodyInformation={	 parkBrakeActive = true, 
        driverDoorAjar = true,
        passengerDoorAjar = true,
        rearLeftDoorAjar = true,
        rearRightDoorAjar = true,
        ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
        ignitionStatus = "UNKNOWN"
      },
      clusterModeStatus={	 powerModeActive = true, 
        powerModeQualificationStatus = "POWER_MODE_UNDEFINED",
        carModeStatus = "NORMAL",
        powerModeStatus = "KEY_OUT"
      },
      beltStatus = 	{	 driverBeltDeployed = "NO_EVENT",
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
        middleRow1BuckleBelted = "NO_EVENT"
      },
      airbagStatus = {	 driverAirbagDeployed = "YES",
        driverSideAirbagDeployed = "YES",
        driverCurtainAirbagDeployed = "YES",
        passengerAirbagDeployed = "YES",
        passengerCurtainAirbagDeployed = "YES",			
        driverKneeAirbagDeployed = "YES",
        passengerSideAirbagDeployed = "YES",
        passengerKneeAirbagDeployed = "YES"
      },
      gps = 			{	 longitudeDegrees = -180,
        latitudeDegrees = -90,
        pdop = 0,
        hdop = 0,
        vdop = 0,
        altitude = -10000.0,
        heading = 0,
        speed = 0,
        
        utcYear = 2010,
        utcMonth = 1,
        utcDay = 1,
        utcHours = 0,
        utcMinutes = 0,
        utcSeconds = 0,
        satellites = 0,
        
        compassDirection = "NORTH",
        dimension = "NO_FIX",
        actual = true
      },
      tirePressure = 	{	 pressureTelltale = "OFF",
        leftFront = {status = "UNKNOWN"},
        rightFront = {status = "UNKNOWN"},
        leftRear = {status = "UNKNOWN"},
        rightRear = {status = "UNKNOWN"},
        innerLeftRear = {status = "UNKNOWN"},
        innerRightRear = {status = "UNKNOWN"}
      },
      fuelRange = 0,
      abs_State = "ACTIVE",
      tirePressureValue = {
        leftFront = 0,
        rightFront = 0,
        leftRear = 0,
        rightRear = 0,
        innerLeftRear = 0,
        innerRightRear = 0,
        frontRecommended = 0,
        rearRecommended = 0
      },
      tpms = "TIRES_NOT_TRAINED",
      turnSignal = "UNUSED"				
    }
    
    self:verify_SUCCESS_Notification_Case(Notification, ExpectNotification)
    
  end
end

-------------------------------------------------------------------------------------------------------------------------------	

local function common_Test_Cases_For_Notification()
  --Print new line to separate new test cases group
  commonFunctions:newTestCasesGroup("Test suite: Common test cases of HMI notification")
  -------------------------------------------------------------------------------------------------------------
  --Common Test cases for Notification
  --1. PositiveNotification
  --2. Only mandatory parameters
  --3. All parameters are lower bound
  --4. All parameters are upper bound
  -----------------------------------------------------------------------------------------------------------------------------
  
  Test["OnVehicleData_OnlyMandatoryParameters_SUCCESS_gps"] = function(self)
    local Notification = 
    {
      
      gps = 			{	 longitudeDegrees = 180,
        latitudeDegrees = 90
      }
    }
    
    local ExpectNotification = 
    {
      
      gps = 			{	 longitudeDegrees = 180,
        latitudeDegrees = 90
        
      }
    }
    
    self:verify_SUCCESS_Notification_Case(Notification, ExpectNotification)
    
  end
  Test["OnVehicleData_PositiveNotification_SUCCESS"] = function(self)
    
    local Notification = 
    {
      speed = 1.1,
      fuelLevel = 1.1,
      instantFuelConsumption = 1.1,
      externalTemperature = 1.1,
      engineTorque = 1.1,
      accPedalPosition = 1.1,
      steeringWheelAngle = 1.1,
      
      rpm = 1,
      odometer = 1,
      
      vin = "a",
      
      prndl = "PARK",
      fuelLevel_State = "UNKNOWN",
      driverBraking = "NO_EVENT",
      wiperStatus = "OFF",
      
      headLampStatus = {	 lowBeamsOn = false, 
        highBeamsOn = false, 
        ambientLightSensorStatus = "NIGHT"
      },
      myKey = 		{	 e911Override = "NO_DATA_EXISTS"},
      deviceStatus = 	{	 voiceRecOn = true,
        btIconOn = true,
        callActive = true,
        phoneRoaming = true,
        textMsgAvailable = true,
        stereoAudioOutputMuted = true,
        monoAudioOutputMuted = true,
        eCallEventActive = true,
        primaryAudioSource = "USB",
        battLevelStatus = "ZERO_LEVEL_BARS",
        signalLevelStatus = "ZERO_LEVEL_BARS"
      },
      eCallInfo = 	{	 eCallNotificationStatus = "NOT_SUPPORTED",
        auxECallNotificationStatus = "NOT_SUPPORTED",
        eCallConfirmationStatus = "NORMAL"
      },
      emergencyEvent ={	 emergencyEventType = "NO_EVENT",
        fuelCutoffStatus = "TERMINATE_FUEL",
        rolloverEvent = "NO_EVENT",
        maximumChangeVelocity = 0,
        multipleEvents = "NO_EVENT"
      },
      bodyInformation={	 parkBrakeActive = true, 
        driverDoorAjar = true,
        passengerDoorAjar = true,
        rearLeftDoorAjar = true,
        rearRightDoorAjar = true,
        ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
        ignitionStatus = "UNKNOWN"
      },
      clusterModeStatus={	 powerModeActive = true, 
        powerModeQualificationStatus = "POWER_MODE_UNDEFINED",
        carModeStatus = "NORMAL",
        powerModeStatus = "KEY_OUT"
      },
      beltStatus = 	{	 driverBeltDeployed = "NO_EVENT",
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
        middleRow1BuckleBelted = "NO_EVENT"
      },
      airbagStatus = {	 driverAirbagDeployed = "YES",
        driverSideAirbagDeployed = "YES",
        driverCurtainAirbagDeployed = "YES",
        passengerAirbagDeployed = "YES",
        passengerCurtainAirbagDeployed = "YES",			
        driverKneeAirbagDeployed = "YES",
        passengerSideAirbagDeployed = "YES",
        passengerKneeAirbagDeployed = "YES"
      },
      gps = 			{ 	longitudeDegrees = 1.1,
        latitudeDegrees = 1.1,
        pdop = 1.1,
        hdop = 1.1,
        vdop = 1.1,
        altitude = 1.1,
        heading = 1.1,
        speed = 1.1,
        
        utcYear = 2011,
        utcMonth = 1,
        utcDay = 1,
        utcHours = 1,
        utcMinutes = 1,
        utcSeconds = 1,
        satellites = 1,
        
        compassDirection = "NORTH",
        dimension = "NO_FIX",
        actual = true
      },
      tirePressure = 	{	 pressureTelltale = "OFF",
        leftFront = {status = "UNKNOWN"},
        rightFront = {status = "UNKNOWN"},
        leftRear = {status = "UNKNOWN"},
        rightRear = {status = "UNKNOWN"},
        innerLeftRear = {status = "UNKNOWN"},
        innerRightRear = {status = "UNKNOWN"}
      },
      fuelRange = 1.1,
      abs_State = "ACTIVE",
      tirePressureValue = {
        leftFront = 1,
        rightFront = 1,
        leftRear = 1,
        rightRear = 1,
        innerLeftRear = 1,
        innerRightRear = 1,
        frontRecommended = 1,
        rearRecommended = 1
      },
      tpms = "LOW",
      turnSignal = "LEFT"
    }
    
    local ExpectNotification = 
    {
      speed = 1.1,
      fuelLevel = 1.1,
      instantFuelConsumption = 1.1,
      externalTemperature = 1.1,
      engineTorque = 1.1,
      accPedalPosition = 1.1,
      steeringWheelAngle = 1.1,
      
      rpm = 1,
      odometer = 1,
      
      --vin = "a",
      
      prndl = "PARK",
      fuelLevel_State = "UNKNOWN",
      driverBraking = "NO_EVENT",
      wiperStatus = "OFF",
      
      headLampStatus = {	 lowBeamsOn = false, 
        highBeamsOn = false, 
        ambientLightSensorStatus = "NIGHT"
      },
      myKey = 		{	 e911Override = "NO_DATA_EXISTS"},
      deviceStatus = 	{	 voiceRecOn = true,
        btIconOn = true,
        callActive = true,
        phoneRoaming = true,
        textMsgAvailable = true,
        stereoAudioOutputMuted = true,
        monoAudioOutputMuted = true,
        eCallEventActive = true,
        primaryAudioSource = "USB",
        battLevelStatus = "ZERO_LEVEL_BARS",
        signalLevelStatus = "ZERO_LEVEL_BARS"
      },
      eCallInfo = 	{	 eCallNotificationStatus = "NOT_SUPPORTED",
        auxECallNotificationStatus = "NOT_SUPPORTED",
        eCallConfirmationStatus = "NORMAL"
      },
      emergencyEvent ={	 emergencyEventType = "NO_EVENT",
        fuelCutoffStatus = "TERMINATE_FUEL",
        rolloverEvent = "NO_EVENT",
        maximumChangeVelocity = 0,
        multipleEvents = "NO_EVENT"
      },
      bodyInformation={	 parkBrakeActive = true, 
        driverDoorAjar = true,
        passengerDoorAjar = true,
        rearLeftDoorAjar = true,
        rearRightDoorAjar = true,
        ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
        ignitionStatus = "UNKNOWN"
      },
      clusterModeStatus={	 powerModeActive = true, 
        powerModeQualificationStatus = "POWER_MODE_UNDEFINED",
        carModeStatus = "NORMAL",
        powerModeStatus = "KEY_OUT"
      },
      beltStatus = 	{	 driverBeltDeployed = "NO_EVENT",
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
        middleRow1BuckleBelted = "NO_EVENT"
      },
      airbagStatus = {	 driverAirbagDeployed = "YES",
        driverSideAirbagDeployed = "YES",
        driverCurtainAirbagDeployed = "YES",
        passengerAirbagDeployed = "YES",
        passengerCurtainAirbagDeployed = "YES",			
        driverKneeAirbagDeployed = "YES",
        passengerSideAirbagDeployed = "YES",
        passengerKneeAirbagDeployed = "YES"
      },
      gps = 			{ 	longitudeDegrees = 1.1,
        latitudeDegrees = 1.1,
        pdop = 1.1,
        hdop = 1.1,
        vdop = 1.1,
        altitude = 1.1,
        heading = 1.1,
        speed = 1.1,
        
        utcYear = 2011,
        utcMonth = 1,
        utcDay = 1,
        utcHours = 1,
        utcMinutes = 1,
        utcSeconds = 1,
        satellites = 1,
        
        compassDirection = "NORTH",
        dimension = "NO_FIX",
        actual = true
      },
      tirePressure = 	{	 pressureTelltale = "OFF",
        leftFront = {status = "UNKNOWN"},
        rightFront = {status = "UNKNOWN"},
        leftRear = {status = "UNKNOWN"},
        rightRear = {status = "UNKNOWN"},
        innerLeftRear = {status = "UNKNOWN"},
        innerRightRear = {status = "UNKNOWN"}
      },
      fuelRange = 1.1,
      abs_State = "ACTIVE",
      tirePressureValue = {
        leftFront = 1,
        rightFront = 1,
        leftRear = 1,
        rightRear = 1,
        innerLeftRear = 1,
        innerRightRear = 1,
        frontRecommended = 1,
        rearRecommended = 1
      },
      tpms = "LOW",
      turnSignal = "LEFT"
    }
    
    self:verify_SUCCESS_Notification_Case(Notification, ExpectNotification)
    
  end
  
  -----------------------------------------------------------------------------------------------------------------------------
  
  --This test case is used to verify positive response to notification when integer values for next params of float type are sent:
  -- speed
  -- fuelLevel
  -- instantFuelConsumption
  -- externalTemperature
  -- engineTorque
  -- accPedalPosition
  -- steeringWheelAngle
  -- gps params
  -- fuelRange
  
  
  Test["OnVehicleData_PositiveNotification_IntForFloat_SUCCESS"] = function(self)
    
    local Notification = 
    {
      speed = 1,
      fuelLevel = 1,
      instantFuelConsumption = 1,
      externalTemperature = 1,
      engineTorque = 1,
      accPedalPosition = 1,
      steeringWheelAngle = 1,
      
      rpm = 1,
      odometer = 1,
      
      vin = "a",
      
      prndl = "PARK",
      fuelLevel_State = "UNKNOWN",
      driverBraking = "NO_EVENT",
      wiperStatus = "OFF",
      
      headLampStatus = {	 lowBeamsOn = false, 
        highBeamsOn = false, 
        ambientLightSensorStatus = "NIGHT"
      },
      myKey = 		{	 e911Override = "NO_DATA_EXISTS"},
      deviceStatus = 	{	 voiceRecOn = true,
        btIconOn = true,
        callActive = true,
        phoneRoaming = true,
        textMsgAvailable = true,
        stereoAudioOutputMuted = true,
        monoAudioOutputMuted = true,
        eCallEventActive = true,
        primaryAudioSource = "USB",
        battLevelStatus = "ZERO_LEVEL_BARS",
        signalLevelStatus = "ZERO_LEVEL_BARS"
      },
      eCallInfo = 	{	 eCallNotificationStatus = "NOT_SUPPORTED",
        auxECallNotificationStatus = "NOT_SUPPORTED",
        eCallConfirmationStatus = "NORMAL"
      },
      emergencyEvent ={	 emergencyEventType = "NO_EVENT",
        fuelCutoffStatus = "TERMINATE_FUEL",
        rolloverEvent = "NO_EVENT",
        maximumChangeVelocity = 0,
        multipleEvents = "NO_EVENT"
      },
      bodyInformation={	 parkBrakeActive = true, 
        driverDoorAjar = true,
        passengerDoorAjar = true,
        rearLeftDoorAjar = true,
        rearRightDoorAjar = true,
        ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
        ignitionStatus = "UNKNOWN"
      },
      clusterModeStatus={	 powerModeActive = true, 
        powerModeQualificationStatus = "POWER_MODE_UNDEFINED",
        carModeStatus = "NORMAL",
        powerModeStatus = "KEY_OUT"
      },
      beltStatus = 	{	 driverBeltDeployed = "NO_EVENT",
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
        middleRow1BuckleBelted = "NO_EVENT"
      },
      airbagStatus = {	 driverAirbagDeployed = "YES",
        driverSideAirbagDeployed = "YES",
        driverCurtainAirbagDeployed = "YES",
        passengerAirbagDeployed = "YES",
        passengerCurtainAirbagDeployed = "YES",			
        driverKneeAirbagDeployed = "YES",
        passengerSideAirbagDeployed = "YES",
        passengerKneeAirbagDeployed = "YES"
      },
      gps = 			{ 	longitudeDegrees = 1,
        latitudeDegrees = 1,
        pdop = 1,
        hdop = 1,
        vdop = 1,
        altitude = 1,
        heading = 1,
        speed = 1,
        
        utcYear = 2011,
        utcMonth = 1,
        utcDay = 1,
        utcHours = 1,
        utcMinutes = 1,
        utcSeconds = 1,
        satellites = 1,
        
        compassDirection = "NORTH",
        dimension = "NO_FIX",
        actual = true
      },
      tirePressure = 	{	 pressureTelltale = "OFF",
        leftFront = {status = "UNKNOWN"},
        rightFront = {status = "UNKNOWN"},
        leftRear = {status = "UNKNOWN"},
        rightRear = {status = "UNKNOWN"},
        innerLeftRear = {status = "UNKNOWN"},
        innerRightRear = {status = "UNKNOWN"}
      },
      fuelRange = 1,
      abs_State = "ACTIVE",
      tirePressureValue = {
        leftFront = 1,
        rightFront = 1,
        leftRear = 1,
        rightRear = 1,
        innerLeftRear = 1,
        innerRightRear = 1,
        frontRecommended = 1,
        rearRecommended = 1
      },
      tpms = "SYSTEM_ACTIVE",
      turnSignal = "RIGHT"
    }
    
    local ExpectNotification = 
    {
      speed = 1,
      fuelLevel = 1,
      instantFuelConsumption = 1,
      externalTemperature = 1,
      engineTorque = 1,
      accPedalPosition = 1,
      steeringWheelAngle = 1,
      
      rpm = 1,
      odometer = 1,
      
      --vin = "a",
      
      prndl = "PARK",
      fuelLevel_State = "UNKNOWN",
      driverBraking = "NO_EVENT",
      wiperStatus = "OFF",
      
      headLampStatus = {	 lowBeamsOn = false, 
        highBeamsOn = false, 
        ambientLightSensorStatus = "NIGHT"
      },
      myKey = 		{	 e911Override = "NO_DATA_EXISTS"},
      deviceStatus = 	{	 voiceRecOn = true,
        btIconOn = true,
        callActive = true,
        phoneRoaming = true,
        textMsgAvailable = true,
        stereoAudioOutputMuted = true,
        monoAudioOutputMuted = true,
        eCallEventActive = true,
        primaryAudioSource = "USB",
        battLevelStatus = "ZERO_LEVEL_BARS",
        signalLevelStatus = "ZERO_LEVEL_BARS"
      },
      eCallInfo = 	{	 eCallNotificationStatus = "NOT_SUPPORTED",
        auxECallNotificationStatus = "NOT_SUPPORTED",
        eCallConfirmationStatus = "NORMAL"
      },
      emergencyEvent ={	 emergencyEventType = "NO_EVENT",
        fuelCutoffStatus = "TERMINATE_FUEL",
        rolloverEvent = "NO_EVENT",
        maximumChangeVelocity = 0,
        multipleEvents = "NO_EVENT"
      },
      bodyInformation={	 parkBrakeActive = true, 
        driverDoorAjar = true,
        passengerDoorAjar = true,
        rearLeftDoorAjar = true,
        rearRightDoorAjar = true,
        ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
        ignitionStatus = "UNKNOWN"
      },
      clusterModeStatus={	 powerModeActive = true, 
        powerModeQualificationStatus = "POWER_MODE_UNDEFINED",
        carModeStatus = "NORMAL",
        powerModeStatus = "KEY_OUT"
      },
      beltStatus = 	{	 driverBeltDeployed = "NO_EVENT",
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
        middleRow1BuckleBelted = "NO_EVENT"
      },
      airbagStatus = {	 driverAirbagDeployed = "YES",
        driverSideAirbagDeployed = "YES",
        driverCurtainAirbagDeployed = "YES",
        passengerAirbagDeployed = "YES",
        passengerCurtainAirbagDeployed = "YES",			
        driverKneeAirbagDeployed = "YES",
        passengerSideAirbagDeployed = "YES",
        passengerKneeAirbagDeployed = "YES"
      },
      gps = 			{ 	longitudeDegrees = 1,
        latitudeDegrees = 1,
        pdop = 1,
        hdop = 1,
        vdop = 1,
        altitude = 1,
        heading = 1,
        speed = 1,
        
        utcYear = 2011,
        utcMonth = 1,
        utcDay = 1,
        utcHours = 1,
        utcMinutes = 1,
        utcSeconds = 1,
        satellites = 1,
        
        compassDirection = "NORTH",
        dimension = "NO_FIX",
        actual = true
      },
      tirePressure = 	{	 pressureTelltale = "OFF",
        leftFront = {status = "UNKNOWN"},
        rightFront = {status = "UNKNOWN"},
        leftRear = {status = "UNKNOWN"},
        rightRear = {status = "UNKNOWN"},
        innerLeftRear = {status = "UNKNOWN"},
        innerRightRear = {status = "UNKNOWN"}
      },
      fuelRange = 1,
      abs_State = "ACTIVE",
      tirePressureValue = {
        leftFront = 1,
        rightFront = 1,
        leftRear = 1,
        rightRear = 1,
        innerLeftRear = 1,
        innerRightRear = 1,
        frontRecommended = 1,
        rearRecommended = 1
      },
      tpms = "SYSTEM_ACTIVE",
      turnSignal = "RIGHT"
    }
    
    self:verify_SUCCESS_Notification_Case(Notification, ExpectNotification)
    
  end
  
  --------------------------------------------------------------------------------------------------------------
  
  OnVehicleData_AllParametersLowerBound_SUCCESS("OnVehicleData_AllParametersLowerBound_SUCCESS")
  ----------------------------------------------------------------------------------------------------------------
  
  OnVehicleData_AllParametersLowerBoundand_IntForFloat_SUCCESS("OnVehicleData_AllParametersLowerBoundand_IntForFloat_SUCCESS")
  ----------------------------------------------------------------------------------------------------------------
  
  Test["OnVehicleData_AllParametersUpperBound_SUCCESS"] = function(self)
    local Notification = 
    {
      speed = 700.0,
      fuelLevel = 106.000000,
      instantFuelConsumption = 25575.000000,
      externalTemperature = 100.000000,
      engineTorque = 2000.000000,
      accPedalPosition = 100.000000,
      steeringWheelAngle = 2000.000000,
      
      rpm = 20000,
      odometer = 17000000,
      
      vin = "aaaaaaaaaaaaaaaaa",
      
      prndl = "PARK",
      fuelLevel_State = "UNKNOWN",
      driverBraking = "NO_EVENT",
      wiperStatus = "OFF",
      
      headLampStatus = {	 lowBeamsOn = false, 
        highBeamsOn = false, 
        ambientLightSensorStatus = "NIGHT"
      },
      myKey = 		{	 e911Override = "NO_DATA_EXISTS"},
      deviceStatus = 	{	 voiceRecOn = true,
        btIconOn = true,
        callActive = true,
        phoneRoaming = true,
        textMsgAvailable = true,
        stereoAudioOutputMuted = true,
        monoAudioOutputMuted = true,
        eCallEventActive = true,
        primaryAudioSource = "USB",
        battLevelStatus = "ZERO_LEVEL_BARS",
        signalLevelStatus = "ZERO_LEVEL_BARS"
      },
      eCallInfo = 	{	 eCallNotificationStatus = "NOT_SUPPORTED",
        auxECallNotificationStatus = "NOT_SUPPORTED",
        eCallConfirmationStatus = "NORMAL"
      },
      emergencyEvent ={	 emergencyEventType = "NO_EVENT",
        fuelCutoffStatus = "TERMINATE_FUEL",
        rolloverEvent = "NO_EVENT",
        maximumChangeVelocity = 255,
        multipleEvents = "NO_EVENT"
      },
      bodyInformation={	 parkBrakeActive = true, 
        driverDoorAjar = true,
        passengerDoorAjar = true,
        rearLeftDoorAjar = true,
        rearRightDoorAjar = true,
        ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
        ignitionStatus = "UNKNOWN"
      },
      clusterModeStatus={	 powerModeActive = true, 
        powerModeQualificationStatus = "POWER_MODE_UNDEFINED",
        carModeStatus = "NORMAL",
        powerModeStatus = "KEY_OUT"
      },
      beltStatus = 	{	 driverBeltDeployed = "NO_EVENT",
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
        middleRow1BuckleBelted = "NO_EVENT"
      },
      airbagStatus = {	 driverAirbagDeployed = "YES",
        driverSideAirbagDeployed = "YES",
        driverCurtainAirbagDeployed = "YES",
        passengerAirbagDeployed = "YES",
        passengerCurtainAirbagDeployed = "YES",			
        driverKneeAirbagDeployed = "YES",
        passengerSideAirbagDeployed = "YES",
        passengerKneeAirbagDeployed = "YES"
      },
      gps = 			{	 longitudeDegrees = 180.0,
        latitudeDegrees = 90.0,
        pdop = 10.0,
        hdop = 10.0,
        vdop = 10.0,
        altitude = 10000.0,
        heading = 359.99,
        speed = 500.0,
        
        utcYear = 2100,
        utcMonth = 12,
        utcDay = 31,
        utcHours = 23,
        utcMinutes = 59,
        utcSeconds = 59,
        satellites = 31,
        
        compassDirection = "NORTH",
        dimension = "NO_FIX",
        actual = true
      },
      tirePressure = 	{	 pressureTelltale = "OFF",
        leftFront = {status = "UNKNOWN"},
        rightFront = {status = "UNKNOWN"},
        leftRear = {status = "UNKNOWN"},
        rightRear = {status = "UNKNOWN"},
        innerLeftRear = {status = "UNKNOWN"},
        innerRightRear = {status = "UNKNOWN"}
      },
      fuelRange = 10000.00,
      abs_State = "ACTIVE",
      tirePressureValue = {
        leftFront = 65533,
        rightFront = 65533,
        leftRear = 65533,
        rightRear = 65533,
        innerLeftRear = 65533,
        innerRightRear = 65533,
        frontRecommended = 65533,
        rearRecommended = 65533
      },
      tpms = "SENSOR_FAULT",
      turnSignal = "OFF"
    }
    
    local ExpectNotification = 
    {
      speed = 700.0,
      fuelLevel = 106.000000,
      instantFuelConsumption = 25575.000000,
      externalTemperature = 100.000000,
      engineTorque = 2000.000000,
      accPedalPosition = 100.000000,
      steeringWheelAngle = 2000.000000,
      
      rpm = 20000,
      odometer = 17000000,
      
      --vin = "aaaaaaaaaaaaaaaaa",
      
      prndl = "PARK",
      fuelLevel_State = "UNKNOWN",
      driverBraking = "NO_EVENT",
      wiperStatus = "OFF",
      
      headLampStatus = {	 lowBeamsOn = false, 
        highBeamsOn = false, 
        ambientLightSensorStatus = "NIGHT"
      },
      myKey = 		{	 e911Override = "NO_DATA_EXISTS"},
      deviceStatus = 	{	 voiceRecOn = true,
        btIconOn = true,
        callActive = true,
        phoneRoaming = true,
        textMsgAvailable = true,
        stereoAudioOutputMuted = true,
        monoAudioOutputMuted = true,
        eCallEventActive = true,
        primaryAudioSource = "USB",
        battLevelStatus = "ZERO_LEVEL_BARS",
        signalLevelStatus = "ZERO_LEVEL_BARS"
      },
      eCallInfo = 	{	 eCallNotificationStatus = "NOT_SUPPORTED",
        auxECallNotificationStatus = "NOT_SUPPORTED",
        eCallConfirmationStatus = "NORMAL"
      },
      emergencyEvent ={	 emergencyEventType = "NO_EVENT",
        fuelCutoffStatus = "TERMINATE_FUEL",
        rolloverEvent = "NO_EVENT",
        maximumChangeVelocity = 255,
        multipleEvents = "NO_EVENT"
      },
      bodyInformation={	 parkBrakeActive = true, 
        driverDoorAjar = true,
        passengerDoorAjar = true,
        rearLeftDoorAjar = true,
        rearRightDoorAjar = true,
        ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
        ignitionStatus = "UNKNOWN"
      },
      clusterModeStatus={	 powerModeActive = true, 
        powerModeQualificationStatus = "POWER_MODE_UNDEFINED",
        carModeStatus = "NORMAL",
        powerModeStatus = "KEY_OUT"
      },
      beltStatus = 	{	 driverBeltDeployed = "NO_EVENT",
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
        middleRow1BuckleBelted = "NO_EVENT"
      },
      airbagStatus = {	 driverAirbagDeployed = "YES",
        driverSideAirbagDeployed = "YES",
        driverCurtainAirbagDeployed = "YES",
        passengerAirbagDeployed = "YES",
        passengerCurtainAirbagDeployed = "YES",			
        driverKneeAirbagDeployed = "YES",
        passengerSideAirbagDeployed = "YES",
        passengerKneeAirbagDeployed = "YES"
      },
      gps = 			{	 longitudeDegrees = 180.0,
        latitudeDegrees = 90.0,
        pdop = 10.0,
        hdop = 10.0,
        vdop = 10.0,
        altitude = 10000.0,
        heading = 359.99,
        speed = 500.0,
        
        utcYear = 2100,
        utcMonth = 12,
        utcDay = 31,
        utcHours = 23,
        utcMinutes = 59,
        utcSeconds = 59,
        satellites = 31,
        
        compassDirection = "NORTH",
        dimension = "NO_FIX",
        actual = true
      },
      tirePressure = 	{	 pressureTelltale = "OFF",
        leftFront = {status = "UNKNOWN"},
        rightFront = {status = "UNKNOWN"},
        leftRear = {status = "UNKNOWN"},
        rightRear = {status = "UNKNOWN"},
        innerLeftRear = {status = "UNKNOWN"},
        innerRightRear = {status = "UNKNOWN"}
      },
      fuelRange = 100000.00,
      abs_State = "ACTIVE",
      tirePressureValue = {
        leftFront = 65533,
        rightFront = 65533,
        leftRear = 65533,
        rightRear = 65533,
        innerLeftRear = 655330,
        innerRightRear = 65533,
        frontRecommended = 65533,
        rearRecommended = 65533
      },
      tpms = "SENSOR_FAULT",
      turnSignal = "OFF"
    }
    
    self:verify_SUCCESS_Notification_Case(Notification, ExpectNotification)
    
  end
  
  ----------------------------------------------------------------------------------------------------------------
  
  --This test case is used to verify all parameters are upper bound when integer values for next params of float type are sent:
  -- speed
  -- fuelLevel
  -- instantFuelConsumption
  -- externalTemperature
  -- engineTorque
  -- accPedalPosition
  -- steeringWheelAngle
  -- gps params
  -- fuelRange
  
  Test["OnVehicleData_AllParametersUpperBound_IntForFloat_SUCCESS"] = function(self)
    local Notification = 
    {
      speed = 700,
      fuelLevel = 106,
      instantFuelConsumption = 25575,
      externalTemperature = 100,
      engineTorque = 2000,
      accPedalPosition = 100,
      steeringWheelAngle = 2000,
      
      rpm = 20000,
      odometer = 17000000,
      
      vin = "aaaaaaaaaaaaaaaaa",
      
      prndl = "PARK",
      fuelLevel_State = "UNKNOWN",
      driverBraking = "NO_EVENT",
      wiperStatus = "OFF",
      
      headLampStatus = {	 lowBeamsOn = false, 
        highBeamsOn = false, 
        ambientLightSensorStatus = "NIGHT"
      },
      myKey = 		{	 e911Override = "NO_DATA_EXISTS"},
      deviceStatus = 	{	 voiceRecOn = true,
        btIconOn = true,
        callActive = true,
        phoneRoaming = true,
        textMsgAvailable = true,
        stereoAudioOutputMuted = true,
        monoAudioOutputMuted = true,
        eCallEventActive = true,
        primaryAudioSource = "USB",
        battLevelStatus = "ZERO_LEVEL_BARS",
        signalLevelStatus = "ZERO_LEVEL_BARS"
      },
      eCallInfo = 	{	 eCallNotificationStatus = "NOT_SUPPORTED",
        auxECallNotificationStatus = "NOT_SUPPORTED",
        eCallConfirmationStatus = "NORMAL"
      },
      emergencyEvent ={	 emergencyEventType = "NO_EVENT",
        fuelCutoffStatus = "TERMINATE_FUEL",
        rolloverEvent = "NO_EVENT",
        maximumChangeVelocity = 255,
        multipleEvents = "NO_EVENT"
      },
      bodyInformation={	 parkBrakeActive = true, 
        driverDoorAjar = true,
        passengerDoorAjar = true,
        rearLeftDoorAjar = true,
        rearRightDoorAjar = true,
        ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
        ignitionStatus = "UNKNOWN"
      },
      clusterModeStatus={	 powerModeActive = true, 
        powerModeQualificationStatus = "POWER_MODE_UNDEFINED",
        carModeStatus = "NORMAL",
        powerModeStatus = "KEY_OUT"
      },
      beltStatus = 	{	 driverBeltDeployed = "NO_EVENT",
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
        middleRow1BuckleBelted = "NO_EVENT"
      },
      airbagStatus = {	 driverAirbagDeployed = "YES",
        driverSideAirbagDeployed = "YES",
        driverCurtainAirbagDeployed = "YES",
        passengerAirbagDeployed = "YES",
        passengerCurtainAirbagDeployed = "YES",			
        driverKneeAirbagDeployed = "YES",
        passengerSideAirbagDeployed = "YES",
        passengerKneeAirbagDeployed = "YES"
      },
      gps = 			{	 longitudeDegrees = 180,
        latitudeDegrees = 90,
        pdop = 10,
        hdop = 10,
        vdop = 10,
        altitude = 10000.0,
        heading = 400,
        speed = 500,
        
        utcYear = 2100,
        utcMonth = 12,
        utcDay = 31,
        utcHours = 23,
        utcMinutes = 59,
        utcSeconds = 59,
        satellites = 31,
        
        compassDirection = "NORTH",
        dimension = "NO_FIX",
        actual = true
      },
      tirePressure = 	{	 pressureTelltale = "OFF",
        leftFront = {status = "UNKNOWN"},
        rightFront = {status = "UNKNOWN"},
        leftRear = {status = "UNKNOWN"},
        rightRear = {status = "UNKNOWN"},
        innerLeftRear = {status = "UNKNOWN"},
        innerRightRear = {status = "UNKNOWN"}
      },
      fuelRange = 10000,
      abs_State = "ACTIVE",
      tirePressureValue = {
        leftFront = 65533,
        rightFront = 65533,
        leftRear = 65533,
        rightRear = 65533,
        innerLeftRear = 65533,
        innerRightRear = 65533,
        frontRecommended = 65533,
        rearRecommended = 65533
      },
      tpms = "SENSOR_FAULT",
      turnSignal = "OFF"
    }
    
    local ExpectNotification = 
    {
      speed = 700,
      fuelLevel = 106,
      instantFuelConsumption = 25575,
      externalTemperature = 100,
      engineTorque = 2000,
      accPedalPosition = 100,
      steeringWheelAngle = 2000,
      
      rpm = 20000,
      odometer = 17000000,
      
      --vin = "aaaaaaaaaaaaaaaaa",
      
      prndl = "PARK",
      fuelLevel_State = "UNKNOWN",
      driverBraking = "NO_EVENT",
      wiperStatus = "OFF",
      
      headLampStatus = {	 lowBeamsOn = false, 
        highBeamsOn = false, 
        ambientLightSensorStatus = "NIGHT"
      },
      myKey = 		{	 e911Override = "NO_DATA_EXISTS"},
      deviceStatus = 	{	 voiceRecOn = true,
        btIconOn = true,
        callActive = true,
        phoneRoaming = true,
        textMsgAvailable = true,
        stereoAudioOutputMuted = true,
        monoAudioOutputMuted = true,
        eCallEventActive = true,
        primaryAudioSource = "USB",
        battLevelStatus = "ZERO_LEVEL_BARS",
        signalLevelStatus = "ZERO_LEVEL_BARS"
      },
      eCallInfo = 	{	 eCallNotificationStatus = "NOT_SUPPORTED",
        auxECallNotificationStatus = "NOT_SUPPORTED",
        eCallConfirmationStatus = "NORMAL"
      },
      emergencyEvent ={	 emergencyEventType = "NO_EVENT",
        fuelCutoffStatus = "TERMINATE_FUEL",
        rolloverEvent = "NO_EVENT",
        maximumChangeVelocity = 255,
        multipleEvents = "NO_EVENT"
      },
      bodyInformation={	 parkBrakeActive = true, 
        driverDoorAjar = true,
        passengerDoorAjar = true,
        rearLeftDoorAjar = true,
        rearRightDoorAjar = true,
        ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
        ignitionStatus = "UNKNOWN"
      },
      clusterModeStatus={	 powerModeActive = true, 
        powerModeQualificationStatus = "POWER_MODE_UNDEFINED",
        carModeStatus = "NORMAL",
        powerModeStatus = "KEY_OUT"
      },
      beltStatus = 	{	 driverBeltDeployed = "NO_EVENT",
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
        middleRow1BuckleBelted = "NO_EVENT"
      },
      airbagStatus = {	 driverAirbagDeployed = "YES",
        driverSideAirbagDeployed = "YES",
        driverCurtainAirbagDeployed = "YES",
        passengerAirbagDeployed = "YES",
        passengerCurtainAirbagDeployed = "YES",			
        driverKneeAirbagDeployed = "YES",
        passengerSideAirbagDeployed = "YES",
        passengerKneeAirbagDeployed = "YES"
      },
      gps = 			{	 longitudeDegrees = 180,
        latitudeDegrees = 90,
        pdop = 10,
        hdop = 10,
        vdop = 10,
        altitude = 10000.0,
        heading = 400,
        speed = 500,
        
        utcYear = 2100,
        utcMonth = 12,
        utcDay = 31,
        utcHours = 23,
        utcMinutes = 59,
        utcSeconds = 59,
        satellites = 31,
        
        compassDirection = "NORTH",
        dimension = "NO_FIX",
        actual = true
      },
      tirePressure = 	{	 pressureTelltale = "OFF",
        leftFront = {status = "UNKNOWN"},
        rightFront = {status = "UNKNOWN"},
        leftRear = {status = "UNKNOWN"},
        rightRear = {status = "UNKNOWN"},
        innerLeftRear = {status = "UNKNOWN"},
        innerRightRear = {status = "UNKNOWN"}
      },
      fuelRange = 10000,
      abs_State = "ACTIVE",
      tirePressureValue = {
        leftFront = 65533,
        rightFront = 65533,
        leftRear = 65533,
        rightRear = 65533,
        innerLeftRear = 65533,
        innerRightRear = 65533,
        frontRecommended = 65533,
        rearRecommended = 65533
      },
      tpms = "SENSOR_FAULT",
      turnSignal = "OFF"
    }
    
    self:verify_SUCCESS_Notification_Case(Notification, ExpectNotification)
    
  end
  
  --------------------------------------------------------------------------------------------------------------------
  
  Test["OnVehicleData_OnlyMandatoryParameters_SUCCESS"] = function(self)
    
    local Notification = 
    {
      bodyInformation={	 parkBrakeActive = true, 
        ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
        ignitionStatus = "UNKNOWN"
      },	
      headLampStatus = {	 lowBeamsOn = false, 
        highBeamsOn = false, 
        ambientLightSensorStatus = "NIGHT"
      },
      myKey = 		{	 e911Override = "NO_DATA_EXISTS"},
      eCallInfo = 	{	 eCallNotificationStatus = "NOT_SUPPORTED",
        auxECallNotificationStatus = "NOT_SUPPORTED",
        eCallConfirmationStatus = "NORMAL"
      },
      clusterModeStatus={	 powerModeActive = true, 
        powerModeQualificationStatus = "POWER_MODE_UNDEFINED",
        carModeStatus = "NORMAL",
        powerModeStatus = "KEY_OUT"
      },
      airbagStatus = {	 driverAirbagDeployed = "YES",
        driverSideAirbagDeployed = "YES",
        driverCurtainAirbagDeployed = "YES",
        passengerAirbagDeployed = "YES",
        passengerCurtainAirbagDeployed = "YES",			
        driverKneeAirbagDeployed = "YES",
        passengerSideAirbagDeployed = "YES",
        passengerKneeAirbagDeployed = "YES"
      },
        tirePressure = 	{	 leftFront = {status = "UNKNOWN"},
        rightFront = {status = "UNKNOWN"},
        leftRear = {status = "UNKNOWN"},
        rightRear = {status = "UNKNOWN"},
        innerLeftRear = {status = "UNKNOWN"},
        innerRightRear = {status = "UNKNOWN"}
      }
    }
    
    self:verify_SUCCESS_Notification_Case(Notification)
    
    
  end
  -----------------------------------------------------------------------------------------
  
  Test["OnVehicleData_OnlyMandatoryParameters_SUCCESS_bodyInformation"] = function(self)
    
    local Notification = 
    {
      bodyInformation={	 parkBrakeActive = true, 
        ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
        ignitionStatus = "UNKNOWN"
      }
    }
    
    self:verify_SUCCESS_Notification_Case(Notification)
  end
  -----------------------------------------------------------------------------------------
  
  Test["OnVehicleData_OnlyMandatoryParameters_SUCCESS_headLampStatus"] = function(self)
    
    local Notification = 
    {
      headLampStatus = {	 lowBeamsOn = false, 
        highBeamsOn = false, 
        ambientLightSensorStatus = "NIGHT"
      }
    }
    
    self:verify_SUCCESS_Notification_Case(Notification)
  end
  -----------------------------------------------------------------------------------------
  
  Test["OnVehicleData_OnlyMandatoryParameters_SUCCESS_myKey"] = function(self)
    
    local Notification = 
    {
      myKey = 		{	e911Override = "NO_DATA_EXISTS"}
    }
    
    self:verify_SUCCESS_Notification_Case(Notification)
  end
  -----------------------------------------------------------------------------------------
  
  Test["OnVehicleData_OnlyMandatoryParameters_SUCCESS_eCallInfo"] = function(self)
    
    local Notification = 
    {
      eCallInfo = 	{	 eCallNotificationStatus = "NOT_SUPPORTED",
        auxECallNotificationStatus = "NOT_SUPPORTED",
        eCallConfirmationStatus = "NORMAL"
      }
    }
    
    self:verify_SUCCESS_Notification_Case(Notification)
  end
  -----------------------------------------------------------------------------------------
  
  Test["OnVehicleData_OnlyMandatoryParameters_SUCCESS_clusterModeStatus"] = function(self)
    
    local Notification = 
    {
      clusterModeStatus={	 powerModeActive = true, 
        powerModeQualificationStatus = "POWER_MODE_UNDEFINED",
        carModeStatus = "NORMAL",
        powerModeStatus = "KEY_OUT"
      }
    }
    
    self:verify_SUCCESS_Notification_Case(Notification)
  end
  -----------------------------------------------------------------------------------------
  
  Test["OnVehicleData_OnlyMandatoryParameters_SUCCESS_airbagStatus"] = function(self)
    
    local Notification = 
    {
      airbagStatus = {	 driverAirbagDeployed = "YES",
        driverSideAirbagDeployed = "YES",
        driverCurtainAirbagDeployed = "YES",
        passengerAirbagDeployed = "YES",
        passengerCurtainAirbagDeployed = "YES",			
        driverKneeAirbagDeployed = "YES",
        passengerSideAirbagDeployed = "YES",
        passengerKneeAirbagDeployed = "YES"
      }
    }
    
    self:verify_SUCCESS_Notification_Case(Notification)
  end
  -----------------------------------------------------------------------------------------
  
  Test["OnVehicleData_OnlyMandatoryParameters_SUCCESS_tirePressure"] = function(self)
    
    local Notification = 
    { 
        tirePressure = 	{	 leftFront = {status = "UNKNOWN"},
        rightFront = {status = "UNKNOWN"},
        leftRear = {status = "UNKNOWN"},
        rightRear = {status = "UNKNOWN"},
        innerLeftRear = {status = "UNKNOWN"},
        innerRightRear = {status = "UNKNOWN"}
      }
    }
    
    self:verify_SUCCESS_Notification_Case(Notification)
  end
  -----------------------------------------------------------------------------------------
  
  --OnVehicleData_OnlyMandatoryParameters_SUCCESS_tirePressure: sub-parameters
    local TestData = 	{	 leftFront = {status = "UNKNOWN"},
    rightFront = {status = "UNKNOWN"},
    leftRear = {status = "UNKNOWN"},
    rightRear = {status = "UNKNOWN"},
    innerLeftRear = {status = "UNKNOWN"},
    innerRightRear = {status = "UNKNOWN"}
  }
  for ParameterName,value in pairs(TestData) do
    Test["OnVehicleData_OnlyMandatoryParameters_SUCCESS_tirePressure_" .. tostring(ParameterName)] = function(self)
      
      local tirePressure_value = {}
      tirePressure_value[ParameterName] = value
      
      local Notification = {tirePressure = tirePressure_value}
      
      self:verify_SUCCESS_Notification_Case(Notification)
    end
  end
  
  -----------------------------------------------------------------------------------------
end
common_Test_Cases_For_Notification()


--1.speed: type=Float minvalue=0 maxvalue=700 mandatory=false
--2.fuelLevel: type=Float minvalue=-6 maxvalue=106 mandatory=false
--3.instantFuelConsumption: type=Float minvalue=0 maxvalue=25575 mandatory=false
--4.externalTemperature: type=Float minvalue=-40 maxvalue=100 mandatory=false
--5.engineTorque: type=Float minvalue=-1000 maxvalue=2000 mandatory=false
--6.accPedalPosition: type=Float minvalue=0 maxvalue=100 mandatory=false
--7.steeringWheelAngle: type=Float minvalue=-2000 maxvalue=2000 mandatory=false	

local Notification = {rpm = 1}		
floatParameterInNotification:verify_Float_Parameter(Notification, {"speed"}, {0.000000, 700.000000}, false)
floatParameterInNotification:verify_Float_Parameter(Notification, {"fuelLevel"}, {-6.000000, 106.000000}, false)
floatParameterInNotification:verify_Float_Parameter(Notification, {"instantFuelConsumption"}, {0.000000, 25575.000000}, false)
floatParameterInNotification:verify_Float_Parameter(Notification, {"externalTemperature"}, {-40.000000, 100.000000}, false)
floatParameterInNotification:verify_Float_Parameter(Notification, {"engineTorque"}, {-1000.000000, 2000.000000}, false)
floatParameterInNotification:verify_Float_Parameter(Notification, {"accPedalPosition"}, {0.000000, 100.000000}, false)
floatParameterInNotification:verify_Float_Parameter(Notification, {"steeringWheelAngle"}, {-2000.000000, 2000.000000}, false)
----------------------------------------------------------------------------------------------

--8.rpm: type=Integer minvalue=0 maxvalue=20000 mandatory=false
--9.odometer: type=Integer minvalue=0 maxvalue=17000000 mandatory=false
local Notification = {speed = 1}
integerParameterInNotification:verify_Integer_Parameter(Notification, {"rpm"}, {0, 20000}, false)
integerParameterInNotification:verify_Integer_Parameter(Notification, {"odometer"}, {0, 17000000}, false)
----------------------------------------------------------------------------------------------

--10.vin: type=String maxlength=17 mandatory=false
-- vin in Notification from HMI will be ignored by SDL according to APPLINK-26880
--local Notification = {rpm = 1}		
--stringParameterInNotification:verify_String_Parameter(Notification, {"vin"}, {1, 17}, false, true)
----------------------------------------------------------------------------------------------

--11.prndl: type=Common.PRNDL mandatory=false
--12.fuelLevel_State: type=Common.ComponentVolumeStatus mandatory=false
--13.driverBraking: type=Common.VehicleDataEventStatus mandatory=false
--14.wiperStatus: type=Common.WiperStatus mandatory=false
--Enumerations:
local PRNDL = {"PARK", "REVERSE", "NEUTRAL", "DRIVE", "SPORT", "LOWGEAR", "FIRST", "SECOND", "THIRD", "FOURTH", "FIFTH", "SIXTH", "SEVENTH", "EIGHTH", "FAULT"}
local ComponentVolumeStatus = {"UNKNOWN", "NORMAL", "LOW", "FAULT", "ALERT", "NOT_SUPPORTED"}
local VehicleDataEventStatus = {"NO_EVENT", "NO", "YES", "NOT_SUPPORTED", "FAULT"}	
local WiperStatus = {"OFF","AUTO_OFF","OFF_MOVING","MAN_INT_OFF","MAN_INT_ON","MAN_LOW","MAN_HIGH", "MAN_FLICK","WASH","AUTO_LOW","AUTO_HIGH","COURTESYWIPE","AUTO_ADJUST","STALLED","NO_DATA_EXISTS"}

local Notification = {rpm = 1}
enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"prndl"}, PRNDL, false)
enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"fuelLevel_State"}, ComponentVolumeStatus, false)
enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"driverBraking"}, VehicleDataEventStatus, false)
enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"wiperStatus"}, WiperStatus, false)
----------------------------------------------------------------------------------------------

--15.headLampStatus: type=Common.HeadLampStatus mandatory=false
--16.myKey: type=Common.MyKey mandatory=false	
--17.deviceStatus: type=Common.DeviceStatus mandatory=false
--18.eCallInfo: type=Common.ECallInfo mandatory=false
--18.emergencyEvent: type=Common.EmergencyEvent mandatory=false
--20.bodyInformation: type=Common.BodyInformation mandatory=false	
--21.clusterModeStatus: type=Common.ClusterModeStatus mandatory=false

local function verify_headLampStatus_parameter()
  --[[headLampStatus: type=Common.HeadLampStatus mandatory=false
  --name="lowBeamsOn" type="Boolean" mandatory="true"
  --name="highBeamsOn" type="Boolean" mandatory="true"
  --name="ambientLightSensorStatus" type="Common.AmbientLightStatus" mandatory="true"]]
  
  --Enumerations:
  local AmbientLightStatus = {"NIGHT", "TWILIGHT_1", "TWILIGHT_2", "TWILIGHT_3", "TWILIGHT_4", "DAY", "UNKNOWN", "INVALID"}
  
  
  local Notification = {instantFuelConsumption = 0, headLampStatus = {}}
  
  --1. IsMissed
  commonFunctions:TestCaseForNotification(self, Notification, {"headLampStatus"}, "IsMissed", nil, true)
  
  --2. IsWrongDataType
  commonFunctions:TestCaseForNotification(self, Notification, {"headLampStatus"}, "IsWrongDataType", 123, false)
  
  local Notification = {rpm = 1, headLampStatus = {lowBeamsOn = false, highBeamsOn = false, ambientLightSensorStatus = AmbientLightStatus[1]}}
  
  --3. TCs for parameter: lowBeamsOn, highBeamsOn
  booleanParameterInNotification:verify_Boolean_Parameter(Notification, {"headLampStatus", "lowBeamsOn"}, true)
  booleanParameterInNotification:verify_Boolean_Parameter(Notification, {"headLampStatus", "highBeamsOn"}, true)
  
  --4. TCs for parameter: ambientLightSensorStatus
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"headLampStatus", "ambientLightSensorStatus"}, AmbientLightStatus, true)	
end
verify_headLampStatus_parameter()

local function verify_myKey_parameter()
  
  --Print new line to separate new test cases group
  commonFunctions:newTestCasesGroup("Test suite For Parameter: myKey")
  
  -- myKey: type=Common.MyKey mandatory=false
  local Notification = {rpm = 1, myKey = {}}
  
  --1. IsMissed: valid notification
  commonFunctions:TestCaseForNotification(self, Notification, {"myKey"}, "IsMissed", nil, true)
  
  --2. IsWrongDataType
  commonFunctions:TestCaseForNotification(self, Notification, {"myKey"}, "IsWrongDataType", 123, false)
  
  -- myKey.e911Override: type=Common.VehicleDataStatus mandatory=true
  local Common_VehicleDataStatus = {"NO_DATA_EXISTS", "OFF", "ON"}	
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"myKey", "e911Override"}, Common_VehicleDataStatus, true)
end	
verify_myKey_parameter()

local function verify_deviceStatus_parameter()
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
  commonFunctions:newTestCasesGroup("Test suite For Parameter: deviceStatus")
  
  local Notification = {speed = 0.0, deviceStatus = {}}
  
  --1. IsMissed
  commonFunctions:TestCaseForNotification(self, Notification, {"deviceStatus"}, "IsMissed", nil, true)
  
  --2. IsEmptyTable
  commonFunctions:TestCaseForNotification(self, Notification, {"deviceStatus"}, "IsEmptyTable", {}, true)
  
  --3. IsWrongDataType
  commonFunctions:TestCaseForNotification(self, Notification, {"deviceStatus"}, "IsWrongDataType", 123, false)
  
  --4. TCs for parameter: voiceRecOn														
  local Notification = {rpm = 1, deviceStatus = { signalLevelStatus = "NOT_PROVIDED" }}
  booleanParameterInNotification:verify_Boolean_Parameter(Notification, {"deviceStatus", "voiceRecOn"}, false)
  
  --5. TCs for parameter: btIconOn, callActive, phoneRoaming, textMsgAvailable, stereoAudioOutputMuted, monoAudioOutputMuted, eCallEventActive
  local Notification = {rpm = 1, deviceStatus = { voiceRecOn = false }}
  booleanParameterInNotification:verify_Boolean_Parameter(Notification, {"deviceStatus", "btIconOn"}, false)
  local Notification = {rpm = 1, deviceStatus = { btIconOn = false }}			
  booleanParameterInNotification:verify_Boolean_Parameter(Notification, {"deviceStatus", "callActive"}, false)
  local Notification = {rpm = 1, deviceStatus = { callActive = false }}			
  booleanParameterInNotification:verify_Boolean_Parameter(Notification, {"deviceStatus", "phoneRoaming"}, false)
  local Notification = {rpm = 1, deviceStatus = { phoneRoaming = false }}			
  booleanParameterInNotification:verify_Boolean_Parameter(Notification, {"deviceStatus", "textMsgAvailable"}, false)
  local Notification = {rpm = 1, deviceStatus = { textMsgAvailable = false }}			
  booleanParameterInNotification:verify_Boolean_Parameter(Notification, {"deviceStatus", "stereoAudioOutputMuted"}, false)
  local Notification = {rpm = 1, deviceStatus = { stereoAudioOutputMuted = false }}			
  booleanParameterInNotification:verify_Boolean_Parameter(Notification, {"deviceStatus", "monoAudioOutputMuted"}, false)
  local Notification = {rpm = 1, deviceStatus = { monoAudioOutputMuted = false }}			
  booleanParameterInNotification:verify_Boolean_Parameter(Notification, {"deviceStatus", "eCallEventActive"}, false)
  
  --6. TCs for parameter: primaryAudioSource
  local PrimaryAudioSource = {"NO_SOURCE_SELECTED", "USB", "USB2", "BLUETOOTH_STEREO_BTST", "LINE_IN", "IPOD", "MOBILE_APP"}
  local Notification = {rpm = 1, deviceStatus = { eCallEventActive = false }}		
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"deviceStatus", "primaryAudioSource"}, PrimaryAudioSource, false)
  
  --7. TCs for parameter: battLevelStatus, signalLevelStatus
  local DeviceLevelStatus = {"ZERO_LEVEL_BARS", "ONE_LEVEL_BARS", "TWO_LEVEL_BARS", "THREE_LEVEL_BARS", "FOUR_LEVEL_BARS", "NOT_PROVIDED"}
  local Notification = {rpm = 1, deviceStatus = { primaryAudioSource = "USB" }}
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"deviceStatus", "battLevelStatus"}, DeviceLevelStatus, false)
  local Notification = {rpm = 1, deviceStatus = { battLevelStatus = "NOT_PROVIDED" }}
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"deviceStatus", "signalLevelStatus"}, DeviceLevelStatus, false)
  
end
verify_deviceStatus_parameter()


local function verify_eCallInfo_parameter()
  --[[eCallInfo: type=Common.ECallInfo mandatory=false
  --name="eCallNotificationStatus" type="Common.VehicleDataNotificationStatus"
  --name="auxECallNotificationStatus" type="Common.VehicleDataNotificationStatus"
  --name="eCallConfirmationStatus" type="Common.ECallConfirmationStatus"]]
  
  --Print new line to separate new test cases group
  commonFunctions:newTestCasesGroup("Test suite For Parameter: eCallInfo")
  
  --Enumerations:
  local VehicleDataNotificationStatus = {"NOT_SUPPORTED", "NORMAL", "ACTIVE", "NOT_USED"}
  local ECallConfirmationStatus = {"NORMAL", "CALL_IN_PROGRESS", "CALL_CANCELLED", "CALL_COMPLETED", "CALL_UNSUCCESSFUL", "ECALL_CONFIGURED_OFF", "CALL_COMPLETE_DTMF_TIMEOUT"}
  
    local Notification = {fuelLevel = -6, eCallInfo = 	{	eCallNotificationStatus = VehicleDataNotificationStatus[1],
      auxECallNotificationStatus = VehicleDataNotificationStatus[1],
  eCallConfirmationStatus = ECallConfirmationStatus[1]}}
  
  --1. IsMissed
  commonFunctions:TestCaseForNotification(self, Notification, {"eCallInfo"}, "IsMissed", nil, true)
  
  --2. IsWrongDataType
  commonFunctions:TestCaseForNotification(self, Notification, {"eCallInfo"}, "IsWrongDataType", 123, false)
  
  --3. TCs for parameter: eCallNotificationStatus, auxECallNotificationStatus, eCallConfirmationStatus
  --local Notification = {rpm = 1, eCallInfo = {auxECallNotificationStatus = VehicleDataNotificationStatus[1]}}
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"eCallInfo", "eCallNotificationStatus"}, VehicleDataNotificationStatus, true)
  
  --local Notification = {rpm = 1, eCallInfo = {eCallNotificationStatus = VehicleDataNotificationStatus[1]}}
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"eCallInfo", "auxECallNotificationStatus"}, VehicleDataNotificationStatus, true)
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"eCallInfo", "eCallConfirmationStatus"}, ECallConfirmationStatus, true)	
end
verify_eCallInfo_parameter()

local function verify_emergencyEvent_parameter()
  --[[emergencyEvent: type=Common.EmergencyEvent mandatory=false
  --name="emergencyEventType" type="Common.EmergencyEventType"
  --name="fuelCutoffStatus" type="Common.FuelCutoffStatus"
  --name="rolloverEvent" type="Common.VehicleDataEventStatus"
  --name="maximumChangeVelocity" type="Common.VehicleDataEventStatus" --APPLINK-15385: maximumChangeVelocity, type="Integer" minvalue="0" maxvalue="255"
  --name="multipleEvents" type="Common.VehicleDataEventStatus"]]
  
  --Print new line to separate new test cases group
  commonFunctions:newTestCasesGroup("Test suite For Parameter: emergencyEvent")
  
  local EmergencyEventType = {"NO_EVENT", "FRONTAL", "SIDE", "REAR", "ROLLOVER", "NOT_SUPPORTED", "FAULT"}
  local FuelCutoffStatus = {"TERMINATE_FUEL", "NORMAL_OPERATION", "FAULT"}
  
    local Notification = {rpm = 1, emergencyEvent = 	{	emergencyEventType = EmergencyEventType[1],
      fuelCutoffStatus = FuelCutoffStatus[1],
      rolloverEvent = VehicleDataEventStatus[1],
      maximumChangeVelocity = 0,
  multipleEvents = VehicleDataEventStatus[1]}}
  
  --1. IsMissed
  commonFunctions:TestCaseForNotification(self, Notification, {"emergencyEvent"}, "IsMissed", nil, true)
  
  --2. IsWrongDataType
  commonFunctions:TestCaseForNotification(self, Notification, {"emergencyEvent"}, "IsWrongDataType", 123, false)
  
  --3. TCs for parameter: emergencyEventType, fuelCutoffStatus, rolloverEvent, maximumChangeVelocity, multipleEvents
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"emergencyEvent", "emergencyEventType"}, EmergencyEventType, true)
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"emergencyEvent", "fuelCutoffStatus"}, FuelCutoffStatus, true)
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"emergencyEvent", "rolloverEvent"}, VehicleDataEventStatus, true)
  integerParameterInNotification:verify_Integer_Parameter(Notification, {"emergencyEvent", "maximumChangeVelocity"}, {0, 255}, true) --defect APPLINK-11178
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"emergencyEvent", "multipleEvents"}, VehicleDataEventStatus, true)
end
verify_emergencyEvent_parameter()	

local function verify_bodyInformation_parameter()
  --[[bodyInformation: type=Common.BodyInformation mandatory=false
  --name="parkBrakeActive" type="Boolean" mandatory="true"
  --name="driverDoorAjar" type="Boolean" mandatory="false"
  --name="passengerDoorAjar" type="Boolean" mandatory="false"
  --name="rearLeftDoorAjar" type="Boolean" mandatory="false"
  --name="rearRightDoorAjar" type="Boolean" mandatory="false"
  --name="ignitionStableStatus" type="Common.IgnitionStableStatus" mandatory="true"
  --name="ignitionStatus" type="Common.IgnitionStatus" mandatory="true"]]
  
  --Print new line to separate new test cases group
  commonFunctions:newTestCasesGroup("Test suite For Parameter: bodyInformation")
  
  --Enumerations:
  local IgnitionStableStatus = {"IGNITION_SWITCH_NOT_STABLE", "IGNITION_SWITCH_STABLE", "MISSING_FROM_TRANSMITTER"}
  local IgnitionStatus = {"UNKNOWN", "OFF", "ACCESSORY", "RUN", "START", "INVALID"}
  
  
  local Notification = {rpm = 1, bodyInformation = {}}
  
  --1. IsMissed
  commonFunctions:TestCaseForNotification(self, Notification, {"bodyInformation"}, "IsMissed", nil, true)
  
  --2. IsWrongDataType
  commonFunctions:TestCaseForNotification(self, Notification, {"bodyInformation"}, "IsWrongDataType", 123, false)
  
  
  local Notification = 	{	rpm = 1, 
    bodyInformation = 	{	parkBrakeActive = true, 
      ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
  ignitionStatus = "UNKNOWN"}}
  
  --3. TCs for parameter: parkBrakeActive														
  booleanParameterInNotification:verify_Boolean_Parameter(Notification, {"bodyInformation", "parkBrakeActive"}, true)
  
  --4. TCs for parameters: driverDoorAjar, passengerDoorAjar, rearLeftDoorAjar, rearRightDoorAjar
  booleanParameterInNotification:verify_Boolean_Parameter(Notification, {"bodyInformation", "driverDoorAjar"}, false)
  booleanParameterInNotification:verify_Boolean_Parameter(Notification, {"bodyInformation", "passengerDoorAjar"}, false)
  booleanParameterInNotification:verify_Boolean_Parameter(Notification, {"bodyInformation", "rearLeftDoorAjar"}, false)
  booleanParameterInNotification:verify_Boolean_Parameter(Notification, {"bodyInformation", "rearRightDoorAjar"}, false)
  
  --5. TCs for parameter: ignitionStableStatus, ignitionStatus
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"bodyInformation", "ignitionStableStatus"}, IgnitionStableStatus, true)
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"bodyInformation", "ignitionStatus"}, IgnitionStatus, true)
  
end
verify_bodyInformation_parameter()	

local function verify_clusterModeStatus_parameter()
  --[[clusterModeStatus: type=Common.ClusterModeStatus mandatory=false
  --name="powerModeActive" type="Boolean"
  --name="powerModeQualificationStatus" type="Common.PowerModeQualificationStatus"
  --name="carModeStatus" type="Common.CarModeStatus"
  --name="powerModeStatus" type="Common.PowerModeStatus"]]
  
  --Enumerations:
  local PowerModeQualificationStatus = {"POWER_MODE_UNDEFINED", "POWER_MODE_EVALUATION_IN_PROGRESS", "NOT_DEFINED", "POWER_MODE_OK"}
  local CarModeStatus = {"NORMAL", "FACTORY", "TRANSPORT", "CRASH"}
  local PowerModeStatus = {"KEY_OUT", "KEY_RECENTLY_OUT", "KEY_APPROVED_0", "POST_ACCESORY_0", "ACCESORY_1", "POST_IGNITION_1", "IGNITION_ON_2", "RUNNING_2", "CRANK_3"}
  
    local Notification = {rpm = 1, clusterModeStatus = {	powerModeActive = true, 
      powerModeQualificationStatus = PowerModeQualificationStatus[1],
      carModeStatus = CarModeStatus[1],
  powerModeStatus = PowerModeStatus[1]}}
  
  --1. IsMissed
  commonFunctions:TestCaseForNotification(self, Notification, {"clusterModeStatus"}, "IsMissed", nil, true)
  
  --2. IsWrongDataType
  commonFunctions:TestCaseForNotification(self, Notification, {"clusterModeStatus"}, "IsWrongDataType", 123, false)
  
  --3. TCs for parameter: powerModeActive
  booleanParameterInNotification:verify_Boolean_Parameter(Notification, {"clusterModeStatus", "powerModeActive"}, true)
  
  --4. TCs for parameter: powerModeQualificationStatus, carModeStatus, powerModeStatus
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"clusterModeStatus", "powerModeQualificationStatus"}, PowerModeQualificationStatus, true)
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"clusterModeStatus", "carModeStatus"}, CarModeStatus, true)
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"clusterModeStatus", "powerModeStatus"}, PowerModeStatus, true)
  
end
verify_clusterModeStatus_parameter()
----------------------------------------------------------------------------------------------


--22.beltStatus: type=Common.BeltStatus mandatory=false
--23.airbagStatus: type=Common.AirbagStatus mandatory=false
--24.gps: type=Common.GPSData mandatory=false
--25.tirePressure: type=Common.TireStatus mandatory=false

local function verify_beltStatus_parameter()
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
  commonFunctions:newTestCasesGroup("Test suite For Verifying: beltStatus structure")	
  local Notification = {rpm = 1, beltStatus = {}}
  
  --1. IsMissed
  commonFunctions:TestCaseForNotification(self, Notification, {"beltStatus"}, "IsMissed", nil, true)
  
  --2. IsEmptyTable
  commonFunctions:TestCaseForNotification(self, Notification, {"beltStatus"}, "IsEmptyTable", {}, true)
  
  --3. IsWrongDataType
  commonFunctions:TestCaseForNotification(self, Notification, {"beltStatus"}, "IsWrongDataType", 123, false)
  
  --4. TCs for parameters
  local Notification = {rpm = 1, beltStatus = {passengerBeltDeployed = "NO_EVENT"}}
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"beltStatus", "driverBeltDeployed"}, VehicleDataEventStatus, false)
  local Notification = {rpm = 1, beltStatus = {passengerBuckleBelted = "NO_EVENT"}}
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"beltStatus", "passengerBeltDeployed"}, VehicleDataEventStatus, false)
  local Notification = {rpm = 1, beltStatus = {driverBuckleBelted = "NO_EVENT"}}
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"beltStatus", "passengerBuckleBelted"}, VehicleDataEventStatus, false)
  local Notification = {rpm = 1, beltStatus = {leftRow2BuckleBelted = "NO_EVENT"}}
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"beltStatus", "driverBuckleBelted"}, VehicleDataEventStatus, false)
  local Notification = {rpm = 1, beltStatus = {passengerChildDetected = "NO_EVENT"}}
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"beltStatus", "leftRow2BuckleBelted"}, VehicleDataEventStatus, false)
  local Notification = {rpm = 1, beltStatus = {rightRow2BuckleBelted = "NO_EVENT"}}
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"beltStatus", "passengerChildDetected"}, VehicleDataEventStatus, false)
  local Notification = {rpm = 1, beltStatus = {middleRow2BuckleBelted = "NO_EVENT"}}
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"beltStatus", "rightRow2BuckleBelted"}, VehicleDataEventStatus, false)
  local Notification = {rpm = 1, beltStatus = {middleRow3BuckleBelted = "NO_EVENT"}}
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"beltStatus", "middleRow2BuckleBelted"}, VehicleDataEventStatus, false)
  local Notification = {rpm = 1, beltStatus = {leftRow3BuckleBelted = "NO_EVENT"}}
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"beltStatus", "middleRow3BuckleBelted"}, VehicleDataEventStatus, false)
  local Notification = {rpm = 1, beltStatus = {rightRow3BuckleBelted = "NO_EVENT"}}
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"beltStatus", "leftRow3BuckleBelted"}, VehicleDataEventStatus, false)	
  local Notification = {rpm = 1, beltStatus = {leftRearInflatableBelted = "NO_EVENT"}}
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"beltStatus", "rightRow3BuckleBelted"}, VehicleDataEventStatus, false)
  local Notification = {rpm = 1, beltStatus = {rightRearInflatableBelted = "NO_EVENT"}}
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"beltStatus", "leftRearInflatableBelted"}, VehicleDataEventStatus, false)
  local Notification = {rpm = 1, beltStatus = {middleRow1BeltDeployed = "NO_EVENT"}}
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"beltStatus", "rightRearInflatableBelted"}, VehicleDataEventStatus, false)
  local Notification = {rpm = 1, beltStatus = {middleRow1BuckleBelted = "NO_EVENT"}}
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"beltStatus", "middleRow1BeltDeployed"}, VehicleDataEventStatus, false)
  local Notification = {rpm = 1, beltStatus = {driverBeltDeployed = "NO_EVENT"}}
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"beltStatus", "middleRow1BuckleBelted"}, VehicleDataEventStatus, false)
end
verify_beltStatus_parameter()	


local function verify_airbagStatus_parameter()
  --[[airbagStatus: type=Common.AirbagStatus mandatory=false
  --name="driverAirbagDeployed" type="Common.VehicleDataEventStatus"
  --name="driverSideAirbagDeployed" type="Common.VehicleDataEventStatus"
  --name="driverCurtainAirbagDeployed" type="Common.VehicleDataEventStatus"
  --name="passengerAirbagDeployed" type="Common.VehicleDataEventStatus"
  --name="passengerCurtainAirbagDeployed" type="Common.VehicleDataEventStatus"		
  --name="driverKneeAirbagDeployed" type="Common.VehicleDataEventStatus"
  --name="passengerSideAirbagDeployed" type="Common.VehicleDataEventStatus"
  --name="passengerKneeAirbagDeployed" type="Common.VehicleDataEventStatus"]]
  
    local Notification = {rpm = 1, airbagStatus = {
      driverAirbagDeployed = "YES",
      driverSideAirbagDeployed = "YES",
      driverCurtainAirbagDeployed = "YES",
      passengerAirbagDeployed = "YES",
      passengerCurtainAirbagDeployed = "YES",			
      driverKneeAirbagDeployed = "YES",
      passengerSideAirbagDeployed = "YES",
  passengerKneeAirbagDeployed = "YES"}}
  
  --1. IsMissed
  commonFunctions:TestCaseForNotification(self, Notification, {"airbagStatus"}, "IsMissed", nil, true)
  
  --2. IsWrongDataType
  commonFunctions:TestCaseForNotification(self, Notification, {"airbagStatus"}, "IsWrongDataType", 123, false)
  
  --3. TCs for parameter: 8 parameters
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"airbagStatus", "driverAirbagDeployed"}, VehicleDataEventStatus, true)
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"airbagStatus", "driverSideAirbagDeployed"}, VehicleDataEventStatus, true)
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"airbagStatus", "driverCurtainAirbagDeployed"}, VehicleDataEventStatus, true)
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"airbagStatus", "passengerAirbagDeployed"}, VehicleDataEventStatus, true)
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"airbagStatus", "passengerCurtainAirbagDeployed"}, VehicleDataEventStatus, true)	
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"airbagStatus", "driverKneeAirbagDeployed"}, VehicleDataEventStatus, true)
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"airbagStatus", "passengerSideAirbagDeployed"}, VehicleDataEventStatus, true)
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"airbagStatus", "passengerKneeAirbagDeployed"}, VehicleDataEventStatus, true)
end
verify_airbagStatus_parameter()	

local function verify_gps_parameter()
  
  --[[gps: type=Common.GPSData mandatory=false	
  --name="longitudeDegrees" type="Float" minvalue="-180" maxvalue="180" mandatory="false", 
  --name="latitudeDegrees" type="Float" minvalue="-90" maxvalue="90" mandatory="false", 
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
  commonFunctions:newTestCasesGroup("Test suite For Verifying: gps structure")	
  local Notification = {rpm = 1, gps = {}}
  
  --1. IsMissed
  commonFunctions:TestCaseForNotification(self, Notification, {"gps"}, "IsMissed", nil, true)
  
  --2. IsEmptyTable
  commonFunctions:TestCaseForNotification(self, Notification, {"gps"}, "IsEmptyTable", {}, false)
  
  --3. IsWrongDataType
  commonFunctions:TestCaseForNotification(self, Notification, {"gps"}, "IsWrongDataType", 123, false)
  
  --4. TCs for parameters
    local Notification = {rpm = 1, gps = {longitudeDegrees = 180,
      latitudeDegrees = 90,
  actual = true}}		
  floatParameterInNotification:verify_Float_Parameter(Notification, {"gps", "longitudeDegrees"}, {-180.000000, 180.000000}, true)
  floatParameterInNotification:verify_Float_Parameter(Notification, {"gps", "latitudeDegrees"}, {-90.000000, 90.000000}, true)
  floatParameterInNotification:verify_Float_Parameter(Notification, {"gps", "pdop"}, {0.000000, 10.000000}, false)
  floatParameterInNotification:verify_Float_Parameter(Notification, {"gps", "hdop"}, {0.000000, 10.000000}, false)	
  floatParameterInNotification:verify_Float_Parameter(Notification, {"gps", "vdop"}, {0.000000, 10.000000}, false)
  floatParameterInNotification:verify_Float_Parameter(Notification, {"gps", "altitude"}, {-10000.000000, 10000.000000}, false)
  floatParameterInNotification:verify_Float_Parameter(Notification, {"gps", "heading"}, {0.000000, 359.99}, false)
  floatParameterInNotification:verify_Float_Parameter(Notification, {"gps", "speed"}, {0.000000, 500.000000}, false)	
  
  integerParameterInNotification:verify_Integer_Parameter(Notification, {"gps", "utcYear"}, {2010, 2100}, false)
  integerParameterInNotification:verify_Integer_Parameter(Notification, {"gps", "utcMonth"}, {1, 12}, false)
  integerParameterInNotification:verify_Integer_Parameter(Notification, {"gps", "utcDay"}, {1, 31}, false)	
  integerParameterInNotification:verify_Integer_Parameter(Notification, {"gps", "utcHours"}, {0, 23}, false)	
  integerParameterInNotification:verify_Integer_Parameter(Notification, {"gps", "utcMinutes"}, {0, 59}, false)
  integerParameterInNotification:verify_Integer_Parameter(Notification, {"gps", "utcSeconds"}, {0, 59}, false)
  integerParameterInNotification:verify_Integer_Parameter(Notification, {"gps", "satellites"}, {0, 31}, false)
  
  local CompassDirection = {"NORTH", "NORTHWEST", "WEST", "SOUTHWEST", "SOUTH", "SOUTHEAST", "EAST", "NORTHEAST"}	
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"gps", "compassDirection"}, CompassDirection, false)
  
  local Dimension = {"NO_FIX", "2D", "3D"}
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"gps", "dimension"}, Dimension, false)
  
    local Notification = {rpm = 1, gps = {longitudeDegrees = 180,
      latitudeDegrees = 90,
  satellites = 1}}
  booleanParameterInNotification:verify_Boolean_Parameter(Notification, {"gps", "actual"}, false)
  booleanParameterInNotification:verify_Boolean_Parameter(Notification, {"gps", "shifted"}, false)	
  
  Test["OnVehicleData_GPS_AllMandatoryParams_IsMissed"] = function(self)
    local Notification = 
    {
      speed = 1.1,
      fuelLevel = 1.1,
      instantFuelConsumption = 1.1,
      externalTemperature = 1.1,
      engineTorque = 1.1,
      accPedalPosition = 1.1,
      steeringWheelAngle = 1.1,
      
      rpm = 1,
      odometer = 1,
      
      vin = "a",
      
      prndl = "PARK",
      fuelLevel_State = "UNKNOWN",
      driverBraking = "NO_EVENT",
      wiperStatus = "OFF",
      
      headLampStatus = {	 lowBeamsOn = false, 
        highBeamsOn = false, 
        ambientLightSensorStatus = "NIGHT"
      },
      myKey = 		{	 e911Override = "NO_DATA_EXISTS"},
      deviceStatus = 	{	 voiceRecOn = true,
        btIconOn = true,
        callActive = true,
        phoneRoaming = true,
        textMsgAvailable = true,
        stereoAudioOutputMuted = true,
        monoAudioOutputMuted = true,
        eCallEventActive = true,
        primaryAudioSource = "USB",
        battLevelStatus = "ZERO_LEVEL_BARS",
        signalLevelStatus = "ZERO_LEVEL_BARS"
      },
      eCallInfo = 	{	 eCallNotificationStatus = "NOT_SUPPORTED",
        auxECallNotificationStatus = "NOT_SUPPORTED",
        eCallConfirmationStatus = "NORMAL"
      },
      emergencyEvent ={	 emergencyEventType = "NO_EVENT",
        fuelCutoffStatus = "TERMINATE_FUEL",
        rolloverEvent = "NO_EVENT",
        maximumChangeVelocity = 0,
        multipleEvents = "NO_EVENT"
      },
      bodyInformation={	 parkBrakeActive = true, 
        driverDoorAjar = true,
        passengerDoorAjar = true,
        rearLeftDoorAjar = true,
        rearRightDoorAjar = true,
        ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
        ignitionStatus = "UNKNOWN"
      },
      clusterModeStatus={	 powerModeActive = true, 
        powerModeQualificationStatus = "POWER_MODE_UNDEFINED",
        carModeStatus = "NORMAL",
        powerModeStatus = "KEY_OUT"
      },
      beltStatus = 	{	 driverBeltDeployed = "NO_EVENT",
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
        middleRow1BuckleBelted = "NO_EVENT"
      },
      airbagStatus = {	 driverAirbagDeployed = "YES",
        driverSideAirbagDeployed = "YES",
        driverCurtainAirbagDeployed = "YES",
        passengerAirbagDeployed = "YES",
        passengerCurtainAirbagDeployed = "YES",			
        driverKneeAirbagDeployed = "YES",
        passengerSideAirbagDeployed = "YES",
        passengerKneeAirbagDeployed = "YES"
      },
      gps = 			{
        pdop = 1.1,
        hdop = 1.1,
        vdop = 1.1,
        altitude = 1.1,
        heading = 1.1,
        speed = 1.1,
        
        utcYear = 2011,
        utcMonth = 1,
        utcDay = 1,
        utcHours = 1,
        utcMinutes = 1,
        utcSeconds = 1,
        satellites = 1,
        
        compassDirection = "NORTH",
        dimension = "NO_FIX",
        actual = true
      },
      tirePressure = 	{	 pressureTelltale = "OFF",
        leftFront = {status = "UNKNOWN"},
        rightFront = {status = "UNKNOWN"},
        leftRear = {status = "UNKNOWN"},
        rightRear = {status = "UNKNOWN"},
        innerLeftRear = {status = "UNKNOWN"},
        innerRightRear = {status = "UNKNOWN"}
      },
      fuelRange = 1.1,
      abs_State = "ACTIVE",
      tirePressureValue = {
        leftFront = 1,
        rightFront = 1,
        leftRear = 1,
        rightRear = 1,
        innerLeftRear = 1,
        innerRightRear = 1,
        frontRecommended = 1,
        rearRecommended = 1
      },
      tpms = "LOW",
      turnSignal = "LEFT"
    }
    self:verify_Notification_IsIgnored_Case(Notification)
    
  end
end
verify_gps_parameter()

local function verify_tirePressure_parameter()
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
  commonFunctions:newTestCasesGroup("Test suite For Verifying: tirePressure structure")	
  local Notification = {rpm = 1, tirePressure = {}}
  
  --1. IsMissed
  commonFunctions:TestCaseForNotification(self, Notification, {"tirePressure"}, "IsMissed", nil, true)
  
  --2. IsEmptyTable {}
  commonFunctions:TestCaseForNotification(self, Notification, {"tirePressure"}, "IsEmptyTable", {}, true)
  
  --3. IsWrongDataType
  commonFunctions:TestCaseForNotification(self, Notification, {"tirePressure"}, "IsWrongDataType", 123, false)
  
  
  --4. TCs for parameter: pressureTelltale
  local Notification = {rpm = 1, tirePressure = {leftFront = {status = "UNKNOWN"}}}
  local WarningLightStatus = {"OFF", "ON", "FLASH", "NOT_USED"}
  enumParameterInNotification:verify_Enumeration_Parameter(Notification, {"tirePressure", "pressureTelltale"}, WarningLightStatus, false)
  
  
  --5. TCs for parameters: "leftFront", "rightFront", "leftRear", "rightRear", "innerLeftRear", "innerRightRear"
  local function verify_SingleTireStatus_parameter_type(Parameter, Notification)
    
    --name="parameterName" type="Common.SingleTireStatus" mandatory="false"
    --struct name="SingleTireStatus">
    --name="status" type="Common.ComponentVolumeStatus" mandatory="true": 
    
    --1. IsMissed
    commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsMissed", nil, true)
    
    --2. IsWrongDataType
    commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsWrongDataType", 123, false)	
    
    --3. name="status" type="Common.ComponentVolumeStatus" mandatory="true"
    local Parameter_status = commonFunctions:BuildChildParameter(Parameter, "status")
    enumParameterInNotification:verify_Enumeration_Parameter(Notification, Parameter_status, ComponentVolumeStatus, true)
    
  end
  
  local Notification = {rpm = 1, tirePressure = {rightFront = {status = "NORMAL"}, leftFront = {} }}
  verify_SingleTireStatus_parameter_type({"tirePressure", "leftFront"}, Notification)
  
  local Notification = {rpm = 1, tirePressure = {leftRear = {status = "NORMAL"}, rightFront = {} }}
  verify_SingleTireStatus_parameter_type({"tirePressure", "rightFront"}, Notification)
  
  local Notification = {rpm = 1, tirePressure = {rightRear = {status = "NORMAL"}, leftRear = {} }}
  verify_SingleTireStatus_parameter_type({"tirePressure", "leftRear"}, Notification)
  
  local Notification = {rpm = 1, tirePressure = {innerLeftRear = {status = "NORMAL"}, rightRear = {} }}
  verify_SingleTireStatus_parameter_type({"tirePressure", "rightRear"}, Notification)
  
  local Notification = {rpm = 1, tirePressure = {innerRightRear = {status = "NORMAL"}, innerLeftRear = {} }}
  verify_SingleTireStatus_parameter_type({"tirePressure", "innerLeftRear"}, Notification)
  
  local Notification = {rpm = 1, tirePressure = {pressureTelltale = "OFF", innerRightRear = {} }}
  verify_SingleTireStatus_parameter_type({"tirePressure", "innerRightRear"}, Notification)
  
end
verify_tirePressure_parameter()
----------------------------------------------------------------------------------------------

--26. fuelRange: type="Float" minvalue="0" maxvalue="10000" mandatory="false"
local Notification = {rpm = 1}
floatParameterInNotification:verify_Float_Parameter(Notification, {"fuelRange"}, {0.000000, 10000.000000}, false)		
--27. abs_State: type="ABS_STATE" mandatory="false"
local Notification = {rpm =1, abs_State = {}}	
enumParameterInNotification:verify_Enumeration_Parameter(Notification,{"abs_State"},absStateValues,false)
--28. tirePressureValue: type="TirePressureValue" mandatory="false"
local Notification = {rpm =1, tirePressureValue = 
  {
    leftFront = 1,
    rightFront = 1,
    leftRear = 1,
    rightRear = 1,
    innerLeftRear = 1,
    innerRightRear = 1,
    frontRecommended = 1,
    rearRecommended = 1
  }
}
commonFunctions:newTestCasesGroup("Tets Suite For Parameter: tirePressureValue")

-- tirePressureValue IsEmpty
commonFunctions:TestCaseForNotification(self, Notification, {"tirePressureValue"}, "IsEmpty", {}, true)

-- tirePressureValue IsWrongType: 
commonFunctions:TestCaseForNotification(self, Notification, {"tirePressureValue"}, "IsWrongDataType", 123, false)

-- Check for all sub-params
local paramBoundary = {{0,65533}, {0,65533}, {0,65533}, {0,65533}, {0,65533}, {0,65533}, {0,65533}, {0,65533}}

for i = 1, #tirePressureValueParams do
  integerParameterInNotification:verify_Integer_Parameter(Notification, {"tirePressureValue", tirePressureValueParams[i]}, paramBoundary[i], false)
end		
--29. tpms: type="TPMS" mandatory="false"
local Notification = {rpm =1, tpms = {}}
enumParameterInNotification:verify_Enumeration_Parameter(Notification,{"tpms"},tpmsValues,false)
--30. turnSignal: type="TurnSignal" mandatory="false"
local Notification = {rpm =1, turnSignal ={}}
enumParameterInNotification:verify_Enumeration_Parameter(Notification,{"turnSignal"},turnSignalValues,false)
----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK IV----------------------------------------
----------------------------Check special cases of HMI notification---------------------------
----------------------------------------------------------------------------------------------
--Requirement id in JAMA or JIRA: 	
--APPLINK-14765: SDL must cut off the fake parameters from requests, responses and notifications received from HMI

--Verification criteria: 
--Refer to list of test case below.
-----------------------------------------------------------------------------------------------

--List of test cases for special cases of HMI notification:
--1. InvalidJsonSyntax
--2. InvalidStructure
--3. FakeParams 
--4. FakeParameterIsFromAnotherAPI
--5. MissedmandatoryParameters
--6. MissedAllPArameters
--7. SeveralNotifications with the same values
--8. SeveralNotifications with different values
----------------------------------------------------------------------------------------------

local function SpecialNotificationChecks()
  
  --Print new line to separate new test cases group
  commonFunctions:newTestCasesGroup("Test suite: Check special cases of HMI notification")
  
  
  --1. Verify OnVehicleData with invalid Json syntax
  ----------------------------------------------------------------------------------------------
  function Test:OnVehicleData_InvalidJsonSyntax()
    
    commonTestCases:DelayedExp(1000)
    
    --hmi side: send OnVehicleData 
    --":" is changed by ";" after "jsonrpc"
    self.hmiConnection:Send('{"params":{"rpm":1},"jsonrpc";"2.0","method":"VehicleInfo.OnVehicleData"}')
    
    --mobile side: expected Notification
    EXPECT_NOTIFICATION("OnVehicleData", {})	
    :Times(0)
  end
  
  --2. Verify OnVehicleData with invalid structure
  ----------------------------------------------------------------------------------------------
  function Test:OnVehicleData_InvalidJsonStructure()
    
    commonTestCases:DelayedExp(1000)
    
    --hmi side: send OnVehicleData 
    --method is moved into params parameter
    self.hmiConnection:Send('{"params":{"rpm":1,"method":"VehicleInfo.OnVehicleData"},"jsonrpc":"2.0"}')
    
    --mobile side: expected Notification
    EXPECT_NOTIFICATION("OnVehicleData", {})	
    :Times(0)
  end
  
  --3. Verify OnVehicleData with FakeParams
  ----------------------------------------------------------------------------------------------
  function Test:OnVehicleData_FakeParams()
    
    local NotificationWithFakeParameters = 
    {
      fake = 123,
      speed = 0.0,
      fuelLevel = -6.000000,
      instantFuelConsumption = 0.000000,
      externalTemperature = -40.000000,
      engineTorque = -1000.000000,
      accPedalPosition = 0.000000,
      steeringWheelAngle = -2000.000000,
      
      rpm = 0,
      odometer = 0,
      
      vin = "a",
      
      prndl = "PARK",
      fuelLevel_State = "UNKNOWN",
      driverBraking = "NO_EVENT",
      wiperStatus = "OFF",
      
      headLampStatus = {	fake = 123,
        lowBeamsOn = false, 
        highBeamsOn = false, 
        ambientLightSensorStatus = "NIGHT"
      },
      myKey = 		{	fake = 123,
      e911Override = "NO_DATA_EXISTS"},
      deviceStatus = 	{	fake = 123,
        voiceRecOn = true,
        btIconOn = true,
        callActive = true,
        phoneRoaming = true,
        textMsgAvailable = true,
        stereoAudioOutputMuted = true,
        monoAudioOutputMuted = true,
        eCallEventActive = true,
        primaryAudioSource = "USB",
        battLevelStatus = "ZERO_LEVEL_BARS",
        signalLevelStatus = "ZERO_LEVEL_BARS"
      },
      eCallInfo = 	{	fake = 123,
        eCallNotificationStatus = "NOT_SUPPORTED",
        auxECallNotificationStatus = "NOT_SUPPORTED",
        eCallConfirmationStatus = "NORMAL"
      },
      emergencyEvent ={	fake = 123,
        emergencyEventType = "NO_EVENT",
        fuelCutoffStatus = "TERMINATE_FUEL",
        rolloverEvent = "NO_EVENT",
        maximumChangeVelocity = 0,
        multipleEvents = "NO_EVENT"
      },
      bodyInformation={	fake = 123,
        parkBrakeActive = true, 
        driverDoorAjar = true,
        passengerDoorAjar = true,
        rearLeftDoorAjar = true,
        rearRightDoorAjar = true,
        ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
        ignitionStatus = "UNKNOWN"
      },
      clusterModeStatus={	fake = 123,
        powerModeActive = true, 
        powerModeQualificationStatus = "POWER_MODE_UNDEFINED",
        carModeStatus = "NORMAL",
        powerModeStatus = "KEY_OUT"
      },
      beltStatus = 	{	fake = 123,
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
        middleRow1BuckleBelted = "NO_EVENT"
      },
      airbagStatus = {	fake = 123,
        driverAirbagDeployed = "YES",
        driverSideAirbagDeployed = "YES",
        driverCurtainAirbagDeployed = "YES",
        passengerAirbagDeployed = "YES",
        passengerCurtainAirbagDeployed = "YES",			
        driverKneeAirbagDeployed = "YES",
        passengerSideAirbagDeployed = "YES",
        passengerKneeAirbagDeployed = "YES"
      },
      gps = 			{	fake = 123,
        longitudeDegrees = -180.0,
        latitudeDegrees = -90.0,
        pdop = 0.0,
        hdop = 0.0,
        vdop = 0.0,
        altitude = -10000.0,
        heading = 0.0,
        speed = 0.0,
        
        utcYear = 2010,
        utcMonth = 1,
        utcDay = 1,
        utcHours = 0,
        utcMinutes = 0,
        utcSeconds = 0,
        satellites = 0,
        
        compassDirection = "NORTH",
        dimension = "NO_FIX",
        actual = true
      },
      tirePressure = 	{	fake = 123,
        pressureTelltale = "OFF",
        leftFront = {status = "UNKNOWN"},
        rightFront = {status = "UNKNOWN"},
        leftRear = {status = "UNKNOWN"},
        rightRear = {status = "UNKNOWN"},
        innerLeftRear = {status = "UNKNOWN"},
        innerRightRear = {status = "UNKNOWN"}
      },
      fuelRange = 0.0,
      abs_State = "INACTIVE",
      tirePressureValue = {
        leftFront = 0,
        rightFront = 0,
        leftRear = 0,
        rightRear = 0,
        innerLeftRear = 0,
        innerRightRear = 0,
        frontRecommended = 0,
        rearRecommended = 0
      },
      tpms = "UNKNOWN",
      turnSignal = "OFF"				
    }
    
    local Notification_ExpectedResultOnMobileWithoutFakeParameters = 
    {
      speed = 0.0,
      fuelLevel = -6.000000,
      instantFuelConsumption = 0.000000,
      externalTemperature = -40.000000,
      engineTorque = -1000.000000,
      accPedalPosition = 0.000000,
      steeringWheelAngle = -2000.000000,
      
      rpm = 0,
      odometer = 0,
      
      --vin = "a",
      
      prndl = "PARK",
      fuelLevel_State = "UNKNOWN",
      driverBraking = "NO_EVENT",
      wiperStatus = "OFF",
      
      headLampStatus = {	lowBeamsOn = false, 
        highBeamsOn = false, 
        ambientLightSensorStatus = "NIGHT"
      },
      myKey = 		{	e911Override = "NO_DATA_EXISTS"},
      deviceStatus = 	{	voiceRecOn = true,
        btIconOn = true,
        callActive = true,
        phoneRoaming = true,
        textMsgAvailable = true,
        stereoAudioOutputMuted = true,
        monoAudioOutputMuted = true,
        eCallEventActive = true,
        primaryAudioSource = "USB",
        battLevelStatus = "ZERO_LEVEL_BARS",
        signalLevelStatus = "ZERO_LEVEL_BARS"
      },
      eCallInfo = 	{	eCallNotificationStatus = "NOT_SUPPORTED",
        auxECallNotificationStatus = "NOT_SUPPORTED",
        eCallConfirmationStatus = "NORMAL"
      },
      emergencyEvent ={	emergencyEventType = "NO_EVENT",
        fuelCutoffStatus = "TERMINATE_FUEL",
        rolloverEvent = "NO_EVENT",
        maximumChangeVelocity = 0,
        multipleEvents = "NO_EVENT"
      },
      bodyInformation={	parkBrakeActive = true, 
        driverDoorAjar = true,
        passengerDoorAjar = true,
        rearLeftDoorAjar = true,
        rearRightDoorAjar = true,
        ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
        ignitionStatus = "UNKNOWN"
      },
      clusterModeStatus={	powerModeActive = true, 
        powerModeQualificationStatus = "POWER_MODE_UNDEFINED",
        carModeStatus = "NORMAL",
        powerModeStatus = "KEY_OUT"
      },
      beltStatus = 	{	driverBeltDeployed = "NO_EVENT",
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
        middleRow1BuckleBelted = "NO_EVENT"
      },
      airbagStatus = {	driverAirbagDeployed = "YES",
        driverSideAirbagDeployed = "YES",
        driverCurtainAirbagDeployed = "YES",
        passengerAirbagDeployed = "YES",
        passengerCurtainAirbagDeployed = "YES",			
        driverKneeAirbagDeployed = "YES",
        passengerSideAirbagDeployed = "YES",
        passengerKneeAirbagDeployed = "YES"
      },
      gps = 			{	longitudeDegrees = -180.0,
        latitudeDegrees = -90.0,
        pdop = 0.0,
        hdop = 0.0,
        vdop = 0.0,
        altitude = -10000.0,
        heading = 0.0,
        speed = 0.0,
        
        utcYear = 2010,
        utcMonth = 1,
        utcDay = 1,
        utcHours = 0,
        utcMinutes = 0,
        utcSeconds = 0,
        satellites = 0,
        
        compassDirection = "NORTH",
        dimension = "NO_FIX",
        actual = true
      },
      tirePressure = 	{	pressureTelltale = "OFF",
        leftFront = {status = "UNKNOWN"},
        rightFront = {status = "UNKNOWN"},
        leftRear = {status = "UNKNOWN"},
        rightRear = {status = "UNKNOWN"},
        innerLeftRear = {status = "UNKNOWN"},
        innerRightRear = {status = "UNKNOWN"}
      },
      fuelRange = 0.0,
      abs_State = "INACTIVE",
      tirePressureValue = {
        leftFront = 0,
        rightFront = 0,
        leftRear = 0,
        rightRear = 0,
        innerLeftRear = 0,
        innerRightRear = 0,
        frontRecommended = 0,
        rearRecommended = 0
      },
      tpms = "UNKNOWN",
      turnSignal = "OFF"
    }
    
    
    
    --hmi side: sending OnVehicleData notification			
    self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", NotificationWithFakeParameters)
    
    --mobile side: expected Notification
    EXPECT_NOTIFICATION("OnVehicleData", Notification_ExpectedResultOnMobileWithoutFakeParameters)	
    :ValidIf (function(_,data)
      if data.payload.fake or
      data.payload.headLampStatus.fake or				
      data.payload.myKey.fake or
      data.payload.deviceStatus.fake or
      data.payload.eCallInfo.fake or					
      data.payload.emergencyEvent.fake or
      data.payload.bodyInformation.fake or
      data.payload.clusterModeStatus.fake or
      data.payload.beltStatus.fake or
      data.payload.airbagStatus.fake or
      data.payload.gps.fake or
      data.payload.tirePressure.fake				
      then
        commonFunctions:printError(" SDL resends fake parameter to mobile app ")
        return false
      else 
        return true
      end
    end)		
  end
  
  
  --4. Verify OnVehicleData with FakeParameterIsFromAnotherAPI	
  function Test:OnVehicleData_FakeParameterIsFromAnotherAPI()
    
    local NotificationWithFakeParameters = 
    {
      sliderPosition = 123,
      speed = 0.0,
      fuelLevel = -6.000000,
      instantFuelConsumption = 0.000000,
      externalTemperature = -40.000000,
      engineTorque = -1000.000000,
      accPedalPosition = 0.000000,
      steeringWheelAngle = -2000.000000,
      
      rpm = 0,
      odometer = 0,
      
      vin = "a",
      
      prndl = "PARK",
      fuelLevel_State = "UNKNOWN",
      driverBraking = "NO_EVENT",
      wiperStatus = "OFF",
      
      headLampStatus = {	sliderPosition = 123,
        lowBeamsOn = false, 
        highBeamsOn = false, 
        ambientLightSensorStatus = "NIGHT"
      },
      myKey = 		{	sliderPosition = 123,
      e911Override = "NO_DATA_EXISTS"},
      deviceStatus = 	{	sliderPosition = 123,
        voiceRecOn = true,
        btIconOn = true,
        callActive = true,
        phoneRoaming = true,
        textMsgAvailable = true,
        stereoAudioOutputMuted = true,
        monoAudioOutputMuted = true,
        eCallEventActive = true,
        primaryAudioSource = "USB",
        battLevelStatus = "ZERO_LEVEL_BARS",
        signalLevelStatus = "ZERO_LEVEL_BARS"
      },
      eCallInfo = 	{	sliderPosition = 123,
        eCallNotificationStatus = "NOT_SUPPORTED",
        auxECallNotificationStatus = "NOT_SUPPORTED",
        eCallConfirmationStatus = "NORMAL"
      },
      emergencyEvent ={	sliderPosition = 123,
        emergencyEventType = "NO_EVENT",
        fuelCutoffStatus = "TERMINATE_FUEL",
        rolloverEvent = "NO_EVENT",
        maximumChangeVelocity = 0,
        multipleEvents = "NO_EVENT"
      },
      bodyInformation={	sliderPosition = 123,
        parkBrakeActive = true, 
        driverDoorAjar = true,
        passengerDoorAjar = true,
        rearLeftDoorAjar = true,
        rearRightDoorAjar = true,
        ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
        ignitionStatus = "UNKNOWN"
      },
      clusterModeStatus={	sliderPosition = 123,
        powerModeActive = true, 
        powerModeQualificationStatus = "POWER_MODE_UNDEFINED",
        carModeStatus = "NORMAL",
        powerModeStatus = "KEY_OUT"
      },
      beltStatus = 	{	sliderPosition = 123,
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
        middleRow1BuckleBelted = "NO_EVENT"
      },
      airbagStatus = {	sliderPosition = 123,
        driverAirbagDeployed = "YES",
        driverSideAirbagDeployed = "YES",
        driverCurtainAirbagDeployed = "YES",
        passengerAirbagDeployed = "YES",
        passengerCurtainAirbagDeployed = "YES",			
        driverKneeAirbagDeployed = "YES",
        passengerSideAirbagDeployed = "YES",
        passengerKneeAirbagDeployed = "YES"
      },
      gps = 			{	sliderPosition = 123,
        longitudeDegrees = -180.0,
        latitudeDegrees = -90.0,
        pdop = 0.0,
        hdop = 0.0,
        vdop = 0.0,
        altitude = -10000.0,
        heading = 0.0,
        speed = 0.0,
        
        utcYear = 2010,
        utcMonth = 1,
        utcDay = 1,
        utcHours = 0,
        utcMinutes = 0,
        utcSeconds = 0,
        satellites = 0,
        
        compassDirection = "NORTH",
        dimension = "NO_FIX",
        actual = true
      },
      tirePressure = 	{	sliderPosition = 123,
        pressureTelltale = "OFF",
        leftFront = {status = "UNKNOWN"},
        rightFront = {status = "UNKNOWN"},
        leftRear = {status = "UNKNOWN"},
        rightRear = {status = "UNKNOWN"},
        innerLeftRear = {status = "UNKNOWN"},
        innerRightRear = {status = "UNKNOWN"}
      },
      fuelRange = 0.0,
      abs_State = "INACTIVE",
      tirePressureValue = {
        leftFront = 0,
        rightFront = 0,
        leftRear = 0,
        rightRear = 0,
        innerLeftRear = 0,
        innerRightRear = 0,
        frontRecommended = 0,
        rearRecommended = 0
      },
      tpms = "UNKNOWN",
      turnSignal = "OFF"	
    }
    
    local Notification_ExpectedResultOnMobileWithoutFakeParameters = 
    {
      speed = 0.0,
      fuelLevel = -6.000000,
      instantFuelConsumption = 0.000000,
      externalTemperature = -40.000000,
      engineTorque = -1000.000000,
      accPedalPosition = 0.000000,
      steeringWheelAngle = -2000.000000,
      
      rpm = 0,
      odometer = 0,
      
      --vin = "a",
      
      prndl = "PARK",
      fuelLevel_State = "UNKNOWN",
      driverBraking = "NO_EVENT",
      wiperStatus = "OFF",
      
      headLampStatus = {	lowBeamsOn = false, 
        highBeamsOn = false, 
        ambientLightSensorStatus = "NIGHT"
      },
      myKey = 		{	e911Override = "NO_DATA_EXISTS"},
      deviceStatus = 	{	voiceRecOn = true,
        btIconOn = true,
        callActive = true,
        phoneRoaming = true,
        textMsgAvailable = true,
        stereoAudioOutputMuted = true,
        monoAudioOutputMuted = true,
        eCallEventActive = true,
        primaryAudioSource = "USB",
        battLevelStatus = "ZERO_LEVEL_BARS",
        signalLevelStatus = "ZERO_LEVEL_BARS"
      },
      eCallInfo = 	{	eCallNotificationStatus = "NOT_SUPPORTED",
        auxECallNotificationStatus = "NOT_SUPPORTED",
        eCallConfirmationStatus = "NORMAL"
      },
      emergencyEvent ={	emergencyEventType = "NO_EVENT",
        fuelCutoffStatus = "TERMINATE_FUEL",
        rolloverEvent = "NO_EVENT",
        maximumChangeVelocity = 0,
        multipleEvents = "NO_EVENT"
      },
      bodyInformation={	parkBrakeActive = true, 
        driverDoorAjar = true,
        passengerDoorAjar = true,
        rearLeftDoorAjar = true,
        rearRightDoorAjar = true,
        ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
        ignitionStatus = "UNKNOWN"
      },
      clusterModeStatus={	powerModeActive = true, 
        powerModeQualificationStatus = "POWER_MODE_UNDEFINED",
        carModeStatus = "NORMAL",
        powerModeStatus = "KEY_OUT"
      },
      beltStatus = 	{	driverBeltDeployed = "NO_EVENT",
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
        middleRow1BuckleBelted = "NO_EVENT"
      },
      airbagStatus = {	driverAirbagDeployed = "YES",
        driverSideAirbagDeployed = "YES",
        driverCurtainAirbagDeployed = "YES",
        passengerAirbagDeployed = "YES",
        passengerCurtainAirbagDeployed = "YES",			
        driverKneeAirbagDeployed = "YES",
        passengerSideAirbagDeployed = "YES",
        passengerKneeAirbagDeployed = "YES"
      },
      gps = 			{	longitudeDegrees = -180.0,
        latitudeDegrees = -90.0,
        pdop = 0.0,
        hdop = 0.0,
        vdop = 0.0,
        altitude = -10000.0,
        heading = 0.0,
        speed = 0.0,
        
        utcYear = 2010,
        utcMonth = 1,
        utcDay = 1,
        utcHours = 0,
        utcMinutes = 0,
        utcSeconds = 0,
        satellites = 0,
        
        compassDirection = "NORTH",
        dimension = "NO_FIX",
        actual = true
      },
      tirePressure = 	{	pressureTelltale = "OFF",
        leftFront = {status = "UNKNOWN"},
        rightFront = {status = "UNKNOWN"},
        leftRear = {status = "UNKNOWN"},
        rightRear = {status = "UNKNOWN"},
        innerLeftRear = {status = "UNKNOWN"},
        innerRightRear = {status = "UNKNOWN"}
      },
      fuelRange = 0.0,
      abs_State = "INACTIVE",
      tirePressureValue = {
        leftFront = 0,
        rightFront = 0,
        leftRear = 0,
        rightRear = 0,
        innerLeftRear = 0,
        innerRightRear = 0,
        frontRecommended = 0,
        rearRecommended = 0
      },
      tpms = "UNKNOWN",
      turnSignal = "OFF"	
    }
    
    
    
    --hmi side: sending OnVehicleData notification			
    self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", NotificationWithFakeParameters)
    
    --mobile side: expected Notification
    EXPECT_NOTIFICATION("OnVehicleData", Notification_ExpectedResultOnMobileWithoutFakeParameters)	
    :ValidIf (function(_,data)
      if data.payload.sliderPosition or
      data.payload.headLampStatus.sliderPosition or				
      data.payload.myKey.sliderPosition or
      data.payload.deviceStatus.sliderPosition or
      data.payload.eCallInfo.sliderPosition or					
      data.payload.emergencyEvent.sliderPosition or
      data.payload.bodyInformation.sliderPosition or
      data.payload.clusterModeStatus.sliderPosition or
      data.payload.beltStatus.sliderPosition or
      data.payload.airbagStatus.sliderPosition or
      data.payload.gps.sliderPosition or
      data.payload.tirePressure.sliderPosition				
      then
        commonFunctions:printError(" SDL resends fake parameter to mobile app ")
        return false
      else 
        return true
      end
    end)		
  end
  
  
  --5. Verify OnVehicleData misses mandatory parameter
  ----------------------------------------------------------------------------------------------
  function Test:OnVehicleData_MissedmandatoryParameters()
    
    commonTestCases:DelayedExp(1000)
    
    --hmi side: sending OnVehicleData notification			
    self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {})
    
    --mobile side: expected Notification
    EXPECT_NOTIFICATION("OnVehicleData", {})	
    :Times(0)	
  end
  
  
  
  --6. Verify OnVehicleData MissedAllPArameters: Covered by case 5.
  ----------------------------------------------------------------------------------------------
  
  
  --7. Verify OnVehicleData with SeveralNotifications_WithTheSameValues
  ----------------------------------------------------------------------------------------------
  function Test:OnVehicleData_SeveralNotifications_WithTheSameValues()
    
    --hmi side: sending OnVehicleData notification			
    self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {rpm = 1})
    self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {rpm = 1})
    self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {rpm = 1})
    
    --mobile side: expected Notification
    EXPECT_NOTIFICATION("OnVehicleData", {rpm = 1},
    {rpm = 1},
    {rpm = 1})
    :Times(3)
  end
  
  
  
  --8. Verify OnVehicleData with SeveralNotifications_WithDifferentValues
  ----------------------------------------------------------------------------------------------	
  function Test:OnVehicleData_SeveralNotifications_WithDifferentValues()
    
    --hmi side: sending OnVehicleData notification			
    self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {rpm = 1})
    self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {speed = 2})
    
    --mobile side: expected Notification
    EXPECT_NOTIFICATION("OnVehicleData", {rpm = 1},
    {speed = 2})
    :Times(2)
    
  end
  
end

SpecialNotificationChecks()	



-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK V----------------------------------------
-------------------------------------Checks All Result Codes-----------------------------------
-----------------------------------------------------------------------------------------------

--Description: Check all resultCodes

--Not Applicable


----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VI----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------

--Description: TC's checks SDL behavior by processing
-- different request sequence with timeout
-- with emulating of user's actions	

--Requirement id in JAMA: 
--N/A

--Verification criteria: Verify SDL behaviors in different states of policy table: 
--1. Notification is not exist in PT => DISALLOWED in policy table, SDL ignores the notification
--2. Notification is exist in PT but it has not consented yet by user => DISALLOWED in policy table, SDL ignores the notification
--3. Notification is exist in PT but user does not allow function group that contains this notification => USER_DISALLOWED in policy table, SDL ignores the notification
--4. Notification is exist in PT and user allow function group that contains this notification
----------------------------------------------------------------------------------------------

local function SequenceChecks()
  
  --Print new line to separate new test cases group
  commonFunctions:newTestCasesGroup("Test suite: Sequence with emulating of user's action(s)")
  
  
  --1. Notification is not exist in PT => DISALLOWED in policy table, SDL ignores the notification
  ----------------------------------------------------------------------------------------------
  --Precondition: Build policy table file
  local PTName = testCasesForPolicyTable:createPolicyTableWithoutAPI("OnVehicleData")
  
  --Precondition: Update policy table
  testCasesForPolicyTable:updatePolicy(PTName)
  
  --Send notification and check it is ignored
  function Test:OnVehicleData_IsNotExistInPT_Disallowed()
    
    commonTestCases:DelayedExp(1000)
    
    --hmi side: send notification
    self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {speed = 1})	 		
    
    --mobile side: expected Notification
    EXPECT_NOTIFICATION("OnVehicleData", {speed = 1})	
    :Times(0)				
  end
  ----------------------------------------------------------------------------------------------
  
  
  
  --2. Notification is allowed but parameters are not allowed => DISALLOWED in policy table, SDL ignores the notification
  ----------------------------------------------------------------------------------------------
  --Precondition: Build policy table file
  local PermissionLines_OnVehicleData_NotAllowParameters = 
  [[					"OnVehicleData": {
    "hmi_levels": [
    "BACKGROUND",
    "FULL",
    "LIMITED"
    ],
    "parameters": [
    "rpm", 
    "fuelLevel", 
    "fuelLevel_State", 
    "instantFuelConsumption", 
    "externalTemperature", 
    "prndl", 
    "tirePressure", 
    "odometer"						
    ]
  }]]
  
  local PermissionLinesForBase4 = PermissionLines_OnVehicleData_NotAllowParameters .. ", \n"
  local PermissionLinesForGroup1 = nil
  local PermissionLinesForApplication = nil
  local PTName = testCasesForPolicyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication, {"OnVehicleData"})	
  
  testCasesForPolicyTable:updatePolicy(PTName)
  
  --Send notification and check it is ignored
  function Test:OnVehicleData_IsAllowedButParameterIsNotAllowed_Disallowed()
    
    commonTestCases:DelayedExp(1000)
    
    --hmi side: send notification
    self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {speed = 1})	 		
    
    --mobile side: expected Notification
    EXPECT_NOTIFICATION("OnVehicleData", {speed = 1})	
    :Times(0)				
  end
  ----------------------------------------------------------------------------------------------
  
  
  
  
  
  --3. Notification is exist in PT but it has not consented yet by user => DISALLOWED in policy table, SDL ignores the notification
  ----------------------------------------------------------------------------------------------
  --Precondition: Build policy table file
  local PermissionLinesForBase4 = PermissionLines_SubscribeVehicleData .. ", \n"
  local PermissionLinesForGroup1 = PermissionLines_OnVehicleData .. "\n"
  local appID = config.application1.registerAppInterfaceParams.appID
  local PermissionLinesForApplication = 
  [[			"]]..appID ..[[" : {
    "keep_context" : false,
    "steal_focus" : false,
    "priority" : "NONE",
    "default_hmi" : "NONE",
    "groups" : ["Base-4", "group1"]
  },
  ]]
  
  local PTName = testCasesForPolicyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication)	
  testCasesForPolicyTable:updatePolicy(PTName)		
  
  --Send notification and check it is ignored
  function Test:OnVehicleData_UserHasNotConsentedYet_Disallowed()
    
    commonTestCases:DelayedExp(1000)
    
    --hmi side: send notification
    self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {speed = 1})	 		
    
    --mobile side: expected Notification
    EXPECT_NOTIFICATION("OnVehicleData", {speed = 1})	
    :Times(0)				
  end
  ----------------------------------------------------------------------------------------------
  
  
  --4. Notification is exist in PT but user does not allow function group that contains this notification => USER_DISALLOWED in policy table, SDL ignores the notification
  ----------------------------------------------------------------------------------------------	
  --Precondition: User does not allow function group
  testCasesForPolicyTable:userConsent(false, "group1")		
  
  function Test:OnVehicleData_UserDisallowed()
    
    commonTestCases:DelayedExp(1000)
    
    --hmi side: send notification
    self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {speed = 1})	 		
    
    --mobile side: expected Notification
    EXPECT_NOTIFICATION("OnVehicleData", {speed = 1})	
    :Times(0)	
  end
  ----------------------------------------------------------------------------------------------
  
  
  --5. Notification is exist in PT and user allow function group that contains this notification
  ----------------------------------------------------------------------------------------------
  --Precondition: User allows function group
  testCasesForPolicyTable:userConsent(true, "group1")		
  
  function Test:OnVehicleData_SUCCESS()
    --hmi side: send notification
    self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", {speed = 1})	 		
    
    --mobile side: expected Notification
    EXPECT_NOTIFICATION("OnVehicleData", {speed = 1})	
  end
  ----------------------------------------------------------------------------------------------	
end

SequenceChecks()


----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VII---------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------

--Description: Check different HMIStatus

--Requirement id in JAMA: 	
--SDLAQ-CRS-1304: HMI Status Requirements for OnVehicleData (FULL, LIMITED, BACKGROUND)

--Verification criteria: 
--None of the applications in HMI NONE receives OnVehicleData request.
--The applications in HMI FULL don't reject OnVehicleData request.
--The applications in HMI LIMITED don't reject OnVehicleData request.
--The applications in HMI BACKGROUND don't reject OnVehicleData request.

local function DifferentHMIlevelChecks()
  
  --Print new line to separate new test cases group
  commonFunctions:newTestCasesGroup("Test suite: Different HMI Level Checks")
  ----------------------------------------------------------------------------------------------
  
  --1. HMI level is NONE
  ----------------------------------------------------------------------------------------------
  --Precondition: Deactivate app to NONE HMI level	
  commonSteps:DeactivateAppToNoneHmiLevel()
  
  function Test:OnVehicleData_Notification_InNoneHmiLevel()
    
    commonTestCases:DelayedExp(1000)
    
    
    local Notification_AllParametersLowBound = 
    {
      speed = 0.0,
      fuelLevel = -6.000000,
      instantFuelConsumption = 0.000000,
      externalTemperature = -40.000000,
      engineTorque = -1000.000000,
      accPedalPosition = 0.000000,
      steeringWheelAngle = -2000.000000,
      
      rpm = 0,
      odometer = 0,
      
      vin = "a",
      
      prndl = "PARK",
      fuelLevel_State = "UNKNOWN",
      driverBraking = "NO_EVENT",
      wiperStatus = "OFF",
      
      headLampStatus = {	lowBeamsOn = false, 
        highBeamsOn = false, 
        ambientLightSensorStatus = "NIGHT"
      },
      myKey = 		{	e911Override = "NO_DATA_EXISTS"},
      deviceStatus = 	{	voiceRecOn = true,
        btIconOn = true,
        callActive = true,
        phoneRoaming = true,
        textMsgAvailable = true,
        stereoAudioOutputMuted = true,
        monoAudioOutputMuted = true,
        eCallEventActive = true,
        primaryAudioSource = "USB",
        battLevelStatus = "ZERO_LEVEL_BARS",
        signalLevelStatus = "ZERO_LEVEL_BARS"
      },
      eCallInfo = 	{	eCallNotificationStatus = "NOT_SUPPORTED",
        auxECallNotificationStatus = "NOT_SUPPORTED",
        eCallConfirmationStatus = "NORMAL"
      },
      emergencyEvent ={	emergencyEventType = "NO_EVENT",
        fuelCutoffStatus = "TERMINATE_FUEL",
        rolloverEvent = "NO_EVENT",
        maximumChangeVelocity = 0,
        multipleEvents = "NO_EVENT"
      },
      bodyInformation={	parkBrakeActive = true, 
        driverDoorAjar = true,
        passengerDoorAjar = true,
        rearLeftDoorAjar = true,
        rearRightDoorAjar = true,
        ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
        ignitionStatus = "UNKNOWN"
      },
      clusterModeStatus={	powerModeActive = true, 
        powerModeQualificationStatus = "POWER_MODE_UNDEFINED",
        carModeStatus = "NORMAL",
        powerModeStatus = "KEY_OUT"
      },
      beltStatus = 	{	driverBeltDeployed = "NO_EVENT",
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
        middleRow1BuckleBelted = "NO_EVENT"
      },
      airbagStatus = {	driverAirbagDeployed = "YES",
        driverSideAirbagDeployed = "YES",
        driverCurtainAirbagDeployed = "YES",
        passengerAirbagDeployed = "YES",
        passengerCurtainAirbagDeployed = "YES",			
        driverKneeAirbagDeployed = "YES",
        passengerSideAirbagDeployed = "YES",
        passengerKneeAirbagDeployed = "YES"
      },
      gps = 			{	longitudeDegrees = -180.0,
        latitudeDegrees = -90.0,
        pdop = 0.0,
        hdop = 0.0,
        vdop = 0.0,
        altitude = -10000.0,
        heading = 0.0,
        speed = 0.0,
        
        utcYear = 2010,
        utcMonth = 1,
        utcDay = 1,
        utcHours = 0,
        utcMinutes = 0,
        utcSeconds = 0,
        satellites = 0,
        
        compassDirection = "NORTH",
        dimension = "NO_FIX",
        actual = true
      },
      tirePressure = 	{	pressureTelltale = "OFF",
        leftFront = {status = "UNKNOWN"},
        rightFront = {status = "UNKNOWN"},
        leftRear = {status = "UNKNOWN"},
        rightRear = {status = "UNKNOWN"},
        innerLeftRear = {status = "UNKNOWN"},
        innerRightRear = {status = "UNKNOWN"}
      },
      fuelRange = 0.0,
      abs_State = "INACTIVE",
      tirePressureValue = {
        leftFront = 0,
        rightFront = 0,
        leftRear = 0,
        rightRear = 0,
        innerLeftRear = 0,
        innerRightRear = 0,
        frontRecommended = 0,
        rearRecommended = 0
      },
      tpms = "UNKNOWN",
      turnSignal = "OFF"										
    }
    
    
    --hmi side: send notification
    self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", Notification_AllParametersLowBound)	 		
    
    --mobile side: expected Notification
    EXPECT_NOTIFICATION("OnVehicleData", {})	
    :Times(0)				
  end			
  
  --Postcondition: Activate app
  commonSteps:ActivationApp()	
  ----------------------------------------------------------------------------------------------
  
  
  --2. HMI level is LIMITED
  ----------------------------------------------------------------------------------------------
  if commonFunctions:isMediaApp() then
    -- Precondition: Change app to LIMITED
    commonSteps:ChangeHMIToLimited()
    
    OnVehicleData_AllParametersLowerBound_SUCCESS("OnVehicleData_Notification_InLimitedHmiLevel")
    
    --Postcondition: Activate app
    commonSteps:ActivationApp()	
  end
  ----------------------------------------------------------------------------------------------
  
  
  --3. HMI level is BACKGROUND
  ----------------------------------------------------------------------------------------------
  --Precondition:
  commonTestCases:ChangeAppToBackgroundHmiLevel()
  
  OnVehicleData_AllParametersLowerBound_SUCCESS("OnVehicleData_Notification_InBackgroundHmiLevel")
  ----------------------------------------------------------------------------------------------
end
DifferentHMIlevelChecks()

----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VIII--------------------------------------
-----------------------------------------Policy Testing---------------------------------------
----------------------------------------------------------------------------------------------

--DISALLOWED
--1. parameters in PT is empty ({}) (CRQ #1,2: APPLINK-23963)
--2. only disallowed parameters (CRQ #3: APPLINK-24180)
--3. only parameters in function groups that use has not consented yet (CRQ #8: APPLINK-25890)
--4. only parameters in function groups that use disallows (CRQ #8: APPLINK-25890)
--5. some parameters in disallowed function group + some parameters is not allowed by PT (CRQ #9: APPLINK-25891)

--ALLOW
--1. parameters in PT is omitted (CRQ #5,6: APPLINK-24225)
--2. only allowed parameters (CRQ #7: APPLINK-24229)
--3. only user allowed parameters in consented group
--4. allowed parameters in consented group + allowed parameters by PT

--DISALLOWED + ALLOWED:
--1. some disallowed parameters + some allowed parameters(CRQ #4: APPLINK-24215)
--2. allowed parameters in consented group + disallowed parameters by PT
--3. allow group 1 + allowed base-4 + disallowed base-4
--4. allowed parameters in consented group + disallowed parameters by PT


--Note: This part only covers above CRQs. Other cases should be verified in scope of full policy testing.

local function Test_Block_VIII()	
  
  --Print new line to separate in ATF log
  commonFunctions:newTestCasesGroup("TEST BLOCK VIII: Policy Testing")
  
  -- Common variables 
  local OnVehicleData_Full_Notification = 
  {
    speed = 0.0,
    fuelLevel = -6.000000,
    instantFuelConsumption = 0.000000,
    externalTemperature = -40.000000,
    engineTorque = -1000.000000,
    accPedalPosition = 0.000000,
    steeringWheelAngle = -2000.000000,
    
    rpm = 0,
    odometer = 0,
    
    --vin = "a", --This parameter is not applicable for OnVehicleData notification
    
    prndl = "PARK",
    fuelLevel_State = "UNKNOWN",
    driverBraking = "NO_EVENT",
    wiperStatus = "OFF",
    
    headLampStatus = {	 lowBeamsOn = false, 
      highBeamsOn = false, 
      ambientLightSensorStatus = "NIGHT"
    },
    myKey = 		{	 e911Override = "NO_DATA_EXISTS"},
    deviceStatus = 	{	 voiceRecOn = true,
      btIconOn = true,
      callActive = true,
      phoneRoaming = true,
      textMsgAvailable = true,
      stereoAudioOutputMuted = true,
      monoAudioOutputMuted = true,
      eCallEventActive = true,
      primaryAudioSource = "USB",
      battLevelStatus = "ZERO_LEVEL_BARS",
      signalLevelStatus = "ZERO_LEVEL_BARS"
    },
    eCallInfo = 	{	 eCallNotificationStatus = "NOT_SUPPORTED",
      auxECallNotificationStatus = "NOT_SUPPORTED",
      eCallConfirmationStatus = "NORMAL"
    },
    emergencyEvent ={	 emergencyEventType = "NO_EVENT",
      fuelCutoffStatus = "TERMINATE_FUEL",
      rolloverEvent = "NO_EVENT",
      maximumChangeVelocity = 0,
      multipleEvents = "NO_EVENT"
    },
    bodyInformation={	 parkBrakeActive = true, 
      driverDoorAjar = true,
      passengerDoorAjar = true,
      rearLeftDoorAjar = true,
      rearRightDoorAjar = true,
      ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
      ignitionStatus = "UNKNOWN"
    },
    clusterModeStatus={	 powerModeActive = true, 
      powerModeQualificationStatus = "POWER_MODE_UNDEFINED",
      carModeStatus = "NORMAL",
      powerModeStatus = "KEY_OUT"
    },
    beltStatus = 	{	 driverBeltDeployed = "NO_EVENT",
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
      middleRow1BuckleBelted = "NO_EVENT"
    },
    airbagStatus = {	 driverAirbagDeployed = "YES",
      driverSideAirbagDeployed = "YES",
      driverCurtainAirbagDeployed = "YES",
      passengerAirbagDeployed = "YES",
      passengerCurtainAirbagDeployed = "YES",			
      driverKneeAirbagDeployed = "YES",
      passengerSideAirbagDeployed = "YES",
      passengerKneeAirbagDeployed = "YES"
    },
    gps = 			{	longitudeDegrees = -180.0,
      latitudeDegrees = -90.0,
      pdop = 0.0,
      hdop = 0.0,
      vdop = 0.0,
      altitude = -10000.0,
      heading = 0.0,
      speed = 0.0,
      
      utcYear = 2010,
      utcMonth = 1,
      utcDay = 1,
      utcHours = 0,
      utcMinutes = 0,
      utcSeconds = 0,
      satellites = 0,
      
      compassDirection = "NORTH",
      dimension = "NO_FIX",
      actual = true
    },
    tirePressure = 	{	 pressureTelltale = "OFF",
      leftFront = {status = "UNKNOWN"},
      rightFront = {status = "UNKNOWN"},
      leftRear = {status = "UNKNOWN"},
      rightRear = {status = "UNKNOWN"},
      innerLeftRear = {status = "UNKNOWN"},
      innerRightRear = {status = "UNKNOWN"}
    },
    fuelRange = 0.0,
    abs_State = "INACTIVE",
    tirePressureValue = {
      leftFront = 0,
      rightFront = 0,
      leftRear = 0,
      rightRear = 0,
      innerLeftRear = 0,
      innerRightRear = 0,
      frontRecommended = 0,
      rearRecommended = 0
    },
    tpms = "UNKNOWN",
    turnSignal = "OFF"
  }
  
  local OnVehicleData_Full_Expected_Notification = 
  {
    speed = 0.0,
    fuelLevel = -6.000000,
    instantFuelConsumption = 0.000000,
    externalTemperature = -40.000000,
    engineTorque = -1000.000000,
    accPedalPosition = 0.000000,
    steeringWheelAngle = -2000.000000,
    
    rpm = 0,
    odometer = 0,
    
    --vin = "a", --This parameter is not applicable for OnVehicleData notification
    
    prndl = "PARK",
    fuelLevel_State = "UNKNOWN",
    driverBraking = "NO_EVENT",
    wiperStatus = "OFF",
    
    headLampStatus = {	
      lowBeamsOn = false, 
      highBeamsOn = false, 
      ambientLightSensorStatus = "NIGHT"
    },
    myKey = 		{e911Override = "NO_DATA_EXISTS"},
    deviceStatus = 	{	voiceRecOn = true,
      btIconOn = true,
      callActive = true,
      phoneRoaming = true,
      textMsgAvailable = true,
      stereoAudioOutputMuted = true,
      monoAudioOutputMuted = true,
      eCallEventActive = true,
      primaryAudioSource = "USB",
      battLevelStatus = "ZERO_LEVEL_BARS",
      signalLevelStatus = "ZERO_LEVEL_BARS"
    },
    eCallInfo = 	{	eCallNotificationStatus = "NOT_SUPPORTED",
      auxECallNotificationStatus = "NOT_SUPPORTED",
      eCallConfirmationStatus = "NORMAL"
    },
    emergencyEvent ={	emergencyEventType = "NO_EVENT",
      fuelCutoffStatus = "TERMINATE_FUEL",
      rolloverEvent = "NO_EVENT",
      maximumChangeVelocity = 0,
      multipleEvents = "NO_EVENT"
    },
    bodyInformation={	parkBrakeActive = true, 
      driverDoorAjar = true,
      passengerDoorAjar = true,
      rearLeftDoorAjar = true,
      rearRightDoorAjar = true,
      ignitionStableStatus = "IGNITION_SWITCH_NOT_STABLE", 
      ignitionStatus = "UNKNOWN"
    },
    clusterModeStatus={	powerModeActive = true, 
      powerModeQualificationStatus = "POWER_MODE_UNDEFINED",
      carModeStatus = "NORMAL",
      powerModeStatus = "KEY_OUT"
    },
    beltStatus = 	{	driverBeltDeployed = "NO_EVENT",
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
      middleRow1BuckleBelted = "NO_EVENT"
    },
    airbagStatus = {	driverAirbagDeployed = "YES",
      driverSideAirbagDeployed = "YES",
      driverCurtainAirbagDeployed = "YES",
      passengerAirbagDeployed = "YES",
      passengerCurtainAirbagDeployed = "YES",			
      driverKneeAirbagDeployed = "YES",
      passengerSideAirbagDeployed = "YES",
      passengerKneeAirbagDeployed = "YES"
    },
    gps = 			{	longitudeDegrees = -180.0,
      latitudeDegrees = -90.0,
      pdop = 0.0,
      hdop = 0.0,
      vdop = 0.0,
      altitude = -10000.0,
      heading = 0.0,
      speed = 0.0,
      
      utcYear = 2010,
      utcMonth = 1,
      utcDay = 1,
      utcHours = 0,
      utcMinutes = 0,
      utcSeconds = 0,
      satellites = 0,
      
      compassDirection = "NORTH",
      dimension = "NO_FIX",
      actual = true
    },
    tirePressure = 	{	pressureTelltale = "OFF",
      leftFront = {status = "UNKNOWN"},
      rightFront = {status = "UNKNOWN"},
      leftRear = {status = "UNKNOWN"},
      rightRear = {status = "UNKNOWN"},
      innerLeftRear = {status = "UNKNOWN"},
      innerRightRear = {status = "UNKNOWN"}
    },
    fuelRange = 0.0,
    abs_State = "INACTIVE",
    tirePressureValue = {
      leftFront = 0,
      rightFront = 0,
      leftRear = 0,
      rightRear = 0,
      innerLeftRear = 0,
      innerRightRear = 0,
      frontRecommended = 0,
      rearRecommended = 0
    },
    tpms = "UNKNOWN",
    turnSignal = "OFF"
  }
  
  ----------------------------------------------------------------------------------------------
  --CRQ #1: APPLINK-21166 [Policies] Conditions for PoliciesManager to disallow all requested parameters: 
  --DISALLOWED: parameters in PT is empty ({}).
  --It is not applied for OnVehicleData. For OnVehicleData, use CRQ #2: APPLINK-23963
  ----------------------------------------------------------------------------------------------
  
  ----------------------------------------------------------------------------------------------	
  --CRQ #2: APPLINK-23963: [Policies] [OnVehicleData] Conditions for PoliciesManager to disallow all requested parameters: 
  --DISALLOWED: parameters in PT is empty ({})
  ----------------------------------------------------------------------------------------------	
  local function CRQ2_APPLINK_23963()
    
    --Print new line to separate in ATF log
    commonFunctions:newTestCasesGroup("CRQ APPLINK-23963")
    
    --Define local functions
    local function OnVehicleData_parameters_IsEmpty_CreatePT()
      
      local pathToPT = "user_modules/shared_testcases/PolicyTables/TestingPolicyTable_OnVehicleData_23963.json"
      os.execute('cp ' .. config.pathToSDL .. 'sdl_preloaded_pt.json' .. ' ' .. pathToPT)
      
      
      local file = io.open(pathToPT, "r")
      local json_data = file:read("*all") -- may be abbreviated to "*a";
      file:close()
      local json = require("modules/json")		 
      local data = json.decode(json_data)
      
      for k,v in pairs(data.policy_table.functional_groupings) do
        if (data.policy_table.functional_groupings[k].rpcs == nil) then
          --do
          data.policy_table.functional_groupings[k] = nil
          
        else
          --do
          local count = 0
          for _ in pairs(data.policy_table.functional_groupings[k].rpcs) do count = count + 1 end
          if (count < 30) then
            --do
            data.policy_table.functional_groupings[k] = nil
            
          end
        end
      end
      
      
      data.policy_table.functional_groupings["Base-4"].rpcs.OnVehicleData = {}
      data.policy_table.functional_groupings["Base-4"].rpcs.OnVehicleData.hmi_levels = {"FULL", "LIMITED", "BACKGROUND"}
      data.policy_table.functional_groupings["Base-4"].rpcs.OnVehicleData.parameters = {}
      
      data.policy_table.app_policies.default.groups = {"Base-4"}		
      
      data = json.encode(data)
      
        --Replace {} by [] for "OnVehicleData":{"parameters":{}
        data = string.gsub(data, "{}", "[]")
        
        file = io.open(pathToPT, "w")
        file:write(data)
        file:close()
        
        return pathToPT
      end
      
      --Create PT
      local pathToPT = OnVehicleData_parameters_IsEmpty_CreatePT()
      
      
      local PermissionLines_ParametersIsEmpty = 
      [[				"OnVehicleData": {
        "hmi_levels": [
        "BACKGROUND",
        "FULL",
        "LIMITED"
        ],
        "parameters": []
      }]]
      local PermissionLinesForBase4 = PermissionLines_ParametersIsEmpty .. ", \n" 
      local PermissionLinesForGroup1 = nil
      local PermissionLinesForApplication = nil
      local PTName = testCasesForPolicyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLinesForGroup1, PermissionLinesForApplication, {"OnVehicleData"})	
      testCasesForPolicyTable:updatePolicy(PTName, nil, "UpdatePolicy_OnVehicleData_InBase4_WithEmptyParameters")
      
      
      
      
      
      Test["APPLINK_23963_OnVehicleData_InBase4_WithEmptyParameters_Disallowed"] = function(self)
        
        self:verify_Notification_IsIgnored_Case(OnVehicleData_Full_Notification)
        
      end
      
    end
    CRQ2_APPLINK_23963() --SDL defect APPLINK-26967
    
    
    ----------------------------------------------------------------------------------------------
    --CRQ #3: APPLINK-24180: [Policies] SendLocation with disallowed parameters by Policies only
    --DISALLOWED: OnVehicleData(only disallowed parameters)
    ----------------------------------------------------------------------------------------------	
    local function CRQ3_APPLINK_24180()
      
      --Print new line to separate in ATF log
      commonFunctions:newTestCasesGroup("CRQ APPLINK 24180")
      
      --Define local functions	
      local function OnVehicleData_parameters_disallows_some_parameters_CreatePT()
        
        local pathToPT = "user_modules/shared_testcases/PolicyTables/TestingPolicyTable_OnVehicleData_Allows_Some_Parameters_24180.json"
        os.execute('cp ' .. config.pathToSDL .. 'sdl_preloaded_pt.json' .. ' ' .. pathToPT)
        
        
        local file = io.open(pathToPT, "r")
        local json_data = file:read("*all") -- may be abbreviated to "*a";
        file:close()
        local json = require("modules/json")		 
        local data = json.decode(json_data)
        
        for k,v in pairs(data.policy_table.functional_groupings) do
          if (data.policy_table.functional_groupings[k].rpcs == nil) then
            --do
            data.policy_table.functional_groupings[k] = nil
            
          else
            --do
            local count = 0
            for _ in pairs(data.policy_table.functional_groupings[k].rpcs) do count = count + 1 end
            if (count < 30) then
              --do
              data.policy_table.functional_groupings[k] = nil
              
            end
          end
        end
        
        
        data.policy_table.functional_groupings["Base-4"].rpcs.OnVehicleData = {}
        data.policy_table.functional_groupings["Base-4"].rpcs.OnVehicleData.hmi_levels = {"FULL", "LIMITED", "BACKGROUND"}
        data.policy_table.functional_groupings["Base-4"].rpcs.OnVehicleData.parameters = {"gps", "speed", "rpm","fuelLevel", "fuelLevel_State"}
        data.policy_table.app_policies.default.groups = {"Base-4"}		
        
        data = json.encode(data)
        file = io.open(pathToPT, "w")
        file:write(data)
        file:close()
        
        return pathToPT
      end
      
      --Create PT
      local pathToPT = OnVehicleData_parameters_disallows_some_parameters_CreatePT()
      
      
      testCasesForPolicyTable:updatePolicy(pathToPT, nil, "APPLINK_24180_UpdatePolicy_OnVehicleData_InBase4_disallows_some_parameters")
      
      Test["APPLINK_24180_OnVehicleData_Only_Disallowed_Parameters_InBase4"] = function(self)
        
        commonTestCases:DelayedExp(1000)
        
        local OnVehicleData_Notification = {
          
          --Disallowed parameters
          instantFuelConsumption = 0.000000,
          externalTemperature = -40.000000,
          engineTorque = -1000.000000
        }
        
        --HMI sends notification
        self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", OnVehicleData_Notification)	 		
        
        --mobile side: expected notification
        EXPECT_NOTIFICATION("OnVehicleData", {})
        :Times(0)
        
      end
      
    end
    CRQ3_APPLINK_24180() --defect APPLINK-26968
    
    ----------------------------------------------------------------------------------------------
    --CRQ #7: APPLINK-24229 [Policies] SendLocation with allowed parameters by Policies only
    --ALLOWED: OnVehicleData(only allowed parameters)
    ----------------------------------------------------------------------------------------------	
    local function CRQ7_APPLINK_24229()
      
      --Print new line to separate in ATF log
      commonFunctions:newTestCasesGroup("CRQ APPLINK 24229")
      
      --Define local functions	
      local function OnVehicleData_parameters_allows_some_parameters_CreatePT()
        
        local pathToPT = "user_modules/shared_testcases/PolicyTables/TestingPolicyTable_OnVehicleData_Allows_Some_Parameters_24229.json"
        os.execute('cp ' .. config.pathToSDL .. 'sdl_preloaded_pt.json' .. ' ' .. pathToPT)
        
        
        local file = io.open(pathToPT, "r")
        local json_data = file:read("*all") -- may be abbreviated to "*a";
        file:close()
        local json = require("modules/json")		 
        local data = json.decode(json_data)
        
        for k,v in pairs(data.policy_table.functional_groupings) do
          if (data.policy_table.functional_groupings[k].rpcs == nil) then
            --do
            data.policy_table.functional_groupings[k] = nil
            
          else
            --do
            local count = 0
            for _ in pairs(data.policy_table.functional_groupings[k].rpcs) do count = count + 1 end
            if (count < 30) then
              --do
              data.policy_table.functional_groupings[k] = nil
              
            end
          end
        end
        
        
        data.policy_table.functional_groupings["Base-4"].rpcs.OnVehicleData = {}
        data.policy_table.functional_groupings["Base-4"].rpcs.OnVehicleData.hmi_levels = {"FULL", "LIMITED", "BACKGROUND"}
        data.policy_table.functional_groupings["Base-4"].rpcs.OnVehicleData.parameters = {"gps", "speed", "rpm","fuelLevel", "fuelLevel_State"}
        data.policy_table.app_policies.default.groups = {"Base-4"}		
        
        data = json.encode(data)
        file = io.open(pathToPT, "w")
        file:write(data)
        file:close()
        
        return pathToPT
      end
      
      --Create PT
      local pathToPT = OnVehicleData_parameters_allows_some_parameters_CreatePT()
      
      testCasesForPolicyTable:updatePolicy(pathToPT, nil, "APPLINK_24229_UpdatePolicy_OnVehicleData_InBase4_allows_some_parameters")
      
      Test["APPLINK_24229_OnVehicleData_Only_Allowed_Parameters_InBase4"] = function(self)
        
        local OnVehicleData_Notification = {
          
          --Allowed parameters:
          gps = 	{	longitudeDegrees = -180.0,
            latitudeDegrees = -90.0,
            pdop = 0.0,
            hdop = 0.0,
            vdop = 0.0,
            altitude = -10000.0,
            heading = 0.0,
            speed = 0.0,
            
            utcYear = 2010,
            utcMonth = 1,
            utcDay = 1,
            utcHours = 0,
            utcMinutes = 0,
            utcSeconds = 0,
            satellites = 0,
            
            compassDirection = "NORTH",
            dimension = "NO_FIX",
            actual = true
          },
          speed = 0.0,
          rpm = 0,
          fuelLevel = -6.000000,
          fuelLevel_State = "UNKNOWN"
        }
        
        --HMI sends notification
        self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", OnVehicleData_Notification)	 		
        
        --mobile side: expected notification
        EXPECT_NOTIFICATION("OnVehicleData", OnVehicleData_Notification)
        
      end
      
    end
    CRQ7_APPLINK_24229()
    
    
    ----------------------------------------------------------------------------------------------	
    --CRQ #4: APPLINK-24215 [Policies]: SendLocation with one OR more allowed parameters and one OR more disallowed parameters by Policies	
    --OnVehicleData - both allowed and disallowed parameters -> ALLOWED + DISALLOWED
    ----------------------------------------------------------------------------------------------	
    local function CRQ4_APPLINK_24215()
      
      --Print new line to separate in ATF log
      commonFunctions:newTestCasesGroup("CRQ APPLINK 24215")
      
      --Define local functions	
      local function OnVehicleData_parameters_allows_some_parameters_CreatePT()
        
        local pathToPT = "user_modules/shared_testcases/PolicyTables/TestingPolicyTable_OnVehicleData_Allows_Some_Parameters_24215.json"
        os.execute('cp ' .. config.pathToSDL .. 'sdl_preloaded_pt.json' .. ' ' .. pathToPT)
        
        
        local file = io.open(pathToPT, "r")
        local json_data = file:read("*all") -- may be abbreviated to "*a";
        file:close()
        local json = require("modules/json")		 
        local data = json.decode(json_data)
        
        for k,v in pairs(data.policy_table.functional_groupings) do
          if (data.policy_table.functional_groupings[k].rpcs == nil) then
            --do
            data.policy_table.functional_groupings[k] = nil
            
          else
            --do
            local count = 0
            for _ in pairs(data.policy_table.functional_groupings[k].rpcs) do count = count + 1 end
            if (count < 30) then
              --do
              data.policy_table.functional_groupings[k] = nil
              
            end
          end
        end
        
        
        data.policy_table.functional_groupings["Base-4"].rpcs.OnVehicleData = {}
        data.policy_table.functional_groupings["Base-4"].rpcs.OnVehicleData.hmi_levels = {"FULL", "LIMITED", "BACKGROUND"}
        data.policy_table.functional_groupings["Base-4"].rpcs.OnVehicleData.parameters = {"gps", "speed", "rpm","fuelLevel", "fuelLevel_State"}
        data.policy_table.app_policies.default.groups = {"Base-4"}		
        
        data = json.encode(data)
        file = io.open(pathToPT, "w")
        file:write(data)
        file:close()
        
        return pathToPT
      end
      
      --Create PT
      local pathToPT = OnVehicleData_parameters_allows_some_parameters_CreatePT()
      
      testCasesForPolicyTable:updatePolicy(pathToPT, nil, "APPLINK_24215_UpdatePolicy_OnVehicleData_InBase4_allows_some_parameters")
      
      Test["APPLINK_24215_OnVehicleData_Only_Allowed_Parameters_InBase4_And_Disallowed"] = function(self)
        
        local OnVehicleData_Notification = {
          
          --Allowed parameters:
          speed = 0.0,
          fuelLevel = -6.000000,
          
          --Disallowed parameters:
          instantFuelConsumption = 0.000000,
          externalTemperature = -40.000000
        }
        
        --HMI sends notification
        self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", OnVehicleData_Notification)	 		
        
        local OnVehicleData_ExpectedNotification = {
          
          --Allowed parameters:
          speed = 0.0,
          fuelLevel = -6.000000
        }
        
        --mobile side: expected notification
        EXPECT_NOTIFICATION("OnVehicleData", OnVehicleData_ExpectedNotification)
        :ValidIf (function(_,data)
          local result = true
          if data.payload.instantFuelConsumption then
            commonFunctions:printError(" SDL resends disallowed parameter 'instantFuelConsumption' to mobile app ")
            result = false	
          end
          
          if data.payload.externalTemperature then
            commonFunctions:printError(" SDL resends disallowed parameter 'externalTemperature' to mobile app ")
            result = false	
          end
          
          return result
          
        end)
        
      end
      
    end
    CRQ4_APPLINK_24215() --defect APPLINK-26968
    
    
    
    ----------------------------------------------------------------------------------------------	
    --CRQ #5: APPLINK-24224 [Policies] PoliciesManager must allow all requested parameters in case "parameters" field is omitted. 
    --It is not applied for OnVehicleData. For OnVehicleData, use CRQ #6: APPLINK-24225
    ----------------------------------------------------------------------------------------------
    
    ----------------------------------------------------------------------------------------------
    --CRQ #6: APPLINK-24225 [Policies] [OnVehicleData] PoliciesManager must allow all requested parameters in case "parameters" field is omitted
    --OnVehicleData - omitted parameters{} -> ALLOW
    ----------------------------------------------------------------------------------------------
    local function CRQ6_APPLINK_24225()
      
      --Print new line to separate in ATF log
      commonFunctions:newTestCasesGroup("CRQ APPLINK 24225")
      
      --Define local functions
      
      local function OnVehicleData_parameters_IsOmitted_CreatePT()
        
        local pathToPT = "user_modules/shared_testcases/PolicyTables/TestingPolicyTable_OnVehicleData_parameters_IsOmitted.json"
        os.execute('cp ' .. config.pathToSDL .. 'sdl_preloaded_pt.json' .. ' ' .. pathToPT)
        
        
        local file = io.open(pathToPT, "r")
        local json_data = file:read("*all") -- may be abbreviated to "*a";
        file:close()
        local json = require("modules/json")		 
        local data = json.decode(json_data)
        
        for k,v in pairs(data.policy_table.functional_groupings) do
          if (data.policy_table.functional_groupings[k].rpcs == nil) then
            --do
            data.policy_table.functional_groupings[k] = nil
            
          else
            --do
            local count = 0
            for _ in pairs(data.policy_table.functional_groupings[k].rpcs) do count = count + 1 end
            if (count < 30) then
              --do
              data.policy_table.functional_groupings[k] = nil
              
            end
          end
        end
        
        
        data.policy_table.functional_groupings["Base-4"].rpcs.OnVehicleData = {}
        data.policy_table.functional_groupings["Base-4"].rpcs.OnVehicleData.hmi_levels = {"FULL", "LIMITED", "BACKGROUND"}
        --data.policy_table.functional_groupings["Base-4"].rpcs.OnVehicleData.parameters = nil
        
        
        data.policy_table.app_policies.default.groups = {"Base-4"}		
        
        data = json.encode(data)
        file = io.open(pathToPT, "w")
        file:write(data)
        file:close()
        
        return pathToPT
      end
      
      --Create PT
      local pathToPT = OnVehicleData_parameters_IsOmitted_CreatePT()
      
      testCasesForPolicyTable:updatePolicy(pathToPT, nil, "APPLINK_24225_UpdatePolicy_OnVehicleData_InBase4_Omitted_Parameters")
      
      Test["APPLINK_24225_OnVehicleData_InBase4_omitted_parameters_Allowed"] = function(self)
        
        self:verify_SUCCESS_Notification_Case(OnVehicleData_Full_Notification, OnVehicleData_Full_Expected_Notification)
      end
      
    end
    CRQ6_APPLINK_24225()
    
    
    ----------------------------------------------------------------------------------------------
    --CRQ #8: APPLINK-25890 [Policies] Conditions for PoliciesManager to respond with USER_DISALLOWED
    --only parameters from disallowed function group -> USER_DISALLOWED
    ----------------------------------------------------------------------------------------------	
    
    
    local function CRQ8_APPLINK_25890()
      
      --Print new line to separate in ATF log
      commonFunctions:newTestCasesGroup("CRQ APPLINK 25890")
      
      local function precondition_create_PT()
        
        local PermissionLinesForBase4 = 
        [[		"OnVehicleData": {
          "hmi_levels": ["BACKGROUND", "FULL", "LIMITED"],
          "parameters": ["airbagStatus", "beltStatus", "driverBraking"]
        },]]
        
        local PermissionLines_AllowedForOnVehicleData = 
        [[			"OnVehicleData": {
          "hmi_levels": ["BACKGROUND", "FULL", "LIMITED"],
          "parameters": ["speed", "rpm","fuelLevel", "fuelLevel_State", "driverBraking"]
        }]]
        
        
        local PermissionLinesForApp1=[[			"]].."0000001" ..[[":{
          "keep_context": true,
          "steal_focus": true,
          "priority": "NONE",
          "default_hmi": "BACKGROUND",
          "groups": ["group1","Base-4"]
        },]]	
        
        local PermissionLinesForSendLocation = PermissionLines_AllowedForOnVehicleData
        local PermissionLinesForApplication = PermissionLinesForApp1
        local RemovedOtherRPCsInPT = {"OnVehicleData"}
        local PTName = testCasesForPolicyTable:createPolicyTableFile(PermissionLinesForBase4, PermissionLines_AllowedForOnVehicleData, PermissionLinesForApplication, RemovedOtherRPCsInPT)	
        
        return PTName
        
      end
      
      local PTName = precondition_create_PT()
      
      testCasesForPolicyTable:updatePolicy(PTName, nil, "APPLINK_25890_UpdatePolicy_OnVehicleData_In_group1_CreatePT")
      
      --Case 1: User_Has_Not_Consented_Yet
      Test["APPLINK_25890_OnVehicleData_in_group1_User_Has_Not_Consented_Yet"] = function(self)
        
        commonTestCases:DelayedExp(1000)
        
        local OnVehicleData_Notification = {
          
          --parameters in function group that has not been consented yet.
          speed = 0.0,
          fuelLevel = -6.000000
        }
        
        self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", OnVehicleData_Notification)	 		
        
        --mobile side: does not receive notification
        EXPECT_NOTIFICATION("OnVehicleData", {})	
        :Times(0)
        
      end
      
      --OnVehicleData(parameters are in consent group1 + parameters are in base-4)
      Test["APPLINK_25890_OnVehicleData_parameters_in_Not_Consented_Yet_group1_And_parameters_in_Base_4"] = function(self)
        
        local OnVehicleData_Notification = {
          
          --parameters in function group that has not been consented yet.
          speed = 0.0,
          fuelLevel = -6.000000,
          
          --Allowed in base-4
          airbagStatus = {
            driverAirbagDeployed = "YES",
            driverSideAirbagDeployed = "YES",
            driverCurtainAirbagDeployed = "YES",
            passengerAirbagDeployed = "YES",
            passengerCurtainAirbagDeployed = "YES",			
            driverKneeAirbagDeployed = "YES",
            passengerSideAirbagDeployed = "YES",
            passengerKneeAirbagDeployed = "YES"
          }, 
          beltStatus = {
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
            middleRow1BuckleBelted = "NO_EVENT"
          },
          driverBraking = "NO_EVENT"
        }
        
        self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", OnVehicleData_Notification)	 		
        
        
        local OnVehicleData_ExpectedNotification = {
          
          --Allowed in base-4
          airbagStatus = {
            driverAirbagDeployed = "YES",
            driverSideAirbagDeployed = "YES",
            driverCurtainAirbagDeployed = "YES",
            passengerAirbagDeployed = "YES",
            passengerCurtainAirbagDeployed = "YES",			
            driverKneeAirbagDeployed = "YES",
            passengerSideAirbagDeployed = "YES",
            passengerKneeAirbagDeployed = "YES"
          }, 
          beltStatus = {
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
            middleRow1BuckleBelted = "NO_EVENT"
          },
          driverBraking = "NO_EVENT"
        }
        
        --mobile side: does not receive notification			
        EXPECT_NOTIFICATION("OnVehicleData", OnVehicleData_ExpectedNotification)	
        :ValidIf (function(_,data)
          local result = true
          if data.payload.speed then
            commonFunctions:printError(" SDL resends disallowed parameter 'speed' to mobile app ")
            result = false	
          end
          if data.payload.fuelLevel then
            commonFunctions:printError(" SDL resends disallowed parameter 'fuelLevel' to mobile app ")
            result = false	
          end
          return result
        end)
        
      end
      
      
      --OnVehicleData(parameters are in consent group1 + parameters are in base-4 + parameters are not in base-4)
      Test["APPLINK_25890_OnVehicleData_parameters_in_Not_Consented_Yet_group1_And_parameters_in_Base_4_And_parameters_not_in_Base_4"] = function(self)
        
        local OnVehicleData_Notification = {
          
          --parameters in function group that has not been consented yet.
          speed = 0.0,
          fuelLevel = -6.000000,
          
          --Allowed in base-4
          airbagStatus = {
            driverAirbagDeployed = "YES",
            driverSideAirbagDeployed = "YES",
            driverCurtainAirbagDeployed = "YES",
            passengerAirbagDeployed = "YES",
            passengerCurtainAirbagDeployed = "YES",			
            driverKneeAirbagDeployed = "YES",
            passengerSideAirbagDeployed = "YES",
            passengerKneeAirbagDeployed = "YES"
          }, 
          beltStatus = {
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
            middleRow1BuckleBelted = "NO_EVENT"
          },
          driverBraking = "NO_EVENT",
          
          --parameters are not in base-4
          tpms = "UNKNOWN",
          turnSignal = "OFF"				
        }
        
        self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", OnVehicleData_Notification)	 		
        
        
        local OnVehicleData_ExpectedNotification = {}
        OnVehicleData_ExpectedNotification.airbagStatus = OnVehicleData_Notification.airbagStatus
        OnVehicleData_ExpectedNotification.beltStatus = OnVehicleData_Notification.beltStatus
        OnVehicleData_ExpectedNotification.driverBraking = OnVehicleData_Notification.driverBraking
        
        --mobile side: does not receive notification			
        EXPECT_NOTIFICATION("OnVehicleData", OnVehicleData_ExpectedNotification)	
        :ValidIf (function(_,data)
          local result = true
          if data.payload.speed then
            commonFunctions:printError(" SDL resends disallowed parameter 'speed' to mobile app ")
            result = false	
          end
          if data.payload.fuelLevel then
            commonFunctions:printError(" SDL resends disallowed parameter 'fuelLevel' to mobile app ")
            result = false	
          end
          if data.payload.tpms then
            commonFunctions:printError(" SDL resends disallowed parameter 'tpms' to mobile app ")
            result = false	
          end
          if data.payload.turnSignal then
            commonFunctions:printError(" SDL resends disallowed parameter 'turnSignal' to mobile app ")
            result = false	
          end
          
          return result
        end)
        
      end
      
      --OnVehicleData(parameters are in base-4 only)
      Test["APPLINK_25890_OnVehicleData_Not_Consented_Yet_group1_And_parameters_in_Base_4"] = function(self)
        
        local OnVehicleData_Notification = {
          
          --Allowed in base-4
          airbagStatus = {
            driverAirbagDeployed = "YES",
            driverSideAirbagDeployed = "YES",
            driverCurtainAirbagDeployed = "YES",
            passengerAirbagDeployed = "YES",
            passengerCurtainAirbagDeployed = "YES",			
            driverKneeAirbagDeployed = "YES",
            passengerSideAirbagDeployed = "YES",
            passengerKneeAirbagDeployed = "YES"
          }, 
          beltStatus = {
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
            middleRow1BuckleBelted = "NO_EVENT"
          },
          driverBraking = "NO_EVENT"
        }
        
        self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", OnVehicleData_Notification)	 		
        
        
        --mobile side: does not receive notification			
        EXPECT_NOTIFICATION("OnVehicleData", OnVehicleData_Notification)	
        
      end
      
      
      --Case 2: User disallowed
      testCasesForPolicyTable:userConsent(false, "group1", "APPLINK_25890_UserConsent_Answer_No")		
      
      Test["APPLINK_25890_OnVehicleData_in_group1_User_Disallowed"] = function(self)
        
        
        commonTestCases:DelayedExp(1000)
        
        local OnVehicleData_Notification = {
          
          --parameters in disallowed function group
          speed = 0.0,
          fuelLevel = -6.000000
        }
        
        self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", OnVehicleData_Notification)	 		
        
        --mobile side: does not receive notification
        EXPECT_NOTIFICATION("OnVehicleData", {})	
        :Times(0)
        
      end
      
      
      Test["APPLINK_25890_OnVehicleData_in_group1_User_Disallowed_And_Base_4"] = function(self)
        
        commonTestCases:DelayedExp(1000)
        
        local OnVehicleData_Notification = {
          
          --parameters in disallowed function group
          speed = 0.0,
          fuelLevel = -6.000000,
          
          --Allowed in base-4
          airbagStatus = {
            driverAirbagDeployed = "YES",
            driverSideAirbagDeployed = "YES",
            driverCurtainAirbagDeployed = "YES",
            passengerAirbagDeployed = "YES",
            passengerCurtainAirbagDeployed = "YES",			
            driverKneeAirbagDeployed = "YES",
            passengerSideAirbagDeployed = "YES",
            passengerKneeAirbagDeployed = "YES"
          }, 
          beltStatus = {
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
            middleRow1BuckleBelted = "NO_EVENT"
          },
          driverBraking = "NO_EVENT"
        }
        
        self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", OnVehicleData_Notification)	 		
        
        
        local OnVehicleData_ExpectedNotification = {}
        --Allowed in base-4
        OnVehicleData_ExpectedNotification.airbagStatus = OnVehicleData_Notification.airbagStatus
        OnVehicleData_ExpectedNotification.beltStatus = OnVehicleData_Notification.beltStatus
        OnVehicleData_ExpectedNotification.driverBraking = OnVehicleData_Notification.driverBraking
        
        
        --mobile side: does not receive notification			
        EXPECT_NOTIFICATION("OnVehicleData", OnVehicleData_ExpectedNotification)	
        :ValidIf (function(_,data)
          local result = true
          if data.payload.speed then
            commonFunctions:printError(" SDL resends disallowed parameter 'speed' to mobile app ")
            result = false	
          end
          if data.payload.fuelLevel then
            commonFunctions:printError(" SDL resends disallowed parameter 'fuelLevel' to mobile app ")
            result = false	
          end
          return result
        end)
        
      end
      
      Test["APPLINK_25890_OnVehicleData_in_group1_User_Disallowed_And_Not_in_Base_4"] = function(self)
        
        
        commonTestCases:DelayedExp(1000)
        
        local OnVehicleData_Notification = {
          
          --parameters in disallowed function group
          speed = 0.0,
          fuelLevel = -6.000000,
          
          --parameters are not in base-4
          tpms = "UNKNOWN",
          turnSignal = "OFF"				
          
        }
        
        self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", OnVehicleData_Notification)	 		
        
        --mobile side: does not receive notification
        EXPECT_NOTIFICATION("OnVehicleData", {})	
        :Times(0)
        
      end
      
      
      Test["APPLINK_25890_OnVehicleData_in_group1_User_Disallowed_And_Base_4_And_not_in_Base_4"] = function(self)
        
        commonTestCases:DelayedExp(1000)
        
        local OnVehicleData_Notification = {
          
          --parameters in disallowed function group
          speed = 0.0,
          fuelLevel = -6.000000,
          
          --Allowed in base-4
          airbagStatus = {
            driverAirbagDeployed = "YES",
            driverSideAirbagDeployed = "YES",
            driverCurtainAirbagDeployed = "YES",
            passengerAirbagDeployed = "YES",
            passengerCurtainAirbagDeployed = "YES",			
            driverKneeAirbagDeployed = "YES",
            passengerSideAirbagDeployed = "YES",
            passengerKneeAirbagDeployed = "YES"
          }, 
          beltStatus = {
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
            middleRow1BuckleBelted = "NO_EVENT"
          },
          driverBraking = "NO_EVENT",
          
          --parameters are not in base-4
          tpms = "UNKNOWN",
          turnSignal = "OFF"					
        }
        
        self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", OnVehicleData_Notification)	 		
        
        
        local OnVehicleData_ExpectedNotification = {}
        --Allowed in base-4
        OnVehicleData_ExpectedNotification.airbagStatus = OnVehicleData_Notification.airbagStatus
        OnVehicleData_ExpectedNotification.beltStatus = OnVehicleData_Notification.beltStatus
        OnVehicleData_ExpectedNotification.driverBraking = OnVehicleData_Notification.driverBraking
        
        --mobile side: does not receive notification			
        EXPECT_NOTIFICATION("OnVehicleData", OnVehicleData_ExpectedNotification)	
        :ValidIf (function(_,data)
          local result = true
          if data.payload.speed then
            commonFunctions:printError(" SDL resends disallowed parameter 'speed' to mobile app ")
            result = false	
          end
          if data.payload.fuelLevel then
            commonFunctions:printError(" SDL resends disallowed parameter 'fuelLevel' to mobile app ")
            result = false	
          end
          if data.payload.tpms then
            commonFunctions:printError(" SDL resends disallowed parameter 'tpms' to mobile app ")
            result = false	
          end
          if data.payload.turnSignal then
            commonFunctions:printError(" SDL resends disallowed parameter 'turnSignal' to mobile app ")
            result = false	
          end				
          return result
        end)
        
      end
      
      Test["APPLINK_25890_OnVehicleData_only_parameters_in_base_4_User_Disallowed_group1"] = function(self)
        
        commonTestCases:DelayedExp(1000)
        
        local OnVehicleData_Notification = {
          
          
          --Allowed in base-4
          airbagStatus = {
            driverAirbagDeployed = "YES",
            driverSideAirbagDeployed = "YES",
            driverCurtainAirbagDeployed = "YES",
            passengerAirbagDeployed = "YES",
            passengerCurtainAirbagDeployed = "YES",			
            driverKneeAirbagDeployed = "YES",
            passengerSideAirbagDeployed = "YES",
            passengerKneeAirbagDeployed = "YES"
          }, 
          beltStatus = {
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
            middleRow1BuckleBelted = "NO_EVENT"
          },
          driverBraking = "NO_EVENT"
        }
        
        self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", OnVehicleData_Notification)	
        --mobile side: does not receive notification			
        EXPECT_NOTIFICATION("OnVehicleData", OnVehicleData_Notification)	
        
      end
      
      
    end
    
    CRQ8_APPLINK_25890()
    
    ----------------------------------------------------------------------------------------------	
    --CRQ #9: APPLINK-25891 [Policies]: SendLocation with one OR more allowed parameters and one OR more disallowed parameters by user
    -- OnVehicleData(some parameters from disallowed function group + some parameters is not allowed by PT)-> USER_DISALLOWED
    ----------------------------------------------------------------------------------------------
    --Precondition: CRQ8_APPLINK_25890 was succeeded. 
    local function CRQ9_APPLINK_25891()
      
      --Print new line to separate Preconditions
      commonFunctions:newTestCasesGroup("APPLINK_25891")
      
      --Precondition: CRQ8_APPLINK_25890 was succeeded. 
      Test["APPLINK_25891_OnVehicleData_some_parameters_disallowed_by_user_some_parameters_disallowed_by_PT"] = function(self)
        
        
        commonTestCases:DelayedExp(1000)
        local OnVehicleData_Notification = {
          
          --Allowed parameters in group1 but group1 is disallowed by user.
          speed = 0.0,
          fuelLevel = -6.000000,
          
          --Disallowed parameters by PT
          wiperStatus = "OFF",
          odometer = 0
        }
        
        self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", OnVehicleData_Notification)	 		
        
        --mobile side: does not receive notification
        EXPECT_NOTIFICATION("OnVehicleData", {})	
        :Times(0)
      end
    end
    
    CRQ9_APPLINK_25891()	
    
    
    --only user allowed parameters in consented group
    local function Additional_Case()
      
      --Print new line to separate in ATF log
      commonFunctions:newTestCasesGroup("Additional case: User allows function group")
      
      testCasesForPolicyTable:userConsent(true, "group1", "UserConsent_Answer_YES")
      
      Test["APPLINK_25890_OnVehicleData_in_group1_User_Allowed"] = function(self)
        commonTestCases:DelayedExp(1000)
        
        local OnVehicleData_Notification = {
          --Allowed parameters:
          speed = 0.0,
          fuelLevel = -6.000000
        }
        
        self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", OnVehicleData_Notification)	 		
        
        --mobile side: receives notification
        EXPECT_NOTIFICATION("OnVehicleData", OnVehicleData_Notification)
      end
    end
    Additional_Case()
    
    --allowed parameters in consented group + allowed parameters by PT
    Test["Allowed_Parameters_In_Consent_Group_And_Allowed_Parameters_In_Base_4"] = function(self)
      
      local OnVehicleData_Notification = {
        
        --Allowed parameters in Base-4 group
        airbagStatus = {
          driverAirbagDeployed = "YES",
          driverSideAirbagDeployed = "YES",
          driverCurtainAirbagDeployed = "YES",
          passengerAirbagDeployed = "YES",
          passengerCurtainAirbagDeployed = "YES",			
          driverKneeAirbagDeployed = "YES",
          passengerSideAirbagDeployed = "YES",
          passengerKneeAirbagDeployed = "YES"
        }, 
        beltStatus = {
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
          middleRow1BuckleBelted = "NO_EVENT"
        },
        driverBraking = "NO_EVENT",
        
        --Allowed parameters in consented group1
        speed = 0.0,
        fuelLevel = -6.000000
      }
      
      self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", OnVehicleData_Notification)	 		
      
      --mobile side: receives notification
      EXPECT_NOTIFICATION("OnVehicleData", OnVehicleData_Notification)	
    end
    
    
    --allowed parameters in consented group + disallowed parameters by PT: --defect APPLINK-26968
    Test["Allowed_Parameters_In_Consent_Group_And_Disallowed_Parameters_In_Base_4"] = function(self)
      
      local OnVehicleData_Notification = {
        --Disallowed parameters in PT(Base-4 group)
        instantFuelConsumption = 0.000000,
        externalTemperature = -40.000000,
        
        --Allowed parameters in consented group1
        speed = 0.0,
        fuelLevel = -6.000000,
        driverBraking = "NO_EVENT"
      }
      self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", OnVehicleData_Notification)	
      local OnVehicleData_Notification = {
        
        --Allowed parameters in consented group1
        speed = 0.0,
        fuelLevel = -6.000000,
        driverBraking = "NO_EVENT"
      }		
      --mobile side: receives notification
      EXPECT_NOTIFICATION("OnVehicleData", OnVehicleData_Notification)
      :ValidIf (function(_,data)
        local result = true
        if data.payload.instantFuelConsumption then
          commonFunctions:printError(" SDL resends disallowed parameter 'instantFuelConsumption' to mobile app ")
          result = false	
        end
        if data.payload.externalTemperature then
          commonFunctions:printError(" SDL resends disallowed parameter 'externalTemperature' to mobile app ")
          result = false	
        end
        return result
      end)
    end
    
    
    --allow group 1 + allowed base-4 + disallowed base-4
    Test["Allowed_Parameters_In_Consent_Group_And_Allowed_Parameters_In_Base_4_Disallowed"] = function(self)
      
      local OnVehicleData_Notification = {
        
        --Allowed parameters in Base-4 group
        airbagStatus = {
          driverAirbagDeployed = "YES",
          driverSideAirbagDeployed = "YES",
          driverCurtainAirbagDeployed = "YES",
          passengerAirbagDeployed = "YES",
          passengerCurtainAirbagDeployed = "YES",			
          driverKneeAirbagDeployed = "YES",
          passengerSideAirbagDeployed = "YES",
          passengerKneeAirbagDeployed = "YES"
        }, 
        beltStatus = {
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
          middleRow1BuckleBelted = "NO_EVENT"
        },
        driverBraking = "NO_EVENT",
        
        
        --Disallowed parameters in PT(Base-4 group)
        instantFuelConsumption = 0.000000,
        externalTemperature = -40.000000,
        
        --Allowed parameters in consented group1
        speed = 0.0,
        fuelLevel = -6.000000,			
      }
      
      self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", OnVehicleData_Notification)	 		
      
      --mobile side: receives notification
      EXPECT_NOTIFICATION("OnVehicleData", OnVehicleData_Notification)	
      :ValidIf (function(_,data)
        local result = true
        if data.payload.instantFuelConsumption then
          commonFunctions:printError(" SDL resends disallowed parameter 'instantFuelConsumption' to mobile app ")
          result = false	
        end
        if data.payload.externalTemperature then
          commonFunctions:printError(" SDL resends disallowed parameter 'externalTemperature' to mobile app ")
          result = false	
        end
        return result
      end)
    end	
  end	
  
  Test_Block_VIII()
  
  
  ---------------------------------------------------------------------------------------------
  -------------------------------------------Postcondition-------------------------------------
  ---------------------------------------------------------------------------------------------
  
  --Print new line to separate Postconditions
  commonFunctions:newTestCasesGroup("Postconditions")
  testCasesForPolicyTable:Restore_preloaded_pt()
  Test["Stop_SDL"] = function(self)
    StopSDL()
  end