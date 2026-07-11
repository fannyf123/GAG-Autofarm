local Utils = {}

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
	ShovelPlant = "Networking.Shovel.UseShovel",
	MovePlant = "Networking.Trowel.MovePlant",

	-- Gear shop (from gearshop.txt)
	BuyGear = "Networking.GearShop.PurchaseGear",
	PurchaseGear = "Networking.GearShop.PurchaseGear",
	EquipGear = "Networking.GearShop.EquipGear",
	UnequipGear = "Networking.GearShop.UnequipGear",
	RequestEquippableState = "Networking.GearShop.RequestEquippableState",
	PlaceSprinkler = "Networking.Place.PlaceSprinkler",

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
