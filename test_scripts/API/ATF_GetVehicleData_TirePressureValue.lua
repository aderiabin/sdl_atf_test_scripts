-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

---------------------------------------Common Variables-----------------------------------------------
local preload_file = config.pathToSDL .. "sdl_preloaded_pt.json"
local response

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

-- Create default request parameters
local function CreateRequest()
  return {
    tirePressureValue = true
  }
end

-- Create default response
local function CreateResponse()
  local response ={
    tirePressureValue ={
      leftFront = 50,
      rightFront = 50,
      leftRear = 50,
      rightRear = 50,
      innerLeftRear = 50,
      innerRightRear = 50,
      frontRecommended = 50,
      rearRecommended = 50
  }} 
  return response
end

-- This function is used to send default request and response with specific invalid data and verify GENERIC_ERROR resultCode
local function Verify_GENERIC_ERROR_Response_Case(self, response)
  -- mobile side: sending the request
  local request = CreateRequest()
  local cid = self.mobileSession:SendRPC("GetVehicleData", request)
  -- hmi side: expect VehicleInfo.GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData", request)
  :Do(function(_,data)
    -- hmi side: sending response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)
  end)
  -- mobile side: expect the response
  EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle" })
  :Timeout(11000)
  common_functions:DelayedExp(1000)
end

-- This function is used to send default request and response with specific valid data and verify SUCCESS resultCode
function Verify_SUCCESS_Response_Case(self, response)
  -- mobile side: sending the request
  local request = CreateRequest()
  local cid = self.mobileSession:SendRPC("GetVehicleData", request)
  -- hmi side: expect VehicleInfo.GetVehicleData request
  EXPECT_HMICALL("VehicleInfo.GetVehicleData", request)
  :Do(function(_,data)
    -- hmi side: sending response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)
  end)
  -- mobile side: expect the response
  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
  common_functions:DelayedExp(1000)
end

-- This function includes all checks for String Parameter in Response
local function CheckIntParameterInResponse(test_name, response, param, boundary, mandatory)
  -- Param is missed
  Test[test_name .. "IsMissed"] = function(self)
    local testing_notification = CloneTable(response)
    --Set value for the Parameter in response
    SetValueForParameter(testing_notification, param, nil)
    if mandatory then
      Verify_GENERIC_ERROR_Response_Case(self, testing_notification)
    else
      Verify_SUCCESS_Response_Case(self, testing_notification)
    end
  end
  -- Param value is wrong type: string
  Test[test_name .. "IsWrongDataType"] = function(self)
    local testing_notification = CloneTable(response)
    --Set value for the Parameter in response
    SetValueForParameter(testing_notification, param, "123")
    Verify_GENERIC_ERROR_Response_Case(self, testing_notification)
  end
  -- Param value is lower bound value
  Test[test_name .. "IsLowerBound"] = function(self)
    local testing_notification = CloneTable(response)
    --Set value for the Parameter in response
    SetValueForParameter(testing_notification, param, boundary.lowerbound)
    Verify_SUCCESS_Response_Case(self, testing_notification)
  end
  -- Param value is upper bound value
  Test[test_name .. "IsUpperBound"] = function(self)
    local testing_notification = CloneTable(response)
    --Set value for the Parameter in response
    SetValueForParameter(testing_notification, param, boundary.upperbound)
    Verify_SUCCESS_Response_Case(self, testing_notification)
  end
  -- Param value is out of lower bound value
  Test[test_name .. "IsOutLowerBound"] = function(self)
    local testing_notification = CloneTable(response)
    --Set value for the Parameter in response
    SetValueForParameter(testing_notification, param, boundary.lowerbound - 1)
    Verify_GENERIC_ERROR_Response_Case(self, testing_notification)
  end
  -- Param value is out of upper bound value
  Test[test_name .. "IsOutUpperBound"] = function(self)
    local testing_notification = CloneTable(response)
    --Set value for the Parameter in response
    SetValueForParameter(testing_notification, param, boundary.upperbound + 1)
    Verify_GENERIC_ERROR_Response_Case(self, testing_notification)
  end 
end

-- This function includes all checks for array Parameter in Response
local function CheckParameterInResponse(test_name, response, param, mandatory)
  -- Param is missed
  Test[test_name .. "IsMissed"] = function(self)
    local testing_notification = CloneTable(response)
    --Set value for the Parameter in response
    SetValueForParameter(testing_notification, param, nil)
    if mandatory then
      Verify_GENERIC_ERROR_Response_Case(self, testing_notification)
    else
      Verify_SUCCESS_Response_Case(self, testing_notification)
    end
  end
  -- Param value is wrong type: string
  Test[test_name .. "IsWrongDataType"] = function(self)
    local testing_notification = CloneTable(response)
    --Set value for the Parameter in response
    SetValueForParameter(testing_notification, param, "123")
    Verify_GENERIC_ERROR_Response_Case(self, testing_notification)
  end 
end

local function UpdatePreloadFileAllowGetVehicleData()
  Test["Precondition_UpdatePreloadFileAllowGetVehicleData"] = function(self)
    -- create PTU from sdl_preloaded_pt.json
    local data = ConvertPreloadedToJson()
    -- insert API into into "functional_groupings"."Base-4"
    data.policy_table.functional_groupings["Base-4"].rpcs["GetVehicleData"] = {
      hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
    } 
    -- create preload json file for testing
    CreateJsonFile(data, preload_file)
  end
end

---------------------------------------Preconditions--------------------------------------------------
common_functions:DeleteLogsFileAndPolicyTable()
common_functions:BackupFile("sdl_preloaded_pt.json")
UpdatePreloadFileAllowGetVehicleData()
common_steps:PreconditionSteps("Start_SDL_To_Activate_Application", 7)

------------------------------------------Body-------------------------------------------------------

response = CreateResponse()
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

local tire_pressure_value_range ={
  lowerbound = 0,
  upperbound = 65533
} 

common_steps:AddNewTestCasesGroup("Verify TirePressureValue param")
CheckParameterInResponse("Check_GetVehicleData_with_TirePressureValue_",response, {"tirePressureValue"}, false)

for i = 1, #tire_pressure_value_params do 
  common_steps:AddNewTestCasesGroup("Verify TirePressureValue." .. tire_pressure_value_params[i] .. " param")
  CheckIntParameterInResponse("Check_GetVehicleData_with_TirePressureValue_" .. tire_pressure_value_params[i] .. "_in_response_", response, 
  {"tirePressureValue", tire_pressure_value_params[i]}, tire_pressure_value_range, false)
end

------------------------------------Postconditions-----------------------------------------------------
-- restore sdl_preloaded_pt.json
Test["Restore file"] = function(self)
  common_functions:RestoreFile("sdl_preloaded_pt.json",1)
end

-- Stop SDL
Test["Stop_SDL"] = function(self)
  StopSDL()
end
