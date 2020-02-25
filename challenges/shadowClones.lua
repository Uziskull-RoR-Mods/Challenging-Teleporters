-- Made by Uziskull

local shadowTransform = Sprite.load("shadowClones_morph", "challenges/shadowClones/morph", 30, 25, 31)
local shadowTransformEpic = Sprite.load("shadowClones_morph_epic", "challenges/shadowClones/morph_epic", 30, 46, 54)

local fakeTp = Object.new("Teleporter?")
fakeTp.sprite = shadowTransform

local function getCoordList(numberTps)
    local tpList = {}
    local spawns = Object.find("B"):findAll()
    local selectedNums = {}
    for i = 1, numberTps do
        local choice = nil
        local exists = true
        while exists do
            exists = false
            choice = math.random(1, #spawns)
            local b1 = spawns[choice]
            for j = 1, #selectedNums do
                local b2 = spawns[selectedNums[j]]
                if math.sqrt((b2.x - b1.x)^2 + (b2.y - b1.y)^2) < 150 then
                    exists = true 
                    break
                end
            end
        end
        local block = spawns[choice]
        table.insert(selectedNums, choice)
        table.insert(tpList, block.x + block.sprite.width / 2)
        table.insert(tpList, block.y - 1)
    end
    return tpList
end

local function doSmoke(inst)
    local particle = ParticleType.find("Smoke5")
    for i = 1, 30 do
        local xx = math.random(1, inst.sprite.width)
        local yy = math.random(1, inst.sprite.height)
        particle:burst("above", inst.x - inst.sprite.xorigin + xx, inst.y - inst.sprite.yorigin + yy, math.random(3, 5))
    end
end

tpSpawnPacket = net.Packet("Challenge FakeTp Spawning", function(sender, numberTps, ...)
    args = {...}
    local teleporter = tpObj:find(1)
    doSmoke(teleporter)
    if net.host then
        local tpList = getCoordList(numberTps)
        for i = 1, numberTps do
            if i == numberTps then
                teleporter.x, teleporter.y = tpList[(i - 1)*2 + 1], tpList[(i - 1)*2 + 2]
            else
                local fakeTpInst = fakeTp:create(tpList[(i - 1)*2 + 1], tpList[(i - 1)*2 + 2])
                fakeTpInst:set("fakeTp_id", i)
                if teleporter:get("epic") == 1 then fakeTpInst:set("fakeTp_epic", 1) end
            end
        end
        tpSpawnPacket:sendAsHost(net.ALL, nil, numberTps, unpack(tpList))
        teleporter:set("puzzleActive", 0):set("locked", 0)
        if net.online then
            deactivatePuzzlePacket:sendAsHost(net.ALL, nil, 0)
        end
    else
        for i = 1, numberTps do
            if i == numberTps then
                teleporter.x, teleporter.y = args[(i - 1)*2 + 1], args[(i - 1)*2 + 2]
            else
                local fakeTpInst = fakeTp:create(args[(i - 1)*2 + 1], args[(i - 1)*2 + 2])
                fakeTpInst:set("fakeTp_id", i)
                if teleporter:get("epic") == 1 then fakeTpInst:set("fakeTp_epic", 1) end
            end
        end
    end
end)

tpTriggerPacket = net.Packet("Challenge FakeTp Trigger", function(sender, tpFakeId)
    if tpFakeId ~= nil then
        for _, tp in ipairs(fakeTp:findAll()) do
            if tp:isValid() then
                if tp:get("fakeTp_id") == tpFakeId and tp:get("fakeTp_triggered") == nil then
                    tp:set("fakeTp_triggered", 1)
                    break
                end
            end
        end
        tpTriggerPacket:sendAsHost(net.ALL, nil, tpFakeId)
    end
end)

fakeTp:addCallback("create", function(self)
    if self:get("fakeTp_epic") then
        fakeTp.sprite = shadowTransformEpic
    end
    self.spriteSpeed = 0.5
    doSmoke(self)
end)
fakeTp:addCallback("draw", function(self)
    if self:get("fakeTp_popup") ~= nil then
        local textKey = "'" .. input.getControlString("enter") .. "'"
        local text1 = "Press "
        local text2 = " to activate teleporter. Are you ready?"
        if self:get("fakeTp_epic") ~= nil then
            text2 = " to activate the divine teleporter. Are you ready?"
        end
        local fullText = text1 .. textKey .. text2
        graphics.color(Color.WHITE)
        graphics.print(text1, self.x - 80, self.y - 32 - 8)
        graphics.color(Color.ROR_YELLOW)
        graphics.print(textKey, self.x - 80 + graphics.textWidth(text1, graphics.FONT_DEFAULT), self.y - 32 - 8)
        graphics.color(Color.WHITE)
        graphics.print(text2, self.x - 80 + graphics.textWidth(text1 .. textKey, graphics.FONT_DEFAULT), self.y - 32 - 8)
    end
end)
fakeTp:addCallback("step", function(self)
    self:set("fakeTp_popup", nil)
    if self:get("fakeTp_triggered") == nil then
        self.subimage = 1
    elseif self.subimage == 30 then
        if net.host then
            if self:get("fakeTp_epic") then
                Object.find("LizardG"):create(self.x, self.y - 26):set("sync", 1)
            else
                Object.find("Imp"):create(self.x, self.y - 10):set("sync", 1)
            end
        end
        self:destroy()
    end
end)
fakeTp:addCallback("destroy", function(self)
    if self:get("fakeTp_triggered") == nil then
        doSmoke(self)
    end
end)

registercallback("onStep", function()
    local teleporter = tpObj:find(1)
    if teleporter ~= nil then
        if teleporter:get("active") > 0 then
            for _, tp in ipairs(fakeTp:findAll()) do
                if tp:isValid() then
                    tp:destroy()
                end
            end
        end
    end
end)

registercallback("onPlayerStep", function(player)
    if not net.online or player == net.localPlayer then
        local tpInst = fakeTp:findNearest(player.x, player.y)
        if tpInst ~= nil then
            if tpInst:get("fakeTp_triggered") == nil then
                if player:get("dead") ~= 1 and player:collidesWith(tpInst, player.x, player.y) then
                    tpInst:set("fakeTp_popup", 1)
                    if player:control("enter") == input.PRESSED then
                        tpInst:set("fakeTp_popup", nil)
                        if net.host then
                            tpInst:set("fakeTp_triggered", 1)
                            tpTriggerPacket:sendAsHost(net.ALL, nil, tpInst:get("fakeTp_id"))
                        else
                            log("sent as client")
                            tpTriggerPacket:sendAsClient(tpInst:get("fakeTp_id"))
                        end
                    end
                elseif tpInst:get("fakeTp_popup") ~= nil then
                    tpInst:set("fakeTp_popup", nil)
                end
            end
        end
    end
end)

local function start(player, isHard)
    local numberTps = 3
    if isHard then
        numberTps = 10
    end
    if not net.host then
        tpSpawnPacket:sendAsClient(numberTps)
    else
        local teleporter = tpObj:find(1)
        doSmoke(teleporter)
        local tpList = getCoordList(numberTps)
        for i = 1, numberTps do
            if i == numberTps then
                teleporter.x, teleporter.y = tpList[(i - 1)*2 + 1], tpList[(i - 1)*2 + 2]
            else
                local fakeTpInst = fakeTp:create(tpList[(i - 1)*2 + 1], tpList[(i - 1)*2 + 2])
                fakeTpInst:set("fakeTp_id", i)
                if teleporter:get("epic") == 1 then fakeTpInst:set("fakeTp_epic", 1) end
            end
        end
        tpSpawnPacket:sendAsHost(net.ALL, nil, numberTps, unpack(tpList))
        teleporter:set("puzzleActive", 0):set("locked", 0)
        if net.online then
            deactivatePuzzlePacket:sendAsHost(net.ALL, nil, 0)
        end
    end
end

table.insert(puzzleList, {start, 0})