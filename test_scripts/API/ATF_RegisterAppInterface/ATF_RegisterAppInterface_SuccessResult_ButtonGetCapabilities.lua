--------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-24325]: [Buttons.GetCapabilities] response from HMI and RegisterAppInterface

-- Description:
-- In case:
---- after SDL startup HMI provides valid successful ButtonsGetCapabilities_response.
-- SDL must:
---- provide this once-obtained buttons capabilities information to each and every application
---- via RegisterAppInterface rpc in the current ignition cycle. 

-- Preconditions:
-- 1. SDL, HMI are initialized, Basic Communication is ready
-- 2. SDL -> HMI: Buttons.GetCapabilities
-- 3. After full HMI initialization connection, session and service #7 are initialized

-- Steps:
-- 1. HMI -> SDL: Buttons.GetCapabilities response with capabilities and presetBankCapabilities
-- 2. Mob -> SDL: "RegisterAppInterface"

-- Expected result:
-- SDL -> Mob: success = true, resultCode = "SUCCESS", with buttonCapabilities and
---- presetBankCapabilities matching those which were sent from HMI
-- SDL -> HMI: "OnAppRegistered"

-- Postconditions:
-- 1. Application is unregistered on SDL
-- 2. SDL is stopped

-- Notes:
-- 1. In this scipt "user_modules/dummy_connecttest.lua" file is used instead of standard 
---- "connecttest"
-- 2. Buttons.GetCapabilities are sent from HMI inside function
---- "dummy_connecttest.lua->InitHMI_onReady()" where external "hmi_table"
---- value is passed containing "Buttons.GetCapabilities" specified explicitly
-- 3. Step #2 and postcondition #1 are repeated for all default RegisterAppInterface params
---- from config.lua
-- 4. "capabilities" param in HMI response corresponds "buttonCapabilities" param
---- in RegisterAppInterface response to Mobile

--------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')
Test = require("user_modules/dummy_connecttest")
hmi_values = require("user_modules/hmi_values")

--[[ Local Variables ]]
local hmi_table = hmi_values.getDefaultHMITable()
hmi_table.Buttons.GetCapabilities.params =
{
  capabilities =
  {
    hmi_values.createButtonCapability("PRESET_0"),
    hmi_values.createButtonCapability("PRESET_1"),
    hmi_values.createButtonCapability("PRESET_2"),
    hmi_values.createButtonCapability("PRESET_3"),
    hmi_values.createButtonCapability("PRESET_4"),
    hmi_values.createButtonCapability("PRESET_5"),
    hmi_values.createButtonCapability("PRESET_6"),
    hmi_values.createButtonCapability("PRESET_7"),
    hmi_values.createButtonCapability("PRESET_8"),
    hmi_values.createButtonCapability("PRESET_9"),
    hmi_values.createButtonCapability("OK", true, false, true),
    hmi_values.createButtonCapability("SEEKLEFT"),
    hmi_values.createButtonCapability("SEEKRIGHT"),
    hmi_values.createButtonCapability("TUNEUP"),
    hmi_values.createButtonCapability("TUNEDOWN")
  },
  presetBankCapabilities = { onScreenPresetsAvailable = true }
}

---------------------------------------------------------------------------------------------
--[[ Preconditions-1 ]]
common_steps:AddNewTestCasesGroup("Preconditions Before HMI Response")
common_steps:PreconditionSteps("Precondition", 2)

common_steps:AddNewTestCasesGroup("HMI Response with external Button Capabilities")

--[[ Preconditions-2]]
--[[ Test-1]]
function Test:InitHMI_onReady()
  self:initHMI_onReady(hmi_table)
end

--[[ Preconditions-2]]
common_steps:AddNewTestCasesGroup("Preconditions After HMI Response")
common_steps:AddMobileConnection("Precondition_AddMobileConnection")
common_steps:AddMobileSession("Precondition_AddMobileSession")

--[[ Test-2 ]]
common_steps:AddNewTestCasesGroup("Verify Button Capabilities passed to mobile after RegisterAppInterface request\n" ..
  "for each mobile application registered further" )
local i = 1
while config["application" .. i] do
  local rai_params = config["application" .. i].registerAppInterfaceParams

  Test["RegisterAppInterface_Button_GetCapabilities_Application_" .. i] = function(self)
    local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
    EXPECT_RESPONSE(correlationId, {
      success = true,
      buttonCapabilities = hmi_table.Buttons.GetCapabilities.params.capabilities,
      presetBankCapabilities = hmi_table.Buttons.GetCapabilities.params.presetBankCapabilities
    })
    :Do(function(_, data)
        EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
      end)
    EXPECT_NOTIFICATION("OnPermissionsChange")
  end

  --[[ Postconditions-1 ]]
  Test["Postcondition_UnregisterApplication_" .. i] = function(self)
    local cor_id = self.mobileSession:SendRPC("UnregisterAppInterface", {})
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { appID = self.applications[app_name], unexpectedDisconnect = false })
    self.mobileSession:ExpectResponse(cor_id, { success = true, resultCode = "SUCCESS"})
  end

  i = i + 1
end

---------------------------------------------------------------------------------------------
--[[ Postconditions-2 ]]
common_steps:AddNewTestCasesGroup("Postcondition")
common_steps:StopSDL("Postcondition_StopSDL")
