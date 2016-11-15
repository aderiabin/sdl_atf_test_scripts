--------------------------------------------------------------------------------
-- This script covers requirement APPLINK-16182 [HMILevel resumption] [Ford-Specific]: Media app (navi, voice-com) is registered during active VR session
--------------------------------------------------------------------------------
--[[In case the media app (or navi, voice-com) satisfies the conditions of successful HMILevel resumption (unexpected disconnect, next ignition cycle, short ignition cycle, low voltage) and SDL receives VR.Started notification
SDL must:
postpone resuming HMILevel of media app till VR.Stopped notification
assign <default_HMI_level> to this media app (meaning: by sending OnHMIStatus notification to mobile app per current req-s)
resume HMILevel after event ends (SDL receives VR.Stopped notification)
]]
-- Author: Truong Thi Kim Hanh
-- ATF version: 2.2
---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local common_functions = require('user_modules/shared_testcases/commonFunctions')
local common_functions_for_CRQ19998 = require('user_modules/commonFunctionsForCRQ19998')
local common_steps = require('user_modules/common_multi_mobile_connections')
Test = require('user_modules/connect_without_mobile_connection')
require('user_modules/AppTypes')
---------------------------------------------------------------------------------------------
------------------------------------ Common Variables ---------------------------------------
---------------------------------------------------------------------------------------------
local events = {
  start = {event_name = "VR.Started", event_params = {}},
  stop = {event_name = "VR.Stopped", event_params = {}}
}
---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
-- Use common precondition in commonFunctionsForCRQ19998.lua
---------------------------------------------------------------------------------------------
-----------------------------------------------Body------------------------------------------
---------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Case 1-14: HMI Level resumption for NAVIGATION/MEDIA/COMMUNICATION/MEDIA app is postponed in case IGNITION cycle and VR is active before/after app is connected
-- NO.AppType HMIStatus VR.Start before registering app (true-before; false-after)
----------------------------------------------------------------------------------------------------------------
-- 1 NAVIGATION FULL, AUDIBLE true
-- 2 MEDIA FULL, AUDIBLE true
-- 3 COMMUNICATION FULL, AUDIBLE true
-- 4 NON MEDIA FULL, NOT_AUDIBLE true
----------------------------------------------------------------------------------------------------------------
-- 5 NAVIGATION LIMITED, AUDIBLE true
-- 6 MEDIA LIMITED, AUDIBLE true
-- 7 COMMUNICATION LIMITED, AUDIBLE true
----------------------------------------------------------------------------------------------------------------
-- 8 NAVIGATION FULL, AUDIBLE false
-- 9 MEDIA FULL, AUDIBLE false
-- 10 COMMUNICATION FULL, AUDIBLE false
-- 11 NON MEDIA FULL, NOT_AUDIBLE false
----------------------------------------------------------------------------------------------------------------
-- 12 NAVIGATION LIMITED, AUDIBLE false
-- 13 MEDIA LIMITED, AUDIBLE false
-- 14 COMMUNICATION LIMITED, AUDIBLE false
--------------------------------------------------------------------------------------------------------------------------------------------------------------
local tc_number = 1
for x = 1, #START_EVENT_BEFORE_AFTER_REGISTER_APP do
  for i = 1, #RESUMED_HMI_LEVEL do
    for j = 1, #apps do
      if (RESUMED_HMI_LEVEL[i] ~= "LIMITED") or (apps[j].appName ~= "NON_MEDIA") then
        common_functions:newTestCasesGroup("TC_" .. tostring(tc_number) .. " \"" .. RESUMED_HMI_LEVEL[i] .. "\" resumption for \"" .. apps[j].appName .. "\" app is postponed in case IGNITION cycle and VR is active " .. (START_EVENT_BEFORE_AFTER_REGISTER_APP[x] == true and 'BEFORE' or 'AFTER') .. " app is connected")
        common_functions_for_CRQ19998:CheckSingleAppIsResumed("TC_" .. tostring(tc_number), RESUMED_HMI_LEVEL[i], START_EVENT_BEFORE_AFTER_REGISTER_APP[x], apps[j], events, true)
        tc_number = tc_number + 1
      end
    end
  end
end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Case 15-16: HMI Level resumption for multiple apps(FULL/LIMITED/LIMITED/BACKGROUND) are postponed in case IGNITION cycle and VR is active before/after apps are connected
-- NO. AppType HMIStatus VR.Start before registering app (true-before; false-after)
----------------------------------------------------------------------------------------------------------------
-- 15 NAVIGATION FULL, AUDIBLE true
-- MEDIA LIMITED, AUDIBLE true
-- COMMUNICATION LIMITED, AUDIBLE true
-- NON MEDIA BACKGROUND, NOT_AUDIBLE true
----------------------------------------------------------------------------------------------------------------
-- 16 NAVIGATION FULL, AUDIBLE false
-- MEDIA LIMITED, AUDIBLE false
-- COMMUNICATION LIMITED, AUDIBLE false
-- NAVIGATION BACKGROUND, NOT_AUDIBLE false
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
for x = 1, #START_EVENT_BEFORE_AFTER_REGISTER_APP do
  common_functions:newTestCasesGroup("Multiple apps (Full-Limited-Limited-Background) are postponed in case IGNITION cycle and VR is active " .. (START_EVENT_BEFORE_AFTER_REGISTER_APP[x] == true and 'BEFORE' or 'AFTER') .. " apps are connected")
  common_functions_for_CRQ19998:CheckMultipleAppsAreResumed("TC_" .. tostring(tc_number), expected_hmi_status_3apps, START_EVENT_BEFORE_AFTER_REGISTER_APP[x], true, events, true)
  tc_number = tc_number + 1
end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Case 17-18: HMI Level resumption for multiple apps(FULL/LIMITED/LIMITED/LIMITED) are postponed in case IGNITION cycle and VR is active before/after apps are connected
-- NO. AppType HMIStatus VR.Start before registering app (true-before; false-after)
----------------------------------------------------------------------------------------------------------------
-- 17 NAVIGATION FULL, NOT_AUDIBLE true
-- MEDIA LIMITED, AUDIBLE true
-- COMMUNICATION LIMITED, AUDIBLE true
-- NON MEDIA LIMITED, AUDIBLE true
----------------------------------------------------------------------------------------------------------------
-- 18 NAVIGATION FULL, NOT_AUDIBLE false
-- MEDIA LIMITED, AUDIBLE false
-- COMMUNICATION LIMITED, AUDIBLE false
-- NAVIGATION LIMITED, AUDIBLE false
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
for x = 1, #START_EVENT_BEFORE_AFTER_REGISTER_APP do
  common_functions:newTestCasesGroup("Multiple apps (Full-Limited-Limited-Limited) are postponed in case IGNITION cycle and VR is active " .. (START_EVENT_BEFORE_AFTER_REGISTER_APP[x] == true and 'BEFORE' or 'AFTER') .. " apps are connected")
  common_functions_for_CRQ19998:CheckMultipleAppsAreResumed("TC_" .. tostring(tc_number), expected_hmi_status_4apps, START_EVENT_BEFORE_AFTER_REGISTER_APP[x], false, events, true)
  tc_number = tc_number + 1
end
---------------------------------------------------------------------------------------------
-------------------------------------------Postcondition-------------------------------------
---------------------------------------------------------------------------------------------
common_steps:RestoreIniFile("Restore_Ini_file")
-- Remove ./user_modules/connecttest_resumption.lua file that was created at the beginning of script.
os.execute( "rm -f ./user_modules/connecttest_resumption.lua" )
