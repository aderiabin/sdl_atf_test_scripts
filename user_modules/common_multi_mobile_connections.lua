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
local policy_table = require('user_modules/shared_testcases/testCasesForPolicyTable')
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
	-- CommonSteps:PrintError("'" .. app_name .. "' application is not exist so that mobile session is not found.")
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
	os.execute(" cp " .. config.pathToSDL .. file_name .. " " .. config.pathToSDL .. "origin_" ..file_name)
end
-----------------------------------------------------------------------------
-- Restore origin of file (FileName) in /bin folder
-- @param file_name: file name will be backed up
-----------------------------------------------------------------------------
function CommonSteps:RestoreFile(file_name)
	os.execute(" cp " .. config.pathToSDL .. "origin_" .. file_name .. " " ..config.pathToSDL .. file_name )
	-- os.execute( " rm -f " .. config.pathToSDL .. "origin_"..file_name )
end

-- COMMON FUNCTIONS FOR PROCESSING JSON FILE
-----------------------------------------------------------------------------
-- Add items into json file
-- @param json_file: file name of a JSON file to be added new items
-- @param parent_item: it will be added new items in added_json_items
-- @param added_json_items: it is a table contains items to be added to json file
-----------------------------------------------------------------------------
local match_result = "null"
local temp_replace_value = "\"Thi123456789\""
function CommonSteps:AddItemsIntoJsonFile(json_file, parent_item, added_json_items)
	common_functions:printTable(added_json_items)
	-- print(json_file)
	local file = io.open(json_file, "r")
	local json_data = file:read("*all")
	file:close()
	json_data_update = string.gsub(json_data, match_result, temp_replace_value)
	local json = require("modules/json")
	local data = json.decode(json_data_update)
	-- Go to parent item
	local parent = data
	for i = 1, #parent_item do
		if not parent[parent_item[i]] then
			parent[parent_item[i]] = {}
		end
		parent = parent[parent_item[i]]
	end
	if type(added_json_items) == "string" then
		added_json_items = json.decode(added_json_items)
	end
	
	for k, v in pairs(added_json_items) do
		parent[k] = v
	end
	
	data = json.encode(data)
	
	data_revert = string.gsub(data, temp_replace_value, match_result)
	
	file = io.open(json_file, "w")
	file:write(data_revert)
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
	local json_data = file:read("*all")
	file:close()
	
	json_data_update = string.gsub(json_data, match_result, temp_replace_value)
	local json = require("modules/json")
	local data = json.decode(json_data_update)
	-- Go to parent item
	local parent = data
	for i = 1, #parent_item do
		parent = parent[parent_item[i]]
	end
	
	-- Remove items
	
	-- for i = 1, #removed_items do
	-- print("Vao day khong")
	-- parent[removed_items[i]] = nil
	-- end
	data = json.encode(data)
	data_revert = string.gsub(data, temp_replace_value, match_result)
	file = io.open(json_file, "w")
	file:write(data_revert)
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
	print(sdl_query)
	if policy_file then
		local ful_sql_query = "sqlite3 " .. policy_file .. " \"" .. sdl_query .. "\""
		local handler = io.popen(ful_sql_query, 'r')
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
		print("mobileSession:"..mobile_session_name)
		common_functions:printTable(application_parameters)
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
		self:runSDL()
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

-----------------------------------------------------------------------------
-- Precondition steps: 
-- @param test_case_name: Test name
-- @param number_of_precondition_steps: Number from 1 to 6: 
-- 1: Include step InitHMI
-- 2: Include steps InitHMI and InitHMI_OnReady
-- 3: Include steps InitHMI, InitHMI_OnReady and AddMobileConnection
-- 4: Include steps InitHMI, InitHMI_OnReady, AddMobileConnection and AddMobileSession
-- 5: Include steps InitHMI, InitHMI_OnReady, AddMobileConnection, AddMobileSession and RegisterApp
-- 6: Include steps InitHMI, InitHMI_OnReady, AddMobileConnection, AddMobileSession, RegisterApp and ActivateApp
-----------------------------------------------------------------------------
function CommonSteps:PreconditionSteps(test_case_name, number_of_precondition_steps)
	local mobile_connection_name = "mobileConnection"
	local mobile_session_name = "mobileSession"
	local app = config.application1.registerAppInterfaceParams 
	if number_of_precondition_steps >= 1 then
		CommonSteps:StartSDL(test_case_name .. "_StartSDL")
	end 
	if number_of_precondition_steps >= 2 then
		CommonSteps:InitializeHmi(test_case_name .. "_InitHMI")
	end
	if number_of_precondition_steps >= 3 then
		CommonSteps:HmiRespondOnReady(test_case_name .. "_InitHMI_onReady")
	end 
	if number_of_precondition_steps >= 4 then
		CommonSteps:AddMobileConnection(test_case_name .. "_AddDefaultMobileConnection_" .. mobile_connection_name, mobile_connection_name)
	end
	if number_of_precondition_steps >= 5 then
		CommonSteps:AddMobileSession(test_case_name .. "_AddDefaultMobileConnect_" .. mobile_session_name, mobile_connection_name, mobile_session_name)
	end 
	if number_of_precondition_steps >= 6 then
		CommonSteps:RegisterApplication(test_case_name .. "_Register_App", mobile_session_name)		 
	end
	if number_of_precondition_steps >= 7 then
		CommonSteps:ActivateApplication(test_case_name .. "_Activate_App", app.appName)		
	end
end




function CommonSteps:CheckPolicyTable(test_case_name, sql_query, is_valid_pt, error_message)
	Test[test_case_name] = function (self)
		local result = CommonSteps:QueryPolicyDataBase(sql_query)
		if (result and is_valid_pt) or ((not result) and (not is_valid_pt))then
			return true
			-- report PASSED
		else
			self:FailTestCase(error_message)
			return false
		end
	end
end

function CommonSteps:CheckNewParameterInPreloadedPt(test_case_name, parent_item, added_json_items, sql_query, is_valid_pt, error_message) 
	CommonSteps:StopSDL(test_case_name .. "_Precondition_StopSDL") 
	Test[test_case_name .. "_Precondition_RestoreDefaultPreloadedPt"] = function (self)
		-- CommonSteps:RestoreFile("sdl_preloaded_pt.json")
		old_common_steps:DeletePolicyTable()
	end 
	
	Test[test_case_name .. "_UpdatePreloadedPt"] = function (self)
		CommonSteps:AddItemsIntoJsonFile(config.pathToSDL .. 'sdl_preloaded_pt.json', parent_item, added_json_items)
	end 
	CommonSteps:StartSDL(test_case_name .. "_StartSDL") 
	
	CommonSteps:CheckPolicyTable(test_case_name .. "_CheckPolicyTable", sql_query, is_valid_pt, error_message)
end
function CommonSteps:VerifyPTUFailedWithInvalidData(test_case_name, ptu_file, mobile_session_name)
	mobile_session_name = mobile_session_name or "mobileSession"
	Test[test_case_name .. "_VerifyPTUFailedWithInvalidData"] = function (self)
		
		local CorIdSystemRequest = self[mobile_session_name]:SendRPC("SystemRequest",
		{
			fileName = "PolicyTableUpdate",
			requestType = "PROPRIETARY"
		},
		ptu_file)
		
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
		--Todo:
		--hmi side: expect SDL.OnStatusUpdate
		EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
		:ValidIf(function(exp,data)
			if 
			exp.occurences == 1 and
			data.params.status == "UPDATE_NEEDED" then
				print ("\27[31m SDL.OnStatusUpdate came with wrong values. PTU file validation failed. Exchange wasn't successful")
				return true
			elseif
			exp.occurences == 1 and
			data.params.status == "UP_TO_DATE" then
				print ("\27[31m SDL.OnStatusUpdate came with wrong values. Exchange should not be successful.Expected in first occurrences status 'UPDATE_NEEDED', got '" .. tostring(data.params.status) .. "' \27[0m")
				return false
			elseif
			exp.occurences == 3 and
			data.params.status == "UPDATING" then
				print ("\27[31m SDL.OnStatusUpdate came with wrong values. Exchange should not be successful.Expected in second occurrences status 'UPDATE_NEEDED', got '" .. tostring(data.params.status) .. "' \27[0m")
				return true
			end
			
		end)
		:Times(Between(1,2))
		
		--mobile side: expect SystemRequest response
		EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
		:Times(0)
	end
end
function CommonSteps:CheckNewParameterInPolicyUpdate(test_case_name, parent_item, added_json_items, sql_query, is_valid_pt, error_message) 
	
	-- Assume precondition: App is registered and local policy does not have the new parameter.
	
	local policy_file = config.pathToSDL .. 'sdl_preloaded_pt.json'
	
	Test[test_case_name .. "_Precondition_copy_sdl_preloaded_pt.json"] = function (self)
		os.execute(" cp " .. config.pathToSDL .. "origin_sdl_preloaded_pt.json".. " " .. config.pathToSDL .. "update_policy_table.json")
	end 
	
	Test[test_case_name .. "_UpdatePolicyTableJSONFile"] = function (self)
		CommonSteps:AddItemsIntoJsonFile(config.pathToSDL .. 'update_policy_table.json', parent_item, added_json_items)
	end 
	
	policy_table:updatePolicy(config.pathToSDL .. 'update_policy_table.json', nil, "PTUSuccessWithExistedValidEntityOn")
	
	CommonSteps:CheckPolicyTable(test_case_name .. "_CheckPolicyTable", sql_query, is_valid_pt, error_message)
end

function CommonSteps:CheckNewParameterOmittedInPreloadedPt(test_case_name, parent_item, items, sql_query, is_valid_pt, error_message, temp_sdl_preloaded_pt) 
	CommonSteps:StopSDL(test_case_name .. "_Precondition_StopSDL") 
	if(not temp_sdl_preloaded_pt) then
		Test[test_case_name .. "_Precondition_RestoreDefaultPreloadedPt"] = function (self)
			CommonSteps:RestoreFile("sdl_preloaded_pt.json")
			
			old_common_steps:DeletePolicyTable()
		end 
	else
		Test[test_case_name .. "_Precondition_RestoreDefaultPreloadedPt"] = function (self)
			os.execute(" cp " .. temp_sdl_preloaded_pt.. " " .. config.pathToSDL .. "sdl_preloaded_pt.json")
			old_common_steps:DeletePolicyTable()
		end 
	end
	Test[test_case_name .. "_UpdatePreloadedPt"] = function (self) 
		CommonSteps:RemoveItemsFromJsonFile(config.pathToSDL .. 'sdl_preloaded_pt.json', parent_item, items)
	end 
	
	CommonSteps:StartSDL(test_case_name .. "_StartSDL")
	
	CommonSteps:CheckPolicyTable(test_case_name .. "_CheckPolicyTable", sql_query, is_valid_pt, error_message)
	
end

function CommonSteps:CheckNewParameterOmittedInPolicyUpdate(test_case_name, parent_item, items, sql_query, is_valid_pt, error_message) 
	Test[test_case_name .. "_Precondition_copy_sdl_preloaded_pt.json"] = function (self)
		os.execute(" cp " .. config.pathToSDL .. "origin_sdl_preloaded_pt.json".. " " .. config.pathToSDL .. "update_policy_table.json")
	end 
	Test[test_case_name .. "_UpdatePolicyTableJSONFile"] = function (self) 
		CommonSteps:RemoveItemsFromJsonFile(config.pathToSDL .. 'update_policy_table.json', parent_item, items)
	end
	-- XXXXXXXXXXXXXX
	function Test:AAAAAAAAA111111111111111111111111()
		
	end
	CommonSteps:VerifyPTUFailedWithInvalidData(test_case_name, config.pathToSDL .. 'update_policy_table.json')
	-- XXXXXXXXXXXXXX
	CommonSteps:CheckPolicyTable(test_case_name .. "_CheckPolicyTable", sql_query, is_valid_pt, error_message)
end

function CommonSteps:CheckNewParameterOmittedInSnapShot(test_case_name, parent_item, file_name, items, is_valid_pt, error_message, temp_sdl_preloaded_pt) 
	
	CommonSteps:StopSDL(test_case_name .. "_Precondition_StopSDL") 
	if(not temp_sdl_preloaded_pt) then
		Test[test_case_name .. "_Precondition_RestoreDefaultPreloadedPt"] = function (self)
			CommonSteps:RestoreFile("sdl_preloaded_pt.json")
			old_common_steps:DeletePolicyTable()
		end 
	else
		Test[test_case_name .. "_Precondition_RestoreDefaultPreloadedPt"] = function (self)
			os.execute(" cp " .. temp_sdl_preloaded_pt.. " " .. config.pathToSDL .. "sdl_preloaded_pt.json")
			old_common_steps:DeletePolicyTable()
		end 
	end 
	
	Test[test_case_name .. "_Precondition_copy_sdl_preloaded_pt.json"] = function (self)
		os.execute(" cp " .. config.pathToSDL .. "origin_sdl_preloaded_pt.json".. " " .. config.pathToSDL .. "update_policy_table.json")
	end 
	Test[test_case_name .. "_UpdatePolicyTableJSONFile"] = function (self) 
		CommonSteps:RemoveItemsFromJsonFile(config.pathToSDL .. 'sdl_preloaded_pt.json', parent_item, items)
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
	CommonSteps:IgnitionOn("Precondition_RegisterApp")
	CommonSteps:AddMobileSession("AddMobileSession")
	CommonSteps:RegisterApplication("RegisterApp")
	CommonSteps:ActivateApplication("ActivateApp", config.application1.registerAppInterfaceParams.appName)
	
	function Test:Precondition_TriggerSDLSnapshotCreation_UpdateSDL()
		local RequestIdUpdateSDL = self.hmiConnection:SendRequest("SDL.UpdateSDL")
		
		--hmi side: expect SDL.UpdateSDL response from HMI
		EXPECT_HMIRESPONSE(RequestIdUpdateSDL,{result = {code = 0, method = "SDL.UpdateSDL", result = "UPDATE_NEEDED" }})
		
		DelayedExp(2000)
	end
	CommonSteps:CheckSnapShot(test_case_name .. "_CheckSnapShot", file_name, items, is_valid_pt, error_message)
end

function CommonSteps:CheckNewParameterExistedInSnapShot(test_case_name, parent_item, file_name, added_json_items, is_valid_pt, error_message) 
	
	CommonSteps:StopSDL(test_case_name .. "_Precondition_StopSDL") 
	Test[test_case_name .. "_Precondition_RestoreDefaultPreloadedPt"] = function (self)
		old_common_steps:DeletePolicyTable()
	end 
	
	Test[test_case_name .. "_AddNewItemIntoPreloadedPT"] = function (self) 
		CommonSteps:AddItemsIntoJsonFile(config.pathToSDL .. 'sdl_preloaded_pt.json', parent_item, added_json_items)
	end 
	
	-- CommonSteps:StartSDL(test_case_name .. "_StartSDL") 
	CommonSteps:IgnitionOn("Precondition_RegisterApp")
	common_functions:printTable(config.pathToSDL .. 'sdl_preloaded_pt.json')
	CommonSteps:AddMobileSession("AddMobileSession")
	CommonSteps:RegisterApplication("RegisterApp")
	CommonSteps:ActivateApplication("ActivateApp", config.application1.registerAppInterfaceParams.appName)
	function DelayedExp(time)
		local event = events.Event()
		event.matches = function(self, e) return self == e end
		EXPECT_EVENT(event, "Delayed event")
		:Timeout(time+1000)
		RUN_AFTER(function()
			RAISE_EVENT(event, event)
		end, time)
	end
	function Test:Precondition_TriggerSDLSnapshotCreation_UpdateSDL()
		local RequestIdUpdateSDL = self.hmiConnection:SendRequest("SDL.UpdateSDL")
		
		--hmi side: expect SDL.UpdateSDL response from HMI
		EXPECT_HMIRESPONSE(RequestIdUpdateSDL,{result = {code = 0, method = "SDL.UpdateSDL", result = "UPDATE_NEEDED" }})
		
		DelayedExp(2000)
	end
	CommonSteps:CheckSnapShot(test_case_name .. "_CheckSnapShot", file_name, "disallowed_by_ccs_entities_on", is_valid_pt, error_message)
end

function CommonSteps:CheckSnapShot(test_case_name, file_name, new_item, is_valid_pt, error_message)
	Test[test_case_name] = function (self)
		local result = CommonSteps:VerifyNewParamInSnapShot(file_name, new_item)
		if (result and is_valid_pt) or ((not result) and (not is_valid_pt))then
			-- report PASSED
			return true
		else
			self:FailTestCase(error_message)
			return false
		end
	end
end

function CommonSteps:VerifyNewParamInSnapShot(file_name, new_item)
	
	local file_json = io.open(file_name, "r")
	local json_snap_shot = file_json:read("*all") -- may be abbreviated to "*a";
	if type(new_item) == "table" then
		new_item = json.encode(new_item)
	end
	-- Add new items as child items of parent item.
	common_functions:printTable(added_json_items)
	item = json_snap_shot:match(new_item)
	
	if item == nil then
		print ( " \27[31m disallowed_by_ccs_entities_on is not found in SnapShot \27[0m " )
		return false
	else
		print ( " \27[31m disallowed_by_ccs_entities_on is found in SnapShot \27[0m " )
		return true
		
	end
	file_json:close()
	
end

function CommonSteps:AddEmptyTestForNewTestCase(message)
	common_functions:newTestCasesGroup(message)
end

return CommonSteps