local LoudVehicleRadio = { version = "0.0.0" }
local Cron = require("Modules/Cron")

VehicleStationList = {
    "Gameplay-Devices-Radio-RadioStationAggroIndie",
    "Gameplay-Devices-Radio-RadioStationElectroIndie",
    "Gameplay-Devices-Radio-RadioStationHipHop",
    "Gameplay-Devices-Radio-RadioStationAggroTechno",
    "Gameplay-Devices-Radio-RadioStationDownTempo",
    "Gameplay-Devices-Radio-RadioStationAttRock",
    "Gameplay-Devices-Radio-RadioStationPop",
    "Gameplay-Devices-Radio-RadioStationLatino",
    "Gameplay-Devices-Radio-RadioStationMetal",
    "Gameplay-Devices-Radio-RadioStationMinimalTechno",
    "Gameplay-Devices-Radio-RadioStationJazz",
    "Gameplay-Devices-Radio-RadioStationGrowlFm",
    "Gameplay-Devices-Radio-RadioStationDarkStar",
    "Gameplay-Devices-Radio-RadioStationImpulseFM",
}

SpeakerStationList = {
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
}

Speaker = {
    path = "base\\gameplay\\devices\\home_appliances\\radio_sets\\speaker_virtual.ent",
    entID = nil,
    entity = nil
}

Vehicle = {
    base = nil,
    record = nil,
    station = nil,
    lastLoc = nil,
    mounted = false
}

Checks = {
    count = 0,
    spawned = false
}

local timer = nil
local rot = nil

LoudVehicleRadio = {}

function LoudVehicleRadio:New()
    registerForEvent("onInit", function()
        
        rot = EulerAngles.new(0,0,0)
        Observe('hudCarController', 'OnMountingEvent', function()
            OnVehicleEntered()
        end)

        Observe('hudCarController', 'OnUnmountingEvent', function()
            OnVehicleExited()
        end)

        if HasMountedVehicle() then
            GetVehicleData()
        end
    end)
    
    registerForEvent("onUpdate", function(delta)
        Cron.Update(delta)
    end)

    timer = Cron.Every(.1, Update)

    return {
      version = LoudVehicleRadio.version
    }
end

function Update()
    if Vehicle.base ~= nil then
        if Speaker.entity == nil then
            if Checks.spawned then
                SetSpeaker()
            else
                Spawn()
            end
        else
            if StationChanged() then
                Vehicle.station = GetVehicleStation()
                SetSpeaker()
            end

            local pos = Vehicle.base:GetWorldTransform().Position

            if VectorCompare(pos, Vehicle.lastLoc) then
                if Vehicle.mounted == false then
                    Checks.count = Checks.count + 1
                end
            else
                Game.GetTeleportationFacility():Teleport(Speaker.entity, VectorFromPosition(pos) , rot)
                Vehicle.lastLoc = pos
                Checks.count = 0
            end
        end
    else
        Cron.Pause(timer)
    end

    if Speaker.entID ~= nil and Checks.count > 4 then
        Cron.Pause(timer)
        Checks.count = 0
    end
end

function GetVehicleData()
    Vehicle.base = Game['GetMountedVehicle;GameObject'](Game.GetPlayer())
    Vehicle.base:ToggleRadioReceiver(true)
    Vehicle.record = GetMountedVehicleRecord()
    Vehicle.station = GetVehicleStation()
end

function GetVehicleStation()
    return indexOf(VehicleStationList, Vehicle.base:GetRadioReceiverStationName().value)
end

function StationChanged()
    local station = GetVehicleStation()
    return Vehicle.station ~= station
end

function VectorFromPosition(pos)
    return Vector4.new(pos:GetX(),pos:GetY(),pos:GetZ())
end

function VectorCompare(vector1, vector2)
    if vector1 == nil then
        return false
    end

    if vector2 == nil then
        return false
    end

    if vector1:GetX() == vector2:GetX() and vector1:GetY() == vector2:GetY() and vector1:GetZ() == vector2:GetZ() then
        return true
    end

    return false
end

function HasMountedVehicle()
    return not not Game['GetMountedVehicle;GameObject'](Game.GetPlayer())
end

function GetMountedVehicleRecord()
    local veh = Game['GetMountedVehicle;GameObject'](Game.GetPlayer())
    if veh then
        return veh:GetRecordID()
    end
end

function OnVehicleEntered()
    Vehicle.mounted = true
    Checks.count = 0
    if Vehicle.record ~= GetMountedVehicleRecord() then
        GetVehicleData()
        Despawn()
    end
    Cron.Resume(timer)
end

function OnVehicleExited()
    Vehicle.mounted = false
end

function Spawn()
    local transform = Vehicle.base:GetWorldTransform()
    Speaker.entID = exEntitySpawner.Spawn(Speaker.path, transform)
    Checks.spawned = true
end

function Despawn()
    if Game.FindEntityByID(Speaker.entID) ~= nil then
        Game.FindEntityByID(Speaker.entID):GetEntity():Destroy()
        Checks.spawned = false
        Speaker.entID = nil
        Speaker.entity = nil
    end
end

function SetSpeaker()
    if Game.FindEntityByID(Speaker.entID) ~= nil then
        Speaker.entity = Game.FindEntityByID(Speaker.entID)
        Speaker.entity:GetDevicePS():SetCurrentStation(SpeakerStationList[Vehicle.station])
        Speaker.entity:PlayAllSounds()
    end
end

-- Return the first index with the given value (or nil if not found).
function indexOf(array, value)
    for i, v in ipairs(array) do
        if v == value then
            return i
        end
    end
end

return LoudVehicleRadio:New()
