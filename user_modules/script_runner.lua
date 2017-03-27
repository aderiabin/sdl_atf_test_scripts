local Test = require('user_modules/dummy_connecttest')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

local stepNumber = 0
local runnerState = {
  precondition = false,
  test = false,
  postcondition = false
}
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

local function extendedAddTestStep(runnerStateType, messageText, testStepName, testStepImplFunction, test)
  local newTestStepImplFunction = testStepImplFunction
  if not runnerState[runnerStateType] then
    newTestStepImplFunction = function(self)
        commonFunctions:userPrint(32, messageText)
        testStepImplFunction(self)
      end
    runnerState[runnerStateType] = true
  end
  addTestStep(testStepName, newTestStepImplFunction, test)
end

function runner.PRECONDITION(testStepName, testStepImplFunction, test)
  extendedAddTestStep("precondition", "--------------------------------Precondition--------------------------------", testStepName, testStepImplFunction, test)
end

function runner.STEP(testStepName, testStepImplFunction, test)
  extendedAddTestStep("test", "------------------------------------Test------------------------------------", testStepName, testStepImplFunction, test)
end

function runner.POSTCONDITION(testStepName, testStepImplFunction, test)
  extendedAddTestStep("postcondition", "--------------------------------Postcondition-------------------------------", testStepName, testStepImplFunction, test)
end

function runner.Run(test)
  for _, step in pairs(steps) do
    test[step.name] = step.implFunc
  end
end

return runner