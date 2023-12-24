-- Data to allow multiple vehicles at the same time
Vehicle = {}
Vehicle.__index = Vehicle

function Vehicle.new()
    local o = setmetatable({}, Vehicle)

    o.base = nil
    o.record = nil
    o.station = nil
    o.stationExt = nil
    o.playing = false
    o.lastLoc = nil
    o.entering = false
    o.data = audio.data:new()

    return o
end

function Vehicle:g_base()
    return self.base
end

function Vehicle:s_base(val)
    self.base = val
end

function Vehicle:g_record()
    return self.base
end

function Vehicle:s_record(val)
    self.record = val
end

function Vehicle:g_station()
    return self.station
end

function Vehicle:s_station(val)
    self.station = val
end

function Vehicle:g_stationExt()
    return self.stationExt
end

function Vehicle:s_stationExt(val)
    self.stationExt = val
end

function Vehicle:g_playing()
    return self.playing
end

function Vehicle:s_playing(val)
    self.playing = val
end

function Vehicle:g_lastloc()
    return self.lastloc
end

function Vehicle:s_lastloc(val)
    self.lastloc = val
end

function Vehicle:g_entering()
    return self.entering
end

function Vehicle:s_entering(val)
    self.entering = val
end

function Vehicle:g_data()
    return self.data
end

function Vehicle:s_data(val)
    self.data = val
end


-- Save data for reloading and summoning vehicles
Save = {}
Save.__index = Save

function Save.new()
    local o = setmetatable({}, Save)

    o.base = nil
    o.record = nil
    o.station = nil
    o.stationExt = nil
    o.playing = false
    o.reattach = nil
    o.update = nil

    return o
end

function Save:g_base()
    return self.base
end

function Save:s_base(val)
    self.base = val
end

function Save:g_record()
    return self.base
end

function Save:s_record(val)
    self.record = val
end

function Save:g_station()
    return self.station
end

function Save:s_station(val)
    self.station = val
end

function Save:g_stationExt()
    return self.stationExt
end

function Save:s_stationExt(val)
    self.stationExt = val
end

function Save:g_playing()
    return self.playing
end

function Save:s_playing(val)
    self.playing = val
end

function Save:g_reattach()
    return self.reattach
end

function Save:s_reattach(val)
    self.reattach = val
end

function Save:g_update()
    return self.update
end

function Save:s_update(val)
    self.update = val
end

-- Data saved for multiple radios
Data = {}
Data.__index = Data

function Data.new()
    local o = setmetatable({}, Vehicle)

    o.radios = {}

    return o
end

function Data:g_radios()
    return self.radios
end

function Data:s_radios(val)
    self.radios = val
end