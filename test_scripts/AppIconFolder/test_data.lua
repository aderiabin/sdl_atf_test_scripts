local testData = {}

local config = require('config')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--common data
testData.pathToSdlStorage = commonPreconditions:GetPathToSDL() .. "storage"
testData.RAIParameters = config.application1.registerAppInterfaceParams
testData.AppIconsFolderPath = commonPreconditions:GetPathToSDL() .. "Icons"

return testData