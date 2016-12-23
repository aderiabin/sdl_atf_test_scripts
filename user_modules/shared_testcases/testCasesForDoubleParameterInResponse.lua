--This script contains all test cases to verify Double parameter
--How to use:
	--1. local integerParameter = require('user_modules/shared_testcases/testCasesForDoubleParameter')
	--2. integerParameter:verify_Double_Parameter(Request, Parameter, Boundary, Mandatory)
---------------------------------------------------------------------------------------------

local testCasesForDoubleParameter = {}
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

function testCasesForDoubleParameter:verify_Double_Parameter(Response, Parameter, Boundary, Mandatory)

		local Response = commonFunctions:cloneTable(Response)			
		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup(Parameter)	
		
		--1. IsMissed
		local resultCode
		if Mandatory == true then
			resultCode = "GENERIC_ERROR"
			
		else
			resultCode = "SUCCESS"
		end
		
		commonFunctions:TestCaseForResponse(self, Response, Parameter,"IsMissed", nil, resultCode)	
		
		--2. IsWrongDataType
		commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsWrongDataType", "123", "GENERIC_ERROR")
		
		--3. IsEmptyValue
		commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsEmptyValue", "", "GENERIC_ERROR")
		
		--4. IsLowerBound
		commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsLowerBound_Int", Boundary[1], "SUCCESS")
		

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
		commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsLowerBound_Double", Boundary[1] + ValueForLowerBound, "SUCCESS")
		
		--5. IsUpperBound
		commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsUpperBound_Int" , Boundary[2], "SUCCESS")

		local ValueForUpperBound = Value_for_Double_cases(Boundary[2])
		commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsUpperBound_Double" , Boundary[2] - ValueForUpperBound, "SUCCESS")
		
		--6. IsOutLowerBound
		commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsOutLowerBound", Boundary[1] - ValueForLowerBound, "GENERIC_ERROR")
		
		--7. IsOutUpperBound
		commonFunctions:TestCaseForResponse(self, Response, Parameter , "IsOutUpperBound", Boundary[2] + ValueForUpperBound, "GENERIC_ERROR")

		--8. Max double value
		commonFunctions:TestCaseForResponse(self, Response, Parameter , "MaxDoubleDecimalPlaces" , 0.00000000000000001, "SUCCESS")
		
end


return testCasesForDoubleParameter
