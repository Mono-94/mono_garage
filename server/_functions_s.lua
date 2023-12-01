local ox = exports.ox_inventory
local Thread = Citizen.CreateThread
local wait = Citizen.Wait
local itemKey = Garages.Items.carkeys

function Debug(text)
    if Garages.Debug then
        print(text)
    end
end

function Notifi(source, data)
    TriggerClientEvent('mono_garage:Notifi', source, data)
end

-- Clear area vehicles
---@param data any
---@return vector4|nil
---@return number
function SpawnClearArea(data)
    local player = GetPlayerPed(data.player)
    local playerpos = GetEntityCoords(player)
    local distancia, coords = math.huge, nil

    for _, v in ipairs(data.coords) do
        local spawnPos = vector3(v.x, v.y, v.z)
        local distance = #(playerpos - spawnPos)

        if distance < distancia then
            local isClear = true
            for k, vehicle in pairs(GetAllVehicles()) do
                local vehicleDistance = #(vector3(spawnPos.x, spawnPos.y, spawnPos.z) - GetEntityCoords(vehicle))
                if vehicleDistance <= data.distance then
                    isClear = false
                    break
                end
            end

            if isClear then
                distancia, coords = distance, vec4(v.x, v.y, v.z, v.w)
            end
        end
    end

    return coords, distancia
end

local plateExistQuery = 'SELECT 1 FROM `owned_vehicles` WHERE `plate` = ?'
---Check plate exist in  DataBase
---@param plate any
---@return boolean
function PlateExist(plate)
    return not MySQL.scalar.await(plateExistQuery, { plate })
end

---Random plate
---@return string
function GeneratePlate()
    local letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local numbers = "0123456789"
    local plate = ""

    repeat
        plate = ""
        for i = 1, 4 do
            local index = math.random(#letters)
            plate = plate .. string.sub(letters, index, index)
        end
        plate = plate .. " "
        for i = 1, 3 do
            local index = math.random(#numbers)
            plate = plate .. string.sub(numbers, index, index)
        end
    until PlateExist(plate)

    return plate
end

RegisterNetEvent('GeneratePlate', GeneratePlate)

-- Inventory give/remove KEYS
---@param data any
---@param action any
function InventoryKeys(action, data)
    data.plate = string.gsub(data.plate, "%s", "")
    local metaData = {
        plate       = data.plate,
        description = Text('PlateMetadata', data.plate)
    }
    if Garages.CarKeys.isItem then
        if action == 'add' then
            if Garages.inventory == 'ox' then
                ox:AddItem(data.player, itemKey, 1, metaData)
            elseif Garages.inventory == 'qs' then
                exports['qs-inventory']:AddItem(data.player, itemKey, 1, nil, metaData)
            elseif Garages.inventory == 'custom' then
                -- custom
            end
        elseif action == 'remove' then
            if Garages.inventory == 'ox' then
                ox:RemoveItem(data.player, itemKey, 1, metaData)
            elseif Garages.inventory == 'qs' then
                exports['qs-inventory']:RemoveItem(data.player, itemKey, 1, nil, metaData)
            elseif Garages.inventory == 'custom' then
                -- custom
            end
        end
    end
end

exports('InventoryKeys', InventoryKeys)

lib.callback.register('mono_garage:InventoryKeys', function(source, action, plate)
    InventoryKeys(action, { player = source, plate = plate })
end)

--- Player to vehicle
---@param data table player/entity
function PlayerToCar(data)
    if DoesEntityExist(data.entity) then
        if data.intocar then
            Thread(function()
                while true do
                    TaskWarpPedIntoVehicle(data.player, data.entity, -1)
                    if GetPedInVehicleSeat(data.entity, -1) > 0 then
                        if Garages.CarKeys.isItem then
                            InventoryKeys('add', data)
                        end
                        break
                    end
                    wait(0)
                end
            end)
        else
            if Garages.CarKeys.isItem then
                InventoryKeys('add', data)
            end
        end
    end
end

--- Player out vehicle
---@param data table player/entity
function PlayerOutCar(data)
    if DoesEntityExist(data.entity) then
        Thread(function()
            while true do
                if GetPedInVehicleSeat(data.entity, -1) > 0 then
                    TaskLeaveVehicle(data.player, data.entity, 1)
                    wait(1000)
                else
                    if Garages.CarKeys.isItem then
                        InventoryKeys('remove', data)
                    end
                    if DoesEntityExist(data.entity) then
                        Entity(data.entity).state.FadeEntity = { action = 'delete' }
                        break
                    end
                end
                wait(0)
            end
        end)
    end
end

lib.addCommand(Garages.Commands.GiveCar, {
    help = Text('CommandGivecar1'),
    restricted = 'admin',
    params = {
        {
            name = 'target',
            type = 'playerId',
            help = Text('CommandParamsTarget'),
        },
        {
            name = 'model',
            type = 'string',
            help = Text('CommandParamsModel'),
        },
        {
            name = 'type',
            type = 'string',
            help = Text('CommandParamsType'),
        },
        {
            name = 'owner',
            type = 'string',
            help = 'true/false [OPTIONAL]',
            optional = true,
        },
    },
}, function(source, data)
    local player = GetPlayerPed(data.target)
    local playerpos = GetEntityCoords(player)
    local playerHeading = GetEntityHeading(player)
    data.source = data.target
    data.player = data.target
    data.intocar = true
    data.coords = { vec4(playerpos.x, playerpos.y, playerpos.z, playerHeading)}
    data.distance = 2.0
    data.props = { plate = GeneratePlate(), fuelLevel = 100, model = data.model }
    data.plate = data.props.plate
    data.coords = SpawnClearArea(data)

    if data.owner == 'true' then data.owner = true else data.owner = false end

    if not data.coords then return else
        CreateVehicleServer(data)
    end
end)
lib.addCommand(Garages.Commands.carTimer, {
    help = Text('CommandCarTime'),
    restricted = 'admin',
    params = {
        {
            name = 'target',
            type = 'playerId',
            help = Text('CommandParamsTarget'),
        },
        {
            name = 'model',
            type = 'string',
            help = Text('CommandParamsModel'),
        },
        {
            name = 'time',
            type = 'number',
            help = Text('CommandParamTime'),
            optional = true,
        },
    },
}, function(source, args)
    local Ped = GetPlayerPed(args.target)
    local inCar = GetVehiclePedIsIn(Ped, false)
    local coordsped = GetEntityCoords(GetPlayerPed(args.target))
    local headingped = GetEntityHeading(GetPlayerPed(args.target))
    local coords = vec4(coordsped.x, coordsped.y, coordsped.z, headingped)
    local props = { plate = GeneratePlate(), fuelLevel = 100 }
    if inCar <= 0 then
        CreateVehicleServer({
            model = args.model,
            plate = props.plate,
            coords = coords,
            props = props,
            source = args.target,
            owner = args.owner,
            type = args.type,
            intocar = true
        }, function(vehicle)
            if args.time then
                Notifi(args.target, Text('CommandCarTime2', args.time))
                Citizen.SetTimeout(args.time * 1000 * 60, function()
                    if DoesEntityExist(vehicle.entity) then
                        Notifi(args.target, Text('CommandCarTime3'))
                        PlayerOutCar({ entity = vehicle.entity, plate = props.plate, player = args.target })
                    end
                end)
            end
        end)
    end
end)

local selectDeletePlateQuery = "SELECT * FROM `owned_vehicles`"
local deleteDeletePlateQuery = "DELETE FROM `owned_vehicles` WHERE `plate` = ?"

lib.addCommand(Garages.Commands.DelDataBasePlate, {
    help = Text('CommandDelPlate1'),
    restricted = 'admin',
    params = {
        {
            name = 'plate',
            type = 'string',
            help = Text('CommandDelPlate2'),
        },
    },
}, function(source, args)
    local vehicles = MySQL.query.await(selectDeletePlateQuery)
    local plate = false
    for i, result in ipairs(vehicles) do
        if PlateEqual(result.plate, args.plate) then
            plate = true
            lib.callback('mono_garage:DelVehicleByPlate', source, function(action)
                if action then
                    MySQL.execute(deleteDeletePlateQuery, { result.plate })
                    Notifi(source, Text('CommandDelPlate3', result.plate))
                end
            end, result.plate)
        end
    end
    if not plate then
        Notifi(source, Text('CommandDelPlate4', args.plate))
    end
end)


local UpdateAllPlateQuery =
"UPDATE `owned_vehicles` SET `parking` = ?, `stored` = 1, `pound` = NULL, `infoimpound` = NULL WHERE `type` = ? and `stored` = 0"

lib.addCommand(Garages.Commands.sendAll, {
    help = Text('SendAll2'),
    restricted = 'admin',
    params = {
        {
            name = 'type',
            type = 'string',
            help = Text('CommandParamsType'),
        },
    },
}, function(source, args)
    local affectedRows = MySQL.update.await(UpdateAllPlateQuery, { Garages.DefaultGarage[args.type], args.type })
    Notifi(source, Text('SendAll', affectedRows, (args.type):upper(), (Garages.DefaultGarage[args.type]):upper()))
end)

local selectNamePlateQuery =
"SELECT `owner`, `firstname`, `lastname` FROM `owned_vehicles` JOIN `users` ON owned_vehicles.owner = users.identifier WHERE `plate` = ?"
lib.callback.register('mono_garage:GetPlayerNamePlate', function(source, plate)
    local data = {}
    local current_time = os.time()

    local result = MySQL.query.await(selectNamePlateQuery, { plate })

    if result and #result > 0 then
        data.name = result[1].firstname .. ' ' .. result[1].lastname
    else
        data.name = Text('NameNotFound')
    end

    data.fecha = os.date("%d/%m/%Y", current_time)
    data.hora = os.date("%H:%M:%S", current_time)

    return data
end)


lib.callback.register('mono_garage:getBankMoney', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    local bank = xPlayer.getAccount("bank")
    local money = xPlayer.getMoney()
    return { bank = bank.money, money = money }
end)

exports('LockPick', function(event, item, inventory, slot, data)
    if event == 'usingItem' then
        local entity, vehicle = lib.callback.await('mono_garage:ClosetVehicles', inventory.id, 5)
        local entity2 = NetworkGetEntityFromNetworkId(entity)
        lib.callback('mono_garage:LockPick', inventory.id, function(success, status)
            if success then
                if status == 2 then
                    Entity(vehicle).state.VehicleDoors = 0
                elseif status == 0 or 1 then
                    Entity(vehicle).state.VehicleDoors = 2
                end
            end
        end, vehicle)
    end
end)

exports('HotWire', function(event, item, inventory, slot, data)
    local Ped = GetPlayerPed(inventory.id)
    local vehicle = GetVehiclePedIsIn(Ped, false)
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local isEngineRunning = GetIsVehicleEngineRunning(vehicle)
    if event == 'usingItem' then
        if vehicle > 0 and GetPedInVehicleSeat(GetVehiclePedIsIn(Ped), -1) == Ped then
            lib.callback('mono_garage:HotWire', inventory.id, function(success)
                Notifi(inventory.id, Text('VehicleHotWire'))
            end, netId, isEngineRunning)
        end
    end
end)

-- DataBase Setting
local ShowColumnsQuery = 'SHOW COLUMNS FROM `owned_vehicles`'

local requiredColumns = { 'infoimpound', 'lastparking', 'friends', 'fakeplate' }

MySQL.query(ShowColumnsQuery, {}, function(columns)
    if columns then
        local success = false

        for _, columnName in ipairs(requiredColumns) do
            local columnExists = false

            for _, columnInfo in ipairs(columns) do
                if columnInfo.Field == columnName then
                    columnExists = true
                    break
                end
            end

            if not columnExists then
                local columnDefinition = ""
                if columnName == "fakeplate" then
                    columnDefinition = "`fakeplate` varchar(12) DEFAULT NULL"
                else
                    columnDefinition = string.format("`%s` longtext DEFAULT NULL", columnName)
                end

                local UpdateColumnsQuery = string.format('ALTER TABLE `owned_vehicles` ADD COLUMN IF NOT EXISTS %s;',
                    columnDefinition)

                MySQL.update(UpdateColumnsQuery, {}, function(succ)
                    if succ then
                        success = true
                    end
                end)
            end
        end

        if success then
            warn(Text('DBCreate1'))
        end
    else
        warn(Text('DBCreate2'))
    end
end)

