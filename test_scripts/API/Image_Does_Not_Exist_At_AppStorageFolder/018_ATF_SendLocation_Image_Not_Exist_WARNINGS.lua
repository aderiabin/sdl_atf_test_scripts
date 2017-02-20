-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

------------------------------------ Common Variables ---------------------------------------
local storagePath = config.pathToSDL .. "storage/"..config.application1.registerAppInterfaceParams.appID.. "_" .. config.deviceMAC.. "/"

-------------------------------------------Preconditions-------------------------------------
-- common_functions:DeleteLogsFileAndPolicyTable()
common_functions:BackupFile("sdl_preloaded_pt.json")
--1. Activate application
common_steps:PreconditionSteps("PreconditionSteps", 7)
--2. Backup sdl_preloaded_pt.json then updatePolicy
update_policy:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/PTU_For_Image_Not_Exist.json")

--------------------------------------------BODY---------------------------------------------
-- Verify: when all params are correct and image of locationImage doesn't exist
-- SDL->MOB: RPC (success:false, resultCode:"WARNINGS", info:"Reference image(s) not found")
---------------------------------------------------------------------------------------------
function Test:Verify_AllParamsCorrect_ImageNotExist_WARNINGS()
  local request = {
    longitudeDegrees = 1.1,
    latitudeDegrees = 1.1,
    locationImage =
    {
      value = storagePath.."icon888.png",
      imageType = "DYNAMIC",
    }
  }
  local cid = self.mobileSession:SendRPC("SendLocation", request)

  EXPECT_HMICALL("Navigation.SendLocation", {
      longitudeDegrees = 1.1,
      latitudeDegrees = 1.1
    })
  :Do(function(_,data)
      -- self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      self.hmiConnection:SendError(data.id, data.method, "WARNINGS","Reference image(s) not found")
    end)

  -- EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", info = "Reference image(s) not found"})
end
-------------------------------------------Postconditions-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegisterApp", config.application1.registerAppInterfaceParams.appName)
common_steps:StopSDL("Postcondition_StopSDL")
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")
