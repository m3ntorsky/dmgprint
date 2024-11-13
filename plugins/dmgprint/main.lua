local Damage = {}
local DamageHits = {}


local function IsValidPlayer(player)
    return player and player:IsValid()
end


local function InitializeDamageTables()
    for i = 0, playermanager:GetPlayerCap() - 1 do
        if IsValidPlayer(GetPlayer(i)) then
            Damage[i] = {}
            DamageHits[i] = {}
            for j = 0, playermanager:GetPlayerCap() - 1 do
                if IsValidPlayer(GetPlayer(j)) then
                    Damage[i][j] = 0
                    DamageHits[i][j] = 0
                end
            end
        end
    end
end


local function PrintDamageInfo(playerid)
    local player = GetPlayer(playerid)
    if not IsValidPlayer(player) then return end

    local team = player:CBaseEntity().TeamNum
    if team ~= Team.CT and team ~= Team.T then return end

    local otherTeam = (team == Team.CT) and Team.T or Team.CT

    for i = 0, playermanager:GetPlayerCap() - 1 do
        local victim = GetPlayer(i)
        if not (IsValidPlayer(victim) and victim:CBaseEntity().TeamNum == otherTeam) then
            goto continue
        end

        Damage[playerid] = Damage[playerid] or {}
        DamageHits[playerid] = DamageHits[playerid] or {}
        Damage[i] = Damage[i] or {}
        DamageHits[i] = DamageHits[i] or {}

        local victimHealth = victim:CBaseEntity().Health
        local message, _ = FetchTranslation("dmgprint.info")
            :gsub("{DMG_TO}", Damage[playerid][i] or 0)
            :gsub("{HITS_TO}", DamageHits[playerid][i] or 0)
            :gsub("{DMG_FROM}", Damage[i][playerid] or 0)
            :gsub("{HITS_FROM}", DamageHits[i][playerid] or 0)
            :gsub("{NAME}", victim:CBasePlayerController().PlayerName)
            :gsub("{HEALTH}", victimHealth)

        ReplyToCommand(playerid, tostring(config:Fetch("dmgprint.prefix") or ""), message)
        ::continue::
    end
end


AddEventHandler("OnRoundStart", function(event)
    InitializeDamageTables()
    return EventResult.Continue
end)


AddEventHandler("OnPostRoundEnd", function(event)
    for i = 0, playermanager:GetPlayerCap() - 1 do
        if IsValidPlayer(GetPlayer(i)) then
            PrintDamageInfo(i)
        end
    end
end)


AddEventHandler("OnPlayerHurt", function(event)
    local attackerId = event:GetInt("attacker")
    local victimId = event:GetInt("userid")
    if attackerId == victimId then return end

    local attacker = GetPlayer(attackerId)
    local victim = GetPlayer(victimId)
    if not (IsValidPlayer(attacker) and IsValidPlayer(victim)) then return end

    local preHealth = victim:CBaseEntity().Health
    local damage = event:GetInt("dmg_health")
    local postHealth = event:GetInt("health")

    if postHealth == 0 then
        damage = damage + preHealth
    end

    Damage[attackerId] = Damage[attackerId] or {}
    Damage[attackerId][victimId] = (Damage[attackerId][victimId] or 0) + damage

    DamageHits[attackerId] = DamageHits[attackerId] or {}
    DamageHits[attackerId][victimId] = (DamageHits[attackerId][victimId] or 0) + 1
end)


commands:Register("dmg", function(playerid, args, argc, silent, prefix)
    local player = GetPlayer(playerid)
    if not IsValidPlayer(player) then return end

    if player:CCSPlayerController().PawnIsAlive then
        return ReplyToCommand(playerid, tostring(config:Fetch("dmgprint.prefix")), FetchTranslation("dmgprint.must_die", playerid))
    end

    return PrintDamageInfo(playerid)
end)