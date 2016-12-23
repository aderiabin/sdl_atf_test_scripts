------------------------------------------------------------------------------------------------------
------------------------------------General Settings for Configuration--------------------------------
------------------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

------------------------------------------------------------------------------------------------------
---------------------------------------Common Variables-----------------------------------------------
------------------------------------------------------------------------------------------------------
local preload_file = config.pathToSDL .. "sdl_preloaded_pt.json"
local request
local boundary_longitude_degrees = {
  lowerbound = -180,
  upperbound = 180
}
local boundary_latitude_degrees = {
  lowerbound = -90,
  upperbound = 90
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

-- Create UI expected result based on parameters from the request
local function CreateUIParameters(request_params)
  local param = {}
  if request_params["locationImage"] ~= nil then
    param["locationImage"] = request_params["locationImage"]
    if param["locationImage"].imageType == "DYNAMIC" then			
      param["locationImage"].value = STORAGE_PATH .. param["locationImage"].value
    end	
  end	
  if request_params["longitudeDegrees"] ~= nil then
    param["longitudeDegrees"] = request_params["longitudeDegrees"]
  end
  if request_params["latitudeDegrees"] ~= nil then
    param["latitudeDegrees"] = request_params["latitudeDegrees"]
  end
  if request_params["locationName"] ~= nil then
    param["locationName"] = request_params["locationName"]
  end
  if request_params["locationDescription"] ~= nil then
    param["locationDescription"] = request_params["locationDescription"]
  end
  if request_params["addressLines"] ~= nil then
    param["addressLines"] = request_params["addressLines"]
  end
  if request_params["deliveryMode"] ~= nil then
    param["deliveryMode"] = request_params["deliveryMode"]
  end
  if request_params["phoneNumber"] ~= nil then
    param["phoneNumber"] = request_params["phoneNumber"]
  end
  if request_params["address"] ~= nil then
    local addressParams = {"countryName", "countryCode", "postalCode", "administrativeArea", "subAdministrativeArea", "locality", "subLocality", "thoroughfare", "subThoroughfare"}
    local parameterFind = false
    param.address = {}
    for i=1, #addressParams do
      if request_params.address[addressParams[i]] ~= nil then
        param.address[addressParams[i]] = request_params.address[addressParams[i]]
        parameterFind = true
      end
    end
    if
    parameterFind == false then
      param.address = nil
    end
  end
  if request_params["timeStamp"] ~= nil then
    param.timeStamp = {}
    local timeStampParams = {"millisecond","second", "minute", "hour", "day", "month", "year", "tz_hour", "tz_minute"}
    for i=1, #timeStampParams do
      if 
      request_params.timeStamp[timeStampParams[i]] ~= nil then
        param.timeStamp[timeStampParams[i]] = request_params.timeStamp[timeStampParams[i]]
      else
        if request_params.timeStamp["tz_hour"] == nil then
          param.timeStamp["tz_hour"] = 0
        end
        if request_params.timeStamp["tz_minute"] == nil then
          param.timeStamp["tz_minute"] = 0
        end
      end
    end
  end
  return param
end

-- This function sends a request from mobile and verify result on HMI and mobile for SUCCESS resultCode cases.
local function Verify_SUCCESS_Case(self, request_params)
  local temp = json.encode(request_params)
  local cid = 0
  if string.find(temp, "{}") ~= nil or string.find(temp, "{{}}") ~= nil then						
    temp = string.gsub(temp, "{}", "[]")
    temp = string.gsub(temp, "{{}}", "[{}]")
    if string.find(temp, "\"address\":%[%]") ~= nil then
      temp = string.gsub(temp, "\"address\":%[%]", "\"address\":{}")
    end
    if string.find(temp, "\"timeStamp\":%[%]") ~= nil then
      temp = string.gsub(temp, "\"timeStamp\":%[%]", "\"timeStamp\":{}")
    end
    self.mobileSession.correlationId = self.mobileSession.correlationId + 1
    cid = self.mobileSession.correlationId
    local msg = 
    {
      serviceType = 7,
      frameInfo = 0,
      rpcType = 0,
      rpcFunctionId = 39,
      rpcCorrelationId = cid,				
      payload = temp
    }
    self.mobileSession:Send(msg)
  else
    -- mobile side: sending SendLocation request
    cid = self.mobileSession:SendRPC("SendLocation", request_params)
  end
  ui_params = CreateUIParameters(request_params)
  if 
  request_params.longitudeDegrees and
  request_params.latitudeDegrees and 
  request_params.address == {} then
    -- hmi side: expect Navigation.SendLocation request
    EXPECT_HMICALL("Navigation.SendLocation", ui_params)
    :Do(function(_,data)
      -- hmi side: sending Navigation.SendLocation response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    :ValidIf(function(_,data)
      if data.params.address then
        commonFunctions:userPrint(31,"Navigation.SendLocation contain address parameter in request when should be omitted")
        return false
      else
        return true
      end
    end)
  else
    -- hmi side: expect Navigation.SendLocation request
    EXPECT_HMICALL("Navigation.SendLocation", ui_params)
    :Do(function(_,data)
      -- hmi side: sending Navigation.SendLocation response
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  end
  -- mobile side: expect SendLocation response
  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})			
end

-- This function sends a request from mobile with INVALID_DATA and verify result on mobile.
local function Verify_INVALID_DATA_Case(self, request_params)
  local temp = json.encode(request_params)
  local cid = 0
  if string.find(temp, "{}") ~= nil or string.find(temp, "{{}}") ~= nil then						
    temp = string.gsub(temp, "{}", "[]")
    temp = string.gsub(temp, "{{}}", "[{}]")
    if string.find(temp, "\"address\":%[%]") ~= nil then
      temp = string.gsub(temp, "\"address\":%[%]", "\"address\":{}")
    end
    self.mobileSession.correlationId = self.mobileSession.correlationId + 1
    cid = self.mobileSession.correlationId
    local msg = 
    {
      serviceType = 7,
      frameInfo = 0,
      rpcType = 0,
      rpcFunctionId = 39,
      rpcCorrelationId = cid,	
      payload = temp
    }
    self.mobileSession:Send(msg)
  else
    -- mobile side: sending SendLocation request
    cid = self.mobileSession:SendRPC("SendLocation", request_params)
  end
  -- mobile side: expect SendLocation response
  EXPECT_RESPONSE(cid, {success = false, resultCode = "INVALID_DATA"})
end

-- This function includes all checks for Float Paramter in Request
local function CheckFloatParameterInRequest(test_name, request, param, boundary, mandatory)
  -- Param is missed
  if mandatory then
    Test[test_name .. "IsMissed_INVALID_DATA"] = function(self)
      local testing_request = CloneTable(request)
      SetValueForParameter(testing_request, param, nil)  
      Verify_INVALID_DATA_Case(self, testing_request)
    end
  else
    Test[test_name .. "IsMissed_SUCCESS"] = function(self)
      local testing_request = CloneTable(request)
      SetValueForParameter(testing_request, param, nil)  
      Verify_SUCCESS_Case(self, testing_request)
    end
  end  

  -- Param value is wrong type: string
	Test[test_name .. "IsWrongDataType_INVALID_DATA"] = function(self)
		local testing_request = CloneTable(request)
		SetValueForParameter(testing_request, param, "123")
    Verify_INVALID_DATA_Case(self, testing_request)
	end

  -- Param value is lower bound value
	Test[test_name .. "IsLowerBound_SUCCESS"] = function(self)
		local testing_request = CloneTable(request)
		SetValueForParameter(testing_request, param, boundary.lowerbound)
    Verify_SUCCESS_Case(self, testing_request)
	end

  -- Param value is upper bound value
	Test[test_name .. "IsUpperBound_SUCCESS"] = function(self)
		local testing_request = CloneTable(request)
		SetValueForParameter(testing_request, param, boundary.upperbound)
    Verify_SUCCESS_Case(self, testing_request)
	end

  -- Param value is out of lower bound value
	Test[test_name .. "IsOutLowerBound_INVALID_DATA"] = function(self)
		local testing_request = CloneTable(request)
		SetValueForParameter(testing_request, param, boundary.lowerbound - 0.0000001)
    Verify_INVALID_DATA_Case(self, testing_request)
	end

  -- Param value is out of upper bound value
	Test[test_name .. "IsOutUpperBound_INVALID_DATA"] = function(self)
		local testing_request = CloneTable(request)
		SetValueForParameter(testing_request, param, boundary.upperbound + 0.0000001)
    Verify_INVALID_DATA_Case(self, testing_request)
	end

  -- Param value is max of float decimal places
	Test[test_name .. "IsMaxFloatDecimalPlaces_SUCCESS"] = function(self)
		local testing_request = CloneTable(request)
		SetValueForParameter(testing_request, param, 0.00000001)
    Verify_SUCCESS_Case(self, testing_request)
	end 
  
end

------------------------------------------------------------------------------------------------------
---------------------------------------Preconditions--------------------------------------------------
------------------------------------------------------------------------------------------------------
-- delete app_info.dat, SmartDeviceLinkCore.log, TransportManager.log, ProtocolFordHandling.log, HmiFrameworkPlugin.log and policy.sqlite
common_functions:DeleteLogsFileAndPolicyTable()

-- replace sdl_preloaded_pt.json by new file with SendLocation is allowed 
Test["Precondition_Replace_Preload"] = function(self)
  -- backup preload
  os.execute(" cp " .. preload_file .. " " .. preload_file .. "_origin" )
  -- create PTU from sdl_preloaded_pt.json
	local data = ConvertPreloadedToJson()
  -- insert API into into "functional_groupings"."Base-4"
  data.policy_table.functional_groupings["Base-4"].rpcs["SendLocation"] = {
    hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
  }  
  -- create preload json file for testing
  CreateJsonFile(data, preload_file)
end

-- start SDL, add connection, add mobile session, register application then activate application
common_steps:PreconditionSteps("Start_SDL_To_Activate_Application", 7)

------------------------------------------------------------------------------------------------------
------------------------------------------Tests-------------------------------------------------------
------------------------------------------------------------------------------------------------------
request = {		
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1
}

-- Main Check: Float parameter longitude in request (without Address)
CheckFloatParameterInRequest("Check_SendLocation_withoutAddress_longitudeDegrees_", 
  request, {"longitudeDegrees"}, boundary_longitude_degrees, true)

-- Main Check: Float parameter latitude in request (without Address)
CheckFloatParameterInRequest("Check_SendLocation_withoutAddress_latitudeDegrees_", 
  request, {"latitudeDegrees"}, boundary_latitude_degrees, true)

request = {		
  longitudeDegrees = 1.1,
  latitudeDegrees = 1.1,
  address = {
    countryName = "countryName"
  }
}

-- Main Check: Float parameter longitude in request (with Address)
CheckFloatParameterInRequest("Check_SendLocation_withAddress_longitudeDegrees_", 
  request, {"longitudeDegrees"}, boundary_longitude_degrees, true)

-- Main Check: Float parameter latitude in request (with Address)
CheckFloatParameterInRequest("Check_SendLocation_withAddress_latitudeDegrees_", 
  request, {"latitudeDegrees"}, boundary_latitude_degrees, true)

------------------------------------------------------------------------------------------------------
------------------------------------Postcondition-----------------------------------------------------
------------------------------------------------------------------------------------------------------
-- restore sdl_preloaded_pt.json
Test["Restore_Preload"] = function(self)
  os.execute(" cp " .. preload_file .. "_origin " .. preload_file)
end

-- Stop SDL
Test["Stop_SDL"] = function(self)
  StopSDL()
end
