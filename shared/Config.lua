Garages                = {}

Garages.Lang           = 'EN'    -- ES/EN/PL/FR/IT/PT

Garages.Debug          = false

Garages.Warn           = true    -- warn in console, entity not exist or plate duplicate

Garages.Options        = 'textui'

Garages.TargetDistance = 2

Garages.DefaultGarage     = {
    ['car'] = 'Pillbox Hill',
    ['boat'] = 'La Puerta Boat',
    ['air'] = 'Aeropuerto INYL. de los Santos Air',
}

Garages.DefaultImpound    = {
    ['car'] = 'LSPD Impound',
    ['boat'] = 'Boat Impound',
    ['air'] = 'AirCraft Impound',
}

Garages.VehicleCategories = {
    ['car'] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 17, 19, 13, 20, 18 },
    ['boat'] = { 14 },
    ['air'] = { 15, 16 },
}

Garages.Commands          = {
    GiveCar = 'givecar',
    DelDataBasePlate = 'delplate',
    carTimer = 'cartimer',
    sendAll = 'sendAll'
}

Garages.Buttons           = {
    carkeys = 'U',
    engine  = 'M',
}

Garages.CarKeys           = {
    isItem           = true,
    engine           = true, -- only work isItem = true
    CarKeyDistance   = 5,
    CarKeyDelay      = 2000,
    EngineStartDelay = 1000,
}


Garages.VehicleEntitys     = {
    CloseAllDoors = true,
    densitiy = true,
    SetVehicleDensityMultiplier = 0.0,
    SetRandomVehicleDensityMultiplier = 0.0,
    SetParkedVehicleDensityMultiplier = 0.0
}

Garages.AutoImpound        = {
    active = true,
    TimeInterval = 5000,
    Price = 100,
    Reason = 'Mono Garage Impound'
}

Garages.ImpoundTarget      = {
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
        { 'e',    'e',    'e',    'e',    'e',    'e',    'e',    'e', }
    },
    -- HotWire
    HotWireAlarmProbablity = 0.5,
    HotWireSkillCheck = {
        { 'easy', 'easy', 'easy', 'easy', 'easy', 'easy', 'easy', 'easy' },
        { 'e',    'e',    'e',    'e',    'e',    'e',    'e',    'e', }
    },
}

function LockPickDispatchFunction(source, Coords, PlayerId, VehicleEntity)
    print(source, Coords, PlayerId, VehicleEntity)
end


-- Add your custom FuelEvenet
function SetFuelLevel(vehicle, fuelAmmount)
   -- Ox_Fuel
   Entity(vehicle).state.fuel = fuelAmmount

   -- print(vehicle, fuelAmmount)
end

function PlateEqual(valueA, valueB)
    valueA = tostring(valueA)
    valueB = tostring(valueB)
    valueA = valueA:gsub("%s", ""):lower()
    valueB = valueB:gsub("%s", ""):lower()
    return valueA == valueB
end

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

function CapitalizeFirstLetter(string)
    return string:gsub("(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)
end

function TextUI(text)
    lib.showTextUI(text, {
        icon = 'car',
    })
end

function HideTextUI()
    lib.hideTextUI()
end
