local LoudVehicleRadio = { version = "0.0.0" }
local Cron = require("Modules/Cron")
local Radio = require("Modules/Radio")

local isInVehicle = false

local currentRadioStation = ""

LoudVehicleRadio = {}

function LoudVehicleRadio:New()

    registerForEvent("onInit", function()

        -- Cron.Every(0.2, function()

        --     local isInVehicleNext = IsInVehicle() and not IsEnteringVehicle() and not IsExitingVehicle()

        --     if IsEnteringVehicle() then
        --         OnVehicleEntering()
        --     elseif IsExitingVehicle() then
        --         OnVehicleExiting()
        --     elseif isInVehicleNext == true and isInVehicle == false then
        --         OnVehicleEntered()
        --     elseif isInVehicleNext == false and isInVehicle == true then
        --         OnVehicleExited()
        --     end

        --     isInVehicle = isInVehicleNext
        -- end)

        -- Fires when execting
        Observe('hudCarController', 'OnMountingEvent', function()
            OnVehicleEntered()
        end)

        Observe('hudCarController', 'OnUnmountingEvent', function()
            OnVehicleExited()
        end)
        
    end)
    
    -- registerForEvent("onUpdate", function(delta)
    --     Cron.Update(delta)
    -- end)

    return {
      version = LoudVehicleRadio.version
    }
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
    local vehicle = Game['GetMountedVehicle;GameObject'](Game.GetPlayer())
    if vehicle then
        return vehicle:IsPlayerDriver()
    end
end

function GetMountedVehicleRecord()
    local vehicle = Game['GetMountedVehicle;GameObject'](Game.GetPlayer())
    if vehicle then
        return vehicle:GetRecord()
    end
end

function IsPlayerDriver()
    local vehicle = Game['GetMountedVehicle;GameObject'](Game.GetPlayer())
    if vehicle then
        return vehicle:IsPlayerDriver()
    end
end

function GetRadioStation()
    local vehicle = Game['GetMountedVehicle;GameObject'](Game.GetPlayer())
    if vehicle then
        return vehicle:GetRadioRecieverStationName()
    end
end

function OnVehicleEntered()
    print("Entered Vehicle")
    Radio:despawn()
end

function OnVehicleEntering()

end

function OnVehicleExiting()

end

function OnVehicleExited()
    print("Exited Vehicle")
    Radio:spawn()
end

return LoudVehicleRadio:New()
