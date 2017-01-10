-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')
------------------------------------ Common Variables ---------------------------------------
local storagePath = config.SDLStoragePath..config.application1.registerAppInterfaceParams.appID.. "_" .. config.deviceMAC.. "/"
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
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
	EXPECT_NOTIFICATION("OnHashChange")
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
function Test:createInteractionChoiceSet(choiceSetID, choiceID)
	cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
	{
		interactionChoiceSetID = choiceSetID,
		choiceSet = setChoiseSet(choiceID),
	})
	EXPECT_HMICALL("VR.AddCommand",
	{
		cmdID = choiceID,
		type = "Choice",
		vrCommands = {"VrChoice"..tostring(choiceID) }
	})
	:Do(function(_,data)
		self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
	end)
	EXPECT_RESPONSE(cid, { resultCode = "SUCCESS", success = true })
end
choice_set_id_values = {0, 100, 200, 300, 2000000000}
for i=1, #choice_set_id_values do
	Test["CreateInteractionChoiceSet" .. choice_set_id_values[i] .. "_PositiveCase"] = function(self)
		if (choice_set_id_values[i] == 2000000000) then
			self:createInteractionChoiceSet(choice_set_id_values[i], 65535)
		else
			self:createInteractionChoiceSet(choice_set_id_values[i], choice_set_id_values[i])
		end
	end
end
-------------------------------------------------------------------------------
-- TC10_Description: DeleteInteractionChoiceSet
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
-- TC11_Description: DeleteFile
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
-- TC12_Description: ListFiles
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
-- TC13_Description: CreateInteractionChoiceSet
-- -- Common function for createInteractionChoiceSet
function performInteractionAllParams()
	local temp = {
		initialText = "StartPerformInteraction",
			initialPrompt = {{
				text = "Make your choice",
				type = "TEXT"
		}},
		interactionMode = "BOTH",
		interactionChoiceSetIDList =
		{
			100, 200, 300
		},
		helpPrompt = {
			{
				text = "Help Promptv ",
				type = "TEXT"
			},
			{
				text = "Help Promptvv ",
				type = "TEXT"
		}},
			timeoutPrompt = {{
				text = "Timeoutv",
				type = "TEXT"
			},
			{
				text = "Timeoutvv",
				type = "TEXT"
		}},
		timeout = 5000,
		vrHelp = {
			{
				image =
				{
					imageType = "DYNAMIC",
					value = storagePath.."icon.png"
				},
				text = "NewVRHelpv",
				position = 1
			},
			{
				image =
				{
					imageType = "DYNAMIC",
					value = storagePath.."icon.png"
				},
				text = "NewVRHelpvv",
				position = 2
			},
			{
				image =
				{
					imageType = "DYNAMIC",
					value = storagePath.."icon.png"
				},
				text = "NewVRHelpvvv",
				position = 3
			}
		},
		interactionLayout = "ICON_ONLY"
	}
	return temp
end

function setChoiseSet(choiceIDValue, size)
	if (size == nil) then
			local temp = {{
				choiceID = choiceIDValue,
				menuName ="Choice" .. tostring(choiceIDValue),
				vrCommands =
				{
					"VrChoice" .. tostring(choiceIDValue),
				},
				image =
				{
					value ="icon.png",
					imageType ="STATIC"
				}
		}}
		return temp
	else
		local temp = {}
		for i = 1, size do
			temp[i] = {
				choiceID = choiceIDValue+i-1,
				menuName ="Choice" .. tostring(choiceIDValue+i-1),
				vrCommands =
				{
					"VrChoice" .. tostring(choiceIDValue+i-1),
				},
				image =
				{
					value ="icon.png",
					imageType ="STATIC"
				}
			}
		end
		return temp
	end
end

function setExChoiseSet(choiceIDValues)
	local exChoiceSet = {}
	for i = 1, #choiceIDValues do
		exChoiceSet[i] = {
			choiceID = choiceIDValues[i],
			image =
			{
				value = "icon.png",
				imageType = "STATIC",
			},
			menuName = Choice100
		}
		if (choiceIDValues[i] == 2000000000) then
			exChoiceSet[i].choiceID = 65535
		end
	end
	return exChoiceSet
end
-------------------------------------------------------------------------------
-- TC14_Description: PerformInteraction
local request_parameters = performInteractionAllParams()
function Test:PerformInteraction_PositiveCase_VR_ONLY_SUCCESS()
	request_parameters.interactionMode = "VR_ONLY"
	cid = self.mobileSession:SendRPC("PerformInteraction",request_parameters)
	EXPECT_HMICALL("VR.PerformInteraction",{
		helpPrompt = request_parameters.helpPrompt,
		initialPrompt = request_parameters.initialPrompt,
		timeout = request_parameters.timeout,
		timeoutPrompt = request_parameters.timeoutPrompt
	})
	:Do(function(_,data)
		self.hmiConnection:SendNotification("TTS.Started")
		self.hmiConnection:SendNotification("VR.Started")
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self), systemContext = "VRSESSION"})
		self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
		self.hmiConnection:SendNotification("TTS.Stopped")
		self.hmiConnection:SendNotification("VR.Stopped")
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self), systemContext = "MAIN"})
	end)
	:ValidIf(function(_,data)
		if data.params.fakeParam or
		data.params.helpPrompt[1].fakeParam or
		data.params.initialPrompt[1].fakeParam or
		data.params.timeoutPrompt[1].fakeParam or
		data.params.ttsChunks then
			print(" \27[36m SDL re-sends fakeParam parameters to HMI in VR.PerformInteraction request \27[0m ")
			return false
		else
			return true
		end
	end)
	EXPECT_HMICALL("UI.PerformInteraction",{
		timeout = request_parameters.timeout,
		vrHelp = request_parameters.vrHelp,
		vrHelpTitle = request_parameters.initialText,
	})
	:Do(function(_,data)
		local function uiResponse()
			self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
		end
		RUN_AFTER(uiResponse, 10)
	end)
	:ValidIf(function(_,data)
		if data.params.fakeParam or
		data.params.vrHelp[1].fakeParam or
		data.params.ttsChunks then
			print(" \27[36m SDL re-sends fakeParam parameters to HMI in UI.PerformInteraction request \27[0m ")
			return false
		else
			return true
		end
	end)
	EXPECT_NOTIFICATION("OnHMIStatus",
	{ hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "MAIN"},
	{ hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
	{ hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION"},
	{ hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "VRSESSION"},
	{ hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	:Times(5)
	EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT" })
end

function Test:PerformInteraction_PositiveCase_MANUAL_ONLY_SUCCESS()
	request_parameters.interactionMode = "MANUAL_ONLY"
	cid = self.mobileSession:SendRPC("PerformInteraction", request_parameters)
	EXPECT_HMICALL("VR.PerformInteraction",
	{
		helpPrompt = request_parameters.helpPrompt,
		initialPrompt = request_parameters.initialPrompt,
		timeout = request_parameters.timeout,
		timeoutPrompt = request_parameters.timeoutPrompt
	})
	:Do(function(_,data)
		self.hmiConnection:SendNotification("TTS.Started")
		self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
	end)
	:ValidIf(function(_,data)
		if data.params.fakeParam or
		data.params.helpPrompt[1].fakeParam or
		data.params.initialPrompt[1].fakeParam or
		data.params.timeoutPrompt[1].fakeParam or
		data.params.ttsChunks then
			print(" \27[36m SDL re-sends fakeParam parameters to HMI in VR.PerformInteraction request \27[0m ")
			return false
		else
			return true
		end
	end)
	EXPECT_HMICALL("UI.PerformInteraction",{
		timeout = request_parameters.timeout,
		choiceSet = setExChoiseSet(request_parameters.interactionChoiceSetIDList),
		initialText =
		{
			fieldName = "initialInteractionText",
			fieldText = request_parameters.initialText
		}
	})
	:Do(function(_,data)
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self), systemContext = "HMI_OBSCURED"})
		self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
		self.hmiConnection:SendNotification("TTS.Stopped")
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self), systemContext = "MAIN"})
	end)
	:ValidIf(function(_,data)
		if data.params.fakeParam or
		data.params.ttsChunks then
			print(" \27[36m SDL re-sends fakeParam parameters to HMI in UI.PerformInteraction request \27[0m ")
			return false
		else
			return true
		end
	end)
	EXPECT_NOTIFICATION("OnHMIStatus",
	{ hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "MAIN"},
	{ hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "HMI_OBSCURED"},
	{ hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED"},
	{ hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	:Times(4)
	EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT"})
end

function Test:PerformInteraction_PositiveCase_BOTH_SUCCESS()
	request_parameters.interactionMode = "BOTH"
	cid = self.mobileSession:SendRPC("PerformInteraction",request_parameters)
	EXPECT_HMICALL("VR.PerformInteraction", {
		helpPrompt = request_parameters.helpPrompt,
		initialPrompt = request_parameters.initialPrompt,
		timeout = request_parameters.timeout,
		timeoutPrompt = request_parameters.timeoutPrompt
	})
	:Do(function(_,data)
		self.hmiConnection:SendNotification("VR.Started")
		self.hmiConnection:SendNotification("TTS.Started")
		self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self), systemContext = "VRSESSION"})
		local function firstSpeakTimeOut()
			self.hmiConnection:SendNotification("TTS.Stopped")
			self.hmiConnection:SendNotification("TTS.Started")
		end
		RUN_AFTER(firstSpeakTimeOut, 5)
		local function vrResponse()
			self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
			self.hmiConnection:SendNotification("VR.Stopped")
		end
		RUN_AFTER(vrResponse, 20)
	end)
	:ValidIf(function(_,data)
		if data.params.fakeParam or
		data.params.helpPrompt[1].fakeParam or
		data.params.initialPrompt[1].fakeParam or
		data.params.timeoutPrompt[1].fakeParam or
		data.params.ttsChunks then
			print(" \27[36m SDL re-sends fakeParam parameters to HMI in VR.PerformInteraction request \27[0m ")
			return false
		else
			return true
		end
	end)
	EXPECT_HMICALL("UI.PerformInteraction", {
		timeout = request_parameters.timeout,
		choiceSet = setExChoiseSet(request_parameters.interactionChoiceSetIDList),
		initialText =
		{
			fieldName = "initialInteractionText",
			fieldText = request_parameters.initialText
		},
		vrHelp = request_parameters.vrHelp,
		vrHelpTitle = request_parameters.initialText
	})
	:Do(function(_,data)
		local function choiceIconDisplayed()
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self), systemContext = "HMI_OBSCURED"})
		end
		RUN_AFTER(choiceIconDisplayed, 25)
		local function uiResponse()
			self.hmiConnection:SendNotification("TTS.Stopped")
			self.hmiConnection:SendError(data.id, data.method, "TIMED_OUT", "Perform Interaction error response.")
			self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self), systemContext = "MAIN"})
		end
		RUN_AFTER(uiResponse, 30)
	end)
	:ValidIf(function(_,data)
		if data.params.fakeParam or
		data.params.vrHelp[1].fakeParam or
		data.params.ttsChunks then
			print(" \27[36m SDL re-sends fakeParam parameters to HMI in UI.PerformInteraction request \27[0m ")
			return false
		else
			return true
		end
	end)
	EXPECT_NOTIFICATION("OnHMIStatus",
	{ hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"},
	{ hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION"},
	{ hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "VRSESSION"},
	{ hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "HMI_OBSCURED"},
	{ hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "HMI_OBSCURED"},
	{ hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
	:Times(6)
	EXPECT_RESPONSE(cid, { success = false, resultCode = "TIMED_OUT" })
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
commonPreconditions:BackupFile("hmi_capabilities.json")
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
		if common_functions:IsFileExist(config.SDLStoragePath.."/".."audio.wav") ~= true then
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
		if common_functions:IsFileExist(config.SDLStoragePath.."/".."audio.wav") ~= true then
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
		fileName = SystemFilesPath .. "/" .. request.fileName,
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
	local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
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
	})
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
	EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
	:Timeout(2000)
	:Do(function(_,data)
		EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
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
-- TC45_Description: GetWayPoints
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
-------------------------------------------Postconditions-------------------------------------
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")
function Test:RestoreHmiCapabilities()
	commonPreconditions:RestoreFile("hmi_capabilities.json")
end
