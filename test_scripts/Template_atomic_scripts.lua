---------------------------------------------------------------------------------------------
-- Requirement summary: 
-- [Requirement ID]: Summary of requirement that is covered.
-- [Requirement ID]: Summary of additional non-functional requirement(s) if applicable. 
-- Refer to below example:
-- [APPLINK-22403]: [Policies]: User consent storage in LocalPT (OnAppPermissionConsent with appID)

-- Description:
-- Describe correctly the CASE of requirement that is covered, conditions that will be used.

-- Preconditions:
-- 1. App is registered and activated
-- 2...

-- Steps:
-- 1. Mob -> SDL: ...
-- 2. SDL -> UI: ...
-- 3. UI -> SDL: ...

-- Expected result:
-- SDL -> Mob: ...

---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

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

---------------------------------------------------------------------------------------------
--[[ General Precondition before ATF start ]]
-- General precondition for restoring configuration files of SDL:
-- such as backup then update preloaded_pt.json

--[[ Preconditions ]]
-- if not applicable remove this section
common_steps:AddNewTestCasesGroup("Preconditions")
-- An app is registered and activated
common_steps:PreconditionSteps("Preconditions", 7)
common_steps:PutFile("Preconditions_PutFile_action.png", "action.png")
function Test:Precondition_DESCRIPTION()
  -- body
end

---------------------------------------------------------------------------------------------
--[[ Test ]]
common_steps:AddNewTestCasesGroup("Test")
-- Each Test will be separate and defined as one or few TestSteps
function Test:TestStep_DESCRIPTION()
  -- body
end

---------------------------------------------------------------------------------------------
--[[ Postconditions ]]
-- if not applicable remove this section
common_steps:AddNewTestCasesGroup("Postconditions")
function Test:Postcondition_DESCRIPTION()
  -- body
end
local app_name = config.application1.registerAppInterfaceParams.appName
common_steps:UnregisterApp("Postcondition_UnRegisterApp", app_name)
common_steps:StopSDL("Postcondition_StopSDL")
