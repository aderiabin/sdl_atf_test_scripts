| Id| Check | Priority | Comment |
| - | ----- | -------- | -------- |
| 1 | **New parameter `moduleInfo` in RC capabilities** | | |
| 1.1 | Parameter checks for struct `ModuleInfo` | | Each check performed on one of available RC modules |
| 1.1.1 | All correct params of `moduleInfo` | 1 | |
| 1.1.2 | Mandatory only correct params of `moduleInfo` | 2 | |
| 1.1.3 | Mandatory only incorrect params of `moduleInfo` | 2 | |
| 1.1.4 | Absent mandatory param of `moduleInfo` | 2 | |
| 1.1.5 | Mandatory params and one incorrect optional param of `moduleInfo` | 2 | |
| 1.1.6 | Inconsistent grid values of `location` and `serviceArea` | 3 | |
| 1.2 | Parameter checks for struct `Grid` | | Each check performed on one of grid based params of `moduleInfo`: `location`, `serviceArea`|
| 1.2.1 | All correct params of grid based param in `moduleInfo` | 1 | |
| 1.2.2 | Mandatory only correct params of grid based param in `moduleInfo` | 2 | |
| 1.2.3 | Mandatory only incorrect params of grid based param in `moduleInfo` | 2 | |
| 1.2.4 | Absent mandatory param of grid based param in `moduleInfo` | 2 | |
| 1.2.5 | Mandatory params and one incorrect optional param of grid based param in `moduleInfo` | 2 | |
| 1.3 | Presence of new parameter `moduleInfo` in existing RC capabilities | | |
| 1.3.1 | Parameter `moduleInfo` in `ClimateControlCapabilities` through GetSystemCapability RPC | 1 | |
| 1.3.2 | Parameter `moduleInfo` in `RadioControlCapabilities` through GetSystemCapability RPC | 1 | |
| 1.3.3 | Parameter `moduleInfo` in `ButtonCapabilities` through GetSystemCapability RPC | 1 | |
| 1.3.4 | Parameter `moduleInfo` in `SeatControlCapabilities` through GetSystemCapability RPC | 1 | |
| 1.3.5 | Parameter `moduleInfo` in `AudioControlCapabilities` through GetSystemCapability RPC | 1 | |
| 1.3.6 | Parameter `moduleInfo` in `HMISettingsControlCapabilities` through GetSystemCapability RPC | 1 | |
| 1.3.7 | Parameter `moduleInfo` in `LightControlCapabilities` through GetSystemCapability RPC | 1 | |
| 2 | **Multiple modules per module type in RC capabilities** | | |
| 2.1 | One module per module type in GetSystemCapability RPC | 1 | |
| 2.2 | Multiple modules with different parameters in `moduleInfo` per a module type in GetSystemCapability RPC | 1 | |
| 2.3 | Multiple modules with same parameters in `moduleInfo` per a module type in GetSystemCapability RPC | 2 | |
| 2.4 | Multiple module types which contain modules with the same `moduleId` in GetSystemCapability RPC | 2 | |
| 3 | **New capability `SeatLocationCapability` in system capabilities** | | |
| 3.1 | Presence of new parameter `seatLocationCapability` in SystemCapability | 1 | |
| 3.2 | Parameter checks for `seatLocationCapability` | | |
| 3.2.1 | Parameter checks for `rows` | 3 | |
| 3.2.2 | Parameter checks for `columns` | 3 | |
| 3.2.3 | Parameter checks for `levels` | 3 | |
| 3.2.4 | Parameter checks for `seats` | | |
| 3.2.4.1 | Common checks for array-parameter | 3 | |
| 3.2.4.2 | Array parameter contains element with absent 'grid' only | 3 | |
| 3.2.4.3 | Array parameter contains element with absent 'grid' and other elements | 3 | |
| 4 | **Receive updates for capabilities with OnSystemCapabilityUpdated notification** | | |
| 4.1 | Receive updates for RC capabilities | 1 |Can not be tested. It is impossible to trigger SDL to send this notification for RC capability |
| 4.2 | Receive updates for SeatLocation capabilities | 1 |Can not be tested. It is impossible to trigger SDL to send this notification for SeatLocation capability |
| 5 | **RC data related RPCs functionality with new parameter `moduleId`** | | |
| 5.1 | GetInteriorVehicleData RPC with new parameter `moduleId` | | Each check performed on one of available RC modules |
| 5.1.1 | GetInteriorVehicleData RPC with param `moduleId` exists and correct | 1 | |
| 5.1.2 | GetInteriorVehicleData RPC with param `moduleId` exists and incorrect by capabilities | | |
| 5.1.2.1 | Module with `moduleId` does not exist in capabilities | 3 | |
| 5.1.2.2 | Module with `moduleId` exists but it does not match with <module>ControlData | 4 | |
| 5.1.3 | GetInteriorVehicleData RPC with param `moduleId` exists and incorrect by other reason (type, empty, nil, array) | 4 | |
| 5.1.4 | GetInteriorVehicleData RPC without param `moduleId` | | |
| 5.1.4.1 | One module for module type [existing test] | 2 | |
| 5.1.4.2 | Multiple modules for module type | 2 | |
| 5.2 | SetInteriorVehicleData RPC with new parameter `moduleId` | | Each check performed on one of available RC modules |
| 5.2.1 | SetInteriorVehicleData RPC with param `moduleId` exists and correct | 1 | |
| 5.2.2 | SetInteriorVehicleData RPC with param `moduleId` exists and incorrect by capabilities | | |
| 5.2.2.1 | Module with `moduleId` does not exist in capabilities | 4 | |
| 5.2.2.2 | Module with `moduleId` exists but it does not match with <module>ControlData | 3 | |
| 5.2.3 | SetInteriorVehicleData RPC with param `moduleId` exists and incorrect by other reason (type, empty, nil, array) | 4 | |
| 5.2.4 | SetInteriorVehicleData RPC without param `moduleId` | | |
| 5.2.4.1 | One module for module type [existing test] | 4 | |
| 5.2.4.2 | Multiple modules for module type | 4 | |
| 5.3 | ButtonPress RPC with new parameter `moduleId` | | Each check performed on one of available RC modules |
| 5.3.1 | ButtonPress RPC with param `moduleId` exists and correct | 1 | |
| 5.3.2 | ButtonPress RPC with param `moduleId` exists and incorrect by capabilities | | |
| 5.3.2.1 | Module with `moduleId` does not exist in capabilities | 4 | |
| 5.3.2.2 | Module with `moduleId` exists but it does not match with <module>ControlData | 4 | |
| 5.3.3 | ButtonPress RPC with param `moduleId` exists and incorrect by other reason (type, empty, nil, array) | 3 | |
| 5.3.4 | ButtonPress RPC without param `moduleId` | | |
| 5.3.4.1 | One module for module type [existing test] | 4 | |
| 5.3.4.2 | Multiple modules for module type | 4 | |
| 5.4 | Deprecation of `id` parameter in `SeatControlData` | | |
| 5.4.1 | GetInteriorVehicleData RPC | | |
| 5.4.1.1 | GetInteriorVehicleData RPC request contains mandatory parameter `id` and does not contain mandatory parameter `moduleId` | 2 | |
| 5.4.1.2 | GetInteriorVehicleData RPC request does not contain mandatory parameter `id` and contains mandatory parameter `moduleId` | 1 | |
| 5.4.1.3 | GetInteriorVehicleData RPC request contains correct mandatory parameter `id` and contains correct mandatory parameter `moduleId` | 4 | |
| 5.4.1.4 | GetInteriorVehicleData RPC request contains incorrect mandatory parameter `id` and contains correct mandatory parameter `moduleId` | 4 | |
| 5.4.1.5 | GetInteriorVehicleData RPC request contains correct mandatory parameter `id` and contains incorrect mandatory parameter `moduleId` | 3 | |
| 5.4.2 | SetInteriorVehicleData RPC | | |
| 5.4.2.1 | SetInteriorVehicleData RPC request contains mandatory parameter `id` and does not contain mandatory parameter `moduleId` | 4 | |
| 5.4.2.2 | SetInteriorVehicleData RPC request does not contain mandatory parameter `id` and contains mandatory parameter `moduleId` | 4 | |
| 5.4.2.3 | SetInteriorVehicleData RPC request contains correct mandatory parameter `id` and contains correct mandatory parameter `moduleId` | 2 | |
| 5.4.2.4 | SetInteriorVehicleData RPC request contains incorrect mandatory parameter `id` and contains correct mandatory parameter `moduleId` | 4 | |
| 5.4.2.5 | SetInteriorVehicleData RPC request contains correct mandatory parameter `id` and contains incorrect mandatory parameter `moduleId` | 4 | |
| 5.4.3 | ButtonPress RPC | | |
| 5.4.3.1 | ButtonPress RPC request contains mandatory parameter `id` and does not contain mandatory parameter `moduleId` | 4 | |
| 5.4.3.2 | ButtonPress RPC request does not contain mandatory parameter `id` and contains mandatory parameter `moduleId` | 4 | |
| 5.4.3.3 | ButtonPress RPC request contains correct mandatory parameter `id` and contains correct mandatory parameter `moduleId`| 4 | |
| 5.4.3.4 | ButtonPress RPC request contains incorrect mandatory parameter `id` and contains correct mandatory parameter `moduleId` | 3 | |
| 5.4.3.5 | ButtonPress RPC request contains correct mandatory parameter `id` and contains incorrect mandatory parameter `moduleId` | 4 | |
| 6 | **RC data related notifications with new parameter `moduleId`** | | |
| 6.1 | Subscription to data of RC module on base of pair of parameters `moduleType` and `moduleId` | | Each check performed on one of available RC modules |
| 6.1.1 | Subscription to data of RC module defined by pair of parameters `moduleType` and `moduleId` | 1 | |
| 6.1.2 | Subscription to data of default RC module defined by parameter `moduleType` only | 2 | |
| 6.2 | Unsubscription from data of RC module on base of pair of parameters `moduleType` and `moduleId` | | Each check performed on one of available RC modules |
| 6.2.1 | Unsubscription to data of RC module defined by pair of parameters `moduleType` and `moduleId` | 1 | |
| 6.2.2 | Unsubscription to data of default RC module defined by parameter `moduleType` only | 3 | |
| 6.3 | Does not performing of subscription to data of RC module if parameter `subscribe` is absent | 4 | |
| 6.4 | Receiving updates with RC module data via OnInteriorVehicleData by subscribed applications | 1 | |
| 7 | **RC modules allocation on base of `ModuleInfo`** | | |
| 7.1 | RC module allocation on base of pair of parameters `moduleType` and `moduleId` | | Each check performed on one of available RC modules. Each check performed on one of module allocation RPCs (SetInteriorVehicleData, ButtonPress, ?GetInteriorVehicleDataConsent) |
| 7.1.1 | RC module (`ModuleInfo.allowMultipleAccess` = false) allocation | 1 | |
| 7.1.1.1 | RC mode is AUTO_ALLOW | | |
| 7.1.1.1.1 | RC module has `ModuleInfo.serviceArea` | | |
| 7.1.1.1.1.1 | User location is within `ModuleInfo.serviceArea` of RC module | | It is impossible to check: allocation RPCs do not provide user location information |
| 7.1.1.1.1.2 | User location is not within `ModuleInfo.serviceArea` of RC module | | It is impossible to check: allocation RPCs do not provide user location information |
| 7.1.1.1.2 | RC module has no `ModuleInfo.serviceArea` (default same as ModuleInfo.location) | | Contains the same child checks as 7.1.1.1.1 |
| 7.1.1.1.3 | RC module has no `ModuleInfo.serviceArea` and no `ModuleInfo.location` | | Contains the same child checks as 7.1.1.1.1  |
| 7.1.1.2 | RC mode is AUTO_DENY | | Contains the same child checks as 7.1.1.1 |
| 7.1.1.3 | RC mode is ASK_DRIVER | | Contains the same child checks as 7.1.1.1 |
| 7.1.1.3.4 | GetInteriorVehicleDataConsent (SDL->HMI) with new parameters `moduleIds` and `userLocation` | | It is impossible to check: it is impossible to trigger SDL to send this RPC with `userLocation` parameter |
| 7.1.1.3.4.1 | GetInteriorVehicleDataConsent (SDL->HMI) with `moduleIds` if allocation RPC does not contain 'moduleIds' | | |
| 7.1.2 | RC module (`ModuleInfo.allowMultipleAccess` = true) allocation | 1 | Contains the same child checks as 7.1.1 |
| 7.1.3 | RC module (`ModuleInfo.allowMultipleAccess` is default (true)) allocation | 2 | Contains the same child checks as 7.1.1 |
| 7.2 | RC module allocation on base of parameter `moduleType` only | 2 | Contains the same child checks as 7.1|
| 7.3 | RC module allocation to applications in different HMI levels | 3 | |
| 7.4 | Notification on RC module allocation | | |
| 7.4.1 | Notification `OnRCStatus` always contains new parameter `moduleId` for each module in parameter `allocatedModules` | 1 | |
| 7.4.2 | Notification `OnRCStatus` always contains new parameter `moduleId` for each module in parameter `freeModules` | 1 | |
| 7.5 | New RPC `ReleaseInteriorVehicleDataModule` for RC module allocation | | Each check performed on one of available RC modules |
| 7.5.1 | Parameters checks for RPC `ReleaseInteriorVehicleDataModule` | 2 | |
| 7.5.1.1| Parameter checks for `moduleType` | | |
| 7.5.1.2| Parameter checks for `moduleId` | | |
| 7.5.2 | Sequences checks for RPC `ReleaseInteriorVehicleDataModule` | | |
| 7.5.2.1| RPC `ReleaseInteriorVehicleDataModule` processing with all correct parameters | | |
| 7.5.2.1.1| RC module is allocated to current application | 1 | |
| 7.5.2.1.2| RC module is allocated to other application | 2 | |
| 7.5.2.1.3| RC module is free | 2 | |
| 7.5.2.2| RPC `ReleaseInteriorVehicleDataModule` processing without `moduleId` | 2 | |
| 7.5.2.3| RPC `ReleaseInteriorVehicleDataModule` processing with inconsistent values of `moduleType` and `moduleIds` parameters | 3 | |
| 7.6 | New RPC `GetInteriorVehicleDataConsent` (MOB->SDL) | | Each check performed on one of available RC modules |
| 7.6.1 | Parameters checks for RPC `GetInteriorVehicleDataConsent` | 2 | |
| 7.6.1.1| Parameter checks for `moduleType` | | |
| 7.6.1.2| Parameter checks for `moduleIds` | | |
| 7.6.1.3| Parameter checks for `userLocation` | | |
| 7.6.1.3.1| Value with absent `grid` | | |
| 7.6.2 | Sequences checks for RPC `GetInteriorVehicleDataConsent` |  | |
| 7.6.2.1| RPC `GetInteriorVehicleDataConsent` processing with all correct parameters | 1 | |
| 7.6.2.1.1| Check equality of length of arrays of `moduleIds` in request and `allowed` in response | | |
| 7.6.2.2| RPC `GetInteriorVehicleDataConsent` processing without `moduleId` | 2 | |
| 7.6.2.2.1| Check equality of length of arrays of `moduleIds` in request and `allowed` in response | | |
| 7.6.2.3| RPC `GetInteriorVehicleDataConsent` processing with inconsistent values of `moduleType` and `moduleIds` parameters | 3 | |
| 7.6.2.4| RPC `GetInteriorVehicleDataConsent` processing without `userLocation` | 3 | |
| 7.6.2.5| RPC `GetInteriorVehicleDataConsent` processing with `userLocation` value inconsistent with `SeatLocationCapability` capabilities | 3 | |
| 7.7 | New parameter `userLocation` in `SetGlobalProperties` RPC (MOB->SDL) | | |
| 7.7.1 | All correct params | 1 | |
| 7.7.2 | Incorrect params present | 3 | |
| 7.8.| Multiple realocations of RC modules | 3 | |
| 8 | **Caching functionality for RC on base of pair of parameters `moduleType` and `moduleId`** | | |
| 8.1 | Caching of RC capabilities | 2 | Each check performed for each of available RC modules |
| 8.2 | Caching of RC modules data | 2 | Each check performed for each of available RC modules |
| 8.3 | Caching of driver decisions for RC modules allocation |  | Each check performed for each of available RC modules |
| 8.3.1 | Storing of driver decisions for RC modules allocation into cache | | |
| 8.3.1.1 | Normal use of cached driver decisions for RC modules allocation | 2 | |
| 8.3.1.2 | Use of cached driver decisions for RC modules allocation in different ignition cycles | 3 | |
| 8.3.1.3 | Use of cached driver decisions for RC modules allocation in different RC modes | 3 | |
| 8.3.2 | Removing of driver decisions for RC modules allocation from cahe | 2 | |
| 8.3.2.1 | On cache expired (30 days) | | |
| 8.3.2.2 | On RC disable | | |
| 9 | **Not RC related RPCs which use ButtonCapabilities with new parameter `moduleInfo`** | | |
| 9.1 | Using of new parameter `moduleInfo` in `RegisterAppInterface` RPC response | 4 | |
| 9.2 | Using of new parameter `moduleInfo` in `SetDisplayLayout` RPC response | 4 | |
