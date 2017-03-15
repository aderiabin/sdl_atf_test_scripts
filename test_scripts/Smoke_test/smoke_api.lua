-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')
------------------------------------ Common Variables ---------------------------------------
local storagePath = config.pathToSDL .. "storage/"..config.application1.registerAppInterfaceParams.appID.. "_" .. config.deviceMAC.. "/"
local textPromtValue = {"Please speak one of the following commands,", "Please say a command,"}
local audibleState
if config.application1.registerAppInterfaceParams.isMediaApplication == true or
Test.appHMITypes.COMMUNICATION == true or
Test.appHMITypes.NAVIGATION == true then
	audibleState = "AUDIBLE"
elseif config.application1.registerAppInterfaceParams.isMediaApplication == false then
	audibleState = "NOT_AUDIBLE"
end
-------------------------------------------Preconditions-------------------------------------
common_functions:DeleteLogsFileAndPolicyTable()
common_functions:BackupFile("sdl_preloaded_pt.json")
--1. Activate application
common_steps:PreconditionSteps("PreconditionSteps", 7)
--2. Backup sdl_preloaded_pt.json then updatePolicy
update_policy:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/PTU_For_SmokeTesting.json")
--------------------------------------------BODY---------------------------------------------
----------------------------------Positive checks of all APIs--------------------------------
-- TC1_Description: PutFiles
common_steps:PutFile("PutFile_action.png", "action.png")
common_steps:PutFile("PutFile_MaxLength_255Characters", string.rep("a", 251) .. ".png")
common_steps:PutFile("Putfile_SpaceBefore", " SpaceBefore")
common_steps:PutFile("Putfile_Icon.png", "icon.png")
-------------------------------------------------------------------------------
-- TC2_Description: SetGlobalProperties
function Test:SetGlobalProperties_PositiveCase()
	local cid = self.mobileSession:SendRPC("SetGlobalProperties",
	{
		menuTitle = "Menu Title",
		timeoutPrompt =
		{
			{
				text = "Timeout prompt",
				type = "TEXT"
			}
		},
		vrHelp =
		{
			{
				position = 1,
				image =
				{
					value = "icon.png",
					imageType = "DYNAMIC"
				},
				text = "VR help item"
			}
		},
		menuIcon =
		{
			value = "icon.png",
			imageType = "DYNAMIC"
		},
		helpPrompt =
		{
			{
				text = "Help prompt",
				type = "TEXT"
			}
		},
		vrHelpTitle = "VR help title",
		keyboardProperties =
		{
			keyboardLayout = "QWERTY",
			keypressMode = "SINGLE_KEYPRESS",
			language = "EN-US"
		}
	})
	EXPECT_HMICALL("TTS.SetGlobalProperties",
	{
		timeoutPrompt =
		{
			{
				text = "Timeout prompt",
				type = "TEXT"
			}
		},
		helpPrompt =
		{
			{
				text = "Help prompt",
				type = "TEXT"
			}
		}
	})
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	EXPECT_HMICALL("UI.SetGlobalProperties",
	{
		menuTitle = "Menu Title",
		vrHelp =
		{
			{
				position = 1,
				image =
				{
					imageType = "DYNAMIC",
					value = storagePath.."icon.png"
				},
				text = "VR help item"
			}
		},
		menuIcon =
		{
			imageType = "DYNAMIC",
			value = storagePath.."icon.png"
		},
		vrHelpTitle = "VR help title",
		keyboardProperties =
		{
			keyboardLayout = "QWERTY",
			keypressMode = "SINGLE_KEYPRESS",
			language = "EN-US"
		}
	})
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
	EXPECT_NOTIFICATION("OnHashChange")
end
-------------------------------------------------------------------------------
-- TC3_Description: ResetGlobalProperties request resets the requested GlobalProperty values to default ones
function Test:ResetGlobalProperties_PositiveCase()
	local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
	{
		properties =
		{
			"VRHELPTITLE",
			"MENUNAME",
			"MENUICON",
			"KEYBOARDPROPERTIES",
			"VRHELPITEMS",
			"HELPPROMPT",
			"TIMEOUTPROMPT"
		}
	})
	EXPECT_HMICALL("TTS.SetGlobalProperties",
	{
		helpPrompt =
		{
			{
				type = "TEXT",
				text = textPromtValue[1]
			},
			{
				type = "SILENCE",
				text = "300"
			},
			{
				type = "TEXT",
				text = textPromtValue[2]
			},
			{
				type = "SILENCE",
				text = "300"
			}
		},
		timeoutPrompt =
		{
			{
				type = "TEXT",
				text = textPromtValue[1]
			},
			{
				type = "TEXT",
				text = textPromtValue[2]
			}
		}
	})
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	EXPECT_HMICALL("UI.SetGlobalProperties",
	{
		menuTitle = "",
		vrHelpTitle = "Test Application",
		keyboardProperties =
		{
			keyboardLayout = "QWERTY",
			language = "EN-US"
		},
		vrHelp = nil
	})
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
	EXPECT_NOTIFICATION("OnHashChange")
end
-------------------------------------------------------------------------------
-- TC4_Description: AddCommand
function Test:AddCommand_PositiveCase()
	local cid = self.mobileSession:SendRPC("AddCommand",
	{
		cmdID = 11,
		menuParams =
		{
			position = 0,
			menuName ="Commandpositive"
		},
		vrCommands =
		{
			"VRCommandonepositive",
			"VRCommandonepositivedouble"
		},
		cmdIcon =
		{
			value ="icon.png",
			imageType ="DYNAMIC"
		}
	})
	EXPECT_HMICALL("UI.AddCommand",
	{
		cmdID = 11,
		cmdIcon =
		{
			value = storagePath.."icon.png",
			imageType = "DYNAMIC"
		},
		menuParams =
		{
			position = 0,
			menuName ="Commandpositive"
		}
	})
	:Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	EXPECT_HMICALL("VR.AddCommand",
	{
		cmdID = 11,
		type = "Command",
		vrCommands =
		{
			"VRCommandonepositive",
			"VRCommandonepositivedouble"
		}
	})
	:Do(function(_,data)
    grammarIDValue = data.params.grammarID
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
	EXPECT_NOTIFICATION("OnHashChange")
end

------------------------------------------------------------------------------
-- TC_Description: OnCommand
function Test:OnCommand_UI()	
  self.hmiConnection:SendNotification("UI.OnCommand", {
    cmdID = 11,
    appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)})
  EXPECT_NOTIFICATION("OnCommand", {cmdID = 11, triggerSource= "MENU"})
end

function Test:OnCommand_VR()
  self.hmiConnection:SendNotification("VR.OnCommand", {
    cmdID = 11,
    grammarID = grammarIDValue})
  EXPECT_NOTIFICATION("OnCommand", {cmdID = 11, triggerSource= "VR"})
end

------------------------------------------------------------------------------
-- TC5_Description: DeleteCommand
function Test:DeleteCommand_PositiveCase()
	local cid = self.mobileSession:SendRPC("DeleteCommand",{ cmdID = 11})
	EXPECT_HMICALL("UI.DeleteCommand",
	{
		cmdID = 11,
		appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
	})
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	EXPECT_HMICALL("VR.DeleteCommand",
	{
		cmdID = 11,
		type = "Command",
		grammarID = data.params.grammarID,
		appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
	})
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
	EXPECT_NOTIFICATION("OnHashChange")
end
-------------------------------------------------------------------------------
-- TC6_Description: AddSubMenu
function Test:AddSubMenu_PositiveCase()
	local cid = self.mobileSession:SendRPC("AddSubMenu",{
		menuID = 1000,
		position = 500,
		menuName ="SubMenupositive"
	})
	EXPECT_HMICALL("UI.AddSubMenu",
	{
		menuID = 1000,
		menuParams = {
			position = 500,
			menuName ="SubMenupositive"
		}
	})
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
	EXPECT_NOTIFICATION("OnHashChange")
end
-------------------------------------------------------------------------------
-- TC7_Description: DeleteSubMenu
function Test:DeleteSubMenu_PositiveCase()
	local cid = self.mobileSession:SendRPC("DeleteSubMenu", { menuID = 1000})
	EXPECT_HMICALL("UI.DeleteSubMenu",
	{
		menuID = 1000,
		appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
	})
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
	EXPECT_NOTIFICATION("OnHashChange")
end
-------------------------------------------------------------------------------
-- TC8_Description: Alert
function Test:Alert_PositiveCase()
	local cor_id_alert = self.mobileSession:SendRPC("Alert",
	{
		alertText1 = "alertText1",
		alertText2 = "alertText2",
		alertText3 = "alertText3",
		ttsChunks =
		{
			{
				text = "TTSChunk",
				type = "TEXT"
			}
		},
		duration = 3000,
		playTone = true,
		progressIndicator = true,
		softButtons =
		{
			{
				type = "BOTH",
				text = "Close",
				image =
				{
					value = "icon.png",
					imageType = "DYNAMIC"
				},
				isHighlighted = true,
				softButtonID = 3,
				systemAction = "DEFAULT_ACTION"
			},
			{
				type = "TEXT",
				text = "Keep",
				isHighlighted = true,
				softButtonID = 4,
				systemAction = "DEFAULT_ACTION"
			},
			{
				type = "IMAGE",
				image =
				{
					value = "icon.png",
					imageType = "DYNAMIC"
				},
				softButtonID = 5,
				systemAction = "DEFAULT_ACTION"
			},
		}
	})
	local alert_id
	EXPECT_HMICALL("UI.Alert",
	{
		alertStrings =
		{
			{fieldName = "alertText1", fieldText = "alertText1"},
			{fieldName = "alertText2", fieldText = "alertText2"},
			{fieldName = "alertText3", fieldText = "alertText3"}
		},
		alertType = "BOTH",
		duration = 3000,
		progressIndicator = true,
		softButtons =
		{
			{
				type = "BOTH",
				text = "Close",
				image =
				{
					value = storagePath .. "icon.png",
					imageType = "DYNAMIC"
				},
				isHighlighted = true,
				softButtonID = 3,
				systemAction = "DEFAULT_ACTION"
			},
			{
				type = "TEXT",
				text = "Keep",
				isHighlighted = true,
				softButtonID = 4,
				systemAction = "DEFAULT_ACTION"
			},
			{
				type = "IMAGE",
				image =
				{
					value = storagePath .. "icon.png",
					imageType = "DYNAMIC"
				},
				softButtonID = 5,
				systemAction = "DEFAULT_ACTION"
			},
		}
	})
	:Do(function(_,data)
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self), systemContext = "ALERT"})
		alert_id = data.id
		local function alert_response()
			self.hmiConnection:SendResponse(alert_id, "UI.Alert", "SUCCESS", {})
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self), systemContext = "MAIN"})
		end
		RUN_AFTER(alert_response, 3000)
	end)
	local speak_id
	EXPECT_HMICALL("TTS.Speak",
	{
		ttsChunks =
		{
			{
				text = "TTSChunk",
				type = "TEXT"
			}
		},
		speakType = "ALERT",
		playTone = true
	})
	:Do(function(_,data)
		self.hmiConnection:SendNotification("TTS.Started")
		speak_id = data.id
		local function speakResponse()
			self.hmiConnection:SendResponse(speak_id, "TTS.Speak", "SUCCESS", { })
			self.hmiConnection:SendNotification("TTS.Stopped")
		end
		RUN_AFTER(speakResponse, 2000)
	end)
	:ValidIf(function(_,data)
		if #data.params.ttsChunks == 1 then
			return true
		else
			print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1, actual "..tostring(#data.params.ttsChunks))
			return false
		end
	end)
	EXPECT_NOTIFICATION("OnHMIStatus",
	{ systemContext = "ALERT", hmiLevel = level, audioStreamingState = "AUDIBLE" },
	{ systemContext = "ALERT", hmiLevel = level, audioStreamingState = "ATTENUATED" },
	{ systemContext = "ALERT", hmiLevel = level, audioStreamingState = "AUDIBLE" },
	{ systemContext = "MAIN", hmiLevel = level, audioStreamingState = "AUDIBLE" })
	:Times(4)
	EXPECT_RESPONSE(cor_id_alert, { success = true, resultCode = "SUCCESS" })
end
-------------------------------------------------------------------------------
-- TC9_Description: CreateInteractionChoiceSet
choice_set_id_values = {0, 100, 200, 300, 2000000000}
choice_id_values     = {0, 100, 200, 300, 65535}
for i=1, #choice_set_id_values do
  Test["CreateInteractionChoiceSet_Positive_Id_" .. tostring(choice_set_id_values[i])] = function(self)
    local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet", {
      interactionChoiceSetID = choice_set_id_values[i],
      choiceSet = {{
        choiceID = choice_id_values[i],
        menuName = "Choice" .. tostring(choice_id_values[i]),
        vrCommands = {"Choice" .. tostring(choice_id_values[i])},
        image = {
          value ="action.png",
          imageType ="DYNAMIC"}}}})
    EXPECT_HMICALL("VR.AddCommand", {
      cmdID = choice_id_values[i],
      appID = applicationID,
      type = "Choice",
      vrCommands = {"Choice" .. tostring(choice_id_values[i])}})
    :Do(function(_,data)
      grammarIDValue = data.params.grammarID
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
    EXPECT_NOTIFICATION("OnHashChange")
  end
end

-------------------------------------------------------------------------------
-- TC10_Description: PerformInteraction
local interaction_modes = {"MANUAL_ONLY", "VR_ONLY", "BOTH"}
local interaction_layouts = {"ICON_ONLY", "ICON_WITH_SEARCH", "LIST_ONLY", "LIST_WITH_SEARCH", "KEYBOARD"}
for i = 1, #interaction_layouts do
  local interaction_mode
  if i > #interaction_modes then
    interaction_mode = interaction_modes[#interaction_modes]
  else
    interaction_mode = interaction_modes[i]
  end
  Test["PerformInteraction_Positive_Mode_" .. interaction_mode .. "_layout_" .. interaction_layouts[i]] = function(self)
    local cid = self.mobileSession:SendRPC("PerformInteraction", {
      initialText ="StartPerformInteraction",
      initialPrompt = {{
        text ="Makeyourchoice",
        type ="TEXT"}},
      interactionMode = interaction_mode,
      interactionChoiceSetIDList = {100},
      helpPrompt = {{
        text ="ChoosethevariantonUI",
        type ="TEXT"}},
      timeoutPrompt = {{
        text ="Timeisout",
        type ="TEXT"}},
      timeout = 5000,
      vrHelp = {{
        text = "Help2",
        position = 1,
      image = {
        value ="action.png",
        imageType ="DYNAMIC"}}},
      interactionLayout = interaction_layouts[i]})
    EXPECT_HMICALL("VR.PerformInteraction", {})
    :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    local parameter = {event = "KEYPRESS", data = "abc"}
    EXPECT_HMICALL("UI.PerformInteraction", {})
    :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      if interaction_layouts[i] == "KEYBOARD" then
        self.hmiConnection:SendNotification("UI.OnKeyboardInput",parameter)
      end
    end)
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
    if interaction_layouts[i] == "KEYBOARD" then
      EXPECT_NOTIFICATION("OnKeyboardInput", parameter)
    end
  end
end

-------------------------------------------------------------------------------
-- TC11_Description: OnKeyboardInput
local keyboard_event = {
  "KEYPRESS", 
  "ENTRY_SUBMITTED", 
  "ENTRY_VOICE", 
  "ENTRY_CANCELLED", 
  "ENTRY_ABORTED"}
for i = 1, #keyboard_event  do
  Test["OnKeyboardInput_PositiveCase_" .. keyboard_event[i]] = function(self)
    local parameter = {
      event = keyboard_event[i], 
      data = "abc"}
    self.hmiConnection:SendNotification("UI.OnKeyboardInput",	parameter)
    EXPECT_NOTIFICATION("OnKeyboardInput", parameter)
  end
end

-------------------------------------------------------------------------------
-- TC12_Description: DeleteInteractionChoiceSet
function Test:DeleteInteractionChoiceSet_Positive()
	local cid = self.mobileSession:SendRPC("DeleteInteractionChoiceSet",{interactionChoiceSetID = 0})
	EXPECT_HMICALL("VR.DeleteCommand",
	{cmdID = 0,
		type = "Choice",
		grammarID = data.params.grammarID,
		appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
	}
	)
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
	EXPECT_NOTIFICATION("OnHashChange")
end

-------------------------------------------------------------------------------
-- TC13_Description: DeleteFile
function Test:DeleteFile_PositiveCase()
	local cid = self.mobileSession:SendRPC("DeleteFile",{ syncFileName = "action.png"})
	EXPECT_HMINOTIFICATION("BasicCommunication.OnFileRemoved", {
		fileName = storagePath.. "action.png",
		fileType = "GRAPHIC_PNG",
		appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
	})
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
end
-------------------------------------------------------------------------------
-- TC14_Description: ListFiles
function Test:ListFiles_PositiveCase()
	local cid = self.mobileSession:SendRPC("ListFiles", {} )
	EXPECT_RESPONSE(cid,
	{
		success = true,
		resultCode = "SUCCESS",
		filenames = {
			" SpaceBefore",
			string.rep("a", 251) .. ".png",
			"icon.png"
		},
	})
end

-------------------------------------------------------------------------------
-- TC15_Description: ScrollableMessage
function Test:ScrollableMessage_PositiveCase()
	local cid = self.mobileSession:SendRPC("ScrollableMessage", {
		scrollableMessageBody = "abc",
		softButtons =
		{
			{
				softButtonID = 1,
				text = "Button1",
				type = "BOTH",
				image =
				{
					value = "icon.png",
					imageType = "DYNAMIC"
				},
				isHighlighted = false,
				systemAction = "DEFAULT_ACTION"
			},
			{
				softButtonID = 2,
				text = "Button2",
				type = "BOTH",
				image =
				{
					value = "icon.png",
					imageType = "DYNAMIC"
				},
				isHighlighted = false,
				systemAction = "DEFAULT_ACTION"
			}
		},
		timeout = 5000
	})
	EXPECT_HMICALL("UI.ScrollableMessage",{
		messageText = {
			fieldName = "scrollableMessageBody",
			fieldText = "abc"
		},
		softButtons =
		{
			{
				softButtonID = 1,
				text = "Button1",
				type = "BOTH",
				image =
				{
					value = storagePath.."icon.png",
					imageType = "DYNAMIC"
				},
				isHighlighted = false,
				systemAction = "DEFAULT_ACTION"
			},
			{
				softButtonID = 2,
				text = "Button2",
				type = "BOTH",
				image =
				{
					value = storagePath.."icon.png",
					imageType = "DYNAMIC"
				},
				isHighlighted = false,
				systemAction = "DEFAULT_ACTION"
			}
		},
		timeout = 5000
	} )
	:Do(function(_,data)
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "HMI_OBSCURED" })
		local function scrollableMessageResponse()
			self.hmiConnection:SendResponse(data.id, "UI.ScrollableMessage", "SUCCESS", {})
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
		end
		RUN_AFTER(scrollableMessageResponse, 1000)
	end)
	EXPECT_NOTIFICATION("OnHMIStatus",
	{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
	{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState}
	)
	:Times(2)
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
end
-------------------------------------------------------------------------------
-- TC16_Description: SetMediaClockTimer
local update_mode = {"COUNTUP", "COUNTDOWN", "PAUSE", "RESUME", "CLEAR"}
for i=1,#update_mode do
	Test["SetMediaClockTimer_PositiveCase_" .. tostring(update_mode[i]).."_SUCCESS"] = function(self)
		count_down = 0
		if update_mode[i] == "COUNTDOWN" then
			count_down = -1
		end
		local cid = self.mobileSession:SendRPC("SetMediaClockTimer",
		{
			startTime =
			{
				hours = 0,
				minutes = 1,
				seconds = 33
			},
			endTime =
			{
				hours = 0,
				minutes = 1 + count_down,
				seconds = 35
			},
			updateMode = update_mode[i]
		})
		EXPECT_HMICALL("UI.SetMediaClockTimer",
		{
			startTime =
			{
				hours = 0,
				minutes = 1,
				seconds = 33
			},
			endTime =
			{
				hours = 0,
				minutes = 1 + count_down,
				seconds = 35
			},
			updateMode = update_mode[i]
		})
		:Do(function(_,data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
	end
end
-------------------------------------------------------------------------------
-- TC17_Description: Show
function Test:createUIParameters(Request)
	local param = {}
	param["alignment"] = Request["alignment"]
	param["customPresets"] = Request["customPresets"]
	local j = 0
	for i = 1, 4 do
		if Request["mainField" .. i] ~= nil then
			j = j + 1
			if param["showStrings"] == nil then
				param["showStrings"] = {}
			end
			param["showStrings"][j] = {
				fieldName = "mainField" .. i,
				fieldText = Request["mainField" .. i]
			}
		end
	end
	if Request["mediaClock"] ~= nil then
		j = j + 1
		if param["showStrings"] == nil then
			param["showStrings"] = {}
		end
		param["showStrings"][j] = {
			fieldName = "mediaClock",
			fieldText = Request["mediaClock"]
		}
	end
	if Request["mediaTrack"] ~= nil then
		j = j + 1
		if param["showStrings"] == nil then
			param["showStrings"] = {}
		end
		param["showStrings"][j] = {
			fieldName = "mediaTrack",
			fieldText = Request["mediaTrack"]
		}
	end
	if Request["statusBar"] ~= nil then
		j = j + 1
		if param["showStrings"] == nil then
			param["showStrings"] = {}
		end
		param["showStrings"][j] = {
			fieldName = "statusBar",
			fieldText = Request["statusBar"]
		}
	end
	param["graphic"] = Request["graphic"]
	if param["graphic"] ~= nil and
	param["graphic"].imageType ~= "STATIC" and
	param["graphic"].value ~= nil and
	param["graphic"].value ~= "" then
		param["graphic"].value = storagePath ..param["graphic"].value
	end
	param["secondaryGraphic"] = Request["secondaryGraphic"]
	if param["secondaryGraphic"] ~= nil and
	param["secondaryGraphic"].imageType ~= "STATIC" and
	param["secondaryGraphic"].value ~= nil and
	param["secondaryGraphic"].value ~= "" then
		param["secondaryGraphic"].value = storagePath ..param["secondaryGraphic"].value
	end
	if Request["softButtons"] ~= nil then
		param["softButtons"] = Request["softButtons"]
		for i = 1, #param["softButtons"] do
			if param["softButtons"][i].type == "TEXT" then
				param["softButtons"][i].image = nil
			elseif param["softButtons"][i].type == "IMAGE" then
				param["softButtons"][i].text = nil
			end
			if param["softButtons"][i].image ~= nil and
			param["softButtons"][i].image.imageType ~= "STATIC" then
				param["softButtons"][i].image.value = storagePath ..param["softButtons"][i].image.value
			end
		end
	end
	return param
end

function Test:Show_PositiveCase()
	local request_params =
	{
		mainField1 = "a",
		mainField2 = "a",
		mainField3 = "a",
		mainField4 = "a",
		statusBar= "a",
		mediaClock = "a",
		mediaTrack = "a",
		alignment = "CENTERED",
		graphic =
		{
			imageType = "DYNAMIC",
			value = "icon.png"
		},
		secondaryGraphic =
		{
			imageType = "DYNAMIC",
			value = "icon.png"
		}
	}
	local cid = self.mobileSession:SendRPC("Show", request_params)
	UIParams = self:createUIParameters(request_params)
	EXPECT_HMICALL("UI.Show", UIParams)
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
end
-------------------------------------------------------------------------------
-- TC18_Description: ShowConstantTBT
function Test:createUIParameters_For_ShowConstant(request_params)
	local param = {}
	param["maneuverComplete"] = request_params["maneuverComplete"]
	param["distanceToManeuver"] = request_params["distanceToManeuver"]
	param["distanceToManeuverScale"] = request_params["distanceToManeuverScale"]
	local j = 0
	if request_params["navigationText1"] ~= nil then
		j = j + 1
		if param["navigationTexts"] == nil then
			param["navigationTexts"] = {}
		end
		param["navigationTexts"][j] = {
			fieldName = "navigationText1",
			fieldText = request_params["navigationText1"]
		}
	end
	if request_params["navigationText2"] ~= nil then
		j = j + 1
		if param["navigationTexts"] == nil then
			param["navigationTexts"] = {}
		end
		param["navigationTexts"][j] = {
			fieldName = "navigationText2",
			fieldText = request_params["navigationText2"]
		}
	end
	if request_params["eta"] ~= nil then
		j = j + 1
		if param["navigationTexts"] == nil then
			param["navigationTexts"] = {}
		end
		param["navigationTexts"][j] = {
			fieldName = "ETA",
			fieldText = request_params["eta"]
		}
	end
	if request_params["totalDistance"] ~= nil then
		j = j + 1
		if param["navigationTexts"] == nil then
			param["navigationTexts"] = {}
		end
		param["navigationTexts"][j] = {
			fieldName = "totalDistance",
			fieldText = request_params["totalDistance"]
		}
	end
	if request_params["timeToDestination"] ~= nil then
		j = j + 1
		if param["navigationTexts"] == nil then
			param["navigationTexts"] = {}
		end
		param["navigationTexts"][j] = {
			fieldName = "timeToDestination",
			fieldText = request_params["timeToDestination"]
		}
	end
	param["nextTurnIcon"] = request_params["nextTurnIcon"]
	if param["nextTurnIcon"] ~= nil and
	param["nextTurnIcon"].imageType ~= "STATIC" and
	param["nextTurnIcon"].value ~= nil and
	param["nextTurnIcon"].value ~= "" then
		param["nextTurnIcon"].value = storagePath ..param["nextTurnIcon"].value
	end
	param["turnIcon"] = request_params["turnIcon"]
	if param["turnIcon"] ~= nil and
	param["turnIcon"].imageType ~= "STATIC" and
	param["turnIcon"].value ~= nil and
	param["turnIcon"].value ~= "" then
		param["turnIcon"].value = storagePath ..param["turnIcon"].value
	end
	if request_params["softButtons"] ~= nil then
		if next(request_params["softButtons"]) == nil then
			request_params["softButtons"] = nil
		else
			param["softButtons"] = request_params["softButtons"]
			for i = 1, #param["softButtons"] do
				if param["softButtons"][i].type == "TEXT" then
					param["softButtons"][i].image = nil
				elseif param["softButtons"][i].type == "IMAGE" then
					param["softButtons"][i].text = nil
				end
				if param["softButtons"][i].image ~= nil and
				param["softButtons"][i].image.imageType ~= "STATIC" then
					param["softButtons"][i].image.value = storagePath ..param["softButtons"][i].image.value
				end
				if param["softButtons"][i].systemAction == nil then
					param["softButtons"][i].systemAction = "DEFAULT_ACTION"
				end
			end
		end
	end
	return param
end

common_steps:PutFile("PutFile_action.png", "action.png")
function Test:ShowConstantTBT_PositiveCase()
	local request_paramters = {
		navigationText1 ="navigationText1",
		navigationText2 ="navigationText2",
		eta ="12:34",
		totalDistance ="100miles",
		turnIcon =
		{
			value ="icon.png",
			imageType ="DYNAMIC"
		},
		nextTurnIcon =
		{
			value = "action.png",
			imageType ="DYNAMIC"
		},
		distanceToManeuver = 50.5,
		distanceToManeuverScale = 100.5,
		maneuverComplete = false,
		softButtons =
		{
			{
				type ="BOTH",
				text ="Close",
				image =
				{
					value ="icon.png",
					imageType ="DYNAMIC"
				},
				isHighlighted = true,
				softButtonID = 44,
				systemAction ="DEFAULT_ACTION"
			},
		},
	}
	local cid = self.mobileSession:SendRPC("ShowConstantTBT", request_paramters)
	local ui_params = self:createUIParameters_For_ShowConstant(request_paramters)
	EXPECT_HMICALL("Navigation.ShowConstantTBT", ui_params)
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
end
-------------------------------------------------------------------------------
-- TC19_Description: Slider
function Test:Slider_PositiveCase()
	local request =
	{
		numTicks = 7,
		position = 1,
		sliderHeader ="sliderHeader",
		timeout = 1000
	}
	local cid = self.mobileSession:SendRPC("Slider", request)
	local UIRequest =
	{
		numTicks = 7,
		position = 1,
		sliderHeader ="sliderHeader",
		timeout = 1000
	}
	EXPECT_HMICALL("UI.Slider", UIRequest)
	:Do(function(_,data)
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self), systemContext = "HMI_OBSCURED" })
		local function sendReponse()
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {sliderPosition = 1})
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self), systemContext = "MAIN" })
		end
		RUN_AFTER(sendReponse, 1000)
	end)
	EXPECT_NOTIFICATION("OnHMIStatus",
	{systemContext = "HMI_OBSCURED", hmiLevel = "FULL", audioStreamingState = audibleState},
	{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = audibleState})
	:Times(2)
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS", sliderPosition = 1 })
end
-------------------------------------------------------------------------------
-- Precondtion:UpdateHmiCapabilities using for SendLocation
local HmiCapabilities = config.pathToSDL .. "hmi_capabilities.json"
common_preconditions:BackupFile("hmi_capabilities.json")
f = assert(io.open(HmiCapabilities, "r"))
fileContent = f:read("*all")
fileContentTextFields = fileContent:match("%s-\"%s?textFields%s?\"%s-:%s-%[[%w%d%s,:%{%}\"]+%]%s-,?")
if not fileContentTextFields then
	print ( " \27[31m textFields is not found in hmi_capabilities.json \27[0m " )
else
	fileContentTextFieldsContant = fileContent:match("%s-\"%s?textFields%s?\"%s-:%s-%[([%w%d%s,:%{%}\"]+)%]%s-,?")
	if not fileContentTextFieldsContant then
		print ( " \27[31m textFields contant is not found in hmi_capabilities.json \27[0m " )
	else
		fileContentTextFieldsContantTab = fileContent:match("%s-\"%s?textFields%s?\"%s-:%s-%[.+%{\n([^\n]+)(\"name\")")
		local StringToReplace = fileContentTextFieldsContant
		fileContentLocationNameFind = fileContent:match("locationName")
		if not fileContentLocationNameFind then
			local ContantToAdd = ",\n " .. tostring(fileContentTextFieldsContantTab) .. " { \"name\": \"locationName\",\"characterSet\": \"TYPE2SET\",\"width\": 500,\"rows\": 1 }"
			StringToReplace = StringToReplace .. ContantToAdd
		end
		fileContentLocationDescriptionFind = fileContent:match("locationDescription")
		if not fileContentLocationDescriptionFind then
			local ContantToAdd = ",\n " .. tostring(fileContentTextFieldsContantTab) .. " { \"name\": \"locationDescription\",\"characterSet\": \"TYPE2SET\",\"width\": 500,\"rows\": 1 }"
			StringToReplace = StringToReplace .. ContantToAdd
		end
		fileContentAddressLinesFind = fileContent:match("addressLines")
		if not fileContentAddressLinesFind then
			local ContantToAdd = ",\n " .. tostring(fileContentTextFieldsContantTab) .. " { \"name\": \"addressLines\",\"characterSet\": \"TYPE2SET\",\"width\": 500,\"rows\": 1 }"
			StringToReplace = StringToReplace .. ContantToAdd
		end
		fileContentPhoneNumberFind = fileContent:match("phoneNumber")
		if not fileContentPhoneNumberFind then
			local ContantToAdd = ",\n " .. tostring(fileContentTextFieldsContantTab) .. " { \"name\": \"phoneNumber\",\"characterSet\": \"TYPE2SET\",\"width\": 500,\"rows\": 1 }"
			StringToReplace = StringToReplace .. ContantToAdd
		end
		fileContentUpdated = string.gsub(fileContent, fileContentTextFieldsContant, StringToReplace)
		f = assert(io.open(HmiCapabilities, "w"))
		f:write(fileContentUpdated)
		f:close()
	end
end
-- Create UI expected result based on parameters from the request
function Test:createUIParameters_For_SendLocation(RequestParams)
	local param = {}
	if RequestParams["locationImage"] ~= nil then
		param["locationImage"] = RequestParams["locationImage"]
		if param["locationImage"].imageType == "DYNAMIC" then
			param["locationImage"].value = storagePath .. param["locationImage"].value
		end
	end
	if RequestParams["longitudeDegrees"] ~= nil then
		param["longitudeDegrees"] = RequestParams["longitudeDegrees"]
	end
	if RequestParams["latitudeDegrees"] ~= nil then
		param["latitudeDegrees"] = RequestParams["latitudeDegrees"]
	end
	if RequestParams["locationName"] ~= nil then
		param["locationName"] = RequestParams["locationName"]
	end
	if RequestParams["locationDescription"] ~= nil then
		param["locationDescription"] = RequestParams["locationDescription"]
	end
	if RequestParams["addressLines"] ~= nil then
		param["addressLines"] = RequestParams["addressLines"]
	end
	if RequestParams["deliveryMode"] ~= nil then
		param["deliveryMode"] = RequestParams["deliveryMode"]
	end
	if RequestParams["phoneNumber"] ~= nil then
		param["phoneNumber"] = RequestParams["phoneNumber"]
	end
	if RequestParams["address"] ~= nil then
		local addressParams = {"countryName", "countryCode", "postalCode", "administrativeArea", "subAdministrativeArea", "locality", "subLocality", "thoroughfare", "subThoroughfare"}
		local parameterFind = false
		param.address = {}
		for i=1, #addressParams do
			if RequestParams.address[addressParams[i]] ~= nil then
				param.address[addressParams[i]] = RequestParams.address[addressParams[i]]
				parameterFind = true
			end
		end
		if
		parameterFind == false then
			param.address = nil
		end
	end
	if RequestParams["timeStamp"] ~= nil then
		param.timeStamp = {}
		local timeStampParams = {"millisecond","second", "minute", "hour", "day", "month", "year", "tz_hour", "tz_minute"}
		for i=1, #timeStampParams do
			if
			RequestParams.timeStamp[timeStampParams[i]] ~= nil then
				param.timeStamp[timeStampParams[i]] = RequestParams.timeStamp[timeStampParams[i]]
			end
		end
	end
	return param
end
function Test:SendLocation_PositiveCase()
	local Request = {
		longitudeDegrees = 1,
		latitudeDegrees = 1,
		address = {
			countryName = "countryName",
			countryCode = "countryCode",
			postalCode = "postalCode",
			administrativeArea = "administrativeArea",
			subAdministrativeArea = "subAdministrativeArea",
			locality = "locality",
			subLocality = "subLocality",
			thoroughfare = "thoroughfare",
			subThoroughfare = "subThoroughfare"
		},
		timeStamp = {
			millisecond = 20,
			second = 40,
			minute = 30,
			hour = 14,
			day = 25,
			month = 5,
			year = 2017,
			tz_hour = 5,
			tz_minute = 30
		},
		locationName = "location Name",
		locationDescription = "location Description",
		addressLines =
		{
			"line1",
			"line2",
		},
		phoneNumber = "phone Number",
		deliveryMode = "PROMPT",
		locationImage =
		{
			value = "icon.png",
			imageType = "DYNAMIC",
		}
	}
	local cid = self.mobileSession:SendRPC("SendLocation", Request)
	local UIParams = self:createUIParameters_For_SendLocation(Request)
	EXPECT_HMICALL("Navigation.SendLocation", UIParams)
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
end
-----------------------------------------------------------------------------
-- TC21_Description: SetAppIcon
function Test:SetAppIcon_PositiveCase()
	local cid = self.mobileSession:SendRPC("SetAppIcon",{ syncFileName = "icon.png"})
	EXPECT_HMICALL("UI.SetAppIcon",{
		syncFileName =
		{
			imageType = "DYNAMIC",
			value = storagePath.."icon.png"
		}
	})
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
	end)
	EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
end
-------------------------------------------------------------------------------
-- TC21_Description: SetDisplayCapabilities
function butCap_Value()
	local buttonCapabilities =
	{
		{
			name = "PRESET_0",
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true
		},
		{
			name = "PRESET_1",
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true
		},
		{
			name = "PRESET_2",
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true
		},
		{
			name = "PRESET_3",
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true
		},
		{
			name = "PRESET_4",
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true
		},
		{
			name = "PRESET_5",
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true
		},
		{
			name = "PRESET_6",
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true
		},
		{
			name = "PRESET_7",
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true
		},
		{
			name = "PRESET_8",
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true
		},
		{
			name = "PRESET_9",
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true
		},
		{
			name = "OK",
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true
		},
		{
			name = "SEEKLEFT",
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true
		},
		{
			name = "SEEKRIGHT",
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true
		},
		{
			name = "TUNEUP",
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true
		},
		{
			name = "TUNEDOWN",
			shortPressAvailable = true,
			longPressAvailable = true,
			upDownAvailable = true
		}
	}
	return buttonCapabilities
end

function displayCap_Value()
	local displayCapabilities =
	{
		displayType = "GEN2_8_DMA",
		graphicSupported = true,
		imageCapabilities =
		{
			"DYNAMIC",
			"STATIC"
		},
		imageFields = displayCap_imageFields_Value(),
		
		mediaClockFormats =
		{
			"CLOCK1",
			"CLOCK2",
			"CLOCK3",
			"CLOCKTEXT1",
			"CLOCKTEXT2",
			"CLOCKTEXT3",
			"CLOCKTEXT4"
		},
		numCustomPresetsAvailable = 10,
		screenParams =
		{
			resolution =
			{
				resolutionHeight = 480,
				resolutionWidth = 800
			},
			touchEventAvailable =
			{
				doublePressAvailable = false,
				multiTouchAvailable = true,
				pressAvailable = true
			}
		},
		templatesAvailable =
		{
			"ONSCREEN_PRESETS"
		},
		textFields = displayCap_textFields_Value()
	}
	return displayCapabilities
end

function displayCap_imageFields_Value()
	local imageFields =
	{
		{
			imageResolution =
			{
				resolutionHeight = 64,
				resolutionWidth = 64
			},
			imageTypeSupported =
			{
				"GRAPHIC_BMP",
				"GRAPHIC_JPEG",
				"GRAPHIC_PNG"
			},
			name = "softButtonImage"
		},
		{
			imageResolution =
			{
				resolutionHeight = 64,
				resolutionWidth = 64
			},
			imageTypeSupported =
			{
				"GRAPHIC_BMP",
				"GRAPHIC_JPEG",
				"GRAPHIC_PNG"
			},
			name = "choiceImage"
		},
		{
			imageResolution =
			{
				resolutionHeight = 64,
				resolutionWidth = 64
			},
			imageTypeSupported =
			{
				"GRAPHIC_BMP",
				"GRAPHIC_JPEG",
				"GRAPHIC_PNG"
			},
			name = "choiceSecondaryImage"
		},
		{
			imageResolution =
			{
				resolutionHeight = 64,
				resolutionWidth = 64
			},
			imageTypeSupported =
			{
				"GRAPHIC_BMP",
				"GRAPHIC_JPEG",
				"GRAPHIC_PNG"
			},
			name = "vrHelpItem"
		},
		{
			imageResolution =
			{
				resolutionHeight = 64,
				resolutionWidth = 64
			},
			imageTypeSupported =
			{
				"GRAPHIC_BMP",
				"GRAPHIC_JPEG",
				"GRAPHIC_PNG"
			},
			name = "turnIcon"
		},
		{
			imageResolution =
			{
				resolutionHeight = 64,
				resolutionWidth = 64
			},
			imageTypeSupported =
			{
				"GRAPHIC_BMP",
				"GRAPHIC_JPEG",
				"GRAPHIC_PNG"
			},
			name = "menuIcon"
		},
		{
			imageResolution =
			{
				resolutionHeight = 64,
				resolutionWidth = 64
			},
			imageTypeSupported =
			{
				"GRAPHIC_BMP",
				"GRAPHIC_JPEG",
				"GRAPHIC_PNG"
			},
			name = "cmdIcon"
		},
		{
			imageResolution =
			{
				resolutionHeight = 64,
				resolutionWidth = 64
			},
			imageTypeSupported =
			{
				"GRAPHIC_BMP",
				"GRAPHIC_JPEG",
				"GRAPHIC_PNG"
			},
			name = "graphic"
		},
		{
			imageResolution =
			{
				resolutionHeight = 64,
				resolutionWidth = 64
			},
			imageTypeSupported =
			{
				"GRAPHIC_BMP",
				"GRAPHIC_JPEG",
				"GRAPHIC_PNG"
			},
			name = "showConstantTBTIcon"
		},
		{
			imageResolution =
			{
				resolutionHeight = 64,
				resolutionWidth = 64
			},
			imageTypeSupported =
			{
				"GRAPHIC_BMP",
				"GRAPHIC_JPEG",
				"GRAPHIC_PNG"
			},
			name = "showConstantTBTNextTurnIcon"
		},
		{
			imageResolution =
			{
				resolutionHeight = 64,
				resolutionWidth = 64
			},
			imageTypeSupported =
			{
				"GRAPHIC_BMP",
				"GRAPHIC_JPEG",
				"GRAPHIC_PNG"
			},
			name = "showConstantTBTNextTurnIcon"
		}
	}
	return imageFields
end

function displayCap_textFields_Value()
	local textFields =
	{
		{
			characterSet = "TYPE2SET",
			name = "mainField1",
			rows = 1,
			width = 500
		},
		{
			characterSet = "TYPE2SET",
			name = "mainField2",
			rows = 1,
			width = 500
		},
		{
			characterSet = "TYPE2SET",
			name = "mainField3",
			rows = 1,
			width = 500
		},
		{
			characterSet = "TYPE2SET",
			name = "mainField4",
			rows = 1,
			width = 500
		},
		{
			characterSet = "TYPE2SET",
			name = "statusBar",
			rows = 1,
			width = 500
		},
		{
			characterSet = "TYPE2SET",
			name = "mediaClock",
			rows = 1,
			width = 500
		},
		{
			characterSet = "TYPE2SET",
			name = "mediaTrack",
			rows = 1,
			width = 500
		},
		{
			characterSet = "TYPE2SET",
			name = "alertText1",
			rows = 1,
			width = 500
		},
		{
			characterSet = "TYPE2SET",
			name = "alertText2",
			rows = 1,
			width = 500
		},
		{
			characterSet = "TYPE2SET",
			name = "alertText3",
			rows = 1,
			width = 500
		},
		{
			characterSet = "TYPE2SET",
			name = "scrollableMessageBody",
			rows = 1,
			width = 500
		},
		{
			characterSet = "TYPE2SET",
			name = "initialInteractionText",
			rows = 1,
			width = 500
		},
		{
			characterSet = "TYPE2SET",
			name = "navigationText1",
			rows = 1,
			width = 500
		},
		{
			characterSet = "TYPE2SET",
			name = "navigationText2",
			rows = 1,
			width = 500
		},
		{
			characterSet = "TYPE2SET",
			name = "ETA",
			rows = 1,
			width = 500
		},
		{
			characterSet = "TYPE2SET",
			name = "totalDistance",
			rows = 1,
			width = 500
		},
		{
			characterSet = "TYPE2SET",
			name = "navigationText", --Error
			rows = 1,
			width = 500
		},
		{
			characterSet = "TYPE2SET",
			name = "audioPassThruDisplayText1",
			rows = 1,
			width = 500
		},
		{
			characterSet = "TYPE2SET",
			name = "audioPassThruDisplayText2",
			rows = 1,
			width = 500
		},
		{
			characterSet = "TYPE2SET",
			name = "sliderHeader",
			rows = 1,
			width = 500
		},
		{
			characterSet = "TYPE2SET",
			name = "sliderFooter",
			rows = 1,
			width = 500
		},
		{
			characterSet = "TYPE2SET",
			name = "notificationText",
			rows = 1,
			width = 500
		},
		{
			characterSet = "TYPE2SET",
			name = "menuName",
			rows = 1,
			width = 500
		},
		{
			characterSet = "TYPE2SET",
			name = "secondaryText",
			rows = 1,
			width = 500
		},
		{
			characterSet = "TYPE2SET",
			name = "tertiaryText",
			rows = 1,
			width = 500
		},
		{
			characterSet = "TYPE2SET",
			name = "timeToDestination",
			rows = 1,
			width = 500
		},
		{
			characterSet = "TYPE2SET",
			name = "turnText",
			rows = 1,
			width = 500
		},
		{
			characterSet = "TYPE2SET",
			name = "menuTitle",
			rows = 1,
			width = 500
		},
		{
			characterSet = "TYPE2SET",
			name = "locationName",
			rows = 1,
			width = 500
		},
		{
			characterSet = "TYPE2SET",
			name = "locationDescription",
			rows = 1,
			width = 500
		},
		{
			characterSet = "TYPE2SET",
			name = "addressLines",
			rows = 1,
			width = 500
		},
		{
			characterSet = "TYPE2SET",
			name = "phoneNumber",
			rows = 1,
			width = 500
		}
	}
	return textFields
end

function Test:SetDispLay_PositiveCase()
	local cid = self.mobileSession:SendRPC("SetDisplayLayout",
	{
		displayLayout = "ONSCREEN_PRESETS"
	})
	EXPECT_HMICALL("UI.SetDisplayLayout",
	{
		displayLayout = "ONSCREEN_PRESETS"
	})
	:Timeout(500)
	:Do(function(_,data)
		local responsed_params = {
			displayCapabilities = displayCap_Value(),
			buttonCapabilities = butCap_Value(),
			softButtonCapabilities =
				{{
					shortPressAvailable = true,
					longPressAvailable = true,
					upDownAvailable = true,
					imageSupported = true
			}},
			presetBankCapabilities =
			{
				onScreenPresetsAvailable = true
			}
		}
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", responsed_params)
	end)
	EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
end
-------------------------------------------------------------------------------
-- TC22_Description: Speak with reset timeout
function Test:Speak_PositiveCase()
		local cid = self.mobileSession:SendRPC("Speak", {ttsChunks ={
			{
				text ="a",
				type ="TEXT"
			}
	}})
	EXPECT_HMICALL("TTS.Speak", {ttsChunks =
		{
			{
				text ="a",
				type ="TEXT"
			}
	}})
	:Do(function(_,data)
		self.hmiConnection:SendNotification("TTS.Started")
		speak_id = data.id
		local function speakResponse()
			self.hmiConnection:SendResponse(speak_id, "TTS.Speak", "SUCCESS", { })
			self.hmiConnection:SendNotification("TTS.Stopped")
		end
		local function SendOnResetTimeout()
			self.hmiConnection:SendNotification("TTS.OnResetTimeout", {appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self), methodName = "TTS.Speak"})
		end
		RUN_AFTER(SendOnResetTimeout, 9000)
		RUN_AFTER(SendOnResetTimeout, 18000)
		RUN_AFTER(SendOnResetTimeout, 24000)
		RUN_AFTER(speakResponse, 33000)
	end)
	EXPECT_NOTIFICATION("OnHMIStatus",
	{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "ATTENUATED"},
	{systemContext = "MAIN", hmiLevel = "FULL", audioStreamingState = "AUDIBLE"})
	:Times(2)
	:Timeout(35000)
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
	:Timeout(35000)
end
-------------------------------------------------------------------------------
-- TC24_Description: SubscribeButton
local buttonName = {"OK","SEEKLEFT","SEEKRIGHT","TUNEUP","TUNEDOWN", "PRESET_0","PRESET_1","PRESET_2","PRESET_3","PRESET_4","PRESET_5","PRESET_6","PRESET_7","PRESET_8"}
for i=1,#buttonName do
	Test["SubscribeButton_PositiveCase_" .. tostring(buttonName[i]).."_SUCCESS"] = function(self)
		local cid = self.mobileSession:SendRPC("SubscribeButton",{ buttonName = buttonName[i]})
		EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self), isSubscribed = true, name = buttonName[i]})
		:Timeout(2000)
		EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
		:Timeout(2000)
		EXPECT_NOTIFICATION("OnHashChange")
	end
end
-------------------------------------------------------------------------------
-- TC_Description: OnButtonEvent, OnButtonPress
local button_press_modes = {"SHORT", "LONG"}
for i =1, #buttonName do
  for j =1, #button_press_modes do
    Test["OnButtonEvent_OnButtonPress_PositiveCase_" .. tostring(buttonName[i]) .. "_PressMode_" .. tostring(button_press_modes[j]) .. "_SUCCESS"] = function(self)
      self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = buttonName[i], mode = "BUTTONDOWN"})
      self.hmiConnection:SendNotification("Buttons.OnButtonEvent",{name = buttonName[i], mode = "BUTTONUP"})
      self.hmiConnection:SendNotification("Buttons.OnButtonPress",{name = buttonName[i], mode = button_press_modes[j]})
      EXPECT_NOTIFICATION("OnButtonEvent", 
          {buttonName = buttonName[i], buttonEventMode = "BUTTONDOWN"},
          {buttonName = buttonName[i], buttonEventMode = "BUTTONUP"})
      :Times(2)
      EXPECT_NOTIFICATION("OnButtonPress", {buttonName = buttonName[i], buttonPressMode = button_press_modes[j]})
    end
  end
end
-------------------------------------------------------------------------------
-- TC25_Description: UnSubscribeButton
local function unSubscribeButton(self, btnName, strTestCaseName)
	Test[strTestCaseName] = function(self)
		local cid = self.mobileSession:SendRPC("UnsubscribeButton",{ buttonName = btnName})
		if
		self.isMediaApplication == false and
		(btnName == "SEEKLEFT" or
		btnName == "SEEKRIGHT" or
		btnName == "TUNEUP" or
		btnName == "TUNEDOWN") then
			EXPECT_RESPONSE(cid, {success = false, resultCode = "IGNORED"})
			EXPECT_NOTIFICATION("OnHashChange")
			:Times(0)
		else
			EXPECT_HMINOTIFICATION("Buttons.OnButtonSubscription", {name = btnName, isSubscribed = false})
			:Timeout(500)
			EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
			EXPECT_NOTIFICATION("OnHashChange")
		end
	end
end

for i=1,#buttonName do
	strTestCaseName = "UnsubscribeButton_PositiveCase_".. tostring(buttonName[i]).."_SUCCESS"
	unSubscribeButton(self, buttonName[i], strTestCaseName)
end
-------------------------------------------------------------------------------
--TC26 Description: SubscribeVehicleData
local allVehicleData = {"gps", "speed", "rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption", "externalTemperature", "prndl", "tirePressure", "odometer", "beltStatus", "bodyInformation", "deviceStatus", "driverBraking", "wiperStatus", "headLampStatus", "engineTorque", "accPedalPosition", "steeringWheelAngle", "eCallInfo", "airbagStatus", "emergencyEvent", "clusterModeStatus", "myKey"}
local SVDValues = {gps="VEHICLEDATA_GPS", speed="VEHICLEDATA_SPEED", rpm="VEHICLEDATA_RPM", fuelLevel="VEHICLEDATA_FUELLEVEL", fuelLevel_State="VEHICLEDATA_FUELLEVEL_STATE", instantFuelConsumption="VEHICLEDATA_FUELCONSUMPTION", externalTemperature="VEHICLEDATA_EXTERNTEMP", prndl="VEHICLEDATA_PRNDL", tirePressure="VEHICLEDATA_TIREPRESSURE", odometer="VEHICLEDATA_ODOMETER", beltStatus="VEHICLEDATA_BELTSTATUS", bodyInformation="VEHICLEDATA_BODYINFO", deviceStatus="VEHICLEDATA_DEVICESTATUS", driverBraking="VEHICLEDATA_BRAKING", wiperStatus="VEHICLEDATA_WIPERSTATUS", headLampStatus="VEHICLEDATA_HEADLAMPSTATUS", engineTorque="VEHICLEDATA_ENGINETORQUE", accPedalPosition="VEHICLEDATA_ACCPEDAL", steeringWheelAngle="VEHICLEDATA_STEERINGWHEEL", eCallInfo="VEHICLEDATA_ECALLINFO", airbagStatus="VEHICLEDATA_AIRBAGSTATUS", emergencyEvent="VEHICLEDATA_EMERGENCYEVENT", clusterModeStatus="VEHICLEDATA_CLUSTERMODESTATUS", myKey="VEHICLEDATA_MYKEY"}
function setSVD_GVD_USVD_Request(paramsSend)
	local temp = {}
	for i = 1, #paramsSend do
		temp[paramsSend[i]] = true
	end
	return temp
end

function setSVDResponse(paramsSend, vehicleDataResultCode)
	local temp = {}
	local vehicle_data_result_code = ""
	if vehicleDataResultCode ~= nil then
		vehicle_data_result_code = vehicleDataResultCode
	else
		vehicle_data_result_code = "SUCCESS"
	end
	for i = 1, #paramsSend do
		if paramsSend[i] == "clusterModeStatus" then
			temp["clusterModes"] = {
				resultCode = vehicle_data_result_code,
				dataType = SVDValues[paramsSend[i]]
			}
		else
			temp[paramsSend[i]] = {
				resultCode = vehicle_data_result_code,
				dataType = SVDValues[paramsSend[i]]
			}
		end
	end
	return temp
end

function setGVDResponse(paramsSend)
	local temp = {}
	for i = 1, #paramsSend do
		temp[paramsSend[i]] = copyTable(vehicleDataValues[paramsSend[i]])
	end
	return temp
end

function Test:SubscribeVehicleData_PositiveCase()
	local request = setSVD_GVD_USVD_Request(allVehicleData)
	local response = setSVDResponse(allVehicleData)
	local cid = self.mobileSession:SendRPC("SubscribeVehicleData",request)
	EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData",request)
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)
	end)
	EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
	EXPECT_NOTIFICATION("OnHashChange")
end
-------------------------------------------------------------------------------
-- TC27_Description: GetVehicleData
local allVehicleData = {"gps", "speed", "rpm", "fuelLevel", "fuelLevel_State", "instantFuelConsumption", "externalTemperature", "prndl", "tirePressure", "odometer", "beltStatus", "bodyInformation", "deviceStatus", "driverBraking", "wiperStatus", "headLampStatus", "engineTorque", "accPedalPosition", "steeringWheelAngle", "eCallInfo", "airbagStatus", "emergencyEvent", "clusterModeStatus", "myKey"}
local vehicleDataValues = {
	gps = {
		longitudeDegrees = 25.5,
		latitudeDegrees = 45.5
	},
	speed = 100.5,
	rpm = 1000,
	fuelLevel= 50.5,
	fuelLevel_State="NORMAL",
	instantFuelConsumption=1000.5,
	externalTemperature=55.5,
	vin = "123456",
	prndl="DRIVE",
	tirePressure={
		pressureTelltale = "ON",
	},
	odometer= 8888,
	beltStatus={
		driverBeltDeployed = "NOT_SUPPORTED"
	},
	bodyInformation={
		parkBrakeActive = true,
		ignitionStableStatus = "MISSING_FROM_TRANSMITTER",
		ignitionStatus = "UNKNOWN"
	},
	deviceStatus={
		voiceRecOn = true
	},
	driverBraking="NOT_SUPPORTED",
	wiperStatus="MAN_LOW",
	headLampStatus={
		lowBeamsOn = true,
		highBeamsOn = true,
		ambientLightSensorStatus = "NIGHT"
	},
	engineTorque=555.5,
	accPedalPosition=55.5,
	steeringWheelAngle=555.5,
	eCallInfo={
		eCallNotificationStatus = "NORMAL",
		auxECallNotificationStatus = "NORMAL",
		eCallConfirmationStatus = "NORMAL"
	},
	airbagStatus={
		driverAirbagDeployed = "NOT_SUPPORTED",
		driverSideAirbagDeployed = "NOT_SUPPORTED",
		driverCurtainAirbagDeployed = "NOT_SUPPORTED",
		passengerAirbagDeployed = "NOT_SUPPORTED",
		passengerCurtainAirbagDeployed = "NOT_SUPPORTED",
		driverKneeAirbagDeployed = "NOT_SUPPORTED",
		passengerSideAirbagDeployed = "NOT_SUPPORTED",
		passengerKneeAirbagDeployed = "NOT_SUPPORTED"
	},
	emergencyEvent={
		emergencyEventType = "NO_EVENT",
		fuelCutoffStatus = "NORMAL_OPERATION",
		rolloverEvent = "NO_EVENT",
		maximumChangeVelocity = 0,
		multipleEvents = "NO_EVENT"
	},
	clusterModeStatus={
		powerModeActive = true,
		powerModeQualificationStatus = "POWER_MODE_UNDEFINED",
		carModeStatus = "TRANSPORT",
		powerModeStatus = "KEY_OUT"
	},
	myKey={
		e911Override = "NO_DATA_EXISTS"
	}
}

function copyTable(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[copyTable(orig_key)] = copyTable(orig_value)
		end
		setmetatable(copy, copyTable(getmetatable(orig)))
	else
		copy = orig
	end
	return copy
end

function setGVDResponse(paramsSend)
	local temp = {}
	for i = 1, #paramsSend do
		temp[paramsSend[i]] = copyTable(vehicleDataValues[paramsSend[i]])
	end
	return temp
end

function Test:GetVehicleData_PositiveCase()
	local request = setSVD_GVD_USVD_Request(allVehicleData)
	local response = setGVDResponse(allVehicleData)
	local cid = self.mobileSession:SendRPC("GetVehicleData",request)
	EXPECT_HMICALL("VehicleInfo.GetVehicleData",request)
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)
	end)
	EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
	common_functions:DelayedExp(300)
end
-------------------------------------------------------------------------------
local vehicleDataValues_expect = {
	gps = {
		longitudeDegrees = 25.5,
		latitudeDegrees = 45.5
	},
	speed = 100.5,
	rpm = 1000,
	fuelLevel= 50.5,
	fuelLevel_State="NORMAL",
	instantFuelConsumption=1000.5,
	externalTemperature=55.5,
	prndl="DRIVE",
	tirePressure={
		pressureTelltale = "ON",
	},
	odometer= 8888,
	beltStatus={
		driverBeltDeployed = "NOT_SUPPORTED"
	},
	bodyInformation={
		parkBrakeActive = true,
		ignitionStableStatus = "MISSING_FROM_TRANSMITTER",
		ignitionStatus = "UNKNOWN"
	},
	deviceStatus={
		voiceRecOn = true
	},
	driverBraking="NOT_SUPPORTED",
	wiperStatus="MAN_LOW",
	headLampStatus={
		lowBeamsOn = true,
		highBeamsOn = true,
		ambientLightSensorStatus = "NIGHT"
	},
	engineTorque=555.5,
	accPedalPosition=55.5,
	steeringWheelAngle=555.5,
	eCallInfo={
		eCallNotificationStatus = "NORMAL",
		auxECallNotificationStatus = "NORMAL",
		eCallConfirmationStatus = "NORMAL"
	},
	airbagStatus={
		driverAirbagDeployed = "NOT_SUPPORTED",
		driverSideAirbagDeployed = "NOT_SUPPORTED",
		driverCurtainAirbagDeployed = "NOT_SUPPORTED",
		passengerAirbagDeployed = "NOT_SUPPORTED",
		passengerCurtainAirbagDeployed = "NOT_SUPPORTED",
		driverKneeAirbagDeployed = "NOT_SUPPORTED",
		passengerSideAirbagDeployed = "NOT_SUPPORTED",
		passengerKneeAirbagDeployed = "NOT_SUPPORTED"
	},
	emergencyEvent={
		emergencyEventType = "NO_EVENT",
		fuelCutoffStatus = "NORMAL_OPERATION",
		rolloverEvent = "NO_EVENT",
		maximumChangeVelocity = 0,
		multipleEvents = "NO_EVENT"
	},
	clusterModeStatus={
		powerModeActive = true,
		powerModeQualificationStatus = "POWER_MODE_UNDEFINED",
		carModeStatus = "TRANSPORT",
		powerModeStatus = "KEY_OUT"
	},
	myKey={
		e911Override = "NO_DATA_EXISTS"
	}
}
function Test:OnVehicleData_PositiveCase()
  self.hmiConnection:SendNotification("VehicleInfo.OnVehicleData", vehicleDataValues)
  EXPECT_NOTIFICATION("OnVehicleData", vehicleDataValues_expect)
end

-------------------------------------------------------------------------------
-- TC28_Description: UnSubscribeVehicleData
local USVDValues = {gps="VEHICLEDATA_GPS", speed="VEHICLEDATA_SPEED", rpm="VEHICLEDATA_RPM", fuelLevel="VEHICLEDATA_FUELLEVEL", fuelLevel_State="VEHICLEDATA_FUELLEVEL_STATE", instantFuelConsumption="VEHICLEDATA_FUELCONSUMPTION", externalTemperature="VEHICLEDATA_EXTERNTEMP", prndl="VEHICLEDATA_PRNDL", tirePressure="VEHICLEDATA_TIREPRESSURE", odometer="VEHICLEDATA_ODOMETER", beltStatus="VEHICLEDATA_BELTSTATUS", bodyInformation="VEHICLEDATA_BODYINFO", deviceStatus="VEHICLEDATA_DEVICESTATUS", driverBraking="VEHICLEDATA_BRAKING", wiperStatus="VEHICLEDATA_WIPERSTATUS", headLampStatus="VEHICLEDATA_HEADLAMPSTATUS", engineTorque="VEHICLEDATA_ENGINETORQUE", accPedalPosition="VEHICLEDATA_ACCPEDAL", steeringWheelAngle="VEHICLEDATA_STEERINGWHEEL", eCallInfo="VEHICLEDATA_ECALLINFO", airbagStatus="VEHICLEDATA_AIRBAGSTATUS", emergencyEvent="VEHICLEDATA_EMERGENCYEVENT", clusterModeStatus="VEHICLEDATA_CLUSTERMODESTATUS", myKey="VEHICLEDATA_MYKEY"}
function setUSVDResponse(paramsSend, vehicleDataResultCode)
	local temp = {}
	local vehicle_data_result_code = ""
	if vehicleDataResultCode ~= nil then
		vehicle_data_result_code = vehicleDataResultCode
	else
		vehicle_data_result_code = "SUCCESS"
	end
	for i = 1, #paramsSend do
		if paramsSend[i] == "clusterModeStatus" then
			temp["clusterModes"] = {
				resultCode = vehicle_data_result_code,
				dataType = USVDValues[paramsSend[i]]
			}
		else
			temp[paramsSend[i]] = {
				resultCode = vehicle_data_result_code,
				dataType = USVDValues[paramsSend[i]]
			}
		end
	end
	return temp
end

function Test:UnsubscribeVehicleData_PositiveCase()
	local request = setSVD_GVD_USVD_Request(allVehicleData)
	local response = setUSVDResponse(allVehicleData)
	local cid = self.mobileSession:SendRPC("UnsubscribeVehicleData",request)
	EXPECT_HMICALL("VehicleInfo.UnsubscribeVehicleData",request)
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)
	end)
	EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
	EXPECT_NOTIFICATION("OnHashChange")
end
-------------------------------------------------------------------------------
-- TC29_Description: UpdateTurnList
function Test:UpdateTurnList_PositiveCase()
	local request = {
		turnList =
		{
			{
				navigationText ="Text",
				turnIcon =
				{
					value ="icon.png",
					imageType ="DYNAMIC"
				}
			}
		},
		softButtons =
		{
			{
				type ="BOTH",
				text ="Close",
				image =
				{
					value ="icon.png",
					imageType ="DYNAMIC"
				},
				isHighlighted = true,
				softButtonID = 111,
				systemAction ="DEFAULT_ACTION"
			}
		}
	}
	local cor_id_update_turn_list = self.mobileSession:SendRPC("UpdateTurnList", request)
  request.softButtons[1].image.value = storagePath..request.softButtons[1].image.value
	EXPECT_HMICALL("Navigation.UpdateTurnList",
	{
		turnList = {
			{
				navigationText =
				{
					fieldText = "Text",
					fieldName = "turnText"
				},
				turnIcon =
				{
					value =storagePath.."icon.png",
					imageType ="DYNAMIC"
				}
			}
		},
		softButtons = request.softButtons
	})
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
	end)
	EXPECT_RESPONSE(cor_id_update_turn_list, { success = true, resultCode = "SUCCESS" })
end
-------------------------------------------------------------------------------
-- TC30_Description: AlertManeuver
function Test:AlertManeuver_PositiveCase()
	local cor_id_alert_maneuver = self.mobileSession:SendRPC("AlertManeuver", {
		ttsChunks =
		{
			{
				text ="FirstAlert",
				type ="TEXT"
			},
			{
				text ="SecondAlert",
				type ="TEXT"
			},
		},
		softButtons =
		{
			{
				type = "BOTH",
				text = "Close",
				image =
				{
					value = "icon.png",
					imageType = "DYNAMIC"
				},
				isHighlighted = true,
				softButtonID = 821,
				systemAction = "DEFAULT_ACTION"
			},
			{
				type = "BOTH",
				text = "AnotherClose",
				image =
				{
					value = "icon.png",
					imageType = "DYNAMIC"
				},
				isHighlighted = false,
				softButtonID = 822,
				systemAction = "DEFAULT_ACTION"
			},
		}
	})
	local alert_id
	EXPECT_HMICALL("Navigation.AlertManeuver",{
		appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self),
		softButtons =
		{
			{
				type = "BOTH",
				text = "Close",
				image =
				{
					value = storagePath.."icon.png",
					imageType = "DYNAMIC"
				},
				isHighlighted = true,
				softButtonID = 821,
				systemAction = "DEFAULT_ACTION"
			},
			{
				type = "BOTH",
				text = "AnotherClose",
				image =
				{
					value = storagePath.."icon.png",
					imageType = "DYNAMIC"
				},
				isHighlighted = false,
				softButtonID = 822,
				systemAction = "DEFAULT_ACTION"
			}
		}
	})
	:Do(function(_,data)
		alert_id = data.id
		local function alert_response()
			self.hmiConnection:SendResponse(alert_id, "Navigation.AlertManeuver", "SUCCESS", {})
		end
		RUN_AFTER(alert_response, 2000)
	end)
	local speak_id
	EXPECT_HMICALL("TTS.Speak",{
		ttsChunks =
		{
			{
				text ="FirstAlert",
				type ="TEXT"
			},
			{
				text ="SecondAlert",
				type ="TEXT"
			}
		},
		speakType = "ALERT_MANEUVER"
	})
	:Do(function(_,data)
		self.hmiConnection:SendNotification("TTS.Started")
		speak_id = data.id
		local function speakResponse()
			self.hmiConnection:SendResponse(speak_id, "TTS.Speak", "SUCCESS", { })
			
			self.hmiConnection:SendNotification("TTS.Stopped")
		end
		RUN_AFTER(speakResponse, 1000)
	end)
	EXPECT_NOTIFICATION("OnHMIStatus",
	{ systemContext = "MAIN", hmiLevel = level, audioStreamingState = "ATTENUATED" },
	{ systemContext = "MAIN", hmiLevel = level, audioStreamingState = "AUDIBLE" })
	:Times(2)
	EXPECT_RESPONSE(cor_id_alert_maneuver, { success = true, resultCode = "SUCCESS" })
	:Timeout(11000)
end
-------------------------------------------------------------------------------
-- TC31_Description: GenericResponse
function Test:GenericResponse_PositiveCase()
	local generic_response_id = 31
	self.mobileSession.correlationId = self.mobileSession.correlationId + 1
	local msg =
	{
		serviceType = 7,
		frameInfo = 0,
		rpcType = 0,
		rpcFunctionId = 0x0200,
		rpcCorrelationId = self.mobileSession.correlationId,
		payload = '{}'
	}
	self.mobileSession:Send(msg)
--[[
  --[TODO][nhphi] Below code can only be checked by manual reading ATF log. 
  -- ATF does not support below checking still [APPLINK-33041] is implemented. 
	EXPECT_RESPONSE(self.mobileSession.correlationId)
	:ValidIf(function(_,data)
		if data.rpcFunctionId == generic_response_id then
			if data.payload.resultCode == "INVALID_DATA" and data.payload.success == false and data.payload.info == nil then
				return true
			else
				return false
			end
		else
			print("Response is not correct. Expected: ".. generic_response_id .." (generic_response_id), actual: "..tostring(data.rpcFunctionId))
			return false
		end
	end)
--]]
end
-------------------------------------------------------------------------------
-- TC32_Description: OnDriverDistraction
local onDriverDistractionValue = {"DD_ON", "DD_OFF"}
for i=1,#onDriverDistractionValue do
	Test["OnDriverDistraction_PositiveCase_State_" .. onDriverDistractionValue[i]] = function(self)
		local request = {state = onDriverDistractionValue[i]}
		self.hmiConnection:SendNotification("UI.OnDriverDistraction",request)
		EXPECT_NOTIFICATION("OnDriverDistraction", request)
		:ValidIf (function(_,data)
			if data.payload.fake ~= nil or data.payload.syncFileName ~= nil then
				print(" \27[36m SDL resend fake parameter to mobile app \27[0m")
				return false
			else
				return true
			end
		end)
	end
end
-------------------------------------------------------------------------------
-- TC33_Description: DialNumber
function Test:DialNumber_PositiveCase()
	local CorIdDialNumber = self.mobileSession:SendRPC("DialNumber",{ number = "#3804567654*"})
	EXPECT_HMICALL("BasicCommunication.DialNumber",{
		number = "#3804567654*",
		appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
	})
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id,"BasicCommunication.DialNumber", "SUCCESS", {})
	end)
	EXPECT_RESPONSE(CorIdDialNumber, { success = true, resultCode = "SUCCESS"})
	:Timeout(2000)
end
-------------------------------------------------------------------------------
-- TC34_Description: PerformAudioPassThru
function Test:PerformAudioPassThru_PositiveCase()
	local request = { initialPrompt =
		{
			{
				text ="Makeyourchoice",
				type ="TEXT"
			},
		},
		audioPassThruDisplayText1 ="DisplayText1",
		audioPassThruDisplayText2 ="DisplayText2",
		samplingRate ="8KHZ",
		maxDuration = 2000,
		bitsPerSample ="8_BIT",
		audioType ="PCM",
		muteAudio = true
	}
	local cid = self.mobileSession:SendRPC("PerformAudioPassThru", request)
	if request["initialPrompt"] ~= nil then
		EXPECT_HMICALL("TTS.Speak", {
			speakType = "AUDIO_PASS_THRU",
			ttsChunks =
			{
				{
					type = "TEXT",
					text = "Makeyourchoice"
				}
			}
		})
		:Do(function(_,data)
			self.hmiConnection:SendNotification("TTS.Started")
			local function ttsSpeakResponse()
				self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
				self.hmiConnection:SendNotification("TTS.Stopped")
				EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)})
			end
			RUN_AFTER(ttsSpeakResponse, 50)
		end)
	end
	EXPECT_HMICALL("UI.PerformAudioPassThru", {
		muteAudio = true,
		maxDuration = 2000,
		audioPassThruDisplayTexts =
		{
			{
				fieldName = "audioPassThruDisplayText1",
				fieldText = "DisplayText1"
			},
			{
				fieldName = "audioPassThruDisplayText2",
				fieldText = "DisplayText2"
			}
		}
	})
	:Do(function(_,data)
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self), systemContext = "HMI_OBSCURED"})
		local function uiResponse()
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self), systemContext = "MAIN"})
		end
		RUN_AFTER(uiResponse, 1500)
	end)
	EXPECT_NOTIFICATION("OnHMIStatus",
	{ hmiLevel = level, audioStreamingState = "ATTENUATED", systemContext = "MAIN"},
	{ hmiLevel = level, audioStreamingState = "ATTENUATED", systemContext = "HMI_OBSCURED"},
	{ hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED"},
	{ hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	:Times(4)
	EXPECT_NOTIFICATION("OnAudioPassThru")
	:Times(1)
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
	:ValidIf (function(_,data)
		if common_functions:IsFileExist(config.pathToSDL .. "storage/".."/".."audio.wav") ~= true then
			print(" \27[36m Can not found file: audio.wav \27[0m ")
			return false
		else
			return true
		end
	end)
	common_functions:DelayedExp(1000)
end
-------------------------------------------------------------------------------
-- TC35_Description: EndAudioPassThru
function Test:EndAudioPassThru_PositiveCase()
	local uiPerformID
	local params ={
		samplingRate ="8KHZ",
		maxDuration = 5000,
		bitsPerSample ="8_BIT",
		audioType ="PCM"
	}
	local cid = self.mobileSession:SendRPC("PerformAudioPassThru", params)
	EXPECT_NOTIFICATION("OnHMIStatus",
	{ hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED"},
	{ hmiLevel = level, audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	:Times(2)
	EXPECT_HMINOTIFICATION("UI.OnRecordStart", {appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)})
	EXPECT_HMICALL("UI.PerformAudioPassThru", {
		maxDuration = 5000
	})
	:Do(function(_,data)
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self), systemContext = "HMI_OBSCURED" })
		uiPerformID = data.id
	end)
	EXPECT_NOTIFICATION("OnAudioPassThru")
	:Do(function(_,data)
		local cidEndAudioPassThru = self.mobileSession:SendRPC("EndAudioPassThru", {})
		EXPECT_HMICALL("UI.EndAudioPassThru")
		:Do(function(_,data)
			self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
			self.hmiConnection:SendResponse(uiPerformID, "UI.PerformAudioPassThru", "SUCCESS", {})
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self), systemContext = "MAIN"})
		end)
		EXPECT_RESPONSE(cidEndAudioPassThru, { success = true, resultCode = "SUCCESS" })
	end)
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
	:ValidIf (function(_,data)
		if common_functions:IsFileExist(config.pathToSDL .. "storage/".."/".."audio.wav") ~= true then
			print(" \27[36m Can not found file: audio.wav \27[0m ")
			return false
		else
			return true
		end
	end)
end
-------------------------------------------------------------------------------
-- TC36_Description: ReadDID
function Test:ReadDID_PositiveCase()
	local request = { ecuName = 2000, didLocation = {56832}}
	local cid = self.mobileSession:SendRPC("ReadDID",request)
	EXPECT_HMICALL("VehicleInfo.ReadDID",{ ecuName = 2000, didLocation = {56832}})
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {didLocation ={56832}})
	end)
	EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS" })
	common_functions:DelayedExp(300)
end
-------------------------------------------------------------------------------
-- TC37_Description: GetDTC
function Test:GetDTCs_PositiveCase()
	local request =
	{
		ecuName = 2,
		dtcMask = 3
	}
	local cid = self.mobileSession:SendRPC("GetDTCs", request)
	EXPECT_HMICALL("VehicleInfo.GetDTCs", {
		ecuName = 2,
		dtcMask = 3
	})
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
			dtc =
			{
				"line 0",
				"line 1",
				"line 2"
			},
			ecuHeader = 2
		}
		)
	end)
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
end
-------------------------------------------------------------------------------
-- TC38_Description: ChangeRegistration
function Test:ChangeRegistration_PositiveCase()
	local request = {
		language ="EN-US",
		hmiDisplayLanguage ="EN-US",
		appName ="SyncProxyTester",
		ttsName =
		{
			{
				text ="SyncProxyTester",
				type ="TEXT"
			},
		},
		ngnMediaScreenAppName ="SPT",
		vrSynonyms =
		{
			"VRSyncProxyTester"
		},
	}
	local CorIdChangeRegistration = self.mobileSession:SendRPC("ChangeRegistration", request)
	EXPECT_HMICALL("UI.ChangeRegistration",
	{
		appName = request.appName,
		language = request.hmiDisplayLanguage,
		ngnMediaScreenAppName = request.ngnMediaScreenAppName
	})
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
	end)
	EXPECT_HMICALL("VR.ChangeRegistration",
	{
		language = request.language,
		vrSynonyms = request.vrSynonyms
	})
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
	end)
	EXPECT_HMICALL("TTS.ChangeRegistration",
	{
		language = request.language,
		ttsName = request.ttsName
	})
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS",{})
	end)
	EXPECT_RESPONSE(CorIdChangeRegistration, { success = true, resultCode = "SUCCESS" })
end
-------------------------------------------------------------------------------
-- TC39_Description: SystemRequest
function Test:SystemRequest_PositiveCase()
	local request = {fileName = "PolicyTableUpdate",
	requestType = "HTTP"}
	local pt_file = "./files/PTU_ForSystemRequest.json"
	local cid = self.mobileSession:SendRPC("SystemRequest", request, pt_file)
	EXPECT_HMICALL("BasicCommunication.SystemRequest", {
		fileName = sdl_config:GetValue("SystemFilesPath") .. "/" .. request.fileName,
		requestType = request.requestType,
		appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
	}
	)
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
	end)
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
end
-------------------------------------------------------------------------------
-- TC40_Description: UnregisterAppInterface
function Test:UnregisterAppInterface_PositiveCase()
	local CorIdURAI = self.mobileSession:SendRPC("UnregisterAppInterface", {})
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.appID, unexpectedDisconnect = false})
	EXPECT_RESPONSE("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})
end
-------------------------------------------------------------------------------
-- TC41_Description: RegisterAppInterface
function Test:RegisterAppInterface_PositiveCase()
  local app_params = 
	{
		syncMsgVersion =
		{
			majorVersion = 2,
			minorVersion = 2
		},
		appName ="SyncProxyTester",
		ttsName =
		{
			{
				text ="SyncProxyTester",
				type ="TEXT"
			},
		},
		ngnMediaScreenAppName ="SPT",
		vrSynonyms =
		{
			"VRSyncProxyTester",
		},
		isMediaApplication = true,
		languageDesired ="EN-US",
		hmiDisplayLanguageDesired ="EN-US",
		appHMIType =
		{
			"DEFAULT",
		},
		appID ="123456",
		deviceInfo =
		{
			hardware = "hardware",
			firmwareRev = "firmwareRev",
			os = "os",
			osVersion = "osVersion",
			carrier = "carrier",
			maxNumberRFCOMMPorts = 5
		}
	}
  common_functions:StoreApplicationData("mobileSession", "SyncProxyTester", app_params, _, self)
	local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface", app_params)
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {
		application =
		{
			appName = "SyncProxyTester",
			ngnMediaScreenAppName ="SPT",
			deviceInfo =
			{
				name = "127.0.0.1",
				id = config.deviceMAC,
				transportType = "WIFI",
				isSDLAllowed = true
			},
			policyAppID = "123456",
			hmiDisplayLanguageDesired ="EN-US",
			isMediaApplication = true,
			appType =
			{
				"DEFAULT"
			},
		},
		ttsName =
		{
			{
				text ="SyncProxyTester",
				type ="TEXT"
			}
		},
		vrSynonyms =
		{
			"VRSyncProxyTester",
		}
	})
  :Do(function(_,data)
    common_functions:StoreHmiAppId("SyncProxyTester", data.params.application.appID, self)
  end)
	EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
	:Timeout(2000)
	:Do(function(_,data)
		EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    :Do(function(_,data)
      common_functions:StoreHmiStatus("SyncProxyTester", data.payload, self)
    end)
	end)
	EXPECT_NOTIFICATION("OnPermissionsChange")
end
-------------------------------------------------------------------------------
-- TC42_Description: DiagnosticMessage
function Test:DiagnosticMessage_PositiveRequest()
	local request = {
		targetID = 42,
		messageLength = 8,
		messageData = {1,2},
		appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
	}
	local cid = self.mobileSession:SendRPC("DiagnosticMessage", request)
	EXPECT_HMICALL("VehicleInfo.DiagnosticMessage", {
		targetID = 42,
		messageLength = 8,
		messageData = {1,2}
	})
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {messageDataResult = {200}})
	end)
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
end
-------------------------------------------------------------------------------
-- TC43_Description: SubscribeWayPoints
function Test:SubscribeWayPoints_PositiveCase ()
	local cor_id = self.mobileSession:SendRPC("SubscribeWayPoints", {})
	EXPECT_HMICALL("Navigation.SubscribeWayPoints")
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	EXPECT_RESPONSE(cor_id, {success = true , resultCode = "SUCCESS"} )
	EXPECT_NOTIFICATION("OnHashChange")
end
-------------------------------------------------------------------------------
-- TC_Description: OnWayPointChange
common_steps:ActivateApplication("Activate_App_Before_OnWayPointChange", "SyncProxyTester", "FULL")
function Test:OnWayPointChange_ParamsAreValid()
  local notifications = {
    wayPoints = {{
      coordinate = {
        latitudeDegrees = -90,
        longitudeDegrees = -180},
      locationName = "Ho Chi Minh City",
      addressLines = {"182 LDH"},
      locationDescription = "Flemington Building",
      phoneNumber = "1234321",
      locationImage = {
        value = config.pathToSDL .."icon.png",
        imageType = "DYNAMIC"},
      searchAddress = {
        countryName = "aaa",
        countryCode = "084",
        postalCode = "test",
        administrativeArea = "aa",
        subAdministrativeArea="a",
        locality="a",
        subLocality="a",
        thoroughfare="a",
        subThoroughfare="a"}}}}
  self.hmiConnection:SendNotification("Navigation.OnWayPointChange", notifications)	 		
  EXPECT_NOTIFICATION("OnWayPointChange")
end

-------------------------------------------------------------------------------
-- TC44_Description: UnsubscribeWayPoints
function Test:UnsubscribeWayPoints_PositiveCase ()
	local cid = self.mobileSession:SendRPC("UnsubscribeWayPoints",{})
	EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
	EXPECT_NOTIFICATION("OnHashChange")
end

-------------------------------------------------------------------------------
-- TC45_Description: OnLanguageChange
function Test:OnLanguageChange_UI()
  self.hmiConnection:SendNotification("UI.OnLanguageChange", {language = "DE-DE"})
  EXPECT_NOTIFICATION("OnLanguageChange",{language="EN-US", hmiDisplayLanguage="DE-DE"})
  -- App name = "SyncProxyTester" which is registered from TC41: RegisterAppInterface
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {
      appID = common_functions:GetHmiAppId("SyncProxyTester", self),
      unexpectedDisconnect =  false})
  EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "LANGUAGE_CHANGE"})
end

local app_params_language_change_ui = {
  hmiDisplayLanguageDesired = "DE-DE",
  deviceInfo = {
    maxNumberRFCOMMPorts = 1,
    carrier = "Megafon",
    os = "Android",
    osVersion = "4.4.2",
    firmwareRev = "Name: Linux, Version: 3.4.0-perf"},
  appName = "Test Application",
  isMediaApplication = true,
  languageDesired = "EN-US",
  syncMsgVersion = {
    majorVersion = 3,
    minorVersion = 0},
  appHMIType = {"NAVIGATION"},
  appID = "0000001"}
common_steps:RegisterApplication("Register_App_After_OnLanguageChange_UI", "mobileSession", app_params_language_change_ui)

function Test:OnLanguageChange_TTS_VR()
  self.hmiConnection:SendNotification("TTS.OnLanguageChange", {language = "FR-CA"})
  self.hmiConnection:SendNotification("VR.OnLanguageChange", {language = "FR-CA"})
  EXPECT_NOTIFICATION("OnLanguageChange",{language="FR-CA", hmiDisplayLanguage="DE-DE"})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {
      appID = common_functions:GetHmiAppId("Test Application", self),
      unexpectedDisconnect =  false})
  EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", {reason = "LANGUAGE_CHANGE"})
end

local app_params_language_change_tts_vr = {
  hmiDisplayLanguageDesired = "DE-DE",
  deviceInfo = {
    maxNumberRFCOMMPorts = 1,
    carrier = "Megafon",
    os = "Android",
    osVersion = "4.4.2",
    firmwareRev = "Name: Linux, Version: 3.4.0-perf"},
  appName = "Test Application",
  isMediaApplication = true,
  languageDesired = "FR-CA",
  syncMsgVersion = {
    majorVersion = 3,
    minorVersion = 0},
  appHMIType = {"NAVIGATION"},
  appID = "0000001"}
common_steps:RegisterApplication("Register_App_After_OnLanguageChange_TTS_VR", "mobileSession", app_params_language_change_tts_vr)
common_steps:ActivateApplication("Activate_App_After_OnLanguageChange_TTS_VR", app_params_language_change_tts_vr.appName, "FULL")
-------------------------------------------------------------------------------
-- TC46_Description: OnTBTClientState
local tbt_states = {
  "ROUTE_UPDATE_REQUEST",
	"ROUTE_ACCEPTED",
	"ROUTE_REFUSED",
	"ROUTE_CANCELLED",
	"ETA_REQUEST",
	"NEXT_TURN_REQUEST",
	"ROUTE_STATUS_REQUEST",
	"ROUTE_SUMMARY_REQUEST",
	"TRIP_STATUS_REQUEST",
	"ROUTE_UPDATE_REQUEST_TIMEOUT"}
for i = 1, #tbt_states do
  Test["OnTBTClientState_" .. tbt_states[i]] = function(self)
    self.hmiConnection:SendNotification("Navigation.OnTBTClientState", {state = tbt_states[i]})
    EXPECT_NOTIFICATION("OnTBTClientState", {state = tbt_states[i]})
  end
end

-------------------------------------------------------------------------------
-- TC47_Description: OnTouchEvent
local ontouch_types = {
  "BEGIN",
  "MOVE",
  "END"
} 
for i = 1, #ontouch_types do
  Test["OnTouchEvent_" .. ontouch_types[i]] = function(self)
    local notification = {
      type = ontouch_types[i], 
      event = {{id = i, ts = {100+i,100+i}, c = {{x = i, y = i}}}}}
    self.hmiConnection:SendNotification("UI.OnTouchEvent", notification)
    EXPECT_NOTIFICATION("OnTouchEvent", notification)
  end
end

-------------------------------------------------------------------------------
-- TC48_Description: OnAppPermissionConsent and OnPermissionsChange
local group_id

function Test:Precondition_CreateJsonFile()
  assert(os.execute(" cp " .. config.pathToSDL .. "sdl_preloaded_pt.json /tmp/update_ptu.json" ))
  -- remove preload_pt
  local parent_removed_item = {"policy_table", "module_config"}
  local removed_json_items = {"preloaded_pt"}
  common_functions:RemoveItemsFromJsonFile("/tmp/update_ptu.json", parent_removed_item, removed_json_items)
  -- add application policy
  local parent_added_item = {"policy_table", "app_policies"}
  local added_json_items ={}
  added_json_items["0000001"] = {
      keep_context = false,
      steal_focus = false,
      priority = "NONE",
      default_hmi = "NONE",
      groups = {"Base-4", "Group001"}
    }
  common_functions:AddItemsIntoJsonFile("/tmp/update_ptu.json", parent_added_item, added_json_items)
  -- add function group
  local parent_added_item_2 = {"policy_table", "functional_groupings"}
  local added_json_items_2 ={}
  added_json_items_2["Group001"] = {
    user_consent_prompt = "ConsentGroup001",
    rpcs = {GetWayPoints = {hmi_levels = {"BACKGROUND","FULL","LIMITED","NONE"}}}}
  common_functions:AddItemsIntoJsonFile("/tmp/update_ptu.json", parent_added_item_2, added_json_items_2)    
end

update_policy:updatePolicy("/tmp/update_ptu.json", nil, "Precondition_Update_Policy")

function Test:Precondition_Get_List_Of_Permissions()
  local request_id = self.hmiConnection:SendRequest("SDL.GetListOfPermissions")
  EXPECT_HMIRESPONSE(request_id,{
    result = {
      code = 0,
      method = "SDL.GetListOfPermissions",
      allowedFunctions = {{name = "ConsentGroup001"}}}})
  :Do(function(_,data)
    for i = 1, #data.result.allowedFunctions do
      if(data.result.allowedFunctions[i].name == "ConsentGroup001") then
        group_id = data.result.allowedFunctions[i].id
      end
    end
  end)
end

function Test:OnAppPermissionConsent_OnPermissionsChange()
  self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
      source = "GUI",
      consentedFunctions = {{name = "ConsentGroup001", id = group_id, allowed = true}}
    })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
  :ValidIf(function(_,data)
    for i = 1, #data.payload.permissionItem do
      if data.payload.permissionItem[i].rpcName == "GetWayPoints" then
        return common_functions:CompareTables(
          data.payload.permissionItem[i].hmiPermissions,
          {allowed = {"BACKGROUND","FULL","LIMITED","NONE"}, userDisallowed = {}})
      end
    end
  end)
end

-------------------------------------------------------------------------------
-- TC49_Description: GetWayPoints
-- Note: This RPC is disallowed and need TC48 to allowed in Policy Table.
function Test:GetWayPoints_PositiveCase()
	local cid = self.mobileSession:SendRPC("GetWayPoints", { wayPointType = "ALL"})
	local response = {}
	response["wayPoints"] =
		{{
			coordinate =
			{
				latitudeDegrees = 1.1,
				longitudeDegrees = 1.1
			},
			locationName = "Hotel",
			addressLines =
			{
				"Hotel Bora",
				"Hotel 5 stars"
			},
			locationDescription = "VIP Hotel",
			phoneNumber = "Phone39300434",
			locationImage =
			{
				value ="icon.png",
				imageType ="DYNAMIC",
			},
			searchAddress =
			{
				countryName = "countryName",
				countryCode = "countryCode",
				postalCode = "postalCode",
				administrativeArea = "administrativeArea",
				subAdministrativeArea = "subAdministrativeArea",
				locality = "locality",
				subLocality = "subLocality",
				thoroughfare = "thoroughfare",
				subThoroughfare = "subThoroughfare"
			}
	} }
	EXPECT_HMICALL("Navigation.GetWayPoints", { wayPointType = "ALL"})
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)
	end)
	EXPECT_RESPONSE(cid, {success = true, resultCode = "SUCCESS"})
end

-------------------------------------------------------------------------------
-- TC50_Description: OnAppInterfaceUnregistered
function Test:OnAppInterfaceUnregistered_IGNITION_OFF()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "IGNITION_OFF"})
  self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {reason = "IGNITION_OFF"})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = false})
  common_functions:DelayedExp(2000)  
  StopSDL()
end

common_steps:PreconditionSteps("Precondition", 7)

function Test:OnAppInterfaceUnregistered_FACTORY_DEFAULTS()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "FACTORY_DEFAULTS"})
  self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{reason = "FACTORY_DEFAULTS"}})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = false})
  common_functions:DelayedExp(2000)
  StopSDL()
end

common_steps:PreconditionSteps("Precondition", 7)

function Test:OnAppInterfaceUnregistered_UNSUPPORTED_HMI_RESOURCE()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {
    appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self), 
    reason = "UNSUPPORTED_HMI_RESOURCE"})
  self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{reason = "UNSUPPORTED_HMI_RESOURCE"}})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = false})
  common_functions:DelayedExp(2000)
  StopSDL()
end

common_steps:PreconditionSteps("Precondition", 7)

function Test:OnAppInterfaceUnregistered_UNAUTHORIZED_TRANSPORT_REGISTRATION()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {
    appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self),
    reason = "UNAUTHORIZED_TRANSPORT_REGISTRATION"})
  self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{reason = "UNAUTHORIZED_TRANSPORT_REGISTRATION"}})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = false})
  common_functions:DelayedExp(2000)
  StopSDL()
end

common_steps:PreconditionSteps("Precondition", 7)

function Test:OnAppInterfaceUnregistered_MASTER_RESET()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications", {reason = "MASTER_RESET"})
  self.mobileSession:ExpectNotification("OnAppInterfaceUnregistered", {{reason = "MASTER_RESET"}})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = false})
  common_functions:DelayedExp(2000)
  StopSDL()
end

-------------------------------------------Postconditions-------------------------------------
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")
function Test:RestoreHmiCapabilities()
	common_preconditions:RestoreFile("hmi_capabilities.json")
end
