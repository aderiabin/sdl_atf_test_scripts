require('user_modules/all_common_modules')
local mobile_session_name1 = "mobileSession1"
local mobile_session_name2 = "mobileSession2"
local app_params1 = config.application1.registerAppInterfaceParams
local app_params2 = config.application2.registerAppInterfaceParams

---------------------------------------Preconditions--------------------------------------------------
local app_storage_folder = common_functions:GetValueFromIniFile("AppStorageFolder")
local app_folder_path2 = config.pathToSDL .. app_storage_folder .. "/" .. 
    app_params2.appID .. "_" .. config.deviceMAC    
local app_icons_folder = common_functions:GetValueFromIniFile("AppIconsFolder")
local app_icons_folder_path = config.pathToSDL .. app_icons_folder

------------------------------------------Tests-------------------------------------------------------
-- Description:
-- 1. Delete AppIconsFolder (if exists)
-- 2. Start SDL => empty AppIconsFolder is created
-- 3. Register App1
-- Expected Result: 
--   SDL->MOBI:RegisterAppInterface(iconResumed = false)
--   SDL->HMI:OnAppRegistered(App1: icon = nil)
--   SDL->HMI:UpdateAppList(App1: icon = nil)
-- 4. Register App2
-- Expected Result: 
--   SDL->MOBI:RegisterAppInterface(iconResumed = false)
--   SDL->HMI:OnAppRegistered(App2: icon = nil)
--   SDL->HMI:UpdateAppList(App2: icon = nil)
-- 5. On App2: PutFile(icon.png)
-- 6. On App2: SetAppIcon(icon.png)
-- 7. HMI->SDL:SetAppIcon(success = true, resultCode = "SUCCESS")
-- Expected Result: App2's icon is copied into AppIconsFolder.
-- 8. Stop SDL
-- 9. Start SDL => AppIconsFolder contains App2's icon
-- 10. Register App1
-- Expected Result: 
--   SDL->MOBI:RegisterAppInterface(iconResumed = false)
--   SDL->HMI:OnAppRegistered(App1: icon = nil)
--   SDL->HMI:UpdateAppList(App1: icon = nil)
-- 11. Register App2
-- Expected Result:
--   SDL->MOBI:RegisterAppInterface(iconResumed = true)
--   SDL->HMI:OnAppRegistered(App2: icon = path to icon in AppIconsFolder)
--   SDL->HMI:UpdateAppList(App2: icon = path to icon in AppIconsFolder)
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

common_steps:PreconditionSteps("Preconditions_First_Time", 4)
common_steps:AddMobileSession("Preconditions_First_Time_AddMobileSession_1",
    mobile_connection_name, mobile_session_name1)

function Test:Register_App_1()
  local cid_rai = self[mobile_session_name1]:SendRPC("RegisterAppInterface", app_params1)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
      {application = {appName = app_params1.appName}})
  :ValidIf(function(_,data)
    if data.params.application.icon then
      common_functions:PrintError(
          "The OnAppRegistered's icon param is not null: " .. data.params.application.icon)
      return false
    else
      return true
    end
  end)
  self[mobile_session_name1]:ExpectResponse(cid_rai, 
      {success = true, resultCode = "SUCCESS", iconResumed = false})
  self[mobile_session_name1]:ExpectNotification("OnHMIStatus", 
      {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  EXPECT_HMICALL("BasicCommunication.UpdateAppList",
      {applications = {{appName = app_params1.appName}}})
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

common_steps:AddMobileSession("Preconditions_First_Time_AddMobileSession_2",
    mobile_connection_name, mobile_session_name2)

function Test:Register_App_2()
  local cid_rai = self[mobile_session_name2]:SendRPC("RegisterAppInterface", app_params2)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
      {application = {appName = app_params2.appName}})
  :ValidIf(function(_,data)
    if data.params.application.icon then
      common_functions:PrintError(
          "The OnAppRegistered's icon param is not null: " .. data.params.application.icon)
      return false
    else
      return true
    end
  end)
  self[mobile_session_name2]:ExpectResponse(cid_rai, 
      {success = true, resultCode = "SUCCESS", iconResumed = false})
  self[mobile_session_name2]:ExpectNotification("OnHMIStatus", 
      {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  EXPECT_HMICALL("BasicCommunication.UpdateAppList", {applications = {
      {appName = app_params1.appName},
      {appName = app_params2.appName}}})
  :ValidIf(function(_,data)
    if data.params.applications[1].icon or data.params.applications[2].icon then
      common_functions:PrintError(
          "The UpdateAppList's icon param of application " .. app_params1.appName .. 
          ": " .. data.params.applications[1].icon .. "\n or application " .. 
          app_params2.appName .. ": " .. data.params.applications[2].icon .. " is not null")         
      return false
    else
      return true
    end
  end)
end

function Test:PutFile_App_2()
  local cid = self[mobile_session_name2]:SendRPC("PutFile",{
      syncFileName = "icon.png",
      fileType = "GRAPHIC_PNG",
      persistentFile = false,
      systemFile = false},
      "files/icon.png")
  self[mobile_session_name2]:ExpectResponse(cid, {success = true, resultCode = "SUCCESS"})      
end

function Test:SetAppIcon_App_2_SUCCESS()
  local cid = self[mobile_session_name2]:SendRPC("SetAppIcon",{
      syncFileName = "icon.png"})
  EXPECT_HMICALL("UI.SetAppIcon",{
    syncFileName = {
      imageType = "DYNAMIC", 
      value = app_folder_path2 .. "/icon.png"}})
	:Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  self[mobile_session_name2]:ExpectResponse(cid, {success = true, resultCode = "SUCCESS"})
end

function Test:Check_App_Icon_Copied_To_AppIconsFolder()
  local result = common_functions:IsFileExist(app_icons_folder_path .. "/" .. app_params2.appID)
  if not result then
    self:FailTestCase("Icon " .. app_icons_folder_path .. 
        "/" .. app_params.appID .. " does NOT exist in AppIconsFolder.")
  end
end

function Test:Stop_SDL()
  StopSDL()
end

common_steps:PreconditionSteps("Preconditions_Second_Time", 4)
common_steps:AddMobileSession("Preconditions_Second_Time_AddMobileSession_1",
    mobile_connection_name, mobile_session_name1)

function Test:Register_App_1()
  local cid_rai = self[mobile_session_name1]:SendRPC("RegisterAppInterface", app_params1)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
      {application = {appName = app_params1.appName}})
  :ValidIf(function(_,data)
    if data.params.application.icon then
      common_functions:PrintError(
          "The OnAppRegistered's icon param is not null: " .. data.params.application.icon)
      return false
    else
      return true
    end
  end)
  self[mobile_session_name1]:ExpectResponse(cid_rai, 
      {success = true, resultCode = "SUCCESS", iconResumed = false})
  self[mobile_session_name1]:ExpectNotification("OnHMIStatus", 
      {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  EXPECT_HMICALL("BasicCommunication.UpdateAppList",
      {applications = {{appName = app_params1.appName}}})
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

common_steps:AddMobileSession("Preconditions_First_Time_AddMobileSession_2",
    mobile_connection_name, mobile_session_name2)

function Test:Register_App_2()
  local cid_rai = self[mobile_session_name2]:SendRPC("RegisterAppInterface", app_params2)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = {
      appName = app_params2.appName, icon = app_icons_folder_path .. "/" .. app_params2.appID}})
  self[mobile_session_name2]:ExpectResponse(cid_rai, 
      {success = true, resultCode = "SUCCESS", iconResumed = true})
  self[mobile_session_name2]:ExpectNotification("OnHMIStatus", 
      {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  EXPECT_HMICALL("BasicCommunication.UpdateAppList", {applications = {
      {appName = app_params1.appName},
      {appName = app_params2.appName, icon = app_icons_folder_path .. "/" .. app_params2.appID}}})
  :ValidIf(function(_,data)
    if data.params.applications[1].icon then
      common_functions:PrintError(
          "The UpdateAppList's icon param of application " .. app_params1.appName 
          .. " is not null: " .. data.params.applications[1].icon)
      return false
    else
      return true
    end
  end)
end

------------------------------------Postcondition-----------------------------------------------------
common_steps:AddNewTestCasesGroup("Postconditions")
common_steps:StopSDL("Postcondition_StopSDL")
