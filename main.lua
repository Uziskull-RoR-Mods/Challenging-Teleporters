-----------------
-- Challenging --
-- Teleporters --
-----------------
-- by Uziskull --
-----------------

-----------
-- Flags --
-----------
hardMode = modloader.checkFlag("tp_hard_mode")
flags = {
    disablePuzzles = modloader.checkFlag("tp_disable_puzzles"),
    disableChallenges = modloader.checkFlag("tp_disable_challenges"),
    disablePanels = modloader.checkFlag("tp_disable_panels"),
}

---------------
-- Functions --
---------------
function shuffle(l)
    for m = #l, 2, -1 do
        local n = math.random(m)
        l[m], l[n] = l[n], l[m]
    end
end

function getScreenCorners(player)
    -- TODO: we have a camera class now dumbass, get rid of this
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

function getCoordList(amount)
    local coordList = {}
    local spawns = Object.find("B"):findAll()
    local selectedNums = {}
    for i = 1, amount do
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
        table.insert(coordList, block.x + block.sprite.width / 2)
        table.insert(coordList, block.y - 1)
    end
    return coordList
end

-----------
-- Stuff --
-----------

require("onPlayerDisconnect")

-- manager
require("puzzleManager")

-- puzzles
require("puzzles.ballMaze")
require("puzzles.latchSpin")
-- require("puzzles.slidePuzzle")    --[[Yeah idk what I was thinking, uncomment this one at your own risk]]--
require("puzzles.lockPick")

-- challenges
require("challenges.movingTeleporter")
require("challenges.shadowClones")
require("challenges.pieceGathering")
require("challenges.teleporterGuardian")

-- panels
-- CONSOLE_FONT = graphics.fontFromFile("panels/console_font", 6)
require("panels.codeRoulette")
require("panels.codeHacking")

-----------
-- DEBUG --
-----------

-- registercallback("onPlayerDisconnect", function(playerIndex)
    -- log("player "..playerIndex.." disconnected; i am "..(net.host and "" or "not ").."the host")
-- end)

-- registercallback("onDraw", function()
    -- local tp = Object.find("Teleporter"):find(1)
    -- if tp then
        -- graphics.color(Color.WHITE)
        -- graphics.print("locked: " .. (tp:get("locked") ~= nil and tp:get("locked") or 0), tp.x, tp.y - tp.sprite.height - 32, nil, graphics.ALIGN_MIDDLE)
        -- graphics.print("puzzleActive: " .. (tp:get("puzzleActive") ~= nil and tp:get("puzzleActive") or 0), tp.x, tp.y - tp.sprite.height - 8, nil, graphics.ALIGN_MIDDLE)
    -- end
-- end)

-- registercallback("onPlayerStep", function(player)
    -- --if player:get("true_invincible") ~= 1 then
    -- if not player:get("aaaaaa") then
        -- local currentTp = Object.find("Teleporter"):find(1)
        -- player.x = currentTp.x
        -- player.y = currentTp.y - 16
        -- player:set("pHmax", 10)--:set("true_invincible", 1)
        -- player:set("aaaaaa", 1)
        -- -- Stage.transport(Stage.find("Risk of Rain"))
    -- end
-- end)