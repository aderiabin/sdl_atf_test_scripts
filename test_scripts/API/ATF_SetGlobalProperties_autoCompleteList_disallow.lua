-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

-------------------------------------------Preconditions-------------------------------------
common_functions:DeleteLogsFileAndPolicyTable()
function Test:UpdatePreloadFileDisallowSetGlobalProperties()
  local pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
  local parent_item = {"policy_table", "functional_groupings", "Base-4", "rpcs"}
  local removed_json_items =
  {
    "SetGlobalProperties"
  }
  common_functions:RemoveItemsFromJsonFile(pathToFile, parent_item, removed_json_items)
end
common_steps:PreconditionSteps("Precondition", 7)

------------------------------------------------Body-----------------------------------------
common_steps:AddNewTestCasesGroup("Test cases for autoCompleteList array")
function Test:SetGlobalProperties_WithOnlyAutoCompleteList()
  common_functions:DelayedExp(2000)
  local cid = self.mobileSession:SendRPC("SetGlobalProperties",
    {
      keyboardProperties = {autoCompleteList = {"ABC"}}
    })
  EXPECT_HMICALL("UI.SetGlobalProperties")
  :Times(0)
  EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED"})
end

------------------------------------------Postconditions-------------------------------------
common_steps:StopSDL("StopSDL")
