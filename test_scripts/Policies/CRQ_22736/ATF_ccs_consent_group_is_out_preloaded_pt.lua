require('user_modules/all_common_modules')
-------------------------------------- Variables --------------------------------------------


------------------------------------ Common functions ---------------------------------------
-- n/a

-------------------------------------- Preconditions ----------------------------------------
common_functions:BackupFile("sdl_preloaded_pt.json")

------------------------------------------- BODY ---------------------------------------------
-- Precondition: 
-- 1. ccs_consent_group is not existed in PreloadedPT
-- 2. user_consent_records existed in PreloadedPT
-- Verification criteria: 
-- 1. SDL considers PreloadedPT as valid
-- 2. Start successfully
-- 3. Triggered to create a SnapshotPolicyTable without ccs_consent_group
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
					"input": "GUI",
					"time_stamp": "2015-10-09T18:07:21Z"
				}
			}
		}
	}
}
]]

local test_case_id = "TC_1"
local test_case_name = test_case_id .. ": ccs_consent_groups is omitted in PreloadedPT"
common_steps:AddNewTestCasesGroup(test_case_name)

Test[tostring(test_case_name) .. "_Precondition_StopSDL"] = function(self)
	StopSDL()
end	

Test[test_case_name .. "_Precondition_RestoreDefaultPreloadedPt"] = function (self)
	common_functions:DeletePolicyTable()
end

-- Create temp_sdl_preloaded_pt.json in current build to make sure it does not contain ccs_consent_group
-- Add device_data structure into temp_sdl_preloaded_pt.json
local function AddItemsIntoJsonFile(parent_item, added_json_items)
	local json_file = "files/temp_sdl_preloaded_pt_without_ccs_consent_group.json"
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
-- Remove sdl_preloaded_pt.json from current build
Test[test_case_name .. "_Precondition_Remove_DefaultPreloadedPt"] = function (self)
	os.execute(" rm " .. config.pathToSDL .. "sdl_preloaded_pt.json")
end 
-- Change temp_sdl_preloaded_pt_without_ccs_consent_group.json to sdl_preloaded_pt.json
Test[test_case_name .. "_Precondition_ChangedPreloadedPt"] = function (self)
	os.execute(" cp " .. "files/temp_sdl_preloaded_pt_without_ccs_consent_group.json".. " " .. config.pathToSDL .. "sdl_preloaded_pt.json")
end 

common_steps:IgnitionOn("StartSDL")

common_steps:AddMobileSession("AddMobileSession")

common_steps:RegisterApplication("RegisterApp")

common_steps:ActivateApplication("ActivateApp", config.application1.registerAppInterfaceParams.appName)

function DelayedExp(time)
	local event = events.Event()
	event.matches = function(self, e) return self == e end
	EXPECT_EVENT(event, "Delayed event")
	:Timeout(time+1000)
	RUN_AFTER(function()
		RAISE_EVENT(event, event)
	end, time)
end

function Test:Precondition_TriggerSDLSnapshotCreation_UpdateSDL()
	local RequestIdUpdateSDL = self.hmiConnection:SendRequest("SDL.UpdateSDL")
	--hmi side: expect SDL.UpdateSDL response from HMI
	EXPECT_HMIRESPONSE(RequestIdUpdateSDL,{result = {code = 0, method = "SDL.UpdateSDL", result = "UPDATE_NEEDED" }})
	DelayedExp(2000)
end

function Test:CheckCcsConsentGroupNotIncludedInSnapshot()
	Test["CheckCcsConsentGroupNotIncludedInSnapshot"] = function (self)
		local SDLsnapshot = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json"
		
		local file_snap_shot = io.open(SDLsnapshot, "r")
		
		local json_snap_shot = file_snap_shot:read("*all") -- may be abbreviated to "*a";
		entities = json_snap_shot:match("ccs_consent_groups")
		commonFunctions:printTable(entities)
		if entities == nil then
			print ( " \27[31m disallowed_by_ccs_entities_on is not found in SnapShot \27[0m " )
			return true
			
			
		else
			print ( " \27[31m disallowed_by_ccs_entities_on is found in SnapShot \27[0m " )
			return false
			
		end
		file_snap_shot:close()
	end
end

-------------------------------------- Postconditions ----------------------------------------
common_steps:RestoreIniFile("Restore_PreloadedPT", "sdl_preloaded_pt.json")