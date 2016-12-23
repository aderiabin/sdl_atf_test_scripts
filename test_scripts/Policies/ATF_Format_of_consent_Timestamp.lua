-- Script is developed by Byanova Irina
-- for ATF version 2.2

Test = require('connecttest')
require('cardinalities')
local mobile_session = require('mobile_session')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')
local mobile  = require('mobile_connection')

----------------------------------------------------------------------------
-- User required files

require('user_modules/AppTypes')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local Policy = require('user_modules/shared_testcases/testCasesForPolicyTable')

----------------------------------------------------------------------------
-- User required variables
local CurrentUnixDateForDeviceConsent
local appIDValue
local CurrentUnixDateForPermissionConsent
local TimeStamp_InDeviceConsentGroupTableValue
local TimeStamp_InConsentGroupTableValue

---------------------------------------------------------------------------------------------
------------------------------------------Common functions-----------------------------------
---------------------------------------------------------------------------------------------

-- Check direcrory existence 
local function Directory_exist(DirectoryPath)
	local returnValue

	local Command = assert( io.popen(  "[ -d " .. tostring(DirectoryPath) .. " ] && echo \"Exist\" || echo \"NotExist\"" , 'r'))
	local CommandResult = tostring(Command:read( '*l' ))

	if 
		CommandResult == "NotExist" then
			returnValue = false
	elseif 
		CommandResult == "Exist" then
		returnValue =  true
	else 
		commonFunctions:userPrint(31," Some unexpected result in Directory_exist function, CommandResult = " .. tostring(CommandResult))
		returnValue = false
	end

	return returnValue
end


local function RestartSDL(prefix, DeleteStorageFolder)

	Test["Precondition_StopSDL_" .. tostring(prefix) ] = function(self)
		commonFunctions:userPrint(35, "================= Precondition ==================")
		StopSDL()
	end

	if DeleteStorageFolder then
		Test["Precondition_DeleteStorageFolder_" .. tostring(prefix)] = function(self)
			commonSteps:DeleteLogsFileAndPolicyTable()
		end
	end

	Test["Precondition_StartSDL_" .. tostring(prefix) ] = function(self)
		StartSDL(config.pathToSDL, config.ExitOnCrash)
	end

	Test["Precondition_InitHMI_" .. tostring(prefix) ] = function(self)
		self:initHMI()
	end

	Test["Precondition_InitHMI_onReady_" .. tostring(prefix) ] = function(self)
		self:initHMI_onReady()
	end

	Test["Precondition_ConnectMobile_" .. tostring(prefix) ] = function(self)
  		self:connectMobile()
	end

	Test["Precondition_StartSessionRegisterApp_" .. tostring(prefix) ] = function(self)
  		self:startSession()
	end

end

function DelayedExp(time)
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  :Timeout(time+1000)
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, time)
end

-- Consent device
function ConsentDevice(self, allowedValue, idValue, nameValue)
	--hmi side: sending SDL.GetUserFriendlyMessage request
	local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", 
						{language = "EN-US", messageCodes = {"DataConsent"}})

	--hmi side: expect SDL.GetUserFriendlyMessage response
	--TODO: Update after resolving APPLINK-16094 EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
	EXPECT_HMIRESPONSE(RequestId)
		:Do(function(_,data)

			--hmi side: send request SDL.OnAllowSDLFunctionality
			self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", 
				{allowed = allowedValue, source = "GUI", device = {id = idValue, name = nameValue}})
		end)
end

--======================================================================================--
--Precondition: Restart SDL with deleting storage folder
--======================================================================================--
RestartSDL("InitialPrecondition", true)

--======================================================================================--
-- PoliciesManager adds a timestamp into "time_stamp" field of Local PolicyTable in the format of "<yyyy-mm-dd>T<hh:mm:ss>Z"
--======================================================================================--

-- Consent connected device
function Test:ConsentDevice()
	appIDValue = self.applications[config.application1.registerAppInterfaceParams.appName]

	ConsentDevice(self, true, config.deviceMAC, config.mobileHost )

	-- Get time of Device consent
	local CurrentUnixDateCommand = assert( io.popen( "date +%s" , 'r'))
	CurrentUnixDateForDeviceConsent = CurrentUnixDateCommand:read( '*l' )
end

--======================================================================================--
-- Update Policy with group needed consent
Policy:updatePolicy("files/PTU_with_LocationGroupForApp.json", appIDValue)

--======================================================================================--
-- User consent of "Location" group
function Test:UserGroupConsent()
	--Get GetListOfPermissions		
	--hmi side: sending SDL.GetListOfPermissions request to SDL
	local RequestIdGetListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
	
	

	-- hmi side: expect SDL.GetListOfPermissions response
	-- TODO: Update after resolving APPLINK-16094 to  EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions,{result = {code = 0, method = "SDL.GetListOfPermissions", allowedFunctions = {{name = "Location"}}}})
	EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions)
		:Do(function(_,data)
				
			--Get groupID
			local groupID
			for i = 1, #data.result.allowedFunctions do
				if data.result.allowedFunctions[i].name == "Location" then
					groupID = data.result.allowedFunctions[i].id
					break
				end					

			end
			
			if groupID == nil then
				commonFunctions:printError("Error: userConsent function: 'Location' group name is not exist")					
			end
							
			
			--hmi side: sending SDL.OnAppPermissionConsent
			self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications[config.application1.registerAppInterfaceParams.appName], consentedFunctions = {{ allowed = true, id = groupID, name = "Location"}}, source = "GUI"})
			-- Get time of group consent
			local CurrentUnixDateCommand = assert( io.popen( "date +%s" , 'r'))
			CurrentUnixDateForPermissionConsent = CurrentUnixDateCommand:read( '*l' )
			
			EXPECT_NOTIFICATION("OnPermissionsChange")                   
		end)
end

--======================================================================================--
-- Timestamp in device_consent_group table
function Test:TimeStamp_InDeviceConsentGroupTable()
	local errorFlag = false
	local ErrorMessage = ""
	os.execute( " sleep 5 " )
	local TimeStamp_InDeviceConsentGroupTable = "sqlite3 " .. tostring(config.pathToSDL) .. "storage/policy.sqlite \"SELECT time_stamp FROM device_consent_group WHERE rowid = 1\""

  	local aHandle = assert( io.popen( TimeStamp_InDeviceConsentGroupTable , 'r'))
    TimeStamp_InDeviceConsentGroupTableValue = aHandle:read( '*l' ) 

    if TimeStamp_InDeviceConsentGroupTableValue then

	    commonFunctions:userPrint(33, "TimeStamp in device_consent_group " .. tostring(TimeStamp_InDeviceConsentGroupTableValue))

		local Date, separatorFirst, Time, separatorSecond = TimeStamp_InDeviceConsentGroupTableValue:match("([%d-]-)([T])([%d:]-)([Z])")

		-- Get current date
		local CurrentDateCommand = assert( io.popen( "date +%Y-%m-%d " , 'r'))
		CurrentDate = CurrentDateCommand:read( '*l' )

		if Date then
			if Date ~= CurrentDate then
				ErrorMessage = ErrorMessage .. "Date in device_consent_group is not equal to current date. Date from device_consent_group is " .. tostring(Date) .. ", current date is " .. tostring(CurrentDate) .. ". \n"
				errorFlag = true
			end
		else
			ErrorMessage = ErrorMessage .."Date in device_consent_group is wrong or absent. \n"
			errorFlag = true
		end

		if Time then

			local CurrentDateCommand = assert( io.popen( "date -d @" .. tostring(CurrentUnixDateForDeviceConsent) .. "  +%H:%M:%S " , 'r'))
			TimeForPermissionConsentValue = CurrentDateCommand:read( '*l' )

			local CurrentDateCommand2 = assert( io.popen( "date -d @" .. tostring(tonumber(CurrentUnixDateForDeviceConsent)+1) .. "  +%H:%M:%S " , 'r'))

			TimeForPermissionConsentValuePlusSecond = CurrentDateCommand2:read( '*l' )

			local CurrentDateCommand3 = assert( io.popen( "date -d @" .. tostring(tonumber(CurrentUnixDateForDeviceConsent)-1) .. "  +%H:%M:%S " , 'r'))
			TimeForPermissionConsentValueMinusSecond = CurrentDateCommand3:read( '*l' )

			if Time == TimeForPermissionConsentValue or 
				Time == TimeForPermissionConsentValuePlusSecond or 
				Time == TimeForPermissionConsentValueMinusSecond then
			else
				ErrorMessage = ErrorMessage .. "Time in device_consent_group is not equal to time of device consent. Time from device_consent_group is " .. tostring(Time) .. ", time to check is " .. tostring(TimeForPermissionConsentValue) .. " +- 1 second. \n" 
				errorFlag = true
			end

		else
			print("Time in device_consent_group is wrong or absent")
		end


		if separatorFirst then
			if separatorFirst ~= "T" then
				ErrorMessage = ErrorMessage .. "Separator 'T' between date and time in device_consent_group is not equal to 'T'. Separator from device_consent_group is " .. tostring(separatorFirst) .. ". \n"
				errorFlag = true
			end
		else
			ErrorMessage = ErrorMessage .."Separator 'T' between date and time in device_consent_group is wrong or absent. \n"
			errorFlag = true
		end

		if separatorSecond then
			if separatorSecond ~= "Z" then
				ErrorMessage = ErrorMessage .. "Separator 'Z' after date and time in device_consent_group is not equal to 'Z'. Separator from device_consent_group is " .. tostring(separatorSecond) .. ". \n"
				errorFlag = true
			end
		else
			ErrorMessage = ErrorMessage .."Separator 'Z' after date and time in device_consent_group is wrong or absent. \n"
			errorFlag = true
		end
	else
		ErrorMessage = ErrorMessage .. "TimeStamp is absent or empty in device_consent_group. \n"
		errorFlag = true
	end


	if errorFlag == true then
		self:FailTestCase(ErrorMessage)
	end

end

--======================================================================================--
-- Timestamp in consent_group table
function Test:TimeStamp_InConsentGroupTable()
	local errorFlag = false
	local ErrorMessage = ""
	os.execute( " sleep 3 " )
	local TimeStamp_InConsentGroupTable = "sqlite3 " .. tostring(config.pathToSDL) .. "storage/policy.sqlite \"SELECT time_stamp FROM consent_group WHERE rowid = 1\""

  	local aHandle = assert( io.popen( TimeStamp_InConsentGroupTable , 'r'))
    TimeStamp_InConsentGroupTableValue = aHandle:read( '*l' )

    if  TimeStamp_InConsentGroupTableValue then

	    commonFunctions:userPrint(33, "TimeStamp in consent_group " .. tostring(TimeStamp_InConsentGroupTableValue))

		local Date, separatorFirst, Time, separatorSecond = TimeStamp_InConsentGroupTableValue:match("([%d-]-)([T])([%d:]-)([Z])")

		-- Get current date
		local CurrentDateCommand = assert( io.popen( "date +%Y-%m-%d " , 'r'))
		CurrentDate = CurrentDateCommand:read( '*l' )

		if Date then
			if Date ~= CurrentDate then
				ErrorMessage = ErrorMessage .. "Date in consent_group is not equal to current date. Date from consent_group is " .. tostring(Date) .. ", current date is" .. tostring(CurrentDate) .. ". \n"
				errorFlag = true
			end
		else
			ErrorMessage = ErrorMessage .."Date in consent_group is wrong or absent. \n"
			errorFlag = true
		end

		if Time then

			local CurrentDateCommand = assert( io.popen( "date -d @" .. tostring(CurrentUnixDateForPermissionConsent) .. "  +%H:%M:%S " , 'r'))
			TimeForPermissionConsentValue = CurrentDateCommand:read( '*l' )


			local CurrentDateCommand2 = assert( io.popen( "date -d @" .. tostring(tonumber(CurrentUnixDateForPermissionConsent)+1) .. "  +%H:%M:%S " , 'r'))
			TimeForPermissionConsentValuePlusSecond = CurrentDateCommand2:read( '*l' )


			local CurrentDateCommand3 = assert( io.popen( "date -d @" .. tostring(tonumber(CurrentUnixDateForPermissionConsent)-1) .. "  +%H:%M:%S " , 'r'))
			TimeForPermissionConsentValueMinusSecond = CurrentDateCommand3:read( '*l' )


			if Time == TimeForPermissionConsentValue or 
				Time == TimeForPermissionConsentValuePlusSecond or 
				Time == TimeForPermissionConsentValueMinusSecond then
			else
				ErrorMessage = ErrorMessage .. "Time in consent_group is not equal to time of group consent. Time from consent_group is " .. tostring(Time) .. ", time to check is " .. tostring(TimeForPermissionConsentValue) .. " +- 1 second. \n" 
				errorFlag = true
			end

		else
			print("Time in consent_group is wrong or absent")
		end


		if separatorFirst then
			if separatorFirst ~= "T" then
				ErrorMessage = ErrorMessage .. "Separator 'T' between date and time in consent_group is not equal to 'T'. Separator from consent_group is " .. tostring(separatorFirst) .. ". \n"
				errorFlag = true
			end
		else
			ErrorMessage = ErrorMessage .."Separator 'T' between date and time in consent_group is wrong or absent. \n"
			errorFlag = true
		end

		if separatorSecond then
			if separatorSecond ~= "Z" then
				ErrorMessage = ErrorMessage .. "Separator 'Z' after date and time in consent_group is not equal to 'Z'. Separator from consent_group is " .. tostring(separatorSecond) .. ". \n"
				errorFlag = true
			end
		else
			ErrorMessage = ErrorMessage .."Separator 'Z' after date and time in consent_group is wrong or absent. \n"
			errorFlag = true
		end

	else
		ErrorMessage = ErrorMessage .. "TimeStamp is absent or empty in consent_group. \n"
		errorFlag = true
	end

	if errorFlag == true then
		self:FailTestCase(ErrorMessage)
	end
end

--======================================================================================--
-- PM saves "time_stamp" values in sdl_snapshot.json in the format of "<yyyy-mm-dd>T<hh:mm:ss>Z"
--======================================================================================--
-- Precondition: Trigger the sdl_snapshot.json creation by receiving SDL.UpdateSDL request from HMI
function Test:Precondition_TriggerSDLSnapshotCreation_UpdateSDL()
	local RequestIdUpdateSDL = self.hmiConnection:SendRequest("SDL.UpdateSDL")

  	--hmi side: expect SDL.UpdateSDL response from HMI
  	EXPECT_HMIRESPONSE(RequestIdUpdateSDL,{result = {code = 0, method = "SDL.UpdateSDL", result = "UPDATE_NEEDED" }})

  	DelayedExp(2000)
end

-- PM saves "time_stamp" values in sdl_snapshot.json in the format of "<yyyy-mm-dd>T<hh:mm:ss>Z"
--======================================================================================--
function Test:TimeStamp_InSdlSnapshot()
	local errorFlag = false
	local ErrorMessage = ""
	local SDLsnapshot = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json"

	f = assert(io.open(SDLsnapshot, "r"))
	if f then
		fileContent = f:read("*all")

		local Timestamp_DeviceConsent = string.match(fileContent,"\"user_consent_records\":[%d%w%s%p]-\"device\":[%d%w%s%p]-\"time_stamp\"%s-:%s-\"([%d-:TZ]-)\"")


		local Timestamp_GroupConsent = string.match(fileContent,"\"user_consent_records\":[%d%w%s%p]-\"" .. tostring(config.application1.registerAppInterfaceParams.appID) .. "\":[%d%w%s%p]-\"time_stamp\"%s-:%s-\"([%d-:TZ]-)\"")

		if Timestamp_DeviceConsent then
			if TimeStamp_InDeviceConsentGroupTableValue then
				if TimeStamp_InDeviceConsentGroupTableValue ~= Timestamp_DeviceConsent then
					ErrorMessage = ErrorMessage .. " Timestamp of device consent is not match with time in local PT. Expected value is '" .. tostring(TimeStamp_InDeviceConsentGroupTableValue) .. "'. Actual result is '" .. tostring(Timestamp_DeviceConsent) .. "' \n"
					errorFlag = true 
				end
			else
				ErrorMessage = ErrorMessage .. " Timestamp of device consent is not checked in snapshot because value from local PT is not received. Value in snapshot is " .. tostring(Timestamp_DeviceConsent) .. " \n"
				errorFlag = true 
			end
		else
			ErrorMessage = ErrorMessage .. " Timestamp of group consent is not found in snapshot \n"
			errorFlag = true
		end

		if Timestamp_GroupConsent then
			if TimeStamp_InConsentGroupTableValue then
				if TimeStamp_InConsentGroupTableValue ~= Timestamp_GroupConsent then
					ErrorMessage = ErrorMessage .. " Timestamp of group consent is not match with time in local PT. Expected value is '" .. tostring(TimeStamp_InConsentGroupTableValue) .. "'. Actual result is '" .. tostring(Timestamp_GroupConsent) .. "' \n"
					errorFlag = true 
				end
			else
				ErrorMessage = ErrorMessage .. " Timestamp of group consent is not checked in snapshot because value from local PT is not received. Value in snapshot is " .. tostring(Timestamp_GroupConsent) ..". \n"
				errorFlag = true 
			end
		else
			ErrorMessage = ErrorMessage .. " Timestamp of group consent is not found in snapshot \n"
			errorFlag = true
		end

		if errorFlag == true then
			self:FailTestCase(ErrorMessage)
		end

		f:close()
	else 
		commonFunctions:userPrint(31, " Snapshot is not opened successfully. Please check path to sdl_snapshot.json. Expected path is '" .. SDLsnapshot .."'")
	end
end
