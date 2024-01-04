# <center>   MONO  GARAGE V2

# ❗ Dependencies 
- oxmysql - https://github.com/overextended/oxmysql
- ox_lib - https://github.com/overextended/ox_lib
- ox_inventory - https://github.com/overextended/ox_inventory
 
# 💻 Installation 

- It is important to use the latest Gamebuild version.
- In your server.cfg, add the following line: ```set sv_enforceGameBuild 2944```
- ensure mono_garage.
- Automatically creates the necessary data in the database.

# 📑Features
- Available languages: **ES** | **EN** | **PL** | **FR** | **IT** | **DE** | **PT**
- **[Garages]**: Garages for owned vehicles and jobs with owned vehicles.
- **[Impound]**: Vehicle impound lots with various options.
- **[Customs]**: Allows creating garages with vehicles from a list for jobs or setting up vehicle rental spots.
- Verification of duplicate vehicles.
- Ensures that a spawned vehicle in the garage always exists; otherwise, it will be sent to the impound.
- Command to spawn a vehicle with the option to add it as property to the database.
- Command to remove a plate from the database.
- Command to spawn a vehicle with a timer to be removed after a specific time.
- Command to send all vehicles of a type ("all", "air", "car", "boat") to a default garage.
- Export *(Client/Server)* to create or delete keys.
- Use of PolyZone or BoxZone in the garage position (ox_lib).
- Share vehicles with friends.
- Vehicles: density, doors, lockpick, hotwire, engine.
- Keys work as items or through the database-> (50%).
- Mark vehicle on the map if it's outside.
- Send the vehicle to the impound if it's outside.
- FakePlate system, an item that sets a fake  plate with a timer to a owned vehicle. (You can store the vehicle with the fakeplate.)
- Target to send vehicles to the impound.


- - ## Commandos
- ### /givecar [ID] [MODEL] [TYPE] [true/fale]  
- - **ID** = source player
- - **MODEL** = Vehicle Model 
- - **MODEL** = car | air | boat If owner  true
- - **BOOLEAN** = (Optional) Set Vehicle owner true, false only spawn default.
- ### /delplate [PLATE]  
- - **PLATE** = Borrar vehiculo de la base de datos por la matricula. (Escribir sin espacios la matricula)
- ### /cartimer [ID] [MODEL] [TIME] 
- - **ID** = source player
- - **MODEL** = Vehicle Model 
- - **TIME** = Timer in minutes
- ### /sendall [TYPE] 
- - **TYPE** = "all", "air", "car","boat"


# 🔩 Exports / Events

## Client

- Give or Remove Keys
```lua
--  actio = 'add' or 'revome'
    exports.mono_garage:ClientInventoryKeys(action, plate) 
```
- Open Owner Garage 
```lua
    exports.mono_garage:OpenGarage({
        name = 'Mono Garage'
		intocar = false,
		type = 'car',
		defaultImpound = 'LSPD Impound',
		priceImpound = 0,
        spawnpos  = {
            vec4(420.0, 420.0, 420.0, 420.0),

        },
    })
```
- Store Owner Vehicle 
```lua
     exports.mono_garage:SaveVehicle({
        name = 'Mono Garage',
        type = 'car',
        entity = GetVehiclePedIsIn(PlayerPedId(), false)
    })
```
- Open Custom Garage
```lua
    
    exports.mono_garage:OpenCustomGarage({
        name      = 'Custom Mono Garage'
        job       = false,
        intocar   = true,
        spawnpos  = {
            vec4(420.0, 420.0, 420.0, 420.0),

        },
        vehicles  = {
        --[[ if job = 'job', Vehicles Job and Grades
            { name = 'police', model = 'sultan', plate = 'MONO V20', grade = 1 },
            { name = 'police', model = 'sultan', plate = 'MONO V20', grade = 'boss' },
          ]]

        --[[ if job = false, Rent a car
            -- { name = 'BMX', model = 'BMX', plate = 'MONORENT', priceMin = 10 }
          ]]
        },
    })
```
- Store  Custom Garage only Jobs not for
```lua
     exports.mono_garage:SaveCustomVehicle({
        name = name,
        entity = GetVehiclePedIsIn(PlayerPedId(), false),
        vehicles  = {
        --[[ if job = 'job', Vehicles Job and Grades
            { name = 'police', model = 'sultan', plate = 'MONO V20', grade = 1 },
            { name = 'police', model = 'sultan', plate = 'MONO V20', grade = 'boss' },
          ]]

        --[[ if job = false, Rent a car
             { name = 'BMX', model = 'BMX', plate = 'MONORENT', priceMin = 10 }
          ]]
        }
    })
```


## Server

- Give or Remove Keys
```lua
    local source = source -- Source Player 
    local action = 'add' --  'add' or 'revome'
    exports.mono_garage:InventoryKeys(action, { plate = plate, player = source})
```


# 📦 Items

- carkeys 
```lua
    ['carkeys']  = {
		label = 'Car Keys',
		weight = 10,
		stack = true,
	},
```
- fakeplate 
```lua
   ['fakeplate'] = {
		label = 'Fake Plate',
		weight = 1000,
		stack = false,
		consume = 0,
		server = {
			export = 'mono_garage.FakePlate'
		}
	},
```
- lockpick 
```lua
    ['lockpick'] = {
		label = 'LockPick',
		weight = 390,
		stack = true,
		consume = 0,
		server = {
			export = 'mono_garage.LockPick'
		}
	},
```
- wirecutt 
```lua
    ['wirecutt']                 = {
		label = 'Wire Cutters',
		weight = 500,
		stack = true,
        consume = 0,
		server = {
			export = 'mono_garage.HotWire'
		}
	},
```
