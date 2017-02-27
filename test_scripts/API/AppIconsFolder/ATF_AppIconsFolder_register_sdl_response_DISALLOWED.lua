require('user_modules/all_common_modules')
local app_params = config.application1.registerAppInterfaceParams

---------------------------------------Preconditions--------------------------------------------------
local app_storage_folder = common_functions:GetValueFromIniFile("AppStorageFolder")
local app_folder_path = config.pathToSDL .. app_storage_folder .. "/" .. 
    app_params.appID .. "_" .. config.deviceMAC
local app_icons_folder = common_functions:GetValueFromIniFile("AppIconsFolder")
local app_icons_folder_path = config.pathToSDL .. app_icons_folder

------------------------------------------Tests-------------------------------------------------------
-- Description:
-- 1. Delete AppIconsFolder (if exists)
-- 2. Update sdl_preloaded_pt.json file to disallow SetAppIcon
-- 3. Start SDL => empty AppIconsFolder is created
-- 4. Register app
-- Expected Result: 
--   SDL->MOBI:RegisterAppInterface(iconResumed = false)
--   SDL->HMI:OnAppRegistered(icon = nil)
--   SDL->HMI:UpdateAppList(icon = nil)
-- 5. PutFile(icon.png)
-- 6. SetAppIcon(icon.png)
-- 7. SDL->MOBI:SetAppIcon(success = false, resultCode = "DISALLOWED")
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

function Test:Update_SetAppIcon_Permission_In_Preloaded_Json()
  local parent_item = {"policy_table", "functional_groupings", "BaseBeforeDataConsent", "rpcs"}
  local added_json_items = {
    SetAppIcon = {
      hmi_levels = { 
        "BACKGROUND",
        "FULL",
        "LIMITED"}}}
  common_functions:AddItemsIntoJsonFile( 
    config.pathToSDL .. "sdl_preloaded_pt.json", parent_item, added_json_items)
end

common_steps:PreconditionSteps("Preconditions", 5)

function Test:Register_App()
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
  self.mobileSession:ExpectResponse(cid_rai, 
      {success = true, resultCode = "SUCCESS", iconResumed = false})
  self.mobileSession:ExpectNotification("OnHMIStatus", 
      {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
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

function Test:PutFile_icon_png()
  local cid = self.mobileSession:SendRPC("PutFile",{
      syncFileName = "icon.png",
      fileType = "GRAPHIC_PNG",
      persistentFile = false,
      systemFile = false},
      "files/icon.png")
  self.mobileSession:ExpectResponse(cid, {success = true, resultCode = "SUCCESS"})      
end

function Test:SetAppIcon_DISALLOWED()
  local cid = self.mobileSession:SendRPC("SetAppIcon",{
      syncFileName = "icon.png"})
  EXPECT_HMICALL("UI.SetAppIcon")
  :Times(0)
  self.mobileSession:ExpectResponse(cid, 
      {success = false, resultCode = "DISALLOWED"})
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
