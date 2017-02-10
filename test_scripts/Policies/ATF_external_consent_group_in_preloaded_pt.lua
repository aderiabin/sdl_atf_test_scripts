----------------------------General Settings for Configuration-----------------
require('user_modules/all_common_modules')

-------------------------------------- Preconditions --------------------------
common_functions:BackupFile("sdl_preloaded_pt.json")

------------------------------------------- BODY ------------------------------
Test["Precondition_RemoveExistedLPT"] = function(self)
  common_functions:DeletePolicyTable()
end

-- Change temp_sdl_preloaded_pt_with_external_consent_status_groups.json to sdl_preloaded_pt.json
-- To make sure it does not contain external_consent_status_groups param
Test["Precondition_ChangedPreloadedPt"] = function(self)
  os.execute(" cp " .. "files/temp_sdl_preloaded_pt_with_external_consent_status_groups.json".. " " .. config.pathToSDL .. "sdl_preloaded_pt.json")
end

Test["StartSDL_WithExternalConsentStatusGroupsInPreloadedPT"] = function(self)
  StartSDL(config.pathToSDL, config.ExitOnCrash)
end

-- Verify processID of SDL not existed because SDL shut down.
Test["SDLShutDownWithExistedExternalConsentStatusGroupsInPreloadedPT"] = function(self)
  os.execute(" sleep 1 ")
  -- Remove sdl.pid file on ATF folder in case SDL is stopped not by script.
  os.execute("rm sdl.pid")
  local status = sdl:CheckStatusSDL()
  if (status == 1) then
    self:FailTestCase(" smartDeviceLinkCore process is not stopped ")
    return false
  end
  common_functions:PrintError(" \27[32m SDL has already stopped.")
  return true
end

Test["VerifyExternalConsentStatusGroupsNotSavedInPreloadedPT"] = function(self)
  sql_query = "select * from external_consent_status_groups"
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
    if(result==nil or result == "") then
      common_functions:PrintError(" \27[32m external_consent_status_groups is not saved in LPT \27[0m ")
      return true
    else
      self:FailTestCase("external_consent_status_groups is still saved in local policy table although SDL can not start.")
      return false
    end
  end
end

-------------------------------------- Postconditions -------------------------
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")
