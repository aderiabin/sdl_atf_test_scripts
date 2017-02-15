--Requirements: APPLINK-14765

--Description:
--In case the request comes to SDL when the command has all correct parameters
--and extra parameters: ttsChunks from another request and fakeParams, which not
--from Protocol. The command should be added to UI Commands Menu and to VR menu.
--All parameters are in boundary conditions. SDL should ignore extra ttsChunks
--and fake params. SDL must respond with resultCode "Success" and success:"true"
--value.

-- Performed steps
-- 1. Application sends "AddCommand" request which contains all possible input parameters
-- and extra ttsChunks and fake params
-- 2. Validation the image type and the path to image
-- 3. Validation that SDL ignore ttsChunks and fake params in UI menu and in Vr menu

-- Expected result:
-- 1. SDL responds with resultCode:"Success" and success: "true" value and ignoring extra params

-- -------------------------------------------Required Resources-------------------------------

require('user_modules/all_common_modules')

-- -------------------------------------------Common Variables----------------------------------

local image_file_name = "icon.png"

-- -------------------------------------------Preconditions-------------------------------------

common_steps:PreconditionSteps("Preconditions",7)
common_steps:PutFile("PutFile", image_file_name)
common_functions:CheckSdlPath()

-- ------------------------------------------Body-----------------------------------------------
function Test:AddCommand_AdditionalFakeParams_And_ParamsFromAnotherRequest()
  local cid = self.mobileSession:SendRPC("AddCommand",
    {
      cmdID = 3200,
      fakeParam ="fakeParam",
      menuParams =
      {
        parentID = 0,
        position = 0,
        menuName ="fakeparam",
        fakeParam ="fakeParam"
      },
      vrCommands =
      {
        "VrMenu3200"
      },
      cmdIcon =
      {
        value ="icon.png",
        imageType ="DYNAMIC",
        fakeParam ="fakeParam"
      },
      ttsChunks =
      {
        TTSChunk =
        {
          text ="SpeakFirst",
          type ="TEXT",
        },
        TTSChunk =
        {
          text ="SpeakSecond",
          type ="TEXT",
        },
      },
    })
  EXPECT_HMICALL("UI.AddCommand",
    {
      cmdID = 3200,

      menuParams =
      {
        parentID = 0,
        position = 0,
        menuName ="fakeparam"
      }
    })
  :ValidIf(function(_, data)
      local full_path_icon = common_functions:GetFullPathIcon(image_file_name)

      if data.params.cmdIcon.value ~= full_path_icon then
        local color = 31
        local msg = "value of menuIcon is WRONG. Expected: ".. full_path_icon.. "; Real: " .. data.params.cmdIcon.value
        common_functions:UserPrint(color, msg)
        return false
      end

      if not (data.params.cmdIcon.imageType == "DYNAMIC") then
        local color = 31
        local msg = "imageType of menuIcon is WRONG. Expected: DYNAMIC; Real: " .. data.params.cmdIcon.imageType
        common_functions:UserPrint(color, msg)
        return false
      end
      return true
    end)
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :ValidIf(function(_,data)
      local result = true

      if data.params.ttsChunks then
        print(" SDL re-sends ttsChunks parameters to HMI in UI.AddCommand request")
        result = false
      end
      if data.params.fakeParam then
        print(" SDL re-sends fakeParam from parameters to HMI in UI.AddCommand request")
        result = false
      end
      if data.params.menuParams.fakeParam then
        print(" SDL re-sends fakeParam from menuParams to HMI in UI.AddCommand request")
        result = false
      end
      if data.params.cmdIcon.fakeParam then
        print(" SDL re-sends fakeParam from cmdIcon to HMI in UI.AddCommand request")
        result = false
      end

      return result

    end)
  EXPECT_HMICALL("VR.AddCommand",
    {
      cmdID = 3200,
      type = "Command",
      vrCommands =
      {
        "VrMenu3200"
      }
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :ValidIf(function(_,data)
      local result = true
      if data.params.ttsChunks then
        print(" SDL re-sends ttsChunks to HMI in VR.AddCommand request")
        result = false
      end
      if data.params.fakeParam then
        print(" SDL re-sends fakeParam parameters to HMI in VR.AddCommand request")
        result = false
      end

      return result

    end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  EXPECT_NOTIFICATION("OnHashChange")
end
-- -------------------------------------------Postcondition-------------------------------------

common_steps:StopSDL("StopSDL")
