local pityshield = CV_RegisterVar({"br_pityshield", "Off", CV_NETVAR, CV_OnOff})
local suddendeath = CV_RegisterVar({"br_suddendeath", "On", CV_NETVAR, CV_OnOff})
local battleroyale = CV_RegisterVar({"battleroyale", "Off", CV_NETVAR, CV_OnOff})
local countdown = 30

G_AddGametype({
    name = "Battle Royale",
    identifier = "battleroyale",
    typeoflevel = TOL_MATCH,
    rules = GTR_RINGSLINGER|GTR_SPECTATORS|GTR_DEATHMATCHSTARTS|GTR_HURTMESSAGES|GTR_STARTCOUNTDOWN|GTR_FIRSTPERSON,
    intermissiontype = int_match,
    description = "Battle Royale, last man standing wins",
})

local check_source = function(source, target)
    return source != nil and source.type == MT_PLAYER and source != target
end

local alive_players = function()
    local count = 0
    for player in players.iterate
        if player.valid and not player.spectator then
            count = count + 1 
        end
    end
    return count
end

local num_seconds = function()
    return leveltime / TICRATE
end

local endgame = function()
    return alive_players() <= 1 and num_seconds() > countdown
end

local is_battleroyale = do
    return battleroyale.value or gametype == GT_BATTLEROYALE
end

addHook("ThinkFrame", do
    if is_battleroyale() then
        if endgame() then
            G_ExitLevel()
        end
    end
end)

addHook("PlayerSpawn", function(player)
    if is_battleroyale() and not player.spectator then
        local timeleft = countdown - num_seconds()
        if timeleft > 0 then
            chatprintf(player, string.format("You have %d seconds left to gear up", timeleft))
        end
        if pityshield.value then
            player.powers[pw_shield] = SH_PITY
        end
        player.powers[pw_invulnerability] = timeleft * TICRATE
    end
end)

addHook("MobjDeath", function(target, inflictor, source, damage, damagetype)
    if (is_battleroyale() and target.player) then
        target.player.spectator = true
    end
end, MT_PLAYER)

addHook("ShouldDamage", function(target, inflictor, source, damage, damagetype)
    if (is_battleroyale() and check_source(source, target) and num_seconds() <= countdown) then
        return false
    else
        return nil
    end
end, MT_PLAYER)

addHook("MobjDamage", function(target, inflictor, source, damage, damagetype)
    if (is_battleroyale()
        and suddendeath.value
        and check_source(source, target)
        and target.player.powers[pw_shield] == SH_NONE) then
        target.health = 0
    end
end, MT_PLAYER)

addHook("TeamSwitch", function(player, team, fromspectators, autobalance, scramble)
    if (is_battleroyale() and num_seconds() > countdown and fromspectators) then
        return false
    else
        return nil
    end
end)
