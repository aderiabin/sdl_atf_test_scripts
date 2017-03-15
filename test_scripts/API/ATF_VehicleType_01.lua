--------------------------------------------------------------------------------
-- Preconditions before ATF start
--------------------------------------------------------------------------------
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
--------------------------------------------------------------------------------
--Precondition: preparation connecttest_VT.lua
os.execute(  'cp ./modules/connecttest.lua  ./user_modules/connecttest_VT.lua')

f = assert(io.open('./user_modules/connecttest_VT.lua', "r"))

  fileContent = f:read("*all")
  f:close()

 -- update hmiCapabilities in UI.GetLanguage
    local pattern1 = 'ExpectRequest%s-%(%s-"%s-VehicleInfo.GetVehicleType%s-".-%{.-%}%s-%)'
    local ResultPattern2 = fileContent:match(pattern1)

    if ResultPattern2 == nil then 
        print(" \27[31m ExpectRequest UI.GetLanguage call is not found in /user_modules/connecttest_VT.lua \27[0m ")
    else
        fileContent  =  string.gsub(fileContent, pattern1, "")
    end

f = assert(io.open('./user_modules/connecttest_VT.lua', "w"))
f:write(fileContent)
f:close()
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

Test = require('user_modules/connecttest_VT')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')
local config = require('config')

-- VehicleType suit of tests is intended to check sending
-- VehicleType, which selected from PT, in RAI response, if HMI did not sent response to GetVehicleType
-- Note: Used connecttest_1.lua for initializing SDL in which HMI does not send response to GetVehicleType request
-- connecttest.lua should be placed in "modules" folder


-- Precondition: removing user_modules/connecttest_VT.lua
function Test:Precondition_remove_user_connecttest()
  os.execute( "rm -f ./user_modules/connecttest_VT.lua" )
end

-- Preconditional part for updating PT with VehicleType information

function Test:ActivationApp()
    --hmi side: send request SDL.ActivateApp
    local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"]})

    --hmi side: expect SDL.ActivateApp response from SDL
 EXPECT_HMIRESPONSE(RequestId)
 :Do(function(_,data)
     if
         data.result.isSDLAllowed ~= true then
                --hmi side: send request SDL.GetUserFriendlyMessage
             local RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
                  --hmi side: send request SDL.GetUserFriendlyMessage
         EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
               :Do(function(_,data)
            --hmi side: send notification SDL.OnAllowSDLFunctionality
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = 1, name = "127.0.0.1"}})
               end)

                --hmi side: expect BasicCommunication.ActivateApp request from SDL
                EXPECT_HMICALL("BasicCommunication.ActivateApp")
                :Times(AnyNumber())
                :Do(function(_,data)
                    --hmi side: sending BasicCommunication.ActivateApp response from HMI
                    self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
          end)
        elseif data.result.code ~= 0 then
            --In case when activation is not successfull script execution is finish
     quit()
  end
      end)

    --mobile side: receiving OnHMIStatus notification
   EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL"}) 

end

function Test:Precondition_PolicyUpdate()
    --hmi side: sending SDL.GetURLS request
    local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })

    --hmi side: expect SDL.GetURLS response from HMI
    EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {{url = "https://policies.telematics.ford.com/api/policies"}}}})
    :Do(function(_,data)
        print("SDL.GetURLS response is received")
        --hmi side: sending BasicCommunication.OnSystemRequest request to SDL
        self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        {
            requestType = "PROPRIETARY",
            fileName = "filename"
        }
        )
        --mobile side: expect OnSystemRequest notification 
        EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
        :Do(function(_,data)
            print("OnSystemRequest notification is received")
            --mobile side: sending SystemRequest request 
            local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
            {
                fileName = "PolicyTableUpdate",
                requestType = "PROPRIETARY"
            },
            "VehicleTypePTU_01.json")

            local systemRequestId
            --hmi side: expect SystemRequest request
            EXPECT_HMICALL("BasicCommunication.SystemRequest")
            :Do(function(_,data)
                systemRequestId = data.id
                print("BasicCommunication.SystemRequest is received")

                --hmi side: sending BasicCommunication.OnSystemRequest request to SDL
                self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
                {
                    policyfile = "/tmp/fs/mp/images/ivsu_cache/0PolicyTableUpdate"
                }
                )
                function to_run()
                    --hmi side: sending SystemRequest response
                    self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
                end

                RUN_AFTER(to_run, 500)
            end)

            --hmi side: expect SDL.OnStatusUpdate
            EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status =  "UP_TO_DATE"})
            :Do(function(_,data)
                print("SDL.OnStatusUpdate is received")

               
            end)
            :Timeout(2000)

            --mobile side: expect SystemRequest response
            EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
            :Do(function(_,data)
                print("SystemRequest is received")
                --hmi side: sending SDL.GetUserFriendlyMessage request to SDL
                local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"StatusUpToDate"}})

                --hmi side: expect SDL.GetUserFriendlyMessage response
                EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage", messages = {{line1 = "Up-To-Date", messageCode = "StatusUpToDate", textBody = "Up-To-Date"}}}})
                :Do(function(_,data)
                    print("SDL.GetUserFriendlyMessage is received")

                    --hmi side: sending SDL.GetListOfPermissions request to SDL
                    local RequestIdGetListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = self.applications["Test Application"]})

                    -- hmi side: expect SDL.GetListOfPermissions response
                    EXPECT_HMIRESPONSE(RequestIdGetListOfPermissions,{result = {code = 0, method = "SDL.GetListOfPermissions", allowedFunctions = {{ id = 156072572, name = "Location"}}}})
                    :Do(function(_,data)
                        print("SDL.GetListOfPermissions response is received")

                        --hmi side: sending SDL.OnAppPermissionConsent
                        self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID =  self.applications["Test Application"], consentedFunctions = {{ allowed = true, id = 156072572, name = "Location"}}, source = "GUI"})
                    end)
                end)
            end)
            :Timeout(7000)
            print("PT successfully updated")

        end)
    end)

end


-- The current application should be unregistered before next test. 
  function Test:UnregisterAppInterface_Success()
    --request from mobile side
        local CorIdUnregisterAppInterface = self.mobileSession:SendRPC("UnregisterAppInterface",{})

    --response on mobile side
    EXPECT_RESPONSE(CorIdUnregisterAppInterface, { success = true, resultCode = "SUCCESS"})
    :Timeout(2000)
    end



-- Checking that vehicleType selected from PT

  -- Register the app again 
  function Test:RAI_With_Expected_VehicleType()
    --request from mobile side
        local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

        --response on mobile side
        EXPECT_RESPONSE(correlationId, { 
        	success = true, 
        	resultCode = "SUCCESS",
        	vehicleType = {
      			make = "Ford from policy",
     			model = "Fiesta from policy",
      			modelYear = "2222"} }
      				 	)
  end
