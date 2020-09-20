local spriteLife = Sprite.load("lockPick_life", "puzzles/lockPick/life", 1, 5, 5)

local colorBase = Color.fromHex(0x414152)
local colorSub = Color.fromHex(0x38364E)

PICK_HP = 2 * 60
ACCEPTED_MARGIN = 20
TURN_SENSITIVITY = 2
PICK_DAMAGE = 1
ANIM_DURATION = 1 * 60

--[[
    instant block (-)
    turns a % before blocking (o)
    acceptable (+)
    actual target (X)
    
    + is 0.5x of the accepted margin and o is 2x of it
    margin dependant on difficulty

        ----------|oooooooooo|+++++|X|+++++|oooooooooo|----------
]]--

function lockPickUI(handler, frame)
    local handlerTable = handler:getData()
    local player, lock, pick = handlerTable.player, handlerTable.lock, handlerTable.pick
    
    -- end condition
    if math.abs(pick.currentRotation - lock.correctAngle) <= lock.buffer and lock.currentRotation == -90 then
        if player:hasBuff(puzzleBuff) then
            player:removeBuff(puzzleBuff)
        end
        exitPuzzle(true, getInteractable():findNearest(player.x, player.y))
        handler:destroy()
        return
    else
        if player:isValid() then
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
            
            -- draw lock
            if not lock.image then
                local surf = Surface.new(180, 180)
                local cX, cY = surf.width/2, surf.height/2
                graphics.setTarget(surf)
                -- lock groove
                graphics.color(colorSub)
                graphics.circle(
                    cX,
                    cY,
                    80
                )
                graphics.color(colorBase)
                graphics.circle(
                    cX,
                    cY,
                    70
                )
                -- actual lock
                graphics.color(Color.BLACK)
                graphics.circle(
                    cX,
                    cY - 15,
                    20
                )
                graphics.triangle(
                    cX,        cY - 35,
                    cX - 20,   cY + 30,
                    cX + 20,   cY + 30
                )
                -- tension tool
                -- TODO: get off your ass and do this
                lock.image = surf:createSprite(cX, cY)
                graphics.resetTarget()
                surf:free()
            end
            graphics.drawImage{
                image = lock.image,
                x = templateCenterX,
                y = templateCenterY,
                angle = lock.currentRotation
            }
            
            -- draw pick
            if not pick.image then
                local surf = Surface.new(10, 100)
                graphics.setTarget(surf)
                graphics.color(Color.GRAY)
                graphics.rectangle(
                    1, 1,
                    10, 35
                )
                graphics.setBlendMode("subtract")
                graphics.rectangle(
                    4, 5,
                    6, 15
                )
                graphics.setBlendMode("normal")
                graphics.triangle(
                    1, 35,
                    10, 35,
                    5, 125
                )
                pick.image = surf:createSprite(surf.width/2, surf.height)
                graphics.resetTarget()
                surf:free()
            end
            if not handlerTable.animation then
                local hpShake = 0
                if lock.ableToRotate and lock.currentRotation == -lock.ableToRotate then
                    --hpShake = math.clamp((6 * 60 / pick.hp) * math.cos(pick.hp), -10, 10)
                    hpShake = math.clamp((60 / pick.hp) * math.cos(math.pi * pick.hp / 2), -5, 5)
                end
                graphics.drawImage{
                    image = pick.image,
                    x = templateCenterX,
                    y = templateCenterY,
                    angle = pick.currentRotation + hpShake
                }
            end
            
            -- draw tries
            local tryY = templateCenterY - 125
            for i = 1, pick.maxLives do
                if pick.lives >= i then
                    local tryX = templateCenterX + (i - pick.maxLives/2) * spriteLife.width
                    graphics.drawImage{
                        image = spriteLife,
                        x = tryX,
                        y = tryY
                    }
                end
            end
            
        end
        
        -- pick break animation
        if handlerTable.animation then
            handlerTable.animation = handlerTable.animation - 1
            if handlerTable.animation == 0 then
                handlerTable.animation = nil
                lock.currentRotation = 0
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
            if frame > 1 and player:control("enter") == input.PRESSED or pick.lives == 0 then
                -- exit
                giveUp(player)
                handler:destroy()
            elseif not handlerTable.animation then
                local heldUse = player:control("ability1") == input.HELD or input.checkKeyboard("space") == input.HELD
                if lock.resetting then
                    -- keep rotating the lock back to normal
                    lock.currentRotation = math.min(0, lock.currentRotation + TURN_SENSITIVITY * 1.5)
                    if lock.currentRotation == 0 then
                        lock.resetting = false
                    end
                elseif player:control("ability1") == input.RELEASED or input.checkKeyboard("space") == input.RELEASED then
                    -- if stopped rotating, start resetting back to normal
                    lock.resetting = true
                    lock.ableToRotate = nil
                elseif heldUse then
                    -- start/continue picking (rotating)
                    if not lock.ableToRotate then
                        local angleBetween = math.abs(lock.correctAngle - pick.currentRotation)
                        lock.ableToRotate = 0
                        if angleBetween <= lock.buffer * (1) then
                            lock.ableToRotate = 90
                        elseif angleBetween <= lock.buffer * (1 + 3) then
                            lock.ableToRotate = 90 - 90 * (angleBetween - lock.buffer) / (lock.buffer * 3)
                        end
                    end
                    if lock.currentRotation > -lock.ableToRotate then
                        lock.currentRotation = math.max(-lock.ableToRotate, lock.currentRotation - TURN_SENSITIVITY/2)
                    else
                        -- already at max rotation, deal damage to pick
                        pick.hp = math.max(0, pick.hp - 1)
                        if pick.hp == 0 then
                            -- it ded
                            pick.lives = pick.lives - 1
                            pick.currentRotation = 0
                            pick.hp = (hardMode and PICK_HP/2 or PICK_HP)
                            handlerTable.animation = ANIM_DURATION
                            lock.ableToRotate = nil
                            -- TODO: maybe pick break sound?
                        end
                    end
                elseif not heldUse and (player:control("left") == input.HELD or player:control("right") == input.HELD) then
                    local pressedLeft = player:control("left") == input.HELD
                    local pressedRight = player:control("right") == input.HELD
                    if not (pressedLeft == pressedRight) then
                        pick.currentRotation = math.clamp(pick.currentRotation + TURN_SENSITIVITY * (pressedLeft and 1 or -1), -90, 90)
                    end
                end
            end
        end
    end
end

local function start(player)
    if not net.online or net.localPlayer == player then
        local handler = graphics.bindDepth(-99999, lockPickUI)
        local handlerTable = handler:getData()
        handlerTable.player = player
        handlerTable.lock = {
            correctAngle = math.random(-90, 90),
            currentRotation = 0,
            buffer = (hardMode and ACCEPTED_MARGIN/2 or ACCEPTED_MARGIN)/2,
            resetting = false
        }
        handlerTable.pick = {
            hp = (hardMode and PICK_HP/2 or PICK_HP),
            currentRotation = 0,
            lives = hardMode and 3 or 5,
            maxLives = hardmode and 3 or 5
        }
    end
end

-- table.insert(puzzleList, {start = start, isPuzzle = true})
table.insert(puzzleList.puzzle, start)