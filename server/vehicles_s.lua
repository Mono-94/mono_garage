local Thread = Citizen.CreateThread
local wait = Citizen.Wait
local ox = exports.ox_inventory

local Vehicles = {}
--- GetAll Vehicles Spawned for mono_garage
---@return table
lib.callback.register('mono_garage:GetSpawnedVehicles', function()
    local data = {}
    for plate, veh in pairs(Vehicles) do
        data[plate] = veh
        data[plate].vec3 = GetEntityCoords(veh.entity)
        data[plate].heading = GetEntityHeading(veh.entity)
        data[plate].netId = NetworkGetNetworkIdFromEntity(veh.entity)
        data[plate].vec4 = vec4(data[plate].vec3.x, data[plate].vec3.y, data[plate].vec3.z, data[plate].heading)
    end
    return data
end)

--- Create Vehicle Server
---@param cb function
function CreateVehicleServer(data, cb)
    Thread(function()
        data.entity = CreateVehicleServerSetter(data.model, "automobile", data.coords)

        while not DoesEntityExist(data.entity) do
            wait(0)
        end

        Entity(data.entity).state.fuel = data.props.fuelLevel or data.fuel or 100

        if data.props then
            Entity(data.entity).state.SetProperties = data.props
        end

        Entity(data.entity).state.FadeEntity = { action = 'spawn' }

        PlayerToCar({ player = data.source, plate = data.plate, entity = data.entity, intocar = data.intocar })


        SetVehicleNumberPlateText(data.entity, data.plate or data.props.plate)

        while not PlateEqual(GetVehicleNumberPlateText(data.entity), data.plate) do
            SetVehicleNumberPlateText(data.entity, data.plate)
            wait(0)
        end

        Vehicles[data.plate] = { entity = data.entity, plate = data.plate }


        if data.owner then
            SetOwner(data)
            if cb then
                cb({
                    entity = data.entity,
                    netid = NetworkGetNetworkIdFromEntity(data.entity),
                    data = data,
                    isOwner = true,
                    text = 'Vehiculo agregado a la base de datos y spawneado'
                })
            end
        else
            if cb then
                cb({
                    entity = data.entity,
                    netid = NetworkGetNetworkIdFromEntity(data.entity),
                    data = data,
                    text = 'Vehiculo Spawneado'
                })
            end
        end
    end)
end

local insertSetOwnerQuery = 'INSERT INTO `owned_vehicles` (owner, plate, vehicle, parking, type, job) VALUES (?, ?, ?, ?, ?, ?)'
--- Set Vehicle owner
---@param data any
---@return unknown
function SetOwner(data)
    local player = ESX.GetPlayerFromId(data.source)
    local SetOwner = MySQL.insert.await(insertSetOwnerQuery,
        { player.identifier, data.plate, json.encode(data.props), Garages.DefaultGarage[data.type], data.type, data.job })
    return SetOwner
end

local selectOwnerFriendQuery = "SELECT * FROM `owned_vehicles` WHERE `owner` = ? OR `friends` LIKE ?"
--- Get Owner Vehicles
---@param source any
---@return table
function GetOwnerVehicles(source)
    local player = ESX.GetPlayerFromId(source)

    local vehicles = MySQL.query.await(selectOwnerFriendQuery, { player.identifier, '%' .. player.identifier .. '%' })

    for i, result in ipairs(vehicles) do
        local amigos = json.decode(result.amigos)
        local isOwner = result.owner == player.identifier
        local isFriend = false

        if not isOwner and amigos then
            for j, amigo in ipairs(amigos) do
                if amigo.identifier == player.identifier then
                    isFriend = true
                    break
                end
            end
        end

        result.isOwner = isOwner
        result.isFriend = isFriend
        result.OwnerName = ESX.GetPlayerFromIdentifier(result.owner).getName()
    end

    return vehicles
end

local selectSpawnOwnertQuery = "SELECT * FROM `owned_vehicles` WHERE `plate` = ?"
local updateSpawnOwnerQuery = "UPDATE `owned_vehicles` SET `stored` = 0, `pound` = NULL, `lastparking` = ? WHERE `plate` = ?"
--- Spawn Vehicle
---@param data any plate/name garage
---@param cb function
function SpawnOwnerVehicle(data, cb)
    MySQL.query(selectSpawnOwnertQuery, { data.plate }, function(result)
        if result and #result > 0 then
            MySQL.update(updateSpawnOwnerQuery, { result[1].parking, data.plate, },
                function(rowsChanged)
                    if rowsChanged > 0 then
                        cb({ success = true, props = json.decode(result[1].vehicle) })
                    else
                        cb({ success = false, props = nil })
                    end
                end)
        else
            cb({ success = false, props = nil })
        end
    end)
end

local selectSpawnOwnerVehicleImpoundQuery = "SELECT * FROM `owned_vehicles` WHERE `plate` = ?"
local updateSpawnOwnerVehicleImpoundQuery = "UPDATE `owned_vehicles` SET pound = NULL, `parking` = ?, `infoimpound` = NULL WHERE `plate` = ?"
--- Spawn Vehicle Impound
---@param data any plate/name garage
---@param cb function
function SpawnOwnerVehicleImpound(data, cb)
    MySQL.query(selectSpawnOwnerVehicleImpoundQuery, { data.plate }, function(result)
        if result and #result > 0 then
            MySQL.update(updateSpawnOwnerVehicleImpoundQuery, { result[1].lastparking, data.plate },
                function(rowsChanged)
                    if rowsChanged > 0 then
                        cb({ success = true, props = json.decode(result[1].vehicle) })
                    else
                        cb({ success = false, props = nil })
                    end
                end)
        else
            cb({ success = false, props = nil })
        end
    end)
end

local selectStoreOwnerVehicleQuery = "SELECT * FROM `owned_vehicles` WHERE `owner` = ? OR `friends` LIKE ?"
local updateStoreOwnerVehicleQuery =
"UPDATE `owned_vehicles` SET `parking` = ?, `vehicle` = ?, `stored` = 1, `type` = ? WHERE `plate` = ? or `fakeplate` = ?"

--- Store Vehicle
---@param data any
---@param cb function
function StoreOwnerVehicle(source, data, cb)
    local player = ESX.GetPlayerFromId(source)
    local vehicles = MySQL.query.await(selectStoreOwnerVehicleQuery,
        { player.identifier, '%' .. player.identifier .. '%' })

    local function updateVehicle(result)
        local amigos = json.decode(result.amigos)
        local isOwner = result.owner == player.identifier

        if not isOwner and amigos then
            for _, amigo in ipairs(amigos) do
                if amigo.identifier == player.identifier then
                    result.owner = amigo.identifier
                    break
                end
            end
        end

        MySQL.update(updateStoreOwnerVehicleQuery,
            { data.name, json.encode(data.props), data.type,  result.plate },
            function(rowsChanged)
                if rowsChanged > 0 then
                    Vehicles[result.plate] = nil
                    cb(true)
                else
                    cb(false)
                end
            end)
    end

    local isVehicle = false

    for _, result in ipairs(vehicles) do
        if (PlateEqual(result.plate, data.plate) or PlateEqual(result.fakeplate, data.plate)) and result.job == data.job then
            if not result.parking then
                result.parking = data.name
            end
            isVehicle = true
            updateVehicle(result)
            break
        end
    end

    if not isVehicle then
        cb(false)
    end
end

local updateImpoundVehicleQuery =
"UPDATE owned_vehicles SET `parking` = ?, `infoimpound` = ?, `pound` = 1, `stored` = 0  WHERE  `plate` = ?"
--- Impound Vehicle
---@param data any
---@param cb function
function ImpoundVehicle(data, cb)
    local entity = NetworkGetEntityFromNetworkId(data.entity)
    local current_time = os.time()
    data.fecha = os.date("%d/%m/%Y", current_time)
    data.hora = os.date("%H:%M:%S", current_time)

    local info = { date = data.fecha .. ' - ' .. data.hora, price = data.price, reason = data.reason }


    MySQL.update(updateImpoundVehicleQuery, { data.impound, json.encode(info), data.plate }, function(rowsChanged)
        if rowsChanged > 0 then
            Entity(entity).state.FadeEntity = { action = 'delete' }
            Citizen.Wait(1500)
            DeleteEntity(entity)
            Vehicles[data.plate] = {}
            cb(true)
        else
            Entity(entity).state.FadeEntity = { action = 'delete' }
            Citizen.Wait(1500)
            DeleteEntity(entity)
            cb(false)
        end
    end)
end

--- FakePlate
ox:registerHook('createItem', function(payload)
    local plate = GeneratePlate()
    local metadata = payload.metadata
    metadata.description = plate
    return metadata
end, {
    itemFilter = {
        fakeplate = true
    }
})

local selectFakePlateQuery = "SELECT * FROM `owned_vehicles` WHERE `plate` = ? and `owner` = ?"
local updateFakePlateQuery = "UPDATE `owned_vehicles` SET `fakeplate` = ?  WHERE `plate` = ? and `owner` = ?"
local updateNullFakePlateQuery = "UPDATE `owned_vehicles` SET `fakeplate` = NULL  WHERE `plate` = ? and `owner` = ?"
exports('FakePlate', function(event, item, inventory, slot, data)
    local player = ESX.GetPlayerFromId(inventory.id)
    if event == 'usingItem' then
        local vehicle = lib.callback.await('mono_garage:ClosetVehicles', inventory.id, 5)
        local entity = NetworkGetEntityFromNetworkId(vehicle)
        local plate = GetVehicleNumberPlateText(entity)
        local itemSlot = ox:GetSlot(inventory.id, slot)
        local fakePlateValue = itemSlot.metadata.description
        MySQL.query(selectFakePlateQuery, { plate, player.identifier }, function(result)
            if result and #result > 0 then
                lib.callback('mono_garage:FakePlate', inventory.id, function(success)
                    if success.success then
                        ox:RemoveItem(inventory.id, item, 1, itemSlot.metadata, slot)
                        MySQL.update(updateFakePlateQuery, { fakePlateValue, plate, player.identifier },
                            function(rowsChanged)
                                if rowsChanged > 0 then
                                    Notifi(inventory.id, Text('FakePlate1'))
                                    if Garages.CarKeys.isItem then
                                        InventoryKeys('remove', { plate = plate, player = inventory.id, })
                                        InventoryKeys('add', { plate = fakePlateValue, player = inventory.id, })
                                    end
                                    SetVehicleNumberPlateText(entity, fakePlateValue)
                                    Citizen.SetTimeout(1000 * 60 * Garages.FakePlate.timeoutMins, function()
                                        MySQL.update(updateNullFakePlateQuery, { plate, player.identifier },
                                            function(rowsChanged)
                                                if rowsChanged > 0 then
                                                    if DoesEntityExist(entity) then
                                                        if Garages.CarKeys.isItem then
                                                            InventoryKeys('add',
                                                                { plate = plate, player = inventory.id, })
                                                            InventoryKeys('remove',
                                                                { plate = fakePlateValue, player = inventory.id, })
                                                        end
                                                        SetVehicleNumberPlateText(entity, plate)
                                                    end
                                                    Notifi(inventory.id, Text('FakePlate2'))
                                                else
                                                    Notifi(inventory.id, Text('FakePlate3'))
                                                end
                                            end)
                                    end)
                                else
                                    Notifi(inventory.id, Text('FakePlate3'))
                                end
                            end)
                    end
                end, true)
            else
                Notifi(inventory.id, Text('NotOwnerVeh'))
            end
        end)
    end
end)

-- Close Vehicles Doors when vehicle create
if Garages.VehicleEntitys.CloseAllDoors then
    AddEventHandler('entityCreated', function(entity)
        if not DoesEntityExist(entity) then
            return
        end

        local entityType = GetEntityType(entity)
        if entityType ~= 2 then
            return
        end

        if GetEntityPopulationType(entity) > 5 then
            return
        end

        local plate = GetVehicleNumberPlateText(entity)

        local motor = GetIsVehicleEngineRunning(entity)


        if motor then
            if math.random() <= 0.1 then
                SetVehicleDoorsLocked(entity, 2)
            end
        end

        if not motor then
            SetVehicleDoorsLocked(entity, 2)
        end
    end)
end

local SelecVehiclesImpoundQuery = "SELECT * FROM owned_vehicles"
local updateAutoImpoundQuery =
"UPDATE `owned_vehicles` SET `pound` = 1, `stored` = 0, `parking` = ?, `infoimpound` = ? WHERE `plate` = ?"
---Garage Auto Impound
if Garages.AutoImpound.active then
    SetInterval(function()
        local vehicles = MySQL.query.await(SelecVehiclesImpoundQuery)
        local current_time = os.time()
        local date = os.date("%d/%m/%Y", current_time) .. ' - ' .. os.date("%H:%M:%S", current_time)
        local info = json.encode({ date = date, price = Garages.AutoImpound.Price, reason = Garages.AutoImpound.Reason })

        local EntityExist = false

        for i = 1, #vehicles do
            local data = vehicles[i]

            if data.stored == 0 and data.pound == nil and data.fakeplate == nil then
                if not Vehicles[data.plate] then
                    Vehicles[data.plate] = {}
                end

                local existingEntity = Vehicles[data.plate].entity

                for index, entity in pairs(GetAllVehicles()) do
                    local plate = GetVehicleNumberPlateText(entity)

                    if PlateEqual(plate, data.plate) then
                        Vehicles[data.plate].entity = entity
                        Vehicles[data.plate].plate = data.plate

                        if existingEntity and existingEntity ~= entity then
                            EntityExist = true
                            Entity(existingEntity).state.FadeEntity = { action = 'delete' }
                            if Garages.Warn then
                                print(('[^1PLATE DUPLICATE^7] ^3Entity: %s, Plate: %s - Delete Entity'):format(
                                    existingEntity, data.plate))
                            end
                            break
                        end

                        if DoesEntityExist(Vehicles[data.plate].entity) then
                            EntityExist = true
                            Debug(('Entity: %s, Exist: %s, Plate: %s'):format(entity,
                                DoesEntityExist(Vehicles[data.plate].entity), data.plate))
                        end
                    end
                end

                if not EntityExist then
                    if Garages.Warn then
                        print(('[^1ENTITY NOT EXIST^7] ^3Vehicle impound: %s, plate: %s'):format(
                            Garages.DefaultImpound[data.type], data.plate))
                    end
                    MySQL.update.await(updateAutoImpoundQuery, { Garages.DefaultImpound[data.type], info, data.plate })
                    Vehicles[data.plate] = {}
                end
            end
        end
    end, Garages.AutoImpound.TimeInterval)
end
