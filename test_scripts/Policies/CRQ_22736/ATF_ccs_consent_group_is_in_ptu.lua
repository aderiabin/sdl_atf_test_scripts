require('user_modules/all_common_modules')
-------------------------------------- Variables --------------------------------------------
--n/a

------------------------------------ Common functions ---------------------------------------
local function AddNewParamIntoJSonFile(json_file, parent_item, testing_value)
	Test["AddNewParamIntoJSonFile"] = function (self)
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
end

-------------------------------------- Preconditions ----------------------------------------
common_functions:BackupFile("sdl_preloaded_pt.json")

------------------------------------------- BODY ---------------------------------------------
-- Precondition: 
-- 1. ccs_consent_groups is not existed in PreloadedPT
-- 2. ccs_consent_groups is existed in PTU
-- Verification criteria:
-- 1. SDL starts successfully 
-- 2. SDL considers PTU as invalid
-- 3. PTU failed
-- 3. Does not save ccs_consent_groups from PTU to LPT

local test_case_id = "TC_1"
local test_case_name = test_case_id .. ": ccs_consent_groups is existed in PTU file"
common_steps:AddNewTestCasesGroup(test_case_name)	

Test[tostring(test_case_name) .. "_Precondition_StopSDL"] = function(self)
	StopSDL()
end	

Test[test_case_name .. "_Precondition_RestoreDefaultPreloadedPt"] = function (self)
	common_functions:DeletePolicyTable()
end
-- Precondition

Test[test_case_name .. "_Precondition_ChangedPreloadedPt"] = function (self)
	os.execute(" cp " .. config.pathToSDL .. "sdl_preloaded_pt.json".. " " .. config.pathToSDL .. "update_sdl_preloaded_pt.json")
end 

local parent_item = {"policy_table", "module_config"}
local added_item_into_ptu = 
[[
{
	"device_data": {
		"HUU40DAS7F970UEI17A73JH32L41K32JH4L1K234H3K4": {
			"user_consent_records": {
				"0000001": {
					"consent_groups": {
						"Location": true
					},
					"ccs_consent_groups": {
						"Location": false
					},
					"input": "GUI",
					"time_stamp": "2015-10-09T18:07:21Z"
				}
			}
		}
	}
}
]]
-- Add valid entityType and entityID into PTU 
AddNewParamIntoJSonFile(config.pathToSDL .. "update_sdl_preloaded_pt.json", parent_item, added_item_into_ptu)

-- Add valid entityType and entityID into PreloadedPT
local added_item_into_preloadedpt = 
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
AddNewParamIntoJSonFile(config.pathToSDL .. "sdl_preloaded_pt.json", parent_item, added_item_into_preloadedpt)

common_steps:IgnitionOn("StartSDL")

common_steps:AddMobileSession("AddMobileSession")

common_steps:RegisterApplication("RegisterApp")

common_steps:ActivateApplication("ActivateApp", config.application1.registerAppInterfaceParams.appName)

-- Verify PTU failed when ccs_consent_param existed in PTU file
local function VerifyPTUFailedWithExistedCcsConsentGroup()
	mobile_session_name = mobile_session_name or "mobileSession"
	Test["VerifyPTUFailedWithExistedCcsConsentGroup"] = function (self)
		
		local CorIdSystemRequest = self[mobile_session_name]:SendRPC("SystemRequest",
		{
			fileName = "PolicyTableUpdate",
			requestType = "PROPRIETARY"
		},
		config.pathToSDL .. "update_sdl_preloaded_pt.json")
		
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
VerifyPTUFailedWithExistedCcsConsentGroup()
-- Verify ccs_consent_group is not saved in LPT after PTU failed
Test["VerifyCcsConsentGroupNotSavedInLPTWhenPTUFailed"] = function (self)
	local sql_query = "select * from ccs_consent_group"
	-- Look for policy.sqlite file
	print(sql_query)
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
		if(result == nil) then
			print ( " \27[31m ccs_consent_group is not updated in LPT \27[0m " )
			return true
			
		else
			self:FailTestCase("ccs_consent_group is updated in LPT")
			return false
		end
	end
end
-------------------------------------- Postconditions ----------------------------------------
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")