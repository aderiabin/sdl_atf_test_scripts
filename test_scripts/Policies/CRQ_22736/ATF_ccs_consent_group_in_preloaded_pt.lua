require('user_modules/all_common_modules')
-------------------------------------- Variables ------------------------------
-- n/a

------------------------------------ Common functions -------------------------
-- n/a

-------------------------------------- Preconditions --------------------------
common_functions:BackupFile("sdl_preloaded_pt.json")

------------------------------------------- BODY ------------------------------
Test["Precondition_RemoveExistedLPT"] = function (self)
  common_functions:DeletePolicyTable()
end

-- Change temp_sdl_preloaded_pt_with_ccs_consent_group.json to sdl_preloaded_pt.json
-- To make sure it does not contain Ccs_consent_group param
Test["Precondition_ChangedPreloadedPt"] = function (self)
	os.execute(" cp " .. "files/temp_sdl_preloaded_pt_with_ccs_consent_group.json".. " " .. config.pathToSDL .. "sdl_preloaded_pt.json")
end 

Test["StartSDL_WithCcsConsentGroupInPreloadedPT"] = function(self)
		StartSDL(config.pathToSDL, config.ExitOnCrash)
end	

-- Verify processID of SDL not existed because SDL shut down.
Test["VerifySDLShutDownWithExistedCcsConsentGroupInPreloadedPT"] = function (self)
  os.execute(" sleep 2 ")
  local GetPIDsmartDeviceLinkCore = assert(io.popen("pidof smartDeviceLinkCore"))
  local Result = GetPIDsmartDeviceLinkCore:read( '*l' )
  if 
    Result and
    Result ~= "" then
    self:FailTestCase(" smartDeviceLinkCore process is not stopped ")
  end 
end

Test["VerifyCcsConsentGroupNotSavedInPreloadedPT"] = function(self)
    sql_query = "select * from ccs_consent_group"
		-- Look for policy.sqlite file
		local policy_file1 = config.pathToSDL .. "storage/policy.sqlite"
		local policy_file2 = config.pathToSDL .. "policy.sqlite"
		local policy_file
		if common_steps:FileExisted(policy_file1) then
			policy_file = policy_file1
		elseif common_steps:FileExisted(policy_file2) then
			policy_file = policy_file2
		else
			 common_functions:PrintError(" \27[32m policy.sqlite file is not exist because SDL failed \27[0m ")
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
				self:FailTestCase("ccs_consent_group is still saved in local policy table although SDL can not start.")
				return false
			end
		end
	end

-------------------------------------- Postconditions -------------------------
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")
