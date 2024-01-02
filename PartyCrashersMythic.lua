-- PartyCrashersMythicPlus: A helper module for managing Mythic Plus keys in World of Warcraft
local PartyCrashersMythicPlus = {}
local pc = PartyCrashersMythicPlus

-- Slash commands for easy access
SLASH_PARTYCRASHERS1 = "/pc"

-- Command list and handler
SlashCmdList["PARTYCRASHERS"] = function(msg)
    pc.handleCommand(msg)
end

-- Handles the input command
function pc.handleCommand(args)
    local keyLevel, affix = pc.parseArguments(args)

    -- Check if Mythic Season is active
    if not pc.isMythicSeasonActive() then
        print("PartyCrashers Mythic+ Calculator: There is currently no M+ season active!")
        return
    end

    -- Validate key level range
    if keyLevel and (keyLevel < 2 or keyLevel > 30) then
        print("PartyCrashers Mythic+ Calculator: You can only enter keys between 2 and 30.")
        print("Please try again")
        return
    end

    -- Process key level or print usage instructions
    if keyLevel then
        pc.calculateRating(keyLevel, affix)
    else
        pc.printUsageInstructions()
    end
end

-- Parses arguments from the input command
function pc.parseArguments(args)
    local keyLevel = tonumber(args:match("^%-?%d+"))
    local affix = args:match("[F|T]$")
    return keyLevel, affix
end

-- Checks if the Mythic Season is active
function pc.isMythicSeasonActive()
    local currentAffixes = C_MythicPlus.GetCurrentAffixes()
    return currentAffixes and currentAffixes[1]
end

-- Prints usage instructions for the addon
function pc.printUsageInstructions()
    print("PartyCrashers Mythic+ Calculator can be used by using the following command:")
    print("/pc <key level>")
    print("Want to check a special week? Then use:")
    print("/pc <key level> <F|T>")
end

-- Updated base score table for key levels
pc.baseScores = {
    [2] = 40, [3] = 45, [4] = 55, [5] = 60, [6] = 65, [7] = 75, [8] = 80, [9] = 85, [10] = 100,
    [11] = 107, [12] = 114, [13] = 121, [14] = 128, [15] = 135, [16] = 142, [17] = 149,
    [18] = 156, [19] = 163, [20] = 170, [21] = 177, [22] = 184, [23] = 191, [24] = 198,
    [25] = 205, [26] = 212, [27] = 219, [28] = 226, [29] = 233, [30] = 240
}

-- Updated function to get the rating for a given key level
function pc.getRatingForLevel(keyLevel)
    return pc.baseScores[keyLevel] or 0
end

-- Updated function to calculate the rating based on key level and affix
function pc.calculateRating(keyLevel, affix)
    local affixMap = { ["T"] = 1, ["F"] = 2 }
    local currentWeek = affix and affixMap[affix] or pc.getCurrentWeekAffixId()
    local rating = pc.getRatingForLevel(keyLevel)
    pc.displayRatingInfo(keyLevel, rating, currentWeek)
end

-- Retrieves the current week's affix ID
function pc.getCurrentWeekAffixId()
    return C_MythicPlus.GetCurrentAffixes()[1].id - 8
end

-- Displays the rating information
function pc.displayRatingInfo(keyLevel, rating, currentWeek)
    print("---- PartyCrashers Mythic Plus Helper ----")
    print("Points for +"..keyLevel.." "..pc.affixTypes[currentWeek]..":")

    pc.totalGain = 0
    for _, mapId in ipairs(C_ChallengeMode.GetMapTable()) do
        local gain = pc.calculateMapScore(mapId, rating)
        if gain > 1 then
            local mapName = C_ChallengeMode.GetMapUIInfo(mapId)
            print(mapName..": "..gain)
        end
    end

    print("Total points: "..pc.totalGain)
    print("---- PartyCrashers Mythic Plus Helper ----\n")
end

-- Types of affixes
pc.affixTypes = { "Tyrannical", "Fortified" }

-- Calculates the score for a map
function pc.calculateMapScore(mapId, newScore)
    local affixScores = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap(mapId)
    return pc.calculateScoreGain(affixScores, newScore)
end

-- Calculates the score gain for a new score
function pc.calculateScoreGain(affixScores, newScore)
    local scores = {0, 0}

    if affixScores then
        for i = 1, 2 do
            scores[i] = affixScores[i] and affixScores[i].score or 0
        end
    end

    local currentBest = math.max(scores[1], scores[2]) * 1.5 + math.min(scores[1], scores[2]) * 0.5
    local updatedBest = math.max(scores[1], scores[2], newScore) * 1.5 + math.min(scores[1], scores[2], newScore) * 0.5

    local gain = updatedBest - currentBest
    if gain > 0 then
        pc.totalGain = pc.totalGain + gain
    end

    return gain
end

pc.totalGain = 0
