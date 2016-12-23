--This script contains all test cases to verify boolean parameter
--How to use:
	--1. local booleanParameter = require('user_modules/shared_testcases/testCasesForBooleanParameter')
	--2. booleanParameter:verify_bolean_Parameter(Request, Parameter, ExistentValues, Mandatory)
---------------------------------------------------------------------------------------------

local testCasesForBooleanParameterInResponse = {}
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')



---------------------------------------------------------------------------------------------
--Test cases to verify boolean parameter
---------------------------------------------------------------------------------------------
--List of test cases:
	--1. IsMissed
	--2. IsExistentValues
	--3. IsWrongType
	

--Contains all test cases
function testCasesForBooleanParameterInResponse:verify_Boolean_Parameter(Response, Parameter, IsMandatory)

	--Print new line to separate new test cases group
	commonFunctions:newTestCasesGroup(Parameter)	
	
	--1. IsMissed
	if IsMandatory == nil then
		--no check mandatory: in case this parameter is element in array. We does not verify an element is missed. It is checked in test case checks bound of array.
	else			
		if IsMandatory == true then
			--HMI sends response and check that SDL ignores the Response 
			commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsMissed", nil, "GENERIC_ERROR")	
		else
			--HMI sends response and check that SDL ignores the Response
			commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsMissed", nil, "SUCCESS")	
		end		
	end
	
	--2. IsWrongDataType
	commonFunctions:TestCaseForResponse(self, Response, Parameter, "IsWrongDataType", 123, "GENERIC_ERROR")
	
	--3. IsExistentValues
	commonFunctions:TestCaseForResponse(self, Response, Parameter, "true", true, "SUCCESS")
	commonFunctions:TestCaseForResponse(self, Response, Parameter, "false", false, "SUCCESS")
	
end
return testCasesForBooleanParameterInResponse
