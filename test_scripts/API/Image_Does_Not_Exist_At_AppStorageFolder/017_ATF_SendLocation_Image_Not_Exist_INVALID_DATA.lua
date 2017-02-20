-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

------------------------------------ Common Variables ---------------------------------------
local storagePath = config.pathToSDL .. "storage/"
..config.application1.registerAppInterfaceParams.appID.. "_" .. config.deviceMAC.. "/"
local appName = config.application1.registerAppInterfaceParams.appName

-------------------------------------------Preconditions-------------------------------------
-- common_functions:DeleteLogsFileAndPolicyTable()
common_functions:BackupFile("sdl_preloaded_pt.json")
--1. Activate application
common_steps:PreconditionSteps("PreconditionSteps", 7)
--2. Backup sdl_preloaded_pt.json then updatePolicy
update_policy:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/PTU_For_Image_Not_Exist.json")

--------------------------------------------BODY---------------------------------------------
-- Verify: when longitudeDegrees param is invalid and image of locationImage doesn't exist
-- SDL->MOB: RPC (success:false, resultCode:"INVALID_DATA")
---------------------------------------------------------------------------------------------
function Test:Verify_LongitudeDegreesIncorrect_ImageNotExist_INVALID_DATA()
  local Request = {
    --longitudeDegrees = 1,
    longitudeDegrees = "abc",
    latitudeDegrees = 1,
    locationImage =
    {
      value = storagePath.."icon888.png",
      imageType = "DYNAMIC",
    }
  }
  local cid = self.mobileSession:SendRPC("SendLocation", Request)
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
end

-------------------------------------------Postconditions-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegisterApp", appName)
common_steps:StopSDL("Postcondition_StopSDL")
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")
