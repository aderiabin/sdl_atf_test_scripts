------------------------------------General Settings for Configuration-----------------------
require('user_modules/all_common_modules')

-------------------------------------- Preconditions ----------------------------------------
os.execute( "rm -f /tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json")
common_functions:BackupFile("sdl_preloaded_pt.json")

------------------------------------------- BODY ---------------------------------------------
-- Precondition:
-- 1. disallowed_by_external_consent_entities_on is omitted in PreloadedPT

-- Verification criteria:
-- 1. SDL considers PreloadedPT as valid
-- 2. Start successfully
-- 3. Does not saved disallowed_by_external_consent_entities_on in LPT

local test_case_name = "disallowed_by_external_consent_entities_on_is_omitted_in PreloadedPT"

Test["Precondition_RemoveExistedLPT"] = function(self)
  common_functions:DeletePolicyTable()
end

-- Change temp_sdl_preloaded_pt_without_entity_on.json to sdl_preloaded_pt.json
Test["Precondition_Prepare_PreloadedPT_Without_DisallowedExternalConsentEntityOn"] = function(self)
  os.execute(" cp " .. "files/temp_sdl_preloaded_pt_without_entity_on.json".. " " .. config.pathToSDL .. "sdl_preloaded_pt.json")
end

common_steps:IgnitionOn("StartSDL")

common_steps:AddMobileSession("AddMobileSession")
common_steps:RegisterApplication("RegisterApp")
common_steps:ActivateApplication("ActivateApp", config.application1.registerAppInterfaceParams.appName)
common_steps:Sleep("WaitingSDLCreateSnapshot", 2)

-- Verify disallowed_by_external_consent_entities_on is not included in Snapshot
function Test:VerifyDisallowedByExternalConsentEntityIsNotInSnapShot()
  local ivsu_cache_folder = common_functions:GetValueFromIniFile("SystemFilesPath")
  local file_name = ivsu_cache_folder.."/".."sdl_snapshot.json"
  local new_param = "disallowed_by_external_consent_entities_on"
  if common_functions:IsFileExist(file_name) then
    file_name = file_name
  else
    common_functions:PrintError("Snapshot file is not exist")
  end
  local file_json = assert(io.open(file_name, "r"))
  local json_snap_shot = file_json:read("*all")
  if type(new_item) == "table" then
    new_item = json.encode(new_item)
  end
  -- Add new items as child items of parent item.
  item = json_snap_shot:match(new_param)

  if not item then
    print ( " \27[32m disallowed_by_external_consent_entities_on is not found in SnapShot \27[0m " )
    return true
  else
    print ( " \27[31m disallowed_by_external_consent_entities_on is found in SnapShot \27[0m " )
    return false
  end
  file_json:close()
end

-------------------------------------- Postconditions ----------------------------------------
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")
