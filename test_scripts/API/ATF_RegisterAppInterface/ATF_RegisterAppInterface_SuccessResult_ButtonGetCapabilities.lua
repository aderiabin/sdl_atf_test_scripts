-- Requirements: [APPLINK-24325]:[Buttons.GetCapabilities] response from HMI and RegisterAppInterface

-- Description:
-- In case after SDL startup HMI provides valid successful ButtonsGetCapabilities_response.
-- SDL must provide this once-obtained buttons capabilities information to each and every application
-- via RegisterAppInterface rpc in the current ignition cycle. 

-- Preconditions:
-- 1. Init function button_capability, which is the same as in connectest.lua and describe
-- value buttons_capabilities.
-- 2. Run following functions: StartSDL, InitHMI, InitHMI_onReady, AddDefaultMobileConnection,
-- AddDefaultMobileConnect

-- Steps:
-- 1. Mobile app sends RegisterAppInterface rpc
-- 2. HMI -> SDL: Buttons.GetCapabilities
-- 3. Check buttons_capabilities = Buttons.GetCapabilities

-- Expected result:
-- SDL -> Mob: {success = true, button_capabilities = buttonCapabilities}

-- ------------------------------------------Required Resources---------------------------------
require('user_modules/all_common_modules')
-- -------------------------------------------Preconditions-------------------------------------
--This function determine boolean value false in case there are no action or no capabilities for
--button and value true otherwise.
local function button_capability(name, shortPressAvailable, longPressAvailable, upDownAvailable)
  return
  {
    name = name,
    shortPressAvailable = shortPressAvailable == nil or shortPressAvailable,
    longPressAvailable = longPressAvailable == nil or longPressAvailable,
    upDownAvailable = upDownAvailable == nil or upDownAvailable
  }
end

local buttons_capabilities =
{
    button_capability("PRESET_0"),
    button_capability("PRESET_1"),
    button_capability("PRESET_2"),
    button_capability("PRESET_3"),
    button_capability("PRESET_4"),
    button_capability("PRESET_5"),
    button_capability("PRESET_6"),
    button_capability("PRESET_7"),
    button_capability("PRESET_8"),
    button_capability("PRESET_9"),
    button_capability("OK", true, false, true),
    button_capability("SEEKLEFT"),
    button_capability("SEEKRIGHT"),
    button_capability("TUNEUP"),
    button_capability("TUNEDOWN")
}
common_steps:PreconditionSteps("Preconditions", 5)
-- -----------------------------------------------Body------------------------------------------
--Value buttonCapabilities we get in step RegisterAppInterface when SDL send this array to Mobile side
function Test:RegisterAppInterface()
  local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  EXPECT_RESPONSE(correlationId, {success = true, buttonCapabilities = buttons_capabilities, presetBankCapabilities = {onScreenPresetsAvailable = true }})
  :Do(function(_, data)
      EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    end)
  EXPECT_NOTIFICATION("OnPermissionsChange")
end
-- -------------------------------------------Postcondition-------------------------------------
common_steps:StopSDL("StopSDL")
