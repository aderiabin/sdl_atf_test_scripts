-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

------------------------------------------Common Variables-----------------------------------
local app = {}
app[1] = common_functions:CreateRegisterAppParameters(
  {appID = "1", appName = "Application1", isMediaApplication = true, appHMIType = {"MEDIA"}})
app[2] = common_functions:CreateRegisterAppParameters(
  {appID = "2", appName = "Application2", isMediaApplication = true, appHMIType = {"MEDIA"}})

-------------------------------------------Common functions----------------------------------
local function RegisterAndActivateApp(register_app, activate_app)
  for i =1, #register_app do
    local mobile_session_name = "mobile_session" .. tostring(i)
    common_steps:AddMobileSession("AddMobileSession" .. register_app[i].appID,_, mobile_session_name)
    common_steps:RegisterApplication("RegisterApplication" .. register_app[i].appID, mobile_session_name, app[i])
  end
  for i =1, #activate_app do
    common_steps:ActivateApplication("ActivateApplication" .. activate_app[i].appID, activate_app[i].appName)
  end
end

local function ShowRPC(self)
  local cid = self.mobileSession:SendRPC("Show",
    {
      mainField1 = "Test Existence of App"
    })
  EXPECT_HMICALL("UI.Show",
    {
      showStrings = {{fieldName = "mainField1", fieldText = "Test Existence of App"}}})
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
end

-------------------------------------------Preconditions-------------------------------------
common_functions:DeleteLogsFileAndPolicyTable()
common_steps:PreconditionSteps("Precondition", 7)

------------------------------------------------Body-----------------------------------------
common_steps:AddNewTestCasesGroup("OnExitAllApplications_SPECIAL_CASES")

function Test:Exit_Invalid_Json()
  --self.hmiConnection:SendNotification('{"params":{"reason":"IGNITION_OFF"},"jsonrpc":"2.0","method":"BasicCommunication.OnExitAllApplications"}'). Change : to ;
  self.hmiConnection:Send('{"params";{"reason":"IGNITION_OFF"},"jsonrpc":"2.0","method":"BasicCommunication.OnExitAllApplications"} ')
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    {appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect = false})
  :Times(0)
  self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{reason = ""}})
  :Times(0)
end

function Test:SendShowAPI()
  ShowRPC(self)
end

function Test:Exit_Invalid_Structure()
  --self.hmiConnection:SendNotification('{"params":{"reason":"IGNITION_OFF"},"jsonrpc":"2.0","method":"BasicCommunication.OnExitAllApplications"} '). Put jsonrpc to params section
  self.hmiConnection:Send('{"params":{"jsonrpc":"2.0","reason":"IGNITION_OFF"},"method":"BasicCommunication.OnExitAllApplications"} ')
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    {appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect = false})
  :Times(0)
  self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{reason = ""}})
  :Times(0)
end

function Test:SendShowAPI()
  ShowRPC(self)
end

function Test:Exit_Fake_Param()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "IGNITION_OFF", fakeparam = "fake"})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    {appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect = false})
  self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{reason = "IGNITION_OFF"}})
  :Do(function(_,data)
      StopSDL()
    end)
end

common_steps:PreconditionSteps("Precondition", 7)

function Test:Exit_Fake_Param_From_Another_API()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "IGNITION_OFF", sliderPosition = 123})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    {appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect = false})
  self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{reason = "IGNITION_OFF"}})
  :Do(function(_,data)
      StopSDL()
    end)
end

common_steps:PreconditionSteps("Precondition", 7)

function Test:Exit_All_Params_Are_Missed()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    {appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect = false})
  :Times(0)
  self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{reason = ""}})
  :Times(0)
end

function Test:SendShowAPI()
  ShowRPC(self)
end

function Test:Exit_Same_Notification_With_Same_Value()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "IGNITION_OFF"})
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "IGNITION_OFF"})
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "IGNITION_OFF"})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    {appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect = false})
  self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{reason = "IGNITION_OFF"}})
  common_functions:DelayedExp(2000)
  StopSDL()
end

common_steps:PreconditionSteps("Precondition", 7)

function Test:Exit_Same_Notification_With_Different_Value()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "IGNITION_OFF"})
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "FACTORY_DEFAULTS"})
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "abcdef"})
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = ""})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    {appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect = false})
  self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{reason = "IGNITION_OFF"}})
  common_functions:DelayedExp(2000)
  StopSDL()
end

common_steps:PreconditionSteps("Precondition", 4)
RegisterAndActivateApp({app[1], app[2]}, {app[1], app[2]})

function Test:Exit_Many_Apps_Master_Reset()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "MASTER_RESET"})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    {appID = common_functions:GetHmiAppId(app[1].appName, self), unexpectedDisconnect = false},
    {appID = common_functions:GetHmiAppId(app[2].appName, self), unexpectedDisconnect = false})
  :Times(2)
  self.mobile_session1:ExpectNotification("OnAppInterfaceUnregistered", {reason = "MASTER_RESET"})
  self.mobile_session2:ExpectNotification("OnAppInterfaceUnregistered", {reason = "MASTER_RESET"})
  :Do(function(_,data)
      StopSDL()
    end)
end

-------------------------------------------Postconditions-------------------------------------
common_steps:StopSDL("Stop SDL")
