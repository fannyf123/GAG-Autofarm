local Misc = {}

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
