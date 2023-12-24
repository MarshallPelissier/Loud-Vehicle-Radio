local Audio = {}

function Audio.audio()
    local self = {
        active = false,
        spawned = false,
        ready = false,
        radios = {},
    }

    local volume = 3

    local radio = {
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

    function self.Initialize()
        local radioExt = GetMod("radioExt")
        if radioExt then
            local rs = radioExt.radioManager.radios

            for k, r in ipairs(rs) do
                radio.stations[13 + k] = r.name
            end
        end
    end

    function self.GetRadioID(stationName)
        for key, value in pairs(radio.stations) do
            if value == stationName then
                return key
            end
        end
    end

    function self.SetRadio(currentStation, isPlaying)
        for _, r in pairs(self.radios) do
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

    function self.SpawnRadios(transform)
        self.ready = false
        self.spawned = true
        for i = 1, volume, 1 do
            self.SpawnRadio(transform)
        end
    end

    function self.SpawnRadio(transform)
        local entID = exEntitySpawner.Spawn(radio.path, transform)
        table.insert(self.radios, entID)
    end

    function self.DespawnRadio()
        for _, s in pairs(self.radios) do
            if s ~= nil then
                local ent = Game.FindEntityByID(s)
                if ent ~= nil then
                    ent:GetEntity():Destroy()
                end
            end
        end
        self.radios = {}
        self.spawned = false
        self.ready = false
        self.active = false
    end

    function self.TeleportRadio(position, rotation)
        for _, r in pairs(self.radios) do
            local radio = Game.FindEntityByID(r)
            Game.GetTeleportationFacility():Teleport(radio, VectorFromPosition(position) , rotation)
        end
    end

    return self
end

return Audio