local Stats = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local overlay = nil
local consoleFrame = nil
local labels = {}
local consoleLines = {}
local updateConnection = nil
local inputConnection = nil
local startTime = 0
local visible = true
local consoleVisible = true
local _GAG = nil

local TOGGLE_KEY = Enum.KeyCode.F4
local MAX_CONSOLE_LINES = 20
local UPDATE_INTERVAL = 1.5

local TAG_COLORS = {
	BUY = Color3.fromRGB(100, 200, 255),
	PLANT = Color3.fromRGB(100, 255, 130),
	SHOVEL = Color3.fromRGB(255, 180, 80),
	SELL = Color3.fromRGB(255, 230, 80),
	MAIL = Color3.fromRGB(200, 130, 255),
	ERROR = Color3.fromRGB(255, 80, 80),
	INFO = Color3.fromRGB(200, 200, 200),
}

function Stats.FormatDuration(seconds)
	seconds = math.floor(seconds)
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	if h > 0 then
		return string.format("%dh %02dm %02ds", h, m, s)
	elseif m > 0 then
		return string.format("%dm %02ds", m, s)
	else
		return string.format("%ds", s)
	end
end

function Stats.FormatNumber(n)
	local formatted = tostring(math.floor(n))
	local k
	repeat
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
	until k == 0
	return formatted
end

local function createTextLabel(props)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = props.Font or Enum.Font.RobotoMono
	label.TextColor3 = props.TextColor3 or Color3.fromRGB(220, 220, 220)
	label.TextSize = props.TextSize or 14
	label.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextWrapped = false
	label.Size = props.Size or UDim2.new(1, 0, 0, 18)
	label.Text = props.Text or ""
	label.Name = props.Name or "Label"
	label.Parent = props.Parent
	return label
end

local function createButton(parent, text, color, callback)
	local btn = Instance.new("TextButton")
	btn.Name = text:gsub("%s+", "") .. "Button"
	btn.BackgroundColor3 = color or Color3.fromRGB(45, 45, 55)
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamSemibold
	btn.TextColor3 = Color3.fromRGB(245, 245, 245)
	btn.TextSize = 11
	btn.Text = text
	btn.AutoButtonColor = true
	btn.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn
	btn.MouseButton1Click:Connect(function()
		pcall(callback)
	end)
	return btn
end

local function applyPreset(name)
	if not _GAG or not _GAG.Modules or not _GAG.Modules.Config then return end
	local ok = _GAG.Modules.Config.ApplyPreset and _GAG.Modules.Config.ApplyPreset(_GAG, name)
	if ok then
		Stats.ConsoleLog("INFO", "Preset applied: " .. name)
		if labels.Preset then labels.Preset.Text = name end
	else
		Stats.ConsoleLog("ERROR", "Preset not found: " .. tostring(name))
	end
end

local function toggleRunning()
	if not _GAG then return end
	local nextState = not (_GAG.Running ~= false and _GAG.State and _GAG.State.Running ~= false)
	_GAG.Running = nextState
	_GAG.Farming = nextState
	_GAG.State = _GAG.State or {}
	_GAG.State.Running = nextState
	Stats.ConsoleLog("INFO", nextState and "Farm resumed" or "Farm paused")
end

local function getMoney()
	local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
	if leaderstats then
		local cash = leaderstats:FindFirstChild("Cash") or leaderstats:FindFirstChild("Money") or leaderstats:FindFirstChild("Coins")
		if cash then
			return cash.Value
		end
	end
	return 0
end

local function getInventoryInfo()
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	local character = LocalPlayer.Character
	local count = 0
	local capacity = 60
	if backpack then
		count = count + #backpack:GetChildren()
	end
	if character then
		count = count + #character:GetChildren()
	end
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if playerGui then
		local mainGui = playerGui:FindFirstChild("Main") or playerGui:FindFirstChild("Inventory")
		if mainGui then
			local capLabel = mainGui:FindFirstChild("Capacity", true)
			if capLabel and capLabel:IsA("TextLabel") then
				local cap = tonumber(capLabel.Text:match("(%d+)"))
				if cap then capacity = cap end
			end
		end
	end
	return count, capacity
end

local function buildStatEntry(parent, labelText, name)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 18)
	row.Name = name
	row.Parent = parent

	local lbl = createTextLabel({
		Name = "Label",
		Text = labelText,
		Size = UDim2.new(0.55, 0, 1, 0),
		TextColor3 = Color3.fromRGB(170, 170, 170),
		TextSize = 13,
		Parent = row,
	})

	local val = createTextLabel({
		Name = "Value",
		Text = "0",
		Size = UDim2.new(0.45, 0, 1, 0),
		Position = UDim2.new(0.55, 0, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 13,
		Parent = row,
	})

	return val
end

local function createConsoleLine(tag, message)
	local tagColor = TAG_COLORS[tag] or TAG_COLORS.INFO
	local timestamp = os.date("%H:%M:%S")

	local line = Instance.new("Frame")
	line.BackgroundTransparency = 1
	line.Size = UDim2.new(1, 0, 0, 16)
	line.Name = "Line"

	local timeLabel = Instance.new("TextLabel")
	timeLabel.BackgroundTransparency = 1
	timeLabel.Font = Enum.Font.RobotoMono
	timeLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
	timeLabel.TextSize = 11
	timeLabel.TextXAlignment = Enum.TextXAlignment.Left
	timeLabel.Size = UDim2.new(0, 62, 1, 0)
	timeLabel.Text = timestamp
	timeLabel.Parent = line

	local tagLabel = Instance.new("TextLabel")
	tagLabel.BackgroundTransparency = 1
	tagLabel.Font = Enum.Font.RobotoMono
	tagLabel.TextColor3 = tagColor
	tagLabel.TextSize = 11
	tagLabel.TextXAlignment = Enum.TextXAlignment.Left
	tagLabel.Size = UDim2.new(0, 50, 1, 0)
	tagLabel.Position = UDim2.new(0, 64, 0, 0)
	tagLabel.Text = "[" .. tag .. "]"
	tagLabel.Parent = line

	local msgLabel = Instance.new("TextLabel")
	msgLabel.BackgroundTransparency = 1
	msgLabel.Font = Enum.Font.RobotoMono
	msgLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	msgLabel.TextSize = 11
	msgLabel.TextXAlignment = Enum.TextXAlignment.Left
	msgLabel.TextTruncate = Enum.TextTruncate.AtEnd
	msgLabel.Size = UDim2.new(1, -118, 1, 0)
	msgLabel.Position = UDim2.new(0, 118, 0, 0)
	msgLabel.Text = message
	msgLabel.Parent = line

	return line
end

function Stats.CreateOverlay()
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
	panel.Size = UDim2.new(0, 280, 0, 445)
	panel.Position = UDim2.new(1, -295, 0, 15)
	panel.Parent = overlay

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(50, 50, 60)
	stroke.Thickness = 1
	stroke.Parent = panel

	local title = createTextLabel({
		Name = "Title",
		Text = "GAG AUTOFARM",
		TextColor3 = Color3.fromRGB(100, 220, 140),
		TextSize = 15,
		Size = UDim2.new(1, -16, 0, 22),
		Position = UDim2.new(0, 8, 0, 6),
		Font = Enum.Font.RobotoMono,
		Parent = panel,
	})

	local divider = Instance.new("Frame")
	divider.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	divider.BorderSizePixel = 0
	divider.Size = UDim2.new(1, -16, 0, 1)
	divider.Position = UDim2.new(0, 8, 0, 32)
	divider.Parent = panel

	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 2)
	list.Parent = panel

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.Size = UDim2.new(1, -16, 1, -82)
	content.Position = UDim2.new(0, 8, 0, 38)
	content.Parent = panel

	local contentList = Instance.new("UIListLayout")
	contentList.SortOrder = Enum.SortOrder.LayoutOrder
	contentList.Padding = UDim.new(0, 1)
	contentList.Parent = content

	local statusLabel = createTextLabel({
		Name = "StatusLabel",
		Text = "Status",
		Size = UDim2.new(1, 0, 0, 20),
		TextSize = 13,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		Parent = content,
	})

	local statusValue = createTextLabel({
		Name = "StatusValue",
		Text = "ACTIVE",
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 60, 0, 0),
		TextSize = 13,
		TextColor3 = Color3.fromRGB(100, 255, 130),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = content,
	})

	labels.Status = statusValue

	local presetRow = Instance.new("Frame")
	presetRow.Name = "PresetRow"
	presetRow.BackgroundTransparency = 1
	presetRow.Size = UDim2.new(1, 0, 0, 18)
	presetRow.Parent = content

	createTextLabel({
		Text = "Preset",
		Size = UDim2.new(0.45, 0, 1, 0),
		TextColor3 = Color3.fromRGB(170, 170, 170),
		TextSize = 13,
		Parent = presetRow,
	})

	labels.Preset = createTextLabel({
		Name = "PresetValue",
		Text = tostring((_GAG and _GAG.Config and _GAG.Config.Preset) or "Custom"),
		Size = UDim2.new(0.55, 0, 1, 0),
		Position = UDim2.new(0.45, 0, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = Color3.fromRGB(120, 200, 255),
		TextSize = 13,
		Parent = presetRow,
	})

	local controls = Instance.new("Frame")
	controls.Name = "QuickControls"
	controls.BackgroundTransparency = 1
	controls.Size = UDim2.new(1, 0, 0, 58)
	controls.Parent = content

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0, 78, 0, 24)
	grid.CellPadding = UDim2.new(0, 4, 0, 4)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = controls

	createButton(controls, "Starter", Color3.fromRGB(45, 95, 60), function() applyPreset("Starter") end)
	createButton(controls, "Balanced", Color3.fromRGB(45, 80, 120), function() applyPreset("Balanced") end)
	createButton(controls, "Rich", Color3.fromRGB(120, 80, 35), function() applyPreset("Rich") end)
	createButton(controls, "Alt/Main", Color3.fromRGB(95, 60, 120), function() applyPreset("AltToMain") end)
	createButton(controls, "Low PC", Color3.fromRGB(60, 90, 90), function() applyPreset("LowPC") end)
	createButton(controls, "Pause/Run", Color3.fromRGB(120, 55, 55), toggleRunning)

	local statsOrder = {
		{ name = "Harvested", text = "Harvested" },
		{ name = "Sold", text = "Sold" },
		{ name = "Planted", text = "Planted" },
		{ name = "Shoveled", text = "Shoveled" },
		{ name = "Expansions", text = "Expansions" },
		{ name = "SeedsBought", text = "Seeds Bought" },
		{ name = "GearBought", text = "Gear Bought" },
		{ name = "PetsBought", text = "Pets Bought" },
		{ name = "Mailed", text = "Items Mailed" },
	}

	for i, entry in ipairs(statsOrder) do
		labels[entry.name] = buildStatEntry(content, entry.text, entry.name)
	end

	local sep = Instance.new("Frame")
	sep.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	sep.BorderSizePixel = 0
	sep.Size = UDim2.new(1, 0, 0, 1)
	sep.Parent = content

	local runtimeRow = Instance.new("Frame")
	runtimeRow.BackgroundTransparency = 1
	runtimeRow.Size = UDim2.new(1, 0, 0, 18)
	runtimeRow.Parent = content

	local runtimeLbl = createTextLabel({
		Text = "Runtime",
		Size = UDim2.new(0.55, 0, 1, 0),
		TextColor3 = Color3.fromRGB(170, 170, 170),
		TextSize = 13,
		Parent = runtimeRow,
	})

	local runtimeVal = createTextLabel({
		Name = "RuntimeValue",
		Text = "0s",
		Size = UDim2.new(0.45, 0, 1, 0),
		Position = UDim2.new(0.55, 0, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 13,
		Parent = runtimeRow,
	})

	labels.Runtime = runtimeVal

	local moneyRow = Instance.new("Frame")
	moneyRow.BackgroundTransparency = 1
	moneyRow.Size = UDim2.new(1, 0, 0, 18)
	moneyRow.Parent = content

	createTextLabel({
		Text = "Money",
		Size = UDim2.new(0.55, 0, 1, 0),
		TextColor3 = Color3.fromRGB(170, 170, 170),
		TextSize = 13,
		Parent = moneyRow,
	})

	labels.Money = createTextLabel({
		Name = "MoneyValue",
		Text = "$0",
		Size = UDim2.new(0.45, 0, 1, 0),
		Position = UDim2.new(0.55, 0, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = Color3.fromRGB(100, 255, 130),
		TextSize = 13,
		Parent = moneyRow,
	})

	local invRow = Instance.new("Frame")
	invRow.BackgroundTransparency = 1
	invRow.Size = UDim2.new(1, 0, 0, 18)
	invRow.Parent = content

	createTextLabel({
		Text = "Inventory",
		Size = UDim2.new(0.55, 0, 1, 0),
		TextColor3 = Color3.fromRGB(170, 170, 170),
		TextSize = 13,
		Parent = invRow,
	})

	labels.Inventory = createTextLabel({
		Name = "InventoryValue",
		Text = "0 / 60",
		Size = UDim2.new(0.45, 0, 1, 0),
		Position = UDim2.new(0.55, 0, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 13,
		Parent = invRow,
	})

	local hintLabel = createTextLabel({
		Name = "Hint",
		Text = "F4 to toggle",
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 0, 1, -18),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = Color3.fromRGB(80, 80, 90),
		TextSize = 10,
		Parent = panel,
	})

	consoleFrame = Instance.new("Frame")
	consoleFrame.Name = "Console"
	consoleFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	consoleFrame.BackgroundTransparency = 0.1
	consoleFrame.BorderSizePixel = 0
	consoleFrame.Size = UDim2.new(0, 380, 0, 340)
	consoleFrame.Position = UDim2.new(1, -395, 0, 470)
	consoleFrame.Parent = overlay

	local consoleCorner = Instance.new("UICorner")
	consoleCorner.CornerRadius = UDim.new(0, 8)
	consoleCorner.Parent = consoleFrame

	local consoleStroke = Instance.new("UIStroke")
	consoleStroke.Color = Color3.fromRGB(45, 45, 55)
	consoleStroke.Thickness = 1
	consoleStroke.Parent = consoleFrame

	local consoleTitle = createTextLabel({
		Name = "ConsoleTitle",
		Text = "CONSOLE FEED",
		TextColor3 = Color3.fromRGB(255, 200, 80),
		TextSize = 13,
		Size = UDim2.new(1, -16, 0, 20),
		Position = UDim2.new(0, 8, 0, 6),
		Font = Enum.Font.RobotoMono,
		Parent = consoleFrame,
	})

	local consoleDivider = Instance.new("Frame")
	consoleDivider.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	consoleDivider.BorderSizePixel = 0
	consoleDivider.Size = UDim2.new(1, -16, 0, 1)
	consoleDivider.Position = UDim2.new(0, 8, 0, 28)
	consoleDivider.Parent = consoleFrame

	local scrolling = Instance.new("ScrollingFrame")
	scrolling.Name = "ScrollArea"
	scrolling.BackgroundTransparency = 1
	scrolling.BorderSizePixel = 0
	scrolling.ScrollBarThickness = 4
	scrolling.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
	scrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrolling.Size = UDim2.new(1, -16, 1, -38)
	scrolling.Position = UDim2.new(0, 8, 0, 34)
	scrolling.Parent = consoleFrame

	local scrollList = Instance.new("UIListLayout")
	scrollList.SortOrder = Enum.SortOrder.LayoutOrder
	scrollList.Padding = UDim.new(0, 1)
	scrollList.Parent = scrolling

	consoleLines = {}

	overlay.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

function Stats.ConsoleLog(tag, message)
	if not consoleFrame then return end
	local scrolling = consoleFrame:FindFirstChild("ScrollArea", true)
	if not scrolling then return end

	local line = createConsoleLine(tag, message)
	line.Parent = scrolling

	table.insert(consoleLines, line)

	while #consoleLines > MAX_CONSOLE_LINES do
		local oldest = table.remove(consoleLines, 1)
		if oldest and oldest.Parent then
			oldest:Destroy()
		end
	end

	scrolling.CanvasPosition = Vector2.new(0, math.max(0, scrolling.AbsoluteCanvasSize.Y - scrolling.AbsoluteWindowSize.Y))
end

function Stats.UpdateOverlay()
	if not overlay or not _GAG then return end
	if not visible then return end

	local stats = _GAG.Stats or {}
	local elapsed = os.clock() - startTime

	if labels.Status then
		local farming = (_GAG.Running ~= false) and (_GAG.State == nil or _GAG.State.Running ~= false)
		if farming then
			labels.Status.Text = "ACTIVE"
			labels.Status.TextColor3 = Color3.fromRGB(100, 255, 130)
		else
			labels.Status.Text = "PAUSED"
			labels.Status.TextColor3 = Color3.fromRGB(255, 180, 80)
		end
	end

	if labels.Harvested then labels.Harvested.Text = Stats.FormatNumber(stats.Harvested or 0) end
	if labels.Sold then labels.Sold.Text = Stats.FormatNumber(stats.Sold or 0) end
	if labels.Planted then labels.Planted.Text = Stats.FormatNumber(stats.Planted or 0) end
	if labels.Shoveled then labels.Shoveled.Text = Stats.FormatNumber(stats.Shoveled or 0) end
	if labels.Expansions then labels.Expansions.Text = Stats.FormatNumber(stats.Expansions or 0) end
	if labels.SeedsBought then labels.SeedsBought.Text = Stats.FormatNumber(stats.SeedsBought or 0) end
	if labels.GearBought then labels.GearBought.Text = Stats.FormatNumber(stats.GearBought or 0) end
	if labels.PetsBought then labels.PetsBought.Text = Stats.FormatNumber(stats.PetsBought or 0) end
	if labels.Mailed then labels.Mailed.Text = Stats.FormatNumber(stats.Mailed or 0) end

	if labels.Runtime then labels.Runtime.Text = Stats.FormatDuration(elapsed) end

	if labels.Money then labels.Money.Text = "$" .. Stats.FormatNumber(getMoney()) end

	if labels.Inventory then
		local count, cap = getInventoryInfo()
		labels.Inventory.Text = count .. " / " .. cap
		if count >= cap then
			labels.Inventory.TextColor3 = Color3.fromRGB(255, 100, 100)
		elseif count >= cap * 0.8 then
			labels.Inventory.TextColor3 = Color3.fromRGB(255, 220, 80)
		else
			labels.Inventory.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end
end

function Stats.Toggle()
	visible = not visible
	if overlay then
		local panel = overlay:FindFirstChild("Panel")
		if panel then panel.Visible = visible end
	end
end

function Stats.SetConsole(enabled)
	consoleVisible = enabled
	if consoleFrame then
		consoleFrame.Visible = enabled
	end
end

function Stats.Start(GAG)
	_GAG = GAG
	startTime = os.clock()

	Stats.CreateOverlay()

	if inputConnection then inputConnection:Disconnect() end
	inputConnection = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == TOGGLE_KEY then
			Stats.Toggle()
		end
	end)

	if updateConnection then updateConnection:Disconnect() end
	local accumulator = 0
	updateConnection = RunService.Heartbeat:Connect(function(dt)
		accumulator = accumulator + dt
		if accumulator >= UPDATE_INTERVAL then
			accumulator = 0
			Stats.UpdateOverlay()
		end
	end)

	Stats.ConsoleLog("INFO", "Stats overlay started")
end

function Stats.Init(GAG)
	_GAG = GAG
	if not GAG.Stats then
		GAG.Stats = {
			Harvested = 0,
			Sold = 0,
			Planted = 0,
			Shoveled = 0,
			Expansions = 0,
			SeedsBought = 0,
			GearBought = 0,
			PetsBought = 0,
			Mailed = 0,
		}
	end
end

return Stats
