--------------------------------------------------------------------------------
-- This script covers requirment [AddCommand] [GeneralResultCodes] [Ford-Specific]: 
-- In case:
-- the request (AddCommand) comes to SDL with incorrect json syntax
-- SDL must:
-- respond with resultCode "INVALID_DATA" and success:"false" value. 

-- Requirement id in Confluence: 
	-- APPLINK-16739
					
---------------------------------Required Shared Libraries-----------------------------------
require('user_modules/all_common_modules')
---------------------------------------------------------------------------------------------

-------------------------------------Common Variables ---------------------------------------
local app = config.application1.registerAppInterfaceParams

local test_case_name = "ATF_AddCommand_INVALID_DATA_Incorrect_JSON"
local precondition   = "Precondition"
local postcondition  = "Postcondition"
local icon_name      = "action.png"
---------------------------------------------------------------------------------------------

-----------------------------------------Preconditions---------------------------------------
common_steps:PreconditionSteps(precondition, 7)
---------------------------------------------------------------------------------------------
-- Putting icon image file
---------------------------------------------------------------------------------------------
local function putFileIcon()
	Test[precondition .. "_PutFile_Icon"] = function(self)
		local cid = self.mobileSession:SendRPC("PutFile",
			{			
				syncFileName = icon_name,
				fileType	= "GRAPHIC_PNG",
				persistentFile = false,
				systemFile = false
			-- }, "files/action.png")	
			}, "files/" .. icon_name)	
		EXPECT_RESPONSE(cid, { success = true})
	end
end

putFileIcon()
-------------------------------------------Body----------------------------------------------
common_steps:AddNewTestCasesGroup("TC_" .. test_case_name)
---------------------------------------------------------------------------------------------
-- Requirement summary: After AddCommand request from mobile application with incorrect JSON
-- syntax SDL responds with "INVALID_DATA" and success:"false" value.

-- 1.Preconditions:
-- -- 1.1. Application is registered and activated
-- -- 1.2. Icon image file is successfully uploaded with PutFile request
-- -- 1.3. SubMenu successfully added with AddSubMenu request

-- 2.Steps:
-- -- 2.1. Send AddCommand request with wrong JSON syntax

-- 3.Expected Results:
-- -- 3.1. Response with resultCode "INVALID_DATA" and success:"false" value recieved for each step.
-- -- 3.1. No "OnHashChange" notification recieved for each step.
---------------------------------------------------------------------------------------------
-- Begin Step 2.1
---------------------------------------------------------------------------------------------
local function addCommand_IncorrectJSON()
	Test["AddCommand_IncorrectJSON"] = function(self)
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
			-- rpcCorrelationId
			rpcCorrelationId = self.mobileSession.correlationId,
			--<<!-- missing ':'
			payload          = '{"cmdID" 55,"vrCommands":["synonym1","synonym2"],"menuParams":{"position":1000,"menuName":"Item To Add"},' ..
							   '"cmdIcon":{"value":"action.png","imageType":"DYNAMIC"}}'
		}
		self.mobileSession:Send(msg)
		EXPECT_RESPONSE(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })
		:Timeout(5000)
				
		--mobile side: expect OnHashChange notification is not send to mobile
		EXPECT_NOTIFICATION("OnHashChange")
		:Times(0)	
		
	end
end			

addCommand_IncorrectJSON()
---------------------------------------------------------------------------------------------
-- End Step 2.1
---------------------------------------------------------------------------------------------

-------------------------------------------Postcondition-------------------------------------
common_steps:UnregisterApp(postcondition .. "_UnRegister_App", app.appName)
common_steps:StopSDL(postcondition .. "_StopSDL")