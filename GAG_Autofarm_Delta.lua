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
        ["Show Console"]          = true,
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
local CollectionService = game:GetService("CollectionService")

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
pcall(function()
    local playerGui = LP:FindFirstChild("PlayerGui")
    if playerGui then
        for _, guiName in ipairs({"GAG_Stats", "GAG_Loader_Status"}) do
            local oldGui = playerGui:FindFirstChild(guiName)
            if oldGui then oldGui:Destroy() end
        end
    end
end)

---------------------------------------------------------------------------
-- GLOBAL STATE
---------------------------------------------------------------------------
if type(_G.GAG) == "table" then
    _G.GAG.Alive = false
    _G.GAG.Running = false
    if type(_G.GAG.Connections) == "table" then
        for _, conn in ipairs(_G.GAG.Connections) do
            pcall(function()
                if conn and conn.Disconnect then conn:Disconnect() end
            end)
        end
    end
end

_G.GAG = {
    Alive    = true,
    Running  = true,
    Player   = LP,
    Character = Char,
    HRP      = HRP,
    Connections = {},
    Config   = _G.GAGConfig,
    Stats    = {
        Harvested  = 0, Sold = 0, Planted = 0, Shoveled = 0,
        Expanded   = 0, SeedsBought = 0, GearBought = 0,
        PetsBought = 0, MailSent = 0, Replaced = 0,
    },
}
local GAG = _G.GAG

table.insert(GAG.Connections, LP.CharacterAdded:Connect(function(c)
    GAG.Character = c
    GAG.HRP = c:WaitForChild("HumanoidRootPart")
    HRP = GAG.HRP
end))

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

    local function NormalizeName(name)
        local text = tostring(name or "")
        text = text:gsub("%b[]", "")
        text = text:gsub("%b()", "")
        text = text:gsub("%s+[%.%d]+%s*[Kk][Gg]", "")
        text = text:gsub("%s+[%.%d]+%s*[Gg]", "")
        text = text:gsub(" Seed$", "")
        text = text:gsub("^%s+", ""):gsub("%s+$", "")
        return text
    end

    local function BuildSet(list)
        if type(list) ~= "table" then return {} end
        local s = {}
        for k, v in pairs(list) do
            if type(k) == "number" then s[NormalizeName(v)] = true else s[NormalizeName(k)] = v end
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
                cfg._LK.NeverSellExact[NormalizeName(p.fruit) .. "|" .. tostring(p.mut):lower()] = true
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
        name = NormalizeName(name)
        local c = GAG.Config; local lk = c._LK
        if not c["Auto Harvest"] then return false end
        if next(lk.OnlyHarvest) and not lk.OnlyHarvest[name] then return false end
        if lk.DontHarvest[name] then return false end
        return true
    end
    function Config.ShouldPlant(name)
        name = NormalizeName(name)
        local c = GAG.Config; local lk = c._LK
        if not c["Auto Plant"] then return false end
        if next(lk.OnlyPlant) and not lk.OnlyPlant[name] then return false end
        if lk.DontPlant[name] then return false end
        return true
    end
    function Config.ShouldBuySeed(name)
        name = NormalizeName(name)
        local lk = GAG.Config._LK
        if lk.DontPlant[name] then return false end
        if lk.DontBuy[name] then return false end
        local banned = { Gold = true, Rainbow = true, Mega = true }
        if banned[name] then return false end
        return true
    end
    function Config.ShouldShovel(name, tier)
        name = NormalizeName(name)
        local lk = GAG.Config._LK
        if lk.NeverShovel[name] then return false end
        local tiers = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mythic = 6 }
        local max = tiers[GAG.Config["Shovel Up To"]]
        local tierValue = type(tier) == "number" and tier or tiers[tier]
        if max and tierValue and tierValue > max then return false end
        return true
    end
    function Config.ShouldNeverSell(fruit, mut)
        local rawFruit = tostring(fruit or "")
        fruit = NormalizeName(rawFruit)
        local fruitLower = fruit:lower()
        local rawLower = rawFruit:lower()
        local lk = GAG.Config._LK
        local mutText = tostring(mut or ""):lower()
        for mutName in pairs(lk.NeverSellMut or {}) do
            local m = tostring(mutName):lower()
            if mutText == m or rawLower:find(m, 1, true) then return true end
        end
        for protectedFruit in pairs(lk.NeverSellFruit or {}) do
            local p = tostring(protectedFruit):lower()
            if fruitLower == p or rawLower:find(p, 1, true) then return true end
        end
        if mut and lk.NeverSellExact[fruit .. "|" .. tostring(mut):lower()] then return true end
        return false
    end
end

---------------------------------------------------------------------------
-- UTILS MODULE
---------------------------------------------------------------------------
local Utils = {}
do
    local remoteCache = {}
    local remoteMissAt = {}
    local Net = nil
    local NetMissAt = 0
    local Replica = nil
    local ReplicaMissAt = 0

    local function LoadNet()
        if Net then return Net end
        if NetMissAt > 0 and tick() - NetMissAt < 5 then return nil end
        local ok, res = pcall(function()
            local sharedModules = ReplicatedStorage:WaitForChild("SharedModules", 15)
            local networking = sharedModules and sharedModules:WaitForChild("Networking", 15)
            return networking and require(networking) or nil
        end)
        if ok and type(res) == "table" then
            Net = res
            NetMissAt = 0
            Utils.Log("NET", "Networking module loaded")
        else
            NetMissAt = tick()
            Utils.Log("NET", "Networking module not found")
        end
        return Net
    end

    local function GetAction(path)
        local cur = LoadNet()
        if type(cur) ~= "table" then return nil end
        for part in string.gmatch(tostring(path or ""), "[^%.]+") do
            if type(cur) ~= "table" then return nil end
            cur = cur[part]
        end
        return cur
    end

    local function LoadReplica()
        if Replica then return Replica end
        if ReplicaMissAt > 0 and tick() - ReplicaMissAt < 5 then return nil end
        local ok, res = pcall(function()
            local cm = ReplicatedStorage:WaitForChild("ClientModules", 15)
            local psc = cm and cm:WaitForChild("PlayerStateClient", 15)
            local mod = psc and require(psc) or nil
            local function result(first, second)
                if first == false then return nil end
                if second ~= nil then return second end
                if first ~= nil and type(first) ~= "boolean" then return first end
                return nil
            end
            if mod and mod.WaitForLocalReplica then
                local okReplica, first, second = pcall(function()
                    return mod:WaitForLocalReplica(30)
                end)
                local replica = okReplica and result(first, second) or nil
                if replica then return replica end
                local okDirect, direct, directSecond = pcall(function()
                    return mod.WaitForLocalReplica(30)
                end)
                replica = okDirect and result(direct, directSecond) or nil
                if replica then return replica end
            end
            return nil
        end)
        if ok and res then
            Replica = res
            ReplicaMissAt = 0
            Utils.Log("DATA", "Player replica loaded")
        else
            ReplicaMissAt = tick()
            Utils.Log("DATA", "Player replica not found")
        end
        return Replica
    end

    local function StockOf(shop, name)
        local ok, items = pcall(function()
            return ReplicatedStorage.StockValues[shop].Items
        end)
        if not ok or not items then return nil end
        local item = items:FindFirstChild(name)
        return item and tonumber(item.Value) or 0
    end

    local function ToolByAttr(attr, wantName)
        local sources = {LP:FindFirstChild("Backpack"), LP.Character}
        for _, source in ipairs(sources) do
            if source then
                for _, tool in ipairs(source:GetChildren()) do
                    if tool:IsA("Tool") and tool:GetAttribute(attr) ~= nil then
                        if not wantName or tool:GetAttribute(attr) == wantName or tool.Name == wantName then
                            return tool
                        end
                    end
                end
            end
        end
        return nil
    end

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
        local gardens = workspace:FindFirstChild("Gardens")
        local plotId = LP:GetAttribute("PlotId")
        local function ownValue(value)
            if value == LP then return true end
            if typeof(value) == "Instance" then return value == LP end
            if tostring(value) == LP.Name then return true end
            if tonumber(value) and tonumber(value) == LP.UserId then return true end
            return false
        end
        local function plotValue(value)
            return plotId ~= nil and tostring(value) == tostring(plotId)
        end
        local function childOwner(p)
            local o = p:FindFirstChild("Owner") or p:FindFirstChild("OwnerValue")
            if not o then return false end
            if o:IsA("StringValue") or o:IsA("ObjectValue") or o:IsA("IntValue") or o:IsA("NumberValue") then
                return ownValue(o.Value)
            end
            return false
        end
        if gardens and plotId then
            local plot = gardens:FindFirstChild("Plot" .. tostring(plotId)) or gardens:FindFirstChild(tostring(plotId))
            if plot then return plot end
        end
        if gardens then
            for _, p in ipairs(gardens:GetChildren()) do
                if ownValue(p:GetAttribute("Owner")) or ownValue(p:GetAttribute("OwnerUserId")) or ownValue(p:GetAttribute("UserId")) or plotValue(p:GetAttribute("PlotId")) or childOwner(p) or p.Name == LP.Name then
                    return p
                end
            end
        end
        for _, folderName in ipairs({"Gardens", "Farms", "Plots"}) do
            local folder = workspace:FindFirstChild(folderName)
            if folder then
                for _, p in ipairs(folder:GetChildren()) do
                    if childOwner(p) then return p end
                    if p.Name == LP.Name then return p end
                end
            end
        end
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj.Name:lower():find("farm") or obj.Name:lower():find("plot") then
                local o = obj:FindFirstChild("Owner") or obj:FindFirstChild("OwnerValue")
                if o then
                    if o:IsA("StringValue") and o.Value == LP.Name then return obj end
                    if o:IsA("ObjectValue") and o.Value == LP then return obj end
                end
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

    function Utils.NetAction(path)
        return GetAction(path)
    end

    function Utils.NetFire(path, ...)
        local action = GetAction(path)
        if not (action and action.Fire) then return false, "missing action: " .. tostring(path) end
        local pack = table.pack or function(...) return { n = select("#", ...), ... } end
        local unpackArgs = table.unpack or unpack
        local args = pack(...)
        local ok, res = pcall(function()
            return action:Fire(unpackArgs(args, 1, args.n))
        end)
        if not ok then
            Utils.Log("NET", tostring(path) .. " err: " .. tostring(res))
            return false, res
        end
        if res == false then return false, res end
        if type(res) == "table" and res.Success == false then return false, res end
        return true, res
    end

    function Utils.Data()
        local rep = LoadReplica()
        return rep and rep.Data or {}
    end

    function Utils.InventoryCategory(category)
        local inv = Utils.Data().Inventory
        return inv and inv[category] or {}
    end

    function Utils.InventoryNames(category)
        local out = {}
        for k, v in pairs(Utils.InventoryCategory(category)) do
            local name, count
            if type(v) == "table" then
                name = v.Name or v.ItemName or v.Type or tostring(k)
                count = tonumber(v.Count) or tonumber(v.Amount) or 1
            elseif type(v) == "number" then
                name, count = tostring(k), v
            else
                name, count = tostring(k), 1
            end
            if name then out[name] = (out[name] or 0) + (count or 1) end
        end
        return out
    end

    function Utils.StockOf(shop, name)
        return StockOf(shop, name)
    end

    function Utils.ToolByAttr(attr, wantName)
        return ToolByAttr(attr, wantName)
    end

    function Utils.FindRemote(name)
        if remoteCache[name] ~= nil then
            local cached = remoteCache[name]
            if cached and cached.Parent then return cached end
        end
        if remoteMissAt[name] and tick() - remoteMissAt[name] < 5 then
            return nil
        end
        local lname = tostring(name):lower()
        local function search(cont, exact)
            local scanned = 0
            local stack = {cont}
            while #stack > 0 and scanned < 3000 do
                local current = table.remove(stack)
                for _, ch in ipairs(current:GetChildren()) do
                    scanned = scanned + 1
                    if ch:IsA("RemoteEvent") or ch:IsA("RemoteFunction") then
                        local cname = ch.Name:lower()
                        if (exact and cname == lname) or ((not exact) and cname:find(lname, 1, true)) then
                            remoteCache[name] = ch
                            return ch
                        end
                    end
                    if scanned >= 3000 then break end
                    table.insert(stack, ch)
                end
            end
        end
        local found = search(ReplicatedStorage, true) or search(workspace, true)
        if not found and #lname > 4 then
            found = search(ReplicatedStorage, false) or search(workspace, false)
        end
        if found then
            remoteCache[name] = found
        else
            remoteMissAt[name] = tick()
        end
        return found
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
        local data = Utils.Data()
        local sheckles = tonumber(data.Sheckles)
        if sheckles then return sheckles end
        local ls = LP:FindFirstChild("leaderstats")
        if ls then
            local c = ls:FindFirstChild("Cash") or ls:FindFirstChild("Sheckles") or ls:FindFirstChild("Money")
            if c then return c.Value end
        end
        return 0
    end

    function Utils.GetFruitCount()
        local attrCount = tonumber(LP:GetAttribute("FruitCount")) or 0
        local bp = LP:FindFirstChild("Backpack")
        if not bp then return attrCount end
        local crops = {
            Carrot = true, Strawberry = true, Blueberry = true, Tomato = true, Corn = true,
            Apple = true, Bamboo = true, Coconut = true, Cactus = true, Pumpkin = true,
            Watermelon = true, ["Dragon Fruit"] = true, Mango = true, Grape = true,
            Mushroom = true, Pepper = true, Cacao = true, Beanstalk = true,
        ["Moon Bloom"] = true, ["Dragon's Breath"] = true, ["Venus Fly Trap"] = true,
        ["Orange Tulip"] = true,
        }
        local n = 0
        for _, i in ipairs(bp:GetChildren()) do
            if i:IsA("Tool") then
                local lower = i.Name:lower()
                local clean = tostring(i.Name):gsub(" Seed$", ""):gsub("%b[]", ""):gsub("%b()", ""):gsub("%s+[%.%d]+%s*[Kk][Gg]", ""):gsub("%s+[%.%d]+%s*[Gg]", ""):gsub("^%s+", ""):gsub("%s+$", "")
                if not lower:find("seed") and (i:GetAttribute("IsFruit") or i:GetAttribute("HarvestedFruit") or lower:find("fruit") or crops[clean]) then
                    n = n + 1
                end
            end
        end
        return math.max(n, attrCount)
    end

    function Utils.Diagnostics()
        local farm = Utils.GetFarm()
        local plants = farm and Utils.GetPlants(farm) or {}
        local backpack = LP:FindFirstChild("Backpack")
        local actions = {"Garden.CollectFruit", "NPCS.SellAll", "Plant.PlantSeed", "SeedShop.PurchaseSeed", "GearShop.PurchaseGear", "Mailbox.OpenInbox", "Mailbox.Claim", "Actions.ExpandGarden"}
        Utils.Log("DIAG", "Running: " .. tostring(GAG.Running) .. " | Farm: " .. (farm and farm.Name or "NOT FOUND") .. " | PlotId: " .. tostring(LP:GetAttribute("PlotId")))
        Utils.Log("DIAG", "Plants: " .. tostring(#plants) .. " | Backpack items: " .. tostring(backpack and #backpack:GetChildren() or 0) .. " | Money: " .. tostring(Utils.GetMoney()) .. " | Fruit: " .. tostring(LP:GetAttribute("FruitCount") or Utils.GetFruitCount()))
        for _, path in ipairs(actions) do
            Utils.Log("DIAG", path .. ": " .. (Utils.NetAction(path) and "FOUND" or "NOT FOUND"))
        end
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
        local name = tostring(plant:GetAttribute("PlantName") or plant.Name):gsub(" Seed$", ""):gsub("%s+$", "")
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

    local function FindAncestorAttr(obj, attr)
        local cur = obj
        while cur and cur ~= workspace do
            local value = cur:GetAttribute(attr)
            if value ~= nil then return value, cur end
            cur = cur.Parent
        end
        return nil, nil
    end

    function Harvest.HarvestTagged()
        if not GAG.Config["Auto Harvest"] then return 0 end
        local farm = Utils.GetFarm()
        local done = 0
        for _, prompt in ipairs(CollectionService:GetTagged("HarvestPrompt")) do
            if not GAG.Alive or not GAG.Running then break end
            if prompt and prompt:IsDescendantOf(workspace) and (not prompt:IsA("ProximityPrompt") or prompt.Enabled ~= false) then
                local plantId, carrier = FindAncestorAttr(prompt, "PlantId")
                local fruitId = FindAncestorAttr(prompt, "FruitId")
                local userId = FindAncestorAttr(prompt, "UserId")
                local owned = (not userId or tonumber(userId) == LP.UserId or tostring(userId) == tostring(LP.UserId))
                if owned and farm and carrier and not carrier:IsDescendantOf(farm) then owned = false end
                if owned and plantId then
                    local ok = Utils.NetFire("Garden.CollectFruit", tostring(plantId), tostring(fruitId or ""))
                    if ok then
                        done = done + 1
                        GAG.Stats.Harvested = GAG.Stats.Harvested + 1
                        if done % 12 == 0 then task.wait(0.05) end
                    end
                end
            end
        end
        if done > 0 then Utils.Log("HARVEST", "Collected " .. tostring(done) .. " tagged fruits") end
        return done
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

        local plantId = plant:GetAttribute("PlantId")
        local fruitId = plant:GetAttribute("FruitId")
        if plantId and Utils.NetFire("Garden.CollectFruit", tostring(plantId), tostring(fruitId or "")) then
            GAG.Stats.Harvested = GAG.Stats.Harvested + 1
            task.wait(0.1)
            return true
        end
        for _, ch in ipairs(plant:GetDescendants()) do
            local descPlantId = ch:GetAttribute("PlantId") or plantId
            local descFruitId = ch:GetAttribute("FruitId") or fruitId
            if descPlantId or descFruitId then
                descPlantId = descPlantId or FindAncestorAttr(ch, "PlantId")
                descFruitId = descFruitId or FindAncestorAttr(ch, "FruitId")
                if Utils.NetFire("Garden.CollectFruit", tostring(descPlantId or ""), tostring(descFruitId or "")) then
                    GAG.Stats.Harvested = GAG.Stats.Harvested + 1
                    task.wait(0.1)
                    return true
                end
            end
        end

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
        local sources = {LP:FindFirstChild("Backpack"), LP.Character}
        for _, source in ipairs(sources) do
            if source then
                for _, item in ipairs(source:GetChildren()) do
                    if item:IsA("Tool") then
                        local mutation = item:GetAttribute("Mutation") or item:GetAttribute("MutationName") or item:GetAttribute("Mutated") or item:GetAttribute("Variant")
                        if mutation == true and next(GAG.Config._LK.NeverSellMut or {}) then
                            Utils.Log("SELL", "Skipped sell: protected mutated item " .. item.Name)
                            return false
                        end
                        if Config.ShouldNeverSell(item.Name, mutation) then
                            Utils.Log("SELL", "Skipped sell: protected item " .. item.Name)
                            return false
                        end
                        for mutName in pairs(GAG.Config._LK.NeverSellMut or {}) do
                            if tostring(item.Name):lower():find(tostring(mutName):lower(), 1, true) then
                                Utils.Log("SELL", "Skipped sell: protected mutation " .. tostring(mutName))
                                return false
                            end
                        end
                    end
                end
            end
        end
        local beforeCount = Utils.GetFruitCount()
        Utils.Log("HARVEST", "Selling fruits...")
        local okSell, sellRes = Utils.NetFire("NPCS.SellAll")
        if okSell then
            local sold = beforeCount
            if type(sellRes) == "table" and sellRes.Success == true then
                sold = tonumber(sellRes.SoldCount) or sold
            end
            GAG.Stats.Sold = GAG.Stats.Sold + sold
            sellTimer = 0
            Utils.Log("SELL", "Sold " .. tostring(sold) .. " fruits")
            return true
        end
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
            if not GAG.Running then
                Utils.Sleep(1)
            else
            pcall(function()
                Harvest.HarvestTagged()
                local plants = Utils.GetPlants()
                table.sort(plants, function(a, b)
                    local am = a:GetAttribute("Mutated") or a:GetAttribute("HasMutation")
                    local bm = b:GetAttribute("Mutated") or b:GetAttribute("HasMutation")
                    if am and not bm then return true end
                    return false
                end)

                for _, plant in ipairs(plants) do
                    if not GAG.Alive or not GAG.Running then break end
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
            end
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
        local text = tostring(name or ""):gsub(" Seed", "")
        local known = {
            Carrot = 1,
            Strawberry = 1,
            Blueberry = 2,
            Tomato = 2,
            ["Orange Tulip"] = 2,
            Corn = 3,
            Apple = 3,
            Bamboo = 3,
            Coconut = 4,
            Cactus = 4,
            Pumpkin = 4,
            Watermelon = 4,
            ["Dragon Fruit"] = 5,
            Mango = 5,
            Grape = 5,
            Mushroom = 6,
            Pepper = 6,
            Cacao = 6,
            Beanstalk = 6,
            ["Dragon's Breath"] = 6,
            ["Moon Bloom"] = 6,
            ["Venus Fly Trap"] = 6,
        }
        if known[text] then return known[text] end
        for t, v in pairs(SEED_TIERS) do
            if text:lower():find(t:lower(), 1, true) then return v end
        end
        return 6
    end

    local function IsProtected(plant)
        local rawName = plant:GetAttribute("SeedName") or plant.Name
        local name = tostring(rawName or ""):gsub(" Seed$", ""):gsub("%s+$", "")
        local lk = GAG.Config._LK
        for attr, val in pairs(plant:GetAttributes()) do
            if attr:lower():find("mutation") and val then return true end
        end
        local sz = plant:GetAttribute("Size") or plant:GetAttribute("PlantSize")
        if sz and tostring(sz):lower() == "mega" then return true end
        if lk.NeverShovel[name] then return true end
        if lk.NeverSellFruit[name] then return true end
        local mutation = plant:GetAttribute("Mutation") or plant:GetAttribute("MutationName") or plant:GetAttribute("Mutated") or plant:GetAttribute("Variant")
        if Config.ShouldNeverSell(rawName, mutation) then return true end
        local plan = GAG.Config["Plant Plan"]
        if plan then
            for _, e in ipairs(plan) do
                local n = tostring(type(e) == "table" and e.Name or e):gsub(" Seed$", ""):gsub("%s+$", "")
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

    local function TryPlantWithRay(pos)
        local playerScripts = LP:FindFirstChild("PlayerScripts")
        local controllers = playerScripts and playerScripts:FindFirstChild("Controllers")
        local plantController = controllers and controllers:FindFirstChild("PlantController")
        if not plantController then return false end
        local controller = plantController
        if plantController:IsA("ModuleScript") then
            local okRequire, mod = pcall(require, plantController)
            if not okRequire then return false end
            controller = mod
        end
        local okFn, fn = pcall(function() return controller.TryPlantWithRay end)
        if not okFn or type(fn) ~= "function" then return false end
        local ray = Ray.new(pos + Vector3.new(0, 12, 0), Vector3.new(0, -40, 0))
        local ok, res = pcall(function()
            return fn(controller, ray)
        end)
        return ok and (res == nil or res ~= false)
    end

    function Plant.GetPlotPositions()
        local farm = Utils.GetFarm()
        if not farm then return {} end
        local tagged = {}
        for _, area in ipairs(CollectionService:GetTagged("PlantArea")) do
            if area:IsA("BasePart") and area:IsDescendantOf(farm) then
                table.insert(tagged, area)
            end
        end
        if #tagged > 0 then
            local lo = LAYOUT[GAG.Config["Layout"]] or LAYOUT.compact
            local pos = {}
            for _, area in ipairs(tagged) do
                local stepsX = math.max(1, math.floor(area.Size.X / lo.x))
                local stepsZ = math.max(1, math.floor(area.Size.Z / lo.z))
                for x = 1, stepsX do
                    for z = 1, stepsZ do
                        local lx = -area.Size.X / 2 + (x - 0.5) * lo.x
                        local lz = -area.Size.Z / 2 + (z - 0.5) * lo.z
                        table.insert(pos, (area.CFrame * CFrame.new(lx, area.Size.Y / 2 + 0.05, lz)).Position)
                    end
                end
            end
            return pos
        end
        local primary = (farm:IsA("BasePart") and farm) or (farm:IsA("Model") and farm.PrimaryPart) or farm:FindFirstChildWhichIsA("BasePart", true)
        if not primary then return {} end
        local fp = primary.Position
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
        local tool = Utils.ToolByAttr("SeedTool", name) or Utils.ToolByAttr("SeedName", name)
        if not tool then
            for _, t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") and (t.Name == name or t.Name == name .. " Seed") then tool = t; break end
            end
        end
        if not tool then
            for _, t in ipairs(ch:GetChildren()) do
                if t:IsA("Tool") and (t.Name == name or t.Name == name .. " Seed") then tool = t; break end
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
        local seedName = tool:GetAttribute("SeedTool") or tool:GetAttribute("SeedName") or name:gsub(" Seed$", "")
        local ok = Utils.NetFire("Plant.PlantSeed", pos, seedName, tool)
        if not ok then ok = TryPlantWithRay(pos) end
        if not ok then
            ok = Utils.FireRemote("PlantSeed", name, pos) or Utils.FireRemote("Plant", name, pos)
        end
        if not ok then return false end
        GAG.Stats.Planted = GAG.Stats.Planted + 1
        task.wait(0.3)
        return true
    end

    function Plant.ShovelPlant(plant)
        local name = plant:GetAttribute("SeedName") or plant.Name
        if IsProtected(plant) then return false end
        if not Config.ShouldShovel(name, TierVal(name)) then return false end
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
        local ok = Utils.NetFire("Actions.ExpandGarden")
        if not ok then
            ok = Utils.FireRemote("ExpandPlot") or Utils.FireRemote("BuyExpansion")
        end
        if not ok then return false end
        GAG.Stats.Expanded = GAG.Stats.Expanded + 1
        task.wait(0.5)
        return true
    end

    function Plant.GetNextSeed()
        local bp = LP:FindFirstChild("Backpack")
        if not bp then return nil end
        local counts = {}
        local function isSeedTool(tool)
            if not tool:IsA("Tool") then return false end
            if tool:GetAttribute("IsFruit") or tool:GetAttribute("HarvestedFruit") or tool:GetAttribute("IsGear") or tool:GetAttribute("IsPet") then return false end
            local lower = tool.Name:lower()
            if lower:find("sprinkler") or lower:find("trowel") or lower:find("shovel") or lower:find("watering") then return false end
            return tool:GetAttribute("IsSeed") or tool:GetAttribute("SeedName") or lower:find("seed")
        end
        for _, t in ipairs(bp:GetChildren()) do
            if isSeedTool(t) then
                local seedName = t:GetAttribute("SeedTool") or t:GetAttribute("SeedName") or t.Name:gsub(" Seed$", "")
                counts[seedName] = (counts[seedName] or 0) + 1
            end
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
                if (pCounts[n] or 0) < tgt and (counts[n] or 0) > 0 and Config.ShouldPlant(n) then return n end
            end
        end
        local only = GAG.Config["Only Plant"]
        if only and #only > 0 then
            for _, n in ipairs(only) do
                if (counts[n] or 0) > 0 and Config.ShouldPlant(n) then return n end
            end
            return nil
        end
        local minTier = TierVal(GAG.Config["Minimum Seed"])
        local best, bestT = nil, math.huge
        for n, c in pairs(counts) do
            if c > 0 then
                local tv = TierVal(n)
                if Config.ShouldPlant(n) and tv >= minTier and tv < bestT then bestT = tv; best = n end
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
                if GAG.Running and GAG.Config["Auto Plant"] then
                    local empty = Plant.GetEmptyPositions()
                    if #empty > 0 then
                        local seed = Plant.GetNextSeed()
                        if seed then
                            for _, pos in ipairs(empty) do
                                if not GAG.Running or not GAG.Config["Auto Plant"] then break end
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
        if cash <= GAG.Config["Keep Cash"] then return false end
        local stock = Utils.StockOf("SeedShop", name)
        if stock ~= nil and stock <= 0 then return false end
        local bought = 0
        for _ = 1, amount do
            cash = Utils.GetMoney()
            if cash <= GAG.Config["Keep Cash"] then break end
            local ok = Utils.NetFire("SeedShop.PurchaseSeed", name)
            if not ok then
                ok = Utils.FireRemote("BuySeed", name, 1) or Utils.FireRemote("Buy", name, 1)
            end
            if ok then bought = bought + 1 end
            task.wait(0.12)
        end
        if bought <= 0 then return false end
        GAG.Stats.SeedsBought = GAG.Stats.SeedsBought + bought
        Utils.Log("BUY", bought .. "x " .. name)
        return true
    end

    function BuySeeds.ProcessConfig()
        local cfg = GAG.Config["Buy Seeds"]
        if type(cfg) ~= "table" then return end
        local bp = LP:FindFirstChild("Backpack")
        if not bp then return end
        local counts = {}
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then
                local seedName = t:GetAttribute("SeedTool") or t:GetAttribute("SeedName") or t.Name:gsub(" Seed$", "")
                counts[seedName] = (counts[seedName] or 0) + 1
            end
        end
        for name, target in pairs(cfg) do
            if not GAG.Running then break end
            if Utils.GetMoney() <= GAG.Config["Keep Cash"] then break end
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
            if GAG.Running then
                pcall(function() BuySeeds.ProcessConfig() end)
            end
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
        local owned = Utils.InventoryNames("Pets")
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
        if not Utils.NetFire("Pets.RequestEquipByName", name) then
            Utils.FireRemote("EquipPet", name)
        end
        Utils.Log("PET", "Equipped " .. name)
    end

    function Pets.BuySlot()
        if not GAG.Config["Pets"]["Auto Buy Slots"] then return end
        if not Utils.NetFire("Pets.RequestPurchasePetSlot") then
            Utils.FireRemote("BuyPetSlot")
        end
        Utils.Log("PET", "Bought pet slot")
    end

    function Pets.Start()
        Utils.Log("PETS", "Loop started")
        while GAG.Alive do
            if GAG.Running then
            pcall(function()
                local buyCfg = GAG.Config["Pets"]["Buy"]
                local owned = Pets.GetOwned()
                for k, v in pairs(buyCfg) do
                    if not GAG.Running then break end
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
                    if not GAG.Running then break end
                    for i = 1, count do
                        if not GAG.Running then break end
                        Pets.Equip(name)
                        task.wait(0.3)
                    end
                end
            end)
            end
            Utils.Sleep(10)
        end
    end
end

---------------------------------------------------------------------------
-- GEAR MODULE
---------------------------------------------------------------------------
local Gear = {}
do
    local sprinklersPlaced = false

    function Gear.PlaceSprinklers()
        local cfg = GAG.Config["Gear"]["Place Sprinklers"]
        if not cfg then return true end
        local farm = Utils.GetFarm()
        if not farm then return false end
        local primary = (farm:IsA("BasePart") and farm) or (farm:IsA("Model") and farm.PrimaryPart) or farm:FindFirstChildWhichIsA("BasePart", true)
        if not primary then return false end
        local fp = primary.Position
        local placed = 0
        local total = 0

        for name, count in pairs(cfg) do
            total = total + count
            if name == "best" then
                local best = GAG.Config["Gear"]["Best Sprinkler Up To"] or "Rare Sprinkler"
                Utils.Log("GEAR", "Placing " .. count .. " best sprinklers (up to " .. best .. ")")
                for i = 1, count do
                    if not GAG.Running then break end
                    local angle = (i - 1) * (2 * math.pi / count)
                    local r = 10
                    local pos = fp + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
                    local tool = Utils.ToolByAttr("Sprinkler", best)
                    local ok = Utils.NetFire("Place.PlaceSprinkler", pos, best, tool, LP:GetAttribute("PlotId"))
                    if not ok then ok = Utils.FireRemote("PlaceSprinkler", best, pos) end
                    if ok then placed = placed + 1 end
                    task.wait(0.3)
                end
            else
                for i = 1, count do
                    if not GAG.Running then break end
                    local angle = (i - 1) * (2 * math.pi / count)
                    local pos = fp + Vector3.new(math.cos(angle) * 8, 0, math.sin(angle) * 8)
                    local tool = Utils.ToolByAttr("Sprinkler", name)
                    local ok = Utils.NetFire("Place.PlaceSprinkler", pos, name, tool, LP:GetAttribute("PlotId"))
                    if not ok then ok = Utils.FireRemote("PlaceSprinkler", name, pos) end
                    if ok then placed = placed + 1 end
                    task.wait(0.3)
                end
            end
        end
        return total <= 0 or placed >= total
    end

    function Gear.ProcessBuy()
        local buyList = GAG.Config["Gear"]["Buy Gear"]
        if not buyList then return end
        local keep = GAG.Config["Gear"]["Keep Cash"] or 15000
        for _, name in ipairs(buyList) do
            if not GAG.Running then break end
            local cash = Utils.GetMoney()
            if cash <= keep then break end
            local stock = Utils.StockOf("GearShop", name)
            if stock == nil or stock > 0 then
                local ok = Utils.NetFire("GearShop.PurchaseGear", name)
                if not ok then ok = Utils.FireRemote("BuyGear", name) end
                if ok then
                    GAG.Stats.GearBought = GAG.Stats.GearBought + 1
                    Utils.Log("GEAR", "Bought " .. name)
                end
                task.wait(0.5)
            end
        end
    end

    function Gear.Start()
        Utils.Log("GEAR", "Loop started")
        while GAG.Alive do
            if GAG.Running then
            pcall(function()
                if GAG.Config["Gear"]["Auto Buy"] then
                    if not sprinklersPlaced then
                        sprinklersPlaced = Gear.PlaceSprinklers()
                    end
                    Gear.ProcessBuy()
                end
            end)
            end
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
        Carrot = true, Tomato = true, Corn = true, Bamboo = true, Cactus = true,
        Pumpkin = true, Mushroom = true, Pepper = true, Cacao = true, Beanstalk = true,
        ["Moon Bloom"] = true, ["Dragon's Breath"] = true, ["Venus Fly Trap"] = true,
        ["Orange Tulip"] = true,
    }

    local function MailCleanName(name)
        return tostring(name or ""):gsub("%b[]", ""):gsub("%b()", ""):gsub("%s+[%.%d]+%s*[Kk][Gg]", ""):gsub("%s+[%.%d]+%s*[Gg]", ""):gsub(" Seed$", ""):gsub("^%s+", ""):gsub("%s+$", "")
    end

    function Mail.Claim()
        local ok, box = Utils.NetFire("Mailbox.OpenInbox")
        local claimed = 0
        if ok and type(box) == "table" then
            local inbox = box.Mailbox or box.Inbox or box
            for id, entry in pairs(inbox) do
                if type(entry) == "table" and entry.Claimed ~= true and entry.IsClaimed ~= true then
                    local claimId = entry.Id or entry.ID or entry.MailId or entry.MailID or entry.UUID or id
                    if Utils.NetFire("Mailbox.Claim", claimId) then
                        claimed = claimed + 1
                        task.wait(0.1)
                    end
                end
            end
        end
        if claimed == 0 then
            if not Utils.FireRemote("ClaimMail") then
                Utils.FireRemote("MailClaim")
            end
        end
        Utils.Log("MAIL", claimed > 0 and ("Claimed " .. tostring(claimed) .. " mail") or "Claimed mail")
    end

    function Mail.SendItem(name, count)
        if not tostring(name):lower():find("seed") and FRUITS[MailCleanName(name)] then return false end
        if Config.ShouldNeverSell(name, nil) then
            Utils.Log("MAIL", "Skipped protected item " .. tostring(name))
            return false
        end
        for _, source in ipairs({LP:FindFirstChild("Backpack"), LP.Character}) do
            if source then
                for _, tool in ipairs(source:GetChildren()) do
                    if tool:IsA("Tool") and tool.Name == name then
                        local mutation = tool:GetAttribute("Mutation") or tool:GetAttribute("MutationName") or tool:GetAttribute("Mutated") or tool:GetAttribute("Variant")
                        if mutation == true and next(GAG.Config._LK.NeverSellMut or {}) then
                            Utils.Log("MAIL", "Skipped protected mutated item " .. tostring(name))
                            return false
                        end
                        if Config.ShouldNeverSell(tool.Name, mutation) then
                            Utils.Log("MAIL", "Skipped protected item " .. tostring(name))
                            return false
                        end
                    end
                end
            end
        end
        local target = GAG.Config["Mail"]["Send To"]
        if not target or target == "" then return false end
        local ok = Utils.NetFire("Mailbox.Send", target, name, count)
        if not ok then ok = Utils.NetFire("Mailbox.SendItem", target, name, count) end
        if not ok then ok = Utils.FireRemote("SendMail", target, name, count) or Utils.FireRemote("MailSend", target, name, count) end
        if not ok then return false end
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
            if not GAG.Running then break end
            local itemName, reqCount
            if type(entry) == "string" then
                itemName = entry; reqCount = counts[entry] or 0
            elseif type(entry) == "table" then
                itemName = entry.Item or entry[1]
                reqCount = entry.Count or entry[2] or 0
            end
            if itemName and (tostring(itemName):lower():find("seed") or not FRUITS[MailCleanName(itemName)]) then
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
            if GAG.Running then
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
            end
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
        if not Utils.NetFire("NPCS.CheckDailyDeal") then
            Utils.FireRemote("DailyDeal")
        end
        Utils.NetFire("NPCS.UseDailyDealAll")
        Utils.Log("MISC", "Daily deal triggered")
    end

    function Misc.Start()
        Utils.Log("MISC", "Loop started")
        Misc.ApplyPerformance()
        Misc.DailyDeal()
        while GAG.Alive do
            if GAG.Running then
            pcall(function()
                Misc.CollectEventSeeds()
                Misc.AutoReturn()
                Misc.ApplyWalkSpeed()
            end)
            end
            Utils.Sleep(5)
        end
    end
end

---------------------------------------------------------------------------
-- STATS OVERLAY MODULE
---------------------------------------------------------------------------
local StatsUI = {}
do
    local overlay, consoleFrame, menuFrame
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

        menuFrame = Instance.new("Frame")
        menuFrame.Name = "Menu"
        menuFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
        menuFrame.BackgroundTransparency = 0.08
        menuFrame.BorderSizePixel = 0
        menuFrame.Size = UDim2.new(0, 260, 0, 330)
        menuFrame.Position = UDim2.new(0.5, -130, 0.5, -165)
        menuFrame.Visible = false
        menuFrame.Parent = overlay
        Instance.new("UICorner", menuFrame).CornerRadius = UDim.new(0, 10)
        local menuStroke = Instance.new("UIStroke", menuFrame)
        menuStroke.Color = Color3.fromRGB(70, 70, 85)
        menuStroke.Thickness = 1

        local menuTitle = mkLabel(menuFrame, "GAG MENU", Enum.TextXAlignment.Center, Color3.fromRGB(100, 220, 140), 16)
        menuTitle.Position = UDim2.new(0, 0, 0, 8)

        local function menuButton(text, y, color, callback)
            local btn = Instance.new("TextButton")
            btn.BackgroundColor3 = color
            btn.BackgroundTransparency = 0.05
            btn.BorderSizePixel = 0
            btn.Size = UDim2.new(1, -24, 0, 32)
            btn.Position = UDim2.new(0, 12, 0, y)
            btn.Font = Enum.Font.SourceSansBold
            btn.Text = text
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextSize = 15
            btn.Parent = menuFrame
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
            btn.MouseButton1Click:Connect(callback)
            return btn
        end

        local function refreshMenuButtons()
        end

        menuButton("START FARM", 44, Color3.fromRGB(40, 150, 80), function()
            GAG.Running = true
            Utils.Log("MENU", "Farm started")
        end)
        menuButton("STOP FARM", 82, Color3.fromRGB(170, 60, 55), function()
            GAG.Running = false
            Utils.Log("MENU", "Farm stopped")
        end)
        menuButton("TOGGLE HARVEST", 120, Color3.fromRGB(70, 100, 170), function()
            GAG.Config["Auto Harvest"] = not GAG.Config["Auto Harvest"]
            Utils.Log("MENU", "Auto Harvest = " .. tostring(GAG.Config["Auto Harvest"]))
        end)
        menuButton("TOGGLE PLANT", 158, Color3.fromRGB(70, 100, 170), function()
            GAG.Config["Auto Plant"] = not GAG.Config["Auto Plant"]
            Utils.Log("MENU", "Auto Plant = " .. tostring(GAG.Config["Auto Plant"]))
        end)
        menuButton("TOGGLE MAIL", 196, Color3.fromRGB(70, 100, 170), function()
            GAG.Config["Mail"]["Auto Claim"] = not GAG.Config["Mail"]["Auto Claim"]
            Utils.Log("MENU", "Mail Auto Claim = " .. tostring(GAG.Config["Mail"]["Auto Claim"]))
        end)
        menuButton("RUN DIAGNOSTIC", 234, Color3.fromRGB(165, 120, 35), function()
            Utils.Diagnostics()
            consoleVisible = true
            if consoleFrame then consoleFrame.Visible = true end
            if menuFrame then menuFrame.Visible = false end
            panel.Visible = false
        end)
        menuButton("CLOSE MENU", 280, Color3.fromRGB(80, 80, 90), function()
            menuFrame.Visible = false
            local panel = overlay and overlay:FindFirstChild("Panel")
            if panel then panel.Visible = visible and not consoleVisible end
        end)

        local controls = Instance.new("Frame")
        controls.Name = "MobileControls"
        controls.BackgroundTransparency = 1
        controls.Size = UDim2.new(0, 120, 0, 150)
        controls.Position = UDim2.new(0, 12, 1, -160)
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

        makeButton("MENU", 0, Color3.fromRGB(80, 110, 190)).MouseButton1Click:Connect(function()
            if menuFrame then
                menuFrame.Visible = not menuFrame.Visible
                if menuFrame.Visible then
                    consoleVisible = false
                    if consoleFrame then consoleFrame.Visible = false end
                    local panel = overlay and overlay:FindFirstChild("Panel")
                    if panel then panel.Visible = false end
                else
                    local panel = overlay and overlay:FindFirstChild("Panel")
                    if panel then panel.Visible = visible and not consoleVisible end
                end
            end
        end)

        makeButton("STATS", 50, Color3.fromRGB(45, 160, 95)).MouseButton1Click:Connect(function()
            StatsUI.Toggle()
        end)

        makeButton("CONSOLE", 100, Color3.fromRGB(165, 120, 35)).MouseButton1Click:Connect(function()
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
        local menuWasVisible = menuFrame and menuFrame.Visible
        if menuFrame then menuFrame.Visible = false end
        if menuWasVisible then
            visible = true
            consoleVisible = false
            if consoleFrame then consoleFrame.Visible = false end
        elseif consoleVisible then
            consoleVisible = false
            visible = true
            if consoleFrame then consoleFrame.Visible = false end
        else
            visible = not visible
        end
        if overlay then
            local p = overlay:FindFirstChild("Panel")
            if p then p.Visible = visible end
        end
    end

    function StatsUI.ToggleConsole()
        consoleVisible = not consoleVisible
        if consoleFrame then
            consoleFrame.Visible = consoleVisible
        end
        if menuFrame and consoleVisible then
            menuFrame.Visible = false
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
        table.insert(GAG.Connections, RunService.Heartbeat:Connect(function(dt)
            acc = acc + dt
            if acc >= 1.5 then acc = 0; StatsUI.Update() end
        end))

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

Utils.Log("BOOT", "All modules loaded! Use MENU / STATS / CONSOLE buttons.")
pcall(function() Utils.Diagnostics() end)
Utils.Notify("GAG Autofarm", "Loaded. Use MENU to Start/Stop and run diagnostics.")
