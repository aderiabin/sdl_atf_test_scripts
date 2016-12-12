-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

---------------------------------------Common Variables-----------------------------------------------
preload_file = config.pathToSDL .. "sdl_preloaded_pt.json"

---------------------------------------Common Functions-----------------------------------------------
-- Convert sdl_preloaded_pt.json to table
local function ConvertPreloadedToJson()
  -- load data from sdl_preloaded_pt.json
  local file = io.open(preload_file, "r")
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
    if has_value(data.policy_table.app_policies.default.groups, k) or 
    has_value(data.policy_table.app_policies.pre_DataConsent.groups, k) then 
    else 
      data.policy_table.functional_groupings[k] = nil 
    end
  end
  return data
end

-- Create json file from table
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
  self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", notification)
  --mobile side: expected SubscribeVehicleData response
  EXPECT_NOTIFICATION("OnVehicleData", notification)
end

-- This function is used to send notification from HMI and verify this notification is ignored by SDL.
local function Verify_IGNORED_Notification_Case(self, notification)
  common_functions:DelayedExp(1000)
  self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", notification)	
  -- mobile side: expected Notification
  EXPECT_NOTIFICATION("OnVehicleData", notification)	
  :Times(0)
end

-- This function includes all checks for Float Parameter in Notification
local function CheckFloatParameterInNotification(test_name, notification, param, boundary, mandatory)
  -- Param is missed
  Test[test_name .. "IsMissed"] = function(self)
    local testing_notification = CloneTable(notification)
    --Set value for the Parameter in notification
    SetValueForParameter(testing_notification, param, nil)
    if mandatory then
      Verify_IGNORED_Notification_Case(self, testing_notification)
    else
      Verify_SUCCESS_Notification_Case(self, testing_notification)
    end
  end
  -- Param value is wrong type: string
  Test[test_name .. "IsWrongDataType"] = function(self)
    local testing_notification = CloneTable(notification)
    --Set value for the Parameter in notification
    SetValueForParameter(testing_notification, param, "123")
    Verify_IGNORED_Notification_Case(self, testing_notification)
  end
  -- Param value is lower bound value
  Test[test_name .. "IsLowerBound"] = function(self)
    local testing_notification = CloneTable(notification)
    --Set value for the Parameter in notification
    SetValueForParameter(testing_notification, param, boundary.lowerbound)
    Verify_SUCCESS_Notification_Case(self, testing_notification)
  end
  -- Param value is upper bound value
  Test[test_name .. "IsUpperBound"] = function(self)
    local testing_notification = CloneTable(notification)
    --Set value for the Parameter in notification
    SetValueForParameter(testing_notification, param, boundary.upperbound)
    Verify_SUCCESS_Notification_Case(self, testing_notification)
  end
  -- Param value is out of lower bound value
  Test[test_name .. "IsOutLowerBound"] = function(self)
    local testing_notification = CloneTable(notification)
    --Set value for the Parameter in notification
    SetValueForParameter(testing_notification, param, boundary.lowerbound - 0.0000001)
    Verify_IGNORED_Notification_Case(self, testing_notification)
  end
  -- Param value is out of upper bound value
  Test[test_name .. "IsOutUpperBound"] = function(self)
    local testing_notification = CloneTable(notification)
    --Set value for the Parameter in notification
    SetValueForParameter(testing_notification, param, boundary.upperbound + 0.0000001)
    Verify_IGNORED_Notification_Case(self, testing_notification)
  end
  -- Param value is integer
  Test[test_name .. "IsInteger"] = function(self)
    local testing_notification = CloneTable(notification)
    --Set value for the Parameter in notification
    SetValueForParameter(testing_notification, param, math.ceil(boundary.lowerbound))
    Verify_SUCCESS_Notification_Case(self, testing_notification)
  end 
end

-- This function includes all checks for Int Parameter in Notification
local function CheckIntParameterInNotification(test_name, notification, param, boundary, mandatory)
  -- Param is missed
  Test[test_name .. "IsMissed"] = function(self)
    local testing_notification = CloneTable(notification)
    --Set value for the Parameter in notification
    SetValueForParameter(testing_notification, param, nil)
    if mandatory then
      Verify_IGNORED_Notification_Case(self, testing_notification)
    else
      Verify_SUCCESS_Notification_Case(self, testing_notification)
    end
  end
  -- Param value is wrong type: string
  Test[test_name .. "IsWrongDataType"] = function(self)
    local testing_notification = CloneTable(notification)
    --Set value for the Parameter in notification
    SetValueForParameter(testing_notification, param, "123")
    Verify_IGNORED_Notification_Case(self, testing_notification)
  end
  -- Param value is lower bound value
  Test[test_name .. "IsLowerBound"] = function(self)
    local testing_notification = CloneTable(notification)
    --Set value for the Parameter in notification
    SetValueForParameter(testing_notification, param, boundary.lowerbound)
    Verify_SUCCESS_Notification_Case(self, testing_notification)
  end
  -- Param value is upper bound value
  Test[test_name .. "IsUpperBound"] = function(self)
    local testing_notification = CloneTable(notification)
    --Set value for the Parameter in notification
    SetValueForParameter(testing_notification, param, boundary.upperbound)
    Verify_SUCCESS_Notification_Case(self, testing_notification)
  end
  -- Param value is out of lower bound value
  Test[test_name .. "IsOutLowerBound"] = function(self)
    local testing_notification = CloneTable(notification)
    --Set value for the Parameter in notification
    SetValueForParameter(testing_notification, param, boundary.lowerbound - 1)
    Verify_IGNORED_Notification_Case(self, testing_notification)
  end
  -- Param value is out of upper bound value
  Test[test_name .. "IsOutUpperBound"] = function(self)
    local testing_notification = CloneTable(notification)
    --Set value for the Parameter in notification
    SetValueForParameter(testing_notification, param, boundary.upperbound + 1)
    Verify_IGNORED_Notification_Case(self, testing_notification)
  end
end

-- This function includes all checks for Array Parameter in Notification
local function CheckParameterInNotification(test_name, notification, param, boundary, mandatory)
  -- Param is missed
  Test[test_name .. "IsMissed"] = function(self)
    local testing_notification = CloneTable(notification)
    --Set value for the Parameter in notification
    SetValueForParameter(testing_notification, param, nil)
    if mandatory then
      Verify_IGNORED_Notification_Case(self, testing_notification)
    else
      Verify_SUCCESS_Notification_Case(self, testing_notification)
    end
  end
  -- Param value is wrong type: string
  Test[test_name .. "IsWrongDataType"] = function(self)
    local testing_notification = CloneTable(notification)
    --Set value for the Parameter in notification
    SetValueForParameter(testing_notification, param, "123")
    Verify_IGNORED_Notification_Case(self, testing_notification)
  end 
end

local function UpdatePreloadFileAllowOnVehicleDataAndSubscribeVehicleData()
  Test["Precondition_UpdatePreloadFileAllowOnVehicleDataAndSubscribeVehicleData"] = function(self)
    local data = ConvertPreloadedToJson()
    -- insert API into into "functional_groupings"."Base-4"
    data.policy_table.functional_groupings["Base-4"].rpcs["OnVehicleData"] = {
      hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
    }
    data.policy_table.functional_groupings["Base-4"].rpcs["SubscribeVehicleData"] = {
      hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
    }
    -- create preload json file for testing
    CreateJsonFile(data, preload_file)
  end
end

local function SubscribeVehicleData()
  Test["SubscribeVehicleData"] = function(self)
    -- mobile side: send SubscribeWayPoints request
    local cid = self.mobileSession:SendRPC("SubscribeVehicleData",{fuelRange = true, rpm = true, tirePressureValue = true})
    -- hmi side: expected SubscribeWayPoints request
    EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData", {fuelRange = true, rpm = true, tirePressureValue = true})
    :Do(function(_,data)
      -- hmi side: sending Navigation.SubscribeWayPoints response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
    end)
    -- mobile side: SubscribeWayPoints response
    EXPECT_RESPONSE(cid, {success = true , resultCode = "SUCCESS"})
    EXPECT_NOTIFICATION("OnHashChange")
  end
end

---------------------------------------Preconditions--------------------------------------------------
common_functions:DeleteLogsFileAndPolicyTable()
common_functions:BackupFile("sdl_preloaded_pt.json")
UpdatePreloadFileAllowOnVehicleDataAndSubscribeVehicleData()
common_steps:PreconditionSteps("Start_SDL_To_Activate_Application", 7)
SubscribeVehicleData()

------------------------------------------Body--------------------------------------------------------
common_steps:AddNewTestCasesGroup("Verify Fuel Range param")
local boundary_fuel_range ={
  lowerbound = 0.0000,
  upperbound = 10000.0000
}
local notification1 = {rpm = 1}

CheckFloatParameterInNotification("Check_OnVehicleData_with_FuelRange_", notification1, 
{"fuelRange"}, boundary_fuel_range, false)

local tire_pressure_value_params ={
  "leftFront", 
  "rightFront", 
  "leftRear", 
  "rightRear", 
  "innerLeftRear", 
  "innerRightRear", 
  "frontRecommended", 
  "rearRecommended"
}
local boundary_tire_pressure_value ={
  lowerbound = 0,
  upperbound = 65533
}
local notification2 = {rpm =1, tirePressureValue =
  {
    leftFront = 1,
    rightFront = 1,
    leftRear = 1,
    rightRear = 1,
    innerLeftRear = 1,
    innerRightRear = 1,
    frontRecommended = 1,
    rearRecommended = 1
  }
}

common_steps:AddNewTestCasesGroup("Verify Tire Pressure param")
CheckParameterInNotification("Check_VehicleData_with_TirePressureValue_", notification2, {"tirePressureValue"}, false)

for i = 1, #tire_pressure_value_params do 
  common_steps:AddNewTestCasesGroup("Verify TirePressureValue." .. tire_pressure_value_params[i] .. " param")
  CheckIntParameterInNotification("Check_VehicleData_with_TirePressureValue_" ..tire_pressure_value_params[i] .. "_", 
  notification2, {"tirePressureValue", tire_pressure_value_params[i]}, boundary_tire_pressure_value, false)
end 

------------------------------------Postconditions-----------------------------------------------------
Test["Restore file"] = function(self)
  common_functions:RestoreFile("sdl_preloaded_pt.json",1)
end

-- Stop SDL
Test["Postcondition_Stop_SDL"] = function(self)
  StopSDL()
end
