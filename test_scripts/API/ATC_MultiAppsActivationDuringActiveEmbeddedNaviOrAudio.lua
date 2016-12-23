Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
-- local mobile  = require('mobile_connection')
-- local tcp = require('tcp_connection')
-- local file_connection  = require('file_connection')



local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

commonSteps:DeletePolicyTable()

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

-- Used Apps
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local media_app_1 = {}
media_app_1 = deepcopy(config.application1.registerAppInterfaceParams)
media_app_1.isMediaApplication = true
media_app_1.appHMIType = nil
media_app_1.appName = "media_app_1"
media_app_1.appID = "media_app_1"

local navigation_app_1 = {}
navigation_app_1 = deepcopy(config.application1.registerAppInterfaceParams)
navigation_app_1.isMediaApplication = false
navigation_app_1.appHMIType = {"NAVIGATION"}
navigation_app_1.appName = "navigation_app_1"
navigation_app_1.appID = "navigation_app_1"

local non_media_app_1 = {}
non_media_app_1 = deepcopy(config.application1.registerAppInterfaceParams)
non_media_app_1.isMediaApplication = false
non_media_app_1.appHMIType = nil
non_media_app_1.appName = "non_media_app_1"
non_media_app_1.appID = "non_media_app_1"

local hmi_ids_of_applications = {}

-- common functions
local function userPrint( color, message)
  print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
end

---------------------------------------------------------------------------------------------
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------
local MixingAudioSupported = ""

-- Read default value of MixingAudioSupported in .ini file
f = assert(io.open(config.pathToSDL.. "/smartDeviceLink.ini", "r"))

fileContent = f:read("*all")
DefaultContant = fileContent:match('MixingAudioSupported.?=.?([^\n]*)')

if not DefaultContant then
  print ( " \27[31m MixingAudioSupported is not found in smartDeviceLink.ini \27[0m " )
else
  MixingAudioSupported = DefaultContant
  --print("MixingAudioSupported = " ..MixingAudioSupported)
end
f:close()

---------------------------------------------------------------------------------------------
--Description: MixingAudioSupported is checked in smartDeviceLink.ini
--Requirement id in JIRA: APPLINK-21529
--Verification criteria: Parameter MixingAudioSupported is present in file smartDeviceLink.ini
Test["INIfile_MixingAudioSupported"] = function(self)
  userPrint(35,"======================================= Test Case =============================================")
  if(MixingAudioSupported == "true") then
    print ("\27[32m Tests will be executed for MixingAudioSupported = true.\27[0m")
  else
    self.FailTestCase("MixingAudioSupported = " ..MixingAudioSupported ..". Pay attention in test execution")
  end
end

-----------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------

--Begin Test case TC.1
      --Description: This test is intended to check SDL behavior during active embedded navigation 

      --Requirement id: Multiple media and navigation apps activation during 
      --                  active embedded navigation+audio mixing supported

function Test:UnregisterApp()
  userPrint(35, "================= Precondition ==================")
  --mobile side: UnregisterAppInterface request 
  local CorIdUAI = self.mobileSession:SendRPC("UnregisterAppInterface",{}) 

  --hmi side: expect OnAppUnregistered notification 
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
 

  --mobile side: UnregisterAppInterface response 
  EXPECT_RESPONSE(CorIdUAI, { success = true, resultCode = "SUCCESS"})
  :Timeout(200)
end

function Test:registerApp(session, params)
  
  -- userPrint(34, "=================== Test Case ===================")

  local registerAppInterfaceID = session:SendRPC("RegisterAppInterface", params)

  -- hmi side: SDL notifies HMI about registered App
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
      {application = {appName = params.appName}})
  :Do(function(_,data)
      
      -- remember HMI appID of registered App
      hmi_ids_of_applications[params.appName] = data.params.application.appID
  end)

  session:ExpectResponse(registerAppInterfaceID, { success = true, resultCode = "SUCCESS"})
  :Timeout(2000)

  -- todo: make precondition to have NONE as default level
  session:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE"})
  :Times(1)
  session:ExpectNotification("OnPermissionsChange")
  :Times(1)
end

-- Start streaming for media app 
local function StartStreamingForMedia(self)
    self.mobileSession:StartService(10)

    EXPECT_HMICALL("Navigation.StartAudioStream")
        :Do(function(exp,data)
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })         
             function to_run2()
             -- os.execute( " sleep 1 " )
                 self.mobileSession:StartStreaming(10,"files/Kalimba.mp3")
             end

             RUN_AFTER(to_run2, 300)
        end)

    EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming", {available = true})

    commonTestCases:DelayedExp(2000)
end

-- Start streaming for navi
local function StartStreamingForNavi(self)
    self.mobileSession2:StartService(10)

    EXPECT_HMICALL("Navigation.StartAudioStream")
        :Do(function(exp,data)
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })         
             function to_run2()
             -- os.execute( " sleep 1 " )
                 self.mobileSession2:StartStreaming(10,"files/Kalimba.mp3")
             end

             RUN_AFTER(to_run2, 300)
        end)

    EXPECT_HMINOTIFICATION("Navigation.OnAudioDataStreaming", {available = true})

    commonTestCases:DelayedExp(2000)
end


local function StopAudioStreamingForMedia(self)
     self.mobileSession:StopStreaming("files/Kalimba.mp3")
     StopAudioStreamingTime = timestamp()
end

local function StopAudioStreamingForNavi(self)
     self.mobileSession2:StopStreaming("files/Kalimba.mp3")
     StopAudioStreamingTime = timestamp()
end


local function activateApp(self, hmi_app_id)--Test:TC01_PreconditionActivateApp(self, hmi_app_id)

      -- hmi side: sending SDL.ActivateApp request
      local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = hmi_app_id})

      -- hmi side: expect SDL.ActivateApp response
      EXPECT_HMIRESPONSE(RequestId)
      :Do(function(_,data)
          -- In case when app is not allowed, it is needed to allow app
            if( data.result.isSDLAllowed ~= true ) then
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
                  -- according APPLINK-9283 we send "device" parameter, so expect "BasicCommunication.ActivateApp" one time
                  :Times(1)
              end)                                                                                        
          end --if( data.result.isSDLAllowed ~= true ) then
      end)
end

-- function Test:connectMobileStartSession()
--     local tcpConnection = tcp.Connection(config.mobileHost, config.mobilePort)
--     local fileConnection = file_connection.FileConnection("mobile.out", tcpConnection)
--     self.mobileConnection = mobile.MobileConnection(fileConnection)
--     self.mobileSession= mobile_session.MobileSession(
--     self,
--     self.mobileConnection)
--     event_dispatcher:AddConnection(self.mobileConnection)
--     self.mobileSession:ExpectEvent(events.connectedEvent, "Connection started")
--     self.mobileConnection:Connect()
--     self.mobileSession:StartService(7)    
-- end

-- function Test:PrecondConnectPhoneTC1()
--     
--     self:connectMobileStartSession()
-- end
------------------------------------------------------------------------------------------------------------
----------------------------------------------------------- APPLINK-25974
------------------------------------------------------------------------------------------------------------
userPrint(35,"======================================= Test Case 01 =============================================")
  -- register all Apps
  function Test:PrecondRegisterMediaApp1TC1()

      self:registerApp(self.mobileSession, media_app_1)
  end

  function Test:PrecondNaviAppOpenSessionTC1()
      -- Connected expectation
      self.mobileSession2 = mobile_session.MobileSession(
          self,
          self.mobileConnection)
      self.mobileSession2:StartService(7)
  end

  function Test:PrecondRegisterNaviAppTC1()
      
      self:registerApp(self.mobileSession2, navigation_app_1)
  end

  function Test:PrecondNonMediaAppOpenSessionTC1()
      -- Connected expectation
      self.mobileSession3 = mobile_session.MobileSession(
          self,
          self.mobileConnection)
      self.mobileSession3:StartService(7)
  end

  function Test:PrecondRegisterNonMediaAppTC1()
      
      self:registerApp(self.mobileSession3, non_media_app_1)
  end

  function Test:PrecondActivateNonMediaAppTC1()
      
      activateApp(self, hmi_ids_of_applications[non_media_app_1.appName])
      self.mobileSession3:ExpectNotification("OnHMIStatus", 
          {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
      :Times(1)

      -- other Apps without changes
      self.mobileSession2:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
      :Times(0)

      self.mobileSession:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
      :Times(0)
  end

  function Test:PrecondActivateNaviAppTC1( )
      
      activateApp(self, hmi_ids_of_applications[navigation_app_1.appName])
      -- navi to FULL
      self.mobileSession2:ExpectNotification("OnHMIStatus", 
          {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
      :Times(1)

      --non-media to BACKGROUND
      self.mobileSession3:ExpectNotification("OnHMIStatus", 
          {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
      :Times(1)

      --media App without changes
      self.mobileSession:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
      :Times(0)
  end

  -- APPLINK-25974, b. Three apps running on system:
  function Test:TC01_PrecondActivateMediaAppTC1(  )
      
      activateApp(self, hmi_ids_of_applications[media_app_1.appName])
      
      -- media to FULL
      self.mobileSession:ExpectNotification("OnHMIStatus", 
          {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
      :Times(1)

      --navi to LIMITED, AUDIBLE
      self.mobileSession2:ExpectNotification("OnHMIStatus", 
          {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
      :Times(1)

      --non-media App without changes
      self.mobileSession3:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
      :Times(0)
  end

  -- Action: User activates embedded navigation
  -- function Test:TC01_PrecondDeactivateMediaApp(  )
  --     
  --     self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", 
  --         {appID = hmi_ids_of_applications[media_app_1.appName]})

  --     -- expect Media will be in LIMITED, AUDIBLE
  --     self.mobileSession:ExpectNotification("OnHMIStatus", 
  --         {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  --     :Times(1)

  --     -- other Apps without changes
  --     self.mobileSession2:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
  --     :Times(0)
  --     self.mobileSession3:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
  --     :Times(0)
  -- end

  -- APPLINK-25974, c.User activates embedded navigation and HMILevel of apps were changed to: (per APPLINK-17839)
  function Test:ActivateEmbeddedNaviTC1()
     
      self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", 
          {eventName = "EMBEDDED_NAVI", isActive = true})

      -- Media app should change state to LIMITED and NOT_AUDIBLE
      self.mobileSession:ExpectNotification("OnHMIStatus", 
           {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
      :Times(1)

      -- Navi app should change state to BACKGROUND and NOT_AUDIBLE
      self.mobileSession2:ExpectNotification("OnHMIStatus", 
           {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
      :Times(1)
      
      -- self.mobileSession2:ExpectNotification("OnHMIStatus", 
      --     {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
      -- :Times(1)

      -- -- other Apps without changes
      -- self.mobileSession:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
      -- :Times(0)
      self.mobileSession3:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
      :Times(0)
  end

  -- APPLINK-25974:
  -- Action 1. User activates media app_1
  -- Action 2. SDL -> media app_1: OnHMIStatus (FULL, AUDIBLE) (per APPLINK-20341)
  function Test:ActivatesMediaAppTC1()
      
      userPrint(34, "=================== Test Case ===================")
      activateApp(self, hmi_ids_of_applications[media_app_1.appName])      

      self.mobileSession:ExpectNotification("OnHMIStatus", 
          {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
      :Times(1)

      -- other Apps without changes
      self.mobileSession2:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
      :Times(0)
      self.mobileSession3:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
      :Times(0)
  end

  -- APPLINK-25974:
  -- Action 3. User activates Navi App
  function Test:UserActivatesNaviAppTC1()
      
      userPrint(34, "=================== Test Case ===================")
      self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", 
          {eventName = "EMBEDDED_NAVI", isActive = false})
      
      self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", 
          {appID = hmi_ids_of_applications[media_app_1.appName]})
      
      activateApp(self, hmi_ids_of_applications[navigation_app_1.appName])

      -- media App moves to LIMITED, AUDIBLE
      self.mobileSession:ExpectNotification("OnHMIStatus", 
          {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
      :Times(1)

      -- navi App moves to FULL, AUDIBLE
      self.mobileSession2:ExpectNotification("OnHMIStatus", 
          {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}, -- Due to "EMBEDDED_NAVI", isActive = false
          {hmiLevel = "FULL",    audioStreamingState = "AUDIBLE", systemContext = "MAIN"} ) -- Due to BasicCommunication.OnAppDeactivated(media)
      :Times(2)

      -- non-media still in BACKGROUND
      self.mobileSession3:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
      :Times(0)
  end

  --todo: check statuses during streaming
  -- function Test:PrecondCreateFileForStream()
  --     
  --     local file_path = config.pathToSDL .. "sample.txt"
  --     os.execute("openssl rand -out" .. file_path .. "-base64 $((5 * 1000 ))")
  -- end

  --todo: register defect - SDL is freezes if uncomment function below
  -- function Test:PrecondStartAudioService()
  --     
  --     self.mobileSession2:StartService(10)
  --     :Do(function ()
  --         
  --         self.mobileSession2:StartStreaming(10, config.pathToSDL .. "sample.txt", 30 *1024)
  --     end)

  --     EXPECT_HMICALL("NAVIGATION.OnAudioDataStreaming", {{available = true}, {available = false}})

  --     --todo: expect hmiLevels
  -- end

  -- function Test:PostCondRemoveFile()
  --     
  --     os.execute("rm " .. config.pathToSDL .. "sample.txt")
  -- end

  --////////////////////////////////////////////////////////////////////////////////////////////////////////////
  --Start Audio Service and Streaming an navi app (which is in FULL, AUDIBLE)
  function Test:NaviApp_StartStreamingAudioTC1 ()
      StartStreamingForNavi(self)
      commonTestCases:DelayedExp(2000)
  end

  function Test:NaviApp_StopStreamingAudioTC1 ()

      StopAudioStreamingForNavi(self)

  end
--End Test case TC.1

---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
--Begin Test case TC.2
      --Description: This test is intended to check SDL behavior during active embedded navigation 

      --Requirement id: Multiple media, navigation and non-media apps activation during 
      --                  active embedded navigation+audio mixing supported
      --APPLINK-25979


-- precondition: unregister all apps
function Test:unregisterApplication(session)
  --mobile side: UnregisterAppInterface request 
  local CorIdUAI = session:SendRPC("UnregisterAppInterface",{}) 

  --hmi side: expect OnAppUnregistered notification 
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
 

  --mobile side: UnregisterAppInterface response 
  session:ExpectResponse(CorIdUAI, { success = true, resultCode = "SUCCESS"})
  :Timeout(200)
end

function Test:PrecondUnregisterMediaAppTC2()

    userPrint(35, "================= Precondition ==================")
    self:unregisterApplication(self.mobileSession)
end

function Test:PrecondUnregisterNaviAppTC2()

    self:unregisterApplication(self.mobileSession2)
end

function Test:PrecondUnregisterNonMediaAppTC2( )

    self:unregisterApplication(self.mobileSession3)
end
-- register all Apps
function Test:PrecondRegisterMediaApp1TC2()

    self:registerApp(self.mobileSession, media_app_1)
end

function Test:PrecondNaviAppOpenSessionTC2()
    -- Connected expectation
    self.mobileSession2 = mobile_session.MobileSession(
        self,
        self.mobileConnection)
    self.mobileSession2:StartService(7)
end

function Test:PrecondRegisterNaviApp1TC2()

    self:registerApp(self.mobileSession2, navigation_app_1)
end

function Test:PrecondNonMediaAppOpenSessionTC2()
    -- Connected expectation
    self.mobileSession3 = mobile_session.MobileSession(
        self,
        self.mobileConnection)
    self.mobileSession3:StartService(7)
end

function Test:PrecondRegisterNonMediaApp1TC2()

    self:registerApp(self.mobileSession3, non_media_app_1)
end

function Test:activateApp(self, hmi_app_id)

  -- if 
  --   notificationState.VRSession == true then
  --     self.hmiConnection:SendNotification("VR.Stopped", {})
  -- elseif 
  --   notificationState.EmergencyEvent == true then
  --     self.hmiConnection:SendNotification("BasicCommunication.OnEmergencyEvent", {enabled = false})
  -- elseif
  --   notificationState.PhoneCall == true then
  --     self.hmiConnection:SendNotification("BasicCommunication.OnPhoneCall", {isActive = false})
  -- end

    -- hmi side: sending SDL.ActivateApp request
      local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = hmi_app_id})

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
                -- according APPLINK-9283 we send "device" parameter, so expect "BasicCommunication.ActivateApp" one time
                :Times(1)
              end)                                                                                        
        end
    end)

end

function Test:PrecondActivateNonMediaAppTC2()
    
    activateApp(self, hmi_ids_of_applications[non_media_app_1.appName])
    self.mobileSession3:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    :Times(1)

    -- other Apps without changes
    self.mobileSession2:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
    :Times(0)
    self.mobileSession:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
    :Times(0)
end

function Test:PrecondActivateNaviAppTC2( )
   
    activateApp(self, hmi_ids_of_applications[navigation_app_1.appName])
    -- navi to FULL
    self.mobileSession2:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
    :Times(1)

    --non-media to BACKGROUND
    self.mobileSession3:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    :Times(1)

    --media App without changes
    self.mobileSession:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
    :Times(0)
end

--APPLINK-25979: Pre-condition b. Three apps running on system:
function Test:PrecondActivateMediaAppTC2()
    
    activateApp(self, hmi_ids_of_applications[media_app_1.appName])
    -- media to FULL
    self.mobileSession:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
    :Times(1)

    --navi to LIMITED, AUDIBLE
    self.mobileSession2:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
    :Times(1)

    --non-media App without changes
    self.mobileSession3:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
    :Times(0)
end
---End precondition TC2
------------------------------------------------------------------------------
-- Action: User activates embedded navigation
-- function Test:PrecondDeactivateMediaAppTC2()

--     self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", 
--         {appID = hmi_ids_of_applications[media_app_1.appName]})

--     -- expect Media will be in LIMITED, AUDIBLE
--     self.mobileSession:ExpectNotification("OnHMIStatus", 
--         {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
--     :Times(1)

--     -- other Apps without changes
--     self.mobileSession2:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
--     :Times(0)
--     self.mobileSession3:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
--     :Times(0)
-- end

-- APPLINK-25979: c. User activates embedded navigation and HMILevel of apps were changed to:
function Test:PrecondActivateEmbeddedNaviTC2()

    self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", 
        {eventName = "EMBEDDED_NAVI", isActive = true})

    -- media app: LIMITED and AUDIBLE
    self.mobileSession:ExpectNotification("OnHMIStatus",  
        {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
    :Times(1)

    -- expect navi will be in BACKGROUND, NOT_AUDIBLE
    self.mobileSession2:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    :Times(1)

    
    self.mobileSession3:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
    :Times(0)
end

-- APPLINK-25979: d. User activates media app_1 -> FULL, AUDIBLE
function Test:UserActivatesMediaAppTC2()

    activateApp(self, hmi_ids_of_applications[media_app_1.appName])

    self.mobileSession:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
    :Times(1)

    -- other Apps without changes (navi: BACKGROUND, NOT_AUDIBLE. non-media: BACKGROUND, NOT_AUDIBLE )
    self.mobileSession2:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
    :Times(0)
    self.mobileSession3:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
    :Times(0)
end

-- APPLINK-25979: e. User activates navigation app_2 -> FULL, AUDIBLE 
-- User activates Navi App to FULL, AUDIBLE
function Test:UserActivatesNaviAppTC2()

    self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", 
        {eventName = "EMBEDDED_NAVI", isActive = false})

    self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", 
        {appID = hmi_ids_of_applications[media_app_1.appName]})

    activateApp(self, hmi_ids_of_applications[navigation_app_1.appName])

    -- navi App moves to FULL, AUDIBLE
    self.mobileSession2:ExpectNotification("OnHMIStatus", 
          {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}, -- Due to "EMBEDDED_NAVI", isActive = false
          {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"} ) -- Due to BasicCommunication.OnAppDeactivated(media)
    :Times(2)

    -- media App moves to LIMITED, AUDIBLE
    self.mobileSession:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
    :Times(1)

   

    -- non-media still in BACKGROUND
    self.mobileSession3:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
    :Times(0)
end

-- APPLINK-25979: Action: user activates non_media_app_3
function Test:UserActivateNonMediaAppTC2()
    
    userPrint(34, "=================== Test Case ===================")

    activateApp(self, hmi_ids_of_applications[non_media_app_1.appName])
    
    self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", 
        {appID = hmi_ids_of_applications[navigation_app_1.appName]})

    self.mobileSession3:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    :Times(1)

    -- navi App moves to LIMITED, AUDIBLE
    self.mobileSession2:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
    :Times(1)

    -- media app without changes (LIMITED, AUDIBLE)
    self.mobileSession:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
    :Times(0)

end

-- HMI -> SDL: OnAppDeactivated for media app
-- function Test:DeactivateMediaAppTC2( )

--     self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", 
--         {appID = hmi_ids_of_applications[media_app_1.appName]})

--     -- expect Media will be in LIMITED, AUDIBLE
--     self.mobileSession:ExpectNotification("OnHMIStatus", 
--         {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
--     :Times(1)

--     -- other Apps without changes
--     self.mobileSession2:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
--     :Times(0)
--     self.mobileSession3:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
--     :Times(0)
-- end
-----------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------

--Begin Test case TC.3
      --Description: This test is intended to check SDL behavior during active embedded audio 

      --Requirement id: Multiple media and navigation apps activation during 
      --                  active embedded audio source+audio mixing supported
      -- APPLINK-25987

function Test:unregisterApplication(session)
  --mobile side: UnregisterAppInterface request 
  local CorIdUAI = session:SendRPC("UnregisterAppInterface",{}) 

  --hmi side: expect OnAppUnregistered notification 
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
 

  --mobile side: UnregisterAppInterface response 
  session:ExpectResponse(CorIdUAI, { success = true, resultCode = "SUCCESS"})
  :Timeout(200)
end

function Test:PrecondUnregisterMediaAppTC3()
    
    userPrint(35, "================= Precondition ==================")
    self:unregisterApplication(self.mobileSession)
end

function Test:PrecondUnregisterNaviAppTC3()
    
    self:unregisterApplication(self.mobileSession2)
end

function Test:PrecondUnregisterNonMediaAppTC3()
    
    self:unregisterApplication(self.mobileSession3)
end

-- register all Apps
function Test:PrecondRegisterMediaApp1TC3()
    
    self:registerApp(self.mobileSession, media_app_1)
end

function Test:PrecondRegisterNaviApp1TC3()
    
    self:registerApp(self.mobileSession2, navigation_app_1)
end

function Test:PrecondRegisterNonMediaApp1TC3()
    
    self:registerApp(self.mobileSession3, non_media_app_1)
end

function Test:PrecondActivateNonMediaAppTC3()
    
    activateApp(self, hmi_ids_of_applications[non_media_app_1.appName])
    self.mobileSession3:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    :Times(1)

    -- other Apps without changes
    self.mobileSession2:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
    :Times(0)
    self.mobileSession:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
    :Times(0)
end

function Test:PrecondActivateNaviAppTC3()
    
    activateApp(self, hmi_ids_of_applications[navigation_app_1.appName])
    -- navi to FULL
    self.mobileSession2:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
    :Times(1)

    --non-media to BACKGROUND
    self.mobileSession3:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    :Times(1)

    --media App without changes
    self.mobileSession:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
    :Times(0)
end

--APPLINK-25987: Precondition: Three apps running on system
function Test:PrecondActivateMediaAppTC3()

    activateApp(self, hmi_ids_of_applications[media_app_1.appName])
    -- media to FULL
    self.mobileSession:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
    :Times(1)

    --navi to LIMITED, AUDIBLE
    self.mobileSession2:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
    :Times(1)

    --non-media App without changes
    self.mobileSession3:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
    :Times(0)
end

--APPLINK-25987: c. User activates embedded audio source 
function Test:PrecondActivateEmbeddedAudioTC3()

    -- self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", 
    --     {appID = hmi_ids_of_applications[media_app_1.appName]})
    self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", 
        {eventName = "AUDIO_SOURCE", isActive = true})

    -- expect Media will be in BACKGROUND, NOT_AUDIBLE
    self.mobileSession:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    :Times(1)

    -- expect Navi will be in LIMITED, AUDIBLE
    -- TODO: APPLINK-20371 is not resolved
    userPrint(31,"APPLINK-20371 is not resolved")
    self.mobileSession2:ExpectNotification("OnHMIStatus",
         {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
    :Times(1)

    -- non-media App without changes
    self.mobileSession3:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
    :Times(0)
end

--APPLINK-25987: 
-- Action: User activates navi App
-- navigation app_2: OnHMIStatus (FULL, AUDIBLE)
function Test:UserActivatesNaviAppTC3()

    userPrint(34, "=================== Test Case ===================")

    activateApp(self, hmi_ids_of_applications[navigation_app_1.appName])

    -- media App moves to LIMITED, AUDIBLE
    self.mobileSession2:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
    :Times(1)

    -- other Apps without changes
    self.mobileSession:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
    :Times(0)
    self.mobileSession3:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
    :Times(0)
end

--APPLINK-25987: Action: User activates media App
function Test:UserActivatesMediaAppTC3()

    self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", 
        {eventName = "AUDIO_SOURCE", isActive = false})
   
    self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", 
        {appID = hmi_ids_of_applications[navigation_app_1.appName]})
   
    activateApp(self, hmi_ids_of_applications[media_app_1.appName])

    -- media App moves to FULL, AUDIBLE
    self.mobileSession:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}, -- Due to "AUDIO_SOURCE", isActive = false
        {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"} ) -- Due to BasicCommunication.OnAppDeactivated(media)
    :Times(2)

    -- navi App moves to LIMITED, AUDIBLE
    self.mobileSession2:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
    :Times(1)

    -- non-media Apps without changes (BACKGROUND, NOT_AUDIBLE)
    self.mobileSession3:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
    :Times(0)
end

-- audio streamind is started
--[[TODO: APPLINK-28069 - 
--Start Audio Service and Streaming in media app (which is in FULL, AUDIBLE)
function Test:StartStreamingForMediaApp()
    StartStreamingForMedia(self)
end


function Test:StopStreamingForMediaApp()
    StopAudioStreamingForMedia(self)
end]]
--End Test case TC.3

-----------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------

--Begin Test case TC.4
      --Description: This test is intended to check SDL behavior during active embedded audio 

      --Requirement id: Multiple media, navigation and non-media apps activation during 
      --                  active embedded audio source+audio mixing supported
      -- APPLINK-25988

function Test:unregisterApplication(session)
  --mobile side: UnregisterAppInterface request 
  local CorIdUAI = session:SendRPC("UnregisterAppInterface",{}) 

  --hmi side: expect OnAppUnregistered notification 
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
 

  --mobile side: UnregisterAppInterface response 
  session:ExpectResponse(CorIdUAI, { success = true, resultCode = "SUCCESS"})
  :Timeout(200)
end

function Test:PrecondUnregisterMediaAppTC4()

    userPrint(35, "================= Precondition ==================")
    self:unregisterApplication(self.mobileSession)
end

function Test:PrecondUnregisterNaviAppTC4()

    self:unregisterApplication(self.mobileSession2)
end

function Test:PrecondUnregisterNonMediaAppTC4()

    self:unregisterApplication(self.mobileSession3)
end

-- register all Apps
function Test:PrecondRegisterMediaApp1TC4()

    self:registerApp(self.mobileSession, media_app_1)
end

function Test:PrecondRegisterNaviApp1TC4()

    self:registerApp(self.mobileSession2, navigation_app_1)
end

function Test:PrecondRegisterNonMediaApp1TC4()

    self:registerApp(self.mobileSession3, non_media_app_1)
end

function Test:PrecondActivateNonMediaAppTC4()

    activateApp(self, hmi_ids_of_applications[non_media_app_1.appName])
    self.mobileSession3:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    :Times(1)

    -- other Apps without changes
    self.mobileSession2:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
    :Times(0)
    self.mobileSession:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
    :Times(0)
end

function Test:PrecondActivateNaviAppTC4()

    activateApp(self, hmi_ids_of_applications[navigation_app_1.appName])
    -- navi to FULL
    self.mobileSession2:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
    :Times(1)

    --non-media to BACKGROUND
    self.mobileSession3:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    :Times(1)

    --media App without changes
    self.mobileSession:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
    :Times(0)
end

--APPLINK-25988: Pre-conditions: Three apps running on system:
function Test:PrecondActivateMediaAppTC4()

    activateApp(self, hmi_ids_of_applications[media_app_1.appName])
    -- media to FULL
    self.mobileSession:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
    :Times(1)

    --navi to LIMITED, AUDIBLE
    self.mobileSession2:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
    :Times(1)

    --non-media App without changes
    self.mobileSession3:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
    :Times(0)
end

--APPLINK-25988: c. User activates embedded audio
function Test:PrecondActivateEmbeddedAudioTC4()

    -- self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", 
    --     {appID = hmi_ids_of_applications[media_app_1.appName]})
    self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", 
        {eventName = "AUDIO_SOURCE", isActive = true})

    -- expect Media will be in BACKGROUND, NOT_AUDIBLE
    self.mobileSession:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    :Times(1)

    -- TODO: APPLINK-20371 is not resolved
    -- expect navi will be in LIMITED, AUDIBLE
    userPrint(31,"APPLINK-20371 is not resolved")
    self.mobileSession2:ExpectNotification("OnHMIStatus",
         {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
    :Times(1)

    -- non-media Apps without changes
    self.mobileSession3:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
    :Times(0)
end

-- Action: User activates navi App
function Test:PrecondActivatesNaviAppTC4()

    activateApp(self, hmi_ids_of_applications[navigation_app_1.appName])

    -- navi app moves to FULL, AUDIBLE
    self.mobileSession2:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
    :Times(1)

    -- other Apps without changes
    self.mobileSession:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
    :Times(0)
    self.mobileSession3:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
    :Times(0)
end

-- Action: User activates media App
function Test:PrecondActivatesMediaAppTC4()

    self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged", 
        {eventName = "AUDIO_SOURCE", isActive = false})

    self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", 
        {appID = hmi_ids_of_applications[navigation_app_1.appName]})
    
    activateApp(self, hmi_ids_of_applications[media_app_1.appName])

    -- media App moves to FULL, AUDIBLE
    self.mobileSession:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"}, -- Due to "AUDIO_SOURCE", isActive = false
        {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"} ) -- Due to BasicCommunication.OnAppDeactivated(media)
    :Times(2)

    -- navi App moves to LIMITED, AUDIBLE
    self.mobileSession2:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
    :Times(1)

    -- non-media Apps without changes
    self.mobileSession3:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
    :Times(0)
end

function Test:UserActivatesNonMediaAppTC4()

    userPrint(34, "=================== Test Case ===================")
    self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", 
        {appID = hmi_ids_of_applications[media_app_1.appName]})

    activateApp(self, hmi_ids_of_applications[non_media_app_1.appName])

    -- non-media App moves to FULL, NOT_AUDIBLE
    self.mobileSession3:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    :Times(1)

    -- media App moves to LIMITED, AUDIBLE
    self.mobileSession:ExpectNotification("OnHMIStatus", 
        {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
    :Times(1)

    -- navi App without changes
    self.mobileSession2:ExpectNotification("OnHMIStatus", {systemContext = "MAIN"})
    :Times(0)
end
-- audio streamind is started

--Start Audio Service and Streaming an navi app (which is in LIMITED, AUDIBLE)
function Test:StartStreamingForNaviApp ()
    StartStreamingForNavi(self)
end

function Test:StopStreamingForNaviApp()
    StopAudioStreamingForNavi(self)
end


--End Test case TC.4
