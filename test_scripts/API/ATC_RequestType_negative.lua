-- --------------------------------------------------------------------------------
-- Kill SDL if PID is exist.
os.execute("ps aux | grep -e smartDeviceLinkCore | awk '{print$2}'")
os.execute("kill -9 $(ps aux | grep -e smartDeviceLinkCore | awk '{print$2}')")
-- --------------------------------------------------------------------------------

local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
commonPreconditions:Connecttest_without_ExitBySDLDisconnect("connecttest_RequestType.lua")

Test = require('user_modules/connecttest_RequestType')
require('cardinalities')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
require('user_modules/AppTypes')


--local mobile_session = require('mobile_session')
--local tcp = require('tcp_connection')
--local file_connection  = require('file_connection')
--local mobile  = require('mobile_connection')

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

local odometerValue = 0
local exchange_after_x_kilometers = 0
local requestTypeEnum = {"HTTP", "FILE_RESUME", "AUTH_REQUEST", "AUTH_CHALLENGE", 
  "AUTH_ACK", "PROPRIETARY", "QUERY_APPS", "LAUNCH_APP", "LOCK_SCREEN_ICON_URL", 
  "TRAFFIC_MESSAGE_CHANNEL", "DRIVER_PROFILE", "VOICE_SEARCH", "NAVIGATION", 
  "PHONE", "CLIMATE", "SETTINGS", "VEHICLE_DIAGNOSTICS", "EMERGENCY", "MEDIA", "FOTA"}

local temp = {}
for k,v in pairs(requestTypeEnum) do
  if v ~= "PROPRIETARY" and v ~= "QUERY_APPS" and v ~= "LAUNCH_APP" then
	  --do
	  temp[k] = requestTypeEnum[k]
  end
end

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
local applicationRegisterParams = 
  {
    syncMsgVersion =
    {
      majorVersion = 3,
      minorVersion = 0
    },
    appName = "App1",
    isMediaApplication = true,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appID = "App1",
    deviceInfo =
    {
      os = "Android",
      carrier = "Megafon",
      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
      osVersion = "4.4.2",
      maxNumberRFCOMMPorts = 1
    }
  }


local function userPrint( color, message)
  print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
end


function Test:makeDeviceUntrusted()
  -- body

  userPrint(35, "================= Precondition ==================")

  -- hmi side: Send SDL.OnAllowSDLFunctionality
  self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
    { device = {
        name = "127.0.0.1",
        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
      }, 
      allowed = false,
      source = "GUI" })
end

function Test:ptu()

  userPrint(35, "================= Precondition ==================")

  -- hmi side: Send SDL.OnAllowSDLFunctionality
  self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
    { device = {
        name = "127.0.0.1",
        id = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
      }, 
      allowed = true,
      source = "GUI" })

  -- hmi side: sending SDL.ActivateApp request
  -- local updateSdlId = self.hmiConnection:SendRequest("SDL.UpdateSDL",{})

  -- hmi side: expect SDL.ActivateApp response
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function(_,data)
    local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
    --hmi side: expect SDL.GetURLS response from HMI
    EXPECT_HMIRESPONSE(RequestIdGetURLS)
    :Do(function(_,data)
      --hmi side: sending BasicCommunication.OnSystemRequest request to SDL
      --urlOfCloud = tostring(data.result.urls[1].url)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        {
          requestType = "PROPRIETARY",
          fileName = "filename",
          -- url = urlOfCloud
        }
      )

      EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function(_,data)
        --mobile side: sending SystemRequest request 
        local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
          {
            fileName = "PolicyTableUpdate",
            requestType = "PROPRIETARY"
          }, "/tmp/ptu_update.json")
        
        local systemRequestId
        --hmi side: expect SystemRequest request
        EXPECT_HMICALL("BasicCommunication.SystemRequest")
        :Do(function(_,data)
          systemRequestId = data.id
          
          --hmi side: sending BasicCommunication.OnSystemRequest request to SDL
          self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
            {
              policyfile = "/tmp/ptu_update.json"
            }
          )
          
          function to_run()
            --hmi side: sending SystemRequest response
            self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
          end
          
          RUN_AFTER(to_run, 500)
          EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"})
        end)
      end)
    end)
  end)
end

function Test:unregisterApp( ... )
  userPrint(35, "================= Precondition ==================")
  --mobile side: UnregisterAppInterface request 
  local CorIdUAI = self.mobileSession:SendRPC("UnregisterAppInterface",{}) 

  --hmi side: expect OnAppUnregistered notification 
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.applications[applicationRegisterParams.appName], unexpectedDisconnect = false})
 

  --mobile side: UnregisterAppInterface response 
  EXPECT_RESPONSE(CorIdUAI, { success = true, resultCode = "SUCCESS"})
  :Timeout(2000)
end

function Test:checkOnAppRegistered(params)
  -- body

  userPrint(34, "=================== Test Case ===================")

  local registerAppInterfaceID = self.mobileSession:SendRPC("RegisterAppInterface", applicationRegisterParams)

  -- hmi side: SDL notifies HMI about registered App
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {
    application = {
      appName = applicationRegisterParams.appName,
      requestType = params
    }})

  EXPECT_RESPONSE(registerAppInterfaceID, { success = true, resultCode = "SUCCESS"})
  :Timeout(2000)

  EXPECT_NOTIFICATION("OnAppInterfaceUnregistered")
  :Times(0)
  :ValidIf(function(exp, data)
    if 
      exp.occurences == 1 then
        self:FailTestCase("UnexpectedDisconnect")
    end
  end)
end

function Test:checkRequestTypeInSystemRequest(request_type)
  userPrint(34, "=================== Test Case ===================")
    local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
        {
          fileName = "PolicyTableUpdate",
          requestType = request_type
        },
      "files/jsons/QUERY_APP/query_app_response.json")

    local systemRequestId
    --hmi side: expect SystemRequest request
    if request_type ~= "QUERY_APPS" and request_type ~= "LAUNCH_APP" then
      EXPECT_HMICALL("BasicCommunication.SystemRequest")
      :ValidIf(function (self, data)
            -- body
            if data.params.requestType == request_type then
              return true
            else
              return false
            end
      end)
      :Do(function(_,data)
            --hmi side: sending SystemRequest response
          self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
      end)
    end
    if request_type ~= "QUERY_APPS" and request_type ~= "LAUNCH_APP" then
      EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})        
      :Timeout(5000)
    else
      if request_type == "LAUNCH_APP" then
        userPrint(40, "open question \"What response should be for requstType LAUNCH_APP if SDL4.0 is ommited in implementation\",\nassumption is DISALLOWED result code")
        EXPECT_RESPONSE(CorIdSystemRequest, { success = false, resultCode = "DISALLOWED"})        
        :Timeout(5000)
      else
        -- according to CRQ "SDL behaviour in case SDL 4.0 feature is required to be ommited in implementation"
        EXPECT_RESPONSE(CorIdSystemRequest, { success = false, resultCode = "UNSUPPORTED_RESOURCE"})        
        :Timeout(5000)
      end
    end
end

function Test:convertPreloadedToJson()
  -- body
  -- Create PTU from sdl_preloaded_pt.json
  pathToFile = config.pathToSDL .. "sdl_preloaded_pt.json"
  local file  = io.open(pathToFile, "r")
  local json_data = file:read("*all") -- may be abbreviated to "*a";
  file:close()

  local json = require("json")
   
  local data = json.decode(json_data)

  local function has_value (tab, val)
    for index, value in ipairs (tab) do
        if value == val then
            return true
        end
    end

    return false
  end

  for k,v in pairs(data.policy_table.functional_groupings) do
    if  has_value(data.policy_table.app_policies.default.groups, k) or 
        has_value(data.policy_table.app_policies.pre_DataConsent.groups, k) then 
    else 
      data.policy_table.functional_groupings[k] = nil 
    end
  end

  return data
end

function Test:checkRequestTypeInSystemRequestIsDisallowed(request_type)
  userPrint(34, "=================== Test Case ===================")
  local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
	  {
		fileName = "PolicyTableUpdate",
		requestType = request_type
	  },
	"files/jsons/QUERY_APP/query_app_response.json")

  local systemRequestId
  --hmi side: expect SystemRequest request
  EXPECT_HMICALL("BasicCommunication.SystemRequest")
  :Times(0)

  EXPECT_RESPONSE(CorIdSystemRequest, { success = false, resultCode = "DISALLOWED"})        
  :Timeout(5000)
end



---------------------------------------------------------------------------------------------
-------------------------------------------PreConditions-------------------------------------
---------------------------------------------------------------------------------------------

commonSteps:DeleteLogsFileAndPolicyTable()

function Test:GetExchangeAfterXKilometers( ... )
  -- body
  local commandToExecute = "sqlite3 " .. config.pathToSDL .. "/storage/policy.sqlite 'select exchange_after_x_kilometers from module_config;'"
  local f = assert(io.popen(commandToExecute, 'r'))
  local s = assert(f:read('*a'))
  f:close()
  exchange_after_x_kilometers = tonumber(tostring(s))
end


---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------

-- Req1: APPLINK-14724 [Policies]: SDL behavior in case PTU comes with empty "RequestType" field of <default> or <pre_DataConsent> section
-- In case
--		PTU with "<default>" or "<pre_DataConsent>" policies comes
-- 		and "RequestType" array is empty
-- PoliciesManager must:
-- 		leave "RequestType" as empty array
-- 		allow any request type for such app. 

local function Req1_APPLINK_14724_Case1_default_RequestType_empty()

	function Test:CreatePTUEmptyRequestTypeDefault(...)
	  -- body
	  -- Create PTU from sdl_preloaded_pt.json
	  local data = self:convertPreloadedToJson()

	  -- data.policy_table.app_policies.default.RequestType = {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"}
	  data.policy_table.app_policies.default.RequestType = {}
	  data.policy_table.app_policies.device.RequestType = {"PROPRIETARY"}
	  data.policy_table.app_policies.pre_DataConsent.RequestType = {"PROPRIETARY"}
	  data.policy_table.app_policies[applicationRegisterParams.appName] = "default"

	  local json = require("json")
	  data = json.encode(data)
	  file = io.open("/tmp/ptu_update.json", "w")
	  file:write(data)
	  file:close()

	end
	function Test:PrecondMakeDeviceUntrusted()
	  self:makeDeviceUntrusted()
	end

	function Test:PrecondPTU()
	  self:ptu()
	  EXPECT_NOTIFICATION("OnPermissionsChange")
	end

	function Test:PrecondExitApp1()
	  self:unregisterApp()
	end

	function Test:CheckOnAppRegisteredHasEmptyRequestType( ... )
	  self:checkOnAppRegistered({})
	end


	for k, v in pairs( requestTypeEnum ) do
	  Test["CheckRequestTypeTC1_" .. v] = function(self)
		self:checkRequestTypeInSystemRequest(v)
	  end
	end


end

local function Req1_APPLINK_14724_Case2_pre_DataConsent_RequestType_empty()


	function Test:CreatePTUEmptyRequestTypePreData(...)
	  -- body
	  userPrint(35, "================= Precondition ==================")

	  -- Create PTU from sdl_preloaded_pt.json
	  local data = self:convertPreloadedToJson()

	  data.policy_table.app_policies.default.RequestType = {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"}
	  -- data.policy_table.app_policies.default.RequestType = {}
	  data.policy_table.app_policies.device.RequestType = {"PROPRIETARY"}
	  data.policy_table.app_policies.pre_DataConsent.RequestType = {}
	  data.policy_table.app_policies[applicationRegisterParams.appName] = "default"

	  local json = require("json")
	  data = json.encode(data)
	  file = io.open("/tmp/ptu_update.json", "w")
	  file:write(data)
	  file:close()
	  
	  --debug
	  file_debug = io.open("/tmp/ptu_update_tc2.json", "w")
	  file_debug:write(data)
	  file_debug:close()

	end

	function Test:PrecondMakeDeviceUntrusted1( ... )
	  self:makeDeviceUntrusted()
	end

	function Test:TriggerPTU( ... )
	  -- body
	  userPrint(35, "================= Precondition ==================")

	  odometerValue = odometerValue + exchange_after_x_kilometers + 1
	  self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", { odometer = odometerValue})
	  self:ptu()
	  EXPECT_NOTIFICATION("OnPermissionsChange")
	end

	function Test:PrecondExitAppPreData()
	  self:unregisterApp()
	end

	function Test:PrecondMakeDeviceUnTrusted2( ... )
	  self:makeDeviceUntrusted()
	end

	function Test:CheckOnAppRegisteredHasEmptyRequestTypePreData( ... )
	  self:checkOnAppRegistered({})
	end


	for k, v in pairs( requestTypeEnum ) do
	  Test["CheckRequestTypeTC2_" .. v] = function(self)
		self:checkRequestTypeInSystemRequest(v)
	  end
	end

end

--Print new line to separate Preconditions
commonFunctions:newTestCasesGroup("Req1_APPLINK_14724_Case1_default_RequestType_empty")
Req1_APPLINK_14724_Case1_default_RequestType_empty()

--Print new line to separate Preconditions
commonFunctions:newTestCasesGroup("Req1_APPLINK_14724_Case2_pre_DataConsent_RequestType_empty")
Req1_APPLINK_14724_Case2_pre_DataConsent_RequestType_empty()

---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------

-- Req2: APPLINK-14723 [Policies]: SDL behavior in case PTU comes with omitted "RequestType" field of <default> or <pre_DataConsent> section
-- In case
-- 		PTU with "<default>" or "<pre_DataConsent>" policies comes
-- 		and "RequestType" array is omitted at all
-- PoliciesManager must:
-- 		assign "RequestType" field from "<default>" or "<pre_DataConsent>" section of PolicyDataBase to such app 

local function Req2_APPLINK_14723_Case1_default_RequestType_omitted()

	--Precondition: Update PT with default.RequestType = {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"}
	function Test:CreatePTUValidRequestTypeDefault(...)
	  userPrint(35, "================= Precondition ==================")
	  -- body
	  -- Create PTU from sdl_preloaded_pt.json
	  local data = self:convertPreloadedToJson()

	  data.policy_table.app_policies.default.RequestType = {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"}
	  data.policy_table.app_policies.device.RequestType = {"PROPRIETARY"}
	  data.policy_table.app_policies.pre_DataConsent.RequestType = {"PROPRIETARY"}
	  data.policy_table.app_policies[applicationRegisterParams.appName] = "default"

	  local json = require("json")
	  data = json.encode(data)

	  file = io.open("/tmp/ptu_update.json", "w")
	  file:write(data)
	  file:close()

	end

	function Test:TriggerPTUForOmmitedRequestType( ... )
	  -- body
	  userPrint(35, "================= Precondition ==================")

	  odometerValue = odometerValue + exchange_after_x_kilometers + 1
	  self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", { odometer = odometerValue})
	  self:ptu()
	  EXPECT_NOTIFICATION("OnPermissionsChange")
	end

	function Test:PrecondExitAppPreData()
	  self:unregisterApp()
	end

	function Test:CheckOnAppRegisteredHasDeafultRequestTypeTC3()
	  self:checkOnAppRegistered({"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"})
	end



	for k, v in pairs( temp ) do
	  Test["CheckRequestTypeTC3_1_" .. v] = function(self)
		self:checkRequestTypeInSystemRequestIsDisallowed(v)
	  end
	end

	for k, v in pairs( {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"} ) do
	  Test["CheckRequestTypeTC3_2_" .. v] = function(self)
		self:checkRequestTypeInSystemRequest(v)
	  end
	end

	
	
	-- Body of this case:
	
	function Test:CreatePTUOmmitedRequestTypeDefault(...)
	  userPrint(35, "================= Precondition ==================")
	  -- body
	  -- Create PTU from sdl_preloaded_pt.json
	  local data = self:convertPreloadedToJson()

	  -- data.policy_table.app_policies.default.RequestType = {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"}
	  data.policy_table.app_policies.default.RequestType = nil
	  data.policy_table.app_policies.device.RequestType = {"PROPRIETARY"}
	  data.policy_table.app_policies.pre_DataConsent.RequestType = {"PROPRIETARY"}
	  data.policy_table.app_policies[applicationRegisterParams.appName] = "default"

	  local json = require("json")
	  data = json.encode(data)
	  file = io.open("/tmp/ptu_update.json", "w")
	  file:write(data)
	  file:close()

	end

	function Test:PrecondMakeDeviceUntrustedOmmited( ... )
	  -- body
	  self:makeDeviceUntrusted()
	end

	function Test:TriggerPTU( ... )
	  -- body
	  userPrint(35, "================= Precondition ==================")

	  odometerValue = odometerValue + exchange_after_x_kilometers + 1
	  self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", { odometer = odometerValue})
	  self:ptu()
	  EXPECT_NOTIFICATION("OnPermissionsChange")
	end

	function Test:PrecondExitAppPreData()
	  self:unregisterApp()
	end

	function Test:CheckOnAppRegisteredHasDeafultRequestTypeTC3_1()
	  self:checkOnAppRegistered({"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"})
	end

	for k, v in pairs( temp ) do
	  Test["CheckRequestTypeTC3_3_" .. v] = function(self)
		self:checkRequestTypeInSystemRequestIsDisallowed(v)
	  end
	end

	for k, v in pairs( {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"} ) do
	  Test["CheckRequestTypeTC3_4_" .. v] = function(self)
		self:checkRequestTypeInSystemRequest(v)
	  end
	end


end

local function Req2_APPLINK_14723_Case2_pre_DataConsent_RequestType_omitted()


	function Test:CreatePTUValidRequestTypeDefault(...)
	  userPrint(35, "================= Precondition ==================")
	  -- body
	  -- Create PTU from sdl_preloaded_pt.json
	  local data = self:convertPreloadedToJson()

	  -- data.policy_table.app_policies.default.RequestType = {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"}
	  data.policy_table.app_policies.default.RequestType = {"PROPRIETARY"}
	  data.policy_table.app_policies.device.RequestType = {"PROPRIETARY"}
	  data.policy_table.app_policies.pre_DataConsent.RequestType = {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"}
	  data.policy_table.app_policies[applicationRegisterParams.appName] = "default"

	  local json = require("json")
	  data = json.encode(data)

	  file = io.open("/tmp/ptu_update.json", "w")
	  file:write(data)
	  file:close()

	end

	function Test:PrecondMakeDeviceUntrustedOmmitedPreData( ... )
	  self:makeDeviceUntrusted()
	end

	function Test:TriggerPTU( ... )
	  -- body
	  userPrint(35, "================= Precondition ==================")

	  odometerValue = odometerValue + exchange_after_x_kilometers + 1
	  self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", { odometer = odometerValue})
	  self:ptu()
	  EXPECT_NOTIFICATION("OnPermissionsChange")
	end


	function Test:PrecondExitAppPreData()
	  self:unregisterApp()
	end

	function Test:PrecondMakeDeviceUntrustedOmmitedPreData2( ... )
	  self:makeDeviceUntrusted()
	end

	function Test:CheckOnAppRegisteredHasEmptyRequestTypePreData( ... )
	  self:checkOnAppRegistered({"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"})
	end

	for k, v in pairs( temp ) do
	  Test["CheckRequestTypeTC4_1_" .. v] = function(self)
		self:checkRequestTypeInSystemRequestIsDisallowed(v)
	  end
	end

	for k, v in pairs( {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"} ) do
	  Test["CheckRequestTypeTC4_2_" .. v] = function(self)
		self:checkRequestTypeInSystemRequest(v)
	  end
	end

	function Test:CreatePTUOmmitedRequestTypePreData(...)
	  userPrint(35, "================= Precondition ==================")
	  -- body
	  -- Create PTU from sdl_preloaded_pt.json
	  local data = self:convertPreloadedToJson()

	  data.policy_table.app_policies.default.RequestType = {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"}
	  -- data.policy_table.app_policies.default.RequestType = nil
	  data.policy_table.app_policies.device.RequestType = {"PROPRIETARY"}
	  data.policy_table.app_policies.pre_DataConsent.RequestType = nil
	  data.policy_table.app_policies[applicationRegisterParams.appName] = "default"

	  local json = require("json")
	  data = json.encode(data)

	  file = io.open("/tmp/ptu_update.json", "w")
	  file:write(data)
	  file:close()

	end

	function Test:TriggerPTU( ... )
	  -- body
	  userPrint(35, "================= Precondition ==================")

	  odometerValue = odometerValue + exchange_after_x_kilometers + 1
	  self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", { odometer = odometerValue})
	  self:ptu()
	  EXPECT_NOTIFICATION("OnPermissionsChange")
	end

	function Test:PrecondMakeDeviceUntrustedOmmitedPreData22()
	  self:makeDeviceUntrusted()
	end

	function Test:PrecondExitAppPreData()
	  self:unregisterApp()
	end

	function Test:CheckOnAppRegisteredHasDeafultRequestTypeTC4()
	  self:checkOnAppRegistered({"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"})
	end

	for k, v in pairs( temp ) do
	  Test["CheckRequestTypeTC4_3_" .. v] = function(self)
		self:checkRequestTypeInSystemRequestIsDisallowed(v)
	  end
	end

	for k, v in pairs( {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"} ) do
	  Test["CheckRequestTypeTC4_4_" .. v] = function(self)
		self:checkRequestTypeInSystemRequest(v)
	  end
	end


end


-- ToDo: According to defect APPLINK-28498, if script is executed from Re1 to Req4, tests for Req2, 3 and 4 will be failed. So please execute each Req1, then comment it and execute Req2, 3 and 4

--Print new line to separate Preconditions
commonFunctions:newTestCasesGroup("Req2_APPLINK_14723_Case1_default_RequestType_omitted")
Req2_APPLINK_14723_Case1_default_RequestType_omitted()

--Print new line to separate Preconditions
commonFunctions:newTestCasesGroup("Req2_APPLINK_14723_Case1_pre_DataConsent_RequestType_omitted")
Req2_APPLINK_14723_Case2_pre_DataConsent_RequestType_omitted()

---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------

-- Req3: APPLINK-14722 [Policies]: SDL behavior in case PTU comes with at least one invalid value in "RequestType" of <default> or <pre_DataConsent> section
-- In case
-- 		PTU comes with several values in "RequestType" array of "<default>" and "<pre_DataConsent>" policies
-- 		and at least one of the values is invalid
-- Policies Manager must:
-- 		ignore invalid values in "RequestType" array of "<default>" or "<pre_DataConsent>" policies
-- 		copy valid values of "RequestType" array of "<default>" or "<pre_DataConsent>" policies 

local function Req3_APPLINK_14722_Case1_default_RequestType_valid_invalid()
	 
	--Precondition: Update PT with default.RequestType = {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"}
	function Test:CreatePTUValidRequestTypeDefault(...)
	  userPrint(35, "================= Precondition ==================")
	  -- body
	  -- Create PTU from sdl_preloaded_pt.json
	  local data = self:convertPreloadedToJson()

	  data.policy_table.app_policies.default.RequestType = {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"}
	  data.policy_table.app_policies.device.RequestType = {"PROPRIETARY"}
	  data.policy_table.app_policies.pre_DataConsent.RequestType = {"PROPRIETARY"}
	  data.policy_table.app_policies[applicationRegisterParams.appName] = "default"

	  local json = require("json")
	  data = json.encode(data)

	  file = io.open("/tmp/ptu_update.json", "w")
	  file:write(data)
	  file:close()

	end

	function Test:TriggerPTU( ... )
	  -- body
	  userPrint(35, "================= Precondition ==================")

	  odometerValue = odometerValue + exchange_after_x_kilometers + 1
	  self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", { odometer = odometerValue})
	  self:ptu()
	  EXPECT_NOTIFICATION("OnPermissionsChange")
	end

	function Test:PrecondExitApp()
	  self:unregisterApp()
	end

	function Test:CheckOnAppRegisteredHasEmptyRequestTypePreData( ... )
	  self:checkOnAppRegistered({"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"})
	end

	for k, v in pairs( temp ) do
	  Test["CheckRequestTypeTC5_1_" .. v] = function(self)
		self:checkRequestTypeInSystemRequestIsDisallowed(v)
	  end
	end

	for k, v in pairs( {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"} ) do
	  Test["CheckRequestTypeTC5_2_" .. v] = function(self)
		self:checkRequestTypeInSystemRequest(v)
	  end
	end

	
	-- Body of this test 
	
	function Test:CreatePTURequestTypeWithInvalidValuesDefault(...)
	  userPrint(35, "================= Precondition ==================")
	  -- body
	  -- Create PTU from sdl_preloaded_pt.json
	  local data = self:convertPreloadedToJson()

	  -- data.policy_table.app_policies.default.RequestType = {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"}
	  data.policy_table.app_policies.default.RequestType = {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP", "IVSU", "IGOR"}
	  data.policy_table.app_policies.device.RequestType = {"PROPRIETARY"}
	  data.policy_table.app_policies.pre_DataConsent.RequestType = {"PROPRIETARY"}
	  data.policy_table.app_policies[applicationRegisterParams.appName] = "default"

	  local json = require("json")
	  data = json.encode(data)
	  
	  file = io.open("/tmp/ptu_update.json", "w")
	  file:write(data)
	  file:close()

	end

	function Test:PrecondMakeDeviceUntrustedOmmited( ... )
	  self:makeDeviceUntrusted()
	end

	function Test:TriggerPTU( ... )
	  -- body
	  userPrint(35, "================= Precondition ==================")

	  odometerValue = odometerValue + exchange_after_x_kilometers + 1
	  self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", { odometer = odometerValue})
	  self:ptu()
	  EXPECT_NOTIFICATION("OnPermissionsChange")
	end

	function Test:PrecondExitAppPreData()
	  self:unregisterApp()
	end

	function Test:CheckOnAppRegisteredHasDeafultRequestTypeTC5()
	  self:checkOnAppRegistered({"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"})
	end

	for k, v in pairs( temp ) do
	  Test["CheckRequestTypeTC5_3_" .. v] = function(self)
		self:checkRequestTypeInSystemRequestIsDisallowed(v)
	  end
	end

	for k, v in pairs( {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"} ) do
	  Test["CheckRequestTypeTC5_4_" .. v] = function(self)
		self:checkRequestTypeInSystemRequest(v)
	  end
	end

end

local function Req3_APPLINK_14722_Case2_pre_DataConsent_RequestType_valid_invalid()

	--Precondition: Update PT with pre_DataConsent.RequestType = {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"}
	function Test:CreatePTUValidRequestTypeDefault(...)
	  userPrint(35, "================= Precondition ==================")
	  -- body
	  -- Create PTU from sdl_preloaded_pt.json
	  local data = self:convertPreloadedToJson()

	  data.policy_table.app_policies.default.RequestType = {"PROPRIETARY"}
	  data.policy_table.app_policies.device.RequestType = {"PROPRIETARY"}
	  data.policy_table.app_policies.pre_DataConsent.RequestType = {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"}
	  data.policy_table.app_policies[applicationRegisterParams.appName] = "default"

	  local json = require("json")
	  data = json.encode(data)
	  
	  file = io.open("/tmp/ptu_update.json", "w")
	  file:write(data)
	  file:close()

	end

	function Test:PrecondMakeDeviceUntrustedPreDataSomeInvalid( ... )
	  self:makeDeviceUntrusted()
	end

	function Test:TriggerPTU( ... )
	  -- body
	  userPrint(35, "================= Precondition ==================")

	  odometerValue = odometerValue + exchange_after_x_kilometers + 1
	  self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", { odometer = odometerValue})
	  self:ptu()
	  EXPECT_NOTIFICATION("OnPermissionsChange")
	end


	function Test:PrecondExitAppPreData()
	  self:unregisterApp()
	end

	function Test:PrecondMakeDeviceUntrustedPreDataSomeInvalid2( ... )
	  self:makeDeviceUntrusted()
	end

	function Test:CheckOnAppRegisteredHasEmptyRequestTypePreData( ... )
	  self:checkOnAppRegistered({"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"})
	end

	for k, v in pairs( temp ) do
	  Test["CheckRequestTypeTC6_1_" .. v] = function(self)
		self:checkRequestTypeInSystemRequestIsDisallowed(v)
	  end
	end

	for k, v in pairs( {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"} ) do
	  Test["CheckRequestTypeTC6_2_" .. v] = function(self)
		self:checkRequestTypeInSystemRequest(v)
	  end
	end

	
	
	-- Body of this test 
	
	function Test:CreatePTURequestTypeWithInvalidValuesPreData(...)
	  userPrint(35, "================= Precondition ==================")
	  -- body
	  -- Create PTU from sdl_preloaded_pt.json
	  local data = self:convertPreloadedToJson()

	  -- data.policy_table.app_policies.default.RequestType = {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"}
	  data.policy_table.app_policies.default.RequestType = {"PROPRIETARY"}
	  data.policy_table.app_policies.device.RequestType = {"PROPRIETARY"}
	  data.policy_table.app_policies.pre_DataConsent.RequestType = {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP", "IVSU", "IGOR"}
	  data.policy_table.app_policies[applicationRegisterParams.appName] = "default"

	  local json = require("json")
	  data = json.encode(data)
	  
	  file = io.open("/tmp/ptu_update.json", "w")
	  file:write(data)
	  file:close()

	end

	function Test:PrecondMakeDeviceUntrustedOmmited( ... )
	  self:makeDeviceUntrusted()
	end

	function Test:TriggerPTU( ... )
	  -- body
	  userPrint(35, "================= Precondition ==================")

	  odometerValue = odometerValue + exchange_after_x_kilometers + 1
	  self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", { odometer = odometerValue})
	  self:ptu()
	  EXPECT_NOTIFICATION("OnPermissionsChange")
	end

	function Test:PrecondMakeDeviceUntrustedOmmitedPreData22()
	  self:makeDeviceUntrusted()
	end

	function Test:PrecondExitAppPreData()
	  self:unregisterApp()
	end

	function Test:CheckOnAppRegisteredHasDeafultRequestTypeTC6()
	  self:checkOnAppRegistered({"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"})
	end

	for k, v in pairs( temp ) do
	  Test["CheckRequestTypeTC6_3_" .. v] = function(self)
		self:checkRequestTypeInSystemRequestIsDisallowed(v)
	  end
	end

	for k, v in pairs( {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"} ) do
	  Test["CheckRequestTypeTC6_4_" .. v] = function(self)
		self:checkRequestTypeInSystemRequest(v)
	  end
	end


end

--Print new line to separate Preconditions
commonFunctions:newTestCasesGroup("Req3_APPLINK_14722_Case1_default_RequestType_valid_invalid")
Req3_APPLINK_14722_Case1_default_RequestType_valid_invalid()


--Print new line to separate Preconditions
commonFunctions:newTestCasesGroup("Req3_APPLINK_14722_Case2_pre_DataConsent_RequestType_valid_invalid")
Req3_APPLINK_14722_Case2_pre_DataConsent_RequestType_valid_invalid()


---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------

-- Req4: APPLINK-14721 [Policies]: SDL behavior in case PTU comes with all invalid values in "RequestType" of <default> or <pre_DataConsent> section
-- In case
-- 		PTU comes with several values in "RequestType" array of "<default>" or "<pre_DataConsent>" policies
-- 		and all these values are invalid
-- Policies Manager must:
-- 		ignore the invalid values in "RequestType" array of "<default>" or "<pre_DataConsent>" policies
-- 		copy and assign the values of "RequestType" array of "<default>" or "<pre_DataConsent>" policies from PolicyDataBase before updating without any changes


local function Req4_APPLINK_14721_Case1_default_RequestType_invalid()

	--Precondition: Update PT with default.RequestType = {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"}
	function Test:CreatePTUValidRequestTypeDefault(...)
	  userPrint(35, "================= Precondition ==================")
	  -- body
	  -- Create PTU from sdl_preloaded_pt.json
	  local data = self:convertPreloadedToJson()

	  data.policy_table.app_policies.default.RequestType = {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"}
	  -- data.policy_table.app_policies.default.RequestType = {}
	  data.policy_table.app_policies.device.RequestType = {"PROPRIETARY"}
	  data.policy_table.app_policies.pre_DataConsent.RequestType = {"PROPRIETARY"}
	  data.policy_table.app_policies[applicationRegisterParams.appName] = "default"

	  local json = require("json")
	  data = json.encode(data)
	  
	  file = io.open("/tmp/ptu_update.json", "w")
	  file:write(data)
	  file:close()

	end

	function Test:TriggerPTU( ... )
	  -- body
	  userPrint(35, "================= Precondition ==================")

	  odometerValue = odometerValue + exchange_after_x_kilometers + 1
	  self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", { odometer = odometerValue})
	  self:ptu()
	  EXPECT_NOTIFICATION("OnPermissionsChange")
	end


	function Test:PrecondExitApp()
	  self:unregisterApp()
	end

	function Test:CheckOnAppRegisteredHasEmptyRequestTypePreData( ... )
	  self:checkOnAppRegistered({"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"})
	end

	for k, v in pairs( temp ) do
	  Test["CheckRequestTypeTC7_1_" .. v] = function(self)
		self:checkRequestTypeInSystemRequestIsDisallowed(v)
	  end
	end

	for k, v in pairs( {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"} ) do
	  Test["CheckRequestTypeTC7_2_" .. v] = function(self)
		self:checkRequestTypeInSystemRequest(v)
	  end
	end

	
	
	-- Body of this test 
	
	function Test:CreatePTURequestTypeWithInvalidValuesDefault(...)
	  userPrint(35, "================= Precondition ==================")
	  -- body
	  -- Create PTU from sdl_preloaded_pt.json
	  local data = self:convertPreloadedToJson()

	  -- data.policy_table.app_policies.default.RequestType = {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"}
	  data.policy_table.app_policies.default.RequestType = {"IVSU", "IGOR"}
	  data.policy_table.app_policies.device.RequestType = {"PROPRIETARY"}
	  data.policy_table.app_policies.pre_DataConsent.RequestType = {"PROPRIETARY"}
	  data.policy_table.app_policies[applicationRegisterParams.appName] = "default"

	  local json = require("json")
	  data = json.encode(data)
	  
	  file = io.open("/tmp/ptu_update.json", "w")
	  file:write(data)
	  file:close()

	end

	function Test:PrecondMakeDeviceUntrustedOmmited( ... )
	  self:makeDeviceUntrusted()
	end

	function Test:TriggerPTU( ... )
	  -- body
	  userPrint(35, "================= Precondition ==================")

	  odometerValue = odometerValue + exchange_after_x_kilometers + 1
	  self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", { odometer = odometerValue})
	  self:ptu()
	  EXPECT_NOTIFICATION("OnPermissionsChange")
	end

	function Test:PrecondExitAppPreData()
	  self:unregisterApp()
	end

	function Test:CheckOnAppRegisteredHasDeafultRequestTypeTC7()
	  self:checkOnAppRegistered({"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"})
	end

	for k, v in pairs( temp ) do
	  Test["CheckRequestTypeTC7_3_" .. v] = function(self)
		self:checkRequestTypeInSystemRequestIsDisallowed(v)
	  end
	end

	for k, v in pairs( {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"} ) do
	  Test["CheckRequestTypeTC7_4_" .. v] = function(self)
		self:checkRequestTypeInSystemRequest(v)
	  end
	end



end

local function Req4_APPLINK_14721_Case2_pre_DataConsent_RequestType_invalid()


	--Precondition: Update PT with pre_DataConsent.RequestType = {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"}
	function Test:CreatePTUValidRequestTypeDefault(...)
	  userPrint(35, "================= Precondition ==================")
	  -- body
	  -- Create PTU from sdl_preloaded_pt.json
	  local data = self:convertPreloadedToJson()

	  data.policy_table.app_policies.default.RequestType = {"PROPRIETARY"}
	  -- data.policy_table.app_policies.default.RequestType = {}
	  data.policy_table.app_policies.device.RequestType = {"PROPRIETARY"}
	  data.policy_table.app_policies.pre_DataConsent.RequestType = {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"}
	  data.policy_table.app_policies[applicationRegisterParams.appName] = "default"

	  local json = require("json")
	  data = json.encode(data)
	  
	  file = io.open("/tmp/ptu_update.json", "w")
	  file:write(data)
	  file:close()

	end

	function Test:PrecondMakeDeviceUntrustedSeveralValues( ... )
	  self:makeDeviceUntrusted()
	end

	function Test:TriggerPTU( ... )
	  -- body
	  userPrint(35, "================= Precondition ==================")

	  odometerValue = odometerValue + exchange_after_x_kilometers + 1
	  self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", { odometer = odometerValue})
	  self:ptu()
	  EXPECT_NOTIFICATION("OnPermissionsChange")
	end


	function Test:PrecondExitApp()
	  self:unregisterApp()
	end

	function Test:PrecondMakeDeviceUntrustedSeveralValues( ... )
	  self:makeDeviceUntrusted()
	end

	function Test:CheckOnAppRegisteredHasEmptyRequestTypePreData( ... )
	  self:checkOnAppRegistered({"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"})
	end

	for k, v in pairs( temp ) do
	  Test["CheckRequestTypeTC8_1_" .. v] = function(self)
		self:checkRequestTypeInSystemRequestIsDisallowed(v)
	  end
	end

	for k, v in pairs( {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"} ) do
	  Test["CheckRequestTypeTC8_2_" .. v] = function(self)
		self:checkRequestTypeInSystemRequest(v)
	  end
	end

	
	
	-- Body of this test 
		
	function Test:CreatePTURequestTypeWithInvalidValuesDefault(...)
	  userPrint(35, "================= Precondition ==================")
	  -- body
	  -- Create PTU from sdl_preloaded_pt.json
	  local data = self:convertPreloadedToJson()

	  data.policy_table.app_policies.default.RequestType = {"PROPRIETARY"}
	  data.policy_table.app_policies.device.RequestType = {"PROPRIETARY"}
	  data.policy_table.app_policies.pre_DataConsent.RequestType = {"IVSU", "IGOR"}
	  data.policy_table.app_policies[applicationRegisterParams.appName] = "default"

	  local json = require("json")
	  data = json.encode(data)
	  file = io.open("/tmp/ptu_update.json", "w")
	  file:write(data)
	  file:close()

	end

	function Test:TriggerPTU( ... )
	  -- body
	  userPrint(35, "================= Precondition ==================")

	  odometerValue = odometerValue + exchange_after_x_kilometers + 1
	  self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", { odometer = odometerValue})
	  self:ptu()
	  EXPECT_NOTIFICATION("OnPermissionsChange")
	end

	function Test:PrecondMakeDeviceUntrustedOmmited( ... )
	  self:makeDeviceUntrusted()
	end

	function Test:PrecondExitAppPreData()
	  self:unregisterApp()
	end

	function Test:CheckOnAppRegisteredHasDeafultRequestType()
	  self:checkOnAppRegistered({"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"})
	end

	for k, v in pairs( temp ) do
	  Test["CheckRequestTypeTC8_3_" .. v] = function(self)
		self:checkRequestTypeInSystemRequestIsDisallowed(v)
	  end
	end

	for k, v in pairs( {"PROPRIETARY", "QUERY_APPS", "LAUNCH_APP"} ) do
	  Test["CheckRequestTypeTC8_4_" .. v] = function(self)
		self:checkRequestTypeInSystemRequest(v)
	  end
	end

end

--Print new line to separate Preconditions
commonFunctions:newTestCasesGroup("Req4_APPLINK_14721_Case1_default_RequestType_invalid")
Req4_APPLINK_14721_Case1_default_RequestType_invalid()

--Print new line to separate Preconditions
commonFunctions:newTestCasesGroup("Req4_APPLINK_14721_Case2_pre_DataConsent_RequestType_invalid")
Req4_APPLINK_14721_Case2_pre_DataConsent_RequestType_invalid()


return Test