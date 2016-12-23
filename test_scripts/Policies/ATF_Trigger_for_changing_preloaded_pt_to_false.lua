
-- Requirement: APPLINK-16899 "New trigger for changing the value of "preloaded_pt" field to 'false'"
-- Goal is to test if value of "preload_pt" saved in localPT changes: 
-- on initial start it should be true, which means that PTU should start.
-- SDL must change value of "preloadedPT" param to "false" after PTU is applied
------------------------------------------------------------------------------------------------------
------------------------------------General Settings for Configuration--------------------------------
------------------------------------------------------------------------------------------------------
--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
Test = require('connecttest')
require('cardinalities')
local mobile_session = require('mobile_session')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')
local mobile  = require('mobile_connection')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local SDLStoragePath = config.pathToSDL .. "storage/"
Test.HMIappId = nil
------------------------------------------------------------------------------------------------------
----------------------------------Steps before start ATF----------------------------------------------
------------------------------------------------------------------------------------------------------
-- delete sdl_snapshot
os.execute( "rm -f /tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json" )
-- delete app_info.dat, SmartDeviceLinkCore.log, TransportManager.log, ProtocolFordHandling.log, 
-- HmiFrameworkPlugin.log and policy.sqlite
commonSteps:DeleteLogsFileAndPolicyTable()

------------------------------------------------------------------------------------------------------
---------------------------------------Functions used-------------------------------------------------
------------------------------------------------------------------------------------------------------
local function RestartSDL(prefix, DeleteStorageFolder)

	Test["Precondition_StopSDL_" .. tostring(prefix) ] = function(self)
		commonFunctions:userPrint(35, "================= Precondition ==================")
		StopSDL()
	end

	if DeleteStorageFolder then
		Test["Precondition_DeleteStorageFolder_" .. tostring(prefix)] = function(self)
			commonSteps:DeleteLogsFileAndPolicyTable()
		end
	end

	Test["Precondition_StartSDL_" .. tostring(prefix) ] = function(self)
		StartSDL(config.pathToSDL, config.ExitOnCrash)
	end

	Test["Precondition_InitHMI_" .. tostring(prefix) ] = function(self)
		self:initHMI()
	end

	Test["Precondition_InitHMI_onReady_" .. tostring(prefix) ] = function(self)
		self:initHMI_onReady()
	end

	Test["Precondition_ConnectMobile_" .. tostring(prefix) ] = function(self)
  		self:connectMobile()
	end

	Test["Precondition_StartSessionRegisterApp_" .. tostring(prefix) ] = function(self)
  		self:startSession()
	end

end


local function StartSDLAfterStop(prefix, DeleteStorageFolder)

	if DeleteStorageFolder then
		Test["Precondition_DeleteStorageFolder_" .. tostring(prefix)] = function(self)
			commonSteps:DeleteLogsFileAndPolicyTable()
		end
	end

	Test["Precondition_StartSDL_" .. tostring(prefix) ] = function(self)
		StartSDL(config.pathToSDL, config.ExitOnCrash)
	end

	Test["Precondition_InitHMI_" .. tostring(prefix) ] = function(self)
		self:initHMI()
	end

	Test["Precondition_InitHMI_onReady_" .. tostring(prefix) ] = function(self)
		self:initHMI_onReady()
	end

	Test["Precondition_ConnectMobile_" .. tostring(prefix) ] = function(self)
  		self:connectMobile()
	end

	Test["Precondition_StartSessionRegisterApp_" .. tostring(prefix) ] = function(self)
  		self:startSession()
	end

end


function DelayedExp(time)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  :Timeout(time+1000)
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, time)
end


local function get_preloaded_pt_value()   

  local sql_select = "sqlite3 " .. tostring(SDLStoragePath) .. "policy.sqlite \"SELECT preloaded_pt FROM module_config WHERE rowid = 1\""
   
  local aHandle = assert( io.popen( sql_select , 'r'))
  sql_output = aHandle:read( '*l' )
 
  local retvalue = tonumber(sql_output);
  
  if (retvalue == nil) then
    -- module:FailTestCase("preloaded_pt can't be read")
    self:FailTestCase("preloaded_pt can't be read")
  else 
    return retvalue
  end
end


local function UpdatePolicy(self, PTName)
--hmi side: sending SDL.GetURLS request
local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
--hmi side: expect SDL.GetURLS response from HMI
EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {{url = "http://policies.telematics.ford.com/api/policies"}}}})
  :Do(function(_,data)
	print("SDL.GetURLS response is received")
	--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
	self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
		{   
		    requestType = "PROPRIETARY",
		    url="http://policies.telematics.ford.com/api/policies",
		    fileName = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json",
			appID = self.applications["Test Application"]				
		}
	)
	--mobile side: expect OnSystemRequest notification
	self.mobileSession:ExpectNotification("OnReceivedPolicyUpdate", 
		{ 
		  requestType = "PROPRIETARY",
		  url="http://policies.telematics.ford.com/api/policies",
		  fileName = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json"

		 })
	end)
	:Do(function(_,data)				
    --mobile side: sending SystemRequest request
		local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
			{
				fileName = "PolicyTableUpdate",
				requestType = "PROPRIETARY"
			},
			"files/" .. "PTU_UpdateNeeded.json")

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
		self.mobileSession:ExpectResponse(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
		:Do(function(_,data)
			--hmi side: sending SDL.GetUserFriendlyMessage request to SDL
			local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})

			--hmi side: expect SDL.GetUserFriendlyMessage response
			EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
			:Do(function(_,data)
			end)
		end)

	end)
end

local function UpdatePolicyInvalidJSON(self, PTName)
--hmi side: sending SDL.GetURLS request
local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
--hmi side: expect SDL.GetURLS response from HMI
EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {{url = "http://policies.telematics.ford.com/api/policies"}}}})
  :Do(function(_,data)
	print("SDL.GetURLS response is received")
	--hmi side: sending BasicCommunication.OnSystemRequest request to SDL
	self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
		{   
		    requestType = "PROPRIETARY",
		    url="http://policies.telematics.ford.com/api/policies",
		    fileName = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json",
			appID = self.applications["Test Application"]				
		}
	)
	--mobile side: expect OnSystemRequest notification
	self.mobileSession:ExpectNotification("OnReceivedPolicyUpdate", 
		{ 
		  requestType = "PROPRIETARY",
		  url="http://policies.telematics.ford.com/api/policies",
		  fileName = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json"

		 })
	end)
	:Do(function(_,data)				
    --mobile side: sending SystemRequest request
		local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
			{
				fileName = "PolicyTableUpdate",
				requestType = "PROPRIETARY"
			},
			"files/" .. "PTU_UpdateNeeded.json")

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
		-- EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
		-- :ValidIf(function(exp,data)
		-- 	if
		-- 		exp.occurences == 1 and
		-- 		data.params.status == "UP_TO_DATE" then
		-- 			return true
		-- 	elseif
		-- 		exp.occurences == 1 and
		-- 		data.params.status == "UPDATING" then
		-- 			return true
		-- 	elseif
		-- 		exp.occurences == 2 and
		-- 		data.params.status == "UP_TO_DATE" then
		-- 			return true
		-- 	else
		-- 		if
		-- 			exp.occurences == 1 then
		-- 				print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in first occurrences status 'UP_TO_DATE' or 'UPDATING', got '" .. tostring(data.params.status) .. "' \27[0m")
		-- 		elseif exp.occurences == 2 then
		-- 				print ("\27[31m SDL.OnStatusUpdate came with wrong values. Expected in second occurrences status 'UP_TO_DATE', got '" .. tostring(data.params.status) .. "' \27[0m")
		-- 		end
		-- 		return false
		-- 	end
		-- end)
		-- :Times(Between(1,2))

		--mobile side: expect SystemRequest response

		self.mobileSession:ExpectResponse(CorIdSystemRequest, { success = false, resultCode = "INVALID_DATA"})
		:Do(function(_,data)
			--hmi side: sending SDL.GetUserFriendlyMessage request to SDL
			local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusPending"}})

			--hmi side: expect SDL.GetUserFriendlyMessage response
			EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Updating...", messageCode = "StatusPending", textBody = "Updating..."}}}})
			:Do(function(_,data)
			end)
		end)

	end)
end

local function MASTER_RESET(self, appNumber)
	StopSDL()

	if appNumber == nil then 
		appNumber = 1
	end

	-- hmi side: sends OnExitAllApplications (SUSPENDED)
	self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
		{
		  reason = "MASTER_RESET"
		})

	-- hmi side: expect OnSDLClose notification
	EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose", {})

	-- hmi side: expect OnAppUnregistered notification
	-- will be uncommented after fixinf defect: APPLINK-21931
	--EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
      :Times(1)
	DelayedExp(1000)
end


local function RegisterApplication(self) 

  --mobile side: RegisterAppInterface request 
  local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
                        config.application1.registerAppInterfaceParams)
  

    --hmi side: expected  BasicCommunication.OnAppRegistered
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
      :Do(function(_,data)
        self.appID = data.params.application.appID
      end)

  --mobile side: RegisterAppInterface response 
  EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
    :Timeout(2000)
    :Do(function(_,data)
      
      EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", systemContext = "MAIN"})

    end)

  EXPECT_NOTIFICATION("OnPermissionsChange")
end

------------------------------------------------------------------------------------------------------
------------------------------------------Tests-------------------------------------------------------
------------------------------------------------------------------------------------------------------
-- Test case Check 1 
-- First SDL start without any app -> check preloaded_pt FROM module_config ==> value is "1"
--check value of "preloaded_pt" in storage/policy.sqlite. It should be true. That means that LocalPT should be updated
function Test:CheckValueOfPreloaded1()  
  commonFunctions:userPrint(34, "=================== Test Case Check 1 ===================")
  preloaded_pt = get_preloaded_pt_value(self)
  print (preloaded_pt)
  
  if (preloaded_pt == 0) then
    --commonFunctions:userPrint(31, "preloaded_pt in localPT is 0, should be 1")
   -- module:FailTestCase("preloaded_pt in localPT is 0, should be 1")
    self:FailTestCase("preloaded_pt in localPT is 0, should be 1")

  end
 end

------------------------------------------------------------------------------------------------------
-- Test case Check 2
-- Stop SDL with IGNITION_OFF (check that SDL correctly saves preloaded_pt) -> check preloaded_pt FROM module_config ==> value is "1"
-- send Ignition off 
function Test:IGNITION_OFF_Check2()
commonFunctions:userPrint(34, "=================== Test Case Check 2 ===================")
-- commonFunctions:userPrint(34, "currently case fails due to APPLINK-19717")
  
  StopSDL()
  
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",{reason = "IGNITION_OFF"})

  -- hmi side: expect OnSDLClose notification
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")

  -- hmi side: expect OnAppUnregistered notification
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
  :Times(1)
end

-- check preloaded_pt FROM module_config ==> value is "1"
function Test:CheckValueOfPreloaded2()  
  preloaded_pt = get_preloaded_pt_value()

  if (preloaded_pt == 0) then
    -- commonFunctions:userPrint(31, "preloaded_pt in localPT is 0, should be 1")
    self:FailTestCase("preloaded_pt in localPT is 0, should be 1")
  end
 end

------------------------------------------------------------------------------------------------------
-- Test case Check 3
-- Start SDL (check SDL correctly loads preloaded_pt) -> check preloaded_pt FROM module_config ==> value is "1"
function Test:RestartSDL()
	commonFunctions:userPrint(34, "=================== Test Case Check 3 ===================")
	StartSDLAfterStop("TestCaseCheck3", false)
  end
-- check preloaded_pt FROM module_config ==> value is "1"
function Test:CheckValueOfPreloaded3()  
  preloaded_pt = get_preloaded_pt_value()

  if (preloaded_pt == 0) then
    -- commonFunctions:userPrint(31, "preloaded_pt in localPT is 0, should be 1")
    self:FailTestCase("preloaded_pt in localPT is 0, should be 1")
  end
 end

------------------------------------------------------------------------------------------------------
-- Test case Check 4
-- Register app and perform PTU with invalid .json file (Unsuccessfull PTU) -> check preloaded_pt FROM module_config ==> value is "1"
-- register App
function Test:RegisterAppCheck4()
	commonFunctions:userPrint(34, "=================== Test Case Check 4 ===================")
	RegisterApplication(self)
end

-- perform PTU with invalid .json file
function Test:PTUInvalidJson()

    UpdatePolicyInvalidJSON(self, "files/incorrectJSON.json")

end

-- check preloaded_pt FROM module_config, value should be "1"
function Test:CheckValueOfPreloaded4()  
  preloaded_pt = get_preloaded_pt_value()

  if (preloaded_pt == 0) then

    self:FailTestCase("preloaded_pt in localPT is 0, should be 1")
  end
 end

------------------------------------------------------------------------------------------------------
-- Test case Check 5
-- Stop SDL with IGNITION_OFF (check that SDL correctly saves preloaded_pt) -> check preloaded_pt FROM module_config ==> value is "1"
-- send Ignition off 
function Test:IGNITION_OFF_Check5()
commonFunctions:userPrint(34, "=================== Test Case Check 5 ===================")
-- ToDo: remove after APPLINK-19717 resolved
commonFunctions:userPrint(34, "currently case fails due to APPLINK-19717")
  
  StopSDL()
  
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",{reason = "IGNITION_OFF"})

  -- hmi side: expect OnSDLClose notification
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")

  -- hmi side: expect OnAppUnregistered notification
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
  :Times(1)
end

-- check preloaded_pt FROM module_config ==> value is "1"
function Test:CheckValueOfPreloaded5()  
  preloaded_pt = get_preloaded_pt_value()

  if (preloaded_pt == 0) then
    -- commonFunctions:userPrint(31, "preloaded_pt in localPT is 0, should be 1")
    self:FailTestCase("preloaded_pt in localPT is 0, should be 1")
  end
 end

------------------------------------------------------------------------------------------------------
-- Test case Check 6
-- Start SDL (check SDL correctly loads preloaded_pt) -> check preloaded_pt FROM module_config ==> value is "1"
function Test:RestartSDL()
	commonFunctions:userPrint(34, "=================== Test Case Check 6 ===================")
	StartSDLAfterStop("TestCaseCheck6", false)
  end
-- check preloaded_pt FROM module_config ==> value is "1"
function Test:CheckValueOfPreloaded6()  
  preloaded_pt = get_preloaded_pt_value()

  if (preloaded_pt == 0) then
    -- commonFunctions:userPrint(31, "preloaded_pt in localPT is 0, should be 1")
    self:FailTestCase("preloaded_pt in localPT is 0, should be 1")
  end
 end

------------------------------------------------------------------------------------------------------
-- Test case Check 7
-- Register app and perform successfull PTU -> check preloaded_pt FROM module_config ==> value is "0"
function Test:RegisterAppCheck7()
	commonFunctions:userPrint(34, "=================== Test Case Check 7 ===================")
	RegisterApplication(self)
end

function Test:PtuSuccess()
	-- hmi side: sending BasicCommunication.OnSystemRequest request to SDL
	self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
		{
			policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"
		})

	--hmi side: expect SDL.OnStatusUpdate
	EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UP_TO_DATE"})
	:Do(function(_,data)
		print("SDL.OnStatusUpdate is received")			               
	end)
	:Timeout(2000)
end

-- check preloaded_pt FROM module_config ==> value is "0"
function Test:CheckValueOfPreloaded7()  
  preloaded_pt = get_preloaded_pt_value()

  if (preloaded_pt == 1) then
    -- commonFunctions:userPrint(31, "preloaded_pt in localPT is 1, should be 0")
    self:FailTestCase("preloaded_pt in localPT is 1, should be 0")
  end
end

------------------------------------------------------------------------------------------------------
-- Test case Check 8
-- Stop SDL with IGNITION_OFF (check that SDL correctly saves preloaded_pt) -> check preloaded_pt FROM module_config ==> value is "0"
-- send Ignition off 
function Test:IGNITION_OFF_Check8()
commonFunctions:userPrint(34, "=================== Test Case Check 8 ===================")
-- ToDo: remove after APPLINK-19717 resolved
commonFunctions:userPrint(34, "currently case fails due to APPLINK-19717")
  
  StopSDL()
  
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",{reason = "IGNITION_OFF"})

  -- hmi side: expect OnSDLClose notification
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")

  -- hmi side: expect OnAppUnregistered notification
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
  :Times(1)
end

-- check preloaded_pt FROM module_config, value should be "0"
function Test:CheckValueOfPreloaded8()  
  preloaded_pt = get_preloaded_pt_value()

  if (preloaded_pt == 1) then

    self:FailTestCase("preloaded_pt in localPT is 1, should be 0")
  end
end

------------------------------------------------------------------------------------------------------
-- Test case Check 9
-- Start SDL (check SDL correctly loads preloaded_pt) -> check preloaded_pt FROM module_config ==> value is "0"
function Test:RestartSDL()
	commonFunctions:userPrint(34, "=================== Test Case Check 9 ===================")
	StartSDLAfterStop("TestCaseCheck9", false)
  end

-- check preloaded_pt FROM module_config ==> value is "0"
function Test:CheckValueOfPreloaded9()  
  preloaded_pt = get_preloaded_pt_value()

  if (preloaded_pt == 1) then
    self:FailTestCase("preloaded_pt in localPT is 1, should be 0")
  end
end

------------------------------------------------------------------------------------------------------
-- Test case Check 10
-- Stop SDL with MASTER_RESET -> check absence of policy.sqlite file ==> file is absent
-- send master reset	
function Test:ExecuteMasterReset() 
	commonFunctions:userPrint(34, "=================== Test Case Check 10 ===================")
	--TODO: delete after APPLINK-19717 resolved
	commonFunctions:userPrint(34, "currently case fails due to APPLINK-19717")
       MASTER_RESET(self)
end

-- check absence of policy.sqlite file, file should be absent
function Test:CheckAbsenceOfPolisyTable()
	local returnValue

     if commonSteps.file_exists(SDLStoragePath .. "policy.sqlite") == false then
	 self:FailTestCase("policy.sqlite should be absent")
    end
end

------------------------------------------------------------------------------------------------------
-- Test case Check 11
-- Start SDL (check SDL correctly loads preloaded_pt) -> check preloaded_pt FROM module_config ==> value is "1"
function Test:RestartSDL()
	commonFunctions:userPrint(34, "=================== Test Case Check 11 ===================")
	StartSDLAfterStop("TestCaseCheck11", false)
  end

-- check preloaded_pt FROM module_config, value should be "1"
function Test:CheckValueOfPreloaded11()  
  preloaded_pt = get_preloaded_pt_value()

  if (preloaded_pt == 0) then
    -- commonFunctions:userPrint(31, "preloaded_pt in localPT is 0, should be 1")
    self:FailTestCase("preloaded_pt in localPT is 0, should be 1")
  end
 end
