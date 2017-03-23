require('user_modules/all_common_modules')
local file_size_1
local file_size_2
local mobile_session_name = "mobileSession"
local app_params = config.application1.registerAppInterfaceParams

---------------------------------------Common Functions-----------------------------------------------
local function GetFileSize(file)
  local f = assert(io.open(file,"r"))
  local current = f:seek()
  local size = f:seek("end")
  f:seek("set", current)
  f:close()
  return size
end

---------------------------------------Preconditions--------------------------------------------------
local app_storage_folder = common_functions:GetValueFromIniFile("AppStorageFolder")
local app_folder_path = config.pathToSDL .. app_storage_folder .. "/" .. 
    app_params.appID .. "_" .. config.deviceMAC
local app_icons_folder = common_functions:GetValueFromIniFile("AppIconsFolder")
local app_icons_folder_path = config.pathToSDL .. app_icons_folder

------------------------------------------Tests-------------------------------------------------------
-- Description:
-- 1. Delete AppIconsFolder (if exists)
-- 2. Start SDL => empty AppIconsFolder is created
-- 3. Register app
-- Expected Result: 
--   SDL->MOBI:RegisterAppInterface(iconResumed = false)
--   SDL->HMI:OnAppRegistered(icon = nil)
--   SDL->HMI:UpdateAppList(icon = nil)
-- 4. PutFile(icon.png)
-- 5. SetAppIcon(icon.png)
-- 6. HMI->SDL:SetAppIcon(success = true, resultCode = "SUCCESS")
-- Expected Result: Icon is copied into AppIconsFolder.
-- 7. Get file size of icon
-- 8. Stop SDL
-- 9. Start SDL => AppIconsFolder contains app's icon
-- 10. Register app
-- Expected Result:
--   SDL->MOBI:RegisterAppInterface(iconResumed = true)
--   SDL->HMI:OnAppRegistered(icon = path to icon in AppIconsFolder)
--   SDL->HMI:UpdateAppList(icon = path to icon in AppIconsFolder)
-- 11. PutFile(action.bmp)
-- 12. SetAppIcon(action.bmp)
-- 13. HMI->SDL:SetAppIcon(success = false, resultCode = "DISALLOWED")
-- 14. Get file size of icon
-- Expected Result: File size is NOT different with step #7
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

common_steps:PreconditionSteps("Preconditions_1", 5)

function Test:Register_App_First_Time()
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

function Test:SetAppIcon_icon_png_SUCCESS()
  local cid = self.mobileSession:SendRPC("SetAppIcon",{
      syncFileName = "icon.png"})
  EXPECT_HMICALL("UI.SetAppIcon",{
    syncFileName = {
      imageType = "DYNAMIC", 
      value = app_folder_path .. "/icon.png"}})
	:Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  self.mobileSession:ExpectResponse(cid, {success = true, resultCode = "SUCCESS"})
end

function Test:Get_Icon_File_Size_To_Check_File_Not_Replaced_In_Next_Steps()
  file_size_1 = GetFileSize(app_icons_folder_path ..
      "/" .. config.application1.registerAppInterfaceParams.appID)
  common_functions:UserPrint(32, "Icon file size: " .. tostring(file_size_1))
end

function Test:Stop_SDL()
  StopSDL()
end

common_steps:PreconditionSteps("Preconditions_2", 5)

function Test:Register_App_Second_Time()
  local cid_rai = self.mobileSession:SendRPC("RegisterAppInterface", app_params)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = {
      appName = app_params.appName, icon = app_icons_folder_path .. "/" .. app_params.appID}})
  self.mobileSession:ExpectResponse(cid_rai, 
      {success = true, resultCode = "SUCCESS", iconResumed = true})
  self.mobileSession:ExpectNotification("OnHMIStatus", 
      {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  EXPECT_HMICALL("BasicCommunication.UpdateAppList", {applications = {
      {appName = app_params.appName, icon = app_icons_folder_path .. "/" .. app_params.appID}}})
end

function Test:PutFile_action_bmp()
  local cid = self.mobileSession:SendRPC("PutFile",{
      syncFileName = "action.bmp",
      fileType = "GRAPHIC_PNG",
      persistentFile = false,
      systemFile = false},
      "files/action.bmp")
  self.mobileSession:ExpectResponse(cid, {success = true, resultCode = "SUCCESS"})      
end

function Test:SetAppIcon_action_bmp_DISALLOWED()
  local cid = self.mobileSession:SendRPC("SetAppIcon",{
      syncFileName = "action.bmp"})
  EXPECT_HMICALL("UI.SetAppIcon",{
    syncFileName = {
      imageType = "DYNAMIC", 
      value = app_folder_path .. "/action.bmp"}})
	:Do(function(_,data)
    self.hmiConnection:SendError(data.id, data.method, "DISALLOWED", "Error message.")
  end)
  self.mobileSession:ExpectResponse(cid, 
      {success = false, resultCode = "DISALLOWED", info = "Error message."})
end

function Test:Check_Icon_Not_Replaced_By_Compare_File_Size()
  file_size_2 = GetFileSize(app_icons_folder_path ..
      "/" .. config.application1.registerAppInterfaceParams.appID)
  common_functions:UserPrint(32, "Icon file size: " .. tostring(file_size_2))      
  if file_size_2 ~= file_size_1 then
    self:FailTestCase("Application's icon in AppIconsFolder is changed.")
  end
end

------------------------------------Postcondition-----------------------------------------------------
common_steps:AddNewTestCasesGroup("Postconditions")
common_steps:StopSDL("Postcondition_StopSDL")
