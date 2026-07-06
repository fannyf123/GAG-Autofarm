--[[
    Grow a Garden — Autofarm (All-in-One)
    Target: Delta Executor
    
    Cara pakai:
      1. Edit config di bawah sesuai kebutuhan
      2. Paste & run di Delta
    
    Mobile: gunakan tombol floating STATS / CONSOLE di layar
]]

---------------------------------------------------------------------------
-- CONFIG USER — Edit di sini
---------------------------------------------------------------------------
_G.GAGConfig = {
    ["Auto Harvest"]        = true,
    ["Sell At"]             = 85,
    ["Sell Every"]          = 40,
    ["Only Harvest"]        = {},
    ["Don't Harvest"]       = {},
    ["Wait For Mutation"]   = { "Bamboo", "Mushroom" },

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

    ["Keep Cash"]           = 15000,
    ["Auto Expand Plot"]    = true,
    ["Max Expansions"]      = 3,
    ["Expand If Over"]      = 1500000,
    ["Auto Replace Plants"] = true,

    ["Never Sell"] = {
        ["By Mutation"] = { "Rainbow", "Gold" },
        ["By Fruit"]    = {},
        ["Exact"]       = {},
    },

    ["Pets"] = {
        ["Buy"]            = {},
        ["Equip"]          = {},
        ["Auto Buy Slots"] = true,
        ["Max Pet Slots"]  = 6,
    },

    ["Gear"] = {
        ["Auto Buy"]           = true,
        ["Keep Cash"]          = 15000,
        ["Sprinkler Coverage"] = "concentrate",
        ["Place Sprinklers"]   = { ["best"] = 4 },
        ["Best Sprinkler Up To"] = "Rare Sprinkler",
        ["Keep Gear"]          = {},
        ["Buy Gear"]           = {},
    },

    ["Event Seeds"] = {
        ["Auto Claim"] = true,
    },

    ["Mail"] = {
        ["Auto Claim"] = true,
        ["Send To"]    = "",
        ["Send Every"] = 0,
        ["Send"]       = {},
    },

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

    ["Friends"] = {
        ["Auto Accept"] = false,
        ["Auto Send"]   = false,
    },

    ["Performance"] = {
        ["FPS Cap"]              = 0,
        ["Low Graphics"]         = true,
        ["Remove Other Gardens"] = true,
        ["Hide Crop Visuals"]    = true,
        ["Hide Fruit Visuals"]   = true,
        ["Hide Players"]         = true,
    },

    ["Debug"] = {
        ["Log To File"] = true,
        ["Console"]     = true,
    },
}

---------------------------------------------------------------------------
-- SERVICES
---------------------------------------------------------------------------
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local StarterGui        = game:GetService("StarterGui")
local Lighting          = game:GetService("Lighting")

local LP   = Players.LocalPlayer
local Char = LP.Character
if not Char then
    local started = tick()
    repeat
        task.wait(0.2)
        Char = LP.Character
    until Char or tick() - started > 20
end
local HRP = Char and (Char:FindFirstChild("HumanoidRootPart") or Char:WaitForChild("HumanoidRootPart", 20)) or nil

---------------------------------------------------------------------------
-- GLOBAL STATE
---------------------------------------------------------------------------
if type(_G.GAG) == "table" then
    _G.GAG.Alive = false
    _G.GAG.Running = false
end

_G.GAG = {
    Alive    = true,
    Running  = true,
    Player   = LP,
    Character = Char,
    HRP      = HRP,
    Config   = _G.GAGConfig,
    Stats    = {
        Harvested  = 0, Sold = 0, Planted = 0, Shoveled = 0,
        Expanded   = 0, SeedsBought = 0, GearBought = 0,
        PetsBought = 0, MailSent = 0, Replaced = 0,
    },
}
local GAG = _G.GAG

LP.CharacterAdded:Connect(function(c)
    GAG.Character = c
    GAG.HRP = c:WaitForChild("HumanoidRootPart")
    HRP = GAG.HRP
end)

---------------------------------------------------------------------------
-- CONFIG MODULE
---------------------------------------------------------------------------
local Config = {}
do
    local DEFAULTS = {
        ["Auto Harvest"] = true, ["Sell At"] = 85, ["Sell Every"] = 40,
        ["Only Harvest"] = {}, ["Don't Harvest"] = {},
        ["Wait For Mutation"] = { "Bamboo", "Mushroom" },
        ["Auto Plant"] = true, ["Plant Plan"] = {}, ["Only Plant"] = {},
        ["Minimum Seed"] = "Bamboo", ["Layout"] = "compact",
        ["Don't Plant"] = {}, ["Don't Buy"] = {}, ["Keep Seeds"] = {},
        ["Plant Limit"] = 0, ["Never Shovel"] = {}, ["Shovel Up To"] = "",
        ["Buy Seeds"] = {},
        ["Keep Cash"] = 15000, ["Auto Expand Plot"] = true,
        ["Max Expansions"] = 3, ["Expand If Over"] = 1500000,
        ["Auto Replace Plants"] = true,
        ["Never Sell"] = { ["By Mutation"] = {}, ["By Fruit"] = {}, ["Exact"] = {} },
        ["Pets"] = { ["Buy"] = {}, ["Equip"] = {}, ["Auto Buy Slots"] = true, ["Max Pet Slots"] = 6 },
        ["Gear"] = { ["Auto Buy"] = true, ["Keep Cash"] = 15000, ["Sprinkler Coverage"] = "concentrate",
            ["Place Sprinklers"] = { ["best"] = 4 }, ["Best Sprinkler Up To"] = "Rare Sprinkler",
            ["Keep Gear"] = {}, ["Buy Gear"] = {} },
        ["Event Seeds"] = { ["Auto Claim"] = true },
        ["Mail"] = { ["Auto Claim"] = true, ["Send To"] = "", ["Send Every"] = 0, ["Send"] = {} },
        ["Misc"] = { ["Auto Return To Garden"] = true, ["Show Stats"] = true, ["Hide Game UI"] = false,
            ["Show Console"] = false, ["Smart Travel"] = true, ["Auto Daily Deal"] = true,
            ["Walk Speed"] = 0, ["Slide Speed"] = 30, ["Fast Travel"] = false, ["Teleport"] = true },
        ["Friends"] = { ["Auto Accept"] = false, ["Auto Send"] = false },
        ["Performance"] = { ["FPS Cap"] = 0, ["Low Graphics"] = true, ["Remove Other Gardens"] = true,
            ["Hide Crop Visuals"] = true, ["Hide Fruit Visuals"] = true, ["Hide Players"] = true },
        ["Debug"] = { ["Log To File"] = true, ["Console"] = true },
    }

    local function DeepMerge(def, usr)
        if type(def) ~= "table" or type(usr) ~= "table" then
            return usr ~= nil and usr or def
        end
        local r = {}
        for k, v in pairs(def) do
            if usr[k] ~= nil then
                r[k] = (type(v) == "table" and type(usr[k]) == "table") and DeepMerge(v, usr[k]) or usr[k]
            else
                r[k] = v
            end
        end
        for k, v in pairs(usr) do
            if r[k] == nil then r[k] = v end
        end
        return r
    end

    local function BuildSet(list)
        if type(list) ~= "table" then return {} end
        local s = {}
        for k, v in pairs(list) do
            if type(k) == "number" then s[v] = true else s[k] = v end
        end
        return s
    end

    local function Init()
        local cfg = DeepMerge(DEFAULTS, GAG.Config or {})
        for _, key in ipairs({"Never Sell", "Pets", "Gear", "Event Seeds", "Mail", "Misc", "Friends", "Performance", "Debug"}) do
            if type(cfg[key]) ~= "table" then
                cfg[key] = DeepMerge(DEFAULTS[key], {})
            end
        end
        for _, key in ipairs({"By Mutation", "By Fruit", "Exact"}) do
            if type(cfg["Never Sell"][key]) ~= "table" then
                cfg["Never Sell"][key] = {}
            end
        end
        -- Clamp
        cfg["Sell At"] = math.clamp(tonumber(cfg["Sell At"]) or 85, 1, 200)
        cfg["Sell Every"] = math.max(tonumber(cfg["Sell Every"]) or 40, 0)
        cfg["Keep Cash"] = math.max(tonumber(cfg["Keep Cash"]) or 15000, 0)
        cfg["Plant Limit"] = math.max(tonumber(cfg["Plant Limit"]) or 0, 0)
        cfg["Misc"]["Slide Speed"] = math.clamp(tonumber(cfg["Misc"]["Slide Speed"]) or 30, 10, 150)

        -- Lookup sets
        cfg._LK = {
            OnlyHarvest = BuildSet(cfg["Only Harvest"]),
            DontHarvest = BuildSet(cfg["Don't Harvest"]),
            WaitForMut  = BuildSet(cfg["Wait For Mutation"]),
            OnlyPlant   = BuildSet(cfg["Only Plant"]),
            DontPlant   = BuildSet(cfg["Don't Plant"]),
            DontBuy     = BuildSet(cfg["Don't Buy"]),
            NeverShovel = BuildSet(cfg["Never Shovel"]),
            NeverSellMut   = BuildSet(cfg["Never Sell"]["By Mutation"]),
            NeverSellFruit = BuildSet(cfg["Never Sell"]["By Fruit"]),
        }
        cfg._LK.NeverSellExact = {}
        for _, p in ipairs(cfg["Never Sell"]["Exact"] or {}) do
            if p.fruit and p.mut then
                cfg._LK.NeverSellExact[p.fruit .. "|" .. p.mut] = true
            end
        end
        GAG.Config = cfg
    end

    Init()

    function Config.Get(key) return GAG.Config[key] end
    function Config.GetNested(section, key)
        local s = GAG.Config[section]
        return s and type(s) == "table" and s[key] or nil
    end
    function Config.ShouldHarvest(name)
        local c = GAG.Config; local lk = c._LK
        if not c["Auto Harvest"] then return false end
        if next(lk.OnlyHarvest) and not lk.OnlyHarvest[name] then return false end
        if lk.DontHarvest[name] then return false end
        return true
    end
    function Config.ShouldPlant(name)
        local c = GAG.Config; local lk = c._LK
        if not c["Auto Plant"] then return false end
        if next(lk.OnlyPlant) and not lk.OnlyPlant[name] then return false end
        if lk.DontPlant[name] then return false end
        return true
    end
    function Config.ShouldBuySeed(name)
        local lk = GAG.Config._LK
        if lk.DontPlant[name] then return false end
        if lk.DontBuy[name] then return false end
        local banned = { Gold = true, Rainbow = true, Mega = true }
        if banned[name] then return false end
        return true
    end
    function Config.ShouldShovel(name, tier)
        local lk = GAG.Config._LK
        if lk.NeverShovel[name] then return false end
        local tiers = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mythic = 6 }
        local max = tiers[GAG.Config["Shovel Up To"]]
        if max and tiers[tier] and tiers[tier] > max then return false end
        return true
    end
    function Config.ShouldNeverSell(fruit, mut)
        local lk = GAG.Config._LK
        if mut and lk.NeverSellMut[mut] then return true end
        if lk.NeverSellFruit[fruit] then return true end
        if mut and lk.NeverSellExact[fruit .. "|" .. mut] then return true end
        return false
    end
end

---------------------------------------------------------------------------
-- UTILS MODULE
---------------------------------------------------------------------------
local Utils = {}
do
    local remoteCache = {}

    local function SafeRoot()
        local c = LP.Character or LP.CharacterAdded:Wait()
        return c, c:FindFirstChild("HumanoidRootPart"), c:FindFirstChildOfClass("Humanoid")
    end

    function Utils.Log(tag, msg)
        local dbg = GAG.Config["Debug"]
        if dbg and dbg["Console"] ~= false then
            print(string.format("[%s][%s] %s", os.date("%H:%M:%S"), tag, tostring(msg)))
        end
    end

    function Utils.Notify(title, text)
        pcall(StarterGui.SetCore, StarterGui, "SendNotification", { Title = title, Text = text, Duration = 4 })
    end

    function Utils.Sleep(sec)
        if not sec or sec <= 0 then return end
        local e = 0
        while e < sec do
            if not GAG.Alive then return end
            local s = math.min(0.1, sec - e)
            task.wait(s)
            e = e + s
        end
    end

    function Utils.WalkTo(pos, timeout)
        timeout = timeout or 10
        local _, hrp, hum = SafeRoot()
        if not hum then return false end
        local target = typeof(pos) == "CFrame" and pos.Position or pos
        local reached = false
        local conn = hum.MoveToFinished:Connect(function() reached = true end)
        hum:MoveTo(target)
        local e = 0
        while not reached and e < timeout do
            if not GAG.Alive then conn:Disconnect() return false end
            if hrp and (hrp.Position * Vector3.new(1,0,1) - target * Vector3.new(1,0,1)).Magnitude < 3 then
                reached = true; break
            end
            task.wait(0.1); e = e + 0.1
        end
        if conn.Connected then conn:Disconnect() end
        return reached
    end

    function Utils.TeleportTo(pos)
        local _, hrp = SafeRoot()
        if not hrp then return false end
        hrp.CFrame = typeof(pos) == "CFrame" and pos or CFrame.new(pos)
        return true
    end

    function Utils.SlideTo(pos, speed)
        speed = speed or GAG.Config["Misc"]["Slide Speed"] or 30
        local target = typeof(pos) == "CFrame" and pos.Position or pos
        local c, hrp, hum = SafeRoot()
        if not hrp or not hum then return false end
        local orig = {}
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then orig[p] = p.CanCollide; p.CanCollide = false end
        end
        local dist = (target - hrp.Position).Magnitude
        local tw = TweenService:Create(hrp, TweenInfo.new(dist / speed, Enum.EasingStyle.Linear), { CFrame = CFrame.new(target) })
        tw:Play()
        tw.Completed:Wait()
        for p, cc in pairs(orig) do if p and p.Parent then p.CanCollide = cc end end
        return true
    end

    function Utils.GetFarm()
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj.Name:lower():find("farm") or obj.Name:lower():find("plot") then
                local o = obj:FindFirstChild("Owner") or obj:FindFirstChild("OwnerValue")
                if o then
                    if o:IsA("StringValue") and o.Value == LP.Name then return obj end
                    if o:IsA("ObjectValue") and o.Value == LP then return obj end
                end
            end
        end
        local folder = workspace:FindFirstChild("Farms") or workspace:FindFirstChild("Plots") or workspace:FindFirstChild("Gardens")
        if folder then
            for _, p in ipairs(folder:GetChildren()) do
                local o = p:FindFirstChild("Owner") or p:FindFirstChild("OwnerValue")
                if o then
                    if o:IsA("StringValue") and o.Value == LP.Name then return p end
                    if o:IsA("ObjectValue") and o.Value == LP then return p end
                end
                if p.Name == LP.Name then return p end
            end
        end
        return nil
    end

    function Utils.GetPlants(farm)
        farm = farm or Utils.GetFarm()
        if not farm then return {} end
        local pf = farm:FindFirstChild("Plants") or farm:FindFirstChild("Crops") or farm:FindFirstChild("Planted")
        if pf then return pf:GetChildren() end
        local t = {}
        for _, ch in ipairs(farm:GetDescendants()) do
            if ch:IsA("Model") or ch:IsA("BasePart") then
                if ch:FindFirstChild("PlantData") or ch:FindFirstChild("Growth") or ch:GetAttribute("IsPlant") then
                    table.insert(t, ch)
                end
            end
        end
        return t
    end

    function Utils.GetFruits(plant)
        if not plant then return {} end
        local ff = plant:FindFirstChild("Fruits") or plant:FindFirstChild("Harvestable")
        if ff then return ff:GetChildren() end
        local t = {}
        for _, ch in ipairs(plant:GetChildren()) do
            if ch:GetAttribute("IsFruit") or ch:GetAttribute("Harvestable") or ch.Name:lower():find("fruit") then
                table.insert(t, ch)
            end
        end
        return t
    end

    function Utils.GetInventory()
        local items = {}
        local bp = LP:FindFirstChild("Backpack")
        if bp then for _, i in ipairs(bp:GetChildren()) do table.insert(items, i) end end
        return items
    end

    function Utils.FindRemote(name)
        if remoteCache[name] and remoteCache[name].Parent then
            return remoteCache[name]
        end
        local lname = tostring(name):lower()
        local function search(cont)
            local scanned = 0
            for _, ch in ipairs(cont:GetDescendants()) do
                scanned = scanned + 1
                if scanned > 3000 then break end
                if (ch:IsA("RemoteEvent") or ch:IsA("RemoteFunction")) and ch.Name:lower():find(lname, 1, true) then
                    remoteCache[name] = ch
                    return ch
                end
            end
        end
        return search(ReplicatedStorage) or search(workspace)
    end

    function Utils.FireRemote(name, ...)
        local r = Utils.FindRemote(name)
        if not r then Utils.Log("Remote", "Not found: " .. name); return false end
        if not r:IsA("RemoteEvent") then return false end
        local args = {...}
        local ok, err = pcall(function() r:FireServer(unpack(args)) end)
        if not ok then Utils.Log("Remote", name .. " err: " .. tostring(err)) end
        return ok
    end

    function Utils.InvokeRemote(name, ...)
        local r = Utils.FindRemote(name)
        if not r or not r:IsA("RemoteFunction") then return nil end
        local args = {...}
        local ok, res = pcall(function() return r:InvokeServer(unpack(args)) end)
        return ok and res or nil
    end

    function Utils.IsInList(item, list)
        if not list then return false end
        if list[item] ~= nil then return true end
        for _, v in ipairs(list) do if v == item then return true end end
        return false
    end

    function Utils.GetTierOrder()
        return { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mythic = 6 }
    end

    function Utils.WaitForReady(timeout)
        timeout = timeout or 30
        for i = 1, math.ceil(timeout / 0.5) do
            local c = LP.Character
            if c then
                local h = c:FindFirstChild("HumanoidRootPart")
                local hu = c:FindFirstChildOfClass("Humanoid")
                if h and hu and hu.Health > 0 then
                    LP:WaitForChild("PlayerGui", timeout)
                    GAG.Alive = true
                    return true
                end
            end
            task.wait(0.5)
        end
        return false
    end

    function Utils.GetMoney()
        local ls = LP:FindFirstChild("leaderstats")
        if ls then
            local c = ls:FindFirstChild("Cash") or ls:FindFirstChild("Sheckles") or ls:FindFirstChild("Money")
            if c then return c.Value end
        end
        return 0
    end

    function Utils.GetFruitCount()
        local bp = LP:FindFirstChild("Backpack")
        if not bp then return 0 end
        local n = 0
        for _, i in ipairs(bp:GetChildren()) do
            if i:IsA("Tool") and (i:GetAttribute("IsFruit") or i.Name:lower():find("fruit")) then
                n = n + 1
            end
        end
        return n
    end
end

---------------------------------------------------------------------------
-- HARVEST MODULE
---------------------------------------------------------------------------
local Harvest = {}
do
    local sellTimer = 0

    local function HasMutation(plant)
        for attr, val in pairs(plant:GetAttributes()) do
            if attr:lower():find("mutation") and val then return true end
        end
        return false
    end

    local function ShouldWaitMut(plant)
        local name = plant:GetAttribute("PlantName") or plant.Name
        local lk = GAG.Config._LK
        if not lk.WaitForMut[name] then return false end
        local fruits = Utils.GetFruits(plant)
        for _, f in ipairs(fruits) do
            if not f:GetAttribute("Mutated") and not f:GetAttribute("HasMutation") then
                return true
            end
        end
        return false
    end

    function Harvest.HarvestPlant(plant)
        local name = plant:GetAttribute("PlantName") or plant.Name
        if not Config.ShouldHarvest(name) then return false end
        if ShouldWaitMut(plant) then return false end

        local pivot
        if plant:IsA("Model") then
            pivot = plant:GetPivot().Position
        elseif plant:IsA("BasePart") then
            pivot = plant.Position
        end
        if pivot then
            if GAG.Config["Misc"]["Teleport"] then
                Utils.TeleportTo(pivot + Vector3.new(0, 3, 0))
            else
                Utils.WalkTo(pivot)
            end
        end
        task.wait(0.3)

        local prompt = plant:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            pcall(function()
                prompt:InputHoldBegin()
                task.wait(prompt.HoldDuration or 0.2)
                prompt:InputHoldEnd()
            end)
        else
            Utils.FireRemote("Harvest", plant)
        end

        GAG.Stats.Harvested = GAG.Stats.Harvested + 1
        task.wait(0.2)
        return true
    end

    function Harvest.Sell()
        Utils.Log("HARVEST", "Selling fruits...")
        local sell = workspace:FindFirstChild("SellArea") or workspace:FindFirstChild("SellNPC")
            or workspace:FindFirstChild("Sell")
        if sell then
            local pos
            if sell:IsA("Model") then
                pos = sell:GetPivot().Position
            elseif sell:IsA("BasePart") then
                pos = sell.Position
            end
            if pos then Utils.TeleportTo(pos) end
        end
        task.wait(0.5)
        Utils.FireRemote("Sell")
        local count = Utils.GetFruitCount()
        GAG.Stats.Sold = GAG.Stats.Sold + count
        sellTimer = 0
    end

    function Harvest.Start()
        Utils.Log("HARVEST", "Loop started")
        while GAG.Alive do
            pcall(function()
                local plants = Utils.GetPlants()
                table.sort(plants, function(a, b)
                    local am = a:GetAttribute("Mutated") or a:GetAttribute("HasMutation")
                    local bm = b:GetAttribute("Mutated") or b:GetAttribute("HasMutation")
                    if am and not bm then return true end
                    return false
                end)

                for _, plant in ipairs(plants) do
                    if not GAG.Alive then break end
                    local fruits = Utils.GetFruits(plant)
                    if #fruits > 0 then
                        Harvest.HarvestPlant(plant)
                    end
                    if Utils.GetFruitCount() >= (GAG.Config["Sell At"]) then
                        Harvest.Sell()
                    end
                end

                sellTimer = sellTimer + 2
                local sellEvery = GAG.Config["Sell Every"]
                if sellEvery > 0 and sellTimer >= sellEvery and Utils.GetFruitCount() > 0 then
                    Harvest.Sell()
                end
            end)
            Utils.Sleep(2)
        end
    end
end

---------------------------------------------------------------------------
-- PLANT MODULE
---------------------------------------------------------------------------
local Plant = {}
do
    local SEED_TIERS = Utils.GetTierOrder()
    local LAYOUT = { compact = { x = 2.5, z = 2.5 }, spread = { x = 4.5, z = 4.5 } }

    local function TierVal(name)
        for t, v in pairs(SEED_TIERS) do
            if name:lower():find(t:lower()) then return v end
        end
        return 1
    end

    local function IsProtected(plant)
        local name = plant:GetAttribute("SeedName") or plant.Name
        local lk = GAG.Config._LK
        for attr, val in pairs(plant:GetAttributes()) do
            if attr:lower():find("mutation") and val then return true end
        end
        local sz = plant:GetAttribute("Size") or plant:GetAttribute("PlantSize")
        if sz and tostring(sz):lower() == "mega" then return true end
        if lk.NeverShovel[name] then return true end
        if lk.NeverSellFruit[name] then return true end
        local plan = GAG.Config["Plant Plan"]
        if plan then
            for _, e in ipairs(plan) do
                local n = type(e) == "table" and e.Name or e
                if n == name then return true end
            end
        end
        if TierVal(name) >= 5 then return true end -- Legendary+
        return false
    end

    local function HasMutation(plant)
        for a, v in pairs(plant:GetAttributes()) do
            if a:lower():find("mutation") and v then return true end
        end
        return false
    end

    function Plant.GetPlotPositions()
        local farm = Utils.GetFarm()
        if not farm then return {} end
        local primary = (farm:IsA("BasePart") and farm) or (farm:IsA("Model") and farm.PrimaryPart) or farm:FindFirstChildWhichIsA("BasePart", true)
        if not primary then return {} end
        local fp, fs = primary.Position, primary.Size
        local lo = LAYOUT[GAG.Config["Layout"]] or LAYOUT.compact
        local ex = GAG.Stats.Expanded or 0
        local gs = math.floor(3 + ex * 0.5)
        local pos = {}
        for x = 0, gs - 1 do
            for z = 0, gs - 1 do
                table.insert(pos, fp + Vector3.new(x * lo.x, 0, z * lo.z))
            end
        end
        return pos
    end

    function Plant.GetEmptyPositions()
        local all = Plant.GetPlotPositions()
        local plants = Utils.GetPlants()
        local occ = {}
        for _, p in ipairs(plants) do
            local pp = p:IsA("Model") and p:GetPivot().Position or (p:IsA("BasePart") and p.Position)
            if pp then
                for _, pos in ipairs(all) do
                    if (pos - pp).Magnitude < 1.5 then
                        occ[pos.X .. "," .. pos.Z] = true
                    end
                end
            end
        end
        local empty = {}
        for _, pos in ipairs(all) do
            if not occ[pos.X .. "," .. pos.Z] then table.insert(empty, pos) end
        end
        return empty
    end

    function Plant.PlantSeed(name, pos)
        local bp = LP:FindFirstChild("Backpack")
        local ch = LP.Character
        if not bp or not ch then return false end
        local tool
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and t.Name == name then tool = t; break end
        end
        if not tool then
            for _, t in ipairs(ch:GetChildren()) do
                if t:IsA("Tool") and t.Name == name then tool = t; break end
            end
        end
        if not tool then return false end
        if tool.Parent == bp then
            local hum = ch:FindFirstChildOfClass("Humanoid") or ch:WaitForChild("Humanoid", 5)
            if not hum then return false end
            pcall(function() hum:EquipTool(tool) end)
            task.wait(0.2)
        end
        Utils.TeleportTo(pos)
        task.wait(0.15)
        if not Utils.FireRemote("PlantSeed", name, pos) then
            Utils.FireRemote("Plant", name, pos)
        end
        GAG.Stats.Planted = GAG.Stats.Planted + 1
        task.wait(0.3)
        return true
    end

    function Plant.ShovelPlant(plant)
        local name = plant:GetAttribute("SeedName") or plant.Name
        if IsProtected(plant) then return false end
        if not Config.ShouldShovel(name) then return false end
        if not Utils.FireRemote("ShovelPlant", plant) then
            Utils.FireRemote("Shovel", plant)
        end
        GAG.Stats.Shoveled = GAG.Stats.Shoveled + 1
        task.wait(0.3)
        return true
    end

    function Plant.ExpandPlot()
        if not GAG.Config["Auto Expand Plot"] then return false end
        local cash = Utils.GetMoney()
        if cash < GAG.Config["Expand If Over"] then return false end
        if GAG.Stats.Expanded >= (GAG.Config["Max Expansions"]) then return false end
        if not Utils.FireRemote("ExpandPlot") then
            Utils.FireRemote("BuyExpansion")
        end
        GAG.Stats.Expanded = GAG.Stats.Expanded + 1
        task.wait(0.5)
        return true
    end

    function Plant.GetNextSeed()
        local bp = LP:FindFirstChild("Backpack")
        if not bp then return nil end
        local counts = {}
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then counts[t.Name] = (counts[t.Name] or 0) + 1 end
        end
        local plan = GAG.Config["Plant Plan"]
        if plan and #plan > 0 then
            local plants = Utils.GetPlants()
            local pCounts = {}
            for _, p in ipairs(plants) do
                local n = p:GetAttribute("SeedName") or p.Name
                pCounts[n] = (pCounts[n] or 0) + 1
            end
            for _, e in ipairs(plan) do
                local n = type(e) == "table" and e.Name or e
                local tgt = type(e) == "table" and (e.Count or e[2]) or 1
                if (pCounts[n] or 0) < tgt and (counts[n] or 0) > 0 then return n end
            end
        end
        local only = GAG.Config["Only Plant"]
        if only and #only > 0 then
            for _, n in ipairs(only) do
                if (counts[n] or 0) > 0 then return n end
            end
            return nil
        end
        local minTier = SEED_TIERS[GAG.Config["Minimum Seed"]] or 1
        local best, bestT = nil, math.huge
        for n, c in pairs(counts) do
            if c > 0 then
                local tv = TierVal(n)
                if tv >= minTier and tv < bestT then bestT = tv; best = n end
            end
        end
        return best
    end

    function Plant.ReplacePlants()
        if not GAG.Config["Auto Replace Plants"] then return false end
        local empty = Plant.GetEmptyPositions()
        if #empty > 0 then return false end
        local plants = Utils.GetPlants()
        local cheapest, cheapTier = nil, math.huge
        for _, p in ipairs(plants) do
            if not IsProtected(p) then
                local n = p:GetAttribute("SeedName") or p.Name
                local tv = TierVal(n)
                if tv < cheapTier then cheapTier = tv; cheapest = p end
            end
        end
        if not cheapest then return false end
        local nextSeed = Plant.GetNextSeed()
        if not nextSeed or TierVal(nextSeed) <= cheapTier then return false end
        local pos = cheapest:IsA("Model") and cheapest:GetPivot().Position or cheapest.Position
        Plant.ShovelPlant(cheapest)
        task.wait(0.2)
        Plant.PlantSeed(nextSeed, pos)
        GAG.Stats.Replaced = GAG.Stats.Replaced + 1
        return true
    end

    function Plant.RespectLimit()
        local lim = GAG.Config["Plant Limit"]
        if not lim or lim <= 0 then return end
        local plants = Utils.GetPlants()
        if #plants <= lim then return end
        local cands = {}
        for _, p in ipairs(plants) do
            if not IsProtected(p) then
                local n = p:GetAttribute("SeedName") or p.Name
                table.insert(cands, { plant = p, tier = TierVal(n) })
            end
        end
        table.sort(cands, function(a, b) return a.tier < b.tier end)
        for i = 1, math.min(#plants - lim, #cands) do
            Plant.ShovelPlant(cands[i].plant)
            task.wait(0.2)
        end
    end

    function Plant.Start()
        Utils.Log("PLANT", "Loop started")
        while GAG.Alive do
            pcall(function()
                if GAG.Config["Auto Plant"] then
                    local empty = Plant.GetEmptyPositions()
                    if #empty > 0 then
                        local seed = Plant.GetNextSeed()
                        if seed then
                            for _, pos in ipairs(empty) do
                                if not GAG.Config["Auto Plant"] then break end
                                Plant.PlantSeed(seed, pos)
                                task.wait(0.5)
                                seed = Plant.GetNextSeed()
                                if not seed then break end
                            end
                        end
                    else
                        Plant.ReplacePlants()
                    end
                    Plant.RespectLimit()
                    Plant.ExpandPlot()
                end
            end)
            Utils.Sleep(2)
        end
    end
end

---------------------------------------------------------------------------
-- BUY SEEDS MODULE
---------------------------------------------------------------------------
local BuySeeds = {}
do
    function BuySeeds.GetShopStock()
        local items = {}
        pcall(function()
            local gui = LP:FindFirstChild("PlayerGui")
            if gui then
                local shop = gui:FindFirstChild("SeedShop", true) or gui:FindFirstChild("ShopGui", true)
                if shop then
                    for _, ch in ipairs(shop:GetDescendants()) do
                        local n = ch:GetAttribute("ItemName") or ch:GetAttribute("SeedName")
                        if n then
                            items[n] = {
                                price = ch:GetAttribute("Price") or 0,
                                stock = ch:GetAttribute("Stock") or -1,
                            }
                        end
                    end
                end
            end
        end)
        return items
    end

    function BuySeeds.BuySeed(name, amount)
        amount = amount or 1
        if not Config.ShouldBuySeed(name) then return false end
        local cash = Utils.GetMoney()
        if cash < GAG.Config["Keep Cash"] then return false end
        if not Utils.FireRemote("BuySeed", name, amount) then
            Utils.FireRemote("Buy", name, amount)
        end
        GAG.Stats.SeedsBought = GAG.Stats.SeedsBought + amount
        Utils.Log("BUY", amount .. "x " .. name)
        return true
    end

    function BuySeeds.ProcessConfig()
        local cfg = GAG.Config["Buy Seeds"]
        if type(cfg) ~= "table" then return end
        local bp = LP:FindFirstChild("Backpack")
        if not bp then return end
        local counts = {}
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then counts[t.Name] = (counts[t.Name] or 0) + 1 end
        end
        for name, target in pairs(cfg) do
            if type(target) == "number" and target > 0 then
                local have = counts[name] or 0
                if have < target then
                    BuySeeds.BuySeed(name, target - have)
                    task.wait(0.5)
                end
            end
        end
    end

    function BuySeeds.Start()
        Utils.Log("BUYSEEDS", "Loop started")
        while GAG.Alive do
            pcall(function() BuySeeds.ProcessConfig() end)
            Utils.Sleep(15)
        end
    end
end

---------------------------------------------------------------------------
-- PETS MODULE
---------------------------------------------------------------------------
local Pets = {}
do
    function Pets.GetOwned()
        local owned = {}
        local data = LP:FindFirstChild("PetData") or LP:FindFirstChild("Pets")
        if data then
            for _, ch in ipairs(data:GetChildren()) do
                owned[ch.Name] = (owned[ch.Name] or 0) + 1
            end
        end
        return owned
    end

    function Pets.Buy(name)
        if not Utils.FireRemote("BuyPet", name) then
            Utils.FireRemote("PurchasePet", name)
        end
        GAG.Stats.PetsBought = GAG.Stats.PetsBought + 1
        Utils.Log("PET", "Bought " .. name)
    end

    function Pets.Equip(name)
        Utils.FireRemote("EquipPet", name)
        Utils.Log("PET", "Equipped " .. name)
    end

    function Pets.BuySlot()
        if not GAG.Config["Pets"]["Auto Buy Slots"] then return end
        Utils.FireRemote("BuyPetSlot")
        Utils.Log("PET", "Bought pet slot")
    end

    function Pets.Start()
        Utils.Log("PETS", "Loop started")
        while GAG.Alive do
            pcall(function()
                local buyCfg = GAG.Config["Pets"]["Buy"]
                local owned = Pets.GetOwned()
                for k, v in pairs(buyCfg) do
                    local name, limit
                    if type(k) == "number" then
                        name = v; limit = math.huge
                    else
                        name = k; limit = v
                    end
                    if (owned[name] or 0) < limit then
                        Pets.Buy(name)
                        task.wait(0.5)
                    end
                end

                local eqCfg = GAG.Config["Pets"]["Equip"]
                for name, count in pairs(eqCfg) do
                    for i = 1, count do
                        Pets.Equip(name)
                        task.wait(0.3)
                    end
                end
            end)
            Utils.Sleep(10)
        end
    end
end

---------------------------------------------------------------------------
-- GEAR MODULE
---------------------------------------------------------------------------
local Gear = {}
do
    function Gear.PlaceSprinklers()
        local cfg = GAG.Config["Gear"]["Place Sprinklers"]
        if not cfg then return end
        local farm = Utils.GetFarm()
        if not farm then return end
        local primary = (farm:IsA("BasePart") and farm) or (farm:IsA("Model") and farm.PrimaryPart) or farm:FindFirstChildWhichIsA("BasePart", true)
        if not primary then return end
        local fp = primary.Position

        for name, count in pairs(cfg) do
            if name == "best" then
                local best = GAG.Config["Gear"]["Best Sprinkler Up To"] or "Rare Sprinkler"
                Utils.Log("GEAR", "Placing " .. count .. " best sprinklers (up to " .. best .. ")")
                for i = 1, count do
                    local angle = (i - 1) * (2 * math.pi / count)
                    local r = 10
                    local pos = fp + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
                    Utils.FireRemote("PlaceSprinkler", best, pos)
                    task.wait(0.3)
                end
            else
                for i = 1, count do
                    local angle = (i - 1) * (2 * math.pi / count)
                    local pos = fp + Vector3.new(math.cos(angle) * 8, 0, math.sin(angle) * 8)
                    Utils.FireRemote("PlaceSprinkler", name, pos)
                    task.wait(0.3)
                end
            end
        end
    end

    function Gear.ProcessBuy()
        local buyList = GAG.Config["Gear"]["Buy Gear"]
        if not buyList then return end
        local cash = Utils.GetMoney()
        local keep = GAG.Config["Gear"]["Keep Cash"] or 15000
        for _, name in ipairs(buyList) do
            if cash > keep then
                Utils.FireRemote("BuyGear", name)
                GAG.Stats.GearBought = GAG.Stats.GearBought + 1
                Utils.Log("GEAR", "Bought " .. name)
                task.wait(0.5)
            end
        end
    end

    function Gear.Start()
        Utils.Log("GEAR", "Loop started")
        if GAG.Config["Gear"]["Auto Buy"] then
            pcall(Gear.PlaceSprinklers)
        end
        while GAG.Alive do
            pcall(function()
                if GAG.Config["Gear"]["Auto Buy"] then
                    Gear.ProcessBuy()
                end
            end)
            Utils.Sleep(10)
        end
    end
end

---------------------------------------------------------------------------
-- MAIL MODULE
---------------------------------------------------------------------------
local Mail = {}
do
    local FRUITS = {
        Apple = true, Banana = true, Blueberry = true, Cherry = true, Coconut = true,
        ["Dragon Fruit"] = true, Grape = true, Lemon = true, Mango = true, Orange = true,
        Peach = true, Pear = true, Pineapple = true, Raspberry = true, Strawberry = true,
        Watermelon = true, Kiwi = true, Plum = true, Avocado = true, Starfruit = true,
    }

    function Mail.Claim()
        if not Utils.FireRemote("ClaimMail") then
            Utils.FireRemote("MailClaim")
        end
        GAG.Stats.MailSent = GAG.Stats.MailSent -- keep
        Utils.Log("MAIL", "Claimed mail")
    end

    function Mail.SendItem(name, count)
        if FRUITS[name] then return false end
        local target = GAG.Config["Mail"]["Send To"]
        if not target or target == "" then return false end
        if not Utils.FireRemote("SendMail", target, name, count) then
            Utils.FireRemote("MailSend", target, name, count)
        end
        GAG.Stats.MailSent = GAG.Stats.MailSent + count
        Utils.Log("MAIL", "Sent " .. count .. "x " .. name .. " to " .. target)
        return true
    end

    function Mail.ProcessSend()
        local sendCfg = GAG.Config["Mail"]["Send"]
        if not sendCfg or #sendCfg == 0 then return end
        local target = GAG.Config["Mail"]["Send To"]
        if not target or target == "" then return end

        local bp = LP:FindFirstChild("Backpack")
        if not bp then return end
        local counts = {}
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then counts[t.Name] = (counts[t.Name] or 0) + 1 end
        end

        for _, entry in ipairs(sendCfg) do
            local itemName, reqCount
            if type(entry) == "string" then
                itemName = entry; reqCount = counts[entry] or 0
            elseif type(entry) == "table" then
                itemName = entry.Item or entry[1]
                reqCount = entry.Count or entry[2] or 0
            end
            if itemName and not FRUITS[itemName] then
                local have = counts[itemName] or 0
                local send = reqCount > 0 and math.min(have, reqCount) or have
                if send > 0 then
                    Mail.SendItem(itemName, send)
                    task.wait(1)
                end
            end
        end
    end

    function Mail.Start()
        Utils.Log("MAIL", "Loop started")
        local lastSend = 0
        while GAG.Alive do
            pcall(function()
                if GAG.Config["Mail"]["Auto Claim"] then Mail.Claim() end
                local sendTo = GAG.Config["Mail"]["Send To"]
                if sendTo and sendTo ~= "" then
                    local delay = (GAG.Config["Mail"]["Send Every"] or 0) * 60
                    if delay <= 0 then delay = 45 end
                    if tick() - lastSend >= delay then
                        Mail.ProcessSend()
                        lastSend = tick()
                    end
                end
            end)
            Utils.Sleep(10)
        end
    end
end

---------------------------------------------------------------------------
-- MISC MODULE
---------------------------------------------------------------------------
local Misc = {}
do
    local gardenPos = nil

    function Misc.ApplyPerformance()
        local perf = GAG.Config["Performance"]
        if perf["Low Graphics"] then
            pcall(function()
                Lighting.GlobalShadows = false
                Lighting.FogEnd = 100
                for _, e in ipairs(Lighting:GetDescendants()) do
                    if e:IsA("PostEffect") then e.Enabled = false end
                end
            end)
        end
        if perf["Remove Other Gardens"] then
            pcall(function()
                local farms = workspace:FindFirstChild("Farms") or workspace:FindFirstChild("Plots")
                if farms then
                    for _, plot in ipairs(farms:GetChildren()) do
                        local own = plot.Name == LP.Name
                        local owner = plot:FindFirstChild("Owner") or plot:FindFirstChild("OwnerValue")
                        if owner then
                            if owner:IsA("StringValue") and owner.Value == LP.Name then own = true end
                            if owner:IsA("ObjectValue") and owner.Value == LP then own = true end
                        end
                        if not own then
                            for _, obj in ipairs(plot:GetDescendants()) do
                                if obj:IsA("BasePart") then
                                    obj.LocalTransparencyModifier = 1
                                    obj.CanCollide = false
                                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                                    obj.Transparency = 1
                                elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                                    obj.Enabled = false
                                end
                            end
                        end
                    end
                end
            end)
        end
        if perf["Hide Players"] then
            pcall(function()
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character then
                        for _, ch in ipairs(p.Character:GetDescendants()) do
                            if ch:IsA("BasePart") then ch.Transparency = 1
                            elseif ch:IsA("Decal") then ch.Transparency = 1 end
                        end
                    end
                end
            end)
        end
    end

    function Misc.CollectEventSeeds()
        if not GAG.Config["Event Seeds"]["Auto Claim"] then return end
        local scanned = 0
        for _, obj in ipairs(workspace:GetDescendants()) do
            scanned = scanned + 1
            if scanned > 1000 then break end
            if obj:IsA("BasePart") and (obj:GetAttribute("IsEventSeed") or obj.Name:lower():find("eventseed")) then
                Utils.TeleportTo(obj.Position)
                task.wait(0.3)
            end
        end
    end

    function Misc.AutoReturn()
        if not GAG.Config["Misc"]["Auto Return To Garden"] then return end
        if not gardenPos then
            local farm = Utils.GetFarm()
            if farm then
                local p = (farm:IsA("BasePart") and farm) or (farm:IsA("Model") and farm.PrimaryPart) or farm:FindFirstChildWhichIsA("BasePart", true)
                if p then gardenPos = p.Position end
            end
        end
        if gardenPos and HRP and (HRP.Position - gardenPos).Magnitude > 200 then
            Utils.Log("MISC", "Returning to garden")
            Utils.TeleportTo(gardenPos)
        end
    end

    function Misc.ApplyWalkSpeed()
        local ws = GAG.Config["Misc"]["Walk Speed"]
        if ws and ws > 0 then
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = ws end
        end
    end

    function Misc.DailyDeal()
        if not GAG.Config["Misc"]["Auto Daily Deal"] then return end
        Utils.FireRemote("DailyDeal")
        Utils.Log("MISC", "Daily deal triggered")
    end

    function Misc.Start()
        Utils.Log("MISC", "Loop started")
        Misc.ApplyPerformance()
        Misc.DailyDeal()
        while GAG.Alive do
            pcall(function()
                Misc.CollectEventSeeds()
                Misc.AutoReturn()
                Misc.ApplyWalkSpeed()
            end)
            Utils.Sleep(5)
        end
    end
end

---------------------------------------------------------------------------
-- STATS OVERLAY MODULE
---------------------------------------------------------------------------
local StatsUI = {}
do
    local overlay, consoleFrame
    local labels = {}
    local consoleLines = {}
    local visible = GAG.Config["Misc"]["Show Stats"] ~= false
    local consoleVisible = GAG.Config["Misc"]["Show Console"] == true
    local startTime = 0

    local TAG_COLORS = {
        BUY = Color3.fromRGB(100, 200, 255), PLANT = Color3.fromRGB(100, 255, 130),
        SHOVEL = Color3.fromRGB(255, 180, 80), SELL = Color3.fromRGB(255, 230, 80),
        MAIL = Color3.fromRGB(200, 130, 255), PET = Color3.fromRGB(255, 150, 200),
        GEAR = Color3.fromRGB(150, 200, 255), ERROR = Color3.fromRGB(255, 80, 80),
        INFO = Color3.fromRGB(200, 200, 200),
    }

    local function fmtTime(s)
        s = math.floor(s)
        local h = math.floor(s / 3600)
        local m = math.floor((s % 3600) / 60)
        return h > 0 and string.format("%dh %02dm", h, m) or string.format("%dm %02ds", m, s % 60)
    end

    local function fmtNum(n)
        local formatted = tostring(math.floor(tonumber(n) or 0))
        local changed
        repeat
            formatted, changed = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        until changed == 0
        return formatted
    end

    local function mkLabel(parent, text, xAlign, color, size)
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Font = Enum.Font.RobotoMono
        l.TextColor3 = color or Color3.fromRGB(220, 220, 220)
        l.TextSize = size or 13
        l.TextXAlignment = xAlign or Enum.TextXAlignment.Left
        l.Size = UDim2.new(1, 0, 0, 18)
        l.Text = text or ""
        l.Parent = parent
        return l
    end

    function StatsUI.Create()
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
        panel.Size = UDim2.new(0, 250, 0, 330)
        panel.Position = UDim2.new(1, -262, 0, 12)
        panel.Parent = overlay
        panel.Visible = visible
        Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)
        local s = Instance.new("UIStroke", panel); s.Color = Color3.fromRGB(50, 50, 60); s.Thickness = 1

        local title = mkLabel(panel, "GAG AUTOFARM", nil, Color3.fromRGB(100, 220, 140), 15)
        title.Position = UDim2.new(0, 8, 0, 6)

        local div = Instance.new("Frame")
        div.BackgroundColor3 = Color3.fromRGB(50, 50, 60); div.BorderSizePixel = 0
        div.Size = UDim2.new(1, -16, 0, 1); div.Position = UDim2.new(0, 8, 0, 32); div.Parent = panel

        local content = Instance.new("Frame")
        content.Name = "C"; content.BackgroundTransparency = 1
        content.Size = UDim2.new(1, -16, 1, -70); content.Position = UDim2.new(0, 8, 0, 38); content.Parent = panel
        local cl = Instance.new("UIListLayout", content); cl.Padding = UDim.new(0, 1)

        local function statRow(name, text)
            local row = Instance.new("Frame"); row.BackgroundTransparency = 1
            row.Size = UDim2.new(1, 0, 0, 18); row.Parent = content
            local lbl = mkLabel(row, text, nil, Color3.fromRGB(170, 170, 170))
            lbl.Size = UDim2.new(0.55, 0, 1, 0)
            local val = mkLabel(row, "0", Enum.TextXAlignment.Right, Color3.fromRGB(255, 255, 255))
            val.Size = UDim2.new(0.45, 0, 1, 0); val.Position = UDim2.new(0.55, 0, 0, 0)
            labels[name] = val
        end

        statRow("Harvested", "Harvested")
        statRow("Sold", "Sold")
        statRow("Planted", "Planted")
        statRow("Shoveled", "Shoveled")
        statRow("Expanded", "Expansions")
        statRow("SeedsBought", "Seeds Bought")
        statRow("GearBought", "Gear Bought")
        statRow("PetsBought", "Pets Bought")
        statRow("Mailed", "Items Mailed")

        local sep = Instance.new("Frame"); sep.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        sep.BorderSizePixel = 0; sep.Size = UDim2.new(1, 0, 0, 1); sep.Parent = content

        statRow("Runtime", "Runtime")
        statRow("Money", "Money")
        statRow("Inventory", "Inventory")

        local hint = mkLabel(panel, "Tap STATS / CONSOLE", Enum.TextXAlignment.Center, Color3.fromRGB(80, 80, 90), 10)
        hint.Position = UDim2.new(0, 0, 1, -18)

        -- Console
        consoleFrame = Instance.new("Frame")
        consoleFrame.Name = "Console"; consoleFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        consoleFrame.BackgroundTransparency = 0.1; consoleFrame.BorderSizePixel = 0
        consoleFrame.Size = UDim2.new(1, -150, 0, 210)
        consoleFrame.Position = UDim2.new(0, 12, 0, 12)
        consoleFrame.Parent = overlay
        Instance.new("UICorner", consoleFrame).CornerRadius = UDim.new(0, 8)
        local cs = Instance.new("UIStroke", consoleFrame); cs.Color = Color3.fromRGB(45, 45, 55); cs.Thickness = 1

        mkLabel(consoleFrame, "CONSOLE FEED", nil, Color3.fromRGB(255, 200, 80), 13).Position = UDim2.new(0, 8, 0, 6)

        local scrolling = Instance.new("ScrollingFrame")
        scrolling.Name = "Scroll"; scrolling.BackgroundTransparency = 1; scrolling.BorderSizePixel = 0
        scrolling.ScrollBarThickness = 4; scrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scrolling.Size = UDim2.new(1, -16, 1, -38); scrolling.Position = UDim2.new(0, 8, 0, 34)
        scrolling.Parent = consoleFrame
        Instance.new("UIListLayout", scrolling).Padding = UDim.new(0, 1)
        consoleFrame.Visible = consoleVisible
        if consoleVisible then panel.Visible = false end

        local controls = Instance.new("Frame")
        controls.Name = "MobileControls"
        controls.BackgroundTransparency = 1
        controls.Size = UDim2.new(0, 120, 0, 96)
        controls.Position = UDim2.new(0, 12, 1, -110)
        controls.Parent = overlay

        local function makeButton(text, y, color)
            local btn = Instance.new("TextButton")
            btn.Name = text .. "Button"
            btn.BackgroundColor3 = color
            btn.BackgroundTransparency = 0.08
            btn.BorderSizePixel = 0
            btn.Size = UDim2.new(0, 110, 0, 44)
            btn.Position = UDim2.new(0, 0, 0, y)
            btn.Font = Enum.Font.RobotoMono
            btn.Text = text
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextSize = 14
            btn.AutoButtonColor = true
            btn.Parent = controls
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
            local stroke = Instance.new("UIStroke", btn)
            stroke.Color = Color3.fromRGB(255, 255, 255)
            stroke.Transparency = 0.65
            stroke.Thickness = 1
            return btn
        end

        makeButton("STATS", 0, Color3.fromRGB(45, 160, 95)).MouseButton1Click:Connect(function()
            StatsUI.Toggle()
        end)

        makeButton("CONSOLE", 50, Color3.fromRGB(165, 120, 35)).MouseButton1Click:Connect(function()
            StatsUI.ToggleConsole()
        end)

        local playerGui = LP:FindFirstChild("PlayerGui") or LP:WaitForChild("PlayerGui", 10)
        if not playerGui then return end
        overlay.Parent = playerGui
    end

    function StatsUI.ConsoleLog(tag, msg)
        if not consoleFrame then return end
        local scroll = consoleFrame:FindFirstChild("Scroll", true)
        if not scroll then return end
        local line = Instance.new("Frame"); line.BackgroundTransparency = 1
        line.Size = UDim2.new(1, 0, 0, 18); line.Parent = scroll

        local ts = Instance.new("TextLabel"); ts.BackgroundTransparency = 1
        ts.Font = Enum.Font.RobotoMono; ts.TextColor3 = Color3.fromRGB(100, 100, 100)
        ts.TextSize = 12; ts.TextXAlignment = Enum.TextXAlignment.Left
        ts.Size = UDim2.new(0, 62, 1, 0); ts.Text = os.date("%H:%M:%S"); ts.Parent = line

        local tl = Instance.new("TextLabel"); tl.BackgroundTransparency = 1
        tl.Font = Enum.Font.RobotoMono; tl.TextColor3 = TAG_COLORS[tag] or TAG_COLORS.INFO
        tl.TextSize = 12; tl.TextXAlignment = Enum.TextXAlignment.Left
        tl.Size = UDim2.new(0, 50, 1, 0); tl.Position = UDim2.new(0, 64, 0, 0)
        tl.Text = "[" .. tag .. "]"; tl.Parent = line

        local ml = Instance.new("TextLabel"); ml.BackgroundTransparency = 1
        ml.Font = Enum.Font.RobotoMono; ml.TextColor3 = Color3.fromRGB(200, 200, 200)
        ml.TextSize = 12; ml.TextXAlignment = Enum.TextXAlignment.Left
        ml.TextTruncate = Enum.TextTruncate.AtEnd
        ml.Size = UDim2.new(1, -118, 1, 0); ml.Position = UDim2.new(0, 118, 0, 0)
        ml.Text = tostring(msg); ml.Parent = line

        table.insert(consoleLines, line)
        while #consoleLines > 20 do
            local old = table.remove(consoleLines, 1)
            if old and old.Parent then old:Destroy() end
        end
        pcall(function()
            scroll.CanvasPosition = Vector2.new(0, math.max(0, scroll.AbsoluteCanvasSize.Y - scroll.AbsoluteWindowSize.Y))
        end)
    end

    function StatsUI.Update()
        if not overlay or not visible then return end
        local st = GAG.Stats
        if labels.Harvested then labels.Harvested.Text = fmtNum(st.Harvested) end
        if labels.Sold then labels.Sold.Text = fmtNum(st.Sold) end
        if labels.Planted then labels.Planted.Text = fmtNum(st.Planted) end
        if labels.Shoveled then labels.Shoveled.Text = fmtNum(st.Shoveled) end
        if labels.Expanded then labels.Expanded.Text = fmtNum(st.Expanded) end
        if labels.SeedsBought then labels.SeedsBought.Text = fmtNum(st.SeedsBought) end
        if labels.GearBought then labels.GearBought.Text = fmtNum(st.GearBought) end
        if labels.PetsBought then labels.PetsBought.Text = fmtNum(st.PetsBought) end
        if labels.Mailed then labels.Mailed.Text = fmtNum(st.MailSent) end
        if labels.Runtime then labels.Runtime.Text = fmtTime(os.clock() - startTime) end
        if labels.Money then labels.Money.Text = "$" .. fmtNum(Utils.GetMoney()) end
        if labels.Inventory then
            local bp = LP:FindFirstChild("Backpack")
            local cnt = bp and #bp:GetChildren() or 0
            labels.Inventory.Text = cnt .. " / 60"
            labels.Inventory.TextColor3 = cnt >= 60 and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(255, 255, 255)
        end
    end

    function StatsUI.Toggle()
        visible = not visible
        if overlay then
            local p = overlay:FindFirstChild("Panel")
            if p then p.Visible = visible and not consoleVisible end
        end
    end

    function StatsUI.ToggleConsole()
        consoleVisible = not consoleVisible
        if consoleFrame then
            consoleFrame.Visible = consoleVisible
        end
        if overlay then
            local panel = overlay:FindFirstChild("Panel")
            if panel then
                panel.Visible = (not consoleVisible) and visible
            end
        end
    end

    function StatsUI.Start()
        startTime = os.clock()
        StatsUI.Create()

        local acc = 0
        RunService.Heartbeat:Connect(function(dt)
            acc = acc + dt
            if acc >= 1.5 then acc = 0; StatsUI.Update() end
        end)

        StatsUI.ConsoleLog("INFO", "Overlay started — use STATS / CONSOLE buttons")
    end
end

---------------------------------------------------------------------------
-- GLOBAL LOG HOOK (modules log to console overlay)
---------------------------------------------------------------------------
local _origLog = Utils.Log
Utils.Log = function(tag, msg)
    _origLog(tag, msg)
    pcall(function() StatsUI.ConsoleLog(tag, tostring(msg)) end)
end

---------------------------------------------------------------------------
-- BOOT
---------------------------------------------------------------------------
local ready = Utils.WaitForReady(20)
if not ready then
    Utils.Log("BOOT", "Character not fully ready; continuing with safe guards")
end

Utils.Log("BOOT", "All systems starting...")

-- Start all modules in separate threads
local modules = {
    { name = "Harvest",  fn = Harvest.Start },
    { name = "Plant",    fn = Plant.Start },
    { name = "BuySeeds", fn = BuySeeds.Start },
    { name = "Pets",     fn = Pets.Start },
    { name = "Gear",     fn = Gear.Start },
    { name = "Mail",     fn = Mail.Start },
    { name = "Misc",     fn = Misc.Start },
}

for _, mod in ipairs(modules) do
    coroutine.wrap(function()
        local ok, err = pcall(mod.fn)
        if not ok then
            Utils.Log("ERROR", mod.name .. ": " .. tostring(err))
        end
    end)()
end

-- Stats overlay (must run on main thread for GUI)
local okStats, statsErr = pcall(StatsUI.Start)
if not okStats then
    Utils.Log("ERROR", "StatsUI: " .. tostring(statsErr))
end

Utils.Log("BOOT", "All modules loaded! Use STATS / CONSOLE buttons.")
Utils.Notify("GAG Autofarm", "All modules running! Use STATS / CONSOLE buttons.")
