local Mail = {}

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

return Mail