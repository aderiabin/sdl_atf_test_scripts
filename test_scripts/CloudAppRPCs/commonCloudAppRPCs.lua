local actions = require("user_modules/sequences/actions")
local json = require("modules/json")
local test = require("user_modules/dummy_connecttest")
local cloud = require("cloud_connection")
local file_connection = require("file_connection")
local mobile = require("mobile_connection")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local utils = require("user_modules/utils")
local events = require("events")
local expectations = require('expectations')
local constants = require('protocol_handler/ford_protocol_constants')

local commonCloudAppRPCs = actions

local function jsonFileToTable(file_name)
  local f = io.open(file_name, "r")
  local content = f:read("*all")
  f:close()
  return json.decode(content)
end

function commonCloudAppRPCs.getCloudAppConfig(app_id)
  return {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = { "Base-4" , "CloudApp" },
    endpoint = "ws://127.0.0.1:2000/",
    nicknames = { config["application" .. app_id].registerAppInterfaceParams.appName },
    cloud_transport_type = "WS",
    enabled = true
  }
end

function commonCloudAppRPCs.getCloudAppStoreConfig()
  return {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = { "Base-4" , "CloudAppStore" }
  }
end

function commonCloudAppRPCs:Request_PTU()
  local is_test_fail = false
  local hmi_app1_id = config.application1.registerAppInterfaceParams.appName
  commonCloudAppRPCs.getHMIConnection():SendNotification("SDL.OnPolicyUpdate", {} )
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})

  EXPECT_HMICALL("BasicCommunication.PolicyUpdate",{ file = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json" })
  :Do(function(_,data)
    commonCloudAppRPCs.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
end

function commonCloudAppRPCs.test_assert(condition, msg)
  if not condition then
    test:FailTestCase(msg)
  end
end

function commonCloudAppRPCs.GetPolicySnapshot()
  return jsonFileToTable("/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json")
end

function commonCloudAppRPCs:Directory_exist(DirectoryPath)
  if type( DirectoryPath ) ~= 'string' then
          error('Directory_exist : Input parameter is not string : ' .. type(DirectoryPath) )
          return false
  else
      local response = os.execute( 'cd ' .. DirectoryPath .. " 2> /dev/null" )
      -- ATf returns as result of 'os.execute' boolean value, lua interp returns code. if conditions process result as for lua enterp and for ATF.
      if response == nil or response == false then
          return false
      end
      if response == true then
          return true
      end
      return response == 0;
  end
end

function commonCloudAppRPCs.DeleteStorageFolder()
  local ExistDirectoryResult = commonCloudAppRPCs:Directory_exist( tostring(config.pathToSDL .. "storage"))
  if ExistDirectoryResult == true then
    local RmFolder  = assert( os.execute( "rm -rf " .. tostring(config.pathToSDL .. "storage" )))
    if RmFolder ~= true then
      print("Folder 'storage' is not deleted")
    end
  else
    print("Folder 'storage' is absent")
  end
end

local function getPTUFromPTS()
  local pTbl = {}
  local ptsFileName = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath") .. "/"
    .. commonFunctions:read_parameter_from_smart_device_link_ini("PathToSnapshot")
  if utils.isFileExist(ptsFileName) then
    pTbl = utils.jsonFileToTable(ptsFileName)
  else
    utils.cprint(35, "PTS file was not found, PreloadedPT is used instead")
    local appConfigFolder = commonFunctions:read_parameter_from_smart_device_link_ini("AppConfigFolder")
    if appConfigFolder == nil or appConfigFolder == "" then
      appConfigFolder = commonPreconditions:GetPathToSDL()
    end
    local preloadedPT = commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")
    local ptsFile = appConfigFolder .. preloadedPT
    if utils.isFileExist(ptsFile) then
      pTbl = utils.jsonFileToTable(ptsFile)
    else
      utils.cprint(35, "PreloadedPT was not found, PTS is not created")
    end
  end
  if next(pTbl) ~= nil then
    pTbl.policy_table.consumer_friendly_messages.messages = nil
    pTbl.policy_table.device_data = nil
    pTbl.policy_table.module_meta = nil
    pTbl.policy_table.usage_and_error_counts = nil
    pTbl.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
    pTbl.policy_table.module_config.preloaded_pt = nil
    pTbl.policy_table.module_config.preloaded_date = nil
  end
  return pTbl
end

function commonCloudAppRPCs.policyTableUpdateWithIconUrl(pPTUpdateFunc, pExpNotificationFunc, url)
  if pExpNotificationFunc then
    pExpNotificationFunc()
  end
  local ptsFileName = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath") .. "/"
    .. commonFunctions:read_parameter_from_smart_device_link_ini("PathToSnapshot")
  local ptuFileName = os.tmpname()
  local requestId = commonCloudAppRPCs.getHMIConnection():SendRequest("SDL.GetURLS", { service = 7 })
  commonCloudAppRPCs.getHMIConnection():ExpectResponse(requestId)
  :Do(function()
    commonCloudAppRPCs.getHMIConnection():SendNotification("BasicCommunication.OnSystemRequest",
        { requestType = "PROPRIETARY", fileName = ptsFileName })
      local ptuTable = getPTUFromPTS()
      for i = 1, commonCloudAppRPCs.getAppsCount() do
        ptuTable.policy_table.app_policies[commonCloudAppRPCs.getConfigAppParams(i).fullAppID] = commonCloudAppRPCs.getAppDataForPTU(i)
      end
      if pPTUpdateFunc then
        pPTUpdateFunc(ptuTable)
      end
      utils.tableToJsonFile(ptuTable, ptuFileName)
      local event = events.Event()
      event.matches = function(e1, e2) return e1 == e2 end
      commonCloudAppRPCs.getHMIConnection():ExpectEvent(event, "PTU event")
      for id = 1, commonCloudAppRPCs.getAppsCount() do
        commonCloudAppRPCs.getMobileSession(id):ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY"}, {requestType = "ICON_URL"  })
        :ValidIf(function(self, data)
          if data.payload.requestType == "PROPRIETARY" then
            return true
          end
          if data.payload.requestType == "ICON_URL" and data.payload.url == url then
            return true
          end
          return false
        end)
        :Do(function(_, data)
            if data.payload.requestType == "PROPRIETARY" then
              if not pExpNotificationFunc then
                commonCloudAppRPCs.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { odometer = true })
                commonCloudAppRPCs.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate", { status = "UP_TO_DATE" })
              end
              utils.cprint(35, "App ".. id .. " was used for PTU")
              commonCloudAppRPCs.getHMIConnection():RaiseEvent(event, "PTU event")
              local corIdSystemRequest = commonCloudAppRPCs.getMobileSession(id):SendRPC("SystemRequest", {
                requestType = "PROPRIETARY" }, ptuFileName)
              commonCloudAppRPCs.getHMIConnection():ExpectRequest("BasicCommunication.SystemRequest")
              :Do(function(_, d3)
                  commonCloudAppRPCs.getHMIConnection():SendResponse(d3.id, "BasicCommunication.SystemRequest", "SUCCESS", { })
                  commonCloudAppRPCs.getHMIConnection():SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = d3.params.fileName })
                end)
              commonCloudAppRPCs.getMobileSession(id):ExpectResponse(corIdSystemRequest, { success = true, resultCode = "SUCCESS" })
              :Do(function()
                os.remove(ptuFileName) end)
            end
          end)
        :Times(AtMost(2))
      end
    end)
end

function commonCloudAppRPCs.startWithoutMobile(pHMIParams)
  local event = commonCloudAppRPCs.run.createEvent()
  commonCloudAppRPCs.init.SDL()
  :Do(function()
      commonCloudAppRPCs.init.HMI()
      :Do(function()
          commonCloudAppRPCs.init.HMI_onReady()
          :Do(function()
              commonCloudAppRPCs.hmi.getConnection():RaiseEvent(event, "Start event")
            end)
        end)
    end)
  return commonCloudAppRPCs.hmi.getConnection():ExpectEvent(event, "Start event")
end

function commonCloudAppRPCs.modifyPreloadedPt(modificationFunc)
  commonCloudAppRPCs.sdl.backupPreloadedPT()
  local pt = commonCloudAppRPCs.sdl.getPreloadedPT()
  modificationFunc(pt)
  commonCloudAppRPCs.sdl.setPreloadedPT(pt)
end

commonCloudAppRPCs.cloneTable = utils.cloneTable
commonCloudAppRPCs.connectedEvent = events.connectedEvent
commonCloudAppRPCs.disconnectedEvent = events.disconnectedEvent

function commonCloudAppRPCs.getCloudAppHmiId(pCloudAppName)
  return test.applications[pCloudAppName]
end

function commonCloudAppRPCs.activateCloudApp(pAppId, pMobConnId, pAppParams)
  local appParams = commonCloudAppRPCs.app.getParams(pAppId)
  for k, v in pairs(pAppParams) do
    appParams[k] = v
  end

  local hmiConnection = commonCloudAppRPCs.hmi.getConnection()
  local cloudAppHmiId = commonCloudAppRPCs.getCloudAppHmiId(appParams.appName)
  local requestId = hmiConnection:SendRequest("SDL.ActivateApp", {appID = cloudAppHmiId})
  local cloudConnection = commonCloudAppRPCs.mobile.getConnection(pMobConnId)
  local sdlConnectedEvent = cloudConnection:ExpectEvent(events.connectedEvent, "Connected")
  sdlConnectedEvent:Do(function()
    local session = commonCloudAppRPCs.mobile.createSession(pAppId, pMobConnId)
    session:StartService(7)
    :Do(function()
        local corId = session:SendRPC("RegisterAppInterface", appParams)
        hmiConnection:ExpectNotification("BasicCommunication.OnAppRegistered",
          { application = { appName = appParams.appName } })
        :Do(function(_, d1)
            commonCloudAppRPCs.app.setHMIId(d1.params.application.appID, pAppId)
          end)
        session:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
        :Do(function()
            session:ExpectNotification("OnHMIStatus",
              { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
              { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
              :Times(2)
          end)
      end)
  end)
  hmiConnection:ExpectResponse(requestId, {result = {code = 0, method = "SDL.ActivateApp"}})
end

function commonCloudAppRPCs.ExpectEndService(pAppId,pService)
  local mobileSession =commonCloudAppRPCs.mobile.getSession(pAppId)
  local event = events.Event()
  event.matches = function(_, data)
    return data.frameType == constants.FRAME_TYPE.CONTROL_FRAME
      and data.serviceType == pService
      and data.sessionId == mobileSession.sessionId
      and data.frameInfo == constants.FRAME_INFO.END_SERVICE
  end

  return mobileSession:ExpectEvent(event, "EndService")
end

function commonCloudAppRPCs.setP5Configuration()
  if not utils.isFileExist("modules/libbson4lua.so") then
    print("'bson4lua' library is not available in ATF")
    return false
  end
  commonCloudAppRPCs.bson = require('bson4lua')
  config.defaultProtocolVersion = 5
  constants.FRAME_SIZE.P5 = 131084
  commonCloudAppRPCs.bson.bsonType = {
    DOUBLE   = 0x01,
    STRING   = 0x02,
    DOCUMENT = 0x03,
    ARRAY    = 0x04,
    BOOLEAN  = 0x08,
    INT32    = 0x10,
    INT64    = 0x12
  }
  return true
end

function commonCloudAppRPCs.createCloudConnection(pMobConnId, pMobConnHost, pMobConnPort)
  local function MobRaiseEvent(self, pEvent, pEventName)
    if pEventName == nil then pEventName = "noname" end
      reporter.AddMessage(debug.getinfo(1, "n").name, pEventName)
      event_dispatcher:RaiseEvent(self, pEvent)
  end

  local function MobExpectEvent(self, pEvent, pEventName)
    if pEventName == nil then pEventName = "noname" end
    local ret = expectations.Expectation(pEventName, self)
    ret.event = pEvent
    event_dispatcher:AddEvent(self, pEvent, ret)
    test:AddExpectation(ret)
    return ret
  end

  if pMobConnId == nil then pMobConnId = 1 end
  local baseConnection = cloud.Connection(pMobConnPort, false)
  local filename = "mobile" .. pMobConnId .. ".out"
  local fileConnection = file_connection.FileConnection(filename, baseConnection)
  local connection = mobile.MobileConnection(fileConnection)
  connection.RaiseEvent = MobRaiseEvent
  connection.ExpectEvent = MobExpectEvent
  connection.host = pMobConnHost
  connection.port = pMobConnPort
  connection.type = "CLOUD"
  event_dispatcher:AddConnection(connection)
  test.mobileConnections[pMobConnId] = connection
  return connection, baseConnection
end

return commonCloudAppRPCs
