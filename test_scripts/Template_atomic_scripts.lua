---------------------------------------------------------------------------------------------
-- Requirement summary: 
-- Requirement ID: Name(s) of requirement that is covered.
-- Requirement ID: Name(s) of additional non-functional requirement(s) if applicable
--
-- Description:
-- Describe correctly the CASE of requirement that is covered, conditions that will be used.
-- 1. Used preconditions(if applicable)
-- 2. Performed steps
--
-- Expected result:
-- Expected SDL behavior
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local common_functions = require ('user_modules/shared_testcases/commonFunctions')

--[[ Local Variables ]]
-- if not applicable remove this section

--[[ Local Functions ]]
-- if not applicable remove this section

-- if applicable shortly describe the purpose of function and used parameters
--[[ @Example: the function gets....
--! @parameters:
--! func_param ]]
local function Example(func_param)
  -- body
end

--[[ General Precondition before ATF start ]]
-- General precondition for restoring configuration files of SDL:
common_functions:SDLForceStop()

--[[ General Settings for configuration ]]
-- if not applicable remove this section
-- This part is under clarification, based on section for using common functions
Test = require('connecttest')
require('user_modules/AppTypes')

--[[ Preconditions ]]
-- if not applicable remove this section
common_functions:newTestCasesGroup("Preconditions")
function Test:Precondition_DESCRIPTION()
  -- body
end

--[[ Test ]]
common_functions:newTestCasesGroup("Test")
-- Each Test will be separate and defined as one or few TestSteps
function Test:TestStep_DESCRIPTION()
  -- body
end

--[[ Postconditions ]]
-- if not applicable remove this section
common_functions:newTestCasesGroup("Postconditions")
function Test:Postcondition_DESCRIPTION()
  -- body
end

return Test
