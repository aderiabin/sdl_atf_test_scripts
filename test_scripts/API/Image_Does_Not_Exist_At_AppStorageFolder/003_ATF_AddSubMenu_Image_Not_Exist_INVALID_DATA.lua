-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

------------------------------------ Common Variables ---------------------------------------
local appName = config.application1.registerAppInterfaceParams.appName

-------------------------------------------Preconditions-------------------------------------
-- Register App -> Activate App
common_steps:PreconditionSteps("PreconditionSteps", 7)

--------------------------------------------BODY---------------------------------------------
-- Verify: when menuID param is invalid and image of subMenuIcon doesn't exist
-- SDL->MOB: RPC (success:false, resultCode:"INVALID_DATA")
---------------------------------------------------------------------------------------------
function Test:Verify_MenuIDIncorrect_ImageNotExist_INVALID_DATA()
  common_functions:DelayedExp(2000)
  local cid = self.mobileSession:SendRPC("AddSubMenu",
    {
      --menuID = 1000,
      menuID = "abc",
      position = 500,
      menuName ="SubMenupositive",
      --subMenuIcon will be tested when [APPLINK-21293] done
      subMenuIcon =
      {
        value = "invalidImage.png",
        imageType ="DYNAMIC"
      }
    })
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)
end

-------------------------------------------Postconditions-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegisterApp", appName)
common_steps:StopSDL("Postcondition_StopSDL")
