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
_G.GAGConfig = _G.GAGConfig or {}
-- Keep the modular build manual by default. Set Preset before executing to opt in.

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
    if type(source) ~= "string" or source:match("^%-%-#include") then
        warn("[GAG] Module " .. name .. " was not injected. Build src/loader.lua with tools/build_modular_source.py first.")
        return nil
    end
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

-- Module sources are injected by tools/build_modular_source.py.
-- This template intentionally fails clearly if it is pasted without being built.

---------------------------------------------------------------------------
-- 4. BOOT SEQUENCE
---------------------------------------------------------------------------
local function Boot()
    print("[GAG] ==============================")
    print("[GAG] Grow a Garden Autofarm")
    print("[GAG] Loading modules...")
    
    -- Load order matters: Utils first, then Config, then farm modules
    LoadModule("Config",  [[--#include Config.lua]])
    LoadModule("Utils",   [[--#include Utils.lua]])
    LoadModule("Harvest", [[--#include Harvest.lua]])
    LoadModule("Plant",   [[--#include Plant.lua]])
    LoadModule("BuySeeds",[[--#include BuySeeds.lua]])
    LoadModule("Pets",    [[--#include Pets.lua]])
    LoadModule("Gear",    [[--#include Gear.lua]])
    LoadModule("Mail",    [[--#include Mail.lua]])
    LoadModule("Misc",    [[--#include Misc.lua]])
    LoadModule("Stats",   [[--#include Stats.lua]])
    
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
