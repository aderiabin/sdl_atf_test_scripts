--------------------------------------------------------------------------------
-- This script covers requirment [AddCommand] [GeneralResultCodes] [Ford-Specific]: 
-- In case
-- the request ("AddCommand") comes without parameters defined as mandatory in mobile API
-- SDL must:
-- respond with resultCode:"INVALID_DATA" and success:"false" value. 

-- Requirement id in Confluence: 
	-- APPLINK-16115
					

-------------------------------------Required Shared Libraries-------------------------------
require('user_modules/all_common_modules')

------------------------------------ Common Variables ---------------------------------------
local app = config.application1.registerAppInterfaceParams

local test_case_name = "ATF_AddCommand_INVALID_DATA_Mandatory_Param_Missing"
local precondition   = "Precondition"
local postcondition  = "Postcondition"
local icon_name      = "icon.png"

--------------------------------------Preconditions------------------------------------------
common_steps:PreconditionSteps(precondition, 7)
---------------------------------------------------------------------------------------------
-- Putting icon image file
---------------------------------------------------------------------------------------------
local function putFile()
	Test["PutFile"] = function(self)
		local cid = self.mobileSession:SendRPC("PutFile",
			{			
				syncFileName = icon_name,
				fileType	= "GRAPHIC_PNG",
				persistentFile = false,
				systemFile = false
			}, "files/icon.png")	
		EXPECT_RESPONSE(cid, { success = true})
	end
end

putFile()
---------------------------------------------------------------------------------------------
-- Adding SubMenu
---------------------------------------------------------------------------------------------
local function addSubMenu()
	menuIDValue = 1
	Test["AddSubMenuWithId" .. menuIDValue] = function(self)
		local cid = self.mobileSession:SendRPC("AddSubMenu",
			{
				menuID = menuIDValue,
				menuName = "SubMenu" .. menuIDValue
			})
		
		EXPECT_HMICALL("UI.AddSubMenu", 
			{ 
				menuID = menuIDValue,
				menuParams = { menuName = "SubMenu" .. menuIDValue }
			})
		:Do(function(_,data)
				--hmi side: sending response
					self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
		end)
		
		EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
		EXPECT_NOTIFICATION("OnHashChange")
	end
end

addSubMenu()
-----------------------------------------------Body------------------------------------------

---------------------------------------------------------------------------------------------
common_steps:AddNewTestCasesGroup("TC_" .. test_case_name)
-----------------------------------------------------------------------------------------
-- Requirement summary: After AddCommand request from mobile application without mandatory
-- parameter  SDL responds with "INVALID_DATA" and success:"false" value.

-- 1.Preconditions:
-- -- 1.1. Application is registered and activated
-- -- 1.2. Icon image file is successfully uploaded with PutFile request
-- -- 1.3. SubMenu successfully added with AddSubMenu request

-- 2.Steps:
-- -- 2.1. Send AddCommand request with mandatory "cmdID" parameter missing
-- -- 2.2. Send AddCommand request with optional "menuParams" paremeter present but it's mandatory "menuName" paremeter missing.
-- -- 2.3. Send AddCommand request with optional "cmdIcon" paremeter present but it's mandatory "value" paremeter missing.
-- -- 2.4. Send AddCommand request with optional "cmdIcon" paremeter present but it's mandatory "imageType" paremeter missing.
-- -- 2.5. Send AddCommand request with all parameters missing.

-- 3.Expected Results:
-- -- 3.1. Response with resultCode "INVALID_DATA" and success:"false" value recieved for each step.
-- -- 3.1. No "OnHashChange" notification recieved for each step.
-----------------------------------------------------------------------------------------
-- Begin step 2.1
-- Description: Mandatory missing - "cmdID"
local function addCommand_cmdIDMissing()
    Test["AddCommand_cmdIDMissing"] = function(self)
		--mobile side: sending AddCommand request
		local cid = self.mobileSession:SendRPC("AddCommand",
		{
			menuParams = 	
			{ 
				parentID = 1,
				position = 0,
				menuName ="Command1"
			}, 
			vrCommands = 
			{ 
				"Voicerecognitioncommandone"
			}, 
			cmdIcon = 	
			{ 
				value ="icon.png",
				imageType ="DYNAMIC"
			}
		})		
		
		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
			
		--mobile side: expect OnHashChange notification is not send to mobile
		EXPECT_NOTIFICATION("OnHashChange")
		:Times(0)
	end
end

addCommand_cmdIDMissing()

-- End Step 2.1
-----------------------------------------------------------------------------------------
-- Begin Step 2.2
-- Description: Mandatory missing - "menuName" of "menuParams" missing
local function addCommand_menuParamsMenuNameMissing()
    Test["AddCommand_menuParamsMenuNameMissing"] = function(self)
		--mobile side: sending AddCommand request
		local cid = self.mobileSession:SendRPC("AddCommand",
			{
				cmdID = 123,
				menuParams = 	
				{ 
					parentID = 1,
					position = 0
				}, 
				vrCommands = 
				{ 
					"VRCommandonepositive",
					"VRCommandonepositivedouble"
				}, 
				cmdIcon = 	
				{ 
					value ="icon.png",
					imageType ="DYNAMIC"
				}
			})		

		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
				
		--mobile side: expect OnHashChange notification is not send to mobile
		EXPECT_NOTIFICATION("OnHashChange")
		:Times(0)
	end
end					
addCommand_menuParamsMenuNameMissing()

-- End Step 2.2
-----------------------------------------------------------------------------------------
-- Begin Step 2.3
-- Description: Mandatory missing - "value" of "cmdIcon" missing
local function addCommand_cmdIconValueMissing()
	Test["AddCommand_cmdIconValueMissing"] = function(self)
	--mobile side: sending AddCommand request
		local cid = self.mobileSession:SendRPC("AddCommand",
		{
			cmdID = 224,
			menuParams = 	
			{ 
				parentID = 1,
				position = 0,
				menuName ="Command224"
			}, 
			vrCommands = 
			{ 
				"CommandTwoTwoFour"
			},
			cmdIcon = 	
			{
				imageType ="DYNAMIC"
			}
		})

		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
		
		--mobile side: expect OnHashChange notification is not send to mobile
		EXPECT_NOTIFICATION("OnHashChange")
		:Times(0)
	end
end					

addCommand_cmdIconValueMissing()

-- End Step 2.3
-----------------------------------------------------------------------------------------
-- Begin Step 2.4
-- Description: Mandatory missing - "imageType" of "cmdIcon" missing
local function addCommand_cmdIconImageTypeMissing()
	Test["AddCommand_cmdIconImageTypeMissing"] = function(self)
	--mobile side: sending AddCommand request
		local cid = self.mobileSession:SendRPC("AddCommand",
		{
			cmdID = 225,
			menuParams = 	
			{ 
				parentID = 1,
				position = 0,
				menuName ="Command225"
			}, 
			vrCommands = 
			{ 
				"CommandTwoTwoFive"
			},
			cmdIcon = 	
			{
				value ="icon.png"
			}
		})
		
		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
			
		--mobile side: expect OnHashChange notification is not send to mobile
		EXPECT_NOTIFICATION("OnHashChange")
		:Times(0)
	end
end					

addCommand_cmdIconImageTypeMissing()

-- End Step 2.4
-----------------------------------------------------------------------------------------
-- Begin Step 2.5
-- Description: All parameters missing
local function addCommand_AllParamsMissing()
	Test["AddCommand_AllParamsMissing"] = function(self)
		--mobile side: sending AddCommand request
		local cid = self.mobileSession:SendRPC("AddCommand",
		{
		})		
		
		EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
			
		--mobile side: expect OnHashChange notification is not send to mobile
		EXPECT_NOTIFICATION("OnHashChange")
		:Times(0)
	end
end		

addCommand_AllParamsMissing()

-- End Step 2.5
-----------------------------------------------------------------------------------------

-------------------------------------------Postcondition-------------------------------------
common_steps:UnregisterApp(postcondition .. "_UnRegister_App", app.appName)
common_steps:StopSDL(postcondition .. "_StopSDL")