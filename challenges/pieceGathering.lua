-- Made by Uziskull
local brokeTp = Sprite.load("pieceGathering_broke", "challenges/pieceGathering/broke", 1, 25, 31)
local brokeTpEpic = Sprite.load("pieceGathering_broke_epic", "challenges/pieceGathering/broke_epic", 1, 46, 54)

local tpPiece = Item.new("Teleporter Piece")
tpPiece.displayName = "Teleporter Piece"
tpPiece.pickupText = "Return it to the teleporter!"
tpPiece.isUseItem = false
tpPiece.color = "p"
tpPiece.sprite = Sprite.load("tpPiece_item", "challenges/pieceGathering/item", 1, 0, 0)
tpPiece:getObject():addCallback("step", function(itemInst)
    itemInst:setAlarm(0, 1)
    local touchingPlayer = {}
    for _, player in ipairs(misc.players) do
        if player:collidesWith(itemInst, player.x, player.y) then
            touchingPlayer[#touchingPlayer + 1] = player
        end
    end
    if #touchingPlayer == 1 and touchingPlayer[1]:countItem(tpPiece) == 0 then
        itemInst:setAlarm(0, 0)
    end
end)

local playerIndexItemList = {}
tpPiece:addCallback("pickup", function(player)
    if net.online and net.host then
        for i, p in ipairs(misc.players) do
            if p == player then
                playerIndexItemList[i] = true
            end
        end
    end
end)
callback.register("onPlayerDisconnect", function(pIndex, pX, pY)
    if playerIndexItemList[pIndex] then
        playerIndexItemList[pIndex] = nil
        tpPiece:create(pX, pY - 32)
    end
end)

local function doBoom(inst)
    -- local particle = ParticleType.find("CutsceneSmoke")
    -- for i = 1, 30 do
        -- local xx = math.random(1, inst.sprite.width)
        -- local yy = math.random(1, inst.sprite.height)
        -- particle:burst("above", inst.x - inst.sprite.xorigin + xx, inst.y - inst.sprite.yorigin + yy, math.random(3, 5))
    -- end
    local quality = misc.getOption("video.quality")
    if quality > 1 then
        local particle = ParticleType.find("CutsceneSmoke")
        particle:speed(0.5, 1, 0, 0)
        for i = 1, 29 do
            if quality == 3 or i % 2 == 1 then
                local xx = inst.sprite.width * i / 29
                local yy = inst.sprite.height
                if i % 2 == 0 then
                    yy = yy * 2/3
                end
                local angle = math.deg(math.atan2(inst.sprite.height - yy, xx - inst.sprite.width/2))
                particle:angle(angle, angle, 0, 0, false)
                particle:direction(angle, angle, 0, 0)-- math.sin(math.rad(angle)) * 5, 0)
                particle:burst(
                    "above",
                    inst.x - inst.sprite.xorigin + xx,
                    inst.y - inst.sprite.yorigin + yy,
                    1
                )
            end
        end
    end
    Sound.find("ExplosiveShot"):play()
end

pieceSpawnPacket = net.Packet("Challenge TpPieces Spawning", function(sender, numberPieces)
    local teleporter = tpObj:find(1)
    doBoom(teleporter)
    local tpData = teleporter:getData()
    tpData.pieces = { total = numberPieces, restored = 0 }
    -- teleporter.subimage = teleporter:get("epic") == 1 and 2 or 7
    tpData.originalSprite = teleporter.sprite
    teleporter.sprite = teleporter:get("epic") == 1 and brokeTpEpic or brokeTp
    
    if net.host then
        playerIndexItemList = {}
        local partList = getCoordList(numberPieces)
        for i = 1, numberPieces do
            tpPiece:create(partList[(i - 1)*2 + 1], partList[(i - 1)*2 + 2] - 32)
        end
        pieceSpawnPacket:sendAsHost(net.ALL, nil, numberPieces)
    end
end)

piecePlacedPacket = net.Packet("Challenge TpPieces Add", function(sender)
    local teleporter = tpObj:find(1)
    local tpData = teleporter:getData()
    local tpPieces = tpData.pieces
    if tpPieces then
        tpPieces.restored = tpPieces.restored + 1
    end
    if tpPieces.restored >= tpPieces.total then
        teleporter:getData().pieces = nil
        -- teleporter.subimage = 1
        teleporter.sprite = tpData.originalSprite
        if net.host then
            -- teleporter:set("puzzleActive", 0):set("locked", 0)
            -- deactivatePuzzlePacket:sendAsHost(net.ALL, nil, 0)
            exitPuzzle(true, teleporter)
        end
    end
    
    if net.host then
        sender:removeItem(tpPiece, sender:countItem(tpPiece))
        piecePlacedPacket:sendAsHost(net.ALL)
    end
end)

callback.register("onDraw", function()
    local teleporter = tpObj:find(1)
    if teleporter ~= nil then
        local tpPieces = teleporter:getData().pieces
        if tpPieces then
            graphics.color(Color.WHITE)
            graphics.print("Pieces: " .. tpPieces.restored .. "/" .. tpPieces.total,
                teleporter.x, teleporter.y - teleporter.sprite.height - 8, nil, graphics.ALIGN_MIDDLE)
        end
    end
end)

callback.register("onPlayerStep", function(player)
    if not net.online or player == net.localPlayer then
        local teleporter = tpObj:find(1)
        if teleporter then
            local tpData = teleporter:getData()
            local tpPieces = tpData.pieces
            if tpPieces then
                local itemCount = player:countItem(tpPiece)
                if itemCount > 0 and player:collidesWith(teleporter, player.x, player.y) then
                    player:removeItem(tpPiece, itemCount)
                    Sound.find("GuardSpawn"):play()
                    if net.host then
                        if net.online then
                            for i, p in ipairs(misc.players) do
                                if p == player then
                                    playerIndexItemList[i] = nil
                                end
                            end
                        end
                        tpPieces.restored = tpPieces.restored + 1
                        if tpPieces.restored >= tpPieces.total then
                            tpData.pieces = nil
                            -- teleporter.subimage = 1
                            teleporter.sprite = tpData.originalSprite
                            -- teleporter:set("locked", 0)
                            -- teleporter:getData().puzzleActive =  false
                            -- if net.online then
                                -- deactivatePuzzlePacket:sendAsHost(net.ALL, nil, 0, teleporter:getNetInstance())
                            -- end
                            exitPuzzle(true, teleporter)
                        end
                    else
                        piecePlacedPacket:sendAsClient()
                    end
                end
            end
        end
    end
end)

callback.register("onPlayerDeath", function(player)
    local itemCount = player:countItem(tpPiece)
    if net.host and itemCount > 0 then
        player:removeItem(tpPiece, itemCount)
        tpPiece:create(player.x, player.y)
    end
end)

local function start(player)
    local numberPieces = hardMode and 6 or 4
    
    if net.host then
        playerIndexItemList = {}
        local teleporter = tpObj:find(1)
        doBoom(teleporter)
        local tpData = teleporter:getData()
        tpData.pieces = { total = numberPieces, restored = 0 }
        -- teleporter.subimage = teleporter:get("epic") == 1 and 2 or 7
        tpData.originalSprite = teleporter.sprite
        teleporter.sprite = teleporter:get("epic") == 1 and brokeTpEpic or brokeTp
        
        local partList = getCoordList(numberPieces)
        for i = 1, numberPieces do
            tpPiece:create(partList[(i - 1)*2 + 1], partList[(i - 1)*2 + 2] - 32)
        end
        
        pieceSpawnPacket:sendAsHost(net.ALL, nil, numberPieces)
    end
end

-- table.insert(puzzleList, {start = start, isPuzzle = false})
table.insert(puzzleList.challenge, start)