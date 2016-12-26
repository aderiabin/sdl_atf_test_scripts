require('user_modules/all_common_modules')
---------------------------------------------------------------------------------------------
-------------------------------------------Preconditions-------------------------------------
---------------------------------------------------------------------------------------------
-- 1. Print new line to separate new test cases group
common_steps:AddNewTestCasesGroup("Preconditions")
common_functions:DeleteLogsFileAndPolicyTable()

-- Start SDL, HMI, Connect mobile, Register and Activate app
common_steps:PreconditionSteps("PreconditionSteps", 7)

-- 2. Create PT that allowed OnTouchEvent in Base-4 group and update PT
local permission_lines_on_touch_event = 
[[	"OnTouchEvent": {
	"hmi_levels": [
	"BACKGROUND",
	"LIMITED",
	"FULL"
	]
}]] .. ", \n"

local permission_lines_on_touch_event = permission_lines_on_touch_event 
local permission_lines_for_group1 = nil
local permission_lines_for_application = nil
local pt_name = update_policy:createPolicyTableFile(permission_lines_on_touch_event, permission_lines_for_group1, permission_lines_for_application)	
update_policy:updatePolicy(pt_name)

-----------------------------------------------------------------------------------------------
-------------------------------------------Body----------------------------------------
--------------------------------Check normal cases of HMI notification---------------------------
-----------------------------------------------------------------------------------------------
-- TouchEvent struct must contain 'ts' param with Long type and maxvalue="5000000000"
-- Parameter: Checks event.ts parameter: type=Long, mandatory=true, array=true, minvalue=0, maxvalue=5000000000 minsize=1, maxsize=1000
----------------------------------------------------------------------------------------------
common_steps:AddNewTestCasesGroup("Check normal cases of HMI notification")
-- 1. IsLowerBound
-- 2. IsMiddle
-- 2. IsUpperBound
local valid_values = {
	{name = "IsLowerBound", value = 0},
	{name = "IsMiddle", value = 1147483647},
	{name = "IsUpperBound", value = 5000000000}
}
for i = 1, #valid_values do
	Test["OnTouchEvent_event_ts_" .. valid_values[i].name] = function(self)
		
		local parameter = {
			type = "BEGIN", 
			event = { {c = {{x = 1, y = 1}}, id = 1, ts = {valid_values[i].value} } }
		}
		
		-- hmi side: send OnTouchEvent
		self.hmiConnection:SendNotification("UI.OnTouchEvent", parameter)
		
		-- mobile side: expected OnTouchEvent notification
		EXPECT_NOTIFICATION("OnTouchEvent", parameter)
		
	end
end

-- 4. IsMissed
-- 5. IsOutLowerBound
-- 6. IsOutUpperBound
-- 7. IsWrongType
local invalid_values = {	
	{name = "IsMissed", value = nil},
	{name = "IsOutLowerBound", value = {}},
	{name = "IsOutUpperBound", value = 5000000001},
	{name = "WrongDataType", value = "123"}
}
for i = 1, #invalid_values do
	Test["OnTouchEvent_event_ts_" .. invalid_values[i].name] = function(self)
		common_functions:DelayedExp(2000)
		local parameter = {
			type = "BEGIN", 
			event = { {c = {{x = 1, y = 1}}, id = 1, ts = {invalid_values[i].value} } }
		}
		
		-- hmi side: send OnTouchEvent
		self.hmiConnection:SendNotification("UI.OnTouchEvent", parameter)
		
		-- mobile side: expected OnTouchEvent notification
		EXPECT_NOTIFICATION("OnTouchEvent")
		:Times(0)
	end
end
