ESX = exports["es_extended"]:getSharedObject()

for impound, data in pairs(Garages.Impound) do
    data.name = impound

    if data.blip then
        CreateBlip(data.npc.pos.xyz, 524, 0.5, 63, data.name)
    end

    function OnEnter()
        ImpoundPed = CreateNPC(data.npc.hash, data.npc.pos)
        exports.ox_target:addLocalEntity(ImpoundPed, {
            {
                name = 'mono_garage:TargetNpc_impound',
                distance = Garages.TargetDistance,
                icon = 'fas fa-car',
                label = impound,
                onSelect = function()
                    OpenImpound(data)
                end
            }
        })
    end

    function OnExit()
        DeleteEntity(ImpoundPed)
        exports.ox_target:removeGlobalVehicle({ 'mono_garage:TargetNpc_impound' })
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

function OpenImpound(data)
    local owned_vehicles = lib.callback.await('mono_garage:GetOwnerVehicles')
    local garagemenu = {}
    local vehiclesFound = false
    for i = 1, #owned_vehicles do
        local vehicle = owned_vehicles[i]
        if vehicle.parking == data.name and tonumber(vehicle.pound) == 1 and vehicle.stored == 0 and vehicle.isOwner then
            vehiclesFound = true
            local props = json.decode(vehicle.vehicle)
            data.infoimpound = json.decode(vehicle.infoimpound)
            local nameCar = GetDisplayNameFromVehicleModel(props.model)
            local markCar = GetMakeNameFromVehicleModel(props.model)
            table.insert(garagemenu, {
                title = CapitalizeFirstLetter(markCar .. ' - ' .. nameCar),
                icon = 'car',
                iconColor = '#32a852' or '#FF8787',
                arrow = true,
                metadata = {
                    { label = Text('Date'),  value = data.infoimpound.date },
                    { label = Text('Reason'),  value = data.infoimpound.reason },
                    { label = Text('Price'), value = data.infoimpound.price .. ' $' }
                },
                colorScheme = '#4ac76b',
                description = vehicle.isOwner and Text('OwnerVehicle', props.plate) or
                    Text('NotOwnerVehicle', props.plate),
                onSelect = function()
                    data.nameCar = nameCar
                    data.markCar = markCar
                    data.vehicle = vehicle
                    data.plate = props.plate
                    VehicleImpoundSelec(data)
                end

            })
        end
    end
    if not vehiclesFound then
        Notifi(Text('NoVehicles', data.name))
    else
        lib.registerContext({
            id = 'mono_garage:owned_vehicles_impound',
            title = data.name,
            options = garagemenu
        })
        lib.showContext('mono_garage:owned_vehicles_impound')
    end
end

function VehicleImpoundSelec(data)
    local money = lib.callback.await('mono_garage:getBankMoney')
    lib.registerContext({
        id = 'mono_garage:VehicleSelect_impound',
        menu = 'mono_garage:owned_vehicles_impound',
        title = CapitalizeFirstLetter(data.nameCar .. ' ' .. data.markCar),
        options = {
            {
                title = Text('CustomGarage2',data.nameCar .. ' ' .. data.markCar),
                icon = 'car-side',
                onSelect = function()
                    local input = lib.inputDialog(Text('SelectPaidType'), {
                        {
                            type = 'select',
                            icon = 'dollar',
                            required = true,
                            label = 'Selecionar',
                            description = Text('CurrentMoney', money.money, money.bank),
                            options = {
                                { value = 'money', label = Text('Money') },
                                { value = 'bank',  label = Text('MoneyBank') },
                            }
                        },
                    })
                    if input == nil then
                        return
                    elseif not input[1] then
                        return Notifi('SelectPaidType')
                    end
                    data.cashType = input[1]
                    lib.callback('mono_garage:SpawnOwnerVehicle_impound', 1000, source, data)
                end
            },
        }
    })
    lib.showContext('mono_garage:VehicleSelect_impound')
end

for i = 1, #Garages.ImpoundTarget.jobs do
    local options = {
        {
            icon = 'fa-solid fa-car-on',
            label = Text('SendImpound'),
            groups = Garages.ImpoundTarget.jobs[i],
            canInteract = function(entity, distance, coords, name, bone)
                vehicle = {
                    entity = entity,
                    distance = distance,
                    coords = coords,
                    name = name,
                    bone = bone,
                    job = Garages.ImpoundTarget.jobs[i]
                }
                return vehicle
            end,
            onSelect = function()
                ImpoundVehicle(vehicle)
            end
        }
    }
    exports.ox_target:addGlobalVehicle(options)
end

function ImpoundVehicle(vehicle)
    local props = lib.getVehicleProperties(vehicle.entity)
    local name = lib.callback.await('mono_garage:GetPlayerNamePlate', source, props.plate)
    local imp = {}
    local data = {}
    for k, v in pairs(Garages.Impound) do
        if v.job == vehicle.job then
            if GetVehicleCategory(vehicle.entity) == v.type then
                table.insert(imp, { value = k, label = k })
            end
        end
    end

    local vehiclename = GetMakeNameFromVehicleModel(props.model) ..' - ' .. GetDisplayNameFromVehicleModel(props.model)

    local input = lib.inputDialog(Text('SetImpound1'), {
        {
            type = 'input',
            icon = 'address-card',
            disabled = true,
            label = Text('SetImpound2'),
            required = false,
            placeholder = name.name
        },
        {
            type = 'input',
            icon = 'window-maximize',
            disabled = true,
            label = Text('SetImpound3'),
            required = false,
            placeholder = props.plate
        },
        {
            type = 'input',
            icon = 'car',
            disabled = true,
            label = Text('SetImpound4'),
            required = false,
            placeholder = vehiclename
        },
        {
            type = 'textarea',
            icon = 'pen-to-square',
            label = Text('Reason'),
            required = true,
            max = 200,
        },
        {
            type = 'number',
            icon = 'money-bill-trend-up',
            label = Text('Price'),
            required = true,
            default = 1,
            min = 1,
            max = 10000000
        },
        {
            type = 'input',
            icon = { 'far', 'calendar' },
            disabled = true,
            label = Text('Date'),
            required = false,
            placeholder = name.fecha .. ' ' .. name.hora
        },
        {
            type = 'select',
            icon = 'warehouse',
            label = Text('SetImpound5'),
            required = true,
            options = imp
        },

    })

    if not input then return end

    if lib.progressBar({
            duration = Garages.ImpoundTarget.ProgressBarTime,
            label = Text('SetImpound6'),
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
            },
            anim = {
                scenario = 'WORLD_HUMAN_CLIPBOARD',
            },

        }) then
        --  plate, impound, price, reason, date, vehicle
        data.plate = props.plate
        data.impound = input[7]
        data.price = input[5]
        data.reason = input[4]
        data.date = name.fecha
        data.entity = VehToNet(vehicle.entity)
        lib.callback.await('mono_garage:ImpoundVehicle', source, data)
    end
end
