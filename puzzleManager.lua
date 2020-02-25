-- Made by Uziskull

tpObj = Object.find("Teleporter")
puzzleList = {}
puzzleTemplates = {}
puzzleTemplates["Dried Lake"] = Sprite.load("puzzle_template_1-1", "puzzles/gui/1-1", 1, 200, 150)
puzzleTemplates["Desolate Forest"] = Sprite.load("puzzle_template_1-2", "puzzles/gui/1-2", 1, 200, 150)
puzzleTemplates["Damp Caverns"] = Sprite.load("puzzle_template_2-1", "puzzles/gui/2-1", 1, 200, 150)
puzzleTemplates["Sky Meadow"] = Sprite.load("puzzle_template_2-2", "puzzles/gui/2-2", 1, 200, 150)
puzzleTemplates["Ancient Valley"] = Sprite.load("puzzle_template_3-1", "puzzles/gui/3-1", 1, 200, 150)
puzzleTemplates["Sunken Tomb"] = Sprite.load("puzzle_template_3-2", "puzzles/gui/3-2", 1, 200, 150)
puzzleTemplates["Magma Barracks"] = Sprite.load("puzzle_template_4-1", "puzzles/gui/4-1", 1, 200, 150)
-- puzzleTemplates["Hive Cluster"] = Sprite.load("puzzle_template_4-2", "puzzles/gui/4-2", 1, 200, 150)
-- puzzleTemplates["Temple of the Elders"] = Sprite.load("puzzle_template_5-1", "puzzles/gui/5-1", 1, 200, 150)
puzzleTemplates["Risk of Rain"] = Sprite.load("puzzle_template_6-1", "puzzles/gui/6-1", 1, 200, 150)
puzzleTemplates["Boar Beach"] = puzzleTemplates["Ancient Valley"]

----------------------
-- Useful Functions --
----------------------
function getScreenCorners(player)
    local cameraWidth, cameraHeight = graphics.getGameResolution()
    local stageWidth, stageHeight = Stage.getDimensions()
    local drawX = 0
    if player.x > cameraWidth / 2 then
        drawX = player.x - cameraWidth / 2
        if drawX + cameraWidth > stageWidth then
            drawX = stageWidth - cameraWidth
        end
    end
    local drawY = 0
    if player.y > cameraHeight / 2 then
        drawY = player.y - cameraHeight / 2
        if drawY + cameraHeight > stageHeight then
            drawY = stageHeight - cameraHeight
        end
    end
    
    return drawX, drawY, drawX + cameraWidth, drawY + cameraHeight
end

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
    actor:set("pVmax", 0)
    actor:set("pVspeed", 0)
    actor:set("pGravity1", 0)
    actor:set("pGravity2", 0)
    actor:set("canrope", 0)
end)

puzzleBuff:addCallback("step", function(actor, remainingTime)
    if remainingTime == 1 then
        actor:applyBuff(puzzleBuff, 60)
    end
end)

puzzleBuff:addCallback("end", function(actor)
    actor:set("pHmax", saveStats[actor.id]["pHmax"])
    actor:set("pVmax", saveStats[actor.id]["pVmax"])
    actor:set("pVspeed", saveStats[actor.id]["pVspeed"])
    actor:set("pGravity1", saveStats[actor.id]["pGravity1"])
    actor:set("pGravity2", saveStats[actor.id]["pGravity2"])
    actor:set("canrope", 1)
    saveStats[actor.id] = {}
end)

-------------
-- Packets --
-------------
requestTpSetupPacket = net.Packet("Request Initial Teleporter Setup", function(sender)
    if sender ~= nil then
        local currentTp = tpObj:find(1)
        if currentTp ~= nil then
            local pType = currentTp:get("puzzleType")
            local pIsP = currentTp:get("puzzleIsPuzzle")
            local pHard = currentTp:get("puzzleHard")
            if pType ~= nil and pIsP ~= nil and pHard ~= nil then
                initialTpSetupPacket:sendAsHost(net.DIRECT, sender, pType, pIsP, pHard)
            end
        end
    end
end)

initialTpSetupPacket = net.Packet("Initial Teleporter Setup", function(sender, pType, isPuzzle, pHard)
    local currentTp = tpObj:find(1)
    currentTp:set("locked", 1)
             :set("canActivate", 0)
             :set("puzzleActive", 0)
             :set("puzzleType", pType)
             :set("puzzleIsPuzzle", isPuzzle)
             :set("puzzleHard", pHard)
end)

activatePuzzlePacket = net.Packet("Activate Teleporter Puzzle", function(sender, netTargetPlayer)
    local targetPlayer = netTargetPlayer:resolve()
    if targetPlayer ~= nil then
        local currentTp = tpObj:find(1)
        if currentTp:get("locked") == 1 and currentTp:get("puzzleActive") == 0 then -- should deal with concurrency
            if net.host then
                activatePuzzlePacket:sendAsHost(net.ALL, nil, netTargetPlayer)
            end
            currentTp:set("puzzleActive", 1)
            local isHard = false
            if currentTp:get("puzzleHard") == 1 then
                isHard = true
            end
            puzzleList[currentTp:get("puzzleType")][1](targetPlayer, isHard)
            if currentTp:get("puzzleIsPuzzle") == 1 then
                targetPlayer:applyBuff(puzzleBuff, 60)
            end
        end
    end
end)

deactivatePuzzlePacket = net.Packet("Deactivate Teleporter Puzzle", function(sender, tpLocked)
    if sender ~= nil then
        local currentTp = tpObj:find(1)
        if currentTp:get("locked") == 1 and currentTp:get("puzzleActive") == 1 then -- should deal with concurrency
            if net.host then
                deactivatePuzzlePacket:sendAsHost(net.ALL, nil, tpLocked)
            end
            if currentTp:get("puzzleIsPuzzle") == 1 and sender:hasBuff(puzzleBuff) then
                sender:removeBuff(puzzleBuff)
            end
            currentTp:set("puzzleActive", 0):set("locked", tpLocked)
        end
    end
end)

------------------
-- Actual stuff --
------------------
registercallback("onStageEntry", function()
    if net.host then
        if #puzzleList > 0 then
            local currentTp = tpObj:find(1)
            if currentTp ~= nil then
                local pType = math.random(#puzzleList)
                local pIsP = puzzleList[pType][2]
                local pHard = 0
                if hardMode then
                    pHard = 1
                end
                currentTp:set("locked", 1)
                         :set("canActivate", 0)
                         :set("puzzleActive", 0)
                         :set("puzzleType", pType)
                         :set("puzzleIsPuzzle", pIsP)
                         :set("puzzleHard", pHard)
                
                initialTpSetupPacket:sendAsHost(net.ALL, nil, pType, pIsP, pHard)
            end
        end
    end
end, 11)
registercallback("onStageEntry", function()
    if not net.host then
        requestTpSetupPacket:sendAsClient()
    end
end, 10)

registercallback("onPlayerStep", function(player)
                                                                -- DEBUG ONLY
                                                                if player:get("true_invincible") ~= 1 then
                                                                    local currentTp = tpObj:find(1)
                                                                    player.x = currentTp.x
                                                                    player.y = currentTp.y - 16
                                                                    player:set("pHmax", 10):set("true_invincible", 1)
                                                                end
                                                                
    if not net.online or player == net.localPlayer then
        local currentTp = tpObj:find(1)
        if currentTp ~= nil then
            if player:get("puzzleActivatePopup") ~= nil then player:set("puzzleActivatePopup", nil) end
            if currentTp:get("locked") == 1 and currentTp:get("puzzleActive") == 0 then
                if player:collidesWith(currentTp, player.x, player.y) then
                    player:set("puzzleActivatePopup", 1)
                    if player:control("enter") == input.PRESSED then
                        if not net.host then
                            activatePuzzlePacket:sendAsClient(net.localPlayer:getNetIdentity())
                        else
                            currentTp:set("puzzleActive", 1)
                            local isHard = false
                            if currentTp:get("puzzleHard") == 1 then
                                isHard = true
                            end
                            puzzleList[currentTp:get("puzzleType")][1](player, isHard)
                            if currentTp:get("puzzleIsPuzzle") == 1 then
                                player:applyBuff(puzzleBuff, 60)
                            end
                            
                            activatePuzzlePacket:sendAsHost(net.ALL, nil, net.localPlayer:getNetIdentity())
                        end
                    end
                end
            end
        end
    end
end)

registercallback("onPlayerDraw", function(player)
    if not net.online or player == net.localPlayer then
        local currentTp = tpObj:find(1)
        if currentTp ~= nil and player:get("puzzleActivatePopup") ~= nil then
            local enterKeyText = input.getControlString("enter")
            local textPart1 = "Press "
            local textPart2 = " to attempt to unlock the teleporter..."
            local fullText = textPart1 .. enterKeyText .. textPart2
            graphics.color(Color.WHITE)
            graphics.print(textPart1, currentTp.x - graphics.textWidth(fullText, graphics.FONT_DEFAULT) / 2, currentTp.y - 32)
            graphics.color(Color.YELLOW)
            graphics.print(enterKeyText, currentTp.x - graphics.textWidth(fullText, graphics.FONT_DEFAULT) / 2 + graphics.textWidth(textPart1, graphics.FONT_DEFAULT), currentTp.y - 32)
            graphics.color(Color.WHITE)
            graphics.print(textPart2, currentTp.x - graphics.textWidth(fullText, graphics.FONT_DEFAULT) / 2 + graphics.textWidth(textPart1 .. enterKeyText, graphics.FONT_DEFAULT), currentTp.y - 32)
        end
    end
end)

registercallback("onStep", function()
    local currentTp = tpObj:find(1)
    if net.online then
        if net.host and currentTp:get("puzzleActive") == 1 then
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
                currentTp:set("puzzleActive", 0):set("locked", 1)
                deactivatePuzzlePacket:sendAsHost(net.ALL, nil, 1)
            end
        end
    else
        if currentTp:get("puzzleActive") == 1 and currentTp:get("puzzleIsPuzzle") == 1 then
            misc.setTimeStop(2)
        end
    end
end)