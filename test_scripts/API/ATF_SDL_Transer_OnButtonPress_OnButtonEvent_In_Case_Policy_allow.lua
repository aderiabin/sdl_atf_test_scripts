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
-- Update the preload file for API SubcribeButton, OnButtonPress and OnButtonEvent allow all HMILevels
-----------------------------------------------------------------------------
local function UpdatePreloadFileAllowForSubscribeButtonAndOnButtonPressAndOnButtonEvent()
  local pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
  local parent_item1 = {"policy_table", "functional_groupings", "Base-4", "rpcs", "OnButtonPress"}
  local parent_item2 = {"policy_table", "functional_groupings", "Base-4", "rpcs", "OnButtonEvent"}
  local parent_item3 = {"policy_table", "functional_groupings", "Base-4", "rpcs", "SubscribeButton"}
  local added_json_items =
  [[
  {
    "hmi_levels" : ["BACKGROUND", "FULL", "LIMITED", "NONE"]
  }
  ]]
  common_functions:AddItemsIntoJsonFile(pathToFile, parent_item1, added_json_items)
  common_functions:AddItemsIntoJsonFile(pathToFile, parent_item2, added_json_items)
  common_functions:AddItemsIntoJsonFile(pathToFile, parent_item3, added_json_items)
end

-----------------------------------------------------------------------------
-- Check notifications is sent to mobile when OnButtonEvent/OnButtonPress(OK/CUSTOM_BUTTON) contains valid AppID
-- @param test_case_name: main test name
-- @param app: the app will be subscribed
-- @param button_name: name of the button send event
-- @param button_mode: the mode of pressing: LONG or SHORT
-- @param is_notification: TRUE/ FALSE: to check the notification will be send to mobile or not
-----------------------------------------------------------------------------
local function OnButtonEventOnButtonPressWithValidAppID(test_case_name, app,button_name, button_mode, is_notification)
  Test[test_case_name .. "_SendOnButtonPressEvent_" .. button_name .. "_" .. app.appID .. "_" .. button_mode] = function(self)
    local mobile_session_send
    local other_mobile_sessions
    local all_mobile_sessions = {self.mobile_session1, self.mobile_session2, self.mobile_session3, self.mobile_session4} 
    
    if app.appID == "1" then
      mobile_session_send = self.mobile_session1
      other_mobile_sessions = {self.mobile_session2, self.mobile_session3, self.mobile_session4} 
    elseif app.appID == "2" then
      mobile_session_send = self.mobile_session2
      other_mobile_sessions = {self.mobile_session1, self.mobile_session3, self.mobile_session4} 
    elseif app.appID == "3" then
      mobile_session_send = self.mobile_session3
      other_mobile_sessions = {self.mobile_session1, self.mobile_session2, self.mobile_session4} 
    elseif app.appID == "4" then
      mobile_session_send = self.mobile_session4
      other_mobile_sessions = {self.mobile_session1, self.mobile_session2, self.mobile_session3} 
    end
    
    local hmi_app_id = common_functions:GetHmiAppId(app.appName, self)
    -- hmi side: send the OnButtonPress/ OnButtonEvent notification
    self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = button_name, mode = "BUTTONDOWN", appID = hmi_app_id})
    self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = button_name, mode = "BUTTONUP", appID = hmi_app_id})
    self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = button_name, mode = button_mode, appID = hmi_app_id})
    -- to check notification should be send to mobile or not
    if is_notification == true then
      mobile_session_send:ExpectNotification("OnButtonPress", {buttonName = button_name, buttonPressMode = button_mode})
      mobile_session_send:ExpectNotification("OnButtonEvent", {buttonName = button_name, buttonEventMode = "BUTTONDOWN"}, {buttonName = button_name, buttonEventMode = "BUTTONUP"})
      :Times(2)
      for i =1, #other_mobile_sessions do
        other_mobile_sessions[i]:ExpectNotification("OnButtonPress", {})
        :Times(0)
        other_mobile_sessions[i]:ExpectNotification("OnButtonEvent", {})
        :Times(0)
      end	 
    else
      common_functions:DelayedExp(12000)
      for i =1, #all_mobile_sessions do
        all_mobile_sessions[i]:ExpectNotification("OnButtonPress", {})
        :Times(0)
        all_mobile_sessions[i]:ExpectNotification("OnButtonEvent", {})
        :Times(0)        
      end
    end
  end
end

-----------------------------------------------------------------------------
-- Check no notifications is sent to mobile when OnButtonEvent/OnButtonPress(OK) contains invalid AppID
-- @param test_case_name: main test name
-- @param button_mode: the mode of pressing: LONG or SHORT
-----------------------------------------------------------------------------
local function PressWithInvalidAppIDOk(test_case_name, button_mode)
  Test[test_case_name .. "_SendOnButtonPressEventWithInvalidAppId_OK_" .. button_mode] = function(self)
    local all_mobile_sessions = {self.mobile_session1, self.mobile_session2, self.mobile_session3, self.mobile_session4} 
    -- hmi side: send with invalid AppID
    self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "OK", mode = "BUTTONDOWN", appID = "1234567"})
    self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "OK", mode = "BUTTONUP", appID = "1234567"})
    self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "OK", mode = button_mode, appID = "1234567"})
    -- mobile side: expect no notification will receive
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
-- Check no notifications is sent to mobile when OnButtonEvent/OnButtonPress(CUSTOM_BUTTON) contains invalid appID
-- @param test_case_name: main test name
-- @param button_mode: the mode of pressing: LONG or SHORT
-- @param custom_button_id: id of CUSTOM_BUTTON [0-65536]
-----------------------------------------------------------------------------
local function OnButtonEventOnButtonPressWithInvalidAppIDCustomButton(test_case_name, button_mode, custom_button_id)
  Test[test_case_name .. "_SendOnButtonPressEventWithInvalidAppId_CUSTOM_BUTTON" .. button_mode .. "_" .. custom_button_id] = function(self)
    local all_mobile_sessions = {self.mobile_session1, self.mobile_session2, self.mobile_session3, self.mobile_session4} 
    -- hmi side: send with invalid AppID
    self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONDOWN", appID = "1234567", customButtonID = custom_button_id})
    if button_mode=="SHORT" then
      self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", appID = "1234567", customButtonID = custom_button_id})
      self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = button_mode, appID = "1234567", customButtonID = custom_button_id})
    else
      self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = "CUSTOM_BUTTON", mode = button_mode, appID = "1234567", customButtonID = custom_button_id})
      self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = "CUSTOM_BUTTON", mode = "BUTTONUP", appID = "1234567", customButtonID = custom_button_id})
    end
    -- mobile side: expect no notification will receive
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
-- Check that notifications are sent or not sent to app when OnButtonEvent/OnButtonPress() doesn't contain AppId
-- @param test_case_name: main test name
-- @param button_name: name of the button send event
-- @param button_mode: the mode of pressing: LONG or SHORT
-- @param is_notification: TRUE/ FALSE: to check the notification will be send to mobile or not
-----------------------------------------------------------------------------
local function OnButtonEventOnButtonPressWithoutAppID(test_case_name, button_name, button_mode, is_notification)
  Test[test_case_name .. "_SendOnButtonPressEventWithOutAppId_" .. button_name .. "_" .. button_mode] = function(self)
    local not_full_mobile_sessions = {self.mobile_session1, self.mobile_session2, self.mobile_session3} 
    -- hmi side: send the OnButtonPress notification
    self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = button_name, mode = "BUTTONDOWN"})
    self.hmiConnection:SendNotification("Buttons.OnButtonEvent", {name = button_name, mode = "BUTTONUP"})
    self.hmiConnection:SendNotification("Buttons.OnButtonPress", {name = button_name, mode = button_mode})
    if is_notification ==true then
      -- mobile side: the FULL app with expect get the OnButtonPress and Event. Other apps are not
      self.mobile_session4:ExpectNotification("OnButtonPress", {buttonName = button_name, buttonPressMode = button_mode})
      self.mobile_session4:ExpectNotification("OnButtonEvent", {buttonName = button_name, buttonEventMode = "BUTTONDOWN"}, {buttonName = button_name, buttonEventMode = "BUTTONUP"})
      :Times(2)
    else
      self.mobile_session4:ExpectNotification("OnButtonPress", {})
      :Times(0)
      self.mobile_session4:ExpectNotification("OnButtonEvent", {})
      :Times(0)
    end
    common_functions:DelayedExp(12000)
    for i =1, #not_full_mobile_sessions do
      not_full_mobile_sessions[i]:ExpectNotification("OnButtonPress", {})
      :Times(0)
      not_full_mobile_sessions[i]:ExpectNotification("OnButtonEvent", {})
      :Times(0)
    end
  end
end

-------------------------------------------Preconditions-------------------------------------
common_functions:BackupFile("sdl_preloaded_pt.json")
UpdatePreloadFileAllowForSubscribeButtonAndOnButtonPressAndOnButtonEvent()
common_functions:DeleteLogsFileAndPolicyTable()
common_steps:PreconditionSteps("Precondition", 4)
RegisterAndActivateApp({app[1], app[2], app[3], app[4]}, {app[1], app[3], app[4]})
SubscribeButton("OK")

-----------------------------------------------Body------------------------------------------
---------------------------------------------------------------------------------------------
--[[ Requirement summary: SDL receives OnButtonPress/ OnButtonEvent (name= "OK", <valid appID>) from HMI 
1.Preconditions:
1.1. There are 4 apps. 1st: BACKGROUND, 2nd: NONE, 3rd: LIMITED, 4th: FULL
1.2. OnButtonPress,OnButtonEvent and SubscribeButton are allowed by Policy.
1.3. OK button is subscribed all 4 these apps.
2.Steps: HMI sends OnButtonEvent/OnButtonPress(with valid AppId)
3.Expected Result: SDL transfer OnButtonEvent/OnButtonPress to FULL/ LIMITED app only.
]]
---------------------------------------------------------------------------------------------
common_steps:AddNewTestCasesGroup("Case 1: app in FULL/ LIMITED receive and app in BACKGROUND/ NONE does not receive notification OnButtonPress/ OnButtonEvent (name = \"OK\") when notification from HMI contains valid <appID> - Policy allows")
OnButtonEventOnButtonPressWithValidAppID("Case_1", app[1], "OK", "SHORT", false)
OnButtonEventOnButtonPressWithValidAppID("Case_1", app[2], "OK", "SHORT", false)
OnButtonEventOnButtonPressWithValidAppID("Case_1", app[3], "OK", "SHORT", true)
OnButtonEventOnButtonPressWithValidAppID("Case_1", app[4], "OK", "SHORT", true)

---------------------------------------------------------------------------------------------
--[[ Requirement summary: SDL receives OnButtonPress/ OnButtonEvent (name= "OK", <invalid_appID>) from HMI 
1.Preconditions:
1.1. There are 4 apps. 1st: BACKGROUND, 2nd: NONE, 3rd: LIMITED, 4th: LIMITED
1.2. OnButtonPress,OnButtonEvent and SubscribeButton are allowed by Policy.
1.3. OK button is subscribed all 4 these apps.
2.Steps: HMI sends OnButtonEvent/OnButtonPress(with invalid AppId)
3.Expected Result: SDL does not transfer OnButtonEvent/OnButtonPress to any app
]]
---------------------------------------------------------------------------------------------
common_steps:AddNewTestCasesGroup("Case 2: Check no apps receive the notification OnButtonPress/ OnButtonEvent (name = \"OK\") when notification from HMI contain invalid appID - Policy allows")
PressWithInvalidAppIDOk("Case_2", "SHORT")

---------------------------------------------------------------------------------------------
--[[ Requirement summary: SDL receives OnButtonPress/ OnButtonEvent (name= "CUSTOM_BUTTON", <invalid_appID>) from HMI 
1.Preconditions:
1.1. There are 4 apps. 1st: BACKGROUND, 2nd: NONE, 3rd: LIMITED, 4th: LIMITED
1.2. OnButtonPress,OnButtonEvent and SubscribeButton are allowed by Policy.
1.3. OK button is subscribed all 4 these apps.
2.Steps: HMI sends OnButtonEvent/OnButtonPress(with invalid AppId)
3.Expected Result: SDL does not transfer OnButtonEvent/OnButtonPress to any app
]]
---------------------------------------------------------------------------------------------
common_steps:AddNewTestCasesGroup("Case 3: Check no apps receive the notification OnButtonPress/ OnButtonEvent (name = \"CUSTOM_BUTTON\") when notification from HMI contain invalid appID - Policy allows")
OnButtonEventOnButtonPressWithInvalidAppIDCustomButton("Case_3", "SHORT", 0)
OnButtonEventOnButtonPressWithInvalidAppIDCustomButton("Case_3", "SHORT", 65536)
OnButtonEventOnButtonPressWithInvalidAppIDCustomButton("Case_3", "LONG", 0)
OnButtonEventOnButtonPressWithInvalidAppIDCustomButton("Case_3", "LONG", 65536)

--------------------------------------------------------------------------------------------- 
--[[ Requirement summary: SDL receives OnButtonPress/ OnButtonEvent (name= "OK") from HMI (without appID)
1.Preconditions:
1.1. There are 4 apps. 1st: BACKGROUND, 2nd: NONE, 3rd: LIMITED, 4th: FULL
1.2. OnButtonPress,OnButtonEvent and SubscribeButton are allowed by Policy.
1.3. OK button is subscribed all 4 these apps.
2.Steps: HMI sends OnButtonEvent/OnButtonPress(without valid AppId)
3.Expected Result: SDL transfer OnButtonEvent/OnButtonPress to FULL app only
]]
---------------------------------------------------------------------------------------------
common_steps:AddNewTestCasesGroup("Case 4: Check only app in FULL receive notification OnButtonPress/ OnButtonEvent (name = \"OK\") when notification from HMI does not contain appID. Other apps do not receive - Policy allows")
OnButtonEventOnButtonPressWithoutAppID("Case_4", "OK", "SHORT", true)

---------------------------------------------------------------------------------------------
--[[ Requirement summary: SDL receives OnButtonPress/ OnButtonEvent (name= "OK") from HMI (without appID)
1.Preconditions:
1.1. There are 4 apps. 1st: BACKGROUND, 2nd: NONE, 3rd: LIMITED, 4th: LIMITED
1.2. OnButtonPress,OnButtonEvent and SubscribeButton are allowed by Policy.
1.3. OK button is subscribed all 4 these apps.
2.Steps: HMI sends OnButtonEvent/OnButtonPress(without AppId)
3.Expected Result: SDL does not transfer OnButtonEvent/OnButtonPress to any app
]]
---------------------------------------------------------------------------------------------
common_steps:AddNewTestCasesGroup("Case 5: Check no apps receive the notification OnButtonPress/ OnButtonEvent (name = \"OK\") when notification from HMI does not contain appID and there is no app in FULL- Policy allows")
common_steps:ChangeHMIToLimited("Case_5_ChangeAppToLimited", app[4].appName)
OnButtonEventOnButtonPressWithoutAppID("Case_5", "OK", "SHORT", false)

-------------------------------------------Postconditions-------------------------------------
Test["Restore file"] = function(self)
  common_functions:RestoreFile("sdl_preloaded_pt.json",1)
end

return Test
