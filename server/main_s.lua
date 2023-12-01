ESX = exports["es_extended"]:getSharedObject()

lib.callback.register('mono_garage:GetOwnerVehicles', function(source)
    return GetOwnerVehicles(source)
end)

lib.callback.register('mono_garage:SpawnOwnerVehicle', function(source, data)
    local spawncoords = SpawnClearArea({ coords = data.spawnpos, distance = 2.0, player = source })

    if not spawncoords then
        Notifi(source, Text('NoSpawnFree'))
    else
        SpawnOwnerVehicle({ plate = data.plate, name = data.name, source = source }, function(stat)
            if stat.success then
                local model = json.decode(data.vehicle.vehicle).model
                CreateVehicleServer({
                    model = model,
                    plate = data.plate,
                    coords = spawncoords,
                    props = stat.props,
                    source = source,
                    intocar = data.intocar
                }, function(vehicle)
                    Notifi(source, Text('VehicleSpawn', data.name))
                end)
            end
        end)
    end
end)

lib.callback.register('mono_garage:CustomGarage', function(source, option, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    local job = xPlayer.getJob()

    local props = { plate = data.plate, fuelLevel = 100 }

    if data.job then
        local checkGrade = type(data.grade) == "number" and data.grade ~= job.grade
        local checkGradeName = type(data.grade) == "string" and data.grade ~= job.grade_name
        if checkGrade or checkGradeName then
            Notifi(source, Text('CustomGarage6'))
            return false
        end
    end

    if data.priceRent then
        local PlayerMoney = xPlayer.getMoney()
        if PlayerMoney < data.priceRent then
            Notifi(source, Text('CustomGarage7'))
            return false
        end
        xPlayer.removeMoney(data.priceRent)
    end

    if option == 'spawn' then
        local spawncoords = SpawnClearArea({ coords = data.spawnpos, distance = 2.0, player = source })
        if not spawncoords then
            Notifi(source, Text('NoSpawnFree'))
            return false
        end

        CreateVehicleServer({
            model = data.model,
            plate = data.plate,
            coords = spawncoords,
            source = source,
            props = props,
            intocar = data.intocar,
        }, function(vehicle)
            if not DoesEntityExist(vehicle.entity) then return end
            if data.priceRent then
                Notifi(source, Text('CustomGarage8', data.garage, data.timeRent))

                Citizen.SetTimeout(1000 * 60 * data.timeRent, function()
                    PlayerOutCar({ plate = data.plate, entity = vehicle.entity, player = source })
                end)
            else
                Notifi(source, Text('VehicleSpawn', data.garage))
            end
        end)
        return true
    elseif option == 'delete' then
        PlayerOutCar({ entity = NetworkGetEntityFromNetworkId(data.entity), player = source, plate = data.plate })
        return false
    end
end)


lib.callback.register('mono_garage:StoreOwnerVehicle', function(source, data)
    StoreOwnerVehicle(source, data, function(success)
        if success then
            local vehicle = NetworkGetEntityFromNetworkId(data.entity)
            PlayerOutCar({ entity = vehicle, player = source, plate = data.plate })
            Notifi(source, Text('VehicleDeposit', data.name))
        else
            Notifi(source, Text('NotOwnerVeh'))
        end
    end)
end)

lib.callback.register('mono_garage:ImpoundVehicle', function(source, data)
    ImpoundVehicle(data, function(success)
        if success then
            Notifi(source, Text('VehicleImpound', data.plate, data.impound))
        else
            Notifi(source, Text('VehicleImpoundFail'))
        end
    end)
end)

lib.callback.register('mono_garage:SpawnOwnerVehicle_impound', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)

    local money = xPlayer.getAccount(data.cashType)

    if money.money >= data.infoimpound.price then
        local spawncoords = SpawnClearArea({ coords = data.spawnpos, distance = 2.0, player = source })
        if not spawncoords then
            Notifi(source, Text('NoSpawnFree'))
        else
            SpawnOwnerVehicleImpound({ plate = data.plate, name = data.name, source = source }, function(stat)
                if stat.success then
                    local model = json.decode(data.vehicle.vehicle).model
                    CreateVehicleServer({
                        model = model,
                        plate = data.plate,
                        coords = spawncoords,
                        props = stat.props,
                        source = source,
                        intocar = data.intocar
                    }, function(vehicle)
                        if DoesEntityExist(vehicle.entity) then
                            if not data.society then
                                xPlayer.removeAccountMoney(data.cashType, data.infoimpound.price)
                            else
                                TriggerEvent('esx_addonaccount:getSharedAccount', data.society, function(account)
                                    xPlayer.removeAccountMoney(data.cashType, data.infoimpound.price)
                                    account.addMoney(data.infoimpound.price)
                                end)
                            end
                        end
                    end)
                end
            end)
        end
    else
        Notifi(source, Text('NoMoney'))
    end
end)

lib.callback.register('mono_garage:CarDoors', function(source, action, entity)
    local vehicle = NetworkGetEntityFromNetworkId(entity)
    local plate = GetVehicleNumberPlateText(vehicle)
    if action then
        local Owner = GetOwnerVehicles(source)
        for i = 1, #Owner do
            local vehicles = Owner[i]
            if PlateEqual(plate, vehicles.plate) or PlateEqual(plate, vehicles.fakeplate) then
                return true
            end
        end
    else
        return true
    end
end)

lib.callback.register('mono_garage:ShareVehicle', function(source, action, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    data.plate = string.gsub(data.plate, "^%s*(.-)%s*$", "%1")

    if action == 'add' then
        local selectQuery = "SELECT friends FROM owned_vehicles WHERE owner = ? AND plate = ?"
        local updateQuery = "UPDATE owned_vehicles SET friends = ? WHERE owner = ? AND plate = ?"

        local xTarget = ESX.GetPlayerFromId(data.id)
        local friendName = xTarget.getName()

        if xPlayer.identifier == xTarget.identifier then
            return Notifi(source, Text('FriendList7'))
        end

        MySQL.query(selectQuery, { xPlayer.identifier, data.plate },
            function(result)
                if result[1] ~= nil then
                    local amigosTable = {}

                    if result[1].friends ~= nil and result[1].friends ~= '' then
                        amigosTable = json.decode(result[1].friends)

                        for _, amigoData in ipairs(amigosTable) do
                            if amigoData.identifier == xTarget.identifier then
                                Notifi(source, Text('FriendList6'))
                                return
                            end
                        end
                    end

                    local amigoData = { name = friendName, identifier = xTarget.identifier }
                    amigosTable[#amigosTable + 1] = amigoData
                    local amigosStr = json.encode(amigosTable)

                    MySQL.update(updateQuery,
                        { amigosStr, xPlayer.identifier, data.plate },
                        function(rowsChanged)
                            if rowsChanged > 0 then
                                Notifi(source, Text('FriendList3', data.plate, friendName))
                                Notifi(xTarget.source, Text('FriendList4', data.plate))
                            else
                                Notifi(source, Text('FriendList5', friendName))
                            end
                        end)
                else
                    Notifi(source, 'No se pudo encontrar el vehículo con la matrícula ' .. data.plate)
                end
            end)
    elseif action == 'delete' then
        local selectQuery = "SELECT friends FROM owned_vehicles WHERE owner = ? AND plate = ?"
        local updateQuery = "UPDATE owned_vehicles SET friends = ? WHERE owner = ? AND plate = ?"

        MySQL.query(selectQuery, { xPlayer.identifier, data.plate },
            function(result)
                if result[1] ~= nil then
                    local amigosTable = result[1].friends and json.decode(result[1].friends) or {}

                    local found, index = false, nil
                    for i, amigo in ipairs(amigosTable) do
                        if amigo.name == data.name then
                            found, index = true, i
                            break
                        end
                    end

                    if found then
                        table.remove(amigosTable, index)
                        local amigosStr = #amigosTable > 0 and json.encode(amigosTable) or nil
                        MySQL.update(updateQuery,
                            { amigosStr, xPlayer.identifier, data.plate },
                            function(rowsChanged)
                                if rowsChanged > 0 then
                                    Notifi(source, Text('FriendList1', data.name, data.plate))
                                else
                                    Notifi(source, Text('FriendList2', data.name, data.plate))
                                end
                            end)
                    end
                end
            end)
    end
end)
