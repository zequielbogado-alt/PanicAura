-- PanicAura - Core Logic & Visuals for WoW 3.3.5a
local addonName = ...
PanicAura = PanicAura or {}
local PA = PanicAura

local classDefaults = {
    ["HUNTER"] = {
        [1] = { name = "Poción de curación inferior", enabled = true },
        [2] = { name = "Fingir muerte", enabled = true },
        [3] = { name = "Aspecto del mono", enabled = true },
        [4] = { name = "Golpe de alas", enabled = true },
        [5] = { name = "Disparo de conmoción", enabled = true },
    },
    ["WARLOCK"] = {
        [1] = { name = "Piedra de salud", enabled = true },
        [2] = { name = "Sacrificio", enabled = true },          -- Escudo del Abisario
        [3] = { name = "Miedo", enabled = true },
        [4] = { name = "Espiral de la muerte", enabled = true },
        [5] = { name = "Poción de curación inferior", enabled = true },
    },
    ["MAGE"] = {
        [1] = { name = "Bloque de hielo", enabled = true },
        [2] = { name = "Traslación", enabled = true },
        [3] = { name = "Barrera de hielo", enabled = true },
        [4] = { name = "Nova de escarcha", enabled = true },
        [5] = { name = "Poción de curación inferior", enabled = true },
    },
    ["PALADIN"] = {
        [1] = { name = "Escudo divino", enabled = true },
        [2] = { name = "Protección divina", enabled = true },
        [3] = { name = "Imposición de manos", enabled = true },
        [4] = { name = "Martillo de justicia", enabled = true },
        [5] = { name = "Poción de curación inferior", enabled = true },
    },
    ["PRIEST"] = {
        [1] = { name = "Palabra de poder: escudo", enabled = true },
        [2] = { name = "Dispersión", enabled = true },
        [3] = { name = "Alarido psíquico", enabled = true },
        [4] = { name = "Supresión de dolor", enabled = true },
        [5] = { name = "Poción de curación inferior", enabled = true },
    },
    ["ROGUE"] = {
        [1] = { name = "Esfumarse", enabled = true },
        [2] = { name = "Evasión", enabled = true },
        [3] = { name = "Capa de las Sombras", enabled = true },
        [4] = { name = "Gouge", enabled = true },
        [5] = { name = "Poción de curación inferior", enabled = true },
    },
    ["DRUID"] = {
        [1] = { name = "Piel de corteza", enabled = true },
        [2] = { name = "Forma de oso", enabled = true },
        [3] = { name = "Carrera", enabled = true },
        [4] = { name = "Regeneración frenética", enabled = true },
        [5] = { name = "Poción de curación inferior", enabled = true },
    },
    ["WARRIOR"] = {
        [1] = { name = "Muro de escudo", enabled = true },
        [2] = { name = "Última carga", enabled = true },
        [3] = { name = "Ira rabiosa", enabled = true },
        [4] = { name = "Desarmar", enabled = true },
        [5] = { name = "Poción de curación inferior", enabled = true },
    },
    ["SHAMAN"] = {
        [1] = { name = "Ira del chamán", enabled = true },
        [2] = { name = "Tótem Garra de piedra", enabled = true },
        [3] = { name = "Tótem Nexo Terrestre", enabled = true },
        [4] = { name = "Maestría elemental", enabled = true },
        [5] = { name = "Poción de curación inferior", enabled = true },
    },
    ["DEATHKNIGHT"] = {
        [1] = { name = "Entereza ligada al hielo", enabled = true },
        [2] = { name = "Caparazón antimagia", enabled = true },
        [3] = { name = "Pacto de la Muerte", enabled = true },
        [4] = { name = "Transfusión de sangre", enabled = true },
        [5] = { name = "Poción de curación inferior", enabled = true },
    }
}

local function GetClassDefaults()
    local _, class = UnitClass("player")
    return classDefaults[class] or classDefaults["HUNTER"]
end

local defaultDB = {
    enabled = true,
    hpThreshold = 40,          -- Alerta ROJA (crítica): en combate con <= 40% de vida
    warnEnabled = true,        -- Alerta AMARILLA (aviso) previa a la crítica
    warnThreshold = 70,        -- Aviso amarillo: en combate con <= 70% de vida
    triggerOnPetDeath = true,   -- Aviso si la mascota muere en combate
    soundAlert = true,         -- Sonido en alerta roja
    soundWarn = false,         -- Sonido suave en alerta amarilla/naranja
    soundFile = "Sound\\Interface\\RaidWarning.wav",
    iconSize = 44,
    hudScale = 1.0,
    showKeybinds = true,
    showBanner = true,         -- Cartel superior
    showScreenFlash = true,
    flashWarn = true,          -- Destello (suave) también en amarillo/naranja
    flashIntensity = 0.6,
    rangeWarn = true,          -- Cazador: aviso de rango de seguridad (zona muerta / melé)
    threatCount = true,        -- Contador de enemigos que te tienen como objetivo
    threatAlert = true,        -- Aviso amarillo si hay N o más atacantes
    threatAlertMin = 3,
    -- Modo Die & Rise (TuWoW Hardcore)
    drEnabled = true,          -- Integración con estados Normal / Putrefacto / Esquelético
    drShowWidget = true,       -- Mostrar indicador compacto de estado, almas y corporeidad
    drHideWhenAlive = false,   -- Ocultar indicador mientras esté Vivo (mostrar solo en Putrefacto/Esquelético)
    drWidgetX = 0,
    drWidgetY = -175,
    drStageBoost = true,       -- Subir umbrales de vida (+10% en Putrefacto, +15% en Esquelético)
    drNauseaWarn = true,       -- Avisar náuseas / vómito al comer en estado Putrefacto
    drBlockPotions = true,     -- Marcar pociones como bloqueadas en estado Esquelético
    drCorporealTrack = true,   -- Cronómetro de 36 s al sacrificar 1 alma para comer/beber
    drBigHitAlert = true,      -- Alerta roja instantánea ante un golpe fuerte
    drBigHitPct = 35,          -- % de vida máxima en un solo golpe para disparar alerta
    drStage = 0,               -- Último estado conocido (0=Normal, 1=Putrefacto, 2=Esquelético)
    drSouls = 0,
    drGoal = 300,
    deathLog = {},             -- Historial de muertes del personaje
    -- Alerta de Zona Peligrosa (Nivel Superior)
    zoneDangerAlert = true,    -- Avisar al entrar a una zona con enemigos superiores en nivel
    zoneDangerDiff = 1,        -- Diferencia mínima de nivel (1 = mínimo nivel de zona >= player + 2)
    zoneDangerSound = true,    -- Reproducir sonido al entrar a zona peligrosa
    zoneDangerSoundFile = "Sound\\Interface\\RaidWarning.wav",
    zoneDangerFlash = true,    -- Destellos suaves en los bordes de la pantalla
    locked = false,
    frameX = 0,
    frameY = -120,
    minimap = {
        hide = false,
        minimapPos = 195, -- Ubicación por defecto en el borde del minimapa
    },
    slots = nil -- Se asigna dinámicamente según la clase del personaje
}

local function InitDB()
    if not PanicAuraDB then
        PanicAuraDB = {}
    end
    for k, v in pairs(defaultDB) do
        if PanicAuraDB[k] == nil then
            if k == "slots" then
                PanicAuraDB.slots = GetClassDefaults()
            elseif type(v) == "table" then
                PanicAuraDB[k] = {}
                for subK, subV in pairs(v) do
                    if type(subV) == "table" then
                        PanicAuraDB[k][subK] = {}
                        for sK, sV in pairs(subV) do
                            PanicAuraDB[k][subK][sK] = sV
                        end
                    else
                        PanicAuraDB[k][subK] = subV
                    end
                end
            else
                PanicAuraDB[k] = v
            end
        end
    end
    if not PanicAuraDB.slots or #PanicAuraDB.slots == 0 then
        PanicAuraDB.slots = GetClassDefaults()
    end
    PA.db = PanicAuraDB
end

--------------------------------------------------------------------------------
-- 0. Botón del Minimapa (Compatible con ForeverUI y Minimapa Clásico)
--------------------------------------------------------------------------------
local function CreateMinimapButton()
    local btn = CreateFrame("Button", "PanicAuraMinimapButton", Minimap)
    btn:SetSize(31, 31)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(9)
    btn:RegisterForClicks("anyUp")
    btn:RegisterForDrag("LeftButton")
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(20, 20)
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetPoint("TOPLEFT", 6, -5)

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetTexture("Interface\\Icons\\Ability_Hunter_RunningShot") -- Icono de alerta / huida
    icon:SetPoint("CENTER", 0, 0)
    btn.icon = icon

    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("TOPLEFT", 0, 0)

    local isDragging = false
    local function UpdateMinimapPos(pos)
        local angle = math.rad(pos or 195)
        local mapScale = (ForeverUI and ForeverUI.Minimap and Minimap and Minimap:GetScale()) or 1
        if mapScale ~= 1 then
            btn:SetScale(1 / mapScale)
        end
        local radiusOffset = (mapScale ~= 1) and 1 or 2
        local w = (Minimap:GetWidth() * mapScale / 2) + radiusOffset
        local h = (Minimap:GetHeight() * mapScale / 2) + radiusOffset
        local x = math.cos(angle) * w
        local y = math.sin(angle) * h
        btn:ClearAllPoints()
        btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end
    PA.UpdateMinimapPos = UpdateMinimapPos

    btn:SetScript("OnDragStart", function(self)
        isDragging = true
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            px, py = px / scale, py / scale
            local pos = math.deg(math.atan2(py - my, px - mx)) % 360
            PA.db.minimap.minimapPos = pos
            UpdateMinimapPos(pos)
        end)
    end)

    btn:SetScript("OnDragStop", function(self)
        isDragging = false
        self:SetScript("OnUpdate", nil)
    end)

    btn:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            if IsShiftKeyDown() then
                -- Shift + Click Derecho: Modo Configuración de Barra (sin alertas ni flashes)
                PA.setupMode = not PA.setupMode
                if PA.setupMode then
                    PA.testMode = true
                    PA.mainFrame:EnableMouse(true)
                    PA:StartPanic("MODO CONFIGURACIÓN: Arrastra aquí poderes o pociones")
                    DEFAULT_CHAT_FRAME:AddMessage("|cffff2222PanicAura:|r Barra visible en modo configuración. Arrastra tus habilidades/pociones o muévela con click izquierdo.")
                else
                    PA.testMode = false
                    PA.mainFrame:EnableMouse(false)
                    PA:StopPanic()
                    DEFAULT_CHAT_FRAME:AddMessage("|cffff2222PanicAura:|r Modo configuración cerrado.")
                end
            else
                -- Click Derecho Normal: Modo Prueba completo
                PA.setupMode = false
                PA.testLevel = 3
                PA.testMode = not PA.testMode
                if PA.testMode then
                    PA.mainFrame:EnableMouse(true)
                    PA:StartPanic("¡MODO PRUEBA ACTIVO!")
                else
                    PA.mainFrame:EnableMouse(false)
                    PA:StopPanic()
                end
            end
        else
            if PanicAuraConfigFrame:IsShown() then
                PanicAuraConfigFrame:Hide()
            else
                PanicAuraConfigFrame:Show()
            end
        end
    end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cffff2222PanicAura|r", 1, 1, 1)
        GameTooltip:AddLine("|cff66ccffClick Izquierdo:|r Abrir panel de opciones", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("|cff66ccffClick Derecho:|r Probar Alerta completa (con sonido y cartel)", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("|cffffff00Shift + Click Derecho:|r Configurar Barra (solo muestra los iconos)", 1, 1, 0.2)
        GameTooltip:AddLine("|cff66ccffArrastrar:|r Mover este icono en el minimapa", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    PA.minimapBtn = btn
    UpdateMinimapPos(PA.db.minimap.minimapPos or 195)
end

--------------------------------------------------------------------------------
-- 1. Viñeta / Destello en Bordes de Pantalla (Screen Flash)
--------------------------------------------------------------------------------
local flashFrame = CreateFrame("Frame", "PanicAuraScreenFlash", UIParent)
flashFrame:SetAllPoints(UIParent)
flashFrame:SetFrameStrata("FULLSCREEN_DIALOG")
flashFrame:SetAlpha(0)
flashFrame:Hide()

-- Niveles de alerta: 1 = aviso (amarillo), 2 = rango de seguridad (naranja), 3 = crítica (roja)
local LEVEL_COLORS = {
    [1] = { 1.00, 0.82, 0.05 },
    [2] = { 1.00, 0.50, 0.00 },
    [3] = { 1.00, 0.10, 0.10 },
}
PA.LEVEL_COLORS = LEVEL_COLORS

local edgeTextures = {}

local function CreateEdgeTextures(parent)
    local function mk(p1, p2, p3, isH, size)
        local t = parent:CreateTexture(nil, "BACKGROUND")
        t:SetPoint(p1, parent, p1)
        t:SetPoint(p2, parent, p2)
        if isH then t:SetWidth(size) else t:SetHeight(size) end
        t:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
        t.orient = p3
        table.insert(edgeTextures, t)
    end
    mk("TOPLEFT", "TOPRIGHT", "top", false, 60)
    mk("BOTTOMLEFT", "BOTTOMRIGHT", "bottom", false, 60)
    mk("TOPLEFT", "BOTTOMLEFT", "left", true, 60)
    mk("TOPRIGHT", "BOTTOMRIGHT", "right", true, 60)
end
CreateEdgeTextures(flashFrame)

local function SetEdgeColor(r, g, b)
    for _, t in ipairs(edgeTextures) do
        -- Gradiente: opaco en el borde de pantalla, transparente hacia el centro
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
SetEdgeColor(unpack(LEVEL_COLORS[3]))

local flashTimer = 0
local flashAlpha = 0
flashFrame:SetScript("OnUpdate", function(self, elapsed)
    if not PA.inPanic and not PA.testMode then
        self:SetAlpha(0)
        self:Hide()
        return
    end

    local maxAlpha = PA.db and PA.db.flashIntensity or 0.6
    local level = PA.level or 3
    local speed = (level == 3) and 3.5 or ((level == 2) and 2.8 or 2.0)
    if level < 3 then maxAlpha = maxAlpha * 0.55 end -- amarillo/naranja: más sutiles
    flashTimer = flashTimer + elapsed * speed
    flashAlpha = (math.sin(flashTimer) + 1) / 2 * maxAlpha
    self:SetAlpha(flashAlpha)
end)

--------------------------------------------------------------------------------
-- 2. Marco Principal del HUD (Iconos + Teclas)
--------------------------------------------------------------------------------
local mainFrame = CreateFrame("Frame", "PanicAuraMainFrame", UIParent)
mainFrame:SetSize(250, 60)
mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -120)
mainFrame:SetFrameStrata("HIGH")
mainFrame:SetMovable(true)
mainFrame:EnableMouse(false)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnDragStart", function(self)
    if not PA.db.locked then self:StartMoving() end
end)
mainFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, _, x, y = self:GetPoint()
    PA.db.frameX = x
    PA.db.frameY = y
end)
mainFrame:Hide()
PA.mainFrame = mainFrame

-- Texto de estado sobre la barra (solo modo configuración / cartel desactivado)
local statusText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
statusText:SetPoint("BOTTOM", mainFrame, "TOP", 0, 8)
statusText:SetTextColor(1, 0.82, 0.05, 1)
statusText:SetShadowOffset(1, -1)
PA.statusText = statusText

--------------------------------------------------------------------------------
-- 2.0 Contador de Atacantes (Threat / Aggro Count) junto a la barra
--------------------------------------------------------------------------------
local threatFrame = CreateFrame("Frame", "PanicAuraThreatFrame", mainFrame)
threatFrame:SetSize(54, 54)
threatFrame:SetPoint("LEFT", mainFrame, "RIGHT", 10, 0)
threatFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 14,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
threatFrame:SetBackdropColor(0.05, 0, 0, 0.75)
threatFrame:SetBackdropBorderColor(1, 0.1, 0.1, 0.9)
threatFrame:Hide()

local threatNumber = threatFrame:CreateFontString(nil, "OVERLAY")
threatNumber:SetFont("Fonts\\FRIZQT__.TTF", 28, "OUTLINE")
threatNumber:SetPoint("CENTER", threatFrame, "CENTER", 0, 4)
threatNumber:SetTextColor(1, 0.1, 0.1, 1)

local threatLabel = threatFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
threatLabel:SetPoint("BOTTOM", threatFrame, "BOTTOM", 0, 5)
threatLabel:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
threatLabel:SetText("ATACANTES")
threatLabel:SetTextColor(1, 0.7, 0.7, 1)
PA.threatFrame, PA.threatNumber = threatFrame, threatNumber

--------------------------------------------------------------------------------
-- 2.1 Cartel de Alerta en el Centro Superior de la Pantalla
--------------------------------------------------------------------------------
local bossBanner = CreateFrame("Frame", "PanicAuraBossBanner", UIParent)
bossBanner:SetSize(380, 58)
bossBanner:SetPoint("TOP", UIParent, "TOP", 0, -140)
bossBanner:SetFrameStrata("FULLSCREEN_DIALOG")
bossBanner:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 14,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
bossBanner:SetBackdropColor(0.05, 0.03, 0, 0.78)
bossBanner:Hide()

local bannerText = bossBanner:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
bannerText:SetPoint("TOP", bossBanner, "TOP", 0, -10)
bannerText:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
bannerText:SetTextColor(1, 0.82, 0.05, 1)
PA.bannerText = bannerText

local bannerSubtext = bossBanner:CreateFontString(nil, "OVERLAY", "GameFontNormal")
bannerSubtext:SetPoint("TOP", bannerText, "BOTTOM", 0, -4)
bannerSubtext:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
bannerSubtext:SetTextColor(1, 1, 1, 1)
PA.bannerSubtext = bannerSubtext

local bannerTimer = 0
bossBanner:SetScript("OnUpdate", function(self, elapsed)
    if not PA.inPanic and not PA.testMode then
        self:Hide()
        return
    end
    if (PA.level or 3) < 3 then
        self:SetScale(1) -- amarillo / naranja: sin pulso, discreto
        return
    end
    bannerTimer = bannerTimer + elapsed * 6
    self:SetScale(1 + (math.sin(bannerTimer) * 0.04))
end)
PA.bossBanner = bossBanner

--------------------------------------------------------------------------------
-- 3. Generación de Ranuras de Habilidades / Items (Slots)
--------------------------------------------------------------------------------
local slotFrames = {}

local function FormatKeybindText(bind)
    if not bind or bind == "" then return "" end
    bind = bind:upper()
    bind = bind:gsub("BUTTON", "M")
    bind = bind:gsub("MOUSEWHEELUP", "MWU")
    bind = bind:gsub("MOUSEWHEELDOWN", "MWD")
    bind = bind:gsub("NUMPAD", "N")
    bind = bind:gsub("NUMPADPLUS", "N+")
    bind = bind:gsub("NUMPADMINUS", "N-")
    bind = bind:gsub("SHIFT%-", "S-")
    bind = bind:gsub("CTRL%-", "C-")
    bind = bind:gsub("ALT%-", "A-")
    return bind
end

local function FindKeybindForAction(targetName)
    if not targetName or targetName == "" then return nil end
    local lowerTarget = targetName:lower():trim()

    -- 1) Buscar en barras de acción estándares (1..120)
    for slot = 1, 120 do
        local actionType, id, subType = GetActionInfo(slot)
        local match = false
        if actionType == "spell" then
            local spellName = GetSpellInfo(id)
            if spellName and spellName:lower() == lowerTarget then match = true end
        elseif actionType == "item" then
            local itemName = GetItemInfo(id)
            if itemName and itemName:lower() == lowerTarget then match = true end
        elseif actionType == "macro" then
            local macroName = GetMacroInfo(id)
            if macroName and macroName:lower() == lowerTarget then match = true end
        end

        if match then
            -- Mapear action slot a su binding oficial de Blizzard
            local bindCommand
            if slot <= 12 then
                bindCommand = "ACTIONBUTTON" .. slot
            elseif slot >= 13 and slot <= 24 then
                bindCommand = "ACTIONBUTTON" .. (slot - 12) -- Segunda página
            elseif slot >= 25 and slot <= 36 then
                bindCommand = "MULTIACTIONBAR3BUTTON" .. (slot - 24) -- Barra derecha
            elseif slot >= 37 and slot <= 48 then
                bindCommand = "MULTIACTIONBAR4BUTTON" .. (slot - 36) -- Barra derecha 2
            elseif slot >= 49 and slot <= 60 then
                bindCommand = "MULTIACTIONBAR2BUTTON" .. (slot - 48) -- Abajo a la derecha
            elseif slot >= 61 and slot <= 72 then
                bindCommand = "MULTIACTIONBAR1BUTTON" .. (slot - 60) -- Abajo a la izquierda
            end

            if bindCommand then
                local k1, k2 = GetBindingKey(bindCommand)
                if k1 then return FormatKeybindText(k1) end
                if k2 then return FormatKeybindText(k2) end
            end
        end
    end

    -- 2) Buscar keybind directo si existe una macro con ese nombre
    local k1, k2 = GetBindingKey("MACRO " .. targetName)
    if k1 then return FormatKeybindText(k1) end
    if k2 then return FormatKeybindText(k2) end

    -- 3) Buscar keybind directo si existe un hechizo en el Spellbook
    local kSpell = GetBindingKey("SPELL " .. targetName)
    if kSpell then return FormatKeybindText(kSpell) end

    return nil
end

local function GetActionInfoByName(targetName)
    if not targetName or targetName == "" then return nil end
    local lowerTarget = targetName:lower():trim()

    -- Comprobar si es un hechizo conocido en el libro de hechizos
    local spellTexture
    for tab = 1, GetNumSpellTabs() do
        local _, _, offset, numSpells = GetSpellTabInfo(tab)
        for s = offset + 1, offset + numSpells do
            local spellName = GetSpellName(s, BOOKTYPE_SPELL)
            if spellName and spellName:lower() == lowerTarget then
                spellTexture = GetSpellTexture(s, BOOKTYPE_SPELL)
                local start, duration, enabled = GetSpellCooldown(s, BOOKTYPE_SPELL)
                local isUsable, notEnoughMana = IsUsableSpell(s, BOOKTYPE_SPELL)
                return {
                    type = "spell",
                    name = spellName,
                    texture = spellTexture,
                    cooldownStart = start or 0,
                    cooldownDuration = duration or 0,
                    isUsable = (isUsable and not notEnoughMana and enabled == 1)
                }
            end
        end
    end

    -- Comprobar si es un ítem en inventario / bolsas
    local itemId, itemName, _, _, _, _, _, _, _, itemTexture = GetItemInfo(targetName)
    if itemName or tonumber(targetName) then
        local count = GetItemCount(targetName)
        local start, duration, enable = GetItemCooldown(targetName)
        local texture = itemTexture or select(10, GetItemInfo(targetName)) or "Interface\\Icons\\INV_Misc_QuestionMark"
        return {
            type = "item",
            name = itemName or targetName,
            texture = texture,
            count = count,
            cooldownStart = start or 0,
            cooldownDuration = duration or 0,
            isUsable = (count and count > 0)
        }
    end

    return nil
end

local function CreateSlotButton(index)
    local btn = CreateFrame("Button", "PanicAuraSlot" .. index, mainFrame, "SecureActionButtonTemplate")
    btn:SetSize(44, 44)
    btn.slotIndex = index
    btn:RegisterForClicks("AnyUp", "AnyDown")
    btn:SetAttribute("type", "macro")

    -- Drag & Drop directo sobre la ranura
    btn:SetScript("OnReceiveDrag", function(self)
        if InCombatLockdown() then return end
        local infoType, info1, info2 = GetCursorInfo()
        local nameToSet
        if infoType == "spell" then
            nameToSet = GetSpellName(info1, BOOKTYPE_SPELL)
        elseif infoType == "item" then
            nameToSet = GetItemInfo(info1)
        elseif infoType == "macro" then
            nameToSet = GetMacroInfo(info1)
        end
        if nameToSet then
            PA.db.slots[self.slotIndex].name = nameToSet
            PA.db.slots[self.slotIndex].enabled = true
            ClearCursor()
            PA:UpdateLayout()
            DEFAULT_CHAT_FRAME:AddMessage("|cffff2222PanicAura:|r Ranura " .. self.slotIndex .. " configurada con: |cffffff00" .. nameToSet .. "|r")
        end
    end)

    -- Tooltip al pasar el mouse
    btn:SetScript("OnEnter", function(self)
        local data = PA.db.slots[self.slotIndex]
        if data and data.name and data.name ~= "" then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(data.name, 1, 1, 1)
            local keybind = FindKeybindForAction(data.name)
            if keybind and keybind ~= "" then
                GameTooltip:AddLine("Tecla: |cffffff00" .. keybind .. "|r", 0.8, 0.8, 0.8)
            end
            GameTooltip:AddLine("|cff66ccffClick:|r Lanzar / Usar", 0.2, 1, 0.2)
            GameTooltip:AddLine("|cffaaaaaa(Arrastra un hechizo o item aqui para cambiarlo)|r", 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Textura del Icono
    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetAllPoints(btn)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn.icon = icon

    -- Borde estilizado
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    border:SetPoint("CENTER", btn, "CENTER", 0, -1)
    border:SetSize(70, 70)
    btn.border = border

    -- Glow pulsante cuando está listo para salvarte
    local glow = btn:CreateTexture(nil, "OVERLAY")
    glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    glow:SetBlendMode("ADD")
    glow:SetPoint("CENTER", btn, "CENTER", 0, 0)
    glow:SetSize(68, 68)
    glow:SetVertexColor(0.2, 1, 0.2, 0.8)
    glow:Hide()
    btn.glow = glow

    -- Cooldown frame nativo de Blizzard
    local cd = CreateFrame("Cooldown", "PanicAuraSlotCD" .. index, btn, "CooldownFrameTemplate")
    cd:SetAllPoints(btn)
    btn.cooldown = cd

    -- Texto del Keybind (Tecla grande en esquina superior o centro)
    local keybind = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    keybind:SetPoint("BOTTOM", btn, "BOTTOM", 0, 2)
    keybind:SetTextColor(1, 1, 0, 1)
    keybind:SetShadowOffset(1, -1)
    keybind:SetShadowColor(0, 0, 0, 1)
    btn.keybind = keybind

    -- Contador de acumulaciones / cantidad de pociones
    local count = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    count:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -2, -2)
    count:SetShadowOffset(1, -1)
    btn.count = count

    -- Marca de bloqueado (ej: pociones en estado Esquelético)
    local blocked = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    blocked:SetPoint("CENTER", btn, "CENTER", 0, 0)
    blocked:SetFont("Fonts\\FRIZQT__.TTF", 22, "THICKOUTLINE")
    blocked:SetTextColor(1, 0.15, 0.15, 0.95)
    blocked:SetText("X")
    blocked:Hide()
    btn.blocked = blocked

    return btn
end

function PA:UpdateLayout()
    local size = PA.db and PA.db.iconSize or 44
    local count = 0
    local visibleSlots = {}

    for i = 1, 5 do
        local slotData = PA.db.slots[i]
        if not slotFrames[i] then
            slotFrames[i] = CreateSlotButton(i)
        end
        local f = slotFrames[i]
        f:SetSize(size, size)
        f.border:SetSize(size * 1.6, size * 1.6)
        f.glow:SetSize(size * 1.55, size * 1.55)

        if slotData and slotData.enabled and slotData.name and slotData.name ~= "" then
            if not InCombatLockdown() then
                f:SetAttribute("type", "macro")
                f:SetAttribute("macrotext", "/use " .. slotData.name)
            end
            table.insert(visibleSlots, f)
            count = count + 1
        else
            f:Hide()
        end
    end

    local spacing = 6
    local totalWidth = count * size + (count - 1) * spacing
    mainFrame:SetSize(math.max(totalWidth, 100), size)

    local startX = -totalWidth / 2 + size / 2
    for idx, f in ipairs(visibleSlots) do
        f:ClearAllPoints()
        f:SetPoint("CENTER", mainFrame, "CENTER", startX + (idx - 1) * (size + spacing), 0)
        f:Show()
    end
end

--------------------------------------------------------------------------------
-- 4. Actualización en Tiempo Real de Habilidades y Cooldowns
--------------------------------------------------------------------------------
local function IsBlockedInSkeleton(name, actionType)
    if not PA.db or not PA.db.drEnabled or not PA.db.drBlockPotions then return false end
    if (PA.drStage or 0) ~= 2 then return false end
    -- Si tiene corporeidad provisoria activa (36 s), sí puede comer/beber
    if PA.corporealEnd and GetTime() < PA.corporealEnd then return false end
    if not name then return false end
    local low = name:lower()
    if actionType == "item" then
        if low:find("poci") or low:find("potion") or low:find("elixir") or low:find("frasco") then
            return true
        end
    end
    if low:find("poci") or low:find("comer") or low:find("beber") then
        return true
    end
    return false
end

local pulseTimer = 0
local function UpdateSlots()
    local size = PA.db and PA.db.iconSize or 44
    pulseTimer = pulseTimer + 0.05
    local pulseAlpha = (math.sin(pulseTimer * 5) + 1) / 2 * 0.7 + 0.3

    for i = 1, 5 do
        local f = slotFrames[i]
        local data = PA.db.slots[i]
        if f and data and data.enabled and data.name and data.name ~= "" then
            local info = GetActionInfoByName(data.name)
            local keybind = FindKeybindForAction(data.name)

            if info then
                f.icon:SetTexture(info.texture or "Interface\\Icons\\INV_Misc_QuestionMark")
                local isBlocked = IsBlockedInSkeleton(info.name or data.name, info.type)
                
                -- Cantidad de ítems (si es poción)
                if info.count and info.count > 1 then
                    f.count:SetText(info.count)
                    f.count:Show()
                else
                    f.count:Hide()
                end

                if isBlocked then
                    f.cooldown:Hide()
                    f.icon:SetVertexColor(0.4, 0.1, 0.1)
                    f.glow:Hide()
                    if f.blocked then f.blocked:Show() end
                else
                    if f.blocked then f.blocked:Hide() end
                    -- Cooldown
                    if info.cooldownDuration and info.cooldownDuration > 1.5 then
                        CooldownFrame_SetTimer(f.cooldown, info.cooldownStart, info.cooldownDuration, 1)
                        f.icon:SetVertexColor(0.35, 0.35, 0.35)
                        f.glow:Hide()
                    else
                        f.cooldown:Hide()
                        if info.isUsable then
                            f.icon:SetVertexColor(1, 1, 1)
                            f.glow:SetAlpha(pulseAlpha)
                            f.glow:Show()
                        else
                            f.icon:SetVertexColor(0.5, 0.5, 0.5)
                            f.glow:Hide()
                        end
                    end
                end
            else
                f.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                f.icon:SetVertexColor(0.5, 0.5, 0.5)
                f.glow:Hide()
                f.cooldown:Hide()
                f.count:Hide()
                if f.blocked then f.blocked:Hide() end
            end

            -- Mostrar keybind
            if PA.db.showKeybinds and keybind and keybind ~= "" then
                f.keybind:SetText(keybind)
                f.keybind:Show()
            else
                f.keybind:Hide()
            end
        end
    end
end

--------------------------------------------------------------------------------
-- 4.5 Sistema Die & Rise (Estados, Contador de Almas, Náuseas y Corporeidad)
--------------------------------------------------------------------------------
local SOUL_SPELL_ID = 900114
local SOUL_PREFIX = "TuWoWSouls"

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

drWidget:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    local st = PA.drStage or 0
    if st == 0 then
        GameTooltip:AddLine("Estado Die & Rise: |cff22ff22Vivo (Normal)|r", 1, 1, 1)
        GameTooltip:AddLine("Tenés tus vidas intactas. Si morís pasarás a estado Putrefacto.", 0.8, 0.8, 0.8, true)
    elseif st == 1 then
        GameTooltip:AddLine("Estado Die & Rise: |cff88ff22Putrefacto|r", 1, 1, 1)
        GameTooltip:AddLine("Al comer podés sentir náuseas y vomitar. ¡Si morís pasarás a Esquelético!", 1, 0.8, 0.2, true)
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
PA.drWidget = drWidget

local function ScanPlayerAurasForDR()
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
    if foundStage then
        PA.drStage = foundStage
        if PA.db then PA.db.drStage = foundStage end
    end
    if foundSouls and not PA.drSoulsFresh then
        PA.drSouls = foundSouls
        if PA.db then PA.db.drSouls = foundSouls end
    end
end

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
        if nauseaRem > 0 then
            drText:SetText("|cffff8000PUTREFACTO · ¡NÁUSEAS ACTIVAS!|r")
            drWidget:SetBackdropBorderColor(1.0, 0.5, 0.0, 0.95)
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
-- 5. Lógica de Alertas (Vida, Mascota, Rango de seguridad, Atacantes, Die & Rise)
--------------------------------------------------------------------------------
local _, playerClass = UnitClass("player")
local ATTACKER_EXPIRE = 6 -- segundos sin golpearte para dejar de contar a un atacante

-- Registro de atacantes vía registro de combate (único modo fiable en 3.3.5 sin placas de nombre)
local attackers = {}
local playerGUID

local function CountThreat()
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

local function GetRangeDanger()
    if playerClass ~= "HUNTER" or not PA.db.rangeWarn then return nil end
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

local lastSoundTime = 0

local function CheckPanicState()
    if not PA.db or not PA.db.enabled then
        PA:StopPanic()
        return
    end

    local threat = CountThreat()
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

    local danger = GetRangeDanger()
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
        -- Orange sólo mientras la vida esté a salvo de la crítica; sube a rojo por vida baja (arriba)
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

local function ApplyLevelVisuals(level)
    local c = LEVEL_COLORS[level] or LEVEL_COLORS[3]
    SetEdgeColor(c[1], c[2], c[3])
    bannerText:SetTextColor(c[1], c[2], c[3], 1)
    statusText:SetTextColor(c[1], c[2], c[3], 1)
    bossBanner:SetBackdropBorderColor(c[1], c[2], c[3], 1)
    bossBanner:SetBackdropColor(c[1] * 0.12, c[2] * 0.12, c[3] * 0.12, 0.8)
end

local function UpdateThreatDisplay()
    if PA.db.threatCount and (PA.threat or 0) >= 1 then
        PA.threatNumber:SetText(PA.threat)
        PA.threatFrame:Show()
    else
        PA.threatFrame:Hide()
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
        if level == 3 and PA.db.soundAlert then
            PlaySoundFile(PA.db.soundFile or "Sound\\Interface\\RaidWarning.wav")
            lastSoundTime = now
        elseif level < 3 and PA.db.soundWarn then
            PlaySound("TellMessage")
            lastSoundTime = now
        end
    end

    ApplyLevelVisuals(level)

    local flashAllowed = PA.db.showScreenFlash and (level == 3 or PA.db.flashWarn)
    if flashAllowed and not PA.setupMode then
        flashFrame:Show()
    else
        flashFrame:Hide()
    end

    if PA.db.showBanner and not PA.setupMode then
        bannerText:SetText(reason or "¡PELIGRO INMINENTE!")
        bannerSubtext:SetText(sub or "")
        local w = math.max(bannerText:GetStringWidth(), bannerSubtext:GetStringWidth()) + 50
        bossBanner:SetWidth(math.max(w, 280))
        bossBanner:Show()
        statusText:SetText("")
    else
        bossBanner:Hide()
        statusText:SetText(PA.setupMode and "MODO CONFIGURACIÓN: Arrastra aquí poderes o pociones" or (reason or ""))
    end

    mainFrame:Show()
    UpdateThreatDisplay()
    UpdateSlots()
end

function PA:StopPanic()
    PA.inPanic = false
    PA.level = nil
    PA.setupMode = false
    flashFrame:Hide()
    bossBanner:Hide()
    threatFrame:Hide()
    if not PA.testMode and PA.db and PA.db.locked then
        mainFrame:Hide()
    elseif not PA.testMode and not PA.db then
        mainFrame:Hide()
    end
end

function PA:ApplyScale()
    mainFrame:SetScale(PA.db and PA.db.hudScale or 1)
end

--------------------------------------------------------------------------------
-- 6. Eventos y Tickers de Actualización
--------------------------------------------------------------------------------
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
eventFrame:RegisterEvent("PLAYER_DEAD")
eventFrame:RegisterEvent("UPDATE_BINDINGS")
eventFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

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
            PA:UpdateDRWidget()
            CheckPanicState()
            if PA.inPanic or PA.testMode then
                UpdateSlots()
            end
        end
    end
end)

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
        attackers[dstGUID] = nil
    elseif ATTACK_EVENTS[subEvent] and dstGUID == playerGUID and srcGUID and srcGUID ~= playerGUID
        and srcFlags and bit.band(srcFlags, 0x40) > 0 then -- 0x40 = reacción hostil
        attackers[srcGUID] = GetTime()
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

local function HandleDieAndRiseChat(msg)
    if not msg or not PA.db or not PA.db.drEnabled then return end
    local low = msg:lower()
    local now = GetTime()

    -- 1) Pre-aviso de náuseas en estado Putrefacto
    if PA.db.drNauseaWarn and (low:find("estomago putrefacto rechaza") or low:find("estómago putrefacto rechaza") or low:find("sientes fuertes nauseas") or low:find("sientes fuertes náuseas")) then
        PA.nauseaActive = now
        PA.tempAlert = {
            title = "¡NÁUSEAS! TU ESTÓMAGO RECHAZA LA COMIDA",
            sub = "Podrías vomitar pronto · ¡No entres en combate descuidado!",
            level = 2,
            untilTime = now + 5,
        }
        PA:UpdateDRWidget()
        CheckPanicState()
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
        CheckPanicState()
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
        CheckPanicState()
    end
end

eventFrame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        OnCombatLog(arg1, arg2, arg3, arg4, ...)
    elseif event == "CHAT_MSG_ADDON" then
        if arg1 == SOUL_PREFIX and arg3 == "WHISPER" and arg4 == UnitName("player") then
            local st, souls, goal = string.match(arg2 or "", "^(%d+):(%d+):(%d+)$")
            st, souls, goal = tonumber(st), tonumber(souls), tonumber(goal)
            if st and st <= 2 and souls and goal and goal >= 1 then
                local prevSouls = PA.drSouls or 0
                local prevStage = PA.drStage or 0
                PA.drStage = st
                PA.drSouls = souls
                PA.drGoal = goal
                PA.drSoulsFresh = GetTime()
                if PA.db then
                    PA.db.drStage = st
                    PA.db.drSouls = souls
                    PA.db.drGoal = goal
                end
                -- Si sacrificó 1 alma (bajó en 1 estando en estado Esquelético), iniciar el cronómetro de 36 s
                if st == 2 and prevStage == 2 and prevSouls > 0 and souls == prevSouls - 1 and PA.db and PA.db.drCorporealTrack then
                    PA.corporealEnd = GetTime() + 36
                end
                -- Si llegó a la meta de almas (ej. 300/300), avisar en pantalla
                if st == 2 and souls >= goal and prevSouls < goal and PA.db and PA.db.drEnabled then
                    PA.tempAlert = {
                        title = string.format("¡%d / %d ALMAS RECOLECTADAS!", souls, goal),
                        sub = "¡Ya podés canjear tus almas para recuperar tu cuerpo Putrefacto!",
                        level = 1,
                        untilTime = GetTime() + 6,
                    }
                end
                PA:UpdateDRWidget()
            end
        end
    elseif event == "UNIT_AURA" and arg1 == "player" then
        ScanPlayerAurasForDR()
        PA:UpdateDRWidget()
    elseif event == "CHAT_MSG_SYSTEM" or event == "CHAT_MSG_MONSTER_EMOTE" or event == "CHAT_MSG_TEXT_EMOTE" or event == "UI_ERROR_MESSAGE" then
        HandleDieAndRiseChat(arg1)
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
        CheckPanicState()
    elseif event == "ADDON_LOADED" and arg1 == addonName then
        InitDB()
        PA.drStage = PA.db.drStage or 0
        PA.drSouls = PA.db.drSouls or 0
        PA.drGoal = PA.db.drGoal or 300
        CreateMinimapButton()
        PA:UpdateLayout()
        PA:ApplyScale()
        if PA.db.frameX and PA.db.frameY then
            mainFrame:ClearAllPoints()
            mainFrame:SetPoint("CENTER", UIParent, "CENTER", PA.db.frameX, PA.db.frameY)
        end
        if PA.db.drWidgetX and PA.db.drWidgetY then
            drWidget:ClearAllPoints()
            drWidget:SetPoint("CENTER", UIParent, "CENTER", PA.db.drWidgetX, PA.db.drWidgetY)
        end
        PA:UpdateDRWidget()
    elseif event == "PLAYER_ENTERING_WORLD" then
        playerGUID = UnitGUID("player")
        if not PA.minimapBtn then
            CreateMinimapButton()
        else
            PA.UpdateMinimapPos(PA.db.minimap.minimapPos or 195)
        end
        ScanPlayerAurasForDR()
        PA:UpdateDRWidget()
        PA:UpdateLayout()
        CheckPanicState()
    elseif event == "PLAYER_REGEN_ENABLED" then
        wipe(attackers)
        CheckPanicState()
    elseif event == "UPDATE_BINDINGS" or event == "ACTIONBAR_UPDATE_COOLDOWN" or event == "BAG_UPDATE" then
        if PA.inPanic or PA.testMode then
            UpdateSlots()
        end
    else
        CheckPanicState()
    end
end)
