local Damage = {}
local DamageHits = {}

local PrintDamageInfo = function(playerid)
    local player = GetPlayer(playerid)
    if not player or not player:IsValid() then return end

    local team = player:CBaseEntity().TeamNum

    if team ~= Team.CT and team ~= Team.T then
        return
    end

    local otherTeam = Team.CT

    if player:CBaseEntity().TeamNum == Team.CT then
        otherTeam = Team.T
    end

    for i = 0, playermanager:GetPlayerCap() - 1, 1 do
        local victim = GetPlayer(i)
        if not victim or not victim:IsValid() or victim:CBaseEntity().TeamNum ~= otherTeam then goto continue end
        local victimHealth =victim:CBaseEntity().Health
        if victimHealth < 0 then
            victimHealth = 0
        end
        local message, _ = FetchTranslation("dmgprint.info")
            :gsub("{DMG_TO}", Damage[playerid][i])
            :gsub("{HITS_TO}", DamageHits[playerid][i])
            :gsub("{DMG_FROM}",Damage[i][playerid])
            :gsub("{HITS_FROM}", DamageHits[i][playerid])
            :gsub("{NAME}", victim:CBasePlayerController().PlayerName)
            :gsub("{HEALTH}", victimHealth)

            ReplyToCommand(playerid, tostring(config:Fetch("dmgprint.prefix") or ""), message)
        ::continue::
    end
end

AddEventHandler("OnRoundStart", function(event)
    Damage = Damage or {}
    DamageHits = DamageHits or {}

    for i = 0, playermanager:GetPlayerCap() - 1, 1 do
        local player = GetPlayer(i)
        if not player or not player:IsValid() then goto continue end

        Damage[i] = Damage[i] or {}
        DamageHits[i] = DamageHits[i] or {}

        for j = 0, playermanager:GetPlayerCap() - 1, 1 do
            local victim = GetPlayer(j)
            if not victim or not victim:IsValid() then goto continue2 end

            Damage[i][j] = 0
            DamageHits[i][j] = 0
            ::continue2::
        end
        ::continue::
    end
    return EventResult.Continue
end)

AddEventHandler("OnPostRoundEnd", function (event)
    for i = 0, playermanager:GetPlayerCap() - 1, 1 do
        local player = GetPlayer(i)
        if not player or not player:IsValid() then goto continue end
        PrintDamageInfo(i)
        ::continue::   
    end
end)

AddEventHandler("OnPlayerHurt", function(event)
    local attackerId = event:GetInt("attacker")
    local victimId = event:GetInt("userid")
    if attackerId == victimId then return end

    local attacker = GetPlayer(attackerId)
    local victim = GetPlayer(victimId)
    if not attacker or not attacker:IsValid() or not victim or not victim:IsValid() then return end

    local preHealth = victim:CBaseEntity().Health
    local damage = event:GetInt("dmg_health")
    local postHealth = event:GetInt("health")

    if postHealth == 0 then
        damage = damage + preHealth
    end

    Damage[attackerId] = Damage[attackerId] or {}
    Damage[attackerId][victimId] = Damage[attackerId][victimId] or 0

    DamageHits[attackerId] = DamageHits[attackerId] or {}
    DamageHits[attackerId][victimId] = DamageHits[attackerId][victimId] or 0

    Damage[attackerId][victimId] = Damage[attackerId][victimId] + damage
    DamageHits[attackerId][victimId] = DamageHits[attackerId][victimId] + 1
end)


commands:Register("dmg", function (playerid, args, argc, silent, prefix)
    local player = GetPlayer(playerid)
    if not player or not player:IsValid() then return end
    if player:CCSPlayerController().PawnIsAlive then
        return ReplyToCommand(playerid, tostring(config:Fetch("dmgprint.prefix")), FetchTranslation("dmgprint.must_die", playerid))
    end
    return PrintDamageInfo(playerid)
end)
