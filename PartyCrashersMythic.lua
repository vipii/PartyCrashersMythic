local PartyCrashersMythicPlus = {}
local pc = PartyCrashersMythicPlus

-- Command aliases
SLASH_PARTYCRASHERS1 = "/pc"
SLASH_PARTYCRASHERS2 = "/partycrashers"
SlashCmdList["PARTYCRASHERS"] = function(msg)
    pc.handleCommand(msg)
end

-- Handle command input
function pc.handleCommand(args)
    local keyLevel, affix = pc.parseArguments(args)

    if not pc.isMythicSeasonActive() then
        print("PartyCrashers Mythic Plus Helper: No M+ season is currently active!")
        return
    end

    if keyLevel and (keyLevel < 2 or keyLevel > 50) then
        print("PartyCrashers Mythic Plus Helper: Key level must be between 2 and 50")
        return
    end

    if keyLevel then
        pc.calculateRating(keyLevel, affix)
    else
        pc.printUsageInstructions()
    end
end

-- Parse arguments from the command
function pc.parseArguments(args)
    local keyLevel = tonumber(args:match("^%-?%d+"))
    local affix = args:match("[F|T]$")
    return keyLevel, affix
end

-- Check if Mythic+ season is active
function pc.isMythicSeasonActive()
    local currentAffixes = C_MythicPlus.GetCurrentAffixes()
    return currentAffixes and currentAffixes[1]
end

-- Print usage instructions
function pc.printUsageInstructions()
    print("Usage: /pc <key level>")
    print("To check a specific week: /pc <key level> <F|T>")
end

-- Calculate rating based on key level and affix
function pc.calculateRating(keyLevel, affix)
    local affixMap = { ["T"] = 1, ["F"] = 2 }
    local currentWeek = affix and affixMap[affix] or pc.getCurrentWeekAffixId()
    local rating = pc.getRatingForLevel(keyLevel)
    pc.displayRatingInfo(keyLevel, rating, currentWeek)
end

-- Get the current week's affix ID
function pc.getCurrentWeekAffixId()
    return C_MythicPlus.GetCurrentAffixes()[1].id - 8
end

-- Return rating based on key level
function pc.getRatingForLevel(keyLevel)
    if keyLevel < 10 then
        return pc.sub10Ratings[keyLevel]
    end
    return keyLevel * 5 + 50 + (keyLevel - 10) * 2
end

-- Display rating information
function pc.displayRatingInfo(keyLevel, rating, currentWeek)
    print("---- PartyCrashers Mythic Plus Helper ----")
    print("Points for +"..keyLevel.." "..pc.affixTypes[currentWeek]..":")

    -- Calculate and display points for each map
    for _, mapId in ipairs(C_ChallengeMode.GetMapTable()) do
        local gain = pc.calculateMapScore(mapId, rating)
        if gain > 0 then
            local mapName = C_ChallengeMode.GetMapUIInfo(mapId)
            print(mapName..": "..gain)
        end
    end

    print("Total points: "..pc.totalGain)
    print("---- PartyCrashers Mythic Plus Helper ----\n")
end

-- Rating for levels below 10
pc.sub10Ratings = {
    [2] = 40, [3] = 45, [4] = 55, [5] = 60,
    [6] = 65, [7] = 75, [8] = 80, [9] = 85
}

-- Affix types
pc.affixTypes = { "Tyrannical", "Fortified" }

-- Calculate score for a map
function pc.calculateMapScore(mapId, newScore)
    local affixScores = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap(mapId)
    return pc.calculateScoreGain(affixScores, newScore)
end

-- Calculate the score gain
function pc.calculateScoreGain(affixScores, newScore)
    local scores = {0, 0}

    if affixScores then
        for i
