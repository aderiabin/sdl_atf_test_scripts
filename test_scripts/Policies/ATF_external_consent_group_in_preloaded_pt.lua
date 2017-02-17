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

-------------------------------------- Postconditions -------------------------
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")
