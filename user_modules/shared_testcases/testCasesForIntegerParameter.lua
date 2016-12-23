--This script contains all test cases to verify Integer parameter
--How to use:
	--1. local integerParameter = require('user_modules/shared_testcases/testCasesForIntegerParameter')
	--2. integerParameter:verify_Integer_Parameter(Request, Parameter, Boundary, Mandatory)
---------------------------------------------------------------------------------------------


local testCasesForIntegerParameter = {}
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')




---------------------------------------------------------------------------------------------
--Test cases to verify Integer parameter
---------------------------------------------------------------------------------------------
--List of test cases for Integer type parameter:
	--1. IsMissed
	--2. IsWrongType
	--3. IsLowerBound
	--4. IsUpperBound
	--5. IsOutLowerBound
	--6. IsOutUpperBound
	

--Contains all test cases
function testCasesForIntegerParameter:verify_Integer_Parameter(Request, Parameter, Boundary, Mandatory, DefaultValue)
		
		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup(Parameter)	
		
		
		--1. IsMissed
		local resultCode
		if ((Mandatory == true) and (DefaultValue ==nil)) then
			resultCode = "INVALID_DATA"
		else
			resultCode = "SUCCESS"
		end
		
		
		commonFunctions:TestCase(self, Request, Parameter, "IsMissed", DefaultValue, resultCode)	
		
		
		--2. IsWrongDataType
		commonFunctions:TestCase(self, Request, Parameter, "IsWrongDataType", "123", "INVALID_DATA")
		
		--3. IsLowerBound
		commonFunctions:TestCase(self, Request, Parameter, "IsLowerBound", Boundary[1], "SUCCESS")
		
		--4. IsUpperBound
		commonFunctions:TestCase(self, Request, Parameter, "IsUpperBound", Boundary[2], "SUCCESS")
		
		
		--5. IsOutLowerBound
		commonFunctions:TestCase(self, Request, Parameter, "IsOutLowerBound", Boundary[1] -1, "INVALID_DATA")
		
		--6. IsOutUpperBound
		commonFunctions:TestCase(self, Request, Parameter, "IsOutUpperBound", Boundary[2] + 1, "INVALID_DATA")
		
end


return testCasesForIntegerParameter
