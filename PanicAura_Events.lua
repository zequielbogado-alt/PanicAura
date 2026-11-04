-- PanicAura_Events.lua - Despachador Central de Eventos y Tickers de Actualización
local addonName = ...
PanicAura = PanicAura or {}
local PA = PanicAura

local playerGUID

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")  -- Entró en combate
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")   -- Salió de combate
eventFrame:RegisterEvent("UNIT_HEALTH")
eventFrame:RegisterEvent("UNIT_MAXHEALTH")
eventFrame:RegisterEvent("UNIT_PET")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
eventFrame:RegisterEvent("CHAT_MSG_MONSTER_EMOTE")
eventFrame:RegisterEvent("CHAT_MSG_TEXT_EMOTE")
eventFrame:RegisterEvent("UI_ERROR_MESSAGE")
eventFrame:RegisterEvent("UI_INFO_MESSAGE")
eventFrame:RegisterEvent("PLAYER_DEAD")
eventFrame:RegisterEvent("UPDATE_BINDINGS")
eventFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
PA.eventFrame = eventFrame

--------------------------------------------------------------------------------
-- 1. Ticker en Tiempo Real (0.1s)
--------------------------------------------------------------------------------
local throttle = 0
local lastCorpWarn = 0
eventFrame:SetScript("OnUpdate", function(self, elapsed)
    throttle = throttle + elapsed
    if throttle >= 0.1 then
        throttle = 0
        if PA.db then
            local now = GetTime()
            if PA.corporealEnd and PA.db.drEnabled and PA.db.drCorporealTrack then
                local rem = PA.corporealEnd - now
                if rem > 0 and rem <= 6 and now - lastCorpWarn > 10 then
                    lastCorpWarn = now
                    PA.tempAlert = {
                        title = string.format("¡CORPOREIDAD TERMINA EN %.0f S!", rem),
                        sub = "Dejarás de poder comer, beber o usar pociones",
                        level = 2,
                        untilTime = now + 3.5,
                    }
                elseif rem <= 0 then
                    PA.corporealEnd = nil
                end
            end
            if PA.UpdateDRWidget then PA:UpdateDRWidget() end
            if PA.CheckPanicState then PA:CheckPanicState() end
            if (PA.inPanic or PA.testMode) and PA.UpdateSlots then
                PA:UpdateSlots()
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- 2. Procesamiento de Registro de Combate (Combat Log)
--------------------------------------------------------------------------------
local ATTACK_EVENTS = {
    SWING_DAMAGE = true, SWING_MISSED = true,
    RANGE_DAMAGE = true, RANGE_MISSED = true,
    SPELL_DAMAGE = true, SPELL_MISSED = true,
}

local DAMAGE_EVENTS = {
    SWING_DAMAGE = true, RANGE_DAMAGE = true, SPELL_DAMAGE = true, SPELL_PERIODIC_DAMAGE = true,
}

local function OnCombatLog(timestamp, subEvent, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
    if not playerGUID then playerGUID = UnitGUID("player") end
    if subEvent == "UNIT_DIED" then
        if PA.attackers then PA.attackers[dstGUID] = nil end
    elseif ATTACK_EVENTS[subEvent] and dstGUID == playerGUID and srcGUID and srcGUID ~= playerGUID
        and srcFlags and bit.band(srcFlags, 0x40) > 0 then -- 0x40 = reacción hostil
        if PA.attackers then PA.attackers[srcGUID] = GetTime() end
    end

    -- Registro de último atacante y detección de golpe fuerte (Big Hit)
    if DAMAGE_EVENTS[subEvent] and dstGUID == playerGUID then
        local amount = (subEvent == "SWING_DAMAGE") and select(1, ...) or select(4, ...)
        local spellName = (subEvent == "SWING_DAMAGE") and "Ataque cuerpo a cuerpo" or select(2, ...)
        if srcName and srcName ~= "" then
            PA.lastAttacker = srcName .. (spellName and (" (" .. spellName .. ")") or "")
        end
        if amount and tonumber(amount) and PA.db and PA.db.drEnabled and PA.db.drBigHitAlert then
            local maxHP = UnitHealthMax("player")
            if maxHP and maxHP > 0 then
                local pct = (tonumber(amount) / maxHP) * 100
                if pct >= (PA.db.drBigHitPct or 35) then
                    PA.bigHitTime = GetTime()
                    PA.bigHitPct = math.floor(pct)
                end
            end
        end
    end
end
PA.OnCombatLog = OnCombatLog

--------------------------------------------------------------------------------
-- 3. Manejador de Eventos
--------------------------------------------------------------------------------
eventFrame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        OnCombatLog(arg1, arg2, arg3, arg4, ...)
    elseif event == "CHAT_MSG_ADDON" then
        if arg1 == PA.SOUL_PREFIX and arg3 == "WHISPER" and arg4 == UnitName("player") then
            local st, souls, goal = string.match(arg2 or "", "^(%d+):(%d+):(%d+)$")
            st, souls, goal = tonumber(st), tonumber(souls), tonumber(goal)
            if st and st >= 0 and st <= 2 then
                local prevSouls = PA.drSouls or 0
                local prevStage = PA.drStage or 0
                PA.drStage = st
                PA.drSouls = souls or 0
                PA.drGoal = (goal and goal >= 1) and goal or 300
                PA.drSoulsFresh = GetTime()
                if PA.db then
                    PA.db.drStage = st
                    PA.db.drSouls = PA.drSouls
                    PA.db.drGoal = PA.drGoal
                end
                -- Si volvió a estado Vivo (0) desde Putrefacto o Esquelético:
                if prevStage > 0 and st == 0 then
                    PA.nauseaActive = nil
                    PA.corporealEnd = nil
                    if PA.PlayAlertSound then
                        PA:PlayAlertSound("LevelUp", false, 2.0)
                    else
                        PlaySound("LevelUp")
                    end
                    PA.tempAlert = {
                        title = "¡HAS SIDO PURIFICADO!",
                        sub = "Recuperaste el estado VIVO · Vidas intactas",
                        level = 1,
                        untilTime = GetTime() + 6,
                    }
                end
                -- Si sacrificó 1 alma (bajó en 1 estando en estado Esquelético), iniciar el cronómetro de 36 s
                if st == 2 and prevStage == 2 and prevSouls > 0 and (souls or 0) == prevSouls - 1 and PA.db and PA.db.drCorporealTrack then
                    PA.corporealEnd = GetTime() + 36
                end
                -- Si llegó a la meta de almas (ej. 300/300), avisar en pantalla
                if st == 2 and (souls or 0) >= PA.drGoal and prevSouls < PA.drGoal and PA.db and PA.db.drEnabled then
                    PA.tempAlert = {
                        title = string.format("¡%d / %d ALMAS RECOLECTADAS!", souls, PA.drGoal),
                        sub = "¡Ya podés canjear tus almas para recuperar tu cuerpo Putrefacto!",
                        level = 1,
                        untilTime = GetTime() + 6,
                    }
                end
                if PA.UpdateDRWidget then PA:UpdateDRWidget() end
            end
        end
    elseif event == "UNIT_AURA" and arg1 == "player" then
        if PA.ScanPlayerAurasForDR then PA:ScanPlayerAurasForDR() end
        if PA.UpdateDRWidget then PA:UpdateDRWidget() end
    elseif event == "CHAT_MSG_SYSTEM" or event == "CHAT_MSG_MONSTER_EMOTE" or event == "CHAT_MSG_TEXT_EMOTE" or event == "UI_ERROR_MESSAGE" or event == "UI_INFO_MESSAGE" then
        if PA.HandleDieAndRiseChat then PA:HandleDieAndRiseChat(arg1) end
    elseif event == "PLAYER_DEAD" then
        if PA.db then
            PA.db.deathLog = PA.db.deathLog or {}
            local zone = GetRealZoneText() or GetZoneText() or "Desconocido"
            local killer = PA.lastAttacker or "Desconocido"
            local st = PA.drStage or PA.db.drStage or 0
            local stName = (st == 0 and "Vivo -> Putrefacto") or (st == 1 and "Putrefacto -> Esquelético") or "Esquelético"
            table.insert(PA.db.deathLog, 1, {
                date = date("%d/%m %H:%M"),
                level = UnitLevel("player") or 1,
                zone = zone,
                killer = killer,
                stage = stName,
            })
            while #PA.db.deathLog > 15 do
                table.remove(PA.db.deathLog)
            end
        end
        if PA.CheckPanicState then PA:CheckPanicState() end
    elseif event == "ADDON_LOADED" and arg1 == addonName then
        PA:InitDB()
        PA.drStage = PA.db.drStage or 0
        PA.drSouls = PA.db.drSouls or 0
        PA.drGoal = PA.db.drGoal or 300
        if PA.CreateMinimapButton then PA:CreateMinimapButton() end
        if PA.UpdateLayout then PA:UpdateLayout() end
        if PA.ApplyScale then PA:ApplyScale() end
        if PA.mainFrame and PA.db.frameX and PA.db.frameY then
            PA.mainFrame:ClearAllPoints()
            PA.mainFrame:SetPoint("CENTER", UIParent, "CENTER", PA.db.frameX, PA.db.frameY)
        end
        if PA.drWidget and PA.db.drWidgetX and PA.db.drWidgetY then
            PA.drWidget:ClearAllPoints()
            PA.drWidget:SetPoint("CENTER", UIParent, "CENTER", PA.db.drWidgetX, PA.db.drWidgetY)
        end
        if PA.UpdateDRWidget then PA:UpdateDRWidget() end
    elseif event == "PLAYER_ENTERING_WORLD" then
        playerGUID = UnitGUID("player")
        if not PA.minimapBtn and PA.CreateMinimapButton then
            PA:CreateMinimapButton()
        elseif PA.UpdateMinimapPos and PA.db and PA.db.minimap then
            PA.UpdateMinimapPos(PA.db.minimap.minimapPos or 195)
        end
        if PA.ScanPlayerAurasForDR then PA:ScanPlayerAurasForDR() end
        if PA.UpdateDRWidget then PA:UpdateDRWidget() end
        if PA.UpdateLayout then PA:UpdateLayout() end
        if PA.CheckPanicState then PA:CheckPanicState() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if PA.attackers then wipe(PA.attackers) end
        if PA.CheckPanicState then PA:CheckPanicState() end
    elseif event == "UPDATE_BINDINGS" or event == "ACTIONBAR_UPDATE_COOLDOWN" or event == "BAG_UPDATE" then
        if event == "BAG_UPDATE" and (PA.drStage == 1 or PA.drStage == 0) and PA.UpdateDRWidget then
            PA:UpdateDRWidget()
        end
        if (PA.inPanic or PA.testMode) and PA.UpdateSlots then
            PA:UpdateSlots()
        end
    else
        if PA.CheckPanicState then PA:CheckPanicState() end
    end
end)
