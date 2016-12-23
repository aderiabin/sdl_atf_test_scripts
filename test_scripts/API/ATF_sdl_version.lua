--------------------------------------------------------------------------------
-- Preconditions before ATF start
--------------------------------------------------------------------------------
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
--------------------------------------------------------------------------------
--Precondition: preparation connecttest_sdl_ver.lua
commonPreconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_sdl_ver.lua", true)

f = assert(io.open('./user_modules/connecttest_sdl_ver.lua', "r"))

  fileContent = f:read("*all")
  f:close()

  local pattern1 = "function .?module%:InitHMI_onReady.-initHMI_onReady.-end"
  local pattern1Result = fileContent:match(pattern1)

  if pattern1Result == nil then 
    print(" \27[31m InitHMI_onReady functions is not found in /user_modules/connecttest_sdl_ver.lua \27[0m ")
  else
    fileContent  =  string.gsub(fileContent, pattern1, "")
  end

f = assert(io.open('./user_modules/connecttest_sdl_ver.lua', "w"))
f:write(fileContent)
f:close()

Test = require('user_modules/connecttest_sdl_ver')
require('cardinalities')
local mobile_session = require('mobile_session')
require('user_modules/AppTypes')


---------------------------------------------------------------------------------------------
-------------------------------------------Functions-------------------------------------
---------------------------------------------------------------------------------------------

local function userPrint( color, message)
  print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
end

local function sleep(sec)
  -- body
  os.execute("sleep " .. sec)
end

local function GetSDLVersion()
  -- body
  local iniFilePath = config.pathToSDL .. "smartDeviceLink.ini"
  local iniFile = io.open(iniFilePath)
  if iniFile then
    for line in iniFile:lines() do
      if line:match("SDLVersion") then
        local version = line:match("=.*")
          version = string.gsub(version, "= ", "")
          version = string.gsub(version, "% ", "")
        return version
      end
    end
  else
      return nil
  end
end

local function CheckSDLVersion()
  -- body
  local version = GetSDLVersion()
  if (version:match("%a")) and (version:match("%d"))  then
    if version:match("%p") then
      return false
    else
      return true
    end
  else
      userPrint(33, "There are no digits or letters")
      return false
  end
end

function ReplaceSDLVersion(version)
  -- body
  local iniFilePath = config.pathToSDL .. "smartDeviceLink.ini"
  local iniFile = io.open(iniFilePath, "r")
  sContent = ""
  if iniFile then
    for line in iniFile:lines() do
        if line:match("SDLVersion") then
        -- local version = line:match("=.*")
        line = string.gsub(line, "=.*", "= " .. version)
        sContent = sContent .. line ..'\n'
      else
        sContent = sContent .. line .. '\n'
      end
    end
  end
  iniFile:close()

  iniFile = io.open(iniFilePath, "w")
  iniFile:write(sContent)
  iniFile:close()
end

local function CreateSession( self)
  self.mobileSession = mobile_session.MobileSession(
        self,
        self.mobileConnection)
end

local function RegisterApp(self, passCriteria)
  local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
    :Do(function(_,data)
      HMIAppID = data.params.application.appID
      self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
    end)

  -- self.mobileSession:ExpectResponse(correlationId, { success = true })
  EXPECT_RESPONSE(correlationId, { success = true })
  :ValidIf(function (_,data)
    if data.payload.sdlVersion == passCriteria then
      return true
    else
      return false
    end
  end)

end

function RestartSDL(self, suffix)
  -- body
  
  Test["StopSDL"..tostring(suffix)] = function (self)
    StopSDL()
  end

  Test["StartSDL" .. tostring(suffix)] = function (self)
    StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  Test["TestInitHMI" .. tostring(suffix)] = function (self)
    self:initHMI()
  end

  Test["TestInitHMIOnReady" .. tostring(suffix)] = function (self)
    self:initHMI_onReady()
  end

end


-- Precondition: removing user_modules/connecttest_sdl_ver.lua
  function Test:Precondition_remove_user_connecttest()
    os.execute( "rm -f ./user_modules/connecttest_sdl_ver.lua" )
  end
	
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------

-- BEGIN TEST SUIT sdlVersion
-- Description: SDL must set;
--    value of 'sdlVersion' parameter as commit hash automatically;
--    copy this value to corresponding parameter in .ini file;
--    extract the default value of 'sdlVersion' parameter from .ini file
--    parameter sdlVersion must be confugurable by user

local sdl_version = GetSDLVersion()

-- BEGIN TEST CASE 1.1
-- Description: SDL must set value of 'sdlVersion' parameter as commit hash automatically;
function Test:SDLVersionIsPresentInINI()
  -- body
  CheckSDLVersion()

end
-- END TESTCASE 1.1

-- BEGIN TEST CASE 1.2
-- Description: SDL must provide sdl_version in RegisterAppInterface response
local version = ''
local indexOfTests = 1
RestartSDL(self, indexOfTests)

Test["ConnectMobile" .. tostring(indexOfTests)] = function (self)
  userPrint(33, "===Test start - SDL must provide sdl_version in RegisterAppInterface response===")
  self:connectMobile()
end
Test["StartSession" .. tostring(indexOfTests)] = function (self)
  CreateSession(self)
end
Test["RegisterApp" .. tostring(indexOfTests)] = function (self)
  self.mobileSession:StartService(7)
  :Do(function (_,data)
    RegisterApp(self, sdl_version)
  end)
  userPrint(33, "===Test end - SDL must provide sdl_version in RegisterAppInterface response===")
end
indexOfTests = indexOfTests + 1
-- END TESTCASE 1.2

-- BEGIN TEST CASE 1.3
-- Description: sdlVersion must be configured by user
Test["StopSDL"..tostring(indexOfTests)] = function (self)
  userPrint(33, "===Test start - sdlVersion must be configured by user===")
  StopSDL()
end

function Test:PreconditionChangeSDLVersion(...)
  -- body
  sdl_version = "123456"
  ReplaceSDLVersion(sdl_version)
end

Test["StartSDL" .. tostring(indexOfTests)] = function (self)
  StartSDL(config.pathToSDL, config.ExitOnCrash)
  sleep(2)
end

Test["TestInitHMI" .. tostring(indexOfTests)] = function (self)
  self:initHMI()
end

Test["TestInitHMIOnReady" .. tostring(indexOfTests)] = function (self)
  self:initHMI_onReady("absent")
end

Test["ConnectMobile" .. tostring(indexOfTests)] = function (self)
  self:connectMobile()
end
Test["StartSession" .. tostring(indexOfTests)] = function (self)
  CreateSession(self)
end
Test["RegisterApp" .. tostring(indexOfTests)] = function (self)
  self.mobileSession:StartService(7)
  :Do(function (_,data)
    RegisterApp(self, sdl_version)
  end)
  userPrint(33, "===Test end - sdlVersion must be configured by user===")
end
indexOfTests = indexOfTests + 1
-- END TESTCASE 1.3



-- BEGIN TEST CASE 1.4
-- Description: sdlVersion parameter is empty
Test["StopSDL"..tostring(indexOfTests)] = function (self)
  userPrint(33, "===Test start - sdlVersion parameter is empty===")
  StopSDL()
end

function Test:PreconditionChangeSDLVersion(...)
  -- body
  sdl_version = ""
  ReplaceSDLVersion(sdl_version)
end

Test["StartSDL" .. tostring(indexOfTests)] = function (self)
  StartSDL(config.pathToSDL, config.ExitOnCrash)
  sleep(2)
end

Test["TestInitHMI" .. tostring(indexOfTests)] = function (self)
  self:initHMI()
end

Test["TestInitHMIOnReady" .. tostring(indexOfTests)] = function (self)
  self:initHMI_onReady("absent")
end

Test["ConnectMobile" .. tostring(indexOfTests)] = function (self)
  self:connectMobile()
end
Test["StartSession" .. tostring(indexOfTests)] = function (self)
  CreateSession(self)
end
Test["RegisterApp" .. tostring(indexOfTests)] = function (self)
  self.mobileSession:StartService(7)
  :Do(function (_,data)
    RegisterApp(self, sdl_version)
  end)
  userPrint(33, "===Test end - sdlVersion parameter is empty===")
end
indexOfTests = indexOfTests + 1
-- END TESTCASE 1.4

-- END TEST SUIT sdlVersion