-- PanicAura_Flash.lua - Viñeta y Destello en Bordes de Pantalla (Screen Flash)
local addonName = ...
PanicAura = PanicAura or {}
local PA = PanicAura

local flashFrame = CreateFrame("Frame", "PanicAuraScreenFlash", UIParent)
flashFrame:SetAllPoints(UIParent)
flashFrame:SetFrameStrata("FULLSCREEN_DIALOG")
flashFrame:SetAlpha(0)
flashFrame:Hide()
PA.flashFrame = flashFrame

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

function PA:SetEdgeColor(r, g, b)
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

-- Inicializar en color rojo por defecto
local initCol = PA.LEVEL_COLORS and PA.LEVEL_COLORS[3] or { 1.0, 0.1, 0.1 }
PA:SetEdgeColor(unpack(initCol))

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
