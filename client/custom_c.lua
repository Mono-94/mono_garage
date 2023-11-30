for garage, data in pairs(Garages.Customs) do
    data.name = garage
    if data.blip then
        CreateBlip(data.npc.pos.xyz, data.blip.sprite, data.blip.size, data.blip.color, garage)
    end

    function OnEnter()
        CustomGaragePed = CreateNPC(data.npc.hash, data.npc.pos)
        exports.ox_target:addLocalEntity(CustomGaragePed, {
            {
                name = 'mono_garage:OpenCustomGarage',
                groups = data.job,
                distance = 5,
                group = data.job,
                icon = 'fas fa-car',
                label = Text('TargetPedOpen', garage),
                onSelect = function()
                    OpenCustomGarage(data)
                end
            }
        })
        exports.ox_target:addGlobalVehicle({
            {
                name = 'mono_garage:SaveCustomTarget',
                icon = 'fa-solid fa-road',
                label = Text('TargetPedDeposit', garage),
                groups = data.job,
                distance = 5,
                canInteract = function(entity, distance, coords, name, bone)
                    --[[for k, v in pairs(data.vehicles) do
                        if PlateEqual(v.plate, GetVehicleNumberPlateText(entity)) then
                            return entity, distance, coords, name, bone
                        end
                    end]]
                end,
                onSelect = function()
                    SaveCustomVehicle(data)
                end
            },
        })
    end

    function OnExit()
        if DoesEntityExist(CustomGaragePed) then
            DeleteEntity(CustomGaragePed)
        end
        exports.ox_target:removeGlobalVehicle({ 'mono_garage:SaveCustomTarget', 'mono_garage:OpenCustomGarage' })
    end

    if type(data.garagepos) == "table" then
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
local rent = false

function SaveCustomVehicle(data)
    if DoesEntityExist(data.entity) then
        data.plate = GetVehicleNumberPlateText(vehicle.entity)
        data.entity = NetworkGetNetworkIdFromEntity(vehicle.entity)
        for k, v in pairs(data.vehicles) do
            if PlateEqual(v.plate, data.plate) then
                lib.callback('mono_garage:CustomGarage', nil, source, 'delete', data)
                if not data.job then
                    rent = false
                end
            else
                Notifi('No puedes guardar este vehiculo aqui')
                return
            end
        end
    end
end

function OpenCustomGarage(data)
    local price = false
    local time = false
    local input
    local custom = {}
    for _, vehicle in pairs(data.vehicles) do
        if not vehicle.priceMin then
            vehicle.description = Text('CustomGarage1', vehicle.grade)
        else
            vehicle.description = Text('CustomGarage3', vehicle.priceMin)
        end
        table.insert(custom, {
            title = Text('CustomGarage2', vehicle.name),
            icon = 'car-side',
            description = vehicle.description,
            iconColor = '#6fe39a',
            arrow = true,
            colorScheme = '#408f7c',
            progress = 100,
            onSelect = function()
                if vehicle.priceMin then
                    if not rent then else return Notifi(Text('CustomGarage5')) end
                    input = lib.inputDialog(data.name, {
                        { default = 1, type = 'number', label = Text('CustomGarage4'), description = Text('CustomGarage3', vehicle.priceMin), required = true, min = 1, max = 120 }
                    })
                    if not input then return end
                    price = vehicle.priceMin * input[1]
                    time = input[1]
                end

                lib.callback('mono_garage:CustomGarage', false, function(success)
                    rent = success
                end, 'spawn', {
                    job = data.job,
                    grade = vehicle.grade,
                    spawnpos = data.spawnpos,
                    plate = vehicle.plate,
                    model = vehicle.model,
                    garage = data.name,
                    priceRent = price,
                    timeRent = time,
                    intocar = data.intocar,
                    fuel = 100,
                })
                if vehicle.priceMin then
                    Citizen.Wait(1000 * 60 * time)
                    rent = false
                end
            end
        })
    end
    lib.registerContext({
        id = 'mono_garage:owned_vehicles_custom',
        title = Text('TargetPedOpen', data.name),
        options = custom,
    })
    lib.showContext('mono_garage:owned_vehicles_custom')
end

exports('SaveCustomVehicle', SaveCustomVehicle)
exports('OpenCustomGarage', OpenCustomGarage)
