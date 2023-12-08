audio = {
    active = false,
    spawned = false,
    ready = false,
    volume = 3,
    despawnDelay = 7,
    counter = 0,
}

radio = {
    path = "base\\quest\\main_quests\\prologue\\q000\\entities\\q000_invisible_radio.ent",
    radios = {},
    stations = {
        [0] = "Radio Vexelstrom",
        [1] = "Night FM",
        [2] = "The Dirge",
        [3] = "Radio Pebkac",
        [4] = "Pacific Dreams",
        [5] = "Morro Rock Radio",
        [6] = "Body Heat Radio",
        [7] = "30 Principales",
        [8] = "Ritual FM",
        [9] = "Samizdat Radio",
        [10] = "Royal Blue Radio",
        [11] = "Growl FM",
        [12] = "Dark Star",
        [13] = "Impulse",
    },
}

function audio.Initialize()
    local radioExt = GetMod("radioExt")
    if radioExt then
        local rs = radioExt.radioManager.radios

        for k, r in ipairs(rs) do
            radio.stations[13 + k] = r.name
        end
    end
end

function audio.GetRadioID(stationName)
    for key, value in pairs(radio.stations) do
        if value == stationName then
            return key
        end
    end
end

function audio.SetRadio(currentStation, isPlaying)
    for _, r in pairs(radio.radios) do
        local ent = Game.FindEntityByID(r)
        if ent ~= nil then
            if isPlaying then
                local ps = ent:GetDevicePS()
                ps.activeStation = currentStation
                ent:PlayGivenStation()
            else
                ent:TurnOffDevice()
            end
        end
    end
end

function audio.SpawnRadios(transform)
    audio.ready = false
    for i = 1, audio.volume, 1 do
        audio.SpawnRadio(transform)
    end
    audio.spawned = true
end

function audio.SpawnRadio(transform)
    local entID = exEntitySpawner.Spawn(radio.path, transform)
    table.insert(radio.radios, entID)
end

function audio.DespawnRadio()
    for _, s in pairs(radio.radios) do
        if s ~= nil then
            local ent = Game.FindEntityByID(s)
            if ent ~= nil then
                ent:GetEntity():Destroy()
            end
        end
    end
    radio.radios = {}
    audio.spawned = false
    audio.ready = false
    audio.active = false
end

function audio.TeleportRadio(position, rotation)
    for _, r in pairs(radio.radios) do
        local radio = Game.FindEntityByID(r)
        Game.GetTeleportationFacility():Teleport(radio, VectorFromPosition(position) , rotation)
    end
end

return audio