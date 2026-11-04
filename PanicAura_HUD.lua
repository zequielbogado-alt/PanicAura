-- PanicAura_HUD.lua - Marco Principal, Cartel Superior y Contador de Atacantes
local addonName = ...
PanicAura = PanicAura or {}
local PA = PanicAura

--------------------------------------------------------------------------------
-- 1. Marco Principal de la Barra de Salvavidas
--------------------------------------------------------------------------------
local mainFrame = CreateFrame("Frame", "PanicAuraMainFrame", UIParent)
mainFrame:SetSize(250, 60)
mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -120)
mainFrame:SetFrameStrata("HIGH")
mainFrame:SetMovable(true)
mainFrame:EnableMouse(false)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnDragStart", function(self)
    if not PA.db or not PA.db.locked then self:StartMoving() end
end)
mainFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, _, x, y = self:GetPoint()
    if PA.db then
        PA.db.frameX = x
        PA.db.frameY = y
    end
end)
mainFrame:Hide()
PA.mainFrame = mainFrame

-- Texto de estado sobre la barra (para modo configuración o si el cartel está oculto)
local statusText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
statusText:SetPoint("BOTTOM", mainFrame, "TOP", 0, 8)
statusText:SetTextColor(1, 0.82, 0.05, 1)
statusText:SetShadowOffset(1, -1)
PA.statusText = statusText

--------------------------------------------------------------------------------
-- 2. Contador de Atacantes (Threat / Aggro Count) junto a la barra
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

PA.threatFrame = threatFrame
PA.threatNumber = threatNumber

function PA:UpdateThreatDisplay()
    if PA.db and PA.db.threatCount and (PA.threat or 0) >= 1 then
        PA.threatNumber:SetText(PA.threat)
        PA.threatFrame:Show()
    else
        PA.threatFrame:Hide()
    end
end

--------------------------------------------------------------------------------
-- 3. Cartel de Alerta en el Centro Superior de la Pantalla
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

function PA:ApplyScale()
    if PA.mainFrame then
        PA.mainFrame:SetScale(PA.db and PA.db.hudScale or 1)
    end
end
