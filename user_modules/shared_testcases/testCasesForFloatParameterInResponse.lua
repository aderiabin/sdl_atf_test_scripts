--This script contains all test cases to verify Float parameter
--How to use:
	--1. local integerParameter = require('user_modules/shared_testcases/testCasesForFloatParameter')
	--2. integerParameter:verify_Float_Parameter(Response, Parameter, Boundary, Mandatory)
---------------------------------------------------------------------------------------------


local testCasesForFloatParameter = {}
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')




---------------------------------------------------------------------------------------------
--Test cases to verify Float parameter
---------------------------------------------------------------------------------------------
--List of test cases for Float type parameter:
	--1. IsMissed
	--2. IsWrongType
	--3. IsLowerBound
	--4. IsUpperBound
	--5. IsOutLowerBound
	--6. IsOutUpperBound
	

--Contains all test cases
function testCasesForFloatParameter:verify_Float_Parameter(Response, Parameter, Boundary, Mandatory, NamePrefix)
		
		--Print new line to separate new test cases group
		commonFunctions:newTestCasesGroup(Parameter)	
		
		
		--1. IsMissed
		local resultCode
		if Mandatory == true then
			resultCode = "GENERIC_ERROR"
		else
			resultCode = "SUCCESS"
		end

		if NamePrefix == nil then
			NamePrefix = ""
		end
		
		
		commonFunctions:TestCaseForResponse(self, Response, Parameter, tostring(NamePrefix) .. "IsMissed", nil, resultCode)	
		
		
		--2. IsWrongDataType
		commonFunctions:TestCaseForResponse(self, Response, Parameter, tostring(NamePrefix) .. "IsWrongDataType", "123", "GENERIC_ERROR")
		
		--3. IsLowerBound
		commonFunctions:TestCaseForResponse(self, Response, Parameter, tostring(NamePrefix) .. "IsLowerBound", Boundary[1] + 0.1, "SUCCESS")
		
		--4. IsUpperBound
		commonFunctions:TestCaseForResponse(self, Response, Parameter, tostring(NamePrefix) .. "IsUpperBound" , Boundary[2] - 0.1, "SUCCESS")
		
		--5. IsOutLowerBound
		commonFunctions:TestCaseForResponse(self, Response, Parameter, tostring(NamePrefix) .. "IsOutLowerBound", Boundary[1] - 0.1, "GENERIC_ERROR")
		
		--6. IsOutUpperBound
		commonFunctions:TestCaseForResponse(self, Response, Parameter, tostring(NamePrefix) .. "IsOutUpperBound", Boundary[2] + 0.1, "GENERIC_ERROR")

		--8.IsOutUpperBoundFloatSize
		commonFunctions:TestCaseForResponse(self, Response, Parameter, tostring(NamePrefix) .. "MaxFloatDecimalPlaces", 0.00000001 , "SUCCESS")

		--8.IsOutUpperBoundFloatSize
		-- Uncomment after resolving APPLINK-23105
		-- commonFunctions:TestCaseForResponse(self, Response, Parameter, tostring(NamePrefix) .. "IsOutUpperBoundFloatSize", 0.0000000001 , "INVALID_DATA")
		
end


return testCasesForFloatParameter
