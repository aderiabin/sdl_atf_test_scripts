-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

-------------------------------------------Preconditions-------------------------------------
-- Register App -> Activate App
common_steps:PreconditionSteps("PreconditionSteps", 7)

--------------------------------------------BODY---------------------------------------------
-- Verify: when type param is invalid and image of vrHelp doesn't exist
-- SDL->MOB: RPC (success:false, resultCode:"INVALID_DATA")
---------------------------------------------------------------------------------------------
function Test:Verify_AllParamsCorrect_ImageNotExist_INVALID_DATA()
  cid = self.mobileSession:SendRPC("PerformInteraction",
    {
      initialText = "StartPerformInteraction",
      initialPrompt = {{
          text = "Make your choice",
          --type = "TEXT"
          type = 123
      }},
      interactionMode = "BOTH",
      interactionChoiceSetIDList =
      {
        100, 200, 300
      },
      helpPrompt = {
        {
          text = "Help Promptv ",
          type = "TEXT"
        },
        {
          text = "Help Promptvv ",
          type = "TEXT"
      }},
      timeoutPrompt = {{
          text = "Timeoutv",
          type = "TEXT"
        },
        {
          text = "Timeoutvv",
          type = "TEXT"
      }},
      timeout = 5000,
      vrHelp = {
        {
          image =
          {
            imageType = "DYNAMIC",
            value = "InvalidImage.png"
          },
          text = "NewVRHelpv",
          position = 1
        },
        {
          image =
          {
            imageType = "DYNAMIC",
            value = "invalidImage.png"
          },
          text = "NewVRHelpvv",
          position = 2
        },
        {
          image =
          {
            imageType = "DYNAMIC",
            value = "invalidImage.png"
          },
          text = "NewVRHelpvvv",
          position = 3
        }
      },
      interactionLayout = "ICON_ONLY"
    })
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
end

-------------------------------------------Postconditions-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegisterApp", const.default_app_name)
common_steps:StopSDL("Postcondition_StopSDL")
