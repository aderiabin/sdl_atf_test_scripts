---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonFunctionsForCRQ20003 = require('user_modules/shared_testcases/commonFunctionsForCRQ20003')
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--------------------------------------------------------------------------------
--Precondition: preparation connecttest_resumption.lua
commonPreconditions:Connecttest_without_ExitBySDLDisconnect("connecttest_resumption.lua")
commonPreconditions:Connecttest_adding_timeOnReady("connecttest_resumption.lua")

Test = require('user_modules/connecttest_resumption')
require('cardinalities')
local mobile_session = require('mobile_session')
require('user_modules/AppTypes')

local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

local test_data ={
		{app="NAVIGATION",				appType ={"NAVIGATION"},	isMedia=false,	hmiLevel="FULL", 	audioStreamingState="AUDIBLE"},
		{app="MEDIA",					appType ={"MEDIA"},			isMedia=true,	hmiLevel="FULL", 	audioStreamingState="AUDIBLE"},
		{app="COMMUNICATION",			appType ={"COMMUNICATION"}, isMedia=false,	hmiLevel="FULL", 	audioStreamingState="AUDIBLE"},
		{app="NON MEDIA",				appType ={"DEFAULT"}, 		isMedia=false,	hmiLevel="FULL", 	audioStreamingState="NOT_AUDIBLE"}
	}
local hmi_level_FULL = "FULL"
local hmi_level_LIMITED = "LIMITED"

function Test:Postcondition_remove_user_connecttest()
  os.execute( "rm -f ./user_modules/connecttest_resumption.lua" )
end

--Precondition: backup smartDeviceLink.ini
commonPreconditions:BackupFile("smartDeviceLink.ini")

-- set ApplicationResumingTimeout in .ini file to resuming_timeout;
local resuming_timeout = 3000
commonFunctions:SetValuesInIniFile("%p?ApplicationResumingTimeout%s?=%s-[%d]-%s-\n", "ApplicationResumingTimeout", resuming_timeout)
config.defaultProtocolVersion = 2

local HMIAppID

local DefaulthmiLevel = "NONE"
local AppValuesOnHMIStatusFULL ={hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}
local AppValuesOnHMIStatusLIMITED ={hmiLevel = "LIMITED", systemContext = "MAIN", audioStreamingState = "AUDIBLE"}

local function userPrint( color, message)
  print ("\27[" .. tostring(color) .. "m " .. tostring(message) .. " \27[0m")
end

--////////////////////////////////////////////////////////////////////////////////////////////--
--APPLINK-16182: VR IS ACTIVE BEFORE OR AFTER APP IS CONNECTED
--CHECK WITH SINGLE APP
--////////////////////////////////////////////////////////////////////////////////////////////--
--------------------------------------------------------------------------------
-- Case: Resumption_HMIlevelFULL_VRTrue_Before_App_Is_Connected
-- Step1: Change App Type
-- Step2: Register/Activate app
-- Step3: IGNITION_OFF
-- Step4: Start SDL
-- Step5: VR.Start
-- Step6: Register App
-- Step7: Resumption postpone
-- Step8: VR.End
-- Step9: Resumption success
---------------------------------------------------------------------------------
local function ResumptionSingleAppFull_VRIsTrueBeforeAppIsConnected_IGNITION_OFF()		
	for i =1, #test_data do
		commonFunctions:newTestCasesGroup("Single App (FULL) - Next IGNITION cycle: VR is active BEFORE app is connected and waiting for resume: " ..test_data[i].app)
		
		--Precondition:Unregister/Register/Activate App
		commonSteps:UnregisterApplication(test_data[i].app.."_Unregister_App")				
		commonFunctionsForCRQ20003:RegisterTheFirstApp(test_data[i].appType, test_data[i].isMedia,test_data[i].app.."_Register_App")
		commonFunctionsForCRQ20003:ActivateTheFirstApp(test_data[i].app.."_Activate_App")	

		--IGNITION_OFF
		commonFunctionsForCRQ20003:IgnitionOff()
				
		--StartSDL
		commonFunctionsForCRQ20003:StartSDL(test_data[i].app)	
		
		--VR is started before app is connected
		commonFunctionsForCRQ20003:VRIsStarted(test_data[i].app.."_VR_Is_Started")
		commonFunctionsForCRQ20003:StartService1(test_data[i].app.."_Start_Service")
		commonFunctionsForCRQ20003:RegisterTheFirstApp(test_data[i].appType, test_data[i].isMedia,test_data[i].app.."_Register_App")

		--VR is stop and verify resumpt succesful
		commonFunctionsForCRQ20003:VRIsStopped(test_data[i].app.."_VR_Is_Stopped")
		commonFunctionsForCRQ20003:ResumptionSuccessWhenVREnded1App()		
	end
end
ResumptionSingleAppFull_VRIsTrueBeforeAppIsConnected_IGNITION_OFF()

--------------------------------------------------------------------------------
-- Case: Resumption_HMIlevelLIMITTED_VRTrue_Before_App_Is_Connected
-- Step1: Change App Type
-- Step2: Register/Activate app/ChangeHMIToLimited
-- Step3: IGNITION_OFF
-- Step4: Start SDL
-- Step5: VR.Start
-- Step6: Register App
-- Step7: Resumption postpone
-- Step8: VR.End
-- Step9: Resumption success
---------------------------------------------------------------------------------
local function ResumptionSingleAppLimited_VRIsTrueBeforeAppIsConnected_IGNITION_OFF()		
	for i =1, #test_data-1 do
		commonFunctions:newTestCasesGroup("Single App (LIMITED) - Next IGNITION cycle: VR is active BEFORE app is connected and waiting for resume: " ..test_data[i].app)
		
		--Precondition:Unregister/Register/Activate App
		commonSteps:UnregisterApplication(test_data[i].app.."_Unregister_App")				
		commonFunctionsForCRQ20003:RegisterTheFirstApp(test_data[i].appType, test_data[i].isMedia,test_data[i].app.."_Register_App")
		commonFunctionsForCRQ20003:ActivateTheFirstApp(test_data[i].app.."_Activate_App")	
		
		--Change App to LIMITED
		commonFunctionsForCRQ20003:ChangeHMIToLimited(test_data[i].app.."_Change_App_To_Limited")
		
		--IGNITION_OFF
		commonFunctionsForCRQ20003:IgnitionOff()
				
		--StartSDL
		commonFunctionsForCRQ20003:StartSDL(test_data[i].app)	
		
		--VR is started before app is connected
		commonFunctionsForCRQ20003:VRIsStarted(test_data[i].app.."_VR_Is_Started")
		commonFunctionsForCRQ20003:StartService1(test_data[i].app.."_Start_Service")
		commonFunctionsForCRQ20003:RegisterTheFirstApp(test_data[i].appType, test_data[i].isMedia,test_data[i].app.."_Register_App")

		--VR is stop and verify resumpt succesful
		commonFunctionsForCRQ20003:VRIsStopped(test_data[i].app.."_VR_Is_Stopped")
		commonFunctionsForCRQ20003:ResumptionSuccessWhenVREnded1App()	
	end
end
ResumptionSingleAppLimited_VRIsTrueBeforeAppIsConnected_IGNITION_OFF()

--------------------------------------------------------------------------------
-- Case: Resumption_HMIlevelFULL_VRTrue_After_App_Is_Connected
-- Step1: Change App Type
-- Step2: Register/Activate app
-- Step3: IGNITION_OFF
-- Step4: Start SDL
-- Step5: Register App
-- Step6: VR.Start
-- Step7: Resumption postpone
-- Step8: VR.End
-- Step9: Resumption success
---------------------------------------------------------------------------------
local function ResumptionSingleAppFull_VRIsTrueAfterAppIsConnected_IGNITION_OFF()		
	for i =1, #test_data do
		commonFunctions:newTestCasesGroup("Single App (FULL) - Next IGNITION cycle: VR is active AFTER app is connected and waiting for resume: " ..test_data[i].app)
		
		--Precondition:Unregister/Register/Activate App
		commonSteps:UnregisterApplication(test_data[i].app.."_Unregister_App")				
		commonFunctionsForCRQ20003:RegisterTheFirstApp(test_data[i].appType, test_data[i].isMedia,test_data[i].app.."_Register_App")
		commonFunctionsForCRQ20003:ActivateTheFirstApp(test_data[i].app.."_Activate_App")	

		--IGNITION_OFF
		commonFunctionsForCRQ20003:IgnitionOff()
				
		--StartSDL
		commonFunctionsForCRQ20003:StartSDL(test_data[i].app)	
		
		--VR is started after app is connected		
		commonFunctionsForCRQ20003:StartService1(test_data[i].app.."_Start_Service")
		commonFunctionsForCRQ20003:RegisterTheFirstApp(test_data[i].appType, test_data[i].isMedia,test_data[i].app.."_Register_App")
		commonFunctionsForCRQ20003:VRIsStarted(test_data[i].app.."_VR_Is_Started")

		--VR is stop and verify resumpt succesful
		commonFunctionsForCRQ20003:VRIsStopped(test_data[i].app.."_VR_Is_Stopped")
		commonFunctionsForCRQ20003:ResumptionSuccessWhenVREnded1App()		
	end
end
ResumptionSingleAppFull_VRIsTrueAfterAppIsConnected_IGNITION_OFF()

--------------------------------------------------------------------------------
-- Case: Resumption_HMIlevelLIMITTED_VRTrue_Before_App_Is_Connected
-- Step1: Change App Type
-- Step2: Register/Activate app/ChangeHMIToLimited
-- Step3: IGNITION_OFF
-- Step4: Start SDL
-- Step5: Register App
-- Step6: VR.Start
-- Step7: Resumption postpone
-- Step8: VR.End
-- Step9: Resumption success
---------------------------------------------------------------------------------
local function ResumptionSingleAppLimited_VRIsTrueAfterAppIsConnected_IGNITION_OFF()		
	for i =1, #test_data-1 do
		commonFunctions:newTestCasesGroup("Single App (LIMITED) - Next IGNITION cycle: VR is active AFTER app is connected and waiting for resume: " ..test_data[i].app)
		
		--Precondition:Unregister/Register/Activate App
		commonSteps:UnregisterApplication(test_data[i].app.."_Unregister_App")				
		commonFunctionsForCRQ20003:RegisterTheFirstApp(test_data[i].appType, test_data[i].isMedia,test_data[i].app.."_Register_App")
		commonFunctionsForCRQ20003:ActivateTheFirstApp(test_data[i].app.."_Activate_App")	
		
		--Change App to LIMITED
		commonFunctionsForCRQ20003:ChangeHMIToLimited(test_data[i].app.."_Change_App_To_Limited")
		
		--IGNITION_OFF
		commonFunctionsForCRQ20003:IgnitionOff()
				
		--StartSDL
		commonFunctionsForCRQ20003:StartSDL(test_data[i].app)	
		
		--VR is started after app is connected		
		commonFunctionsForCRQ20003:StartService1(test_data[i].app.."_Start_Service")
		commonFunctionsForCRQ20003:RegisterTheFirstApp(test_data[i].appType, test_data[i].isMedia,test_data[i].app.."_Register_App")
		commonFunctionsForCRQ20003:VRIsStarted(test_data[i].app.."_VR_Is_Started")

		--VR is stop and verify resumpt succesful
		commonFunctionsForCRQ20003:VRIsStopped(test_data[i].app.."_VR_Is_Stopped")
		commonFunctionsForCRQ20003:ResumptionSuccessWhenVREnded1App()	
		end		
	end
ResumptionSingleAppLimited_VRIsTrueAfterAppIsConnected_IGNITION_OFF()

--////////////////////////////////////////////////////////////////////////////////////////////--
--APPLINK-16182: VR IS ACTIVE BEFORE OR AFTER APP IS CONNECTED
--CHECK WITH MULTIPLE APPS (FULL, LIMITED, LIMITED, BACKGROUND)
--////////////////////////////////////////////////////////////////////////////////////////////--
--------------------------------------------------------------------------------
-- Case: Multiple Apps (FULL,LIMITED,LIMITED,BACKGROUND) - Next IGNITION cycle: VR is active BEFORE apps is connected and waiting for resume:
-- Step1: Register and activate 4 Apps
-- Step2: IGNITION_OFF 4 Apps
-- Step3: Start SDL
-- Step4: VR.Start
-- Step5: Register App
-- Step6: Resume postpone
-- Step7: VR.End with isActive valid
-- Step8: Resumption success
---------------------------------------------------------------------------------
local function ResumptionMultiApps_FullLimitedLimitedBackground_VRIsTrueBeforeAppIsConnected_IGNITION_OFF()		
	commonFunctions:newTestCasesGroup("Multiple Apps (FULL,LIMITED,LIMITED,BACKGROUND) - Next IGNITION cycle: VR is active BEFORE apps is connected and waiting for resume: ")
	
	-- precondition: Unregister App	- Add new session		
	commonSteps:UnregisterApplication("Unregister_App")			
	commonSteps:precondition_AddNewSession("Precondition_AddNewSession2")	
	commonFunctionsForCRQ20003:Precondition_AddNewSession3()
	commonFunctionsForCRQ20003:Precondition_AddNewSession4()
	
	--Register 4 Apps	
	commonFunctionsForCRQ20003:RegisterTheFirstApp(test_data[4].appType, test_data[4].isMedia)
	commonFunctionsForCRQ20003:RegisterTheSecondApp(test_data[3].appType, test_data[3].isMedia)
	commonFunctionsForCRQ20003:RegisterTheThirdApp(test_data[2].appType, test_data[2].isMedia)
	commonFunctionsForCRQ20003:RegisterTheFourthApp(test_data[1].appType, test_data[1].isMedia)
		
	--Activate 4 Apps	
	commonFunctionsForCRQ20003:ActivateTheFirstApp()
	commonFunctionsForCRQ20003:ActivateTheSecondApp()
	commonFunctionsForCRQ20003:ActivateTheThirdApp()
	commonFunctionsForCRQ20003:ActivateTheFourthApp()
	
	--IGNITION_OFF
	commonFunctionsForCRQ20003:IgnitionOff(4)
	
	--StartSDL -IGNITION_ON
	commonFunctionsForCRQ20003:StartSDL("Multiple_Apps")
	commonFunctionsForCRQ20003:Start4Session()
	
	--VR is Started before Register 4 app
	commonFunctionsForCRQ20003:VRIsStarted()
	
	commonFunctionsForCRQ20003:Start4Service()	
	commonFunctionsForCRQ20003:RegisterTheFirstApp(test_data[4].appType, test_data[4].isMedia)
	commonFunctionsForCRQ20003:RegisterTheSecondApp(test_data[3].appType, test_data[3].isMedia)
	commonFunctionsForCRQ20003:RegisterTheThirdApp(test_data[2].appType, test_data[2].isMedia)
	commonFunctionsForCRQ20003:RegisterTheFourthApp(test_data[1].appType, test_data[1].isMedia)
	
	--VR is stopped and verify the resumpt successful
	commonFunctionsForCRQ20003:VRIsStopped()
	commonFunctionsForCRQ20003:ResumptionSuccessWhenVREnded4Apps_FullL_Limited_Limited_Background()
end
ResumptionMultiApps_FullLimitedLimitedBackground_VRIsTrueBeforeAppIsConnected_IGNITION_OFF()

--------------------------------------------------------------------------------
-- Case: Multiple Apps (FULL,LIMITED,LIMITED,BACKGROUND) - Next IGNITION cycle: VR is active AFTER apps is connected and waiting for resume:
-- Step1: Register and activate 4 Apps
-- Step2: IGNITION_OFF 4 Apps
-- Step3: Start SDL
-- Step4: VR.Start
-- Step5: Register App
-- Step6: Resume postpone
-- Step7: VR.End with isActive valid
-- Step8: Resumption success
---------------------------------------------------------------------------------
local function ResumptionMultiApps_FullLimitedLimitedBackground_VRIsTrueAfterAppIsConnected_IGNITION_OFF()		
	commonFunctions:newTestCasesGroup("Multiple Apps (FULL,LIMITED,LIMITED,BACKGROUND) - Next IGNITION cycle: VR is active AFTER apps is connected and waiting for resume: ")
	
	--Precondition: Unregister 4 Apps
	commonSteps:UnregisterApplication("Unregister_App1")	
	commonFunctionsForCRQ20003:UnregisterApp2("Unregister_App2")	
	commonFunctionsForCRQ20003:UnregisterApp3("Unregister_App3")
	commonFunctionsForCRQ20003:UnregisterApp4("Unregister_App4")
	
	--Register 4 Apps	
	commonFunctionsForCRQ20003:RegisterTheFirstApp(test_data[4].appType, test_data[4].isMedia)
	commonFunctionsForCRQ20003:RegisterTheSecondApp(test_data[3].appType, test_data[3].isMedia)
	commonFunctionsForCRQ20003:RegisterTheThirdApp(test_data[2].appType, test_data[2].isMedia)
	commonFunctionsForCRQ20003:RegisterTheFourthApp(test_data[1].appType, test_data[1].isMedia)
		
	--Activate 4 Apps	
	commonFunctionsForCRQ20003:ActivateTheFirstApp()
	commonFunctionsForCRQ20003:ActivateTheSecondApp()
	commonFunctionsForCRQ20003:ActivateTheThirdApp()
	commonFunctionsForCRQ20003:ActivateTheFourthApp()
	
	--IGNITION_OFF
	commonFunctionsForCRQ20003:IgnitionOff(4)
	
	--StartSDL -IGNITION_ON
	commonFunctionsForCRQ20003:StartSDL("Multiple_Apps")
	commonFunctionsForCRQ20003:Start4Session()
	
	--VR is Started after Register 4 app
	commonFunctionsForCRQ20003:Start4Service()	
	commonFunctionsForCRQ20003:RegisterTheFirstApp(test_data[4].appType, test_data[4].isMedia)
	commonFunctionsForCRQ20003:RegisterTheSecondApp(test_data[3].appType, test_data[3].isMedia)
	commonFunctionsForCRQ20003:RegisterTheThirdApp(test_data[2].appType, test_data[2].isMedia)
	commonFunctionsForCRQ20003:RegisterTheFourthApp(test_data[1].appType, test_data[1].isMedia)
	
	commonFunctionsForCRQ20003:VRIsStarted()
	
	--VR is stopped and verify the resumpt successful
	commonFunctionsForCRQ20003:VRIsStopped()
	commonFunctionsForCRQ20003:ResumptionSuccessWhenVREnded4Apps_FullL_Limited_Limited_Background()
end
ResumptionMultiApps_FullLimitedLimitedBackground_VRIsTrueAfterAppIsConnected_IGNITION_OFF()

--////////////////////////////////////////////////////////////////////////////////////////////--
--APPLINK-16182: VR IS ACTIVE BEFORE OR AFTER APP IS CONNECTED
--CHECK WITH MULTIPLE APPS (FULL, LIMITED, LIMITED, LIMITED)
--////////////////////////////////////////////////////////////////////////////////////////////--
--------------------------------------------------------------------------------
-- Case: Multiple Apps (FULL,LIMITED,LIMITED,LIMITED) - Next IGNITION cycle: VR is active BEFORE apps is connected and waiting for resume:
-- Step1: Register and activate 4 Apps
-- Step2: IGNITION_OFF 4 Apps
-- Step3: Start SDL
-- Step4: VR.Start
-- Step5: Register App
-- Step6: Resume postpone
-- Step7: VR.End with isActive valid
-- Step8: Resumption success
---------------------------------------------------------------------------------
local function ResumptionMultiApps_FullLimitedLimitedLimited_VRIsTrueBeforeAppIsConnected_IGNITION_OFF()		
	commonFunctions:newTestCasesGroup("Multiple Apps (FULL, LIMITED, LIMITED, LIMITED) - Next IGNITION cycle: VR is active AFTER apps is connected and waiting for resume")
	
	--Precondition: Unregister 4 Apps
	commonSteps:UnregisterApplication("Unregister_App1")	
	commonFunctionsForCRQ20003:UnregisterApp2("Unregister_App2")	
	commonFunctionsForCRQ20003:UnregisterApp3("Unregister_App3")
	commonFunctionsForCRQ20003:UnregisterApp4("Unregister_App4")

	--Register 4 Apps	
	commonFunctionsForCRQ20003:RegisterTheFirstApp(test_data[4].appType, test_data[4].isMedia)
	commonFunctionsForCRQ20003:RegisterTheSecondApp(test_data[3].appType, test_data[3].isMedia)
	commonFunctionsForCRQ20003:RegisterTheThirdApp(test_data[2].appType, test_data[2].isMedia)
	commonFunctionsForCRQ20003:RegisterTheFourthApp(test_data[1].appType, test_data[1].isMedia)
		
	--Activate 4 Apps	
	commonFunctionsForCRQ20003:ActivateTheSecondApp()
	commonFunctionsForCRQ20003:ActivateTheThirdApp()
	commonFunctionsForCRQ20003:ActivateTheFourthApp()
	commonFunctionsForCRQ20003:ActivateTheFirstApp()
	
	--IGNITION_OFF
	commonFunctionsForCRQ20003:IgnitionOff(4)
	
	--StartSDL -IGNITION_ON
	commonFunctionsForCRQ20003:StartSDL("Multiple_Apps")
	commonFunctionsForCRQ20003:Start4Session()
	
	--VR is Started before Register 4 app
	commonFunctionsForCRQ20003:VRIsStarted()
	
	commonFunctionsForCRQ20003:Start4Service()	
	commonFunctionsForCRQ20003:RegisterTheFirstApp(test_data[4].appType, test_data[4].isMedia)
	commonFunctionsForCRQ20003:RegisterTheSecondApp(test_data[3].appType, test_data[3].isMedia)
	commonFunctionsForCRQ20003:RegisterTheThirdApp(test_data[2].appType, test_data[2].isMedia)
	commonFunctionsForCRQ20003:RegisterTheFourthApp(test_data[1].appType, test_data[1].isMedia)
			
	--VR is stopped and verify the resumpt successful
	commonFunctionsForCRQ20003:VRIsStopped()
	commonFunctionsForCRQ20003:ResumptionSuccessWhenVREnded4Apps_Full_Limited_Limited_Limited()
end
ResumptionMultiApps_FullLimitedLimitedLimited_VRIsTrueBeforeAppIsConnected_IGNITION_OFF()

--------------------------------------------------------------------------------
-- Case: Multiple Apps (FULL,LIMITED,LIMITED,LIMITED) - Next IGNITION cycle: VR is active AFTER apps is connected and waiting for resume
-- Step1: Register and activate 4 Apps
-- Step2: IGNITION_OFF 4 Apps
-- Step3: Start SDL
-- Step4: VR.Start
-- Step5: Register App
-- Step6: Resume postpone
-- Step7: VR.End with isActive valid
-- Step8: Resumption success
---------------------------------------------------------------------------------
local function ResumptionMultiApps_FullLimitedLimitedLimited_VRIsTrueAfterAppIsConnected_IGNITION_OFF()		
	commonFunctions:newTestCasesGroup("Multiple Apps (FULL,LIMITED,LIMITED,LIMITED) - Next IGNITION cycle: VR is active AFTER apps is connected and waiting for resume")
	--Precondition: Unregister 4 Apps
	commonSteps:UnregisterApplication("Unregister_App1")	
	commonFunctionsForCRQ20003:UnregisterApp2("Unregister_App2")	
	commonFunctionsForCRQ20003:UnregisterApp3("Unregister_App3")
	commonFunctionsForCRQ20003:UnregisterApp4("Unregister_App4")

	--Register 4 Apps	
	commonFunctionsForCRQ20003:RegisterTheFirstApp(test_data[4].appType, test_data[4].isMedia)
	commonFunctionsForCRQ20003:RegisterTheSecondApp(test_data[3].appType, test_data[3].isMedia)
	commonFunctionsForCRQ20003:RegisterTheThirdApp(test_data[2].appType, test_data[2].isMedia)
	commonFunctionsForCRQ20003:RegisterTheFourthApp(test_data[1].appType, test_data[1].isMedia)
		
	--Activate 4 Apps	
	commonFunctionsForCRQ20003:ActivateTheSecondApp()
	commonFunctionsForCRQ20003:ActivateTheThirdApp()
	commonFunctionsForCRQ20003:ActivateTheFourthApp()
	commonFunctionsForCRQ20003:ActivateTheFirstApp()
	
	--IGNITION_OFF
	commonFunctionsForCRQ20003:IgnitionOff(4)
	
	--StartSDL -IGNITION_ON
	commonFunctionsForCRQ20003:StartSDL("Multiple_Apps")
	commonFunctionsForCRQ20003:Start4Session()
	
	--VR is Started after Register 4 app	
	commonFunctionsForCRQ20003:Start4Service()	
	commonFunctionsForCRQ20003:RegisterTheFirstApp(test_data[4].appType, test_data[4].isMedia)
	commonFunctionsForCRQ20003:RegisterTheSecondApp(test_data[3].appType, test_data[3].isMedia)
	commonFunctionsForCRQ20003:RegisterTheThirdApp(test_data[2].appType, test_data[2].isMedia)
	commonFunctionsForCRQ20003:RegisterTheFourthApp(test_data[1].appType, test_data[1].isMedia)
	
	commonFunctionsForCRQ20003:VRIsStarted()
			
	--VR is stopped and verify the resumpt successful
	commonFunctionsForCRQ20003:VRIsStopped()
	commonFunctionsForCRQ20003:ResumptionSuccessWhenVREnded4Apps_Full_Limited_Limited_Limited()
end
ResumptionMultiApps_FullLimitedLimitedLimited_VRIsTrueAfterAppIsConnected_IGNITION_OFF()

---------------------------------------------------------------------------------------------
-------------------------------------------Postcondition-------------------------------------
---------------------------------------------------------------------------------------------

function Test:Postcondition_RestoreIniFile()
  commonPreconditions:RestoreFile("smartDeviceLink.ini")
end