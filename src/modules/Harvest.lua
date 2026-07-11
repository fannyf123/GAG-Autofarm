--[[
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

return Harvest