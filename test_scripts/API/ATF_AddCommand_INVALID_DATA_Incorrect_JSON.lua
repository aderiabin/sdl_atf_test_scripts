---------------------------------Required Shared Libraries-----------------------------------
require('user_modules/all_common_modules')

-------------------------------------Common Variables ---------------------------------------
local app = config.application1.registerAppInterfaceParams

---------------------------------------Preconditions---------------------------------------
common_steps:PreconditionSteps("Start_SDL_To_Activate_Application", 7)
common_steps:PutFile("Precondition_Put_File", "action.png")

------------------------------------------Tests-----------------------------------------------
-- This script covers the following requirement:
-- In case:
-- the request "AddCommand" comes to SDL with incorrect json syntax
-- SDL must:
-- respond with resultCode "INVALID_DATA" and success:"false" value. 
----------------------------------------------------------------------------------------------
function Test:AddCommand_INVALID_DATA_Incorrect_JSON()
  local rpc_service_type = 7
  local single_frame_frame_info_type = 0
  local request_rpc_type = 0
  local add_command_function_id = 5
  local incorrect_json_missing_colon_after_cmd_id = '{"cmdID" 55,"vrCommands":["synonym1","synonym2"],' ..
    '"menuParams":{"position":1000,"menuName":"Item To Add"},"cmdIcon":{"value":"action.png","imageType":"DYNAMIC"}}'

  local msg = 
  {
    serviceType      = rpc_service_type,
    frameInfo        = single_frame_frame_info_type,
    rpcType          = request_rpc_type,
    rpcFunctionId    = add_command_function_id,
    rpcCorrelationId = self.mobileSession.correlationId,
    payload          = incorrect_json_missing_colon_after_cmd_id
  }
  self.mobileSession:Send(msg)

  EXPECT_RESPONSE(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })
  :Timeout(5000)
end
-------------------------------------------Postcondition-------------------------------------
common_steps:UnregisterApp("UnRegister_App", app.appName)
common_steps:StopSDL("StopSDL")