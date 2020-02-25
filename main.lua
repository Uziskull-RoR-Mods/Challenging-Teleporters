-----------------
-- Challenging --
-- Teleporters --
-----------------
-- by Uziskull --
-----------------

-----------
-- Flags --
-----------
hardMode = modloader.checkFlag("teleporterPuzzle_hard_mode")
local disablePuzzles = modloader.checkFlag("teleporterPuzzle_disable_puzzles")
local disableChallenges = modloader.checkFlag("teleporterPuzzle_disable_challenges")

-----------
-- Stuff --
-----------
if not net.host or net.host and (not disablePuzzles or not disableChallenges) then -- disabling everything is basically not having the mod
    require("puzzleManager")
end
if not net.host or net.host and not disablePuzzles then
    require("puzzles.ballMaze")
    require("puzzles.latchSpin")
    require("puzzles.slidePuzzle")
end
if not net.host or net.host and not disableChallenges then
    require("challenges.movingTeleporter")
    require("challenges.shadowClones")
end