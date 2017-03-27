local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

local appIconsFolderCommon = {}

--[Helpers]
function appIconsFolderCommon.prepareEnvironment(testIconsFolder)
	commonSteps:DeleteLogsFileAndPolicyTable()
	assert(os.execute( "rm -rf " .. testIconsFolder))
end

local function backupSdlIni()
	os.execute( "cp -f " .. commonPreconditions:GetPathToSDL() .. "smartDeviceLink.ini " .. commonPreconditions:GetPathToSDL() .. "backup_smartDeviceLink.ini")
end

function appIconsFolderCommon.prepareSdlIni(data)
	backupSdlIni()
	for _, params in pairs(data) do
		commonFunctions:SetValuesInIniFile(params.property .. "%s-=%s-.-%s-\n", params.property, params.value)
	end
end

function appIconsFolderCommon.restoreSdlIni()
	os.execute( "mv -f " .. commonPreconditions:GetPathToSDL() .. "backup_smartDeviceLink.ini " .. commonPreconditions:GetPathToSDL() .. "smartDeviceLink.ini")
end

local function folderSize(PathToFolder)
  local aHandle = assert(io.popen( "du -s -B1 " .. PathToFolder, 'r'))
  local buff = aHandle:read( '*l' )
  return buff:match("^%d+")
end

function appIconsFolderCommon.getListOfFilesInStorageFolder(folder)
  local aHandle = assert( io.popen( "ls --full-time " .. folder .. " | awk '{print $9\"\t\"$6\" \"$7}'" , 'r'))
  local ListOfFilesInStorageFolder = aHandle:read( '*a' )
  aHandle:close()
  commonFunctions:userPrint(32, "Content of storage folder: " .."\n" ..ListOfFilesInStorageFolder)
end

function appIconsFolderCommon.makeAppIconsFolderFull(AppIconsFolder)
  local iconFolderSizeInBytes = 1048576
  local oneIconSizeInBytes = 326360
  local currentSizeIconsFolderInBytes = folderSize(AppIconsFolder)
  local sizeToFull = iconFolderSizeInBytes - currentSizeIconsFolderInBytes
  local i = 1
  while sizeToFull > oneIconSizeInBytes do
    os.execute("sleep 2")
    local copyFileToAppIconsFolder = assert(os.execute( "cp files/icon.png " .. AppIconsFolder .. "/icon" .. i ..".png"))
    i = i + 1
    if copyFileToAppIconsFolder ~= true then
      commonFunctions:userPrint(31, " Files are not copied to " .. AppIconsFolder)
    end
    currentSizeIconsFolderInBytes = folderSize(AppIconsFolder)
    sizeToFull = iconFolderSizeInBytes - currentSizeIconsFolderInBytes
    if i > 10 then
      commonFunctions:userPrint(31, " Loop is breaking due to a lot of iterations ")
      break
    end
  end
  appIconsFolderCommon.getListOfFilesInStorageFolder(AppIconsFolder)
end

--[Test steps implementation]
function appIconsFolderCommon.registerApplication(test, RAIParameters)
  local corIdRAI = test.mobileSession:SendRPC("RegisterAppInterface", RAIParameters)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
    {
      application =
      {
        appName = RAIParameters.appName
      }
    })
  :Do(function(_,data)
      test.applications[RAIParameters.appName] = data.params.application.appID
    end)
  test.mobileSession:ExpectResponse(corIdRAI, { success = true, resultCode = "SUCCESS" })
end

function appIconsFolderCommon.startSDLWithConnectedHMIandMobile(test)
  test:runSDL()
  commonFunctions:waitForSDLStart(test):Do(function()
    test:initHMI():Do(function()
      commonFunctions:userPrint(35, "HMI initialized")
      test:initHMI_onReady():Do(function ()
        commonFunctions:userPrint(35, "HMI is ready")
        test:connectMobile():Do(function ()
          commonFunctions:userPrint(35, "Mobile Connected")
        end)
      end)
    end)
  end)
end

return appIconsFolderCommon