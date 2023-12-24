audio = {
    volume = 3,
    despawnDelay = 7,
}

data = {}
data.__index = data

function data:new()
    local o = setmetatable({}, data)
    
    o.active = false
    o.spawned = false
    o.ready = false
    o.radios = {}
    o.counter = 0

   	return o
end

radio = {
    path = "base\\quest\\main_quests\\prologue\\q000\\entities\\q000_invisible_radio.ent",
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

function audio:Initialize()
    print("Initialize Audio")
    local radioExt = GetMod("radioExt")
    if radioExt then
        local rs = radioExt.radioManager.radios

        for k, r in ipairs(rs) do
            radio.stations[13 + k] = r.name
        end
    end
end

function audio:GetRadioID(stationName)
    for key, value in pairs(radio.stations) do
        if value == stationName then
            return key
        end
    end
end

function audio:SetRadio(currentStation, isPlaying, data)
    for _, r in pairs(data.radios) do
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

function audio:SpawnRadios(transform, data)
    data.ready = false
    data.spawned = true
    print("Audio Volume: ", audio.volume)
    for i = 1, audio.volume, 1 do
        audio:SpawnRadio(transform, data)
    end
end

function audio:SpawnRadio(transform, data)
    local entID = exEntitySpawner.Spawn(radio.path, transform)
    print("Ent: ", entID)
    print("Table: ", data.radios)
    table.insert(data.radios, entID)
end

function audio:DespawnRadio(data)
    print("despawn")
    for _, s in pairs(data.radios) do
        if s ~= nil then
            local ent = Game.FindEntityByID(s)
            if ent ~= nil then
                ent:GetEntity():Destroy()
            end
        end
    end
    data.radios = {}
    data.spawned = false
    data.ready = false
    data.active = false
end

function audio:TeleportRadio(position, rotation, data)
    for _, r in pairs(data.radios) do
        local radio = Game.FindEntityByID(r)
        Game.GetTeleportationFacility():Teleport(radio, VectorFromPosition(position) , rotation)
    end
end

return audio