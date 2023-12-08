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

VehicleStationList2 = {
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
    stationExt = nil,
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
    stationExt = nil,
    playing = false,
    vehicle = nil
}

local timer = nil
local rot = nil
local playingCheck = false
local lastVehicle = nil
--local radioExt = nil

LoudVehicleRadio = {}

function Cleanup()
    audio.DespawnRadio()

    Vehicle.base = nil
    Vehicle.record = nil
    Vehicle.station = nil
    Vehicle.stationExt = nil
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
    Save.stationExt = nil
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
    if Vehicle.record ~= nil and lastVehicle ~= nil and Vehicle.record ~= lastVehicle then
        audio.DespawnRadio()
    end
    if Vehicle.base ~= nil then
        Vehicle.count = 0
        Cron.Resume(timer)
    end
end

function OnVehicleExited()
    if not audio.ready and not audio.spawned then
        Vehicle.ejected = true
    end
    playingCheck = false
    lastVehicle = Vehicle.record
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

    if Vehicle.base ~= nil then
        if not Vehicle.base:IsPlayerDriver() then
            Vehicle.base = nil
        else
            Vehicle.record = GetMountedVehicleRecord()
            Vehicle.station = GetVehicleStation()
            print("Data: ", Vehicle.station)
            Vehicle.stationExt = GetRadioExtStation()
            if lastVehicle ~= nil then
                if Vehicle.record ~= lastVehicle then
                    Vehicle.playing = GetVehiclePlaying()
                end
            end
        end
    end
end

function GetVehicleStation()
    local radioExt = GetMod("radioExt")
    if radioExt then
        return IndexOf(VehicleStationList2, Vehicle.base:GetRadioReceiverStationName().value) - 1
    else
        return IndexOf(VehicleStationList, Vehicle.base:GetRadioReceiverStationName().value)
    end
end

function GetRadioExtStation()
    local radioExt = GetMod("radioExt")
    if radioExt then
        if radioExt.radioManager.managerV:getActiveStationData() then
            return audio.GetRadioID(radioExt.radioManager.managerV:getActiveStationData().station)
        end
    end
    return nil
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
        Save.stationExt = Vehicle.stationExt
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
        Vehicle.playing = GetVehiclePlaying()
    end

    if Vehicle.base ~= nil then
        if IsEnteringVehicle() then
            playingCheck = true
        elseif not IsEnteringVehicle() and playingCheck then
            if not Vehicle.playing then
                Vehicle.playing = GetVehiclePlaying()
            end
            playingCheck = false
        end

        if not audio.ready and (IsExitingVehicle() or Vehicle.ejected) then
            if audio.spawned then
                Vehicle.station = GetVehicleStation()
                print("Exiting: ", Vehicle.station)
                Vehicle.stationExt = GetRadioExtStation()
                print("EXT: ", Vehicle.stationExt)
                if Vehicle.stationExt then
                    print("EXT Set")
                    audio.SetRadio(Vehicle.stationExt, true)
                else
                    print("Regular Set")
                    audio.SetRadio(Vehicle.station, Vehicle.playing)
                end
                audio.ready = true
                Vehicle.ejected = false
                Vehicle.detached = false
            else
                audio.SpawnRadios(Vehicle.base:GetWorldTransform())
            end
        elseif audio.ready then
            -- moves speaker with vehicle until it comes to a full stop
            local pos = Vehicle.base:GetWorldTransform().Position
            if not VectorCompare(pos, Vehicle.lastLoc) then
                audio.TeleportRadio(pos, rot)
                Vehicle.lastLoc = pos
                Vehicle.count = 0
            end

            -- starts Despawn delay after entering vehicle
            if Vehicle.entering and not IsEnteringVehicle() then
                audio.counter = 1
            end
            if audio.counter == audio.despawnDelay then
                audio.counter = 0
                audio.DespawnRadio()
            elseif audio.counter > 0 then
                audio.counter = audio.counter + 1
            end
            Vehicle.entering = IsEnteringVehicle()
        end

        -- checks if Vehicle has been destroyed then cleans up
        if Vehicle.base:IsDestroyed() then
            audio.DespawnRadio()
            Cron.Pause(timer)
        end
        
    elseif Save.reattach then
        if audio.spawned then
            audio.SetRadio(Save.station, Save.playing)
            audio.ready = true
            Save.reattach = false
            Vehicle.base = Save.vehicle
        else
            audio.SpawnRadios(Save.vehicle:GetWorldTransform())
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
    end)

    registerForEvent("onUpdate", function(delta)
        Cron.Update(delta)
    end)

    registerForEvent("onShutdown", function()
        Cleanup()
        ResetSave()
    end)

    Cron.After(0.1, function ()
        audio.Initialize()
    end)

    timer = Cron.Every(.1, Update)

    return {
      version = LoudVehicleRadio.version
    }
end

return LoudVehicleRadio:New()