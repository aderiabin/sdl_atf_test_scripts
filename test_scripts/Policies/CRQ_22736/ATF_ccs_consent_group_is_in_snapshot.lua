require('user_modules/all_common_modules')

-------------------------------------- Variables --------------------------------------------
-- n/a

------------------------------------ Common functions ---------------------------------------
-- n/a
-------------------------------------- Preconditions ----------------------------------------
common_steps:BackupFile("Precondition_Backup_PreloadedPT", "sdl_preloaded_pt.json")

------------------------------------------- BODY ---------------------------------------------
os.execute( "rm -f /tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json" )
Test["Precondition_RestoreDefaultPreloadedPt"] = function (self)
	common_functions:DeletePolicyTable()
end

-- Change temp_sdl_preloaded_pt_without_ccs_consent_group.json to sdl_preloaded_pt.json
Test["Precondition_ChangedPreloadedPt"] = function (self)
	os.execute(" cp " .. "files/temp_snapshot_ccs_consent_group.json".. " " .. config.pathToSDL .. "sdl_preloaded_pt.json")
end 

common_steps:IgnitionOn("StartSDL")
Test["Precondition_HMI_sends_OnAppPermissionConsent"] = function(self)
	-- hmi side: sending SDL.OnAppPermissionConsent for applications
	self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
		source = "GUI",
		ccsStatus = {{entityType = 0, entityID = 128, status = "ON"}}
	})
	common_functions:DelayedExp(20000) 
end
common_steps:AddMobileSession("AddMobileSession")

common_steps:RegisterApplication("RegisterApp")
common_steps:ActivateApplication("ActivateApp", config.application1.registerAppInterfaceParams.appName)
common_steps:Sleep("WaitingSDLCreateSnapshot", 2)
-- Verify SDL triggers to create ccs_consent_group in Snapshot
function Test:VerifyDisallowedByCcsEntitiesOnInSnapShot()
	local ivsu_cache_folder = common_functions:GetValueFromIniFile("SystemFilesPath")
	local file_name = ivsu_cache_folder.."/".."sdl_snapshot.json"
	local new_param = "ccs_consent_group"
	if common_steps:FileExisted(file_name) then
		file_name = file_name
	else
		common_functions:PrintError(" \27[31m Snapshot file is not existed. \27[0m ")
	end
	if(file_name) then
		local file_json = assert(io.open(file_name, "r"))
		local json_snap_shot = file_json:read("*all")
		-- Check new param existed.
		item = json_snap_shot:match(new_param)
		
		if item == nil then
			self:FailTestCase("ccs_consent_group is not found in SnapShot although is existed in PreloadedPT file")
			return false
		else
			print (" \27[32m ccs_consent_group is found in SnapShot \27[0m ")
			return true
		end
		file_json:close()
	end
end

------------------------------------ Postconditions ----------------------------------------
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")
