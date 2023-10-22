audio = {
    path = "base\\gameplay\\devices\\home_appliances\\radio_sets\\speaker_virtual.ent",
    speakers = {},
    active = false,
    spawned = false,
    ready = false,
    station = nil,
    stationList = {
        "radio_station_02_aggro_ind",
        "radio_station_03_elec_ind",
        "radio_station_04_hiphop",
        "radio_station_07_aggro_techno",
        "radio_station_09_downtempo",
        "radio_station_01_att_rock",
        "radio_station_05_pop",
        "radio_station_10_latino",
        "radio_station_11_metal",
        "radio_station_06_minim_techno",
        "radio_station_08_jazz",
        "radio_station_12_growl_fm",
        "radio_station_13_dark_star",
        "radio_station_14_impulse_fm",
    },
    volume = 4,
    despawnDelay = 7,
    counter = 0,
}


function audio.SetSpeaker(currentStation)
    print("Set Speakers")
    local station = audio.stationList[currentStation]
    print(station)
    for _, s in pairs(audio.speakers) do
        local speaker = Game.FindEntityByID(s)
        speaker:GetDevicePS():SetCurrentStation(station)
        speaker:TurnOnDevice()
    end
    audio.ready = true
end

function audio.SpawnAll(transform)
    print("Spawn All")
    for i = 1, audio.volume, 1 do
        audio.Spawn(transform)
    end
    audio.ready = false
    
    local count = 0
    for _ in pairs(audio.speakers) do count = count + 1 end
    print("Radios: ", count)
    print(" ")
    audio.spawned = true
end

function audio.Spawn(transform)
    local entID = exEntitySpawner.Spawn(audio.path, transform)
    table.insert(audio.speakers, entID)

end

function audio.Despawn()
    print("Despawn")
    for _, s in pairs(audio.speakers) do
        Game.FindEntityByID(s):GetEntity():Destroy()
    end
    audio.speakers = {}
    audio.spawned = false
    audio.active = false
    audio.ready = false
end

function audio.Teleport(position, rotation)
    for _, s in pairs(audio.speakers) do
        local speaker = Game.FindEntityByID(s)
        Game.GetTeleportationFacility():Teleport(speaker, VectorFromPosition(position) , rotation)
    end
end

return audio