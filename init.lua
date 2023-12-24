local LoudVehicleRadio = { version = "1.0.0" }
local Cron = require("Modules/Cron")
local audio = require("Modules/audio")
local Classes = require("Modules/Classes")

local disableRadioPort = false

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
    AddList(VehicleList.list, veh)
    VehicleList.count = VehicleList.count + 1
end

function RemoveVehicle(veh)
    RemoveList(VehicleList.list, veh)
    VehicleList.count = VehicleList.count - 1
end

function IsInVehicleList(veh)
    return IndexOf(VehicleList.list, veh) ~= -1
end

function AddSave(save)
    AddList(SaveList.list, save)
    SaveList.count = SaveList.count + 1
end

function RemoveSave(save)
    RemoveList(SaveList.list, save)
    SaveList.count = SaveList.count - 1
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


function Cleanup()
    for i,v in ipairs(VehicleList.list) do
        audio.DespawnRadio(v.data)

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
            return audio.GetRadioID(radioExt.radioManager.managerV:getActiveStationData().station)
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
    
    local tempVeh = GetVehicleBase()

    if Vehicle == nil or Vehicle.base == nil or Vehicle.record ~= tempVeh:GetRecordID() then
        print("New Vehicle")
        Vehicle = Vehicle.new()

        print("Volume: ", audio.volume)
    end
    
    Vehicle.base = tempVeh

    SetVehicleRadioData()
    radioPortActive = GetPocketRadio():IsActive()
end

function OnVehicleExited()
    AddVehicle(Vehicle)
    Cron.Resume(spawnTimer)
end

function SpawnSetRadio()
    if Vehicle.data.spawned then
        if Vehicle.stationExt then
            audio.SetRadio(Vehicle.stationExt, true, Vehicle.data)
        else
            audio.SetRadio(Vehicle.station, Vehicle.playing, Vehicle.data)
        end
        Vehicle.data.ready = true
        Cron.Pause(spawnTimer)
    else
        audio.SpawnRadios(Vehicle.base:GetWorldTransform(), Vehicle.data)
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
                audio.TeleportRadio(pos, rot, v.data)
                v.lastLoc = pos
            end
        end

        -- -- starts Despawn delay after entering vehicle
        -- if Vehicle.entering and not IsEnteringVehicle() then
        --     print("start counter")
        --     Vehicle.data.counter = 1
        -- end
        -- if Vehicle.data.counter == audio.despawnDelay then
        --     print("despawn counter")
        --     Vehicle.data.counter = 0
        --     audio.DespawnRadio(Vehicle.data)
        -- elseif Vehicle.data.counter > 0 then
        --     Vehicle.data.counter = Vehicle.data.counter + 1
        -- end
        -- Vehicle.entering = IsEnteringVehicle()
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
            print("Started Unmounting PS")
            OnVehicleExited()
        end)

        Observe('VehicleComponent', 'OnGameDetach', function(veh)
            CreateSave(veh)
        end)

        Observe('VehicleComponent', 'OnSummonStartedEvent', function(veh)
            LoadSave(veh)
        end)

        Observe('VehicleComponent', 'EnableRadio', function()
            print("EnableRadio")
            print("---")
        end)

        Observe('VehicleComponent', 'DisableRadio', function()
            print("DisableRadio")
            print("---")
        end)

        Observe('VehicleComponent', 'OnVehicleRadioStationInitialized', function()
            print("OnVehicleRadioStationInitialized")
            print("---")
        end)

        Observe('VehicleComponent', 'OnVehicleRadioEvent', function(_, evt)
            if evt == nil then
				evt = _
                print("nil")
			end

            print("OnVehicleRadioEvent")
            print("Toggle: ", evt.toggle)
            print("Set Station: ", evt.setStation)
            print("Station ID: ", evt.station)
            Vehicle.station = evt.station
            Vehicle.playing = evt.toggle;

            if (not evt.toggle and evt.station == -1) then
                print("not toggle and negative station")
                Vehicle.stationExt = GetRadioExtStation()
                if Vehicle.stationExt ~= nil then
                    Vehicle.playing = true;
                end
            end
            print("---")
        end)

        Observe('VehicleComponent', 'OnVehicleRadioTierEvent', function(_, evt)
            if evt == nil then
				evt = _
			end
            
            print("OnVehicleRadioTierEvent")
            print("Radio Tier: ",evt.radioTier)
            print("Override Tier: ",evt.overrideTier)
            print("---")
        end)

        Observe('VehicleComponent', 'OnRadioToggleEvent', function(_, evt)
            print("OnRadioToggleEvent", _:GetVehicle():IsRadioReceiverActive())
            local active = not _:GetVehicle():IsRadioReceiverActive()
            if active then
                Vehicle.station = GetVehicleStation()
                Vehicle.stationExt = GetRadioExtStation()
                Vehicle.playing = true;
            else
                Vehicle.playing = false;
            end
            print("---")
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

    Cron.After(0.1, audio.Initialize())

    spawnTimer = Cron.Every(.1, SpawnSetRadio)
    Cron.Pause(spawnTimer)

    updateTimer = Cron.Every(.1, Update)
    Cron.Pause(updateTimer)

    return {
      version = LoudVehicleRadio.version
    }
end

return LoudVehicleRadio:New()