local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local colors = require('user_modules/consts').color

function DEBUG_MESSAGE(message, data) 
	if data then
		if type(data) == "table" then
			message = message .. " =>\n" .. commonFunctions:convertTableToString(data, 1)
		else
			message = message .. " => " .. data
		end
	end
	commonFunctions:userPrint(colors.blue, message)
end
