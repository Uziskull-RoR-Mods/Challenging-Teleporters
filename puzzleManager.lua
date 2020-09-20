-- Made by Uziskull

tpObj = Object.find("Teleporter")
panelObj = Object.find("BlastdoorPanel")

puzzleList = {puzzle = {}, challenge = {}, panel = {}}

puzzleTemplates = {}
puzzleTemplates["Dried Lake"] = Sprite.load("puzzle_template_1-1", "puzzles/gui/1-1", 1, 200, 150)
puzzleTemplates["Desolate Forest"] = Sprite.load("puzzle_template_1-2", "puzzles/gui/1-2", 1, 200, 150)
puzzleTemplates["Damp Caverns"] = Sprite.load("puzzle_template_2-1", "puzzles/gui/2-1", 1, 200, 150)
puzzleTemplates["Sky Meadow"] = Sprite.load("puzzle_template_2-2", "puzzles/gui/2-2", 1, 200, 150)
puzzleTemplates["Ancient Valley"] = Sprite.load("puzzle_template_3-1", "puzzles/gui/3-1", 1, 200, 150)
puzzleTemplates["Sunken Tomb"] = Sprite.load("puzzle_template_3-2", "puzzles/gui/3-2", 1, 200, 150)
puzzleTemplates["Magma Barracks"] = Sprite.load("puzzle_template_4-1", "puzzles/gui/4-1", 1, 200, 150)
puzzleTemplates["Hive Cluster"] = Sprite.load("puzzle_template_4-2", "puzzles/gui/4-2", 1, 200, 150)
-- puzzleTemplates["Temple of the Elders"] = Sprite.load("puzzle_template_5-1", "puzzles/gui/5-1", 1, 200, 150)
puzzleTemplates["Risk of Rain"] = Sprite.load("puzzle_template_6-1", "puzzles/gui/6-1", 1, 200, 150)
puzzleTemplates["Boar Beach"] = puzzleTemplates["Ancient Valley"]

setmetatable(puzzleTemplates, {
    __index = function (t, k)
        return t["Dried Lake"]
    end
})

-----------
-- Buffs --
-----------
puzzleBuff = Buff.new("Hmm...")
puzzleBuff.sprite = Sprite.load("puzzle_buff", "puzzles/puzzle_buff", 1, 5, 5)

saveStats = {}

puzzleBuff:addCallback("start", function(actor)
    saveStats[actor.id] = {
        pHmax = actor:get("pHmax"),
        pVmax = actor:get("pVmax"),
        pVspeed = actor:get("pVspeed"),
        pGravity1 = actor:get("pGravity1"),
        pGravity2 = actor:get("pGravity2")
    }
    actor:set("pHmax", 0)
        :set("pVmax", 0)
        :set("pVspeed", 0)
        :set("pGravity1", 0)
        :set("pGravity2", 0)
        :set("canrope", 0)
end)

puzzleBuff:addCallback("step", function(actor, remainingTime)
    if remainingTime == 1 then
        actor:applyBuff(puzzleBuff, 60)
    end
    actor:setAlarm(0, actor:getAlarm(0) + 1)
    for i = 2, 5 do
        actor:setAlarm(i, actor:getAlarm(i) + 1)
    end
end)

puzzleBuff:addCallback("end", function(actor)
    actor:set("pHmax", saveStats[actor.id]["pHmax"])
        :set("pVmax", saveStats[actor.id]["pVmax"])
        :set("pVspeed", saveStats[actor.id]["pVspeed"])
        :set("pGravity1", saveStats[actor.id]["pGravity1"])
        :set("pGravity2", saveStats[actor.id]["pGravity2"])
        :set("canrope", 1)
    saveStats[actor.id] = {}
end)

function getInteractable()
    return Stage.getCurrentStage().displayName == "Risk of Rain" and panelObj or tpObj
end

-------------
-- Packets --
-------------
requestTpSetupPacket = net.Packet("Request Initial Teleporter Setup", function(sender)
    if sender ~= nil then
        local intrObj = getInteractable()
        local intrList = {}
        for _, intr in ipairs(intrObj:findAll()) do
            local intrData = intr:getData()
            if intr:isValid() and intrData.puzzle ~= nil then
                intrList[#intrList + 1] = intr:getNetIdentity()
                intrList[#intrList + 1] = intrData.puzzleType
                intrList[#intrList + 1] = intrData.puzzleIndex
            end
        end
        initialTpSetupPacket:sendAsHost(net.DIRECT, sender, hardMode, unpack(intrList))
    end
end)

initialTpSetupPacket = net.Packet("Initial Teleporter Setup", function(sender, isHard, ...)
    args = {...}
    hardMode = isHard
    local i = 1
    while args[i] do
        local intr = args[i]:resolve()
        if not intr then
            break
        end
        intr:set("locked", 1)
        local intrData = intr:getData()
        intrData.puzzleActive = false
        intrData.puzzleType = args[i+1]
        intrData.puzzleIndex = args[i+2]
        i = i + 3
    end
end)

activatePuzzlePacket = net.Packet("Activate Teleporter Puzzle", function(sender, netTargetPlayer, netTargetInst)
    local targetP, targetI = netTargetPlayer:resolve(), netTargetInst:resolve()
    if targetP and targetI then
        local iData = targetI:getData()
        if targetI:get("locked") == 1 and not iData.puzzleActive then
            if net.host then
                activatePuzzlePacket:sendAsHost(net.ALL, nil, netTargetPlayer, netTargetInst)
            end
            iData.puzzleActive = true
            puzzleList[iData.puzzleType][iData.puzzleIndex](targetP)
            if iData.puzzleType ~= "challenge" then
                targetP:applyBuff(puzzleBuff, 60)
            end
        end
    end
end)

deactivatePuzzlePacket = net.Packet("Deactivate Teleporter Puzzle", function(sender, tpLocked, netTargetInst)
    local targetI = netTargetInst:resolve()
    if sender and targetI then
        local iData = targetI:getData()
        if targetI:get("locked") == 1 and iData.puzzleActive then
            if net.host then
                deactivatePuzzlePacket:sendAsHost(net.ALL, nil, tpLocked, netTargetInst)
            end
            if iData.puzzleType ~= "challenge" and sender:hasBuff(puzzleBuff) then
                sender:removeBuff(puzzleBuff)
            end
            iData.puzzleActive = false
            targetI:set("locked", tpLocked)
        end
    end
end)

------------------
-- Actual stuff --
------------------

function exitPuzzle(finished, inst)
    local lock = finished and 0 or 1
    if not net.host then
        deactivatePuzzlePacket:sendAsClient(lock, inst:getNetIdentity())
    else
        inst:set("locked", lock)
        inst:getData().puzzleActive = false
        
        if net.online then
            deactivatePuzzlePacket:sendAsHost(net.ALL, nil, lock, inst:getNetIdentity())
        end
    end
end

function giveUp(player)
    if player:isValid() then
        if player:hasBuff(puzzleBuff) then
            player:removeBuff(puzzleBuff)
        end
    end
    exitPuzzle(false, getInteractable():findNearest(player.x, player.y))
end

callback.register("onStageEntry", function()
    if net.host then
        local intrObj = getInteractable()
        local availableTypes = {}
        if intrObj == panelObj then
            if not flags.disablePanels then
                availableTypes[#availableTypes+1] = "panel"
            end
        else
            if not flags.disablePuzzles then
                availableTypes[#availableTypes+1] = "puzzle"
            end
            if not flags.disableChallenges then
                availableTypes[#availableTypes+1] = "challenge"
            end
        end
        if #availableTypes == 0 then return end
        
        local intrList = {}
        for _, intr in ipairs(intrObj:findAll()) do
            local intrData = intr:getData()
            intr:set("locked", 1)
            intrData.puzzleActive = false
            intrData.puzzleType = table.irandom(availableTypes)
            intrData.puzzleIndex = math.random(#puzzleList[intrData.puzzleType])
            intrList[#intrList + 1] = intr:getNetIdentity()
            intrList[#intrList + 1] = intrData.puzzleType
            intrList[#intrList + 1] = intrData.puzzleIndex
        end
        if net.online then
            initialTpSetupPacket:sendAsHost(net.ALL, nil, hardMode, unpack(intrList))
        end
    end
end, 11)
callback.register("onStageEntry", function()
    if not net.host then
        requestTpSetupPacket:sendAsClient()
    end
end, 10)

callback.register("onPlayerStep", function(player)
    if not net.online or player == net.localPlayer then
        local pData = player:getData()
        local currentInst = getInteractable():findNearest(player.x, player.y)
        if currentInst and currentInst:isValid() then
            local iData = currentInst:getData()
            if pData.puzzleActivatePopup then pData.puzzleActivatePopup = nil end
            if currentInst:get("locked") == 1 and not iData.puzzleActive and player:collidesWith(currentInst, player.x, player.y) then
                pData.puzzleActivatePopup = true
                if player:control("enter") == input.PRESSED then
                    if not net.host then
                        activatePuzzlePacket:sendAsClient(net.localPlayer:getNetIdentity(), currentInst:getNetIdentity())
                    else
                        iData.puzzleActive = true
                        puzzleList[iData.puzzleType][iData.puzzleIndex](player)
                        if iData.puzzleType ~= "challenge" then
                            player:applyBuff(puzzleBuff, 60)
                        end
                        
                        if net.online then
                            activatePuzzlePacket:sendAsHost(net.ALL, nil, net.localPlayer:getNetIdentity(), currentInst:getNetIdentity())
                        end
                    end
                end
            end
        end
    end
end)

callback.register("onPlayerDraw", function(player)
    if not net.online or player == net.localPlayer then
        local pData = player:getData()
        local currentInst = getInteractable():findNearest(player.x, player.y)
        if currentInst and pData.puzzleActivatePopup then
            local enterKeyText = input.getControlString("enter")
            local textPart1 = "Press "
            local textPart2 = " to attempt to unlock the "..(currentInst:getObject() == panelObj and "blast door" or "teleporter").."..."
            local fullText = textPart1 .. enterKeyText .. textPart2
            graphics.color(Color.WHITE)
            graphics.print(textPart1, currentInst.x - graphics.textWidth(fullText, graphics.FONT_DEFAULT) / 2, currentInst.y - 32)
            graphics.color(Color.YELLOW)
            graphics.print(enterKeyText, currentInst.x - graphics.textWidth(fullText, graphics.FONT_DEFAULT) / 2 + graphics.textWidth(textPart1, graphics.FONT_DEFAULT), currentInst.y - 32)
            graphics.color(Color.WHITE)
            graphics.print(textPart2, currentInst.x - graphics.textWidth(fullText, graphics.FONT_DEFAULT) / 2 + graphics.textWidth(textPart1 .. enterKeyText, graphics.FONT_DEFAULT), currentInst.y - 32)
        end
    end
end)

callback.register("onStep", function()
    local intrObj = getInteractable()
    for _, intr in ipairs(intrObj:findAll()) do
        if intr:isValid() then
            local iData = intr:getData()
            -- check for stuff that should be unlocked (panels mainly tbh)
            local instActive = intr:get("active")
            if instActive and instActive > 0 and intr:get("locked") == 1 then
                intr:set("locked", 0)
            end
            -- check for ongoing puzzles
            if net.online and net.host and iData.puzzleActive and iData.puzzleType ~= "challenge" then
                local nobodySolving = true
                for _, p in ipairs(misc.players) do
                    if p:isValid() then
                        if p:hasBuff(puzzleBuff) then
                            nobodySolving = false
                            break
                        end
                    end
                end
                if nobodySolving then
                    intr:set("locked", 1)
                    iData.puzzleActive = false
                    deactivatePuzzlePacket:sendAsHost(net.ALL, nil, true, intr:getNetIdentity())
                end
            else
                if iData.puzzleActive and iData.puzzleType ~= "challenge" then
                    misc.setTimeStop(2)
                end
            end
        end
    end
end)