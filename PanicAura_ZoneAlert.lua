-- PanicAura - Módulo de Alerta de Zona Peligrosa (Nivel Superior)
-- Muestra una advertencia central con sonido y destellos al entrar a una zona peligrosa
-- NO activa barras de pánico ni botones de acción de emergencia
local addonName = ...
PanicAura = PanicAura or {}
local PA = PanicAura

--------------------------------------------------------------------------------
-- 1. Destello visual en bordes de pantalla para Zona Peligrosa (3 pulsos suaves)
--------------------------------------------------------------------------------
local zoneFlashFrame = CreateFrame("Frame", "PanicAuraZoneFlash", UIParent)
zoneFlashFrame:SetAllPoints(UIParent)
zoneFlashFrame:SetFrameStrata("FULLSCREEN_DIALOG")
zoneFlashFrame:SetAlpha(0)
zoneFlashFrame:Hide()

local flashTextures = {}
local function CreateFlashEdge(parent, p1, p2, orient, size)
    local t = parent:CreateTexture(nil, "BACKGROUND")
    t:SetPoint(p1, parent, p1)
    t:SetPoint(p2, parent, p2)
    if orient == "left" or orient == "right" then
        t:SetWidth(size)
    else
        t:SetHeight(size)
    end
    t:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    t.orient = orient
    table.insert(flashTextures, t)
end

CreateFlashEdge(zoneFlashFrame, "TOPLEFT", "TOPRIGHT", "top", 65)
CreateFlashEdge(zoneFlashFrame, "BOTTOMLEFT", "BOTTOMRIGHT", "bottom", 65)
CreateFlashEdge(zoneFlashFrame, "TOPLEFT", "BOTTOMLEFT", "left", 65)
CreateFlashEdge(zoneFlashFrame, "TOPRIGHT", "BOTTOMRIGHT", "right", 65)

local function SetFlashColor(r, g, b)
    for _, t in ipairs(flashTextures) do
        if t.orient == "top" then
            t:SetGradientAlpha("VERTICAL", r, g, b, 0, r, g, b, 0.85)
        elseif t.orient == "bottom" then
            t:SetGradientAlpha("VERTICAL", r, g, b, 0.85, r, g, b, 0)
        elseif t.orient == "left" then
            t:SetGradientAlpha("HORIZONTAL", r, g, b, 0.85, r, g, b, 0)
        else
            t:SetGradientAlpha("HORIZONTAL", r, g, b, 0, r, g, b, 0.85)
        end
    end
end
SetFlashColor(1.0, 0.45, 0.0) -- Naranja/ámbar por defecto

local flashTimeLeft = 0
local flashTimer = 0
zoneFlashFrame:SetScript("OnUpdate", function(self, elapsed)
    if flashTimeLeft <= 0 then
        self:SetAlpha(0)
        self:Hide()
        return
    end
    flashTimeLeft = flashTimeLeft - elapsed
    flashTimer = flashTimer + elapsed * 5.5
    -- Oscilación de 3 pulsos suaves
    local alpha = ((math.sin(flashTimer) + 1) / 2) * 0.65
    if flashTimeLeft < 0.8 then
        alpha = alpha * (flashTimeLeft / 0.8)
    end
    self:SetAlpha(alpha)
end)

local function TriggerZoneFlash(r, g, b)
    if not PA.db or not PA.db.zoneDangerFlash then return end
    SetFlashColor(r or 1.0, g or 0.45, b or 0.0)
    flashTimeLeft = 3.0 -- dura 3 segundos (aproximadamente 3-4 destellos)
    flashTimer = 0
    zoneFlashFrame:Show()
end

--------------------------------------------------------------------------------
-- 2. Cartel Central de Advertencia de Zona (Banner no invasivo)
--------------------------------------------------------------------------------
local banner = CreateFrame("Button", "PanicAuraZoneBanner", UIParent)
banner:SetSize(450, 78)
banner:SetPoint("TOP", UIParent, "TOP", 0, -185)
banner:SetFrameStrata("FULLSCREEN_DIALOG")
banner:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
banner:SetBackdropColor(0.06, 0.03, 0.01, 0.90)
banner:SetBackdropBorderColor(1.0, 0.5, 0.0, 0.95)
banner:EnableMouse(true)
banner:RegisterForClicks("anyUp")
banner:SetScript("OnClick", function(self)
    self:Hide()
    flashTimeLeft = 0
end)
banner:Hide()
PA.zoneBanner = banner

-- Icono de calavera / peligro
local icon = banner:CreateTexture(nil, "ARTWORK")
icon:SetSize(40, 40)
icon:SetPoint("LEFT", banner, "LEFT", 14, 0)
icon:SetTexture("Interface\\Icons\\Ability_Rogue_FeignDeath")
icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local iconBorder = banner:CreateTexture(nil, "OVERLAY")
iconBorder:SetTexture("Interface\\Buttons\\UI-Quickslot2")
iconBorder:SetPoint("CENTER", icon, "CENTER", 0, -1)
iconBorder:SetSize(64, 64)

-- Título grande
local titleText = banner:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
titleText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 14, 4)
titleText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
titleText:SetTextColor(1.0, 0.80, 0.1, 1)
titleText:SetShadowOffset(1, -1)

-- Subtexto con datos de nivel
local levelText = banner:CreateFontString(nil, "OVERLAY", "GameFontNormal")
levelText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -3)
levelText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
levelText:SetTextColor(1, 1, 1, 1)

-- Nota de pie
local hintText = banner:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
hintText:SetPoint("TOPLEFT", levelText, "BOTTOMLEFT", 0, -3)
hintText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
hintText:SetTextColor(1.0, 0.5, 0.2, 1)

-- Animación de entrada y desaparición automática
local bannerDuration = 0
banner:SetScript("OnUpdate", function(self, elapsed)
    if bannerDuration <= 0 then
        self:Hide()
        return
    end
    bannerDuration = bannerDuration - elapsed
    if bannerDuration < 1.0 then
        self:SetAlpha(bannerDuration / 1.0)
    else
        self:SetAlpha(1.0)
    end
end)

--------------------------------------------------------------------------------
-- 3. Función de disparo de alerta de zona
--------------------------------------------------------------------------------
function PA:ShowZoneDangerAlert(zoneName, minLvl, maxLvl, playerLevel, levelDiff)
    if not PA.db or not PA.db.zoneDangerAlert then return end

    local diff = levelDiff or (minLvl - playerLevel)
    local isExtreme = diff >= 4

    -- Colores: Naranja para 2-3 niveles por encima, Rojo intenso para 4+ niveles
    local r, g, b = 1.0, 0.50, 0.0
    if isExtreme then
        r, g, b = 1.0, 0.15, 0.15
        banner:SetBackdropColor(0.12, 0.02, 0.02, 0.92)
        banner:SetBackdropBorderColor(1.0, 0.2, 0.2, 0.95)
        icon:SetTexture("Interface\\Icons\\INV_Misc_Bone_Skull_02")
    else
        banner:SetBackdropColor(0.08, 0.04, 0.01, 0.90)
        banner:SetBackdropBorderColor(1.0, 0.55, 0.1, 0.95)
        icon:SetTexture("Interface\\Icons\\Ability_Rogue_FeignDeath")
    end

    titleText:SetText(string.format("¡ZONA PELIGROSA: %s!", (zoneName or "DESCONOCIDA"):upper()))
    titleText:SetTextColor(r, g, b, 1)

    levelText:SetText(string.format("Enemigos Nv. %d-%d  ·  Tu nivel: %d (|cffff2222+%d niveles|r)", minLvl, maxLvl, playerLevel, diff))
    hintText:SetText(isExtreme and "¡EXTREMO PELIGRO! Los enemigos te detectan desde muy lejos." or "Peligro en Hardcore · Retrocede o avanza con extrema precaución.")

    bannerDuration = 4.8
    banner:SetAlpha(1.0)
    banner:Show()

    -- Sonido de advertencia con control de volumen
    if PA.db.zoneDangerSound then
        local sound = PA.db.zoneDangerSoundFile or "Sound\\Interface\\RaidWarning.wav"
        if PA.PlayAlertSound then
            PA:PlayAlertSound(sound, true, 3.5)
        else
            PlaySoundFile(sound)
        end
    end

    -- Destellos en los bordes
    TriggerZoneFlash(r, g, b)
end

--------------------------------------------------------------------------------
-- 4. Verificación automática de la zona actual
--------------------------------------------------------------------------------
local lastCheckedZone = nil
local lastAlertTime = 0

function PA:CheckZoneDanger(force)
    if not PA.db or not PA.db.zoneDangerAlert then return end

    local currentZone = GetRealZoneText()
    if not currentZone or currentZone == "" then
        currentZone = GetZoneText()
    end
    if not currentZone or currentZone == "" then return end

    local now = GetTime()
    -- Evitar re-disparar si no cambió de zona y no es forzado
    if not force and currentZone == lastCheckedZone and (now - lastAlertTime < 10) then
        return
    end
    lastCheckedZone = currentZone

    local data = PA:GetZoneLevelData(currentZone)
    if not data then
        -- Intentar con el nombre interno del mapa
        SetMapToCurrentZone()
        local mapInfo = GetMapInfo()
        if mapInfo then
            data = PA:GetZoneLevelData(mapInfo)
        end
    end

    if not data or data.safe then
        PA.lastDangerZone = nil
        return
    end

    local playerLevel = UnitLevel("player")
    if not playerLevel or playerLevel <= 0 then return end

    local diffThreshold = PA.db.zoneDangerDiff or 1
    local levelDiff = data.min - playerLevel

    -- Regla del usuario: si supera en más de 1 nivel (ej: nivel 15 entra a zona mín 17 -> diff = 2 > 1 -> ALERTA)
    if levelDiff > diffThreshold then
        if not force and currentZone == PA.lastDangerZone then
            return -- Ya alertamos para esta zona
        end
        PA.lastDangerZone = currentZone
        lastAlertTime = now
        PA:ShowZoneDangerAlert(currentZone, data.min, data.max, playerLevel, levelDiff)
    else
        PA.lastDangerZone = nil
    end
end

--------------------------------------------------------------------------------
-- 5. Prueba Manual (/pa testzone o /pa tz)
--------------------------------------------------------------------------------
function PA:TestZoneAlert()
    local pLevel = UnitLevel("player")
    if not pLevel or pLevel <= 0 then pLevel = 15 end
    local sampleZone = "Bosque del Ocaso"
    local sampleMin = pLevel + 3
    local sampleMax = pLevel + 12
    PA:ShowZoneDangerAlert(sampleZone, sampleMin, sampleMax, pLevel, 3)
    DEFAULT_CHAT_FRAME:AddMessage("|cffff8800PanicAura:|r Probando Alerta de Zona Peligrosa (simulando " .. sampleZone .. " para tu nivel).")
end

--------------------------------------------------------------------------------
-- 6. Escucha de Eventos de Cambio de Zona
--------------------------------------------------------------------------------
local zoneWatcher = CreateFrame("Frame")
zoneWatcher:RegisterEvent("ZONE_CHANGED_NEW_AREA")
zoneWatcher:RegisterEvent("ZONE_CHANGED")
zoneWatcher:RegisterEvent("ZONE_CHANGED_INDOORS")
zoneWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
zoneWatcher:RegisterEvent("PLAYER_LEVEL_UP")

local zoneTimer = 0
local pendingCheck = false

zoneWatcher:SetScript("OnEvent", function(self, event, ...)
    if event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
        -- Esperar un instante para que el cliente cargue el nombre de la zona completo
        pendingCheck = true
        zoneTimer = 0.6
    elseif event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" then
        pendingCheck = true
        zoneTimer = 1.0
    elseif event == "PLAYER_LEVEL_UP" then
        pendingCheck = true
        zoneTimer = 0.5
    end
end)

zoneWatcher:SetScript("OnUpdate", function(self, elapsed)
    if pendingCheck then
        zoneTimer = zoneTimer - elapsed
        if zoneTimer <= 0 then
            pendingCheck = false
            PA:CheckZoneDanger(false)
        end
    end
end)
