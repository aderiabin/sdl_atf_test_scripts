------------------------------------General Settings for Configuration-----------------------
require('user_modules/all_common_modules')

-------------------------------------- Preconditions ----------------------------------------
os.execute( "rm -f /tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json" )
common_steps:BackupFile("Precondition_Backup_PreloadedPT", "sdl_preloaded_pt.json")

------------------------------------------- BODY ---------------------------------------------
-- Precondition: disallowed_by_external_consent_entities_off existed in PreloadedPT
-- Verification criteria:
-- 1. SDL considers PreloadedPT as valid
-- 2. Start successfully
-- 3. Triggered to create a SnapshotPolicyTable contains disallowed_external_consent_entities_on
local test_case_name = "TC_DisallowedByExternalConsentEntitiesOnExistedInSnapshot"
common_steps:AddNewTestCasesGroup(test_case_name)

Test["Precondition_RemoveExistedLPT_"..test_case_name ] = function(self)
  common_functions:DeletePolicyTable()
end

Test["AddNewItemIntoPreloadedPT_"..test_case_name] = function(self)
  local json_file = config.pathToSDL .. "sdl_preloaded_pt.json"
  local parent_item = {"policy_table", "functional_groupings", "Location-1"}
  local testing_value =
  {
    disallowed_by_external_consent_entities_off = {
      {
        entityType = 128,
        entityID = 70
      }
    }
  }
  local match_result = "null"
  local temp_replace_value = "\"Thi123456789\""
  local file = assert(io.open(json_file, "r"))
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
  file = assert(io.open(json_file, "w"))
  file:write(data_revert)
  file:close()
end

common_steps:IgnitionOn("StartSDL")
common_steps:AddMobileSession("AddMobileSession")
common_steps:RegisterApplication("RegisterApp")
common_steps:ActivateApplication("ActivateApp", config.application1.registerAppInterfaceParams.appName)
common_steps:Sleep("WaitingSDLCreateSnapshot", 2)

function Test:VerifyDisallowedByExternalConsentEntitiesOnInSnapShot()
  local ivsu_cache_folder = common_functions:GetValueFromIniFile("SystemFilesPath")
  local file_name = ivsu_cache_folder.."/".."sdl_snapshot.json"
  local new_param = "disallowed_by_external_consent_entities_off"
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
    if not item then
      self:FailTestCase("disallowed_by_external_consent_entities_off is not found in SnapShot although is existed in PreloadedPT file")
      return false
    else
      print (" \27[32m disallowed_by_external_consent_entities_off is found in SnapShot \27[0m ")
      return true
    end
    file_json:close()
  else
  end
end

-------------------------------------- Postconditions ---------------------------------------
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")
