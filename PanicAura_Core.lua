-- PanicAura_Core.lua - Configuración base, base de datos y namespace
local addonName = ...
PanicAura = PanicAura or {}
local PA = PanicAura

-- Estado global del addon
PA.addonName = addonName
PA.inPanic = false
PA.testMode = false
PA.testLevel = nil
PA.setupMode = false
PA.level = nil
PA.threat = 0
PA.drStage = 0
PA.drSouls = 0
PA.drGoal = 300
PA.deathLog = {}

-- Colores por nivel de alerta: 1 = aviso (amarillo), 2 = rango (naranja), 3 = crítica (roja)
PA.LEVEL_COLORS = {
    [1] = { 1.00, 0.82, 0.05 },
    [2] = { 1.00, 0.50, 0.00 },
    [3] = { 1.00, 0.10, 0.10 },
}

-- Habilidades salvavidas predeterminadas según clase
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
PA.classDefaults = classDefaults

function PA:GetClassDefaults()
    local _, class = UnitClass("player")
    return classDefaults[class] or classDefaults["HUNTER"]
end

-- Configuración por defecto
local defaultDB = {
    enabled = true,
    hpThreshold = 40,          -- Alerta ROJA (crítica): en combate con <= 40% de vida
    warnEnabled = true,        -- Alerta AMARILLA (aviso) previa a la crítica
    warnThreshold = 70,        -- Aviso amarillo: en combate con <= 70% de vida
    triggerOnPetDeath = true,   -- Aviso si la mascota muere en combate
    soundAlert = true,         -- Sonido en alerta roja
    soundWarn = false,         -- Sonido suave en alerta amarilla/naranja
    soundFile = "Sound\\Interface\\RaidWarning.wav",
    alertVolume = 0.7,         -- Volumen temporal de alertas (0.10 a 1.00)
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
PA.defaultDB = defaultDB

function PA:InitDB()
    if not PanicAuraDB then
        PanicAuraDB = {}
    end
    for k, v in pairs(defaultDB) do
        if PanicAuraDB[k] == nil then
            if k == "slots" then
                PanicAuraDB.slots = PA:GetClassDefaults()
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
        PanicAuraDB.slots = PA:GetClassDefaults()
    end
    PA.db = PanicAuraDB
end

--------------------------------------------------------------------------------
-- Control Inteligente de Volumen y Reproducción de Audio
--------------------------------------------------------------------------------
local audioTimerFrame = CreateFrame("Frame")
local originalMasterVol = nil
local isPlayingAlertAudio = false

-- Restablecer volumen en caso de deslogueo o recarga de interfaz
audioTimerFrame:RegisterEvent("PLAYER_LOGOUT")
audioTimerFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
audioTimerFrame:SetScript("OnEvent", function(self, event)
    if originalMasterVol ~= nil then
        pcall(SetCVar, "Sound_MasterVolume", tostring(originalMasterVol))
        originalMasterVol = nil
        isPlayingAlertAudio = false
    end
end)

function PA:PlayAlertSound(sound, isFile, duration)
    if not sound then return end
    duration = duration or 3.0
    local targetVol = (PA.db and PA.db.alertVolume) or 0.7

    -- Guardar el volumen maestro del usuario antes de la alerta (solo si no hay otra alerta activa)
    if not isPlayingAlertAudio then
        originalMasterVol = tonumber(GetCVar("Sound_MasterVolume") or "1") or 1
        isPlayingAlertAudio = true
    end

    -- Aplicar temporalmente el volumen configurado en el addon
    pcall(SetCVar, "Sound_MasterVolume", tostring(targetVol))

    -- Reproducir audio en canal Master
    if isFile then
        local ok = pcall(PlaySoundFile, sound, "Master")
        if not ok then pcall(PlaySoundFile, sound) end
    else
        pcall(PlaySound, sound)
    end

    -- Programar restauración al volumen previo del juego
    audioTimerFrame.elapsed = 0
    audioTimerFrame.duration = duration
    audioTimerFrame:SetScript("OnUpdate", function(self, dt)
        self.elapsed = self.elapsed + dt
        if self.elapsed >= self.duration then
            self:SetScript("OnUpdate", nil)
            isPlayingAlertAudio = false
            if originalMasterVol ~= nil then
                pcall(SetCVar, "Sound_MasterVolume", tostring(originalMasterVol))
                originalMasterVol = nil
            end
        end
    end)
end
