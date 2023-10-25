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
    playing = false,
    lastLoc = nil,
    entering = false,
    detached = false,
    ejected = false,
    count = 0,
}

Save = {
    reattach = nil,
    record = nil,
    station = nil,
    playing = false,
    vehicle = nil
}

local timer = nil
local rot = nil

LoudVehicleRadio = {}

function Cleanup()
    audio.Despawn()

    Vehicle.base = nil
    Vehicle.record = nil
    Vehicle.station = nil
    Vehicle.playing = false
    Vehicle.lastLoc = nil
    Vehicle.entering = false
    Vehicle.ejected = false
    Vehicle.count = 0

    Cron.Resume(timer)
end

function ResetSave()
    Save.reattach = nil
    Save.record = nil
    Save.station = nil
    Save.playing = false
    Save.vehicle = nil
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
    GetVehicleData()
    Vehicle.count = 0
    Cron.Resume(timer)
end

function OnVehicleExited()
    if not audio.ready and not audio.spawned then
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
    Vehicle.playing = GetVehiclePlaying()
end

function GetVehicleStation()
    return IndexOf(VehicleStationList, Vehicle.base:GetRadioReceiverStationName().value)
end

function GetVehiclePlaying()
    return Vehicle.base:IsRadioReceiverActive()
end

function CreateSave(veh)
    local record = veh:GetVehicle():GetRecordID()
    
    if Vehicle.record == record then
        Cron.Pause(timer)
        Save.reattach = false
        Save.record = record
        Save.station = Vehicle.station
        Save.playing = Vehicle.playing
        Cleanup()
        Save.vehicle = veh:GetVehicle()
    elseif Save.record == record then
        Cron.Pause(timer)
        Save.reattach = false
        Cleanup()
        Save.vehicle = veh:GetVehicle()
    end
end

function LoadSave(veh)
    if Vehicle.base == nil and Save.record == veh:GetVehicle():GetRecordID() then
        Save.vehicle = veh:GetVehicle()
        if Save.vehicle ~= nil then
            Save.reattach = true
            Cron.Resume(timer)
        end
    end
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

function Update()
    if HasMountedVehicle() and Vehicle.base == nil then
        GetVehicleData()
    end

    if Vehicle.base ~= nil then
        if not audio.ready and (IsExitingVehicle() or Vehicle.ejected) then
            if audio.spawned then
                Vehicle.station = GetVehicleStation()
                audio.SetSpeaker(Vehicle.station, Vehicle.playing)
                audio.ready = true
                Vehicle.ejected = false
                Vehicle.detached = false
            else
                audio.SpawnAll(Vehicle.base:GetWorldTransform())
            end
        elseif audio.ready then
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
    elseif Save.reattach then
        if audio.spawned then
            audio.SetSpeaker(Save.station, Save.playing)
            audio.ready = true
            Save.reattach = false
            Vehicle.base = Save.vehicle
        else
            audio.SpawnAll(Save.vehicle:GetWorldTransform())
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

        Observe('VehicleComponent', 'OnGameDetach', function(veh)
            CreateSave(veh)
        end)

        Observe('VehicleComponent', 'OnSummonStartedEvent', function(veh)
            LoadSave(veh)
        end)

        Observe('VehicleComponent', 'OnVehicleRadioEvent', function(_, evt)
            if evt == nil then
				evt = _
			end

            if Vehicle.base ~= nil and Vehicle.base:GetRecordID() == _:GetVehicle():GetRecordID() and not IsExitingVehicle() then
                Vehicle.playing = evt.toggle
            end
        end)

        Observe('LoadGameMenuGameController', 'OnUninitialize', function()
            Cleanup()
        end)

        Observe('PlayerPuppet', 'OnDeath', function()
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
        ResetSave()
    end)

    timer = Cron.Every(.1, Update)

    return {
      version = LoudVehicleRadio.version
    }
end

return LoudVehicleRadio:New()