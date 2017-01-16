-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

-------------------------------------------Preconditions-------------------------------------
common_functions:DeleteLogsFileAndPolicyTable()
common_steps:PreconditionSteps("Precondition", 7)

-----------------------------------------------Body------------------------------------------
function Test:Turn_on_DD()
  self.hmiConnection:SendNotification("UI.OnDriverDistraction", {state = "DD_ON"})
  EXPECT_NOTIFICATION("OnDriverDistraction", {state = "DD_ON"})
end

function Test:ScrollableMessageIsRejected()
  local appID = common_functions:GetHmiAppId(config.application1.registerAppInterfaceParams.appName, self)
  local request =
  {
    scrollableMessageBody = "abc",
    timeout = 3000
  }
  local cid = self.mobileSession:SendRPC("ScrollableMessage", request)
  EXPECT_HMICALL("UI.ScrollableMessage", {})
  :Do(function(_,data)
    self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = appID, systemContext = "MAIN" })
    self.hmiConnection:SendError(data.id, data.method, "REJECTED", "DD mode is active!")
  end)
  
  EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED", info = "DD mode is active!"})
end

function Test:AddSubMenuIsSuccess()
  local cid = self.mobileSession:SendRPC("AddSubMenu",
  {
    menuID = 11,
    menuName ="SubMenumandatoryonly1"
  })
  EXPECT_HMICALL("UI.AddSubMenu", {})
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  EXPECT_NOTIFICATION("OnHashChange")
end


function Test:AddSubMenuIsRejected()
  local cid = self.mobileSession:SendRPC("AddSubMenu",
  {
    menuID = 12,
    menuName ="SubMenumandatoryonly2"
  })
  EXPECT_HMICALL("UI.AddSubMenu", {})
  :Do(function(_,data)
    self.hmiConnection:SendError(data.id, data.method, "REJECTED", "DD mode is active!")
  end)
  EXPECT_RESPONSE(cid, { success = false, resultCode = "REJECTED", info = "DD mode is active!"})
end
      
