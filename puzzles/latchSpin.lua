-- Made by Uziskull

-- local spriteCrest = Sprite.load("latchSpin_crest", "puzzles/latchSpin/crest", 1, 12, 12)
-- local spriteSlice = Sprite.load("latchSpin_slice", "puzzles/latchSpin/slice", 6, 12, 46)

local spriteCrest = Sprite.load("latchSpin_crest", "puzzles/latchSpin/fancy_crest", 1, 20, 20)
local spriteSlice = Sprite.load("latchSpin_slice", "puzzles/latchSpin/fancy_slice", 25, 17, 89)

--math.randomseed(os.time())

local function giveUp(player)
    if player:isValid() then
        if player:hasBuff(puzzleBuff) then
            player:removeBuff(puzzleBuff)
        end
    end
    if not net.host then
        deactivatePuzzlePacket:sendAsClient(1)
    else
        local currentTp = tpObj:find(1)
        currentTp:set("puzzleActive", 0):set("locked", 1)
        
        deactivatePuzzlePacket:sendAsHost(net.ALL, nil, 1)
    end
end

function latchSpinUI(handler, frame)
    local colorBase = Color.fromHex(0x414152)
    local colorSub = Color.fromHex(0x38364E)
    
    local handlerTable = handler:getData()
    local player = handlerTable["player"]
    
    -- end condition
    local finished = true
    for i = 1, 12 do
        if handlerTable["slices"][i] ~= 25 then
            finished = false
            break
        end
    end
    
    if finished then
        if player:hasBuff(puzzleBuff) then
            player:removeBuff(puzzleBuff)
        end
        if not net.host then
            deactivatePuzzlePacket:sendAsClient(0)
        else
            local currentTp = tpObj:find(1)
            currentTp:set("puzzleActive", 0):set("locked", 0)
            
            deactivatePuzzlePacket:sendAsHost(net.ALL, nil, 0)
        end
        handler:destroy()
    else
        if player:isValid() then
            -- physics
            handlerTable["angle"] = (handlerTable["angle"] + handlerTable["angleStep"]) % 360
            for i = 1, 12 do
                if handlerTable["slices"][i] > 1 and handlerTable["slices"][i] < 25 
                  or handlerTable["slices"][i] < -1 and handlerTable["slices"][i] > -25 then
                    handlerTable["slices"][i] = handlerTable["slices"][i] + 1
                    if handlerTable["slices"][i] == -1 then
                        handlerTable["slices"][i] = 1
                    end
                end
            end
        
            -- drawing
            local x1, y1, x2, y2 = getScreenCorners(player)
            local centerX = x1 + (x2 - x1) / 2
            local centerY = y1 + (y2 - y1) / 2
            local templateCenterX = centerX + 48
            local templateCenterY = centerY - 1
            
            -- shading
            graphics.color(Color.BLACK)
            graphics.alpha(0.25)
            graphics.rectangle(x1 - 5, y1 - 5, x2 + 5, y2 + 5)
            graphics.alpha(1)
            
            -- template
            graphics.drawImage{
                image = puzzleTemplates[Stage.getCurrentStage().displayName],
                x = centerX,
                y = centerY
            }
            
            -- puzzle ball groove
            graphics.color(colorSub)
            graphics.circle(
                templateCenterX,
                templateCenterY,
                110
            )
            graphics.color(colorBase)
            graphics.circle(
                templateCenterX,
                templateCenterY,
                100
            )
            
            -- puzzle shadow
            graphics.color(colorSub)
            graphics.circle(
                templateCenterX,
                templateCenterY,
                90
            )
            
            -- slices
            for i = 1, 12 do
                local sliceAngle = (30 * i - 75) % 360
                graphics.drawImage{
                    image = spriteSlice,
                    subimage = math.abs(handlerTable["slices"][i]),
                    x = templateCenterX,
                    y = templateCenterY,
                    angle = sliceAngle
                }
            end
            
            -- crest
            graphics.drawImage{
                image = spriteCrest,
                x = templateCenterX,
                y = templateCenterY
            }
            
            -- puzzle ball
            graphics.color(Color.WHITE)
            graphics.circle(
                templateCenterX + 105 * math.cos(math.rad(handlerTable["angle"])),
                templateCenterY - 105 * math.sin(math.rad(handlerTable["angle"])),
                5
            )
            
            -- tries
            if handlerTable["isHard"] then
                local tryY = templateCenterY - 125
                for i = 1, 5 do
                    local tryColor = Color.ROR_RED
                    if i > handlerTable["tries"] then
                        tryColor = colorSub
                    end
                    local tryX = templateCenterX + (10 + 5) * (i - 3)
                    graphics.color(tryColor)
                    graphics.circle(
                        tryX,
                        tryY,
                        5
                    )
                    graphics.color(colorBase)
                    graphics.circle(
                        tryX,
                        tryY,
                        3
                    )
                end
            end
            
        end
        
        -- control
        if not player:isValid() then
            giveUp(player)
            handler:destroy()
        elseif player:get("dead") == 1 then
            giveUp(player)
            handler:destroy()
        else
            if frame > 1 and player:control("enter") == input.PRESSED or handlerTable["tries"] == 0 then
                -- exit
                giveUp(player)
                handler:destroy()
            elseif player:control("ability1") == input.PRESSED or input.checkKeyboard("space") == input.PRESSED then
                -- activated
                if handlerTable["isHard"] then
                    handlerTable["angleStep"] = handlerTable["angleStep"] * -1
                end
                
                local chosenSlice = math.floor(handlerTable["angle"] / 30)
                if chosenSlice == 0 then
                    chosenSlice = 12
                end
                if handlerTable["slices"][chosenSlice] == 1 then
                    handlerTable["slices"][chosenSlice] = 2
                elseif handlerTable["slices"][chosenSlice] == 25 then
                    handlerTable["slices"][chosenSlice] = -24
                    handlerTable["tries"] = handlerTable["tries"] - 1
                end
            end
        end
    end
end

local function start(player, isHard)
    if not net.online or net.localPlayer == player then
        local handler = graphics.bindDepth(-99999, latchSpinUI)
        local handlerTable = handler:getData()
        handlerTable["isHard"] = isHard
        handlerTable["angle"] = math.random(0, 359)
        handlerTable["angleStep"] = math.random() * 2 + 5
        if math.random(2) == 1 then
            handlerTable["angleStep"] = handlerTable["angleStep"] * -1
        end
        handlerTable["player"] = player
        sliceTable = {}
        for i = 1, 12 do
            local v = math.random(2)
            if v == 2 then v = 25 end
            table.insert(sliceTable, v)
        end
        for i = 1, 4 do
            sliceTable[math.random(12)] = 1
        end
        handlerTable["slices"] = sliceTable
        handlerTable["tries"] = 5
    end
end

table.insert(puzzleList, {start, 1})