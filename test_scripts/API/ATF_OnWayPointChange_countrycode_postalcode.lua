------------------------------------------------------------------------------------------------------
------------------------------------General Settings for Configuration--------------------------------
------------------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

------------------------------------------------------------------------------------------------------
---------------------------------------Common Variables-----------------------------------------------
------------------------------------------------------------------------------------------------------
local preload_file = config.pathToSDL .. "sdl_preloaded_pt.json"
local notification =
{	
  wayPoints = {
    {
      searchAddress = {
        countryName = "a",
        countryCode = "a",
        postalCode = "a",
        administrativeArea = "a",
        subAdministrativeArea = "a",
        locality = "a",
        subLocality = "a",
        thoroughfare = "a",
        subThoroughfare = "a"
      },
      locationName = "a"
    }
  }
}
local string_boundary = {
  lowerbound = 0,
  upperbound = 200
}
------------------------------------------------------------------------------------------------------
---------------------------------------Common Functions-----------------------------------------------
------------------------------------------------------------------------------------------------------
-- Convert sdl_preloaded_pt.json to table
local function ConvertPreloadedToJson()
  -- load data from sdl_preloaded_pt.json
  local file  = io.open(preload_file, "r")
  local json_data = file:read("*all") 
  file:close()
  -- decode json to array
  local json = require("json") 
  local data = json.decode(json_data)
  local function has_value (tab, val)
    for index, value in ipairs (tab) do
        if value == val then
            return true
        end
    end
    return false
  end
  for k,v in pairs(data.policy_table.functional_groupings) do
    if  has_value(data.policy_table.app_policies.default.groups, k) or 
        has_value(data.policy_table.app_policies.pre_DataConsent.groups, k) then 
    else 
      data.policy_table.functional_groupings[k] = nil 
    end
  end
  return data
end

-- Creat json file from table
local function CreateJsonFile(input_data, json_file_path)
  local json = require("json")
  data = json.encode(input_data)
  file = io.open(json_file_path, "w")
  file:write(data)
  file:close()  
end

-- Create new table and copy value from other tables. It is used to void unexpected change original table.
local function CloneTable(original)
	if original == nil then
		return {}
	end

    local copy = {}
    for k, v in pairs(original) do
        if type(v) == 'table' then
            v = CloneTable(v)
        end
        copy[k] = v
    end
    return copy
end

-- Set value for a parameter on the request
local function SetValueForParameter(request, parameter, value)
	local temp = request
	for i = 1, #parameter - 1 do
		temp = temp[parameter[i]]
	end
	temp[parameter[#parameter]] = value
end

-- This function is used to send notification from HMI and verify this notification is successed sent to SDL.
local function Verify_SUCCESS_Notification_Case(self, notification)
  self.hmiConnection:SendNotification("Navigation.OnWayPointChange", notification)	 		
  -- mobile side: expected SubscribeVehicleData response
  EXPECT_NOTIFICATION("OnWayPointChange", notification)	
end

-- This function is used to send notification from HMI and verify this notification is ignored by SDL.
local function Verify_IGNORED_Notification_Case(self, notification)
  common_functions:DelayedExp(1000)
  self.hmiConnection:SendNotification("Navigation.OnWayPointChange", notification)	 		
  -- mobile side: expected Notification
  EXPECT_NOTIFICATION("OnWayPointChange", notification)	
  :Times(0)
end

-- This function includes all checks for String Paramter in Notification
local function CheckStringParameterInNotification(test_name, notification, param, boundary, mandatory)
  -- Param is missed
  if mandatory then
    Test[test_name .. "IsMissed_IGNORED"] = function(self)
      local testing_notification = CloneTable(notification)
      SetValueForParameter(testing_notification, param, nil)  
      Verify_IGNORED_Notification_Case(self, testing_notification)
    end
  else
    Test[test_name .. "IsMissed_SUCCESS"] = function(self)
      local testing_notification = CloneTable(notification)
      SetValueForParameter(testing_notification, param, nil)  
      Verify_SUCCESS_Notification_Case(self, testing_notification)
    end
  end

  -- Param value is wrong type: number
	Test[test_name .. "IsWrongDataType_IGNORED"] = function(self)
		local testing_notification = CloneTable(notification)
		SetValueForParameter(testing_notification, param, 123)
    Verify_IGNORED_Notification_Case(self, testing_notification)
	end

  -- Param value is lower bound value: is empty
	Test[test_name .. "IsLowerBound_IsEmpty_SUCCESS"] = function(self)
		local testing_notification = CloneTable(notification)
		SetValueForParameter(testing_notification, param, "")
    Verify_SUCCESS_Notification_Case(self, testing_notification)
	end
  
  -- Param value is upper bound value
	Test[test_name .. "IsUpperBound_SUCCESS"] = function(self)
		local testing_notification = CloneTable(notification)
    local input_string = string.rep("a", boundary.upperbound)
		SetValueForParameter(testing_notification, param, input_string)
    Verify_SUCCESS_Notification_Case(self, testing_notification)
	end

  -- Param value is out of lower bound value: not applicable

  -- Param value is out of upper bound value
	Test[test_name .. "IsOutUpperBound_IGNORED"] = function(self)
		local testing_notification = CloneTable(notification)
    local input_string = string.rep("a", boundary.upperbound+1)    
		SetValueForParameter(testing_notification, param, input_string)
    Verify_IGNORED_Notification_Case(self, testing_notification)
	end

  -- Param value contains white spaces only
	Test[test_name .. "ContainsWhiteSpacesOnly_SUCCESS"] = function(self)
		local testing_notification = CloneTable(notification)
		SetValueForParameter(testing_notification, param, "   ")
    Verify_SUCCESS_Notification_Case(self, testing_notification)
	end

  -- Param value contains special character: new line character
	Test[test_name .. "ContainsNewLineCharacter_SUCCESS"] = function(self)
		local testing_notification = CloneTable(notification)
		SetValueForParameter(testing_notification, param, "a\nb")
    Verify_SUCCESS_Notification_Case(self, testing_notification)
	end 

  -- Param value contains special character: Tab Character
	Test[test_name .. "ContainsTabCharacter_SUCCESS"] = function(self)
		local testing_notification = CloneTable(notification)
		SetValueForParameter(testing_notification, param, "a\tb")
    Verify_SUCCESS_Notification_Case(self, testing_notification)
	end 
  
end

------------------------------------------------------------------------------------------------------
---------------------------------------Preconditions--------------------------------------------------
------------------------------------------------------------------------------------------------------
-- delete app_info.dat, SmartDeviceLinkCore.log, TransportManager.log, ProtocolFordHandling.log, HmiFrameworkPlugin.log and policy.sqlite
common_functions:DeleteLogsFileAndPolicyTable()

-- replace sdl_preloaded_pt.json by new file with SubscribeWayPoints, OnWayPointChange, UnsubscribeWayPoints are allowed 
Test["Precondition_Replace_Preload"] = function(self)
  -- backup preload
  os.execute(" cp " .. preload_file .. " " .. preload_file .. "_origin" )
  -- create PTU from sdl_preloaded_pt.json
	local data = ConvertPreloadedToJson()
  -- insert API into into "functional_groupings"."Base-4"
  data.policy_table.functional_groupings["Base-4"].rpcs["SubscribeWayPoints"] = {
    hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
  }
  data.policy_table.functional_groupings["Base-4"].rpcs["OnWayPointChange"] = {
    hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
  }  
  data.policy_table.functional_groupings["Base-4"].rpcs["UnsubscribeWayPoints"] = {
    hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
  }  
  -- create preload json file for testing
  CreateJsonFile(data, preload_file)
end

-- start SDL, add connection, add mobile session, register application then activate application
common_steps:PreconditionSteps("Start_SDL_To_Activate_Application", 7)

-- success SubscribeWayPoints
Test["Precondition_SubscribeWayPoints"] = function(self)
  -- mobile side: send SubscribeWayPoints request
  local cid = self.mobileSession:SendRPC("SubscribeWayPoints",{})
  -- hmi side: expected SubscribeWayPoints request
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Do(function(_,data)
    -- hmi side: sending Navigation.SubscribeWayPoints response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
  end)
  -- mobile side: SubscribeWayPoints response
  EXPECT_RESPONSE(cid, {success = true , resultCode = "SUCCESS"})
  EXPECT_NOTIFICATION("OnHashChange")
end

------------------------------------------------------------------------------------------------------
------------------------------------------Tests-------------------------------------------------------
------------------------------------------------------------------------------------------------------
-- Main Check: String parameter countryCode 
CheckStringParameterInNotification("Check_OnWayPointChange_countryCode_", notification, 
  {"wayPoints", 1, "searchAddress","countryCode"}, string_boundary, false)

-- Main Check: String parameter postalCode 
CheckStringParameterInNotification("Check_OnWayPointChange_postalCode_", notification, 
  {"wayPoints", 1, "searchAddress","postalCode"}, string_boundary, false)

------------------------------------------------------------------------------------------------------
------------------------------------Postcondition-----------------------------------------------------
------------------------------------------------------------------------------------------------------
-- success UnsubscribeWayPoints
Test["Postcondition_UnsubscribeWayPoints"] = function(self)
  -- mobile side: sending UnsubscribeWayPoints request
  local cid = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})
  -- hmi side: expect UnsubscribeWayPoints request
  EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
  :Do(function(_,data)
    -- hmi side: sending Navigation.UnsubscribeWayPoints response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})	
  end)
  -- mobile side: expect UnsubscribeWayPoints response
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  EXPECT_NOTIFICATION("OnHashChange")
end

-- restore sdl_preloaded_pt.json
Test["Postcondition_Restore_Preload"] = function(self)
  os.execute(" cp " .. preload_file .. "_origin " .. preload_file)
end

-- Stop SDL
Test["Postcondition_Stop_SDL"] = function(self)
  StopSDL()
end
