require('user_modules/all_common_modules')
-------------------------------------- Variables --------------------------------------------
-- n/a

------------------------------------ Common functions ---------------------------------------
-- n/a

-------------------------------------- Preconditions ----------------------------------------
common_functions:BackupFile("sdl_preloaded_pt.json")

------------------------------------------- BODY ---------------------------------------------
-- Precondition: 
-- 1. disallowed_by_ccs_entities_on is omitted in PreloadedPT

-- Verification criteria: 
-- 1. SDL considers PreloadedPT as valid
-- 2. Start successfully
-- 3. Does not saved disallowed_by_ccs_entities_on in LPT

local test_case_name = "disallowed_by_ccs_entities_on is omitted in PreloadedPT"

Test["Precondition_StopSDL_"..test_case_name] = function(self)
	StopSDL()
end	

Test["Precondition_RestoreDefaultPreloadedPt_"..test_case_name] = function (self)
	common_functions:DeletePolicyTable()
end

-- Remove sdl_preloaded_pt.json from current build
Test["Precondition_RemoveDefaultPreloadedPt_"..test_case_name] = function (self)
	os.execute(" rm " .. config.pathToSDL .. "sdl_preloaded_pt.json")
end 
-- -- Change temp_sdl_preloaded_pt_without_entity_on.json to sdl_preloaded_pt.json
Test["Precondition_Prepare_PreloadedPT_Without_DisallowedCcsEntityOn_"..test_case_name ] = function (self)
	os.execute(" cp " .. "files/temp_sdl_preloaded_pt_without_entity_on.json".. " " .. config.pathToSDL .. "sdl_preloaded_pt.json")
end 

common_steps:IgnitionOn("StartSDL")

common_steps:AddMobileSession("AddMobileSession")

common_steps:RegisterApplication("RegisterApp")

common_steps:ActivateApplication("ActivateApp", config.application1.registerAppInterfaceParams.appName)

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

-- Verify valid entityType and entityID are inserted into entities table in LPT
Test["VerifyDisallowedCcsEntityOnNotSavedInLPT"..test_case_name] = function(self)
	-- Look for policy.sqlite file
	local sql_query = "select entity_type, entity_id from entities, functional_group where entities.group_id = functional_group.id"
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
			print ( " \27[31m disallowed_by_ccs_entities_on is not found in LPT \27[0m " )
			return true
		else
			self:FailTestCase("entities value in DB is not saved in local policy table although valid param existed in PreloadedPT file")
			return false
		end
	end
end

-- Verify disallowed_by_ccs_entities_on is not included in Snapshot
function Test:VerifyDisallowedByCcsEntityIsNotInSnapShot()
	local file_name = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json"
	local new_param = "disallowed_by_ccs_entities_on"
	local file_json = io.open(file_name, "r")
	local json_snap_shot = file_json:read("*all") -- may be abbreviated to "*a";
	if type(new_item) == "table" then
		new_item = json.encode(new_item)
	end
	-- Add new items as child items of parent item.
	item = json_snap_shot:match(new_param)
	
	if item == nil then
				print ( " \27[31m disallowed_by_ccs_entities_on is not found in SnapShot \27[0m " )
		return true
	else
    print ( " \27[31m disallowed_by_ccs_entities_on is found in SnapShot \27[0m " )
		return false
	end
	file_json:close()
end
-------------------------------------- Postconditions ----------------------------------------
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")