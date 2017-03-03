---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] "usage_and_error_counts" and "count_of_rpcs_sent_in_hmi_none" update
--
-- Description:
-- In case an application sends RPC in HMILevel NONE which is restricted and declined by Policies,
-- Policy Manager must increment "count_of_rpcs_sent_in_hmi_none" section value of
-- Local Policy Table for the corresponding application. For more details refer APPLINK-23472 and APPLINK-16145

-- Pre-conditions:
-- a. SDL and HMI are started
-- b. app successfully registers and running in NONE on SDL

-- Steps:
-- 1. app -> SDL: RPC

-- Expected:
-- 2. PoliciesManager increment "count_of_rpcs_sent_in_hmi_none" at LocalPT for this app

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases_genivi/commonSteps')
local commonFunctions = require('user_modules/shared_testcases_genivi/commonFunctions')

--[[ General Precondition before ATF start ]]
commonFunctions:cleanup_environment()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('user_modules/shared_testcases_genivi/connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Local Variables ]]
local count_before = {}
local count_after = {}

--[[ Test ]] 
function Test:GetDB_count_of_rpcs_sent_in_hmi_none()
  local db_path = config.pathToSDL.."storage/policy.sqlite"
  local sql_query = "SELECT count_of_rpcs_sent_in_hmi_none FROM app_level WHERE application_id = '0000001'"
  count_before = commonFunctions:get_data_policy_sql(db_path, sql_query)
  commonFunctions:userPrint(32,"count_of_rpcs_sent_in_hmi_none: " .. tostring(count_before[1]))
end

function Test:SendDissalowedRpcInNone()
  local cid = self.mobileSession:SendRPC("AddCommand",
    {
      cmdID = 10,
      menuParams =
      {
        position = 0,
        menuName ="Command"
      }
    })
  EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED" })
end

function Test:GetDB_Increase_count_of_rpcs_sent_in_hmi_none()
  local db_path = config.pathToSDL.."storage/policy.sqlite"
  local sql_query = "SELECT count_of_rpcs_sent_in_hmi_none FROM app_level WHERE application_id = '0000001'"
  count_after = commonFunctions:get_data_policy_sql(db_path, sql_query)
  commonFunctions:userPrint(32,"count_of_rpcs_sent_in_hmi_none: " .. tostring(count_after[1]))
  local count_after_exp = count_before[1] + 1
  if not count_after[1] == count_after_exp then
    self:FailTestCase("DB doesn't increase value for count_of_rpcs_sent_in_hmi_none.")
  end
end

return Test