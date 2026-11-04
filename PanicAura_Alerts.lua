-- PanicAura_Alerts.lua - Lógica de Alertas (Vida, Cazador, Atacantes, Die & Rise)
local addonName = ...
PanicAura = PanicAura or {}
local PA = PanicAura

local _, playerClass = UnitClass("player")
local ATTACKER_EXPIRE = 6 -- segundos sin golpearte para dejar de contar a un atacante
local lastSoundTime = 0

-- Registro de atacantes vía registro de combate
local attackers = {}
PA.attackers = attackers

function PA:CountThreat()
    if PA.testMode then return 3 end
    local now = GetTime()
    local set = {}
    for guid, t in pairs(attackers) do
        if now - t > ATTACKER_EXPIRE then
            attackers[guid] = nil
        else
            set[guid] = true
        end
    end

    local function check(u)
        if UnitExists(u) and UnitCanAttack("player", u) and not UnitIsDead(u)
           and UnitExists(u .. "target") and UnitIsUnit(u .. "target", "player") then
            local g = UnitGUID(u)
            if g then set[g] = true end
        end
    end
    check("target"); check("focus"); check("mouseover")
    local n = GetNumRaidMembers()
    if n > 0 then
        for i = 1, n do check("raid" .. i .. "target") end
    else
        for i = 1, GetNumPartyMembers() do check("party" .. i .. "target") end
    end

    local c = 0
    for _ in pairs(set) do c = c + 1 end
    return c
end

-- Rango de seguridad (Cazador): devuelve nil / "melee" / "dead"
local SPELL_RAPTOR, SPELL_CHEETAH, SPELL_MONKEY, SPELL_TRAP, SPELL_CONCUSSIVE = 2973, 5118, 13163, 1499, 5116
local function SpellN(id) return (GetSpellInfo(id)) or "?" end

function PA:GetRangeDanger()
    if playerClass ~= "HUNTER" or not PA.db or not PA.db.rangeWarn then return nil end
    if not UnitExists("target") or not UnitCanAttack("player", "target") or UnitIsDead("target") then return nil end
    if not UnitAffectingCombat("target") then return nil end
    -- Sólo si el enemigo te ataca a ti (no a tu mascota) o es un jugador
    local targetsMe = UnitExists("targettarget") and UnitIsUnit("targettarget", "player")
    if not (targetsMe or UnitIsPlayer("target")) then return nil end

    if IsSpellInRange(SpellN(SPELL_RAPTOR), "target") == 1 then
        return "melee"
    end
    -- ~9.9 yardas: aproxima la zona muerta del Cazador (< 8 yd) donde no podés usar disparos
    if CheckInteractDistance("target", 3) then
        return "dead"
    end
    return nil
end

local function ApplyLevelVisuals(level)
    local c = (PA.LEVEL_COLORS and PA.LEVEL_COLORS[level]) or { 1.0, 0.1, 0.1 }
    if PA.SetEdgeColor then PA:SetEdgeColor(c[1], c[2], c[3]) end
    if PA.bannerText then PA.bannerText:SetTextColor(c[1], c[2], c[3], 1) end
    if PA.statusText then PA.statusText:SetTextColor(c[1], c[2], c[3], 1) end
    if PA.bossBanner then
        PA.bossBanner:SetBackdropBorderColor(c[1], c[2], c[3], 1)
        PA.bossBanner:SetBackdropColor(c[1] * 0.12, c[2] * 0.12, c[3] * 0.12, 0.8)
    end
end

function PA:CheckPanicState()
    if not PA.db or not PA.db.enabled then
        PA:StopPanic()
        return
    end

    local threat = PA:CountThreat()
    PA.threat = threat

    if PA.testMode then
        local lvl = PA.testLevel or 3
        local reasons = {
            [1] = { "¡CUIDADO! SALUD BAJANDO", "Mantené la calma y usá tus recursos" },
            [2] = { "¡ENEMIGO EN ZONA DE PELIGRO!", string.format("%s · %s · %s", SpellN(SPELL_CHEETAH), SpellN(SPELL_RAPTOR), SpellN(SPELL_TRAP)) },
            [3] = { "¡PELIGRO! SALUD BAJA", "¡USA TUS HABILIDADES SALVAVIDAS!" },
        }
        PA:StartPanic(reasons[lvl][1], lvl, reasons[lvl][2])
        return
    end

    local now = GetTime()
    if PA.tempAlert and PA.tempAlert.untilTime > now then
        PA:StartPanic(PA.tempAlert.title, PA.tempAlert.level, PA.tempAlert.sub)
        return
    end

    if not UnitAffectingCombat("player") then
        PA:StopPanic()
        return
    end

    local curHP = UnitHealth("player")
    local maxHP = UnitHealthMax("player")
    local hpPct = (maxHP > 0) and ((curHP / maxHP) * 100) or 100
    local alive = curHP > 0 and not UnitIsDeadOrGhost("player")
    if not alive then
        PA:StopPanic()
        return
    end

    local stage = (PA.db.drEnabled and (PA.drStage or PA.db.drStage)) or 0
    local boost = 0
    if PA.db.drEnabled and PA.db.drStageBoost then
        if stage == 1 then boost = 10 elseif stage == 2 then boost = 15 end
    end
    local critThresh = math.min(85, (PA.db.hpThreshold or 40) + boost)
    local warnThresh = math.min(95, math.max((PA.db.warnThreshold or 70) + boost, critThresh + 5))

    local critical = hpPct <= critThresh
    local lowish = PA.db.warnEnabled and hpPct <= warnThresh
    local recentBigHit = PA.db.drEnabled and PA.db.drBigHitAlert and PA.bigHitTime and (now - PA.bigHitTime < 4)

    local petName
    local isPetDead = false
    if PA.db.triggerOnPetDeath and UnitExists("pet") then
        petName = (UnitName("pet") or "TU MASCOTA"):upper()
        if UnitIsDead("pet") or UnitIsGhost("pet") or UnitHealth("pet") == 0 then
            isPetDead = true
        end
    end

    local danger = PA:GetRangeDanger()
    local manyAttackers = PA.db.threatAlert and threat >= (PA.db.threatAlertMin or 3)

    if critical or recentBigHit then
        local title = recentBigHit and not critical
            and string.format("¡GOLPE BRUTAL! (-%d%% DE VIDA)", PA.bigHitPct or 0)
            or string.format("¡PELIGRO! SALUD BAJA (%d%%)", math.floor(hpPct))
        local sub = "¡USA TUS HABILIDADES SALVAVIDAS!"
        if stage == 1 then
            sub = "¡1 MUERTE MÁS = ESQUELÉTICO! ¡USÁ TUS SALVAVIDAS!"
        elseif stage == 2 then
            sub = "¡ESTADO ESQUELÉTICO! (Pociones bloqueadas · Usá defensivos)"
        end
        if danger then
            sub = sub .. " · Enemigo cerca"
        end
        PA:StartPanic(title, 3, sub)
    elseif danger then
        local sub
        if danger == "melee" then
            sub = string.format("%s · %s · %s", SpellN(SPELL_RAPTOR), SpellN(SPELL_MONKEY), SpellN(SPELL_TRAP))
        else
            sub = string.format("%s · %s · %s", SpellN(SPELL_CHEETAH), SpellN(SPELL_TRAP), SpellN(SPELL_CONCUSSIVE))
        end
        local title = (danger == "melee") and "¡ENEMIGO CUERPO A CUERPO!" or "¡ENEMIGO EN ZONA MUERTA!"
        PA:StartPanic(title, 2, sub)
    elseif isPetDead then
        PA:StartPanic(string.format("%s HA MUERTO", petName), 1, "Revivila o preparate para defenderte")
    elseif lowish then
        local sub = "Considerá usar tus habilidades defensivas"
        if stage == 1 then sub = "Estás en estado Putrefacto · Cuidá tu vida"
        elseif stage == 2 then sub = "Estás en estado Esquelético · Sin pociones" end
        PA:StartPanic(string.format("SALUD BAJA (%d%%)", math.floor(hpPct)), 1, sub)
    elseif manyAttackers then
        PA:StartPanic(string.format("¡%d ENEMIGOS TE ATACAN!", threat), 1, "Considerá huir o usar control de masas")
    else
        PA:StopPanic()
    end
end

function PA:StartPanic(reason, level, sub)
    level = level or 3
    local prev = PA.inPanic and (PA.level or 0) or 0
    PA.inPanic = true
    PA.level = level

    -- Sonido sólo al subir de nivel (con enfriamiento para no molestar)
    local now = GetTime()
    if level > prev and now - lastSoundTime > 2 and not PA.setupMode then
        if level == 3 and PA.db and PA.db.soundAlert then
            PlaySoundFile(PA.db.soundFile or "Sound\\Interface\\RaidWarning.wav")
            lastSoundTime = now
        elseif level < 3 and PA.db and PA.db.soundWarn then
            PlaySound("TellMessage")
            lastSoundTime = now
        end
    end

    ApplyLevelVisuals(level)

    local flashAllowed = PA.db and PA.db.showScreenFlash and (level == 3 or PA.db.flashWarn)
    if flashAllowed and not PA.setupMode and PA.flashFrame then
        PA.flashFrame:Show()
    elseif PA.flashFrame then
        PA.flashFrame:Hide()
    end

    if PA.db and PA.db.showBanner and not PA.setupMode and PA.bossBanner then
        PA.bannerText:SetText(reason or "¡PELIGRO INMINENTE!")
        PA.bannerSubtext:SetText(sub or "")
        local w = math.max(PA.bannerText:GetStringWidth(), PA.bannerSubtext:GetStringWidth()) + 50
        PA.bossBanner:SetWidth(math.max(w, 280))
        PA.bossBanner:Show()
        if PA.statusText then PA.statusText:SetText("") end
    else
        if PA.bossBanner then PA.bossBanner:Hide() end
        if PA.statusText then
            PA.statusText:SetText(PA.setupMode and "MODO CONFIGURACIÓN: Arrastra aquí poderes o pociones" or (reason or ""))
        end
    end

    if PA.mainFrame then PA.mainFrame:Show() end
    if PA.UpdateThreatDisplay then PA:UpdateThreatDisplay() end
    if PA.UpdateSlots then PA:UpdateSlots() end
end

function PA:StopPanic()
    PA.inPanic = false
    PA.level = nil
    PA.setupMode = false
    if PA.flashFrame then PA.flashFrame:Hide() end
    if PA.bossBanner then PA.bossBanner:Hide() end
    if PA.threatFrame then PA.threatFrame:Hide() end
    if PA.mainFrame then
        if not PA.testMode and PA.db and PA.db.locked then
            PA.mainFrame:Hide()
        elseif not PA.testMode and not PA.db then
            PA.mainFrame:Hide()
        end
    end
end
