local words = {easy = {}, hard = {}}
local drawAscii = {yes = {}, no = {}}
local fillerChars = {".", ".", "#", "#", "*", "*", "$", "$", "%", "%", "(", ")", "[", "]", "<", ">"}

local WORD_COUNT = 10
local COLUMN_NUM, ROW_NUM, COLUMN_CHAR_WIDTH = 2, 15, 8
local ANIM_DURATION = 2 * 60
local MAX_ATTEMPTS = 5

local function compareWords(w1, w2)
    local count = 0
    for i = 1, w1:len() do
        if w1:sub(i, i) == w2:sub(i, i) then
            count = count + 1
        end
    end
    return count
end

local textColor = Color.fromHex(0x6BDC85)
local shadowColor = Color.fromHex(0x30643C)
local bgColor = Color.fromHex(0x1B3223)
local function drawConsoleText(text, x, y, invert)
    graphics.color(shadowColor)
    graphics.print(text, x + 1, y + 1)--, CONSOLE_FONT)
    graphics.color(invert and bgColor or textColor)
    graphics.print(text, x, y)--, CONSOLE_FONT)
end

function codeHackingUI(handler, frame)
    
    local handlerTable = handler:getData()
    local player, words, tape, address, attempts =
        handlerTable.player, handlerTable.words, handlerTable.tape, handlerTable.address, handlerTable.attempts
    local animation, maxAttempts = handlerTable.animation, handlerTable.maxAttempts
    
    -- end condition
    if animation then
        if animation < ANIM_DURATION then
            handlerTable.animation = handlerTable.animation + 1
        else
            if #attempts == maxAttempts and attempts[1].correct ~= words[handlerTable.correct].word:len() then
                giveUp(player)
                handler:destroy()
                return
            else
                if player:hasBuff(puzzleBuff) then
                    player:removeBuff(puzzleBuff)
                end
                exitPuzzle(true, getInteractable():findNearest(player.x, player.y))
                handler:destroy()
                return
            end
        end
    end
    
    if player:isValid() then
        -- drawing
        local x1, y1, x2, y2 = getScreenCorners(player)
        local centerX = x1 + (x2 - x1) / 2
        local centerY = y1 + (y2 - y1) / 2
        local screenImage = puzzleTemplates[Stage.getCurrentStage().displayName]
        local screenCornerX, screenCornerY = centerX - screenImage.width / 2 + 48, centerY - screenImage.height / 2 + 45
        local screenW, screenH = 308, 211
        local sliceX = (6 + 1 + COLUMN_CHAR_WIDTH) * COLUMN_NUM -- width of address + space + codetape
            + 2 -- space between columns
            + 3 -- space between last col and text
            + 9 -- text
            + 2 + 0 -- space between borders and printed stuff on both sides
        local sliceY = ROW_NUM + 8 -- column space plus extra padding
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

        -- draw columns
        --[[
            x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x
            -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
            x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x
            -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
            x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x
            -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
            x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x
            -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
            x|x| | | | | | |x| | | | | | | | |x|x| | | | | | |x| | | | | | | | |x|x|x| | | | | | | | | 
            -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
            x|x| | | | | | |x| | | | | | | | |x|x| | | | | | |x| | | | | | | | |x|x|x| | | | | | | | | 
            -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
            x|x| | | | | | |x| | | | | | | | |x|x| | | | | | |x| | | | | | | | |x|x|x| | | | | | | | | 
            -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
            x|x| | | | | | |x| | | | | | | | |x|x| | | | | | |x| | | | | | | | |x|x|x| | | | | | | | | 
            -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
            x|x| | | | | | |x| | | | | | | | |x|x| | | | | | |x| | | | | | | | |x|x|x| | | | | | | | | 
            -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
            x|x| | | | | | |x| | | | | | | | |x|x| | | | | | |x| | | | | | | | |x|x|x| | | | | | | | | 
            -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
            x|x| | | | | | |x| | | | | | | | |x|x| | | | | | |x| | | | | | | | |x|x|x| | | | | | | | | 
            -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
            x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x
            -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
            x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x
            -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
            x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x
            -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
            x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x
        ]]--
        for x = 2 + 1, sliceX do
            for y = 4 + 1, sliceY - 4 do
                local yy = y - 4
                if x == 3 or x == 20 then
                    drawConsoleText(string.format("0x%x", handlerTable.address + (yy - 1 + (x == 3 and 0 or ROW_NUM)) * COLUMN_CHAR_WIDTH),
                      screenCornerX + (x - 1) * sliceW, screenCornerY + (y - 1) * sliceH)
                elseif x >= 10 and x <= 10 + (COLUMN_CHAR_WIDTH - 1)
                  or x >= 27 and x <= 27 + (COLUMN_CHAR_WIDTH - 1) then
                    local charIndex = (x - (10 - 1)) + COLUMN_CHAR_WIDTH * (y - 4 - 1)
                    if x > 10 + (COLUMN_CHAR_WIDTH - 1) then
                        charIndex = (x - (27 - 1)) + COLUMN_CHAR_WIDTH * (y - 4 - 1) + ROW_NUM * COLUMN_CHAR_WIDTH
                    end
                    local invertColors = false
                    if charIndex >= words[handlerTable.cursor].pos
                      and charIndex <= words[handlerTable.cursor].pos + words[handlerTable.cursor].word:len() - 1 then
                        invertColors = true
                        graphics.color(textColor)
                        -- graphics.alpha(0.2)
                        graphics.rectangle(
                            screenCornerX + (x - 1) * sliceW - sliceW/2,
                            screenCornerY + (y - 1) * sliceH,
                            screenCornerX + (x - 1) * sliceW + sliceW - 1,
                            screenCornerY + (y - 1) * sliceH + sliceH
                        )
                        -- graphics.alpha(1)
                    end
                    drawConsoleText(tape[charIndex], screenCornerX + (x - 1) * sliceW, screenCornerY + (y - 1) * sliceH, invertColors)
                elseif x == 38 then
                    if yy == 1 then
                        drawConsoleText("Attempts", screenCornerX + (x - 1) * sliceW,
                            screenCornerY + (y - 1) * sliceH)
                        drawConsoleText("left: " .. (maxAttempts - #attempts), screenCornerX + (x - 1) * sliceW,
                            screenCornerY + (y - 1 + 1) * sliceH)
                    elseif animation and yy >= 4 and yy <= 4 + 8 - 1 then
                        for i = 1, 2 do
                            local drawTable = attempts[1].correct == words[handlerTable.correct].word:len() and drawAscii.yes or drawAscii.no
                            drawConsoleText(drawTable[yy - (4 - 1)], screenCornerX + (x - 1) * sliceW, screenCornerY + (y - 1) * sliceH)
                        end
                    elseif yy == ROW_NUM then
                        drawConsoleText(">", screenCornerX + (x - 1) * sliceW, screenCornerY + (y - 1) * sliceH)
                    elseif yy >= ROW_NUM - maxAttempts * 2 then
                        local attemptIndex = (7 + 1) - math.ceil(yy / 2)
                        if attempts[attemptIndex] then
                            if yy % 2 == 1 then
                                drawConsoleText(">"..words[attempts[attemptIndex].index].word, screenCornerX + (x - 1) * sliceW, screenCornerY + (y - 1) * sliceH)
                            else
                                local correctLetters = attempts[attemptIndex].correct
                                local maxLetters = words[attempts[attemptIndex].index].word:len()
                                drawConsoleText(correctLetters == maxLetters and "Correct!"
                                  or correctLetters .. "/" .. maxLetters .. " hits", screenCornerX + (x - 1) * sliceW, screenCornerY + (y - 1) * sliceH)
                            end
                        end
                    end
                end
            end
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
        elseif player:control("up") == input.PRESSED or player:control("down") == input.PRESSED then
            local pressedUp = player:control("up") == input.PRESSED
            local pressedDown = player:control("down") == input.PRESSED
            if not (pressedUp == pressedDown) then
                handlerTable.cursor = ((handlerTable.cursor + (pressedDown and 0 or -2)) % WORD_COUNT) + 1
            end
        elseif player:control("ability1") == input.PRESSED or input.checkKeyboard("space") == input.PRESSED then
            local letterCount = compareWords(words[handlerTable.cursor].word, words[handlerTable.correct].word)
            -- attempts[#attempts + 1] = {
            table.insert(attempts, 1, {
                index = handlerTable.cursor,
                correct = letterCount
            })
            if letterCount == words[handlerTable.correct].word:len() or #attempts == maxAttempts then
                handlerTable.animation = 0
            end
        end
    end
end

local function start(player)
    if not net.online or net.localPlayer == player then
        local handler = graphics.bindDepth(-99999, codeHackingUI)
        local handlerTable = handler:getData()
        handlerTable.player = player
        
        -- how 2 maek word (simple tutorial)
        -- TODO: please make this more efficient, its really not that hard you idiot
        handlerTable.words = {}
        -- stp1: do the shuffle and get words (inefficient as fuck but idc lmfao)
        local wordDiff = hardMode and "hard" or "easy"
        local wordLen = words[wordDiff][1]:len()
        shuffle(words[wordDiff])
        for i = 1, WORD_COUNT do
            handlerTable.words[#handlerTable.words + 1] = {word = words[wordDiff][i], pos = 0}
        end
        -- stp2: generate the entire string of clusterfuck using total character count minus words
        --       AND also subtract one extra char per word (it's a surprise tool that'll help us later ;) )
        local wordTape = {}
        for i = 1, COLUMN_CHAR_WIDTH * ROW_NUM * COLUMN_NUM - WORD_COUNT * (wordLen + 1) do
            wordTape[#wordTape + 1] = table.irandom(fillerChars)
        end
        -- stp3: append tokens representing words, then shuffle dat boi
        for i = 1, #handlerTable.words do
            wordTape[#wordTape + 1] = "w"
        end
        shuffle(wordTape)
        -- stp4: build the proper tape, and take note of word positions
        handlerTable.tape = {}
        local iWord = 1
        for i, s in ipairs(wordTape) do
            if s == "w" then
                handlerTable.words[iWord].pos = i + wordLen*(iWord - 1)
                for j = 1, wordLen do
                    handlerTable.tape[#handlerTable.tape + 1] = handlerTable.words[iWord].word:sub(j, j)
                end
                -- surprise tool activate: insert filter character afterwards, to prevent probability of joint words
                handlerTable.tape[#handlerTable.tape + 1] = table.irandom(fillerChars)
                iWord = iWord + 1
            else
                handlerTable.tape[#handlerTable.tape + 1] = s
            end
        end
        
        -- extra step: generate cool kid memory addresses B)
        handlerTable.address = math.random(16^3, 16^4 - 1 - COLUMN_CHAR_WIDTH * ROW_NUM * COLUMN_NUM)
        
        handlerTable.cursor = 1
        handlerTable.attempts = {}
        handlerTable.maxAttempts = hardMode and (MAX_ATTEMPTS - 2) or (MAX_ATTEMPTS)
        handlerTable.correct = math.random(#handlerTable.words)
    end
end

-- table.insert(puzzleList, {start = start, isPuzzle = true})
table.insert(puzzleList.panel, start)

-- put stuff down here, to prevent spam for code viewers
words = {
    easy = {"able", "acid", "aged", "also", "area", "army", "away", "baby", "back", "ball", "band", "bank", "base", "bath", "bear", "beat", "been", "beer", "bell", "belt", "best", "bill", "bird", "blow", "blue", "boat", "body", "bomb", "bond", "bone", "book", "boom", "born", "boss", "both", "bowl", "bulk", "burn", "bush", "busy", "call", "calm", "came", "camp", "card", "care", "case", "cash", "cast", "cell", "chat", "chip", "city", "club", "coal", "coat", "code", "cold", "come", "cook", "cool", "cope", "copy", "core", "cost", "crew", "crop", "dark", "data", "date", "dawn", "days", "dead", "deal", "dean", "dear", "debt", "deep", "deny", "desk", "dial", "dick", "diet", "disc", "disk", "does", "done", "door", "dose", "down", "draw", "drew", "drop", "drug", "dual", "duke", "dust", "duty", "each", "earn", "ease", "east", "easy", "edge", "else", "even", "ever", "evil", "exit", "face", "fact", "fail", "fair", "fall", "farm", "fast", "fate", "fear", "feed", "feel", "feet", "fell", "felt", "file", "fill", "film", "find", "fine", "fire", "firm", "fish", "five", "flat", "flow", "food", "foot", "ford", "form", "fort", "four", "free", "from", "fuel", "full", "fund", "gain", "game", "gate", "gave", "gear", "gene", "gift", "girl", "give", "glad", "goal", "goes", "gold", "golf", "gone", "good", "gray", "grew", "grey", "grow", "gulf", "hair", "half", "hall", "hand", "hang", "hard", "harm", "hate", "have", "head", "hear", "heat", "held", "hell", "help", "here", "hero", "high", "hill", "hire", "hold", "hole", "holy", "home", "hope", "host", "hour", "huge", "hung", "hunt", "hurt", "idea", "inch", "into", "iron", "item", "jack", "jane", "jean", "john", "join", "jump", "jury", "just", "keen", "keep", "kent", "kept", "kick", "kill", "kind", "king", "knee", "knew", "know", "lack", "lady", "laid", "lake", "land", "lane", "last", "late", "lead", "left", "less", "life", "lift", "like", "line", "link", "list", "live", "load", "loan", "lock", "logo", "long", "look", "lord", "lose", "loss", "lost", "love", "luck", "made", "mail", "main", "make", "male", "many", "mark", "mass", "matt", "meal", "mean", "meat", "meet", "menu", "mere", "mike", "mile", "milk", "mill", "mind", "mine", "miss", "mode", "mood", "moon", "more", "most", "move", "much", "must", "name", "navy", "near", "neck", "need", "news", "next", "nice", "nick", "nine", "none", "nose", "note", "okay", "once", "only", "onto", "open", "oral", "over", "pace", "pack", "page", "paid", "pain", "pair", "palm", "park", "part", "pass", "past", "path", "peak", "pick", "pink", "pipe", "plan", "play", "plot", "plug", "plus", "poll", "pool", "poor", "port", "post", "pull", "pure", "push", "race", "rail", "rain", "rank", "rare", "rate", "read", "real", "rear", "rely", "rent", "rest", "rice", "rich", "ride", "ring", "rise", "risk", "road", "rock", "role", "roll", "roof", "room", "root", "rose", "rule", "rush", "ruth", "safe", "said", "sake", "sale", "salt", "same", "sand", "save", "seat", "seed", "seek", "seem", "seen", "self", "sell", "send", "sent", "sept", "ship", "shop", "shot", "show", "shut", "sick", "side", "sign", "site", "size", "skin", "slip", "slow", "snow", "soft", "soil", "sold", "sole", "some", "song", "soon", "sort", "soul", "spot", "star", "stay", "step", "stop", "such", "suit", "sure", "take", "tale", "talk", "tall", "tank", "tape", "task", "team", "tech", "tell", "tend", "term", "test", "text", "than", "that", "them", "then", "they", "thin", "this", "thus", "till", "time", "tiny", "told", "toll", "tone", "tony", "took", "tool", "tour", "town", "tree", "trip", "true", "tune", "turn", "twin", "type", "unit", "upon", "used", "user", "vary", "vast", "very", "vice", "view", "vote", "wage", "wait", "wake", "walk", "wall", "want", "ward", "warm", "wash", "wave", "ways", "weak", "wear", "week", "well", "went", "were", "west", "what", "when", "whom", "wide", "wife", "wild", "will", "wind", "wine", "wing", "wire", "wise", "wish", "with", "wood", "word", "wore", "work", "yard", "yeah", "year", "your", "zero", "zone", },
    hard = {"ability", "absence", "academy", "account", "accused", "achieve", "acquire", "address", "advance", "adverse", "advised", "adviser", "against", "airline", "airport", "alcohol", "alleged", "already", "analyst", "ancient", "another", "anxiety", "anxious", "anybody", "applied", "arrange", "arrival", "article", "assault", "assumed", "assured", "attempt", "attract", "auction", "average", "backing", "balance", "banking", "barrier", "battery", "bearing", "beating", "because", "bedroom", "believe", "beneath", "benefit", "besides", "between", "billion", "binding", "brother", "brought", "burning", "cabinet", "caliber", "calling", "capable", "capital", "captain", "caption", "capture", "careful", "carrier", "caution", "ceiling", "central", "centric", "century", "certain", "chamber", "channel", "chapter", "charity", "charlie", "charter", "checked", "chicken", "chronic", "circuit", "classes", "classic", "climate", "closing", "closure", "clothes", "collect", "college", "combine", "comfort", "command", "comment", "compact", "company", "compare", "compete", "complex", "concept", "concern", "concert", "conduct", "confirm", "connect", "consent", "consist", "contact", "contain", "content", "contest", "context", "control", "convert", "correct", "council", "counsel", "counter", "country", "crucial", "crystal", "culture", "current", "cutting", "dealing", "decided", "decline", "default", "defence", "deficit", "deliver", "density", "deposit", "desktop", "despite", "destroy", "develop", "devoted", "diamond", "digital", "discuss", "disease", "display", "dispute", "distant", "diverse", "divided", "drawing", "driving", "dynamic", "eastern", "economy", "edition", "elderly", "element", "engaged", "enhance", "essence", "evening", "evident", "exactly", "examine", "example", "excited", "exclude", "exhibit", "expense", "explain", "explore", "express", "extreme", "factory", "faculty", "failing", "failure", "fashion", "feature", "federal", "feeling", "fiction", "fifteen", "filling", "finance", "finding", "fishing", "fitness", "foreign", "forever", "formula", "fortune", "forward", "founder", "freedom", "further", "gallery", "gateway", "general", "genetic", "genuine", "gigabit", "greater", "hanging", "heading", "healthy", "hearing", "heavily", "helpful", "helping", "herself", "highway", "himself", "history", "holding", "holiday", "housing", "however", "hundred", "husband", "illegal", "illness", "imagine", "imaging", "improve", "include", "initial", "inquiry", "insight", "install", "instant", "instead", "intense", "interim", "involve", "jointly", "journal", "journey", "justice", "justify", "keeping", "killing", "kingdom", "kitchen", "knowing", "landing", "largely", "lasting", "leading", "learned", "leisure", "liberal", "liberty", "library", "license", "limited", "listing", "logical", "loyalty", "machine", "manager", "married", "massive", "maximum", "meaning", "measure", "medical", "meeting", "mention", "message", "million", "mineral", "minimal", "minimum", "missing", "mission", "mistake", "mixture", "monitor", "monthly", "morning", "musical", "mystery", "natural", "neither", "nervous", "network", "neutral", "notable", "nothing", "nowhere", "nuclear", "nursing", "obvious", "offense", "officer", "ongoing", "opening", "operate", "opinion", "optical", "organic", "outcome", "outdoor", "outlook", "outside", "overall", "pacific", "package", "painted", "parking", "partial", "partner", "passage", "passing", "passion", "passive", "patient", "pattern", "payable", "payment", "penalty", "pending", "pension", "percent", "perfect", "perform", "perhaps", "phoenix", "picking", "picture", "pioneer", "plastic", "pointed", "popular", "portion", "poverty", "precise", "predict", "premier", "premium", "prepare", "present", "prevent", "primary", "printer", "privacy", "private", "problem", "proceed", "process", "produce", "product", "profile", "program", "project", "promise", "promote", "protect", "protein", "protest", "provide", "publish", "purpose", "pushing", "qualify", "quality", "quarter", "radical", "railway", "readily", "reading", "reality", "realize", "receipt", "receive", "recover", "reflect", "regular", "related", "release", "remains", "removal", "removed", "replace", "request", "require", "reserve", "resolve", "respect", "respond", "restore", "retired", "revenue", "reverse", "rollout", "routine", "running", "satisfy", "science", "section", "segment", "serious", "service", "serving", "session", "setting", "seventh", "several", "shortly", "showing", "silence", "silicon", "similar", "sitting", "sixteen", "skilled", "smoking", "society", "somehow", "someone", "speaker", "special", "species", "sponsor", "station", "storage", "strange", "stretch", "student", "studied", "subject", "succeed", "success", "suggest", "summary", "support", "suppose", "supreme", "surface", "surgery", "surplus", "survive", "suspect", "sustain", "teacher", "telecom", "telling", "tension", "theatre", "therapy", "thereby", "thought", "through", "tonight", "totally", "touched", "towards", "traffic", "trouble", "turning", "typical", "uniform", "unknown", "unusual", "upgrade", "upscale", "utility", "variety", "various", "vehicle", "venture", "version", "veteran", "victory", "viewing", "village", "violent", "virtual", "visible", "waiting", "walking", "wanting", "warning", "warrant", "wearing", "weather", "webcast", "website", "wedding", "weekend", "welcome", "welfare", "western", "whereas", "whereby", "whether", "willing", "winning", "without", "witness", "working", "writing", "written", }
}
drawAscii = {
    yes = {
        "      ++",
        "      ++",
        "     ++ ",
        "++   ++ ",
        "++  ++  ",
        " ++ ++  ",
        " ++++   ",
        "  ++    ",
    },
    no = {
        "##    ##",
        "###  ###",
        " ###### ",
        "  ####  ",
        "  ####  ",
        " ###### ",
        "###  ###",
        "##    ##",
    }
}