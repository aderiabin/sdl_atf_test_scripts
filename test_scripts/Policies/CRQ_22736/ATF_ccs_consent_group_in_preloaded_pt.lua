require('user_modules/all_common_modules')
-------------------------------------- Variables ------------------------------

------------------------------------ Common functions -------------------------
-- n/a

-------------------------------------- Preconditions --------------------------
common_functions:BackupFile("sdl_preloaded_pt.json")

------------------------------------------- BODY ------------------------------
-- Precondition: 
-- 1. ccs_consent_group is existed in PreloadedPT

-- Verification criteria: 
-- 1. SDL considers PreloadedPT as invalid
-- 2. log corresponding error internally and shut SDL down

local test_case_id = "TC_1"
local test_case_name = test_case_id .. ": SDL failed when ccs_consent_groups is existed in PreloadedPT"
common_steps:AddNewTestCasesGroup(test_case_name)

Test[tostring(test_case_name) .. "_Precondition_StopSDL"] = function(self)
	StopSDL()
end	

Test[test_case_name .. "_Precondition_RestoreDefaultPreloadedPt"] = function (self)
	common_functions:DeletePolicyTable()
end


function Test:AddItemsIntoJsonFile(parent_item, added_json_items)
  local parent_item = {"policy_table", "module_config"}
local added_json_items = 
[[
{
	 "device_data": {
        "HUU40DAS7F970UEI17A73JH32L41K32JH4L1K234H3K4": {
          "user_consent_records": {
              "0000001": {
                "consent_groups": {
                  "Location": true
               },
              "ccs_consent_groups": {
                             "Location":false
              },
           "input": "GUI",
           "time_stamp": "2015-10-09T18:07:21Z"
            }
            },
            "os": "Android"
        }
    }
}
]]
	local json_file = config.pathToSDL .. 'sdl_preloaded_pt.json'
	local match_result = "null"
	local temp_replace_value = "\"Thi123456789\""
	local file = io.open(json_file, "r")
	local json_data = file:read("*all")
	file:close()
	json_data_update = string.gsub(json_data, match_result, temp_replace_value)
	local json = require("modules/json")
	local data = json.decode(json_data_update)
	-- Go to parent item
	local parent = data
	for i = 1, #parent_item do
		if not parent[parent_item[i]] then
			parent[parent_item[i]] = {}
		end
		parent = parent[parent_item[i]]
	end
	if type(added_json_items) == "string" then
		added_json_items = json.decode(added_json_items)
	end
	
	for k, v in pairs(added_json_items) do
		parent[k] = v
	end
	
	data = json.encode(data)	
	data_revert = string.gsub(data, temp_replace_value, match_result)
	file = io.open(json_file, "w")
	file:write(data_revert)
	file:close()	
end

Test[test_case_name .. "_StartSDL_WithInvalidParamInPreloadedPT"] = function(self)
		StartSDL(config.pathToSDL, config.ExitOnCrash)
end	

Test["VerifyCcsConsentGroupNotSavedInPreloadedPT_"..test_case_name] = function(self)
    sql_query = "select * from ccs_consent_group"
		-- Look for policy.sqlite file
		local policy_file1 = config.pathToSDL .. "storage/policy.sqlite"
		local policy_file2 = config.pathToSDL .. "policy.sqlite"
		local policy_file
		if common_steps:FileExisted(policy_file1) then
			policy_file = policy_file1
		elseif common_steps:FileExisted(policy_file2) then
			policy_file = policy_file2
		else
			common_functions:PrintError("policy.sqlite file is not exist")
		end
		if policy_file then
			local ful_sql_query = "sqlite3 " .. policy_file .. " \"" .. sql_query .. "\""
			local handler = io.popen(ful_sql_query, 'r')
			os.execute("sleep 1")
			local result = handler:read( '*l' )
			handler:close()
			if(result==nil) then
				return true
			else
				self:FailTestCase("entities value in DB is also saved in local policy table although invalid param existed in PreloadedPT file")
				return false
			end
		end
	end

-------------------------------------- Postconditions -------------------------
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")
