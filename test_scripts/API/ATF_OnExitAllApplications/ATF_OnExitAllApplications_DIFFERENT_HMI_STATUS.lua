-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

------------------------------------------Common Variables-----------------------------------
local app = {}
app[1] = common_functions:CreateRegisterAppParameters(
  {appID = "1", appName = "Application1", isMediaApplication = true, appHMIType = {"MEDIA"}})
app[2] = common_functions:CreateRegisterAppParameters(
  {appID = "2", appName = "Application2", isMediaApplication = true, appHMIType = {"MEDIA"}})
app[3] = common_functions:CreateRegisterAppParameters(
  {appID = "3", appName = "Application3", isMediaApplication = true, appHMIType = {"MEDIA"}})
app[4] = common_functions:CreateRegisterAppParameters(
  {appID = "4", appName = "Application4", isMediaApplication = false, appHMIType = {"DEFAULT"}})

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
common_steps:PreconditionSteps("Precondition", 4)

------------------------------------------------Body-----------------------------------------
common_steps:AddNewTestCasesGroup("OnExitAllApplications_Different_HMI_STATUS")
RegisterAndActivateApp(app, {app[2], app[3], app[4]})

function Test:Exit_With_All_HMI_Status()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "IGNITION_OFF"})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    {appID = common_functions:GetHmiAppId(app[1].appName, self), unexpectedDisconnect = false},
    {appID = common_functions:GetHmiAppId(app[2].appName, self), unexpectedDisconnect = false},
    {appID = common_functions:GetHmiAppId(app[3].appName, self), unexpectedDisconnect = false},
    {appID = common_functions:GetHmiAppId(app[4].appName, self), unexpectedDisconnect = false})
  :Times(4)
  self.mobile_session1:ExpectNotification("OnAppInterfaceUnregistered", {reason = "IGNITION_OFF"})
  self.mobile_session2:ExpectNotification("OnAppInterfaceUnregistered", {reason = "IGNITION_OFF"})
  self.mobile_session3:ExpectNotification("OnAppInterfaceUnregistered", {reason = "IGNITION_OFF"})
  self.mobile_session4:ExpectNotification("OnAppInterfaceUnregistered", {reason = "IGNITION_OFF"})
  :Do(function(_,data)
      StopSDL()
    end)
end

-------------------------------------------Postconditions-------------------------------------
common_steps:StopSDL("Stop SDL")
