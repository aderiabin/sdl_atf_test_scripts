--------------------------------------------------------------------------------------------
-- Requirement summary:
--[APPLINK-23087]: [RegisterAppInterface]: SDL must return value of "pcmStreamCapabilities"
-- param at response to mobile app

-- Description:
-- In case:
---- any mobile app sends "RegisterAppInterface" request to SDL and this registration is
---- successful
-- SDL must:
---- retrieve values of "samplingRate", "bitsPerSample", "audioType" params from
---- "pcmStreamCapabilities" struct at "HMI_capabilities.json" file provide these values via
---- "pcmStreamCapabilities" parameter at RegisterAppInterface_response with other related
---- to this RPC params

-- Preconditions:
-- 1. Possible valid values of "pcmStreamCapabilities" are read from "MOBILE_API.xml" file
-- 2. Correct values for "pcmStreamCapabilities" are strored in "HMI_capabilities.json" file
-- 3. SDL, HMI are initialized, connection, session and service #7 are initialized for the
---- application
-- 4. The request "RegisterAppInterface" is intended to be sent from mobile applicaton

-- Steps:
-- 1. Mob -> SDL: "RegisterAppInterface"

-- Expected result:
-- SDL -> Mob: success = true, resultCode = "SUCCESS", "pcmStreamCapabilities" match ones
---- stored in "HMI_capabilities.json"
-- SDL -> HMI: "OnAppRegistered"

-- Postconditions:
-- 1. Application is unregistered on SDL
-- 2. SDL is stopped
-- 3. "HMI_capabilities.json" file is restored to original state

-- Note:
-- Preconditions 2-4, step 1 and postconditions 1-2 are repeated and specified result is
---- expected for each possible combination of valid "pcmStreamCapabilities"

--------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')
local utils = require('user_modules/utils')

--[[ Local Variables ]]
local rai_params = config.application1.registerAppInterfaceParams
local app_name = const.default_app_name
local hmi_caps_file_name = "hmi_capabilities.json"
local full_file_name = config.pathToSDL .. hmi_caps_file_name

local sampling_rates = utils.GetEnumFromMobileApi("SamplingRate")
local bit_rates = utils.GetEnumFromMobileApi("BitsPerSample")
local audio_types = utils.GetEnumFromMobileApi("AudioType")

local capabilities = {}
for i_sampl = 1, #sampling_rates do
  for i_bps = 1, #bit_rates do
    for i_type = 1, #audio_types do
      table.insert(capabilities, {
        samplingRate = sampling_rates[i_sampl],
        bitsPerSample = bit_rates[i_bps],
        audioType = audio_types[i_type]
      })
    end
  end
end

--[[ Local Functions ]]
-- Changes pcmSreamCapabilites format into internal one which is used in
-- "hmi_capabilities.json" file (addes prefix to values starting from
-- a digit)
-- @param caps - capabilities table to be processed
local function MakeCapsInternal(caps)
  local int_prefix = "RATE_"
  for k, v in pairs(caps) do
    if tonumber(string.sub(v, 1, 1)) then
      caps[k] = int_prefix .. v
    end
  end
end

-- Checks if received pcmStreamCapability matchs one stored in JSON file
--(some of stored capabilies may have a prefix like "RATE_")
-- @param actual - actual value received in responce RPC
-- @param expected - expected value stored in JSON file
-- Example: CapabilityMatches("8_BIT", "RATE_8_BIT") --> true
local function CapabilityMatches(actual, expected)
  if actual == expected then
    return true
  end
  actual = "_" .. actual
  local string_end = string.sub(expected, -string.len(actual))
  return actual == string_end
end

---------------------------------------------------------------------------------------------
--[[ General Precondition before ATF start ]]
common_steps:AddNewTestCasesGroup('Precondition: Backup of "HMI_capabilities.json"')
function Test:Precondition_BackupFile()
  common_functions:BackupFile(hmi_caps_file_name)
end

common_steps:AddNewTestCasesGroup("Verify pcmStreamCapabilities received for all valid values after RegisterAppInterface request")

for i = 1, #capabilities do
  local sampling_rate = capabilities[i]["samplingRate"]
  local bit_rate = capabilities[i]["bitsPerSample"]
  local audio_type = capabilities[i]["audioType"]

  MakeCapsInternal(capabilities[i])

  --[[ Preconditions ]]
  local test_name_postfix = "pcmStreamCapabilities_" .. sampling_rate .. "_" .. bit_rate .. "_" .. audio_type
  Test["Precondition_PutValuesIntoJson_" .. test_name_postfix] = function(self)
    common_functions:AddItemsIntoJsonFile(full_file_name, { "UI", "pcmStreamCapabilities" }, capabilities[i])
  end

  common_steps:PreconditionSteps("Precondition", 5)

  --[[ Test ]]
  Test["RegisterAppInterface_AreReceived_" .. test_name_postfix] = function(self)
    common_functions:UserPrint(const.color.cyan, "pcmStreamCapabilities: samplingRate = " .. sampling_rate ..
      ", bitsPerSample = " .. bit_rate .. ", audioType = " .. audio_type)
    local cor_id = self.mobileSession:SendRPC("RegisterAppInterface", rai_params)
    
    self.mobileSession:ExpectResponse(cor_id, { success = true, resultCode = "SUCCESS" })
    :ValidIf(function(_, data)
      local received_caps = data.payload.pcmStreamCapabilities
      if not received_caps then
        return false
      end
      for k, v in pairs(received_caps) do
        if not CapabilityMatches(v, capabilities[i][k]) then
          return false
        end
      end
      return true
    end)
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
  end

  --[[ Postconditions ]]
  Test["Postcondition_UnregisterApplication"] = function(self)
    local cor_id = self.mobileSession:SendRPC("UnregisterAppInterface",{})
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { appID = self.applications[app_name], unexpectedDisconnect = false })
    self.mobileSession:ExpectResponse(cor_id, { success = true, resultCode = "SUCCESS"})
  end
  common_steps:StopSDL("Postcondition_StopSDL_")
end

---------------------------------------------------------------------------------------------
--[[ General Postcondition]]
common_steps:AddNewTestCasesGroup('Postcondition: Restore of "HMI_capabilities.json"')
function Test:Postcondition_RestoreFile()
  common_functions:RestoreFile(hmi_caps_file_name, true)
end
