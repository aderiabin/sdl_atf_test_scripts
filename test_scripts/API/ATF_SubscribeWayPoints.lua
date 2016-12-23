-------------------------------------------------------------------------------------------------
-------------------------------------------- Preconditions --------------------------------------
-------------------------------------------------------------------------------------------------local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')commonSteps:DeleteLogsFileAndPolicyTable()
if commonSteps:file_exists(config.pathToSDL .. "policy.sqlite") == true then
    os.remove(config.pathToSDL .. "policy.sqlite")
end--------------------------------------------------------------------------------
-- Precondition: preparation connecttest_SWP.lua
commonPreconditions:Connecttest_without_ExitBySDLDisconnect("connecttest_SWP.lua")
--------------------------------------------------------------------------------
---------------------------------------------------------------------------------- Backup, updated preloaded file
-------------------------------------------------------------------------------------
commonSteps:DeleteLogsFileAndPolicyTable()os.execute(" cp " .. config.pathToSDL .. "/sdl_preloaded_pt.json " .. config.pathToSDL .. "/sdl_preloaded_pt_origin.json" )
f = assert(io.open(config.pathToSDL.. "/sdl_preloaded_pt.json", "r"))fileContent = f:read("*all")-- default sectionDefaultContant = fileContent:match('"rpcs".?:.?.?%{')if not DefaultContant then
  print ( " \27[31m  rpcs is not found in sdl_preloaded_pt.json \27[0m " )
else
   DefaultContant =  string.gsub(DefaultContant, '"rpcs".?:.?.?%{', '"rpcs": { \n"SubscribeWayPoints": {\n "hmi_levels": [\n  "BACKGROUND",\n   "FULL",\n   "LIMITED" \n]\n},\n"UnsubscribeWayPoints": { \n"hmi_levels": [\n   "BACKGROUND",\n   "FULL", \n  "LIMITED" \n]\n},')
endfileContent  =  string.gsub(fileContent, '"rpcs".?:.?.?%{', DefaultContant)f = assert(io.open(config.pathToSDL.. "/sdl_preloaded_pt.json", "w+"))f:write(fileContent)
f:close()
-- os.execute(" cp " .. config.pathToSDL .. "sdl_preloaded_pt.json " .. config.pathToSDL .. "sdl_preloaded_pt_corrected.json" )
-------------------------------------------------------------------------------------Test = require('user_modules/connecttest_SWP')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local policyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')require('user_modules/AppTypes')
local json = require("json")

--------------------------------------------------------------------------------------- upper bound "info" param maxlengt=1000
local infoMessage1000 = "1qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'"
local infoMessage1001 = "1qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYqwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=QWERTYUIOPASDFGHJKLZXCVBNM{}|?>:<qwertyuiopasdfghjklzxcvbnm1234567890[]'.!@#$%^&*()_+-=qwertyuiopasdfghjklzxcvbnm1234567890[]'2"APIName = "SubscribeWayPoints" -- set request nameconfig.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

-- ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2
local function userPrint( color, message)  print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
end
local function IGNITION_OFF(self, appNumber)
  StopSDL()  if appNumber == nil then
    appNumber = 1
  end  -- hmi side: sends OnExitAllApplications (SUSPENDED)
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
    {
      reason = "IGNITION_OFF"
    })  -- hmi side: expect OnSDLClose notification
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")  -- hmi side: expect OnAppUnregistered notification
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
  :Times(appNumber)  -- Check that SDL doesn't send UnsubscribeWayPoints when Ignition OFF
  EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
  :Times(0)  commonTestCases:DelayedExp(1000)
end
local function subscribewaypoints_success(TestName)
  Test[TestName] = function(self)
    -- Requirement id in JAMA/or Jira ID:
    -- APPLINK-21629 #1    -- mobile side: send SubscribeWayPoints request
    local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})    -- hmi side: expected SubscribeWayPoints request
    EXPECT_HMICALL("Navigation.SubscribeWayPoints")
    :Do(function(_,data)
        -- hmi side: sending Navigation.SubscribeWayPoints response
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)    -- mobile side: SubscribeWayPoints response
    EXPECT_RESPONSE(CorIdSWP, {success = true , resultCode = "SUCCESS"} )    EXPECT_NOTIFICATION("OnHashChange")
    :Times(1)
  end
end
local function postcondition_unsubscribewaypoints_success(TestName)
  Test[TestName] = function(self)
    -- mobile side: send UnsubscribeWayPoints request
    local CorIdSWP = self.mobileSession:SendRPC("UnsubscribeWayPoints", {})
    -- hmi side: expected UnsubscribeWayPoints request    EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
    :Do(function(_,data)
      -- hmi side: sending Navigation.UnsubscribeWayPoints response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)    -- mobile side: UnsubscribeWayPoints response
    EXPECT_RESPONSE(CorIdSWP,   {success = true , resultCode = "SUCCESS"})    EXPECT_NOTIFICATION("OnHashChange")
  end
end---------------------------------------------------------------------------------------------
-------------------------------------------PreConditions-------------------------------------
----------------------------------------------------------------------------------------------- Begin PreCondition.1
-- Description: removing user_modules/connecttest_SWP.lua
function Test:Precondition_remove_user_connecttest()
      os.execute( "rm -f ./user_modules/connecttest_SWP.lua" )
end
-- End PreCondition.1-- Begin PreCondition.2

-- Description: Activation applicationfunction Test:ActivationApp1()  userPrint(34, "=================== Test Case ===================")
  --hmi side: sending SDL.ActivateApp request
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,data)
    if data.result.isSDLAllowed ~= true then
      local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})      -- hmi side: expect SDL.GetUserFriendlyMessage message response
      -- TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      EXPECT_HMIRESPONSE(RequestId)
      :Do(function(_,data)
          -- hmi side: send request SDL.OnAllowSDLFunctionality
          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})          -- hmi side: expect BasicCommunication.ActivateApp request
          EXPECT_HMICALL("BasicCommunication.ActivateApp")
          :Do(function(_,data)
              -- hmi side: sending BasicCommunication.ActivateApp response
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
            end)
          :Times(AnyNumber())
        end)    end
  end)  -- mobile side: expect notification
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL"},"OnHMIStatus", {hmiLevel = "FULL"})
end
-- End PreCondition.2--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
------CommonRequestCheck: Check of mandatory/conditional request's parameters (mobile protocol)----
----------------------------------------------------------------------------------------------- Begin Test suit CommonRequestCheck
-- Description:
-- request with all parameters
-- request with only mandatory parameters
-- request with all combinations of conditional-mandatory parameters (if exist)
-- request with one by one conditional parameters (each case - one conditional parameter)
-- request with missing mandatory parameters one by one (each case - missing one mandatory parameter)
-- request with all parameters are missing
-- request with fake parameters (fake - not from protocol, from another request)
-- request is sent with invalid JSON structure
-- different conditions of correlationID parameter (invalid, several the same etc.)
----------------------------------------------------------------------------------------------------------
-- Begin Test case CommonRequestCheck.1
-- Description: Success resultCode-- Requirement id in JAMA/or Jira ID:
-- APPLINK-21629 #1-- Verification criteria:
-- In case mobile app sends the valid SubscribeWayPoints_request to SDL and this request is allowed by Policies SDL must: transfer SubscribeWayPoints_request_ to HMI respond with <resultCode> received from HMI to mobile app
-- The request for SubscribeWayPoints is sent and executed successfully. The response code SUCCESS is returned.subscribewaypoints_success("SubscribeWayPoints_Success_1")
-- Postconditionpostcondition_unsubscribewaypoints_success("Unsubscribewaypoints_success_1")-- End Test suit CommonRequestCheck.1
-----------------------------------------------------------------------------------------------------------
-- Begin Test case CommonRequestCheck.2
-- Description: Check processing invalid format of JSON message of SubscribeWayPoints request-- Requirement id in JAMA/or Jira ID:
-- APPLINK-21629 #3-- Verification criteria: the request is sent invalid format of JSON message, the response comes with INVALID_DATA result code.function Test:SubscribeWayPoints_InvalidJSON()
  userPrint(34, "=================== Test Case ===================")
  self.mobileSession.correlationId = self.mobileSession.correlationId + 1  -- mobile side: SubscribeWayPoints request
  local msg =
  {
    serviceType = 7,
    frameInfo = 0,
    rpcType = 0,
    rpcFunctionId = 42,
    rpcCorrelationId = self.mobileSession.correlationId,
    --<<!-- extra ','
    payload = '{,}'
  }
  self.mobileSession:Send(msg)  -- hmi side: there is no SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Times(0)  commonTestCases:DelayedExp(1000)  -- mobile side:SubscribeWayPoints response
  self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)  commonTestCases:DelayedExp(1000)
end
-------------------------------------------------------------------------------------------- Begin Test case CommonRequestCheck.3
-- Description: Check processing SubscribeWayPoints request with fake parameter-- Requirement id in JAMA/or Jira ID:
-- APPLINK-21629 #3-- Verification criteria:
-- According to APPLINK-13008 and APPLINK-11906 SDL must cut off fake parameters and process only parameters valid for named requestfunction Test:SubscribeWayPoints_FakeParam()
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {fakeParam = "fakeParam"})  -- hmi side: there is no SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Times(1)  :Do(function(_,data)
    -- hmi side: sending Navigation.SubscribeWayPoints response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  :ValidIf(function(_,data)
      if data.params then
        print("SDL re-sends fakeParam parameters to HMI in SubscribeWayPoints request")
        return false
      else
        return true
      end
    end)  -- mobile side: SubscribeWayPoints response
  self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = true, resultCode = "SUCCESS"})  EXPECT_NOTIFICATION("OnHashChange")
  :Times(1)end-- Postconditionpostcondition_unsubscribewaypoints_success("Unsubscribewaypoints_success_2")
------------------------------------------------------------------------------------------------------------
-- Begin Test case CommonRequestCheck.4
-- Description: Check processing UnregisterAppInterface request with parameters from another request-- Requirement id in JAMA/or Jira ID:
-- APPLINK-21629 #3-- Verification criteria:
-- In case mobile app sends the SubscribeWayPoints_request to SDL with invalid format of JSON message SDL must: consider this request as invalid respond "INVALID_DATA, success:false" to mobile appfunction Test:SubscribeWayPoints_AnotherRequest()
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: UnregisterAppInterface request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", { menuName = "shouldn't be transfered" })  -- hmi side: there is no SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Times(1)  :Do(function(_,data)
    -- hmi side: sending Navigation.SubscribeWayPoints response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  :ValidIf(function(_,data)
      if data.params then
        print("SDL re-sends fakeParam parameters to HMI in SubscribeWayPoints request")
        return false
      else
        return true
      end
    end)  -- mobile side: SubscribeWayPoints response
  self.mobileSession:ExpectResponse(self.mobileSession.correlationId, { success = true, resultCode = "SUCCESS" })  EXPECT_NOTIFICATION("OnHashChange")
  :Times(1)end--Postconditionpostcondition_unsubscribewaypoints_success("Unsubscribewaypoints_success_3")
------------------------------------------------------------------------------------------
-- Begin Test case CommonRequestCheck.5
-- Description: Check processing requests with duplicate correlationID
-- TODO: fill Requirement, Verification criteria about duplicate correlationID
-- Requirement id in JAMA/or Jira ID:
-- APPLINK-21629 #6-- Verification criteria: In case mobile app already subscribed on wayPoints-related parameters and the same mobile app sends SubscribeWayPoints_request to SDL SDL must: respond "IGNORED, success:false" to mobile appfunction Test:SubscribeWayPoints_correlationIdDuplicateValue()
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints",{})  self.mobileSession.correlationId = CorIdSWP  -- hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Times(1)  :Do(function(_,data)
    -- hmi side: sending Navigation.SubscribeWayPoints response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  :Times(1)  -- mobile side: SubscribeWayPoints response
  EXPECT_RESPONSE(CorIdSWP,
    { success = true, resultCode = "SUCCESS"},
    { success = false, resultCode = "IGNORED"})
  :Times(2)
  :Do(function(exp,data)      if exp.occurences == 1 then        -- mobile side: SubscribeWayPoints request
        local msg =
        {
          serviceType = 7,
          frameInfo = 0,
          rpcType = 0,
          rpcFunctionId = 42,
          rpcCorrelationId = self.mobileSession.correlationId,
          payload = '{}'
        }
        self.mobileSession:Send(msg)
      end    end)  EXPECT_NOTIFICATION("OnHashChange")
  :Times(1)end-- Postconditionpostcondition_unsubscribewaypoints_success("Unsubscribewaypoints_success_4")--------------------------------------------------------------------------------------------
----------------------------------------II TEST BLOCK----------------------------------------
----------------------------------------Positive cases---------------------------------------
-----------------------------------------------------------------------------------------------=================================================================================--
--------------------------------Positive request check-------------------------------
--=================================================================================---- Begin Test suit PositiveRequestCheck
-- Description: Check of each request parameter value in bound and boundary conditions
-- -------------------------------------------------------------------------------------- Begin Test case PositiveRequestCheck.1
-- Description: Check "info" parameter in response with lower bound, in bound and upper bound values-- Requirement id in JIRA:
-- APPLINK-21629-- Verification criteria:
-- TODO: add verification criteria-- Description: info - lower bound (SendResponse)function Test:SubscribeWayPoints_SendResponse_info_lower_bound()
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})  -- hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")  :Do(function(_,data)
    -- hmi side: sending Navigation.SubscribeWayPoints response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = "a"} )
  end)  -- mobile side: SubscribeWayPoints response
  EXPECT_RESPONSE(CorIdSWP, {success = true , resultCode = "SUCCESS", info = "a"})  EXPECT_NOTIFICATION("OnHashChange")end-- Postconditionpostcondition_unsubscribewaypoints_success("Unsubscribewaypoints_success_5")
-- Description: info - lower bound (SendError)function Test:SubscribeWayPoints_SendError_info_lower_bound()
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})  -- hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")  :Do(function(_,data)
    -- hmi side: sending Navigation.SubscribeWayPoints response
    self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "a" )
  end)  -- mobile side: SubscribeWayPoints response
  EXPECT_RESPONSE(CorIdSWP, {success = false , resultCode = "GENERIC_ERROR", info = "a"})  EXPECT_NOTIFICATION("OnHashChange")
  :Times (0)
  commonTestCases:DelayedExp(1000)end-- End Test case PositiveRequestCheck.1
-----------------------------------------------------------------------------------------
-- Begin Test case PositiveRequestCheck.2
-- Description: Check "info" parameter in response with upper bound, in bound and upper bound values-- Requirement id in JIRA:
-- APPLINK-21629-- Verification criteria:
-- TODO: add verification criteria-- Description: info - upper bound (SendResponse)function Test:SubscribeWayPoints_SendResponse_info_upper_bound()
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})  -- hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")  :Do(function(_,data)
    -- hmi side: sending Navigation.SubscribeWayPoints response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = infoMessage1000} )
  end)  -- mobile side: SubscribeWayPoints response
  EXPECT_RESPONSE(CorIdSWP, {success = true , resultCode = "SUCCESS", info = infoMessage1000})  EXPECT_NOTIFICATION("OnHashChange")end-- Postconditionpostcondition_unsubscribewaypoints_success("Unsubscribewaypoints_success_6")
-- Description: info - upper bound (SendError)function Test:SubscribeWayPoints_SendError_info_upper_bound()
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})  --hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")  :Do(function(_,data)
    -- hmi side: sending Navigation.SubscribeWayPoints response
    self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoMessage1000 )
   end)  -- mobile side: SubscribeWayPoints response
  EXPECT_RESPONSE(CorIdSWP, {success = false , resultCode = "GENERIC_ERROR", info = infoMessage1000})  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)
  commonTestCases:DelayedExp(1000)end-- End Test case PositiveRequestCheck.2
-------------------------------------------------------------------------------------------------------
-- Begin Test case PositiveRequestCheck.3
-- Description: Check "info" parameter in response with upper bound, in bound and upper bound values-- Requirement id in JIRA:
-- APPLINK-21629-- Verification criteria:
-- TODO: add verification criteria-- Description: info - in bound (SendResponse)function Test:SubscribeWayPoints_SendResponse_info_in_bound()
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})  -- hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")  :Do(function(_,data)
    -- hmi side: sending Navigation.SubscribeWayPoints response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = "in_bound_information123"} )
  end)  -- mobile side: SubscribeWayPoints response
  EXPECT_RESPONSE(CorIdSWP, {success = true , resultCode = "SUCCESS", info = "in_bound_information123"})  EXPECT_NOTIFICATION("OnHashChange")end-- Postconditionpostcondition_unsubscribewaypoints_success("Unsubscribewaypoints_success_7")
-- Description: info - in bound (SendError)function Test:SubscribeWayPoints_SendError_info_in_bound()
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})  -- hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")  :Do(function(_,data)
    -- hmi side: sending Navigation.SubscribeWayPoints response
    self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "in_bound_information123" )
  end)  -- mobile side: SubscribeWayPoints response
  EXPECT_RESPONSE(CorIdSWP, {success = false, resultCode = "GENERIC_ERROR", info = "in_bound_information123"})  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)
  commonTestCases:DelayedExp(1000)end----------------------------------------------------------------------------------------------
----------------------------------------III TEST BLOCK----------------------------------------
----------------------------------------Negative cases----------------------------------------
-----------------------------------------------------------------------------------------------=================================================================================--
---------------------------------Negative request check------------------------------
--=================================================================================----------Checks-----------
-- check "info" value in out of bound, missing, with wrong type, empty, duplicate etc.
-- Begin Test case NegativeRequestCheck.1
-- info param is empty (SendResponse)function Test:SubscribeWayPoints_SendResponse_info_empty()
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})  -- hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")  :Do(function(_,data)
    -- hmi side: sending Navigation.SubscribeWayPoints response
    -- According CRS APPLINK-14551 In case HMI responds via RPC with "message" param AND the value of "message" param is empty SDL must NOT transfer "info" parameter via corresponding RPC to mobile app
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = ""} )
  end)  -- mobile side: SubscribeWayPoints response
  EXPECT_RESPONSE(CorIdSWP, {success = true , resultCode = "SUCCESS"})  EXPECT_NOTIFICATION("OnHashChange")end-- Postconditionpostcondition_unsubscribewaypoints_success("Unsubscribewaypoints_success_8")
-- info param is empty (SendError)
function Test:SubscribeWayPoints_SendError_info_empty()
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})  -- hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")  :Do(function(_,data)
    -- hmi side: sending Navigation.SubscribeWayPoints response
    -- According CRS APPLINK-14551 In case HMI responds via RPC with "message" param AND the value of "message" param is empty SDL must NOT transfer "info" parameter via corresponding RPC to mobile app
    self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR",  "" )
  end)  -- mobile side: SubscribeWayPoints response
  EXPECT_RESPONSE(CorIdSWP, {success = false , resultCode = "GENERIC_ERROR"})  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)
  commonTestCases:DelayedExp(1000)end-- End Test case NegativeRequestCheck.1
--------------------------------------------------------------------------------------------------
-- Begin Test case NegativeRequestCheck.2
-- info param is out of upper bound (SendResponse)function Test:SubscribeWayPoints_SendResponse_info_out_upper_bound()
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})  -- hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")  :Do(function(_,data)
    -- hmi side: sending Navigation.SubscribeWayPoints response
    -- According CRS APPLINK-14551 In case SDL receives <message> from HMI with maxlength more than defined for <info> param at MOBILE_API SDL must:truncate <message> to maxlength of <info> defined at MOBILE_API
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { info = infoMessage1001} )
  end)  -- mobile side: SubscribeWayPoints response
  EXPECT_RESPONSE(CorIdSWP, {success = true , resultCode = "SUCCESS", info = infoMessage1000})  EXPECT_NOTIFICATION("OnHashChange")end-- Postconditionpostcondition_unsubscribewaypoints_success("Unsubscribewaypoints_success_9")-- info param is out of upper bound (SendError)
function Test:SubscribeWayPoints_SendError_info_out_upper_bound()
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})  -- hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")  :Do(function(_,data)
    -- hmi side: sending Navigation.SubscribeWayPoints response
    -- According CRS APPLINK-14551 In case SDL receives <message> from HMI with maxlength more than defined for <info> param at MOBILE_API SDL must:truncate <message> to maxlength of <info> defined at MOBILE_API
    self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", infoMessage1001 )
  end)  -- mobile side: SubscribeWayPoints response
  EXPECT_RESPONSE(CorIdSWP, {success = false , resultCode = "GENERIC_ERROR", info = infoMessage1000})  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)
  commonTestCases:DelayedExp(1000)end-- End Test case NegativeRequestCheck.2
---------------------------------------------------------------------------
-- Begin Test case NegativeRequestCheck.3-- info param is missed (SendResponse)function Test:SubscribeWayPoints_SendResponse_info_missed()  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})  -- hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")  :Do(function(_,data)
      -- hmi side: sending Navigation.SubscribeWayPoints response      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {} )
    end)  -- mobile side: SubscribeWayPoints response
  EXPECT_RESPONSE(CorIdSWP, {success = true , resultCode = "SUCCESS"})
  :ValidIf (function(_,data)
            if data.payload.info then
              commonFunctions:printError(" SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\"")
              return false
            else
              return true
            end
          end)  EXPECT_NOTIFICATION("OnHashChange")end-- Postconditionpostcondition_unsubscribewaypoints_success("Unsubscribewaypoints_success_10")
-- info param is missed (SendError)function Test:SubscribeWayPoints_SendError_info_missed()
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})  -- hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")  :Do(function(_,data)
    -- hmi side: sending Navigation.SubscribeWayPoints response    self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR")
  end)  -- mobile side: SubscribeWayPoints response  EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "GENERIC_ERROR"})  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)
  commonTestCases:DelayedExp(1000)end-- End Test case NegativeRequestCheck.3
--------------------------------------------------------------------------------------------------------
-- Begin NegativeRequestCheck.4-- info param is WrongType(SendResponse)function Test:SubscribeWayPoints_SendResponse_info_IsWrongType()
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})  -- hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")  :Do(function(_,data)
    -- hmi side: sending Navigation.SubscribeWayPoints response    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {123} )
  end)  -- mobile side: SubscribeWayPoints response
  EXPECT_RESPONSE(CorIdSWP, {success = true , resultCode = "SUCCESS"})
  :ValidIf (function(_,data)
    if data.payload.info then
      commonFunctions:printError(" SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\"")
      return false
    else
      return true
    end
  end)  EXPECT_NOTIFICATION("OnHashChange")end-- Postconditionpostcondition_unsubscribewaypoints_success("Unsubscribewaypoints_success_11")
-- info param is WrongType (SendError)function Test:SubscribeWayPoints_SendError_info_IsWrongType()
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})  -- hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")  :Do(function(_,data)
    -- hmi side: sending Navigation.SubscribeWayPoints response    self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", 123)
  end)  -- mobile side: SubscribeWayPoints response  EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "GENERIC_ERROR"})
  :ValidIf (function(_,data)
        if data.payload.info then
          commonFunctions:printError(" SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\"")
          return false
        else
          return true
        end      end)  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)
  commonTestCases:DelayedExp(1000)end------------------------------------------------------------------------------------------------------------

-- Begin NegativeRequestCheck.5-- info param is \n (SendResponse)function Test:SubscribeWayPoints_SendResponse_info_NewLine()
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})  -- hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")  :Do(function(_,data)
    -- hmi side: sending Navigation.SubscribeWayPoints response    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = "a\nb"})
  end)  -- mobile side: SubscribeWayPoints response
  EXPECT_RESPONSE(CorIdSWP, {success = true , resultCode = "SUCCESS"})
  :ValidIf (function(_,data)
    if data.payload.info then
      commonFunctions:printError(" SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\"")
      return false
    else
      return true
    end
  end)  EXPECT_NOTIFICATION("OnHashChange")end-- Postconditionpostcondition_unsubscribewaypoints_success("Unsubscribewaypoints_success_12")-- info param is WrongType (SendError)function Test:SubscribeWayPoints_SendError_info_NewLine()
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})  -- hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")  :Do(function(_,data)
    -- hmi side: sending Navigation.SubscribeWayPoints response    self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "a\nb")
  end)  -- mobile side: SubscribeWayPoints response  EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "GENERIC_ERROR"})  :ValidIf (function(_,data)
    if data.payload.info then
      commonFunctions:printError(" SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\"")
      return false
    else
      return true
    end  end)  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)
  commonTestCases:DelayedExp(1000)end

---------------------------------------------------------------------------------------------------- Begin NegativeRequestCheck.6-- there is \t in info param (SendResponse)function Test:SubscribeWayPoints_SendResponse_info_Tab()
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})  -- hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")  :Do(function(_,data)
    -- hmi side: sending Navigation.SubscribeWayPoints response    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {info = "a\tb"})
  end)  -- mobile side: SubscribeWayPoints response
  EXPECT_RESPONSE(CorIdSWP, {success = true , resultCode = "SUCCESS"})
  :ValidIf (function(_,data)
    if data.payload.info then
      commonFunctions:printError(" SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\"")
      return false
    else
      return true
    end
  end)  EXPECT_NOTIFICATION("OnHashChange")end-- Postconditionpostcondition_unsubscribewaypoints_success("Unsubscribewaypoints_success_13")
-- info param is WrongType (SendError)function Test:SubscribeWayPoints_SendError_info_Tab()
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})  -- hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")  :Do(function(_,data)
    -- hmi side: sending Navigation.SubscribeWayPoints response    self.hmiConnection:SendError(data.id, data.method, "GENERIC_ERROR", "a\tb")
  end)  -- mobile side: SubscribeWayPoints response  EXPECT_RESPONSE(CorIdSWP, { success = false, resultCode = "GENERIC_ERROR"})  :ValidIf (function(_,data)
    if data.payload.info then
      commonFunctions:printError(" SDL resends info parameter to mobile app. info = \"" .. data.payload.info .. "\"")
      return false
    else
      return true
    end  end)  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)
  commonTestCases:DelayedExp(1000)end----------------------------------------------------------------------------------------------
----------------------------------------IV TEST BLOCK-----------------------------------------
---------------------------------------Result code check--------------------------------------
------------------------------------------------------------------------------------------------ Check all uncovered pairs resultCodes+success-- Begin Test suit ResultCodeCheck
-- Description: TC's check all resultCodes values in pair with success value
-- Begin Test case ResultCodeCheck.1
-- Description: Checking result code responded from HMI-- Requirement id in JIRA:
-- APPLINK-21629-- Verification criteria:
-- SDL returns REJECTED code for the request sent-- Begin Test case 4.1function Test:SubscribeWayPoints_REJECTED()
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})  -- hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")  :Do(function(_,data)
    -- hmi side: sending UI.AddCommand response
    self.hmiConnection:SendError(data.id, data.method, "REJECTED", "")
  end)  EXPECT_RESPONSE(CorIdSWP, {success = false , resultCode = "REJECTED"})  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)  commonTestCases:DelayedExp(1000)end
-- End Test case 4.1
----------------------------------------------------------------------------------------------
-- Verification criteria: APPLINK-25187
-- HMI does NOT respond to Navi.IsReady_request -> SDL must transfer received RPC to HMI even to non-responded Navi module
-- Begin Test case 4.2function Test:SubscribeWayPoints_UNSUPPORTED_RESOURCE_From_HMI()
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})  -- hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")  :Do(function(_,data)
    -- hmi side: sending UI.AddCommand response
    self.hmiConnection:SendError(data.id, data.method, "UNSUPPORTED_RESOURCE", "Navigation is not supported")
  end)  EXPECT_RESPONSE(CorIdSWP, {success = false , resultCode = "UNSUPPORTED_RESOURCE", info = "Navigation is not supported"})  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)  commonTestCases:DelayedExp(1000)end
-- End Test case 4.2
----------------------------------------------------------------------------------------------
-- Begin Test case 4.3
-- Description: Checking "GENERIC_ERROR" result code in case HMI does NOT respond during <DefaultTimeout>
-- Requirement id in JIRA:
-- APPLINK-21629, APPLINK-17008
-- Verification criteria: SDL must respond with "GENERIC_ERROR, success:false" in case HMI does NOT respond during <DefaultTimeout>function Test:SubscribeWayPoints_HMI_does_not_respond()
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})  -- hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")  -- mobile side: SubscribeWayPoints response
  EXPECT_RESPONSE(CorIdSWP, {success = false , resultCode = "GENERIC_ERROR", info = "Navigation component does not respond"})  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)  commonTestCases:DelayedExp(1000)end-- End Test case 4.3
----------------------------------------------------------------------------------------------
-- Begin Test case 4.4
-- Requirements in Jira: APPLINK-21900
-- Verification criteria: In case mobile app already subscribed on wayPoints-related parameters and the same mobile app sends SubscribeWayPoints_request to SDL SDL must: respond "IGNORED, success:false" to mobile appfunction Test:SubscribeWayPoints_Success_2()
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints",{})  -- hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Times(1)  :Do(function(_,data)
    -- hmi side: sending Navigation.SubscribeWayPoints response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  :Times(1)  -- mobile side: SubscribeWayPoints response
  EXPECT_RESPONSE(CorIdSWP,{ success = true, resultCode = "SUCCESS"})
  :Times(1)  EXPECT_NOTIFICATION("OnHashChange")
  :Times(1)
  :Do(function(_, data)
    self.currentHashID1 = data.payload.hashID
  end)
endfunction Test:SubscribeWayPoints_IGNORED()
    userPrint(34, "=================== Test Case ===================")
    -- mobile side: SubscribeWayPoints request
    local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints",{})    -- hmi side: expected SubscribeWayPoints request
    EXPECT_HMICALL("Navigation.SubscribeWayPoints")
    :Times(0)    commonTestCases:DelayedExp(1000)    -- mobile side: SubscribeWayPoints response
    EXPECT_RESPONSE(CorIdSWP,{ success = false, resultCode = "IGNORED"})
    :Times(1)    EXPECT_NOTIFICATION("OnHashChange")
    :Times(0)    commonTestCases:DelayedExp(1000)end-- End Test case 4.4
----------------------------------------------------------------------------------------------
-- Begin Test case 4.5
-- Requirements in Jira: APPLINK-21900
-- Verification criteria: In case mobile app already subscribed on wayPoints-related parameters and the another app sends SubscribeWayPoints_request to SDL
function Test:Case_StartSession2()
  userPrint(34, "=================== Precondition ===================")
  -- Connected expectation
  self.mobileSession2 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    config.application2.registerAppInterfaceParams)
endfunction Test:RegisterAppSession2()
  self.mobileSession2:Start()  EXPECT_HMICALL("BasicCommunication.OnAppRegistered")
  :Do(function(_,data)
    if data.params.application.appName == "Test Application2" then
      HMIAppID2 = data.params.application.appID
    end
  end)
endfunction Test:ActivationApp2()
    -- hmi side: sending SDL.ActivateApp request    local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = HMIAppID2} )
    EXPECT_HMIRESPONSE(RequestId)
    :Do(function(_,data)
      if
      data.result.isSDLAllowed ~= true then
        local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})        -- hmi side: expect SDL.GetUserFriendlyMessage message response
        -- TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
        EXPECT_HMIRESPONSE(RequestId)
        :Do(function(_,data)
            -- hmi side: send request SDL.OnAllowSDLFunctionality
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})            -- hmi side: expect BasicCommunication.ActivateApp request
            EXPECT_HMICALL("BasicCommunication.ActivateApp")
            :Do(function(_,data)
                -- hmi side: sending BasicCommunication.ActivateApp response
                self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
              end)
            :Times(AnyNumber())
          end)      end
      end)    -- mobile side: expect notification
    EXPECT_NOTIFICATION("OnHMIStatus",
      { systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})    self.mobileSession2:ExpectNotification("OnHMIStatus",
      { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})endfunction Test:SubscribeWayPoints_AnotherApp_sends_request()
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: SubscribeWayPoints request
  local CorIdSWP = self.mobileSession2:SendRPC("SubscribeWayPoints",{})  -- hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Times(0)  commonTestCases:DelayedExp(1000)  -- mobile side: SubscribeWayPoints response
  self.mobileSession2:ExpectResponse("SubscribeWayPoints",{ success = true, resultCode = "SUCCESS"})  -- APPLINK-15682 [Data Resumption]: OnHashChange
  self.mobileSession2:ExpectNotification("OnHashChange", {})
  :Times(1)
  :Do(function(_, data)
    self.currentHashID2 = data.payload.hashID
  end)end-- End Test case 4.5
----------------------------------------------------------------------------------------------
-- Begin Test case 4.6
-- Requirement id in JIRA:APPLINK-21900
-- Verification criteria: In case mobile app already subscribed on wayPoints-related parameters and the another app sends SubscribeWayPoints_request to SDL, SDL must: remember this another app as subscribed on wayPoints-related datafunction Test:SUSPEND()
  userPrint(34, "=================== Precondition ===================")
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
  {
    reason = "SUSPEND"
  })  -- hmi side: expect OnSDLPersistenceComplete notification
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")  -- Check that SDL doesn't send UnsubscribeWayPoints when SUSPEND
  EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
  :Times(0)  commonTestCases:DelayedExp(1000)endfunction Test:IGNITION_OFF()
  IGNITION_OFF(self,2)
  commonTestCases:DelayedExp(3000)
endfunction Test:CheckSubscribeWayPointsInAppInfoDat_For_BOTH_Apps()
  userPrint(34, "=================== Test Case ===================")
  -- checkSDLPathValue
  commonSteps:CheckSDLPath()  local resumptionAppData
  local resumptionDataTable  local app_info_file = io.open(config.pathToSDL .."app_info.dat",r)  local resumptionfile = app_info_file:read("*a")  resumptionDataTable = json.decode(resumptionfile)  local resumptionAppData1
  local resumptionAppData2  for p = 1, #resumptionDataTable.resumption.resume_app_list do
    if resumptionDataTable.resumption.resume_app_list[p].appID == "0000001" then
      resumptionAppData1 = resumptionDataTable.resumption.resume_app_list[p]
    elseif resumptionDataTable.resumption.resume_app_list[p].appID == "0000002" then
      resumptionAppData2 = resumptionDataTable.resumption.resume_app_list[p]    end
  end  -- print("resumptionAppData1")
  -- print_table(resumptionAppData1)  -- print("resumptionAppData2")
  -- print_table(resumptionAppData2)  local ErrorMessage = ""
  local ErrorStatus = false  if not resumptionAppData1 or
  resumptionAppData1.subscribed_for_way_points == false then
    ErrorMessage = ErrorMessage .. "subscribed_for_way_points saved in app_info.dat for app1 with false or data for app1 is absent at all\n"
    ErrorStatus = true
    -- self:FailTestCase("subscribed_for_way_points saved in app_info.dat with false")
  end
  if
  not resumptionAppData2 or
  resumptionAppData2.subscribed_for_way_points == false then
    ErrorMessage = ErrorMessage .. "subscribed_for_way_points saved in app_info.dat for app2 with false or data for app2 is absent at all\n"
    ErrorStatus = true
    -- self:FailTestCase("subscribed_for_way_points saved in app_info.dat with false")
  end  if ErrorStatus == true then
    self:FailTestCase(ErrorMessage)
  end
end-- End Test case 4.6
----------------------------------------------------------------------------------------------
-- Begin Test case 4.7
-- Requirement id in JIRA: APPLINK-21898
-- Verification criteria: In case mobile app being subscribed on wayPoints-related data at previous ignition cycle registers at the next ignition cycle with the same <hashID> being at previous ignition cycle SDL must: restore status of subscription on wayPoints-related data being at previous ignition cycle for this app
function Test:RunSDL()
  userPrint(34, "=================== PreCondition ===================")
  StartSDL(config.pathToSDL, true)
endfunction Test:InitHMI()  self:initHMI()
endfunction Test:InitHMI_onReady()  self:initHMI_onReady()
endfunction Test:PreconditionConnectMobile()  self:connectMobile()
endfunction Test:Case_StartSession2()
  -- Connected expectation
  self.mobileSession2 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    config.application2.registerAppInterfaceParams)
endfunction Test:RegisterAppSession2()
  config.application2.registerAppInterfaceParams.hashID = self.currentHashID2
  self.mobileSession2:Start()
  print("\27[33m " .. "in app_info.dat hashID for app2 = ".. tostring(self.currentHashID2) .. "\27[0m")  EXPECT_HMICALL("BasicCommunication.OnAppRegistered")  self.mobileSession2:ExpectNotification("OnHMIStatus",
    { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})endfunction Test:Restore_Subscription_App2_registers()
  userPrint(34, "=================== Test Case ===================")
  -- body
  EXPECT_HMICALL("BasicCommunication.ActivateApp")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
    end)  self.mobileSession2:ExpectNotification("OnHMIStatus",
    { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})  EXPECT_HMICALL("Navigation.SubscribeWayPoints")  self.mobileSession2:ExpectNotification("OnHashChange", {})end-- End test case 4.7
----------------------------------------------------------------------------------------------
-- Begin Test case 4.8
-- Description: Check that there is no redundant request to HMI when app1 registers with hashIDfunction Test:Case_StartSession1()
  userPrint(34, "=================== Precondition ===================")
  -- Connected expectation
  self.mobileSession = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    config.application1.registerAppInterfaceParams)
endfunction Test:RegisterAppSession_No_Redundant_SWP()
  userPrint(34, "=================== Test Case ===================")
  config.application1.registerAppInterfaceParams.hashID = self.currentHashID1
  self.mobileSession:Start()
  print("\27[33m " .. "in app_info.dat hashID for app1 = ".. tostring(self.currentHashID1) .. "\27[0m")  EXPECT_HMICALL("BasicCommunication.OnAppRegistered")  EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Times(0)  commonTestCases:DelayedExp(1000)  EXPECT_NOTIFICATION("OnHashChange", {})end-- End test case 4.8
----------------------------------------------------------------------------------------------
-- Begin Test case 4.9
-- Requirement in JIRA: APPLINK-21897
-- [[ verification criteria: In case mobile app subscribed on wayPoints-related parameters unexpectedly disconnects SDL must:
-- store the status of subscription on wayPoints-related data for this app send UnsubscribeWayPoints_request to HMI ONLY if
-- no any apps currently subscribed to wayPoints-related data (please see APPLINK-21641) restore status of subscription on
-- ayPoints-related data for this app right after the same mobile app re-connects within the same ignition cycle with the same <hashID> being before unexpected disconnect ]]-- Description: Check that SDL send UnsubscribeWayPoints_request to HMI when unexpected disconnect occurs-- Preconditionfunction Test:UnregisterApps_Gracefully()
  userPrint(34, "=================== Precondition ===================")
  -- mobile side: UnregisterAppInterface request
  self.mobileSession:SendRPC("UnregisterAppInterface", {})
  -- mobile side: UnregisterAppInterface request
  self.mobileSession2:SendRPC("UnregisterAppInterface", {})  -- hmi side: expected BasicCommunication.OnAppUnregistered
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    {unexpectedDisconnect = false},
    {unexpectedDisconnect = false})
  :Times(2)  -- UnsubscribeWayPoints should be sent if there is no subscribed apps (Confirmed by T.Melnik over Skyoe, TODO: Question in JIRA !!!)  EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
  :Times(1)  -- mobile side: UnregisterAppInterface response
  self.mobileSession:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})
  -- mobile side: UnregisterAppInterface response
  self.mobileSession2:ExpectResponse("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})endfunction Test:Case_StartSession1()
  -- Connected expectation
  self.mobileSession = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    config.application1.registerAppInterfaceParams)
endfunction Test:RegisterAppSession1()
  self.mobileSession:Start()  EXPECT_HMICALL("BasicCommunication.OnAppRegistered")
  :Do(function(_,data)
    if data.params.application.appName == "Test Application" then
      HMIAppID1 = data.params.application.appID
    end
  end)  EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})endfunction Test:ActivationApp1()
  -- hmi side: sending SDL.ActivateApp request
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = HMIAppID1 })
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,data)
    if
    data.result.isSDLAllowed ~= true then
      local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})      -- hmi side: expect SDL.GetUserFriendlyMessage message response
      -- TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      EXPECT_HMIRESPONSE(RequestId)
      :Do(function(_,data)
          -- hmi side: send request SDL.OnAllowSDLFunctionality
          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})          -- hmi side: expect BasicCommunication.ActivateApp request
          EXPECT_HMICALL("BasicCommunication.ActivateApp")
          :Do(function(_,data)
              -- hmi side: sending BasicCommunication.ActivateApp response
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
            end)
          :Times(AnyNumber())
        end)    end
   end)  -- mobile side: expect notification
  EXPECT_NOTIFICATION("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})
endfunction Test:SubscribeWayPoints_Success_3()  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})  -- hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")  :Do(function(_,data)
    -- hmi side: sending Navigation.SubscribeWayPoints response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)  -- mobile side: SubscribeWayPoints response
  EXPECT_RESPONSE(CorIdSWP, {success = true , resultCode = "SUCCESS"})  EXPECT_NOTIFICATION("OnHashChange")
  :Do(function(_, data)
    self.currentHashID3 = data.payload.hashID
  end)endfunction Test:Case_StartSession2()
  -- Connected expectation
  self.mobileSession2 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    config.application2.registerAppInterfaceParams)
endfunction Test:RegisterAppSession2()
  self.mobileSession2:Start()  EXPECT_HMICALL("BasicCommunication.OnAppRegistered")
  :Do(function(_,data)
    if data.params.application.appName == "Test Application2" then
      HMIAppID2 = data.params.application.appID
    end
  end)  self.mobileSession2:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})endfunction Test:ActivationApp2()
  -- hmi side: sending SDL.ActivateApp request  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = HMIAppID2} )
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,data)
      if
      data.result.isSDLAllowed ~= true then
        local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})        -- hmi side: expect SDL.GetUserFriendlyMessage message response
        -- TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
        EXPECT_HMIRESPONSE(RequestId)
        :Do(function(_,data)
            -- hmi side: send request SDL.OnAllowSDLFunctionality
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})            -- hmi side: expect BasicCommunication.ActivateApp request
            EXPECT_HMICALL("BasicCommunication.ActivateApp")
            :Do(function(_,data)
                -- hmi side: sending BasicCommunication.ActivateApp response
                self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
              end)
            :Times(AnyNumber())
          end)      end
    end)  -- mobile side: expect notification
  EXPECT_NOTIFICATION("OnHMIStatus",
    { systemContext = "MAIN", hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})  self.mobileSession2:ExpectNotification("OnHMIStatus",
    { systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})end-- SDL should't resend "Navigation.SubscribeWayPoints" to HMI
function Test:SubscribeWayPoints_Success_App2()  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession2:SendRPC("SubscribeWayPoints", {})  -- hmi side: not expected SubscribeWayPoints request as already subscribed
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Times(0)  :Do(function(_,data)
    -- hmi side: sending Navigation.SubscribeWayPoints response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)  -- mobile side: SubscribeWayPoints response
  self.mobileSession2:ExpectResponse("SubscribeWayPoints", {success = true , resultCode = "SUCCESS"})  -- APPLINK-15682 [Data Resumption]: OnHashChange
  self.mobileSession2:ExpectNotification("OnHashChange", {})
  :Do(function(_, data)
    self.currentHashID4 = data.payload.hashID
  end)  :Times(1)  commonTestCases:DelayedExp(1000)
end-- !!!Unexpected disconnect!!!-- function Test:CloseSession1()
-- self.mobileSession:Stop()
-- end
-- function Test:CloseSession2()
-- self.mobileSession2:Stop()
-- endfunction Test:CloseConnection()  self.mobileConnection:Close()
endfunction Test:UnsubscribeWayPoints_after_disconnect()
  userPrint(34, "=================== Test Case ===================")
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true})
  :Times(2)  EXPECT_HMICALL("UnsubscribeWayPoints")
end-- End test case 4.9
----------------------------------------------------------------------------------------------
-- Begin test case 4.10-- Requirenments in JIRA: APPLINK-21897
-- Description: Check that SDL store the status of subscription on wayPoints-related data for this appfunction Test:CheckSubscribeWayPointsInAppInfoDat_For_BOTH_Apps()
  userPrint(34, "=================== Test Case ===================")
  -- checkSDLPathValue()
  commonSteps:CheckSDLPath()  local resumptionAppData
  local resumptionDataTable  local app_info_file = io.open(config.pathToSDL .."app_info.dat",r)  local resumptionfile = app_info_file:read("*a")  -- print("\27[33m " .. resumptionfile .. "\27[0m")  resumptionDataTable = json.decode(resumptionfile)  -- print(" #resumptionDataTable.resumption.resume_app_list" .. tostring( #resumptionDataTable.resumption.resume_app_list))  local resumptionAppData1
  local resumptionAppData2  for p = 1, #resumptionDataTable.resumption.resume_app_list do
    if resumptionDataTable.resumption.resume_app_list[p].appID == "0000001" then
      resumptionAppData1 = resumptionDataTable.resumption.resume_app_list[p]
    elseif resumptionDataTable.resumption.resume_app_list[p].appID == "0000002" then
      resumptionAppData2 = resumptionDataTable.resumption.resume_app_list[p]    end
  end  -- print("resumptionAppData1")
  -- print_table(resumptionAppData1)  -- print("resumptionAppData2")
  -- print_table(resumptionAppData2)  local ErrorMessage = ""
  local ErrorStatus = false  if not resumptionAppData1 or
  resumptionAppData1.subscribed_for_way_points == false then
    ErrorMessage = ErrorMessage .. "subscribed_for_way_points saved in app_info.dat for app1 with false or data for app1 is absent at all\n"
    ErrorStatus = true
    -- self:FailTestCase("subscribed_for_way_points saved in app_info.dat with false")
  end
  if
  not resumptionAppData2 or
  resumptionAppData2.subscribed_for_way_points == false then
    ErrorMessage = ErrorMessage .. "subscribed_for_way_points saved in app_info.dat for app2 with false or data for app2 is absent at all\n"
    ErrorStatus = true
    -- self:FailTestCase("subscribed_for_way_points saved in app_info.dat with false")
  end  if ErrorStatus == true then
    self:FailTestCase(ErrorMessage)
  end
end-- End test case 4.10
----------------------------------------------------------------------------------------------
-- Begin test case 4.11-- Description: check that SDL restore status of subscription on wayPoints-related data for this app right after the same app reconnects
-- within the same ignition cycle with the same <hashID> being before unexpected disconnectfunction Test:ConnectMobile()
  userPrint(34, "=================== Precondition ===================")
  self:connectMobile()
endfunction Test:Case_StartSession2()
  -- Connected expectation
  self.mobileSession2 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    config.application2.registerAppInterfaceParams)
endfunction Test:RegisterAppSession2()
  config.application2.registerAppInterfaceParams.hashID = self.currentHashID4
  self.mobileSession2:Start()
  print("\27[33m " .. "in app_info.dat hashID for app2 = ".. tostring(self.currentHashID4) .. "\27[0m")  EXPECT_HMICALL("BasicCommunication.OnAppRegistered")  self.mobileSession2:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})endfunction Test:Restore_Subscription_App2_registers_after_unexpected()
  userPrint(34, "=================== Test Case ===================")
  -- body
  EXPECT_HMICALL("BasicCommunication.ActivateApp")
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
  end)  self.mobileSession2:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})  EXPECT_HMICALL("Navigation.SubscribeWayPoints")  self.mobileSession2:ExpectNotification("OnHashChange", {})
  :Do(function(_, data)
    self.currentHashID6 = data.payload.hashID
  end)end-- End test case 4.11
----------------------------------------------------------------------------------------------

-- Begin test case 4.12-- Description: Check that there is no redundant request to HMI when app1 registers with hashIDfunction Test:Case_StartSession1()
  userPrint(34, "=================== Precondition ===================")
  -- Connected expectation
  self.mobileSession = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    config.application1.registerAppInterfaceParams)
endfunction Test:RegisterAppSession_No_Redundant_SWP_after_unexpected()
  userPrint(34, "=================== Test Case ===================")
  config.application1.registerAppInterfaceParams.hashID = self.currentHashID3
  self.mobileSession:Start()
  print("\27[33m " .. "in app_info.dat hashID for app1 = ".. tostring(self.currentHashID3) .. "\27[0m")  EXPECT_HMICALL("BasicCommunication.OnAppRegistered")  EXPECT_NOTIFICATION("OnHMIStatus",
    { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Times(0)  commonTestCases:DelayedExp(1000)  EXPECT_NOTIFICATION("OnHashChange", {})
  :Do(function(_, data)
    self.currentHashID5 = data.payload.hashID
  end)end-- End test case 4.12
----------------------------------------------------------------------------------------------

-- Begin test case 4.13-- Requirenments in JIRA: APPLINK-21897
-- Description: Check that SDL does't send UnsubscribeWayPoints if unexpected disconnect occurs with one app but another one still registers-- !!!Unexpected disconnect with app2!!!function Test:CloseSession2()
  userPrint(34, "=================== Precondition ===================")
  self.mobileSession2:Stop()endfunction Test:Redundant_UWP()
  userPrint(34, "=================== Test Case ===================")
  -- EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true})  EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
  :Times(0)  commonTestCases:DelayedExp(1000)end-- End test case 4.13
----------------------------------------------------------------------------------------------

-- Begin test case 4.14-- Description: Check that SDL does't send SubscribeWayPoints when app reconnects with hashID but another one still registers and subscribedfunction Test:Case_StartSession2()
  userPrint(34, "=================== Precondition ===================")
  -- Connected expectation
  self.mobileSession2 = mobile_session.MobileSession(
    self,
    self.mobileConnection,
    config.application2.registerAppInterfaceParams)
endfunction Test:RegisterAppSession2()
  config.application2.registerAppInterfaceParams.hashID = self.currentHashID6
  self.mobileSession2:Start()
  print("\27[33m " .. "in app_info.dat hashID for app2 = ".. tostring(self.currentHashID6) .. "\27[0m")  EXPECT_HMICALL("BasicCommunication.OnAppRegistered")  self.mobileSession2:ExpectNotification("OnHMIStatus",
    { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})end-- Resumption of HMI level occurs, but there is no redundant Navigation.SubscribeWayPoints requestfunction Test:RedundantSWP()
  userPrint(34, "=================== Test Case ===================")
  EXPECT_HMICALL("BasicCommunication.ActivateApp")
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
  end)  self.mobileSession2:ExpectNotification("OnHMIStatus",{ systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Times(0)  commonTestCases:DelayedExp(1000)end-- End test case 4.14
----------------------------------------------------------------------------------------------
-- Begin test case 4.15
-- Description: Check DISALLOWED result code wirh success false
-- Requirement id in JIRA: APPLINK-21896-- Verification criteria:
-- In case mobile app sends the valid SubscribeWayPoints_request to SDL and this request is NOT allowed by Policies SDL must: respond "DISALLOWED, success;false" to mobile app-- Check from "NONE" HMI level:function Test:SubscribeWayPoints_DISALLOWED_from_NONE()
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: send SubscribeWayPoints request
  local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})  -- hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Times(0)  commonTestCases:DelayedExp(1000)  -- mobile side: SubscribeWayPoints response
  EXPECT_RESPONSE(CorIdSWP, {success = false , resultCode = "DISALLOWED"})  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)  commonTestCases:DelayedExp(1000)end-- End test case 4.15
----------------------------------------------------------------------------------------------
-- Begin test case 4.16
-- Description: Check processing RPC in LIMITED Level
-- Requirement id in JIRA: APPLINK-21894-- Verification criteria:
-- In case mobile app sends the valid SubscribeWayPoints_request to SDL and this request is allowed by Policies SDL must: transfer SubscribeWayPoints_request_ to HMI respond with <resultCode> received from HMI to mobile app -- Precondition: function Test:ActivationApp1()
  userPrint(34, "=================== Precondition ===================")
  -- hmi side: sending SDL.ActivateApp request
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,data)
    if
    data.result.isSDLAllowed ~= true then
      local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})      -- hmi side: expect SDL.GetUserFriendlyMessage message response
      -- TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      EXPECT_HMIRESPONSE(RequestId)
      :Do(function(_,data)
          -- hmi side: send request SDL.OnAllowSDLFunctionality
          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})          -- hmi side: expect BasicCommunication.ActivateApp request
          EXPECT_HMICALL("BasicCommunication.ActivateApp")
          :Do(function(_,data)
            -- hmi side: sending BasicCommunication.ActivateApp response
            self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
          end)
          :Times(AnyNumber())
        end)    end
  end)  -- mobile side: expect notification
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL"},"OnHMIStatus", {hmiLevel = "FULL"})
endpostcondition_unsubscribewaypoints_success("Unsubscribewaypoints_success_14")-- Check from "LIMITED" HMI level:
function Test:DeactivateApp_Limited()
  local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
  {
    appID = self.applications["Test Application"],
    reason = "GENERAL"
  })  -- mobile side: expect OnHMIStatus notification
  EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})endfunction Test:SubscribeWayPoints_Limited_Success()
  userPrint(34, "=================== Test Case ===================")  -- mobile side: send SubscribeWayPoints request
 local CorIdSWP = self.mobileSession:SendRPC("SubscribeWayPoints", {})  -- hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints") :Do(function(_,data)
  -- hmi side: sending Navigation.SubscribeWayPoints response
  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
 end)  -- mobile side: SubscribeWayPoints response
  EXPECT_RESPONSE(CorIdSWP, {success = true , resultCode = "SUCCESS"})  -- mobile side: expect OnHashChange notification
  EXPECT_NOTIFICATION("OnHashChange")
  :Times(1)  
end-- End test case 4.16
----------------------------------------------------------------------------------------------

-- Begin test case 4.17-- Precondition:
-- activate app1function Test:ActivationApp1()
  userPrint(34, "=================== Precondition ===================")
  -- hmi side: sending SDL.ActivateApp request
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,data)
    if data.result.isSDLAllowed ~= true then
      local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
      -- hmi side: expect SDL.GetUserFriendlyMessage message response
      -- TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      EXPECT_HMIRESPONSE(RequestId)
      :Do(function(_,data)
        -- hmi side: send request SDL.OnAllowSDLFunctionality
        self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
        -- hmi side: expect BasicCommunication.ActivateApp request
        EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function(_,data)
          -- hmi side: sending BasicCommunication.ActivateApp response
          self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)
        :Times(AnyNumber())
      end)
    end
  end)
  -- mobile side: expect notification
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL"},"OnHMIStatus", {hmiLevel = "FULL"})
end
-- Precondition: UnsubscribeWayPoints request
postcondition_unsubscribewaypoints_success("Unsubscribewaypoints_success_15")
-- Upate policy where app1 has Location-1 group of permission
policyTable:updatePolicy("files/PTU_ForSubscribeWayPoints1.json")
----------------------------------------------------------------------------------
---------------------Common Functions for Policy check-----------------------------
-----------------------------------------------------------------------------------
function Test:PolicyCheckPrintName()
  userPrint(34, "=================== Test Case ===================")
end
policyTable:userConsent(true, "Location")
-- End test case 4.17
----------------------------------------------------------------------------------------------

-- Begin test case 4.18
-- Description: Request successful after user allow
function Test:PolicyCheckPrintName()
userPrint(34, "=================== Test Case ===================")
end
subscribewaypoints_success("SubscribeWayPoints_Success_4")
-- Postcondition: UnsubscribeWayPoints request
postcondition_unsubscribewaypoints_success("Unsubscribewaypoints_success_16")
-- End test case 4.18
-- testCasesForPolicyTable:userConsent(false, "Location")
function Test:PolicyCheckPrintName()
 userPrint(34, "=================== Precondition ===================")
end
policyTable:userConsent(false, "Location")
-- Send request and check USER_DISALLOWED resultCode
Test[APIName .."_resultCode_USER_DISALLOWED"] = function(self)
  userPrint(34, "=================== Test Case ===================")
  -- mobile side: sending the request
  local cid = self.mobileSession:SendRPC("SubscribeWayPoints", {})
 -- mobile side: expect response
  self.mobileSession:ExpectResponse(cid, { success = false, resultCode = "USER_DISALLOWED"})
end
function Test:Postcondition_remove_user_connecttest_restore_preloaded_file()
 os.execute(" cp " .. config.pathToSDL .. "sdl_preloaded_pt_origin.json " .. config.pathToSDL .. "sdl_preloaded_pt.json" )
 os.execute(" rm -f " .. config.pathToSDL .. "/sdl_preloaded_pt_origin.json" )
 os.execute( "rm -f ./user_modules/connecttest_OnButtonSubscription.lua" )
end