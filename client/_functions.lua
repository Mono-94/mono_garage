local ox = exports.ox_inventory
if Garages.VehicleEntitys.densitiy then
    local SetVehicleDensityMultiplier = Garages.VehicleEntitys.SetVehicleDensityMultiplier
    local SetRandomVehicleDensityMultiplier = Garages.VehicleEntitys.SetRandomVehicleDensityMultiplier
    local SetParkedVehicleDensityMultiplier = Garages.VehicleEntitys.SetParkedVehicleDensityMultiplier
    Citizen.CreateThread(function()
        while true do
            SetVehicleDensityMultiplierThisFrame(SetVehicleDensityMultiplier)
            SetRandomVehicleDensityMultiplierThisFrame(SetRandomVehicleDensityMultiplier)
            SetParkedVehicleDensityMultiplierThisFrame(SetParkedVehicleDensityMultiplier)
            Citizen.Wait(0)
        end
    end)
end

-- Get Vehicle type
---@param vehicle any
---@return unknown
function GetVehicleCategory(vehicle)
    local Category = {}
    local function GetClase()
        local clase = GetVehicleClass(vehicle)
        return clase
    end

    for categoria, clase in pairs(Garages.VehicleCategories) do
        for _, class in pairs(clase) do
            Category[class] = categoria
        end
    end

    return Category[GetClase()]
end

-- Create NPC
function CreateNPC(hash, coords)
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(1)
    end
    local entity = CreatePed(2, hash, coords, false, false)
    SetPedFleeAttributes(entity, 0, 0)
    SetPedDiesWhenInjured(entity, false)
    TaskStartScenarioInPlace(entity, "missheistdockssetup1clipboard@base", 0, true)
    SetPedKeepTask(entity, true)
    SetBlockingOfNonTemporaryEvents(entity, true)
    SetEntityInvincible(entity, true)
    FreezeEntityPosition(entity, true)
    return entity
end

---Create Blip
function CreateBlip(pos, sprite, scale, colorblip, blipName)
    local entity = AddBlipForCoord(pos)
    SetBlipSprite(entity, sprite)
    SetBlipDisplay(entity, 4)
    SetBlipScale(entity, scale)
    SetBlipColour(entity, colorblip)
    SetBlipAsShortRange(entity, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(blipName)
    EndTextCommandSetBlipName(entity)
    return entity
end

AddStateBagChangeHandler('SetProperties', nil, function(bagName, key, value, _unused, replicated)
    if not value then return end

    local entity = GetEntityFromStateBagName(bagName)

    if NetworkGetEntityOwner(entity) ~= PlayerId() then return end

    lib.setVehicleProperties(entity, value)

    SetVehicleEngineOn(entity, false, false, true)

    FuelLevel(entity, value.fuelLevel)

    Entity(entity).state:set('SetProperties', nil, true)
end)

AddStateBagChangeHandler('FadeEntity', nil, function(bagName, key, value, _unused, replicated)
    if not value then return end

    local entity = GetEntityFromStateBagName(bagName)

    if NetworkGetEntityOwner(entity) ~= PlayerId() then return end

    value.entity = entity

    DeleteVehicleEntity(value)

    Entity(entity).state:set('FadeEntity', nil, true)
end)

AddStateBagChangeHandler('VehicleDoors', nil, function(bagName, key, value, _unused, replicated)
    if not value then return end

    local entity = GetEntityFromStateBagName(bagName)

    if NetworkGetEntityOwner(entity) ~= PlayerId() then return end

    SetVehicleDoorsLocked(entity, value)

    Entity(entity).state:set('VehicleDoors', nil, true)
end)

---FadeInFadeOutEntity
function DeleteVehicleEntity(data)
    if data.action == 'spawn' then
        NetworkFadeInEntity(data.entity, true)
    elseif data.action == 'delete' then
        NetworkFadeOutEntity(data.entity, true, true)
        Citizen.Wait(1500)
        DeleteEntity(data.entity)
    end
end

-- Export InventoryKeys
function ClientInventoryKeys(action, plate)
    lib.callback('mono_garage:InventoryKeys', nil, source, action, plate)
end

exports('ClientInventoryKeys', ClientInventoryKeys)

---Get Player Inventory Key
function GetPlayerKey(vehicle)
    local Ped = PlayerPedId()
    local coords = GetEntityCoords(Ped)
    local inAcar = IsPedInAnyVehicle(Ped, true)
    local entity = vehicle or lib.getClosestVehicle(coords, Garages.CarKeys.CarKeyDistance, true)
    local plate = GetVehicleNumberPlateText(entity)
    if Garages.inventory == 'ox' then
        local keys = ox:Search('slots', Garages.Items.carkeys)
        for i, v in ipairs(keys) do
            if PlateEqual(v.metadata.plate, plate) then
                return true, entity, inAcar, Ped
            end
        end
    elseif Garages.inventory == 'qs' then
        local items = exports['qs-inventory']:getUserInventory()
        for item, meta in pairs(items) do
            if PlateEqual(meta.info.plate, plate) then
                return true, entity, inAcar, Ped
            end
        end
    end
    return false, entity, inAcar, Ped
end

exports('GetPlayerKey', GetPlayerKey)

function VehicleDoors()
    local haveKey, entity, inCar, ped = GetPlayerKey()

    if not haveKey or not DoesEntityExist(entity) then return end

    local nameCar = GetDisplayNameFromVehicleModel(GetEntityModel(entity))
    local markCar = GetMakeNameFromVehicleModel(GetEntityModel(entity))
    local marca = CapitalizeFirstLetter(nameCar .. ' - ' .. markCar)

    lib.callback('mono_garage:CarDoors', Garages.CarKeys.CarKeyDelay, function(success)
        if success then
            local doorLockStatus = GetVehicleDoorLockStatus(entity)

            Entity(entity).state.VehicleDoors = doorLockStatus == 2 and 0 or 2
            PlayVehicleDoorCloseSound(entity, 1)
            local soundEvent = doorLockStatus == 2 and "Remote_Control_Close" or "Remote_Control_Fob"
            PlaySoundFromEntity(-1, soundEvent, entity, "PI_Menu_Sounds", 1, 0)

            local notificationText = doorLockStatus == 2 and Text('VehicleOpen') or Text('VehicleClose')
            local notificationColor = doorLockStatus == 2 and '#64cc69' or '#cc6493'
            Notifi({
                title = marca,
                text = notificationText,
                icon = doorLockStatus == 2 and 'lock-open' or 'lock',
                color =
                    notificationColor
            })

            if not inCar then
                AnimKeys(ped)
            end

            for _ = 1, 2 do
                SetVehicleLights(entity, 2)
                Citizen.Wait(250)
                SetVehicleLights(entity, 0)
                Citizen.Wait(250)
            end
        end
    end, Garages.CarKeys.isItem, VehToNet(entity))
end

function AnimKeys(ped)
    RequestModel('p_car_keys_01')

    while not HasModelLoaded('p_car_keys_01') do Wait(1) end

    local prop = CreateObject('p_car_keys_01', 1.0, 1.0, 1.0, 1, 1, 0)
    RequestAnimDict("anim@mp_player_intmenu@key_fob@")
    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 57005), 0.08, 0.039, 0.0, 0.0, 0.0, 0.0, true, true, false, true,
        1, true)
    TaskPlayAnim(ped, "anim@mp_player_intmenu@key_fob@", "fob_click_fp", 8.0, 8.0, -1, 48, 1, false, false, false)
    Citizen.Wait(1000)
    DeleteObject(prop)
end

lib.addKeybind({
    name = 'mono_garage_keys',
    description = Text('DoorsVehicleKeyBind'),
    defaultKey = Garages.Buttons.carkeys,
    onPressed = function()
        VehicleDoors()
    end
})


lib.callback.register('mono_garage:DelVehicleByPlate', function(plate)
    local alert = lib.alertDialog({
        header = Text('CommandDelPlate6', plate),
        content = Text('CommandDelPlate5', plate),
        centered = true,
        cancel = true
    })
    if alert == 'confirm' then
        local progressBarResult = lib.progressBar({
            duration = 1000,
            label = Text('CommandDelPlate7', plate),
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = true
            },
        })
        if progressBarResult then return true else return false end
    else
        return false
    end
end)


lib.callback.register('mono_garage:ClosetVehicles', function(radius)
    local ped = cache.ped
    local vehicle = lib.getClosestVehicle(GetEntityCoords(ped), radius, true)
    if DoesEntityExist(vehicle) then
        return VehToNet(vehicle), vehicle
    end
end)


lib.callback.register('mono_garage:FakePlate', function(data)
    local animDictLockPick = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
    local animLockPick = "machinic_loop_mechandplayer"

    if lib.progressBar({
            duration = 5000,
            label = Text('FakePlate4'),
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = true,
            },
            anim = {
                dict = animDictLockPick,
                clip = animLockPick,
                flag = 1,

            },
            prop = {
                model = 'p_num_plate_01',
                pos = vec3(0.0, 0.2, 0.1),
                rot = vec3(100, 100.0, 0.0)
            },
        }) then
        return { success = true }
    else
        return { success = false }
    end
end)

local LockPicked = {}

lib.callback.register('mono_garage:LockPick', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local entity = lib.getClosestVehicle(coords, 3, true)
    local animDictLockPick = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
    local animLockPick = "machinic_loop_mechandplayer"
    local status = GetVehicleDoorLockStatus(entity)
    local ped = cache.ped
    local plate = GetVehicleNumberPlateText(entity)
    lib.requestAnimDict(animDictLockPick)
    if entity then
        if status == 2 then
            TaskPlayAnim(ped, animDictLockPick, animLockPick, 8.0, 8.0, -1, 48, 1,
                false, false, false)
            local success = lib.skillCheck(table.unpack(Garages.LockPickAndHotWire.LockPickSkillCheck))
            if success then
                if math.random() < Garages.LockPickAndHotWire.LockPickAlarmAndDispatchProbablity and not LockPicked[plate] then
                    SetVehicleAlarmTimeLeft(entity, true)
                    Citizen.Wait(100)
                    LockPickDispatchFunction(cache.serverId, cache.coords, cache.ped, entity)
                end
                LockPicked[plate] = true
                Notifi({ text = Text('VehicleOpen') })
                Entity(entity).state.VehicleDoors = 0
                ClearPedTasks(ped)
                SetVehicleEngineOn(entity, false, true, true)
            else
                Notifi({ text = Text('FailThief') })
                ClearPedTasks(ped)
            end
        elseif status == 0 or 1 then
            TaskPlayAnim(ped, animDictLockPick, animLockPick, 8.0, 8.0, -1, 48, 1,
                false, false, false)
            local success = lib.skillCheck(table.unpack(Garages.LockPickAndHotWire.LockPickSkillCheck))
            if success then
                if math.random() < Garages.LockPickAndHotWire.HotWireAlarmProbablity and not LockPicked[plate] then
                    SetVehicleAlarmTimeLeft(entity, 5000)
                end
                LockPicked[plate] = true
                Notifi({ text = Text('VehicleClose') })
                ClearPedTasks(ped)
                Entity(entity).state.VehicleDoors = 2
            else
                Notifi({ text = Text('FailThief') })
                ClearPedTasks(ped)
            end
        end
    end
end)

local animDicHotWire = "veh@std@ds@base"
local animHotWire = "hotwire"

lib.callback.register('mono_garage:HotWire', function(netId, isEngineRunning)
    local ped = cache.ped
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    lib.requestAnimDict(animDicHotWire)
    TaskPlayAnim(ped, animDicHotWire, animHotWire, 8.0, 8.0, -1, 48, 1, false, false, false)
    local success = lib.skillCheck(table.unpack(Garages.LockPickAndHotWire.HotWireSkillCheck))
    if success then
        if isEngineRunning then
            SetVehicleEngineOn(vehicle, false, true, true)
            ClearPedTasks(ped)
            return Text('VehicleHotWire3', success)
        else
            SetVehicleEngineOn(vehicle, true, true, true)
            ClearPedTasks(ped)
            return Text('VehicleHotWire2', success)
        end
    else
        ClearPedTasks(ped)
        Notifi({ text = Text('FailThief') })
        return 'fail'
    end
end)


if Garages.CarKeys.engine and Garages.CarKeys.isItem then
    -- toggleEngine
    local delayEngine = false
    lib.addKeybind({
        name = 'mono_garage_engine',
        description = Text('EngineKeyBind'),
        defaultKey = Garages.Buttons.engine,
        onPressed = function()
            local haveKey, vehicle, inCar, ped = GetPlayerKey()
            if not haveKey then return end
            if delayEngine then return end
            local nameCar = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
            local markCar = GetMakeNameFromVehicleModel(GetEntityModel(vehicle))
            local marca = CapitalizeFirstLetter(nameCar .. ' - ' .. markCar)
            if GetPedInVehicleSeat(vehicle, -1) == ped then
                if GetIsVehicleEngineRunning(vehicle) then
                    SetVehicleEngineOn(vehicle, false, true, true)
                    Notifi({ title = marca, text = Text('EngineOff'), icon = 'bolt', color = '#63591f' })
                else
                    SetVehicleEngineOn(vehicle, true, true, true)
                    Notifi({ title = marca, text = Text('EngineOn'), icon = 'bolt', color = '#edd54a' })
                end
                delayEngine = true
                Citizen.Wait(Garages.CarKeys.EngineStartDelay)
                delayEngine = false
            end
        end
    })

    CreateThread(function()
        while true do
            local vehicle = cache.vehicle

            if vehicle then
                local isEngineRunning = GetIsVehicleEngineRunning(vehicle)

                if isEngineRunning then
                    EnableControlAction(2, 71, true)
                else
                    SetVehicleEngineOn(vehicle, false, false, true)
                    DisableControlAction(2, 71, true)
                end
            end

            Wait(0)
        end
    end)

    local MotorOn = false
    local MotorOnExit = nil

    MotorOnExit = SetInterval(function()
        local vehicle = cache.vehicle
        if vehicle then
            if IsControlPressed(2, 75) then
                Citizen.Wait(100)
                if IsControlPressed(2, 75) then
                    Citizen.Wait(100)
                    if not MotorOn and GetIsVehicleEngineRunning(vehicle) then
                        MotorOn = true
                    end
                    if MotorOn then
                        SetVehicleEngineOn(vehicle, true, true, false)
                    end
                end
            else
                if GetIsVehicleEngineRunning(vehicle) then
                    MotorOn = true
                else
                    MotorOn = false
                end
            end
        else
            SetInterval(MotorOnExit, 500)
        end
    end, 10)
end

local TryingToEnterVehicle = nil

TryingToEnterVehicle = SetInterval(function()
    local ped = cache.ped
    local veh = GetVehiclePedIsTryingToEnter(ped)
    local lock = GetVehicleDoorLockStatus(veh)
    if DoesEntityExist(veh) then
        if lock == 2 then
            ClearPedTasks(ped)
        elseif lock == 0 then
            if GetIsVehicleEngineRunning(veh) == false then
                SetVehicleNeedsToBeHotwired(veh, false)
                SetVehicleEngineOn(veh, false, true, true)
            end
        end
        if GetIsVehicleEngineRunning(veh) == false then
            return
        end
    else
        SetInterval(TryingToEnterVehicle, 500)
    end
end, 0)



