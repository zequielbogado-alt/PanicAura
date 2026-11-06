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
-- 4. Escaneo Seguro de Auras (Buffs/Debuffs) para detectar Estado
--------------------------------------------------------------------------------
local function IsMountAura(name)
    if not name then return false end
    local low = name:lower()
    return low:find("caballo") or low:find("corcel") or low:find("steed") or low:find("horse")
        or low:find("montura") or low:find("mount") or low:find("kodo") or low:find("raptor")
        or low:find("lobo") or low:find("wolf") or low:find("carnero") or low:find("ram")
        or low:find("zancudo") or low:find("strider") or low:find("halcón") or low:find("halcon")
        or low:find("hawk") or low:find("oso") or low:find("bear") or low:find("draco")
        or low:find("drake") or low:find("grifo") or low:find("gryphon") or low:find("mantícora")
        or low:find("manticora") or low:find("hipogrifo") or low:find("hippogryph")
        or low:find("jinete") or low:find("destrero") or low:find("tigre") or low:find("leopardo")
        or low:find("sable") or low:find("cohete") or low:find("alfombra") or low:find("elekk")
        or low:find("talbuk") or low:find("raya") or low:find("tortuga")
end

function PA:ScanPlayerAurasForDR()
    local isMounted = (IsMounted and IsMounted())
    local foundStage = nil
    local foundSouls = nil

    -- 1. Escanear Buffs (Aura de Almas / Corporeidad)
    for i = 1, 40 do
        local name, _, _, stacks, _, duration, expTime, _, _, _, id = UnitBuff("player", i)
        if not name then break end
        local low = name:lower()

        -- El aura oficial de Esquelético es el Spell ID 900114 (Aura de Almas de TuWoW)
        if id == SOUL_SPELL_ID then
            foundStage = 2
            foundSouls = stacks
        elseif not isMounted and not IsMountAura(name) then
            -- Solo considerar esquelético si NO es una montura y el nombre coincide estrictamente
            if low == "esquelético" or low == "esqueletico" or low == "aura de almas" or low == "forma esquelética" then
                foundStage = 2
            end
        end

        -- Rastrear Corporeidad (36 segundos al sacrificar un alma en Esquelético)
        if duration and duration >= 30 and duration <= 40 and not isMounted and not IsMountAura(name) then
            if low == "corporeidad" or low == "cuerpo temporal" or (low:find("corpor") and not low:find("montura")) then
                PA.corporealEnd = expTime
            end
        end
    end

    -- 2. Escanear Debuffs (Putrefacto de TuWoW)
    for i = 1, 40 do
        local name, _, _, _, _, duration, expTime, _, _, _, id = UnitDebuff("player", i)
        if not name then break end
        local low = name:lower()

        -- Debe ser el estado Putrefacto de Die & Rise, NO enfermedades comunes de bichos (peste putrefacta, etc.)
        if low == "putrefacto" or low == "putrefacción" or low == "putrefaccion" or low == "estado: putrefacto" then
            if foundStage ~= 2 then foundStage = 1 end
        elseif (low == "esquelético" or low == "esqueletico") and not isMounted and not IsMountAura(name) then
            foundStage = 2
        end

        if duration and duration >= 30 and duration <= 40 and not isMounted and not IsMountAura(name) then
            if low == "corporeidad" or low == "cuerpo temporal" or (low:find("corpor") and not low:find("montura")) then
                PA.corporealEnd = expTime
            end
        end
    end

    -- 3. Actualización de estado seguras:
    -- Si encontramos activamente el aura de Esquelético (ID 900114 o debuff real) o Putrefacto real:
    if foundStage then
        if PA.drStage ~= foundStage then
            PA.drStage = foundStage
            if PA.db then PA.db.drStage = foundStage end
            PA:UpdateDRWidget()
        end
    elseif PA.drStage == 2 and not foundStage then
        -- Si estaba marcado erróneamente como Esquelético (ej. guardado previo al montar un caballo esquelético),
        -- pero no tiene el Aura de Almas (900114), sanear silenciosamente a 0 (Vivo) sin falsas alarmas.
        PA.drStage = 0
        if PA.db then PA.db.drStage = 0 end
        PA:UpdateDRWidget()
    end

    if foundSouls and not PA.drSoulsFresh then
        PA.drSouls = foundSouls
        if PA.db then PA.db.drSouls = foundSouls end
    end
end

--------------------------------------------------------------------------------
-- 5. Actualización Visual del Widget Die & Rise
--------------------------------------------------------------------------------
function PA:UpdateDRWidget()
    if not PA.drWidget then return end
    if not PA.db or not PA.db.enabled or not PA.db.drEnabled or not PA.db.drShowWidget then
        PA.drWidget:Hide()
        return
    end

    local st = PA.drStage or (PA.db and PA.db.drStage) or 0

    -- Si el usuario eligió ocultar el indicador cuando está Vivo (0 muertes):
    if st == 0 and PA.db.drHideWhenAlive and not PA.testMode and PA.db.locked then
        PA.drWidget:Hide()
        return
    end

    PA.drWidget:Show()

    local now = GetTime()
    local corpActive = PA.corporealEnd and (PA.corporealEnd > now)

    if st == 0 then
        -- Estado Vivo (Normal)
        PA.drIcon:SetTexture("Interface\\Icons\\Spell_Holy_Resurrection")
        PA.drText:SetText("|cff22ff22Estado: Vivo|r")
        PA.drWidget:SetBackdropBorderColor(0.2, 0.8, 0.2, 0.9)
        PA.drBar:Hide()
    elseif st == 1 then
        -- Estado Putrefacto (1 muerte)
        PA.drIcon:SetTexture("Interface\\Icons\\Spell_Shadow_AbominationExplosion")
        local hasElixir = PA.HasPurificationElixir and PA:HasPurificationElixir()
        if hasElixir then
            PA.drText:SetText("|cff88ff22Putrefacto|r |cff00ffff[¡Bebé Elixir!]|r")
            PA.drWidget:SetBackdropBorderColor(0.0, 0.9, 0.9, 0.9)
        elseif PA.nauseaActive and (now - PA.nauseaActive < 15) then
            PA.drText:SetText("|cff88ff22Putrefacto|r |cffff8800(Náuseas)|r")
            PA.drWidget:SetBackdropBorderColor(1.0, 0.5, 0.0, 0.9)
        else
            PA.drText:SetText("|cff88ff22Putrefacto (1 Muerte)|r")
            PA.drWidget:SetBackdropBorderColor(0.5, 0.8, 0.2, 0.9)
        end
        PA.drBar:Hide()
    else
        -- Estado Esquelético (2 o más muertes)
        PA.drIcon:SetTexture("Interface\\Icons\\INV_Misc_Bone_Skull_02")
        local s = PA.drSouls or 0
        local g = PA.drGoal or 300
        if corpActive then
            local rem = math.max(0, PA.corporealEnd - now)
            PA.drText:SetText(string.format("|cff00ffffCorpóreo: %.0f s|r |cffffff00(%d/%d)|r", rem, s, g))
            PA.drWidget:SetBackdropBorderColor(0.0, 0.8, 1.0, 0.95)
            PA.drBar:SetMinMaxValues(0, 36)
            PA.drBar:SetValue(rem)
            PA.drBar:SetStatusBarColor(0.0, 0.8, 1.0)
            PA.drBar:Show()
        else
            PA.drText:SetText(string.format("|cffccccccEsqueleto:|r |cffffff00%d / %d|r almas", s, g))
            PA.drWidget:SetBackdropBorderColor(0.8, 0.2, 0.2, 0.95)
            PA.drBar:SetMinMaxValues(0, g)
            PA.drBar:SetValue(s)
            PA.drBar:SetStatusBarColor(0.9, 0.3, 0.1)
            PA.drBar:Show()
        end
    end
end

--------------------------------------------------------------------------------
-- 6. Escaneo de Mensajes de Chat / Sistema para Die & Rise
--------------------------------------------------------------------------------
function PA:HandleDieAndRiseChat(msg)
    if not msg or not PA.db or not PA.db.drEnabled then return end
    local low = msg:lower()
    local now = GetTime()

    -- 0) Purificación con Elixir de Purificación
    -- IMPORTANTE: Solo disparar si el jugador está actualmente Putrefacto o Esquelético (drStage > 0)
    -- y si el mensaje es del Elixir de Purificación o recuperación de Die & Rise.
    -- NUNCA disparar con hechizos de clase como "Purificar" (Paladín/Sacerdote) ni si el jugador ya está Vivo.
    local isPurificationMsg = low:find("elixir de purific")
        or low:find("dejas de estar putrefacto")
        or low:find("vuelves a estar vivo")
        or low:find("has sido purificado de la putrefacci")
        or (low:find("purific") and (low:find("putrefact") or low:find("elixir")))

    local currentStage = PA.drStage or (PA.db and PA.db.drStage) or 0
    if isPurificationMsg and currentStage > 0 then
        PA.nauseaActive = nil
        PA.corporealEnd = nil
        PA.drStage = 0
        if PA.db then PA.db.drStage = 0 end
        if PA.PlayAlertSound then
            PA:PlayAlertSound("LevelUp", false, 2.0)
        else
            PlaySound("LevelUp")
        end
        PA.tempAlert = {
            title = "¡HAS SIDO PURIFICADO!",
            sub = "Recuperaste el estado VIVO · Vidas intactas",
            level = 1,
            untilTime = now + 6,
        }
        PA:UpdateDRWidget()
        if PA.CheckPanicState then PA:CheckPanicState() end
    -- 1) Pre-aviso de náuseas en estado Putrefacto (solo si está en stage 1)
    elseif PA.db.drNauseaWarn and currentStage == 1 and (low:find("estomago putrefacto rechaza") or low:find("estómago putrefacto rechaza") or low:find("sientes fuertes nauseas") or low:find("sientes fuertes náuseas")) then
        PA.nauseaActive = now
        PA.tempAlert = {
            title = "¡NÁUSEAS! TU ESTÓMAGO RECHAZA LA COMIDA",
            sub = "Podrías vomitar pronto · ¡No entres en combate descuidado!",
            level = 2,
            untilTime = now + 5,
        }
        PA:UpdateDRWidget()
        if PA.CheckPanicState then PA:CheckPanicState() end
    -- 2) Vómito inminente / activo (solo si está en stage 1)
    elseif PA.db.drNauseaWarn and currentStage == 1 and (low:find("no puedes contener las nauseas") or low:find("no puedes contener las náuseas") or low:find("comienzas a vomitar")) then
        PA.nauseaActive = nil
        PA.tempAlert = {
            title = "¡ESTÁS VOMITANDO!",
            sub = "¡Cuidado! Estás vulnerable · Alejate del peligro",
            level = 3,
            untilTime = now + 5,
        }
        PA:UpdateDRWidget()
        if PA.CheckPanicState then PA:CheckPanicState() end
    -- 3) Sacrificio de 1 alma por 36 segundos de corporeidad (solo si está en stage 2)
    elseif PA.db.drCorporealTrack and currentStage == 2 and ((low:find("sacrifica") and low:find("alma")) or low:find("36 segundo") or low:find("corporeidad")) then
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
