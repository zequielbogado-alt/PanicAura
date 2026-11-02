-- PanicAura - Database de Niveles de Zonas para WoW 3.3.5a (WotLK)
-- Soporta nombres en español (esES / esMX), inglés y nombres de mapas de sistema
local addonName = ...
PanicAura = PanicAura or {}
local PA = PanicAura

local function Normalize(str)
    if not str then return "" end
    str = str:lower()
    str = str:gsub("^%s+", ""):gsub("%s+$", "")
    str = str:gsub("[áàäâ]", "a")
    str = str:gsub("[éèëê]", "e")
    str = str:gsub("[íìïî]", "i")
    str = str:gsub("[óòöô]", "o")
    str = str:gsub("[úùüû]", "u")
    str = str:gsub("ñ", "n")
    str = str:gsub("['`%-%_]", "")
    str = str:gsub("%s+", " ")
    return str
end
PA.NormalizeZoneName = Normalize

-- Base de datos de niveles (min, max) para zonas abiertas y mazmorras en 3.3.5a
local rawZones = {
    -- =========================================================================
    -- REINOS DEL ESTE (Eastern Kingdoms)
    -- =========================================================================
    { en = "Elwynn Forest", es = "Bosque de Elwynn", map = "Elwynn", min = 1, max = 10 },
    { en = "Dun Morogh", es = "Dun Morogh", map = "DunMorogh", min = 1, max = 10 },
    { en = "Tirisfal Glades", es = "Claros de Tirisfal", map = "Tirisfal", min = 1, max = 10 },
    { en = "Eversong Woods", es = "Bosque Cancion Eterna", map = "EversongWoods", min = 1, max = 10 },
    { en = "Westfall", es = "Paramos de Poniente", map = "Westfall", min = 10, max = 20 },
    { en = "Loch Modan", es = "Loch Modan", map = "LochModan", min = 10, max = 20 },
    { en = "Silverpine Forest", es = "Bosque de Argenteos", map = "Silverpine", min = 10, max = 20 },
    { en = "Ghostlands", es = "Tierras Fantasma", map = "Ghostlands", min = 10, max = 20 },
    { en = "Redridge Mountains", es = "Montañas Crestagrana", map = "Redridge", min = 15, max = 25 },
    { en = "Duskwood", es = "Bosque del Ocaso", map = "Duskwood", min = 18, max = 30 },
    { en = "Hillsbrad Foothills", es = "Laderas de Trabalomas", map = "HillsbradFoothills", min = 20, max = 30 },
    { en = "Wetlands", es = "Los Humedales", map = "Wetlands", min = 20, max = 30 },
    { en = "Alterac Mountains", es = "Montañas de Alterac", map = "Alterac", min = 30, max = 40 },
    { en = "Arathi Highlands", es = "Tierras Altas de Arathi", map = "Arathi", min = 30, max = 40 },
    { en = "Stranglethorn Vale", es = "Vega de Tuercespina", map = "Stranglethorn", min = 30, max = 45 },
    { en = "Badlands", es = "Tierras Inhospitas", map = "Badlands", min = 35, max = 45 },
    { en = "Swamp of Sorrows", es = "Pantano de las Penas", map = "SwampOfSorrows", min = 35, max = 45 },
    { en = "The Hinterlands", es = "Tierras del Interior", map = "Hinterlands", min = 40, max = 50 },
    { en = "Searing Gorge", es = "La Garganta de Fuego", map = "SearingGorge", min = 45, max = 50 },
    { en = "Blasted Lands", es = "Las Tierras Devastadas", map = "BlastedLands", min = 45, max = 55 },
    { en = "Burning Steppes", es = "Las Estepas Ardientes", map = "BurningSteppes", min = 50, max = 58 },
    { en = "Western Plaguelands", es = "Tierras de la Peste del Oeste", map = "WesternPlaguelands", min = 51, max = 58 },
    { en = "Eastern Plaguelands", es = "Tierras de la Peste del Este", map = "EasternPlaguelands", min = 53, max = 60 },
    { en = "Deadwind Pass", es = "Paso de la Muerte", map = "DeadwindPass", min = 55, max = 60 },
    { en = "Isle of Quel'Danas", es = "Isla de Quel'Danas", map = "Sunwell", min = 70, max = 70 },

    -- =========================================================================
    -- KALIMDOR
    -- =========================================================================
    { en = "Durotar", es = "Durotar", map = "Durotar", min = 1, max = 10 },
    { en = "Mulgore", es = "Mulgore", map = "Mulgore", min = 1, max = 10 },
    { en = "Teldrassil", es = "Teldrassil", map = "Teldrassil", min = 1, max = 10 },
    { en = "Azuremyst Isle", es = "Isla Bruma Azur", map = "AzuremystIsle", min = 1, max = 10 },
    { en = "Bloodmyst Isle", es = "Isla Bruma de Sangre", map = "BloodmystIsle", min = 10, max = 20 },
    { en = "Darkshore", es = "Costa Oscura", map = "Darkshore", min = 10, max = 20 },
    { en = "The Barrens", es = "Los Baldios", map = "Barrens", min = 10, max = 25 },
    { en = "Stonetalon Mountains", es = "Sierra Espolon", map = "StonetalonMountains", min = 15, max = 27 },
    { en = "Ashenvale", es = "Vallefresno", map = "Ashenvale", min = 18, max = 30 },
    { en = "Thousand Needles", es = "Las Mil Agujas", map = "ThousandNeedles", min = 25, max = 35 },
    { en = "Desolace", es = "Desolace", map = "Desolace", min = 30, max = 40 },
    { en = "Dustwallow Marsh", es = "Marjal Revolcafango", map = "Dustwallow", min = 35, max = 45 },
    { en = "Tanaris", es = "Tanaris", map = "Tanaris", min = 40, max = 50 },
    { en = "Feralas", es = "Feralas", map = "Feralas", min = 40, max = 50 },
    { en = "Azshara", es = "Azshara", map = "Azshara", min = 45, max = 55 },
    { en = "Felwood", es = "Frondavil", map = "Felwood", min = 48, max = 55 },
    { en = "Un'Goro Crater", es = "Crater de Un'Goro", map = "UngoroCrater", min = 48, max = 55 },
    { en = "Silithus", es = "Silithus", map = "Silithus", min = 55, max = 60 },
    { en = "Winterspring", es = "Cuna del Invierno", map = "Winterspring", min = 53, max = 60 },
    { en = "Moonglade", es = "Claro de la Luna", map = "Moonglade", min = 55, max = 60 },

    -- =========================================================================
    -- TERRALLENDE (Outland)
    -- =========================================================================
    { en = "Hellfire Peninsula", es = "Peninsula del Fuego Infernal", map = "Hellfire", min = 58, max = 63 },
    { en = "Zangarmarsh", es = "Marisma de Zangar", map = "Zangarmarsh", min = 60, max = 64 },
    { en = "Terokkar Forest", es = "Bosque de Terokkar", map = "TerokkarForest", min = 62, max = 65 },
    { en = "Nagrand", es = "Nagrand", map = "Nagrand", min = 64, max = 67 },
    { en = "Blade's Edge Mountains", es = "Montañas Filospada", map = "BladesEdgeMountains", min = 65, max = 68 },
    { en = "Netherstorm", es = "Tormenta Abisal", map = "Netherstorm", min = 67, max = 70 },
    { en = "Shadowmoon Valley", es = "Valle Sombraluna", map = "ShadowmoonValley", min = 67, max = 70 },

    -- =========================================================================
    -- RASGANORTE (Northrend)
    -- =========================================================================
    { en = "Borean Tundra", es = "Tundra Boreal", map = "BoreanTundra", min = 68, max = 72 },
    { en = "Howling Fjord", es = "Fiordo Aquilonal", map = "HowlingFjord", min = 68, max = 72 },
    { en = "Dragonblight", es = "Cementerio de Dragones", map = "Dragonblight", min = 71, max = 74 },
    { en = "Grizzly Hills", es = "Colinas Pardas", map = "GrizzlyHills", min = 73, max = 75 },
    { en = "Zul'Drak", es = "Zul'Drak", map = "ZulDrak", min = 74, max = 77 },
    { en = "Sholazar Basin", es = "Cuenca de Sholazar", map = "SholazarBasin", min = 76, max = 78 },
    { en = "The Storm Peaks", es = "Las Cumbres Tormentosas", map = "StormPeaks", min = 77, max = 80 },
    { en = "Crystalsong Forest", es = "Bosque Canto de Cristal", map = "CrystalsongForest", min = 77, max = 80 },
    { en = "Icecrown", es = "Corona de Hielo", map = "IcecrownGlacier", min = 77, max = 80 },
    { en = "Wintergrasp", es = "Conquista del Invierno", map = "LakeWintergrasp", min = 77, max = 80 },
    { en = "Hrothgar's Landing", es = "Desembarco de Hrothgar", map = "HrothgarsLanding", min = 77, max = 80 },

    -- =========================================================================
    -- CIUDADES Y CAPITALES (Zonas seguras)
    -- =========================================================================
    { en = "Stormwind City", es = "Ciudad de Ventormenta", map = "Stormwind", min = 1, max = 80, safe = true },
    { en = "Ironforge", es = "Forjaz", map = "Ironforge", min = 1, max = 80, safe = true },
    { en = "Darnassus", es = "Darnassus", map = "Darnassus", min = 1, max = 80, safe = true },
    { en = "The Exodar", es = "El Exodar", map = "TheExodar", min = 1, max = 80, safe = true },
    { en = "Orgrimmar", es = "Orgrimmar", map = "Orgrimmar", min = 1, max = 80, safe = true },
    { en = "Thunder Bluff", es = "Cima del Trueno", map = "ThunderBluff", min = 1, max = 80, safe = true },
    { en = "Undercity", es = "Entrañas", map = "Undercity", min = 1, max = 80, safe = true },
    { en = "Silvermoon City", es = "Ciudad de Lunargenta", map = "SilvermoonCity", min = 1, max = 80, safe = true },
    { en = "Shattrath City", es = "Ciudad de Shattrath", map = "ShattrathCity", min = 60, max = 80, safe = true },
    { en = "Dalaran", es = "Dalaran", map = "Dalaran", min = 70, max = 80, safe = true },

    -- =========================================================================
    -- MAZMORRAS Y BANDAS CLAVE (Dungeons / Raids)
    -- =========================================================================
    { en = "Ragefire Chasm", es = "Sima Ignea", min = 13, max = 18 },
    { en = "Wailing Caverns", es = "Cuevas de los Lamentos", min = 17, max = 24 },
    { en = "The Deadmines", es = "Las Minas de la Muerte", min = 17, max = 26 },
    { en = "Shadowfang Keep", es = "Castillo de Colmillo Oscuro", min = 22, max = 30 },
    { en = "Blackfathom Deeps", es = "Cavernas de Brazanegra", min = 24, max = 32 },
    { en = "The Stockade", es = "Las Mazmorras", min = 24, max = 32 },
    { en = "Gnomeregan", es = "Gnomeregan", min = 29, max = 38 },
    { en = "Razorfen Kraul", es = "Horado Rajacieno", min = 30, max = 40 },
    { en = "Scarlet Monastery", es = "Monasterio Escarlata", min = 30, max = 45 },
    { en = "Razorfen Downs", es = "Zahurda Rajacieno", min = 37, max = 46 },
    { en = "Uldaman", es = "Uldaman", min = 41, max = 51 },
    { en = "Zul'Farrak", es = "Zul'Farrak", min = 44, max = 54 },
    { en = "Maraudon", es = "Maraudon", min = 46, max = 55 },
    { en = "Sunken Temple", es = "El Templo Sumergido", min = 50, max = 60 },
    { en = "Blackrock Depths", es = "Profundidades de Roca Negra", min = 52, max = 60 },
    { en = "Lower Blackrock Spire", es = "Cumbre inferior de Roca Negra", min = 55, max = 60 },
    { en = "Upper Blackrock Spire", es = "Cumbre de Roca Negra", min = 58, max = 60 },
    { en = "Stratholme", es = "Stratholme", min = 58, max = 60 },
    { en = "Scholomance", es = "Scholomance", min = 58, max = 60 },
    { en = "Dire Maul", es = "La Masacre", min = 58, max = 60 },
    { en = "Hellfire Ramparts", es = "Murallas del Fuego Infernal", min = 60, max = 62 },
    { en = "The Blood Furnace", es = "El Horno de Sangre", min = 61, max = 63 },
    { en = "The Slave Pens", es = "Recinto de los Esclavos", min = 62, max = 64 },
    { en = "The Underbog", es = "La Sotienaga", min = 63, max = 65 },
    { en = "Mana-Tombs", es = "Tumbas de Mana", min = 64, max = 66 },
    { en = "Auchenai Crypts", es = "Criptas Auchenai", min = 65, max = 67 },
    { en = "Sethekk Halls", es = "Salas Sethekk", min = 67, max = 69 },
    { en = "Shadow Labyrinth", es = "Laberinto de las Sombras", min = 69, max = 70 },
    { en = "Utgarde Keep", es = "Fortaleza de Utgarde", min = 69, max = 72 },
    { en = "The Nexus", es = "El Nexo", min = 69, max = 73 },
    { en = "Azjol-Nerub", es = "Azjol-Nerub", min = 72, max = 74 },
    { en = "Ahn'kahet: The Old Kingdom", es = "Ahn'kahet: El Antiguo Reino", min = 73, max = 75 },
    { en = "Drak'Tharon Keep", es = "Fortaleza de Drak'Tharon", min = 74, max = 76 },
    { en = "The Violet Hold", es = "El Bastion Violeta", min = 75, max = 77 },
    { en = "Gundrak", es = "Gundrak", min = 76, max = 78 },
    { en = "Halls of Stone", es = "Camaras de Piedra", min = 77, max = 79 },
    { en = "Halls of Lightning", es = "Camaras de Relampagos", min = 78, max = 80 },
    { en = "Utgarde Pinnacle", es = "Pinaculo de Utgarde", min = 79, max = 80 },
    { en = "The Oculus", es = "El Oculus", min = 79, max = 80 },
    { en = "The Culling of Stratholme", es = "La Matanza de Stratholme", min = 79, max = 80 },
    { en = "Trial of the Champion", es = "Prueba del Campeon", min = 80, max = 80 },
    { en = "Forge of Souls", es = "La Forja de Almas", min = 80, max = 80 },
    { en = "Pit of Saron", es = "Foso de Saron", min = 80, max = 80 },
    { en = "Halls of Reflection", es = "Camaras de Reflexion", min = 80, max = 80 },
}

-- Construcción del mapa indexado
local ZoneLookup = {}

for _, item in ipairs(rawZones) do
    local data = {
        name = item.es or item.en,
        nameEN = item.en,
        min = item.min,
        max = item.max,
        safe = item.safe or false,
    }
    if item.es then
        ZoneLookup[item.es] = data
        ZoneLookup[Normalize(item.es)] = data
    end
    if item.en then
        ZoneLookup[item.en] = data
        ZoneLookup[Normalize(item.en)] = data
    end
    if item.map then
        ZoneLookup[item.map] = data
        ZoneLookup[Normalize(item.map)] = data
    end
end

PA.ZoneLookup = ZoneLookup

function PA:GetZoneLevelData(zoneName)
    if not zoneName or zoneName == "" then return nil end
    local direct = ZoneLookup[zoneName]
    if direct then return direct end
    return ZoneLookup[Normalize(zoneName)]
end
