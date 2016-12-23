--This script contains all test cases to verify Double parameter
--How to use:
	--1. local doubleParameterInNotification = require('user_modules/shared_testcases/testCasesForDoubleParameterInNotification')
	--2. doubleParameterInNotification:verify_Double_Parameter(Notification, Parameter, Boundary, Mandatory)
---------------------------------------------------------------------------------------------


local testCasesForDoubleParameterInNotification = {}
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')




---------------------------------------------------------------------------------------------
--Test cases to verify Double parameter
---------------------------------------------------------------------------------------------
--List of test cases for Double type parameter:
	--1. IsMissed
	--2. IsWrongType
	--3. IsLowerBound
	--4. IsUpperBound
	--5. IsOutLowerBound
	--6. IsOutUpperBound
	

--Contains all test cases
function testCasesForDoubleParameterInNotification:verify_Double_Parameter(Notification, Parameter, Boundary, Mandatory)
		
		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup(Parameter)	
		
		
		--1. IsMissed
		local IsValidValue = false

		if Mandatory == true then
				--resultCode = "GENERIC_ERROR"
				IsValidValue = false
		else
				--resultCode = "SUCCESS"
				IsValidValue = true
		end		
		commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsMissed", nil, IsValidValue)	

		
		
		--2. IsWrongDataType
		commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsWrongDataType", "123", false)
		
		--3. IsLowerBound
		commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsLowerBound_Int", Boundary[1], true)

		local function Value_for_Double_cases(BoundValue)
			local valueForBound 

			BoundValue = tostring(BoundValue)
			IntBound = BoundValue:match("[-]?([(%d^.]+).?")

			if #IntBound == 1 then
				valueForBound = 0.0000000000001
			elseif #IntBound == 2 then
				valueForBound = 0.000000000001
			elseif #IntBound == 3 then
				valueForBound = 0.00000000001
			end

			return valueForBound
		end

		local ValueForLowerBound = Value_for_Double_cases(Boundary[1])
		commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsLowerBound_Double", Boundary[1] + ValueForLowerBound, true)
		
		--4. IsUpperBound
		commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsUpperBound_Int" , Boundary[2], true)

		local ValueForUpperBound = Value_for_Double_cases(Boundary[2])
		commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsUpperBound_Double" , Boundary[2] - ValueForUpperBound, true)
		
		--5. IsOutLowerBound
		commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsOutLowerBound", Boundary[1] - ValueForLowerBound, false)
		
		--6. IsOutUpperBound
		commonFunctions:TestCaseForNotification(self, Notification, Parameter, "IsOutUpperBound", Boundary[2] + ValueForUpperBound, false)

		--7. Max double value
		commonFunctions:TestCaseForNotification(self, Notification, Parameter, "MaxDoubleDecimalPlaces" , 0.00000000000000001, true)
		
end


return testCasesForDoubleParameterInNotification
