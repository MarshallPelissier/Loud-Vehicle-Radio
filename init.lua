local LoudVehicleRadio = { version = "0.0.0" }
local Cron = require("Modules/Cron")
-- local radio = require("Modules.radio")

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

Vehicle = {
    base = nil,
    station = nil
}

Radio = {
    path = "base\\gameplay\\devices\\home_appliances\\radio_sets\\radio_1.ent",
    entID = nil,
    entity = nil,
    spawned = false,
    stationID = ""
}

local timer = nil

LoudVehicleRadio = {}

function LoudVehicleRadio:New()

    registerForEvent("onInit", function()

        GetVehicleData()

        -- Fires when execting
        Observe('hudCarController', 'OnMountingEvent', function()
            OnVehicleEntered()
        end)

        Observe('hudCarController', 'OnUnmountingEvent', function()
            OnVehicleExited()
        end)
        
    end)
    
    registerForEvent("onUpdate", function(delta)
        Cron.Update(delta)
    end)

    timer = Cron.Every(.1, SetRadio)

    return {
      version = LoudVehicleRadio.version
    }

end

function GetVehicleData()
    Vehicle.base = Game['GetMountedVehicle;GameObject'](Game.GetPlayer())
    Vehicle.base:ToggleRadioReceiver(true)
    Vehicle.station = Vehicle.base:GetRadioReceiverStationName().value
end

function UpdateVehicleStation()
    Vehicle.station = Vehicle.base:GetRadioReceiverStationName().value
end

function OnVehicleEntered()
    print("Entered Vehicle")
    Despawn()
    GetVehicleData()
    Cron.Pause(timer)
end

function OnVehicleExited()
    print("Exited Vehicle")
    Spawn()
    Cron.Resume(timer)
end

function Spawn()
    print("Radio Spawn test")
    local transform = Vehicle.base:GetWorldTransform()
    local rot = EulerAngles.new(0,90,0)
    transform:SetPosition(Vector4.new(transform.Position:GetX(), (transform.Position:GetY()), transform.Position:GetZ() - 0.1))
    transform:SetOrientation(GetSingleton('EulerAngles').ToQuat(rot))
    Radio.entID = exEntitySpawner.Spawn(Radio.path, transform)
end

function Fadeout()
    if Game.FindEntityByID(Radio.entID) ~= nil then
        Radio.entity = Game.FindEntityByID(Radio.entID):GetEntity()
        Radio.spawned = false
    end
end

function Despawn()
    print("Radio Despawn")
    if Game.FindEntityByID(Radio.entID) ~= nil then
        Game.FindEntityByID(Radio.entID):GetEntity():Destroy()
        Radio.spawned = false
    end
end

function SetRadio()
    print("SetRadio")
    if Radio.entID == nil then
        Cron.Pause(timer)
    end
    if Game.FindEntityByID(Radio.entID) ~= nil then
        Radio.entity = Game.FindEntityByID(Radio.entID)
        UpdateVehicleStation()
        Radio.entity:GetDevicePS():SetActiveStationIndex(indexOf(StationList, Vehicle.station) - 1)
        Radio.entity:PlayGivenStation()
        Radio.spawned = true
        Cron.Pause(timer)
    end
end

return LoudVehicleRadio:New()
