-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

------------------------------------ Common Variables ---------------------------------------
local apps = {}
apps[1] = common_functions:CreateRegisterAppParameters(
{appID = "1", appName = "Application1", isMediaApplication = true, appHMIType = {"MEDIA"}})
apps[2] = common_functions:CreateRegisterAppParameters(
{appID = "2", appName = "Application2", isMediaApplication = false, appHMIType = {"NAVIGATION"}})
apps[3] = common_functions:CreateRegisterAppParameters(
{appID = "3", appName = "Application3", isMediaApplication = false, appHMIType = {"NAVIGATION"}})
apps[4] = common_functions:CreateRegisterAppParameters(
{appID = "4", appName = "Application4", isMediaApplication = false, appHMIType = {"COMMUNICATION"}})
apps[5] = common_functions:CreateRegisterAppParameters(
{appID = "5", appName = "Application5", isMediaApplication = false, appHMIType = {"COMMUNICATION"}})

------------------------------------ Common Functions ---------------------------------------

-------------------------------------------Preconditions-------------------------------------
common_functions:DeleteLogsFileAndPolicyTable()
common_steps:PreconditionSteps("Precondition",4)
-----------------------------------------------Body------------------------------------------
-- Case 1: Check that already running App is registered by establishing transport connection
common_steps:AddNewTestCasesGroup("Check that already running App is registered by establishing transport connection")
common_steps:AddMobileSession("Case_1_AddMobileSession", _, "mobile_session1")
common_steps:RegisterApplication("Case_1_RegisterApplication", "mobile_session1", apps[1])
common_steps:UnregisterApp("Case_1_Unregister_App", apps[1].appName )

-- Case 2: Check that it is able to register 5 Apps together by establishing transport connection
common_steps:AddNewTestCasesGroup("Check that it is able to register 5 Apps together by establishing transport connection")
for i = 1, 5 do
  common_steps:AddMobileSession("Case_2_AddMobileSession" .. i, _, "mobile_session" .. i)
  common_steps:RegisterApplication("Case_2_RegisterApplication" .. i, "mobile_session" .. i, apps[i])
end
common_steps:ActivateApplication("Case_2_ActivateApplication1",apps[1].appName)
local HMIStatus = {}
HMIStatus[apps[1].appName] = {hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}
common_steps:ActivateApplication("Case_2_ActivateApplication2",apps[2].appName, _, HMIStatus)
for i = 1, 5 do
  common_steps:UnregisterApp("Case_2_Unregister_App" .. i, apps[i].appName )
end

-- Case 3: Check that it is able to register 5 sessions one by one
common_steps:AddNewTestCasesGroup("Check that it is able to register 5 sessions one by one")
for i = 1, 5 do
  common_steps:AddMobileSession("Case_3_AddMobileSession" .. i, _, "mobile_session" .. i)
  common_steps:RegisterApplication("Case_3_RegisterApplication" .. i, "mobile_session" .. i, apps[i])
end
