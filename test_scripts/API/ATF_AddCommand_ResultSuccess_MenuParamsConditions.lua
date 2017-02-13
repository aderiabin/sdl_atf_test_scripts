--Requirements: APPLINK-31632 Success result for positive request check

--Description:
--In case the request comes to SDL when the command has only MenuParams definitions
--and no VR command definitions, the command should be added only to UI Commands Menu/SubMenu.
--All parameters are in boundary conditions
--SDL must respond with resultCode "Success" and success:"true" value.

-- Preconditons:
-- 1. Mobile application is registered and activated on HMI

-- Performed steps:
-- 1. Application sends "AddCommand" request which contains such parameters: cmdId, menuParams
-- for the first case and only cmdId and menuName from menuParams for another case

-- Expected result:
-- 1. SDL responds with resultCode:"Success" and success: "true" value

-- -------------------------------------------Required Resources-------------------------------

require('user_modules/all_common_modules')

-- -------------------------------------------Preconditions-------------------------------------

common_steps:PreconditionSteps("Preconditions",7)

-- -----------------------------------------------Body-------------------------------------------

function AddCommand_MenuParamsOnly()
  --mobile side: sending AddCommand request
  for i = 1, 2 do
    local cid_parameters =
    {
      cmdID = i,
      menuParams =
      {
        parentID = 0,
        position = i,
        menuName = table.concat({"Command", i})
      }
    }

    if i == 1 then
      full_name = "MenuParamsOnly"
    end

    if i == 2 then
      full_name = "MenuParamsWithoutConditional"
      parentID = nil
      position = nil
    end

    local functionName = "AddCommand_" .. full_name
    Test[functionName] = function(self)

      local cid = self.mobileSession:SendRPC("AddCommand",cid_parameters)

      EXPECT_HMICALL("UI.AddCommand", cid_parameters)
      :Do(function(_,data)
          --hmi side: sending UI.AddCommand response
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        end)

      --mobile side: expect AddCommand response
      EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })

      --mobile side: expect OnHashChange notification
      EXPECT_NOTIFICATION("OnHashChange")
    end
  end
end
AddCommand_MenuParamsOnly()
-- -------------------------------------------Postcondition-------------------------------------

common_steps:StopSDL("StopSDL")
