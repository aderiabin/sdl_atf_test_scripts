--------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-23626]: [UI.GetCapabilities]: [UI.GetCapabilities] response from HMI and
---- RegisterAppInterface

-- Description:
-- In case:
---- UI module has confirmed to be ready (via response to IsReady RPC)
-- SDL must:
---- request UI capabilities via GetCapabilities request.
-- On getting UI.GetCapabilities response from HMI
-- SDL must:
---- return displayCapabilities, audioPassThruCapabilities, hmiZoneCapabilities,
---- softButtonCapabilities, hmiCapabilities (if some returned by HMI) via
---- RegisterAppInterface response to each mobile application which will have been
---- registered futher.

-- Preconditions:
-- 1. SDL, HMI are initialized, Basic Communication is ready, UI module is ready
-- 2. SDL -> HMI: UI.GetCapabilities
-- 3. After full HMI initialization connection, session and service #7 are initialized

-- Steps:
-- 1. HMI -> SDL: UI.GetCapabilities response with displayCapabilities, audioPassThruCapabilities,
---- hmiZoneCapabilities, softButtonCapabilities, hmiCapabilities.
-- 2. Mob -> SDL: "RegisterAppInterface"

-- Expected result:
-- SDL -> Mob: success = true, resultCode = "SUCCESS", with displayCapabilities,
---- audioPassThruCapabilities, hmiZoneCapabilities, softButtonCapabilities,
---- hmiCapabilities values matching those which were sent from HMI
-- SDL -> HMI: "OnAppRegistered"

-- Postconditions:
-- 1. Application is unregistered on SDL
-- 2. SDL is stopped

-- Notes:
-- 1. In this scipt "user_modules/dummy_connecttest.lua" file is used instead of standard 
---- "connecttest"
-- 2. UI.GetCapabilities are sent from HMI inside function
---- "dummy_connecttest.lua->InitHMI_onReady()" where external "hmi_table"
---- value is passed containing "UI.GetCapabilities" specified expicitly
-- 3. Step #2 and postcondition #1 are repeated for all default RegisterAppInterface params
---- from config.lua
-- 4. "audioPassThruCapabilities" and "hmiZoneCapabilities" in Mobile API are arrays while
---- in HMI API they are structures, so they are checked for presence in arrays via
---- "Find" function in "ValidIf()" function
-- 5. "displayCapabilites.imageCapabilies" aren't present in HMI API, so they are excluded
---- from validation in response
-- 6. "displayCapabilites.textFields" array order in HMI API differs from one in Mobile API,
---- so it's elemenets are checked for presence in the 2nd loop in "ValidIf()" function
---- separately

--------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')
Test = require("user_modules/dummy_connecttest")
hmi_values = require("user_modules/hmi_values")

--[[ Local Variables ]]
local hmi_table = hmi_values.getDefaultHMITable()
hmi_table.UI.GetCapabilities.params = 
{
  displayCapabilities =
  {
    displayType = "GEN2_8_DMA",
    textFields =
    {
      hmi_values.createTextField("mainField1"),
      hmi_values.createTextField("mainField2"),
      hmi_values.createTextField("mainField3"),
      hmi_values.createTextField("mainField4"),
      hmi_values.createTextField("statusBar"),
      hmi_values.createTextField("mediaClock"),
      hmi_values.createTextField("mediaTrack"),
      hmi_values.createTextField("alertText1"),
      hmi_values.createTextField("alertText2"),
      hmi_values.createTextField("alertText3"),
      hmi_values.createTextField("scrollableMessageBody"),
      hmi_values.createTextField("initialInteractionText"),
      hmi_values.createTextField("navigationText1"),
      hmi_values.createTextField("navigationText2"),
      hmi_values.createTextField("ETA"),
      hmi_values.createTextField("totalDistance"),
      hmi_values.createTextField("navigationText"),
      hmi_values.createTextField("audioPassThruDisplayText1"),
      hmi_values.createTextField("audioPassThruDisplayText2"),
      hmi_values.createTextField("sliderHeader"),
      hmi_values.createTextField("sliderFooter"),
      hmi_values.createTextField("notificationText"),
      hmi_values.createTextField("menuName"),
      hmi_values.createTextField("secondaryText"),
      hmi_values.createTextField("tertiaryText"),
      hmi_values.createTextField("timeToDestination"),
      hmi_values.createTextField("turnText"),
      hmi_values.createTextField("menuTitle"),
      hmi_values.createTextField("locationName"),
      hmi_values.createTextField("locationDescription"),
      hmi_values.createTextField("addressLines"),
      hmi_values.createTextField("phoneNumber")
    },
    imageFields =
    {
      hmi_values.createImageField("softButtonImage"),
      hmi_values.createImageField("choiceImage"),
      hmi_values.createImageField("choiceSecondaryImage"),
      hmi_values.createImageField("vrHelpItem"),
      hmi_values.createImageField("turnIcon"),
      hmi_values.createImageField("menuIcon"),
      hmi_values.createImageField("cmdIcon"),
      hmi_values.createImageField("showConstantTBTIcon"),
      hmi_values.createImageField("locationImage")
    },
    mediaClockFormats =
    {
      "CLOCK1",
      "CLOCK2",
      "CLOCK3",
      "CLOCKTEXT1",
      "CLOCKTEXT2",
      "CLOCKTEXT3",
      "CLOCKTEXT4"
    },
    graphicSupported = true,
    imageCapabilities = { "DYNAMIC", "STATIC" },
    templatesAvailable = { "TEMPLATE" },
    screenParams =
    {
      resolution = { resolutionWidth = 800, resolutionHeight = 480 },
      touchEventAvailable =
      {
        pressAvailable = true,
        multiTouchAvailable = true,
        doublePressAvailable = false
      }
    },
    numCustomPresetsAvailable = 10
  },
  audioPassThruCapabilities =
  {
    samplingRate = "44KHZ",
    bitsPerSample = "8_BIT",
    audioType = "PCM"
  },
  hmiZoneCapabilities = "FRONT",
  softButtonCapabilities =
  {
    {
      shortPressAvailable = true,
      longPressAvailable = true,
      upDownAvailable = true,
      imageSupported = true
    }
  },
  hmiCapabilities = { navigation = true, phoneCall = true }
}

---------------------------------------------------------------------------------------------
--[[ Preconditions-1]]
common_steps:AddNewTestCasesGroup("Preconditions Before HMI Response")
common_steps:PreconditionSteps("Precondition", 2)

common_steps:AddNewTestCasesGroup("HMI Response with external UI Capabilities")

--[[ Preconditions-2]]
--[[ Test-1]]
function Test:InitHMI_onReady()
  self:initHMI_onReady(hmi_table)
end

--[[ Preconditions-3]]
common_steps:AddNewTestCasesGroup("Preconditions After HMI Response")
common_steps:AddMobileConnection("Precondition_AddMobileConnection")
common_steps:AddMobileSession("Precondition_AddMobileSession")

--[[ Test-2]]
common_steps:AddNewTestCasesGroup("Verify UI Capabilities passed to mobile after RegisterAppInterface request\n" ..
  "for each mobile application registered further" )
local i = 1
while config["application" .. i] do
  local rai_params = config["application" .. i].registerAppInterfaceParams

  Test["RegisterAppInterface_UI_GetCapabilities_Application_" .. i] = function(self)
    local cor_id = self.mobileSession:SendRPC("RegisterAppInterface", rai_params)

    self.mobileSession:ExpectResponse(cor_id, { success = true, resultCode = "SUCCESS" })
    :ValidIf(function(_, data)
        local result = true
        local text_fields_expected = {}
        local text_fields_actual = {}
        for k, v in pairs(hmi_table.UI.GetCapabilities.params) do
          if k == "displayCapabilities" then
            text_fields_expected = common_functions:CloneTable(v.textFields)
            v.imageCapabilities = nil
            v.textFields = nil
            text_fields_actual = common_functions:CloneTable(data.payload[k].textFields)
            data.payload[k].textFields = nil
          end
          if not common_functions:Find(v, data.payload[k]) then
            result = false
            common_functions:PrintError("Value received by Mobile doesn't match the value sent from HMI: " .. k)
          end
        end
        
        for i = 1, #text_fields_expected do
          if not common_functions:Find(text_fields_expected[i], text_fields_actual) then
            result = false
            common_functions:PrintError("Value sent from HMI is absent in response to Mobile: " .. text_fields_expected[i].name)
          end
        end
        return result
      end)
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
  end

  --[[ Postconditions-1]]
  Test["Postcondition_UnregisterApplication_" .. i] = function(self)
    local cor_id = self.mobileSession:SendRPC("UnregisterAppInterface", {})
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { appID = self.applications[app_name], unexpectedDisconnect = false })
    self.mobileSession:ExpectResponse(cor_id, { success = true, resultCode = "SUCCESS"})
  end

  i = i + 1
end

---------------------------------------------------------------------------------------------
--[[ Postconditions-2]]
common_steps:AddNewTestCasesGroup("Postcondition")
common_steps:StopSDL("Postcondition_StopSDL")
