local LoudVehicleRadio = { version = "1.0.0" }
local Cron = require("Modules/Cron")
local audio = require("Modules/audio")

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

Vehicle = {
    base = nil,
    record = nil,
    station = nil,
    lastLoc = nil,
    mounted = false,
    entering = false,
    ejected = false,
    count = 0,
}

local timer = nil
local rot = nil

LoudVehicleRadio = {}

function Cleanup()
    audio.Despawn()

    Vehicle.base = nil
    Vehicle.record = nil
    Vehicle.station = nil
    Vehicle.lastLoc = nil
    Vehicle.mounted = false
    Vehicle.entering = false
    Vehicle.ejected = false
    Vehicle.count = 0

    Cron.Resume(timer)
end

function IsEnteringVehicle()
    return IsInVehicle() and Game.GetWorkspotSystem():GetExtendedInfo(Game.GetPlayer()).entering
end
function IsExitingVehicle()
    return IsInVehicle() and Game.GetWorkspotSystem():GetExtendedInfo(Game.GetPlayer()).exiting
end

function IsInVehicle()
    local player = Game.GetPlayer()
    return player and Game.GetWorkspotSystem():IsActorInWorkspot(player)
            and Game.GetWorkspotSystem():GetExtendedInfo(player).isActive
            and HasMountedVehicle()
            and IsPlayerDriver()
end

function OnVehicleEntered()
    print("ENTERED VEHICLE ---")
    if Vehicle.record ~= GetMountedVehicleRecord() then
        GetVehicleData()
    end
    Vehicle.mounted = true
    Vehicle.count = 0
    Cron.Resume(timer)
end

function OnVehicleEntering()
    print("ENTERING VEHICLE")
end

function OnVehicleExiting()
    print("EXITING VEHICLE")
end

function OnVehicleExited()
    print("EXITED VEHICLE ---")
    Vehicle.mounted = false
    print("Ready", audio.ready)
    print("Spawned", audio.spawned)
    if not audio.ready and not audio.spawned then
        print("Ejected")
        Vehicle.ejected = true
    end
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

function GetVehicleData()
    Vehicle.base = Game['GetMountedVehicle;GameObject'](Game.GetPlayer())
    Vehicle.base:ToggleRadioReceiver(true)
    Vehicle.record = GetMountedVehicleRecord()
    Vehicle.station = GetVehicleStation()
end

function GetVehicleStation()
    return IndexOf(VehicleStationList, Vehicle.base:GetRadioReceiverStationName().value)
end

function StationChanged()
    if not Vehicle.base:IsVehicle() then
        GetVehicleData()
    end

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

function IndexOf(array, value)
    for i, v in ipairs(array) do
        if v == value then
            return i
        end
    end
end

-- function PrintPosition(pos)
--     local x = pos:GetX()
--     local y = pos:GetY()
--     local z = pos:GetZ()
--     print("X: " .. x .. " - Y: " .. y .. " - Z: " .. z)
-- end

function Update()
    if HasMountedVehicle() and Vehicle.base == nil then
        GetVehicleData()
    end

    if IsEnteringVehicle() then
        OnVehicleEntering()
    elseif IsExitingVehicle() then
        OnVehicleExiting()
    end

    if Vehicle.base ~= nil then
        if not audio.ready and (IsExitingVehicle() or Vehicle.ejected) then
            if audio.spawned then
                audio.SetSpeaker(Vehicle.station)
                audio.ready = true
                Vehicle.ejected = false
            else
                audio.SpawnAll(Vehicle.base:GetWorldTransform())
            end
        elseif audio.ready then
            -- Check if vehicle radio station has changed
            if HasMountedVehicle() then  
                if StationChanged() then
                    Vehicle.station = GetVehicleStation()
                    audio.SetSpeaker(Vehicle.station)
                end
            end

            -- moves speaker with vehicle until it comes to a full stop
            local pos = Vehicle.base:GetWorldTransform().Position
            if not VectorCompare(pos, Vehicle.lastLoc) then
                audio.Teleport(pos, rot)
                Vehicle.lastLoc = pos
                Vehicle.count = 0
            end

            -- starts Despawn delay after entering vehicle
            if Vehicle.entering and not IsEnteringVehicle() then
                audio.counter = 1
            end
            if audio.counter == audio.despawnDelay then
                audio.counter = 0
                audio.Despawn()
            elseif audio.counter > 0 then
                audio.counter = audio.counter + 1
            end
            Vehicle.entering = IsEnteringVehicle()

            -- checks if Vehicle has been destroyed then cleans up
            if Vehicle.base:IsDestroyed() then
                audio.Despawn()
                Cron.Pause(timer)
            end
        end
    else
        Cron.Pause(timer)
    end
end

function LoudVehicleRadio:New()
    registerForEvent("onInit", function()

        rot = EulerAngles.new(0,90,0)

        Observe('hudCarController', 'OnMountingEvent', function()
            OnVehicleEntered()
        end)

        Observe('hudCarController', 'OnUnmountingEvent', function()
            OnVehicleExited()
        end)

        Observe('LoadGameMenuGameController', 'OnUninitialize', function()
            Cleanup()
        end)
        
        if HasMountedVehicle() then
            GetVehicleData()
        end
    end)

    registerForEvent("onUpdate", function(delta)
        Cron.Update(delta)
    end)

    registerForEvent("onShutdown", function()
        Cleanup()
    end)

    timer = Cron.Every(.1, Update)

    return {
      version = LoudVehicleRadio.version
    }
end

return LoudVehicleRadio:New()
