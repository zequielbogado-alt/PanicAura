-- PanicAura_Minimap.lua - Botón del Minimapa (Compatible con ForeverUI y Minimapa Clásico)
local addonName = ...
PanicAura = PanicAura or {}
local PA = PanicAura

function PA:CreateMinimapButton()
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
            if PA.db and PA.db.minimap then
                PA.db.minimap.minimapPos = pos
            end
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
                    if PA.mainFrame then PA.mainFrame:EnableMouse(true) end
                    PA:StartPanic("MODO CONFIGURACIÓN: Arrastra aquí poderes o pociones")
                    DEFAULT_CHAT_FRAME:AddMessage("|cffff2222PanicAura:|r Barra visible en modo configuración. Arrastra tus habilidades/pociones o muévela con click izquierdo.")
                else
                    PA.testMode = false
                    if PA.mainFrame then PA.mainFrame:EnableMouse(false) end
                    PA:StopPanic()
                    DEFAULT_CHAT_FRAME:AddMessage("|cffff2222PanicAura:|r Modo configuración cerrado.")
                end
            else
                -- Click Derecho Normal: Modo Prueba completo
                PA.setupMode = false
                PA.testLevel = 3
                PA.testMode = not PA.testMode
                if PA.testMode then
                    if PA.mainFrame then PA.mainFrame:EnableMouse(true) end
                    PA:StartPanic("¡MODO PRUEBA ACTIVO!")
                else
                    if PA.mainFrame then PA.mainFrame:EnableMouse(false) end
                    PA:StopPanic()
                end
            end
        else
            if PanicAuraConfigFrame then
                if PanicAuraConfigFrame:IsShown() then
                    PanicAuraConfigFrame:Hide()
                else
                    PanicAuraConfigFrame:Show()
                end
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
    local initialPos = (PA.db and PA.db.minimap and PA.db.minimap.minimapPos) or 195
    UpdateMinimapPos(initialPos)
end
