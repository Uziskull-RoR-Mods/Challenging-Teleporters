-- Made by Uziskull

local legsInstance = nil
registercallback("onStageEntry", function()
    legsInstance = nil
end, 20)

local legsSprite = Sprite.load("movingTeleporter_legs", "challenges/movingTeleporter/legs", 1, 25, 0)

local function unstuckTp(tpInst)
    local unstuckLimit = 50
    local oldX, oldY = tpInst.x, tpInst.y
    local count = 1
    while tpInst:collidesMap(tpInst.x, tpInst.y) and count <= 50 do
        local mult = 1
        if count % 2 == 0 then
            mult = -1
        end
        tpInst.x = tpInst.x + count * mult
        
        count = count + 1
    end
    if count > 50 then
        tpInst.x, tpInst.y = oldX, oldY
    end
end

local legsObj = Object.new("Teleporter Legs")
legsObj.sprite = legsSprite

legsSpawningPacket = net.Packet("Challenge Legs Spawning", function(sender, isHard)
    if legsInstance == nil then
        local tpInst = tpObj:find(1)
        unstuckTp(tpInst)
        legsInstance = legsObj:create(tpInst.x, tpInst.y)
        legsInstance.depth = tpInst.depth + 1
        local legData = legsInstance:getData()
        legData["jumpChargeTime"] = 60
        legData["countdown"] = 3 * 60
        legData["speedX"] = 3
        if isHard then
            legData["jumpChargeTime"] = 30
            legData["countdown"] = 10 * 60
            legData["speedX"] = 5
        end
        legData["maxSpeedY"] = 7
        legData["speedY"] = 0
        legData["grav"] = 0.26
        
        local stageW, _ = Stage.getDimensions()
        legData["direction"] = 1
        if legsInstance.x > stageW / 2 then
            legData["direction"] = -1
        end
        
        legData["tpOrigX"] = tpInst.x
        legData["tpOrigY"] = tpInst.y
    end
    
    legsSpawningPacket:sendAsHost(net.ALL, nil, isHard)
end)
legsResyncPacket = net.Packet("Challenge Legs Resync", function(sender, x, y, anim, direction)
    if legsInstance ~= nil then
        local legData = legsInstance:getData()
        legsInstance.x = x
        legsInstance.y = y
        legData["anim"] = anim
        legData["direction"] = direction
    end
end)

legsObj:addCallback("create", function(self)
    local legData = self:getData()
    legData["anim"] = -30
end)
legsObj:addCallback("step", function(self)
    local teleporter = tpObj:find(1)
    local legData = self:getData()
    
    local stageW, stageH = Stage.getDimensions()
    if teleporter.x - (teleporter.sprite.width - teleporter.sprite.xorigin) < 0
      or teleporter.x + teleporter.sprite.xorigin > stageW
      or teleporter.y - (teleporter.sprite.height - teleporter.sprite.yorigin) < 0
      or teleporter.y + teleporter.sprite.yorigin > stageH then
        teleporter.x, teleporter.y = legData["tpOrigX"], legData["tpOrigY"] - self.sprite.height
        self.x, self.y = legData["tpOrigX"], legData["tpOrigY"] - self.sprite.height
        legData["direction"] = legData["direction"] * -1
        Sound.find("Teleporter", "vanilla"):play()
    end
    
    if legData["countdown"] > 0 then
        teleporter.subimage = 7
        legData["countdown"] = legData["countdown"] - 1
        if legData["countdown"] == 0 then
            teleporter.subimage = 1
            if net.host then
                if net.online then
                    deactivatePuzzlePacket:sendAsHost(net.ALL, nil, 0)
                end
                teleporter:set("puzzleActive", 0):set("locked", 0)
            end
        end
    end
    
    if legData["anim"] < -4 then
        self.y = self.y - 1
    elseif legData["anim"] >= 0 then -- legData["anim"] <= 3 and legData["anim"] >= 0 then
        if legData["anim"] == 3 then
            legData["speedY"] = legData["maxSpeedY"] * -1
        elseif legData["anim"] == 0 and self:collidesMap(self.x, self.y + 1) then
            legData["anim"] = legData["jumpChargeTime"]
            legsResyncPacket:sendAsHost(net.ALL, nil, self.x, self.y, legData["jumpChargeTime"], legData["direction"])
        end
        
        -- physics
        if not self:collidesMap(self.x, self.y - 1) then
            legData["speedY"] = legData["speedY"] + legData["grav"]
        end
        self.y = self.y + legData["speedY"]
        teleporter.y = self.y
        if (self:collidesMap(self.x, self.y) or teleporter:collidesMap(teleporter.x, teleporter.y)) and legData["speedY"] ~= 0 then
            while self:collidesMap(self.x, self.y) or teleporter:collidesMap(teleporter.x, teleporter.y) do
                self.y = self.y - (legData["speedY"] / math.abs(legData["speedY"]))
                teleporter.y = self.y
            end
            legData["speedY"] = 0
        end
        
        if legData["anim"] <= 3 and not self:collidesMap(self.x, self.y - 1) then
            local speed = legData["speedX"] * legData["direction"]
            self.x = self.x + speed
            teleporter.x = self.x
            if self:collidesMap(self.x, self.y) or teleporter:collidesMap(teleporter.x, teleporter.y) then
                while self:collidesMap(self.x, self.y) or teleporter:collidesMap(teleporter.x, teleporter.y) do
                    self.x = self.x - (speed / math.abs(speed))
                    teleporter.x = self.x
                end
                legData["direction"] = legData["direction"] * -1
            end
        end
    end
    
    teleporter.x = self.x
    teleporter.y = self.y
    
    if legData["anim"] ~= 0 then
        legData["anim"] = legData["anim"] - legData["anim"] / math.abs(legData["anim"])
    end
    if legData["anim"] == 0 then
        self.yscale = 8 / 8
    elseif legData["anim"] < 0 then
        if legData["anim"] < -4 then
            local animFrame = math.floor((26 + (legData["anim"] + 4)) / 3) + 1
            self.yscale = animFrame / 8
        else
            self.yscale = 8 / 8
        end
    elseif legData["anim"] < legData["jumpChargeTime"] then
        if legData["anim"] > legData["jumpChargeTime"] - 20 then
            self.yscale = (((legData["anim"] - (legData["jumpChargeTime"] - 20)) / 20) * 4 + 4) / 8
        else
            self.yscale = 4 / 8
        end
    end
end)

local function start(player, isHard)
    if not net.host then
        legsSpawningPacket:sendAsClient(isHard)
    else
        if legsInstance == nil then
            local tpInst = tpObj:find(1)
            unstuckTp(tpInst)
            legsInstance = legsObj:create(tpInst.x, tpInst.y)
            legsInstance.depth = tpInst.depth + 1
            local legData = legsInstance:getData()
            legData["jumpChargeTime"] = 60
            legData["countdown"] = 3 * 60
            legData["speedX"] = 3
            if isHard then
                legData["jumpChargeTime"] = 30
                legData["countdown"] = 10 * 60
                legData["speedX"] = 5
            end
            legData["maxSpeedY"] = 7
            legData["speedY"] = 0
            legData["grav"] = 0.26
            
            local stageW, _ = Stage.getDimensions()
            legData["direction"] = 1
            if legsInstance.x > stageW / 2 then
                legData["direction"] = -1
            end
            
            legData["tpOrigX"] = tpInst.x
            legData["tpOrigY"] = tpInst.y
        end
        
        legsSpawningPacket:sendAsHost(net.ALL, nil, isHard)
    end
end

table.insert(puzzleList, {start, 0})