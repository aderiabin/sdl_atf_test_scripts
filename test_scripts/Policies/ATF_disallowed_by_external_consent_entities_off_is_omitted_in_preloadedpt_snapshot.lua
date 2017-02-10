------------------------------------General Settings for Configuration-----------------------
require('user_modules/all_common_modules')

-------------------------------------- Preconditions ----------------------------------------
os.execute( "rm -f /tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json" )
common_functions:BackupFile("sdl_preloaded_pt.json")

------------------------------------------- BODY ---------------------------------------------
-- Precondition:
-- 1. disallowed_by_external_consent_entities_off is omitted in PreloadedPT

-- Verification criteria:
-- 1. SDL considers PreloadedPT as valid
-- 2. Start successfully
-- 3. Does not saved disallowed_by_external_consent_entities_off in LPT

local test_case_name = "disallowed_by_external_consent_entities_off_is_omitted_in_PreloadedPT"

Test["Precondition_RemoveExistedLPT_"..test_case_name] = function(self)
  common_functions:DeletePolicyTable()
end

-- Change temp_sdl_preloaded_pt_without_entity_on.json to sdl_preloaded_pt.json
Test["Precondition_Prepare_PreloadedPT_Without_DisallowedExternalConsentEntityOn"] = function(self)
  os.execute(" cp " .. "files/temp_sdl_preloaded_pt_without_entity_on.json".. " " .. config.pathToSDL .. "sdl_preloaded_pt.json")
end

common_steps:IgnitionOn("StartSDL")

-- Verify valid entityType and entityID are inserted into entities table in LPT
Test["VerifyDisallowedExternalConsentEntityOnNotSavedInLPT"] = function(self)
  -- Look for policy.sqlite file
  local sql_query = "select entity_type, entity_id from entities, functional_group where entities.group_id = functional_group.id"
  local policy_file1 = config.pathToSDL .. "storage/policy.sqlite"
  local policy_file2 = config.pathToSDL .. "policy.sqlite"
  local policy_file
  if common_functions:IsFileExist(policy_file1) then
    policy_file = policy_file1
  elseif common_functions:IsFileExist(policy_file2) then
    policy_file = policy_file2
  else
    common_functions:PrintError(" \27[32m policy.sqlite file is not exist \27[0m ")
  end
  if policy_file then
    local ful_sql_query = "sqlite3 " .. policy_file .. " \"" .. sql_query .. "\""
    local handler = io.popen(ful_sql_query, 'r')
    os.execute("sleep 1")
    local result = handler:read( '*l' )
    handler:close()
    if(result == nil or result == "") then
      print ( " \27[32m disallowed_by_external_consent_entities_off is not found in LPT \27[0m " )
      return true
    else
      self:FailTestCase("entities value in DB is not saved in local policy table although valid param existed in PreloadedPT file")
      return false
    end
  end
end

common_steps:AddMobileSession("AddMobileSession")
common_steps:RegisterApplication("RegisterApp")
common_steps:ActivateApplication("ActivateApp", config.application1.registerAppInterfaceParams.appName)

common_steps:Sleep("WaitingSDLCreateSnapshot", 2)

-- Verify disallowed_by_external_consent_entities_off is not included in Snapshot
function Test:VerifyDisallowedByExternalConsentEntityIsNotInSnapShot()
  local ivsu_cache_folder = common_functions:GetValueFromIniFile("SystemFilesPath")
  local file_name = ivsu_cache_folder.."/".."sdl_snapshot.json"
  local new_param = "disallowed_by_external_consent_entities_off"
  local file_json = assert(io.open(file_name, "r"))
  local json_snap_shot = file_json:read("*all")
  -- Add new items as child items of parent item.
  item = json_snap_shot:match(new_param)

  if not item then
    print ( " \27[32m disallowed_by_external_consent_entities_off is not found in SnapShot \27[0m " )
    return true
  else
    print ( " \27[31m disallowed_by_external_consent_entities_off is found in SnapShot \27[0m " )
    return false
  end
  file_json:close()
end

-------------------------------------- Postconditions ----------------------------------------
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")
