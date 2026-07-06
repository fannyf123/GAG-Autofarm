-- Built by tools/build_delta.py. Do not edit generated output directly.
--[[
    Grow a Garden — Autofarm Script
    Target: Delta Executor (Roblox)
    
    Cara pakai:
      1. Edit _G.GAGConfig di bawah sesuai kebutuhan
      2. Jalankan script ini di Delta
    
    Arsitektur:
      - Semua modul di-load secara berurutan
      - Config diproses duluan, lalu Utils, lalu modul farm
      - Tiap modul punya thread sendiri (coroutine) biar nggak blokir satu sama lain
]]

---------------------------------------------------------------------------
-- 0. CONFIG USER — Edit bagian ini sebelum run
---------------------------------------------------------------------------
_G.GAGConfig = _G.GAGConfig or {
    -- Pilih: "Starter", "Balanced", "Rich", "AltToMain", "LowPC"
    Preset = "Balanced",

    -- Boleh override sebagian saja. Contoh:
    -- ["Mail"] = { ["Send To"] = "USERNAME_AKUN_UTAMAMU" },
    -- ["Performance"] = { ["FPS Cap"] = 30 },
}

-- Contoh config lengkap (uncomment / edit sesuai kebutuhan):
-- _G.GAGConfig = {
--     ["Auto Harvest"]     = true,
--     ["Sell At"]          = 85,
--     ["Sell Every"]       = 40,
--     ["Only Harvest"]     = {},
--     ["Don't Harvest"]    = {},
--     ["Wait For Mutation"] = { "Bamboo", "Mushroom" },
--
--     ["Auto Plant"]       = true,
--     ["Plant Plan"]       = {},
--     ["Only Plant"]       = {},
--     ["Minimum Seed"]     = "Bamboo",
--     ["Layout"]           = "compact",
--     ["Don't Plant"]      = {},
--     ["Don't Buy"]        = {},
--     ["Keep Seeds"]       = {},
--     ["Plant Limit"]      = 0,
--     ["Never Shovel"]     = {},
--     ["Shovel Up To"]     = "",
--     ["Buy Seeds"]        = {},
--
--     ["Keep Cash"]              = 15000,
--     ["Auto Expand Plot"]       = true,
--     ["Max Expansions"]         = 3,
--     ["Expand If Over"]         = 1500000,
--     ["Auto Replace Plants"]    = true,
--
--     ["Never Sell"] = {
--         ["By Mutation"] = { "Rainbow", "Gold" },
--         ["By Fruit"]    = {},
--         ["Exact"]       = {},
--     },
--
--     ["Pets"] = {
--         ["Buy"]            = {},
--         ["Equip"]          = {},
--         ["Auto Buy Slots"] = true,
--         ["Max Pet Slots"]  = 6,
--     },
--
--     ["Gear"] = {
--         ["Auto Buy"]           = true,
--         ["Keep Cash"]          = 15000,
--         ["Sprinkler Coverage"] = "concentrate",
--         ["Place Sprinklers"]   = { ["best"] = 4 },
--         ["Best Sprinkler Up To"] = "Rare Sprinkler",
--         ["Keep Gear"]          = {},
--         ["Buy Gear"]           = {},
--     },
--
--     ["Event Seeds"] = {
--         ["Auto Claim"] = true,
--     },
--
--     ["Mail"] = {
--         ["Auto Claim"] = true,
--         ["Send To"]    = "",
--         ["Send Every"] = 0,
--         ["Send"]       = {},
--     },
--
--     ["Misc"] = {
--         ["Auto Return To Garden"] = true,
--         ["Show Stats"]            = true,
--         ["Hide Game UI"]          = false,
--         ["Show Console"]          = false,
--         ["Smart Travel"]          = true,
--         ["Auto Daily Deal"]       = true,
--         ["Walk Speed"]            = 0,
--         ["Slide Speed"]           = 30,
--         ["Fast Travel"]           = false,
--         ["Teleport"]              = true,
--     },
--
--     ["Friends"] = {
--         ["Auto Accept"] = false,
--         ["Auto Send"]   = false,
--     },
--
--     ["Performance"] = {
--         ["FPS Cap"]              = 0,
--         ["Low Graphics"]         = true,
--         ["Remove Other Gardens"] = true,
--         ["Hide Crop Visuals"]    = true,
--         ["Hide Fruit Visuals"]   = true,
--         ["Hide Players"]         = true,
--     },
--
--     ["Debug"] = {
--         ["Log To File"] = true,
--         ["Console"]     = true,
--     },
-- }

---------------------------------------------------------------------------
-- 1. SERVICE SHORTCUTS
---------------------------------------------------------------------------
local Players        = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local Workspace      = game:GetService("Workspace")
local HttpService    = game:GetService("HttpService")
local StarterGui     = game:GetService("StarterGui")

local LocalPlayer    = Players.LocalPlayer
local Character      = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

---------------------------------------------------------------------------
-- 2. GLOBAL STATE
---------------------------------------------------------------------------
_G.GAG = _G.GAG or {}
local GAG = _G.GAG

GAG.Alive       = true
GAG.Running     = true
GAG.Farming     = true
GAG.Player      = LocalPlayer
GAG.Character   = Character
GAG.HRP         = HumanoidRootPart
GAG.Services    = {
    Players = Players,
    ReplicatedStorage = ReplicatedStorage,
    RunService = RunService,
    UserInputService = UserInputService,
    TweenService = TweenService,
    Workspace = Workspace,
    HttpService = HttpService,
    StarterGui = StarterGui,
}
GAG.Modules     = {}
GAG.Config      = _G.GAGConfig
GAG.State       = GAG.State or {}
GAG.State.Running = true
GAG.State.SeedShopStock = GAG.State.SeedShopStock or {}
GAG.State.BuySeedsDone = GAG.State.BuySeedsDone or {}
GAG.Stats       = {
    Harvested   = 0,
    Sold        = 0,
    Planted     = 0,
    Shoveled    = 0,
    Expanded    = 0,
    Expansions  = 0,
    SeedsBought = 0,
    GearBought  = 0,
    PetsBought  = 0,
    MailSent    = 0,
    MailClaimed = 0,
    Mailed      = 0,
    StartTime   = tick(),
}

-- Character respawn handler
LocalPlayer.CharacterAdded:Connect(function(char)
    GAG.Character = char
    GAG.HRP = char:WaitForChild("HumanoidRootPart")
end)

---------------------------------------------------------------------------
-- 3. LOAD MODULES (inline — no HttpGet needed)
---------------------------------------------------------------------------
local function LoadModule(name, source)
    local fn, compileError = loadstring(source)
    if not fn then
        warn("[GAG] Failed to compile module " .. name .. ": " .. tostring(compileError))
        return nil
    end

    local ok, modOrErr = pcall(fn)
    if not ok then
        warn("[GAG] Failed to run module " .. name .. ": " .. tostring(modOrErr))
        return nil
    end

    local mod = modOrErr
    GAG.Modules[name] = mod
    if name == "Utils" then GAG.Utils = mod end
    if name == "Config" then GAG.ConfigModule = mod end

    if type(mod) == "table" and mod.Init then
        local okInit, initErr = pcall(mod.Init, GAG)
        if not okInit then
            warn("[GAG] Failed to init module " .. name .. ": " .. tostring(initErr))
            return nil
        end
    end

    if name == "Utils" then GAG.Utils = mod end
    if name == "Config" then GAG.ConfigModule = mod end
    return mod
end

-- NOTE: Module sources are injected below by the build script
-- or loaded from individual files if running locally

---------------------------------------------------------------------------
-- 4. BOOT SEQUENCE
---------------------------------------------------------------------------
local function Boot()
    print("[GAG] ==============================")
    print("[GAG] Grow a Garden Autofarm")
    print("[GAG] Loading modules...")
    
    -- Load order matters: Utils first, then Config, then farm modules
    LoadModule("Config",  [=[--[[
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
]=])
    LoadModule("Utils",   [[local Utils = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local GAG = _G.GAG or {}
_G.GAG = GAG

------------------------------------------------------------------------
-- Internal helpers
------------------------------------------------------------------------

local function safeGetRoot()
	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	if not char then return nil, nil end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	return char, hrp, hum
end

local function resolvePosition(pos)
	if typeof(pos) == "CFrame" then
		return pos.Position, pos
	elseif typeof(pos) == "Vector3" then
		return pos, CFrame.new(pos)
	end
	return nil, nil
end

------------------------------------------------------------------------
-- 1. Movement helpers
------------------------------------------------------------------------

function Utils.WalkTo(position, timeout)
	timeout = timeout or 10
	local targetPos = resolvePosition(position)
	if not targetPos then return false end

	local _, hrp, hum = safeGetRoot()
	if not hum then return false end

	local reached = false
	local conn

	conn = hum.MoveToFinished:Connect(function()
		reached = true
	end)

	hum:MoveTo(targetPos)

	local elapsed = 0
	while not reached and elapsed < timeout do
		if not GAG.Alive then
			conn:Disconnect()
			return false
		end
		local dist = (hrp.Position * Vector3.new(1, 0, 1) - targetPos * Vector3.new(1, 0, 1)).Magnitude
		if dist < 3 then
			reached = true
			break
		end
		task.wait(0.1)
		elapsed = elapsed + 0.1
	end

	if conn.Connected then
		conn:Disconnect()
	end
	return reached
end

function Utils.TeleportTo(position)
	local _, hrp = safeGetRoot()
	if not hrp then return false end

	if typeof(position) == "CFrame" then
		hrp.CFrame = position
	elseif typeof(position) == "Vector3" then
		hrp.CFrame = CFrame.new(position)
	else
		return false
	end
	return true
end

function Utils.SlideTo(position, speed)
	speed = speed or 60
	local targetPos = resolvePosition(position)
	if not targetPos then return false end

	local char, hrp, hum = safeGetRoot()
	if not hrp or not hum then return false end

	local originalCollisions = {}
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			originalCollisions[part] = part.CanCollide
			part.CanCollide = false
		end
	end

	hum.WalkSpeed = 0

	local startPos = hrp.Position
	local distance = (targetPos - startPos).Magnitude
	local duration = distance / speed

	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(targetPos)})
	tween:Play()

	local completed = false
	local conn
	conn = tween.Completed:Connect(function()
		completed = true
	end)

	while not completed do
		if not GAG.Alive then
			tween:Cancel()
			break
		end
		task.wait(0.05)
	end

	if conn and conn.Connected then conn:Disconnect() end

	for part, canCollide in pairs(originalCollisions) do
		if part and part.Parent then
			part.CanCollide = canCollide
		end
	end

	return completed
end

function Utils.SmartWalkTo(position, cfg)
	cfg = cfg or {}
	local fastTravel = cfg.FastTravel or cfg.Slide

	if fastTravel then
		local speed = cfg.SlideSpeed or 60
		return Utils.SlideTo(position, speed)
	end

	local timeout = cfg.WalkTimeout or 10
	return Utils.WalkTo(position, timeout)
end

------------------------------------------------------------------------
-- 2. Game interaction helpers
------------------------------------------------------------------------

function Utils.FindFirstChildByClass(parent, className, name)
	if not parent then return nil end
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA(className) and child.Name == name then
			return child
		end
	end
	return nil
end

function Utils.GetCharacter(retries, delay)
	retries = retries or 10
	delay = delay or 0.5

	for i = 1, retries do
		local char = LocalPlayer.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hrp and hum and hum.Health > 0 then
				return char, hrp, hum
			end
		end
		task.wait(delay)
	end
	return nil, nil, nil
end

function Utils.GetFarm()
	local farm = nil

	for _, obj in ipairs(workspace:GetChildren()) do
		if obj.Name:lower():find("farm") or obj.Name:lower():find("plot") then
			local owner = obj:FindFirstChild("Owner") or obj:FindFirstChild("OwnerValue")
			if owner then
				if owner:IsA("StringValue") and owner.Value == LocalPlayer.Name then
					return obj
				end
				if owner:IsA("ObjectValue") and owner.Value == LocalPlayer then
					return obj
				end
			end
		end
	end

	local farmsFolder = workspace:FindFirstChild("Farms") or workspace:FindFirstChild("Plots") or workspace:FindFirstChild("Gardens")
	if farmsFolder then
		for _, plot in ipairs(farmsFolder:GetChildren()) do
			local owner = plot:FindFirstChild("Owner") or plot:FindFirstChild("OwnerValue")
			if owner then
				if owner:IsA("StringValue") and owner.Value == LocalPlayer.Name then
					return plot
				end
				if owner:IsA("ObjectValue") and owner.Value == LocalPlayer then
					return plot
				end
			end
			if plot.Name == LocalPlayer.Name then
				return plot
			end
		end
	end

	local playerFolder = workspace:FindFirstChild(LocalPlayer.Name)
	if playerFolder then
		local possibleFarm = playerFolder:FindFirstChild("Farm") or playerFolder:FindFirstChild("Plot") or playerFolder:FindFirstChild("Garden")
		if possibleFarm then return possibleFarm end
	end

	return nil
end

function Utils.GetPlants(farm)
	farm = farm or Utils.GetFarm()
	if not farm then return {} end
	local plants = {}

	local plantsFolder = farm:FindFirstChild("Plants") or farm:FindFirstChild("Crops") or farm:FindFirstChild("Planted")
	if plantsFolder then
		for _, plant in ipairs(plantsFolder:GetChildren()) do
			table.insert(plants, plant)
		end
		return plants
	end

	for _, child in ipairs(farm:GetDescendants()) do
		if child:IsA("Model") or child:IsA("BasePart") then
			if child:FindFirstChild("PlantData") or child:FindFirstChild("Growth") or child:GetAttribute("IsPlant") then
				table.insert(plants, child)
			end
		end
	end

	return plants
end

function Utils.GetFruits(plant)
	if not plant then return {} end
	local fruits = {}

	local fruitsFolder = plant:FindFirstChild("Fruits") or plant:FindFirstChild("Harvestable")
	if fruitsFolder then
		for _, fruit in ipairs(fruitsFolder:GetChildren()) do
			table.insert(fruits, fruit)
		end
		return fruits
	end

	for _, child in ipairs(plant:GetChildren()) do
		if child:GetAttribute("IsFruit") or child:GetAttribute("Harvestable") then
			table.insert(fruits, child)
		elseif child.Name:lower():find("fruit") then
			table.insert(fruits, child)
		end
	end

	return fruits
end

function Utils.GetInventory()
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	if backpack then
		local items = {}
		for _, item in ipairs(backpack:GetChildren()) do
			table.insert(items, item)
		end
		return items
	end
	return {}
end

function Utils.GetSeedList()
	local seeds = {}

	local shopGui = LocalPlayer:FindFirstChild("PlayerGui")
	if shopGui then
		local seedShop = shopGui:FindFirstChild("SeedShop", true)
		if seedShop then
			for _, seed in ipairs(seedShop:GetDescendants()) do
				if seed:GetAttribute("SeedName") then
					table.insert(seeds, {
						Name = seed:GetAttribute("SeedName"),
						Stock = seed:GetAttribute("Stock") or 0,
						Price = seed:GetAttribute("Price") or 0,
					})
				end
			end
		end
	end

	if #seeds == 0 then
		local seedFolder = ReplicatedStorage:FindFirstChild("Seeds") or ReplicatedStorage:FindFirstChild("SeedData")
		if seedFolder then
			for _, seed in ipairs(seedFolder:GetChildren()) do
				table.insert(seeds, {Name = seed.Name, Stock = 0, Price = 0})
			end
		end
	end

	return seeds
end

function Utils.GetShopItems(shopName)
	local items = {}

	local shopGui = LocalPlayer:FindFirstChild("PlayerGui")
	if shopGui then
		local shopFrame = shopGui:FindFirstChild(shopName, true)
		if shopFrame then
			for _, item in ipairs(shopFrame:GetDescendants()) do
				if item:GetAttribute("ItemName") or item:IsA("TextButton") or item:IsA("Frame") then
					local name = item:GetAttribute("ItemName") or item.Name
					if name and name ~= "" then
						table.insert(items, {
							Name = name,
							Price = item:GetAttribute("Price") or 0,
							Stock = item:GetAttribute("Stock") or 0,
						})
					end
				end
			end
		end
	end

	return items
end

------------------------------------------------------------------------
-- 3. Raycast / positioning
------------------------------------------------------------------------

function Utils.RaycastGround(position)
	local rayOrigin = Vector3.new(position.X, position.Y + 100, position.Z)
	local rayDirection = Vector3.new(0, -500, 0)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	local char = LocalPlayer.Character
	if char then
		params.FilterDescendantsInstances = {char}
	end

	local result = workspace:Raycast(rayOrigin, rayDirection, params)
	if result then
		return result.Position, result.Instance
	end

	return Vector3.new(position.X, position.Y, position.Z), nil
end

function Utils.GetPlotPositions(farm)
	if not farm then return {} end

	local positions = {}
	local primary = farm.PrimaryPart or farm:FindFirstChildWhichIsA("BasePart")
	if not primary then return {} end

	local farmPos = primary.Position
	local farmSize = primary.Size

	local plotSize = 4
	local cols = math.floor(farmSize.X / plotSize)
	local rows = math.floor(farmSize.Z / plotSize)

	local startX = farmPos.X - (cols * plotSize) / 2 + plotSize / 2
	local startZ = farmPos.Z - (rows * plotSize) / 2 + plotSize / 2

	for row = 0, rows - 1 do
		for col = 0, cols - 1 do
			local worldPos = Vector3.new(
				startX + col * plotSize,
				farmPos.Y,
				startZ + row * plotSize
			)
			local groundPos = Utils.RaycastGround(worldPos)
			table.insert(positions, {
				Position = groundPos,
				Row = row,
				Col = col,
				Taken = false,
			})
		end
	end

	return positions
end

function Utils.CalculateSprinklerPositions(farm, count, coverage)
	count = count or 4
	coverage = coverage or 20

	if not farm then return {} end
	local primary = farm.PrimaryPart or farm:FindFirstChildWhichIsA("BasePart")
	if not primary then return {} end

	local farmPos = primary.Position
	local farmSize = primary.Size

	local sprinklerPositions = {}

	if count == 1 then
		table.insert(sprinklerPositions, farmPos)
	elseif count == 2 then
		table.insert(sprinklerPositions, farmPos + Vector3.new(-farmSize.X / 4, 0, 0))
		table.insert(sprinklerPositions, farmPos + Vector3.new(farmSize.X / 4, 0, 0))
	else
		local cols = math.ceil(math.sqrt(count))
		local rows = math.ceil(count / cols)
		local spacingX = farmSize.X / (cols + 1)
		local spacingZ = farmSize.Z / (rows + 1)

		local idx = 0
		for row = 1, rows do
			for col = 1, cols do
				idx = idx + 1
				if idx > count then break end
				local pos = farmPos + Vector3.new(
					-col * spacingX + (cols + 1) * spacingX / 2,
					0,
					-row * spacingZ + (rows + 1) * spacingZ / 2
				)
				local groundPos = Utils.RaycastGround(pos)
				table.insert(sprinklerPositions, groundPos)
			end
		end
	end

	return sprinklerPositions
end

------------------------------------------------------------------------
-- 4. Remote helpers
------------------------------------------------------------------------

local REMOTE_ALIASES = {
	-- Plant / garden (from plant.txt)
	PlantSeed = "Networking.Plant.PlantSeed",
	Plant = "Networking.Plant.PlantSeed",
	ShovelPlant = "Networking.Trowel.MovePlant",
	MovePlant = "Networking.Trowel.MovePlant",

	-- Gear shop (from gearshop.txt)
	BuyGear = "Networking.GearShop.PurchaseGear",
	PurchaseGear = "Networking.GearShop.PurchaseGear",
	EquipGear = "Networking.GearShop.EquipGear",
	UnequipGear = "Networking.GearShop.UnequipGear",
	RequestEquippableState = "Networking.GearShop.RequestEquippableState",

	-- Seed shop (from record.txt)
	BuySeed = "Networking.SeedShop.PurchaseSeed",
	PurchaseSeed = "Networking.SeedShop.PurchaseSeed",
	RefreshShop = "Networking.SeedShop.PersonalRestock",

	-- Mailbox (from mail.txt)
	OpenMailbox = "Networking.Mailbox.OpenInbox",
	OpenInbox = "Networking.Mailbox.OpenInbox",
	ClaimMail = "Networking.Mailbox.Claim",
	Claim = "Networking.Mailbox.Claim",
	SendMail = "Networking.Mailbox.Send",
	MailboxSend = "Networking.Mailbox.Send",
	SendBatchMail = "Networking.Mailbox.SendBatch",
	MailboxList = "Networking.Mailbox.List",
	LookupPlayer = "Networking.Mailbox.LookupPlayer",

	-- Pets (from pet.txt)
	EquipPet = "Networking.Pets.RequestEquipByName",
	PetEquip = "Networking.Pets.RequestEquipByName",
	RequestEquipByName = "Networking.Pets.RequestEquipByName",
	UnequipPet = "Networking.Pets.RequestUnequipByName",
	PetUnequip = "Networking.Pets.RequestUnequipByName",
	RequestUnequipByName = "Networking.Pets.RequestUnequipByName",
	BuyPetSlot = "Networking.Pets.RequestPurchasePetSlot",
	PurchasePetSlot = "Networking.Pets.RequestPurchasePetSlot",
	RequestPurchasePetSlot = "Networking.Pets.RequestPurchasePetSlot",
	GetEquippedPets = "Networking.Pets.GetEquippedPets",
	SnapPets = "Networking.Pets.SnapPets",
	WildPetTame = "Networking.Pets.WildPetTame",

	-- Seed pack (from seedpack.txt)
	OpenSeedPack = "Networking.SeedPack.OpenSeedPack",
	ClickPack = "Networking.SeedPack.ClickPack",
	ConfirmSeedPack = "Networking.SeedPack.ConfirmSeedPack",
	ClaimSeedPackSpawn = "Networking.SeedPackSpawn.Claimed",

	-- Auction (from Auctioneer.txt)
	AuctionPurchaseLot = "Networking.Auctioneer.PurchaseLot",
	AuctioneerPurchaseLot = "Networking.Auctioneer.PurchaseLot",
	AuctionSnapshot = "Networking.Auctioneer.RequestSnapshot",
	RequestAuctionSnapshot = "Networking.Auctioneer.RequestSnapshot",
	BuyAuctionItem = "Networking.Guild.BuyAuctionItem",
	GetAuctionManifest = "Networking.Guild.GetAuctionManifest",
}

local function normalizeRemoteName(name)
	if type(name) == "table" then
		if #name > 0 then
			name = table.concat(name, ".")
		else
			return nil
		end
	end
	if type(name) ~= "string" then return nil end
	return REMOTE_ALIASES[name] or name
end

local function findByPath(root, path)
	local current = root
	for part in string.gmatch(path, "[^%.]+") do
		if part ~= "ReplicatedStorage" and part ~= "game" then
			current = current and current:FindFirstChild(part)
			if not current then return nil end
		end
	end
	return current
end

function Utils.FindRemote(name)
	name = normalizeRemoteName(name)
	if not name then return nil end

	local exact = findByPath(ReplicatedStorage, name)
	if exact and (exact:IsA("RemoteEvent") or exact:IsA("RemoteFunction")) then
		return exact
	end

	local leaf = name:match("([^%.]+)$") or name
	local function search(container)
		for _, child in ipairs(container:GetDescendants()) do
			if (child:IsA("RemoteEvent") or child:IsA("RemoteFunction")) then
				local childName = child.Name:lower()
				if childName == leaf:lower() or childName:find(leaf:lower(), 1, true) then
					return child
				end
			end
		end
		return nil
	end

	local found = search(ReplicatedStorage)
	if found then return found end

	local char = LocalPlayer.Character
	if char then
		for _, child in ipairs(char:GetDescendants()) do
			if (child:IsA("RemoteEvent") or child:IsA("RemoteFunction")) and child.Name:lower():find(leaf:lower(), 1, true) then
				return child
			end
		end
	end

	return nil
end

function Utils.FireRemote(remoteName, ...)
	remoteName = normalizeRemoteName(remoteName)
	local remote = Utils.FindRemote(remoteName)
	if not remote then
		Utils.Log("Remote", "RemoteEvent not found: " .. tostring(remoteName))
		return false
	end
	if remote:IsA("RemoteFunction") then
		local ok = pcall(function() remote:InvokeServer(...) end)
		return ok
	end
	if not remote:IsA("RemoteEvent") then
		Utils.Log("Remote", "Not a RemoteEvent: " .. tostring(remoteName))
		return false
	end

	local ok, err = pcall(function()
		remote:FireServer(...)
	end)
	if not ok then
		Utils.Log("Remote", "FireServer failed for " .. tostring(remoteName) .. ": " .. tostring(err))
		return false
	end
	return true
end

function Utils.InvokeRemote(remoteName, ...)
	remoteName = normalizeRemoteName(remoteName)
	local remote = Utils.FindRemote(remoteName)
	if not remote then
		Utils.Log("Remote", "RemoteFunction not found: " .. tostring(remoteName))
		return nil
	end
	if not remote:IsA("RemoteFunction") then
		Utils.Log("Remote", "Not a RemoteFunction: " .. tostring(remoteName))
		return nil
	end

	local ok, result = pcall(function()
		return remote:InvokeServer(...)
	end)
	if not ok then
		Utils.Log("Remote", "InvokeServer failed for " .. tostring(remoteName) .. ": " .. tostring(result))
		return nil
	end
	return result
end

------------------------------------------------------------------------
-- 5. UI helpers
------------------------------------------------------------------------

function Utils.Notify(title, text)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = title or "GAG",
			Text = text or "",
			Duration = 4,
		})
	end)
end

function Utils.Log(tag, message, cfg)
	cfg = cfg or {}
	local debugCfg = cfg.Debug or GAG.Debug or {}
	local enabled = debugCfg.Enabled
	if enabled == nil then enabled = true end
	if not enabled then return end

	local timestamp = os.date("%H:%M:%S")
	local prefix = string.format("[%s][%s] %s", timestamp, tag or "Log", message or "")

	if debugCfg.Console ~= false then
		print(prefix)
	end

	if debugCfg.LogFile and typeof(debugCfg.LogFile) == "string" then
		pcall(function()
			local logService = game:GetService("LogService")
		end)
	end
end

------------------------------------------------------------------------
-- 6. Utility
------------------------------------------------------------------------

function Utils.WaitForReady(timeout)
	timeout = timeout or 30

	local char, hrp, hum = Utils.GetCharacter(math.ceil(timeout / 0.5), 0.5)
	if not char or not hrp or not hum then
		Utils.Log("Ready", "Character not ready within timeout")
		return false
	end

	if not LocalPlayer:FindFirstChild("PlayerGui") then
		LocalPlayer:WaitForChild("PlayerGui", timeout)
	end

	GAG.Alive = true
	Utils.Log("Ready", "Game ready")
	return true
end

function Utils.SafeCall(fn, ...)
	if type(fn) ~= "function" then return nil, "not a function" end

	local args = {...}
	local maxRetries = 3
	local lastErr

	for attempt = 1, maxRetries do
		local results = {pcall(fn, unpack(args))}
		local ok = results[1]
		if ok then
			return unpack(results, 2)
		end
		lastErr = results[2]
		if attempt < maxRetries then
			task.wait(0.2 * attempt)
		end
	end

	Utils.Log("SafeCall", "Failed after " .. maxRetries .. " retries: " .. tostring(lastErr))
	return nil, lastErr
end

function Utils.IsInList(item, list)
	if not list then return false end

	if type(list) == "table" then
		if list[item] ~= nil then
			return true
		end
		for _, v in ipairs(list) do
			if v == item then
				return true
			end
		end
	end

	return false
end

function Utils.GetTierOrder()
	return {
		Common = 1,
		Uncommon = 2,
		Rare = 3,
		Epic = 4,
		Legendary = 5,
		Mythic = 6,
	}
end

function Utils.Sleep(seconds)
	if not seconds or seconds <= 0 then return end
	local elapsed = 0
	while elapsed < seconds do
		if not GAG.Alive then return end
		local step = math.min(0.1, seconds - elapsed)
		task.wait(step)
		elapsed = elapsed + step
	end
end


function Utils.GetMoney()
	local data = GAG.Data or {}
	local sheckles = tonumber(data.Sheckles)
	if sheckles then return sheckles end
	local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
	if leaderstats then
		local cash = leaderstats:FindFirstChild("Cash") or leaderstats:FindFirstChild("Sheckles") or leaderstats:FindFirstChild("Money")
		if cash then return tonumber(cash.Value) or 0 end
	end
	return 0
end

return Utils
]])
    LoadModule("Harvest", [=[--[[
	Harvest Module - Grow a Garden Autofarm
	Handles auto-harvesting fruits from plants and auto-selling inventory.
]]

local Harvest = {}

-- Private state
local running = false
local sellTimer = 0

-- References (set on Init)
local GAG = nil
local Config = nil
local Utils = nil

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function Log(msg)
	if Utils and Utils.Log then
		Utils.Log("[Harvest] " .. tostring(msg))
	end
end

local function GetConfig(key)
	if Config and Config.Get then
		return Config.Get(key)
	end
	return nil
end

local function Sleep(seconds)
	if Utils and Utils.Sleep then
		Utils.Sleep(seconds)
	else
		task.wait(seconds or 1)
	end
end

---------------------------------------------------------------------------
-- GetInventoryFruitCount
-- Returns the number of fruits currently in the player's backpack.
---------------------------------------------------------------------------

function Harvest.GetInventoryFruitCount()
	local player = GAG and GAG.Player
	if not player then return 0 end

	local success, count = pcall(function()
		local backpack = player:FindFirstChild("Backpack")
		if not backpack then return 0 end

		local total = 0
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") and item:GetAttribute("IsFruit") then
				total = total + 1
			end
		end

		return total
	end)

	if success then
		return count
	end

	return 0
end

---------------------------------------------------------------------------
-- ShouldWaitForMutation
-- Returns true if the plant is configured to wait for a mutation
-- but the current fruit has no mutation applied yet.
---------------------------------------------------------------------------

local function ShouldWaitForMutation(plant)
	local waitMut = GetConfig("Wait For Mutation")
	if not waitMut or type(waitMut) ~= "table" then return false end

	local plantName = plant.Name or plant:GetAttribute("PlantName") or ""
	if not waitMut[plantName] then return false end

	local fruits = nil
	local ok = pcall(function()
		if Utils and Utils.GetFruits then
			fruits = Utils.GetFruits(plant)
		end
	end)

	if not ok or not fruits then return false end

	for _, fruit in ipairs(fruits) do
		local mutated = fruit:GetAttribute("Mutated") or fruit:GetAttribute("HasMutation")
		if not mutated then
			return true -- at least one fruit lacks mutation, keep waiting
		end
	end

	return false
end

---------------------------------------------------------------------------
-- HarvestPlant
-- Walks to a single plant and harvests all ready fruits.
---------------------------------------------------------------------------

function Harvest.HarvestPlant(plant)
	if not plant then return false end

	local plantName = plant.Name or plant:GetAttribute("PlantName") or "Unknown"

	-- Check if we should harvest this plant
	if Config and Config.ShouldHarvest then
		if not Config.ShouldHarvest(plantName) then
			return false
		end
	end

	-- Check "Should Never Sell" list — if fruit is protected, still harvest
	-- but log a note. We don't skip harvesting, we just won't sell later.
	if Config and Config.ShouldNeverSell then
		if Config.ShouldNeverSell(plantName) then
			Log("Plant '" .. plantName .. "' is on protected list — harvesting but will not sell.")
		end
	end

	-- Wait-for-mutation check
	if ShouldWaitForMutation(plant) then
		Log("Skipping '" .. plantName .. "' — waiting for mutation.")
		return false
	end

	-- Walk to the plant
	local success = pcall(function()
		if Utils and Utils.WalkTo then
			local pos = plant:GetPivot and plant:GetPivot().Position
				or plant.PrimaryPart and plant.PrimaryPart.Position
				or plant:FindFirstChild("HumanoidRootPart") and plant.HumanoidRootPart.Position

			if pos then
				Utils.WalkTo(pos)
			end
		end
	end)

	if not success then
		Log("Failed to walk to plant '" .. plantName .. "'.")
		return false
	end

	-- Brief settle delay after walking
	task.wait(0.3)

	-- Interact with the plant to harvest
	local harvestSuccess = pcall(function()
		-- Try common interaction patterns
		local remote = plant:FindFirstChild("HarvestRemote")
			or plant:FindFirstChildWhichIsA("RemoteEvent", true)

		if remote and remote:IsA("RemoteEvent") then
			remote:FireServer()
		else
			-- Try proximity prompt
			local prompt = plant:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt then
				prompt:InputHoldBegin()
				task.wait(prompt.HoldDuration or 0.2)
				prompt:InputHoldEnd()
			end
		end
	end)

	if harvestSuccess then
		GAG.Stats.Harvested = (GAG.Stats.Harvested or 0) + 1
		Log("Harvested: " .. plantName .. " (Total: " .. GAG.Stats.Harvested .. ")")
		task.wait(0.2)
		return true
	end

	Log("Failed to interact with plant '" .. plantName .. "'.")
	return false
end

---------------------------------------------------------------------------
-- SellFruits
-- Walks/teleports to the sell NPC and sells the entire inventory.
---------------------------------------------------------------------------

function Harvest.SellFruits()
	Log("Selling fruits...")

	local player = GAG and GAG.Player
	local hrp = GAG and GAG.HRP
	if not player or not hrp then return false end

	local soldCount = Harvest.GetInventoryFruitCount()

	-- Find sell area
	local sellNPC = nil
	local ok = pcall(function()
		local workspace = game:GetService("Workspace")
		local sellFolder = workspace:FindFirstChild("SellArea")
			or workspace:FindFirstChild("SellNPC")
			or workspace:FindFirstChild("Shop")
			or workspace:FindFirstChild("Sell")

		if sellFolder then
			sellNPC = sellFolder:FindFirstChildWhichIsA("Model")
				or sellFolder:FindFirstChild("NPC")
				or sellFolder
		end

		-- Fallback: search by name
		if not sellNPC then
			for _, obj in ipairs(workspace:GetDescendants()) do
				if obj.Name == "SellNPC" or obj.Name == "Sell" then
					sellNPC = obj
					break
				end
			end
		end
	end)

	if not sellNPC then
		Log("Could not find sell NPC!")
		return false
	end

	-- Teleport or walk to sell NPC
	ok = pcall(function()
		local sellPos = nil

		if sellNPC:IsA("Model") then
			sellPos = sellNPC:GetPivot and sellNPC:GetPivot().Position
				or sellNPC.PrimaryPart and sellNPC.PrimaryPart.Position
		elseif sellNPC:IsA("BasePart") then
			sellPos = sellNPC.Position
		end

		if sellPos then
			if Utils and Utils.TeleportTo then
				Utils.TeleportTo(sellPos)
			elseif Utils and Utils.WalkTo then
				Utils.WalkTo(sellPos)
			end
		end
	end)

	task.wait(0.5)

	-- Interact with sell NPC
	local sellSuccess = pcall(function()
		local remote = sellNPC:FindFirstChild("SellRemote")
			or sellNPC:FindFirstChildWhichIsA("RemoteEvent", true)

		if remote and remote:IsA("RemoteEvent") then
			remote:FireServer()
		else
			local prompt = sellNPC:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt then
				prompt:InputHoldBegin()
				task.wait(prompt.HoldDuration or 0.3)
				prompt:InputHoldEnd()
			end
		end
	end)

	if sellSuccess then
		GAG.Stats.Sold = (GAG.Stats.Sold or 0) + soldCount
		Log("Sold " .. soldCount .. " fruits. (Total sold: " .. GAG.Stats.Sold .. ")")
		sellTimer = 0
		return true
	end

	Log("Failed to sell fruits.")
	return false
end

---------------------------------------------------------------------------
-- GetPlantsSortedByPriority
-- Returns plants sorted: mutated first, then by name.
---------------------------------------------------------------------------

local function GetPlantsSortedByPriority(plants)
	if not plants then return {} end

	table.sort(plants, function(a, b)
		local aMutated = a:GetAttribute("Mutated") or a:GetAttribute("HasMutation") or false
		local bMutated = b:GetAttribute("Mutated") or b:GetAttribute("HasMutation") or false

		if aMutated and not bMutated then return true end
		if not aMutated and bMutated then return false end

		local aName = a.Name or ""
		local bName = b.Name or ""
		return aName < bName
	end)

	return plants
end

---------------------------------------------------------------------------
-- ShouldSellNow
-- Returns true if inventory is full enough or the sell timer has elapsed.
---------------------------------------------------------------------------

local function ShouldSellNow()
	local sellAt = GetConfig("Sell At") or 50
	local sellEvery = GetConfig("Sell Every") or 300

	local fruitCount = Harvest.GetInventoryFruitCount()

	if fruitCount >= sellAt then
		Log("Inventory at " .. fruitCount .. " >= Sell At (" .. sellAt .. ").")
		return true
	end

	if sellTimer >= sellEvery then
		Log("Sell timer reached " .. sellEvery .. "s.")
		return true
	end

	return false
end

---------------------------------------------------------------------------
-- Init
-- Called once to set up module references.
---------------------------------------------------------------------------

function Harvest.Init(gag)
	GAG = gag
	Config = GAG and GAG.Modules and GAG.Modules.Config
	Utils = GAG and GAG.Modules and GAG.Modules.Utils

	Log("Harvest module initialized.")
end

---------------------------------------------------------------------------
-- Start
-- Main loop: scan, harvest, sell, repeat.
---------------------------------------------------------------------------

function Harvest.Start(gag)
	if running then
		Log("Already running!")
		return
	end

	if gag then
		Harvest.Init(gag)
	end

	running = true
	sellTimer = 0
	Log("Harvest loop started.")

	while running do
		local loopStart = tick()

		pcall(function()
			-- Gather plants from the farm
			local plants = nil
			if Utils and Utils.GetPlants then
				plants = Utils.GetPlants()
			elseif Utils and Utils.GetFarm then
				local farm = Utils.GetFarm()
				if farm then
					plants = farm:GetChildren()
				end
			end

			if plants and #plants > 0 then
				-- Sort by priority (mutations first)
				plants = GetPlantsSortedByPriority(plants)

				-- Harvest each ready plant
				for _, plant in ipairs(plants) do
					if not running then break end

					-- Check if plant is ready (has fruits)
					local hasFruits = false
					pcall(function()
						if Utils and Utils.GetFruits then
							local fruits = Utils.GetFruits(plant)
							hasFruits = fruits and #fruits > 0
						else
							local fruitsFolder = plant:FindFirstChild("Fruits")
							hasFruits = fruitsFolder and #fruitsFolder:GetChildren() > 0
						end
					end)

					if hasFruits then
						Harvest.HarvestPlant(plant)

						-- Check sell condition after each harvest batch
						if ShouldSellNow() then
							Harvest.SellFruits()
						end
					end
				end
			end

			-- Also check sell on timer even if no plants were harvested this tick
			if ShouldSellNow() then
				Harvest.SellFruits()
			end
		end)

		-- Update sell timer
		local elapsed = tick() - loopStart
		sellTimer = sellTimer + elapsed

		-- Sleep between iterations
		Sleep(GetConfig("Harvest Interval") or 2)
	end

	Log("Harvest loop stopped.")
end

---------------------------------------------------------------------------
-- Stop
-- Gracefully stops the main loop.
---------------------------------------------------------------------------

function Harvest.Stop()
	running = false
	Log("Harvest stop requested.")
end

---------------------------------------------------------------------------
-- IsRunning
---------------------------------------------------------------------------

function Harvest.IsRunning()
	return running
end

return Harvest]=])
    LoadModule("Plant",   [[local Plant = {}

local GAG

local SEED_TIERS = {
	Common = 1,
	Uncommon = 2,
	Rare = 3,
	Epic = 4,
	Legendary = 5,
	Mythic = 6,
}

local LAYOUT_OFFSETS = {
	compact = { x = 2.5, z = 2.5 },
	spread = { x = 4.5, z = 4.5 },
}

local pendingShovel = {}

local function TierValue(name)
	if not name then return 0 end
	for tName, val in pairs(SEED_TIERS) do
		if string.find(string.lower(name), string.lower(tName)) then
			return val
		end
	end
	return 1
end

local function HasMutation(plant)
	if not plant then return false end
	local attrs = plant:GetAttributes()
	for attr, val in pairs(attrs) do
		if string.find(string.lower(attr), "mutation") and val then
			return true
		end
	end
	local success, mutation = pcall(function()
		return plant:GetAttribute("Mutation") or plant:GetAttribute("Mutated")
	end)
	return success and mutation ~= nil and mutation ~= false
end

local function IsMegaSize(plant)
	if not plant then return false end
	local success, size = pcall(function()
		return plant:GetAttribute("Size") or plant:GetAttribute("PlantSize")
	end)
	if success and size then
		return string.lower(tostring(size)) == "mega"
	end
	return false
end

local function IsInPlantPlan(seedName)
	local plan = GAG.Config.Get("Plant Plan")
	if not plan then return false end
	for _, entry in ipairs(plan) do
		if entry == seedName or (type(entry) == "table" and entry.Name == seedName) then
			return true
		end
	end
	return false
end

local function IsNeverSell(seedName)
	local list = GAG.Config.GetNested("Never Sell", "By Fruit")
	if not list then return false end
	for _, name in ipairs(list) do
		if name == seedName then
			return true
		end
	end
	return false
end

local function IsWaitForMutation(plant, seedName)
	local list = GAG.Config.Get("Wait For Mutation")
	if not list then return false end
	for _, entry in ipairs(list) do
		if entry == seedName or (type(entry) == "table" and entry.Name == seedName) then
			return true
		end
	end
	if not HasMutation(plant) then
		local wfmut = false
		if wfmut then
			return true
		end
	end
	return false
end

local function IsNeverShovel(seedName)
	if IsInPlantPlan(seedName) then return true end
	if IsNeverSell(seedName) then return true end
	local list = GAG.Config.Get("Never Shovel")
	if not list then return false end
	for _, name in ipairs(list) do
		if name == seedName then
			return true
		end
	end
	return false
end

local function ShouldSkipPlant(plant)
	local seedName = plant:GetAttribute("SeedName") or plant.Name
	if HasMutation(plant) then return true, "has mutation" end
	if IsMegaSize(plant) then return true, "mega size" end
	if IsNeverShovel(seedName) then return true, "never shovel" end
	if IsWaitForMutation(plant, seedName) then return true, "wait for mutation" end
	local tier = TierValue(seedName)
	if tier >= SEED_TIERS.Legendary then return true, "legendary+ tier" end
	return false, nil
end

local function GetPlotOrigin()
	local farm = GAG.Modules.Utils.GetFarm()
	if not farm then return Vector3.new(0, 0, 0) end
	local origin = farm:FindFirstChild("PlotOrigin") or farm:FindFirstChild("Origin")
	if origin and origin:IsA("BasePart") then
		return origin.Position
	end
	if farm:IsA("Model") and farm.PrimaryPart then
		return farm.PrimaryPart.Position
	end
	return farm:GetPivot().Position
end

function Plant.GetPlotPositions(plotSize, layout)
	plotSize = plotSize or 0
	layout = layout or GAG.Config.Get("PlantLayout") or "compact"
	local offset = LAYOUT_OFFSETS[layout] or LAYOUT_OFFSETS.compact
	local origin = GetPlotOrigin()
	local positions = {}
	local expansions = GAG.Stats.Expanded or 0
	local gridSize = math.floor(3 + expansions * 0.5)
	if plotSize > 0 then
		gridSize = math.floor(math.sqrt(plotSize)) + 1
	end
	for x = 0, gridSize - 1 do
		for z = 0, gridSize - 1 do
			local pos = origin + Vector3.new(x * offset.x, 0, z * offset.z)
			table.insert(positions, pos)
		end
	end
	return positions
end

function Plant.GetEmptyPositions()
	local plotPositions = Plant.GetPlotPositions()
	local plants = GAG.Modules.Utils.GetPlants()
	local occupied = {}
	for _, plant in ipairs(plants) do
		if plant:IsA("Model") then
			local pivot = plant:GetPivot().Position
			for _, pos in ipairs(plotPositions) do
				if (pos - pivot).Magnitude < 1.5 then
					occupied[pos.X .. "," .. pos.Z] = true
				end
			end
		elseif plant:IsA("BasePart") then
			for _, pos in ipairs(plotPositions) do
				if (pos - plant.Position).Magnitude < 1.5 then
					occupied[pos.X .. "," .. pos.Z] = true
				end
			end
		end
	end
	local empty = {}
	for _, pos in ipairs(plotPositions) do
		local key = pos.X .. "," .. pos.Z
		if not occupied[key] then
			table.insert(empty, pos)
		end
	end
	return empty
end

function Plant.PlantSeed(seedName, position)
	if not seedName or not position then
		GAG.Modules.Utils.Log("PlantSeed: missing seedName or position", "Warn")
		return false
	end

	local backpack = GAG.Player and GAG.Player:FindFirstChild("Backpack")
	local character = GAG.Player and GAG.Player.Character
	if not backpack or not character then
		GAG.Modules.Utils.Log("PlantSeed: no backpack or character", "Warn")
		return false
	end

	local tool = nil
	for _, item in ipairs(backpack:GetChildren()) do
		if item:IsA("Tool") and item.Name == seedName then
			tool = item
			break
		end
	end

	if not tool then
		for _, item in ipairs(character:GetChildren()) do
			if item:IsA("Tool") and item.Name == seedName then
				tool = item
				break
			end
		end
	end

	if not tool then
		GAG.Modules.Utils.Log("PlantSeed: seed '" .. seedName .. "' not found in backpack", "Warn")
		return false
	end

	if tool.Parent == backpack then
		character:WaitForChild("Humanoid"):EquipTool(tool)
		task.wait(0.2)
	end

	GAG.Modules.Utils.TeleportTo(position)
	task.wait(0.15)

	local planted = GAG.Modules.Utils.FireRemote("Networking.Plant.PlantSeed", seedName, position)
	if not planted then
		GAG.Modules.Utils.Log("PlantSeed: plant remote not found", "Error")
		return false
	end

	GAG.Modules.Utils.Log("Planted " .. seedName .. " at " .. tostring(position), "Info")
	task.wait(0.3)
	return true
end

function Plant.ShovelPlant(plant)
	if not true then
		return false
	end
	if not plant then return false end

	local seedName = plant:GetAttribute("SeedName") or plant.Name
	local skip, reason = ShouldSkipPlant(plant)
	if skip then
		GAG.Modules.Utils.Log("ShovelPlant: skip " .. seedName .. " (" .. reason .. ")", "Debug")
		return false
	end

	if pendingShovel[plant] then return false end
	pendingShovel[plant] = true

	local shoveled = GAG.Modules.Utils.FireRemote("Networking.Trowel.MovePlant", plant)
	if not shoveled then
		GAG.Modules.Utils.Log("ShovelPlant: shovel remote not found", "Error")
		pendingShovel[plant] = nil
		return false
	end

	GAG.Stats.Shoveled = (GAG.Stats.Shoveled or 0) + 1
	GAG.Modules.Utils.Log("Shoveled " .. seedName, "Info")
	task.wait(0.3)
	pendingShovel[plant] = nil
	return true
end

function Plant.ExpandPlot()
	if not GAG.Config.Get("Auto Expand Plot") then
		return false
	end

	local cash = GAG.Modules.Utils.GetMoney() or 0
	local expandIfOver = GAG.Config.Get("Expand If Over") or 5000
	local keepCash = GAG.Config.Get("Keep Cash") or 1000
	local maxExpansions = GAG.Config.Get("Max Expansions") or 10
	local expanded = GAG.Stats.Expanded or 0

	if cash < expandIfOver then return false end
	if cash - keepCash < expandIfOver then return false end
	if expanded >= maxExpansions then return false end

	local expandRemote = GAG.Modules.Config.GetNested("Remotes", "ExpandPlot")
		or game.ReplicatedStorage:FindFirstChild("ExpandPlot")
		or game.ReplicatedStorage:FindFirstChild("BuyExpansion")
	if expandRemote and expandRemote:IsA("RemoteEvent") then
		expandRemote:FireServer()
	elseif expandRemote and expandRemote:IsA("RemoteFunction") then
		expandRemote:InvokeServer()
	else
		GAG.Modules.Utils.Log("ExpandPlot: expand remote not found", "Error")
		return false
	end

	GAG.Stats.Expanded = expanded + 1
	GAG.Modules.Utils.Log("Plot expanded (" .. GAG.Stats.Expanded .. "/" .. maxExpansions .. ")", "Info")
	task.wait(0.5)
	return true
end

function Plant.GetNextSeedToPlant()
	local inventory = GAG.Player and GAG.Player:FindFirstChild("Backpack")
	if not inventory then return nil end

	local plantPlan = GAG.Config.Get("Plant Plan")
	local onlyPlant = GAG.Config.Get("OnlyPlant")
	local minTier = GAG.Config.Get("Minimum Seed")
	local minTierVal = TierValue(minTier)

	local plants = GAG.Modules.Utils.GetPlants()
	local plantCounts = {}
	for _, p in ipairs(plants) do
		local name = p:GetAttribute("SeedName") or p.Name
		plantCounts[name] = (plantCounts[name] or 0) + 1
	end

	local seedCounts = {}
	for _, item in ipairs(inventory:GetChildren()) do
		if item:IsA("Tool") then
			seedCounts[item.Name] = (seedCounts[item.Name] or 0) + 1
		end
	end

	local character = GAG.Player and GAG.Player.Character
	if character then
		for _, item in ipairs(character:GetChildren()) do
			if item:IsA("Tool") then
				seedCounts[item.Name] = (seedCounts[item.Name] or 0) + 1
			end
		end
	end

	if plantPlan and #plantPlan > 0 then
		for _, entry in ipairs(plantPlan) do
			local name, targetCount
			if type(entry) == "table" then
				name = entry.Name
				targetCount = entry.Count or entry.Amount or 1
			else
				name = entry
				targetCount = 1
			end
			local current = plantCounts[name] or 0
			local available = seedCounts[name] or 0
			if current < targetCount and available > 0 and TierValue(name) >= minTierVal then
				return name
			end
		end
	end

	if onlyPlant and #onlyPlant > 0 then
		for _, name in ipairs(onlyPlant) do
			local available = seedCounts[name] or 0
			if available > 0 and TierValue(name) >= minTierVal then
				return name
			end
		end
		return nil
	end

	local bestSeed = nil
	local bestTier = math.huge
	for name, count in pairs(seedCounts) do
		if count > 0 then
			local tv = TierValue(name)
			if tv >= minTierVal and tv < bestTier then
				bestTier = tv
				bestSeed = name
			end
		end
	end

	if bestSeed then return bestSeed end

	if GAG.Config.Get("ShouldBuySeed") then
		local buySeeds = GAG.Modules.BuySeeds
		if buySeeds and buySeeds.AutoBuy then
			local bought = buySeeds.AutoBuy()
			if bought then
				task.wait(0.3)
				return Plant.GetNextSeedToPlant()
			end
		end
	end

	return nil
end

function Plant.ReplacePlants()
	if not GAG.Config.Get("Auto Replace Plants") then return false end

	local plants = GAG.Modules.Utils.GetPlants()
	local emptyPositions = Plant.GetEmptyPositions()
	if #emptyPositions > 0 then return false end

	local cheapest = nil
	local cheapestTier = math.huge
	for _, plant in ipairs(plants) do
		local name = plant:GetAttribute("SeedName") or plant.Name
		local skip = ShouldSkipPlant(plant)
		if not skip then
			local tv = TierValue(name)
			if tv < cheapestTier then
				cheapestTier = tv
				cheapest = plant
			end
		end
	end

	if not cheapest then
		GAG.Modules.Utils.Log("ReplacePlants: no replaceable plants found", "Debug")
		return false
	end

	local nextSeed = Plant.GetNextSeedToPlant()
	if not nextSeed then
		GAG.Modules.Utils.Log("ReplacePlants: no seeds available", "Debug")
		return false
	end

	local nextTier = TierValue(nextSeed)
	if nextTier <= cheapestTier then
		GAG.Modules.Utils.Log("ReplacePlants: next seed not better than cheapest plant", "Debug")
		return false
	end

	local pos = cheapest:GetPivot().Position
	local seedName = cheapest:GetAttribute("SeedName") or cheapest.Name

	GAG.Modules.Utils.Log("Replacing " .. seedName .. " with " .. nextSeed, "Info")
	Plant.ShovelPlant(cheapest)
	task.wait(0.2)
	Plant.PlantSeed(nextSeed, pos)
	return true
end

function Plant.RespectPlantLimit()
	local plantLimit = GAG.Config.Get("Plant Limit")
	if not plantLimit or plantLimit <= 0 then return end

	local plants = GAG.Modules.Utils.GetPlants()
	if #plants <= plantLimit then return end

	local shovelCandidates = {}
	for _, plant in ipairs(plants) do
		local name = plant:GetAttribute("SeedName") or plant.Name
		local skip = ShouldSkipPlant(plant)
		if not skip then
			table.insert(shovelCandidates, { plant = plant, tier = TierValue(name), name = name })
		end
	end

	table.sort(shovelCandidates, function(a, b)
		return a.tier < b.tier
	end)

	local excess = #plants - plantLimit
	for i = 1, math.min(excess, #shovelCandidates) do
		local entry = shovelCandidates[i]
		GAG.Modules.Utils.Log("PlantLimit: shoveling " .. entry.name .. " (over limit)", "Info")
		Plant.ShovelPlant(entry.plant)
		task.wait(0.2)
	end
end

function Plant.Init(gag)
	GAG = gag
	GAG.Stats.Planted = GAG.Stats.Planted or 0
	GAG.Stats.Shoveled = GAG.Stats.Shoveled or 0
	GAG.Stats.Expanded = GAG.Stats.Expanded or 0
	GAG.Stats.Replaced = GAG.Stats.Replaced or 0
	GAG.Modules.Utils.Log("Plant module initialized", "Info")
end

function Plant.Start(gag)
	GAG = gag
	GAG.Modules.Utils.Log("Plant loop started", "Info")

	while GAG.Config.Get("Auto Plant") do
		local emptyPositions = Plant.GetEmptyPositions()

		if #emptyPositions > 0 then
			local seedName = Plant.GetNextSeedToPlant()
			if seedName then
				for _, pos in ipairs(emptyPositions) do
					if not GAG.Config.Get("Auto Plant") then break end
					local success = Plant.PlantSeed(seedName, pos)
					if success then
						GAG.Stats.Planted = (GAG.Stats.Planted or 0) + 1
						task.wait(0.5 or 0.5)
					end
					seedName = Plant.GetNextSeedToPlant()
					if not seedName then break end
				end
			end
		else
			local replaced = Plant.ReplacePlants()
			if replaced then
				GAG.Stats.Replaced = (GAG.Stats.Replaced or 0) + 1
			end
		end

		Plant.RespectPlantLimit()
		Plant.ExpandPlot()

		GAG.Modules.Utils.Sleep(2 or 2)
	end

	GAG.Modules.Utils.Log("Plant loop stopped", "Info")
end

return Plant
]])
    LoadModule("BuySeeds",[[local BuySeeds = {}

local SEED_SHOP_NPC_NAME = "Seed Shop"
local BUY_SEED_REMOTE = "Networking.SeedShop.PurchaseSeed"
local SHOP_REFRESH_INTERVAL = 300
local SHOP_CHECK_INTERVAL = 15
local CASH_RESERVE_DEFAULT = 10000

local REFRESH_REMOTE = "RefreshShop"
local SHOP_GUI_PATH = "PlayerGui.ShopGui.SeedShop"

local Utils, Config

local function Log(...)
	if Utils and Utils.Log then
		Utils.Log("[BuySeeds]", ...)
	end
end

local function GetCash(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local cash = leaderstats:FindFirstChild("Cash") or leaderstats:FindFirstChild("Sheckles") or leaderstats:FindFirstChild("Money")
		if cash then
			return cash.Value
		end
	end
	return 0
end

function BuySeeds.Init(GAG)
	Utils = GAG.Utils
	Config = GAG.Config

	GAG.State = GAG.State or {}
	GAG.State.SeedShopStock = {}
	GAG.State.LastShopRefresh = 0
	GAG.State.BuySeedsDone = {}

	GAG.Stats = GAG.Stats or {}
	GAG.Stats.SeedsBought = GAG.Stats.SeedsBought or 0

	Log("Module initialized")
end

function BuySeeds.GetShopStock(GAG)
	local stock = {}

	local shopItems = Utils.GetShopItems("Seeds") or Utils.GetShopItems("SeedShop")
	if shopItems and type(shopItems) == "table" then
		for _, item in ipairs(shopItems) do
			local seedName = item.Name or item.ItemName or item[1]
			local price = item.Price or item.Cost or item[2]
			local available = item.Available ~= false and item.Stock ~= 0
			if seedName then
				stock[seedName] = {
					price = price or 0,
					available = available,
					stock = item.Stock or item.Quantity or -1,
				}
			end
		end
		return stock
	end

	local player = game.Players.LocalPlayer
	local gui = player and player:FindFirstChild("PlayerGui")
	if gui then
		local shopGui = gui:FindFirstChild("ShopGui") or gui:FindFirstChild("SeedShopGui")
		if shopGui then
			local container = shopGui:FindFirstChild("SeedShop") or shopGui:FindFirstChild("Items") or shopGui:FindFirstChild("ScrollingFrame")
			if container then
				for _, child in ipairs(container:GetDescendants()) do
					if child:IsA("TextButton") or child:IsA("ImageButton") then
						local nameLabel = child:FindFirstChild("Name") or child:FindFirstChild("SeedName") or child:FindFirstChild("Title")
						local priceLabel = child:FindFirstChild("Price") or child:FindFirstChild("Cost")
						if nameLabel then
							local seedName = nameLabel.Text
							local price = 0
							if priceLabel then
								price = tonumber(priceLabel.Text:match("[%d%.]+")) or 0
							end
							stock[seedName] = {
								price = price,
								available = not child.Visible or child.Visible,
								stock = -1,
							}
						end
					end
				end
			end
		end
	end

	if next(stock) == nil then
		local ok, result = pcall(function()
			return Utils.FireRemote("GetShopStock", "Seeds")
		end)
		if ok and type(result) == "table" then
			stock = result
		end
	end

	GAG.State.SeedShopStock = stock
	GAG.State.LastShopRefresh = tick()
	return stock
end

function BuySeeds.ShouldBuySeed(GAG, seedName)
	if not Config then return false end

	if not Config.Get("AutoBuySeeds") and not Config.Get("Buy Seeds")[seedName] then
		return false
	end

	local dontBuy = Config.Get("DontBuy") or Config.Get("Don'tBuy") or {}
	if dontBuy[seedName] then
		Log("Skipping", seedName, "- in Don't Buy list")
		return false
	end

	local dontPlant = Config.Get("DontPlant") or Config.Get("Don'tPlant") or {}
	local buySeedsConfig = Config.Get("Buy Seeds") or {}
	if dontPlant[seedName] and not buySeedsConfig[seedName] then
		Log("Skipping", seedName, "- in Don't Plant and not in Buy Seeds")
		return false
	end

	local bannedSeeds = {
		["Gold Seed"] = true,
		["Rainbow Seed"] = true,
		["Mega Seed"] = true,
		["Gold"] = true,
		["Rainbow"] = true,
		["Mega"] = true,
	}
	if bannedSeeds[seedName] then
		return false
	end

	return true
end

function BuySeeds.ShouldSpendOnSeed(GAG, price)
	local cash = GetCash(game.Players.LocalPlayer)
	local keepCash = Config and Config.Get("Keep Cash") or CASH_RESERVE_DEFAULT
	if cash - price < keepCash then
		Log("Not enough cash after reserve. Cash:", cash, "Price:", price, "Reserve:", keepCash)
		return false
	end
	return true
end

function BuySeeds.BuySeed(GAG, seedName, amount)
	amount = amount or 1

	if not BuySeeds.ShouldBuySeed(GAG, seedName) then
		return false, "Should not buy"
	end

	local stock = GAG.State.SeedShopStock or {}
	local stockInfo = stock[seedName]
	if stockInfo and stockInfo.available == false then
		Log(seedName, "not available in shop")
		return false, "Not available"
	end

	local price = 0
	if stockInfo and stockInfo.price then
		price = stockInfo.price
	end

	if price > 0 and not BuySeeds.ShouldSpendOnSeed(GAG, price * amount) then
		return false, "Keep Cash limit"
	end

	local ok, err = pcall(function()
		Utils.FireRemote(BUY_SEED_REMOTE, seedName, amount)
	end)

	if ok then
		GAG.Stats.SeedsBought = (GAG.Stats.SeedsBought or 0) + amount
		Log("Bought", amount, "x", seedName, "for", price * amount)
		return true
	else
		Log("Failed to buy", seedName, ":", err)
		return false, err
	end
end

function BuySeeds.ProcessBuySeedsConfig(GAG)
	local buySeedsConfig = Config.Get("Buy Seeds") or {}
	if type(buySeedsConfig) ~= "table" then return end

	Log("Processing Buy Seeds config...")

	for seedName, targetCount in pairs(buySeedsConfig) do
		if type(targetCount) ~= "number" or targetCount <= 0 then
			continue
		end

		if not BuySeeds.ShouldBuySeed(GAG, seedName) then
			continue
		end

		local currentCount = 0
		if Utils.GetSeedCount then
			currentCount = Utils.GetSeedCount(seedName) or 0
		else
			local inv = GAG.State.Inventory or {}
			currentCount = inv[seedName] or 0
		end

		local needed = targetCount - currentCount
		if needed <= 0 then
			Log(seedName, "already stocked:", currentCount, "/", targetCount)
			continue
		end

		Log("Need to buy", needed, "more", seedName, "(", currentCount, "/", targetCount, ")")

		local stock = GAG.State.SeedShopStock or {}
		local shopInfo = stock[seedName]
		if shopInfo and shopInfo.available == false then
			Log(seedName, "out of stock, skipping")
			continue
		end

		local buyAmount = needed
		if shopInfo and shopInfo.stock and shopInfo.stock > 0 then
			buyAmount = math.min(buyAmount, shopInfo.stock)
		end

		local success = BuySeeds.BuySeed(GAG, seedName, buyAmount)
		if success then
			GAG.State.BuySeedsDone[seedName] = true
			Log("Stocked", buyAmount, "x", seedName, "for mailing")
		end

		task.wait(0.5)
	end
end

function BuySeeds.GetMinimumSeedTier(GAG)
	local minSeedConfig = Config and Config.Get("Minimum Seed") or Config and Config.Get("MinSeedTier") or "Common"
	local tierStr = tostring(minSeedConfig)

	local tierMap = {
		["common"] = 1,
		["uncommon"] = 2,
		["rare"] = 3,
		["epic"] = 4,
		["legendary"] = 5,
		["mythical"] = 6,
		["divine"] = 7,
		["celestial"] = 8,
		["transcendent"] = 9,
	}

	local tierNumber = tonumber(tierStr)
	if tierNumber then
		return tierNumber
	end

	return tierMap[tierStr:lower()] or 1
end

function BuySeeds.GetTierOrder()
	if Utils and Utils.GetTierOrder then
		return Utils.GetTierOrder()
	end
	return {
		"Common", "Uncommon", "Rare", "Epic", "Legendary",
		"Mythical", "Divine", "Celestial", "Transcendent",
	}
end

function BuySeeds.GetPlantableSeeds(GAG)
	local plantable = {}
	local minTier = BuySeeds.GetMinimumSeedTier(GAG)
	local tierOrder = BuySeeds.GetTierOrder()

	local dontPlant = Config and Config.Get("DontPlant") or Config and Config.Get("Don'tPlant") or {}
	local buySeedsConfig = Config and Config.Get("Buy Seeds") or {}

	local stock = GAG.State.SeedShopStock or {}

	for seedName, info in pairs(stock) do
		if not info.available then continue end
		if dontPlant[seedName] then continue end
		if buySeedsConfig[seedName] then continue end

		local seedTier = 1
		if Utils and Utils.GetSeedTier then
			seedTier = Utils.GetSeedTier(seedName) or 1
		else
			for i, tierName in ipairs(tierOrder) do
				if seedName:find(tierName) then
					seedTier = i
					break
				end
			end
		end

		if seedTier >= minTier then
			table.insert(plantable, {
				name = seedName,
				tier = seedTier,
				price = info.price or 0,
			})
		end
	end

	table.sort(plantable, function(a, b)
		return a.tier > b.tier
	end)

	return plantable
end

function BuySeeds.BuySeedsForPlanting(GAG)
	if not Config or not Config.Get("Auto Plant") then
		return
	end

	Log("Checking seeds for planting...")

	local plantable = BuySeeds.GetPlantableSeeds(GAG)
	local currentSeeds = GAG.State.CurrentSeedCount or 5
	local minSeeds = Config.Get("MinSeedsForPlanting") or 3

	if currentSeeds >= minSeeds then
		Log("Enough seeds for planting:", currentSeeds)
		return
	end

	for _, seedInfo in ipairs(plantable) do
		if currentSeeds >= minSeeds then break end

		if BuySeeds.ShouldSpendOnSeed(GAG, seedInfo.price) then
			local success = BuySeeds.BuySeed(GAG, seedInfo.name, 1)
			if success then
				currentSeeds = currentSeeds + 1
				Log("Bought", seedInfo.name, "for planting. Seeds:", currentSeeds)
			end
			task.wait(0.3)
		end
	end
end

function BuySeeds.RefreshShop(GAG)
	local now = tick()
	if now - (GAG.State.LastShopRefresh or 0) < SHOP_REFRESH_INTERVAL then
		return
	end

	Log("Refreshing seed shop...")

	local seedShopPos = Config and Config.Get("SeedShopPosition")
	if seedShopPos and Utils and Utils.WalkTo then
		Utils.WalkTo(seedShopPos)
		task.wait(1)
	end

	local ok = pcall(function()
		Utils.FireRemote(REFRESH_REMOTE, "Seeds")
	end)

	if ok then
		GAG.State.LastShopRefresh = now
		task.wait(1)
		BuySeeds.GetShopStock(GAG)
	end
end

function BuySeeds.Start(GAG)
	Log("Starting BuySeeds module...")

	BuySeeds.GetShopStock(GAG)

	while GAG.State and GAG.State.Running do
		local ok, err = pcall(function()
			BuySeeds.RefreshShop(GAG)

			BuySeeds.ProcessBuySeedsConfig(GAG)

			BuySeeds.BuySeedsForPlanting(GAG)
		end)

		if not ok then
			Log("Error in main loop:", err)
		end

		local interval = Config and Config.Get("ShopCheckInterval") or SHOP_CHECK_INTERVAL
		if Utils and Utils.Sleep then
			Utils.Sleep(interval)
		else
			task.wait(interval)
		end
	end

	Log("BuySeeds module stopped")
end

return BuySeeds
]])
    LoadModule("Pets",    [=[--[[
    Pets Module - Grow a Garden Autofarm
    Handles buying, equipping, and managing pets.
    
    Pet abilities:
      - Unicorn:        2x Rainbow mutation chance
      - GoldenDragonfly: 2x Gold mutation chance
      - Deer:           Faster crop growth
      - Robin:          Drops random seeds periodically
]]

local Pets = {}

-- Private state
local running = false
local currentSlots = 0
local maxSlots = 3

-- References (set on Init)
local GAG = nil
local Config = nil
local Utils = nil

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function Log(msg)
    if Utils and Utils.Log then
        Utils.Log("[Pets] " .. tostring(msg))
    end
end

local function GetConfig(key)
    if Config and Config.Get then
        return Config.Get(key)
    end
    return nil
end

local function GetNestedConfig(section, key)
    if Config and Config.GetNested then
        return Config.GetNested(section, key)
    end
    return nil
end

local function Sleep(seconds)
    if Utils and Utils.Sleep then
        Utils.Sleep(seconds)
    else
        task.wait(seconds or 1)
    end
end

local function FireRemote(remoteName, ...)
    if Utils and Utils.FireRemote then
        return Utils.FireRemote(remoteName, ...)
    end
    -- Fallback: try to find and fire directly
    local ok, err = pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        local remotes = rs:FindFirstChild("Remotes") or rs:FindFirstChild("Events")
        if remotes then
            local remote = remotes:FindFirstChild(remoteName)
            if remote and remote:IsA("RemoteEvent") then
                remote:FireServer(...)
            end
        end
    end)
    return ok
end

local function InvokeRemote(remoteName, ...)
    if Utils and Utils.InvokeRemote then
        return Utils.InvokeRemote(remoteName, ...)
    end
    local ok, result = pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        local remotes = rs:FindFirstChild("Remotes") or rs:FindFirstChild("Events")
        if remotes then
            local remote = remotes:FindFirstChild(remoteName)
            if remote and remote:IsA("RemoteFunction") then
                return remote:InvokeServer(...)
            end
        end
        return nil
    end)
    return ok and result or nil
end

---------------------------------------------------------------------------
-- GetOwnedPets
-- Returns a table of { petName = count } for all owned pets.
---------------------------------------------------------------------------

function Pets.GetOwnedPets()
    local owned = {}
    
    local ok = pcall(function()
        local player = GAG and GAG.Player
        if not player then return end
        
        -- Try multiple storage locations for pet data
        local petsFolder = player:FindFirstChild("Pets")
            or player:FindFirstChild("OwnedPets")
            or player:FindFirstChild("PetInventory")
        
        if petsFolder then
            for _, pet in ipairs(petsFolder:GetChildren()) do
                local petName = pet.Name
                local count = pet:GetAttribute("Count") or 1
                owned[petName] = (owned[petName] or 0) + count
            end
        end
        
        -- Also check leaderstats or data folders
        local data = player:FindFirstChild("Data") or player:FindFirstChild("PlayerData")
        if data then
            local petsData = data:FindFirstChild("Pets")
            if petsData and petsData:IsA("ModuleScript") then
                -- Some games store pet data in modules
                local modData = require(petsData)
                if type(modData) == "table" then
                    for petName, count in pairs(modData) do
                        owned[petName] = (owned[petName] or 0) + count
                    end
                end
            end
        end
        
        -- Check replicated pet data
        local petData = player:FindFirstChild("PetData")
        if petData and petData:IsA("ValueBase") then
            local dataValue = petData.Value
            if type(dataValue) == "string" then
                local decoded = game:GetService("HttpService"):JSONDecode(dataValue)
                if type(decoded) == "table" then
                    for petName, count in pairs(decoded) do
                        owned[petName] = (owned[petName] or 0) + count
                    end
                end
            end
        end
    end)
    
    if not ok then
        Log("Warning: Could not read owned pets data.")
    end
    
    return owned
end

---------------------------------------------------------------------------
-- GetEquippedPets
-- Returns a table of { petName = count } for currently equipped pets.
---------------------------------------------------------------------------

function Pets.GetEquippedPets()
    local equipped = {}
    
    local ok = pcall(function()
        local player = GAG and GAG.Player
        if not player then return end
        
        local char = GAG.Character or player.Character
        if not char then return end
        
        -- Look for equipped pets in character
        local petsFolder = char:FindFirstChild("EquippedPets")
            or char:FindFirstChild("ActivePets")
            or char:FindFirstChild("Pets")
        
        if petsFolder then
            for _, pet in ipairs(petsFolder:GetChildren()) do
                local petName = pet.Name
                equipped[petName] = (equipped[petName] or 0) + 1
            end
        end
        
        -- Also check player's equipped pets folder
        local playerEquipped = player:FindFirstChild("EquippedPets")
        if playerEquipped then
            for _, pet in ipairs(playerEquipped:GetChildren()) do
                local petName = pet.Name
                equipped[petName] = (equipped[petName] or 0) + 1
            end
        end
    end)
    
    return equipped
end

---------------------------------------------------------------------------
-- GetPetSlotCount
-- Returns { current = N, max = N } for pet slots.
---------------------------------------------------------------------------

function Pets.GetPetSlotCount()
    local result = { current = 0, max = 3 }
    
    local ok = pcall(function()
        local player = GAG and GAG.Player
        if not player then return end
        
        -- Try to get slot count from player data
        local slots = player:FindFirstChild("PetSlots")
            or player:FindFirstChild("MaxPetSlots")
        
        if slots and slots:IsA("ValueBase") then
            result.max = slots.Value
        end
        
        -- Count currently equipped
        local equipped = Pets.GetEquippedPets()
        local count = 0
        for _, c in pairs(equipped) do
            count = count + c
        end
        result.current = count
    end)
    
    -- Update module state
    currentSlots = result.current
    maxSlots = result.max
    
    return result
end

---------------------------------------------------------------------------
-- BuyPet
-- Attempts to buy a specific pet from the pet shop.
---------------------------------------------------------------------------

function Pets.BuyPet(petName)
    if not petName or petName == "" then return false end
    
    Log("Attempting to buy pet: " .. petName)
    
    -- Fire buy remote (common patterns for Grow a Garden)
    local success = FireRemote("WildPetTame", petName)
    
    if success ~= false then
        GAG.Stats.PetsBought = (GAG.Stats.PetsBought or 0) + 1
        Log("Bought pet: " .. petName .. " (Total: " .. GAG.Stats.PetsBought .. ")")
        return true
    end
    
    -- Try with table argument format
    success = success or FireRemote("WildPetTame", { PetName = petName })
    
    if success ~= false then
        GAG.Stats.PetsBought = (GAG.Stats.PetsBought or 0) + 1
        Log("Bought pet: " .. petName .. " (Total: " .. GAG.Stats.PetsBought .. ")")
        return true
    end
    
    Log("Failed to buy pet: " .. petName)
    return false
end

---------------------------------------------------------------------------
-- EquipPet
-- Attempts to equip a pet. Returns true if successful.
---------------------------------------------------------------------------

function Pets.EquipPet(petName)
    if not petName or petName == "" then return false end
    
    -- Check slot availability
    local slots = Pets.GetPetSlotCount()
    if slots.current >= slots.max then
        Log("No pet slots available! (" .. slots.current .. "/" .. slots.max .. ")")
        return false
    end
    
    Log("Equipping pet: " .. petName)
    
    -- Fire equip remote
    local success = FireRemote("EquipPet", petName)
    
    if success ~= false then
        currentSlots = currentSlots + 1
        Log("Equipped pet: " .. petName .. " (Slots: " .. currentSlots .. "/" .. maxSlots .. ")")
        return true
    end
    
    -- Try with index-based equip
    local equipIndex = slots.current + 1
    success = success or FireRemote("EquipPet", petName, equipIndex)
    
    if success ~= false then
        currentSlots = currentSlots + 1
        Log("Equipped pet: " .. petName .. " in slot " .. equipIndex)
        return true
    end
    
    Log("Failed to equip pet: " .. petName)
    return false
end

---------------------------------------------------------------------------
-- UnequipPet
-- Attempts to unequip a pet.
---------------------------------------------------------------------------

function Pets.UnequipPet(petName)
    if not petName or petName == "" then return false end
    
    Log("Unequipping pet: " .. petName)
    
    local success = FireRemote("UnequipPet", petName)
    
    if success ~= false then
        currentSlots = math.max(0, currentSlots - 1)
        Log("Unequipped pet: " .. petName)
        return true
    end
    
    Log("Failed to unequip pet: " .. petName)
    return false
end

---------------------------------------------------------------------------
-- BuyPetSlot
-- Buys an additional pet slot if conditions are met.
---------------------------------------------------------------------------

function Pets.BuyPetSlot()
    -- Check if auto buy slots is enabled
    local autoBuy = GetNestedConfig("Pets", "Auto Buy Slots")
    if not autoBuy then return false end
    
    -- Check current vs max slots
    local slots = Pets.GetPetSlotCount()
    local configMax = GetNestedConfig("Pets", "Max Pet Slots") or 6
    
    if slots.max >= configMax then
        Log("Already at max pet slots (" .. slots.max .. "/" .. configMax .. ")")
        return false
    end
    
    if slots.max >= 6 then
        Log("Cannot buy more slots — already at game max (6)")
        return false
    end
    
    Log("Buying pet slot... (Current max: " .. slots.max .. ")")
    
    -- Fire buy slot remote
    local success = FireRemote("BuyPetSlot")
    
    if success ~= false then
        maxSlots = maxSlots + 1
        Log("Pet slot purchased! New max: " .. maxSlots)
        return true
    end
    
    Log("Failed to buy pet slot.")
    return false
end

---------------------------------------------------------------------------
-- ProcessPetBuyConfig
-- Handles the "Pets.Buy" mixed config:
--   Plain names in array = buy unlimited (one per tick)
--   Map entries ["Name"] = N = stop at N owned
---------------------------------------------------------------------------

function Pets.ProcessPetBuyConfig()
    local buyConfig = GetNestedConfig("Pets", "Buy")
    if not buyConfig or type(buyConfig) ~= "table" then return end
    
    local owned = Pets.GetOwnedPets()
    
    for key, value in pairs(buyConfig) do
        if type(key) == "number" then
            -- Array entry: plain name, buy one at a time, keep buying
            local petName = value
            if type(petName) == "string" and petName ~= "" then
                Pets.BuyPet(petName)
                Sleep(0.5)
            end
        elseif type(key) == "string" then
            -- Map entry: ["PetName"] = targetCount
            local petName = key
            local targetCount = tonumber(value) or 0
            local currentCount = owned[petName] or 0
            
            if currentCount < targetCount then
                Log("Pet '" .. petName .. "': " .. currentCount .. "/" .. targetCount .. " — buying...")
                Pets.BuyPet(petName)
                Sleep(0.5)
            else
                Log("Pet '" .. petName .. "' already at target (" .. currentCount .. "/" .. targetCount .. ")")
            end
        end
    end
end

---------------------------------------------------------------------------
-- ProcessPetEquipConfig
-- Handles the "Pets.Equip" config:
--   Map of petName = count to equip
--   Equips pets in priority order, fills slots up to max
---------------------------------------------------------------------------

function Pets.ProcessPetEquipConfig()
    local equipConfig = GetNestedConfig("Pets", "Equip")
    if not equipConfig or type(equipConfig) ~= "table" then return end
    
    local owned = Pets.GetOwnedPets()
    local equipped = Pets.GetEquippedPets()
    local slots = Pets.GetPetSlotCount()
    
    -- Build equip queue with priority (order matters for Lua tables)
    local equipQueue = {}
    for petName, targetCount in pairs(equipConfig) do
        if type(petName) == "string" and type(targetCount) == "number" then
            table.insert(equipQueue, { name = petName, target = targetCount })
        end
    end
    
    -- Process each pet type
    for _, entry in ipairs(equipQueue) do
        local petName = entry.name
        local targetCount = entry.target
        local ownedCount = owned[petName] or 0
        local equippedCount = equipped[petName] or 0
        
        -- Skip if not owned
        if ownedCount <= 0 then
            Log("Cannot equip '" .. petName .. "': not owned")
            continue
        end
        
        -- Calculate how many more to equip
        local toEquip = math.min(targetCount - equippedCount, ownedCount - equippedCount)
        
        if toEquip <= 0 then
            Log("Pet '" .. petName .. "': already equipped " .. equippedCount .. "/" .. targetCount)
            continue
        end
        
        -- Check slot availability
        local availableSlots = slots.max - slots.current
        if availableSlots <= 0 then
            Log("No pet slots available! Cannot equip more pets.")
            break
        end
        
        -- Equip up to available slots
        local actualEquip = math.min(toEquip, availableSlots)
        for i = 1, actualEquip do
            if slots.current >= slots.max then
                Log("Pet slots full, stopping equip.")
                return
            end
            
            local success = Pets.EquipPet(petName)
            if success then
                slots.current = slots.current + 1
            end
            
            Sleep(0.3)
        end
    end
end

---------------------------------------------------------------------------
-- PrintPetStatus
-- Logs current pet inventory and equipped status.
---------------------------------------------------------------------------

function Pets.PrintPetStatus()
    local owned = Pets.GetOwnedPets()
    local equipped = Pets.GetEquippedPets()
    local slots = Pets.GetPetSlotCount()
    
    Log("=== Pet Status ===")
    Log("Slots: " .. slots.current .. "/" .. slots.max)
    
    Log("Owned pets:")
    local hasOwned = false
    for petName, count in pairs(owned) do
        Log("  " .. petName .. " x" .. count)
        hasOwned = true
    end
    if not hasOwned then
        Log("  (none)")
    end
    
    Log("Equipped pets:")
    local hasEquipped = false
    for petName, count in pairs(equipped) do
        Log("  " .. petName .. " x" .. count)
        hasEquipped = true
    end
    if not hasEquipped then
        Log("  (none)")
    end
    
    Log("==================")
end

---------------------------------------------------------------------------
-- Init
-- Called once to set up module references.
---------------------------------------------------------------------------

function Pets.Init(gag)
    GAG = gag
    Config = GAG and GAG.Modules and GAG.Modules.Config
    Utils = GAG and GAG.Modules and GAG.Modules.Utils
    
    -- Initialize stats if not present
    if GAG and GAG.Stats then
        GAG.Stats.PetsBought = GAG.Stats.PetsBought or 0
    end
    
    Log("Pets module initialized.")
end

---------------------------------------------------------------------------
-- Start
-- Main loop: buy pets, equip pets, buy slots, repeat.
---------------------------------------------------------------------------

function Pets.Start(gag)
    if running then
        Log("Already running!")
        return
    end
    
    if gag then
        Pets.Init(gag)
    end
    
    running = true
    Log("Pets loop started.")
    
    -- Initial status print
    Pets.PrintPetStatus()
    
    while running do
        pcall(function()
            -- 1. Process buy config
            Pets.ProcessPetBuyConfig()
            
            -- 2. Process equip config
            Pets.ProcessPetEquipConfig()
            
            -- 3. Buy slots if needed
            Pets.BuyPetSlot()
        end)
        
        -- Sleep between iterations (pets don't need to be as fast as harvesting)
        Sleep(3)
    end
    
    Log("Pets loop stopped.")
end

---------------------------------------------------------------------------
-- Stop
-- Gracefully stops the main loop.
---------------------------------------------------------------------------

function Pets.Stop()
    running = false
    Log("Pets stop requested.")
end

---------------------------------------------------------------------------
-- IsRunning
---------------------------------------------------------------------------

function Pets.IsRunning()
    return running
end

---------------------------------------------------------------------------
-- GetStatus
-- Returns a summary table for the stats display.
---------------------------------------------------------------------------

function Pets.GetStatus()
    local owned = Pets.GetOwnedPets()
    local equipped = Pets.GetEquippedPets()
    local slots = Pets.GetPetSlotCount()
    
    local ownedCount = 0
    for _, c in pairs(owned) do ownedCount = ownedCount + c end
    
    return {
        Owned = ownedCount,
        Equipped = slots.current,
        MaxSlots = slots.max,
        PetsBought = GAG and GAG.Stats and GAG.Stats.PetsBought or 0,
    }
end

return Pets
]=])
    LoadModule("Gear",    [[local Gear = {}

local GAG = nil
local Utils = nil
local Config = nil

local SPRINKLER_TIERS = {
	["Basic Sprinkler"] = 1,
	["Rare Sprinkler"] = 2,
	["Super Sprinkler"] = 3,
	["Master Sprinkler"] = 4,
	["Grandmaster Sprinkler"] = 5,
}

local function Log(msg)
	if Utils and Utils.Log then
		Utils.Log("[Gear] " .. msg)
	end
end

local function GetTierOrder()
	if Utils and Utils.GetTierOrder then
		return Utils.GetTierOrder()
	end
	local order = {}
	for name, tier in pairs(SPRINKLER_TIERS) do
		order[#order + 1] = { Name = name, Tier = tier }
	end
	table.sort(order, function(a, b) return a.Tier > b.Tier end)
	local result = {}
	for _, entry in ipairs(order) do
		result[#result + 1] = entry.Name
	end
	return result
end

local function Sleep(seconds)
	if Utils and Utils.Sleep then
		Utils.Sleep(seconds)
		return
	end
	task.wait(seconds or 1)
end

local function FireRemote(remoteName, ...)
	if Utils and Utils.FireRemote then
		return Utils.FireRemote(remoteName, ...)
	end
end

local function WalkTo(position)
	if Utils and Utils.WalkTo then
		return Utils.WalkTo(position)
	end
end

local function TeleportTo(position)
	if Utils and Utils.TeleportTo then
		return Utils.TeleportTo(position)
	end
end

local function GetFarm()
	if Utils and Utils.GetFarm then
		return Utils.GetFarm()
	end
	return nil
end

local function CalculateSprinklerPositions(farm, count, mode)
	if Utils and Utils.CalculateSprinklerPositions then
		return Utils.CalculateSprinklerPositions(farm, count, mode)
	end

	if not farm or not farm.PrimaryPart then
		return {}
	end

	local center = farm.PrimaryPart.Position
	local size = farm:GetExtentsSize()
	local halfX = size.X / 2
	local halfZ = size.Z / 2
	local positions = {}

	if mode == "concentrate" then
		local radius = math.min(halfX, halfZ) * 0.4
		for i = 1, count do
			local angle = (2 * math.pi * (i - 1)) / count
			local offsetX = math.cos(angle) * radius
			local offsetZ = math.sin(angle) * radius
			positions[#positions + 1] = Vector3.new(
				center.X + offsetX,
				center.Y,
				center.Z + offsetZ
			)
		end
	elseif mode == "spread" then
		local cols = math.ceil(math.sqrt(count))
		local rows = math.ceil(count / cols)
		local spacingX = (halfX * 2) / (cols + 1)
		local spacingZ = (halfZ * 2) / (rows + 1)
		local idx = 0
		for row = 1, rows do
			for col = 1, cols do
				idx = idx + 1
				if idx > count then break end
				positions[#positions + 1] = Vector3.new(
					center.X - halfX + col * spacingX,
					center.Y,
					center.Z - halfZ + row * spacingZ
				)
			end
		end
	else
		local areaPerSprinkler = (size.X * size.Z) / count
		local spacing = math.sqrt(areaPerSprinkler)
		local cols = math.ceil(math.sqrt(count))
		local rows = math.ceil(count / cols)
		local idx = 0
		for row = 1, rows do
			for col = 1, cols do
				idx = idx + 1
				if idx > count then break end
				positions[#positions + 1] = Vector3.new(
					center.X - halfX + (col - 0.5) * spacing,
					center.Y,
					center.Z - halfZ + (row - 0.5) * spacing
				)
			end
		end
	end

	return positions
end

function Gear.GetOwnedGear()
	local owned = {}

	local player = game:GetService("Players").LocalPlayer
	if not player then return owned end

	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return owned end

	for _, item in ipairs(backpack:GetChildren()) do
		if item:IsA("Tool") then
			local name = item.Name
			owned[name] = (owned[name] or 0) + 1
		end
	end

	local character = player.Character
	if character then
		for _, item in ipairs(character:GetChildren()) do
			if item:IsA("Tool") then
				local name = item.Name
				owned[name] = (owned[name] or 0) + 1
			end
		end
	end

	return owned
end

function Gear.BuyGear(gearName)
	if not GAG then return false end

	local keepCash = Config and Config.Get and Config.Get("Keep Cash") or 0
	local player = game:GetService("Players").LocalPlayer
	local leaderstats = player and player:FindFirstChild("leaderstats")
	local cash = leaderstats and leaderstats:FindFirstChild("Cash") or leaderstats and leaderstats:FindFirstChild("Sheckles")
	if cash and cash.Value <= keepCash then
		Log("Not enough cash to buy " .. gearName .. " (keeping " .. keepCash .. ")")
		return false
	end

	Log("Buying gear: " .. gearName)
	FireRemote("Networking.GearShop.PurchaseGear", gearName)

	if GAG.Stats then
		GAG.Stats.GearBought = (GAG.Stats.GearBought or 0) + 1
	end

	Sleep(0.5)
	return true
end

function Gear.PlaceSprinkler(sprinklerName, position)
	if not position then
		Log("No position provided for " .. sprinklerName)
		return false
	end

	local owned = Gear.GetOwnedGear()
	if not owned[sprinklerName] or owned[sprinklerName] <= 0 then
		Log("Don't own any " .. sprinklerName)
		return false
	end

	Log("Placing " .. sprinklerName .. " at " .. tostring(position))

	local player = game:GetService("Players").LocalPlayer
	local backpack = player and player:FindFirstChild("Backpack")
	local character = player and player.Character

	local tool = nil
	if backpack then
		tool = backpack:FindFirstChild(sprinklerName)
	end
	if not tool and character then
		tool = character:FindFirstChild(sprinklerName)
	end

	if not tool then
		Log("Could not find " .. sprinklerName .. " in inventory")
		return false
	end

	if character and tool.Parent == backpack then
		tool.Parent = character
		Sleep(0.3)
	end

	TeleportTo(position)
	Sleep(0.2)

	FireRemote("Networking.GearShop.EquipGear", sprinklerName, position)

	if GAG.Stats then
		GAG.Stats.SprinklersPlaced = (GAG.Stats.SprinklersPlaced or 0) + 1
	end

	Sleep(0.5)
	return true
end

function Gear.CalculateSprinklerLayout(farm, count, mode)
	return CalculateSprinklerPositions(farm, count, mode or "value")
end

function Gear.PlaceSprinklers()
	if not GAG then return end

	local config = Config and Config.Get and Config.Get("Place Sprinklers") or {}
	local farm = GetFarm()
	if not farm then
		Log("No farm found, skipping sprinkler placement")
		return
	end

	local owned = Gear.GetOwnedGear()
	local bestUpTo = Config and Config.GetNested and Config.GetNested("Best Sprinkler Up To") or nil
	local coverageMode = Config and Config.GetNested and Config.GetNested("Coverage Mode") or "value"

	local tierOrder = GetTierOrder()

	local function GetBestSprinklerOwned()
		for _, name in ipairs(tierOrder) do
			if bestUpTo then
				local currentTier = SPRINKLER_TIERS[name] or 0
				local limitTier = SPRINKLER_TIERS[bestUpTo] or 999
				if currentTier > limitTier then
					continue
				end
			end
			if owned[name] and owned[name] > 0 then
				return name
			end
		end
		return nil
	end

	if config["best"] then
		local count = config["best"]
		local bestSprinkler = GetBestSprinklerOwned()

		if not bestSprinkler then
			Log("No suitable sprinkler owned (up to " .. (bestUpTo or "max") .. ")")
			return
		end

		local available = math.min(count, owned[bestSprinkler] or 0)
		if available <= 0 then
			Log("No " .. bestSprinkler .. " available to place")
			return
		end

		Log("Placing " .. available .. "x " .. bestSprinkler .. " (" .. coverageMode .. " mode)")
		local positions = Gear.CalculateSprinklerLayout(farm, available, coverageMode)

		for i, pos in ipairs(positions) do
			Gear.PlaceSprinkler(bestSprinkler, pos)
		end
	end

	for sprinklerName, count in pairs(config) do
		if sprinklerName ~= "best" and type(count) == "number" then
			local available = math.min(count, owned[sprinklerName] or 0)
			if available > 0 then
				Log("Placing " .. available .. "x " .. sprinklerName)
				local positions = Gear.CalculateSprinklerLayout(farm, available, coverageMode)
				for i, pos in ipairs(positions) do
					Gear.PlaceSprinkler(sprinklerName, pos)
				end
			end
		end
	end
end

function Gear.ProcessKeepGear()
	if not GAG then return end

	local keepConfig = Config and Config.Get and Config.Get("Keep Gear") or {}
	if not next(keepConfig) then return end

	local owned = Gear.GetOwnedGear()

	for gearName, targetCount in pairs(keepConfig) do
		if type(targetCount) ~= "number" then continue end

		local currentCount = owned[gearName] or 0
		if currentCount < targetCount then
			local toBuy = targetCount - currentCount
			Log("Keeping " .. targetCount .. "x " .. gearName .. " (have " .. currentCount .. ", buying " .. toBuy .. ")")
			for i = 1, toBuy do
				if not Gear.BuyGear(gearName) then
					break
				end
			end
		end
	end
end

function Gear.ProcessBuyGear()
	if not GAG then return end

	local buyConfig = Config and Config.Get and Config.Get("Buy Gear") or {}
	if not next(buyConfig) then return end

	for _, gearName in ipairs(buyConfig) do
		Log("Buying gear: " .. gearName)
		Gear.BuyGear(gearName)
	end
end

function Gear.Init(globals)
	GAG = globals
	Utils = GAG and GAG.Utils or nil
	Config = GAG and GAG.Config or nil
	Log("Gear module initialized")
end

function Gear.Start()
	if not GAG then
		error("Gear module not initialized. Call Gear.Init(GAG) first.")
	end

	Log("Gear module started")

	local sprinklersPlaced = false

	while GAG and GAG.Running do
		local success, err = pcall(function()
			if not sprinklersPlaced then
				Gear.PlaceSprinklers()
				sprinklersPlaced = true
			end

			Gear.ProcessKeepGear()
			Gear.ProcessBuyGear()
		end)

		if not success then
			Log("Error: " .. tostring(err))
		end

		Sleep(5)
	end

	Log("Gear module stopped")
end

return Gear
]])
    LoadModule("Mail",    [[local Mail = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = nil
local Config = nil

local MAILBOX_POSITION = Vector3.new(0, 0, 0)
local CLAIM_REMOTE_PATH = "Networking.Mailbox.Claim"
local SEND_REMOTE_PATH = "Networking.Mailbox.Send"
local OPEN_MAILBOX_REMOTE = "Networking.Mailbox.OpenInbox"

local FRUITS = {
	"Apple", "Banana", "Blueberry", "Cherry", "Coconut", "Dragon Fruit",
	"Grape", "Lemon", "Mango", "Orange", "Peach", "Pear", "Pineapple",
	"Raspberry", "Strawberry", "Watermelon", "Kiwi", "Plum", "Avocado",
	"Starfruit", "Passionfruit", "Pomegranate", "Fig", "Guava", "Lychee",
	"Papaya", "Dragonfruit", "Durian", "Jackfruit", "Rambutan",
}

local function isFruit(itemName)
	return Utils.IsInList(FRUITS, itemName)
end

local function getEquippedPets()
	local equipped = {}
	local character = Players.LocalPlayer.Character
	if not character then return equipped end

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("IsPet") then
			table.insert(equipped, child.Name)
		end
	end

	local petFolder = Players.LocalPlayer:FindFirstChild("PlayerGui")
		and Players.LocalPlayer.PlayerGui:FindFirstChild("PetDisplay")
	if petFolder then
		for _, pet in ipairs(petFolder:GetDescendants()) do
			if pet:IsA("Model") and pet:GetAttribute("Equipped") then
				table.insert(equipped, pet.Name)
			end
		end
	end

	return equipped
end

local function isEquippedPet(itemName, equippedPets)
	return Utils.IsInList(equippedPets, itemName)
end

local function getInventoryItems()
	local items = {}
	local backpack = Players.LocalPlayer:FindFirstChild("Backpack")
	if not backpack then return items end

	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then
			local count = tool:GetAttribute("Count") or 1
			items[tool.Name] = (items[tool.Name] or 0) + count
		end
	end

	local character = Players.LocalPlayer.Character
	if character then
		for _, tool in ipairs(character:GetChildren()) do
			if tool:IsA("Tool") then
				local count = tool:GetAttribute("Count") or 1
				items[tool.Name] = (items[tool.Name] or 0) + count
			end
		end
	end

	return items
end

local function findPlayerByUsername(username)
	username = username:lower()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Name:lower() == username or player.DisplayName:lower() == username then
			return player
		end
	end
	return nil
end

function Mail.Init(GAG)
	Utils = GAG.Utils
	Config = GAG.Config

	GAG.Stats.MailSent = GAG.Stats.MailSent or 0
	GAG.Stats.MailClaimed = GAG.Stats.MailClaimed or 0

	Utils.Log("[Mail] Module initialized")
end

function Mail.ClaimMail(GAG)
	Utils.Log("[Mail] Claiming mailbox items...")

	local success = Utils.FireRemote(OPEN_MAILBOX_REMOTE)
	if not success then
		Utils.Log("[Mail] Failed to open mailbox")
		return false
	end

	task.wait(1)

	local claimed = 0
	local maxAttempts = 10

	for attempt = 1, maxAttempts do
		local claimSuccess = Utils.FireRemote(CLAIM_REMOTE_PATH)
		if claimSuccess then
			claimed = claimed + 1
			GAG.Stats.MailClaimed = (GAG.Stats.MailClaimed or 0) + 1
		end

		local notifications = Players.LocalPlayer.PlayerGui:FindFirstChild("Notifications")
		if notifications then
			for _, notif in ipairs(notifications:GetChildren()) do
				if notif:IsA("GuiButton") or notif:IsA("Frame") then
					notif:Destroy()
				end
			end
		end

		task.wait(0.5)
	end

	Utils.Log("[Mail] Claimed " .. claimed .. " mail items")
	return claimed > 0
end

function Mail.GetMailItems(GAG)
	Utils.Log("[Mail] Fetching mailbox items...")

	local success = Utils.FireRemote(OPEN_MAILBOX_REMOTE)
	if not success then
		return {}
	end

	task.wait(1)

	local mailItems = {}
	local mailRemote = Utils.FireRemote("Networking.Mailbox.List")

	task.wait(0.5)

	local mailboxGui = Players.LocalPlayer.PlayerGui:FindFirstChild("MailboxUI")
	if mailboxGui then
		local scrollFrame = mailboxGui:FindFirstChild("ScrollingFrame", true)
		if scrollFrame then
			for _, item in ipairs(scrollFrame:GetChildren()) do
				if item:IsA("Frame") then
					local nameLabel = item:FindFirstChild("ItemName", true)
					local countLabel = item:FindFirstChild("ItemCount", true)
					if nameLabel then
						table.insert(mailItems, {
							Name = nameLabel.Text,
							Count = countLabel and tonumber(countLabel.Text) or 1,
						})
					end
				end
			end
		end
	end

	Utils.Log("[Mail] Found " .. #mailItems .. " mailbox items")
	return mailItems
end

function Mail.SendItem(GAG, itemName, count, targetPlayer)
	if isFruit(itemName) then
		Utils.Log("[Mail] Skipping fruit: " .. itemName)
		return false
	end

	local equippedPets = getEquippedPets()
	if isEquippedPet(itemName, equippedPets) then
		Utils.Log("[Mail] Skipping equipped pet: " .. itemName)
		return false
	end

	local inventory = getInventoryItems()
	local available = inventory[itemName] or 0

	if available <= 0 then
		Utils.Log("[Mail] No " .. itemName .. " in inventory")
		return false
	end

	local sendCount = math.min(count or available, available)
	if sendCount <= 0 then
		return false
	end

	Utils.Log("[Mail] Sending " .. sendCount .. "x " .. itemName .. " to " .. targetPlayer)

	local success = Utils.FireRemote(SEND_REMOTE_PATH, {
		Action = "Send",
		Item = itemName,
		Count = sendCount,
		Recipient = targetPlayer,
	})

	if success then
		GAG.Stats.MailSent = (GAG.Stats.MailSent or 0) + sendCount
		Utils.Log("[Mail] Sent " .. sendCount .. "x " .. itemName .. " successfully")
		task.wait(1)
		return true
	else
		Utils.Log("[Mail] Failed to send " .. itemName)
		return false
	end
end

function Mail.ShouldSendItem(GAG, itemName)
	if isFruit(itemName) then
		return false
	end

	local equippedPets = getEquippedPets()
	if isEquippedPet(itemName, equippedPets) then
		return false
	end

	local sendList = Config.Get(GAG, "Mail.Send")
	if not sendList then return false end

	for _, entry in ipairs(sendList) do
		if type(entry) == "string" then
			if entry == itemName then
				return true
			end
		elseif type(entry) == "table" then
			if entry.Item == itemName then
				return true
			end
		end
	end

	return false
end

function Mail.GetSendableItems(GAG)
	local sendList = Config.Get(GAG, "Mail.Send")
	if not sendList then return {} end

	local target = Config.Get(GAG, "Mail.Send To")
	if not target or target == "" then return {} end

	local inventory = getInventoryItems()
	local equippedPets = getEquippedPets()
	local toSend = {}

	for _, entry in ipairs(sendList) do
		if type(entry) == "string" then
			local itemName = entry
			if not isFruit(itemName) and not isEquippedPet(itemName, equippedPets) then
				local available = inventory[itemName] or 0
				if available > 0 then
					table.insert(toSend, {
						item = itemName,
						count = available,
						target = target,
					})
				end
			end
		elseif type(entry) == "table" and entry.Item then
			local itemName = entry.Item
			local required = entry.Count or 1

			if not isFruit(itemName) and not isEquippedPet(itemName, equippedPets) then
				local available = inventory[itemName] or 0
				if available >= required then
					table.insert(toSend, {
						item = itemName,
						count = required,
						target = target,
					})
				end
			end
		end
	end

	return toSend
end

function Mail.Start(GAG)
	Utils.Log("[Mail] Starting mail loop...")

	local lastSendTime = 0

	while GAG and GAG.Running do
		local autoClaim = Config.Get(GAG, "Mail.Auto Claim")
		if autoClaim then
			Mail.ClaimMail(GAG)
		end

		local sendTo = Config.Get(GAG, "Mail.Send To")
		if sendTo and sendTo ~= "" then
			local targetPlayer = findPlayerByUsername(sendTo)
			if not targetPlayer then
				Utils.Log("[Mail] Target player not found: " .. sendTo)
			else
				local sendEvery = Config.Get(GAG, "Mail.Send Every") or 0
				local delaySeconds = sendEvery > 0 and (sendEvery * 60) or 45

				local now = tick()
				if now - lastSendTime >= delaySeconds then
					local sendableItems = Mail.GetSendableItems(GAG)

					if #sendableItems > 0 then
						Utils.Log("[Mail] Processing " .. #sendableItems .. " items to send")

						for _, itemData in ipairs(sendableItems) do
							if not GAG.Running then break end

							Mail.SendItem(GAG, itemData.item, itemData.count, targetPlayer.Name)
							task.wait(2)
						end

						lastSendTime = tick()
					else
						Utils.Log("[Mail] No items to send")
					end
				else
					local remaining = math.ceil(delaySeconds - (now - lastSendTime))
					Utils.Log("[Mail] Next send in " .. remaining .. "s")
				end
			end
		end

		Utils.Sleep(GAG, 10)
	end

	Utils.Log("[Mail] Mail loop stopped")
end

return Mail]])
    LoadModule("Misc",    [[local Misc = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Utils, Config

local sessionDailyDeal = false
local gardenCenter = nil
local uiHidden = false
local returnConnection = nil
local eventSeedConnection = nil
local friendConnection = nil

local EVENT_SEED_NAMES = {
	"EventSeed", "FallingSeed", "SeedDrop", "MysterySeed",
	"HalloweenSeed", "ChristmasSeed", "EasterSeed", "ValentineSeed",
	"SummerSeed", "LunarSeed", "LuckySeed", "GalaxySeed",
}

local DAILY_DEAL_NPC_NAMES = {
	"DailyDeal", "DailyDealNPC", "TravelingMerchant",
	"SpecialMerchant", "EventMerchant",
}

local function isEventSeed(part)
	if not part or not part:IsA("BasePart") then return false end
	local name = part.Name:lower()
	for _, keyword in ipairs(EVENT_SEED_NAMES) do
		if name:find(keyword:lower()) then
			return true
		end
	end
	if part:FindFirstChild("EventTag") or part:FindFirstChild("IsEventSeed") then
		return true
	end
	local attr = part:GetAttribute("IsEventSeed") or part:GetAttribute("EventDrop")
	if attr then return true end
	return false
end

local function findEventSeeds()
	local seeds = {}
	local function scan(container)
		for _, child in ipairs(container:GetChildren()) do
			if isEventSeed(child) then
				table.insert(seeds, child)
			end
			if child:IsA("Model") or child:IsA("Folder") then
				scan(child)
			end
		end
	end
	scan(Workspace)
	return seeds
end

local function findNearestEventSeed()
	local seeds = findEventSeeds()
	if #seeds == 0 then return nil end

	local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return nil end

	local nearest = nil
	local nearestDist = math.huge
	for _, seed in ipairs(seeds) do
		local pos = seed:IsA("BasePart") and seed.Position
			or seed:FindFirstChildWhichIsA("BasePart") and seed:FindFirstChildWhichIsA("BasePart").Position
		if pos then
			local dist = (rootPart.Position - pos).Magnitude
			if dist < nearestDist then
				nearestDist = dist
				nearest = seed
			end
		end
	end
	return nearest, nearestDist
end

local function findDailyDealNPC()
	local npcNames = {}
	for _, n in ipairs(DAILY_DEAL_NPC_NAMES) do
		table.insert(npcNames, n:lower())
	end

	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("Model") and obj ~= LocalPlayer.Character then
			local lname = obj.Name:lower()
			for _, keyword in ipairs(npcNames) do
				if lname:find(keyword) then
					local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
					if hrp then return obj, hrp.Position end
				end
			end
		end
	end
	return nil, nil
end

local function getGardenPosition()
	if gardenCenter then return gardenCenter end

	local garden = Workspace:FindFirstChild("Gardens") or Workspace:FindFirstChild("FarmPlots")
	if garden then
		for _, plot in ipairs(garden:GetChildren()) do
			if plot:GetAttribute("Owner") == LocalPlayer.Name
				or plot:FindFirstChild("OwnerTag") and plot.OwnerTag.Value == LocalPlayer.Name
			then
				local part = plot:FindFirstChildWhichIsA("BasePart") or plot.PrimaryPart
				if part then
					gardenCenter = part.Position
					return gardenCenter
				end
			end
		end
	end

	local spawn = Workspace:FindFirstChild("SpawnLocation") or Workspace:FindFirstChild("GardenSpawn")
	if spawn and spawn:IsA("BasePart") then
		gardenCenter = spawn.Position
		return gardenCenter
	end

	return Vector3.new(0, 0, 0)
end

local function collectEventSeed(seedPart)
	if not seedPart then return end
	local pos = seedPart:IsA("BasePart") and seedPart.Position
		or seedPart:FindFirstChildWhichIsA("BasePart") and seedPart:FindFirstChildWhichIsA("BasePart").Position
	if not pos then return end

	Utils.Log("Collecting event seed at " .. tostring(pos))

	local smartTravel = Config.GetNested("Misc.Smart Travel")
	local fastTravel = Config.GetNested("Misc.Fast Travel")

	if smartTravel then
		Utils.SmartWalkTo(pos)
	elseif fastTravel then
		Utils.SlideTo(pos)
	else
		Utils.WalkTo(pos)
	end

	Utils.Sleep(0.5)

	local touchPart = seedPart:IsA("BasePart") and seedPart or seedPart:FindFirstChildWhichIsA("BasePart")
	if touchPart then
		firetouchinterest(LocalPlayer.Character.HumanoidRootPart, touchPart, 0)
		Utils.Sleep(0.1)
		firetouchinterest(LocalPlayer.Character.HumanoidRootPart, touchPart, 1)
	end
end

function Misc.EventSeeds()
	if not Config.GetNested("Event Seeds.Auto Claim") then return end

	local seed, dist = findNearestEventSeed()
	if seed and dist < 300 then
		Utils.Log("Event seed detected! Distance: " .. math.floor(dist))
		Utils.Notify("Event Seed", "Collecting nearby event seed...")
		collectEventSeed(seed)
	end
end

function Misc.AutoFriends()
	local autoAccept = Config.GetNested("Friends.Auto Accept")
	local autoSend = Config.GetNested("Friends.Auto Send")

	if autoAccept then
		local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
		if playerGui then
			for _, gui in ipairs(playerGui:GetDescendants()) do
				if gui:IsA("TextButton") or gui:IsA("ImageButton") then
					local txt = (gui.Text or ""):lower()
					if txt:find("accept") and (txt:find("friend") or gui.Parent and gui.Parent.Name:lower():find("friend")) then
						pcall(function()
							gui.Activated:Fire()
						end)
						Utils.Log("Auto-accepted friend request")
					end
				end
			end
		end

		pcall(function()
			local socialService = game:GetService("SocialService")
			-- Delta executor: accept pending friend requests via core API
			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= LocalPlayer then
					local success = pcall(function()
						socialService:AcceptFriendRequest(LocalPlayer, player)
					end)
					if success then
						Utils.Log("Accepted friend request from " .. player.Name)
					end
				end
			end
		end)
	end

	if autoSend then
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				pcall(function()
					local socialService = game:GetService("SocialService")
					socialService:RequestFriendship(LocalPlayer, player)
					Utils.Log("Sent friend request to " .. player.Name)
				end)
			end
		end
	end
end

function Misc.DailyDeal()
	if sessionDailyDeal then return end
	if not Config.GetNested("Misc.Auto Daily Deal") then return end

	Utils.Log("Attempting Daily Deal...")

	local npc, npcPos = findDailyDealNPC()
	if not npc then
		Utils.Log("Daily Deal NPC not found")
		return
	end

	local smartTravel = Config.GetNested("Misc.Smart Travel")
	local fastTravel = Config.GetNested("Misc.Fast Travel")

	if smartTravel then
		Utils.SmartWalkTo(npcPos)
	elseif fastTravel then
		Utils.SlideTo(npcPos)
	else
		Utils.WalkTo(npcPos)
	end

	Utils.Sleep(1)

	-- Try to interact with the NPC
	local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then
		fireproximityprompt(prompt)
		Utils.Sleep(1)
	end

	-- Try clicking sell/confirm buttons in any NPC dialog
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if playerGui then
		for _, gui in ipairs(playerGui:GetDescendants()) do
			if gui:IsA("TextButton") then
				local txt = (gui.Text or ""):lower()
				if txt:find("sell") or txt:find("confirm") or txt:find("deal") then
					pcall(function()
						gui.Activated:Fire()
					end)
					Utils.Sleep(0.5)
				end
			end
		end
	end

	sessionDailyDeal = true
	Utils.Notify("Daily Deal", "Daily Deal interaction completed")
	Utils.Log("Daily Deal completed for this session")
end

function Misc.ApplyPerformance()
	local fpsCap = Config.GetNested("Misc.FPS Cap")
	if fpsCap and fpsCap > 0 then
		pcall(function()
			setfpscap(fpsCap)
			Utils.Log("FPS cap set to " .. fpsCap)
		end)
	end

	local lowGraphics = Config.GetNested("Misc.Low Graphics")
	if lowGraphics then
		pcall(function()
			local lighting = game:GetService("Lighting")
			lighting.GlobalShadows = false
			lighting.FogEnd = 9e9
			lighting.Brightness = 0

			pcall(function()
				lighting.Technology = Enum.Technology.Compatibility
			end)

			for _, v in ipairs(Workspace:GetDescendants()) do
				if v:IsA("ParticleEmitter") or v:IsA("Fire") or v:IsA("Smoke")
					or v:IsA("Sparkles") or v:IsA("Explosion") or v:IsA("Trail")
				then
					v.Enabled = false
				end
				if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect")
					or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect")
				then
					v.Enabled = false
				end
			end

			pcall(function()
				local lighting2 = game:GetService("Lighting")
				for _, effect in ipairs(lighting2:GetChildren()) do
					if effect:IsA("PostEffect") then
						effect.Enabled = false
					end
				end
			end)

			settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
			Utils.Log("Low graphics applied")
		end)
	end

	local hideGardens = Config.GetNested("Misc.Remove Other Gardens")
	if hideGardens then
		pcall(function()
			local gardenFolder = Workspace:FindFirstChild("Gardens") or Workspace:FindFirstChild("FarmPlots")
			if gardenFolder then
				for _, plot in ipairs(gardenFolder:GetChildren()) do
					local isOwn = plot:GetAttribute("Owner") == LocalPlayer.Name
						or (plot:FindFirstChild("OwnerTag") and plot.OwnerTag.Value == LocalPlayer.Name)
					if not isOwn then
						for _, part in ipairs(plot:GetDescendants()) do
							if part:IsA("BasePart") then
								part.Transparency = 1
							elseif part:IsA("Decal") or part:IsA("Texture") then
								part.Transparency = 1
							end
						end
					end
				end
			end
			Utils.Log("Other gardens hidden")
		end)
	end

	local hideCrops = Config.GetNested("Misc.Hide Crop Visuals")
	if hideCrops then
		pcall(function()
			local cropFolder = Workspace:FindFirstChild("Crops") or Workspace:FindFirstChild("Plants")
			if cropFolder then
				for _, crop in ipairs(cropFolder:GetDescendants()) do
					if crop:IsA("BasePart") or crop:IsA("MeshPart") or crop:IsA("UnionOperation") then
						local name = crop.Name:lower()
						if name:find("stem") or name:find("leaf") or name:find("petal")
							or name:find("body") or name:find("plant") or name:find("crop")
						then
							crop.Transparency = 1
							if crop:FindFirstChildWhichIsA("SpecialMesh") then
								crop:FindFirstChildWhichIsA("SpecialMesh").MeshId = ""
							end
						end
					end
				end
			end
			Utils.Log("Crop visuals hidden")
		end)
	end

	local hideFruits = Config.GetNested("Misc.Hide Fruit Visuals")
	if hideFruits then
		pcall(function()
			local fruitFolder = Workspace:FindFirstChild("Fruits") or Workspace:FindFirstChild("Harvestable")
			if fruitFolder then
				for _, fruit in ipairs(fruitFolder:GetDescendants()) do
					if fruit:IsA("BasePart") or fruit:IsA("MeshPart") then
						fruit.Transparency = 1
					elseif fruit:IsA("SpecialMesh") then
						fruit.MeshId = ""
					end
				end
			end
			Utils.Log("Fruit visuals hidden")
		end)
	end

	local hidePlayers = Config.GetNested("Misc.Hide Players")
	if hidePlayers then
		pcall(function()
			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= LocalPlayer and player.Character then
					for _, part in ipairs(player.Character:GetDescendants()) do
						if part:IsA("BasePart") then
							part.Transparency = 1
						elseif part:IsA("Decal") or part:IsA("Texture") then
							part.Transparency = 1
						elseif part:IsA("Accessory") then
							local handle = part:FindFirstChild("Handle")
							if handle then handle.Transparency = 1 end
						end
					end
				end
			end
			Utils.Log("Other players hidden")
		end)
	end
end

function Misc.AutoReturnToGarden()
	if not Config.GetNested("Misc.Auto Return To Garden") then return end

	local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local gardenPos = getGardenPosition()
	local dist = (rootPart.Position - gardenPos).Magnitude

	if dist > 200 then
		Utils.Log("Too far from garden (" .. math.floor(dist) .. " studs). Returning...")
		Utils.Notify("Auto Return", "Returning to garden...")

		local smartTravel = Config.GetNested("Misc.Smart Travel")
		local fastTravel = Config.GetNested("Misc.Fast Travel")

		if smartTravel then
			Utils.SmartWalkTo(gardenPos)
		elseif fastTravel then
			Utils.SlideTo(gardenPos)
		else
			Utils.WalkTo(gardenPos)
		end
	end
end

function Misc.HideGameUI()
	if not Config.GetNested("Misc.Hide Game UI") then return end

	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
	end)

	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if playerGui then
		local topbar = playerGui:FindFirstChild("TopBar") or playerGui:FindFirstChild("TopbarApp")
		if topbar then
			topbar.Enabled = false
		end

		for _, gui in ipairs(playerGui:GetChildren()) do
			local lname = gui.Name:lower()
			if lname:find("chat") or lname:find("backpack") or lname:find("health")
				or lname:find("topbar") or lname:find("hud")
			then
				gui.Enabled = false
			end
		end
	end

	uiHidden = true
	Utils.Log("Game UI hidden")
end

function Misc.ShowGameUI()
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, true)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, true)
	end)

	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if playerGui then
		local topbar = playerGui:FindFirstChild("TopBar") or playerGui:FindFirstChild("TopbarApp")
		if topbar then
			topbar.Enabled = true
		end
	end

	uiHidden = false
	Utils.Log("Game UI restored")
end

function Misc.ToggleUI()
	if uiHidden then
		Misc.ShowGameUI()
		Utils.Notify("UI", "Game UI shown")
	else
		Misc.HideGameUI()
		Utils.Notify("UI", "Game UI hidden")
	end
end

function Misc.SmartTravel(targetPosition)
	if not targetPosition then return end

	local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local useSmart = Config.GetNested("Misc.Smart Travel")
	local useFast = Config.GetNested("Misc.Fast Travel")

	if useSmart then
		Utils.SmartWalkTo(targetPosition)
	elseif useFast then
		Utils.SlideTo(targetPosition)
	else
		Utils.WalkTo(targetPosition)
	end
end

function Misc.Init(GAG)
	Utils = GAG.Utils
	Config = GAG.Config

	Misc.ApplyPerformance()
	Misc.HideGameUI()

	gardenCenter = nil

	local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		gardenCenter = rootPart.Position
	end

	LocalPlayer.CharacterAdded:Connect(function(char)
		Utils.Sleep(1)
		local hrp = char:WaitForChild("HumanoidRootPart", 10)
		if hrp and not gardenCenter then
			gardenCenter = hrp.Position
		end
	end)

	Utils.Log("Misc module initialized")
end

function Misc.Start(GAG)
	Utils = GAG.Utils or Utils
	Config = GAG.Config or Config

	local keybindConnection = nil
	keybindConnection = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.F7 then
			Misc.ToggleUI()
		end
	end)

	local loopCount = 0
	while true do
		local ok, err = pcall(function()
			Misc.EventSeeds()

			loopCount = loopCount + 1
			if loopCount % 5 == 0 then
				Misc.AutoFriends()
			end

			if loopCount == 1 then
				Misc.DailyDeal()
			end

			Misc.AutoReturnToGarden()

			local walkSpeed = Config.GetNested("Misc.Walk Speed")
			if walkSpeed and walkSpeed > 0 then
				local char = LocalPlayer.Character
				local humanoid = char and char:FindFirstChildWhichIsA("Humanoid")
				if humanoid then
					humanoid.WalkSpeed = walkSpeed
				end
			end

			if Config.GetNested("Misc.Hide Players") and loopCount % 10 == 0 then
				pcall(function()
					for _, player in ipairs(Players:GetPlayers()) do
						if player ~= LocalPlayer and player.Character then
							for _, part in ipairs(player.Character:GetDescendants()) do
								if part:IsA("BasePart") then
									part.Transparency = 1
								end
							end
						end
					end
				end)
			end

			if Config.GetNested("Misc.Hide Game UI") and not uiHidden then
				Misc.HideGameUI()
			elseif not Config.GetNested("Misc.Hide Game UI") and uiHidden then
				Misc.ShowGameUI()
			end
		end)

		if not ok then
			Utils.Log("Misc loop error: " .. tostring(err))
		end

		Utils.Sleep(1)
	end
end

return Misc
]])
    LoadModule("Stats",   [[local Stats = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local overlay = nil
local consoleFrame = nil
local labels = {}
local consoleLines = {}
local updateConnection = nil
local inputConnection = nil
local startTime = 0
local visible = true
local consoleVisible = true
local _GAG = nil

local TOGGLE_KEY = Enum.KeyCode.F4
local MAX_CONSOLE_LINES = 20
local UPDATE_INTERVAL = 1.5

local TAG_COLORS = {
	BUY = Color3.fromRGB(100, 200, 255),
	PLANT = Color3.fromRGB(100, 255, 130),
	SHOVEL = Color3.fromRGB(255, 180, 80),
	SELL = Color3.fromRGB(255, 230, 80),
	MAIL = Color3.fromRGB(200, 130, 255),
	ERROR = Color3.fromRGB(255, 80, 80),
	INFO = Color3.fromRGB(200, 200, 200),
}

function Stats.FormatDuration(seconds)
	seconds = math.floor(seconds)
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	if h > 0 then
		return string.format("%dh %02dm %02ds", h, m, s)
	elseif m > 0 then
		return string.format("%dm %02ds", m, s)
	else
		return string.format("%ds", s)
	end
end

function Stats.FormatNumber(n)
	local formatted = tostring(math.floor(n))
	local k
	repeat
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
	until k == 0
	return formatted
end

local function createTextLabel(props)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = props.Font or Enum.Font.RobotoMono
	label.TextColor3 = props.TextColor3 or Color3.fromRGB(220, 220, 220)
	label.TextSize = props.TextSize or 14
	label.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextWrapped = false
	label.Size = props.Size or UDim2.new(1, 0, 0, 18)
	label.Text = props.Text or ""
	label.Name = props.Name or "Label"
	label.Parent = props.Parent
	return label
end

local function createButton(parent, text, color, callback)
	local btn = Instance.new("TextButton")
	btn.Name = text:gsub("%s+", "") .. "Button"
	btn.BackgroundColor3 = color or Color3.fromRGB(45, 45, 55)
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamSemibold
	btn.TextColor3 = Color3.fromRGB(245, 245, 245)
	btn.TextSize = 11
	btn.Text = text
	btn.AutoButtonColor = true
	btn.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn
	btn.MouseButton1Click:Connect(function()
		pcall(callback)
	end)
	return btn
end

local function applyPreset(name)
	if not _GAG or not _GAG.Modules or not _GAG.Modules.Config then return end
	local ok = _GAG.Modules.Config.ApplyPreset and _GAG.Modules.Config.ApplyPreset(_GAG, name)
	if ok then
		Stats.ConsoleLog("INFO", "Preset applied: " .. name)
		if labels.Preset then labels.Preset.Text = name end
	else
		Stats.ConsoleLog("ERROR", "Preset not found: " .. tostring(name))
	end
end

local function toggleRunning()
	if not _GAG then return end
	local nextState = not (_GAG.Running ~= false and _GAG.State and _GAG.State.Running ~= false)
	_GAG.Running = nextState
	_GAG.Farming = nextState
	_GAG.State = _GAG.State or {}
	_GAG.State.Running = nextState
	Stats.ConsoleLog("INFO", nextState and "Farm resumed" or "Farm paused")
end

local function getMoney()
	local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
	if leaderstats then
		local cash = leaderstats:FindFirstChild("Cash") or leaderstats:FindFirstChild("Money") or leaderstats:FindFirstChild("Coins")
		if cash then
			return cash.Value
		end
	end
	return 0
end

local function getInventoryInfo()
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	local character = LocalPlayer.Character
	local count = 0
	local capacity = 60
	if backpack then
		count = count + #backpack:GetChildren()
	end
	if character then
		count = count + #character:GetChildren()
	end
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if playerGui then
		local mainGui = playerGui:FindFirstChild("Main") or playerGui:FindFirstChild("Inventory")
		if mainGui then
			local capLabel = mainGui:FindFirstChild("Capacity", true)
			if capLabel and capLabel:IsA("TextLabel") then
				local cap = tonumber(capLabel.Text:match("(%d+)"))
				if cap then capacity = cap end
			end
		end
	end
	return count, capacity
end

local function buildStatEntry(parent, labelText, name)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 18)
	row.Name = name
	row.Parent = parent

	local lbl = createTextLabel({
		Name = "Label",
		Text = labelText,
		Size = UDim2.new(0.55, 0, 1, 0),
		TextColor3 = Color3.fromRGB(170, 170, 170),
		TextSize = 13,
		Parent = row,
	})

	local val = createTextLabel({
		Name = "Value",
		Text = "0",
		Size = UDim2.new(0.45, 0, 1, 0),
		Position = UDim2.new(0.55, 0, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 13,
		Parent = row,
	})

	return val
end

local function createConsoleLine(tag, message)
	local tagColor = TAG_COLORS[tag] or TAG_COLORS.INFO
	local timestamp = os.date("%H:%M:%S")

	local line = Instance.new("Frame")
	line.BackgroundTransparency = 1
	line.Size = UDim2.new(1, 0, 0, 16)
	line.Name = "Line"

	local timeLabel = Instance.new("TextLabel")
	timeLabel.BackgroundTransparency = 1
	timeLabel.Font = Enum.Font.RobotoMono
	timeLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
	timeLabel.TextSize = 11
	timeLabel.TextXAlignment = Enum.TextXAlignment.Left
	timeLabel.Size = UDim2.new(0, 62, 1, 0)
	timeLabel.Text = timestamp
	timeLabel.Parent = line

	local tagLabel = Instance.new("TextLabel")
	tagLabel.BackgroundTransparency = 1
	tagLabel.Font = Enum.Font.RobotoMono
	tagLabel.TextColor3 = tagColor
	tagLabel.TextSize = 11
	tagLabel.TextXAlignment = Enum.TextXAlignment.Left
	tagLabel.Size = UDim2.new(0, 50, 1, 0)
	tagLabel.Position = UDim2.new(0, 64, 0, 0)
	tagLabel.Text = "[" .. tag .. "]"
	tagLabel.Parent = line

	local msgLabel = Instance.new("TextLabel")
	msgLabel.BackgroundTransparency = 1
	msgLabel.Font = Enum.Font.RobotoMono
	msgLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	msgLabel.TextSize = 11
	msgLabel.TextXAlignment = Enum.TextXAlignment.Left
	msgLabel.TextTruncate = Enum.TextTruncate.AtEnd
	msgLabel.Size = UDim2.new(1, -118, 1, 0)
	msgLabel.Position = UDim2.new(0, 118, 0, 0)
	msgLabel.Text = message
	msgLabel.Parent = line

	return line
end

function Stats.CreateOverlay()
	if overlay then overlay:Destroy() end

	overlay = Instance.new("ScreenGui")
	overlay.Name = "GAG_Stats"
	overlay.ResetOnSpawn = false
	overlay.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	panel.BackgroundTransparency = 0.15
	panel.BorderSizePixel = 0
	panel.Size = UDim2.new(0, 280, 0, 445)
	panel.Position = UDim2.new(1, -295, 0, 15)
	panel.Parent = overlay

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(50, 50, 60)
	stroke.Thickness = 1
	stroke.Parent = panel

	local title = createTextLabel({
		Name = "Title",
		Text = "GAG AUTOFARM",
		TextColor3 = Color3.fromRGB(100, 220, 140),
		TextSize = 15,
		Size = UDim2.new(1, -16, 0, 22),
		Position = UDim2.new(0, 8, 0, 6),
		Font = Enum.Font.RobotoMono,
		Parent = panel,
	})

	local divider = Instance.new("Frame")
	divider.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	divider.BorderSizePixel = 0
	divider.Size = UDim2.new(1, -16, 0, 1)
	divider.Position = UDim2.new(0, 8, 0, 32)
	divider.Parent = panel

	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 2)
	list.Parent = panel

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.Size = UDim2.new(1, -16, 1, -82)
	content.Position = UDim2.new(0, 8, 0, 38)
	content.Parent = panel

	local contentList = Instance.new("UIListLayout")
	contentList.SortOrder = Enum.SortOrder.LayoutOrder
	contentList.Padding = UDim.new(0, 1)
	contentList.Parent = content

	local statusLabel = createTextLabel({
		Name = "StatusLabel",
		Text = "Status",
		Size = UDim2.new(1, 0, 0, 20),
		TextSize = 13,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		Parent = content,
	})

	local statusValue = createTextLabel({
		Name = "StatusValue",
		Text = "ACTIVE",
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 60, 0, 0),
		TextSize = 13,
		TextColor3 = Color3.fromRGB(100, 255, 130),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = content,
	})

	labels.Status = statusValue

	local presetRow = Instance.new("Frame")
	presetRow.Name = "PresetRow"
	presetRow.BackgroundTransparency = 1
	presetRow.Size = UDim2.new(1, 0, 0, 18)
	presetRow.Parent = content

	createTextLabel({
		Text = "Preset",
		Size = UDim2.new(0.45, 0, 1, 0),
		TextColor3 = Color3.fromRGB(170, 170, 170),
		TextSize = 13,
		Parent = presetRow,
	})

	labels.Preset = createTextLabel({
		Name = "PresetValue",
		Text = tostring((_GAG and _GAG.Config and _GAG.Config.Preset) or "Custom"),
		Size = UDim2.new(0.55, 0, 1, 0),
		Position = UDim2.new(0.45, 0, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = Color3.fromRGB(120, 200, 255),
		TextSize = 13,
		Parent = presetRow,
	})

	local controls = Instance.new("Frame")
	controls.Name = "QuickControls"
	controls.BackgroundTransparency = 1
	controls.Size = UDim2.new(1, 0, 0, 58)
	controls.Parent = content

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0, 78, 0, 24)
	grid.CellPadding = UDim2.new(0, 4, 0, 4)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = controls

	createButton(controls, "Starter", Color3.fromRGB(45, 95, 60), function() applyPreset("Starter") end)
	createButton(controls, "Balanced", Color3.fromRGB(45, 80, 120), function() applyPreset("Balanced") end)
	createButton(controls, "Rich", Color3.fromRGB(120, 80, 35), function() applyPreset("Rich") end)
	createButton(controls, "Alt/Main", Color3.fromRGB(95, 60, 120), function() applyPreset("AltToMain") end)
	createButton(controls, "Low PC", Color3.fromRGB(60, 90, 90), function() applyPreset("LowPC") end)
	createButton(controls, "Pause/Run", Color3.fromRGB(120, 55, 55), toggleRunning)

	local statsOrder = {
		{ name = "Harvested", text = "Harvested" },
		{ name = "Sold", text = "Sold" },
		{ name = "Planted", text = "Planted" },
		{ name = "Shoveled", text = "Shoveled" },
		{ name = "Expansions", text = "Expansions" },
		{ name = "SeedsBought", text = "Seeds Bought" },
		{ name = "GearBought", text = "Gear Bought" },
		{ name = "PetsBought", text = "Pets Bought" },
		{ name = "Mailed", text = "Items Mailed" },
	}

	for i, entry in ipairs(statsOrder) do
		labels[entry.name] = buildStatEntry(content, entry.text, entry.name)
	end

	local sep = Instance.new("Frame")
	sep.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	sep.BorderSizePixel = 0
	sep.Size = UDim2.new(1, 0, 0, 1)
	sep.Parent = content

	local runtimeRow = Instance.new("Frame")
	runtimeRow.BackgroundTransparency = 1
	runtimeRow.Size = UDim2.new(1, 0, 0, 18)
	runtimeRow.Parent = content

	local runtimeLbl = createTextLabel({
		Text = "Runtime",
		Size = UDim2.new(0.55, 0, 1, 0),
		TextColor3 = Color3.fromRGB(170, 170, 170),
		TextSize = 13,
		Parent = runtimeRow,
	})

	local runtimeVal = createTextLabel({
		Name = "RuntimeValue",
		Text = "0s",
		Size = UDim2.new(0.45, 0, 1, 0),
		Position = UDim2.new(0.55, 0, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 13,
		Parent = runtimeRow,
	})

	labels.Runtime = runtimeVal

	local moneyRow = Instance.new("Frame")
	moneyRow.BackgroundTransparency = 1
	moneyRow.Size = UDim2.new(1, 0, 0, 18)
	moneyRow.Parent = content

	createTextLabel({
		Text = "Money",
		Size = UDim2.new(0.55, 0, 1, 0),
		TextColor3 = Color3.fromRGB(170, 170, 170),
		TextSize = 13,
		Parent = moneyRow,
	})

	labels.Money = createTextLabel({
		Name = "MoneyValue",
		Text = "$0",
		Size = UDim2.new(0.45, 0, 1, 0),
		Position = UDim2.new(0.55, 0, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = Color3.fromRGB(100, 255, 130),
		TextSize = 13,
		Parent = moneyRow,
	})

	local invRow = Instance.new("Frame")
	invRow.BackgroundTransparency = 1
	invRow.Size = UDim2.new(1, 0, 0, 18)
	invRow.Parent = content

	createTextLabel({
		Text = "Inventory",
		Size = UDim2.new(0.55, 0, 1, 0),
		TextColor3 = Color3.fromRGB(170, 170, 170),
		TextSize = 13,
		Parent = invRow,
	})

	labels.Inventory = createTextLabel({
		Name = "InventoryValue",
		Text = "0 / 60",
		Size = UDim2.new(0.45, 0, 1, 0),
		Position = UDim2.new(0.55, 0, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 13,
		Parent = invRow,
	})

	local hintLabel = createTextLabel({
		Name = "Hint",
		Text = "F4 to toggle",
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 0, 1, -18),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = Color3.fromRGB(80, 80, 90),
		TextSize = 10,
		Parent = panel,
	})

	consoleFrame = Instance.new("Frame")
	consoleFrame.Name = "Console"
	consoleFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	consoleFrame.BackgroundTransparency = 0.1
	consoleFrame.BorderSizePixel = 0
	consoleFrame.Size = UDim2.new(0, 380, 0, 340)
	consoleFrame.Position = UDim2.new(1, -395, 0, 470)
	consoleFrame.Parent = overlay

	local consoleCorner = Instance.new("UICorner")
	consoleCorner.CornerRadius = UDim.new(0, 8)
	consoleCorner.Parent = consoleFrame

	local consoleStroke = Instance.new("UIStroke")
	consoleStroke.Color = Color3.fromRGB(45, 45, 55)
	consoleStroke.Thickness = 1
	consoleStroke.Parent = consoleFrame

	local consoleTitle = createTextLabel({
		Name = "ConsoleTitle",
		Text = "CONSOLE FEED",
		TextColor3 = Color3.fromRGB(255, 200, 80),
		TextSize = 13,
		Size = UDim2.new(1, -16, 0, 20),
		Position = UDim2.new(0, 8, 0, 6),
		Font = Enum.Font.RobotoMono,
		Parent = consoleFrame,
	})

	local consoleDivider = Instance.new("Frame")
	consoleDivider.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	consoleDivider.BorderSizePixel = 0
	consoleDivider.Size = UDim2.new(1, -16, 0, 1)
	consoleDivider.Position = UDim2.new(0, 8, 0, 28)
	consoleDivider.Parent = consoleFrame

	local scrolling = Instance.new("ScrollingFrame")
	scrolling.Name = "ScrollArea"
	scrolling.BackgroundTransparency = 1
	scrolling.BorderSizePixel = 0
	scrolling.ScrollBarThickness = 4
	scrolling.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
	scrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrolling.Size = UDim2.new(1, -16, 1, -38)
	scrolling.Position = UDim2.new(0, 8, 0, 34)
	scrolling.Parent = consoleFrame

	local scrollList = Instance.new("UIListLayout")
	scrollList.SortOrder = Enum.SortOrder.LayoutOrder
	scrollList.Padding = UDim.new(0, 1)
	scrollList.Parent = scrolling

	consoleLines = {}

	overlay.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

function Stats.ConsoleLog(tag, message)
	if not consoleFrame then return end
	local scrolling = consoleFrame:FindFirstChild("ScrollArea", true)
	if not scrolling then return end

	local line = createConsoleLine(tag, message)
	line.Parent = scrolling

	table.insert(consoleLines, line)

	while #consoleLines > MAX_CONSOLE_LINES do
		local oldest = table.remove(consoleLines, 1)
		if oldest and oldest.Parent then
			oldest:Destroy()
		end
	end

	scrolling.CanvasPosition = Vector2.new(0, math.max(0, scrolling.AbsoluteCanvasSize.Y - scrolling.AbsoluteWindowSize.Y))
end

function Stats.UpdateOverlay()
	if not overlay or not _GAG then return end
	if not visible then return end

	local stats = _GAG.Stats or {}
	local elapsed = os.clock() - startTime

	if labels.Status then
		local farming = (_GAG.Running ~= false) and (_GAG.State == nil or _GAG.State.Running ~= false)
		if farming then
			labels.Status.Text = "ACTIVE"
			labels.Status.TextColor3 = Color3.fromRGB(100, 255, 130)
		else
			labels.Status.Text = "PAUSED"
			labels.Status.TextColor3 = Color3.fromRGB(255, 180, 80)
		end
	end

	if labels.Harvested then labels.Harvested.Text = Stats.FormatNumber(stats.Harvested or 0) end
	if labels.Sold then labels.Sold.Text = Stats.FormatNumber(stats.Sold or 0) end
	if labels.Planted then labels.Planted.Text = Stats.FormatNumber(stats.Planted or 0) end
	if labels.Shoveled then labels.Shoveled.Text = Stats.FormatNumber(stats.Shoveled or 0) end
	if labels.Expansions then labels.Expansions.Text = Stats.FormatNumber(stats.Expansions or 0) end
	if labels.SeedsBought then labels.SeedsBought.Text = Stats.FormatNumber(stats.SeedsBought or 0) end
	if labels.GearBought then labels.GearBought.Text = Stats.FormatNumber(stats.GearBought or 0) end
	if labels.PetsBought then labels.PetsBought.Text = Stats.FormatNumber(stats.PetsBought or 0) end
	if labels.Mailed then labels.Mailed.Text = Stats.FormatNumber(stats.Mailed or 0) end

	if labels.Runtime then labels.Runtime.Text = Stats.FormatDuration(elapsed) end

	if labels.Money then labels.Money.Text = "$" .. Stats.FormatNumber(getMoney()) end

	if labels.Inventory then
		local count, cap = getInventoryInfo()
		labels.Inventory.Text = count .. " / " .. cap
		if count >= cap then
			labels.Inventory.TextColor3 = Color3.fromRGB(255, 100, 100)
		elseif count >= cap * 0.8 then
			labels.Inventory.TextColor3 = Color3.fromRGB(255, 220, 80)
		else
			labels.Inventory.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end
end

function Stats.Toggle()
	visible = not visible
	if overlay then
		local panel = overlay:FindFirstChild("Panel")
		if panel then panel.Visible = visible end
	end
end

function Stats.SetConsole(enabled)
	consoleVisible = enabled
	if consoleFrame then
		consoleFrame.Visible = enabled
	end
end

function Stats.Start(GAG)
	_GAG = GAG
	startTime = os.clock()

	Stats.CreateOverlay()

	if inputConnection then inputConnection:Disconnect() end
	inputConnection = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == TOGGLE_KEY then
			Stats.Toggle()
		end
	end)

	if updateConnection then updateConnection:Disconnect() end
	local accumulator = 0
	updateConnection = RunService.Heartbeat:Connect(function(dt)
		accumulator = accumulator + dt
		if accumulator >= UPDATE_INTERVAL then
			accumulator = 0
			Stats.UpdateOverlay()
		end
	end)

	Stats.ConsoleLog("INFO", "Stats overlay started")
end

function Stats.Init(GAG)
	_GAG = GAG
	if not GAG.Stats then
		GAG.Stats = {
			Harvested = 0,
			Sold = 0,
			Planted = 0,
			Shoveled = 0,
			Expansions = 0,
			SeedsBought = 0,
			GearBought = 0,
			PetsBought = 0,
			Mailed = 0,
		}
	end
end

return Stats
]])
    
    print("[GAG] All modules loaded!")
    print("[GAG] ==============================")
    
    -- Start all module threads
    for name, mod in pairs(GAG.Modules) do
        if mod.Start then
            coroutine.wrap(function()
                local ok, err = pcall(mod.Start, GAG)
                if not ok then
                    warn("[GAG] Module " .. name .. " error: " .. tostring(err))
                end
            end)()
        end
    end
end

-- Character ready check
if not Character or not Character:FindFirstChild("HumanoidRootPart") then
    LocalPlayer.CharacterAdded:Wait()
    task.wait(1)
end

Boot()
