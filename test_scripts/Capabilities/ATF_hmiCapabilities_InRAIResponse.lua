-- Preconditions before ATF start
--------------------------------------------------------------------------------
  -- copy initial connecttest.lua to connecttest_hmiCapabilities_value
  os.execute(  'cp ./modules/connecttest.lua  ./user_modules/connecttest_hmiCapabilities_value.lua')

  f = assert(io.open('./user_modules/connecttest_hmiCapabilities_value.lua', "r"))

  fileContent = f:read("*all")
  f:close()

  -- update function,  softButtonCapabilities struct
  local pattern1 = "function .?module%.?:.?initHMI%_onReady%(.?%)"
  local ResultPattern1 = fileContent:match(pattern1)

  if ResultPattern1 == nil then 
    print(" \27[31m initHMI_onReady function is not found in /user_modules/connecttest_hmiCapabilities_value.lua \27[0m ")
  else
    fileContent  =  string.gsub(fileContent, pattern1, "function module:initHMI_onReady(hmiCapabilitiesValue)")
  end

  -- update hmiCapabilities in UI.GetCapabilities
local pattern2 = 'ExpectRequest%s-%(%s-"%s-UI.GetCapabilities%s-".-%{.-%}%s-%)'
local pattern2Result = fileContent:match(pattern2)
  if pattern2Result == nil then 
    print(" \27[31m function ExpectRequest UI.GetCapabilities call is not found in /user_modules/connecttest_hmiCapabilities_value.lua \27[0m ")
  else
    local pattern2_1 = 'hmiCapabilities%s-=%s-%{.-%}'
    local pattern2_1Result = pattern2Result:match(pattern2_1)
    if pattern2_1Result == nil then 
        print(" \27[33m hmiCapabilitiesis not found in UI.GetCapabilities response, will be added \27[0m ")
        local pattern2_1_1 = 'ExpectRequest%s-%(%s-"%s-UI.GetCapabilities%s-".-%{'
    	local pattern2_1_1Result = pattern2Result:match(pattern2_1_1)
    		if pattern2_1_1Result == nil then 
		    	print(" \27[31m UI.GetCapabilitie is not found in /user_modules/connecttest_hmiCapabilities_value.lua \27[0m ")
		  	else
		    	pattern2Result  =  string.gsub(pattern2Result, pattern2_1_1, pattern2_1_1Result .. "\n hmiCapabilities = hmiCapabilitiesValue,")
		    	fileContent = string.gsub(fileContent, pattern2,pattern2Result)
		  	end
    else
      pattern2Result  =  string.gsub(pattern2Result, pattern2_1, 'hmiCapabilities = hmiCapabilitiesValue,')
      fileContent = string.gsub(fileContent, pattern2,pattern2Result)
    end
  end

f = assert(io.open('./user_modules/connecttest_hmiCapabilities_value.lua', "w+"))
f:write(fileContent)
f:close()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

Test = require('user_modules/connecttest_hmiCapabilities_value')
require('cardinalities')
local mobile_session = require('mobile_session')

require('user_modules/AppTypes')

local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

--ToDo: shall be removed when APPLINK-16610 is fixed
config.defaultProtocolVersion = 2

local function OpenSessionRegisterApp(self, hmiCapabilitiesValue)

	self.mobileSession = mobile_session.MobileSession(
      self,
      self.mobileConnection)


	self.mobileSession:StartService(7)
    :Do(function()
      local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

  	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", 
				      {
				        application = 
				        {
				          appName = config.application1.registerAppInterfaceParams.appName
				        }
				      })
      	:Do(function(_,data)
        	local appId = data.params.application.appID
        	self.appId = appId
        end)

  	self.mobileSession:ExpectResponse(CorIdRAI, {
      	success = true,
      	resultCode = "SUCCESS",
        hmiCapabilities = hmiCapabilitiesValue
  	})
      	:Timeout(2000)
      	:ValidIf(function(_,data)

      		local n = 0
      		local m = 0
      		if 
      			hmiCapabilitiesValue.navigation == true or
      			hmiCapabilitiesValue.navigation == false then
      			n = n+1
      		end

      		if 
      			hmiCapabilitiesValue.phoneCall == true or
      			hmiCapabilitiesValue.phoneCall == false then
      			n = n+1
      		end

      		if 
      			data.payload.hmiCapabilities.navigation == true or
      			data.payload.hmiCapabilities.navigation == false then
      			m = m+1
      		end

      		if 
      			data.payload.hmiCapabilities.phoneCall == true or
      			data.payload.hmiCapabilities.phoneCall == false then
      			m = m+1
      		end

      		if 
      			m ~= n then

      			commonFunctions:userPrint(31, "Expected number of params in hmiCapabilities is '" .. tostring(n) .. "', actual number is '" .. tostring(m) .. "'" )
      			return false
      		else
      			return true
      		end
      	end)

    self.mobileSession:ExpectNotification("OnHMIStatus", 
        { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
      	:Timeout(2000)

  	commonTestCases:DelayedExp(1000)

    end)
end

local function RestartSDL(prefix, hmiCapabilitiesValue, hmiCapabilitiesValueRegister, UpdateHmiCapabilitiesJson, StringToReplace)

	Test["StopSDL_" .. tostring(prefix) ] = function(self)
		commonFunctions:userPrint(35, "\n================= Precondition ==================")
		StopSDL()

		commonTestCases:DelayedExp(1000)
	end

	if UpdateHmiCapabilitiesJson then
		Test["UpdateHmiCapabilitiesJson_" .. tostring(prefix) ] = function(self)

		local HmiCapabilities = config.pathToSDL .. "hmi_capabilities.json"

		f = assert(io.open(HmiCapabilities, "r"))
			if f then
				fileContent = f:read("*all")

				if StringToReplace == "" then
					fileContentFind = fileContent:match("%s-\".?hmiCapabilities.?\"%s-:%s-{[%w%d,:\"%s]-},?")
				else
					fileContentFind = fileContent:match("\".?hmiCapabilities.?\"%s-:%s-{[%w%d,:\"%s]-}")
				end

				if fileContentFind then
					fileContentUpdated  =  string.gsub(fileContent, fileContentFind, StringToReplace)
					f = assert(io.open(HmiCapabilities, "w"))
					f:write(fileContentUpdated)
				elseif StringToReplace == "" then
					commonFunctions:userPrint(33, " hmiCapabilities is absent in hmiCapabilities.json  ")
				elseif 
					StringToReplace ~= "" then

					fileContentFindPlaceToInsert = fileContent:match("%p?\".?UI.?\"%s-:%s-{%s-")

					fileContentUpdated  =  string.gsub(fileContent, fileContentFindPlaceToInsert, fileContentFindPlaceToInsert .. tostring("\n\t\t" .. StringToReplace .. ","))

					f = assert(io.open(HmiCapabilities, "w"))
					f:write(fileContentUpdated)


				else 
					commonFunctions:userPrint(31, "Finding of 'ResumptionDelayBeforeIgn = value' is failed. Expect string finding and replacing of value to true")
				end
				f:close()
			end

		end
	end

	Test["StartSDL_" .. tostring(prefix) ] = function(self)
		StartSDL(config.pathToSDL, config.ExitOnCrash)
	end

	Test["InitHMI_" .. tostring(prefix) ] = function(self)
		self:initHMI()
	end

	Test["InitHMI_onReady_" .. tostring(prefix) ] = function(self)
		self:initHMI_onReady(hmiCapabilitiesValue)
	end

	Test["ConnectMobile_" .. tostring(prefix) ] = function(self)
  		self:connectMobile()
	end

	Test["RegisterApp_" .. tostring(prefix) ] = function(self)
		commonFunctions:userPrint(34, "=================== Test Case ===================")	
  		OpenSessionRegisterApp(self, hmiCapabilitiesValueRegister)
	end
end

-- Precondition: removing user_modules/connecttest_hmiCapabilities_value.lua
function Test:Precondition_remove_user_connecttest()
  os.execute( "rm -f ./user_modules/connecttest_hmiCapabilities_value.lua" )
end

--//////////////////////////////////////////////////////////////////////////////////////--
--Set #1: HMI sends UI.GetCapabilities without hmiCapabilities parameter
--//////////////////////////////////////////////////////////////////////////////////////--

	--======================================================================================--
	-- navigation = false, phoneCall = false in RAI response in case hmiCapabilities param is absent in UI.GetCapabilities response and in hmiCapabilities.json file
	--======================================================================================--
	RestartSDL("hmiCapabilities_absentInUIGetCapRespInHmiCapFile", _, { navigation = false, phoneCall = false }, true, "")

-- TODO: Test cases are related to not implemented CRQ APPLINK-21419. Uncomment test cases after implementation will be ready.
	-- --======================================================================================
	-- -- navigation = true, phoneCall = false in RAI response in case hmiCapabilities param is absent in UI.GetCapabilities response and value in hmiCapabilities.json file is navigation = true, phoneCall = false
	-- --======================================================================================--
	-- RestartSDL("hmiCapabilities_absentInUIGetCapResp_InHmiCapFileNavTruePhoneFalse", _, { navigation = true, phoneCall = false }, true, "\"hmiCapabilities\" : { \"navigation\" : true, \"phoneCall\" : false }")

	-- --======================================================================================
	-- -- navigation = false, phoneCall = true in RAI response in case hmiCapabilities param is absent in UI.GetCapabilities response and value in hmiCapabilities.json file is navigation = false, phoneCall = true
	-- --======================================================================================--
	-- RestartSDL("hmiCapabilities_absentInUIGetCapResp_InHmiCapFileNavFalsePhoneTrue", _, { navigation = false, phoneCall = true }, true, "\"hmiCapabilities\" : { \"navigation\" : false, \"phoneCall\" : true }")

	-- --======================================================================================
	-- -- navigation = true, phoneCall = true in RAI response in case hmiCapabilities param is absent in UI.GetCapabilities response and value in hmiCapabilities.json file is navigation = true, phoneCall = true
	-- --======================================================================================--
	-- RestartSDL("hmiCapabilities_absentInUIGetCapResp_InHmiCapFileNavTruePhoneTrue", _, { navigation = true, phoneCall = true }, true, "\"hmiCapabilities\" : { \"navigation\" : true, \"phoneCall\" : true }")

	-- --======================================================================================
	-- -- navigation = false, phoneCall = false in RAI response in case hmiCapabilities param is absent in UI.GetCapabilities response and value in hmiCapabilities.json file is navigation = false, phoneCall = false
	-- --======================================================================================--
	-- RestartSDL("hmiCapabilities_absentInUIGetCapResp_InHmiCapFileNavFalsePhoneFalse", _, { navigation = false, phoneCall = false }, true, "\"hmiCapabilities\" : { \"navigation\" : false, \"phoneCall\" : false }")

	--======================================================================================
	-- navigation = false, phoneCall = false in RAI response in case hmiCapabilities value in UI.GetCapabilities response is empty
	--======================================================================================--
	RestartSDL("hmiCapabilities_InUIGetCapRespEmpty", { }, { navigation = false, phoneCall = false })

--//////////////////////////////////////////////////////////////////////////////////////--
--Set #2: HMI sends UI.GetCapabilities with hmiCapabilities parameter
--//////////////////////////////////////////////////////////////////////////////////////--

	--======================================================================================
	-- navigation = false, phoneCall = false in RAI response in case hmiCapabilities value in UI.GetCapabilities response is navigation = false, phoneCall = false and value in hmiCapabilities.json file is navigation = true, phoneCall = true
	--======================================================================================--
	RestartSDL("hmiCapabilities_InUIGetCapRespBothFalse_InHmiCapFileNavTruePhoneTrue", { navigation = false, phoneCall = false }, { navigation = false, phoneCall = false }, true, "\"hmiCapabilities\" : { \"navigation\" : true, \"phoneCall\" : true }")

	--======================================================================================
	-- navigation = true, phoneCall = true in RAI response in case hmiCapabilities value in UI.GetCapabilities response is navigation = true, phoneCall = true 
	--======================================================================================--
	RestartSDL("hmiCapabilities_InUIGetCapRespBothTrue", { navigation = true, phoneCall = true }, { navigation = true, phoneCall = true })

	--======================================================================================
	-- navigation = false, phoneCall = true in RAI response in case hmiCapabilities value in UI.GetCapabilities response is navigation = false, phoneCall = true 
	--======================================================================================--
	RestartSDL("hmiCapabilities_InUIGetCapRespNavFalsePhoneTrue", { navigation = false, phoneCall = true }, { navigation = false, phoneCall = true })

	--======================================================================================
	-- navigation = true, phoneCall = false in RAI response in case hmiCapabilities value in UI.GetCapabilities response is navigation = true, phoneCall = false 
	--======================================================================================--
	RestartSDL("hmiCapabilities_InUIGetCapRespNavTruePhoneFalse", { navigation = true, phoneCall = false }, { navigation = true, phoneCall = false })


--//////////////////////////////////////////////////////////////////////////////////////--
--Set #4: HMI sends UI.GetCapabilities with hmiCapabilities parameter and with fake parameters
--//////////////////////////////////////////////////////////////////////////////////////--

	--======================================================================================
	-- navigation = false, phoneCall = false in RAI response in case hmiCapabilities values in UI.GetCapabilities response are fake from API
	--======================================================================================--
	RestartSDL("hmiCapabilities_InUIGetCapRespOnlyFakeParamsFromAPI", { upDownAvailable = true,
	      imageSupported = true }, { navigation = false, phoneCall = false })

	--======================================================================================
	-- navigation = false, phoneCall = false in RAI response in case hmiCapabilities values in UI.GetCapabilities response are fake not from API
	--======================================================================================--
	RestartSDL("hmiCapabilities_InUIGetCapRespOnlyFakeParamsNotFromAPI", { voltage = true }, { navigation = false, phoneCall = false })

	--======================================================================================
	-- navigation = true, phoneCall = true in RAI response in case hmiCapabilities in UI.GetCapabilities response contains fake parameters from APi except valid ones
	--======================================================================================--
	RestartSDL("hmiCapabilities_InUIGetCapRespWithFakeParamsFromAPI", { upDownAvailable = false, navigation = true, phoneCall = true, imageSupported = false }, { navigation = true, phoneCall = true })

	--======================================================================================
	-- navigation = true, phoneCall = true in RAI response in case hmiCapabilities in UI.GetCapabilities response contains fake parameters not from APi except valid ones
	--======================================================================================--
	RestartSDL("hmiCapabilities_InUIGetCapRespWithFakeParamsNotFromAPI", { navigation = true, phoneCall = true, voltage = false }, { navigation = true, phoneCall = true })

--//////////////////////////////////////////////////////////////////////////////////////--
--Set #5: HMI sends UI.GetCapabilities with only navigation or phoneCall in hmiCapabilities
--//////////////////////////////////////////////////////////////////////////////////////--

	--======================================================================================
	-- navigation = false in RAI response in case hmiCapabilities value in UI.GetCapabilities is navigation = false
	--======================================================================================--
	RestartSDL("hmiCapabilities_InUIGetCapRespOnlyNavFalse", { navigation = false }, { navigation = false })

	--======================================================================================
	-- navigation = true in RAI response in case hmiCapabilities value in UI.GetCapabilities is navigation = true
	--======================================================================================--
	RestartSDL("hmiCapabilities_InUIGetCapRespOnlyNavTrue", { navigation = true }, { navigation = true })

	--======================================================================================
	-- phoneCall = false in RAI response in case hmiCapabilities value in UI.GetCapabilities is phoneCall = false
	--======================================================================================--
	RestartSDL("hmiCapabilities_InUIGetCapRespOnlyPhoneFalse", { phoneCall = false }, { phoneCall = false })

	--======================================================================================
	-- phoneCall = true in RAI response in case hmiCapabilities value in UI.GetCapabilities is phoneCall = true
	--======================================================================================--
	RestartSDL("hmiCapabilities_InUIGetCapRespOnlyPhoneTrue", { phoneCall = true }, { phoneCall = true })

--//////////////////////////////////////////////////////////////////////////////////////--
--Set #6: HMI sends UI.GetCapabilities with invalid navigation, phoneCall values in hmiCapabilities
--//////////////////////////////////////////////////////////////////////////////////////--

-- TODO: Test cases are related to not implemented CRQ APPLINK-21419. Uncomment precondition and update expectations from { navigation = false, phoneCall = false } to { navigation = true, phoneCall = true } in test cases below after implementation will be ready 
	--Precondition for test set
	-- function Test:Precondition_UpdateHmiCapabilitiesJson_navTrue_PhoneTrue()

	-- 	local HmiCapabilities = config.pathToSDL .. "hmi_capabilities.json"

	-- 	f = assert(io.open(HmiCapabilities, "r"))
	-- 		if f then
	-- 			fileContent = f:read("*all")

	-- 			local StringToReplace = "\"hmiCapabilities\" : { \"navigation\" : true, \"phoneCall\" : true }"

	-- 			if fileContentFind then
	-- 				fileContentUpdated  =  string.gsub(fileContent, fileContentFind, StringToReplace)
	-- 				f = assert(io.open(HmiCapabilities, "w"))
	-- 				f:write(fileContentUpdated)
	-- 			elseif StringToReplace == "" then
	-- 				commonFunctions:userPrint(33, " hmiCapabilities is absent in hmiCapabilities.json  ")
	-- 			elseif 
	-- 				StringToReplace ~= "" then

	-- 				fileContentFindPlaceToInsert = fileContent:match("%p?\".?UI.?\"%s-:%s-{%s-")

	-- 				fileContentUpdated  =  string.gsub(fileContent, fileContentFindPlaceToInsert, fileContentFindPlaceToInsert .. tostring("\n\t\t" .. StringToReplace .. ","))

	-- 				f = assert(io.open(HmiCapabilities, "w"))
	-- 				f:write(fileContentUpdated)


	-- 			else 
	-- 				commonFunctions:userPrint(31, "Finding of 'ResumptionDelayBeforeIgn = value' is failed. Expect string finding and replacing of value to true")
	-- 			end
	-- 			f:close()
	-- 		end

	-- 	end

	--======================================================================================
	-- navigation = false, phoneCall = false in RAI response in case hmiCapabilities values in UI.GetCapabilities response navigation is array { false }, phoneCall = false
	--======================================================================================--
	RestartSDL("hmiCapabilities_InUIGetCapRespNavIsArrayPhoneFalse", { navigation = {false}, phoneCall = false }, { navigation = false, phoneCall = false })

	--======================================================================================
	-- navigation = false, phoneCall = false in RAI response in case hmiCapabilities values in UI.GetCapabilities response navigation is array { false }, phoneCall = true
	--======================================================================================--
	RestartSDL("hmiCapabilities_InUIGetCapRespNavIsArrayPhoneTrue", { navigation = {false}, phoneCall = true }, { navigation = false, phoneCall = false })

	--======================================================================================
	-- navigation = false, phoneCall = false in RAI response in case hmiCapabilities values in UI.GetCapabilities response navigation = false, phoneCall is array { false }
	--======================================================================================--
	RestartSDL("hmiCapabilities_InUIGetCapRespPhoneIsArrayNavFalse", { navigation = false, phoneCall = {true} }, { navigation = false, phoneCall = false })

	--======================================================================================
	-- navigation = false, phoneCall = false in RAI response in case hmiCapabilities values in UI.GetCapabilities response navigation = true, phoneCall is array { false }
	--======================================================================================--
	RestartSDL("hmiCapabilities_InUIGetCapRespPhoneIsArrayNavTrue", { navigation = true, phoneCall = {true} }, { navigation = false, phoneCall = false })

	--======================================================================================
	-- navigation = false, phoneCall = false in RAI response in case hmiCapabilities values in UI.GetCapabilities are navigation = true, phoneCall = integer value
	--======================================================================================--
	RestartSDL("hmiCapabilities_InUIGetCapRespOnlyPhoneInteger", {navigation = true, phoneCall = 12 }, { navigation = false, phoneCall = false })

	--======================================================================================
	-- navigation = false, phoneCall = false in RAI response in case hmiCapabilities values in UI.GetCapabilities are navigation = integer value, phoneCall = true
	--======================================================================================--
	RestartSDL("hmiCapabilities_InUIGetCapRespOnlyNavInteger", {navigation = 12, phoneCall = true }, { navigation = false, phoneCall = false })

	--======================================================================================
	-- navigation = false, phoneCall = false in RAI response in case hmiCapabilities values in UI.GetCapabilities are navigation = true, phoneCall = string value
	--======================================================================================--
	RestartSDL("hmiCapabilities_InUIGetCapRespOnlyPhoneString", {navigation = true, phoneCall = "true" }, { navigation = false, phoneCall = false })

	--======================================================================================
	-- navigation = false, phoneCall = false in RAI response in case hmiCapabilities values in UI.GetCapabilities are navigation = string value, phoneCall = true
	--======================================================================================--
	RestartSDL("hmiCapabilities_InUIGetCapRespOnlyNavString", {navigation = "true", phoneCall = true }, { navigation = false, phoneCall = false })

	--======================================================================================
	-- navigation = false, phoneCall = false in RAI response in case hmiCapabilities values in UI.GetCapabilities are navigation = true, phoneCall = struct value
	--======================================================================================--
	RestartSDL("hmiCapabilities_InUIGetCapRespOnlyPhoneStruct", {navigation = true, phoneCall = { value = true } }, { navigation = false, phoneCall = false })

	--======================================================================================
	-- navigation = false, phoneCall = false in RAI response in case hmiCapabilities values in UI.GetCapabilities are navigation = struct value, phoneCall = true
	--======================================================================================--
	RestartSDL("hmiCapabilities_InUIGetCapRespOnlyNavStruct", {navigation = { value = true }, phoneCall = true }, { navigation = false, phoneCall = false })
