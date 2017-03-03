-----------------------------Required Shared Libraries-----------------------------------
require('user_modules/all_common_modules')

-------------------------------------------Preconditions---------------------------------
-- Register App -> Activate App
common_steps:PreconditionSteps("PreconditionSteps", 7)

--------------------------------------------BODY-----------------------------------------
-- Verify: when position param is invalid and image of cmdIcon doesn't exist
-- SDL->MOB: RPC (success:false, resultCode:"INVALID_DATA")
-----------------------------------------------------------------------------------------
function Test:Verify_PossitionIncorrect_ImageNotExist_INVALID_DATA()
  common_functions:DelayedExp(2000)
  local cid = self.mobileSession:SendRPC("AddCommand",
    {
      cmdID = 11,
      menuParams =
      {
        --position = 0,
        position = "aaa",
        menuName = "Commandpositive"
      },
      vrCommands =
      {
        "VRCommandonepositive",
        "VRCommandonepositivedouble"
      },
      cmdIcon =
      {
        value = "invalidImage.png",
        imageType ="DYNAMIC"
      }
    })
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)
end

-------------------------------------------Postconditions--------------------------------
common_steps:UnregisterApp("Postcondition_UnRegisterApp", const.default_app_name)
common_steps:StopSDL("Postcondition_StopSDL")
