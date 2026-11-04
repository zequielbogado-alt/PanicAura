-- PanicAura_DieAndRise.lua - Sistema Die & Rise (Estados, Almas, Náuseas, Elixires y Corporeidad)
local addonName = ...
PanicAura = PanicAura or {}
local PA = PanicAura

local SOUL_SPELL_ID = 900114
local SOUL_PREFIX = "TuWoWSouls"
PA.SOUL_SPELL_ID = SOUL_SPELL_ID
PA.SOUL_PREFIX = SOUL_PREFIX

--------------------------------------------------------------------------------
-- 1. Creación del Indicador Visual Die & Rise
--------------------------------------------------------------------------------
local drWidget = CreateFrame("Frame", "PanicAuraDRWidget", UIParent)
drWidget:SetSize(220, 26)
drWidget:SetPoint("CENTER", UIParent, "CENTER", 0, -175)
drWidget:SetFrameStrata("HIGH")
drWidget:SetClampedToScreen(true)
drWidget:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
drWidget:SetBackdropColor(0.04, 0.04, 0.06, 0.85)
drWidget:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.9)
drWidget:SetMovable(true)
drWidget:EnableMouse(true)
drWidget:RegisterForDrag("LeftButton")
drWidget:SetScript("OnDragStart", function(self)
    if not PA.db or not PA.db.locked then self:StartMoving() end
end)
drWidget:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local _, _, _, x, y = self:GetPoint()
    if PA.db then
        PA.db.drWidgetX = x
        PA.db.drWidgetY = y
    end
end)
drWidget:Hide()

local drIcon = drWidget:CreateTexture(nil, "ARTWORK")
drIcon:SetSize(18, 18)
drIcon:SetPoint("LEFT", drWidget, "LEFT", 6, 0)
drIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local drText = drWidget:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
drText:SetPoint("LEFT", drIcon, "RIGHT", 6, 0)
drText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")

local drBar = CreateFrame("StatusBar", nil, drWidget)
drBar:SetPoint("BOTTOMLEFT", drWidget, "BOTTOMLEFT", 4, 3)
drBar:SetPoint("BOTTOMRIGHT", drWidget, "BOTTOMRIGHT", -4, 3)
drBar:SetHeight(3)
drBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
drBar:SetMinMaxValues(0, 300)
drBar:SetValue(0)
drBar:Hide()

PA.drWidget = drWidget
PA.drIcon = drIcon
PA.drText = drText
PA.drBar = drBar

--------------------------------------------------------------------------------
-- 2. Detección de Elixir de Purificación en Mochilas
--------------------------------------------------------------------------------
function PA:HasPurificationElixir()
    for b = 0, 4 do
        local numSlots = GetContainerNumSlots(b)
        for s = 1, numSlots do
            local link = GetContainerItemLink(b, s)
            if link then
                local low = link:lower()
                if low:find("purificaci") or low:find("elixir de purific") then
                    return true, link
                end
            end
        end
    end
    return false
end

--------------------------------------------------------------------------------
-- 3. Tooltip Explicativo de Estado
--------------------------------------------------------------------------------
drWidget:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    local st = PA.drStage or 0
    if st == 0 then
        GameTooltip:AddLine("Estado Die & Rise: |cff22ff22Vivo (Normal)|r", 1, 1, 1)
        GameTooltip:AddLine("Tenés tus vidas intactas. Si morís pasarás a estado Putrefacto.", 0.8, 0.8, 0.8, true)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffffff00Tip:|r Si morís y quedás Putrefacto, podés buscar o comerciar un |cff00ff00Elixir de Purificación|r (dropeado por rares) para volver a estar Vivo.", 0.8, 0.9, 0.8, true)
    elseif st == 1 then
        GameTooltip:AddLine("Estado Die & Rise: |cff88ff22Putrefacto|r", 1, 1, 1)
        GameTooltip:AddLine("Al comer podés sentir náuseas y vomitar. ¡Si morís pasarás a Esquelético!", 1, 0.8, 0.2, true)
        local hasElixir = PA.HasPurificationElixir and PA:HasPurificationElixir()
        if hasElixir then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cff00ff00¡Tenés un Elixir de Purificación en tu mochila!|r", 1, 1, 1)
            GameTooltip:AddLine("Bebelo para curar la putrefacción y volver inmediatamente al estado VIVO.", 0.8, 1, 0.8, true)
        else
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cffffff00Tip:|r Los monstruos raros (rares) dropean |cff00ff00Elixir de Purificación|r de tu rango de nivel para volver a estar Vivo.", 0.9, 0.9, 0.9, true)
        end
    else
        GameTooltip:AddLine("Estado Die & Rise: |cffccccccEsquelético|r", 1, 1, 1)
        GameTooltip:AddLine(string.format("Almas recolectadas: |cffffff00%d / %d|r", PA.drSouls or 0, PA.drGoal or 300), 1, 1, 1)
        GameTooltip:AddLine("No podés comer, beber ni usar pociones (salvo sacrificando 1 alma por 36 s).", 1, 0.4, 0.4, true)
    end
    if PA.db and PA.db.deathLog and #PA.db.deathLog > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(string.format("Muertes registradas: %d (ver pestaña Die & Rise)", #PA.db.deathLog), 0.7, 0.7, 0.7)
    end
    GameTooltip:Show()
end)
drWidget:SetScript("OnLeave", function() GameTooltip:Hide() end)

--------------------------------------------------------------------------------
-- 4. Escaneo de Auras (Buffs/Debuffs) para detectar Estado
--------------------------------------------------------------------------------
function PA:ScanPlayerAurasForDR()
    local foundStage = nil
    local foundSouls = nil
    for i = 1, 40 do
        local name, _, _, stacks, _, duration, expTime, _, _, _, id = UnitBuff("player", i)
        if not name then break end
        local low = name:lower()
        if id == SOUL_SPELL_ID then
            foundStage = 2
            foundSouls = stacks
        elseif low:find("esquelet") or low:find("esquelét") or low:find("skeleton") then
            foundStage = 2
        elseif low:find("putrefact") then
            if foundStage ~= 2 then foundStage = 1 end
        end
        if duration and duration >= 30 and duration <= 40 and (low:find("corpor") or low:find("alma") or low:find("carne")) then
            PA.corporealEnd = expTime
        end
    end
    for i = 1, 40 do
        local name, _, _, _, _, duration, expTime, _, _, _, id = UnitDebuff("player", i)
        if not name then break end
        local low = name:lower()
        if low:find("esquelet") or low:find("esquelét") or low:find("skeleton") then
            foundStage = 2
        elseif low:find("putrefact") then
            if foundStage ~= 2 then foundStage = 1 end
        elseif low:find("nausea") or low:find("náusea") or low:find("vomito") or low:find("vómito") then
            PA.nauseaActive = GetTime()
        end
    end

    local newStage = foundStage or 0
    local prevStage = PA.drStage or (PA.db and PA.db.drStage) or 0

    if prevStage ~= newStage then
        -- Si pasó de Putrefacto (1) o Esquelético (2) a Vivo (0)
        if prevStage > 0 and newStage == 0 then
            PA.nauseaActive = nil
            PA.corporealEnd = nil
            PlaySound("LevelUp")
            PA.tempAlert = {
                title = "¡HAS SIDO PURIFICADO!",
                sub = "Recuperaste el estado VIVO · Vidas intactas",
                level = 1,
                untilTime = GetTime() + 6,
            }
        end
        PA.drStage = newStage
        if PA.db then PA.db.drStage = newStage end
        PA:UpdateDRWidget()
    else
        PA.drStage = newStage
        if PA.db then PA.db.drStage = newStage end
    end

    if foundSouls and not PA.drSoulsFresh then
        PA.drSouls = foundSouls
        if PA.db then PA.db.drSouls = foundSouls end
    end
end

--------------------------------------------------------------------------------
-- 5. Actualización Visual del Indicador Die & Rise
--------------------------------------------------------------------------------
function PA:UpdateDRWidget()
    if not PA.db or not PA.db.drEnabled or not PA.db.drShowWidget then
        drWidget:Hide()
        return
    end
    local st = PA.drStage or (PA.db and PA.db.drStage) or 0
    local now = GetTime()
    local corpRem = (PA.corporealEnd and PA.corporealEnd > now) and (PA.corporealEnd - now) or 0
    local nauseaRem = (PA.nauseaActive and (now - PA.nauseaActive) < 25) and (25 - (now - PA.nauseaActive)) or 0

    if PA.db.drHideWhenAlive and st == 0 and corpRem == 0 and nauseaRem == 0 and (PA.db.locked ~= false) then
        drWidget:Hide()
        return
    end

    if corpRem > 0 and PA.db.drCorporealTrack then
        drIcon:SetTexture("Interface\\Icons\\Spell_Holy_GreaterHeal")
        drText:SetText(string.format("|cff66ffccCorporeidad: %.0fs|r (Podés comer/beber)", corpRem))
        drWidget:SetBackdropBorderColor(0.2, 1.0, 0.8, 0.95)
        drBar:SetMinMaxValues(0, 36)
        drBar:SetValue(corpRem)
        drBar:SetStatusBarColor(0.2, 1.0, 0.8)
        drBar:Show()
    elseif st == 2 then
        local souls = PA.drSouls or (PA.db and PA.db.drSouls) or 0
        local goal = PA.drGoal or (PA.db and PA.db.drGoal) or 300
        drIcon:SetTexture("Interface\\Icons\\Spell_Shadow_RaiseDead")
        if souls >= goal then
            drText:SetText(string.format("|cff00ff00ESQUELÉTICO · Almas: %d/%d (¡LISTO!)|r", souls, goal))
            drWidget:SetBackdropBorderColor(0.1, 1.0, 0.1, 0.95)
        else
            drText:SetText(string.format("|cffddddddESQUELÉTICO|r · Almas: |cffffff00%d/%d|r", souls, goal))
            drWidget:SetBackdropBorderColor(0.75, 0.75, 0.85, 0.9)
        end
        drBar:SetMinMaxValues(0, goal)
        drBar:SetValue(math.min(souls, goal))
        drBar:SetStatusBarColor(0.6, 0.4, 1.0)
        drBar:Show()
    elseif st == 1 then
        drIcon:SetTexture("Interface\\Icons\\Ability_Creature_Disease_02")
        local hasElixir = PA.HasPurificationElixir and PA:HasPurificationElixir()
        if nauseaRem > 0 then
            drText:SetText("|cffff8000PUTREFACTO · ¡NÁUSEAS ACTIVAS!|r")
            drWidget:SetBackdropBorderColor(1.0, 0.5, 0.0, 0.95)
        elseif hasElixir then
            drText:SetText("|cff88ff22PUTREFACTO|r · |cff00ff00¡Tenés Elixir! Usalo|r")
            drWidget:SetBackdropBorderColor(0.2, 0.9, 0.4, 0.9)
        else
            drText:SetText("|cff88ff22PUTREFACTO|r · |cffffaaaa1 muerte = Esquelético|r")
            drWidget:SetBackdropBorderColor(0.5, 0.9, 0.2, 0.85)
        end
        drBar:Hide()
    else
        drIcon:SetTexture("Interface\\Icons\\Spell_Holy_Resurrection")
        if PA.db.locked == false then
            drText:SetText("|cff22ff22VIVO|r · Arrastrá para mover")
        else
            drText:SetText("|cff22ff22ESTADO: VIVO|r · |cff88ff88Vidas intactas|r")
        end
        drWidget:SetBackdropBorderColor(0.2, 0.85, 0.3, 0.85)
        drBar:Hide()
    end

    local w = drText:GetStringWidth() + 38
    drWidget:SetWidth(math.max(w, 190))
    drWidget:Show()
end

--------------------------------------------------------------------------------
-- 6. Manejo de Mensajes de Chat y Alertas de Servidor
--------------------------------------------------------------------------------
function PA:HandleDieAndRiseChat(msg)
    if not msg or not PA.db or not PA.db.drEnabled then return end
    local low = msg:lower()
    local now = GetTime()

    -- 0) Purificación (Elixir de Purificación)
    if low:find("purific") or low:find("elixir de purific") or low:find("dejas de estar putrefacto") or low:find("vuelves a estar vivo") or low:find("has sido purificado") then
        PA.nauseaActive = nil
        PA.corporealEnd = nil
        PA.drStage = 0
        if PA.db then PA.db.drStage = 0 end
        PlaySound("LevelUp")
        PA.tempAlert = {
            title = "¡HAS SIDO PURIFICADO!",
            sub = "Recuperaste el estado VIVO · Vidas intactas",
            level = 1,
            untilTime = now + 6,
        }
        PA:UpdateDRWidget()
        if PA.CheckPanicState then PA:CheckPanicState() end
    -- 1) Pre-aviso de náuseas en estado Putrefacto
    elseif PA.db.drNauseaWarn and (low:find("estomago putrefacto rechaza") or low:find("estómago putrefacto rechaza") or low:find("sientes fuertes nauseas") or low:find("sientes fuertes náuseas")) then
        PA.nauseaActive = now
        PA.tempAlert = {
            title = "¡NÁUSEAS! TU ESTÓMAGO RECHAZA LA COMIDA",
            sub = "Podrías vomitar pronto · ¡No entres en combate descuidado!",
            level = 2,
            untilTime = now + 5,
        }
        PA:UpdateDRWidget()
        if PA.CheckPanicState then PA:CheckPanicState() end
    -- 2) Vómito inminente / activo
    elseif PA.db.drNauseaWarn and (low:find("no puedes contener las nauseas") or low:find("no puedes contener las náuseas") or low:find("comienzas a vomitar")) then
        PA.nauseaActive = nil
        PA.tempAlert = {
            title = "¡ESTÁS VOMITANDO!",
            sub = "¡Cuidado! Estás vulnerable · Alejate del peligro",
            level = 3,
            untilTime = now + 5,
        }
        PA:UpdateDRWidget()
        if PA.CheckPanicState then PA:CheckPanicState() end
    -- 3) Sacrificio de 1 alma por 36 segundos de corporeidad
    elseif PA.db.drCorporealTrack and ((low:find("sacrifica") and low:find("alma")) or low:find("36 segundo") or low:find("corporeidad")) then
        PA.corporealEnd = now + 36
        PA.tempAlert = {
            title = "¡CORPOREIDAD PROVISORIA (36 s)!",
            sub = "Aprovechá para comer, beber y curarte ahora",
            level = 1,
            untilTime = now + 4,
        }
        PA:UpdateDRWidget()
        if PA.CheckPanicState then PA:CheckPanicState() end
    end
end
