local Gear = {}

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
	local purchased = FireRemote("Networking.GearShop.PurchaseGear", gearName)
	if not purchased then
		Log("Purchase failed: " .. gearName)
		return false
	end

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

	local plotId = player and player:GetAttribute("PlotId")
	if not plotId then
		Log("Could not determine the current plot ID")
		return false
	end
	local sprinklerType = tool:GetAttribute("Sprinkler") or sprinklerName
	local placed = FireRemote("PlaceSprinkler", position, sprinklerType, tool, plotId)
	if not placed then
		Log("Placement failed: " .. sprinklerName)
		return false
	end

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
	local placedAny = false

	local config = Config and Config.Get and Config.Get("Place Sprinklers") or {}
	local farm = GetFarm()
	if not farm then
		Log("No farm found, skipping sprinkler placement")
		return
	end

	local owned = Gear.GetOwnedGear()
	local bestUpTo = Config and Config.Get and Config.Get("Best Sprinkler Up To") or nil
	local coverageMode = Config and Config.Get and Config.Get("Coverage Mode") or "value"

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
			if Gear.PlaceSprinkler(bestSprinkler, pos) then placedAny = true end
		end
	end

	for sprinklerName, count in pairs(config) do
		if sprinklerName ~= "best" and type(count) == "number" then
			local available = math.min(count, owned[sprinklerName] or 0)
			if available > 0 then
				Log("Placing " .. available .. "x " .. sprinklerName)
				local positions = Gear.CalculateSprinklerLayout(farm, available, coverageMode)
				for i, pos in ipairs(positions) do
					if Gear.PlaceSprinkler(sprinklerName, pos) then placedAny = true end
				end
			end
		end
	end

	return placedAny
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
				sprinklersPlaced = Gear.PlaceSprinklers() == true
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
