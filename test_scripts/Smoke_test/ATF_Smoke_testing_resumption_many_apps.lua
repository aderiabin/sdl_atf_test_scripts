-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

------------------------------------ Common Variables ---------------------------------------
local apps = {}
apps[1] = common_functions:CreateRegisterAppParameters(
  {appID = "1", appName = "Application1", isMediaApplication = true, appHMIType = {"MEDIA"}})
for i = 2, 20 do
  apps[i] = common_functions:CreateRegisterAppParameters(
    {appID = tostring(i), appName = "Application" .. i, isMediaApplication = false, appHMIType = {"NAVIGATION"}})
end

------------------------------------ Common Functions ---------------------------------------
local function RegisterApps(test_case_name, register_app)
  for i =1, #register_app do
    local mobile_session_name = "mobile_session" .. i
    local app_name = register_app[i].appName
    common_steps:AddMobileSession(test_case_name .. "_Add_Mobile_Session" .. register_app[i].appID,_, mobile_session_name)
    common_steps:RegisterApplication(test_case_name .. "_Register_Application" .. register_app[i].appID,
      mobile_session_name, register_app[i], _, {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end
end

local function CheckResume20Apps(test_case_name, app)
  for i = 1, 20 do
    local mobilesession = "mobile_session" .. tostring(i)
    common_steps:AddMobileSession("AddMobileSession" .. i, _, mobilesession)
    Test[test_case_name .. i] = function(self)
      local cor_id_register = self[mobilesession]:SendRPC("RegisterAppInterface", app[i])

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appName = app[i].appName }, resumeVrGrammars = false})
      :Do(function(_,data)
          self.applications[app[i].appName] = data.params.application.appID
          hmi_app_id = data.params.application.appID
          self[mobilesession]:ExpectResponse(cor_id_register, { success = true, resultCode = "SUCCESS" })
        end)

      EXPECT_HMICALL("BasicCommunication.UpdateAppList")
      :Do(function(_,data)
          self.hmiConnection:SendResponse(data.id, "BasicCommunication.UpdateAppList", "SUCCESS", {})
        end)

      if i == 1 then
        EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function(_,data)
            self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
          end)
      elseif i == 2 then
        EXPECT_HMICALL("BasicCommunication.OnResumeAudioSource")
      end

      if i == 1 then
        self[mobilesession]:ExpectNotification("OnHMIStatus",
          {hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"},
          {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"} )
        :Times(2)
      elseif i == 2 then
        self[mobilesession]:ExpectNotification("OnHMIStatus",
          {hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"},
          {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"} )
        :Times(2)
      else
        self[mobilesession]:ExpectNotification("OnHMIStatus",
          {hmiLevel = "BACKGROUND", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE"})
      end
    end
  end
end

local function UpdatePreloadFileDefaultHmiLevelIsBackground()
  local path_to_file = config.pathToSDL .. 'sdl_preloaded_pt.json'
  local parent_item = {"policy_table", "app_policies", "default"}
  local added_json_items =
  [[
  {
    "keep_context": false,
    "steal_focus": false,
    "priority": "NONE",
    "default_hmi": "BACKGROUND",
    "groups": [
    "Base-4"
    ]
  }
  ]]
  common_functions:AddItemsIntoJsonFile(path_to_file, parent_item, added_json_items)
end

-------------------------------------------Preconditions-------------------------------------
common_functions:DeleteLogsFileAndPolicyTable()
UpdatePreloadFileDefaultHmiLevelIsBackground()
------------------------------------------------Body-----------------------------------------
-- Case 1: Check that SDL perform HMI level resumption of 20 Apps( after IGNITION_OFF)
common_steps:AddNewTestCasesGroup("Check that SDL perform HMI level resumption of 20 Apps( after IGNITION_OFF)")

common_steps:PreconditionSteps("Case_1_Precondition",6)
function Test:Case_1_Device_Consent()
  self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
    {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
  self["mobileSession"]:ExpectNotification("OnHMIStatus", {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
end
common_steps:UnregisterApp("Case_1_Unregister_App", config.application1.registerAppInterfaceParams.appName )
common_steps:CloseMobileSession("Case_1_Close_Mobile_Session", "mobileSession")

RegisterApps("Case_1", apps)
common_steps:ActivateApplication("Case_1_Activate_Application_1", apps[2].appName)
local hmi_status = {}
hmi_status[apps[2].appName] = {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}
common_steps:ActivateApplication("Case_1_Activate_Application_2", apps[1].appName, _, hmi_status)
common_steps:IgnitionOff("Case_1_Ignition_off")
common_steps:IgnitionOn("Case_1_Ignition_on")
CheckResume20Apps("Case_1_Check_Resume_App_", apps)
