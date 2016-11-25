-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')
---------------------------------------------------------------------------------------------
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------
local iTimeout = 5000

MEDIA_APP = config.application1.registerAppInterfaceParams
MEDIA_APP.appName = "MEDIA"
MEDIA_APP.isMediaApplication = true
MEDIA_APP.appHMIType = {"MEDIA"}
MEDIA_APP.appID = "1"

BUTTON_NAME = "PLAY_PAUSE"
MOBILE_SESSION = "mobileSession"
MOBILE_CONNECTION = "mobileConnection"
BUTTON_PRESS_MODES = {"SHORT", "LONG"}	
BUTTON_EVENT_MODES = {"BUTTONDOWN","BUTTONUP"}
-------------------------------------------Preconditions-------------------------------------
-- common_steps:AddMobileConnection("AddDefaultMobileConnection_mobileConnection", MOBILE_CONNECTION)
-- common_steps:AddMobileSession("AddDefaultMobileConnect_mobileSession", "mobileConnection", MOBILE_SESSION)
common_steps:PreconditionSteps("Precondition", 5)
common_steps:RegisterApplication("RegisterApplication", MOBILE_SESSION, MEDIA_APP, {success = true, resultCode = "SUCCESS"}, {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
common_steps:ActivateApplication("ActivateApplication", MEDIA_APP.appName)
---------------------------------------------------------------------------------------------
-----------------------------------------------Body------------------------------------------
---------------------------------------------------------------------------------------------
local function CheckResults(cid, blnSuccess, strResultCode)
	EXPECT_RESPONSE(cid, {success = blnSuccess, resultCode = strResultCode})
	:Timeout(iTimeout)
	if strResultCode == "SUCCESS" then
		EXPECT_NOTIFICATION("OnHashChange")
		:Times(1)
		:Timeout(iTimeout)				
	else
		EXPECT_NOTIFICATION("OnHashChange")
		:Times(0)
		:Timeout(iTimeout)	
	end
end

local function SubcribeButton(test_case_name, subscribe_param, expect_hmi_notification, expect_response)
	Test[test_case_name] = function(self)
		subscribe_param = subscribe_param or {buttonName = BUTTON_NAME}
		local cid = self[MOBILE_SESSION]:SendRPC("SubscribeButton",subscribe_param)		
		expect_hmi_notification = expect_hmi_notification or {appID = self.applications[MEDIA_APP.appName], isSubscribed = true, name = BUTTON_NAME}
		EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", expect_hmi_notification)					
		expect_response = expect_response or {success = true, resultCode = "SUCCESS"}
		EXPECT_RESPONSE(cid, expect_response)
		:Timeout(iTimeout)					
		EXPECT_NOTIFICATION("OnHashChange")
	end
end

local function UnSubcribeButton(test_case_name, unsubscribe_param, expect_hmi_notification, expect_response)
	Test[test_case_name] = function(self)
		unsubscribe_param = unsubscribe_param or {buttonName = BUTTON_NAME}
		local cid = self[MOBILE_SESSION]:SendRPC("UnsubscribeButton",unsubscribe_param)		
		expect_hmi_notification = expect_hmi_notification or {appID = self.applications[MEDIA_APP.appName], isSubscribed = false, name = BUTTON_NAME}
		EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", expect_hmi_notification)					
		:Timeout(iTimeout)
		CheckResults(cid, true, "SUCCESS")
	end
end

local function OnButtonEvent(test_case_name)
	Test[test_case_name] = function(self)
		button_up = "BUTTONUP"
		button_down = "BUTTONDOWN"	
		self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = BUTTON_NAME, mode = button_down})
		self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = BUTTON_NAME, mode = button_up})
		self.hmiConnection:SendNotification("Buttons.OnButtonPress",{name = BUTTON_NAME, mode = BUTTON_PRESS_MODES[1]})			
		EXPECT_NOTIFICATION("OnButtonEvent", 
												{buttonName = BUTTON_NAME, buttonEventMode = button_down},
												{buttonName = BUTTON_NAME, buttonEventMode = button_up},
												{buttonName = BUTTON_NAME, buttonPressMode = BUTTON_PRESS_MODES[1]})
		:Times(2)
		EXPECT_NOTIFICATION("OnButtonPress", {buttonName = BUTTON_NAME, buttonPressMode = BUTTON_PRESS_MODES[1]})
	end
end

function TestSubscribeButton()
	common_steps:AddNewTestCasesGroup("TC_Subscribe_Button" )
	SubcribeButton("SubcribeButton_" .. BUTTON_NAME .. "_Success")

	UnSubcribeButton("UnSubcribeButton")
	SubcribeButton("SubcribeButton_" .. BUTTON_NAME .. "_Fake_Param",{fakeParameter = "fakeParameter", buttonName = BUTTON_NAME})

	UnSubcribeButton("UnSubcribeButton")
	SubcribeButton("SubcribeButton_" .. BUTTON_NAME .. "_Parameter_Of_Other_API",{syncFileName = "icon.png",buttonName = BUTTON_NAME})
end	
TestSubscribeButton()

function TestUnSubscribeButton()
	common_steps:AddNewTestCasesGroup("TC_UnSubscribe_Button" )
	UnSubcribeButton("UnSubcribeButton_" .. BUTTON_NAME .. "_Success")
	
	SubcribeButton("SubcribeButton")
	UnSubcribeButton("UnSubcribeButton_" .. BUTTON_NAME .. "_Fake_Param",{fakeParameter = "fakeParameter", buttonName = BUTTON_NAME})
	
	SubcribeButton("SubcribeButton")
	UnSubcribeButton("UnSubcribeButton_" .. BUTTON_NAME .. "_Parameter_Of_Other_API",{syncFileName = "icon.png",buttonName = BUTTON_NAME})
end	
TestUnSubscribeButton()
