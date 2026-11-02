-- PanicAura - In-Game Config Window (/pa o /panicaura)
local addonName = ...
local PA = PanicAura

local _, playerClass = UnitClass("player")
local isHunter = (playerClass == "HUNTER")

local COL_Y, COL_O, COL_R = "|cffffd10d", "|cffff8000", "|cffff1a1a"

--------------------------------------------------------------------------------
-- Ventana principal
--------------------------------------------------------------------------------
local configFrame = CreateFrame("Frame", "PanicAuraConfigFrame", UIParent)
configFrame:SetSize(480, 630)
configFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
configFrame:SetFrameStrata("DIALOG")
configFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 16, edgeSize = 32,
    insets = { left = 10, right = 10, top = 10, bottom = 10 }
})
configFrame:SetBackdropColor(0.04, 0.04, 0.06, 0.96)
configFrame:EnableMouse(true)
configFrame:SetMovable(true)
configFrame:SetClampedToScreen(true)
configFrame:RegisterForDrag("LeftButton")
configFrame:SetScript("OnDragStart", configFrame.StartMoving)
configFrame:SetScript("OnDragStop", configFrame.StopMovingOrSizing)
configFrame:Hide()
tinsert(UISpecialFrames, "PanicAuraConfigFrame") -- cerrar con Escape

local title = configFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
title:SetPoint("TOP", configFrame, "TOP", 0, -18)
title:SetText(COL_R .. "Panic|r" .. COL_Y .. "Aura|r")

local subtitle = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
subtitle:SetPoint("TOP", title, "BOTTOM", 0, -3)
subtitle:SetText("Alertas de supervivencia discretas y útiles")
subtitle:SetTextColor(0.7, 0.7, 0.7)

local closeX = CreateFrame("Button", nil, configFrame, "UIPanelCloseButton")
closeX:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -6, -6)

--------------------------------------------------------------------------------
-- Helpers de widgets
--------------------------------------------------------------------------------
local refreshers = {}
local uid = 0
local function nextName(prefix) uid = uid + 1; return "PanicAura" .. prefix .. uid end

local function Tooltip(frame, text)
    frame:EnableMouse(true)
    frame:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(text, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    frame:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

local function Header(parent, text, anchorTo, yOff)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, yOff or -14)
    fs:SetText(text)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetTexture(1, 1, 1, 0.15)
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", fs, "BOTTOMLEFT", 0, -3)
    line:SetPoint("RIGHT", parent, "RIGHT", -20, 0)
    fs.line = line
    return fs
end

-- anchor: elemento previo; devuelve el checkbox
local function CheckBox(parent, label, key, tip, anchor, onChange, yOff)
    local cb = CreateFrame("CheckButton", nextName("CB"), parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    if anchor.line then
        cb:SetPoint("TOPLEFT", anchor.line, "BOTTOMLEFT", 0, yOff or -6)
    else
        cb:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, yOff or -2)
    end
    local text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    text:SetText(label)
    cb.label = text
    cb:SetScript("OnClick", function(self)
        PA.db[key] = self:GetChecked() and true or false
        if onChange then onChange(PA.db[key]) end
    end)
    if tip then Tooltip(cb, tip) end
    table.insert(refreshers, function() cb:SetChecked(PA.db[key]) end)
    return cb
end

local function Slider(parent, label, key, minV, maxV, step, fmt, scale, anchor, onChange, xOff, yOff)
    local name = nextName("Slider")
    local s = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    s:SetMinMaxValues(minV, maxV)
    s:SetValueStep(step)
    s:SetWidth(190)
    s:SetHeight(16)
    s:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", xOff or 8, yOff or -26)
    _G[name .. "Text"]:SetText(label)
    _G[name .. "Low"]:SetText("")
    _G[name .. "High"]:SetText("")
    local val = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    val:SetPoint("LEFT", s, "RIGHT", 8, 0)
    s.val = val
    scale = scale or 1
    local loading = false
    s:SetScript("OnValueChanged", function(self, v)
        v = math.floor(v / step + 0.5) * step
        val:SetText(string.format(fmt, v))
        if loading then return end
        PA.db[key] = v / scale
        if onChange then onChange(v / scale) end
    end)
    table.insert(refreshers, function()
        loading = true
        s:SetValue((PA.db[key] or minV) * scale)
        val:SetText(string.format(fmt, (PA.db[key] or minV) * scale))
        loading = false
    end)
    return s
end

local function Button(parent, text, w, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w, 24)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end

--------------------------------------------------------------------------------
-- Pestañas
--------------------------------------------------------------------------------
local pages, tabs = {}, {}
local function ShowPage(idx)
    for i, p in ipairs(pages) do
        if i == idx then p:Show() else p:Hide() end
        if i == idx then tabs[i]:Disable() else tabs[i]:Enable() end
    end
end

local tabNames = { "General", "Alertas", "Die & Rise", "Ranuras" }
for i, n in ipairs(tabNames) do
    local page = CreateFrame("Frame", nil, configFrame)
    page:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 22, -88)
    page:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -22, 62)
    page:Hide()
    pages[i] = page

    local t = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    t:SetSize(96, 24)
    t:SetText(n)
    t:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 24 + (i - 1) * 100, -60)
    t:SetScript("OnClick", function() ShowPage(i) end)
    tabs[i] = t
end

--------------------------------------------------------------------------------
-- Pestaña 1: General / Apariencia
--------------------------------------------------------------------------------
do
    local p = pages[1]
    local h1 = Header(p, "Funcionamiento", p, 0)
    h1:ClearAllPoints(); h1:SetPoint("TOPLEFT", p, "TOPLEFT", 0, 0)

    local c1 = CheckBox(p, "Activar PanicAura", "enabled", "Activa o desactiva todas las alertas.", h1)
    local c2 = CheckBox(p, "Mostrar cartel superior", "showBanner", "Cartel con el motivo de la alerta y sugerencias, arriba en pantalla.", c1)
    local c3 = CheckBox(p, "Destello en los bordes de la pantalla", "showScreenFlash", "Viñeta pulsante en los bordes. Siempre se muestra en rojo; amarillo/naranja dependen de la opción siguiente.", c2)
    local c4 = CheckBox(p, "Destello también en alerta amarilla/naranja", "flashWarn", "Desmarcalo si querés que el destello aparezca solo en vida crítica (rojo).", c3)
    local c5 = CheckBox(p, "Mostrar teclas rápidas en los iconos", "showKeybinds", nil, c4, function() PA:UpdateLayout() end)

    local h2 = Header(p, "Sonido", c5, -10)
    local s1 = CheckBox(p, "Sonido en alerta roja (vida crítica)", "soundAlert", nil, h2)
    local s2 = CheckBox(p, "Sonido suave en alerta amarilla/naranja", "soundWarn", "Se reproduce solo al subir de nivel de alerta.", s1)

    local h3 = Header(p, "Apariencia", s2, -10)
    local sl1 = Slider(p, "Tamaño de iconos", "iconSize", 32, 64, 2, "%d px", 1, h3, function() PA:UpdateLayout() end, 8, -30)
    local sl2 = Slider(p, "Escala de la barra", "hudScale", 70, 150, 10, "%d%%", 100, sl1, function() PA:ApplyScale() end, 0, -32)
    local sl3 = Slider(p, "Intensidad del destello", "flashIntensity", 20, 100, 10, "%d%%", 100, sl2, nil, 0, -32)
end

--------------------------------------------------------------------------------
-- Pestaña 2: Alertas (vida, cazador, atacantes)
--------------------------------------------------------------------------------
do
    local p = pages[2]
    local h1 = Header(p, "Vida  " .. COL_Y .. "(amarillo)|r  " .. COL_R .. "(rojo)|r", p, 0)
    h1:ClearAllPoints(); h1:SetPoint("TOPLEFT", p, "TOPLEFT", 0, 0)

    local sCrit = Slider(p, COL_R .. "Alerta ROJA|r al llegar a (% vida)", "hpThreshold", 10, 60, 5, "%d%%", 1, h1, function(v)
        if (PA.db.warnThreshold or 70) < v + 5 then PA.db.warnThreshold = v + 5 end
    end, 8, -30)
    local cbWarn = CheckBox(p, COL_Y .. "Aviso AMARILLO|r previo (vida decreciente)", "warnEnabled", "Aviso discreto antes de llegar a la crítica.", sCrit, nil, -10)
    local sWarn = Slider(p, "Aviso amarillo al llegar a (% vida)", "warnThreshold", 20, 90, 5, "%d%%", 1, cbWarn, function(v)
        if PA.db.hpThreshold > v - 5 then PA.db.hpThreshold = math.max(10, v - 5) end
    end, 8, -24)
    local cbPet = CheckBox(p, "Avisar si la mascota muere en combate", "triggerOnPetDeath", nil, sWarn, nil, -10)

    local h2 = Header(p, COL_O .. "Cazador|r - Rango de seguridad", cbPet, -8)
    local cbRange = CheckBox(p, "Avisar si un enemigo entra en zona muerta / melé", "rangeWarn",
        "Alerta NARANJA cuando un enemigo que te ataca está a menos de ~8-10 m o cuerpo a cuerpo. Sugiere Aspecto del guepardo/mono, Golpe de alas o Trampa.", h2)
    if not isHunter then
        cbRange.label:SetTextColor(0.5, 0.5, 0.5)
        local note = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        note:SetPoint("TOPLEFT", cbRange, "BOTTOMLEFT", 26, 0)
        note:SetText("(solo aplica a personajes Cazador)")
    end

    local h3 = Header(p, COL_R .. "Atacantes|r - Contador de agresores", cbRange, isHunter and -8 or -22)
    local cbThreat = CheckBox(p, "Mostrar contador rojo junto a la barra", "threatCount",
        "Cuenta enemigos que te atacan o te tienen como objetivo (por registro de combate y objetivo/foco/grupo).", h3)
    local cbTA = CheckBox(p, "Aviso amarillo si hay muchos atacantes", "threatAlert", nil, cbThreat, nil, -2)
    local sMin = Slider(p, "Desde cuántos atacantes", "threatAlertMin", 2, 10, 1, "%d", 1, cbTA, nil, 8, -24)

    local h4 = Header(p, COL_O .. "Zona Peligrosa|r - Enemigos de Nivel Superior", sMin, -10)
    local cbZone = CheckBox(p, "Avisar al entrar a una zona de nivel superior", "zoneDangerAlert",
        "Muestra un mensaje central con sonido y destellos al entrar a una zona donde los enemigos superan tu nivel. No activa botones de pánico.", h4)
    local sDiff = Slider(p, "Superan en más de (niveles)", "zoneDangerDiff", 1, 5, 1, "+%d niv.", 1, cbZone, nil, 8, -24)
    local cbZFlash = CheckBox(p, "Destellos en bordes de pantalla", "zoneDangerFlash", "Muestra 3 pulsos suaves en los bordes de la pantalla.", sDiff, nil, -10)
    local cbZSound = CheckBox(p, "Sonido de advertencia", "zoneDangerSound", nil, cbZFlash, nil, -2)

    local btnTestZone = Button(p, "Probar Zona", 95, function()
        if PA.TestZoneAlert then PA:TestZoneAlert() end
    end)
    btnTestZone:SetPoint("LEFT", cbZSound, "RIGHT", 140, 0)
    Tooltip(btnTestZone, "Simula la alerta de zona peligrosa entrando a Bosque del Ocaso.")
end

--------------------------------------------------------------------------------
-- Pestaña 3: Die & Rise (Modo Hardcore de TuWoW)
--------------------------------------------------------------------------------
local drDeathText
local function RefreshDeathLogText()
    if not drDeathText then return end
    local log = PA.db and PA.db.deathLog
    if not log or #log == 0 then
        drDeathText:SetText("|cff888888Sin muertes registradas en este personaje.|r")
        return
    end
    local lines = {}
    for i = 1, math.min(#log, 5) do
        local e = log[i]
        table.insert(lines, string.format("%d. |cffffff00%s|r (Nv.%d, %s) - |cffff6666%s|r [%s]",
            i, e.date or "?", e.level or 1, e.zone or "?", e.killer or "?", e.stage or "?"))
    end
    drDeathText:SetText(table.concat(lines, "\n"))
end

do
    local p = pages[3]
    local h1 = Header(p, "Modo Die & Rise  |cff88ff22(Putrefacto)|r / |cffcccccc(Esquelético)|r", p, 0)
    h1:ClearAllPoints(); h1:SetPoint("TOPLEFT", p, "TOPLEFT", 0, 0)

    local c1 = CheckBox(p, "Activar funciones Die & Rise", "drEnabled",
        "Adapta las alertas según tu estado (Vivo, Putrefacto o Esquelético) y sincroniza el contador de almas del servidor.", h1, function() PA:UpdateDRWidget() end)
    local c2 = CheckBox(p, "Mostrar indicador de Estado, Almas (0/300) y Corporeidad", "drShowWidget",
        "Muestra una barra compacta con tu estado actual, progreso de 300 almas y cuenta regresiva de 36 s de corporeidad.", c1, function() PA:UpdateDRWidget() end)
    local c3 = CheckBox(p, "Aumentar umbrales de vida en Putrefacto (+10%) y Esquelético (+15%)", "drStageBoost",
        "Si ya perdiste una vida, la alerta amarilla y roja se disparan antes para darte más margen de reacción.", c2)
    local c4 = CheckBox(p, "Avisar náuseas y vómito al comer (Putrefacto)", "drNauseaWarn",
        "Detecta en el chat cuando tu estómago putrefacto rechaza la comida y cuando comenzás a vomitar.", c3)
    local c5 = CheckBox(p, "Marcar pociones bloqueadas con 'X' en estado Esquelético", "drBlockPotions",
        "En estado Esquelético no podés tomar pociones. Las marca como bloqueadas salvo que tengas los 36 s de corporeidad.", c4)
    local c6 = CheckBox(p, "Rastrear 36 s de Corporeidad al sacrificar 1 alma", "drCorporealTrack",
        "Inicia un cronómetro visual de 36 segundos cuando sacrificás un alma para poder comer y beber.", c5, function() PA:UpdateDRWidget() end)

    local h2 = Header(p, "Golpe Fuerte (Daño Súbito)", c6, -8)
    local c7 = CheckBox(p, "Disparar alerta ROJA ante un golpe brutal", "drBigHitAlert",
        "Te alerta inmediatamente si un solo golpe te quita un gran porcentaje de tu vida máxima, aunque tengas vida alta.", h2)
    local sBig = Slider(p, "Daño mínimo del golpe (% vida máx.)", "drBigHitPct", 20, 60, 5, "%d%%", 1, c7, nil, 8, -24)

    local h3 = Header(p, "Historial de Muertes del Personaje", sBig, -16)
    h3:ClearAllPoints()
    h3:SetPoint("TOPLEFT", c7, "BOTTOMLEFT", 0, -48)

    drDeathText = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    drDeathText:SetPoint("TOPLEFT", h3.line, "BOTTOMLEFT", 4, -6)
    drDeathText:SetPoint("RIGHT", p, "RIGHT", -8, 0)
    drDeathText:SetJustifyH("LEFT")
    drDeathText:SetSpacing(3)

    table.insert(refreshers, RefreshDeathLogText)
end

--------------------------------------------------------------------------------
-- Pestaña 4: Ranuras
--------------------------------------------------------------------------------
local editBoxes = {}
do
    local p = pages[4]
    local header = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", p, "TOPLEFT", 0, 0)
    header:SetText("Poderes, pociones o ítems salvavidas")

    local hint = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -3)
    hint:SetText("Arrastrá un hechizo/ítem a la caja o escribí el nombre exacto.")

    for i = 1, 5 do
        local lbl = p:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lbl:SetText(i .. ".")
        lbl:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 4, -16 - (i - 1) * 34)

        local eb = CreateFrame("EditBox", "PanicAuraSlotEB" .. i, p, "InputBoxTemplate")
        eb:SetSize(280, 22)
        eb:SetAutoFocus(false)
        eb:SetPoint("LEFT", lbl, "RIGHT", 14, 0)
        eb:SetScript("OnTextChanged", function(self)
            local txt = self:GetText():trim()
            if PA.db and PA.db.slots and PA.db.slots[i] then
                PA.db.slots[i].name = txt
                PA:UpdateLayout()
            end
        end)
        eb:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
        eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        eb:SetScript("OnReceiveDrag", function(self)
            local infoType, info1 = GetCursorInfo()
            local nm
            if infoType == "spell" then nm = GetSpellName(info1, BOOKTYPE_SPELL)
            elseif infoType == "item" then nm = GetItemInfo(info1)
            elseif infoType == "macro" then nm = GetMacroInfo(info1) end
            if nm then
                self:SetText(nm)
                ClearCursor()
            end
        end)
        eb:SetScript("OnMouseUp", function(self)
            if GetCursorInfo() then self:GetScript("OnReceiveDrag")(self) end
        end)

        local cbSlot = CreateFrame("CheckButton", nil, p, "UICheckButtonTemplate")
        cbSlot:SetSize(24, 24)
        cbSlot:SetPoint("LEFT", eb, "RIGHT", 8, 0)
        cbSlot:SetScript("OnClick", function(self)
            if PA.db and PA.db.slots and PA.db.slots[i] then
                PA.db.slots[i].enabled = self:GetChecked() and true or false
                PA:UpdateLayout()
            end
        end)
        Tooltip(cbSlot, "Activar / desactivar esta ranura")

        editBoxes[i] = { eb = eb, cb = cbSlot }
    end
end

--------------------------------------------------------------------------------
-- Barra inferior: pruebas, mover, cerrar
--------------------------------------------------------------------------------
local testButtons = {}
local function StopTests()
    PA.testMode = false
    PA.testLevel = nil
    PA.mainFrame:EnableMouse(false)
    PA:StopPanic()
    for _, b in pairs(testButtons) do b:SetAlpha(1) end
end

local function ToggleTest(level)
    if PA.testMode and PA.testLevel == level then
        StopTests()
        return
    end
    PA.testLevel = level
    PA.testMode = true
    PA.mainFrame:EnableMouse(true)
    for l, b in pairs(testButtons) do b:SetAlpha(l == level and 1 or 0.55) end
end

local bar = CreateFrame("Frame", nil, configFrame)
bar:SetPoint("BOTTOMLEFT", configFrame, "BOTTOMLEFT", 22, 20)
bar:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -22, 20)
bar:SetHeight(26)

local testLbl = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
testLbl:SetPoint("LEFT", bar, "LEFT", 0, 0)
testLbl:SetText("Probar:")

local tY = Button(bar, COL_Y .. "Amarilla|r", 62, function() ToggleTest(1) end)
tY:SetPoint("LEFT", testLbl, "RIGHT", 4, 0)
local tO = Button(bar, COL_O .. "Naranja|r", 62, function() ToggleTest(2) end)
tO:SetPoint("LEFT", tY, "RIGHT", 2, 0)
local tR = Button(bar, COL_R .. "Roja|r", 52, function() ToggleTest(3) end)
tR:SetPoint("LEFT", tO, "RIGHT", 2, 0)
testButtons[1], testButtons[2], testButtons[3] = tY, tO, tR

local btnClose = Button(bar, "Cerrar", 64, function() configFrame:Hide() end)
btnClose:SetPoint("RIGHT", bar, "RIGHT", 0, 0)

local btnUnlock = Button(bar, "Mover barra", 86, function(self)
    PA.db.locked = not PA.db.locked
    if not PA.db.locked then
        self:SetText("Bloquear")
        PA.mainFrame:EnableMouse(true)
        PA.mainFrame:Show()
        PA.statusText:SetText("Arrastrá con click izquierdo")
        PA:UpdateDRWidget()
    else
        self:SetText("Mover barra")
        PA.mainFrame:EnableMouse(false)
        PA.statusText:SetText("")
        if not PA.inPanic and not PA.testMode then
            PA.mainFrame:Hide()
        end
        PA:UpdateDRWidget()
    end
end)
btnUnlock:SetPoint("RIGHT", btnClose, "LEFT", -4, 0)
Tooltip(btnUnlock, "Desbloquea la barra y el indicador Die & Rise para arrastrarlos a otra posición.")

--------------------------------------------------------------------------------
-- Carga / cierre
--------------------------------------------------------------------------------
configFrame:SetScript("OnShow", function()
    for _, r in ipairs(refreshers) do r() end
    for i = 1, 5 do
        local d = PA.db.slots[i]
        if d then
            editBoxes[i].eb:SetText(d.name or "")
            editBoxes[i].eb:SetCursorPosition(0)
            editBoxes[i].cb:SetChecked(d.enabled)
        end
    end
    btnUnlock:SetText(PA.db.locked and "Mover barra" or "Bloquear")
    ShowPage(1)
end)

configFrame:SetScript("OnHide", function()
    if PA.testMode then StopTests() end
    if not PA.db.locked then
        PA.db.locked = true
        PA.mainFrame:EnableMouse(false)
        PA.statusText:SetText("")
        if not PA.inPanic then PA.mainFrame:Hide() end
        PA:UpdateDRWidget()
    end
end)

-- Comandos Slash (/pa y /panicaura para no pisar el emote /panic de WoW)
SLASH_PANICAURA1 = "/pa"
SLASH_PANICAURA2 = "/panicaura"
SlashCmdList["PANICAURA"] = function(msg)
    msg = msg and msg:lower():trim() or ""
    if msg == "test" then
        ToggleTest(3)
    elseif msg == "test1" then
        ToggleTest(1)
    elseif msg == "test2" then
        ToggleTest(2)
    elseif msg == "testzone" or msg == "tz" then
        if PA.TestZoneAlert then PA:TestZoneAlert() end
    elseif msg == "dr0" or msg == "dr1" or msg == "dr2" then
        local st = tonumber(msg:sub(3, 3))
        PA.drStage = st
        if PA.db then PA.db.drStage = st end
        if st == 2 and (PA.drSouls or 0) == 0 then PA.drSouls = 142; PA.drGoal = 300 end
        PA:UpdateDRWidget()
        DEFAULT_CHAT_FRAME:AddMessage("|cffff2222PanicAura:|r Estado Die & Rise simulado: " .. st)
    elseif msg == "corp" then
        PA.corporealEnd = GetTime() + 36
        PA:UpdateDRWidget()
        DEFAULT_CHAT_FRAME:AddMessage("|cffff2222PanicAura:|r Simulando 36 s de Corporeidad provisoria.")
    elseif msg == "auras" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff2222PanicAura - Auras activas:|r")
        for i = 1, 40 do
            local name, _, _, stacks, _, duration, _, _, _, _, id = UnitBuff("player", i)
            if not name then break end
            DEFAULT_CHAT_FRAME:AddMessage(string.format("  [Buff %d] %s (ID: %s, Stacks: %s, Dur: %s)", i, name, tostring(id), tostring(stacks), tostring(duration)))
        end
        for i = 1, 40 do
            local name, _, _, stacks, _, duration, _, _, _, _, id = UnitDebuff("player", i)
            if not name then break end
            DEFAULT_CHAT_FRAME:AddMessage(string.format("  [Debuff %d] %s (ID: %s, Stacks: %s, Dur: %s)", i, name, tostring(id), tostring(stacks), tostring(duration)))
        end
    else
        if configFrame:IsShown() then configFrame:Hide() else configFrame:Show() end
    end
end
