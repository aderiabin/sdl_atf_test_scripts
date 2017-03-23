---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [RPCs] SDL must send GENERIC_ERROR to app in case HMI does NOT respond during <DefaultTimeout>+<RPCs_internal_timeout> for all RPCs with own timer
-- Requirement ID: APPLINK-27496
--
-- Description:
-- 1. Mobile, SDL, HMI started, App activated , consent given
-- 2. Send RPC "Alert" with mandatory parameters
-- 3. No reply from HMI sent during default timeout
--
-- Expected result:
-- Expected SDL behaviour: SDL  sends to mobile the RESPONSE with the following parameters :
-- { success = false, resultCode = "GENERIC_ERROR" })
---------------------------------------------------------------------------------------------


--[[ General Settings for configuration ]]
Test = require('modules/connecttest')
local commonSteps = require('user_modules/shared_testcases_genivi/commonSteps')

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2


--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()

--[[ Preconditions ]]
function Test:Preconditions_ActivateApp()
  commonSteps:ActivateAppInSpecificLevel(self, self.applications["Test Application"])
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
end

--[[ Test ]]
function Test:Alert_NoReplyFromHMI_Expect_GENERIC_ERROR()
  --mobile side: Alert request
  local CorIdAlert = self.mobileSession:SendRPC("Alert", {alertText1 = "alertText1"})
  --hmi side: UI.Alert request
  EXPECT_HMICALL("UI.Alert", { alertStrings = {{fieldName = "alertText1", fieldText = "alertText1" }} })
  -- Expect SDL send the following response to mobile if during timeout  no response from HMI received
  EXPECT_RESPONSE(CorIdAlert, { success = false, resultCode = "GENERIC_ERROR" })
end

--[[ Postconditions ]]
function Test.Postcondition_SDLStop()
  StopSDL()
end

