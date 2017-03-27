---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [GENIVI] Conditions for SDL to create and use 'AppIconsFolder' storage
-- [AppIconsFolder]: Conditions for SDL to remove old icons on value defined at "AppIconsAmountToRemove" param
-- Description:
-- SDL should remove oldest icon due AppIconsAmountToRemove param in .ini file if not enough space
-- 1. Used preconditions:
-- Stop SDL
-- Set AppIconsFolder in .ini file
-- Set AppIconsFolder maxSize
-- Set Icons Amount to remove if not enough space
-- Start SDL and HMI
-- Connect mobile
-- Make AppIconsFolder is full
-- 2. Performed steps:
-- Register app
-- Send SetAppIcon
-- Expected result:
-- SDL should delete oldest icon and save a new one in AppIconsFolder
---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
-- local Test = require('user_modules/dummy_connecttest')
require('cardinalities')
local mobile_session = require('mobile_session')

--[[ Required Shared Libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
-- require('user_modules/AppTypes')
local testData = require('test_scripts/AppIconsFolder/test_data')
local common = require('test_scripts/AppIconsFolder/common')
local runner = require('user_modules/script_runner')

--[[ Local variables ]]
local RAIParameters = testData.RAIParameters
local testIconsFolder = testData.AppIconsFolderPath


--[[ Local functions ]]
local function checkOldDeleted()
  local status = true
  local iconFolderPath = testIconsFolder .. "/"
  common.getListOfFilesInStorageFolder(iconFolderPath)
  local applicationFileToCheck = iconFolderPath .. RAIParameters.appID
  local applicationFileExistsResult = commonSteps:file_exists(applicationFileToCheck)
  if applicationFileExistsResult ~= true then
    commonFunctions:userPrint(31, RAIParameters.appID .. " icon is absent")
    status = false
  end
  local oldFileExistResult = commonSteps:file_exists(iconFolderPath.. "icon1.png" )
  if oldFileExistResult ~= false then
    commonFunctions:userPrint(31,"Oldest icon1.png is not deleted from AppIconsFolder")
    status = false
  end
  return status
end

--[[ Preconditions ]]
local function prepare_Environment_And_SDLini()
  common.prepareEnvironment(testIconsFolder)

  local iniData = {
    {property = "AppIconsFolder", value = testIconsFolder},
    {property = "AppIconsFolderMaxSize", value = 1048576},
    {property = "AppIconsAmountToRemove", value = 1}
  }

  common.prepareSdlIni(iniData)
end

local function make_AppIconsFolder_Full()
  common.makeAppIconsFolderFull(testIconsFolder)
end

local function start_SDL_With_Connected_HMI_and_Mobile(self)
  common.startSDLWithConnectedHMIandMobile(self)
end

--[[ Test ]]
local function check_Deleted_one_old_icon_if_space_not_enough(self)
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
  :Do(function()
      common.registerApplication(self, RAIParameters)
      EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
      :Do(function()
          local cidPutFile = self.mobileSession:SendRPC("PutFile",
            {
              syncFileName = "iconFirstApp.png",
              fileType = "GRAPHIC_PNG",
              persistentFile = false,
              systemFile = false
            }, "files/icon.png")
          EXPECT_RESPONSE(cidPutFile, { success = true, resultCode = "SUCCESS" })
          :Do(function()
              local cidSetAppIcon = self.mobileSession:SendRPC("SetAppIcon",{ syncFileName = "iconFirstApp.png" })
              local pathToAppFolder = testData.pathToSdlStorage.. "/" .. RAIParameters.appID .. "_" .. config.deviceMAC .. "/"
              EXPECT_HMICALL("UI.SetAppIcon",
                {
                  syncFileName =
                  {
                    imageType = "DYNAMIC",
                    value = pathToAppFolder .. "iconFirstApp.png"
                  }
                })
              :Do(function(_,data)
                  self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
                end)
              EXPECT_RESPONSE(cidSetAppIcon, { resultCode = "SUCCESS", success = true })
              :ValidIf(function()
                  return checkOldDeleted()
                end)
            end)
        end)
    end)
end

--[[ Postconditions ]]
local function postconditions()
  StopSDL()
  assert(os.execute( "rm -rf " .. testIconsFolder))
  common.restoreSdlIni()
end

--[[ Scenario]]
runner.PRECONDITION("1: Prepare environment and SDL ini file", prepare_Environment_And_SDLini)
runner.PRECONDITION("2: Start SDL and connect HMI and Mobile device", start_SDL_With_Connected_HMI_and_Mobile)
runner.PRECONDITION("3: Fill the Application icon folder", make_AppIconsFolder_Full)
runner.STEP("4: Check that older icon have been deleted", check_Deleted_one_old_icon_if_space_not_enough)
runner.POSTCONDITION("5: Stop SDL and restore SDL ini file", postconditions)
