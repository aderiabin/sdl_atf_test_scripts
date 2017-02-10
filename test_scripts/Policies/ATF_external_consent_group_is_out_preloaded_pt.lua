------------------------------------General Settings for Configuration-----------------------
require('user_modules/all_common_modules')

-------------------------------------- Preconditions ----------------------------------------
os.execute("rm -f /tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json")
common_functions:BackupFile("sdl_preloaded_pt.json")

------------------------------------------- BODY ---------------------------------------------
-- Precondition:
-- 1. external_consent_status_groups is not existed in PreloadedPT
-- 2. user_consent_records existed in PreloadedPT
-- Verification criteria:
-- 1. SDL considers PreloadedPT as valid
-- 2. Start successfully
-- 3. Triggered to create a SnapshotPolicyTable without external_consent_status_groups
local added_json_items =
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

-- Change temp_sdl_preloaded_pt_without_external_consent_status_groups.json to sdl_preloaded_pt.json
Test["Precondition_ChangedPreloadedPt"] = function(self)
  os.execute(" cp " .. "files/temp_sdl_preloaded_pt_without_external_consent_status_groups.json".. " " .. config.pathToSDL .. "sdl_preloaded_pt.json")
end

common_steps:IgnitionOn("StartSDL")

Test["VerifyExternalConsentStatusGroupsNotSavedInPreloadedPT"] = function(self)
  sql_query = "select * from external_consent_status_groups"
  -- Look for policy.sqlite file
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
    if(result==nil or result == "") then
      common_functions:PrintError(" \27[32m external_consent_status_groups is not saved in LPT \27[0m ")
      return true
    else
      self:FailTestCase("external_consent_status_groups is still saved in local policy table although SDL can not start.")
      return false
    end
  end
end

common_steps:AddMobileSession("AddMobileSession")
common_steps:RegisterApplication("RegisterApp")
common_steps:ActivateApplication("ActivateApp", config.application1.registerAppInterfaceParams.appName)
common_steps:Sleep("WaitingSDLCreateSnapshot", 2)

Test["CheckExternalConsentStatusGroupsNotIncludedInSnapshot"] = function(self)
  local ivsu_cache_folder = common_functions:GetValueFromIniFile("SystemFilesPath")
  local file_name = ivsu_cache_folder.."/".."sdl_snapshot.json"
  if common_functions:IsFileExist(file_name) then
    file_name = file_name
  else
    common_functions:PrintError(" \27[32m Snapshot is not existed. \27[0m ")
  end
  local file_snap_shot = assert(io.open(file_name, "r"))
  local json_snap_shot = file_snap_shot:read("*all")
  entities = json_snap_shot:match("external_consent_status_groups")
  if not entities then
    print ( " \27[32m external_consent_status_groups is not found in SnapShot \27[0m " )
    return true
  else
    self:FailTestCase("external_consent_status_groups is found in SnapShot")
    return false
  end
  file_snap_shot:close()
end

-------------------------------------- Postconditions ----------------------------------------
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")
