-- Made by Uziskull

local portrait = Sprite.find("Portrait");

--math.randomseed(os.time())

-- duration of puzzle piece slide
local slideDuration = 10

local function checkInversions(table)
    local boardSize = math.sqrt(#table)
    local result = true
    local numInversions = 0
    for i = 1, #table - 1 do
        for j = i + 1, #table do
            if table[i] ~= 0 and table[j] ~= 0 and table[i] > table[j] then
                numInversions = numInversions + 1
            end
        end
    end
    if boardSize % 2 ~= 0 then
        result = numInversions % 2 ~= 0
    else
        local blankRow = 0
        for i = 1, #table do
            if table[i] == 0 then
                blankRow = math.floor((i - 1) / 4)
                break
            end
        end
        result = (blankRow + numInversions) % 2 == 0
    end
    return result
end

function slidePuzzleUI(handler, frame)
    local colorBase = Color.fromHex(0x414152)
    local colorSub = Color.fromHex(0x38364E)
    
    local handlerTable = handler:getData()
    local player = handlerTable["player"]
    local isHard = handlerTable["isHard"]
    local piecesOrder = handlerTable["order"]
    
    local surfaceDim = 132
    local tableTiles = 3
    if isHard then
        tableTiles = 4
    end
    local tileDim = surfaceDim / tableTiles
    
    if frame == 1 then
        -- setup puzzle
        piecesTable = {}
        for i = 1, tableTiles do
            for j = 1, tableTiles do
                if not (i == tableTiles and j == tableTiles) then
                    local tileSurface = Surface.new(tileDim, tileDim)
                    local imageX = (i - 1) * tileDim * -1
                    local imageY = (j - 1) * tileDim * -1
                    graphics.setTarget(tileSurface)
                    
                    graphics.drawImage{
                        image = portrait,
                        subimage = handlerTable["sprite"],
                        x = imageX + portrait.xorigin * (surfaceDim / portrait.width),
                        y = imageY + portrait.yorigin * (surfaceDim / portrait.height),
                        xscale = surfaceDim / portrait.width,
                        yscale = surfaceDim / portrait.height
                    }
                    
                    local pieceSprite = tileSurface:createSprite(0, 0)
                    table.insert(piecesTable, pieceSprite)
                    graphics.resetTarget()
                    tileSurface:free()
                end
            end
        end
        handlerTable["pieces"] = piecesTable
    end
    if frame >= 1 then
        local piecesImage = handlerTable["pieces"]
        
        -- end condition
        local finished = true
        local count = 1
        for i = 1, tableTiles do
            for j = 1, tableTiles do
                if not (i == tableTiles and j == tableTiles) then
                    if piecesOrder[i][j] ~= count then
                        finished = false
                        break
                    else
                        count = count + 1
                    end
                end
            end
            if not finished then
                break
            end
        end
        
        if finished then
            if player:hasBuff(puzzleBuff) then
                player:removeBuff(puzzleBuff)
            end
            exitPuzzle(true, getInteractable():findNearest(player.x, player.y))
            handler:destroy()
        else
            if player:isValid() then
                
                -- animation
                if handlerTable["animation"] ~= nil then
                    handlerTable["animation"]["frame"] = handlerTable["animation"]["frame"] + 1
                    if handlerTable["animation"]["frame"] == slideDuration then
                        local xx = handlerTable["animation"]["fromX"]
                        local yy = handlerTable["animation"]["fromY"]
                        local dX = 0
                        local dY = 0
                        local direction = handlerTable["animation"]["direction"]
                        if direction == "up" then
                            dY = -1
                        elseif direction == "down" then
                            dY = 1
                        elseif direction == "left" then
                            dX = -1
                        else    
                            dX = 1
                        end
                        handlerTable["order"][xx][yy], handlerTable["order"][xx + dX][yy + dY] = handlerTable["order"][xx + dX][yy + dY], handlerTable["order"][xx][yy]
                        handlerTable["animation"] = nil
                    end
                end
            
                -- drawing
                local x1, y1, x2, y2 = getScreenCorners(player)
                local centerX = x1 + (x2 - x1) / 2
                local centerY = y1 + (y2 - y1) / 2
                local templateCenterX = centerX + 48
                local templateCenterY = centerY - 1
                local boardStartX = templateCenterX - surfaceDim / 2
                local boardStartY = templateCenterY - surfaceDim / 2
                
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
                
                -- puzzle shadow
                graphics.color(colorSub)
                graphics.rectangle(
                    boardStartX - 5,
                    boardStartY - 5,
                    boardStartX + surfaceDim + 5,
                    boardStartY + surfaceDim + 5
                )
                
                -- pieces
                for i = 1, tableTiles do
                    for j = 1, tableTiles do
                        local pieceX = boardStartX + (i - 1) * tileDim
                        local pieceY = boardStartY + (j - 1) * tileDim
                        local piece = piecesOrder[i][j]
                        if piece ~= 0 then
                            if handlerTable["animation"] ~= nil then
                                if handlerTable["animation"]["fromX"] == i and handlerTable["animation"]["fromY"] == j then
                                    local direction = handlerTable["animation"]["direction"]
                                    if direction == "up" then
                                        pieceY = pieceY - (tileDim * handlerTable["animation"]["frame"]) / slideDuration
                                    elseif direction == "down" then
                                        pieceY = pieceY + (tileDim * handlerTable["animation"]["frame"]) / slideDuration
                                    elseif direction == "left" then
                                        pieceX = pieceX - (tileDim * handlerTable["animation"]["frame"]) / slideDuration
                                    else
                                        pieceX = pieceX + (tileDim * handlerTable["animation"]["frame"]) / slideDuration
                                    end
                                end
                            end
                            graphics.drawImage{
                                image = piecesImage[piece],
                                x = pieceX,
                                y = pieceY
                            }
                        end
                    end
                end
                
            end
            
            -- control
            if not player:isValid() then
                giveUp(player) -- TODO: probably won't work
                handler:destroy()
            elseif player:get("dead") == 1 then
                giveUp(player)
                handler:destroy()
            elseif handlerTable["animation"] == nil then
                if frame > 1 and player:control("enter") == input.PRESSED then
                    -- exit
                    giveUp(player)
                    handler:destroy()
                elseif player:control("left") == input.PRESSED or player:control("right") == input.PRESSED
                  or player:control("up") == input.PRESSED or player:control("down") == input.PRESSED then
                    local pressedLeft = player:control("left") == input.PRESSED
                    local pressedRight = player:control("right") == input.PRESSED
                    local pressedUp = player:control("up") == input.PRESSED
                    local pressedDown = player:control("down") == input.PRESSED
                  
                    -- find empty tile
                    local emptyTileX = -1
                    local emptyTileY = -1
                    for i = 1, tableTiles do
                        for j = 1, tableTiles do
                            if piecesOrder[i][j] == 0 then
                                emptyTileX = i
                                emptyTileY = j
                                break
                            end
                        end
                        if emptyTileX ~= -1 and emptyTileY ~= -1 then
                            break
                        end
                    end
                    
                    local canGoUp = emptyTileY ~= tableTiles
                    local canGoDown = emptyTileY ~= 1
                    local canGoLeft = emptyTileX ~= tableTiles
                    local canGoRight = emptyTileX ~= 1
                    
                    if pressedLeft and canGoLeft or pressedRight and canGoRight
                      or pressedUp and canGoUp or pressedDown and canGoDown then
                        local fromX = emptyTileX
                        local fromY = emptyTileY
                        local direction = ""
                        
                        if pressedLeft then
                            fromX = fromX + 1
                            direction = "left"
                        elseif pressedRight then
                            fromX = fromX - 1
                            direction = "right"
                        elseif pressedUp then
                            fromY = fromY + 1
                            direction = "up"
                        elseif pressedDown then
                            fromY = fromY - 1
                            direction = "down"
                        end
                        
                        handlerTable["animation"] = {
                            fromX = fromX,
                            fromY = fromY,
                            frame = 0,
                            direction = direction
                        }
                    end
                end
            end
        end
    end
end

local function start(player)
    if not net.online or net.localPlayer == player then
        local handler = graphics.bindDepth(-99999, slidePuzzleUI)
        local handlerTable = handler:getData()
        handlerTable["isHard"] = hardMode
        handlerTable["player"] = player
        local orderList = {}
        local pieceNumber = 9 - 1
        local piecesDim = 3
        if hardMode then
            pieceNumber = 16 - 1
            piecesDim = 4
        end
        for i = 0, pieceNumber do
            table.insert(orderList, i)
        end
        repeat
            shuffle(orderList)
        until (not checkInversions(orderList))
        orderTable = {}
        for i = 1, piecesDim do
            orderTable[i] = {}
            for j = 1, piecesDim do
                orderTable[i][j] = orderList[(i - 1) * piecesDim + j]
            end
        end
        handlerTable["order"] = orderTable
        handlerTable["sprite"] = math.random(1,31)
    end
end

-- table.insert(puzzleList, {start = start, isPuzzle = true})
table.insert(puzzleList.puzzle, start)