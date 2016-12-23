Test = require('connecttest')
require('cardinalities')
local events = require('events')
local mobile_session = require('mobile_session')
local mobile  = require('mobile_connection')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')

local commonSteps = require('user_modules/shared_testcases/commonSteps')

function DelayedExp()
  local event = events.Event()
  event.matches = function(self, e) return self == e end
  EXPECT_EVENT(event, "Delayed event")
  RUN_AFTER(function()
              RAISE_EVENT(event, event)
            end, 5000)
end


local n = 0
--///////////////////////////////////////////////////////////////////////////--
--Script cheks TOO_MANY_PENDING_REQUEST resultCode in Alert response from SDL
--///////////////////////////////////////////////////////////////////////////--

--Precondition: app activation
commonSteps:ActivationApp()

-- --///////////////////////////////////////////////////////////////////////////--
-- --Sending 300 Alert requests
-- for n = 1, 300 do
--   Test["AlertRequest"..tostring(n)] = function(self)
--     --mobile side: Alert request  
--       self.mobileSession:SendRPC("Alert",
--                   {
--                     alertText1 = "alertText1",
--                     alertText2 = "alertText2",
--                     alertText3 = "alertText3",
--                     ttsChunks = 
--                     { 
                      
--                       { 
--                         text = "TTSChunk",
--                         type = "TEXT",
--                       } 
--                     }, 
--                     duration = 3000,
--                     softButtons = 
--                     { 
                      
--                       { 
--                         type = "TEXT",
--                         text = "Close" ,
--                         isHighlighted = true,
--                         softButtonID = 3,
--                         systemAction = "DEFAULT_ACTION",
--                       }
--                     }
                  
--                   })
--   end
-- end


--///////////////////////////////////////////////////////////////////////////--
--Check TOO_MANY_PENDING_REQUEST resultCode in Alert response from HMI
  function Test:Alert_TooManyPendingRequest()
    local numberOfRequest = 20
    for n = 1, numberOfRequest do
    --mobile side: Alert request  
      self.mobileSession:SendRPC("Alert",
                  {
                    alertText1 = "alertText1",
                    alertText2 = "alertText2",
                    alertText3 = "alertText3",
                    ttsChunks = 
                    { 
                      
                      { 
                        text = "TTSChunk",
                        type = "TEXT",
                      } 
                    }, 
                    duration = 3000
                  
                  })
  end

  EXPECT_RESPONSE("Alert")
    :ValidIf(function(exp,data)
      if 
        data.payload.resultCode == "TOO_MANY_PENDING_REQUESTS" then
          n = n+1
          print(" \27[32m ChangeRegistration response came with resultCode TOO_MANY_PENDING_REQUESTS \27[0m ")
        return true
      elseif 
        exp.occurences == numberOfRequest and n == 0 then 
          print(" \27[36m  Response ChangeRegistration with resultCode TOO_MANY_PENDING_REQUESTS did not came \27[0m")
          return false
      elseif 
        data.payload.resultCode == "GENERIC_ERROR" then
          print(" \27[32m  ChangeRegistration response came with resultCode GENERIC_ERROR \27[0m")
          return true
      else
          print(" \27[36m  ChangeRegistration response came with resultCode "..tostring(data.payload.resultCode) .."\27[0m")
          return false
        end
      end)
      :Times(AtLeast(numberOfRequest))
      :Timeout(15000)

  --expect absence of OnAppInterfaceUnregistered
  EXPECT_NOTIFICATION("OnAppInterfaceUnregistered")
  :Times(0)

  --expect absence of BasicCommunication.OnAppUnregistered
  EXPECT_HMICALL("BasicCommunication.OnAppUnregistered")
  :Times(0)

  DelayedExp()
  end















