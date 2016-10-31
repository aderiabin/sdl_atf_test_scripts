--------------------------------------------------------------------------------
-- This script contains common functions that are used in testing APPLINK-26401: [HMILevel resumption] Navigation and media app audioStreamingState during active embedded audio and navigation sources
--------------------------------------------------------------------------------
--[[Covered cases:
-> navi app resumption during embedded audio source
-> media app resumption during embedded navigation
-> media app and navi app both must get AUDIBLE after successfull resumption
-> audioStreamingState of media app when navi app streams
-> audioStreamingState of navi app when media app streams
]]
-- This library is used for below scripts:
-- API/ATF_Media_Navi_Activate_Audio_Navi_Source_Ignition_Off_26414
-- API/ATF_Media_Navi_Activate_Audio_Navi_Source_Ignition_Off_26415
-- API/ATF_Media_Navi_Activate_Audio_Navi_Source_Ignition_Off_26473_26503
-- API/ATF_Media_Navi_Activate_Audio_Navi_Source_Closing_Session_26414
-- API/ATF_Media_Navi_Activate_Audio_Navi_Source_Closing_Session_26415
-- API/ATF_Media_Navi_Activate_Audio_Navi_Source_Closing_Session_26473_26503

-- Author: Hoang Quang Nghi
-- ATF version: 2.2

local commonFunctionsForCRQ26401 = {}
local mobile_session = require('mobile_session')
local common_functions = require('user_modules/shared_testcases/commonFunctions')
local common_preconditions = require('user_modules/shared_testcases/commonPreconditions')
local common_testcases = require('user_modules/shared_testcases/commonTestCases')
local common_steps = require('user_modules/shared_testcases/commonSteps')

local config = require('config')

-----------------------------------------------------------------------------
-- Update value of MixingAudioSupported to true/false
-- @param test_case_name: main test name
-- @param is_mixing_audio_supported: value of MixingAudioSupported
-----------------------------------------------------------------------------
function commonFunctionsForCRQ26401:SetMixingAudioSupportedValueInIniFile(test_case_name, is_mixing_audio_supported)
  Test[test_case_name .. "_Precondition_Set_MixingAudioSupported_"..tostring(is_mixing_audio_supported)] = function(self)
    common_functions:SetValuesInIniFile("%p?MixingAudioSupported%s?=%s-[%D]-%s-\n", "MixingAudioSupported", is_mixing_audio_supported)
  end
end
-----------------------------------------------------------------------------
-- Update value of MixingAudioSupported to true/false at preconditions
-- @param is_mixing_audio_supported: value of MixingAudioSupported
-----------------------------------------------------------------------------
function commonFunctionsForCRQ26401:PreconditionSetMixingAudioSupportedValueInIniFile(is_mixing_audio_supported)
  common_functions:SetValuesInIniFile("%p?MixingAudioSupported%s?=%s-[%D]-%s-\n", "MixingAudioSupported", is_mixing_audio_supported)
end

-----------------------------------------------------------------------------
-- Active embedded audio/ navigation source
-- @param test_case_name: main test name
-- @param event_name: name of event
-- @param is_active: value of event: true or false
-----------------------------------------------------------------------------
function commonFunctionsForCRQ26401:ActiveEmbeddedSource(test_case_name, event_name, is_active)
  Test[test_case_name .. "_Activate_" .. event_name .. "_" .. tostring(is_active)] = function(self)
    self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{eventName = event_name, isActive = is_active})
  end
end

-----------------------------------------------------------------------------
-- Set values for application1 to use in RegisterAppInterface
-- @param test_case_name: main test name
-- @param app_hmi_type: value of appHMIType in ini file
-- @param is_media_application: value of isMediaApplication in ini file: true or false
-----------------------------------------------------------------------------
function commonFunctionsForCRQ26401:ChangeAppType(test_case_name, app_hmi_type, is_media_application)
  Test[test_case_name .. "_Precondition_Change_AppType: "..tostring(app_hmi_type[1])..". isMediaApplication: "..tostring(is_media_application)] = function(self)
    config.application1.registerAppInterfaceParams.appHMIType = app_hmi_type
    config.application1.registerAppInterfaceParams.isMediaApplication=is_media_application
  end
end

-----------------------------------------------------------------------------
-- Add new session for the second app
-- @param test_case_name: main test name
-----------------------------------------------------------------------------
function commonFunctionsForCRQ26401:AddSession2(test_case_name)
  Test[test_case_name.."_AddTheSecondSession"] = function(self)
    -- Connected expectation
    Test.mobileSession2 = mobile_session.MobileSession(Test,Test.mobileConnection)
    -- Start Service 7
    Test.mobileSession2:StartService(7)
  end
end

-----------------------------------------------------------------------------
-- Register the second Navi app
-----------------------------------------------------------------------------
function commonFunctionsForCRQ26401:RegisterTheSecondNaviApp(test_case_name)
  Test[test_case_name.."_RegisterTheSecondNaviApp"] = function(self)
    --mobile side: RegisterAppInterface request
    local CorIdRAI = self.mobileSession2:SendRPC("RegisterAppInterface",
      {
        syncMsgVersion =
        {
          majorVersion = 3,
          minorVersion = 0,
        },
        appName ="SPT2",
        isMediaApplication = false,
        languageDesired ="EN-US",
        hmiDisplayLanguageDesired ="EN-US",
        appID ="2",
        ttsName =
        {
          {
            text ="SyncProxyTester2",
            type ="TEXT",
          },
        },
        vrSynonyms =
        {
          "vrSPT2",
        },
        appHMIType = {"NAVIGATION"}
      })
    --hmi side: expect BasicCommunication.OnAppRegistered request
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
      {
        application =
        {
          appName = "SPT2"
        }
      })
    :Do(function(_,data)
        appId2 = data.params.application.appID
        self.applications["SPT2"] = data.params.application.appID
      end)
    --mobile side: RegisterAppInterface response
    self.mobileSession2:ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS"})
    :Timeout(2000)
    self.mobileSession2:ExpectNotification("OnHMIStatus",{hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end
end

-----------------------------------------------------------------------------
-- Activate the second Navi app
-----------------------------------------------------------------------------
function commonFunctionsForCRQ26401:ActivateTheSecondNaviApp(test_case_name)
  Test[test_case_name.."_ActivateTheSecondNaviApp"] = function(self)
    local deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
    --HMI send ActivateApp request
    local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = appId2})
    EXPECT_HMIRESPONSE(RequestId)
    :Do(function(_,data)

        if data.result.isSDLAllowed ~= true then
          local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
          EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
          :Do(function(_,data)
              --hmi side: send request SDL.OnAllowSDLFunctionality
              self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = deviceMAC, name = "127.0.0.1"}})
            end)
          EXPECT_HMICALL("BasicCommunication.ActivateApp")
          :Do(function(_,data)
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
            end)
          :Times(AnyNumber())
        else
          self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end
      end)
    self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
    :Timeout(12000)
  end
end

-----------------------------------------------------------------------------
-- Start Audio Service and Streaming
-- @param test_case_name: main test name
-- @param app_number: this param exists when starts audio on 2nd navi app
-- @param level: HMIlevel of 1st media app
-----------------------------------------------------------------------------
function commonFunctionsForCRQ26401:StartAudioServiceAndStreaming(test_case_name,app_number,level)
  Test[test_case_name.."_StartAudio"] = function(self)
    if app_number == nil then
      self.mobileSession:StartService(10)
      EXPECT_HMICALL("Navigation.StartAudioStream")
      :Do(function(exp,data)
          --Send ACK
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
          function to_run2()
            self.mobileSession:StartStreaming(10,"files/Kalimba.mp3")
          end
          RUN_AFTER(to_run2, 1500)
        end)
      EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming", {available = true})
      :Timeout(20000)
    else
      self.mobileSession2:StartService(10)
      EXPECT_HMICALL("Navigation.StartAudioStream")
      :Do(function(exp,data)
          --Send ACK
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
          function to_run2()
            self.mobileSession2:StartStreaming(10,"files/Kalimba.mp3")
          end
          RUN_AFTER(to_run2, 1500)
        end)
      EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming", {available = true})
      EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = level, systemContext = "MAIN", audioStreamingState = "ATTENUATED"})
      common_testcases:DelayedExp(2000)
    end
  end
end

-----------------------------------------------------------------------------
-- Stop Audio streaming
-- @param test_case_name: main test name
-- @param app_number: this param exists when stops audio streaming on 2nd navi app
-- @param level: HMIlevel of 1st media app
-----------------------------------------------------------------------------
function commonFunctionsForCRQ26401:StopAudioStreaming(test_case_name,app_number,level)
  Test[test_case_name.."_StopAudio"] = function(self)
    if app_number==nil then
      self.mobileSession:StopStreaming("files/Kalimba.mp3")
      EXPECT_HMICALL("Navigation.StopAudioStream")
      :Times(0)
      EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming", {available = false})
      :Timeout(15000)
    else
      self.mobileSession2:StopStreaming("files/Kalimba.mp3")
      EXPECT_HMICALL("Navigation.StopAudioStream")
      :Times(0)
      EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming", {available = false})
      :Timeout(15000)
      EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = level, systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
    end
  end
end

-----------------------------------------------------------------------------
-- Start Video Service and Streaming
-- @param test_case_name: main test name
-- @param app_number: this param exists when starts video on 2nd navi app
-- @param level: HMIlevel of 1st media app
-----------------------------------------------------------------------------
function commonFunctionsForCRQ26401:StartVideoServiceAndStreaming(test_case_name,app_number,level)
  Test[test_case_name.."_StartVideo"] = function(self)
    if app_number==nil then
      self.mobileSession:StartService(11)
      EXPECT_HMICALL("Navigation.StartStream")
      :Do(function(_,data)
          --Send ACK
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
          self.mobileSession:StartStreaming(11,"files/Wildlife.wmv")
        end)
      EXPECT_HMINOTIFICATION("Navigation.OnVideoDataStreaming", {available = true})
    else
      self.mobileSession2:StartService(11)
      EXPECT_HMICALL("Navigation.StartStream")
      :Do(function(_,data)
          --Send ACK
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
          self.mobileSession2:StartStreaming(11,"files/Wildlife.wmv")
        end)
      EXPECT_HMINOTIFICATION("Navigation.OnVideoDataStreaming", {available = true})
      EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = level, systemContext = "MAIN", audioStreamingState = "ATTENUATED"})
    end

  end
end

-----------------------------------------------------------------------------
-- Stop Video streaming
-- @param test_case_name: main test name
-- @param app_number: this param exists when stops video streaming on 2nd navi app
-- @param level: HMIlevel of 1st media app
-----------------------------------------------------------------------------
function commonFunctionsForCRQ26401:StopVideoStreaming(test_case_name,app_number,level)
  Test[test_case_name.."_StopVideo"] = function(self)
    if app_number==nil then
      self.mobileSession:StopStreaming("files/Wildlife.wmv")
      EXPECT_HMINOTIFICATION("Navigation.OnVideoDataStreaming", {available = false})
    else
      self.mobileSession2:StopStreaming("files/Wildlife.wmv")
      EXPECT_HMINOTIFICATION("Navigation.OnVideoDataStreaming", {available = false})
      EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = level, systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
    end
  end
end

-----------------------------------------------------------------------------
-- Stop SDL, Start, Init, Init HMI, Connect Mobile, Create session, Register, Activate app to FULL
-- @param test_case_name: main test name
-----------------------------------------------------------------------------
function commonFunctionsForCRQ26401:RestartSdlInitHmiConnectMobileActivateApp(test_case_name)
  Test[test_case_name.."_StopSdl"] = function(self)
    StopSDL()
  end
  Test[test_case_name.."_StartSdl"] = function(self)
    StartSDL(config.pathToSDL, config.ExitOnCrash)
  end
  Test[test_case_name.."_InitHmi"] = function(self)
    self:initHMI()
  end
  Test[test_case_name.."_InitHMIonReady"] = function(self)
    self:initHMI_onReady()
  end
  Test[test_case_name.."_ConnectMobile"] = function(self)
    self:connectMobile()
  end
  commonFunctionsForCRQ26401:RegisterNewApp(test_case_name)
  commonFunctionsForCRQ26401:ActivateNewApp(test_case_name)
end

function commonFunctionsForCRQ26401:RegisterNewApp(test_case_name)
  Test[test_case_name.."_RegisterApp"] = function(self)
    self.mobileSession = mobile_session.MobileSession(
      self,
      self.mobileConnection,
      config.application1.registerAppInterfaceParams)
    -- Start Service 7
    self.mobileSession:StartService(7)
    :Do(function()
        local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
        EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
          {
            application = { appName = config.application1.registerAppInterfaceParams.appName }
          })
        :Do(function(_,data)
            --self.applications[data.params.application.appName] = data.params.application.appID
            self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            HMIAppID = data.params.application.appID
          end)

        self.mobileSession:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
        :Timeout(2000)

        self.mobileSession:ExpectNotification("OnHMIStatus",
          {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
      end)
  end
end

function commonFunctionsForCRQ26401:ActivateNewApp(test_case_name)
  Test[test_case_name.."_ActivateApp"] = function(self)
    -- hmi side: sending SDL.ActivateApp request
    local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp",
      { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

    -- hmi side: expect SDL.ActivateApp response
    EXPECT_HMIRESPONSE(RequestId)
    :Do(function(_,data)
        -- In case when app is not allowed, it is needed to allow app
        if
        data.result.isSDLAllowed ~= true then
          -- hmi side: sending SDL.GetUserFriendlyMessage request
          local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
            {language = "EN-US", messageCodes = {"DataConsent"}})

          -- hmi side: expect SDL.GetUserFriendlyMessage response
          -- TODO: comment until resolving APPLINK-16094
          -- EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})

          EXPECT_HMIRESPONSE(RequestId)
          :Do(function(_,data)
              -- hmi side: send request SDL.OnAllowSDLFunctionality
              self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
                {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
              -- hmi side: expect BasicCommunication.ActivateApp request
              EXPECT_HMICALL("BasicCommunication.ActivateApp")
              :Do(function(_,data)
                  -- hmi side: sending BasicCommunication.ActivateApp response
                  self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
                end)
              :Times(AnyNumber())
              --:Times(2) NB:Clarification to be made with IKovalenko
            end)
        end
      end)
    --mobile side: expect OnHMIStatus notification
    EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
  end
end
-----------------------------------------------------------------------------
-- Close connection, Connect Mobile, Create session, Register, Activate app to FULL
-- @param test_case_name: main test name
-----------------------------------------------------------------------------
function commonFunctionsForCRQ26401:CloseConnectionConnectMobileActivateApp(test_case_name)
  Test[test_case_name.."_CloseConnection"] = function(self)
    self.mobileConnection:Close()
    -- delete app_info file to make sure there is not any app to resume
    os.remove(config.pathToSDL .. "app_info.dat")
  end
  Test[test_case_name.."_ConnectMobile"] = function(self)
    self:connectMobile()
  end
  -- StartSession and Register Application
  commonFunctionsForCRQ26401:RegisterNewApp(test_case_name)
  --Activate App to Full
  commonFunctionsForCRQ26401:ActivateNewApp(test_case_name)
end

-----------------------------------------------------------------------------
-- Stop SDL, Start SDL, Init, Init HMI, Connect Mobile, Create session, Register app
-- @param test_case_name: main test name
-----------------------------------------------------------------------------
function commonFunctionsForCRQ26401:RestartSdlInitHmiConnectMobile(test_case_name)
  Test[test_case_name.."_StopSdl"] = function(self)
    StopSDL()
  end
  Test[test_case_name.."_StartSdl"] = function(self)
    StartSDL(config.pathToSDL, config.ExitOnCrash)
  end
  Test[test_case_name.."_InitHmi"] = function(self)
    self:initHMI()
  end
  Test[test_case_name.."_InitHmiOnReady"] = function(self)
    self:initHMI_onReady()
  end
  Test[test_case_name.."ConnectMobile"] = function(self)
    self:connectMobile()
  end
  -- StartSession and Register Application
  Test[test_case_name.."_RegisterApp"] = function(self)
    self.mobileSession = mobile_session.MobileSession(
      self,
      self.mobileConnection,
      config.application1.registerAppInterfaceParams)
    -- Start Service 7
    self.mobileSession:StartService(7)
    :Do(function()
        local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
        EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
          {
            application = { appName = config.application1.registerAppInterfaceParams.appName }
          })
        :Do(function(_,data)
            --self.applications[data.params.application.appName] = data.params.application.appID
            self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            HMIAppID = data.params.application.appID
          end)

        self.mobileSession:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
        :Timeout(2000)

        self.mobileSession:ExpectNotification("OnHMIStatus",
          {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
      end)
  end
end

-----------------------------------------------------------------------------
-- Close connection, Connect Mobile, Create session, Register app
-- @param test_case_name: main test name
-----------------------------------------------------------------------------
function commonFunctionsForCRQ26401:CloseConnectionConnectMobile(test_case_name)
  Test[test_case_name.."_CloseConnection"] = function(self)
    self.mobileConnection:Close()
  end
  Test[test_case_name.."_ConnectMobile"] = function(self)
    self:connectMobile()
  end
  -- StartSession and Register Application
  Test[test_case_name.."_RegisterApp"] = function(self)
    self.mobileSession = mobile_session.MobileSession(
      self,
      self.mobileConnection,
      config.application1.registerAppInterfaceParams)
    -- Start Service 7
    self.mobileSession:StartService(7)
    :Do(function()
        local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
        EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
          {
            application = { appName = config.application1.registerAppInterfaceParams.appName }
          })
        :Do(function(_,data)
            --self.applications[data.params.application.appName] = data.params.application.appID
            self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            HMIAppID = data.params.application.appID
          end)

        self.mobileSession:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
        :Timeout(2000)

        self.mobileSession:ExpectNotification("OnHMIStatus",
          {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
      end)
  end
end

-----------------------------------------------------------------------------
-- Bring 1st Application to LIMITED
-- @param test_case_name: main test name
-----------------------------------------------------------------------------
function commonFunctionsForCRQ26401:ChangeHmiLevelToLimited(test_case_name)
  Test[test_case_name.."_Bring1stAppToLimited"] = function(self)
    --hmi side: sending BasicCommunication.OnAppDeactivated request
    local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
      {
        appID = self.applications[config.application1.registerAppInterfaceParams.appName],
        reason = "GENERAL"
      })
    --mobile side: expect OnHMIStatus notification
    EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
  end
end

-----------------------------------------------------------------------------
-- Bring 2nd Application to LIMITED
-- @param test_case_name: main test name
-----------------------------------------------------------------------------
function commonFunctionsForCRQ26401:ChangeHmiLevelToLimited2(test_case_name)
  Test[test_case_name.."_Bring2ndAppToLimited"] = function(self)
    --hmi side: sending BasicCommunication.OnAppDeactivated request
    local cid = self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
      {
        appID = self.applications["SPT2"],
        reason = "GENERAL"
      })
    --mobile side: expect OnHMIStatus notification
    self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "LIMITED", systemContext = "MAIN"})
  end
end

-----------------------------------------------------------------------------
-- Resume the app to hmi_level (when there is only 1 app in testing)
-- @param test_case_name: main test name
-- @param hmi_level: HMILevel of app
-----------------------------------------------------------------------------
function commonFunctionsForCRQ26401:ResumeApp(test_case_name, hmi_level)
  Test[test_case_name .. "_Resume_App_" .. hmi_level] = function(self)
    -- mobile side: create mobile session
    self.mobileSession = mobile_session.MobileSession(
      self,
      self.mobileConnection,
      config.application1.registerAppInterfaceParams)
    -- Start Service 7
    self.mobileSession:StartService(7)
    :Do(function()
        -- Register app
        local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

        -- hmi side: expected OnAppRegistered notification
        EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appName = config.application1.registerAppInterfaceParams.appName }})
        :Do(function(_,data)
            self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            HMIAppID = data.params.application.appID
          end)

        -- mobile side: expect RegisterAppInterface response
        self.mobileSession:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
      end)

    -- hmi side: expected UpdateAppList request
    EXPECT_HMICALL("BasicCommunication.UpdateAppList")
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, "BasicCommunication.UpdateAppList", "SUCCESS", {})
      end)

    if hmi_level == "FULL" then
      -- hmi side: expect BasicCommunication.ActivateApp request
      EXPECT_HMICALL("BasicCommunication.ActivateApp")
      :Do(function(_,data)
          -- hmi side: sending BasicCommunication.ActivateApp response
          self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)
    else
      EXPECT_HMICALL("BasicCommunication.OnResumeAudioSource")
    end

    -- mobile side: expect OnHMIStatus notification, status switch from NONE to LIMITED/ FULL
    EXPECT_NOTIFICATION("OnHMIStatus",
      {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"},
      {hmiLevel = hmi_level, systemContext = "MAIN", audioStreamingState = "AUDIBLE"}
    )
    :Times(2)
  end
end

-----------------------------------------------------------------------------
-- Resume the Media app to level (when there is another navi app in 2nd mobile session)
-- @param level: level of the Media app
-----------------------------------------------------------------------------
function commonFunctionsForCRQ26401:ResumeMediaApp(level)
  Test["Resume Media app"] = function(self)
    self.mobileSession = mobile_session.MobileSession(
      self,
      self.mobileConnection,
      config.application1.registerAppInterfaceParams)
    -- Start Service 7
    self.mobileSession:StartService(7)
    :Do(function()
        local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
        EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
          {
            application = { appName = config.application1.registerAppInterfaceParams.appName }
          })
        :Do(function(_,data)
            self.applications[config.application1.registerAppInterfaceParams.appName] = data.params.application.appID
            HMIAppID = data.params.application.appID
          end)
        self.mobileSession:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
        :Do(function(_,data)
            -- mobile side: expect OnHMIStatus notification, status switch from NONE to FULL/ LIMITED
            EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"},{hmiLevel = level, systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
            :Times(2)
          end)
      end)
    EXPECT_HMICALL("BasicCommunication.UpdateAppList")
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, "BasicCommunication.UpdateAppList", "SUCCESS", {})
      end)
    if level == "FULL" then
      -- hmi side: expect BasicCommunication.ActivateApp request
      EXPECT_HMICALL("BasicCommunication.ActivateApp")
      :Do(function(_,data)
          -- hmi side: sending BasicCommunication.ActivateApp response
          self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)
    end
  end
end

-----------------------------------------------------------------------------
-- Resume the Navi app to level (when there is another media app in 1st mobile session)
-- @param level: level of the Navi app
-----------------------------------------------------------------------------
function commonFunctionsForCRQ26401:ResumeNaviApp(level)
  Test["Resume Navi app"] = function(self)
    self.mobileSession2 = mobile_session.MobileSession(
      self,
      self.mobileConnection,
      config.application2.registerAppInterfaceParams)
    -- Start Service 7
    self.mobileSession2:StartService(7)
    :Do(function()
        local CorIdRegister = self.mobileSession2:SendRPC("RegisterAppInterface", {
            syncMsgVersion =
            {
              majorVersion = 3,
              minorVersion = 0,
            },
            appName ="SPT2",
            isMediaApplication = false,
            languageDesired ="EN-US",
            hmiDisplayLanguageDesired ="EN-US",
            appID ="2",
            ttsName =
            {
              {
                text ="SyncProxyTester2",
                type ="TEXT",
              },
            },
            vrSynonyms =
            {
              "vrSPT2",
            },
            appHMIType = {"NAVIGATION"}

          })
        EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
          {
            application = { appName = "SPT2" }
          })
        :Do(function(_,data)
            -- self.applications[data.params.application.appName] = data.params.application.appID
            self.applications["SPT2"] = data.params.application.appID
            HMIAppID = data.params.application.appID
          end)
        self.mobileSession2:ExpectResponse(CorIdRegister, { success = true, resultCode = "SUCCESS" })
        :Do(function(_,data)
            self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"},{hmiLevel = level, systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
            :Times(2)
          end)
      end)
    EXPECT_HMICALL("BasicCommunication.UpdateAppList")
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, "BasicCommunication.UpdateAppList", "SUCCESS", {})
      end)
    if level == "FULL" then
      -- hmi side: expect BasicCommunication.ActivateApp request
      EXPECT_HMICALL("BasicCommunication.ActivateApp")
      :Do(function(_,data)
          -- hmi side: sending BasicCommunication.ActivateApp response
          self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)
    end
  end
end

-----------------------------------------------------------------------------
-- Start SDL, Init, Init HMI, Connect mobile
-- @param test_case_name: main test name
-----------------------------------------------------------------------------
function commonFunctionsForCRQ26401:StopStartSdlInitHmiConnectMobile(test_case_name)
  Test[test_case_name.."_StartSdl"] = function(self)
    StartSDL(config.pathToSDL, config.ExitOnCrash)
  end
  Test[test_case_name.."_InitHmi"] = function(self)
    self:initHMI()
  end
  Test[test_case_name.."_InitHmiOnReady"] = function(self)
    self:initHMI_onReady()
  end
  Test[test_case_name.."_ConnectMobile"] = function(self)
    self:connectMobile()
  end
end

-----------------------------------------------------------------------------
-- Turn off by Ignition_off
-- @param test_case_name: main test name
-----------------------------------------------------------------------------
function commonFunctionsForCRQ26401:IgnitionOff(test_case_name)
  Test[test_case_name.."_IgnitionOff"] = function(self)
    -- hmi side: sending request to SDL
    self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "IGNITION_OFF"})
    -- hmi side: expect BasicCommunication.OnAppUnregistered
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = HMIAppID, unexpectedDisconnect = false})
    -- mobile side: expect notification
    self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{reason = "IGNITION_OFF"}})
    :Do(function(_,data)
        StopSDL()
      end)
    -- hmi side: expect to BasicCommunication.OnSDLClose
    EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose",{})
    -- hmi side: UpdateAppList request
    EXPECT_HMICALL("BasicCommunication.UpdateAppList")
  end
end

-----------------------------------------------------------------------------
-- Close session of 1st app
-- @param test_case_name: main test name
-----------------------------------------------------------------------------
function commonFunctionsForCRQ26401:CloseSession(test_case_name)
  Test[test_case_name.."_CloseSession1"] = function(self)
    local appIDSession= self.applications[config.application1.registerAppInterfaceParams.appName]
    self.mobileSession:Stop()
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = appIDSession})
    :Timeout(20000)
  end
end

-----------------------------------------------------------------------------
-- Close session of 2nd app
-- @param test_case_name: main test name
-----------------------------------------------------------------------------
function commonFunctionsForCRQ26401:CloseSession2(test_case_name)
  Test[test_case_name.."_CloseSession2"] = function(self)
    local appIDSession2= self.applications[config.application2.registerAppInterfaceParams.appName]
    self.mobileSession2:Stop()
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true, appID = appIDSession2})
    :Timeout(20000)
  end
end

-----------------------------------------------------------------------------
-- Respore original file
-- @param file_name: file will be restored
-----------------------------------------------------------------------------
function commonFunctionsForCRQ26401:RestoreFile(file_name)
  Test["RestoreIniFile"] = function(self)
    common_preconditions:RestoreFile(file_name)
  end
end

return commonFunctionsForCRQ26401
