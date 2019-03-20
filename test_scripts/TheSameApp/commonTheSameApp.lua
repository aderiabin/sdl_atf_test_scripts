---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local utils = require('user_modules/utils')
local actions = require('user_modules/sequences/actions')
local events = require("events")

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Module ]]
local common = actions

--[[ Proxy Functions ]]
common.getDeviceName = utils.getDeviceName
common.getDeviceMAC = utils.getDeviceMAC
common.cloneTable = utils.cloneTable
common.isTableContains = utils.isTableContains

--[[ Common Functions ]]
function common.start()
  local event = events.Event()
  event.matches = function(e1, e2) return e1 == e2 end
  common.init.SDL()
  :Do(function()
      common.init.HMI()
      :Do(function()
          common.init.HMI_onReady()
          :Do(function()
              common.hmi.getConnection():RaiseEvent(event, "Start event")
            end)
        end)
    end)
  return common.hmi.getConnection():ExpectEvent(event, "Start event")
end

function common.modifyPreloadedPt(modificationFunc)
  common.sdl.backupPreloadedPT()
  local pt = common.sdl.getPreloadedPT()
  modificationFunc(pt)
  common.sdl.setPreloadedPT(pt)
end

function common.connectMobDevice(pMobConnId, deviceInfo, isSDLAllowed)
  if isSDLAllowed == nil then isSDLAllowed = true end
  utils.addNetworkInterface(pMobConnId, deviceInfo.host)
  common.mobile.createConnection(pMobConnId, deviceInfo.host, deviceInfo.port)
  local mobConnectExp = common.mobile.connect(pMobConnId)
  if isSDLAllowed then
    mobConnectExp:Do(function()
        common.mobile.allowSDL(pMobConnId)
      end)
  end
end

function common.deleteMobDevice(pMobConnId)
  -- common.mobile.disconnect(pMobConnId)
  -- common.mobile.deleteConnection(pMobConnId)
  utils.deleteNetworkInterface(pMobConnId)
end

function common.connectMobDevices(pDevices)
  for i = 1, #pDevices do
    common.connectMobDevice(i, pDevices[i])
  end
end

function common.clearMobDevices(pDevices)
  for i = 1, #pDevices do
    common.deleteMobDevice(i)
  end
end

function common.registerAppEx(pAppId, pAppParams, pMobConnId)
  local appParams = common.app.getParams(pAppId)
  for k, v in pairs(pAppParams) do
    appParams[k] = v
  end

  local session = common.mobile.createSession(pAppId, pMobConnId)
  session:StartService(7)
  :Do(function()
      local corId = session:SendRPC("RegisterAppInterface", appParams)
      local connection = session.mobile_session_impl.connection
      common.hmi.getConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        {
          application = {
            appName = appParams.appName,
            deviceInfo = {
              name = common.getDeviceName(connection.host, connection.port),
              id = common.getDeviceMAC(connection.host, connection.port)
            }
          }
        })
      :Do(function(_, d1)
        common.app.setHMIId(d1.params.application.appID, pAppId)
        end)
      session:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          session:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          session:ExpectNotification("OnPermissionsChange")
        end)
    end)
end

function common.deactivateApp(pAppId, pNotifParams)
  common.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated",
    { appID = common.getHMIAppId(pAppId)})
  common.mobile.getSession(pAppId):ExpectNotification("OnHMIStatus", pNotifParams)
end

function common.exitApp(pAppId)
common.getHMIConnection():SendNotification("BasicCommunication.OnExitApplication",
  { appID = common.getHMIAppId(pAppId), reason = "USER_EXIT"})
common.mobile.getSession(pAppId):ExpectNotification("OnHMIStatus",
  { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
end

function common.changeRegistrationSuccess(pAppId, pParams)
  local cid = common.mobile.getSession(pAppId):SendRPC("ChangeRegistration", pParams)

  common.hmi.getConnection():ExpectRequest("VR.ChangeRegistration", {
    language = pParams.language,
    vrSynonyms = pParams.vrSynonyms,
    appID = common.getHMIAppId(pAppId)
  })
  :Do(function(_, data)
     common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  common.hmi.getConnection():ExpectRequest("TTS.ChangeRegistration", {
    language = pParams.language,
    ttsName = pParams.ttsName,
    appID = common.getHMIAppId(pAppId)
  })
  :Do(function(_, data)
      common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  common.hmi.getConnection():ExpectRequest("UI.ChangeRegistration", {
    appName = pParams.appName,
    language = pParams.hmiDisplayLanguage,
    ngnMediaScreenAppName = pParams.ngnMediaScreenAppName,
    appID = common.app.getHMIId(pAppId)
  })
  :Do(function(_, data)
      common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  common.mobile.getSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function common.mobile.disallowSDL(pMobConnId)
  if pMobConnId == nil then pMobConnId = 1 end
  local connection = common.mobile.getConnection(pMobConnId)
  local event = common.run.createEvent()
  common.hmi.getConnection():SendNotification("SDL.OnAllowSDLFunctionality", {
    allowed = false,
    source = "GUI",
    device = {
      id = utils.getDeviceMAC(connection.host, connection.port),
      name = utils.getDeviceName(connection.host, connection.port)
    }
  })
  common.run.runAfter(function() common.hmi.getConnection():RaiseEvent(event, "Disallow SDL event") end, 100)
  return common.hmi.getConnection():ExpectEvent(event, "Disallow SDL event")
end

function common.getSystemCapability(pAppId, pResultCode)
  local isSuccess = false
  if pResultCode == "SUCCESS" then
    isSuccess = true
  end

  local mobileSession = common.mobile.getSession(pAppId)
  local cid = mobileSession:SendRPC("GetSystemCapability", { systemCapabilityType = "NAVIGATION" })
  mobileSession:ExpectResponse(cid, {success = isSuccess, resultCode = pResultCode})
end

function common.sendLocation(pAppId, pResultCode)
  local isSuccess = false
  if pResultCode == "SUCCESS" then
    isSuccess = true
  end

  local mobileSession = common.mobile.getSession(pAppId)
  local corId = mobileSession:SendRPC("SendLocation", {
      longitudeDegrees = 1.1,
      latitudeDegrees = 1.1
    })
  if pResultCode == "SUCCESS" then
    common.hmi.getConnection():ExpectRequest("Navigation.SendLocation")
    :Do(function(_,data)
        common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end)
  end
  mobileSession:ExpectResponse(corId, {success = isSuccess , resultCode = pResultCode})
end

function common.show(pAppId, pResultCode)
  local isSuccess = false
  if pResultCode == "SUCCESS" then
    isSuccess = true
  end

  local mobileSession = common.mobile.getSession(pAppId)
  local corId = mobileSession:SendRPC("Show", {mediaClock = "00:00:01", mainField1 = "Show1"})
  if pResultCode == "SUCCESS" then
    common.hmi.getConnection():ExpectRequest("UI.Show")
    :Do(function(_,data)
        common.hmi.getConnection():SendResponse(data.id, "UI.Show", "SUCCESS", {})
      end)
  end
  mobileSession:ExpectResponse(corId, { success = isSuccess, resultCode = pResultCode})
end

function common.funcGroupConsentForApp(pPrompts, pAppId)

  local function findFunctionalGroupIds(pAllowedFunctions, pGroupName)
    local ids = {}
    for _, allowedFunc in pairs(pAllowedFunctions) do
      if allowedFunc.name == pGroupName then
        table.insert(ids, allowedFunc.id)
      end
    end
    return ids
  end

  local function addConsentedFunctionsItems(pAllowedFunctions, pPromptItem, rConsentedFunctions)
    local groupIds = findFunctionalGroupIds(pAllowedFunctions, pPromptItem.name)
    if not next(groupIds) then
      common.run.fail("Unknown user consent prompt:" .. pPromptItem.name)
      return
    end
    for _, groupId in ipairs(groupIds) do
      local item = common.cloneTable(pPromptItem)
      item.id = groupId
      table.insert(rConsentedFunctions, item)
    end
  end

  local hmiAppID = nil
  if pAppId then
    hmiAppID = common.app.getHMIId(pAppId)
    if not hmiAppID then
      common.run.fail("Unknown mobile application number:" .. pAppId)
    end
  end

  local corId = common.hmi.getConnection():SendRequest("SDL.GetListOfPermissions", { appID = hmiAppID})
  common.hmi.getConnection():ExpectResponse(corId)
  :Do(function(_,data)
      local consentedFunctions = {}
      for _, promptItem in pairs(pPrompts) do
        addConsentedFunctionsItems(data.result.allowedFunctions, promptItem, consentedFunctions)
      end

      common.hmi.getConnection():SendNotification("SDL.OnAppPermissionConsent",
        {
          appID = hmiAppID,
          source = "GUI",
          consentedFunctions = consentedFunctions
        })
    end)
end

function common.getModuleControlData(module_type)
  local out = { moduleType = module_type }
  if module_type == "CLIMATE" then
    out.climateControlData = {
      fanSpeed = 30,
      desiredTemperature = {
        unit = "CELSIUS",
        value = 11.5
      },
      acEnable = true,
      circulateAirEnable = true,
      autoModeEnable = true,
      defrostZone = "FRONT",
      dualModeEnable = true,
      acMaxEnable = true,
      ventilationMode = "BOTH",
      heatedSteeringWheelEnable = true,
      heatedWindshieldEnable = true,
      heatedRearWindowEnable = true,
      heatedMirrorsEnable = true
    }
  elseif module_type == "RADIO" then
    out.radioControlData = {
      frequencyInteger = 1,
      frequencyFraction = 2,
      band = "AM",
      hdChannel = 1,
      radioEnable = true,
      hdRadioEnable = true,
    }
  elseif module_type == "LIGHT" then
    out.lightControlData = {
      lightState = {
        {
          id = "FRONT_LEFT_HIGH_BEAM",
          status = "ON",
          density = 0.5,
          color = {
            red = 5,
            green = 15,
            blue = 20
          }
        }
      }
    }
  end
  return out
end

local function sortModules(pModulesArray)
  local function f(a, b)
    if a.moduleType and b.moduleType then
      return a.moduleType < b.moduleType
    elseif a and b then
      return a < b
    end
    return 0
  end
  table.sort(pModulesArray, f)
end

function common.expectOnRCStatusOnMobile(pAppId, pExpData)
  common.mobile.getSession(pAppId):ExpectNotification("OnRCStatus")
  :ValidIf(function(_, d)
     sortModules(pExpData.freeModules)
     sortModules(pExpData.allocatedModules)
     sortModules(d.payload.freeModules)
     sortModules(d.payload.allocatedModules)
     return compareValues(pExpData, d.payload, "payload")
   end)
 :ValidIf(function(_, d)
   if d.payload.allowed == nil  then
     return false, "OnRCStatus notification doesn't contains 'allowed' parameter"
   end
   return true
 end)
end

function common.expectOnRCStatusOnHMI(pExpDataTable)
  local usedHmiAppIds = {}
  local appCount = 0;
  for _,_ in pairs(pExpDataTable) do
    appCount = appCount + 1
  end
  common.hmi.getConnection():ExpectNotification("RC.OnRCStatus")
  :ValidIf(function(_, d)
      if d.params.allowed ~= nil then
        return false, "RC.OnRCStatus notification contains unexpected 'allowed' parameter"
      end

      local hmiAppId = d.params.appID
      usedHmiAppIds[hmiAppId] = true

      if pExpDataTable[hmiAppId] and not usedHmiAppIds[hmiAppId] then
        sortModules(pExpDataTable[hmiAppId].freeModules)
        sortModules(pExpDataTable[hmiAppId].allocatedModules)
        sortModules(d.params.freeModules)
        sortModules(d.params.allocatedModules)
        return compareValues(pExpDataTable[hmiAppId], d.params, "params")
      else
        local msg
        if usedHmiAppIds[hmiAppId] then
          msg = "To many occurrences of RC.OnRCStatus notification for hmiAppId: " .. hmiAppId
        else
          msg = "Unexpected RC.OnRCStatus notification for hmiAppId: " .. hmiAppId
        end
        return false, msg
      end
    end)
  :Times(appCount)
end

function common.defineRAMode(pAllowed, pAccessMode)
  common.hmi.getConnection():SendNotification("RC.OnRemoteControlSettings",
      {allowed = pAllowed, accessMode = pAccessMode})
  common.run.wait(common.minTimeout) -- workaround due to issue with SDL -> redundant OnHMIStatus notification is sent
end

local function successHmiRequestSetInteriorVehicleData(pAppId, pModuleControlData)
  common.hmi.getConnection():ExpectRequest("RC.SetInteriorVehicleData", {
    appID = common.app.getHMIId(pAppId),
    moduleData = pModuleControlData
  })
  :Do(function(_, data)
      common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {
        moduleData = pModuleControlData
      })
    end)
end

function common.rpcAllowed(pAppId, pModuleType)
  local moduleControlData = common.getModuleControlData(pModuleType)
  local mobSession = common.mobile.getSession(pAppId)
  local cid = mobSession:SendRPC("SetInteriorVehicleData", {
        moduleData = moduleControlData
      })
  successHmiRequestSetInteriorVehicleData(pAppId, moduleControlData)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function common.rpcAllowedWithConsent(pModuleType, pAppId)
  local moduleControlData = common.getModuleControlData(pModuleType)
  local mobSession = common.mobile.getSession(pAppId)
  local cid = mobSession:SendRPC("SetInteriorVehicleData", {
        moduleData = moduleControlData
      })
  common.hmi.getConnection():ExpectRequest("RC.GetInteriorVehicleDataConsent", {
        appID = common.app.getHMIId(pAppId),
        moduleType = pModuleType
      })
  :Do(function(_, data)
      common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {allowed = true})
      successHmiRequestSetInteriorVehicleData(pAppId, moduleControlData)
    end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function common.rpcDenied(pModuleType, pAppId, pResultCode)
  local moduleControlData = common.getModuleControlData(pModuleType)
  local mobSession = common.mobile.getSession(pAppId)
  local cid = mobSession:SendRPC("SetInteriorVehicleData", {
        moduleData = moduleControlData
      })
  common.hmi.getConnection():ExpectRequest("RC.SetInteriorVehicleData", {}):Times(0)
  mobSession:ExpectResponse(cid, { success = false, resultCode = pResultCode })
end

function common.rpcRejectWithConsent(pModuleType, pAppId)
  local info = "The resource is in use and the driver disallows this remote control RPC"
  local moduleControlData = common.getModuleControlData(pModuleType)
  local mobSession = common.mobile.getSession(pAppId)
  local cid = mobSession:SendRPC("SetInteriorVehicleData", {
        moduleData = moduleControlData
      })
  common.hmi.getConnection():ExpectRequest("RC.GetInteriorVehicleDataConsent", {
        appID = common.app.getHMIId(pAppId),
        moduleType = pModuleType
      })
  :Do(function(_, data)
      common.hmi.getConnection():SendResponse(data.id, data.method, "SUCCESS", {allowed = false})
      common.hmi.getConnection():ExpectRequest("RC.SetInteriorVehicleData", {}):Times(0)
    end)
  mobSession:ExpectResponse(cid, { success = false, resultCode = "REJECTED", info = info })
end

return common
