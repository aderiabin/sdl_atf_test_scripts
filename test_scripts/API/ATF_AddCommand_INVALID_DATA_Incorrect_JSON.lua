---------------------------------Required Shared Libraries-----------------------------------
require('user_modules/all_common_modules')

-------------------------------------Common Variables ---------------------------------------
local app = config.application1.registerAppInterfaceParams
local icon_name      = "action.png"

---------------------------------------Preconditions---------------------------------------
common_steps:PreconditionSteps("Start_SDL_To_Activate_Application", 7)
common_steps:PutFile("Precondition_Put_File", icon_name)

------------------------------------------Tests-----------------------------------------------
-- This script covers the following requirement:
-- In case:
-- the request "AddCommand" comes to SDL with incorrect json syntax
-- SDL must:
-- respond with resultCode "INVALID_DATA" and success:"false" value. 
----------------------------------------------------------------------------------------------
function Test:AddCommand_INVALID_DATA_Incorrect_JSON()
  local msg = 
  {
    -- serviceType = <Remote Procedure Call>
    serviceType      = 7,
    -- default frameInfo for SingleFrameType
    frameInfo        = 0,
    -- rpcType = <Request>
    rpcType          = 0,
    -- rpcFunctionId = <AddCommandID>
    rpcFunctionId    = 5,
    rpcCorrelationId = self.mobileSession.correlationId,
    -- incorrect JSON in payload: missing ':' after "cmdID"
    payload          = '{"cmdID" 55,"vrCommands":["synonym1","synonym2"],"menuParams":{"position":1000,"menuName":"Item To Add"},' ..
               '"cmdIcon":{"value":"action.png","imageType":"DYNAMIC"}}'
  }
  self.mobileSession:Send(msg)

  EXPECT_RESPONSE(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })
  :Timeout(5000)
end
-------------------------------------------Postcondition-------------------------------------
common_steps:UnregisterApp("UnRegister_App", app.appName)
common_steps:StopSDL("StopSDL")