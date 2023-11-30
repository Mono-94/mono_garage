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
RegisterCommand('pl', function()
    TriggerServerEvent('GeneratePlate')
end)

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
---@param NPCHash any
---@param NPCPos vector4
---@return number
function CreateNPC(NPCHash, NPCPos)
    RequestModel(NPCHash)
    while not HasModelLoaded(NPCHash) do
        Wait(1)
    end
    local NPC = CreatePed(2, NPCHash, NPCPos, false, false)
    SetPedFleeAttributes(NPC, 0, 0)
    SetPedDiesWhenInjured(NPC, false)
    TaskStartScenarioInPlace(NPC, "missheistdockssetup1clipboard@base", 0, true)
    SetPedKeepTask(NPC, true)
    SetBlockingOfNonTemporaryEvents(NPC, true)
    SetEntityInvincible(NPC, true)
    FreezeEntityPosition(NPC, true)
    return NPC
end

---Create Blip
---@param pos any
---@param sprite any
---@param scale any
---@param colorblip any
---@param blipName any
---@return number
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

---StateBag Set Properties
AddStateBagChangeHandler('SetProperties', nil, function(bagName, key, value, _unused, replicated)
    if not value then return end

    local entity = GetEntityFromStateBagName(bagName)

    if NetworkGetEntityOwner(entity) ~= PlayerId() then return end


    lib.setVehicleProperties(entity, value)

    SetVehicleEngineOn(entity, false, false, true)

    Entity(entity).state:set('SetProperties', nil, true)
end)

AddStateBagChangeHandler('FadeEntity', nil, function(bagName, key, value, _unused, replicated)
    if not value then return end

    local entity = GetEntityFromStateBagName(bagName)

    if NetworkGetEntityOwner(entity) ~= PlayerId() then return end

    value.entity = entity

    FadeInOut(value)

    Entity(entity).state:set('FadeEntity', nil, true)
end)

---FadeInFadeOutEntity
---@param data any
function FadeInOut(data)
    if data.action == 'spawn' then
        NetworkFadeInEntity(data.entity, true)
    elseif data.action == 'delete' then
        NetworkFadeOutEntity(data.entity, true, true)
    end
end

-- Export InventoryKeys
function ClientInventoryKeys(action, plate)
    lib.callback('mono_garage:InventoryKeys', nil, source, action, plate)
end

exports('ClientInventoryKeys', ClientInventoryKeys)

---Get Player Inventory Key
---@return boolean
function GetPlayerKey()
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local closet = lib.getClosestVehicle(coords, 5, true)
    local plate = GetVehicleNumberPlateText(closet)
    if Garages.inventory == 'ox' then
        local keys = exports.ox_inventory:Search('slots', Garages.Items.carkeys)
        for i, v in ipairs(keys) do
            if PlateEqual(v.metadata.plate, plate) then
                return true
            end
        end
    elseif Garages.inventory == 'qs' then
        local items = exports['qs-inventory']:getUserInventory()
        for item, meta in pairs(items) do
            if PlateEqual(meta.info.plate, plate) then
                return true
            end
        end
    end

    return false
end

function VehicleDoors()
    local ped = cache.ped
    local closet = lib.getClosestVehicle(GetEntityCoords(ped), 5, true)
    local inCar = IsPedInAnyVehicle(ped, true)
    local nameCar = GetDisplayNameFromVehicleModel(GetEntityModel(closet))
    local markCar = GetMakeNameFromVehicleModel(GetEntityModel(closet))
    local marca = nameCar .. ' - ' .. markCar
    if closet then
        if Garages.CarKeys.isItem then
            if not GetPlayerKey() then return end
        end

        lib.callback('mono_garage:CarDoors', 2000, function(succes)
            if DoesEntityExist(closet) then
                if GetVehicleDoorLockStatus(closet) == 2 then
                    PlayVehicleDoorCloseSound(closet, 1)
                    PlaySoundFromEntity(-1, "Remote_Control_Close", closet, "PI_Menu_Sounds", 1, 0)
                    Notifi({ title = marca, text = Text('VehicleOpen'), icon = 'lock-open', color = '#64cc69' })
                else
                    PlayVehicleDoorCloseSound(closet, 1)
                    PlaySoundFromEntity(-1, "Remote_Control_Fob", closet, "PI_Menu_Sounds", 1, 0)
                    Notifi({ title = marca, text = Text('VehicleClose'), icon = 'lock', color = '#cc6493' })
                end
                if not inCar then
                    AnimKeys(ped)
                end
                SetVehicleLights(closet, 2)
                Citizen.Wait(250)
                SetVehicleLights(closet, 0)
                Citizen.Wait(250)
                SetVehicleLights(closet, 2)
                Citizen.Wait(250)
                SetVehicleLights(closet, 0)
                Citizen.Wait(750)
            end
        end, Garages.CarKeys.isItem, VehToNet(closet))
    end
end

function AnimKeys(ped)
    RequestModel('p_car_keys_01')

    while not HasModelLoaded('p_car_keys_01') do
        Wait(1)
    end
    local prop = CreateObject('p_car_keys_01', 1.0, 1.0, 1.0, 1, 1, 0)

    RequestAnimDict("anim@mp_player_intmenu@key_fob@")

    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 57005), 0.08, 0.039, 0.0, 0.0, 0.0, 0.0,
        true, true, false, true, 1, true)
    TaskPlayAnim(ped, "anim@mp_player_intmenu@key_fob@", "fob_click_fp", 8.0, 8.0, -1, 48, 1, false,
        false, false)
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
-- toggleEngine
local delayEngine = false
lib.addKeybind({
    name = 'mono_garage_engine',
    description = Text('EngineKeyBind'),
    defaultKey = Garages.Buttons.engine,
    onPressed = function()
        if not delayEngine then
            local ped = cache.ped
            local vehicle = cache.vehicle
            local nameCar = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
            local markCar = GetMakeNameFromVehicleModel(GetEntityModel(vehicle))
            local marca = nameCar .. ' - ' .. markCar
            if GetPedInVehicleSeat(GetVehiclePedIsIn(ped), -1) == ped then
                if not GetPlayerKey() then
                    return Notifi({ text = Text('NoKeyOwner') })
                end
                if GetIsVehicleEngineRunning(vehicle) then
                    SetVehicleEngineOn(vehicle, false, true, true)
                    Notifi({ title = marca, text = Text('EngineOff'), icon = 'bolt', color = '#63591f' })
                else
                    SetVehicleEngineOn(vehicle, true, true, true)
                    Notifi({ title = marca, text = Text('EngineOn'), icon = 'bolt', color = '#edd54a' })
                end
                delayEngine = true
                Citizen.Wait(1000)
                delayEngine = false
            end
        end
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

        if progressBarResult then
            return true
        else
            return false
        end
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

local animDictLockPick = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
local animLockPick = "machinic_loop_mechandplayer"

lib.callback.register('mono_garage:FakePlate', function(data)
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


lib.callback.register('mono_garage:LockPick', function(entity)
    local status = GetVehicleDoorLockStatus(entity)
    local ped = cache.ped
    local plate = GetVehicleNumberPlateText(entity)
    lib.requestAnimDict(animDictLockPick)
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

            ClearPedTasks(ped)
            SetVehicleEngineOn(entity, false, true, true)
            return success, status
        else
            Notifi({ text = Text('FailThief') })
            ClearPedTasks(ped)
            return success, status
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
            return success, status
        else
            Notifi({ text = Text('FailThief') })
            ClearPedTasks(ped)
            return success, status
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