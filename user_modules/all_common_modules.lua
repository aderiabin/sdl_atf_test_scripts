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
