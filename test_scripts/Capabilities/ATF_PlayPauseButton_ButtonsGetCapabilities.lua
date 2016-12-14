Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection = require('file_connection')
local config = require('config')
local module = require('testbase')
-----------------------------Required Shared Libraries---------------------------------------
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
require('user_modules/AppTypes')

--------------------------------------- Common functions ------------------------------------
local function button_capability(name, shortPressAvailable, longPressAvailable, upDownAvailable)
  return
  {
    name = name,
    shortPressAvailable = shortPressAvailable == nil and true or shortPressAvailable,
    longPressAvailable = longPressAvailable == nil and true or longPressAvailable,
    upDownAvailable = upDownAvailable == nil and true or upDownAvailable
  }
end

function stopSDL()
  Test["StopSDL"] = function(self)
    StopSDL()
  end
end

function startSDL()
  Test["StartSDL"] = function(self)
    StartSDL(config.pathToSDL, config.ExitOnCrash)
  end
end

function initHMI()
  Test["InitHMI"] = function(self)
    self:initHMI()
  end
end

local function HMI_Send_Button_GetCapabilities_Response(Input_capabilities)
  Test["HMI_Sends_Button_GetCapabilities_Response"] = function(self)
    critical(true)
    local function ExpectRequest(name, mandatory, params)
      xmlReporter.AddMessage(debug.getinfo(1, "n").name, tostring(name))
      local event = events.Event()
      event.level = 2
      event.matches = function(self, data) return data.method == name end
      return
      EXPECT_HMIEVENT(event, name)
      :Times(mandatory and 1 or AnyNumber())
      :Do(function(_, data)
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
        languages =
        {
          "EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU","TR-TR","PL-PL",
          "FR-FR","IT-IT","SV-SE","PT-PT","NL-NL","ZH-TW","JA-JP","AR-SA","KO-KR",
          "PT-BR","CS-CZ","DA-DK","NO-NO"
        }
      })
    ExpectRequest("TTS.GetSupportedLanguages", true, {
        languages =
        {
          "EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU","TR-TR","PL-PL",
          "FR-FR","IT-IT","SV-SE","PT-PT","NL-NL","ZH-TW","JA-JP","AR-SA","KO-KR",
          "PT-BR","CS-CZ","DA-DK","NO-NO"
        }
      })
    ExpectRequest("UI.GetSupportedLanguages", true, {
        languages =
        {
          "EN-US","ES-MX","FR-CA","DE-DE","ES-ES","EN-GB","RU-RU","TR-TR","PL-PL",
          "FR-FR","IT-IT","SV-SE","PT-PT","NL-NL","ZH-TW","JA-JP","AR-SA","KO-KR",
          "PT-BR","CS-CZ","DA-DK","NO-NO"
        }
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

    local buttons_capabilities =
    {
      capabilities = Input_capabilities,
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

    local function text_field(name, characterSet, width, rows)
      xmlReporter.AddMessage(debug.getinfo(1, "n").name, tostring(name))
      return
      {
        name = name,
        characterSet = characterSet or "TYPE2SET",
        width = width or 500,
        rows = rows or 1
      }
    end
    local function image_field(name, width, heigth)
      xmlReporter.AddMessage(debug.getinfo(1, "n").name, tostring(name))
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

    ExpectRequest("UI.GetCapabilities", true, {
        displayCapabilities =
        {
          displayType = "GEN2_8_DMA",
          textFields =
          {
            text_field("mainField1"),
            text_field("mainField2"),
            text_field("mainField3"),
            text_field("mainField4"),
            text_field("statusBar"),
            text_field("mediaClock"),
            text_field("mediaTrack"),
            text_field("alertText1"),
            text_field("alertText2"),
            text_field("alertText3"),
            text_field("scrollableMessageBody"),
            text_field("initialInteractionText"),
            text_field("navigationText1"),
            text_field("navigationText2"),
            text_field("ETA"),
            text_field("totalDistance"),
            text_field("navigationText"),
            text_field("audioPassThruDisplayText1"),
            text_field("audioPassThruDisplayText2"),
            text_field("sliderHeader"),
            text_field("sliderFooter"),
            text_field("notificationText"),
            text_field("menuName"),
            text_field("secondaryText"),
            text_field("tertiaryText"),
            text_field("timeToDestination"),
            text_field("turnText"),
            text_field("menuTitle")
          },
          imageFields =
          {
            image_field("softButtonImage"),
            image_field("choiceImage"),
            image_field("choiceSecondaryImage"),
            image_field("vrHelpItem"),
            image_field("turnIcon"),
            image_field("menuIcon"),
            image_field("cmdIcon"),
            image_field("showConstantTBTIcon"),
            image_field("showConstantTBTNextTurnIcon")
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
          shortPressAvailable = true,
          longPressAvailable = true,
          upDownAvailable = true,
          imageSupported = true
        }
      })

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
end

function connectMobileStartSession()
  Test["Connect_Mobile_Start_Session"] = function(self)
    local tcpConnection = tcp.Connection(config.mobileHost, config.mobilePort)
    local fileConnection = file_connection.FileConnection("mobile.out", tcpConnection)
    self.mobileConnection = mobile.MobileConnection(fileConnection)
    self.mobileSession= mobile_session.MobileSession(
      self,
      self.mobileConnection)
    event_dispatcher:AddConnection(self.mobileConnection)
    self.mobileSession:ExpectEvent(events.connectedEvent, "Connection started")
    self.mobileConnection:Connect()
    self.mobileSession:StartService(7)
  end
end

local function MobileRegisterAppAndVerifyButtonCapabilities(test_case_name, Input_ButtonsCapabilities)
  Test[test_case_name] = function(self)
    local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
    EXPECT_RESPONSE(correlationId, { success = true, buttonCapabilities = Input_ButtonsCapabilities})
  end
end

local function SuccessTestCase(test_case_name, Input_capabilities)
  -- Precondition
  startSDL()
  initHMI()
  -- Body
  HMI_Send_Button_GetCapabilities_Response(Input_capabilities)
  connectMobileStartSession()
  MobileRegisterAppAndVerifyButtonCapabilities(test_case_name, Input_capabilities)
  --Postcondition
  stopSDL()
end

-------------------------------------------Preconditions-------------------------------------
stopSDL()
------------------------------------------Body--------------------------------------------------------
-- 1. HMI-SDL: Send Buttons.GetCapabilities with some button names including Play_Pause button
-- Expected result: SDL sends the list of button names including Play_Pause in RegisterApp's response to app
------------------------------------------------------------------------------------------------------
local function TestHMISendButtonGetCapabilitiesWithSomeButtonNames()
  commonFunctions:newTestCasesGroup("Test case: HMI sends Buttons.GetCapabilities with some button names")
  local capabilities =
  {
    button_capability("PLAY_PAUSE"),
    button_capability("PRESET_1"),
    button_capability("PRESET_2"),
    button_capability("PRESET_3"),
    button_capability("PRESET_4"),
    button_capability("PRESET_5"),
    button_capability("PRESET_6"),
    button_capability("OK", true, false, true),
    button_capability("SEEKLEFT"),
    button_capability("SEEKRIGHT")
  }
  SuccessTestCase("Verify_HMI_sends_Buttons_GetCapabilities_with_some_button_names", capabilities)
end
TestHMISendButtonGetCapabilitiesWithSomeButtonNames()

------------------------------------------------------------------------------------------------------
-- 1. HMI-SDL: Send Buttons.GetCapabilities with only "PLAY_PAUSE" button
-- Expected result: SDL sends only "PLAY_PAUSE" button name in RegisterApp's response to app
------------------------------------------------------------------------------------------------------
local function TestHMISendButtonGetCapabilitiesWithOnlyPlayPauseButton()
  commonFunctions:newTestCasesGroup("Test case: HMI sends Buttons.GetCapabilities with only PLAY_PAUSE button")
  local capabilities_with_only_play_pause_button =
  {
    button_capability("PLAY_PAUSE")
  }
  SuccessTestCase("Verify_HMI_sends_Buttons_GetCapabilities_with_only_PLAY_PAUSE_button", capabilities_with_only_play_pause_button)
end
TestHMISendButtonGetCapabilitiesWithOnlyPlayPauseButton()
