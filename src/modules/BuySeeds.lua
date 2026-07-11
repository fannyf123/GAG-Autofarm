local BuySeeds = {}

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

	local ok = Utils.FireRemote(BUY_SEED_REMOTE, seedName, amount)

	if ok then
		GAG.Stats.SeedsBought = (GAG.Stats.SeedsBought or 0) + amount
		Log("Bought", amount, "x", seedName, "for", price * amount)
		return true
	else
		Log("Failed to buy", seedName)
		return false, "Purchase remote rejected or was unavailable"
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
