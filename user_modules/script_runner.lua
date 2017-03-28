local Test = require('user_modules/dummy_connecttest')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

local stepNumber = 0
local runnerState = {
  precondition = true,
  test = true,
  postcondition = true,
  title = false
}
local title
local steps = {}

local runner = {}



--[ATF]
local function buildStepName(testStepName)
  if type(testStepName) == "string"
    and testStepName ~= "" then
    testStepName = testStepName:gsub("%W", "_")
    while testStepName:match("^[%d_]") do
      if #testStepName == 1 then
        stepNumber = stepNumber + 1
        return "Unknown_test_step_" .. stepNumber
      end
      testStepName = testStepName:sub(2)
    end
    if testStepName:match("^%l") then
        testStepName = testStepName:sub(1, 1):upper() .. testStepName:sub(2)
    end
    return testStepName
  elseif type(testStepName) == "number" then
    return "Test_step_" .. testStepName
  else
    stepNumber = stepNumber + 1
    return "Unknown_test_step_" .. stepNumber
  end
end

local function buildStepImplFunction(testStepImplFunction)
  if type(testStepImplFunction) == "function" then
    return testStepImplFunction
  else
    return function()
        print ("Dummy step")
      end
  end
end

local function addTestStep(testStepName, testStepImplFunction)
  local test = Test
  testStepName = buildStepName(testStepName)
  testStepImplFunction = buildStepImplFunction(testStepImplFunction)
  if test then
    test[testStepName] = testStepImplFunction
  else
    table.insert(steps, {name = testStepName, implFunc = testStepImplFunction})
  end
end

--[[ Precondition - Step - Postcondition approach]]
local function extendedAddTestStep(runnerStateType, messageText, testStepName, testStepImplFunction, paramsTable)
  local implFunctionsListWithParams = {}
  if runnerState[runnerStateType] then
    table.insert(implFunctionsListWithParams, {implFunc = commonFunctions.userPrint, params = {0, 32, messageText, "\n"}})
    runnerState[runnerStateType] = false
  end
  if not paramsTable then
    paramsTable = {}
  end
  table.insert(implFunctionsListWithParams, {implFunc = testStepImplFunction, params = paramsTable})
  local newTestStepImplFunction = function(self)
      for _, func in pairs(implFunctionsListWithParams) do
        table.insert(func.params, self)
        func.implFunc(unpack(func.params))
      end
    end
  addTestStep(testStepName, newTestStepImplFunction, paramsTable)
end

function runner.PRECONDITION(testStepName, testStepImplFunction, paramsTable)
  extendedAddTestStep("precondition", "--------------------------------Precondition--------------------------------", testStepName, testStepImplFunction, paramsTable)
end

function runner.STEP(testStepName, testStepImplFunction, paramsTable)
  extendedAddTestStep("test", "------------------------------------Test------------------------------------", testStepName, testStepImplFunction, paramsTable)
end

function runner.POSTCONDITION(testStepName, testStepImplFunction, paramsTable)
  extendedAddTestStep("postcondition", "--------------------------------Postcondition-------------------------------", testStepName, testStepImplFunction, paramsTable)
end

--[[ Title + Step approach]]
local function buildTitle(titleText)
  local maxLength = 101
  local filler = "-"
  local resultTable = {}
  for line in titleText:gmatch("[^\n]+") do
    local lineLength = #line
    if lineLength >= maxLength then
      table.insert(resultTable, line)
    else
      local tailLength = math.fmod(maxLength - lineLength, 2)
      local emtyLineSideLength = math.floor((maxLength - lineLength) / 2)
      table.insert(resultTable, filler:rep(emtyLineSideLength) .. line .. filler:rep(emtyLineSideLength + tailLength))
    end
  end
  return table.concat(resultTable, "\n")
end

function runner.Title(titleText)
  if runnerState.title == true then
    title = title .. "\n" .. titleText
  else
    title = titleText
    runnerState.title = true
  end
  title = buildTitle(title)
end

function runner.Step(testStepName, testStepImplFunction, paramsTable)
  extendedAddTestStep("title", title, testStepName, testStepImplFunction, paramsTable)
end

function runner.Run()
  local test = Test
  for _, step in pairs(steps) do
    test[step.name] = step.implFunc
  end
end

return runner