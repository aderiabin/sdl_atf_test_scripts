------------------------------------------------------------------------------------------------------
------------------------------------General Settings for Configuration--------------------------------
------------------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

------------------------------------------------------------------------------------------------------
---------------------------------------Common Variables-----------------------------------------------
------------------------------------------------------------------------------------------------------
local preload_file = config.pathToSDL .. "sdl_preloaded_pt.json"
local response
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

-- Create default request parameters
local function CreateRequest()
  return {
    wayPointType = "ALL"
  }
end

-- Create default response
local function CreateResponse()
  local response ={}
  response["wayPoints"] =
    {{
      coordinate =
      {
        latitudeDegrees = 1.1,
        longitudeDegrees = 1.1
      },
      locationName = "Hotel",
      addressLines =
      {
        "Hotel Bora",
        "Hotel 5 stars"
      },
      locationDescription = "VIP Hotel",
      phoneNumber = "Phone39300434",
      locationImage =
      {
        value ="icon.png",
        imageType ="DYNAMIC",
      },
      searchAddress =
      {
        countryName = "countryName",
        countryCode = "countryCode",
        postalCode = "postalCode",
        administrativeArea = "administrativeArea",
        subAdministrativeArea = "subAdministrativeArea",
        locality = "locality",
        subLocality = "subLocality",
        thoroughfare = "thoroughfare",
        subThoroughfare = "subThoroughfare"
      }
  } }
  return response
end

-- This function is used to send default request and response with specific invalid data and verify GENERIC_ERROR resultCode
local function Verify_GENERIC_ERROR_Response_Case(self, response)
  -- mobile side: sending the request
  local request = CreateRequest()
  local cid = self.mobileSession:SendRPC("GetWayPoints", request)
  request.appID = self.applications[config.application1.registerAppInterfaceParams.appName]
  -- hmi side: expect Navigation.GetWayPoints request
  EXPECT_HMICALL("Navigation.GetWayPoints", request)
  :Do(function(_,data)
    -- hmi side: sending response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)
  end)
  -- mobile side: expect the response
  EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from vehicle" })
  :Timeout(11000)
end

-- This function is used to send default request and response with specific valid data and verify SUCCESS resultCode
function Verify_SUCCESS_Response_Case(self, response)
  -- mobile side: sending the request
  local request = CreateRequest()
  local cid = self.mobileSession:SendRPC("GetWayPoints", request)
  request.appID = self.applications[config.application1.registerAppInterfaceParams.appName]
  -- hmi side: expect Navigation.GetWayPoints request
  EXPECT_HMICALL("Navigation.GetWayPoints", request)
  :Do(function(_,data)
    -- hmi side: sending response
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)
  end)
  -- mobile side: expect the response
  EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
end

-- This function includes all checks for Float Paramter in Response
local function CheckFloatParameterInResponse(test_name, response, param, boundary, mandatory)
  -- Param is missed
  if mandatory then
    Test[test_name .. "IsMissed_GENERIC_ERROR"] = function(self)
      local testing_response = CloneTable(response)
      SetValueForParameter(testing_response, param, nil)  
      Verify_GENERIC_ERROR_Response_Case(self, testing_response)
    end
  else
    Test[test_name .. "IsMissed_SUCCESS"] = function(self)
      local testing_response = CloneTable(response)
      SetValueForParameter(testing_response, param, nil)   
      Verify_SUCCESS_Response_Case(self, testing_response)
    end
	end

  -- Param value is wrong type: string
	Test[test_name .. "IsWrongDataType_GENERIC_ERROR"] = function(self)
		local testing_response = CloneTable(response)
		SetValueForParameter(testing_response, param, "123")
    Verify_GENERIC_ERROR_Response_Case(self, testing_response)
	end

  -- Param value is lower bound value
	Test[test_name .. "IsLowerBound_SUCCESS"] = function(self)
		local testing_response = CloneTable(response)
		SetValueForParameter(testing_response, param, boundary.lowerbound)
    Verify_SUCCESS_Response_Case(self, testing_response)
	end

  -- Param value is upper bound value
	Test[test_name .. "IsUpperBound_SUCCESS"] = function(self)
		local testing_response = CloneTable(response)
		SetValueForParameter(testing_response, param, boundary.upperbound)
    Verify_SUCCESS_Response_Case(self, testing_response)
	end

  -- Param value is out of lower bound value
	Test[test_name .. "IsOutLowerBound_GENERIC_ERROR"] = function(self)
		local testing_response = CloneTable(response)
		SetValueForParameter(testing_response, param, boundary.lowerbound - 0.0000001)
    Verify_GENERIC_ERROR_Response_Case(self, testing_response)
	end

  -- Param value is out of upper bound value
	Test[test_name .. "IsOutUpperBound_GENERIC_ERROR"] = function(self)
		local testing_response = CloneTable(response)
		SetValueForParameter(testing_response, param, boundary.upperbound + 0.0000001)
    Verify_GENERIC_ERROR_Response_Case(self, testing_response)
	end

  -- Param value is max of float decimal places
	Test[test_name .. "IsMaxFloatDecimalPlaces_SUCCESS"] = function(self)
		local testing_response = CloneTable(response)
		SetValueForParameter(testing_response, param, 0.00000001)
    Verify_SUCCESS_Response_Case(self, testing_response)
	end 
  
end

------------------------------------------------------------------------------------------------------
---------------------------------------Preconditions--------------------------------------------------
------------------------------------------------------------------------------------------------------
-- delete app_info.dat, SmartDeviceLinkCore.log, TransportManager.log, ProtocolFordHandling.log, HmiFrameworkPlugin.log and policy.sqlite
common_functions:DeleteLogsFileAndPolicyTable()

-- replace sdl_preloaded_pt.json by new file with GetWayPoints is allowed 
Test["Precondition_Replace_Preload"] = function(self)
  -- backup preload
  os.execute(" cp " .. preload_file .. " " .. preload_file .. "_origin" )
  -- create PTU from sdl_preloaded_pt.json
	local data = ConvertPreloadedToJson()
  -- insert API into into "functional_groupings"."Base-4"
  data.policy_table.functional_groupings["Base-4"].rpcs["GetWayPoints"] = {
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
response = CreateResponse()

-- Main Check: Float parameter longitude 
CheckFloatParameterInResponse("Check_GetWayPoints_longitudeDegrees_", response, 
  {"wayPoints", 1, "coordinate", "longitudeDegrees"}, boundary_longitude_degrees, true)

  -- Main Check: Float parameter latitude 
CheckFloatParameterInResponse("Check_GetWayPoints_latitudeDegrees_", response, 
  {"wayPoints", 1, "coordinate", "latitudeDegrees"}, boundary_latitude_degrees, true)

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
