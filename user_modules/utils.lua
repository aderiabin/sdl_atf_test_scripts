local module = {}

local api_loader = require('modules/api_loader')
local mobile_api = api_loader.init("data/MOBILE_API.xml")
local interface_schema = mobile_api.interface["Ford Sync RAPI"]

--! @brief Function which returnes unordered key set from any table
--! @param table - table from which we are going to get keys
function module.GetUnorderedTableKeyset(table)
  local keyset={}
  local n = 0

  for k,v in pairs(table) do
    n=n+1
    keyset[n]=k
  end
  return keyset
end

--! @brief Function converts time in TZ format to epoch seconds
--! @param tz_date - date in TZ format
--! @return value - value in epoch seconds
--! @usage Function usage example: epoch_seconds = module.ConvertTZDateToEpochSeconds("2017-02-13T19:28:19Z")
function module.ConvertTZDateToEpochSeconds(tz_date)
  local tz_table = {year = 0, month = 0, day = 0, hour = 0, min = 0, sec = 0}
  local keyset = {"year", "month", "day", "hour", "min", "sec"}
  local count = 1
  for element in string.gmatch(tz_date,'%d+') do
    tz_table[keyset[count]] = element
    count = count + 1
  end
  return os.time(tz_table)
end

--! @brief Allows to get struct value from any mobile api struct
--! @param struct_name - name of needed struct
--! @param param_name - struct parameter
--! @param value_to_read - value which is needed to be read
--! @usage Function usage example: maxvalueMenuParams = module.GetStructValueFromMobileApi( "MenuParams", "parentID", "maxvalue")
function module.GetStructValueFromMobileApi(struct_name, param_name, value_to_read)
  if not interface_schema.struct[struct_name] then
    print ("\27[31mError : \27[0m")
    print ("\27[31mStruct with name: \27[0m" .. struct_name .." \27[31mdoes not exist\27[0m")
    return
  end
  if not interface_schema.struct[struct_name].param[param_name] then
    print ("\27[31mError : \27[0m")
    print ("\27[31mParam with name: \27[0m" .. param_name .." \27[31mdoes not exist in structure: \27[0m" .. struct_name)
    return
  end
  return interface_schema.struct[struct_name].param[param_name][value_to_read]
end

--! @brief Function allows to get any enum size(number of elements) from mobile api
--! @param enum_name - enum name which size we are going to get
--! @param Function usage example: maxlength = enum_size = module.GetEnumSizeFromMobileApi("AppInterfaceUnregisteredReason")
function module.GetEnumSizeFromMobileApi(enum_name)
  if not interface_schema.enum[enum_name] then
    print ("\27[31mError : \27[0m")
    print ("\27[31mEnum with name: \27[0m" .. enum_name .." \27[31mdoes not exist\27[0m")
    return
  end
  return #module.GetUnorderedTableKeyset(interface_schema.enum[enum_name])
end

--! @brief Function allows to get value from any mobile api function
--! @param function_type - request, response or notification
--! @param function_name - name of the function
--! @param param_name - function parameter
--! @param value_to_read - value which is needed to be read
--! @param Function usage example: maxlength = module.GetFunctionValueFromMobileApi("request", "Show", "mainField2", "maxlength")
function module.GetFunctionValueFromMobileApi(function_type, function_name, param_name, value_to_read)
  if not interface_schema.type[function_type] then
    print ("\27[31mError : \27[0m")
    print ("\27[31mFunction with type: \27[0m" .. function_type .." \27[31mdoes not exist\27[0m")
    return
  end
  if not interface_schema.type[function_type].functions[function_name] then
    print ("\27[31mError : \27[0m")
    print ("\27[31mFunction with name: \27[0m" .. function_name .." \27[31mdoes not exist\27[0m")
    return
  end
  if not interface_schema.type[function_type].functions[function_name].param[param_name] then
    print ("\27[31mError : \27[0m")
    print ("\27[31mParameter with name: \27[0m" .. param_name .." \27[31mdoes not exist in function\27[0m " .. function_name)
    return
  end
  return interface_schema.type[function_type].functions[function_name].param[param_name][value_to_read]
end

return module
