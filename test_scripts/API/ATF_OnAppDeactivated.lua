require('user_modules/all_common_modules')

------------------------------------ Common Variables ---------------------------------------
app1 = common_functions:CreateRegisterAppParameters(
  {appID = "1", appName = "Application1", isMediaApplication = true, appHMIType = {"MEDIA"}})
app2 = common_functions:CreateRegisterAppParameters(
  {appID = "2", appName = "Application2", isMediaApplication = false, appHMIType = {"DEFAULT"}})
app3 = common_functions:CreateRegisterAppParameters(
  {appID = "3", appName = "Application3", isMediaApplication = true, appHMIType = {"NAVIGATION"}})
app4 = common_functions:CreateRegisterAppParameters(
  {appID = "4", appName = "Application4", isMediaApplication = true, appHMIType = {"COMMUNICATION"}})

-------------------------------------------Preconditions-------------------------------------
common_functions:DeleteLogsFileAndPolicyTable()
common_steps:PreconditionSteps("Precondition",4)
common_steps:AddMobileSession("Precondition_AddMobileSession")
common_steps:RegisterApplication("Precondition_Register_App_1", "mobileSession", app1)
common_steps:ActivateApplication("Precondition_Activate_App_1", app1.appName)

---------------------------------------------------------------------------------------------
-----------------------------------------I TEST BLOCK----------------------------------------
-- Check of mandatory/conditional notification's parameters (from HMI)--
---------------------------------------------------------------------------------------------
common_steps:AddNewTestCasesGroup("Test case: Check normal cases of OnAppDeactivate")
function Test:Send_OnAppDeactivated_WithoutMandatoryAppID()
  self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
    {
    })
  EXPECT_NOTIFICATION("OnHMIStatus")
  :Times(0)
end

function Test:Send_OnAppDeactivated_WithFakeParam()
  local appID = common_functions:GetHmiAppId(app1.appName, self)
  self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
    {
      appID = appID,
      fakeParam = "fakeParam"
    })
  EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  :ValidIf (function(_,data)
      if data.payload.fakeParam ~= nil then
        print(" \27[36m SDL resend fake parameter to mobile app \27[0m")
        return false
      else
        return true
      end
    end)
end
common_steps:ActivateApplication("Postcondition_Activate_App_1", app1.appName)

function Test:Send_OnAppDeactivated_WithParamsAnotherRequest()
  local appID = common_functions:GetHmiAppId(app1.appName, self)
  self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
    {
      appID = appID,
      syncFileName = "a"
    })
  EXPECT_NOTIFICATION("OnHMIStatus",{hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  :ValidIf (function(_,data)
      if data.payload.syncFileName ~= nil then
        print(" \27[36m SDL resend fake parameter to mobile app \27[0m")
        return false
      else
        return true
      end
    end)
end

common_steps:ActivateApplication("Postcondition_Activate_App_1", app1.appName)

function Test:Send_OnAppDeactivated_InvalidJsonSyntax()
  --":" is changed by ";" after "jsonrpc"
  self.hmiConnection:Send('{"jsonrpc";"2.0","method":"BasicCommunication.OnAppDeactivated","params":{"appID":' ..
    common_functions:GetHmiAppId(app1.appName, self) .. '}}')
  EXPECT_NOTIFICATION("OnHMIStatus")
  :Times(0)
end

function Test:Send_OnAppDeactivated_InvalidStructure()
  self.hmiConnection:Send('{"jsonrpc":"2.0","params":{"method":"BasicCommunication.OnAppDeactivated", "appID":' ..
    common_functions:GetHmiAppId(app1.appName, self) .. '}}')
  EXPECT_NOTIFICATION("OnHMIStatus")
  :Times(0)
end

----------------------------------------------------------------------------------------------
----------------------------------------II TEST BLOCK----------------------------------------
----------------------------------------Negative cases----------------------------------------
----------------------------------------------------------------------------------------------
function Test:Send_OnAppDeactivated_WithoutMethod()
  self.hmiConnection:Send('{"jsonrpc":"2.0","params":{"appID":' .. common_functions:GetHmiAppId(app1.appName, self) .. '}}')
  EXPECT_NOTIFICATION("OnHMIStatus")
  :Times(0)
end

function Test:Send_OnAppDeactivated_WithoutParams()
  self.hmiConnection:Send('{"jsonrpc":"2.0","method":"BasicCommunication.OnAppDeactivated"}')
  EXPECT_NOTIFICATION("OnHMIStatus")
  :Times(0)
end

common_steps:UnregisterApp("Postcondition_Unregister_App_1", app1.appName)

----------------------------------------------------------------------------------------------
-----------------------------------------III TEST BLOCK --------------------------------------
--------------------------------------Different HMIStatus-------------------------------------
----------------------------------------------------------------------------------------------
common_steps:AddNewTestCasesGroup("Test case: Check OnAppDeactivated notification in different HMILevel")
common_steps:RegisterApplication("Precondition_Register_App_2", "mobileSession", app2)

Test["Send_OnAppDeactivated_at_NONE"] = function(self)
  local appID = common_functions:GetHmiAppId(app2.appName, self)
  self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
    {
      appID = appID,
    })
  EXPECT_NOTIFICATION("OnHMIStatus")
  :Times(0)
end

common_steps:ActivateApplication("Precondition_Activate_App", app2.appName)

Test["Deactivate_app_to_BACKGROUND"] = function(self)
  local appID = common_functions:GetHmiAppId(app2.appName, self)
  self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
    {
      appID = appID,
    })
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
end

Test["Send_OnAppDeactivated_at_BACKGROUND"] = function(self)
  local appID = common_functions:GetHmiAppId(app2.appName, self)
  self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
    {
      appID = appID,
    })
  EXPECT_NOTIFICATION("OnHMIStatus")
  :Times(0)
end

common_steps:UnregisterApp("Postcondition_Unregister_App_2", app2.appName)
common_steps:RegisterApplication("Precondition_Register_Navi_App", "mobileSession", app3)
common_steps:ActivateApplication("Precondition_Activate_Navi_App", app3.appName)
Test["Deactivate_Navi_App"] = function(self)
  local appID = common_functions:GetHmiAppId(app3.appName, self)
  self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
    {
      appID = appID,
    })
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
end

common_steps:UnregisterApp("Postcondition_Unregister_Navi_App", app3.appName)
common_steps:RegisterApplication("Precondition_Register_Communication_App", "mobileSession", app4)
common_steps:ActivateApplication("Precondition_Activate_Communication_App", app4.appName)
Test["Deactivate_Communication_App"] = function(self)
  local appID = common_functions:GetHmiAppId(app4.appName, self)
  self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
    {
      appID = appID,
    })
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
end
