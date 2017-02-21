-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

------------------------------------ Common Variables ---------------------------------------
local app_storage_folder = common_functions:GetValueFromIniFile"AppStorageFolder"
local storagePath = config.pathToSDL .. app_storage_folder .. "/"
..config.application1.registerAppInterfaceParams.appID.. "_" .. config.deviceMAC.. "/"
local appName = config.application1.registerAppInterfaceParams.appName

-------------------------------------------Preconditions-------------------------------------
-- Register App -> Activate App
common_steps:PreconditionSteps("PreconditionSteps", 7)

--------------------------------------------BODY---------------------------------------------
-- Verify: when all params are correct and all images do not exist
-- SDL->MOB: RPC (success:false, resultCode:"WARNINGS", info:"Reference image(s) not found")
---------------------------------------------------------------------------------------------
function Test:createUIParameters(Request)
  local param = {}
  param["alignment"] = Request["alignment"]
  param["customPresets"] = Request["customPresets"]

  --Convert showStrings parameter
  local j = 0
  for i = 1, 4 do
    if Request["mainField" .. i] ~= nil then
      j = j + 1
      if param["showStrings"] == nil then
        param["showStrings"] = {}
      end
      param["showStrings"][j] = {
        fieldName = "mainField" .. i,
        fieldText = Request["mainField" .. i]
      }
    end
  end

  if Request["mediaClock"] ~= nil then
    j = j + 1
    if param["showStrings"] == nil then
      param["showStrings"] = {}
    end
    param["showStrings"][j] = {
      fieldName = "mediaClock",
      fieldText = Request["mediaClock"]
    }
  end

  if Request["mediaTrack"] ~= nil then
    j = j + 1
    if param["showStrings"] == nil then
      param["showStrings"] = {}
    end
    param["showStrings"][j] = {
      fieldName = "mediaTrack",
      fieldText = Request["mediaTrack"]
    }
  end

  if Request["statusBar"] ~= nil then
    j = j + 1
    if param["showStrings"] == nil then
      param["showStrings"] = {}
    end
    param["showStrings"][j] = {
      fieldName = "statusBar",
      fieldText = Request["statusBar"]
    }
  end

  param["graphic"] = Request["graphic"]
  if param["graphic"] ~= nil and
  param["graphic"].imageType ~= "STATIC" and
  param["graphic"].value ~= nil and
  param["graphic"].value ~= "" then
    param["graphic"].value = param["graphic"].value
  end

  param["secondaryGraphic"] = Request["secondaryGraphic"]
  if param["secondaryGraphic"] ~= nil and
  param["secondaryGraphic"].imageType ~= "STATIC" and
  param["secondaryGraphic"].value ~= nil and
  param["secondaryGraphic"].value ~= "" then
    param["secondaryGraphic"].value = param["secondaryGraphic"].value
  end

  if Request["softButtons"] ~= nil then
    param["softButtons"] = Request["softButtons"]
    for i = 1, #param["softButtons"] do
      if param["softButtons"][i].type == "TEXT" then
        param["softButtons"][i].image = nil

      elseif param["softButtons"][i].type == "IMAGE" then
        param["softButtons"][i].text = nil
      end
      if param["softButtons"][i].image ~= nil and
      param["softButtons"][i].image.imageType ~= "STATIC" then
        param["softButtons"][i].image.value = param["softButtons"][i].image.value
      end

    end
  end
  return param
end

function Test:Verify_AllParamsCorrect_ImageNotExist_WARNINGS()
  local request_params =
  {
    mainField1 = "a",
    mainField2 = "a",
    mainField3 = "a",
    mainField4 = "a",
    statusBar= "a",
    mediaClock = "a",
    mediaTrack = "a",
    alignment = "CENTERED",
    graphic =
    {
      imageType = "DYNAMIC",
      value = "invalidImage.png"
    },
    secondaryGraphic =
    {
      imageType = "DYNAMIC",
      value = "invalidImage.png"
    },
    softButtons =
    {
      {
        type = "BOTH",
        text = "Close",
        image =
        {
          value = "invalidImage.png",
          imageType = "DYNAMIC"
        },
        isHighlighted = true,
        softButtonID = 3,
        systemAction = "DEFAULT_ACTION"
      }
    }
  }
  local cid = self.mobileSession:SendRPC("Show", request_params)
  UIParams = self:createUIParameters(request_params)
  EXPECT_HMICALL("UI.Show", UIParams)
  :Do(function(_,data)
      self.hmiConnection:SendError(data.id, data.method, "WARNINGS","Reference image(s) not found")
    end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", info = "Reference image(s) not found"})
end

-------------------------------------------Postconditions-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegisterApp", appName)
common_steps:StopSDL("Postcondition_StopSDL")
