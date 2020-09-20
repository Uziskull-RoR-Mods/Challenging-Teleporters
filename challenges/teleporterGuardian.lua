ANIM_TIMER = 60
SPRITE_SCALE = 0.50

local missileObj = Object.find("EfMissileEnemy")

local function doSmoke(inst)
    local particle = ParticleType.find("Smoke5")
    particle:color(Color.ROR_RED)
    for i = 1, 30 do
        local xx = math.random(1, inst.sprite.width)
        local yy = math.random(1, inst.sprite.height)
        particle:burst("above", inst.x - inst.sprite.xorigin + xx, inst.y - inst.sprite.yorigin + yy, math.random(3, 5))
    end
end

----

local tpGuard = Object.new("Teleporter Guardian")

local guardSpawnPacket
local function fSpawnGuard(sender, hard)
    local tp = tpObj:find(1)
    local guard = tpGuard:create(tp.x, tp.y - 1.5 * tp.sprite.height)
    local guardData = guard:getData()
    guardData.radius = hard and 150 or 100
    guardData.speed = hard and 1.75 or 1.25
    guardData.tp = tp
    
    guardSpawnPacket:sendAsHost(net.ALL, nil, hard)
    tp:set("active", 1)
      :set("locked", 0)
    tp:getData().puzzleActive = false
    if net.online then
        deactivatePuzzlePacket:sendAsHost(net.ALL, nil, 0, tp:getNetIdentity())
    end
end
guardSpawnPacket = net.Packet("Challenge GuardianTp Spawning", fSpawnGuard)

local targetPlayerPacket
local function fTargetPlayer(sender, playerNI)
    local guard = tpGuard:find(1)
    if net.host then
        local targetPlayer, sqrDist, d
        for _, p in ipairs(misc.players) do
            d = (p.x - guard.x)^2 + (p.y - guard.y)^2
            if p:get("dead") == 0 and (not sqrDist or d < sqrDist) then
                sqrDist = d
                targetPlayer = p
            end
        end
        if targetPlayer then
            guard:getData().target = targetPlayer
            if net.online then
                targetPlayerPacket:sendAsHost(net.ALL, nil, targetPlayer:getNetIdentity())
            end
        end
    else
        local player = playerNI and playerNI:resolve()
        if player then
            guard:getData().target = player
        end
    end
end
targetPlayerPacket = net.Packet("Challenge GuardianTp TargetPlayer", fTargetPlayer)

tpGuard:addCallback("create", function(self)
    local guardData = self:getData()
    guardData.animation = -ANIM_TIMER
    guardData.death = nil
    guardData.cooldowns = {
        targetPlayer = 0,
        spawnMissile = 10 * 60, spawnMissileRNG = 0,
    }
end)
tpGuard:addCallback("draw", function(self)
    local guardData = self:getData()
    if not self.sprite then
        local tp = guardData.tp
        local spriteName = "Teleporter Guardian " .. (tp:get("epic") == 1 and "Epic" or "Normal")
        local guardSprite = Sprite.find(spriteName)
        if not guardSprite then
            local tpSpr = tp.sprite
            local surf = Surface.new(tpSpr.width, 2 * tpSpr.height)
            graphics.setTarget(surf)
            graphics.drawImage{
                image = tpSpr,
                x = surf.width/2, y=surf.height/2
            }
            graphics.drawImage{
                image = tpSpr,
                x = surf.width/2, y=surf.height/2 + 1,
                angle = 180
            }
            graphics.resetTarget()
            guardSprite = surf:createSprite(surf.width/2, surf.height/2):finalize(spriteName)
            surf:free()
        end
        self.sprite = guardSprite
    end
    
    -- anim control (spawn/death, increase, AoE)
    if guardData.animation <= 0 then
        self.angle = guardData.animation * 15
        self.xscale = (guardData.animation + ANIM_TIMER) / ANIM_TIMER * SPRITE_SCALE
        self.yscale = self.xscale
    else
        self.angle = 15 * math.sin(math.rad(guardData.animation))
    end
    
    graphics.color(Color.ROR_RED)
    graphics.circle(self.x, self.y, self.xscale / SPRITE_SCALE * guardData.radius, true)
    
    if guardData.death then
        guardData.animation = guardData.animation - 1
        if guardData.animation <= -ANIM_TIMER then
            self:destroy()
            return
        end
    else
        guardData.animation = guardData.animation + 1
    end
end)
tpGuard:addCallback("step", function(self)
    local guardData = self:getData()
    local anim = guardData.animation
    local cds = guardData.cooldowns
    if anim > 0 then
        -- destroy if tp ready to continue
        if guardData.tp:get("active") > 2 then
            guardData.death = true
            guardData.animation = 0
            return
        end
        -- target closest player [60 frame cooldown]
        if net.host and anim - cds.targetPlayer >= 60 then
            fTargetPlayer()
            cds.targetPlayer = anim
        end
        if guardData.target and guardData.target:isValid() then
            local angle = math.atan2(guardData.target.y - self.y, guardData.target.x - self.x)
            self.x = self.x + guardData.speed * math.cos(angle)
            self.y = self.y + guardData.speed * math.sin(angle)
        end
        -- spawn missile [4.5*60 (+ 1*60 random) frame cooldown (3*60 on hard)]
        if net.host and anim - cds.spawnMissile >= (hardMode and 3*60 or 4.5*60) + cds.spawnMissileRNG then
            missileObj:create(self.x, self.y)
            cds.spawnMissile = anim
            cds.spawnMissileRNG = math.random(0, 1*60)
        end

        -- lower tp timer by number of players inside field [align with actual tp countdown]
        if guardData.target and guardData.target:isValid() and guardData.tp:get("active") == 1 and guardData.target:get("dead") == 0 and
          math.sqrt((self.x - guardData.target.x)^2 + (self.y - guardData.target.y)^2) <= guardData.radius then
            guardData.tp:set("time", math.max(0, guardData.tp:get("time") - (hardMode and #guardData.target:getObject():findMatching("dead", 0) or 1)))
        end
    end
end)
tpGuard:addCallback("destroy", function(self)
    doSmoke(self)
end)

local function start(player)
    if not net.host then
        guardSpawnPacket:sendAsClient()
    else
        fSpawnGuard(hardMode)
    end
end

-- table.insert(puzzleList, {start = start, isPuzzle = false})
table.insert(puzzleList.challenge, start)