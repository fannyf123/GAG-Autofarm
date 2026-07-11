--[[
    Config.lua — Default config merger & validator
    Memastikan semua setting punya nilai valid, walau user nggak isi semuanya
]]

local Config = {}

local DEFAULTS = {
    -- Harvest
    ["Auto Harvest"]        = true,
    ["Sell At"]             = 85,
    ["Sell Every"]          = 40,
    ["Only Harvest"]        = {},
    ["Don't Harvest"]       = {},
    ["Wait For Mutation"]   = { "Bamboo", "Mushroom" },

    -- Plant
    ["Auto Plant"]          = true,
    ["Plant Plan"]          = {},
    ["Only Plant"]          = {},
    ["Minimum Seed"]        = "Bamboo",
    ["Layout"]              = "compact",
    ["Don't Plant"]         = {},
    ["Don't Buy"]           = {},
    ["Keep Seeds"]          = {},
    ["Plant Limit"]         = 0,
    ["Never Shovel"]        = {},
    ["Shovel Up To"]        = "",
    ["Buy Seeds"]           = {},

    -- Money
    ["Keep Cash"]           = 15000,
    ["Auto Expand Plot"]    = true,
    ["Max Expansions"]      = 3,
    ["Expand If Over"]      = 1500000,
    ["Auto Replace Plants"] = true,

    -- Never Sell
    ["Never Sell"] = {
        ["By Mutation"] = {},
        ["By Fruit"]    = {},
        ["Exact"]       = {},
    },

    -- Pets
    ["Pets"] = {
        ["Buy"]            = {},
        ["Equip"]          = {},
        ["Auto Buy Slots"] = true,
        ["Max Pet Slots"]  = 6,
    },

    -- Gear
    ["Gear"] = {
        ["Auto Buy"]           = true,
        ["Keep Cash"]          = 15000,
        ["Sprinkler Coverage"] = "concentrate",
        ["Place Sprinklers"]   = { ["best"] = 4 },
        ["Best Sprinkler Up To"] = "Rare Sprinkler",
        ["Keep Gear"]          = {},
        ["Buy Gear"]           = {},
    },

    -- Event Seeds
    ["Event Seeds"] = {
        ["Auto Claim"] = true,
    },

    -- Mail
    ["Mail"] = {
        ["Auto Claim"] = true,
        ["Send To"]    = "",
        ["Send Every"] = 0,
        ["Send"]       = {},
    },

    -- Misc
    ["Misc"] = {
        ["Auto Return To Garden"] = true,
        ["Show Stats"]            = true,
        ["Hide Game UI"]          = false,
        ["Show Console"]          = false,
        ["Smart Travel"]          = true,
        ["Auto Daily Deal"]       = true,
        ["Walk Speed"]            = 0,
        ["Slide Speed"]           = 30,
        ["Fast Travel"]           = false,
        ["Teleport"]              = true,
    },

    -- Friends
    ["Friends"] = {
        ["Auto Accept"] = false,
        ["Auto Send"]   = false,
    },

    -- Performance
    ["Performance"] = {
        ["FPS Cap"]              = 0,
        ["Low Graphics"]         = true,
        ["Remove Other Gardens"] = true,
        ["Hide Crop Visuals"]    = true,
        ["Hide Fruit Visuals"]   = true,
        ["Hide Players"]         = true,
    },

    -- Debug
    ["Debug"] = {
        ["Log To File"] = true,
        ["Console"]     = true,
    },
}

-- Deep merge: user values override defaults
local function DeepMerge(default, user)
    if type(default) ~= "table" or type(user) ~= "table" then
        return user ~= nil and user or default
    end
    local result = {}
    for k, v in pairs(default) do
        if user[k] ~= nil then
            if type(v) == "table" and type(user[k]) == "table" then
                result[k] = DeepMerge(v, user[k])
            else
                result[k] = user[k]
            end
        else
            result[k] = v
        end
    end
    -- Also copy any extra keys user added that aren't in defaults
    for k, v in pairs(user) do
        if result[k] == nil then
            result[k] = v
        end
    end
    return result
end


local Validate, BuildLookupSet

local function Clone(tbl)
    if type(tbl) ~= "table" then return tbl end
    local out = {}
    for k, v in pairs(tbl) do
        out[k] = Clone(v)
    end
    return out
end

local SECTION_MAP = {
    Harvest = { "Auto Harvest", "Sell At", "Sell Every", "Only Harvest", "Don't Harvest", "Wait For Mutation" },
    Planting = { "Auto Plant", "Plant Plan", "Only Plant", "Minimum Seed", "Layout", "Don't Plant", "Don't Buy", "Keep Seeds", "Plant Limit", "Never Shovel", "Shovel Up To", "Buy Seeds" },
    Money = { "Keep Cash", "Auto Expand Plot", "Max Expansions", "Expand If Over", "Auto Replace Plants" },
}

local PRESETS = {
    Starter = {
        Harvest  = { ["Sell At"] = 50, ["Sell Every"] = 20 },
        Planting = { ["Layout"] = "compact", ["Minimum Seed"] = "" },
        Money    = { ["Keep Cash"] = 0, ["Auto Expand Plot"] = true, ["Expand If Over"] = 50000 },
        Pets     = { ["Buy"] = { "Deer", "Robin" }, ["Equip"] = { "Deer" } },
        Gear     = { ["Keep Cash"] = 5000, ["Place Sprinklers"] = { ["Common Sprinkler"] = 4 }, ["Buy Gear"] = { "Super Sprinkler" } },
        Misc     = { ["Auto Return To Garden"] = true },
    },
    Balanced = {
        Harvest  = { ["Sell At"] = 85, ["Sell Every"] = 40 },
        Planting = { ["Layout"] = "compact", ["Minimum Seed"] = "Bamboo", ["Keep Seeds"] = { ["Dragon's Breath"] = 5, ["Moon Bloom"] = 5, Gold = 5, Rainbow = 5 } },
        Money    = { ["Keep Cash"] = 15000, ["Auto Expand Plot"] = true, ["Expand If Over"] = 1500000, ["Auto Replace Plants"] = true },
        Pets     = { ["Buy"] = { "Unicorn", "GoldenDragonfly", Deer = 6 }, ["Equip"] = { "Unicorn", "GoldenDragonfly", "Deer" }, ["Auto Buy Slots"] = true },
        Gear     = { ["Keep Cash"] = 15000, ["Sprinkler Coverage"] = "concentrate", ["Place Sprinklers"] = { best = 4 }, ["Best Sprinkler Up To"] = "Rare Sprinkler" },
        ["Event Seeds"] = { ["Auto Claim"] = true },
        Mail     = { ["Auto Claim"] = true },
        Misc     = { ["Auto Return To Garden"] = true },
    },
    Rich = {
        Harvest  = { ["Sell At"] = 120, ["Sell Every"] = 40 },
        Planting = { ["Layout"] = "compact", ["Plant Plan"] = { ["Dragon Fruit"] = 200, Mango = 200, Grape = 200 }, ["Plant Limit"] = 400, ["Keep Seeds"] = { Gold = 20, Rainbow = 20 } },
        Money    = { ["Keep Cash"] = 500000, ["Auto Expand Plot"] = true, ["Expand If Over"] = 5000000, ["Auto Replace Plants"] = true },
        ["Never Sell"] = { ["By Mutation"] = { "Rainbow", "Starstruck" } },
        Pets     = { ["Buy"] = { "Unicorn", "GoldenDragonfly" }, ["Equip"] = { "Unicorn", "GoldenDragonfly" }, ["Auto Buy Slots"] = true },
        Gear     = { ["Keep Cash"] = 200000, ["Sprinkler Coverage"] = "concentrate", ["Place Sprinklers"] = { best = 6 }, ["Best Sprinkler Up To"] = "Rare Sprinkler" },
        Misc     = { ["Auto Return To Garden"] = true },
    },
    AltToMain = {
        Harvest  = { ["Sell At"] = 85 },
        Planting = { ["Layout"] = "compact" },
        Money    = { ["Keep Cash"] = 0, ["Auto Expand Plot"] = false },
        Mail     = { ["Auto Claim"] = true, ["Send To"] = "USERNAME_AKUN_UTAMAMU", ["Send"] = { "Moon Bloom", "Dragon's Breath", "Gold", "Rainbow", "Unicorn" } },
        Misc     = { ["Auto Return To Garden"] = true },
    },
    LowPC = {
        Performance = { ["FPS Cap"] = 30, ["Low Graphics"] = true, ["Remove Other Gardens"] = true, ["Hide Crop Visuals"] = true, ["Hide Fruit Visuals"] = true, ["Hide Players"] = true },
        Misc = { ["Fast Travel"] = true, ["Hide Game UI"] = true },
    },
}

local function ExpandSections(cfg)
    cfg = Clone(cfg or {})
    for sectionName, keys in pairs(SECTION_MAP) do
        local section = cfg[sectionName]
        if type(section) == "table" then
            for _, key in ipairs(keys) do
                if section[key] ~= nil then
                    cfg[key] = section[key]
                end
            end
        end
        cfg[sectionName] = nil
    end
    return cfg
end

local function NormalizeUserConfig(userCfg)
    userCfg = userCfg or {}
    local presetName = userCfg.Preset or userCfg.preset or _G.GAGPreset
    local merged = {}
    if presetName and PRESETS[presetName] then
        merged = DeepMerge(merged, ExpandSections(PRESETS[presetName]))
    end
    merged = DeepMerge(merged, ExpandSections(userCfg))
    merged.Preset = presetName
    return merged
end

local function FinalizeConfig(cfg)
    cfg = Validate(cfg)
    cfg._Lookup = {
        OnlyHarvest     = BuildLookupSet(cfg["Only Harvest"]),
        DontHarvest     = BuildLookupSet(cfg["Don't Harvest"]),
        WaitForMutation = BuildLookupSet(cfg["Wait For Mutation"]),
        OnlyPlant       = BuildLookupSet(cfg["Only Plant"]),
        DontPlant       = BuildLookupSet(cfg["Don't Plant"]),
        DontBuy         = BuildLookupSet(cfg["Don't Buy"]),
        NeverShovel     = BuildLookupSet(cfg["Never Shovel"]),
        NeverSellMut    = BuildLookupSet(cfg["Never Sell"]["By Mutation"]),
        NeverSellFruit  = BuildLookupSet(cfg["Never Sell"]["By Fruit"]),
    }
    cfg._Lookup.NeverSellExact = {}
    for _, pair in ipairs(cfg["Never Sell"]["Exact"] or {}) do
        if pair.fruit and pair.mut then
            cfg._Lookup.NeverSellExact[pair.fruit .. "|" .. pair.mut] = true
        end
    end
    cfg.Get = Config.Get
    cfg.GetNested = Config.GetNested
    cfg.ShouldHarvest = Config.ShouldHarvest
    cfg.ShouldPlant = Config.ShouldPlant
    cfg.ShouldBuySeed = Config.ShouldBuySeed
    cfg.ShouldShovel = Config.ShouldShovel
    cfg.ShouldNeverSell = Config.ShouldNeverSell
    cfg.Presets = PRESETS
    return cfg
end

-- Validate specific fields
Validate = function(cfg)
    -- Layout must be "compact" or "spread"
    if cfg["Layout"] ~= "compact" and cfg["Layout"] ~= "spread" then
        cfg["Layout"] = "compact"
    end
    -- Shovel Up To must be valid tier or empty
    local validTiers = { [""] = true, ["Common"] = true, ["Uncommon"] = true, ["Rare"] = true, ["Epic"] = true }
    if not validTiers[cfg["Shovel Up To"]] then
        cfg["Shovel Up To"] = ""
    end
    -- Sprinkler Coverage
    local validCoverage = { ["concentrate"] = true, ["value"] = true, ["spread"] = true }
    if not validCoverage[cfg["Gear"]["Sprinkler Coverage"]] then
        cfg["Gear"]["Sprinkler Coverage"] = "concentrate"
    end
    -- Numeric bounds
    cfg["Sell At"] = math.clamp(tonumber(cfg["Sell At"]) or 85, 1, 200)
    cfg["Sell Every"] = math.max(tonumber(cfg["Sell Every"]) or 40, 0)
    cfg["Keep Cash"] = math.max(tonumber(cfg["Keep Cash"]) or 15000, 0)
    cfg["Max Expansions"] = math.max(tonumber(cfg["Max Expansions"]) or 3, 0)
    cfg["Expand If Over"] = math.max(tonumber(cfg["Expand If Over"]) or 1500000, 0)
    cfg["Plant Limit"] = math.max(tonumber(cfg["Plant Limit"]) or 0, 0)
    cfg["Pets"]["Max Pet Slots"] = math.clamp(tonumber(cfg["Pets"]["Max Pet Slots"]) or 6, 3, 6)
    cfg["Misc"]["Walk Speed"] = math.clamp(tonumber(cfg["Misc"]["Walk Speed"]) or 0, 0, 35)
    if cfg["Misc"]["Walk Speed"] > 0 and cfg["Misc"]["Walk Speed"] < 16 then
        cfg["Misc"]["Walk Speed"] = 16
    end
    cfg["Misc"]["Slide Speed"] = math.clamp(tonumber(cfg["Misc"]["Slide Speed"]) or 30, 10, 150)
    cfg["Performance"]["FPS Cap"] = math.max(tonumber(cfg["Performance"]["FPS Cap"]) or 0, 0)

    return cfg
end

-- Convert list-style configs to lookup sets for O(1) checks
BuildLookupSet = function(list)
    if type(list) ~= "table" then return {} end
    local set = {}
    -- Handle both array-style {"A","B"} and map-style {A=1,B=1}
    for k, v in pairs(list) do
        if type(k) == "number" then
            set[v] = true
        elseif type(v) == "boolean" then
            set[k] = v
        else
            set[k] = v
        end
    end
    return set
end

function Config.Init(GAG)
    local userCfg = NormalizeUserConfig(GAG.Config or {})
    local cfg = FinalizeConfig(DeepMerge(DEFAULTS, userCfg))
    GAG.Config = cfg
    GAG.ConfigData = cfg
    GAG.Presets = PRESETS
    print("[GAG/Config] Config loaded and validated" .. (cfg.Preset and (" (preset: " .. tostring(cfg.Preset) .. ")") or ""))
end

function Config.ApplyPreset(GAG, presetName)
    if not PRESETS[presetName] then return false end
    local cfg = FinalizeConfig(DeepMerge(DEFAULTS, ExpandSections(PRESETS[presetName])))
    cfg.Preset = presetName
    GAG.Config = cfg
    GAG.ConfigData = cfg
    _G.GAGConfig = cfg
    _G.GAGPreset = presetName
    return true
end

local function normalizeGetArgs(first, second, ...)
    if type(first) == "table" and type(second) == "string" then
        return second, ...
    end
    return first, second, ...
end

local PATH_ALIASES = {
    ["Harvest.Auto Harvest"] = "Auto Harvest",
    ["Harvest.Sell At"] = "Sell At",
    ["Harvest.Sell Every"] = "Sell Every",
    ["Harvest.Only Harvest"] = "Only Harvest",
    ["Harvest.Don't Harvest"] = "Don't Harvest",
    ["Harvest.Wait For Mutation"] = "Wait For Mutation",
    ["Planting.Auto Plant"] = "Auto Plant",
    ["Planting.Plant Plan"] = "Plant Plan",
    ["Planting.Only Plant"] = "Only Plant",
    ["Planting.Minimum Seed"] = "Minimum Seed",
    ["Planting.Layout"] = "Layout",
    ["Planting.Don't Plant"] = "Don't Plant",
    ["Planting.Don't Buy"] = "Don't Buy",
    ["Planting.Keep Seeds"] = "Keep Seeds",
    ["Planting.Plant Limit"] = "Plant Limit",
    ["Planting.Never Shovel"] = "Never Shovel",
    ["Planting.Shovel Up To"] = "Shovel Up To",
    ["Planting.Buy Seeds"] = "Buy Seeds",
    ["Money.Keep Cash"] = "Keep Cash",
    ["Money.Auto Expand Plot"] = "Auto Expand Plot",
    ["Money.Max Expansions"] = "Max Expansions",
    ["Money.Expand If Over"] = "Expand If Over",
    ["Money.Auto Replace Plants"] = "Auto Replace Plants",
    ["Misc.FPS Cap"] = "Performance.FPS Cap",
    ["Misc.Low Graphics"] = "Performance.Low Graphics",
    ["Misc.Remove Other Gardens"] = "Performance.Remove Other Gardens",
    ["Misc.Hide Crop Visuals"] = "Performance.Hide Crop Visuals",
    ["Misc.Hide Fruit Visuals"] = "Performance.Hide Fruit Visuals",
    ["Misc.Hide Players"] = "Performance.Hide Players",
}

local ALIASES = {
    AutoBuySeeds = "Buy Seeds",
    BuySeeds = "Buy Seeds",
    DontBuy = "Don't Buy",
    ["Don'tBuy"] = "Don't Buy",
    DontPlant = "Don't Plant",
    ["Don'tPlant"] = "Don't Plant",
    OnlyPlant = "Only Plant",
    PlantLayout = "Layout",
    MinSeedTier = "Minimum Seed",
    MinimumSeed = "Minimum Seed",
    AutoPlant = "Auto Plant",
    PlantPlan = "Plant Plan",
    ShouldPlant = "Auto Plant",
    AutoExpandPlot = "Auto Expand Plot",
    KeepCash = "Keep Cash",
    MaxExpansions = "Max Expansions",
    ExpandIfOver = "Expand If Over",
    WaitForMutation = "Wait For Mutation",
    NeverSell = "Never Sell",
    ShouldBuySeed = "Buy Seeds",
    SeedShopPosition = "Seed Shop Position",
    ShopCheckInterval = "Shop Check Interval",
    MinSeedsForPlanting = "Min Seeds For Planting",
    ["Buy Gear"] = "Gear.Buy Gear",
    ["Keep Gear"] = "Gear.Keep Gear",
    ["Place Sprinklers"] = "Gear.Place Sprinklers",
    ["Best Sprinkler Up To"] = "Gear.Best Sprinkler Up To",
    ["Coverage Mode"] = "Gear.Sprinkler Coverage",
}

function Config.Get(first, second, ...)
    local key = normalizeGetArgs(first, second, ...)
    local cfg = _G.GAG and _G.GAG.Config
    if type(key) ~= "string" or type(cfg) ~= "table" then return nil end
    if key:find(".", 1, true) then
        return Config.GetNested(key)
    end
    local value = cfg[key]
    if value ~= nil then return value end
    local alias = ALIASES[key]
    if not alias then return nil end
    if alias:find(".", 1, true) then
        return Config.GetNested(alias)
    end
    return cfg[alias]
end

function Config.GetNested(first, second, third, ...)
    local section, key = normalizeGetArgs(first, second, third, ...)
    local cur = _G.GAG and _G.GAG.Config
    if type(section) ~= "string" or cur == nil then return nil end

    local requested = key == nil and section or (section .. "." .. tostring(key))
    local alias = PATH_ALIASES[requested]
    if alias then
        if alias:find(".", 1, true) then
            return Config.GetNested(alias)
        end
        return Config.Get(alias)
    end

    local parts = {}
    if key == nil and section:find(".", 1, true) then
        for part in string.gmatch(section, "[^%.]+") do
            parts[#parts + 1] = part
        end
    else
        parts[#parts + 1] = section
        if key ~= nil then parts[#parts + 1] = key end
        for _, part in ipairs({...}) do
            parts[#parts + 1] = part
        end
    end

    for _, part in ipairs(parts) do
        if type(cur) ~= "table" then return nil end
        cur = cur[part]
        if cur == nil then return nil end
    end
    return cur
end

function Config.ShouldHarvest(fruitName)
    local cfg = _G.GAG.Config
    local lk = cfg._Lookup
    if not cfg["Auto Harvest"] then return false end
    if #cfg["Only Harvest"] > 0 and not lk.OnlyHarvest[fruitName] then return false end
    if lk.DontHarvest[fruitName] then return false end
    return true
end

function Config.ShouldPlant(plantName)
    local cfg = _G.GAG.Config
    local lk = cfg._Lookup
    if not cfg["Auto Plant"] then return false end
    if #cfg["Only Plant"] > 0 and not lk.OnlyPlant[plantName] then return false end
    if lk.DontPlant[plantName] then return false end
    return true
end

function Config.ShouldBuySeed(seedName)
    local cfg = _G.GAG.Config
    local lk = cfg._Lookup
    if lk.DontPlant[seedName] then return false end
    if lk.DontBuy[seedName] then return false end
    return true
end

function Config.ShouldShovel(plantName, tier)
    local cfg = _G.GAG.Config
    local lk = cfg._Lookup
    if lk.NeverShovel[plantName] then return false end
    -- Shovel Up To tier check
    local tierOrder = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mythic = 6 }
    local maxTier = tierOrder[cfg["Shovel Up To"]]
    if maxTier and tierOrder[tier] and tierOrder[tier] > maxTier then
        return false
    end
    return true
end

function Config.ShouldNeverSell(fruitName, mutationName)
    local cfg = _G.GAG.Config
    local lk = cfg._Lookup
    if mutationName and lk.NeverSellMut[mutationName] then return true end
    if lk.NeverSellFruit[fruitName] then return true end
    if mutationName and lk.NeverSellExact[fruitName .. "|" .. mutationName] then return true end
    return false
end

return Config
