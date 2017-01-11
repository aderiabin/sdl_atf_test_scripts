-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

----------------------------------------Common Variables-------------------------------------
local alert_id
local appID
local cor_id_alert

-------------------------------------------Preconditions-------------------------------------
common_functions:DeleteLogsFileAndPolicyTable()

-----------------------------------------------Body------------------------------------------
common_steps:AddNewTestCasesGroup("Check SDL clears internal data about app's non-responsed RPCs, ignored all responses and notifications from HMI associated with app")
common_steps:PreconditionSteps("Precondition",7)

function Test:SendAlert()
  appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
  cor_id_alert = self.mobileSession:SendRPC("Alert",
    {
      alertText1 = "alertText1",
    })
  EXPECT_HMICALL("UI.Alert",
    {
      alertStrings = {{fieldName = "alertText1", fieldText = "alertText1"}}
    })
  :Do(function(_,data)
      self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = appID, systemContext = "ALERT" })
      alert_id = data.id
    end)
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "ALERT", audioStreamingState = "AUDIBLE"})
end

function Test:ExitApp()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication",
    {reason = "UNAUTHORIZED_TRANSPORT_REGISTRATION", appID = appID})
  EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "APP_UNAUTHORIZED"})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = appID, unexpectedDisconnect = false})
end

function Test:VerifyAlertNotSendToMobile()
  self.hmiConnection:SendResponse(alert_id, "UI.Alert", "SUCCESS", { })
  self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = appID, systemContext = "MAIN" })
  EXPECT_NOTIFICATION("OnHMIStatus")
  :Times(0)
  EXPECT_RESPONSE(cor_id_alert)
  :Times(0)
end

function Test:VerifyOnDriverDistractionNotSendToMobile()
  self.hmiConnection:SendNotification("UI.OnDriverDistraction",{ state = "DD_ON"})
  EXPECT_NOTIFICATION("OnDriverDistraction")
  :Times(0)
end
