--[[ This script contains common functions that are used in testing APPLINK-22736: [Policies], [Validation] New CCS-related params in PTU, PreloadedPT, SnapshotPT
-- This library is used for below scripts:


-- Author: Thi Nguyen
-- ATF version: 2.2
]]

Test = require('user_modules/connect_without_mobile_connection')
local common_functions = require('user_modules/common_multi_mobile_connections')
local commonFunctionsForCqr22736 = {}
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local common_functions2 = require('user_modules/common_multi_mobile_connections')
local sdl_config = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')
require('user_modules/AppTypes')



---------------------------------------------------------------------------------------------
----------------------- Common Variables For CRQ 22736 Only----------------------------------
---------------------------------------------------------------------------------------------
PolicyTableTemplate = "user_modules/shared_testcases/PolicyTables/DefaultPolicyTableWith_group1.json"
PolicyTable = "user_modules/shared_testcases/PolicyTables/TestingPolicyTable.json"

appID = "0000001"
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
storagePath = config.pathToSDL .. sdl_config:GetValue("AppStorageFolder") .. "/" .. tostring(config.application1.registerAppInterfaceParams.appID .. "_" .. tostring(config.deviceMAC) .. "/")
group_name = "Location-1"
ccs_entity = "disallowed_by_ccs_entities_on"
valid_entity_id = 125
valid_entity_type = 128
file_name = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json"
new_entities_on = "disallowed_by_ccs_entities_on"
new_entities_of = "disallowed_by_ccs_entities_off"
test_data = {
	ccs_consent_groups = {
		parent_item = {"policy_table", "module_config"},
		sdl_query = "select * from ccs_consent_group",
		error_message = "error_message"
	},
	disallowed_by_ccs_entities_on = {
		parent_item = {"policy_table", "functional_groupings", "Location-1"},
		sdl_query = "select * from ccs_consent_group",
		error_message = "error_message" 
	},
	disallowed_by_ccs_entities_off = {
		parent_item = {"policy_table", "functional_groupings", "Location-1"},
		sdl_query = "select * from ccs_consent_group",
		error_message = "error_message" 
	},
	
	
	parent_item = {"policy_table", "functional_groupings", "Location-1"},
	entityType = {
		valid_value = 2,
		invalid_values = {
			{description = "WrongType_String", value = "1"},
			{description = "OutUpperBound", value = 129},
			{description = "OutLowerBound", value = -1},
			{description = "WrongType_Float", value = 10.5},
			{description = "WrongType_EmptyTable", value = {}},
			{description = "WrongType_Table", value = {entityType = 1, entityID = 1}},
			{description = "Missed", value = nil}
		},
		valid_values = {
			{description = "LowerBound", value = 0},
			{description = "UpperBound", value = 128}
		},
		sdl_query = "select entities.entity_type from entities, functional_group where entities.group_id = functional_group.id",
		error_message = "error_message"
	},
	entityID = {
		valid_value = 2,
		invalid_values = {
			{description = "WrongType_String", value = "1"},
			{description = "OutUpperBound", value = 129},
			{description = "OutLowerBound", value = -1},
			{description = "WrongType_Float", value = 10.5},
			{description = "WrongType_EmptyTable", value = {}},
			{description = "WrongType_Table", value = {entityID = 1, entityType = 1}}, 
			{description = "Missed", value = nil}
		},
		valid_values = {
			{description = "LowerBound", value = 0},
			{description = "UpperBound", value = 128}
		}, 
		sdl_query = "select entities.entity_id from entities, functional_group where entities.group_id = functional_group.id",
		error_message = "error_message"
	}
}



---------------------------------------------------------------------------------------------
--------------------------------- Common Functions For CRQ-----------------------------------
---------------------------------------------------------------------------------------------
-- list of new functions on common file.
-- CommonSteps:CheckNewParameterInPreloadedPt(test_case_name, parent_item, added_json_items, sql_query, is_valid_pt, error_message) 

function commonFunctionsForCqr22736:StartHmiMobileRegisterActivateApp(test_case_name)
	local mobile_connection_name = "mobileConnection"
	local mobile_session_name = "mobileSession"
	local app = config.application1.registerAppInterfaceParams 
	common_functions:InitializeHmi(test_case_name .. "_InitHMI")
	common_functions:HmiRespondOnReady(test_case_name .. "_InitHMI_onReady")
	common_functions:AddMobileConnection(test_case_name .. "_AddDefaultMobileConnection_" .. mobile_connection_name, mobile_connection_name)
	common_functions:AddMobileSession(test_case_name .. "_AddDefaultMobileConnect_" .. mobile_session_name, mobile_connection_name, mobile_session_name)
	common_functions:RegisterApplication(test_case_name .. "_Register_App", mobile_session_name, app)		 
	-- common_functions:ActivateApplication(test_case_name .. "_Activate_App", app.appName)		
end


function commonFunctionsForCqr22736:Precondition_StartSdlWithout_disallowed_by_ccs_entities_on(test_case_name)
	function Test:AAAAAAAA12()
		
	end
	
	-- Verify case disallowed_by_ccs_entities_on parameter is omitted
	local ful_test_case_name = test_case_name .. ": disallowed_by_ccs_entities_on is omitted in Preloaded_PT.json"
	common_functions:AddEmptyTestForNewTestCase(ful_test_case_name)
	local sdl_query = "select "
	local error_message = "error_message"
	common_functions:CheckNewParameterOmittedInPreloadedPt(test_case_name, test_data.parent_item, {"disallowed_by_ccs_entities_on"}, sdl_query, false, error_message) 
	
	function Test:AAAAAAAA188888()
		
	end
	commonFunctionsForCqr22736:StartHmiMobileRegisterActivateApp(test_case_name)
	
	function Test:AAAAAAAA1()
		
	end
	
end

function commonFunctionsForCqr22736:Precondition_StartSdlWith_disallowed_by_ccs_entities_on(test_case_name)
	-- Verify case disallowed_by_ccs_entities_on parameter is valid
	local ful_test_case_name = test_case_name .. ": disallowed_by_ccs_entities_on is valid in Preloaded_PT.json"
	local error_message = "error_message"
	local testing_value = {
			disallowed_by_ccs_entities_on = {{
				entityType = test_data.entityType.valid_value,
				entityID = test_data.entityID.valid_value
		}}
	}
	common_functions:AddEmptyTestForNewTestCase(ful_test_case_name)
	common_functions:CheckNewParameterInPreloadedPt(test_case_name, test_data.parent_item, testing_value, test_data.entityType.sdl_query, true, test_data.entityType.error_message) 
	commonFunctionsForCqr22736:StartHmiMobileRegisterActivateApp(test_case_name)
end

local parent_item = {"policy_table", "module_config"}

local added_json_items = 
[[
{
	"device_data": {
		"HUU40DAS7F970UEI17A73JH32L41K32JH4L1K234H3K4": {
			"user_consent_records": {
				"0000001": {
					"consent_groups": {
						"Location": true
					},
					"input": "GUI",
					"time_stamp": "2015-10-09T18:07:21Z"
				}
			}
		}
	}
}
]]

common_functions:AddItemsIntoJsonFile(config.pathToSDL .. 'sdl_preloaded_pt.json', parent_item, added_json_items)
function commonFunctionsForCqr22736:Precondition_StartSdlWithout_ccs_consent_groups(test_case_name)
	-- Verify case ccs_consent_groups parameter is omitted
	local ful_test_case_name = test_case_name .. "TC_1: ccs_consent_groups is omitted in Preloaded_PT.json"
	common_functions:AddEmptyTestForNewTestCase(ful_test_case_name)
	local sdl_query = "select * from ccs_consent_group"
	local error_message = "error_message"
	local parent_item = test_data.ccs_consent_groups.parent_item
	
	common_functions:CheckNewParameterOmittedInPreloadedPt(test_case_name, parent_item, added_json_items, test_data.ccs_consent_groups.sdl_query, false, error_message, config.pathToSDL .. 'sdl_preloaded_pt.json') 
	commonFunctionsForCqr22736:StartHmiMobileRegisterActivateApp(test_case_name)	
end


function commonFunctionsForCqr22736:addDisAllowedEntityIntoPolicy(consentGroup, entitiesOnOff, entityType, entityId)
	if consentGroup == nil then
		consentGroup = "Group"
	end
	if entitiesOnOff == nil then
		entitiesOnOff = {}
	end
	if entityType == nil then
		entityType = {}
	end
	if entityId == nil then
		entityId = {}
	end
	local TestCaseName = "CreatePolicyTable"
	if consentGroup ~= nil and entitiesOnOff ~= nil and entityType ~= nil and entityId ~= nil
	then TestCaseName = TestCaseName .. consentGroup .. entitiesOnOff .. "_entityType:" .. tostring(entityType) .. "_entityId:".. tostring(entityId) end
	
	Test[TestCaseName] = function(self)
		local file = io.open(PolicyTableTemplate, "r")
		
		local json_data = file:read("*all") -- may be abbreviated to "*a";
		file:close()
		
		local json = require("modules/json")
		
		local data = json.decode(json_data)
		
		data.policy_table.functional_groupings[consentGroup][entitiesOnOff] = {}
		
		data.policy_table.functional_groupings[consentGroup][entitiesOnOff]["entityType"] = {entityType}
		
		data.policy_table.functional_groupings[consentGroup][entitiesOnOff]["entityID"] = {entityId}
		
		data = json.encode(data)
		local file2 = io.open(PolicyTable, "w")
		file2:write(data)
		file2:close()
		return PolicyTable
	end
end

function commonFunctionsForCqr22736:verifyPtuFailedWhenParamIsInvalid(PTName, iappID, TestName)
	
	if (TestName == nil) then
		TestName = "PtuFailed"
	end
	Test[TestName] = function(self)
		
		if not iappID then
			iappID = self.applications[config.application1.registerAppInterfaceParams.appName]
		end 
		
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
					requestType = "PROPRIETARY",
					appID = iappID
				},
				PTName)
				
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
				
				-- hmi side: expect SDL.OnStatusUpdate
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
				
				
				EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
				:Times(0)
			end)
		end)		
	end
end

-- Remove 
function commonFunctionsForCqr22736:addDisAllowedEntityIntoPreloadedPT(consentGroup, entitiesOnOff, entityType, entityId)
	pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
	if consentGroup == nil then
		consentGroup = "Group"
	end
	if entitiesOnOff == nil then
		entitiesOnOff = {}
	end
	if entityType == nil then
		entityType = {}
	end
	if entityId == nil then
		entityId = {}
	end
	local TestCaseName = "CreatePolicyTable"
	if consentGroup ~= nil and entitiesOnOff ~= nil and entityType ~= nil and entityId ~= nil then 
		TestCaseName = TestCaseName .. consentGroup .. entitiesOnOff .. "_entityType:" .. tostring(entityType) .. "_entityId:".. tostring(entityId) 
	end
	
	
	local file = io.open(pathToFile, "r")
	
	local json_data = file:read("*all") -- may be abbreviated to "*a";
	file:close()
	
	json_data_update = string.gsub(json_data, match_result, temp_replace_value)
	
	local json = require("modules/json")
	
	local data = json.decode(json_data_update)
	
	data.policy_table.functional_groupings[consentGroup][entitiesOnOff] = {}
	
	data.policy_table.functional_groupings[consentGroup][entitiesOnOff]["entityType"] = {entityType}
	
	data.policy_table.functional_groupings[consentGroup][entitiesOnOff]["entityID"] = {entityId}
	
	data = json.encode(data)
	data_convert = string.gsub(json_data, temp_replace_value, match_result)
	local file2 = io.open(pathToFile, "w")
	file2:write(data_convert)
	file2:close()
	return pathToFile
end



function commonFunctionsForCqr22736:checkLocalPolicyTableCaseValidEntities(test_case_name, group_id)
	
	-- Test to check ccpu_version parameter in policy DB
	Test["CheckLocalPolicyTableCase"..tostring(groupid)] = function (self)
		
		local query
		
		if commonSteps:file_exists(config.pathToSDL .. "storage/policy.sqlite") then
			
			query = "sqlite3 " .. config.pathToSDL .. "storage/policy.sqlite".. " \"select entity_type from entities where group_id = \"".. group_id
			
		elseif commonSteps:file_exists(config.pathToSDL .. "policy.sqlite") then
			query = "sqlite3 " .. config.pathToSDL .. "policy.sqlite".. " \"select group_id, entity_type, entity_id, on_off from entities\"".. group_id
		else userPrint( 31, "policy.sqlite is not found" )
		end
		
		if query ~= nil then		
			os.execute("sleep 3")
			local handler = io.popen(query, 'r')
			os.execute("sleep 1")
			local entity = handler:read( '*l' )
			handler:close()
			if entity ~= nil then
				return true
			else
				self:FailTestCase("entities value in DB is unexpected value " .. tostring(group_id))
				return false 
			end
		end
	end
end
-- Remove 
function commonFunctionsForCqr22736:checkLocalPolicyTableCaseInvalidEntities(test_case_name, group_id)
	-- Test to check ccpu_version parameter in policy DB
	Test["CheckLocalPolicyTableCase"..tostring(test_case_name)] = function (self)
		local query
		
		if commonSteps:file_exists(config.pathToSDL .. "storage/policy.sqlite") then
			query = "sqlite3 " .. config.pathToSDL .. "storage/policy.sqlite".. " \"select entity_type from entities where group_id = \"".. group_id
		elseif commonSteps:file_exists(config.pathToSDL .. "policy.sqlite") then
			query = "sqlite3 " .. config.pathToSDL .. "policy.sqlite".. " \"select group_id, entity_type, entity_id, on_off from entities\"".. group_id
		else userPrint( 31, "policy.sqlite is not found" )
		end
		
		if query ~= nil then
			
			os.execute("sleep 3")
			local handler = io.popen(query, 'r')
			os.execute("sleep 1")
			local entity = handler:read( '*l' )
			handler:close()
			if entity ~= nil then
				self:FailTestCase("entities value in DB is also saved in local policy table althought invalid param " .. tostring(group_id))
				return false
			else
				self:FailTestCase("entities value in DB is unexpected value " .. tostring(group_id))
				return true 
			end
		end
	end
end

function commonFunctionsForCqr22736:checkExistedEntityInSnapshot(funtional_group)
	local errorFlag = false
	local ErrorMessage = ""
	local SDLsnapshot = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json"
	local pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
	
	local file_preloaded = io.open(pathToFile, "r")
	
	local json_data_preloaded = file_preloaded:read("*all") -- may be abbreviated to "*a";
	file_preloaded:close()
	local file_snap_shot = io.open(SDLsnapshot, "r")
	
	local json_snap_shot = file_snap_shot:read("*all") -- may be abbreviated to "*a";
	file_snap_shot:close()
	local json = require("modules/json")
	
	local data_preloaded = json.decode(json_data_preloaded)
	local data_snap_shot = json.decode(json_snap_shot)
	local groupid = data_snap_shot.policy_table.functional_groupings[funtional_group]["rpcs"]
	common_functions:printTable(groupid)
	local groupid_preloaded = data_preloaded.policy_table.functional_groupings[funtional_group]["rpcs"]
	common_functions:printTable(groupid_preloaded)
	if groupid == groupid_preloaded then
		return true
	else
		return false
	end
end

function commonFunctionsForCqr22736:checkNonExistedItemInSnapshot(item)
	local SDLsnapshot = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json"
	Test["CheckNonExistedItemInSnapshot"..tostring(item)] = function (self)
		local file_snap_shot = io.open(SDLsnapshot, "r")
		
		local json_snap_shot = file_snap_shot:read("*all") -- may be abbreviated to "*a";
		entities = json_snap_shot:match(item)
		if entities == nil then
			
			return true
			
			
		else
			
			return false
			
		end
		file_snap_shot:close()
	end
end

function commonFunctionsForCqr22736:checkExistedItemInSnapshot(item)
	Test["CheckExistedItemInSnapshot_"..tostring(item)] = function (self)
		local SDLsnapshot = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json"
		
		local file_snap_shot = io.open(SDLsnapshot, "r")
		
		local json_snap_shot = file_snap_shot:read("*all") -- may be abbreviated to "*a";
		entities = json_snap_shot:match(item)
		commonFunctions:printTable(entities)
		if entities == nil then
			print ( " \27[31m disallowed_by_ccs_entities_on is not found in SnapShot \27[0m " )
			return false
			
			
		else
			print ( " \27[31m disallowed_by_ccs_entities_on is found in SnapShot \27[0m " )
			return true
			
		end
		file_snap_shot:close()
	end
end

---------------------------------------------------------------------------------------------
-------------------------------------------Common preconditions------------------------------
---------------------------------------------------------------------------------------------
-- common_steps:PreconditionSteps("Precondition", 0)
common_functions2:BackupFile("sdl_preloaded_pt.json")

return commonFunctionsForCqr22736