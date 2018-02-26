---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/3
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/SetInteriorVehicleData.md
-- Item: Use Case 1: Exceptions: 7.1
--
-- Requirement summary:
-- [SDL_RC] Set available control module settings SetInteriorVehicleData
--
-- Description:
-- In case:
-- 1) SDL has sent SetInteriorVehicleData with one or more settable parameters in "moduleData" struct
-- 2) and HMI responds with "resultCode: READ_ONLY"
-- SDL must:
-- 1) Send "resultCode: READ_ONLY, success:false" to the related mobile application
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/SEAT/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function setVehicleData(pModuleType)
	local mobSession = commonRC.getMobileSession()
	local cid = mobileSession:SendRPC("SetInteriorVehicleData", {
		moduleData = commonRC.getSettableModuleControlData(pModuleType)
	})

	EXPECT_HMICALL("RC.SetInteriorVehicleData",	{
		appID = commonRC.getHMIAppId(),
		moduleData = commonRC.getSettableModuleControlData(pModuleType)
	})
	:Do(function(_, data)
			commonRC.getHMIconnection():SendError(data.id, data.method, "READ_ONLY", "Info message")
		end)

	mobileSession:ExpectResponse(cid, { success = false, resultCode = "READ_ONLY", info = "Info message" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)
runner.Step("Activate App", commonRC.activate_app)

runner.Title("Test")

runner.Step("SetInteriorVehicleData SEAT", setVehicleData, { "SEAT" })


runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)