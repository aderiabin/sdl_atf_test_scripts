require('user_modules/all_common_modules')
local app_params = config.application1.registerAppInterfaceParams
local group_id

---------------------------------------Preconditions--------------------------------------------------
local app_storage_folder = common_functions:GetValueFromIniFile("AppStorageFolder")
local app_folder_path = config.pathToSDL .. app_storage_folder .. "/" .. 
    app_params.appID .. "_" .. config.deviceMAC
local app_icons_folder = common_functions:GetValueFromIniFile("AppIconsFolder")
local app_icons_folder_path = config.pathToSDL .. app_icons_folder

------------------------------------------Tests-------------------------------------------------------
-- Description:
-- 1. Delete AppIconsFolder (if exists)
-- 2. Update sdl_preloaded_pt.json file to set user_consent for SetAppIcon
-- 3. Start SDL => empty AppIconsFolder is created
-- 4. Register app
-- Expected Result: 
--   SDL->MOBI:RegisterAppInterface(iconResumed = false)
--   SDL->HMI:OnAppRegistered(icon = nil)
--   SDL->HMI:UpdateAppList(icon = nil)
-- 6. Activate app
-- 7. PutFile(icon.png)
-- 8. SetAppPermissionConsent to disallow SetAppIcon
-- 9. SetAppIcon(icon.png)
-- 10. SDL->MOBI:SetAppIcon(success = false, resultCode = "USER_DISALLOWED")
-- Expected Result: Icon is NOT copied into AppIconsFolder.
------------------------------------------------------------------------------------------------------
function Test:Delete_AppIconFolder_If_Exist()
  local app_icons_folder_exist = common_functions:IsDirectoryExist(app_icons_folder_path)
  if app_icons_folder_exist then
    local delete_result =  assert(os.execute(" rm -r " .. app_icons_folder_path))
    if not delete_result then
      self:FailTestCase("Cannot delete AppIconsFolder.")
    end
  end
end

common_steps:BackupFile("Back_Up_sdl_preloaded_pt", "sdl_preloaded_pt.json")

function Test:Remove_SetAppIcon_From_Base4_In_Preloaded_Json()
  local parent_item = {"policy_table", "functional_groupings", "Base-4", "rpcs"}
  local removed_items = {"SetAppIcon"}
  common_functions:RemoveItemsFromJsonFile(
    config.pathToSDL .. "sdl_preloaded_pt.json", parent_item, removed_items)
end

function Test:Add_SetAppIcon_Into_Notifications_Group_In_Preloaded_Json()
  local parent_item = {"policy_table", "functional_groupings", "Notifications", "rpcs"}
  local added_json_items = {
    SetAppIcon = {
      hmi_levels = { 
        "BACKGROUND",
        "FULL",
        "LIMITED"}}}
  common_functions:AddItemsIntoJsonFile( 
    config.pathToSDL .. "sdl_preloaded_pt.json", parent_item, added_json_items)
end

function Test:Add_Application_With_Notifications_Group_Into_In_Preloaded_Json()
  local parent_item = {"policy_table", "app_policies"}
  local added_json_items ={}
  added_json_items[app_params.appID] = {
      keep_context = false,
      steal_focus = false,
      priority = "NONE",
      default_hmi = "NONE",
      groups = {"Base-4", "Notifications"}
    }
  common_functions:AddItemsIntoJsonFile( 
    config.pathToSDL .. "sdl_preloaded_pt.json", parent_item, added_json_items)
end

common_steps:PreconditionSteps("Preconditions", 5)

function Test:Register_App()
  common_functions:StoreApplicationData("mobileSession", app_params.appName, app_params, _, self)
  local cid_rai = self.mobileSession:SendRPC("RegisterAppInterface", app_params)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
      {application = {appName = app_params.appName}})
  :ValidIf(function(_,data)
    if data.params.application.icon then
      common_functions:PrintError(
          "The OnAppRegistered's icon param is not null: " .. data.params.application.icon)
      return false
    else
      return true
    end
  end)
  :Do(function(_,data)
      common_functions:StoreHmiAppId(app_params.appName, data.params.application.appID, self)
  end)
  self.mobileSession:ExpectResponse(cid_rai, 
      {success = true, resultCode = "SUCCESS", iconResumed = false})
  self.mobileSession:ExpectNotification("OnHMIStatus", 
      {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  :Do(function(_,data)
    common_functions:StoreHmiStatus(app_params.appName, data.payload, self)
  end)
  EXPECT_HMICALL("BasicCommunication.UpdateAppList",
      {applications = {{appName = app_params.appName}}})
  :ValidIf(function(_,data)
    if data.params.applications[1].icon then
      common_functions:PrintError(
          "The UpdateAppList's icon param is not null: " .. data.params.applications[1].icon)
      return false
    else
      return true
    end
  end)
end

common_steps:ActivateApplication("Activate_App", app_params.appName, "FULL")

function Test:PutFile()
  local cid = self.mobileSession:SendRPC("PutFile",{
      syncFileName = "icon.png",
      fileType = "GRAPHIC_PNG",
      persistentFile = false,
      systemFile = false},
      "files/icon.png")
  self.mobileSession:ExpectResponse(cid, {success = true, resultCode = "SUCCESS"})      
end

function Test:Get_List_Of_Permissions()
  local request_id = self.hmiConnection:SendRequest("SDL.GetListOfPermissions")
  EXPECT_HMIRESPONSE(request_id,{
      result = {
        code = 0,
        method = "SDL.GetListOfPermissions",
        allowedFunctions = {{name = "Notifications"}}
      }
    })
    :Do(function(_,data)
      for i = 1, #data.result.allowedFunctions do
        if(data.result.allowedFunctions[i].name == "Notifications") then
          group_id = data.result.allowedFunctions[i].id
        end
      end
    end)
end

function Test:Set_User_Consent_Disallow_SetAppIcon()
  hmi_app_id = common_functions:GetHmiAppId(app_params.appName, self)
  self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
      appID = hmi_app_id, source = "GUI",
      consentedFunctions = {{name = "Notifications", id = group_id, allowed = false}}
    })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
end

function Test:SetAppIcon_USER_DISALLOWED()
  local cid = self.mobileSession:SendRPC("SetAppIcon",{
      syncFileName = "icon.png"})
  EXPECT_HMICALL("UI.SetAppIcon")
  :Times(0)
  self.mobileSession:ExpectResponse(cid, 
      {success = false, resultCode = "USER_DISALLOWED"})
  common_functions:DelayedExp(5000)
end

function Test:Check_App_Icon_Not_Copied_To_AppIconsFolder()
  local result = common_functions:IsFileExist(app_icons_folder_path .. "/" .. app_params.appID)
  if result then
    self:FailTestCase("Icon " .. app_icons_folder_path .. 
        "/" .. app_params.appID .. " exists in AppIconsFolder.")
  end
end

------------------------------------Postcondition-----------------------------------------------------
common_steps:AddNewTestCasesGroup("Postconditions")
common_steps:RestoreIniFile("Postcondition_Restore_sdl_preloaded_pt", "sdl_preloaded_pt.json")
common_steps:StopSDL("Postcondition_StopSDL")
