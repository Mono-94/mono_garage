for garage, data in pairs(Garages.Garages) do
    data.name = garage

    if data.blip then
        if data.type == 'car' then
            CreateBlip(data.npc.pos.xyz, 50, 0.5, 31, Text('BlipGarage'))
        elseif data.type == 'boat' then
            CreateBlip(data.npc.pos.xyz, 427, 0.5, 31, Text('BlipBoat'))
        elseif data.type == 'air' then
            CreateBlip(data.npc.pos.xyz, 307, 0.5, 31, Text('BlipAir'))
        end
    end

    function OnEnter()
        GaragePed = CreateNPC(data.npc.hash, data.npc.pos)
        exports.ox_target:addLocalEntity(GaragePed, {
            {
                name = 'mono_garage:OpenGarage',
                groups = data.job,
                distance = Garages.TargetDistance,
                group = data.job,
                icon = 'fas fa-car',
                label = Text('TargetPedOpen', garage),
                onSelect = function()
                    OpenGarage(data)
                end
            }
        })
        exports.ox_target:addGlobalVehicle({
            {
                name = 'mono_garage:SaveTarget',
                icon = 'fa-solid fa-road',
                label = Text('TargetPedDeposit', garage),
                groups = data.job,
                distance = Garages.TargetDistance,
                canInteract = function(entity, distance, coords, name, bone)
                    if data.type == GetVehicleCategory(entity) then
                        return entity, distance, coords, name, bone
                    end
                end,
                onSelect = function(vehicle)
                    data.entity = vehicle.entity
                    SaveVehicle(data)
                end
            },
        })
    end

    function OnExit()
        DeleteEntity(GaragePed)
        exports.ox_target:removeGlobalVehicle({ 'mono_garage:SaveTarget', 'mono_garage:OpenGarage' })
    end

    if type(data.garagepos) == "table"  then
        lib.zones.poly({
            points = data.garagepos,
            thickness = data.thickness,
            debug = data.debug,
            onEnter = OnEnter,
            onExit = OnExit,
        })
    else
        lib.zones.box({
            coords = data.garagepos,
            size = data.size,
            rotation = data.garagepos.w,
            debug = data.debug,
            onEnter = OnEnter,
            onExit = OnExit,
        })
    end
end

function SaveVehicle(data)
    if DoesEntityExist(data.entity) then
        data.props = lib.getVehicleProperties(data.entity)
        data.plate = GetVehicleNumberPlateText(data.entity)
        data.entity = VehToNet(data.entity)
        lib.callback('mono_garage:StoreOwnerVehicle', nil, source, data)
    end
end

function OpenGarage(data)
    local owned_vehicles = lib.callback.await('mono_garage:GetOwnerVehicles')
    local garagemenu = {}
    local vehiclesFound = false
    for i = 1, #owned_vehicles do
        local vehicle = owned_vehicles[i]
        if vehicle.parking == data.name and data.type == vehicle.type and data.job == vehicle.job then
            local props = json.decode(vehicle.vehicle)
            local nameCar = GetDisplayNameFromVehicleModel(props.model)
            local markCar = GetMakeNameFromVehicleModel(props.model)
            vehiclesFound = true
            table.insert(garagemenu, {
                title = markCar .. ' - ' .. nameCar,
                icon = 'car',
                iconColor = (vehicle.stored == 1) and '#32a852' or '#FF8787',
                arrow = true,
                metadata = {
                    { label = Text('LastGarage'), value = vehicle.lastparking },
                    {
                        label = Text('Fuel'),
                        value = (props.fuelLevel and props.fuelLevel .. '%' or '100%'),
                        progress = (props.fuelLevel and props.fuelLevel or 100),
                    },
                    {
                        label = Text('Engine'),
                        value = (props.engineHealth and math.floor(props.engineHealth / 10) .. '%' or '100%'),
                        progress = (props.engineHealth and math.floor(props.engineHealth / 10) or 100),
                    },
                    {
                        label = Text('Body'),
                        value = (props.bodyHealth and math.floor(props.bodyHealth / 10) .. '%' or '100%'),
                        progress = (props.bodyHealth and math.floor(props.bodyHealth / 10) or 100),
                    },
                },
                colorScheme = '#4ac76b',
                description = vehicle.isOwner and Text('OwnerVehicle', props.plate) or
                    Text('NotOwnerVehicle',vehicle.OwnerName, props.plate),
                onSelect = function()
                    data.nameCar = nameCar
                    data.markCar = markCar
                    data.vehicle = vehicle
                    data.plate = props.plate
                    data.fuel = props.fuelLevel
                    VehicleSelect(data)
                end

            })
        end
    end
    if not vehiclesFound then
        Notifi(Text('NoVehicles', data.name))
    else
        lib.registerContext({
            id = 'mono_garage:owned_vehicles',
            title = Text('TargetPedOpen', data.name),
            options = garagemenu
        })
        lib.showContext('mono_garage:owned_vehicles')
    end
end

function VehicleSelect(data)
    local menu = {}
    local veh = data.nameCar .. ' ' .. data.markCar
    if data.vehicle.stored == 1 then
        table.insert(menu, {
            title = Text('TakeVehicle'),
            icon = 'right-from-bracket',
            description = Text('DescSelectVehi', data.fuel),
            iconColor = '#6fe39a',
            colorScheme = '#408f7c',
            progress = (data.fuel and data.fuel or 100),
            arrow = true,
            onSelect = function()
                lib.callback('mono_garage:SpawnOwnerVehicle', 1000, source, data)
            end
        })
        if data.vehicle.isOwner then
            table.insert(menu, {
                title = Text('ShareVehicle'),
                description = Text('ShareVehicleDesc'),
                icon = 'users',
                iconColor = '#6f9ce3',
                onSelect = function()
                    SharedFriends(data)
                end
            })
        end
    elseif data.vehicle.stored == 0 then
        table.insert(menu, {
            title = Text('TakeVehicle'),
            icon = 'right-from-bracket',
            iconColor = '#cc5c5c',
            description = Text('DescSelectVehi', data.fuel),
            colorScheme = '#408f7c',
            progress = (data.fuel and data.fuel or 100),
            disabled = true
        })
        if data.vehicle.isOwner then
            table.insert(menu, {
                title = Text('ShareVehicle'),
                description = Text('ShareVehicleDesc'),
                arrow = true,
                icon = 'users',
                iconColor = '#6f9ce3',
                onSelect = function()
                    SharedFriends(data)
                end
            })
            table.insert(menu, {
                title = Text('GetCoordsVehicle'),
                description = Text('GetCoordsVehicleDesc'),
                arrow = true,
                icon = 'map-location-dot',
                iconColor = '#acff63',
                onSelect = function()
                    lib.callback('mono_garage:GetSpawnedVehicles', 1000, function(vehicles)
                        if vehicles then
                            for k, v in pairs(vehicles) do
                                if data.plate == v.plate then
                                    SetNewWaypoint(v.coords.xy)
                                    Notifi('Vehículo marcado en el gps')
                                end
                            end
                        end
                    end)
                end
            })
            table.insert(menu, {
                title = Text('SendImpound'),
                description = Text('SendImpoundDesc', data.defaultImpound),
                arrow = true,
                icon = 'warehouse',
                iconColor = '#ffd45e',
                onSelect = function()
                    local impound = {}
                    lib.callback('mono_garage:GetSpawnedVehicles', 1000, function(vehicles)
                        if vehicles then
                            local alert = lib.alertDialog({
                                header = 'Enviar al deposito',
                                content = 'Seguro quieres enviar el vehiculo al deposito?',
                                centered = true,
                                cancel = true
                            })
                            if alert == 'confirm' then
                                for k, v in pairs(vehicles) do
                                    if data.plate == v.plate then
                                        impound.plate = v.plate
                                        impound.impound = data.defaultImpound
                                        impound.price = data.priceImpound
                                        impound.reason = Text('SendFrom', data.name)
                                        impound.entity = v.netId
                                        lib.callback.await('mono_garage:ImpoundVehicle', source, impound)
                                        SetNewWaypoint(Garages.Impound[data.defaultImpound].npc.pos.xy)
                                    end
                                end
                            end
                        end
                    end)
                end
            })
        end
    end


    lib.registerContext({
        id = 'mono_garage:VehicleSelect',
        menu = 'mono_garage:owned_vehicles',
        title = data.nameCar .. ' ' .. data.markCar,
        options = menu
    })

    lib.showContext('mono_garage:VehicleSelect')
end

exports('SaveVehicle', SaveVehicle)
exports('OpenGarage', OpenGarage)


function SharedFriends(data)
    local menu = {}
    local share = {}
    table.insert(menu, {
        title = Text('ShareAddFriend'),
        icon = 'user-plus',
        iconColor = '#6fe39a',
        description = Text('ShareAddFriendDesc'),
        onSelect = function()
            local input = lib.inputDialog(Text('ShareVehicle'),
                {
                    { type = 'input', label = Text('IdPlayer') },
                })
            if not input then return end

            lib.callback('mono_garage:ShareVehicle', false, source, 'add', { id = input[1], plate = data.plate })
        end
    })
    if data.vehicle.friends then
        for k, v in pairs(json.decode(data.vehicle.friends)) do
            table.insert(menu, {
                title = Text('ShareFriend', k, v.name),
                icon = 'user',
                iconColor = '#6f9ce3',
                description = Text('ShareFriendDesc'),
                onSelect = function()
                    local alert = lib.alertDialog({
                        header = Text('ShareFriendTitle'),
                        content = Text('ShareFriendDel', data.plate, v.name),
                        centered = true,
                        cancel = true
                    })
                    if alert == 'confirm' then
                        lib.callback('mono_garage:ShareVehicle', false, source, 'delete',
                            { name = v.name, plate = data.plate })
                    end
                end
            })
        end
    end
    lib.registerContext({
        id = 'mono_garage:SharedFriends',
        menu = 'mono_garage:VehicleSelect',
        title = data.nameCar .. ' ' .. data.markCar,
        options = menu
    })
    lib.showContext('mono_garage:SharedFriends')
end
