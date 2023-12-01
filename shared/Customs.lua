Garages.Customs = {

    -- Rent a vehicles
    ['Rent a Bike'] = {
        debug     = false,
        job       = false,
        intocar   = true,
        npc       = {
            pos = vec4(-1108.6517333984, -1693.3645019531, 3.52370262146, 308.74691772461),
            hash = 'a_m_y_dhill_01'
        },
        blip      = {
            sprite = 226,
            size = 0.5,
            color = 2
        },
        garagepos = {
            vec3(-1104.0, -1680.0, 4.0),
            vec3(-1121.0, -1691.0, 4.0),
            vec3(-1108.0, -1709.0, 4.0),
            vec3(-1091.0, -1697.0, 4.0),
        },
        thickness = 6.0,
        spawnpos  = {
            vec4(-1104.4356689453, -1694.1052246094, 3.3498411178589, 280.41430664063),
            vec4(-1105.2770996094, -1692.9571533203, 3.3505659103394, 280.41430664063),
            vec4(-1106.0260009766, -1691.8848876953, 3.3506450653076, 280.41430664063),
        },
        vehicles  = {
            { name = 'BMX', model = 'bmx', plate = 'MON1RENT', priceMin = 5 },
            { name = 'Cruiser', model = 'cruiser', plate = 'MON2RENT', priceMin = 5 },
            { name = 'Fixter', model = 'fixter', plate = 'MON3RENT', priceMin = 5 },
            { name = 'Scorcher', model = 'scorcher', plate = 'MON4RENT', priceMin = 5 },
            { name = 'Electric bike', model = 'inductor', plate = 'MON4RENT', priceMin = 10 },
        },
    },
    
     --[[ Vehicles for jobs no owner
    ['LSPD Vehicles Custom'] = {
        debug     = false,
        job       = 'police',
        intocar   = true,
        npc       = {
            pos = vec4(457.27026367188,-1007.4309082031,27.297456741333,195.85415649414),
            hash = 'csb_trafficwarden'
        },
        blip      = {
            sprite = 474,
            size = 0.5,
            color = 0
        },
        garagepos = {
            vec3(411.0, -1002.0, 29.0),
            vec3(411.0, -1035.0, 29.0),
            vec3(492.0, -1028.0, 29.0),
            vec3(492.0, -1002.0, 29.0),
        },
        thickness = 6.0,
        spawnpos  = {
            vec4(449.81292724609,-1018.3796386719,27.528268814087,330.99160766602)
        },
        vehicles  = {
            { name = 'police', model = 'sultan', plate = 'MONO V20', grade = 1 },
            { name = 'police', model = 'sultan', plate = 'MONO V20', grade = 'boss' },
        },
    },]]
    

}
