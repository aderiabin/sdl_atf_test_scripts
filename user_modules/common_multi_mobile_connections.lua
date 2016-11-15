--------------------------------------------------------------------------------
-- This scripts contains common steps(Tests) that are used often in many scripts
--[[ Note: functions in this script are designed based on bellow data structure of mobile connection, sessions, applications, application's parameter and HMI app ID
self.mobile_connections = {
  connection1 = {
    session1 = {
      app_name1 = {
        register_application_parameters = {
          appName = "app_name1",
          appHMIType = {"NAVIGATION"},
          ...}
        hmi_app_id = 123,
        is_unregistered = true -- means application is unregistered, nil or false: application is not unregistered
      }
    },
    session2 = {
      app_name2 = {
        register_application_parameters = {
          appName = "app_name2",
          appHMIType = {"NAVIGATION"},
          ...}
        hmi_app_id = 456,
        is_unregistered = true -- means application is unregistered, nil or false: application is not unregistered
      }
    }
  },
  connection2 = {
    session3 = {
      app_name3 = {
        register_application_parameters = {
          appName = "app_name3",
          appHMIType = {"NAVIGATION"},
          ...}
        hmi_app_id = 789,
        is_unregistered = true -- means application is unregistered, nil or false: application is not unregistered
      }
    },
    session4 = {
      app_name4 = {
        register_application_parameters = {
          appName = "app_name4",
          appHMIType = {"NAVIGATION"},
          ...}
        hmi_app_id = 123456,
        is_unregistered = true -- means application is unregistered, nil or false: application is not unregistered
      }
    },
  }
}]]
-- Author: Ta Thanh Dong
-- ATF version: 2.2
--------------------------------------------------------------------------------
local common_functions = require('user_modules/shared_testcases/commonFunctions')
local old_common_steps = require('user_modules/shared_testcases/commonSteps')
-- local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local common_preconditions = require('user_modules/shared_testcases/commonPreconditions')
local mobile_session = require('mobile_session')
local module = require('testbase')
require('cardinalities')
local events = require('events')
local mobile = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection = require('file_connection')
local config = require('config')
local expectations = require('expectations')
local Expectation = expectations.Expectation
local CommonSteps = {}

-- LIST OF COMMON FUNCTIONS
-- AddMobileConnection(test_case_name, mobile_connection_name)
-- AddMobileSession(test_case_name, mobile_connection_name, mobile_session_name, is_started_rpc_service)
-- CloseMobileSession(test_case_name, mobile_session_name)
-- CloseMobileSessionByAppName(test_case_name, app_name)
-- StartService(test_case_name, mobile_session_name, service_id)
-- RegisterApplication(test_case_name, mobile_session_name, application_parameters, expected_response, expected_on_hmi_status)
-- UnregisterApp(test_case_name, app_name)
-- ActivateApplication(test_case_name, app_name, expected_level, expected_on_hmi_status_for_other_applications)
-- ChangeHMIToLimited(test_case_name, app_name)
-- ChangeHmiLevelToNone(test_case_name, app_name)
-- InitializeHmi(test_case_name)
-- HmiRespondOnReady(test_case_name)
-- IgnitionOff(test_case_name)
-- IgnitionOn(test_case_name)
-- StartSDL(test_case_name)
-- StopSDL(test_case_name)
-- BackupFile(file_name)
-- RestoreFile(file_name)
-- AddItemsIntoJsonFile(json_file, parent_item, added_json_items)
-- RemoveItemsFromJsonFile(json_file, parent_item, removed_items)
-- Compare2Files(file_name1, file_name2, compared_specified_item)
-- QueryPolicyDataBase(sdl_query)
-- Refer to common_steps_with_multi_mobile_connections.lua for other functions.

-- LOCAL COMMON FUNCTIONS ARE CALLED INSIDE

-----------------------------------------------------------------------------
-- Get mobile connection name
-- @param mobile_session_name: name of session to get mobile connection name
-----------------------------------------------------------------------------
function CommonSteps:GetMobileConnectionName(mobile_session_name, self)
  for k_mobile_connection_name, v_mobile_connection_data in pairs(self.mobile_connections) do
    for k_mobile_session_name, v_mobile_session_data in pairs(v_mobile_connection_data) do
      if k_mobile_session_name == mobile_session_name then
        return k_mobile_connection_name
      end
    end
  end
  return nil
end
-----------------------------------------------------------------------------
-- Get application name on a mobile connection
-- @param mobile_session_name: name of session to get mobile connection name
-----------------------------------------------------------------------------
function CommonSteps:GetApplicationName(mobile_session_name, self)
  for k_mobile_connection_name, v_mobile_connection_data in pairs(self.mobile_connections) do
    for k_mobile_session_name, v_mobile_session_data in pairs(v_mobile_connection_data) do
      if k_mobile_session_name == mobile_session_name then
        for k_application_name, k_application_data in pairs(v_mobile_session_data) do
          return k_application_name
        end
      end -- if k_mobile_session_name
    end -- for k_mobile_session_name
  end -- for k_mobile_connection_name
  CommonSteps:PrintError("'" .. mobile_session_name .. "' session is not exist so that application name is not found.")
  return nil
end
-----------------------------------------------------------------------------
-- Get mobile connection name and mobile session name of an application,
-- @param app_name: name of application to get mobile session name
-----------------------------------------------------------------------------
function CommonSteps:GetMobileConnectionNameAndSessionName(app_name, self)
  for k_mobile_connection_name, v_mobile_connection_data in pairs(self.mobile_connections) do
    for k_mobile_session_name, v_mobile_session_data in pairs(v_mobile_connection_data) do
      for k_application_name, v_application_data in pairs(v_mobile_session_data) do
        if k_application_name == app_name then
          return k_mobile_connection_name, k_mobile_session_name
        end
      end
    end
  end
  CommonSteps:PrintError("'" .. app_name .. "' application is not exist so that mobile session is not found.")
  return nil
end
-----------------------------------------------------------------------------
-- Get HMI app ID of current app in a session
-- @param app_name: name of application to get corresponding HMI app ID
-----------------------------------------------------------------------------
function CommonSteps:GetHmiAppId(app_name, self)
  local mobile_connection_name, mobile_session_name = CommonSteps:GetMobileConnectionNameAndSessionName(app_name, self)
  local application = self.mobile_connections[mobile_connection_name][mobile_session_name][app_name]
  if not application.is_unregistered then
    return application.hmi_app_id
  else
    return nil
  end
end
-----------------------------------------------------------------------------
-- Get list of HMI app IDs of existing applications (applications have been registered and have not been unregistered yet).
-----------------------------------------------------------------------------
function CommonSteps:GetHmiAppIds(self)
  local hmi_app_ids = {}
  for k_mobile_connection_name, v_mobile_connection_data in pairs(self.mobile_connections) do
    for k_mobile_session_name, v_mobile_session_data in pairs(v_mobile_connection_data) do
      for k_application_name, v_application_data in pairs(v_mobile_session_data) do
        if not v_application_data.is_unregistered then
          hmi_app_ids[#hmi_app_ids + 1] = k_application_name
        end
      end
    end
  end
  return hmi_app_ids
end
-----------------------------------------------------------------------------
-- Get list of applications that were registered
-----------------------------------------------------------------------------
function CommonSteps:GetRegisteredApplicationNames(self)
  local app_names = {}
  for k_mobile_connection_name, v_mobile_connection_data in pairs(self.mobile_connections) do
    for k_mobile_session_name, v_mobile_session_data in pairs(v_mobile_connection_data) do
      for k_application_name, v_application_data in pairs(v_mobile_session_data) do
        if not v_application_data.is_unregistered then
          app_names[#app_names + 1] = k_application_name
        end
      end
    end
  end
  return app_names
end
-----------------------------------------------------------------------------
-- Get parameter value of current app in a session
-- @param mobile_connect_name: name of mobile session
-- @param app_name: name of application
-----------------------------------------------------------------------------
function CommonSteps:GetAppParameter(app_name, queried_parameter_name, self)
  local mobile_connection_name, mobile_session_name = CommonSteps:GetMobileConnectionNameAndSessionName(app_name, self)
  local application = self.mobile_connections[mobile_connection_name][mobile_session_name][app_name]
  return application.register_application_parameters[queried_parameter_name]
end

-----------------------------------------------------------------------------
-- Check application is media or not
-- @param app_name: name of application
-----------------------------------------------------------------------------
function CommonSteps:IsMediaApp(app_name, self)
  local is_media = CommonSteps:GetAppParameter(app_name, "isMediaApplication", self)
  local app_hmi_types = CommonSteps:GetAppParameter(app_name, "appHMIType", self)
  for i = 1, #app_hmi_types do
    if (app_hmi_types[i] == "COMMUNICATION") or (app_hmi_types[i] == "NAVIGATION") or (app_hmi_types[i] == "MEDIA") then
      is_media = true
    end
  end
  return is_media
end
-----------------------------------------------------------------------------
-- Print error message on ATF script console
-- @param error_message: message to be printed.
-----------------------------------------------------------------------------
function CommonSteps:PrintError(error_message)
  print(" \27[31m " .. error_message .. " \27[0m ")
end
-----------------------------------------------------------------------------
-- Delay to verify expected result
-- @param time: time in seconds for delay verifying expected result
-----------------------------------------------------------------------------
function CommonSteps:DelayedExp(time)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  :Timeout(time+1000)

  RUN_AFTER(function()
      RAISE_EVENT(event, event)
      end, time)
  end
  -----------------------------------------------------------------------------
  -- Store mobile connect data to use later
  -- @param mobile_connection_name: name of connection that is used by ATF
  -----------------------------------------------------------------------------
  function CommonSteps:StoreConnectionData(mobile_connection_name, self)
    if not self.mobile_connections then
      self.mobile_connections = {}
    end
    self.mobile_connections[mobile_connection_name] = {}
  end
  -----------------------------------------------------------------------------
  -- Check connection is exist or not
  -- @param mobile_connection_name: name of connection that is used by ATF
  -----------------------------------------------------------------------------
  function CommonSteps:IsConnectionDataExist(mobile_connection_name, self)
    if not self.mobile_connections then
      self.mobile_connections = {}
    end
    if not self.mobile_connections[mobile_connection_name] then
      return false
    else
      return true
    end
  end
  -----------------------------------------------------------------------------
  -- Store session data to use later
  -- @param mobile_connection_name: name of mobile connection
  -- @param mobile_session_name: name of session
  -----------------------------------------------------------------------------
  function CommonSteps:StoreSessionData(mobile_connection_name, mobile_session_name, self)
    self.mobile_connections[mobile_connection_name][mobile_session_name] = {}
  end
  -----------------------------------------------------------------------------
  -- Store new application data to use later for activate application, unregister, ..
  -- @param mobile_session_name:
  -- @param app_name:
  -----------------------------------------------------------------------------
  function CommonSteps:StoreApplicationData(mobile_session_name, app_name, application_parameters, hmi_app_id, self)
    local mobile_connection_name = CommonSteps:GetMobileConnectionName(mobile_session_name, self)
    self.mobile_connections[mobile_connection_name][mobile_session_name][app_name] = {
      register_application_parameters = application_parameters,
      hmi_app_id = hmi_app_id,
      is_unregistered = false
    }
  end
  -----------------------------------------------------------------------------
  -- Set status of application is unregistered
  -- @param app_name: name of application is unregistered
  -----------------------------------------------------------------------------
  function CommonSteps:SetApplicationStatusIsUnRegistered(app_name, self)
    local mobile_connection_name, mobile_session_name = CommonSteps:GetMobileConnectionNameAndSessionName(app_name, self)
    self.mobile_connections[mobile_connection_name][mobile_session_name][app_name].is_unregistered = true
  end
  -----------------------------------------------------------------------------
  -- Store HMISatatus for application to use later
  -- @param app_name: name of application
  -- @param on_hmi_status: HMI status such as {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}
  -- @param self: "self" object in side a Test.
  -----------------------------------------------------------------------------
  function CommonSteps:StoreHmiStatus(app_name, on_hmi_status, self)
    local mobile_connection_name, mobile_session_name = CommonSteps:GetMobileConnectionNameAndSessionName(app_name, self)
    local application = self.mobile_connections[mobile_connection_name][mobile_session_name][app_name]
    if not application.on_hmi_status then
      application.on_hmi_status = {}
    end
    -- Set value from on_hmi_status to data of application.
    for k, v in pairs(on_hmi_status) do
      application.on_hmi_status[k] = v
    end
  end
  -----------------------------------------------------------------------------
  -- Get HMISatatus for application from stored data.
  -- @param app_name: name of application
  -- @param self: "self" object in side a Test.
  -- @param specific_parameter_name: It can be hmiLevel, audioStreamingState and systemContext.
  -- If it is omitted, return all parameters such as {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}
  -----------------------------------------------------------------------------
  function CommonSteps:GetHmiStatus(app_name, self, specific_parameter_name)
    local mobile_connection_name, mobile_session_name = CommonSteps:GetMobileConnectionNameAndSessionName(app_name, self)
    local application = self.mobile_connections[mobile_connection_name][mobile_session_name][app_name]
    if specific_parameter_name then
      return application.on_hmi_status[specific_parameter_name]
    else
      return application.on_hmi_status
    end
  end

  -- COMMON FUNCTIONS FOR PROCESSING FILE
  -----------------------------------------------------------------------------
  -- Make reserve copy of file (FileName) in /bin folder
  -- @param file_name: file name will be backed up
  -----------------------------------------------------------------------------
  function CommonSteps:BackupFile(file_name)
    os.execute(" cp " .. config.pathToSDL .. file_name .. " " .. config.pathToSDL .. file_name .. "_origin" )
  end
  -----------------------------------------------------------------------------
  -- Restore origin of file (FileName) in /bin folder
  -- @param file_name: file name will be backed up
  -----------------------------------------------------------------------------
  function CommonSteps:RestoreFile(file_name)
    os.execute(" cp " .. config.pathToSDL .. file_name .. "_origin " .. config.pathToSDL .. file_name )
    os.execute( " rm -f " .. config.pathToSDL .. file_name .. "_origin" )
  end

  -- COMMON FUNCTIONS FOR PROCESSING JSON FILE
  -----------------------------------------------------------------------------
  -- Add items into json file
  -- @param json_file: file name of a JSON file to be added new items
  -- @param parent_item: it will be added new items in added_json_items
  -- @param added_json_items: it is a table contains items to be added to json file
  -----------------------------------------------------------------------------
  function CommonSteps:AddItemsIntoJsonFile(json_file, parent_item, added_json_items)
    local file = io.open(json_file, "r")
    local json_data = file:read("*all") -- may be abbreviated to "*a";
    file:close()
    local json = require("modules/json")
    local data = json.decode(json_data)
    -- Go to parent item
    local parent = data
    for i = 1, #parent_item do
      parent = parent[parent_item[i]]
    end
    if type(added_json_items) == "string" then
      added_json_items = json.decode(added_json_items)
    end
    -- Add new items as child items of parent item.
    for k, v in pairs(added_json_items) do
      parent[k] = v
    end
    data = json.encode(data)
    file = io.open(json_file, "w")
    file:write(data)
    file:close()
  end
  -----------------------------------------------------------------------------
  -- Remove items into json file
  -- @param json_file: file name of a JSON file to be removed items
  -- @param parent_item: it will be remove items
  -- @param removed_items: it is a array of items will be removed
  -----------------------------------------------------------------------------
  function CommonSteps:RemoveItemsFromJsonFile(json_file, parent_item, removed_items)
    local file = io.open(json_file, "r")
    local json_data = file:read("*all") -- may be abbreviated to "*a";
    file:close()
    local json = require("modules/json")
    local data = json.decode(json_data)
    -- Go to parent item
    local parent = data
    for i = 1, #parent_item do
      parent = parent[i]
    end
    -- Remove items
    for i = 1, #removed_items do
      parent[removed_items[i]] = nil
    end
    data = json.encode(data)
    file = io.open(json_file, "w")
    file:write(data)
    file:close()
  end
  -----------------------------------------------------------------------------
  -- Compare 2 JSON files
  -- @param file_name1: file name of the first file
  -- @param file_name2: file name of the second file
  -- @param compared_specified_item: specify item on json to compare. Example: {"policy_table", "functional_groupings", "funtional_group1"}
  -- If it is omitted, compare all items.
  -----------------------------------------------------------------------------
  function CommonSteps:Compare2Files(file_name1, file_name2, compared_specified_item)
    local file1 = io.open(file_name1, "r")
    local data1 = file1:read("*all")
    file1:close()
    local file2 = io.open(file_name2, "r") 
    local data2 = file2:read("*all") 
    file2:close()
    local json = require("modules/json")  
    local json_data1 = json.decode(data1)
    local json_data2 = json.decode(data2)
    -- Go to specified item
    for i = 1, #compared_specified_item do 
      json_data1 = json_data1[compared_specified_item[i]]
      json_data2 = json_data2[compared_specified_item[i]] 
    end   
    return commonFunctions:is_table_equal(json_data1,json_data2)
  end

  -- COMMON FUNCTIONS FOR POLICY TABLE
  -----------------------------------------------------------------------------
  -- Query policy table database policy.sqlite
  -- @param sdl_query: sql query in format: "select <field name1, field name 2, ..> from <table name> where <field name n> = <value>".
  -- Example: "\"select entity_type from entities where group_id = 123\""
  -- @param parent_item: it will be remove items
  -- @param removed_items: it is a array of items will be removed
  -----------------------------------------------------------------------------
  function CommonSteps:QueryPolicyDataBase(sdl_query)
    -- Look for policy.sqlite file
    local policy_file1 = config.pathToSDL .. "storage/policy.sqlite"
    local policy_file2 = config.pathToSDL .. "policy.sqlite"
    local policy_file
    if old_common_steps:file_exists(policy_file1) then
      policy_file = policy_file1
    elseif old_common_steps:file_exists(policy_file2) then
      policy_file = policy_file2
    else
      common_functions:printError("policy.sqlite file is not exist")
    end
    if policy_file then
      local ful_sql_query = "sqlite3 " .. policy_file .. " " .. sdl_query
      local handler = io.popen(query, 'r')
      os.execute("sleep 1")
      local result = handler:read( '*l' )
      handler:close()
      return result
    end
  end

  -- COMMON FUNCTIONS FOR MOBILE CONNECTIONS
  -----------------------------------------------------------------------------
  -- Create mobile connection
  -- @param mobile_connection_name: name to create mobile connection. If it is omitted, use default name "mobileConnection"
  -- @param is_stoped_ATF_when_app_is_disconnected: true: stop ATF, false: ATF continues running.
  -----------------------------------------------------------------------------
  function CommonSteps:AddMobileConnection(test_case_name, mobile_connection_name)
    Test[test_case_name] = function(self)
      local tcpConnection = tcp.Connection(config.mobileHost, config.mobilePort)
      local fileConnection = file_connection.FileConnection("mobile2.out", tcpConnection)
      self[mobile_connection_name] = mobile.MobileConnection(fileConnection)
      event_dispatcher:AddConnection(self[mobile_connection_name])
      self[mobile_connection_name]:Connect()
      CommonSteps:StoreConnectionData(mobile_connection_name, self)
    end
  end

  -- COMMON FUNCTIONS FOR MOBILE SESSIONS
  -----------------------------------------------------------------------------
  -- Add new mobile session
  -- @param test_case_name: Test name
  -- @param mobile_connection_name: name of connection to create new session. If it is omitted, use default connection name "mobileConnection"
  -- @param mobile_session_name: name of new session. If it is omitted, use default connection name "mobileSession"
  -- @param is_not_started_rpc_service: true - does not start RPC service (7) after adding new session, otherwise start RPC(7) service
  -----------------------------------------------------------------------------
  function CommonSteps:AddMobileSession(test_case_name, mobile_connection_name, mobile_session_name, is_not_started_rpc_service)
    Test[test_case_name] = function(self)
      mobile_connection_name = mobile_connection_name or "mobileConnection"
      mobile_session_name = mobile_session_name or "mobileSession"
      -- If mobile connection name has not been stored, store it to use later in other functions
      if not CommonSteps:IsConnectionDataExist(mobile_connection_name, self) then
        CommonSteps:StoreConnectionData(mobile_connection_name, self)
      end
      -- Create mobile session on current connection.
      self[mobile_session_name] = mobile_session.MobileSession(self, self[mobile_connection_name])
      CommonSteps:StoreSessionData(mobile_connection_name, mobile_session_name, self)
      if not is_not_started_rpc_service then
        self[mobile_session_name]:StartService(7)
      end
    end
  end
  -----------------------------------------------------------------------------
  -- Close mobile session of an application
  -- @param test_case_name: Test name
  -- @param mobile_session_name: name of session will be closed session
  -----------------------------------------------------------------------------
  function CommonSteps:CloseMobileSession_InternalUsed(app_name, self)
    local hmi_app_id = CommonSteps:GetHmiAppId(app_name, self)
    local mobile_connection_name, mobile_session_name = CommonSteps:GetMobileConnectionNameAndSessionName(app_name, self)
    self[mobile_session_name]:Stop()
    -- Remove data for this session after it is stopped.
    self.mobile_connections[mobile_connection_name][mobile_session_name] = nil
    -- If application is not unregistered on this session, verify SDL sends BasicCommunication.OnAppUnregistered notification to HMI
    if hmi_app_id then
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = hmi_app_id})
    end
  end
  -----------------------------------------------------------------------------
  -- Close mobile session of an application
  -- @param test_case_name: Test name
  -- @param mobile_session_name: name of session will be closed session
  -----------------------------------------------------------------------------
  function CommonSteps:CloseMobileSession(test_case_name, mobile_session_name)
    Test[test_case_name] = function(self)
      mobile_session_name = mobile_session_name or "mobileSession"
      local app_name = CommonSteps:GetApplicationName(mobile_session_name, self)
      CommonSteps:CloseMobileSession_InternalUsed(app_name, self)
    end
  end
  -----------------------------------------------------------------------------
  -- Close mobile session of an application
  -- @param test_case_name: Test name
  -- @param app_name: application name will be closed session
  -----------------------------------------------------------------------------
  function CommonSteps:CloseMobileSessionByAppName(test_case_name, app_name)
    CommonSteps:CloseMobileSession_InternalUsed(app_name, self)
  end

  -- COMMON FUNCTIONS FOR SERVICES
  -----------------------------------------------------------------------------
  -- Start service
  -- @param test_case_name: Test name
  -- @param mobile_session_name: name of mobile session to start service
  -- @param service_id: id of service: RPC: 7, audio: 10, video: 11, ..; if service_id is omitted, this function starts default service (RPC: 7)
  -----------------------------------------------------------------------------
  function CommonSteps:StartService(test_case_name, mobile_session_name, service_id)
    Test[test_case_name] = function(self)
      self[mobile_session_name]:StartService(service_id or 7)
    end
  end

  -- COMMON STEPS FOR APPLICATIONS
  -----------------------------------------------------------------------------
  -- Register application
  -- @param test_case_name: Test name
  -- @param mobile_session_name: mobile session
  -- @param application_parameters: parameters are used to register application.
  -- If it is omitted, use default application parameter config.application1.registerAppInterfaceParams
  -- @param expected_on_hmi_status: value to verify OnHMIStatus notification.
  -- If this parameter is omitted, this function will check default HMI status {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}
  -- @param expected_response: expected response for RegisterAppIterface request.
  -- If expected_response parameter is omitted, this function will check default response {success = true, resultCode = "SUCCESS"}
  -----------------------------------------------------------------------------
  function CommonSteps:RegisterApplication(test_case_name, mobile_session_name, application_parameters, expected_response, expected_on_hmi_status)
    Test[test_case_name] = function(self)
      mobile_session_name = mobile_session_name or "mobileSession"
      application_parameters = application_parameters or config.application1.registerAppInterfaceParams
      local app_name = application_parameters.appName
      local CorIdRAI = self[mobile_session_name]:SendRPC("RegisterAppInterface", application_parameters)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = {appName = app_name}})
      :Do(function(_,data)
          CommonSteps:StoreApplicationData(mobile_session_name, app_name, application_parameters, data.params.application.appID, self)
        end)
      expected_response = expected_response or {success = true, resultCode = "SUCCESS"}
      self[mobile_session_name]:ExpectResponse(CorIdRAI, expected_response)
      expected_on_hmi_status = expected_on_hmi_status or {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"}
      self[mobile_session_name]:ExpectNotification("OnHMIStatus", expected_on_hmi_status)
      :Do(function(_,data)
          CommonSteps:StoreHmiStatus(app_name, data.payload, self)
        end)
    end
  end
  -----------------------------------------------------------------------------
  -- Unregister application
  -- @param test_case_name: Test name
  -- @param app_name: name of application is unregistered
  -----------------------------------------------------------------------------
  function CommonSteps:UnregisterApp(test_case_name, app_name)
    Test[test_case_name] = function(self)
      local mobile_connection_name, mobile_session_name = CommonSteps:GetMobileConnectionNameAndSessionName(app_name, self)
      local cid = self[mobile_session_name]:SendRPC("UnregisterAppInterface",{})
      self[mobile_session_name]:ExpectResponse(cid, {success = true, resultCode = "SUCCESS"})
      CommonSteps:SetApplicationStatusIsUnRegistered(app_name, self)
    end
  end
  -----------------------------------------------------------------------------
  -- Activate application
  -- @param test_case_name: Test name
  -- @param app_name: app name is activated
  -- @param expected_level: HMI level should be changed to. If expected_level omitted, activate application to "FULL".
  -- @param expected_on_hmi_status_for_other_applications: if it is omitted, this step does not verify OnHMIStatus for other application.
  -- In case checking OnHMIStatus for other applications, use below structure to input for this parameter.
  --[[{
  app_name_2 = {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"},
  app_name_3 = {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"},
  app_name_n = {hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"}
}]]
-----------------------------------------------------------------------------
function CommonSteps:ActivateApplication(test_case_name, app_name, expected_level, expected_on_hmi_status_for_other_applications)
  Test[test_case_name] = function(self)
    expected_level = expected_level or "FULL"
    local hmi_app_id = CommonSteps:GetHmiAppId(app_name, self)
    local audio_streaming_state = "NOT_AUDIBLE"
    if CommonSteps:IsMediaApp(app_name, self) then
      audio_streaming_state = "AUDIBLE"
    end
    local mobile_connect_name, mobile_session_name = CommonSteps:GetMobileConnectionNameAndSessionName(app_name, self)
    --local cid = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = hmi_app_id, level = expected_level})
    local cid = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = hmi_app_id})
    EXPECT_HMIRESPONSE(cid)
    :Do(function(_,data)
        -- if application is disallowed, HMI has to send SDL.OnAllowSDLFunctionality notification to allow before activation
        -- If isSDLAllowed is false, consent for sending policy table through specified device is required.
        if data.result.isSDLAllowed ~= true then
          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
          EXPECT_HMICALL("BasicCommunication.ActivateApp")
          :Do(function(_,data)
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
            end)
        end
        self[mobile_session_name]:ExpectNotification("OnHMIStatus", {hmiLevel = expected_level, audioStreamingState = audio_streaming_state, systemContext = "MAIN"})
        -- Verify OnHMIStatus for other applications
        if expected_on_hmi_status_for_other_applications then
          for k_app_name, v in pairs(expected_on_hmi_status_for_other_applications) do
            local mobile_connection_name, mobile_session_name = CommonSteps:GetMobileConnectionNameAndSessionName(k_app_name, self)
            self[mobile_session_name]:ExpectNotification("OnHMIStatus", v)
            :Do(function(_,data)
                -- Store OnHMIStatus notification to use later
                CommonSteps:StoreHmiStatus(app_name, data.payload, self)
              end)
          end -- for k_app_name, v
        end -- if expected_on_hmi_status_for_other_applications then
      end) -- :Do(function(_,data)
  end
end
-----------------------------------------------------------------------------
-- Change hmiLevel to LIMITED
-- @param test_case_name: Test name
-- @param app_name: name of application is changed to limited
-----------------------------------------------------------------------------
function CommonSteps:ChangeHMIToLimited(test_case_name, app_name)
  Test[test_case_name] = function(self)
    local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
      {
        appID = CommonSteps:GetHmiAppId(app_name, self),
        reason = "GENERAL"
      })
    local mobile_connection_name, mobile_session_name = CommonSteps:GetMobileConnectionNameAndSessionName(app_name, self)
    self[mobile_session_name]:ExpectNotification("OnHMIStatus", {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
    :Do(function(_,data)
        -- Store OnHMIStatus notification to use later
        CommonSteps:StoreHmiStatus(app_name, data.payload, self)
      end)
  end
end
-----------------------------------------------------------------------------
-- Change hmiLevel to LIMITED
-- @param test_case_name: Test name
-- @param app_name: name of application is changed to limited
-----------------------------------------------------------------------------
function CommonSteps:ChangeHmiLevelToNone(test_case_name, app_name)
  Test[test_case_name] = function(self)
    local hmi_app_id = CommonSteps:GetHmiAppId(app_name, self)
    self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = hmi_app_id, reason = "USER_EXIT"})
    local mobile_connection_name, mobile_session_name = CommonSteps:GetMobileConnectionNameAndSessionName(app_name, self)
    self[mobile_session_name]:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    :Do(function(_,data)
        -- Store OnHMIStatus notification to use later
        CommonSteps:StoreHmiStatus(app_name, data.payload, self)
      end)
  end
end

-- COMMON FUNCTIONS FOR HMI
-----------------------------------------------------------------------------
-- Initialize HMI
-- @param test_case_name: Test name
-----------------------------------------------------------------------------
function CommonSteps:InitializeHmi(test_case_name)
  Test[test_case_name] = function(self)
    self:initHMI()
  end
end
-----------------------------------------------------------------------------
-- HMI responds OnReady request from SDL
-- @param test_case_name: Test name
-----------------------------------------------------------------------------
function CommonSteps:HmiRespondOnReady(test_case_name)
  Test[test_case_name] = function(self)
    self:initHMI_onReady()
  end
end
-----------------------------------------------------------------------------
-- Ignition Off
-- @param test_case_name: Test name
-----------------------------------------------------------------------------
function CommonSteps:IgnitionOff(test_case_name)
  Test[test_case_name] = function(self)
    local hmi_app_ids = CommonSteps:GetHmiAppIds(self)
    self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "IGNITION_OFF"})
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
    :Times(#hmi_app_ids)
    -- Fore stop SDL if it has not stopped.
    StopSDL()
  end
end
-----------------------------------------------------------------------------
-- Ignition On: Start SDL, start HMI and add a mobile connection.
-- @param test_case_name: Test name
-----------------------------------------------------------------------------
function CommonSteps:IgnitionOn(test_case_name)
  CommonSteps:StartSDL(test_case_name .. "_StartSDL")
  CommonSteps:InitializeHmi(test_case_name.."_InitHMI")
  CommonSteps:HmiRespondOnReady(test_case_name.."_InitHMI_onReady")
  CommonSteps:AddMobileConnection(test_case_name.."_ConnectMobile", "mobileConnection")
end

-- COMMON FUNCTIONS FOR SDL
-----------------------------------------------------------------------------
-- Start SDL
-- @param test_case_name: Test name
-----------------------------------------------------------------------------
function CommonSteps:StartSDL(test_case_name)
  Test[test_case_name] = function(self)
    StartSDL(config.pathToSDL, config.ExitOnCrash)
  end
end
-----------------------------------------------------------------------------
-- Stop SDL
-- @param test_case_name: Test name
-----------------------------------------------------------------------------
function CommonSteps:StopSDL(test_case_name)
  Test[test_case_name] = function(self)
    StopSDL()
  end
end

-- COMMON FUNCTIONS FOR POST-CONDITION
-----------------------------------------------------------------------------
-- Restore smartDeviceLink.ini File
-- @param test_case_name: Test name
-----------------------------------------------------------------------------
function CommonSteps:RestoreIniFile(test_case_name)
  Test[test_case_name] = function(self)
    common_preconditions:RestoreFile("smartDeviceLink.ini")
  end
end

return CommonSteps
