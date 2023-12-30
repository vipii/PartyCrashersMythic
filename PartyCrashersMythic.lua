local PartyCrashersMythicPlus = {}
local pc = PartyCrashersMythicPlus

SLASH_PARTYCRASHERS1 = "/pc"
SLASH_PARTYCRASHERS2 = "/partycrashers"
SlashCmdList["PARTYCRASHERS"] = function(msg)
    pc.handleCommand(msg)
end

function pc.handleCommand(args)
    local keyLevel, affix = pc.parseArguments(args)

    if not pc.isMythicSeasonActive() then
        print("PartyCrashers Mythic Plus Helper: Er is momenteel geen M+ season actief!")
        return
    end

    if keyLevel and (keyLevel < 2 or keyLevel > 50) then
        print("PartyCrashers Mythic Plus Helper: Je kan enkel keys tussen 2 en 50 ingeven")
        return
    end

    if keyLevel then
        pc.calculateRating(keyLevel, affix)
    else
        pc.printUsageInstructions()
    end
end

function pc.parseArguments(args)
    local keyLevel = tonumber(args:match("^%-?%d+"))
    local affix = args:match("[F|T]$")
    return keyLevel, affix
end

function pc.isMythicSeasonActive()
    local currentAffixes = C_MythicPlus.GetCurrentAffixes()
    return currentAffixes and currentAffixes[1]
end

function pc.printUsageInstructions()
    print("PartyCrashers Mythic Plus Helper kun je gebruiken door de volgende command te gebruiken:")
    print("/pc <key level>")
    print("Wil je een speciale week checken? Gebruik dan:")
    print("/pc <key level> <F|T>")
    print("Bij problemen? Contacteer Huskii!")
end

function pc.calculateRating(keyLevel, affix)
    local affixMap = { ["T"] = 1, ["F"] = 2 }
    local currentWeek = affix and affixMap[affix] or pc.getCurrentWeekAffixId()
    local rating = pc.getRatingForLevel(keyLevel)
    pc.displayRatingInfo(keyLevel, rating, currentWeek)
end

function pc.getCurrentWeekAffixId()
    return C_MythicPlus.GetCurrentAffixes()[1].id - 8
end

function pc.getRatingForLevel(keyLevel)
    if keyLevel < 10 then
        return pc.sub10Ratings[keyLevel]
    end
    return keyLevel * 5 + 50 + (keyLevel - 10) * 2
end

function pc.displayRatingInfo(keyLevel, rating, currentWeek)
    print("------------------------------------")
    print("Punten voor +"..keyLevel.." "..pc.affixTypes[currentWeek]..":")

    for _, mapId in ipairs(C_ChallengeMode.GetMapTable()) do
        local gain = pc.calculateMapScore(mapId, rating)
        if gain > 0 then
            local mapName = C_ChallengeMode.GetMapUIInfo(mapId)
            print(mapName..": "..gain)
        end
    end

    print("Totaal punten: "..pc.totalGain)
    print("------------------------------------\n")
end

pc.sub10Ratings = {
    [2] = 40, [3] = 45, [4] = 55, [5] = 60,
    [6] = 65, [7] = 75, [8] = 80, [9] = 85
}

pc.affixTypes = { "Tyrannical", "Fortified" }

function pc.calculateMapScore(mapId, newScore)
    local affixScores = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap(mapId)
    return pc.calculateScoreGain(affixScores, newScore)
end

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
