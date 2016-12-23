--------------------------------------------------------------------------------
-- This scripts tests functions in common_multi_mobile_connection.lua
-- Author: Ta Thanh Dong
-- ATF version: 2.2
--------------------------------------------------------------------------------
---------------------Required Shared Libraries----------------------------------
Test = require('user_modules/connect_without_mobile_connection')
require('cardinalities')
local mobile_session = require('mobile_session')
require('user_modules/AppTypes')
local common_steps = require('user_modules/common_multi_mobile_connections')

local function AddSessionAndRegisterApp(scenario_name, mobile_connection_name, mobile_session_name, register_app_params)
  local app_name = register_app_params.appName
  common_steps:AddMobileSession(scenario_name .. "_AddMobileSession_" .. mobile_session_name, mobile_connection_name, mobile_session_name)
  common_steps:RegisterApplication(scenario_name .. "_RegisterApplication", mobile_session_name, register_app_params)
end

local function ChangeAppToDifferentHmiLevels(scenario_name, app_name)
  common_steps:ActivateApplication(scenario_name .. "_FULL", app_name)
  common_steps:ChangeHMIToLimited(scenario_name .. "_LIMITED", app_name)
  common_steps:ChangeHmiLevelToNone(scenario_name .. "_NONE", app_name)
end

local function UnregisterAppAndCloseSession(scenario_name, app_name, mobile_session_name)
  common_steps:UnregisterApp(scenario_name .. "_UnregisterApp", app_name)
  common_steps:CloseMobileSession(scenario_name .. "_CloseMobileSession", mobile_session_name)
end

local function RegisterAppOnNewMobileDevice(scenario_name, mobile_connection_name, mobile_session_name, register_app_params)
  local app_name = register_app_params.appName
  common_steps:AddMobileConnection(scenario_name .. "_AddMobileConnection", mobile_connection_name)
  AddSessionAndRegisterApp(scenario_name, mobile_connection_name, mobile_session_name, register_app_params)
  ChangeAppToDifferentHmiLevels(scenario_name, app_name)
  UnregisterAppAndCloseSession(scenario_name, app_name, mobile_session_name)
end

-- SCENARIO #1: ADD NEW CONNECTIONS, SESSION AND REGISTER APP. THEN CHANGE APP TO DIFFERENT HMI LEVEL AND UNREGISTER, CLOSE SESSION
-- 1. Add mobile connection to SDL
-- 2. Add mobile session on the mobile connection 
-- 3. Register app
-- 4. Activate app
-- 5. SPECIFIC STEPS FOR TEST CASES RELATED TO FULL HMI LEVEL
-- 6. Change app to LIMITED HMI level
-- 7. SPECIFIC STEPS FOR TEST CASES RELATED TO LIMITED HMI LEVEL
-- 8. Change app level to NONE
-- 9. SPECIFIC STEPS FOR TEST CASES RELATED TO NONE HMI LEVEL
-- 10. Activate app again
-- 11. Unregister app
-- 12. Close session
RegisterAppOnNewMobileDevice("Scenario1", "mobileConnection1", "mobileSession1", config.application1.registerAppInterfaceParams)

-- SCENARIO #2: ADD NEW SESSION AND REGISTER APPLICATIONS AGAIN
-- 1. Add the mobile session again on the mobile connection 
-- 2. Register app
-- 3. Activate app
AddSessionAndRegisterApp("Scenario2", "mobileConnection1", "mobileSession1", config.application1.registerAppInterfaceParams)
ChangeAppToDifferentHmiLevels("Scenario2", config.application1.registerAppInterfaceParams.appName)

-- SCENARIO #3: ADD THE SECOND SESSION AND REGISTER APPLICATIONS
-- 1. Add the second mobile session on the mobile connection 
-- 2. Register app
-- 3. Change HMI level to FULL
-- 4. Change app to LIMITED HMI level
-- 5. Change app level to NONE
AddSessionAndRegisterApp("Scenario3", "mobileConnection1", "mobileSession2", config.application2.registerAppInterfaceParams)
ChangeAppToDifferentHmiLevels("Scenario3", config.application2.registerAppInterfaceParams.appName)

-- SCENARIO #4: CONNECT 3 MOBILE DEVICES, ADD SESSION AND REGISTER APP,..
-- 1. Add mobile connection to SDL
-- 2. Add mobile session on the mobile connection 
-- 3. Register app
-- 4. Activate app
-- 5. Change app to LIMITED HMI level
-- 6. Change app level to NONE
-- 7. Unregister app
-- 8. Close session
RegisterAppOnNewMobileDevice("Scenario4_Second_Device", "mobileConnection2", "mobileSession3", config.application3.registerAppInterfaceParams)
RegisterAppOnNewMobileDevice("Scenario4_Third_Device", "mobileConnection3", "mobileSession4", config.application4.registerAppInterfaceParams)
RegisterAppOnNewMobileDevice("Scenario4_Fourth_Device", "mobileConnection4", "mobileSession5", config.application5.registerAppInterfaceParams)
