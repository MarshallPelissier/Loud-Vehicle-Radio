local LoudVehicleRadio = { version = "1.0.0" }
local Cron = require("Modules/Cron")
local Audio = require("Modules/audio")

LoudVehicleRadio = {}

-- Always turn off Radio Port when exiting vehicle
local disableRadioPort = false

--RadioToggleEvent
---@class RadioToggleEvent : redEvent
RadioToggleEvent = {}

---@return RadioToggleEvent
function RadioToggleEvent.new() return end

local updateTimer = nil
local rot = nil
local pocketUnmount = false
local radioPortActive = false
local despawnSameVehicle = false
local delayCounter = 0
local despawnDelay = 7
local entering = false


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

-- for loading vehicles
Save = {
    playing = false,
    stationExt = 0,
}

-- Data to allow multiple vehicles at the same time
function vehicle()
    local self = {
        base = nil,
        record = nil,
        station = nil,
        stationExt = nil,
        playing = false,
        lastLoc = nil,
        saveStation = nil,
        saveExt = nil,
        savePlaying = false,
        despawn = false,
        timer = nil,
        audio = Audio.audio(),
    }

    self.audio.Initialize()

    function self.SpawnSetRadios()
        if self.audio.spawned then
            if self.stationExt then
                self.audio.SetRadio(self.stationExt, true)
            else
                self.audio.SetRadio(self.station, self.playing)
            end
            self.audio.ready = true
            Cron.Pause(self.timer)
        else
            self.audio.SpawnRadios(self.base:GetWorldTransform())
        end
    end

    function self.StartTimer()
        Cron.Resume(self.timer)
    end

    self.timer = Cron.Every(.1, self.SpawnSetRadios)
    Cron.Pause(self.timer)

    return self
end

Vehicle = nil

VehicleList = {
    count = 0,
    list = {},
}

--Vehicle List
function AddVehicle(veh)
    if veh ~= nil   then
        local v = GetVehicleInListFromRecord(veh.record)
        if v == nil then
            AddList(VehicleList.list, veh)
            VehicleList.count = VehicleList.count + 1
        end
    end
end

function RemoveVehicle(veh)
    if veh ~= nil and IsInVehicleList(veh) then
        RemoveList(VehicleList.list, veh)
        VehicleList.count = VehicleList.count - 1
    end
end

function IsInVehicleList(veh)
    return GetVehicleInListFromRecord(veh.record) ~= nil
end

function GetVehicleInListFromRecord(record)
    return GetItemInListFromRecord(VehicleList.list, record)
end

--Save List
function AddSave(save)
    if save ~= nil and not IsInSaveList(save) then
        AddList(SaveList.list, save)
        SaveList.count = SaveList.count + 1
    end
end

function RemoveSave(save)
    if save ~= nil and IsInSaveList(save) then
        RemoveList(SaveList.list, save)
        SaveList.count = SaveList.count - 1
    end
end

function IsInSaveList(save)
    return GetItemInListFromRecord(save.record) ~= nil
end

function GetSaveInListFromRecord(record)
    return GetItemInListFromRecord(SaveList.list, record)
end

-- List functions
function AddList(list, item)
    table.insert(list, item)
end

function RemoveList(list, item)
    table.remove(list, IndexOf(list,item))
end

function GetItemInListFromRecord(list, record)
    for i, v in ipairs(list) do
        if v.record == record then
            return v
        end
    end

    return nil
end


function Cleanup()
    for i,v in ipairs(VehicleList.list) do
        v.audio.DespawnRadio()
    end
    Vehicle = nil
    pocketUnmount = false
    radioPortActive = false
    despawnSameVehicle = false
    entering = false
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
            return Vehicle.audio.GetRadioID(radioExt.radioManager.managerV:getActiveStationData().station)
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

function MountedVehicle()
    despawnSameVehicle = false
    local tempBase = GetVehicleBase()
    local tempVeh = GetVehicleInListFromRecord(tempBase:GetRecordID())

    if tempVeh ~= nil and IsInVehicleList(tempVeh) then
        Vehicle = tempVeh
        despawnSameVehicle = true
    elseif Vehicle == nil or Vehicle.base == nil or Vehicle.record ~= tempBase:GetRecordID() then
        Vehicle = vehicle()
        Vehicle.base = tempBase
    end

    -- Check for Save Data
    local checkExt = Vehicle.saveExt ~= nil and Vehicle.saveExt ~= -1
    if Vehicle.savePlaying or checkExt then
        if checkExt then
            local radioExt = GetMod("radioExt")
            if radioExt then
                local radio = radioExt.radioManager:getRadioByIndex(Vehicle.saveExt)

                if radio then
                    radioExt.radioManager.managerV:switchToRadio(radio)
                end
            end
        else
            Vehicle.base:SetRadioReceiverStation(Vehicle.saveStation)
            Vehicle.station = Vehicle.saveStation
            Vehicle.playing = true
        end

        Vehicle.saveStation = nil
        Vehicle.saveExt = nil
        Vehicle.savePlaying = false
    end

    SetVehicleRadioData()
end

-- Vehicle and Radio Behavior
function OnVehicleEntered()
    MountedVehicle()
    radioPortActive = GetPocketRadio():IsActive()
end

function OnVehicleExited()
    AddVehicle(Vehicle)

    if Vehicle.playing then
        Vehicle.StartTimer()
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

    -- Handles loading game when mounted on a vehicle
    if Vehicle == nil and GetVehicleBase() ~= nil then
        MountedVehicle()
    elseif Vehicle ~= nil and Vehicle.audio.ready and Vehicle.despawn then
        Vehicle.audio.DespawnRadio()
        Vehicle.despawn = false
    end

    if Vehicle ~= nil and Vehicle.audio.ready then
        -- moves speaker with vehicle until it comes to a full stop
        for i,v in ipairs(VehicleList.list) do
            local pos = v.base:GetWorldTransform().Position
            if not VectorCompare(pos, v.lastLoc) then
                v.audio.TeleportRadio(pos, rot)
                v.lastLoc = pos
            end
        end

        if despawnSameVehicle then
            -- starts Despawn delay after entering vehicle
            if entering and not IsEnteringVehicle() then
                delayCounter = 1
            end
            if delayCounter == despawnDelay then
                delayCounter = 0
                Vehicle.audio.DespawnRadio()
                despawnSameVehicle = false
            elseif delayCounter > 0 then
                delayCounter = delayCounter + 1
            end
            entering = IsEnteringVehicle()
        end
    end
end

-- Save Functionality
function CreateSave(veh)
    local vehicle = GetVehicleInListFromRecord(veh:GetVehicle():GetRecordID())

    if vehicle ~= nil then
        vehicle.despawn = true
        vehicle.saveStation = vehicle.station
        vehicle.saveExt = vehicle.stationExt
        vehicle.savePlaying = vehicle.playing
        vehicle.audio.DespawnRadio()
    end
end

function LoadSave(veh)
    local vehicle = GetVehicleInListFromRecord(veh:GetVehicle():GetRecordID())
    if vehicle ~= nil then
        vehicle.base = veh:GetVehicle()

        Save.playing = vehicle.playing
        Save.stationExt = vehicle.stationExt

        if vehicle.playing then
            vehicle.StartTimer()
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
        
        Observe('VehicleComponent', 'OnGameAttach', function(veh)
            LoadSave(veh)
        end)

        Observe('VehicleComponent', 'OnSummonStartedEvent', function(veh)
            LoadSave(veh)
        end)

        Observe('VehicleComponent', 'OnVehicleRadioEvent', function(_, evt)
            if evt == nil then
				evt = _
			end
            if Vehicle ~= nil then
                Vehicle.station = evt.station
                Vehicle.playing = evt.toggle;

                if (not evt.toggle and evt.station == -1) then
                    Vehicle.stationExt = GetRadioExtStation()
                    if Vehicle.stationExt ~= nil then
                        Vehicle.playing = true;
                    end
                end
            end
        end)

        Observe('VehicleComponent', 'OnRadioToggleEvent', function(_, evt)
            Vehicle.playing = not Vehicle.playing;
            if Vehicle.playing then
                Vehicle.station = GetVehicleStation()
                Vehicle.stationExt = GetRadioExtStation()
            end
        end)

        Observe('LoadGameMenuGameController', 'OnUninitialize', function()
            Cleanup()
        end)

        Observe('PlayerPuppet', 'OnDeath', function()
            Cleanup()
        end)

        Observe('PocketRadio', 'HandleVehicleUnmounted', function()
            pocketUnmount = true
        end)
    end)

    registerForEvent("onUpdate", function(delta)
        Cron.Update(delta)
    end)

    registerForEvent("onShutdown", function()
        Cleanup()
    end)

    updateTimer = Cron.Every(.1, Update)

    return {
      version = LoudVehicleRadio.version
    }
end

return LoudVehicleRadio:New()