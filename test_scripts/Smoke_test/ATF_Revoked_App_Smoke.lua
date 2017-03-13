---------------------------------------------------------------------------------------------
-- Requirement summary: 
-- [APPLINK-19829]: [RegisterAppInterface] Allow only RegisterAppInterface for the application with NULL policies. 

-- Description:
-- In case PolicyTable has "<appID>": "null" in the Local PolicyTable, 
-- PoliciesManager must only process RegisterAppInterface request with successful response

-- Preconditions:
-- 1. PT contains: "<appID>" section (for example, appID=123abc) with "null" permissions:
-- "policy_table":{
	-- "app_policies":{
		-- "123":null
	-- }
--}
-- Steps:
-- 1. Mob -> SDL: Send valid registration request: app->SDL:RegisterAppInterface (appID: 123, params)

-- Expected result:
-- SDL -> Mob: RegisterAppInterface(SUCCESS)

---------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')

---------------------------------------------------------------------------------------------

common_steps:AddNewTestCasesGroup("Preconditions")

-- An app is registered and activated
common_steps:PreconditionSteps("Preconditions", 7)
update_policy:updatePolicy("files/ptu_revokedapp_smoke.json", _, "PTU_With_RevokedApp")

local mobile_session_name = "mobilesession2"
common_steps:AddMobileSession("AddMobileSession_For_Revoked_App",_, mobile_session_name)

local app_revoked = common_functions:CreateRegisterAppParameters(
{appID = "123", appName = "Revoked_app", isMediaApplication = true, appHMIType = {"DEFAULT"}})

common_steps:RegisterApplication("Register_Revoked_Application_AppId_123", mobile_session_name, app_revoked)

---------------------------------------------------------------------------------------------
-- Requirement summary: 
-- [APPLINK-16253]: [GeneralResultCode] DISALLOWED. A request comes with appID which has "null" permissions in Policy Table. 

-- Description:
-- In case PolicyTable has "<appID>": "null" in the Local PolicyTable for the specified application with appID
-- PoliciesManager must return DISALLOWED resultCode and success:"false" to any RPC requested by such <appID> app.

-- Preconditions:
--1. SDL and HMI are running

-- Steps:
-- 1. Mob -> SDL: Any_RPC_except_of_RegisterAppInterface (params)

-- Expected result:
-- SDL -> Mob: Any_RPC_except_of_RegisterAppInterface(DISALLOWED, success:"false")

---------------------------------------------------------------------------------------------
function Test:PutFile_DISALLOWED() 
	local cid = self[mobile_session_name]:SendRPC("PutFile", {
  syncFileName = "icon.png",fileType = "GRAPHIC_PNG"}, "files/icon.png")
	self[mobile_session_name]:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED"})
end

function Test:DeleteFile_DISALLOWED()
	local cid = self[mobile_session_name]:SendRPC("DeleteFile", {syncFileName = "action.png"})
	self[mobile_session_name]:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED"})
end		

function Test:ListFile_DISALLOWED()
	local cid = self[mobile_session_name]:SendRPC("ListFiles", {})
	self[mobile_session_name]:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED"})
end		

-----------------------------------Postcondition-------------------------------
common_steps:StopSDL("Postcondition_StopSDL")
