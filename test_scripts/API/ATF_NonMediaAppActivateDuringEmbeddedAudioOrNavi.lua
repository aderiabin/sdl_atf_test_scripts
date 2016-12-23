-- Goal: Test is covering CRQ: Non-media app activation during active embedded audio source or navigation 
-- Requirement in Jira: APPLINK-20344
----------------------------------------------------------------------------------------------------
----------------------------------General Settings for Configuration--------------------------------
----------------------------------------------------------------------------------------------------
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonSteps     = require('user_modules/shared_testcases/commonSteps')
local commonFunctions     = require('user_modules/shared_testcases/commonFunctions')
local HMIAppIDNonMediaApp
local HMIAppIDNonMediaApp2
local HMIAppIDNonMediaApp3
local HMIAppIDMediaApp
local HMIAppIDNaviApp
local AppValuesOnHMIStatusDEFAULTMediaApp
local AppValuesOnHMIStatusDEFAULTNonMediaApp
local AppValuesOnHMIStatusDEFAULTNavigationApp
-- session: the first non-media APp
-- session2: embedded audio source
-- session3: second non-media App
-- session4: navigation 
-- session5: 3-rd non-media app

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

AppValuesOnHMIStatusDEFAULTMediaApp = {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" }
AppValuesOnHMIStatusDEFAULTNonMediaApp = {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" }
AppValuesOnHMIStatusDEFAULTNavigationApp = {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" }

local notificationState = {VRSession = false, EmergencyEvent = false, PhoneCall = false}


local applicationData = 
{
  mediaApp = {
        syncMsgVersion =
                {
                    majorVersion = 3,
                    minorVersion = 3
                },
        appName = "TestAppMedia",
        isMediaApplication = true,
        languageDesired = 'EN-US',
        hmiDisplayLanguageDesired = 'EN-US',
        appHMIType = { "DEFAULT" },
        appID = "0000002",
        deviceInfo =
              {
                  os = "Android",
                  carrier = "Megafon",
                  firmwareRev = "Name: Linux, Version: 3.4.0-perf",
                  osVersion = "4.4.2",
                  maxNumberRFCOMMPorts = 1
              }
        },
  
  nonmediaApp = {
          syncMsgVersion =
                  {
                      majorVersion = 3,
                      minorVersion = 3
                  },
          appName = "TestAppNonMedia",
          isMediaApplication = false,
          languageDesired = 'EN-US',
          hmiDisplayLanguageDesired = 'EN-US',
          appHMIType = { "DEFAULT" },
    appID = "0000003",
    deviceInfo =
    {
      os = "Android",
      carrier = "Megafon",
      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
      osVersion = "4.4.2",
      maxNumberRFCOMMPorts = 1
    }
    },
    nonmediaApp2 = {
          syncMsgVersion =
                  {
                      majorVersion = 3,
                      minorVersion = 3
                  },
          appName = "TestAppSecondNonMedia",
          isMediaApplication = false,
          languageDesired = 'EN-US',
          hmiDisplayLanguageDesired = 'EN-US',
          appHMIType = { "DEFAULT" },
    appID = "0000004",
    deviceInfo =
    {
      os = "Android",
      carrier = "Megafon",
      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
      osVersion = "4.4.2",
      maxNumberRFCOMMPorts = 1
    }
    },
    nonmediaApp3 = {
          syncMsgVersion =
                  {
                      majorVersion = 3,
                      minorVersion = 3
                  },
          appName = "TestAppThirdNonMedia",
          isMediaApplication = false,
          languageDesired = 'EN-US',
          hmiDisplayLanguageDesired = 'EN-US',
          appHMIType = { "DEFAULT" },
    appID = "0000005",
    deviceInfo =
    {
      os = "Android",
      carrier = "Megafon",
      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
      osVersion = "4.4.2",
      maxNumberRFCOMMPorts = 1
    }
    },
    navigationApp = {
    syncMsgVersion =
    {
      majorVersion = 3,
      minorVersion = 3
    },
    appName = "TestAppNavigation",
    isMediaApplication = false,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appHMIType = { "NAVIGATION" },
    appID = "0000006",
    deviceInfo =
    {
      os = "Android",
      carrier = "Megafon",
      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
      osVersion = "4.4.2",
      maxNumberRFCOMMPorts = 1
    }
    },
    
}

if 
    config.application1.registerAppInterfaceParams.isMediaApplication == true or
    Test.appHMITypes["NAVIGATION"] == true then
    AppValuesOnHMIStatusFULL = {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}
    AppValuesOnHMIStatusLIMITED = {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}
elseif (config.application1.registerAppInterfaceParams.isMediaApplication == false) then
  AppValuesOnHMIStatusFULL = {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"}
end

------------------------------------------------------------------------------------------------------
---------------------------------------Functions used-------------------------------------------------
------------------------------------------------------------------------------------------------------
 
function DelayedExp(time)
    local event = events.Event()
    event.matches = function(self, e) return self == e end
    
    EXPECT_EVENT(event, "Delayed event")
    :Timeout(time+1000)
    
    RUN_AFTER(function()
    
    RAISE_EVENT(event, event)
    end, time)
end

local function ActivationApp(self, AppID)

  --hmi side: sending SDL.ActivateApp request
  RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = applicationID})

  --hmi side: expect SDL.ActivateApp response
  EXPECT_HMIRESPONSE(RequestId)
    :Do(function(_,data)
      --In case when app is not allowed, it is needed to allow app
      if
        data.result.isSDLAllowed ~= true then

          --hmi side: sending SDL.GetUserFriendlyMessage request
          local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", 
                    {language = "EN-US", messageCodes = {"DataConsent"}})

          --hmi side: expect SDL.GetUserFriendlyMessage response
          --TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
          EXPECT_HMIRESPONSE(RequestId)
            :Do(function(_,data)

              --hmi side: send request SDL.OnAllowSDLFunctionality
              self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", 
                {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})


              --hmi side: expect BasicCommunication.ActivateApp request
              EXPECT_HMICALL("BasicCommunication.ActivateApp")
                :Do(function(_,data)

                  --hmi side: sending BasicCommunication.ActivateApp response
                  self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})

                end)
                -- according APPLINK-9283 we send "device" parameter, so expect "BasicCommunication.ActivateApp" one time
                :Times(1)


            end)

    end
  end)
  
  --mobile side: expect notification
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"}) 
end

-- local function ActivationApp(self, AppID)

--     if notificationState.VRSession == true then
--       self.hmiConnection:SendNotification("VR.Stopped", {})
--     elseif 
--       notificationState.EmergencyEvent == true then
--       self.hmiConnection:SendNotification("BasicCommunication.OnEmergencyEvent", {enabled = false})
--     elseif
--       notificationState.PhoneCall == true then
--       self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = false})
--     end

--     --hmi side: sending SDL.ActivateApp request
--     local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = AppID})

--     --hmi side: expect SDL.ActivateApp response
--     EXPECT_HMIRESPONSE(RequestId)
--       :Do(function(_,data)
--       --In case when app is not allowed, it is needed to allow app
--         if
--           data.result.isSDLAllowed ~= true then

--           --hmi side: sending SDL.GetUserFriendlyMessage request
--             local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", 
--                 {language = "EN-US", messageCodes = {"DataConsent"}})

--             --hmi side: expect SDL.GetUserFriendlyMessage response
--             --TODO: comment until resolving APPLINK-16094
--           -- EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
--           EXPECT_HMIRESPONSE(RequestId)
--               :Do(function(_,data)

--             --hmi side: send request SDL.OnAllowSDLFunctionality
--             self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", 
--               {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

--             --hmi side: expect BasicCommunication.ActivateApp request
--               EXPECT_HMICALL("BasicCommunication.ActivateApp")
--               :Do(function(_,data)

--                 --hmi side: sending BasicCommunication.ActivateApp response
--                 self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})

--               end)
--               :Times(2)
--               end)

--       end
--         end)

-- end

-- activation of non-mrdia App
local function ActivateNonMediaApp(self, AppID)
    --hmi side: sending SDL.ActivateApp request
      local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})

      --hmi side: expect SDL.ActivateApp response
    EXPECT_HMIRESPONSE(RequestId)
      :Do(function(_,data)
        --In case when app is not allowed, it is needed to allow app
          if
              data.result.isSDLAllowed ~= true then

                --hmi side: sending SDL.GetUserFriendlyMessage request
                  local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", 
                          {language = "EN-US", messageCodes = {"DataConsent"}})

                  --hmi side: expect SDL.GetUserFriendlyMessage response
                EXPECT_HMIRESPONSE(RequestId)
                      :Do(function(_,data)

                    --hmi side: send request SDL.OnAllowSDLFunctionality
                    self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", 
                      {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})

                    --hmi side: expect BasicCommunication.ActivateApp request
                      EXPECT_HMICALL("BasicCommunication.ActivateApp")
                        :Do(function(_,data)

                          --hmi side: sending BasicCommunication.ActivateApp response
                          self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})

                      end)

                      end)

        end
          end)
  --mobile side: expect OnHMIStatus notification
  EXPECT_NOTIFICATION("OnHMIStatus", 
    {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  
end


local function RegisterApp(self, session, RegisterData, DEFLevel)

    local correlationId = session:SendRPC("RegisterAppInterface", RegisterData)

    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
    :Do(function(_,data)

      
      if(exp.occurences == 2) then 
        userPrint(31, "DEFECT ID: APPLINK-24902. Send RegisterAppInterface again to be sure that application is registered!")
      end


      -- self.applications[RegisterData.appName] = data.params.application.appID
      if RegisterData.appName == "TestAppMedia" then
        -- ToDo: second call of function RegisterApp_WithoutHMILevelResumption shall be removed when APPLINK-24902:"Genivi: Unexpected unregistering application at resumption after closing session."
        --        is resolved. The issue is checked only on Genivi
        local SecondcorrelationId = self.mobileSession:SendRPC("RegisterAppInterface", applicationData.mediaApp)
        
        HMIAppIDMediaApp = data.params.application.appID
      elseif RegisterData.appName == "TestAppNonMedia" then
        -- ToDo: second call of function RegisterApp_WithoutHMILevelResumption shall be removed when APPLINK-24902:"Genivi: Unexpected unregistering application at resumption after closing session."
        --        is resolved. The issue is checked only on Genivi
        local SecondcorrelationId = self.mobileSession:SendRPC("RegisterAppInterface", applicationData.nonmediaApp)

        HMIAppIDNonMediaApp = data.params.application.appID
      elseif RegisterData.appName == "TestAppNavigation" then
        -- ToDo: second call of function RegisterApp_WithoutHMILevelResumption shall be removed when APPLINK-24902:"Genivi: Unexpected unregistering application at resumption after closing session."
        --        is resolved. The issue is checked only on Genivi
        local SecondcorrelationId = self.mobileSession:SendRPC("RegisterAppInterface", applicationData.navigationApp)

        HMIAppIDNaviApp = data.params.application.appID

      end 
    end)
    :Times(1)

    session:ExpectResponse(correlationId, { success = true })

    session:ExpectNotification("OnHMIStatus", DEFLevel)

    -- ToDo: second call of function RegisterApp_WithoutHMILevelResumption shall be removed when APPLINK-24902:"Genivi: Unexpected unregistering application at resumption after closing session."
    --        is resolved. The issue is checked only on Genivi
    DelayedExp(1000)
end

------------------------------------------------------------------------------------------------------
------------------------------------------Tests-------------------------------------------------------
------------------------------------------------------------------------------------------------------
-- Req#1: App activation during active audio soiurce
function Test:PreconditionActivatenonMediaApp()
  commonFunctions:userPrint(35, "================= Precondition ==================")

  ActivateNonMediaApp(self, HMIAppIDNonMediaApp)
end

-- Precondition 1: Register new media app
function Test:AddNewSession()
  commonFunctions:userPrint(34, "=================== Test Req#1 ===================")
    -- Connected expectation
    self.mobileSession2 = mobile_session.MobileSession(
    self,
    self.mobileConnection)
    
    self.mobileSession2:StartService(7)
  end

-- register embedded audio App
function Test:RegisterEmbeddedAudio()
  
  RegisterApp(self, self.mobileSession2, applicationData.mediaApp, AppValuesOnHMIStatusDEFAULTMediaApp)

end
-- Activation of embedded audio
function Test:ActivateEmbeddedAudio()
    ActivationApp(self, HMIAppIDMediaApp)

      self.mobileSession2:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
      :Do(function(_,data)
        print("Embedded audio App level is " .. data.payload.hmiLevel)
        -- HMI -> SDL: OnAppDeactivated (AppID)
        self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIAppIDNonMediaApp , reason = "GENERAL"})
        end)
      -- SDL -> non-media App: OnHMIStatus(BACKGROUND, NOT_AUDIBLE)
      self.mobileSession:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
      :Do(function(_,data)
        print("Non-media App level is " .. data.payload.hmiLevel)
        end)
      -- HMI -> SDL: OnEventChanged (EMBEDDED_NAVI, isActive=true)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnEventChanged", 
        {eventName = "AUDIO_SOURCE", isActive = true})
    end

-- User activates non-medis App
function Test:UserActivatesNonMediaApp()
  ActivationApp(self, HMIAppIDNonMediaApp)
    --mobile side: expect OnHMIStatus notification
    EXPECT_NOTIFICATION("OnHMIStatus", 
    {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"})
  end

--/////////////////////////////////////////////////////////////////////////////////////////////
-- Req#2: Non-media App registers during active audio source
-- currently embedded audio source is active, make new session for new non-media app
function Test:AddNewSession()
  commonFunctions:userPrint(34, "=================== Test Req#2 ===================")
    -- Connected expectation
    self.mobileSession3 = mobile_session.MobileSession(
    self,
    self.mobileConnection)
    
    self.mobileSession3:StartService(7)
  end

-- register NEW non-media App
function Test:RegisterAnothernonMediaApp()
      RegisterApp(self, self.mobileSession3, applicationData.nonmediaApp2, AppValuesOnHMIStatusDEFAULTNonMediaApp)

  end

-- Activation of NEW non-media App
function Test:ActivateAnotherNonMediaApp()
    ActivationApp(self, HMIAppIDMediaApp)

      self.mobileSession3:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"})
      :Do(function(_,data)
        print("New non-media App level is " .. data.payload.hmiLevel)
        -- HMI -> SDL: OnAppDeactivated (AppID)
        self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIAppIDNonMediaApp , reason = "GENERAL"})
        end)
      -- SDL -> non-media App: OnHMIStatus(BACKGROUND, NOT_AUDIBLE)
      self.mobileSession2:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "BACKGROUND", audioStreamingState = "AUDIBLE"})
      :Do(function(_,data)
        print("Media App level is " .. data.payload.hmiLevel)
        end)
      -- HMI -> SDL: OnEventChanged (EMBEDDED_NAVI, isActive=true)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnEventChanged", 
        {eventName = "AUDIO_SOURCE", isActive = true})
    end

--////////////////////////////////////////////////////////////////////////////////////////////
--Req#3: App activation during active navigation source
-- currently non-media App is active, we create new session for navigation App
function Test:AddNewSession()
  commonFunctions:userPrint(34, "=================== Test Req#3 ===================")
    -- Connected expectation
    self.mobileSession4 = mobile_session.MobileSession(
    self,
    self.mobileConnection)
    
    self.mobileSession4:StartService(7)
  end

-- register Navi App
function Test:RegisterNaviApp()
  
      RegisterApp(self, self.mobileSession4, applicationData.navigationApp, AppValuesOnHMIStatusDEFAULTNavigationApp)
  end

-- user activates embedded navigation
function Test:ActivateNaviApp()
  ActivationApp(self, HMIAppIDNaviApp)

  self.mobileSession4:ExpectNotification("OnHMIStatus", 
    {hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})
  :Do(function(_,data)
    print("Navigation level is " .. data.payload.hmiLevel)
    -- HMI -> SDL: OnAppDeactivated (AppID)
    self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIAppIDNonMediaApp , reason = "GENERAL"})
    end)
  -- SDL -> non-media App: OnHMIStatus(BACKGROUND, NOT_AUDIBLE)
  self.mobileSession3:ExpectNotification("OnHMIStatus", 
    {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE"})
  :Do(function(_,data)
    print("Media App level is " .. data.payload.hmiLevel)
    end)
  -- HMI -> SDL: OnEventChanged (EMBEDDED_NAVI, isActive=true)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnEventChanged", 
    {eventName = "EMBEDDED_NAVI", isActive = true})
end

-- user activated non-media App
function Test:ActivateNonMediaApp()
    ActivationApp(self, HMIAppIDMediaApp)

      self.mobileSession3:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"})
      :Do(function(_,data)
        print("Non-media App level is " .. data.payload.hmiLevel)
        -- HMI -> SDL: OnAppDeactivated (AppID)
        self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIAppIDNonMediaApp , reason = "GENERAL"})
        end)
      -- SDL -> non-media App: OnHMIStatus(BACKGROUND, NOT_AUDIBLE)
      self.mobileSession2:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "BACKGROUND", audioStreamingState = "AUDIBLE"})
      :Do(function(_,data)
        print("Embedded audio App level is " .. data.payload.hmiLevel)
        end)
      -- HMI -> SDL: OnEventChanged (EMBEDDED_NAVI, isActive=true)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnEventChanged", 
        {eventName = "EMBEDDED_NAVI", isActive = true})
    end


--/////////////////////////////////////////////////////////////////////////////////////////
-- Req#4: New non media app registers during active navi source
function Test:AddNewSession()
  commonFunctions:userPrint(34, "=================== Test Req#4 ===================")
    -- Connected expectation
    self.mobileSession5 = mobile_session.MobileSession(
    self,
    self.mobileConnection)
    
    self.mobileSession5:StartService(7)
  end
-- register NEW non-media App
function Test:RegisterAnothernonMediaApp()
  
      RegisterApp(self, self.mobileSession5, applicationData.nonmediaApp3, AppValuesOnHMIStatusDEFAULTNonMediaApp)
  end

-- Activation of NEW non-media App
function Test:ActivateThirdNonMediaApp()
    ActivationApp(self, HMIAppIDMediaApp)

      self.mobileSession5:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE"})
      :Do(function(_,data)
        print("3-rd non-media App level is " .. data.payload.hmiLevel)
        -- HMI -> SDL: OnAppDeactivated (AppID)
        self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", {appID = HMIAppIDNonMediaApp , reason = "GENERAL"})
        end)
      -- SDL -> non-media App: OnHMIStatus(BACKGROUND, NOT_AUDIBLE)
      self.mobileSession4:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "BACKGROUND", audioStreamingState = "AUDIBLE"})
      :Do(function(_,data)
        print("Navi App level is " .. data.payload.hmiLevel)
        end)
      -- HMI -> SDL: OnEventChanged (EMBEDDED_NAVI, isActive=true)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnEventChanged", 
        {eventName = "EMBEDDED_NAVI", isActive = true})
    end