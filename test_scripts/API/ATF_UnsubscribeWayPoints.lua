Test = require('connecttest')
local mobile_session = require('mobile_session')
local mobile = require("mobile_connection")
local tcp = require("tcp_connection")
local file_connection = require("file_connection")
require('cardinalities')
local events = require('events')---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')local floatParameterInNotification = require('user_modules/shared_testcases/testCasesForFloatParameterInNotification')
local stringParameterInNotification = require('user_modules/shared_testcases/testCasesForStringParameterInNotification')
local stringArrayParameterInNotification = require('user_modules/shared_testcases/testCasesForArrayStringParameterInNotification')
local imageParameterInNotification = require('user_modules/shared_testcases/testCasesForImageParameterInNotification')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local SDLConfig = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')
require('user_modules/AppTypes')
---------------------------------------------------------------------------------------------
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------
APIName="UnsubscribeWayPoints"strMaxLengthFileName255 = string.rep("a", 251)  .. ".png" -- set max length file name
local storagePath = config.SDLStoragePath..config.application1.registerAppInterfaceParams.appID.. "_" .. config.deviceMAC.. "/"	
---------------------------------------------------------------------------------------------
------------------------------------ Common Functions ---------------------------------------
-----------------------------------------------------------------------------------------------
-- Create default request
function Test:createRequest()
  return 	{}
end
local function SubscribeWayPoints_Success(TCName)  
  Test[TCName] = function(self)  
    -- mobile side: send SubscribeWayPoints request
    local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints",{})    -- hmi side: expected SubscribeWayPoints request
    EXPECT_HMICALL("Navigation.SubscribeWayPoints")    :Do(function(_,data)
      -- hmi side: sending Navigation.SubscribeWayPoints response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
    end)    -- mobile side: SubscribeWayPoints response
    EXPECT_RESPONSE(CorIdSWP, {success = true , resultCode = "SUCCESS"})    -- TODO: This step is failed due to APPLINK-25808 defect. Should be uncommented after defect is fixed.
    -- EXPECT_NOTIFICATION("OnHashChange")
  end		
end
function Test:unSubscribeWayPoints()
  -- mobile side: sending UnsubscribeWayPoints request
  local cid = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})  -- hmi side: expect UnsubscribeWayPoints request
  EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
  :Do(function(_,data)
    -- hmi side: sending VehicleInfo.UnsubscribeWayPoints response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})	
  end)  -- mobile side: expect UnsubscribeWayPoints response
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})  -- mobile side: expect OnHashChange notification
  -- TODO: This step is failed due to APPLINK-25808 defect. Should be uncommented after defect is fixed.
  -- EXPECT_NOTIFICATION("OnHashChange")
end
function Test:registerAppInterface2()
  config.application2.registerAppInterfaceParams.isMediaApplication=false
  config.application2.registerAppInterfaceParams.appHMIType={"DEFAULT"}  -- mobile side: sending request 
  local CorIdRegister = self.mobileSession1:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)  -- hmi side: expect BasicCommunication.OnAppRegistered request
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
  {
    application = 
    {
      appName = config.application2.registerAppInterfaceParams.appName
    }
  })
  :Do(function(_,data)
    self.applications[config.application2.registerAppInterfaceParams.appName] = data.params.application.appID					
  end)  -- mobile side: expect response
  self.mobileSession1:ExpectResponse(CorIdRegister, 
  {
    syncMsgVersion = config.syncMsgVersion
  })
  :Timeout(2000)  -- mobile side: expect notification
  self.mobileSession1:ExpectNotification("OnHMIStatus", {systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
  :Timeout(2000)
end	
function Test:registerAppInterface3()
  -- mobile side: sending request 
  local CorIdRegister = self.mobileSession2:SendRPC("RegisterAppInterface", config.application3.registerAppInterfaceParams)  -- hmi side: expect BasicCommunication.OnAppRegistered request
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
  {
    application = 
    {
      appName = config.application3.registerAppInterfaceParams.appName
    }
  })
  :Do(function(_,data)
    self.applications[config.application3.registerAppInterfaceParams.appName] = data.params.application.appID					
  end)  -- mobile side: expect response
  self.mobileSession2:ExpectResponse(CorIdRegister, 
  {
    syncMsgVersion = config.syncMsgVersion
  })
  :Timeout(2000)  -- mobile side: expect notification
  self.mobileSession2:ExpectNotification("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
  :Timeout(2000)
end
------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
-- Activation App
commonSteps:ActivationApp()
-- PutFiles
commonSteps:PutFile( "PutFile_MinLength", "a")
commonSteps:PutFile( "PutFile_icon.png", "icon.png")
commonSteps:PutFile( "PutFile_action.png", "action.png")
commonSteps:PutFile( "PutFile_MaxLength_255Characters", strMaxLengthFileName255)local permission_lines_subscribewaypoints = 
[[					"SubscribeWayPoints": {
  "hmi_levels": [
  "BACKGROUND",
  "FULL",
  "LIMITED"
  ]
}]]local permission_lines_unsubscribewaypoints = 
[[					"UnsubscribeWayPoints": {
  "hmi_levels": [
  "BACKGROUND",
  "FULL",
  "LIMITED"
  ]
}]]local permission_lines_for_base4 = permission_lines_subscribewaypoints .. ", \n" .. permission_lines_unsubscribewaypoints ..", \n"
local permission_lines_for_group1 = nil
local permission_lines_for_application = nillocal policy_file_name = testCasesForPolicyTable:createPolicyTableFile(permission_lines_for_base4, permission_lines_for_group1, permission_lines_for_application)	
testCasesForPolicyTable:updatePolicy(policy_file_name)	
-- Backup Preloaded PT
function Test:backUpPreloadedPt()
  -- body
  os.execute('cp ' .. config.pathToSDL .. 'sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json')
  os.execute('rm ' .. config.pathToSDL .. 'policy.sqlite')
end
Test:backUpPreloadedPt()
function Test:updatePreloadedJson()
  -- body
  pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
  local file = io.open(pathToFile, "r")
  local json_data = file:read("*all") -- may be abbreviated to "*a";
  file:close()  local json = require("modules/json")  local data = json.decode(json_data)
  for k,v in pairs(data.policy_table.functional_groupings) do
    if (data.policy_table.functional_groupings[k].rpcs == nil) then
      -- do
      data.policy_table.functional_groupings[k] = nil
    else
      -- do
      local count = 0
      for _ in pairs(data.policy_table.functional_groupings[k].rpcs) do count = count + 1 end
      if (count < 30) then
        -- do
        data.policy_table.functional_groupings[k] = nil
      end
    end
  end  data.policy_table.functional_groupings["Base-4"]["rpcs"]["SubscribeWayPoints"] = {}
  data.policy_table.functional_groupings["Base-4"]["rpcs"]["SubscribeWayPoints"]["hmi_levels"] = {"BACKGROUND", "FULL","LIMITED"}  data.policy_table.functional_groupings["Base-4"]["rpcs"]["UnsubscribeWayPoints"] = {}
  data.policy_table.functional_groupings["Base-4"]["rpcs"]["UnsubscribeWayPoints"]["hmi_levels"] = {"BACKGROUND", "FULL","LIMITED"}  data = json.encode(data)  file = io.open(pathToFile, "w")
  file:write(data)
  file:close()
end
Test:updatePreloadedJson()
---------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK I----------------------------------------
------CommonRequestCheck: Check of mandatory/conditional request's parameters (mobile protocol)----
---------------------------------------------------------------------------------------------
-- Requirement id in JAMA/or Jira ID:
-- APPLINK-21641 #6 (APPLINK-21906)
commonFunctions:newTestCasesGroup("Test Suite For Common Request Checks")
function Test:UnsubscribeWayPoints_IGNORED_ApplicationNotRegister()
  commonTestCases:DelayedExp(2000)
		-- mobile side: UnsubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})
		-- hmi side: expected UnsubscribeWayPoints request
  EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
  :Times(0)
		-- mobile side: UnsubscribeWayPoints response
  EXPECT_RESPONSE(CorIdSWP,{ success = false, resultCode = "IGNORED"})
	EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)
end
-- Postcondition: WayPoints are subscribed successfully.
SubscribeWayPoints_Success("SubscribeWayPoints_Success_1")

-- APPLINK-21629 req#1
-- Verification criteria: In case mobile app sends the valid UnsuscibeWayPoints_request to SDL and this request is allowed by Policies SDL must: transfer UnsubscribeWayPoints_request_ to HMI respond with <resultCode> received from HMI to mobile app
function Test:UnSubscribeWayPoints_Success()
  self:unSubscribeWayPoints()
end
----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK II----------------------------------------
-----------------------------Check special cases of Mobile request----------------------------
----------------------------------------------------------------------------------------------local function special_request_checks()	-- Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test Suite For Special Request Checks")
  	-- Precondition: WayPoints are subscribed successfully.
	SubscribeWayPoints_Success("SubscribeWayPoints_Success_2")
  ----------------------------------------------------------------------------------------------
    -- Description: The request with wrong JSON syntax is sent, the response with INVALID_DATA result code is returned.	
  -- Requirement id in JAMA/or Jira ID: APPLINK-21629 #3 (APPLINK-16739)	function Test:UnsubscribeWayPoints_InvalidJSON()		self.mobileSession.correlationId = self.mobileSession.correlationId + 1		-- mobile side: UnsubscribeWayPoints request
		local msg =
		{
			serviceType = 7,
			frameInfo = 0,
			rpcType = 0,
			rpcFunctionId = 43,
			rpcCorrelationId = self.mobileSession.correlationId,
			--<<!-- extra ','
			payload = '{,}'
		}
		self.mobileSession:Send(msg)		-- hmi side: there is no SubscribeWayPoints request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Times(0)		-- mobile side:SubscribeWayPoints response
		self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })		EXPECT_NOTIFICATION("OnHashChange")
		:Times(0)	end
  ----------------------------------------------------------------------------------------------
    -- Description: Check processing UnsubscribeWayPoints request with fake parameter	
  -- Requirement id in JAMA/or Jira ID: APPLINK-14765	function Test:UnsubscribeWayPoints_FakeParam()		-- mobile side: send UnsubscribeWayPoints request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {fakeParam = "fakeParam"})		-- hmi side: there is no UnsubscribeWayPoints request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")		:Do(function(_,data)
			-- hmi side: sending Navigation.UnsubscribeWayPoints response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		  end)
		:ValidIf(function(_,data)
			if data.params then
			  print("SDL re-sends fakeParam parameters to HMI in UnsubscribeWayPoints request")
			  return false
			else
			  return true
			end
		  end)		-- mobile side: UnsubscribeWayPoints response
		self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = true, resultCode = "SUCCESS"})		-- TODO: This step is failed due to APPLINK-25808 defect. Should be uncommented after defect is fixed.
		-- EXPECT_NOTIFICATION("OnHashChange")	end
  	-- Postcondition
	SubscribeWayPoints_Success("SubscribeWayPoints_Success_3")
  ----------------------------------------------------------------------------------------------
    -- Description: Check processing UnsubscribeWayPoints request with parameters from another request
  -- Requirement id in JAMA/or Jira ID: APPLINK-14765	function Test:UnsubscribeWayPoints_AnotherRequest()    -- mobile side: UnsubscribeWayPoints request
    local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", { menuName = "shouldn't be transfered" })    -- hmi side: there is no UnsubscribeWayPoints request
    EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")    :Do(function(_,data)
        -- hmi side: sending Navigation.UnsubscribeWayPoints response
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
    :ValidIf(function(_,data)
        if data.params then
          print("SDL re-sends fakeParam parameters to HMI in UnsubscribeWayPoints request")
          return false
        else
          return true
        end
      end)    -- mobile side: UnsubscribeWayPoints response
    self.mobileSession:ExpectResponse(CorIdSWP, { success = true, resultCode = "SUCCESS" })    -- TODO: This step is failed due to APPLINK-25808 defect. Should be uncommented after defect is fixed.
    -- EXPECT_NOTIFICATION("OnHashChange")	end
  	-- Postcondition
	SubscribeWayPoints_Success("SubscribeWayPoints_Success_4")
  ----------------------------------------------------------------------------------------------
    -- Description: Check processing requests with duplicate correlationID
  -- TODO: fill Requirement, Verification criteria about duplicate correlationID
  -- Requirement id in JAMA/or Jira ID: APPLINK-21629 #6 (APPLINK-21906)	function Test:UnsubscribeWayPoints_correlationIdDuplicateValue()		-- mobile side: UnsubscribeWayPoints request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})		-- hmi side: expected UnsubscribeWayPoints request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Do(function(_,data)
			-- hmi side: sending Navigation.UnsubscribeWayPoints response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		  end)		-- mobile side: UnsubscribeWayPoints response
		EXPECT_RESPONSE(CorIdSWP,
		  { success = true, resultCode = "SUCCESS"},
		  { success = false, resultCode = "IGNORED"})
		:Times(2)
		:Do(function(exp,data)			if exp.occurences == 1 then			  -- mobile side: UnsubscribeWayPoints request
			  local msg =
			  {
				serviceType = 7,
				frameInfo = 0,
				rpcType = 0,
				rpcFunctionId = 43,
				rpcCorrelationId = self.mobileSession.correlationId,
				payload = '{}'
			  }
			  self.mobileSession:Send(msg)
			end		  end)		-- TODO: This step is failed due to APPLINK-25808 defect. Should be uncommented after defect is fixed.
		-- EXPECT_NOTIFICATION("OnHashChange")	end	
endspecial_request_checks()-----------------------------------------------------------------------------------------------
-------------------------------------------TEST BLOCK III--------------------------------------
----------------------------------Check normal cases of HMI Response--------------------------
-----------------------------------------------------------------------------------------------
-- APPLINK-21902 (SUCCESS)
-- APPLINK-16739 (INVALID_DATA)
-- APPLINK-16746 (APPLICATION_NOT_REGISTERED)
-- APPLINK-17008 (GENERIC_ERROR)
-- APPLINK-21903 (DISALLOWED)
-- APPLINK-19584 (USER_DISALLOWED)
-- APPLINK-14765: SDL must cut off the fake parameters from requests, responses and notifications received from HMI ( response (request) is invalid SDL must respond GENERIC_ERROR (success:false, info: "Invalid message received from vehicle") to mobile app)
-- APPLINK-14551: SDL behavior: cases when SDL must transfer "info" parameter via corresponding RPC to mobile app
-- Verification Criteria: 
-- "info" is sent if there is any additional information about the resultCode. -- List of parameters:
-- Parameter 1: resultCode: type=String Enumeration(Integer), mandatory="true" 
-- Parameter 2: method: type=String, mandatory="true" (main test case: method is correct or not) 
-- Parameter 3: info: type=String, minlength="1" maxlength="10" mandatory="false" 
-- Parameter 4: correlationID: type=Integer, mandatory="true" commonFunctions:newTestCasesGroup("Test suite: common test cases for response")
-----------------------------------------------------------------------------------------------
-- Parameter 1: resultCode
-- -------------------------------------------------------------------------------------------
-- List of test cases: 
-- 1. IsMissed
-- 2. IsValidValue
-- 3. IsNotExist
-- 4. IsEmpty
-- 5. IsWrongType
-----------------------------------------------------------------------------------------------local function verify_resultcode_parameter()	-- Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup({"resultCode"})
	-----------------------------------------------------------------------------------------
	-- Postcondition
	SubscribeWayPoints_Success("SubscribeWayPoints_Success_5")	-- 1. IsMissed
	Test[APIName.."_Response_resultCode_IsMissed_GENERIC_ERROR_SendResponse"] = function(self)		-- mobile side: sending the request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})		-- hmi side: expect the request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Do(function(_,data)
			-- hmi side: sending response
			-- self.hmiConnection:Send('{"id":'  .. tostring(data.id) .. ',"jsonrpc":"2.0","result":{"code":0,"method":"Navigation.UnsubscribeWayPoints"}}')	 
			self.hmiConnection:Send('{"id":'  .. tostring(data.id) .. ',"jsonrpc":"2.0","result":{"method":"Navigation.UnsubscribeWayPoints"}}')	 		end)		-- mobile side: expect the response
		EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "INVALID_DATA"})	end
  	Test[APIName.."_Response_resultCode_IsMissed_GENERIC_ERROR_SendError"] = function(self)		-- mobile side: sending the request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})		-- hmi side: expect the request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Do(function(_,data)
			-- hmi side: sending response
			-- self.hmiConnection:Send('{"id":'  .. tostring(data.id) .. ',"jsonrpc":"2.0","result":{"code":0,"method":"Navigation.UnsubscribeWayPoints"}}')	
			self.hmiConnection:Send('{"id":'  .. tostring(data.id) .. ',"jsonrpc":"2.0","error":{"data":{"method":"Navigation.UnsubscribeWayPoints"}}}')	
		end)		-- mobile side: expect the response
		EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "INVALID_DATA"})	end
	-----------------------------------------------------------------------------------------	-- 2. IsValidValue
	local ResultCodes = {
		-- resultCode = "SUCCESS" is covered by UnSubscribeWayPoints_Success test cases
		-- {resultCode = "SUCCESS", success =  true}, 
		{resultCode = "INVALID_DATA", success =  false},		
		{resultCode = "GENERIC_ERROR", success =  false},
		{resultCode = "UNSUPPORTED_RESOURCE", success =  false},
		{resultCode = "IGNORED", success =  false},
		{resultCode = "DISALLOWED", success =  false},	}	for i =1, #ResultCodes do		Test[APIName.."_Response_resultCode_IsValidValue_" .. ResultCodes[i].resultCode .."_SendResponse"] = function(self)
			commonTestCases:DelayedExp(2000)
			-- mobile side: sending the request
			local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})
			-- hmi side: expect the request
			EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
			:Do(function(_,data)
				-- hmi side: sending response
				self.hmiConnection:SendResponse(data.id, data.method, ResultCodes[i].resultCode, {})
			end)			-- mobile side: expect the response
			EXPECT_RESPONSE(CorIdSWP, { ResultCodes[i].success, ResultCodes[i].resultCode})		end		
		-----------------------------------------------------------------------------------------		Test[APIName.."_Response_resultCode_IsValidValue_" .. ResultCodes[i].resultCode .."_SendError"] = function(self)			-- mobile side: sending the request
      local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})			-- hmi side: expect the request
			EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
			:Do(function(_,data)
				-- hmi side: sending the response
				self.hmiConnection:SendError(data.id, data.method, ResultCodes[i].resultCode, {})								
			end)			-- mobile side: expect the response
			EXPECT_RESPONSE(CorIdSWP, { success = ResultCodes[i].success, resultCode = ResultCodes[i].resultCode, {}})
		end	
		-----------------------------------------------------------------------------------------	end -- end of for (ResultCodes)
	-----------------------------------------------------------------------------------------	-- 3. IsNotExist
	-- 4. IsEmpty
	-- 5. IsWrongType
	local TestData = {	
		{value = "ANY", name = "IsNotExist"},
		{value = "", name = "IsEmpty"},
		{value = 123, name = "IsWrongType"}}	for i =1, #TestData do		Test[APIName.."_Response_resultCode_" .. TestData[i].name .."_GENERIC_ERROR_SendResponse"] = function(self)
			commonTestCases:DelayedExp(2000)
			-- mobile side: sending the request
			local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})			-- hmi side: expect the request
			EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
			:Do(function(_,data)
				-- hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, TestData[i].value, {})				
			end)			-- mobile side: expect the response
			-- TODO: update after resolving APPLINK-14765
      -- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
      EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "INVALID_DATA"})
		end
		-----------------------------------------------------------------------------------------		Test[APIName.."_Response_resultCode_" .. TestData[i].name .."_GENERIC_ERROR_SendError"] = function(self)
			commonTestCases:DelayedExp(2000)
			-- mobile side: sending the request
			local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})			-- hmi side: expect the request
			EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
			:Do(function(_,data)
				-- hmi side: sending the response
				self.hmiConnection:SendError(data.id, data.method, TestData[i].value)
			end)			-- mobile side: expect the response
			-- TODO: update after resolving APPLINK-14765
			-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
			EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "INVALID_DATA"})
		end
		-----------------------------------------------------------------------------------------	end -- end of for (TestData)
	-----------------------------------------------------------------------------------------end	verify_resultcode_parameter()
-----------------------------------------------------------------------------------------------
-- Parameter 2: method
-----------------------------------------------------------------------------------------------
-- List of test cases: 
-- 1. IsMissed
-- 2. IsValidResponse
-- 3. IsNotValidResponse
-- 4. IsOtherResponse
-- 5. IsEmpty
-- 6. IsWrongType
-- 7. IsInvalidCharacter - \n, \t, only spaces
------------------------------------------------------------------------------------------------- Verify SDL behaviors when HMI responses invalid correlationId or invalid method
local function verify_method_parameter()	-- Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup({"method"})	-- 1. IsMissed
	Test[APIName.."_Response_method_IsMissed_GENERIC_ERROR_SendResponse"] = function(self)		-- mobile side: sending the request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})		-- hmi side: expect the request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")		
		:Do(function(_,data)
			-- hmi side: sending the response
      -- self.hmiConnection:Send('{"id":'  .. tostring(data.id) .. ',"jsonrpc":"2.0","result":{"code":0,"method":"Navigation.UnsubscribeWayPoints"}}')
      self.hmiConnection:Send('{"id":' .. tostring(data.id) .. ',"jsonrpc":"2.0","result":{"code":0}}')
		end)		-- mobile side: expect the response
		EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)	end
  	Test[APIName.."_Response_method_IsMissed_GENERIC_ERROR_SendError"] = function(self)		-- mobile side: sending the request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})		-- hmi side: expect the request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Do(function(_,data)
      -- hmi side: sending the response		  
      -- self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"Navigation.UnsubscribeWayPoints"},"code":4,"message":"abc"}}')
      self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"Navigation.UnsubscribeWayPoints"},"code":4,"message":"abc"}}')		end)		-- mobile side: expect the response
		EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)	end
	-- ---------------------------------------------------------------------------------------	-- 2. IsValidResponse Covered by many test cases	
	-- ---------------------------------------------------------------------------------------	-- 3. IsNotValidResponse
	-- 4. IsOtherResponse
	-- 5. IsEmpty
	-- 6. IsWrongType
	-- 7. IsInvalidCharacter - \n, \t, spaces	
	local Methods = {	
		{method = "ANY", name = "IsNotValidResponse"},
		{method = "GetCapabilities", name = "IsOtherResponse"},
		{method = "", name = "IsEmpty"},
		{method = 123, name = "IsWrongType"},
		{method = "a\nb", name = "IsInvalidCharacter_NewLine"},
		{method = "a\tb", name = "IsInvalidCharacter_Tab"},
		{method = "  ", name = "IsSpaces"},
	}	for i =1, #Methods do		Test[APIName.."_Response_method_" .. Methods[i].name .."_GENERIC_ERROR_SendResponse"] = function(self)			-- mobile side: sending the request
			local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})			-- hmi side: expect the request
			EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
			:Do(function(_,data)
				-- hmi side: sending the response
				-- self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				self.hmiConnection:SendResponse(data.id, Methods[i].method, "SUCCESS", {})
			end)			-- mobile side: expect the response
			EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(13000)		end
		-----------------------------------------------------------------------------------------		Test[APIName.."_Response_method_" .. Methods[i].name .."_GENERIC_ERROR_SendError"] = function(self)			-- mobile side: sending the request
			local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})			-- hmi side: expect the request
			EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
			:Do(function(_,data)			
				-- hmi side: sending the response
				-- self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "info")
				self.hmiConnection:SendError(data.id, Methods[i].method, "GENERIC_ERROR", "info")			
			end)			-- mobile side: expect the response
			EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "GENERIC_ERROR"})
			:Timeout(13000)		end
		-----------------------------------------------------------------------------------------	end -- end of for (Methods)
	-----------------------------------------------------------------------------------------end	verify_method_parameter()-----------------------------------------------------------------------------------------------
-- Parameter 3: info
-- ---------------------------------------------------------------------------------------------
-- List of test cases: 
-- 1. IsMissed
-- 2. IsLowerBound
-- 3. IsUpperBound
-- 4. IsOutUpperBound
-- 5. IsEmpty/IsOutLowerBound
-- 6. IsWrongType
-- 7. InvalidCharacter - \n, \t, only spaces
-----------------------------------------------------------------------------------------------local function verify_info_parameter()	-- Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup({"info"})	function Test:UnSubscribeWayPoints_Response_info_IsMissed_SendError()		commonTestCases:DelayedExp(2000)
		-- mobile side: sending the request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})		-- hmi side: expect the request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Do(function(_,data)
			-- hmi side: sending the response
			self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR")	
		end)		-- mobile side: expect the response
		-- TODO: update after resolving APPLINK-14765
		-- EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle"})
		EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "INVALID_DATA"})
	end	-----------------------------------------------------------------------------------------	-- 2. IsLowerBound
	-- 3. IsUpperBound
	local TestData = {	
		{value = "a", name = "IsLowerBound"},
		{value = commonFunctions:createString(1000), name = "IsUpperBound"}}
    	for i =1, #TestData do		Test[APIName.."_Response_info_" .. TestData[i].name .."_SendResponse"] = function(self)			-- mobile side: sending the request
			local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})			-- hmi side: expect the request
			EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
			:Do(function(_,data)
				-- hmi side: sending the response
				-- Response["info"] = TestData[i].value				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info=TestData[i].value})
			end)			-- mobile side: expect response
			EXPECT_RESPONSE(CorIdSWP, { success = true, resultCode = "SUCCESS", info=TestData[i].value} )		end		-----------------------------------------------------------------------------------------		Test[APIName.."_Response_info_" .. TestData[i].name .."_SendError"] = function(self)			-- mobile side: sending the request
			local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})			-- hmi side: expect the request
			EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
			:Do(function(_,data)
				-- hmi side: sending the response
				self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", TestData[i].value)
			end)			-- mobile side: expect the response
			EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "GENERIC_ERROR", info = TestData[i].value})							end
		-----------------------------------------------------------------------------------------	end -- end of for (TestData)
	---------------------------------------------------------------------------------------	--[[TODO: update after resolving APPLINK-14551
	-- 4. IsOutUpperBound
	Test[APIName.."_Response_info_IsOutUpperBound_SendResponse"] = function(self)		local infoMaxLength = commonFunctions:createString(1000)		-- mobile side: sending the request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})		-- hmi side: expect the request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Do(function(_,data)
			-- hmi side: sending the response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", infoMaxLength .. "1")
		end)		--mobile side: expect the response
		local ExpectedResponse = commonFunctions:cloneTable({})
		ExpectedResponse["success"] = true
		ExpectedResponse["resultCode"] = "SUCCESS"
		ExpectedResponse["info"] = infoMaxLength		EXPECT_RESPONSE(CorIdSWP, ExpectedResponse)	end
	-----------------------------------------------------------------------------------------	Test[APIName.."_Response_info_IsOutUpperBound_SendError"] = function(self)		local infoMaxLength = commonFunctions:createString(1000)		-- mobile side: sending the request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})		-- hmi side: expect the request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Do(function(_,data)
			-- hmi side: sending the response
			self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoMaxLength .."1")
		end)		-- mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = infoMaxLength})	end
	-----------------------------------------------------------------------------------------	-- 5. IsEmpty/IsOutLowerBound	
	-- 6. IsWrongType
	-- 7. InvalidCharacter - \n, \t, only spaces	local TestData = {	
		{value = "", name = "IsEmpty_IsOutLowerBound"},
		{value = 123, name = "IsWrongType"},
		{value = "a\nb", name = "IsInvalidCharacter_NewLine"},
		{value = "a\tb", name = "IsInvalidCharacter_Tab"},
		{value = " ", name = "IsInvalidCharacter_OnlySpaces"}}	for i =1, #TestData do		Test[APIName.."_Response_info_" .. TestData[i].name .."_SendResponse"] = function(self)			-- mobile side: sending the request
			local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})			-- hmi side: expect the request
			EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
			:Do(function(_,data)
				-- hmi side: sending the response
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", TestData[i].value)
			end)			-- mobile side: expect the response
			local ExpectedResponse = commonFunctions:cloneTable({})
			ExpectedResponse["success"] = true
			ExpectedResponse["resultCode"] = "SUCCESS"
			ExpectedResponse["info"] = nil					
			EXPECT_RESPONSE(cid, ExpectedResponse)			
			:ValidIf (function(_,data)
							if data.payload.info then
								commonFunctions:printError(" SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\"")
								return false
							else 
								return true
							end
						end)						end
		-----------------------------------------------------------------------------------------		Test[APIName.."_Response_info_" .. TestData[i].name .."_SendError"] = function(self)			-- mobile side: sending the request
			local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})			-- hmi side: expect the request
			EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
			:Do(function(_,data)
				-- hmi side: sending the response
				self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", TestData[i].value)
			end)			-- mobile side: expect the response
			EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
			:ValidIf (function(_,data)
							if data.payload.info then
								commonFunctions:printError(" SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\"")
								return false
							else 
								return true
							end						end)						end	end -- end of for (TestData)
  ]]endverify_info_parameter()-----------------------------------------------------------------------------------------------
-- Parameter 4: correlationID 
-- -------------------------------------------------------------------------------------------
-- List of test cases: 
-- 1. IsMissed
-- 2. IsNonexistent
-- 3. IsWrongType
-- 4. IsNegative 
-----------------------------------------------------------------------------------------------local function verify_correlation_id_parameter()	-- Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup({"correlationID"})	-----------------------------------------------------------------------------------------
	SubscribeWayPoints_Success("SubscribeWayPoints_Success_8")
	-- 1. IsMissed	
	function Test:UnsubscribeWayPoints_Response_CorrelationID_IsMissed_SendResponse()		-- mobile side: sending the request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})
		-- hmi side: expect the request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Do(function(_,data)
			-- hmi side: sending the response
			-- self.hmiConnection:Send('{"id":'  .. tostring(data.id) .. ',"jsonrpc":"2.0","result":{"code":0,"method":"Navigation.UnsubscribeWayPoints"}}')			self.hmiConnection:Send('{"jsonrpc":"2.0", "code":0, "result":{"method":"Navigation.UnsubscribeWayPoints"}}')		end)
		-- mobile side: expect the response
		EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)	end
	-----------------------------------------------------------------------------------------	function Test:UnsubscribeWayPoints_Response_CorrelationID_IsMissed_SendError()		-- mobile side: sending the request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})		-- hmi side: expect the request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Do(function(_,data)
			-- hmi side: sending the response
			-- self.hmiConnection:Send('{"id":'  .. tostring(data.id) .. ',"jsonrpc":"2.0","result":{"code":0,"method":"Navigation.UnsubscribeWayPoints"}}')
			self.hmiConnection:Send('{"jsonrpc":"2.0","error":{"data":{"method":"Navigation.UnsubscribeWayPoints"},"code":22,"message":"The unknown issue occurred"}}')		end)		-- mobile side: expect the response
		EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)	end
	-----------------------------------------------------------------------------------------	-- 2. IsNonexistent
	function Test:UnsubscribeWayPoints_Response_CorrelationID_IsNonexistent_SendResponse()		-- mobile side: sending the request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})		-- hmi side: expect the request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Do(function(_,data)
			-- hmi side: sending the response
			-- self.hmiConnection:Send('{"id":'  .. tostring(data.id) .. ',"jsonrpc":"2.0","result":{"code":0,"method":"Navigation.UnsubscribeWayPoints"}}')
			 self.hmiConnection:Send('{"id":'  .. tostring(550) .. ',"jsonrpc":"2.0","result":{"code":0,"method":"Navigation.UnsubscribeWayPoints"}}')		end)		-- mobile side: expect the response
		EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)	end
	-----------------------------------------------------------------------------------------	function Test:UnsubscribeWayPoints_Response_CorrelationID_IsNonexistent_SendError()		-- mobile side: sending the request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})		-- hmi side: expect the request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Do(function(_,data)
			-- hmi side: sending the response
			-- self.hmiConnection:Send('{"id":'  .. tostring(data.id) .. ',{"jsonrpc":"2.0","error":{"data":{"method":"Navigation.UnsubscribeWayPoints"},"code":22,"message":"The unknown issue occurred"}}')
			self.hmiConnection:Send('{"id":'  .. tostring(550) .. ',{"jsonrpc":"2.0","error":{"data":{"method":"Navigation.UnsubscribeWayPoints"},"code":22,"message":"The unknown issue occurred"}}')
		end)		-- mobile side: expect the response
		EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)	end
	-----------------------------------------------------------------------------------------	-- 3. IsWrongType
	function Test:UnsubscribeWayPoints_Response_CorrelationID_IsWrongType_SendResponse()		-- mobile side: sending the request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})		--hmi side: expect the request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Do(function(_,data)
			-- hmi side: sending the response
			-- self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = "info message"})
      self.hmiConnection:SendResponse(tostring(data.id), data.method, "SUCCESS", {"info message"})		end)		-- mobile side: expect the response
		EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)	end
	-----------------------------------------------------------------------------------------	function Test:UnsubscribeWayPoints_Response_CorrelationID_IsWrongType_SendError()		-- mobile side: sending the request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})		-- hmi side: expect the request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Do(function(_,data)
			-- hmi side: sending the response
			-- self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "error message")
			self.hmiConnection:SendError(tostring(data.id), data.method, "GENERIC_ERROR",{"error message"})		end)		-- mobile side: expect the response
		EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)	end
	-----------------------------------------------------------------------------------------	-- 4. IsNegative 
	function Test:UnsubscribeWayPoints_Response_CorrelationID_IsNegative_SendResponse()		-- mobile side: sending the request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})		-- hmi side: expect the request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Do(function(_,data)
			-- hmi side: sending the response
			-- self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = "info message"})
			self.hmiConnection:SendResponse(-1, data.method, "SUCCESS", {info = "info message"})		end)		-- mobile side: expect the response
		EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)	end
	-----------------------------------------------------------------------------------------	function Test:UnsubscribeWayPoints_Response_CorrelationID_IsNegative_SendError()		-- mobile side: sending the request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})		-- hmi side: expect the request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Do(function(_,data)
			-- hmi side: sending the response
			-- self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "error message")
			self.hmiConnection:SendError(-1, data.method, "GENERIC_ERROR", {"error message"})		end)		-- mobile side: expect the response
		EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)	end
	-----------------------------------------------------------------------------------------	-- 5. IsNull
	function Test:UnsubscribeWayPoints_Response_CorrelationID_IsNull_SendResponse()		-- mobile side: sending the request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})		-- hmi side: expect the request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Do(function(_,data)
			-- hmi side: sending the response
			-- self.hmiConnection:Send('{"id":'  .. tostring(data.id) .. ',"jsonrpc":"2.0","result":{"code":0,"method":"Navigation.UnsubscribeWayPoints"}}')
			self.hmiConnection:Send('{"id":'  .. tostring(null) .. ',"jsonrpc":"2.0","result":{"code":0,"method":"Navigation.UnsubscribeWayPoints"}}')		end)		-- mobile side: expect the response
		EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)	end
	-----------------------------------------------------------------------------------------	function Test:UnsubscribeWayPoints_Response_CorrelationID_IsNull_SendError()		-- mobile side: sending the request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})		-- hmi side: expect the request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Do(function(_,data)
			-- hmi side: sending the response
			-- self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","error":{"data":{"method":"Navigation.UnsubscribeWayPoints"},"code":22,"message":"The unknown issue occurred"}}')
			self.hmiConnection:Send('{"id":null,"jsonrpc":"2.0","error":{"data":{"method":"Navigation.UnsubscribeWayPoints"},"code":22,"message":"The unknown issue occurred"}}')		end)		-- mobile side: expect the response
		EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)	end
	-----------------------------------------------------------------------------------------end	verify_correlation_id_parameter()----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK IV----------------------------------------
----------------------------Check special cases of HMI notification---------------------------
----------------------------------------------------------------------------------------------
-- Related requirements: APPLINK-21641-- Verification criteria
--[[ 
	1. InvalidJsonSyntax
	2. InvalidStructure
	3. FakeParams 
	4. FakeParameterIsFromAnotherAPI
	5. SeveralNotifications with the same values
	6. SeveralNotifications with different values
]]
commonFunctions:newTestCasesGroup("Test suite IV: SpecialHMIResponseCheck")	local function special_notification_checks()	-- 1. Verify UnsubscribeWayPoints with invalid Json syntax
	-- --------------------------------------------------------------------------------------------
	-- Requirement id in JAMA/or Jira ID:
	-- Verification criteria: Invalid structure of response.	SubscribeWayPoints_Success("Precondition_SubscribleWayPoints_7")	function Test:UnsubscribeWayPoints_Response_IsInvalidJson()		commonTestCases:DelayedExp(2000)
		 -- mobile side: UnsubscribeWayPoints request		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})		-- hmi side: expected UnsubscribeWayPoints request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
			:Do(function(_,data)
				-- hmi side: sending the response
				-- self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0, "method":"Navigation.UnsubscribeWayPoints"}}')
				 self.hmiConnection:Send('{"id";'  .. tostring(data.id) .. ',"jsonrpc":"2.0","result":{"code":0,"method":"Navigation.UnsubscribeWayPoints"}}')			end)		-- mobile side: expect the response
		EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "GENERIC_ERROR" })
		:Timeout(12000)	end		
  --------------------------------------------------------------------------------------------
  	-- 2. Verify parameter is not from any API	function Test:UnsubscribeWayPoints_Response_FakeParams_IsNotFromAnyAPI()		commonTestCases:DelayedExp(2000)		-- mobile side: send UnsubscribeWayPoints request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})		-- hmi side: there is no UnsubscribeWayPoints request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Do(function(_,data)			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {fake="fake"})		end)		-- mobile side: expect the response
		EXPECT_RESPONSE(CorIdSWP, { success = true, resultCode = "SUCCESS"})
		:ValidIf (function(_,data)			if data.payload.fake then
				commonFunctions:printError(" SDL resend fake parameter to mobile app ")
				return false
			else 
				return true
			end -- end of If		end) -- end of ValidIf  end	-- Post Condition
	SubscribeWayPoints_Success("Precondition_SubscribleWayPoints_8")
  --------------------------------------------------------------------------------------------
  	-- 3. Verify parameter is from other API
	function Test:UnsubscribeWayPoints_FakeParams_IsFromAnotherAPI()		-- mobile side: sending the request
		local cid = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})		-- hmi side: expect the request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")	
		:Do(function(_,data)
			-- hmi side: sending the response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{sliderPosition=5})
		end)
		-- mobile side: expect the response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
		:ValidIf (function(_,data)
			if data.payload.sliderPosition then
				commonFunctions:printError(" SDL resend fake parameter to mobile app ")
				return false
			else 
				return true
			end
		end)	end									-- Post Condition
	SubscribeWayPoints_Success("Precondition_SubscribleWayPoints_9")
  --------------------------------------------------------------------------------------------
  	-- 4. Verify response is invalid json
	function Test:UnsubscribeWayPoints_Response_IsInvalidStructure()		-- mobile side: sending the request		local cid = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})		-- hmi side: expect the request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")		
		:Do(function(_,data)
			-- hmi side: sending the response
			-- self.hmiConnection:Send('{"id":'  .. tostring(data.id) .. ',"jsonrpc":"2.0","result":{"code":0,"method":"Navigation.UnsubscribeWayPoints"}}')
			self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0", "code":0, "result":{"method":"Navigation.UnsubscribeWayPoints"}}')		end)									-- mobile side: expect response 
		EXPECT_RESPONSE(cid, {  success = false, resultCode = "INVALID_DATA"})
		:Timeout(12000)	end	 -- Postcondition
	SubscribeWayPoints_Success("Precondition_SubscribleWayPoints_10")
  --------------------------------------------------------------------------------------------
  	-- 5. Verification criteria: the request is sent 2 times concusively	function Test:UnsubscribeWayPoints_Success()		self:unSubscribeWayPoints()	end	function Test:UnsubscribeWayPoints_IGNORED()		commonTestCases:DelayedExp(2000)		-- mobile side: UnsubscribeWayPoints request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})		-- hmi side: expected UnsubscribeWayPoint request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Times(0)		-- mobile side: UnsubscribeWayPoints response
		EXPECT_RESPONSE(CorIdSWP,{ success = false, resultCode = "IGNORED"})		EXPECT_NOTIFICATION("OnHashChange")
		:Times(0)
	end
  	-- Postcondition
	SubscribeWayPoints_Success("Precondition_SubscribleWayPoints_11")
  --------------------------------------------------------------------------------------------
  	--6. Verification criteria: HMI send error to SDL
	function Test:UnsubscribeWayPoints_GENERIC_ERROR()		commonTestCases:DelayedExp(2000)
		-- mobile side: send UnsubscribeWayPoints request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})		-- hmi side: expected UnsubscribeWayPoints request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")		:Do(function(_,data)
			-- hmi side: sending UI.AddCommand response
			self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "")
		end)		EXPECT_RESPONSE("UnsubscribeWayPoints", {success = false , resultCode = "GENERIC_ERROR"})		EXPECT_NOTIFICATION("OnHashChange")
		:Times(0)
	end
  --------------------------------------------------------------------------------------------
  	-- 7. Verification criteria: SDL returns UNSUPPORTED_RESOURCE code for the request sent
	-- ToDo: Need to update test case according to APPLINK-26029	function Test:UnsubscribeWayPoints_UNSUPPORTED_RESOURCE()		commonTestCases:DelayedExp(2000)		-- mobile side: send UnsubscribeWayPoints request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})		-- hmi side: expected UnsubscribeWayPoints request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")		:Do(function(_,data)
			-- hmi side: sending UI.AddCommand response
			self.hmiConnection:SendError(data.id, data.method, "UNSUPPORTED_RESOURCE", "")
		  end)		EXPECT_RESPONSE("UnsubscribeWayPoints", {success = false , resultCode = "UNSUPPORTED_RESOURCE"})		EXPECT_NOTIFICATION("OnHashChange")
		:Times(0)	 end
  --------------------------------------------------------------------------------------------
  	-- 8. SDL must respond with "GENERIC_ERROR" in case HMI does NOT respond during <DefaultTimeout>	function Test:UnsubscribeWayPoints_HMI_NoResponse()		commonTestCases:DelayedExp(2000)		-- mobile side: send UnsubscribeWayPoints request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})		-- hmi side: expected UnsubscribeWayPoints request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")		-- mobile side: UnsubscribeWayPoints response
		EXPECT_RESPONSE("UnsubscribeWayPoints", {success = false , resultCode = "GENERIC_ERROR", info = "Navigation component does not respond"})
		:Timeout(12000)		EXPECT_NOTIFICATION("OnHashChange")
		:Times(0)	end
  --------------------------------------------------------------------------------------------
  	-- 9.Verification criteria: Several response to one request	function Test:UnsubscibeWayPoints_Response_SeveralResponseToOneRequest()    commonTestCases:DelayedExp(2000)    -- mobile side: send UnsubscribeWayPoints request
    local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})    -- hmi side: expected UnsubscribeWayPoints request
    EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")		
    :Do(function(exp,data)      self.hmiConnection:SendResponse(data.id, data.method, "INVALID_DATA", {})
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})    end)    --mobile side: expect response 
    EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "INVALID_DATA"})	end	
  --------------------------------------------------------------------------------------------
  	-- 10.Verification criteria: Missed parameters in response
	function Test:UnsubscibeWayPoints_Response_IsMissedAllPArameters()			-- mobile side: send UnsubscribeWayPoints request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})			-- hmi side: expect the request
			EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
			:Do(function(_,data)
				-- hmi side: sending Navigation.UnsubscribeWayPoints" response
				-- self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"code":0, "method":"Navigation.UnsubscribeWayPoints"}}')
				self.hmiConnection:Send('{}')
			end)			-- mobile side: expect the response
			EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "GENERIC_ERROR"})
		:Timeout(13000)	endendspecial_notification_checks()	--------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK V---------------------------------------
--------------------------------------Check All Result Codes--------------------------------
--------------------------------------------------------------------------------------------
-- Begin Test case resultcode_checks
-- Description: Check all resultCodes-- Requirement id in JAMA: 
-- APPLINK-21902 (SUCCESS)
-- APPLINK-16739 (INVALID_DATA)
-- APPLINK-16746 (APPLICATION_NOT_REGISTERED)
-- APPLINK-17396 (GENERIC_ERROR)
-- APPLINK-17008 (GENERIC_ERROR)
-- APPLINK-21903 (DISALLOWED)
-- APPLINK-19584 (USER_DISALLOWED)local function resultcode_checks()	-- Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup("Test Suite For resultCodes Checks")
	----------------------------------------------------------------------------------------------	-- SUCCESS: Covered by many test cases.
	-- INVALID_DATA: Covered by many test cases.	-- GENERIC_ERROR: Covered by test case UnsubscribeWayPoints_HMI_NoResponse
	-- GENERIC_ERROR: Covered by test case UnsubscribeWayPoints_GENERIC_ERROR
	-----------------------------------------------------------------------------------------	-- 1. Verification criteria: the request is sent 2 times concusively	function Test:UnsubscribeWayPoints_Success()		self:unSubscribeWayPoints()	end
  	function Test:UnsubscribeWayPoints_IGNORED_2TimesConcusively()		commonTestCases:DelayedExp(2000)		-- mobile side: UnsubscribeWayPoints request
		local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})		-- hmi side: expected UnsubscribeWayPoints request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Times(0)		-- mobile side: UnsubscribeWayPoints response
		EXPECT_RESPONSE(CorIdSWP,{ success = false, resultCode = "IGNORED"})		EXPECT_NOTIFICATION("OnHashChange")
		:Times(0)
	end
  --------------------------------------------------------------------------------------------
   	-- Precondition
	SubscribeWayPoints_Success("Precondition_SubscribleWayPoints_12")
   Test[APIName.."_Response_MissingMandatoryParameters_GENERIC_ERROR"] = function(self)		    -- mobile side: send UnsubscribeWayPoints request
    local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})    -- hmi side: expected UnsubscribeWayPoints request
    EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
    :Do(function(_,data)
    -- hmi side: Sending response
      -- self.hmiConnection:Send('{"id":'  .. tostring(data.id) .. ',"jsonrpc":"2.0","result":{"code":0,"method":"Navigation.UnsubscribeWayPoints"}}')
      self.hmiConnection:Send('{"jsonrpc":"2.0", "code":0, "result":{}')
    end)    -- mobile side: expect the response
    EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "GENERIC_ERROR"})
    :Timeout(13000)  end	
  --------------------------------------------------------------------------------------------
    Test[APIName.."_Response_MissingAllParameters_GENERIC_ERROR"] = function(self)		    -- mobile side: send UnsubscribeWayPoints request
    local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})    -- hmi side: expected UnsubscribeWayPoints request
    EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
    :Do(function(_,data)
      -- hmi side: Sending response
      -- self.hmiConnection:Send('{"id":'  .. tostring(data.id) .. ',"jsonrpc":"2.0","result":{"code":0,"method":"Navigation.UnsubscribeWayPoints"}}')      self.hmiConnection:Send('{}')		
    end)    -- mobile side: expect the response
    EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "GENERIC_ERROR"})
    :Timeout(13000)  end						  --------------------------------------------------------------------------------------------
  -- Description:  SDL sends APPLICATION_NOT_REGISTERED code when the app sends a request within the same connection before RegisterAppInterface has been performed yet.  -- Requirement id in JAMA: APPLINK-16746
			commonTestCases:verifyResultCode_APPLICATION_NOT_REGISTERED()
  --------------------------------------------------------------------------------------------  -- Requirement id in JAMA: APPLINK-21903, APPLINK-19584
  -- Verification criteria: 
  -- 1. SDL must return "resultCode: DISALLOWED, success:false" to the RPC in case this RPC is omitted in the PolicyTable group(s) assigned to the app that requests this RPC.
  -- 2. SDL must return "resultCode: DISALLOWED, success:false" to the RPC in case this RPC is included to the PolicyTable group(s) assigned to the app that requests this RPC and the group has not yet received user's consents.		
  -- SDL must return "resultCode: USER_DISALLOWED, success:false" to the RPC in case this RPC exists in the PolicyTable group disallowed by the user.  
  -- Description: 1. SDL must return "resultCode: DISALLOWED, success:false" to the RPC in case this RPC is omitted in the PolicyTable group(s) assigned to the app that requests this RPC.
  testCasesForPolicyTable:checkPolicyWhenAPIIsNotExist()	
    -- Restore Policy
  testCasesForPolicyTable:updatePolicy(policy_file_name)	
	-----------------------------------------------------------------------------------------endresultcode_checks()----------------------------------------------------------------------------------------------
-----------------------------------------TEST BLOCK VI----------------------------------------
-------------------------Sequence with emulating of user's action(s)--------------------------
----------------------------------------------------------------------------------------------	
--Not appropriate
---------------------------------------------------------------------------------------------
---------------------------------------TEST BLOCK VII---------------------------------------
------------------------------------Different HMIStatus-------------------------------------
--------------------------------------------------------------------------------------------
-- Verification criteria: send UnsubscribeWayPoints in different HMI Level
-- Requirement id in JIRA: APPLINK-23004
-- [[
	-- 1. One app is None
	-- 2. One app is Limited
	-- 3. One app is Background-- ]]commonFunctions:newTestCasesGroup("Test suite VII: Different HMI Level Checks")local function different_hmilevel_checks()
	-- Precondition
	SubscribeWayPoints_Success("Precondition_SubscribleWayPoints_11")	-- Description: Checking "DISALLOWED" result code in case HMI does NOT respond during <DefaultTimeout>
	-- Requirement id in JIRA: APPLINK-23004
	commonSteps:DeactivateAppToNoneHmiLevel()	function Test:UnsubscribeWayPoints_Notification_InNoneHmiLevel()		commonTestCases:DelayedExp(2000)
		-- mobile side: sending UnsubscribeWayPoints request
		local cid = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})
		-- hmi side: expect UnsubscribeWayPoints request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints") 
		:Times(0)
		-- mobile side: expect UnsubscribeWayPoints response
		EXPECT_RESPONSE(cid,
		{ success = false, resultCode = "DISALLOWED" }
		)
	end	
  	-- Postcondition: Activate app
	commonSteps:ActivationApp(_,"Postcondition_UnsubscribeWayPoints_CaseAppIsNone")	
  --------------------------------------------------------------------------------------------
  	-- 2. HMI level is LIMITED
	if commonFunctions:isMediaApp() then
		commonSteps:ChangeHMIToLimited()
		-- Description: Checking "SUCCESS" result code in case LIMITED HMI Level
		-- Requirement id in JIRA: APPLINK-23004
    function Test:UnsubscribeWayPoints_Notification_InLimitedHmiLevel()      -- mobile side: sending UnsubscribeWayPoints request
      local cid = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})      -- hmi side: expect UnsubscribeWayPoints request
      EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
      :Do(function(_,data)
        -- hmi side: sending VehicleInfo.UnsubscribeWayPoints response
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})	
      end)      -- mobile side: expect UnsubscribeWayPoints response
      EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })      -- mobile side: expect OnHashChange notification
      -- TODO: This step is failed due to APPLINK-25808 defect. Should be uncommented after defect is fixed.
      -- EXPECT_NOTIFICATION("OnHashChange")    end
	end
  	-- Postcondition: Activate app
	commonSteps:ActivationApp(_,"Postcondition_UnsubscribeWayPoints_Notification_InLimitedHmiLevel_ActivateApp")	--------------------------------------------------------------------------------------------
  
  -- 3. HMI level is BACKGROUND
	-- Description: Checking "SUCCESS" result code in case LIMITED HMI Level
	-- Requirement id in JIRA: APPLINK-23004
	----------------------------------------------------------------------------------------------
  	commonTestCases:ChangeAppToBackgroundHmiLevel()
  	-- Precondition
	SubscribeWayPoints_Success("Precondition_SubscribleWayPoints_12")
  	function Test:UnsubscribeWayPoints_Notification_InBackgroundHmiLevel()		-- mobile side: sending UnsubscribeWayPoints request
		local cid = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})		-- hmi side: expect UnsubscribeWayPoints request
		EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
		:Do(function(_,data)
			-- hmi side: sending VehicleInfo.UnsubscribeWayPoints response
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})	
		end)		-- mobile side: expect UnsubscribeWayPoints response
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })		-- mobile side: expect OnHashChange notification
		-- TODO: This step is failed due to APPLINK-25808 defect. Should be uncommented after defect is fixed.
		-- EXPECT_NOTIFICATION("OnHashChange")	endenddifferent_hmilevel_checks()
-- Restore preloaded pttestCasesForPolicyTable:Restore_preloaded_pt()return Test