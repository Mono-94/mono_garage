Garages                    = {}

Garages.Lang               = 'EN' -- ES/EN/PL/FR/IT/PT

Garages.Debug              = false

Garages.DefaultGarage      = {
    ['car'] = 'Pillbox Hill',
    ['boat'] = 'La Puerta Boat',
    ['air'] = 'Aeropuerto INYL. de los Santos Air',
}

Garages.DefaultImpound     = {
    ['car'] = 'LSPD Impound',
    ['boat'] = 'Boat Impound',
    ['air'] = 'AirCraft Impound',
}

Garages.VehicleCategories  = {
    ['car'] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 17, 19, 13, 20, 18 },
    ['boat'] = { 14 },
    ['air'] = { 15, 16 },
}

Garages.Commands           = {
    GiveCar = 'givecar',
    DelDataBasePlate = 'delplate',
    carTimer = 'cartimer',
    sendAll = 'sendAll'
}

Garages.Buttons            = {
    carkeys = 'U',
    engine = 'M'
}

Garages.CarKeys            = {
    isItem = true,
    engine = true, -- only work isItem = true
}

Garages.VehicleEntitys     = {
    CloseAllDoors = true,
    densitiy = true,
    SetVehicleDensityMultiplier = 1.0,
    SetRandomVehicleDensityMultiplier = 1.0,
    SetParkedVehicleDensityMultiplier = 1.0
}

Garages.AutoImpound        = {
    active = true,
    TimeInterval = 5000,
    Price = 100,
    Reason = 'Mono Garage Impound'
}

Garages.ImpoundCommand     = {
    Command = 'impound',
    ProgressBarTime = 5000,
    jobs = {
        [1] = 'police',
    }
}

Garages.inventory          = 'ox' -- ox 100% / qs 50% only works keys...

Garages.Items              = {
    carkeys = 'carkeys',
    plate = 'plate',
    lockpick = 'ganzua',
}

Garages.FakePlate          = {
    ItemFakeplate = 'fakeplate',
    timeoutMins = 1,

}

Garages.LockPickAndHotWire = {
    -- LockPick
    LockPickAlarmAndDispatchProbablity = 0.5,
    LockPickSkillCheck = {
        { 'easy', 'easy', 'easy', 'easy', 'easy', 'easy', 'easy', 'easy' },
        { 'e',    'e',    'e',    'e',    'e',    'e',    'e',    'e',   }
    },
    -- HotWire
    HotWireAlarmProbablity = 0.5,
    HotWireSkillCheck = {
        { 'easy', 'easy', 'easy', 'easy', 'easy', 'easy', 'easy', 'easy' },
        { 'e',    'e',    'e',    'e',    'e',    'e',    'e',    'e',   }
    },
}

function LockPickDispatchFunction(source, Coords, PlayerId, VehicleEntity)
    print(source, Coords, PlayerId, VehicleEntity)
end

---PlateEqual
---@param valueA string
---@param valueB string
---@return boolean
function PlateEqual(valueA, valueB)
    valueA = tostring(valueA)
    valueB = tostring(valueB)
    valueA = valueA:gsub("%s", ""):lower()
    valueB = valueB:gsub("%s", ""):lower()
    return valueA == valueB
end

---Notifi
function Notifi(data)
    lib.notify({
        title = data.title or 'Garaje',
        description = data.text or data,
        position = data.position or 'top-right',
        style = {
            backgroundColor = '#292929',
            color = '#c2c2c2',
            ['.description'] = {
                color = '#cccccc'
            }
        },
        icon = data.icon or 'warehouse',
        iconColor = data.color or '#d46363'
    })
end

RegisterNetEvent('mono_garage:Notifi', Notifi)
