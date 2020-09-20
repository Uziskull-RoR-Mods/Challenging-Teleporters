
local alphabet = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"}
local words = {"SANDCRAB", "LEMURIAN", "CLAYMANS", "HOTIFRIT", "VAGRANTS", "COLOSSUS", "SCAVNGER", "WARBANNR", "AMETHYST"}

local ANIM_DURATION = 2 * 60
local ROTATION_DURATION = 1 * 60

local textColor = Color.fromHex(0x6BDC85)
local shadowColor = Color.fromHex(0x30643C)
local function drawConsoleText(text, x, y)
    graphics.color(shadowColor)
    graphics.print(text, x + 1, y + 1)--, CONSOLE_FONT)
    graphics.color(textColor)
    graphics.print(text, x, y)--, CONSOLE_FONT)
end

local function drawRouletteText(letter, x, y, inWhite)
    graphics.color(shadowColor)
    graphics.print(letter, x + 1, y + 1, graphics.FONT_LARGE, graphics.ALIGN_MIDDLE, graphics.ALIGN_CENTER)
    graphics.color(inWhite and Color.WHITE or textColor)
    graphics.print(letter, x, y, graphics.FONT_LARGE, graphics.ALIGN_MIDDLE, graphics.ALIGN_CENTER)
end

function codeRouletteUI(handler, frame)
    
    local handlerTable = handler:getData()
    local player, board, game = handlerTable.player, handlerTable.board, handlerTable.game
    local animation = handlerTable.animation
    
    -- end condition
    if not animation then
        local finished = true
        for i = 2, #game do
            if game[1].pos ~= game[i].pos then
                finished = false
                break
            end
        end
        if finished then
            -- start anim
            handlerTable.animation = 0
        end
    end
    
    if animation and animation >= ANIM_DURATION then
        if player:hasBuff(puzzleBuff) then
            player:removeBuff(puzzleBuff)
        end
        exitPuzzle(true, getInteractable():findNearest(player.x, player.y))
        handler:destroy()
    end
    
    if player:isValid() then
        -- drawing
        local x1, y1, x2, y2 = getScreenCorners(player)
        local centerX = x1 + (x2 - x1) / 2
        local centerY = y1 + (y2 - y1) / 2
        local screenImage = puzzleTemplates[Stage.getCurrentStage().displayName]
        local screenCornerX, screenCornerY = centerX - screenImage.width / 2 + 48, centerY - screenImage.height / 2 + 45
        local screenW, screenH = 308, 211
        local sliceX, sliceY = (#board + 4) * 2, (#board[1] + 6) * 2
        local sliceW, sliceH = screenW / sliceX, screenH / sliceY
        
        -- shading
        graphics.color(Color.BLACK)
        graphics.alpha(0.25)
        graphics.rectangle(x1 - 5, y1 - 5, x2 + 5, y2 + 5)
        graphics.alpha(1)
        
        -- template
        graphics.drawImage{
            image = screenImage,
            x = centerX,
            y = centerY
        }
        
        -- draw details
        drawConsoleText("Prov OS [" .. modloader.getModVersion("teleporterPuzzle") .. "] -- Online", screenCornerX + 8, screenCornerY + 8)
        
        -- rotate (check only when necessary)
        if not animation and frame % (hardMode and (ROTATION_DURATION / 2) or ROTATION_DURATION) == 0 then
            for i = 1, #game do
                if (game[i].order % 2 == 1 and frame % ROTATION_DURATION == 0)
                  or (game[i].order % 2 == 0 and frame % ROTATION_DURATION == ROTATION_DURATION/2) then
                    game[i].pos = ((game[i].pos + game[i].order - 1) % #board[1]) + 1
                end
            end
        end
        
        -- draw roulettes
        --[[
            xx|xx|xx|xx|xx|xx|xx|xx|xx|xx|xx|xx
            --+--+--+--+--+--+--+--+--+--+--+--
            xx|xx|xx|xx|xx|xx|xx|xx|xx|xx|xx|xx
            --+--+--+--+--+--+--+--+--+--+--+--
            xx|xx|xx|xx|xx|xx|xx|xx|xx|xx|xx|xx
            --+--+--+--+--+--+--+--+--+--+--+--
            xx|xx|  |  |  |  |  |  |  |  |xx|xx
            --+--+--+--+--+--+--+--+--+--+--+--
            xx|xx|  |  |  |  |  |  |  |  |xx|xx
            --+--+--+--+--+--+--+--+--+--+--+--
            xx|xx|  |  |  |  |  |  |  |  |xx|xx
            --+--+--+--+--+--+--+--+--+--+--+--
            xx|xx|  |  |  |  |  |  |  |  |xx|xx
            --+--+--+--+--+--+--+--+--+--+--+--
            xx|xx|  |  |  |  |  |  |  |  |xx|xx
            --+--+--+--+--+--+--+--+--+--+--+--
            xx|xx|  |  |  |  |  |  |  |  |xx|xx
            --+--+--+--+--+--+--+--+--+--+--+--
            xx|xx|  |  |  |  |  |  |  |  |xx|xx
            --+--+--+--+--+--+--+--+--+--+--+--
            xx|xx|xx|xx|xx|xx|xx|xx|xx|xx|xx|xx
            --+--+--+--+--+--+--+--+--+--+--+--
            xx|xx|xx|xx|xx|xx|xx|xx|xx|xx|xx|xx
            --+--+--+--+--+--+--+--+--+--+--+--
            xx|xx|xx|xx|xx|xx|xx|xx|xx|xx|xx|xx
        ]]--
        local xx, yy = 1, 1
        for x = 1 + (2 * 2), sliceX - (2 * 2), 2 do
            for y = 1 + (3 * 2), sliceY - (3 * 2), 2 do
                local ypos = (yy - (game[xx].pos - 1)) % #board[xx]
                if ypos == 0 then ypos = #board[xx] end
                drawRouletteText(board[xx][ypos], screenCornerX + x * sliceW, screenCornerY + y * sliceH, ypos == 1)
                yy = yy + 1
            end
            xx, yy = xx + 1, 1
        end
        
        -- play animation
        if animation then
            if animation % 60 >= 30 then
                graphics.color(textColor)
                graphics.alpha(0.2)
                graphics.rectangle(
                    screenCornerX + (1 + (2 * 2)) * sliceW - sliceW,
                    screenCornerY + ((game[1].pos*2 - 1) + (3 * 2)) * sliceH + sliceH / 2,
                    screenCornerX + (sliceX - (2 * 2)) * sliceW + sliceW / 2,
                    screenCornerY + ((game[1].pos*2 + 1) + (3 * 2)) * sliceH + sliceH / 2
                )
                graphics.alpha(1)
            end
            handlerTable.animation = handlerTable.animation + 1
        end
        
        -- draw controls (and highlight current control)
        xx = 1
        y = sliceY - (1 * 2) - 1
        for x = 1 + (2 * 2), sliceX - (2 * 2), 2 do
            local symbol = (game[xx].order < 0) and "<" or ">"
            drawRouletteText((game[xx].order % 2 == 0) and (symbol..symbol) or symbol, screenCornerX + x * sliceW, screenCornerY + y * sliceH)
            if handlerTable.cursor == xx then
                graphics.color(textColor)
                graphics.alpha(0.2)
                graphics.rectangle(
                    screenCornerX + x * sliceW - sliceW,
                    screenCornerY + y * sliceH - sliceH,
                    screenCornerX + x * sliceW + sliceW,
                    screenCornerY + y * sliceH + sliceH
                )
                graphics.alpha(1)
            end
            xx = xx + 1
        end
    end
    
    -- control
    if not player:isValid() or player:get("dead") == 1 then
        giveUp(player) -- TODO: probably won't work
        handler:destroy()
    elseif not animation then
        if frame > 1 and player:control("enter") == input.PRESSED then
            -- exit
            giveUp(player)
            handler:destroy()
        elseif player:control("left") == input.PRESSED or player:control("right") == input.PRESSED then
            local pressedLeft = player:control("left") == input.PRESSED
            local pressedRight = player:control("right") == input.PRESSED
            if not (pressedLeft and pressedRight) then
                handlerTable.cursor = ((handlerTable.cursor + (pressedRight and 0 or -2)) % #game) + 1
            end
        elseif player:control("ability1") == input.PRESSED or input.checkKeyboard("space") == input.PRESSED then
            game[handlerTable.cursor].order = game[handlerTable.cursor].order * -1
        end
    end
end

local function start(player)
    if not net.online or net.localPlayer == player then
        local handler = graphics.bindDepth(-99999, codeRouletteUI)
        local handlerTable = handler:getData()
        -- handlerTable["isHard"] = hardMode
        handlerTable.player = player
        local orders = {-1, 1}
        if hardMode then
            orders[3], orders[4] = 2, -2
        end
        local word = table.irandom(words)
        handlerTable.board, handlerTable.game = {}, {}
        shuffle(alphabet)
        local ai = 1
        local letter
        for i = 1, word:len() do
             handlerTable.board[i] = {word:sub(i, i)}
             while #handlerTable.board[i] < 7 do
                letter = alphabet[ai]
                if handlerTable.board[i][1] ~= letter then
                    handlerTable.board[i][#handlerTable.board[i]+1] = letter
                end
                ai = (ai % #alphabet) + 1
             end
             handlerTable.game[i] = {
                pos = math.random(#handlerTable.board[i]),
                order = table.irandom(orders)
             }
        end
        handlerTable.cursor = 1
    end
end

-- table.insert(puzzleList, {start = start, isPuzzle = true})
table.insert(puzzleList.panel, start)