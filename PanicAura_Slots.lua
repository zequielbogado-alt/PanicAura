-- PanicAura_Slots.lua - Generación de Ranuras de Habilidades, Detección de Keybinds y Cooldowns
local addonName = ...
PanicAura = PanicAura or {}
local PA = PanicAura

local slotFrames = {}
PA.slotFrames = slotFrames

function PA:FormatKeybindText(bind)
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

function PA:FindKeybindForAction(targetName)
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
                if k1 then return PA:FormatKeybindText(k1) end
                if k2 then return PA:FormatKeybindText(k2) end
            end
        end
    end

    -- 2) Buscar keybind directo si existe una macro con ese nombre
    local k1, k2 = GetBindingKey("MACRO " .. targetName)
    if k1 then return PA:FormatKeybindText(k1) end
    if k2 then return PA:FormatKeybindText(k2) end

    -- 3) Buscar keybind directo si existe un hechizo en el Spellbook
    local kSpell = GetBindingKey("SPELL " .. targetName)
    if kSpell then return PA:FormatKeybindText(kSpell) end

    return nil
end

function PA:GetActionInfoByName(targetName)
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
    local btn = CreateFrame("Button", "PanicAuraSlot" .. index, PA.mainFrame, "SecureActionButtonTemplate")
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
        local data = PA.db and PA.db.slots and PA.db.slots[self.slotIndex]
        if data and data.name and data.name ~= "" then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(data.name, 1, 1, 1)
            local keybind = PA:FindKeybindForAction(data.name)
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

    -- Texto del Keybind (Tecla grande en esquina inferior)
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
PA.CreateSlotButton = CreateSlotButton

function PA:UpdateLayout()
    local size = PA.db and PA.db.iconSize or 44
    local count = 0
    local visibleSlots = {}

    for i = 1, 5 do
        local slotData = PA.db and PA.db.slots and PA.db.slots[i]
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
    if PA.mainFrame then
        PA.mainFrame:SetSize(math.max(totalWidth, 100), size)
    end

    local startX = -totalWidth / 2 + size / 2
    for idx, f in ipairs(visibleSlots) do
        f:ClearAllPoints()
        f:SetPoint("CENTER", PA.mainFrame, "CENTER", startX + (idx - 1) * (size + spacing), 0)
        f:Show()
    end
end

function PA:IsBlockedInSkeleton(name, actionType)
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
function PA:UpdateSlots()
    local size = PA.db and PA.db.iconSize or 44
    pulseTimer = pulseTimer + 0.05
    local pulseAlpha = (math.sin(pulseTimer * 5) + 1) / 2 * 0.7 + 0.3

    for i = 1, 5 do
        local f = slotFrames[i]
        local data = PA.db and PA.db.slots and PA.db.slots[i]
        if f and data and data.enabled and data.name and data.name ~= "" then
            local info = PA:GetActionInfoByName(data.name)
            local keybind = PA:FindKeybindForAction(data.name)

            if info then
                f.icon:SetTexture(info.texture or "Interface\\Icons\\INV_Misc_QuestionMark")
                local isBlocked = PA:IsBlockedInSkeleton(info.name or data.name, info.type)
                
                -- Cantidad de ítems (si es poción/consumible)
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
            if PA.db and PA.db.showKeybinds and keybind and keybind ~= "" then
                f.keybind:SetText(keybind)
                f.keybind:Show()
            else
                f.keybind:Hide()
            end
        end
    end
end
