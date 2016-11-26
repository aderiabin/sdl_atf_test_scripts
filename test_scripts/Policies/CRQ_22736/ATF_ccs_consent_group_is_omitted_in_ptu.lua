require('user_modules/all_common_modules')
-------------------------------------- Variables --------------------------------------------
-- n/a

------------------------------------ Common functions ---------------------------------------
-- n/a
-------------------------------------- Preconditions ----------------------------------------
common_functions:BackupFile("sdl_preloaded_pt.json")

------------------------------------------- BODY ---------------------------------------------
-- Precondition: 
-- 1.SDL starts without ccs_consent_group in PreloadedPT 
-- 2.ccs_consent_group is omitted in PTU 
-- Verification criteria: 
-- 1. SDL considers this PTU as valid
-- 2. Does not saved ccs_consent_group in LocalPT

local test_case_id = "TC_"
local test_case_name = test_case_id .. ": PTUSuccessWithDisallowedCcsEntityOnExistedLPT"
common_steps:AddNewTestCasesGroup(test_case_name) 

Test[test_case_name .. "_Precondition_StopSDL"] = function(self)
	StopSDL()
end

Test[test_case_name .. "_Precondition_RestoreDefaultPreloadedPt"] = function (self)
	common_functions:DeletePolicyTable()
end 

-- Remove sdl_preloaded_pt.json from current build
Test[test_case_name .. "_Precondition_Remove_DefaultPreloadedPt"] = function (self)
	os.execute(" rm " .. config.pathToSDL .. "sdl_preloaded_pt.json")
end 
-- Change temp_sdl_preloaded_pt_without_ccs_consent_group.json to sdl_preloaded_pt.json
-- To make sure it does not contain Ccs_consent_group param
Test[test_case_name .. "_Precondition_ChangedPreloadedPt"] = function (self)
	os.execute(" cp " .. "files/temp_sdl_preloaded_pt_without_ccs_consent_group.json".. " " .. config.pathToSDL .. "sdl_preloaded_pt.json")
end 

common_steps:IgnitionOn(test_case_name)

common_steps:AddMobileSession("AddMobileSession")

common_steps:RegisterApplication("RegisterApp")

common_steps:ActivateApplication("ActivateApp", config.application1.registerAppInterfaceParams.appName)


Test[test_case_name .. "_PTUSuccessWithoutCcsConsentGroup"] = function (self)
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
			"files/ptu_withConsentGroup.json")
			
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

-- Verify ccs_consent_group is not saved in LPT after PTU success
function Test:VerifyCcsConsentGroupNotSaveInLPT()
	local sql_query = "select * from ccs_consent_group"
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

-------------------------------------- Postconditions ----------------------------------------
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")