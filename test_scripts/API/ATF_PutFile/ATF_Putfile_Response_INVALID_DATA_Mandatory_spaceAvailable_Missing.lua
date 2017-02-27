---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [APPLINK-16115]: [Putfile RPC] In case the request comes without parameters defined as mandatory in
--  mobile API, SDL must respond with resultCode "INVALID_DATA" and success:"false" value.
-- [APPLINK-14626]: If mandatory flag is missing from mobile API the parameter is set as mandatory.

-- Description:
-- Sending valid request, without mandatory parameters, should result in response containing
--  resultCode "INVALID_DATA", success:"false" and mandatory parameters

-- Preconditions:
-- 1. App is registered and activated
-- Steps:
-- 1. Mob -> SDL: SendRPC "PutFile" without parameters

-- Expected result:
-- SDL -> Mob: Send Response with success = false, resultCode = "INVALID_DATA", spaceAvaliable = xxx
---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

---------------------------------------------------------------------------------------------
--[[ Preconditions ]]
common_steps:AddNewTestCasesGroup("Preconditions")
common_steps:PreconditionSteps("Preconditions", 7)

---------------------------------------------------------------------------------------------
--[[ Test PutFile INVALID_DATA ]]
function Test:Test_PutFile_without_parameters()
  local cid = self.mobileSession:SendRPC("PutFile", {}, "files/" .. const.image_icon_png)
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
end

---------------------------------------------------------------------------------------------
--[[ Postconditions ]]
common_steps:AddNewTestCasesGroup("Postconditions")
common_steps:UnregisterApp("Postcondition_UnRegisterApp", const.default_app_name)
common_steps:StopSDL("Postcondition_StopSDL")
