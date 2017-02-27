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
-- 2. Update endingRequestsAmount in .ini file to 3
-- 3. Start SDL => empty AppIconsFolder is created
-- 4. Register app
-- Expected Result: 
--   SDL->MOBI:RegisterAppInterface(iconResumed = false)
--   SDL->HMI:OnAppRegistered(icon = nil)
--   SDL->HMI:UpdateAppList(icon = nil)
-- 5. PutFile(icon.png)
-- 6. Send SetAppIcon(icon.png) 10 times
-- 7. SDL->MOBI:SetAppIcon(success = false, resultCode = "TOO_MANY_PENDING_REQUESTS")
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

common_steps:BackupFile("Back_Up_ini_File", "smartDeviceLink.ini")

common_steps:SetValuesInIniFile("Set_PendingRequestsAmount",
    "%p?PendingRequestsAmount%s?=%s-[%w%d,-]-%s-\n", "PendingRequestsAmount", 3)

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

function Test:PutFile()
  local cid = self.mobileSession:SendRPC("PutFile",{
      syncFileName = "icon.png",
      fileType = "GRAPHIC_PNG",
      persistentFile = false,
      systemFile = false},
      "files/icon.png")
  self.mobileSession:ExpectResponse(cid, {success = true, resultCode = "SUCCESS"})      
end

function Test:SetAppIcon_TOO_MANY_PENDING_REQUESTS()
  local number_of_requests = 10
  local n = 0
  for i = 1, number_of_requests do
    local cid = self.mobileSession:SendRPC("SetAppIcon",{syncFileName = "icon.png"})
  end
  self.mobileSession:ExpectResponse("SetAppIcon")
  :ValidIf(function(exp,data)
    if data.payload.resultCode == "TOO_MANY_PENDING_REQUESTS" then
      n = n+1
      common_functions:UserPrint(32, "SetAppIcon response came with resultCode TOO_MANY_PENDING_REQUESTS")
      return true
    elseif exp.occurences == number_of_requests-1 and n == 0 then 
      common_functions:PrintError("SetAppIcon response with resultCode TOO_MANY_PENDING_REQUESTS did not come")
      return false
    elseif data.payload.resultCode == "GENERIC_ERROR" then
      common_functions:UserPrint(32, "SetAppIcon response came with resultCode GENERIC_ERROR")
      return true
    else
      common_functions:UserPrint(32, "SetAppIcon response came with resultCode "..tostring(data.payload.resultCode))
      return true
    end
  end)
  :Times(AtLeast(number_of_requests))
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
common_steps:RestoreIniFile("Postcondition_Restore_ini_File")
common_steps:StopSDL("Postcondition_StopSDL")
