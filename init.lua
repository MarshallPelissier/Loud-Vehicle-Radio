local LoudVehicleRadio = { version = "1.0.0" }
local Cron = require("Modules/Cron")
local Audio = require("Modules/audio")
--local Classes = require("Modules/Classes")

local disableRadioPort = false

-- Data to allow multiple vehicles at the same time
function vehicle()
    local self = {
        base = nil,
        record = nil,
        station = nil,
        stationExt = nil,
        playing = false,
        lastLoc = nil,
        entering = false,
        data = Audio.audio(),
    }
    self.data.Initialize()
    return self
end

-- Save data for reloading and summoning vehicles
function save()
    local self = {
        base = nil,
        record = nil,
        station = nil,
        stationExt = nil,
        playing = false,
        reattach = nil,
        update = nil,
    }
    return self
end

LoudVehicleRadio = {}

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

Vehicle = nil

Save = nil

VehicleList = {
    count = 0,
    list = {},
}

SaveList = {
    count = 0,
    list = {},
}

function AddVehicle(veh)
    if not IsInVehicleList(veh) then
        AddList(VehicleList.list, veh)
        VehicleList.count = VehicleList.count + 1
    end
end

function RemoveVehicle(veh)
    if IsInVehicleList(veh) then
        RemoveList(VehicleList.list, veh)
        VehicleList.count = VehicleList.count - 1
    end
end

function IsInVehicleList(veh)
    return IsInVehicleListRecord(veh.record) ~= nil
end

function IsInVehicleListRecord(record)
    for i, v in ipairs(VehicleList.list) do
        if v.record == record then
            return v
        end
    end

    return nil
end

function AddSave(save)
    if not IsInSaveList(save) then
        AddList(SaveList.list, save)
        SaveList.count = SaveList.count + 1
    end
end

function RemoveSave(save)
    if IsInSaveList(save) then
        RemoveList(SaveList.list, save)
        SaveList.count = SaveList.count - 1
    end
end

function IsInSaveList(save)
    return IndexOf(SaveList.list, save) ~= -1
end

function AddList(list, item)
    table.insert(list, item)
end

function RemoveList(list, item)
    table.remove(list, IndexOf(list,item))
end


--RadioToggleEvent
---@class RadioToggleEvent : redEvent
RadioToggleEvent = {}

---@return RadioToggleEvent
function RadioToggleEvent.new() return end

local updateTimer = nil
local spawnTimer = nil
local rot = nil
local pocketUnmount = false
local radioPortActive = false
local despawnSameVehicle = false
local delayCounter = 0


function Cleanup()
    for i,v in ipairs(VehicleList.list) do
        v.data.DespawnRadio(v.data)

        v.base = nil
        v.record = nil
        v.station = nil
        v.stationExt = nil
        v.playing = false
        v.lastLoc = nil
        v.entering = false
    end

    radioPortActive = false

    Cron.Resume(updateTimer)
end


-- Vehicle and Radio Data
function GetPocketRadio()
    return Game.GetPlayer():GetPocketRadio()
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

function HasMountedVehicle()
    return not not Game['GetMountedVehicle;GameObject'](Game.GetPlayer())
end

function IsPlayerDriver()
    local veh = Game['GetMountedVehicle;GameObject'](Game.GetPlayer())
    if veh then
        return veh:IsPlayerDriver()
    end
end

function IsPlayerVehicle()
    return Vehicle.base:IsPlayerVehicle()
end

function GetVehicleBase()
    return Game['GetMountedVehicle;GameObject'](Game.GetPlayer())
end

function GetMountedVehicleRecord()
    return Vehicle.base:GetRecordID()
end

function GetVehiclePlaying()
    return Vehicle.base:IsRadioReceiverActive()
end

function GetVehicleStation()
    return IndexOf(VehicleStationList, Vehicle.base:GetRadioReceiverStationName().value) - 1
end

function GetRadioExtStation()
    local radioExt = GetMod("radioExt")
    if radioExt then
        if radioExt.radioManager.managerV:getActiveStationData() then
            return Vehicle.data.GetRadioID(radioExt.radioManager.managerV:getActiveStationData().station)
        end
    end
    return nil
end

function SetVehicleRadioData()
    Vehicle.record = GetMountedVehicleRecord()
    Vehicle.playing = Vehicle.base:WasRadioReceiverPlaying()
    Vehicle.station = GetVehicleStation()
    Vehicle.stationExt = GetRadioExtStation()
end

function OnVehicleEntered()

    despawnSameVehicle = false
    local tempBase = GetVehicleBase()
    local tempVeh = IsInVehicleListRecord(tempBase:GetRecordID())
    print("List Count: ", VehicleList.count)
    if tempVeh ~= nil then
        print("Is In List: ", IsInVehicleList(tempVeh))
    end

    if tempVeh ~= nil and IsInVehicleList(tempVeh) then
        Vehicle = tempVeh
        despawnSameVehicle = true
    elseif Vehicle == nil or Vehicle.base == nil or Vehicle.record ~= tempBase:GetRecordID() then
        print("New Vehicle")
        Vehicle = vehicle()
        print("Spawned: ", Vehicle.data.spawned)
    end
    
    Vehicle.base = tempBase

    SetVehicleRadioData()
    radioPortActive = GetPocketRadio():IsActive()
end

function OnVehicleExited()
    AddVehicle(Vehicle)
    Cron.Resume(spawnTimer)
end

function SpawnSetRadio()
    if Vehicle.data.spawned then
        print("Set Radio")
        if Vehicle.stationExt then
            Vehicle.data.SetRadio(Vehicle.stationExt, true, Vehicle.data)
        else
            Vehicle.data.SetRadio(Vehicle.station, Vehicle.playing, Vehicle.data)
        end
        Vehicle.data.ready = true
        Cron.Pause(spawnTimer)
    else
        print("Spawn Radio")
        Vehicle.data.SpawnRadios(Vehicle.base:GetWorldTransform(), Vehicle.data)
    end
end

function Update()
    if pocketUnmount then
        if (not radioPortActive or disableRadioPort) and GetPocketRadio():IsActive() then
            local evt = RadioToggleEvent.new()
            GetPocketRadio():HandleRadioToggleEvent(evt)
        end
        pocketUnmount = false
    end

    if Vehicle.data.ready then
        -- moves speaker with vehicle until it comes to a full stop
        for i,v in ipairs(VehicleList.list) do
            local pos = v.base:GetWorldTransform().Position
            if not VectorCompare(pos, v.lastLoc) then
                v.data.TeleportRadio(pos, rot, v.data)
                v.lastLoc = pos
            end
        end

        if despawnSameVehicle then
            -- starts Despawn delay after entering vehicle
            if Vehicle.entering and not IsEnteringVehicle() then
                delayCounter = 1
            end
            if delayCounter == Vehicle.data.despawnDelay then
                print("despawn counter")
                delayCounter = 0
                Vehicle.data.DespawnRadio(Vehicle.data)
                despawnSameVehicle = false
            elseif delayCounter > 0 then
                delayCounter = delayCounter + 1
            end
            Vehicle.entering = IsEnteringVehicle()
        end
    end
end

--Utility
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

function LoudVehicleRadio:New()
    registerForEvent("onInit", function()

        rot = EulerAngles.new(0,90,0)

        Observe('hudCarController', 'OnMountingEvent', function()
            OnVehicleEntered()
        end)

        Observe('VehicleComponentPS', 'OnVehicleStartedUnmountingEvent', function()
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

            -- print("OnVehicleRadioEvent")
            -- print("Toggle: ", evt.toggle)
            -- print("Set Station: ", evt.setStation)
            -- print("Station ID: ", evt.station)
            Vehicle.station = evt.station
            Vehicle.playing = evt.toggle;

            if (not evt.toggle and evt.station == -1) then
                Vehicle.stationExt = GetRadioExtStation()
                if Vehicle.stationExt ~= nil then
                    Vehicle.playing = true;
                end
            end
        end)

        Observe('VehicleComponent', 'OnRadioToggleEvent', function(_, evt)
            local active = not _:GetVehicle():IsRadioReceiverActive()
            if active then
                Vehicle.station = GetVehicleStation()
                Vehicle.stationExt = GetRadioExtStation()
                Vehicle.playing = true;
            else
                Vehicle.playing = false;
            end
        end)

        Observe('LoadGameMenuGameController', 'OnUninitialize', function()
            Cleanup()
        end)

        Observe('PlayerPuppet', 'OnDeath', function()
            Cleanup()
        end)

        Observe('PocketRadio', 'HandleVehicleUnmounted', function()
            Cron.Resume(updateTimer)
            pocketUnmount = true
        end)
    end)

    registerForEvent("onUpdate", function(delta)
        Cron.Update(delta)
    end)

    registerForEvent("onShutdown", function()
        Cleanup()
    end)

    spawnTimer = Cron.Every(.1, SpawnSetRadio)
    Cron.Pause(spawnTimer)

    updateTimer = Cron.Every(.1, Update)
    Cron.Pause(updateTimer)

    return {
      version = LoudVehicleRadio.version
    }
end

return LoudVehicleRadio:New()