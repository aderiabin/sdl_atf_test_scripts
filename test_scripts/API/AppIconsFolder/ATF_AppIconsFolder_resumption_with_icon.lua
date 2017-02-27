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
-- 2. Start SDL => empty AppIconsFolder is created
-- 3. Register app
-- Expected Result: 
--   SDL->MOBI:RegisterAppInterface(iconResumed = false)
--   SDL->HMI:OnAppRegistered(icon = nil)
--   SDL->HMI:UpdateAppList(icon = nil)
-- 4. Activate app
-- 5. PutFile(icon.png)
-- 6. SetAppIcon(icon.png)
-- Expected Result: Icon is copied into AppIconsFolder.
-- 7. Ignition Off
-- 8. Ignition On
-- 9. Resume app 
-- Expected Result:
--   SDL->MOBI:RegisterAppInterface(iconResumed = true)
--   SDL->HMI:OnAppRegistered(icon = path to icon in AppIconsFolder)
--   SDL->HMI:UpdateAppList(icon = path to icon in AppIconsFolder)
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

function Test:SetAppIcon_SUCCESS()
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

function Test:Check_App_Icon_Copied_To_AppIconsFolder()
  local result = common_functions:IsFileExist(app_icons_folder_path .. "/" .. app_params.appID)
  if not result then
    self:FailTestCase("Icon " .. app_icons_folder_path .. 
        "/" .. app_params.appID .. " does NOT exist in AppIconsFolder.")
  end
end

function Test:Iginition_Off()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
    { reason = "IGNITION_OFF" })
  EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  :Do(function()
    StopSDL()
  end)
end

common_steps:PreconditionSteps("Preconditions", 5)

function Test:Resume_App()
  local cid_rai = self.mobileSession:SendRPC("RegisterAppInterface", app_params)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = {
      appName = app_params.appName, icon = app_icons_folder_path .. "/" .. app_params.appID}})
  self.mobileSession:ExpectResponse(cid_rai, 
      {success = true, resultCode = "SUCCESS", iconResumed = true})
	EXPECT_HMICALL("BasicCommunication.ActivateApp")
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})		
	end)      
  self.mobileSession:ExpectNotification("OnHMIStatus", 
      {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
      {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  :Times(2)
  EXPECT_HMICALL("BasicCommunication.UpdateAppList", {applications = {
      {appName = app_params.appName, icon = app_icons_folder_path .. "/" .. app_params.appID}}})
end

------------------------------------Postcondition-----------------------------------------------------
common_steps:AddNewTestCasesGroup("Postconditions")
common_steps:StopSDL("Postcondition_StopSDL")
