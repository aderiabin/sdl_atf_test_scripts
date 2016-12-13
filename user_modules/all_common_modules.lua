Test = require('user_modules/connect_without_mobile_connection')
common_functions = require('user_modules/common_functions')
common_steps = require('user_modules/common_steps')
json = require('json4lua/json/json')
require('user_modules/AppTypes')
mobile_session = require('mobile_session')
module = require('testbase')
require('cardinalities')
events = require('events')
mobile = require('mobile_connection')
tcp = require('tcp_connection')
file_connection = require('file_connection')
config = require('config')
expectations = require('expectations')
Expectation = expectations.Expectation
sdl = require('SDL')

-------------------- Set default settings for ATF script --------------------
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
config.defaultProtocolVersion = 2
if common_functions:IsFileExist("sdl.pid") then
  os.execute("rm sdl.pid")
end
os.execute("kill -9 $(ps aux | grep -e smartDeviceLinkCore | awk '{print$2}')")

local path_to_sdl_without_bin = string.gsub(config.pathToSDL, "bin/", "")
local sdl_bin_bk = path_to_sdl_without_bin .. "sdl_bin_bk/"
if common_functions:IsDirectoryExist(sdl_bin_bk) == false then
  os.execute("mkdir " .. sdl_bin_bk)
end
if common_functions:IsFileExist(sdl_bin_bk .. "hmi_capabilities.json") then
  os.execute("cp -f -r " .. sdl_bin_bk .. "hmi_capabilities.json " .. config.pathToSDL)
else
  os.execute("cp -f -r " .. config.pathToSDL .. "hmi_capabilities.json " ..  sdl_bin_bk .. "hmi_capabilities.json")
end
if common_functions:IsFileExist(sdl_bin_bk .. "smartDeviceLink.ini") then
  os.execute("cp -f -r " .. sdl_bin_bk .. "smartDeviceLink.ini " .. config.pathToSDL)
else
  os.execute("cp -f -r " .. config.pathToSDL .. "smartDeviceLink.ini " ..  sdl_bin_bk .. "smartDeviceLink.ini")
end
if common_functions:IsFileExist(sdl_bin_bk .. "sdl_preloaded_pt.json") then
  os.execute("cp -f -r " .. sdl_bin_bk .. "sdl_preloaded_pt.json " .. config.pathToSDL)
else
  os.execute("cp -f -r " .. config.pathToSDL .. "sdl_preloaded_pt.json " ..  sdl_bin_bk .. "sdl_preloaded_pt.json")
end
