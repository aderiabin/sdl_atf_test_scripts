require('user_modules/all_common_modules')
-------------------------------------- Variables --------------------------------------------
-- n/a 

------------------------------------ Common functions ---------------------------------------
local function UpdatePolicy(PTName, test_case_name)
	Test[test_case_name .. "_PTUSuccessWithoutEntitiesOn"] = function (self)
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
				--mobile side: sending SystemRequest request 
				local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
				{
					fileName = "PolicyTableUpdate",
					requestType = "PROPRIETARY"
				},
				PTName)
				
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
					--hmi side: sending SDL.GetUserFriendlyMessage request to SDL
					local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})
					
					--hmi side: expect SDL.GetUserFriendlyMessage response
					EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
				end)
				
			end)
		end)		
	end
end

-- Verify new parameter is in LPT after PTU success
local function VerifyEntityOnInLPTAfterPTUSuccess(test_case_name, sql_query)
	-- Look for policy.sqlite file
	local policy_file1 = config.pathToSDL .. "storage/policy.sqlite"
	local policy_file2 = config.pathToSDL .. "policy.sqlite"
	local policy_file
	if common_steps:FileExisted(policy_file1) then
		policy_file = policy_file1
	elseif common_steps:FileExisted(policy_file2) then
		policy_file = policy_file2
	else
		common_functions:PrintError("policy.sqlite file is not exist")
	end
	if policy_file then
		local ful_sql_query = "sqlite3 " .. policy_file .. " \"" .. sql_query .. "\""
		local handler = io.popen(ful_sql_query, 'r')
		os.execute("sleep 1")
		local result = handler:read( '*l' )
		handler:close()
		if(result==nil) then
			return true
		else
			self:FailTestCase("Entities on parameter is updated in LPT")
			return false
		end
	end
end


-------------------------------------- Preconditions ----------------------------------------
common_functions:BackupFile("sdl_preloaded_pt.json")

------------------------------------------- BODY ---------------------------------------------
------------------------------------------- TC_01 ---------------------------------------------
-- Precondition: 
-- 1.SDL starts without disallowed_by_ccs_entities_on in PreloadedPT 
-- 2.disallowed_by_ccs_entities_on is omitted in PTU 
-- Verification criteria: 
-- 1. SDL considers this PTU as valid
-- 2. Does not saved disallowed_by_ccs_entities_on in LocalPT
local test_case_id = "TC_1"
local test_case_name = test_case_id .. ": PTUSuccessWithoutDisallowedCcsEntityOnLPT"
common_steps:AddNewTestCasesGroup(test_case_name)

common_steps:IgnitionOn(test_case_name)

common_steps:AddMobileSession("AddMobileSession")

common_steps:RegisterApplication("RegisterApp")

common_steps:ActivateApplication("ActivateApp", config.application1.registerAppInterfaceParams.appName)

UpdatePolicy("files/ptu_without_dissallowed_ccs_entity_on.json", test_case_name)

local sql_query_not_saved_in_lpt = "select entity_type, entity_id from entities, functional_group where entities.group_id = functional_group.id"

Test["VerifyEntityOnInLPTAfterPTUSuccess"] = function(self)
	VerifyEntityOnInLPTAfterPTUSuccess("VerifyEntityOnNotUpdatedInLPT", sql_query_not_saved_in_lpt)
end

------------------------------------------- TC_02 ------------------------------
-- Precondition: 
-- 1.SDL starts without disallowed_by_ccs_entities_on in PreloadedPT 
-- 2.disallowed_by_ccs_entities_on is omitted in PTU 
-- Verification criteria: 
-- 1. SDL considers this PTU as valid
-- 2. Does not merge disallowed_by_ccs_entities_on from PTU to LocalPT

-- common_steps:AddNewTestCasesGroup("------------------Begin TC_2-----------------")
local test_case_id = "TC_2"
local test_case_name = test_case_id .. ": PTUSuccessWithDisallowedCcsEntityOnExistedLPT"
common_steps:AddNewTestCasesGroup(test_case_name) 

Test[test_case_name .. "_Precondition_StopSDL"] = function(self)
	
	StopSDL()
end

Test[test_case_name .. "_Precondition_RestoreDefaultPreloadedPt"] = function (self)
	common_functions:DeletePolicyTable()
end 

local parent_item = {"policy_table", "functional_groupings", "Location-1"}
local testing_value = {
	disallowed_by_ccs_entities_on = {
		{
			entityType = 150,
			entityID = 70
		}
	}
}
function Test:AddItemsIntoJsonFile()
	local json_file = config.pathToSDL .. "sdl_preloaded_pt.json"
	local match_result = "null"
	local temp_replace_value = "\"Thi123456789\""
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
	if type(testing_value) == "string" then
		testing_value = json.decode(testing_value)
	end
	
	for k, v in pairs(testing_value) do
		parent[k] = v
	end
	
	data = json.encode(data)	
	data_revert = string.gsub(data, temp_replace_value, match_result)
	file = io.open(json_file, "w")
	file:write(data_revert)
	file:close()	
end

common_steps:IgnitionOn(test_case_name)

common_steps:AddMobileSession("AddMobileSession")

common_steps:RegisterApplication("RegisterApp")

common_steps:ActivateApplication("ActivateApp", config.application1.registerAppInterfaceParams.appName)

UpdatePolicy("files/ptu_without_dissallowed_ccs_entity_on.json", test_case_name)

local group_name = "Location-1"
local sql_query = "select entity_type, entity_id from entities, functional_group where entities.group_id = functional_group.id and functional_group.name !="..group_name

Test["VerifyEntityOnInLPTAfterPTUSuccess"] = function(self)
	VerifyEntityOnInLPTAfterPTUSuccess("VerifyEntityOnNotUpdatedInLPT", sql_query)
end

-------------------------------------- Postconditions ----------------------------------------
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")