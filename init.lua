local LoudVehicleRadio = { version = "0.0.0" }
local Cron = require("Modules/Cron")

StationList = {
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

-- Return the first index with the given value (or nil if not found).
function indexOf(array, value)
    for i, v in ipairs(array) do
        if v == value then
            return i
        end
    end
    return nil
end

Radio = {
    path = "base\\gameplay\\devices\\home_appliances\\radio_sets\\radio_1.ent",
    entID = nil,
    entity = nil,
    station = ""
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
local rot = EulerAngles.new(0,-90,0)

LoudVehicleRadio = {}

function LoudVehicleRadio:New()

    registerForEvent("onInit", function()
        
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
        if Radio.entity == nil then
            if Checks.spawned then
                SetRadio()
            else
                Spawn()
            end
        else
            if StationChanged() then
                Vehicle.station = GetVehicleStation()
                SetRadio()
            end

            local pos = Vehicle.base:GetWorldTransform().Position

            if VectorCompare(pos, Vehicle.lastLoc) then
                if Vehicle.mounted == false then
                    Checks.count = Checks.count + 1
                end
            else
                Game.GetTeleportationFacility():Teleport(Radio.entity, PositionOffset(pos), rot)
                Vehicle.lastLoc = pos
                Checks.count = 0
            end
        end
    else
        Cron.Pause(timer)
    end

    if Radio.entID ~= nil and Checks.count > 4 then
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
    return indexOf(StationList, Vehicle.base:GetRadioReceiverStationName().value) - 1
end

function StationChanged()
    local station = GetVehicleStation()
    return Vehicle.station == station
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

function PositionOffset(position)
    return Vector4.new(position:GetX(), (position:GetY()), position:GetZ() - 0.5)
end

function HasMountedVehicle()
    return not not Game['GetMountedVehicle;GameObject'](Game.GetPlayer())
end

function IsPlayerDriver()
    local veh = Game['GetMountedVehicle;GameObject'](Game.GetPlayer())
    if veh then
        return veh:IsPlayerDriver()
    end
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
    transform:SetPosition(PositionOffset(transform.Position))
    transform:SetOrientation(GetSingleton('EulerAngles').ToQuat(rot))
    Radio.entID = exEntitySpawner.Spawn(Radio.path, transform)
    Checks.spawned = true
end

function Despawn()
    if Game.FindEntityByID(Radio.entID) ~= nil then
        Game.FindEntityByID(Radio.entID):GetEntity():Destroy()
        Checks.spawned = false
        Radio.entID = nil
        Radio.entity = nil
        Radio.station = ""
    end
end

function SetRadio()
    if Game.FindEntityByID(Radio.entID) ~= nil then
        Radio.entity = Game.FindEntityByID(Radio.entID)
        Radio.entity:GetDevicePS():SetActiveStationIndex(Vehicle.station)
        Radio.entity:PlayGivenStation()
    end
end

return LoudVehicleRadio:New()
