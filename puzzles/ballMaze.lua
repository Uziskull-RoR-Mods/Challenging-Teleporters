-- Made by Uziskull

--math.randomseed(os.time())

local angleStep = 4 -- rotating 360 in 1.5 seconds

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

local function shuffle(l)
    for m = #l, 2, -1 do
        local n = math.random(m)
        l[m], l[n] = l[n], l[m]
    end
end

local function checkNodes(board, list, current)
    local tile = board[current[1]][current[2]]
    local childTiles = {}
    if tile["up"] ~= nil then
        table.insert(childTiles, {current[1], current[2] - 1})
    end
    if tile["down"] ~= nil then
        table.insert(childTiles, {current[1], current[2] + 1})
    end
    if tile["left"] ~= nil then
        table.insert(childTiles, {current[1] - 1, current[2]})
    end
    if tile["right"] ~= nil then
        table.insert(childTiles, {current[1] + 1, current[2]})
    end
    for i = 1, #list do
        if list[i][1] == current[1] and list[i][2] == current[2] then
            return {{-1, -1}}
        end
        for j = 1, #childTiles do
            if list[i][1] == childTiles[j][1] and list[i][2] == childTiles[j][2] then
                table.remove(childTiles, j)
                break
            end
        end
    end
    table.insert(list, current)
    local totChildLists = {}
    for i = 1, #childTiles do
        local childList = checkNodes(board, list, childTiles[i])
        for j = 1, #childList do
            if childList[j][1] == -1 or childList[j][2] == -1 then
                return {{-1, -1}}
            end
            table.insert(totChildLists, {childList[j][1], childList[j][2]})
        end
    end
    --for i = 1, #list do
        table.insert(totChildLists, 1, {current[1], current[2]})
    --end
    return totChildLists
end

function generateBoard(isHard)
    local tableDim = 3
    if isHard then
        tableDim = 4
    end
    local tableTotalTiles = tableDim * tableDim
    
    -- "empty" the board
    local board = {}
    for i = 1, tableDim do
        board[i] = {}
        for j = 1, tableDim do
            board[i][j] = {}
        end
    end
    
    local done = false
    while not done do
    
        -- create random listing of tiles
        randomList = {}
        for i = 1, tableDim do
            for j = 1, tableDim do
                table.insert(randomList, {i, j})
            end
        end
        shuffle(randomList)
        
        -- iterate tile list
        for i = 1, tableTotalTiles do
            local currentTile = randomList[i]
            local currentTileBoard = board[currentTile[1]][currentTile[2]]
        
            local directions = {}
            if currentTile[2] - 1 >= 1 then table.insert(directions, {"up", currentTile[1], currentTile[2] - 1, "down"}) end
            if currentTile[2] + 1 <= tableDim then table.insert(directions, {"down", currentTile[1], currentTile[2] + 1, "up"}) end
            if currentTile[1] - 1 >= 1 then table.insert(directions, {"left", currentTile[1] - 1, currentTile[2], "right"}) end
            if currentTile[1] + 1 <= tableDim then table.insert(directions, {"right", currentTile[1] + 1, currentTile[2], "left"}) end
            shuffle(directions)
            
            local newConnection = false
            local pickedDirection = {}
            for j = 1, #directions do
                pickedDirection = directions[j]
                -- pick a random direction, if it was picked before pick another
                if currentTileBoard[pickedDirection[1]] == nil then
                    newConnection = true
                    board[currentTile[1]][currentTile[2]][pickedDirection[1]] = 1
                    board[pickedDirection[2]][pickedDirection[3]][pickedDirection[4]] = 1
                    break
                end
            end
            if newConnection then
                local list = checkNodes(board, {}, currentTile)
                local countList = 0
                for j = 1, #list do
                    if list[j][1] == -1 or list[j][2] == -1 then
                        -- undo
                        board[currentTile[1]][currentTile[2]][pickedDirection[1]] = nil
                        board[pickedDirection[2]][pickedDirection[3]][pickedDirection[4]] = nil
                        countList = 0
                    else
                        countList = countList + 1
                    end
                end
                if countList == tableTotalTiles then
                    -- complete
                    done = true
                    break
                end
            end
        end
    end
    
    -- pick a start and an end
    randomList = {}
    for i = 1, tableDim do
        for j = 1, tableDim do
            local tile = board[i][j]
            if tile["up"] ~= nil and tile["down"] == nil and tile["left"] == nil and tile["right"] == nil
              or tile["up"] == nil and tile["down"] ~= nil and tile["left"] == nil and tile["right"] == nil
              or tile["up"] == nil and tile["down"] == nil and tile["left"] ~= nil and tile["right"] == nil
              or tile["up"] == nil and tile["down"] == nil and tile["left"] == nil and tile["right"] ~= nil then
                table.insert(randomList, {i, j})
            end
        end
    end
    local r = math.random(#randomList)
    local pick = randomList[r]
    board[pick[1]][pick[2]]["start"] = 1
    table.remove(randomList, r)
    r = math.random(#randomList)
    pick = randomList[r]
    board[pick[1]][pick[2]]["end"] = 1
    
    return board
end

function ballMazeUI(handler, frame)
    local colorBase = Color.fromHex(0x414656)
    local colorSub = Color.fromHex(0x38364E)
    
    local handlerTable = handler:getData()
    local player = handlerTable["player"]
    local isHard = handlerTable["isHard"]
    
    local surfaceDim = 126 -- 126 / 3 == 42, 42 / 3 == 14
    if isHard then
        surfaceDim = 132 -- 132 / 4 == 33, 33 / 3 == 11
    end
    local tableDim = 3
    if isHard then
        tableDim = 4
    end
    local tableTotalTiles = tableDim * tableDim
    
    if frame == 1 then
        local boardStart = {}
        local boardEnd = {}
        -- create board sprite
        local colorStart = Color.DARK_GREEN
        local colorEnd = Color.DARK_RED
        local defaultColor = graphics.getColor()
        
        local surface = Surface.new(surfaceDim, surfaceDim)
        graphics.setTarget(surface)
        for j = 1, 3 * tableDim do
            for i = 1, 3 * tableDim do
                local ii = math.ceil(i / 3)
                local jj = math.ceil(j / 3)
                graphics.color(colorBase)
                if (i == 2 or i == 5 or i == 8 or i == 11) and (j == 2 or j == 5 or j == 8 or j == 11) then
                    if handlerTable["board"][ii][jj]["start"] ~= nil then
                        boardStart = {ii, jj}
                        graphics.color(colorStart)
                    elseif handlerTable["board"][ii][jj]["end"] ~= nil then
                        boardEnd = {ii, jj}
                        graphics.color(colorEnd)
                    else
                        graphics.color(colorSub)
                    end
                else
                    if handlerTable["board"][ii][jj]["up"] ~= nil and (i == 2 or i == 5 or i == 8 or i == 11) and (j == 1 or j == 4 or j == 7 or j == 10) then
                        graphics.color(colorSub)
                    elseif handlerTable["board"][ii][jj]["down"] ~= nil and (i == 2 or i == 5 or i == 8 or i == 11) and (j == 3 or j == 6 or j == 9 or j == 12) then
                        graphics.color(colorSub)
                    elseif handlerTable["board"][ii][jj]["left"] ~= nil and (j == 2 or j == 5 or j == 8 or j == 11) and (i == 1 or i == 4 or i == 7 or i == 10) then
                        graphics.color(colorSub)
                    elseif handlerTable["board"][ii][jj]["right"] ~= nil and (j == 2 or j == 5 or j == 8 or j == 11) and (i == 3 or i == 6 or i == 9 or i == 12) then
                        graphics.color(colorSub)
                    end
                end
                local tileSize = surfaceDim / tableDim / 3
                graphics.rectangle((i - 1) * tileSize, (j - 1) * tileSize, (i - 1) * tileSize + tileSize - 1, (j - 1) * tileSize + tileSize - 1)
            end
        end
        
        handlerTable["sprite"] = surface:createSprite(surfaceDim / 2, surfaceDim / 2)
        
        graphics.resetTarget()
        surface:free()
        graphics.color(defaultColor)
        
        -- setup initial ball values
        handlerTable["ball"]["speedX"] = 0
        handlerTable["ball"]["speedY"] = 0
        handlerTable["ball"]["x"] = boardStart[1]
        handlerTable["ball"]["y"] = boardStart[2]
        handlerTable["goal"]["x"] = boardEnd[1]
        handlerTable["goal"]["y"] = boardEnd[2]
    end
    if frame >= 1 then
        -- physics
        local phyAngle = (handlerTable["angle"] + 90) % 360
        local accelY = math.sin(math.rad(phyAngle)) * 0.0025
        local accelX = math.cos(math.rad(phyAngle)) * 0.0025
        local dragY = 2/5 * accelY
        local dragX = 2/5 * accelX
        
        handlerTable["ball"]["speedX"] = handlerTable["ball"]["speedX"] + accelX - dragX
        handlerTable["ball"]["speedY"] = handlerTable["ball"]["speedY"] + accelY - dragY
        
        local xx = handlerTable["ball"]["x"]
        local bX = math.floor(xx + 0.5)
        local yy = handlerTable["ball"]["y"]
        local bY = math.floor(yy + 0.5)
        
        local bigTile = surfaceDim / tableDim
        local totalBallSize = 10
        if isHard then
            totalBallSize = 7
        end
        
        local lbX = bX - 2/bigTile
        local ubX = bX + 2/bigTile
        if yy >= bY - math.ceil(bigTile / 3 / 2)/bigTile and yy <= bY + math.ceil(bigTile / 3 / 2)/bigTile then
            if handlerTable["board"][bX][bY]["left"] ~= nil then
                lbX = lbX - (totalBallSize + math.ceil(bigTile / 3 / 2) + 2)/bigTile - 0.5
            end
            if handlerTable["board"][bX][bY]["right"] ~= nil then
                ubX = ubX + (totalBallSize + math.ceil(bigTile / 3 / 2) + 2)/bigTile + 0.5
            end
        end
        xx = math.clamp(xx + handlerTable["ball"]["speedX"], lbX, ubX)
        if xx == lbX or xx == ubX then
            handlerTable["ball"]["speedX"] = 0
        end
        bX = math.floor(xx + 0.5)
        handlerTable["ball"]["x"] = xx
        
        local lbY = bY - 2/bigTile
        local ubY = bY + 2/bigTile
        if xx >= bX - math.ceil(bigTile / 3 / 2)/bigTile and xx <= bX + math.ceil(bigTile / 3 / 2)/bigTile then
            if handlerTable["board"][bX][bY]["up"] ~= nil then
                lbY = lbY - (totalBallSize + math.ceil(bigTile / 3 / 2) + 2)/bigTile - 0.5
            end
            if handlerTable["board"][bX][bY]["down"] ~= nil then
                ubY = ubY + (totalBallSize + math.ceil(bigTile / 3 / 2) + 2)/bigTile + 0.5
            end
        end
        yy = math.clamp(yy + handlerTable["ball"]["speedY"], lbY, ubY)
        if yy == lbY or yy == ubY then
            handlerTable["ball"]["speedY"] = 0
        end
        bY = math.floor(yy + 0.5)
        handlerTable["ball"]["y"] = yy
        
        -- end condition
        if handlerTable["goal"]["x"] == bX and handlerTable["goal"]["y"] == bY and
          yy >= bY - math.ceil(bigTile / 3 / 2)/bigTile and yy <= bY + math.ceil(bigTile / 3 / 2)/bigTile and
          xx >= bX - math.ceil(bigTile / 3 / 2)/bigTile and xx <= bX + math.ceil(bigTile / 3 / 2)/bigTile then
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
            handlerTable["sprite"]:delete()
            handler:destroy()
        else
            -- drawing
            if player:isValid() then
                local x1, y1, x2, y2 = getScreenCorners(player)
                local centerX = x1 + (x2 - x1) / 2
                local centerY = y1 + (y2 - y1) / 2
                
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
                
                -- shadow ball
                graphics.color(colorSub)
                graphics.circle(
                    centerX + 48,
                    centerY - 1,
                    104
                )
                
                -- puzzle ball
                graphics.color(colorBase)
                graphics.circle(
                    centerX + 48,
                    centerY - 1,
                    100
                )
                
                -- board sprite w/ angle
                graphics.drawImage{
                    image = handlerTable["sprite"],
                    x = centerX + 48,
                    y = centerY - 1,
                    angle = handlerTable["angle"]
                }
                
                -- ball
                graphics.color(Color.GRAY)
                local ballSize = {5, 4}
                if isHard then
                    ballSize = {3, 3}
                end
                local ballX1, ballY1, ballX2, ballY2 =
                    -surfaceDim / 2 + (handlerTable["ball"]["x"] - 0.5) * (surfaceDim / tableDim) - ballSize[1],
                    -surfaceDim / 2 + (handlerTable["ball"]["y"] - 0.5) * (surfaceDim / tableDim) - ballSize[1],
                    -surfaceDim / 2 + (handlerTable["ball"]["x"] - 0.5) * (surfaceDim / tableDim) + ballSize[2],
                    -surfaceDim / 2 + (handlerTable["ball"]["y"] - 0.5) * (surfaceDim / tableDim) + ballSize[2]
                    
                graphics.triangle(
                    centerX + 48 + ballX1 * math.cos(math.rad(handlerTable["angle"] * -1)) - ballY1 * math.sin(math.rad(handlerTable["angle"] * -1)),
                    centerY - 1 + ballX1 * math.sin(math.rad(handlerTable["angle"] * -1)) + ballY1 * math.cos(math.rad(handlerTable["angle"] * -1)),
                    centerX + 48 + ballX2 * math.cos(math.rad(handlerTable["angle"] * -1)) - ballY1 * math.sin(math.rad(handlerTable["angle"] * -1)),
                    centerY - 1 + ballX2 * math.sin(math.rad(handlerTable["angle"] * -1)) + ballY1 * math.cos(math.rad(handlerTable["angle"] * -1)),
                    centerX + 48 + ballX1 * math.cos(math.rad(handlerTable["angle"] * -1)) - ballY2 * math.sin(math.rad(handlerTable["angle"] * -1)),
                    centerY - 1 + ballX1 * math.sin(math.rad(handlerTable["angle"] * -1)) + ballY2 * math.cos(math.rad(handlerTable["angle"] * -1))
                )
                graphics.triangle(
                    centerX + 48 + ballX2 * math.cos(math.rad(handlerTable["angle"] * -1)) - ballY2 * math.sin(math.rad(handlerTable["angle"] * -1)),
                    centerY - 1 + ballX2 * math.sin(math.rad(handlerTable["angle"] * -1)) + ballY2 * math.cos(math.rad(handlerTable["angle"] * -1)),
                    centerX + 48 + ballX2 * math.cos(math.rad(handlerTable["angle"] * -1)) - ballY1 * math.sin(math.rad(handlerTable["angle"] * -1)),
                    centerY - 1 + ballX2 * math.sin(math.rad(handlerTable["angle"] * -1)) + ballY1 * math.cos(math.rad(handlerTable["angle"] * -1)),
                    centerX + 48 + ballX1 * math.cos(math.rad(handlerTable["angle"] * -1)) - ballY2 * math.sin(math.rad(handlerTable["angle"] * -1)),
                    centerY - 1 + ballX1 * math.sin(math.rad(handlerTable["angle"] * -1)) + ballY2 * math.cos(math.rad(handlerTable["angle"] * -1))
                )
                
            end
            
            -- control
            if not player:isValid() then
                giveUp(player)
                handlerTable["sprite"]:delete()
                handler:destroy()
            elseif player:get("dead") == 1 then
                giveUp(player)
                handlerTable["sprite"]:delete()
                handler:destroy()
            else
                local gamepad = input.getPlayerGamepad() -- input.getPlayerGamepad(player)
                local heldLeft = player:control("left") == input.HELD
                local heldRight = player:control("right") == input.HELD
                if gamepad ~= nil then
                    if not heldLeft then
                        heldLeft = input.getGamepadAxis("lh", gamepad) < -0.3 or input.getGamepadAxis("rh", gamepad) < -0.3
                    end
                    if not heldRight then
                        heldRight = input.getGamepadAxis("lh", gamepad) > 0.3 or input.getGamepadAxis("rh", gamepad) > 0.3
                    end
                end
                if frame > 1 and player:control("enter") == input.PRESSED then
                    -- exit
                    giveUp(player)
                    handlerTable["sprite"]:delete()
                    handler:destroy()
                elseif heldLeft and not heldRight then
                    handlerTable["angle"] = (handlerTable["angle"] - angleStep) % 360
                elseif heldRight and not heldLeft then
                    handlerTable["angle"] = (handlerTable["angle"] + angleStep) % 360
                end
            end
        end
    end
end

local function start(player, isHard)
    if not net.online or net.localPlayer == player then
        local board = generateBoard(isHard)
        local handler = graphics.bindDepth(-99999, ballMazeUI)
        local handlerTable = handler:getData()
        handlerTable["isHard"] = isHard
        handlerTable["board"] = board
        handlerTable["sprite"] = nil
        handlerTable["angle"] = 0
        handlerTable["player"] = player
        handlerTable["ball"] = {}
        handlerTable["goal"] = {}
    end
end

table.insert(puzzleList, {start, 1})