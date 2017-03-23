-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

-------------------------------------------Preconditions-------------------------------------
common_functions:DeleteLogsFileAndPolicyTable()
function Test:UpdatePreloadFileAllowSetAndResetGlobalProperties()
  local pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
  local parent_item = {"policy_table", "functional_groupings", "Base-4", "rpcs"}
  local added_json_items = {SetGlobalProperties = {hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}}, ResetGlobalProperties = {hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}}}
  common_functions:AddItemsIntoJsonFile(pathToFile, parent_item, added_json_items)
end
common_steps:PreconditionSteps("Precondition", 7)

------------------------------------------------Body-----------------------------------------
common_steps:AddNewTestCasesGroup("Test cases for autoCompleteList array")
function Test:SetGlobalProperties_WithLowerBoundArray()
  local cid = self.mobileSession:SendRPC("SetGlobalProperties",
    {
      keyboardProperties = {autoCompleteList = {"ABC"}}
    })
  EXPECT_HMICALL("UI.SetGlobalProperties",
    {
      keyboardProperties = {autoCompleteList = {"ABC"}}
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
  EXPECT_NOTIFICATION("OnHashChange")
end

function Test:SetGlobalProperties_WithUpperBoundArray()
  local text = string.rep("a", 50)
  local array = {}
  for i = 1, 100 do
    array[i] = text
  end
  local cid = self.mobileSession:SendRPC("SetGlobalProperties",
    {
      keyboardProperties = {autoCompleteList = array}
    })
  EXPECT_HMICALL("UI.SetGlobalProperties",
    {
      keyboardProperties = {autoCompleteList = array}
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
  EXPECT_NOTIFICATION("OnHashChange")
end

function Test:SetGlobalProperties_OutUpperBoundArray()
  common_functions:DelayedExp(2000)
  local text = string.rep("a", 50)
  local array = {}
  for i = 1, 101 do
    array[i] = text
  end
  local cid = self.mobileSession:SendRPC("SetGlobalProperties",
    {
      keyboardProperties = {autoCompleteList = array}
    })
  EXPECT_HMICALL("UI.SetGlobalProperties")
  :Times(0)
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
end

function Test:SetGlobalProperties_OutLowerBoundArray()
  common_functions:DelayedExp(2000)
  local cid = self.mobileSession:SendRPC("SetGlobalProperties",
    {
      keyboardProperties = {autoCompleteList = {}}
    })
  EXPECT_HMICALL("UI.SetGlobalProperties")
  :Times(0)
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
end

function Test:SetGlobalProperties_WrongTypeOfArray()
  common_functions:DelayedExp(2000)
  local cid = self.mobileSession:SendRPC("SetGlobalProperties",
    {
      keyboardProperties = {autoCompleteList = "123"}
    })
  EXPECT_HMICALL("UI.SetGlobalProperties")
  :Times(0)
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
end

common_steps:AddNewTestCasesGroup("Test cases for element of autoCompleteList array")
function Test:SetGlobalProperties_WithElementLowerBound()
  local cid = self.mobileSession:SendRPC("SetGlobalProperties",
    {
      keyboardProperties = {autoCompleteList = {"A"}}
    })
  EXPECT_HMICALL("UI.SetGlobalProperties",
    {
      keyboardProperties = {autoCompleteList = {"A"}}
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
  EXPECT_NOTIFICATION("OnHashChange")
end

function Test:SetGlobalProperties_WithElementUpperBound()
  local text = string.rep("a", 50)
  local cid = self.mobileSession:SendRPC("SetGlobalProperties",
    {
      keyboardProperties = {autoCompleteList = {text}}
    })
  EXPECT_HMICALL("UI.SetGlobalProperties",
    {
      keyboardProperties = {autoCompleteList = {text}}
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
  EXPECT_NOTIFICATION("OnHashChange")
end

function Test:SetGlobalProperties_WithElementOutLowerBound()
  common_functions:DelayedExp(2000)
  local cid = self.mobileSession:SendRPC("SetGlobalProperties",
    {
      keyboardProperties = {autoCompleteList = {""}}
    })
  EXPECT_HMICALL("UI.SetGlobalProperties")
  :Times(0)
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
end

function Test:SetGlobalProperties_WithElementOutUpperBound()
  common_functions:DelayedExp(2000)
  local text = string.rep("a", 51)
  local cid = self.mobileSession:SendRPC("SetGlobalProperties",
    {
      keyboardProperties = {autoCompleteList = {text}}
    })
  EXPECT_HMICALL("UI.SetGlobalProperties")
  :Times(0)
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
end

function Test:SetGlobalProperties_WithElementWrongType()
  common_functions:DelayedExp(2000)
  local cid = self.mobileSession:SendRPC("SetGlobalProperties",
    {
      keyboardProperties = {autoCompleteList = {123}}
    })
  EXPECT_HMICALL("UI.SetGlobalProperties")
  :Times(0)
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
end

function Test:SetGlobalProperties_WithElementContainsNewLineCharacter()
  common_functions:DelayedExp(2000)
  local cid = self.mobileSession:SendRPC("SetGlobalProperties",
    {
      keyboardProperties = {autoCompleteList = {"abc\n"}}
    })
  EXPECT_HMICALL("UI.SetGlobalProperties")
  :Times(0)
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
end

function Test:SetGlobalProperties_WithElementContainsTabCharacter()
  common_functions:DelayedExp(2000)
  local cid = self.mobileSession:SendRPC("SetGlobalProperties",
    {
      keyboardProperties = {autoCompleteList = {"abc\t"}}
    })
  EXPECT_HMICALL("UI.SetGlobalProperties")
  :Times(0)
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
end

function Test:SetGlobalProperties_WithElementContainsSpaceCharacters()
  common_functions:DelayedExp(2000)
  local cid = self.mobileSession:SendRPC("SetGlobalProperties",
    {
      keyboardProperties = {autoCompleteList = {" "}}
    })
  EXPECT_HMICALL("UI.SetGlobalProperties")
  :Times(0)
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
end

common_steps:AddNewTestCasesGroup("Test cases for Invalid Json")
function Test:SetGlobalProperties_WithInvalidJson()
  common_functions:DelayedExp(2000)
  local cid = self.mobileSession.correlationId + 1
  local msg =
  {
    serviceType = 7,
    frameInfo = 0,
    rpcType = 0,
    rpcFunctionId = 3, -- ID of SetGlobalProperties RPC
    rpcCorrelationId = cid,
    -- Replace : by = in JSon message
    payload = '{"keyboardProperties" = {"autoCompleteList"=["ABC"]}}'
  }
  self.mobileSession:Send(msg)
  EXPECT_HMICALL("UI.SetGlobalProperties")
  :Times(0)
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA"})
end

common_steps:AddNewTestCasesGroup("Test cases for Response from HMI is invalid")
function Test:SetGlobalProperties_HmiResponsesInvalid()
  common_functions:DelayedExp(2000)
  local cid = self.mobileSession:SendRPC("SetGlobalProperties",
    {
      keyboardProperties = {autoCompleteList = {"ABC"}}
    })
  EXPECT_HMICALL("UI.SetGlobalProperties",
    {
      keyboardProperties = {autoCompleteList = {"ABC"}}
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method .. "abcd", "SUCCESS", {}) -- wrong method
    end)
  EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR"})
  EXPECT_NOTIFICATION("OnHashChange")
  :Times(0)
end

common_steps:AddNewTestCasesGroup("Test case for request without autoCompleteList")
function Test:SetGlobalProperties_WithoutAutoCompleteList()
  local cid = self.mobileSession:SendRPC("SetGlobalProperties",
    {
      keyboardProperties = {autoCompleteText = "ABC"}
    })
  EXPECT_HMICALL("UI.SetGlobalProperties",
    {
      keyboardProperties = {autoCompleteText = "ABC"}
    })
  :ValidIf(function(_,data)
      return not data.params.keyboardProperties.autoCompleteList
    end)
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
  EXPECT_NOTIFICATION("OnHashChange")
end

common_steps:AddNewTestCasesGroup("Test case for request contains both autoCompleteText and autoCompleteList")
function Test:SetGlobalProperties_WithBothAutoCompleteListAndAutoCompleteText()
  local cid = self.mobileSession:SendRPC("SetGlobalProperties",
    {
      keyboardProperties = {autoCompleteText = "ABC", autoCompleteList = {"ABC"}}
    })
  EXPECT_HMICALL("UI.SetGlobalProperties",
    {
      keyboardProperties = {autoCompleteList = {"ABC"}}
    })
  :ValidIf(function(_,data)
      return not data.params.keyboardProperties.autoCompleteText
    end)
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
  EXPECT_NOTIFICATION("OnHashChange")
end

common_steps:AddNewTestCasesGroup("Test case for verify autoCompleteList in ResetGlobalProperties RPC")
common_steps:StopSDL("StopSDL")

function Test:UpdateAutoCompleteListTrue()
  local pathToFile = config.pathToSDL .. 'hmi_capabilities.json'
  local parent_item = {"UI", "keyboardPropertiesDefault"}
  local added_json_items = {
    languageDefault = "EN-US",
    keyboardLayoutDefault = "QWERTY",
    keypressModeDefault = "SINGLE_KEYPRESS",
    autoCompleteListDefault = true}
  common_functions:AddItemsIntoJsonFile(pathToFile, parent_item, added_json_items)
end

common_steps:PreconditionSteps("Precondition", 7)
function Test:ResetGlobalProperties_autoCompleteListTrue()
  local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
    {
      properties = {"KEYBOARDPROPERTIES"}
    })
  EXPECT_HMICALL("UI.SetGlobalProperties",
    {
      keyboardProperties =
      {
        language = "EN-US",
        keyboardLayout = "QWERTY",
        keypressMode = "SINGLE_KEYPRESS",
        autoCompleteList = true
      }
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
  EXPECT_NOTIFICATION("OnHashChange")
end

common_steps:StopSDL("StopSDL")

function Test:UpdateAutoCompleteListFalse()
  local pathToFile = config.pathToSDL .. 'hmi_capabilities.json'
  local parent_item = {"UI", "keyboardPropertiesDefault"}
  local added_json_items = {
    languageDefault = "EN-US",
    keyboardLayoutDefault = "QWERTY",
    keypressModeDefault = "SINGLE_KEYPRESS",
    autoCompleteListDefault = false}
  common_functions:AddItemsIntoJsonFile(pathToFile, parent_item, added_json_items)
end

common_steps:PreconditionSteps("Precondition", 7)
function Test:ResetGlobalProperties_autoCompleteListFalse()
  local cid = self.mobileSession:SendRPC("ResetGlobalProperties",
    {
      properties = {"KEYBOARDPROPERTIES"}
    })
  EXPECT_HMICALL("UI.SetGlobalProperties",
    {
      keyboardProperties =
      {
        language = "EN-US",
        keyboardLayout = "QWERTY",
        keypressMode = "SINGLE_KEYPRESS",
        autoCompleteList = false
      }
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
  EXPECT_NOTIFICATION("OnHashChange")
end

------------------------------------------Postconditions-------------------------------------
common_steps:StopSDL("StopSDL")
