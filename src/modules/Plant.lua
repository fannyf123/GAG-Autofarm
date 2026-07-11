local Plant = {}

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
	for key, entry in pairs(plan) do
		if entry == seedName or key == seedName or (type(entry) == "table" and entry.Name == seedName) then
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

	local player = GAG.Player
	local backpack = player and player:FindFirstChild("Backpack")
	local character = player and player.Character
	local shovel = nil
	local containers = {}
	if character then containers[#containers + 1] = character end
	if backpack then containers[#containers + 1] = backpack end
	for _, container in ipairs(containers) do
		if container then
			for _, item in ipairs(container:GetChildren()) do
				if item:IsA("Tool") and (item:GetAttribute("Shovel") ~= nil or string.find(string.lower(item.Name), "shovel", 1, true)) then
					shovel = item
					break
				end
			end
		end
		if shovel then break end
	end
	if not shovel then
		GAG.Modules.Utils.Log("ShovelPlant: shovel tool not found", "Warn")
		pendingShovel[plant] = nil
		return false
	end
	if shovel.Parent == backpack and character then
		local humanoid = character:FindFirstChildWhichIsA("Humanoid")
		if humanoid then humanoid:EquipTool(shovel); task.wait(0.12) end
	end

	local plantId = plant:GetAttribute("PlantId") or plant:GetAttribute("Id") or plant.Name
	local fruitId = plant:GetAttribute("FruitId") or ""
	local shovelName = shovel:GetAttribute("Shovel") or shovel.Name
	local shoveled = GAG.Modules.Utils.FireRemote("ShovelPlant", tostring(plantId), tostring(fruitId), shovelName, shovel)
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

	if plantPlan and next(plantPlan) then
		for key, entry in pairs(plantPlan) do
			local name, targetCount
			if type(entry) == "table" then
				name = entry.Name
				targetCount = entry.Count or entry.Amount or 1
			elseif type(key) == "string" then
				name = key
				targetCount = tonumber(entry) or 1
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
