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
    entering = false
}

Checks = {
    count = 0,
    spawned = false,
    startup = true
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

    Checks.count = 0
    Checks.spawned = true
    Checks.startup = true
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
    Checks.count = 0
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

-- function SetSpeaker()
--     if Game.FindEntityByID(Speaker.entID) ~= nil then
--         Speaker.entity = Game.FindEntityByID(Speaker.entID)
--         Speaker.entity:GetDevicePS():SetCurrentStation(SpeakerStationList[Vehicle.station])
--         if not Speaker.active then
--             Speaker.entity:TurnOnDevice()
--             Speaker.active = true
--         end
--     end
-- end

-- function Spawn()
--     print("Spawn Speaker")
--     local transform = Vehicle.base:GetWorldTransform()
--     Speaker.entID = exEntitySpawner.Spawn(Speaker.path, transform)
--     Checks.spawned = true
-- end

-- function Despawn()
--     if Game.FindEntityByID(Speaker.entID) ~= nil then
--         print("Despawn Speaker")
--         Game.FindEntityByID(Speaker.entID):GetEntity():Destroy()
--         Checks.spawned = false
--         Speaker.entID = nil
--         Speaker.entity = nil
--         Speaker.active = false
--     end
-- end

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
        if not audio.ready and IsExitingVehicle() then
            if audio.spawned then
                audio.SetSpeaker(Vehicle.station)
            else
                audio.SpawnAll(Vehicle.base:GetWorldTransform())
            end
        elseif audio.ready then
            -- Check if vehicle radio station has changed
            if StationChanged() then
                Vehicle.station = GetVehicleStation()
                -- Speaker.active = false
                audio.SetSpeaker(Vehicle.station)
            end

            -- moves speaker with vehicle until it comes to a full stop
            local pos = Vehicle.base:GetWorldTransform().Position
            if VectorCompare(pos, Vehicle.lastLoc) then
                if Vehicle.mounted == false then
                    Checks.count = Checks.count + 1
                end
            else
                audio.Teleport(pos, rot)
                Vehicle.lastLoc = pos
                Checks.count = 0
            end

            if Vehicle.entering and not IsEnteringVehicle() then
                Vehicle.entering = false
                audio.counter = 1
            end
            
            if audio.counter == audio.despawnDelay then
                audio.counter = 0
                audio.Despawn()
            elseif audio.counter > 0 then
                audio.counter = audio.counter + 1
            end

            Vehicle.entering = IsEnteringVehicle()
        end
    else
        print("Pause")
        Cron.Pause(timer)
    end

    -- stops the timer if the car has been exited, the car has come to a stop, and the speaker is already spawned
    if audio.spawned and Checks.count > 4 then
        Cron.Pause(timer)
        Checks.count = 0
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
