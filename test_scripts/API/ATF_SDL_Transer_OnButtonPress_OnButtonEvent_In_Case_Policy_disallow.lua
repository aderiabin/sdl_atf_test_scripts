-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

------------------------------------ Common Variables ---------------------------------------
local app = {}
app[1] = common_functions:CreateRegisterAppParameters(
{appID = "1", appName = "Application1", isMediaApplication = true, appHMIType = {"MEDIA"}}
)
app[2] = common_functions:CreateRegisterAppParameters(
{appID = "2", appName = "Application2", isMediaApplication = true, appHMIType = {"MEDIA"}}
)
app[3] = common_functions:CreateRegisterAppParameters(
{appID = "3", appName = "Application3", isMediaApplication = true, appHMIType = {"MEDIA"}}
)
app[4] = common_functions:CreateRegisterAppParameters(
{appID = "4", appName = "Application4", isMediaApplication = false, appHMIType = {"NAVIGATION"}}
)

------------------------------------ Common Functions ---------------------------------------
-----------------------------------------------------------------------------
-- Register and Activate apps
-- @param register_app: list of the apps will be register
-- @param activate_app: list of the apps will be activate
-----------------------------------------------------------------------------
local function RegisterAndActivateApp(register_app, activate_app)
  for i =1, #register_app do
    local mobile_session_name = "mobile_session" .. i
    local app_name = register_app[i].appName
    common_steps:AddMobileSession("AddMobileSession" .. register_app[i].appID,_, mobile_session_name)
    common_steps:RegisterApplication("RegisterApplication" .. register_app[i].appID, mobile_session_name, app[i])
  end
  for i =1, #activate_app do
    local mobile_session_name = "mobile_session" .. activate_app[i].appID
    local app_name = activate_app[i].appName
    common_steps:ActivateApplication("ActivateApplication" .. activate_app[i].appID, app_name)
  end
end

-----------------------------------------------------------------------------
-- To subscribe the button
-- @param button: name of the button will be subscribed
-----------------------------------------------------------------------------
local function SubscribeButton(button)
  Test["Subscribe_" .. button] = function(self) 
    -- mobile side: sending SubscribeButton request
    local cid1 = self.mobile_session1:SendRPC("SubscribeButton", {buttonName = button})
    local cid2 = self.mobile_session2:SendRPC("SubscribeButton", {buttonName = button})
    local cid3 = self.mobile_session3:SendRPC("SubscribeButton", {buttonName = button})
    local cid4 = self.mobile_session4:SendRPC("SubscribeButton", {buttonName = button})
    --hmi side: expect Buttons.OnButtonSubscription
    EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", 
    {appID = self.applications[app[1].appID], isSubscribed = true, name = buttonName},
    {appID = self.applications[app[2].appID], isSubscribed = true, name = buttonName},
    {appID = self.applications[app[3].appID], isSubscribed = true, name = buttonName},
    {appID = self.applications[app[4].appID], isSubscribed = true, name = buttonName}
    )
    :Times(4)
    --mobile side: expect SubscribeButton response
    self.mobile_session1:ExpectResponse(cid1, { success = true, resultCode = "SUCCESS"})
    self.mobile_session2:ExpectResponse(cid2, { success = true, resultCode = "SUCCESS"})
    self.mobile_session3:ExpectResponse(cid3, { success = true, resultCode = "SUCCESS"})
    self.mobile_session4:ExpectResponse(cid4, { success = true, resultCode = "SUCCESS"})
    --mobile side: expect notification
    self.mobile_session1:ExpectNotification("OnHashChange", {})
    self.mobile_session2:ExpectNotification("OnHashChange", {})
    self.mobile_session3:ExpectNotification("OnHashChange", {})
    self.mobile_session4:ExpectNotification("OnHashChange", {})
  end
end

-----------------------------------------------------------------------------
-- Update the preload file for API SubcribeButton allow all HMILevels; OnButtonPress and OnButtonEvent disallow all HMILevels 
-----------------------------------------------------------------------------
local function UpdatePreloadFileAllowForSubscribeButtonDisallowForOnButtonPressAndOnButtonEvent()
  local pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
  local parent_item1 = {"policy_table","functional_groupings","Base-4","rpcs","SubscribeButton"}
  local added_json_items =
  [[{
    "hmi_levels" : ["BACKGROUND","FULL","LIMITED","NONE"]
  }
  ]]
  common_functions:AddItemsIntoJsonFile(pathToFile, parent_item1, added_json_items)
  local parent_item2 = {"policy_table","functional_groupings","Base-4","rpcs"}
  local removed_json_items =
  {
    "OnButtonPress", "OnButtonEvent"
  }
  common_functions:RemoveItemsFromJsonFile(pathToFile, parent_item2, removed_json_items)
end

-----------------------------------------------------------------------------
-- To check no notifications is sent to mobile when Policy disallow and OnButtonEvent/OnButtonPress() contains valid AppID
-- @param test_case_name: main test name
-- @param app: the app which send event
-----------------------------------------------------------------------------
local function OnButtonEventOnButtonPressWithValidAppIDDisallow(test_case_name, app)
  Test[test_case_name .. "_SendOnButtonPressEvent_PolicyDisallow_App" .. app.appID] = function(self)
    local mobile_session_send
    local all_mobile_sessions = {self.mobile_session1, self.mobile_session2, self.mobile_session3, self.mobile_session4} 
    if app.appID == "1" then
      mobile_session_send = self.mobile_session1
    elseif app.appID == "2" then
      mobile_session_send = self.mobile_session2
    elseif app.appID == "3" then
      mobile_session_send = self.mobile_session3
    elseif app.appID == "4" then
      mobile_session_send = self.mobile_session4
    end
    local hmi_app_id = common_functions:GetHmiAppId(app.appName, self)
    -- hmi side: send the OnButtonPress/ OnButtonEvent notification
    self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "OK", mode = "BUTTONDOWN", appID = hmi_app_id})
    self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "OK", mode = "BUTTONUP", appID = hmi_app_id})
    self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "OK", mode = "SHORT", appID = hmi_app_id})
    -- mobile side: expect notification will not receive
    common_functions:DelayedExp(12000)
    for i =1, #all_mobile_sessions do
      all_mobile_sessions[i]:ExpectNotification("OnButtonPress", {})
      :Times(0)
      all_mobile_sessions[i]:ExpectNotification("OnButtonEvent", {})
      :Times(0)
    end
  end
end

-----------------------------------------------------------------------------
-- To send notification and check notification from mobile when there is policy disallow and notification does not contain appID
-- @param test_case_name: main test name
-----------------------------------------------------------------------------
local function OnButtonEventOnButtonPressWithoutAppIDDisallow(test_case_name)
  Test[test_case_name .. "_SendOnButtonPressEventWithOutAppId_PolicyDisallow"] = function(self)
    local all_mobile_sessions = {self.mobile_session1, self.mobile_session2, self.mobile_session3, self.mobile_session4} 
    -- hmi side: send the OnButtonPress notification
    self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "OK", mode = "BUTTONDOWN"})
    self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "OK", mode = "BUTTONUP"})
    self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "OK", mode = "SHORT"})
    common_functions:DelayedExp(12000)
    for i =1, #all_mobile_sessions do
      all_mobile_sessions[i]:ExpectNotification("OnButtonPress", {})
      :Times(0)
      all_mobile_sessions[i]:ExpectNotification("OnButtonEvent", {})
      :Times(0)
    end
  end
end

-------------------------------------------Preconditions-------------------------------------
common_functions:BackupFile("sdl_preloaded_pt.json")
UpdatePreloadFileAllowForSubscribeButtonDisallowForOnButtonPressAndOnButtonEvent()
common_functions:DeleteLogsFileAndPolicyTable()
common_steps:PreconditionSteps("Precondition", 4)
RegisterAndActivateApp({app[1], app[2], app[3], app[4]}, {app[1], app[3], app[4]})
SubscribeButton("OK")

-----------------------------------------------Body------------------------------------------

---------------------------------------------------------------------------------------------
--[[ Requirement summary: SDL receives OnButtonPress/ OnButtonEvent (name= "OK", <valid_appID>) from HMI 
1.Preconditions:
1.1. There are 4 apps. 1st: BACKGROUND, 2nd: NONE, 3rd: LIMITED, 4th: FULL
1.2. OnButtonPress,OnButtonEvent and SubscribeButton are not allowed by Policy.
1.3. OK button is subscribed all 4 these apps.
2.Steps: HMI sends OnButtonEvent/OnButtonPress(with valid AppId)
3.Expected Result: SDL does not transfer OnButtonEvent/OnButtonPress to any app
]]
---------------------------------------------------------------------------------------------
common_steps:AddNewTestCasesGroup("Case 1: apps do not not receive notification OnButtonPress/ OnButtonEvent (name = \"OK\") when notification from HMI contains valid appID - Policy disallows")
OnButtonEventOnButtonPressWithValidAppIDDisallow("Case_1", app[1])
OnButtonEventOnButtonPressWithValidAppIDDisallow("Case_1", app[2])
OnButtonEventOnButtonPressWithValidAppIDDisallow("Case_1", app[3])
OnButtonEventOnButtonPressWithValidAppIDDisallow("Case_1", app[4])

---------------------------------------------------------------------------------------------
--[[ Requirement summary: SDL receives OnButtonPress/ OnButtonEvent (name= "OK") from HMI (without appID)
1.Preconditions:
1.1. There are 4 apps. 1st: BACKGROUND, 2nd: NONE, 3rd: LIMITED, 4th: FULL
1.2. OnButtonPress,OnButtonEvent and SubscribeButton are not allowed by Policy.
1.3. OK button is subscribed all 4 these apps.
2.Steps: HMI sends OnButtonEvent/OnButtonPress(without AppId)
3.Expected Result: SDL does not transfer OnButtonEvent/OnButtonPress to any app
]]
---------------------------------------------------------------------------------------------
common_steps:AddNewTestCasesGroup("Case 2: no apps (including FULL) receive the notification OnButtonPress/ OnButtonEvent when notification from HMI does not contain appID - Policy disallow")
OnButtonEventOnButtonPressWithoutAppIDDisallow("Case_2")

-------------------------------------------Postconditions-------------------------------------
Test["Restore file"] = function(self)
  common_functions:RestoreFile("sdl_preloaded_pt.json",1)
end

return Test
