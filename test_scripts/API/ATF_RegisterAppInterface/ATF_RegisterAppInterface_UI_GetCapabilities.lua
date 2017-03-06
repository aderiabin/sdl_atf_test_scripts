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
-- 1. SDL, HMI are initialized, Basic Comunication is ready, UI module is ready.
-- 2. SDL is going to request UI capabilities via UI.GetCapabilities.
-- 3. After full HMI initialization connection, session and service #7 are initialized
-- 4. The request "RegisterAppInterface" is intended to be sent from mobile applicaton

-- Steps:
-- 1. SDL -> HMI: UI.GetCapabilities
-- 2. HMI checks the UI capabilities
-- 3. HMI -> SDL: UI.GetCapabilities response.
-- 4. Mob -> SDL: "RegisterAppInterface"

-- Expected result:
-- HMI -> SDL: UI.GetCapabilities with displayCapabilities, audioPassThruCapabilities,
---- hmiZoneCapabilities, softButtonCapabilities, hmiCapabilities
-- SDL -> Mob: success = true, resultCode = "SUCCESS", with displayCapabilities,
---- audioPassThruCapabilities, hmiZoneCapabilities, softButtonCapabilities,
---- hmiCapabilities values matching those which were sent from HMI
-- SDL -> HMI: "OnAppRegistered"

-- Postconditions:
-- 1. Application is unregistered on SDL
-- 2. SDL is stopped

-- Notes:
-- 1. UI.GetCapabilities are sent from HMI inside function
---- InitHMI_onReady_External_UI_Capabilities() which was copied from
---- "connecttest.lua->InitHMI_onReady()" but using external "ui_capabilities" value, also
---- local functions for tables generation were extracted from it.
---- This should be refactored after refactoring of connecttest.lua is completed
---- [APPLINK-33131]
-- 2. Step #4 and postcondition #1 are repeated for all default RegisterAppInterface params
---- from config.lua
-- 3. "audioPassThruCapabilities" and "hmiZoneCapabilities" in Mobile API are arrays while
---- in HMI API they are structures, so they are checked for presence in arrays via
---- "Find" function in "ValidIf()" function
-- 4. "displayCapabilites.imageCapabilies" aren't present in HMI API, so they are excluded
---- from validation in response
-- 5. "displayCapabilites.textFields" array order in HMI API differs from one in Mobile API,
---- so it's elemenets are checked for presence in the 2nd loop in "ValidIf()" function
---- separately

--------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

--[[ Local Functions ]]
-- Function for textField generation copied from connecttest.lua->InitHMI_onReady()"
local function CreateTextField(name, characterSet, width, rows)
  return
  {
    name = name,
    characterSet = characterSet or "TYPE2SET",
    width = width or 500,
    rows = rows or 1
  }
end

-- Function for imageField generation copied from connecttest.lua->InitHMI_onReady()"
local function CreateImageField(name, width, height)
  return
  {
    name = name,
    imageTypeSupported =
    {
      "GRAPHIC_BMP",
      "GRAPHIC_JPEG",
      "GRAPHIC_PNG"
    },
    imageResolution =
    {
      resolutionWidth = width or 64,
      resolutionHeight = height or 64
    }
  }
end

--[[ Local Variables ]]
local ui_capabilities = {
  displayCapabilities =
  {
    displayType = "GEN2_8_DMA",
    textFields =
    {
      CreateTextField("mainField1"),
      CreateTextField("mainField2"),
      CreateTextField("mainField3"),
      CreateTextField("mainField4"),
      CreateTextField("statusBar"),
      CreateTextField("mediaClock"),
      CreateTextField("mediaTrack"),
      CreateTextField("alertText1"),
      CreateTextField("alertText2"),
      CreateTextField("alertText3"),
      CreateTextField("scrollableMessageBody"),
      CreateTextField("initialInteractionText"),
      CreateTextField("navigationText1"),
      CreateTextField("navigationText2"),
      CreateTextField("ETA"),
      CreateTextField("totalDistance"),
      CreateTextField("navigationText"),
      CreateTextField("audioPassThruDisplayText1"),
      CreateTextField("audioPassThruDisplayText2"),
      CreateTextField("sliderHeader"),
      CreateTextField("sliderFooter"),
      CreateTextField("notificationText"),
      CreateTextField("menuName"),
      CreateTextField("secondaryText"),
      CreateTextField("tertiaryText"),
      CreateTextField("timeToDestination"),
      CreateTextField("turnText"),
      CreateTextField("menuTitle"),
      CreateTextField("locationName"),
      CreateTextField("locationDescription"),
      CreateTextField("addressLines"),
      CreateTextField("phoneNumber")
    },
    imageFields =
    {
      CreateImageField("softButtonImage"),
      CreateImageField("choiceImage"),
      CreateImageField("choiceSecondaryImage"),
      CreateImageField("vrHelpItem"),
      CreateImageField("turnIcon"),
      CreateImageField("menuIcon"),
      CreateImageField("cmdIcon"),
      CreateImageField("showConstantTBTIcon"),
      CreateImageField("locationImage")
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
      resolution = { resolutionWidth = 200, resolutionHeight = 100 },
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
--[[ Preconditions ]]
common_steps:AddNewTestCasesGroup("Preconditions Before HMI Response")
common_steps:PreconditionSteps("Precondition", 2)

common_steps:AddNewTestCasesGroup("HMI Response with external UI Capabilities")

--[[ Preconditions ]]
--[[ Test ]]
function Test:InitHMI_onReady_External_UI_Capabilities()
  local function ExpectRequest(name, mandatory, params)
    local event = events.Event()
    event.level = 2
    event.matches = function(self, data) return data.method == name end
    return
    EXPECT_HMIEVENT(event, name)
    :Times(mandatory and 1 or AnyNumber())
    :Do(function(_, data)
        xmlReporter.AddMessage("hmi_connection", "SendResponse",
          {
            ["methodName"] = tostring(name),
            ["mandatory"] = mandatory,
            ["params"]= params
          })
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", params)
      end)
  end

  local function ExpectNotification(name, mandatory)
    xmlReporter.AddMessage(debug.getinfo(1, "n").name, tostring(name))
    local event = events.Event()
    event.level = 2
    event.matches = function(self, data) return data.method == name end
    return
    EXPECT_HMIEVENT(event, name)
    :Times(mandatory and 1 or AnyNumber())
  end

  ExpectRequest("BasicCommunication.MixingAudioSupported",
    true,
    { attenuatedSupported = true })
  ExpectRequest("BasicCommunication.GetSystemInfo", false,
    {
      ccpu_version = "ccpu_version",
      language = "EN-US",
      wersCountryCode = "wersCountryCode"
    })
  ExpectRequest("UI.GetLanguage", true, { language = "EN-US" })
  ExpectRequest("VR.GetLanguage", true, { language = "EN-US" })
  ExpectRequest("TTS.GetLanguage", true, { language = "EN-US" })
  ExpectRequest("UI.ChangeRegistration", false, { }):Pin()
  ExpectRequest("TTS.SetGlobalProperties", false, { }):Pin()
  ExpectRequest("BasicCommunication.UpdateDeviceList", false, { }):Pin()
  ExpectRequest("VR.ChangeRegistration", false, { }):Pin()
  ExpectRequest("TTS.ChangeRegistration", false, { }):Pin()
  ExpectRequest("VR.GetSupportedLanguages", true, {
      languages = {
        "EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU",
        "TR-TR","PL-PL","FR-FR","IT-IT","SV-SE","PT-PT","NL-NL",
        "ZH-TW","JA-JP","AR-SA","KO-KR","PT-BR","CS-CZ","DA-DK",
        "NO-NO","NL-BE","EL-GR","HU-HU","FI-FI","SK-SK" }
    })
  ExpectRequest("TTS.GetSupportedLanguages", true, {
      languages = {
        "EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU",
        "TR-TR","PL-PL","FR-FR","IT-IT","SV-SE","PT-PT","NL-NL",
        "ZH-TW","JA-JP","AR-SA","KO-KR","PT-BR","CS-CZ","DA-DK",
        "NO-NO","NL-BE","EL-GR","HU-HU","FI-FI","SK-SK" }
    })
  ExpectRequest("UI.GetSupportedLanguages", true, {
      languages = {
        "EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU",
        "TR-TR","PL-PL","FR-FR","IT-IT","SV-SE","PT-PT","NL-NL",
        "ZH-TW","JA-JP","AR-SA","KO-KR","PT-BR","CS-CZ","DA-DK",
        "NO-NO","NL-BE","EL-GR","HU-HU","FI-FI","SK-SK" }
    })
  ExpectRequest("VehicleInfo.GetVehicleType", true, {
      vehicleType =
      {
        make = "Ford",
        model = "Fiesta",
        modelYear = "2013",
        trim = "SE"
      }
    })
  ExpectRequest("VehicleInfo.GetVehicleData", true, { vin = "52-452-52-752" })

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
    capabilities =
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
    },
    presetBankCapabilities = { onScreenPresetsAvailable = true }
  }
  ExpectRequest("Buttons.GetCapabilities", true, buttons_capabilities)
  ExpectRequest("VR.GetCapabilities", true, { vrCapabilities = { "TEXT" } })
  ExpectRequest("TTS.GetCapabilities", true, {
      speechCapabilities = { "TEXT", "PRE_RECORDED" },
      prerecordedSpeechCapabilities =
      {
        "HELP_JINGLE",
        "INITIAL_JINGLE",
        "LISTEN_JINGLE",
        "POSITIVE_JINGLE",
        "NEGATIVE_JINGLE"
      }
    })

  ExpectRequest("UI.GetCapabilities", true, ui_capabilities)

  ExpectRequest("VR.IsReady", true, { available = true })
  ExpectRequest("TTS.IsReady", true, { available = true })
  ExpectRequest("UI.IsReady", true, { available = true })
  ExpectRequest("Navigation.IsReady", true, { available = true })
  ExpectRequest("VehicleInfo.IsReady", true, { available = true })

  self.applications = { }
  ExpectRequest("BasicCommunication.UpdateAppList", false, { })
  :Pin()
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
      self.applications = { }
      for _, app in pairs(data.params.applications) do
        self.applications[app.appName] = app.appID
      end
    end)

  self.hmiConnection:SendNotification("BasicCommunication.OnReady")
end

--[[ Preconditions ]]
common_steps:AddNewTestCasesGroup("Preconditions After HMI Response")
common_steps:AddMobileConnection("Precondition_AddMobileConnection")
common_steps:AddMobileSession("Precondition_AddMobileSession")

--[[ Test ]]
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
        for k, v in pairs(ui_capabilities) do
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

  --[[ Postconditions ]]
  Test["Postcondition_UnregisterApplication_" .. i] = function(self)
    local cor_id = self.mobileSession:SendRPC("UnregisterAppInterface", {})
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { appID = self.applications[app_name], unexpectedDisconnect = false })
    self.mobileSession:ExpectResponse(cor_id, { success = true, resultCode = "SUCCESS"})
  end

  i = i + 1
end

---------------------------------------------------------------------------------------------
--[[ Postconditions ]]
common_steps:AddNewTestCasesGroup("Postcondition")
common_steps:StopSDL("Postcondition_StopSDL")
