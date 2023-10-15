
    
    
Radio = {}


function Radio:newRadio()

    local r = {}

    r.path = "base\\gameplay\\devices\\home_appliances\\radio_sets\\radio_1.ent"
    r.entID = nil -- Actual object stuff
    r.entity = nil
    r.spawned = false
    r.stationID = ""
    
end

function Radio:spawn()
    print("Radio Spawn")
    local transform = Game.GetPlayer():GetWorldTransform()
    transform:SetPosition(Vector4.new(transform.Position:GetX(), (transform.Position:GetY() - 1), transform.Position:GetZ()))
    self.entID = exEntitySpawner.Spawn(self.path, transform)
    self.entity = Game.FindEntityByID(self.entID)
    self.spawned = true
end

function Radio:fadeout()
    if Game.FindEntityByID(self.entID) ~= nil then
        self.ent = Game.FindEntityByID(self.entID):GetEntity()
        self.spawned = false
    end
end

function Radio:despawn()
    print("Radio Despawn")
    if Game.FindEntityByID(self.entID) ~= nil then
        Game.FindEntityByID(self.entID):GetEntity():Destroy()
        self.spawned = false
    end
end

return Radio:newRadio()
