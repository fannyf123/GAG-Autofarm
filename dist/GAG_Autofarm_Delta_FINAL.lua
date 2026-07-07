-- GAG Autofarm Delta build based on user-tested WalkyHub baseline.
-- Optional config before loadstring:
-- _G.GAGConfig = { Preset = "Balanced" } -- Starter, Balanced, Rich, AltToMain, LowPC

-- USED AI TO MAKE IT BETTER
-- CREDITS TO CLAUE & SOMEONES SRC
-- USED AI TO MAKE IT WORK BETTER DO NOT HATE
-- YALL CAN TAKE THE SRC AND MAKE IT BETTER



local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local sharedEnv = type(getgenv) == "function" and getgenv() or _G
sharedEnv.WalkyUISession = (sharedEnv.WalkyUISession or 0) + 1
local SCRIPT_SESSION = sharedEnv.WalkyUISession

local function isSessionActive()
	return sharedEnv.WalkyUISession == SCRIPT_SESSION
end

local KrassUI = {}

local DEFAULT_THEME = {
	Background = Color3.fromRGB(9, 11, 16),
	Panel = Color3.fromRGB(18, 21, 29),
	Panel2 = Color3.fromRGB(25, 29, 39),
	Panel3 = Color3.fromRGB(34, 39, 52),
	Text = Color3.fromRGB(245, 248, 252),
	Muted = Color3.fromRGB(145, 154, 170),
	Accent = Color3.fromRGB(145, 160, 255),
	Accent2 = Color3.fromRGB(95, 105, 255),
	Danger = Color3.fromRGB(255, 75, 95),
	Stroke = Color3.fromRGB(57, 65, 82),
	DarkText = Color3.fromRGB(5, 10, 13),
	Shadow = Color3.fromRGB(0, 0, 0),
}

local THEME_PRESETS = {
	Black = {
		Background = Color3.fromRGB(8, 9, 13),
		Panel = Color3.fromRGB(17, 19, 26),
		Panel2 = Color3.fromRGB(24, 27, 36),
		Panel3 = Color3.fromRGB(34, 38, 50),
		Text = Color3.fromRGB(244, 246, 250),
		Muted = Color3.fromRGB(145, 153, 166),
		Accent = Color3.fromRGB(145, 160, 255),
		Accent2 = Color3.fromRGB(95, 105, 255),
		Danger = Color3.fromRGB(255, 75, 95),
		Stroke = Color3.fromRGB(58, 64, 80),
		DarkText = Color3.fromRGB(5, 7, 10),
		Shadow = Color3.fromRGB(0, 0, 0),
	},
	Pink = {
		Background = Color3.fromRGB(18, 10, 18),
		Panel = Color3.fromRGB(29, 17, 31),
		Panel2 = Color3.fromRGB(42, 24, 45),
		Panel3 = Color3.fromRGB(57, 31, 61),
		Text = Color3.fromRGB(255, 244, 252),
		Muted = Color3.fromRGB(211, 162, 199),
		Accent = Color3.fromRGB(255, 95, 190),
		Accent2 = Color3.fromRGB(195, 80, 255),
		Danger = Color3.fromRGB(255, 77, 119),
		Stroke = Color3.fromRGB(90, 52, 91),
		DarkText = Color3.fromRGB(24, 5, 18),
		Shadow = Color3.fromRGB(0, 0, 0),
	},
	Red = {
		Background = Color3.fromRGB(18, 9, 10),
		Panel = Color3.fromRGB(31, 17, 18),
		Panel2 = Color3.fromRGB(43, 23, 25),
		Panel3 = Color3.fromRGB(61, 31, 34),
		Text = Color3.fromRGB(255, 245, 245),
		Muted = Color3.fromRGB(216, 157, 159),
		Accent = Color3.fromRGB(255, 70, 82),
		Accent2 = Color3.fromRGB(255, 135, 68),
		Danger = Color3.fromRGB(255, 58, 72),
		Stroke = Color3.fromRGB(93, 50, 53),
		DarkText = Color3.fromRGB(25, 4, 6),
		Shadow = Color3.fromRGB(0, 0, 0),
	},
	White = {
		Background = Color3.fromRGB(242, 244, 248),
		Panel = Color3.fromRGB(255, 255, 255),
		Panel2 = Color3.fromRGB(232, 236, 244),
		Panel3 = Color3.fromRGB(216, 222, 234),
		Text = Color3.fromRGB(22, 26, 34),
		Muted = Color3.fromRGB(94, 105, 123),
		Accent = Color3.fromRGB(75, 95, 245),
		Accent2 = Color3.fromRGB(150, 85, 255),
		Danger = Color3.fromRGB(230, 55, 73),
		Stroke = Color3.fromRGB(190, 198, 214),
		DarkText = Color3.fromRGB(255, 255, 255),
		Shadow = Color3.fromRGB(0, 0, 0),
	},
}

KrassUI.Themes = THEME_PRESETS

local function mergeTheme(overrides)
	local theme = {}
	for key, value in pairs(DEFAULT_THEME) do
		theme[key] = value
	end
	for key, value in pairs(overrides or {}) do
		theme[key] = value
	end
	return theme
end

local function new(className, props, children)
	local instance = Instance.new(className)
	for key, value in pairs(props or {}) do
		instance[key] = value
	end
	for _, child in ipairs(children or {}) do
		child.Parent = instance
	end
	return instance
end

local function tween(instance, goal, time, style, direction)
	local info = TweenInfo.new(
		time or 0.18,
		style or Enum.EasingStyle.Quint,
		direction or Enum.EasingDirection.Out
	)
	local active = TweenService:Create(instance, info, goal)
	active:Play()
	return active
end

local function corner(radius)
	return new("UICorner", {
		CornerRadius = UDim.new(0, radius),
	})
end

local function stroke(color, thickness, transparency)
	return new("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
	})
end

local function padding(value)
	return new("UIPadding", {
		PaddingBottom = UDim.new(0, value),
		PaddingLeft = UDim.new(0, value),
		PaddingRight = UDim.new(0, value),
		PaddingTop = UDim.new(0, value),
	})
end

local function list(spacing)
	return new("UIListLayout", {
		Padding = UDim.new(0, spacing),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

local function makeLabel(parent, text, size, color, bold)
	return new("TextLabel", {
		BackgroundTransparency = 1,
		Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
		Parent = parent,
		Text = text,
		TextColor3 = color,
		TextSize = size,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
end

local function makeButton(parent, text, color, textColor)
	return new("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Font = Enum.Font.GothamSemibold,
		Parent = parent,
		Text = text or "",
		TextColor3 = textColor,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
end

local function gradient(parent, colorA, colorB, rotation)
	local item = new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, colorA),
			ColorSequenceKeypoint.new(1, colorB),
		}),
		Rotation = rotation or 0,
		Parent = parent,
	})
	return item
end

local function animateGradient(item, speed)
	task.spawn(function()
		while item.Parent do
			item.Rotation = 0
			tween(item, { Rotation = 360 }, speed or 5, Enum.EasingStyle.Linear)
			task.wait(speed or 5)
		end
	end)
end

local function ripple(button, x, y, color)
	x = x or (button.AbsolutePosition.X + button.AbsoluteSize.X / 2)
	y = y or (button.AbsolutePosition.Y + button.AbsoluteSize.Y / 2)
	local localX = x - button.AbsolutePosition.X
	local localY = y - button.AbsolutePosition.Y
	local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 1.8

	local circle = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = color,
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		Parent = button,
		Position = UDim2.fromOffset(localX, localY),
		Size = UDim2.fromOffset(0, 0),
		ZIndex = button.ZIndex + 8,
	})
	corner(999).Parent = circle

	tween(circle, {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(maxSize, maxSize),
	}, 0.42, Enum.EasingStyle.Quint).Completed:Once(function()
		circle:Destroy()
	end)
end

local function pressable(hit, visual, border, theme, callback)
	local normal = visual.BackgroundColor3
	local hover = theme.Panel3
	local visualScale = visual:FindFirstChildOfClass("UIScale")

	hit.MouseEnter:Connect(function()
		tween(visual, { BackgroundColor3 = hover }, 0.15)
		if border then
			tween(border, {
				Color = theme.Accent,
				Transparency = 0.25,
			}, 0.15)
		end
	end)

	hit.MouseLeave:Connect(function()
		tween(visual, { BackgroundColor3 = normal }, 0.15)
		if visualScale then
			tween(visualScale, { Scale = 1 }, 0.18, Enum.EasingStyle.Back)
		end
		if border then
			tween(border, {
				Color = theme.Stroke,
				Transparency = 0.45,
			}, 0.15)
		end
	end)

	hit.MouseButton1Down:Connect(function(x, y)
		if visualScale then
			tween(visualScale, { Scale = 0.985 }, 0.08, Enum.EasingStyle.Quad)
		end
		ripple(hit, x, y, theme.Accent)
	end)

	hit.MouseButton1Up:Connect(function()
		if visualScale then
			tween(visualScale, { Scale = 1 }, 0.24, Enum.EasingStyle.Back)
		end
	end)

	hit.MouseButton1Click:Connect(function()
		if callback then
			task.spawn(callback)
		end
	end)
end

local function makeDraggable(frame, handle, tracker)
	local dragging = false
	local dragStart = nil
	local startPos = nil

	local function connect(signal, callback)
		if tracker and tracker._connect then
			return tracker:_connect(signal, callback)
		end
		return signal:Connect(callback)
	end

	connect(handle.InputBegan, function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		dragging = true
		dragStart = input.Position
		startPos = frame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end)

	connect(UserInputService.InputChanged, function(input)
		if not dragging or not dragStart or not startPos then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end)
end

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

local Control = {}
Control.__index = Control

function Window:_connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(self.Connections, connection)
	return connection
end

function KrassUI.new(config)
	config = config or {}
	local selectedTheme = nil
	if type(config.Theme) == "string" then
		selectedTheme = THEME_PRESETS[config.Theme]
	elseif type(config.ThemeName) == "string" then
		selectedTheme = THEME_PRESETS[config.ThemeName]
	end
	local theme = mergeTheme(selectedTheme or (type(config.Theme) == "table" and config.Theme or nil))
	theme.Accent = config.Accent or theme.Accent
	theme.Accent2 = config.Accent2 or theme.Accent2

	local guiName = config.GuiName or "WalkyUI_Tycoon"
	local oldGui = PlayerGui:FindFirstChild(guiName)
	if oldGui and config.ClearOld ~= false then
		oldGui:Destroy()
	end
	local oldBlur = Lighting:FindFirstChild(guiName .. "_Blur")
	if oldBlur and config.ClearOld ~= false then
		oldBlur:Destroy()
	end

	local gui = new("ScreenGui", {
		DisplayOrder = config.DisplayOrder or 999,
		IgnoreGuiInset = true,
		Name = guiName,
		Parent = PlayerGui,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})

	local blur = nil
	local blurTarget = config.BlurSize or 12
	if config.Blur ~= false then
		blur = Lighting:FindFirstChild(guiName .. "_Blur")
		if not blur then
			blur = new("BlurEffect", {
				Name = guiName .. "_Blur",
				Size = 0,
				Parent = Lighting,
			})
		end
	end

	local baseSize = config.Size or UDim2.fromOffset(690, 450)
	local holder = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Parent = gui,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = baseSize,
	})

	local scale = new("UIScale", {
		Parent = holder,
		Scale = 0.84,
	})

	local shadow = new("ImageLabel", {
		BackgroundTransparency = 1,
		Image = "rbxassetid://1316045217",
		ImageColor3 = theme.Shadow or Color3.fromRGB(0, 0, 0),
		ImageTransparency = 1,
		Parent = holder,
		Position = UDim2.fromOffset(-48, -48),
		ScaleType = Enum.ScaleType.Slice,
		Size = UDim2.new(1, 96, 1, 96),
		SliceCenter = Rect.new(10, 10, 118, 118),
		Visible = false,
		ZIndex = 0,
	})

	local root = new("Frame", {
		BackgroundColor3 = theme.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = holder,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
	})
	corner(12).Parent = root
	local rootStroke = stroke(theme.Stroke, 1, 0.12)
	rootStroke.Parent = root

	local accentRail = new("Frame", {
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Parent = root,
		Size = UDim2.new(1, 0, 0, 3),
		ZIndex = 4,
	})
	local railGradient = gradient(accentRail, theme.Accent, theme.Accent2, 0)
	animateGradient(railGradient, 4)

	local shine = new("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.88,
		BorderSizePixel = 0,
		Parent = root,
		Position = UDim2.new(-0.35, 0, 0, 0),
		Rotation = 16,
		Size = UDim2.new(0.18, 0, 1.35, 0),
		ZIndex = 6,
	})
	gradient(shine, Color3.fromRGB(255, 255, 255), theme.Accent, 90)
	task.spawn(function()
		while shine.Parent do
			shine.Position = UDim2.new(-0.35, 0, -0.18, 0)
			shine.BackgroundTransparency = 0.92
			tween(shine, {
				BackgroundTransparency = 1,
				Position = UDim2.new(1.18, 0, -0.18, 0),
			}, 1.15, Enum.EasingStyle.Quint)
			task.wait(4.4)
		end
	end)

	local topbar = new("Frame", {
		BackgroundColor3 = theme.Panel,
		BorderSizePixel = 0,
		Parent = root,
		Position = UDim2.fromOffset(0, 3),
		Size = UDim2.new(1, 0, 0, 54),
		ZIndex = 3,
	})

	local title = makeLabel(topbar, config.Name or "Krass Tycoon Hub", 17, theme.Text, true)
	title.Position = UDim2.fromOffset(18, 7)
	title.Size = UDim2.new(1, -160, 0, 24)
	title.ZIndex = 4

	local subtitle = makeLabel(topbar, config.Subtitle or "TYCOON AUTOFARM", 11, theme.Muted, false)
	subtitle.Position = UDim2.fromOffset(18, 29)
	subtitle.Size = UDim2.new(1, -160, 0, 18)
	subtitle.ZIndex = 4

	local close = makeButton(topbar, "X", theme.Panel2, theme.Muted)
	close.Position = UDim2.new(1, -44, 0, 11)
	close.Size = UDim2.fromOffset(32, 32)
	close.ZIndex = 5
	corner(8).Parent = close

	local minimize = makeButton(topbar, "-", theme.Panel2, theme.Muted)
	minimize.Position = UDim2.new(1, -82, 0, 11)
	minimize.Size = UDim2.fromOffset(32, 32)
	minimize.ZIndex = 5
	corner(8).Parent = minimize

	local sidebar = new("ScrollingFrame", {
		Active = true,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = theme.Panel,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, 0),
		ClipsDescendants = true,
		ElasticBehavior = Enum.ElasticBehavior.Always,
		Parent = root,
		Position = UDim2.fromOffset(0, 57),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarImageColor3 = theme.Accent,
		ScrollBarThickness = 8,
		Size = UDim2.new(0, 166, 1, -57),
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
		ZIndex = 3,
	})
	padding(12).Parent = sidebar
	list(8).Parent = sidebar

	local pageHolder = new("Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = root,
		Position = UDim2.fromOffset(166, 57),
		Size = UDim2.new(1, -166, 1, -57),
		ZIndex = 3,
	})

	local toastHolder = new("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Parent = gui,
		Position = UDim2.new(1, -18, 0, 18),
		Size = UDim2.fromOffset(320, 330),
		ZIndex = 50,
	})
	list(9).Parent = toastHolder

	local openButton = new("ImageButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		AutoButtonColor = false,
		BackgroundColor3 = theme.Panel,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Image = "",
		Parent = gui,
		Position = UDim2.new(1, -14, 0.5, 0),
		ScaleType = Enum.ScaleType.Crop,
		Size = UDim2.fromOffset(58, 58),
		Visible = false,
		ZIndex = 61,
	})
	corner(999).Parent = openButton
	local openButtonStroke = stroke(theme.Accent, 2, 0.05)
	openButtonStroke.Parent = openButton
	local openButtonScale = new("UIScale", {
		Parent = openButton,
		Scale = 0.72,
	})
	local openButtonFallback = makeLabel(openButton, "K", 22, theme.Text, true)
	openButtonFallback.Size = UDim2.fromScale(1, 1)
	openButtonFallback.TextXAlignment = Enum.TextXAlignment.Center
	openButtonFallback.ZIndex = 62
	local openButtonGloss = new("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.88,
		BorderSizePixel = 0,
		Parent = openButton,
		Position = UDim2.fromScale(-0.15, -0.1),
		Rotation = 18,
		Size = UDim2.fromScale(0.28, 1.25),
		ZIndex = 63,
	})
	gradient(openButtonGloss, Color3.fromRGB(255, 255, 255), theme.Accent, 90)

	local self = setmetatable({
		Blur = blur,
		BlurTarget = blurTarget,
		Gui = gui,
		Holder = holder,
		Root = root,
		RootStroke = rootStroke,
		Scale = scale,
		Shadow = shadow,
		Topbar = topbar,
		Title = title,
		Subtitle = subtitle,
		CloseButton = close,
		MinimizeButton = minimize,
		Sidebar = sidebar,
		PageHolder = pageHolder,
		BaseSize = baseSize,
		OpenButton = openButton,
		OpenButtonScale = openButtonScale,
		OpenButtonStroke = openButtonStroke,
		OpenButtonFallback = openButtonFallback,
		OpenButtonGloss = openButtonGloss,
		ToastHolder = toastHolder,
		Theme = theme,
		Tabs = {},
		CurrentTab = nil,
		IsCompact = false,
		SidebarWidth = 166,
		TabButtonHeight = 40,
		TabTextSize = 13,
		ToggleKey = config.ToggleKey or Enum.KeyCode.LeftShift,
		Visible = true,
		AnimationToken = 0,
		Connections = {},
		OnClose = config.OnClose,
	}, Window)

	makeDraggable(holder, topbar, self)

	self:_connect(close.MouseEnter, function()
		tween(close, { BackgroundColor3 = theme.Danger, TextColor3 = Color3.new(1, 1, 1) }, 0.14)
	end)
	self:_connect(close.MouseLeave, function()
		tween(close, { BackgroundColor3 = theme.Panel2, TextColor3 = theme.Muted }, 0.14)
	end)
	self:_connect(close.MouseButton1Click, function()
		if self.OnClose then
			pcall(self.OnClose)
		end
		self:Destroy()
	end)

	self:_connect(minimize.MouseEnter, function()
		tween(minimize, { BackgroundColor3 = theme.Panel3, TextColor3 = theme.Text }, 0.14)
	end)
	self:_connect(minimize.MouseLeave, function()
		tween(minimize, { BackgroundColor3 = theme.Panel2, TextColor3 = theme.Muted }, 0.14)
	end)
	self:_connect(minimize.MouseButton1Click, function()
		self:SetVisible(false)
	end)

	self:_connect(openButton.MouseEnter, function()
		tween(openButton, { BackgroundColor3 = theme.Panel3 }, 0.14)
		tween(openButtonScale, { Scale = 1.06 }, 0.2, Enum.EasingStyle.Back)
		tween(openButtonStroke, { Transparency = 0, Thickness = 3 }, 0.14)
	end)
	self:_connect(openButton.MouseLeave, function()
		tween(openButton, { BackgroundColor3 = theme.Panel }, 0.14)
		tween(openButtonScale, { Scale = 1 }, 0.18, Enum.EasingStyle.Back)
		tween(openButtonStroke, { Transparency = 0.05, Thickness = 2 }, 0.14)
	end)
	self:_connect(openButton.MouseButton1Down, function()
		tween(openButtonScale, { Scale = 0.92 }, 0.08, Enum.EasingStyle.Quad)
	end)
	self:_connect(openButton.MouseButton1Up, function()
		tween(openButtonScale, { Scale = 1 }, 0.2, Enum.EasingStyle.Back)
	end)
	self:_connect(openButton.MouseButton1Click, function()
		self:SetVisible(true)
	end)

	holder.Visible = true
	holder.Position = UDim2.fromScale(0.5, 0.5)
	root.Rotation = -4
	root.BackgroundTransparency = 0.16
	rootStroke.Transparency = 0.85
	tween(root, { BackgroundTransparency = 0, Rotation = 0 }, 0.46, Enum.EasingStyle.Back)
	tween(rootStroke, { Transparency = 0.12, Color = theme.Accent }, 0.22, Enum.EasingStyle.Quint).Completed:Once(function()
		if rootStroke.Parent then
			tween(rootStroke, { Color = theme.Stroke }, 0.32, Enum.EasingStyle.Quint)
		end
	end)
	tween(scale, { Scale = 1 }, 0.5, Enum.EasingStyle.Back)
	tween(shadow, { ImageTransparency = 1 }, 0.18, Enum.EasingStyle.Quint)
	if blur then
		tween(blur, { Size = blurTarget }, 0.28, Enum.EasingStyle.Quint)
	end

	return self
end

function Window:GetViewportSize()
	local camera = Workspace.CurrentCamera
	if camera and camera.ViewportSize.X > 0 and camera.ViewportSize.Y > 0 then
		return camera.ViewportSize
	end
	if self.Gui and self.Gui.AbsoluteSize.X > 0 and self.Gui.AbsoluteSize.Y > 0 then
		return self.Gui.AbsoluteSize
	end
	return Vector2.new(1280, 720)
end

function Window:ApplyResponsiveLayout(skipAnimation)
	local viewport = self:GetViewportSize()
	local isTouch = UserInputService.TouchEnabled
	local compact = viewport.X < 760 or viewport.Y < 540 or (isTouch and viewport.X < 930)
	local sideWidth = compact and 118 or 166
	local windowWidth = compact and math.min(690, math.max(290, viewport.X - 22)) or self.BaseSize.X.Offset
	local windowHeight = compact and math.min(520, math.max(340, viewport.Y - 72)) or self.BaseSize.Y.Offset
	local topbarHeight = compact and 52 or 54
	local contentTop = topbarHeight + 3
	local sidebarPadding = compact and 8 or 12
	local tabHeight = compact and 36 or 40
	local tabTextSize = compact and 11 or 13
	local pagePadding = compact and 9 or 14
	local titleSize = compact and 15 or 17
	local subtitleSize = compact and 10 or 11

	self.IsCompact = compact
	self.SidebarWidth = sideWidth
	self.TabButtonHeight = tabHeight
	self.TabTextSize = tabTextSize

	local function applyOrTween(instance, goal, time)
		if skipAnimation then
			for key, value in pairs(goal) do
				instance[key] = value
			end
		else
			tween(instance, goal, time or 0.18)
		end
	end

	applyOrTween(self.Holder, {
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(windowWidth, windowHeight),
	}, 0.2)
	self.Topbar.Size = UDim2.new(1, 0, 0, topbarHeight)
	self.Title.Position = UDim2.fromOffset(compact and 12 or 18, compact and 6 or 7)
	self.Title.Size = UDim2.new(1, compact and -112 or -160, 0, 23)
	self.Title.TextSize = titleSize
	self.Subtitle.Position = UDim2.fromOffset(compact and 12 or 18, compact and 28 or 29)
	self.Subtitle.Size = UDim2.new(1, compact and -112 or -160, 0, 18)
	self.Subtitle.TextSize = subtitleSize

	local buttonSize = compact and 34 or 32
	local buttonTop = compact and 9 or 11
	self.CloseButton.Position = UDim2.new(1, compact and -42 or -44, 0, buttonTop)
	self.CloseButton.Size = UDim2.fromOffset(buttonSize, buttonSize)
	self.MinimizeButton.Position = UDim2.new(1, compact and -82 or -82, 0, buttonTop)
	self.MinimizeButton.Size = UDim2.fromOffset(buttonSize, buttonSize)

	self.Sidebar.Position = UDim2.fromOffset(0, contentTop)
	self.Sidebar.Size = UDim2.new(0, sideWidth, 1, -contentTop)
	self.Sidebar.ScrollBarThickness = compact and 10 or 8
	local sidebarPad = self.Sidebar:FindFirstChildOfClass("UIPadding")
	if sidebarPad then
		sidebarPad.PaddingBottom = UDim.new(0, sidebarPadding)
		sidebarPad.PaddingLeft = UDim.new(0, sidebarPadding)
		sidebarPad.PaddingRight = UDim.new(0, sidebarPadding)
		sidebarPad.PaddingTop = UDim.new(0, sidebarPadding)
	end
	local sidebarList = self.Sidebar:FindFirstChildOfClass("UIListLayout")
	if sidebarList then
		sidebarList.Padding = UDim.new(0, compact and 6 or 8)
	end

	self.PageHolder.Position = UDim2.fromOffset(sideWidth, contentTop)
	self.PageHolder.Size = UDim2.new(1, -sideWidth, 1, -contentTop)

	for _, tab in ipairs(self.Tabs or {}) do
		tab.Button.Size = UDim2.new(1, 0, 0, tabHeight)
		tab.Label.Position = UDim2.fromOffset(compact and 9 or 14, 0)
		tab.Label.Size = UDim2.new(1, compact and -14 or -24, 1, 0)
		tab.Label.TextSize = tabTextSize
		tab.Page.Position = UDim2.fromOffset(0, 0)
		tab.Page.Size = UDim2.fromScale(1, 1)
		tab.Page.ScrollBarThickness = compact and 4 or 3
		local pad = tab.Page:FindFirstChildOfClass("UIPadding")
		if pad then
			pad.PaddingBottom = UDim.new(0, pagePadding)
			pad.PaddingLeft = UDim.new(0, pagePadding)
			pad.PaddingRight = UDim.new(0, pagePadding)
			pad.PaddingTop = UDim.new(0, pagePadding)
		end
	end

	self.OpenButton.Size = UDim2.fromOffset(compact and 64 or 58, compact and 64 or 58)
	self.OpenButton.Position = UDim2.new(1, compact and -10 or -14, 0.5, 0)
	self.OpenButtonFallback.TextSize = compact and 24 or 22
	self.ToastHolder.Position = UDim2.new(1, compact and -10 or -18, 0, compact and 10 or 18)
	self.ToastHolder.Size = UDim2.fromOffset(math.max(240, math.min(320, viewport.X - 20)), 330)
end

function Window:SetVisible(visible)
	self.AnimationToken = (self.AnimationToken or 0) + 1
	local token = self.AnimationToken
	self.Visible = visible

	if visible then
		self.Holder.Visible = true
		if self.OpenButton then
			tween(self.OpenButtonScale, { Scale = 0.72 }, 0.14, Enum.EasingStyle.Quad)
			tween(self.OpenButton, { ImageTransparency = 1, BackgroundTransparency = 1 }, 0.14, Enum.EasingStyle.Quad).Completed:Once(function()
				if token == self.AnimationToken and self.Visible then
					self.OpenButton.Visible = false
					self.OpenButton.BackgroundTransparency = 0
					self.OpenButton.ImageTransparency = 0
				end
			end)
		end
		self.PageHolder.Visible = false
		if self.CurrentTab then
			self.CurrentTab.Page.Visible = true
		end
		self.Scale.Scale = 0.78
		self.Root.Rotation = -4
		self.Root.BackgroundTransparency = 0.16
		self.RootStroke.Transparency = 0.85
		tween(self.Root, { BackgroundTransparency = 0, Rotation = 0 }, 0.4, Enum.EasingStyle.Back)
		tween(self.RootStroke, { Transparency = 0.12, Color = self.Theme.Accent }, 0.2, Enum.EasingStyle.Quint).Completed:Once(function()
			if self.Visible and self.RootStroke.Parent then
				tween(self.RootStroke, { Color = self.Theme.Stroke }, 0.3, Enum.EasingStyle.Quint)
			end
		end)
		tween(self.Scale, { Scale = 1 }, 0.46, Enum.EasingStyle.Back)
		tween(self.Shadow, { ImageTransparency = 1 }, 0.16, Enum.EasingStyle.Quint)
		if self.Blur then
			tween(self.Blur, { Size = self.BlurTarget }, 0.24, Enum.EasingStyle.Quint)
		end
		task.delay(0.24, function()
			if token == self.AnimationToken and self.Visible then
				self.PageHolder.Visible = true
			end
		end)
	else
		self.PageHolder.Visible = false
		tween(self.Root, { BackgroundTransparency = 0.18, Rotation = 4 }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tween(self.RootStroke, { Transparency = 0.8 }, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tween(self.Scale, { Scale = 0.76 }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		tween(self.Shadow, { ImageTransparency = 1 }, 0.16, Enum.EasingStyle.Quad)
		if self.Blur then
			tween(self.Blur, { Size = 0 }, 0.16, Enum.EasingStyle.Quad)
		end
		task.delay(0.21, function()
			if token == self.AnimationToken and not self.Visible then
				self.Holder.Visible = false
				self.Root.Rotation = 0
				self.Root.BackgroundTransparency = 0
				self.RootStroke.Color = self.Theme.Stroke
				self.RootStroke.Transparency = 0.12
				self.Scale.Scale = 1
				self.PageHolder.Visible = true
				if self.OpenButton then
					self.OpenButton.Visible = true
					self.OpenButton.ImageTransparency = 1
					self.OpenButton.BackgroundTransparency = 1
					self.OpenButtonScale.Scale = 0.72
					tween(self.OpenButton, { ImageTransparency = 0, BackgroundTransparency = 0 }, 0.2, Enum.EasingStyle.Quint)
					tween(self.OpenButtonScale, { Scale = 1 }, 0.32, Enum.EasingStyle.Back)
				end
			end
		end)
	end
end

function Window:Destroy()
	for _, connection in ipairs(self.Connections or {}) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	self.Connections = {}
	if self.Blur then
		self.Blur:Destroy()
	end
	self.Gui:Destroy()
end

function Window:Notify(titleText, bodyText, duration)
	local theme = self.Theme
	local lifetime = duration or 3

	local toast = new("Frame", {
		BackgroundColor3 = theme.Panel,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = self.ToastHolder,
		Size = UDim2.fromOffset(320, bodyText and 82 or 58),
		ZIndex = 51,
	})
	corner(10).Parent = toast
	stroke(theme.Stroke, 1, 0.2).Parent = toast

	local scale = new("UIScale", {
		Parent = toast,
		Scale = 0.86,
	})

	local accent = new("Frame", {
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Parent = toast,
		Size = UDim2.new(0, 4, 1, 0),
		ZIndex = 52,
	})
	gradient(accent, theme.Accent, theme.Accent2, 90)

	local title = makeLabel(toast, titleText, 14, theme.Text, true)
	title.Position = UDim2.fromOffset(16, 8)
	title.Size = UDim2.new(1, -30, 0, 24)
	title.ZIndex = 53

	if bodyText then
		local body = makeLabel(toast, bodyText, 12, theme.Muted, false)
		body.Position = UDim2.fromOffset(16, 34)
		body.Size = UDim2.new(1, -30, 0, 34)
		body.TextWrapped = true
		body.TextYAlignment = Enum.TextYAlignment.Top
		body.ZIndex = 53
	end

	local progress = new("Frame", {
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Parent = toast,
		Position = UDim2.new(0, 0, 1, -3),
		Size = UDim2.new(1, 0, 0, 3),
		ZIndex = 52,
	})
	gradient(progress, theme.Accent, theme.Accent2, 0)

	tween(scale, { Scale = 1 }, 0.32, Enum.EasingStyle.Back)
	tween(progress, { Size = UDim2.new(0, 0, 0, 3) }, lifetime, Enum.EasingStyle.Linear)

	task.delay(lifetime, function()
		if not toast.Parent then
			return
		end
		tween(scale, { Scale = 0.86 }, 0.18, Enum.EasingStyle.Quad)
		tween(toast, { BackgroundTransparency = 1 }, 0.18).Completed:Once(function()
			toast:Destroy()
		end)
	end)
end

function Window:Tab(name)
	local theme = self.Theme

	local page = new("ScrollingFrame", {
		Active = true,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, 0),
		ClipsDescendants = true,
		Parent = self.PageHolder,
		Position = UDim2.fromOffset(0, 0),
		ScrollBarImageColor3 = theme.Accent,
		ScrollBarThickness = 3,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 4,
	})
	padding(14).Parent = page
	list(12).Parent = page
	local pageScale = new("UIScale", {
		Parent = page,
		Scale = 1,
	})

	local button = makeButton(self.Sidebar, "", theme.Panel2, theme.Muted)
	button.Size = UDim2.new(1, 0, 0, 40)
	button.Text = ""
	button.ZIndex = 5
	corner(9).Parent = button
	local buttonStroke = stroke(theme.Stroke, 1, 0.5)
	buttonStroke.Parent = button
	local buttonScale = new("UIScale", {
		Parent = button,
		Scale = 1,
	})

	local activeRail = new("Frame", {
		BackgroundColor3 = theme.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = button,
		Position = UDim2.fromOffset(0, 20),
		Size = UDim2.fromOffset(3, 0),
		Visible = true,
		ZIndex = 6,
	})
	corner(4).Parent = activeRail
	gradient(activeRail, theme.Accent, theme.Accent2, 90)

	local text = makeLabel(button, name, 13, theme.Muted, true)
	text.Position = UDim2.fromOffset(14, 0)
	text.Size = UDim2.new(1, -24, 1, 0)
	text.ZIndex = 6

	local tab = setmetatable({
		Button = button,
		ButtonScale = buttonScale,
		ButtonStroke = buttonStroke,
		Label = text,
		Name = name,
		Page = page,
		PageScale = pageScale,
		Rail = activeRail,
		Sections = {},
		Window = self,
	}, Tab)

	table.insert(self.Tabs, tab)
	self:ApplyResponsiveLayout(true)

	button.MouseButton1Click:Connect(function()
		self:SelectTab(tab)
	end)

	button.MouseEnter:Connect(function()
		if self.CurrentTab ~= tab then
			tween(button, { BackgroundColor3 = theme.Panel3 }, 0.14)
			tween(buttonStroke, { Transparency = 0.25 }, 0.14)
		end
	end)

	button.MouseLeave:Connect(function()
		if self.CurrentTab ~= tab then
			tween(button, { BackgroundColor3 = theme.Panel2 }, 0.14)
			tween(buttonStroke, { Transparency = 0.5 }, 0.14)
		end
	end)

	if not self.CurrentTab then
		self:SelectTab(tab)
	end

	return tab
end

function Window:SelectTab(tab)
	local theme = self.Theme

	for _, item in ipairs(self.Tabs) do
		local active = item == tab
		item.Page.Visible = active
		tween(item.Button, {
			BackgroundColor3 = active and theme.Accent or theme.Panel2,
		}, active and 0.2 or 0.16, Enum.EasingStyle.Quint)
		tween(item.ButtonScale, {
			Scale = active and 1.025 or 1,
		}, active and 0.28 or 0.16, active and Enum.EasingStyle.Back or Enum.EasingStyle.Quad)
		tween(item.ButtonStroke, {
			Color = active and theme.Accent or theme.Stroke,
			Transparency = active and 0.1 or 0.5,
		}, 0.18, Enum.EasingStyle.Quint)
		tween(item.Label, {
			TextColor3 = active and theme.DarkText or theme.Muted,
		}, 0.18, Enum.EasingStyle.Quint)
		tween(item.Rail, {
			BackgroundTransparency = active and 0 or 1,
			Position = active and UDim2.fromOffset(0, 9) or UDim2.fromOffset(0, 20),
			Size = active and UDim2.fromOffset(3, 22) or UDim2.fromOffset(3, 0),
		}, active and 0.26 or 0.14, Enum.EasingStyle.Quint)
	end

	tab.Page.CanvasPosition = Vector2.new(0, 0)
	local startOffset = self.IsCompact and 8 or 18
	tab.Page.Position = UDim2.fromOffset(startOffset, 0)
	tab.Page.Size = UDim2.new(1, -startOffset, 1, 0)
	tab.PageScale.Scale = 0.985
	tween(tab.Page, {
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromScale(1, 1),
	}, 0.32, Enum.EasingStyle.Quint)
	tween(tab.PageScale, {
		Scale = 1,
	}, 0.34, Enum.EasingStyle.Back)

	self.CurrentTab = tab
end

function Tab:Section(titleText)
	local theme = self.Window.Theme

	local frame = new("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = theme.Panel,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = self.Page,
		Size = UDim2.new(1, 0, 0, 0),
		ZIndex = 4,
	})
	corner(10).Parent = frame
	stroke(theme.Stroke, 1, 0.25).Parent = frame
	padding(12).Parent = frame
	list(10).Parent = frame

	local header = new("Frame", {
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = frame,
		Size = UDim2.new(1, 0, 0, 24),
		ZIndex = 5,
	})

	local accent = new("Frame", {
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Parent = header,
		Position = UDim2.fromOffset(0, 7),
		Size = UDim2.fromOffset(4, 12),
		ZIndex = 6,
	})
	corner(4).Parent = accent
	gradient(accent, theme.Accent, theme.Accent2, 90)

	local title = makeLabel(header, titleText, 14, theme.Text, true)
	title.Position = UDim2.fromOffset(12, 0)
	title.Size = UDim2.new(1, -12, 1, 0)
	title.ZIndex = 6

	local content = new("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = frame,
		Size = UDim2.new(1, 0, 0, 0),
		ZIndex = 5,
	})
	list(8).Parent = content

	local section = setmetatable({
		Content = content,
		Count = 0,
		Frame = frame,
		Window = self.Window,
	}, Section)

	table.insert(self.Sections, section)
	return section
end

function Section:_baseRow(height)
	local theme = self.Window.Theme
	self.Count = self.Count + 1

	local row = new("Frame", {
		BackgroundColor3 = theme.Panel2,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = self.Content,
		Size = UDim2.new(1, 0, 0, height or 44),
		ZIndex = 6,
	})
	corner(9).Parent = row

	local rowStroke = stroke(theme.Stroke, 1, 1)
	rowStroke.Parent = row

	local rowScale = new("UIScale", {
		Parent = row,
		Scale = 0.96,
	})

	task.delay(self.Count * 0.025, function()
		if not row.Parent then
			return
		end
		tween(row, { BackgroundTransparency = 0 }, 0.18)
		tween(rowStroke, { Transparency = 0.45 }, 0.18)
		tween(rowScale, { Scale = 1 }, 0.36, Enum.EasingStyle.Back)
	end)

	return row, rowStroke
end

function Section:Label(text)
	local theme = self.Window.Theme
	local row = self:_baseRow(36)
	local label = makeLabel(row, text, 12, theme.Muted, false)
	label.Position = UDim2.fromOffset(12, 0)
	label.Size = UDim2.new(1, -24, 1, 0)
	label.ZIndex = 7
	return setmetatable({
		Instance = row,
		Label = label,
		Set = function(nextText, color)
			label.Text = nextText
			if color then
				label.TextColor3 = color
			end
		end,
	}, Control)
end

function Section:Button(text, callback)
	local theme = self.Window.Theme
	local row, rowStroke = self:_baseRow(44)

	local label = makeLabel(row, text, 13, theme.Text, true)
	label.Position = UDim2.fromOffset(12, 0)
	label.Size = UDim2.new(1, -44, 1, 0)
	label.ZIndex = 7

	local arrow = makeLabel(row, ">", 15, theme.Muted, true)
	arrow.Position = UDim2.new(1, -32, 0, 0)
	arrow.Size = UDim2.fromOffset(20, 44)
	arrow.TextXAlignment = Enum.TextXAlignment.Center
	arrow.ZIndex = 7

	local hit = makeButton(row, "", theme.Panel2, theme.Text)
	hit.BackgroundTransparency = 1
	hit.Size = UDim2.fromScale(1, 1)
	hit.ZIndex = 8

	pressable(hit, row, rowStroke, theme, function()
		tween(arrow, { Position = UDim2.new(1, -26, 0, 0), TextColor3 = theme.Accent }, 0.08)
		task.delay(0.08, function()
			if arrow.Parent then
				tween(arrow, { Position = UDim2.new(1, -32, 0, 0), TextColor3 = theme.Muted }, 0.2)
			end
		end)
		if callback then
			callback()
		end
	end)

	return setmetatable({ Instance = row }, Control)
end

function Section:Toggle(text, default, callback)
	local theme = self.Window.Theme
	local enabled = default == true
	local row, rowStroke = self:_baseRow(46)

	local label = makeLabel(row, text, 13, theme.Text, true)
	label.Position = UDim2.fromOffset(12, 0)
	label.Size = UDim2.new(1, -82, 1, 0)
	label.ZIndex = 7

	local switch = new("Frame", {
		BackgroundColor3 = enabled and theme.Accent or theme.Panel3,
		BorderSizePixel = 0,
		Parent = row,
		Position = UDim2.new(1, -58, 0.5, -12),
		Size = UDim2.fromOffset(46, 24),
		ZIndex = 7,
	})
	corner(999).Parent = switch
	local switchGradient = gradient(switch, theme.Accent, theme.Accent2, 0)
	switchGradient.Enabled = enabled

	local knob = new("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Parent = switch,
		Position = enabled and UDim2.new(1, -21, 0, 3) or UDim2.fromOffset(3, 3),
		Size = UDim2.fromOffset(18, 18),
		ZIndex = 8,
	})
	corner(999).Parent = knob

	local hit = makeButton(row, "", theme.Panel2, theme.Text)
	hit.BackgroundTransparency = 1
	hit.Size = UDim2.fromScale(1, 1)
	hit.ZIndex = 9

	local function set(value, fire)
		enabled = value
		tween(switch, {
			BackgroundColor3 = enabled and theme.Accent or theme.Panel3,
		}, 0.16)
		switchGradient.Enabled = enabled
		tween(knob, {
			Position = enabled and UDim2.new(1, -21, 0, 3) or UDim2.fromOffset(3, 3),
		}, 0.25, Enum.EasingStyle.Back)
		tween(rowStroke, {
			Color = enabled and theme.Accent or theme.Stroke,
			Transparency = enabled and 0.18 or 0.45,
		}, 0.18)
		if callback and fire ~= false then
			task.spawn(callback, enabled)
		end
	end

	pressable(hit, row, rowStroke, theme, function()
		set(not enabled)
	end)

	if callback then
		task.spawn(callback, enabled)
	end

	return setmetatable({
		Instance = row,
		Get = function()
			return enabled
		end,
		Set = set,
	}, Control)
end

function Control:Destroy()
	if self.Instance then
		self.Instance:Destroy()
	end
end

function Section:Textbox(text, placeholder, callback)
	local theme = self.Window.Theme
	local row, rowStroke = self:_baseRow(46)

	local label = makeLabel(row, text, 13, theme.Text, true)
	label.Position = UDim2.fromOffset(12, 0)
	label.Size = UDim2.new(1, -82, 1, 0)
	label.ZIndex = 7

	local textbox = new("TextBox", {
		BackgroundColor3 = theme.Panel3,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		PlaceholderColor3 = theme.Muted,
		PlaceholderText = placeholder or "",
		Parent = row,
		Position = UDim2.new(1, -78, 0.5, -15),
		Size = UDim2.fromOffset(66, 30),
		Text = "",
		TextColor3 = theme.Text,
		TextSize = 13,
		ZIndex = 8,
	})
	corner(8).Parent = textbox
	stroke(theme.Stroke, 1, 0.4).Parent = textbox

	textbox.FocusLost:Connect(function(enterPressed)
		if callback then
			task.spawn(callback, textbox.Text, enterPressed)
		end
	end)

	return setmetatable({
		Instance = row,
		Get = function()
			return textbox.Text
		end,
		Set = function(text)
			textbox.Text = text
		end,
	}, Control)
end

function Section:Slider(text, default, min, max, callback)
	local theme = self.Window.Theme
	local value = default or min
	local precision = 0
	local step = (max - min) / 100
	
	-- Auto-detect precision from slider range/default.
	-- Old code used string:split("%."), which does not calculate decimal places correctly in Luau.
	local function decimalPlaces(n)
		if type(n) ~= "number" then return 0 end
		local str = tostring(n)
		local dot = string.find(str, ".", 1, true)
		return dot and math.min(3, #str - dot) or 0
	end
	precision = math.max(decimalPlaces(default), decimalPlaces(min), decimalPlaces(max))
	
	local row, rowStroke = self:_baseRow(46)

	local label = makeLabel(row, text, 13, theme.Text, true)
	label.Position = UDim2.fromOffset(12, 0)
	label.Size = UDim2.new(1, -82, 1, 0)
	label.ZIndex = 7

	local valueLabel = makeLabel(row, tostring(value), 13, theme.Accent, true)
	valueLabel.Position = UDim2.new(1, -58, 0.5, -10)
	valueLabel.Size = UDim2.fromOffset(46, 20)
	valueLabel.TextXAlignment = Enum.TextXAlignment.Center
	valueLabel.ZIndex = 7

	local sliderFrame = new("Frame", {
		BackgroundColor3 = theme.Panel3,
		BorderSizePixel = 0,
		Parent = row,
		Position = UDim2.fromOffset(12, 32),
		Size = UDim2.new(1, -24, 0, 6),
		ZIndex = 7,
	})
	corner(3).Parent = sliderFrame

	local fill = new("Frame", {
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Parent = sliderFrame,
		Size = UDim2.fromScale((value - min) / (max - min), 1),
		ZIndex = 8,
	})
	corner(3).Parent = fill
	gradient(fill, theme.Accent, theme.Accent2, 0)

	local knob = new("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Parent = sliderFrame,
		Position = UDim2.fromScale((value - min) / (max - min), 0.5),
		Size = UDim2.fromOffset(14, 14),
		ZIndex = 9,
	})
	corner(999).Parent = knob

	local hit = makeButton(row, "", theme.Panel2, theme.Text)
	hit.BackgroundTransparency = 1
	hit.Size = UDim2.fromScale(1, 1)
	hit.ZIndex = 10

	local function formatValue(v)
		if precision > 0 then
			return string.format("%." .. precision .. "f", v)
		end
		return tostring(math.floor(v))
	end

	local function setValue(newValue, fire)
		value = math.clamp(newValue, min, max)
		local ratio = (value - min) / (max - min)
		valueLabel.Text = formatValue(value)
		fill.Size = UDim2.fromScale(ratio, 1)
		knob.Position = UDim2.fromScale(ratio, 0.5)
		if callback and fire ~= false then
			task.spawn(callback, value)
		end
	end

	local function getValueFromMouse()
		local mousePos = UserInputService:GetMouseLocation()
		local sliderPos = sliderFrame.AbsolutePosition
		local sliderSize = sliderFrame.AbsoluteSize
		local ratio = math.clamp((mousePos.X - sliderPos.X) / sliderSize.X, 0, 1)
		return min + ratio * (max - min)
	end

	local dragging = false
	local dragConnection = nil
	local upConnection = nil
	local leaveConnection = nil

	hit.MouseButton1Down:Connect(function()
		dragging = true
		-- Fire callback while dragging so runtime settings change immediately, not only on mouse release.
		setValue(getValueFromMouse(), true)
		
		dragConnection = UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				setValue(getValueFromMouse(), true)
			end
		end)
		
		upConnection = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				if dragging then
					dragging = false
					setValue(getValueFromMouse(), true)
					if dragConnection then dragConnection:Disconnect() end
					if upConnection then upConnection:Disconnect() end
					if leaveConnection then leaveConnection:Disconnect() end
				end
			end
		end)
	end)

	-- Click to jump to position
	hit.MouseButton1Click:Connect(function()
		if not dragging then
			setValue(getValueFromMouse(), true)
		end
	end)

	if callback then
		task.spawn(callback, value)
	end

	return setmetatable({
		Instance = row,
		Get = function()
			return value
		end,
		Set = function(v, fire)
			setValue(v, fire)
		end,
	}, Control)
end

function Section:Dropdown(text, options, default, callback)
	local theme = self.Window.Theme
	local compact = self.Window.IsCompact
	local selected = (type(default) == "string" and default ~= "") and default or options[1] or ""
	local open = false
	local row, rowStroke = self:_baseRow(46)
	row.ClipsDescendants = true

	local label = makeLabel(row, text, 13, theme.Text, true)
	label.Position = compact and UDim2.fromOffset(12, 3) or UDim2.fromOffset(12, 0)
	label.Size = compact and UDim2.new(1, -52, 0, 20) or UDim2.new(1, -210, 0, 46)
	label.TextSize = compact and 12 or 13
	label.ZIndex = 7

	local selectedLabel = makeLabel(row, selected, 12, theme.Muted, true)
	selectedLabel.Position = compact and UDim2.fromOffset(12, 22) or UDim2.new(1, -176, 0, 0)
	selectedLabel.Size = compact and UDim2.new(1, -52, 0, 22) or UDim2.fromOffset(132, 46)
	selectedLabel.TextXAlignment = compact and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right
	selectedLabel.ZIndex = 7

	local arrow = makeLabel(row, ">", 15, theme.Muted, true)
	arrow.Position = UDim2.new(1, -32, 0, 0)
	arrow.Size = UDim2.fromOffset(20, 46)
	arrow.TextXAlignment = Enum.TextXAlignment.Center
	arrow.ZIndex = 7

	local holder = new("Frame", {
		BackgroundTransparency = 1,
		Parent = row,
		Position = UDim2.fromOffset(8, 48),
		Size = UDim2.new(1, -16, 0, math.max(1, #options) * 34),
		ZIndex = 7,
	})
	list(6).Parent = holder

	local function choose(option, fire)
		selected = option
		selectedLabel.Text = option
		if callback and fire ~= false then
			task.spawn(callback, selected)
		end
	end

	for _, option in ipairs(options) do
		local optionButton = makeButton(holder, option, theme.Panel3, theme.Text)
		optionButton.Size = UDim2.new(1, 0, 0, 30)
		optionButton.TextXAlignment = Enum.TextXAlignment.Left
		optionButton.ZIndex = 8
		corner(8).Parent = optionButton
		padding(10).Parent = optionButton

		optionButton.MouseEnter:Connect(function()
			tween(optionButton, { BackgroundColor3 = theme.Accent, TextColor3 = theme.DarkText }, 0.12)
		end)
		optionButton.MouseLeave:Connect(function()
			tween(optionButton, { BackgroundColor3 = theme.Panel3, TextColor3 = theme.Text }, 0.12)
		end)
		optionButton.MouseButton1Down:Connect(function(x, y)
			ripple(optionButton, x, y, Color3.fromRGB(255, 255, 255))
		end)
		optionButton.MouseButton1Click:Connect(function()
			choose(option)
			open = false
			tween(row, { Size = UDim2.new(1, 0, 0, 46) }, 0.2)
			tween(arrow, { Rotation = 0 }, 0.2)
		end)
	end

	local hit = makeButton(row, "", theme.Panel2, theme.Text)
	hit.BackgroundTransparency = 1
	hit.Size = UDim2.new(1, 0, 0, 46)
	hit.ZIndex = 9

	pressable(hit, row, rowStroke, theme, function()
		open = not open
		local targetHeight = open and (54 + math.max(1, #options) * 36) or 46
		tween(row, { Size = UDim2.new(1, 0, 0, targetHeight) }, 0.22, Enum.EasingStyle.Quint)
		tween(arrow, { Rotation = open and 90 or 0 }, 0.22)
	end)

	if callback and selected ~= "" then
		task.spawn(callback, selected)
	end

	return setmetatable({
		Instance = row,
		Get = function()
			return selected
		end,
		Set = choose,
	}, Control)
end

pcall(function()
    local prev = getgenv and getgenv().WalkyGAG2
    if prev then
        if prev.S then prev.S.killed = true end
        if prev.unload then pcall(prev.unload) end
    end
end)

pcall(function()
    if setthreadidentity then setthreadidentity(8) end
    if syn and syn.set_thread_identity then syn.set_thread_identity(8) end
end)

-- block ALL Robux purchase prompts so no farm action can pop a real-money dialog
pcall(function()
    local nc = newcclosure or function(f) return f end
    local oldNc
    local function blocker(self, ...)
        local m = getnamecallmethod and getnamecallmethod()
        if type(m) == "string" and string.sub(m, 1, 6) == "Prompt" and string.find(m, "Purchase") then return end
        return oldNc(self, ...)
    end
    if hookmetamethod then
        oldNc = hookmetamethod(game, "__namecall", nc(blocker))
    elseif getrawmetatable and setreadonly then
        local mt = getrawmetatable(game); oldNc = mt.__namecall
        setreadonly(mt, false); mt.__namecall = nc(blocker); setreadonly(mt, true)
    end
end)

-- // ============================================================ \\ --
-- //                       NETWORK / DATA                         \\ --
-- // ============================================================ \\ --
local Net
do
    local sm = ReplicatedStorage:WaitForChild("SharedModules", 15)
    local mod = sm and sm:FindFirstChild("Networking")
    if mod then local ok, m = pcall(require, mod); if ok then Net = m end end
end
if not Net then
    warn("[WalkyHub] Networking module not found — wrong game?")
    return
end

-- light global pacer + jitter (precautionary; GAG2 has no proven AC vector yet)
local _rl = { w = 0, c = 0, cap = 60 }
local function pace()
    local now = os.clock()
    if now - _rl.w >= 1 then _rl.w = now; _rl.c = 0 end
    if _rl.c >= _rl.cap then task.wait(0.05); return pace() end
    _rl.c = _rl.c + 1
end
local function jitter(a, b) a = a or 0.05; b = b or 0.12; return a + math.random() * (b - a) end

local function action(path)
    local cur = Net
    for part in string.gmatch(path, "[^.]+") do
        if type(cur) ~= "table" then return nil end
        cur = cur[part]
    end
    return cur
end
local function fire(path, ...)            -- fire-and-forget OR returns value (both via :Fire)
    local a = action(path)
    if not (a and a.Fire) then return false, "no action: " .. path end
    pace()
    local args = table.pack(...)
    local ok, res = pcall(function() return a:Fire(table.unpack(args, 1, args.n)) end)
    if not ok then return false, res end
    return true, res
end
local function fireFirst(paths, ...)
    local lastErr = nil
    for _, path in ipairs(paths) do
        local ok, res = fire(path, ...)
        if ok then return true, path, res end
        lastErr = tostring(res)
    end
    return false, nil, lastErr
end
-- NO pacer: for the high-volume harvest/sell hot path (the 60/s pacer throttled it to ~0).
local function fireFast(path, ...)
    local a = action(path)
    if not (a and a.Fire) then return false, "no action: " .. path end
    local args = table.pack(...)
    local ok, res = pcall(function() return a:Fire(table.unpack(args, 1, args.n)) end)
    if not ok then return false, res end
    return true, res
end
-- Retry wrapper for critical operations
local function fireWithRetry(path, maxRetries, ...)
    maxRetries = maxRetries or 3
    for i = 1, maxRetries do
        local ok, res = fire(path, ...)
        if ok then return true, res end
        if i < maxRetries then task.wait(0.1 * i) end
    end
    return false, "max retries exceeded"
end

-- local-player replica (Sheckles / Tokens / Inventory / PurchasedThisRestock / OwnedExpansions)
local _replica
local function replica()
    if _replica then return _replica end
    local ok, psc = pcall(function() return require(ReplicatedStorage.ClientModules.PlayerStateClient) end)
    if ok and psc and psc.WaitForLocalReplica then
        local ok2, r = pcall(function() return psc:WaitForLocalReplica(30) end)
        if ok2 and r then _replica = r end
    end
    return _replica
end
local function pdata() local r = replica(); return (r and r.Data) or {} end
local function getSheckles() return tonumber(pdata().Sheckles) or 0 end
local function getTokens()   return tonumber(pdata().Tokens) or 0 end
local function inv(category) local i = pdata().Inventory; return (i and i[category]) or {} end
local function fmt(n)
    n = tonumber(n) or 0
    if n >= 1e12 then return string.format("%.2fT", n/1e12)
    elseif n >= 1e9 then return string.format("%.2fB", n/1e9)
    elseif n >= 1e6 then return string.format("%.2fM", n/1e6)
    elseif n >= 1e3 then return string.format("%.2fK", n/1e3)
    else return tostring(math.floor(n)) end
end
-- extract a usable item "name" + count from an inventory entry (shape varies: count-by-name or uuid->record)
local function invNames(category)
    local out = {}                       -- { name = totalCount }
    for k, v in pairs(inv(category)) do
        local name, count
        if type(v) == "table" then
            name = v.Name or v.ItemName or v.Type or (type(k) == "string" and not v.Name and k) or tostring(k)
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

-- // ============================================================ \\ --
-- //                         CATALOGS                             \\ --
-- // ============================================================ \\ --
local function seedCatalog()
    local out = {}
    local ok, data = pcall(function() return require(ReplicatedStorage.SharedModules.SeedData) end)
    if ok and type(data) == "table" then
        for _, e in pairs(data) do
            if type(e) == "table" and e.SeedName and e.RestockShop ~= false and e.PurchasePrice then
                out[#out + 1] = { name = e.SeedName, price = tonumber(e.PurchasePrice) or 0, rarity = e.Rarity or "" }
            end
        end
    end
    table.sort(out, function(a, b) return a.price < b.price end)
    if #out == 0 then
        for _, n in ipairs({ "Carrot","Strawberry","Blueberry","Tulip","Tomato","Apple","Bamboo","Corn",
            "Cactus","Pineapple","Mushroom","Green Bean","Banana","Grape","Coconut","Mango","Dragon Fruit",
            "Acorn","Cherry","Sunflower","Venus Fly Trap","Pomegranate","Poison Apple","Moon Bloom",
            "Dragon's Breath","Ghost Pepper","Poison Ivy" }) do out[#out + 1] = { name = n, price = 0, rarity = "" } end
    end
    return out
end
local function gearCatalog()
    local out, seen = {}, {}
    local ok, data = pcall(function() return require(ReplicatedStorage.SharedModules.GearShopData) end)
    if ok and data and type(data.Data) == "table" then
        for _, e in pairs(data.Data) do
            if type(e) == "table" and e.ItemName and not e.RobuxOnly then
                if not seen[e.ItemName] then seen[e.ItemName] = true; out[#out + 1] = e.ItemName end
            end
        end
    end
    if #out == 0 then  -- fall back to live stock items
        local ok2, items = pcall(function() return ReplicatedStorage.StockValues.GearShop.Items end)
        if ok2 and items then for _, c in ipairs(items:GetChildren()) do out[#out + 1] = c.Name end end
    end
    table.sort(out)
    return out
end
local CATALOG = seedCatalog()
local SEED_NAMES = {} ; for _, s in ipairs(CATALOG) do SEED_NAMES[#SEED_NAMES + 1] = s.name end
local GEAR_NAMES = gearCatalog()

local function stockOf(shop, name)
    local ok, items = pcall(function() return ReplicatedStorage.StockValues[shop].Items end)
    if not ok or not items then return nil end
    local v = items:FindFirstChild(name)
    return v and tonumber(v.Value) or 0
end

-- // ============================================================ \\ --
-- //                  PLOT / TOOLS / WORLD STATE                  \\ --
-- // ============================================================ \\ --
local function myPlot()
    local id = LocalPlayer:GetAttribute("PlotId")
    local gardens = Workspace:FindFirstChild("Gardens")
    if not (id and gardens) then return nil end
    return gardens:FindFirstChild("Plot" .. tostring(id))
end
local function myPlotId() return LocalPlayer:GetAttribute("PlotId") end
local function humanoid() local c = LocalPlayer.Character; return c and c:FindFirstChildOfClass("Humanoid") end

-- tools in Backpack+Character carrying attribute `attr` (optionally matching a name)
local function toolsByAttr(attr, wantName)
    local out = {}
    local function scan(c)
        if not c then return end
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") and t:GetAttribute(attr) ~= nil then
                if (not wantName) or t:GetAttribute(attr) == wantName or t.Name == wantName then out[#out + 1] = t end
            end
        end
    end
    scan(LocalPlayer:FindFirstChild("Backpack")); scan(LocalPlayer.Character)
    return out
end
local function heldToolByAttr(attr)
    local c = LocalPlayer.Character
    local t = c and c:FindFirstChildWhichIsA("Tool")
    if t and t:GetAttribute(attr) ~= nil then return t end
    return nil
end
local function equipByAttr(attr, wantName)
    local t = heldToolByAttr(attr)
    if t and ((not wantName) or t:GetAttribute(attr) == wantName) then return t end
    local tools = toolsByAttr(attr, wantName)
    if #tools == 0 then return nil end
    t = tools[1]
    local hum = humanoid(); if not hum then return nil end
    local ok = pcall(function() hum:EquipTool(t) end)
    if not ok then return nil end
    task.wait(0.22)
    return heldToolByAttr(attr)
end

-- PlantArea parts inside MY plot
local function myPlantAreas()
    local out, plot = {}, myPlot()
    if not plot then return out end
    for _, p in ipairs(CollectionService:GetTagged("PlantArea")) do
        if p:IsA("BasePart") and p:IsDescendantOf(plot) then out[#out + 1] = p end
    end
    return out
end
-- a grid of world positions over my PlantArea, raycast-confirmed onto the surface
local function plantGrid(spacing)
    local pts, areas = {}, myPlantAreas()
    if #areas == 0 then return pts end
    spacing = math.max(2, spacing or 4)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = areas
    for _, area in ipairs(areas) do
        local ok, cf, size = pcall(function() return area.CFrame, area.Size end)
        if not ok then 
            -- skip this area if error
        else
            local topY = (cf * CFrame.new(0, size.Y/2, 0)).Position.Y
            for dx = -size.X/2 + spacing/2, size.X/2 - spacing/2, spacing do
                for dz = -size.Z/2 + spacing/2, size.Z/2 - spacing/2, spacing do
                    local w = (cf * CFrame.new(dx, 0, dz)).Position
                    local hit = Workspace:Raycast(Vector3.new(w.X, topY + 10, w.Z), Vector3.new(0, -40, 0), params)
                    if hit then pts[#pts + 1] = hit.Position end
                end
            end
        end
    end
    return pts
end
local function existingPlantPositions()
    local out, plot = {}, myPlot()
    local plants = plot and plot:FindFirstChild("Plants")
    if not plants then return out end
    for _, m in ipairs(plants:GetChildren()) do
        local ok, pivot = pcall(function() return m:GetPivot().Position end)
        if ok then out[#out + 1] = pivot end
    end
    return out
end

-- carrier model that holds PlantId/FruitId/UserId for a given prompt
local function promptCarrier(prompt)
    local node = prompt.Parent
    while node and node ~= Workspace and node:GetAttribute("PlantId") == nil do node = node.Parent end
    if node and node:GetAttribute("PlantId") ~= nil then return node end
    return prompt:FindFirstAncestorWhichIsA("Model")
end
local function ripeHarvests()       -- own ripe fruit (tag "HarvestPrompt")
    local out = {}
    for _, pr in ipairs(CollectionService:GetTagged("HarvestPrompt")) do
        if pr:IsA("ProximityPrompt") and pr.Enabled and pr:IsDescendantOf(Workspace) then
            local m = promptCarrier(pr)
            local pid = m and m:GetAttribute("PlantId")
            if pid then
                local uid = tonumber(m:GetAttribute("UserId"))
                if uid == nil or uid == LocalPlayer.UserId then
                    out[#out + 1] = { plantId = tostring(pid), fruitId = tostring(m:GetAttribute("FruitId") or ""), name = m:GetAttribute("FruitName") or m:GetAttribute("PlantName") or m.Name, mutation = m:GetAttribute("Mutation") or m:GetAttribute("Variant") or "" }
                end
            end
        end
    end
    return out
end
local function stealable()          -- other players' ripe fruit (tag "StealPrompt")
    local out = {}
    for _, pr in ipairs(CollectionService:GetTagged("StealPrompt")) do
        if pr:IsA("ProximityPrompt") and pr.Enabled and pr:IsDescendantOf(Workspace) then
            local m = promptCarrier(pr)
            local pid = m and m:GetAttribute("PlantId")
            if pid then
                local pos
                local pp = pr.Parent
                if pp and pp:IsA("BasePart") then pos = pp.Position
                elseif m then local ok, pv = pcall(function() return m:GetPivot().Position end); if ok then pos = pv end end
                out[#out + 1] = {
                    owner = tonumber(m:GetAttribute("UserId")) or 0,
                    plantId = tostring(pid),
                    fruitId = tostring(m:GetAttribute("FruitId") or ""),
                    pos = pos,
                }
            end
        end
    end
    return out
end
local function isNight()
    local n = ReplicatedStorage:FindFirstChild("Night")
    return n and n.Value == true
end
-- world wild pets you walk up to and buy/tame: Map.WildPetRef parts carry PetName/Price/OwnerUserId
local function wildPets()
    local out = {}
    local map = Workspace:FindFirstChild("Map")
    local ref = map and map:FindFirstChild("WildPetRef")
    if ref then for _, p in ipairs(ref:GetChildren()) do
        if p:IsA("BasePart") then
            out[#out + 1] = {
                part = p, name = p:GetAttribute("PetName"),
                price = tonumber(p:GetAttribute("Price")) or 0,
                owner = tonumber(p:GetAttribute("OwnerUserId")) or 0,
                pos = p.Position,
            }
        end
    end end
    return out
end
-- teleport char to a world position, run fn, restore original CFrame
local function atPosition(pos, fn)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local saved = hrp.CFrame
    pcall(function() hrp.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0)) end)
    task.wait(0.45)
    local ok = pcall(fn)
    task.wait(0.15)
    if hrp and hrp.Parent then pcall(function() hrp.CFrame = saved end) end
    return ok
end
-- own-garden anchor: standing inside it sets IsInOwnGarden -> the server banks carried stolen fruit
local function myBasePos()
    local plot = myPlot(); if not plot then return nil end
    for _, tag in ipairs({ "GardenTotalArea", "GardenZone" }) do
        for _, p in ipairs(CollectionService:GetTagged(tag)) do
            if p:IsA("BasePart") and p:IsDescendantOf(plot) then
                return Vector3.new(p.Position.X, p.Position.Y - p.Size.Y / 2 + 5, p.Position.Z)
            end
        end
    end
    local sp = plot:FindFirstChild("SpawnPoint")
    if sp and sp:IsA("BasePart") then return sp.Position end
    local ok, piv = pcall(function() return plot:GetPivot().Position end)
    return ok and piv or nil
end

-- // ============================================================ \\ --
-- //                          STATE                              \\ --
-- // ============================================================ \\ --
local S = {
    -- master
    autoFarm = false,
    -- buy / plant / harvest / sell
    autoBuy = false, buySeeds = {}, buyInterval = 5, buyPerTick = 8,
    autoPlant = false, plantSpacing = 4, plantSeed = "Best owned", plantPlan = {}, plantLimit = 0, keepSeeds = {},
    autoHarvest = false, harvestInterval = 2, harvestDelay = 0.01, onlyHarvest = {}, dontHarvest = {}, neverSellFruit = {}, neverSellMut = {},
    autoSell = false, sellAt = 85, sellInterval = 15,
    autoExpand = false, autoPot = false, autoDaily = false,
    -- boosts
    autoSprinkler = false, sprinklerInterval = 30,
    autoWater = false, waterInterval = 8,
    autoSkill = false, skillStats = {},          -- {"BaseSpeed"=true,...}
    -- pets
    autoEquipPets = false, equipPets = {}, buyPets = {}, autoPetSlot = false,
    autoBuyPets = false, maxPetPrice = 25000, petTeleport = true, petBuyInterval = 5,
    sellPets = {}, autoSellPets = false,
    -- eggs / crates / packs
    autoEgg = false, autoCrate = false, autoPack = false, openInterval = 4,
    -- shop
    autoGear = false, gearBuy = {}, gearInterval = 10,
    -- steal
    autoSteal = false, stealTeleport = true, stealReturnBase = true, stealDelay = 0.05,
    -- misc
    autoMail = false, mailSendTo = "", mailSend = {}, mailSendEvery = 45, lastMailSend = 0, autoAcceptGift = false, autoHop = false, allowServerHop = false, hopInterval = 0,
    codeText = "", autoCodes = false, antiAfk = true,
    -- perf / webhook
    fpsBoost = false, ultraPerformance = false,
    webhookEnabled = false, webhookUrl = "", webhookInterval = 300, webhookEvents = true, webhookReport = true,
    killed = false,
}
local Stats = { bought = 0, planted = 0, harvested = 0, sold = 0, earned = 0,
    sprinklers = 0, watered = 0, tamed = 0, opened = 0, stolen = 0, codes = 0, startAt = os.clock(),
    state = "IDLE", lastAction = "idle", petLast = "idle", webhookLastOk = 0, webhookNextAt = 0, webhookLastError = "none" }
local WebhookStats = { bought = 0, planted = 0, harvested = 0, sold = 0, opened = 0, stolen = 0 }

local _due = {}
local function due(key, period)
    local now = os.clock()
    if not _due[key] or now - _due[key] >= period then _due[key] = now; return true end
    return false
end
-- passive background loop bound to a getter
local function loopOn(getOn, period, body)
    task.spawn(function()
        while not S.killed do
            if getOn() then
                pcall(body)
                local p = (type(period) == "function") and period() or period
                local e = 0; while e < p and getOn() and not S.killed do task.wait(0.4); e += 0.4 end
            else task.wait(0.4) end
        end
    end)
end
local function picked(t) for _ in pairs(t) do return true end return false end


-- // ============================================================ \\
-- //              GAGConfig preset adapter (Hermes)              \\
-- // ============================================================ \\
local function gagClone(tbl)
    if type(tbl) ~= "table" then return tbl end
    local out = {}
    for k, v in pairs(tbl) do out[k] = gagClone(v) end
    return out
end

local function gagMerge(a, b)
    local out = gagClone(a or {})
    for k, v in pairs(b or {}) do
        if type(out[k]) == "table" and type(v) == "table" then out[k] = gagMerge(out[k], v) else out[k] = gagClone(v) end
    end
    return out
end

local GAG_PRESETS = {
    Starter = {
        Harvest = { ["Auto Harvest"] = true, ["Sell At"] = 50, ["Sell Every"] = 20 },
        Planting = { ["Auto Plant"] = true, ["Buy Seeds"] = { "Carrot", "Strawberry", "Blueberry", "Tomato" }, Layout = "compact", ["Minimum Seed"] = "" },
        Money = { ["Keep Cash"] = 0, ["Auto Expand Plot"] = true, ["Expand If Over"] = 50000 },
        Pets = { Buy = { "Deer", "Robin" }, Equip = { "Deer" } },
        Gear = { ["Keep Cash"] = 5000, ["Place Sprinklers"] = { ["Common Sprinkler"] = 4 }, ["Buy Gear"] = { "Super Sprinkler" } },
        Misc = { ["Auto Return To Garden"] = true },
    },
    Balanced = {
        Harvest = { ["Auto Harvest"] = true, ["Sell At"] = 85, ["Sell Every"] = 40 },
        Planting = { ["Auto Plant"] = true, ["Buy Seeds"] = { "Bamboo", "Corn", "Tomato", "Blueberry" }, Layout = "compact", ["Minimum Seed"] = "Bamboo", ["Keep Seeds"] = { ["Dragon's Breath"] = 5, ["Moon Bloom"] = 5, Gold = 5, Rainbow = 5 } },
        Money = { ["Keep Cash"] = 15000, ["Auto Expand Plot"] = true, ["Expand If Over"] = 1500000, ["Auto Replace Plants"] = true },
        Pets = { Buy = { "Unicorn", "GoldenDragonfly", Deer = 6 }, Equip = { "Unicorn", "GoldenDragonfly", "Deer" }, ["Auto Buy Slots"] = true },
        Gear = { ["Keep Cash"] = 15000, ["Sprinkler Coverage"] = "concentrate", ["Place Sprinklers"] = { best = 4 }, ["Best Sprinkler Up To"] = "Rare Sprinkler" },
        ["Event Seeds"] = { ["Auto Claim"] = true },
        Mail = { ["Auto Claim"] = true },
        Misc = { ["Auto Return To Garden"] = true },
    },
    Rich = {
        Harvest = { ["Auto Harvest"] = true, ["Sell At"] = 120, ["Sell Every"] = 40 },
        Planting = { ["Auto Plant"] = true, Layout = "compact", ["Plant Plan"] = { ["Dragon Fruit"] = 200, Mango = 200, Grape = 200 }, ["Plant Limit"] = 400, ["Keep Seeds"] = { Gold = 20, Rainbow = 20 } },
        Money = { ["Keep Cash"] = 500000, ["Auto Expand Plot"] = true, ["Expand If Over"] = 5000000, ["Auto Replace Plants"] = true },
        ["Never Sell"] = { ["By Mutation"] = { "Rainbow", "Starstruck" } },
        Pets = { Buy = { "Unicorn", "GoldenDragonfly" }, Equip = { "Unicorn", "GoldenDragonfly" }, ["Auto Buy Slots"] = true },
        Gear = { ["Keep Cash"] = 200000, ["Sprinkler Coverage"] = "concentrate", ["Place Sprinklers"] = { best = 6 }, ["Best Sprinkler Up To"] = "Rare Sprinkler" },
        Misc = { ["Auto Return To Garden"] = true },
    },
    AltToMain = {
        Harvest = { ["Auto Harvest"] = true, ["Sell At"] = 85 },
        Planting = { ["Auto Plant"] = true, Layout = "compact" },
        Money = { ["Keep Cash"] = 0, ["Auto Expand Plot"] = false },
        Mail = { ["Auto Claim"] = true, ["Send To"] = "USERNAME_AKUN_UTAMAMU", Send = { "Moon Bloom", "Dragon's Breath", "Gold", "Rainbow", "Unicorn" } },
        Misc = { ["Auto Return To Garden"] = true },
    },
    LowPC = {
        Performance = { ["FPS Cap"] = 30, ["Low Graphics"] = true, ["Remove Other Gardens"] = true, ["Hide Crop Visuals"] = true, ["Hide Fruit Visuals"] = true, ["Hide Players"] = true },
        Misc = { ["Fast Travel"] = true, ["Hide Game UI"] = true },
    },
}

local function gagSetMapFromList(dst, src)
    for k in pairs(dst) do dst[k] = nil end
    if type(src) ~= "table" then return end
    for k, v in pairs(src) do
        if type(k) == "number" and type(v) == "string" then dst[v] = true
        elseif type(k) == "string" then dst[k] = true end
    end
end

local function gagFirstName(src)
    if type(src) ~= "table" then return nil end
    for k, v in pairs(src) do
        if type(k) == "number" and type(v) == "string" then return v end
        if type(k) == "string" then return k end
    end
end

local applyFpsBoost, applyUltraPerformance
local function gagApplyPerformance(perf)
    if type(perf) ~= "table" then return end
    if perf["FPS Cap"] and setfpscap then pcall(setfpscap, tonumber(perf["FPS Cap"]) or 0) end
    if perf["Low Graphics"] ~= nil then S.fpsBoost = perf["Low Graphics"] == true; pcall(function() applyFpsBoost(S.fpsBoost) end) end
    if perf["Disable 3D"] ~= nil or perf["Ultra Performance"] ~= nil then
        S.ultraPerformance = (perf["Disable 3D"] == true) or (perf["Ultra Performance"] == true)
        pcall(function() applyUltraPerformance(S.ultraPerformance) end)
    end
end

local function gagApplyConfig(raw)
    raw = raw or {}
    local presetName = raw.Preset or raw.preset or (getgenv and getgenv().GAGPreset)
    local cfg = presetName and GAG_PRESETS[presetName] and gagMerge(GAG_PRESETS[presetName], raw) or raw
    local h, p, m = cfg.Harvest or {}, cfg.Planting or {}, cfg.Money or {}
    local pets, gear, mail = cfg.Pets or {}, cfg.Gear or {}, cfg.Mail or {}
    local misc, perf = cfg.Misc or {}, cfg.Performance or {}
    local webhook = cfg.Webhook or cfg.webhook or {}

    if h["Auto Harvest"] ~= nil then S.autoHarvest = h["Auto Harvest"] == true; S.autoSell = S.autoHarvest end
    if h["Sell At"] ~= nil then S.sellAt = math.max(1, tonumber(h["Sell At"]) or S.sellAt) end
    if h["Sell Every"] ~= nil then S.sellInterval = math.max(3, tonumber(h["Sell Every"]) or S.sellInterval) end
    if type(h["Only Harvest"]) == "table" then gagSetMapFromList(S.onlyHarvest, h["Only Harvest"]) end
    if type(h["Don't Harvest"]) == "table" then gagSetMapFromList(S.dontHarvest, h["Don't Harvest"]) end
    if cfg["Never Sell"] then
        if type(cfg["Never Sell"]["By Fruit"]) == "table" then gagSetMapFromList(S.neverSellFruit, cfg["Never Sell"]["By Fruit"]) end
        if type(cfg["Never Sell"]["By Mutation"]) == "table" then gagSetMapFromList(S.neverSellMut, cfg["Never Sell"]["By Mutation"]) end
    end

    if p["Auto Plant"] ~= nil then S.autoPlant = p["Auto Plant"] == true end
    if p.Layout == "spread" then S.plantSpacing = 8 elseif p.Layout == "compact" then S.plantSpacing = 4 end
    local onlyPlant = gagFirstName(p["Only Plant"] or p["Plant Plan"])
    if onlyPlant then S.plantSeed = onlyPlant end
    if type(p["Plant Plan"]) == "table" then S.plantPlan = gagClone(p["Plant Plan"]) end
    if type(p["Keep Seeds"]) == "table" then S.keepSeeds = gagClone(p["Keep Seeds"]) end
    if p["Plant Limit"] ~= nil then S.plantLimit = math.max(0, tonumber(p["Plant Limit"]) or 0) end
    if type(p["Buy Seeds"]) == "table" then gagSetMapFromList(S.buySeeds, p["Buy Seeds"]); S.autoBuy = picked(S.buySeeds) end

    if m["Auto Expand Plot"] ~= nil then S.autoExpand = m["Auto Expand Plot"] == true end
    if misc["Auto Daily Deal"] ~= nil then S.autoDaily = misc["Auto Daily Deal"] == true end

    if type(pets.Buy) == "table" then gagSetMapFromList(S.buyPets, pets.Buy); S.autoBuyPets = picked(S.buyPets); local max=0; for _,v in pairs(pets.Buy) do if type(v)=="number" and v>max then max=v end end; if max>0 then S.maxPetPrice=1000000 end end
    if type(pets.Equip) == "table" then gagSetMapFromList(S.equipPets, pets.Equip); S.autoEquipPets = picked(S.equipPets) end
    if pets["Auto Buy Slots"] ~= nil then S.autoPetSlot = pets["Auto Buy Slots"] == true end

    if type(gear["Buy Gear"]) == "table" then gagSetMapFromList(S.gearBuy, gear["Buy Gear"]); S.autoGear = picked(S.gearBuy) end
    if type(gear["Keep Gear"]) == "table" then gagSetMapFromList(S.gearBuy, gear["Keep Gear"]); S.autoGear = picked(S.gearBuy) end
    if type(gear["Place Sprinklers"]) == "table" then S.autoSprinkler = picked(gear["Place Sprinklers"]) end

    if cfg["Event Seeds"] and cfg["Event Seeds"]["Auto Claim"] ~= nil then S.autoPack = cfg["Event Seeds"]["Auto Claim"] == true end
    if mail["Auto Claim"] ~= nil then S.autoMail = mail["Auto Claim"] == true end
    if type(mail["Send To"]) == "string" then S.mailSendTo = mail["Send To"] end
    if mail["Send Every"] ~= nil then S.mailSendEvery = math.max(10, (tonumber(mail["Send Every"]) or 0) * 60); if mail["Send Every"] == 0 then S.mailSendEvery = 45 end end
    if type(mail["Send"]) == "table" then S.mailSend = gagClone(mail["Send"]) end
    if misc["Fast Travel"] ~= nil then S.stealTeleport = misc["Fast Travel"] == true; S.petTeleport = misc["Fast Travel"] == true end
    if type(webhook) == "table" then
        if type(webhook.Url) == "string" then S.webhookUrl = webhook.Url end
        if type(webhook.URL) == "string" then S.webhookUrl = webhook.URL end
        if type(webhook.url) == "string" then S.webhookUrl = webhook.url end
        if webhook.Enabled ~= nil then S.webhookEnabled = webhook.Enabled == true end
        if webhook.enabled ~= nil then S.webhookEnabled = webhook.enabled == true end
        if webhook.Events ~= nil then S.webhookEvents = webhook.Events == true end
        if webhook.Report ~= nil then S.webhookReport = webhook.Report == true end
        if webhook.Interval ~= nil then S.webhookInterval = math.max(30, (tonumber(webhook.Interval) or 5) * 60) end
        if webhook["Interval Min"] ~= nil then S.webhookInterval = math.max(30, (tonumber(webhook["Interval Min"]) or 5) * 60) end
    end
    gagApplyPerformance(perf)

    if presetName then warn("[GAGConfig] Applied preset: " .. tostring(presetName)) else warn("[GAGConfig] Applied custom config") end
end

local function pickMulti(sel, into)
    for k in pairs(into) do into[k] = nil end
    if type(sel) == "string" and sel ~= "" then
        -- Current GUI dropdown is single-select and returns a string.
        -- Older code only accepted tables, so manual Seed/Pet dropdowns cleared the setting
        -- and loops fell back to default/all-owned behavior.
        into[sel] = true
    elseif type(sel) == "table" then
        for k, v in pairs(sel) do
            if v == true then into[k] = true elseif type(v) == "string" then into[v] = true end
        end
    end
end
local function selectedNames(map)
    local out = {}
    if type(map) == "table" then for k, v in pairs(map) do if v then out[#out + 1] = tostring(k) end end end
    table.sort(out)
    return (#out > 0) and table.concat(out, ", ") or "-"
end
local function availableActions(paths)
    local out = {}
    for _, path in ipairs(paths or {}) do out[#out + 1] = path .. "=" .. tostring(action(path) ~= nil) end
    return table.concat(out, " | ")
end

-- // ============================================================ \\ --
-- //                     CORE FARM (master loop)                 \\ --
-- // ============================================================ \\ --
local SEED_BUY_ACTIONS = { "SeedShop.PurchaseSeed", "SeedShop.BuySeed", "SeedShop.RequestPurchase", "SeedShop.Purchase", "Shop.PurchaseSeed", "Shop.BuySeed" }
local _seedBuyWarnAt = {}
local function buySeedOnce(seedName)
    local ok, used, err = fireFirst(SEED_BUY_ACTIONS, seedName)
    if ok then return true, used end
    local now = os.clock()
    if now - (_seedBuyWarnAt[seedName] or 0) > 20 then
        _seedBuyWarnAt[seedName] = now
        warn("[Seeds] Buy failed for " .. tostring(seedName) .. ": " .. tostring(err))
    end
    return false, err
end
local function stepBuy()
    if not due("buy", math.max(0.2, tonumber(S.buyInterval) or 1)) then return end
    Stats.state = "BUY"
    if not picked(S.buySeeds) then return end
    for _, s in ipairs(CATALOG) do
        if not (S.autoFarm or S.autoBuy) then break end
        if S.buySeeds[s.name] then
            local stock, bought = stockOf("SeedShop", s.name), 0
            while bought < S.buyPerTick do
                if stock ~= nil and stock <= 0 then break end
                if s.price > 0 and getSheckles() < s.price then break end
                local ok = buySeedOnce(s.name)
                if not ok then break end
                Stats.bought += 1; bought += 1; Stats.lastAction = "bought seed " .. tostring(s.name)
                if stock ~= nil then stock -= 1 end
                task.wait(jitter(0.04, 0.09))
            end
        end
    end
end

local function plantCounts()
    local counts, plot = {}, myPlot()
    local plants = plot and plot:FindFirstChild("Plants")
    if not plants then return counts, 0 end
    local total = 0
    for _, m in ipairs(plants:GetChildren()) do
        local name = m:GetAttribute("PlantName") or m:GetAttribute("SeedName") or m.Name
        counts[name] = (counts[name] or 0) + 1
        total += 1
    end
    return counts, total
end
local function seedToolCount(seedName)
    local n = 0
    for _, t in ipairs(toolsByAttr("SeedTool", seedName)) do n += 1 end
    return n
end
local function seedAllowedByKeep(seedName)
    local keep = tonumber(S.keepSeeds and S.keepSeeds[seedName]) or 0
    return seedToolCount(seedName) > keep
end
local function plannedSeedTarget()
    if type(S.plantPlan) ~= "table" or not picked(S.plantPlan) then return nil end
    local counts = plantCounts()
    for name, target in pairs(S.plantPlan) do
        if (counts[name] or 0) < (tonumber(target) or 0) and seedAllowedByKeep(name) then return name end
    end
    return nil
end
local function pickPlantTool()
    local planned = plannedSeedTarget()
    if planned then
        local t = toolsByAttr("SeedTool", planned)[1]
        if t and seedAllowedByKeep(planned) then return t end
    end
    if S.plantSeed ~= "Best owned" and S.plantSeed ~= "" then
        local t = toolsByAttr("SeedTool", S.plantSeed)[1]
        if t and seedAllowedByKeep(S.plantSeed) then return t end
    end
    -- best owned = rarest/most expensive seed we hold
    local best, bestPrice
    for _, t in ipairs(toolsByAttr("SeedTool")) do
        local nm = t:GetAttribute("SeedTool")
        local price = 0
        for _, s in ipairs(CATALOG) do if s.name == nm then price = s.price; break end end
        if seedAllowedByKeep(nm) and (not bestPrice or price > bestPrice) then best, bestPrice = t, price end
    end
    return best or toolsByAttr("SeedTool")[1]
end

local function stepPlant()
    Stats.state = "PLANT"
    local _, totalPlants = plantCounts()
    if (S.plantLimit or 0) > 0 and totalPlants >= S.plantLimit then return end
    local grid = plantGrid(S.plantSpacing)
    if #grid == 0 then return end
    local tool = pickPlantTool(); if not tool then return end
    local hum = humanoid(); if not hum then return end
    if heldToolByAttr("SeedTool") ~= tool then 
        pcall(function() hum:EquipTool(tool) end)
        task.wait(0.08) 
    end
    tool = heldToolByAttr("SeedTool"); if not tool then return end
    local seedAttr = tool:GetAttribute("SeedTool")
    if not seedAttr then return end
    local occupied = existingPlantPositions()
    for _, pos in ipairs(grid) do
        if not (S.autoFarm or S.autoPlant) then break end
        local clear = true
        for _, op in ipairs(occupied) do
            if (Vector2.new(pos.X, pos.Z) - Vector2.new(op.X, op.Z)).Magnitude < 1 then clear = false; break end
        end
        if clear then
            if not heldToolByAttr("SeedTool") then
                local nx = pickPlantTool(); if not nx then return end
                pcall(function() hum:EquipTool(nx) end)
                task.wait(0.06)
                tool = heldToolByAttr("SeedTool"); if not tool then return end
                seedAttr = tool:GetAttribute("SeedTool")
                if not seedAttr then return end
            end
            pcall(function() fire("Plant.PlantSeed", pos, seedAttr, tool) end)
            Stats.planted += 1; Stats.lastAction = "planted " .. tostring(seedAttr); occupied[#occupied + 1] = pos
            task.wait(jitter(0.025, 0.055))
        end
    end
end

local function maxFruitCap() return tonumber(LocalPlayer:GetAttribute("MaxFruitCapacity")) or 100 end
local function fruitCount()  return tonumber(LocalPlayer:GetAttribute("FruitCount")) or 0 end
local function sellAllNow()
    Stats.state = "SELL"
    if picked(S.neverSellFruit) or picked(S.neverSellMut) then
        warn("[NeverSell] SellAll blocked because Never Sell protection is configured")
        return 0
    end
    local ok, res = fireFast("NPCS.SellAll")
    if ok and type(res) == "table" and res.Success then
        local n = tonumber(res.SoldCount) or 0
        Stats.sold += n; Stats.earned += tonumber(res.SellPrice) or 0; Stats.lastAction = "sold " .. tostring(n) .. " fruit"
        return n
    end
    return 0
end

-- THROUGHPUT FIX: inventory caps at MaxFruitCapacity (100) and the server only accepts
-- ~20-25 collects/sec. So harvest in a tight cycle and SELL THE MOMENT the pack is full —
-- never idle holding a full inventory. Firing faster than the server's rate just gets
-- dropped (delay=0 collected LESS), so harvestDelay paces each collect.
local function stepHarvest()
    Stats.state = "HARVEST"
    local sell = (S.autoFarm or S.autoSell)
    local list = ripeHarvests()
    if #list == 0 then
        if sell and fruitCount() >= math.min(S.sellAt or 85, maxFruitCap()) then
            pcall(sellAllNow)
        end
        return
    end
    local cap = maxFruitCap()
    local sellAt = math.min(S.sellAt or 85, cap)
    local d = S.harvestDelay or 0
    -- fire a fresh batch of collects (the firing time lets the async collects materialize
    -- into the pack), stop if the pack is genuinely full, then sell the whole batch at once.
    for _, h in ipairs(list) do
        if not (S.autoFarm or S.autoHarvest) then break end
        if picked(S.onlyHarvest) and not S.onlyHarvest[h.name] then continue end
        if S.dontHarvest[h.name] then continue end
        if S.neverSellFruit[h.name] or S.neverSellMut[h.mutation] then continue end
        if fruitCount() >= cap - 1 then break end
        pcall(function() fireFast("Garden.CollectFruit", h.plantId, h.fruitId) end)
        Stats.harvested += 1; Stats.lastAction = "harvested " .. tostring(h.name or "fruit")
        if d > 0 then task.wait(math.min(d, 0.03)) end
        if sell and fruitCount() >= sellAt then break end
    end
    if sell and fruitCount() >= sellAt then pcall(sellAllNow) end
end

local function stepSell()       -- sell-only mode (when Auto-Harvest is off)
    if not due("sell", math.min(tonumber(S.sellInterval) or 15, 1)) then return end
    if fruitCount() < math.min(S.sellAt or 85, maxFruitCap()) then return end
    local n = sellAllNow()
    if n > 0 then warn("[Sold] " .. n .. " items") end
end

local function stepExpand()
    if not due("expand", 12) then return end
    fire("Actions.ExpandGarden")        -- server/client-gates affordability itself
end
local function stepDaily()
    if not due("daily", 60) then return end
    fire("NPCS.CheckDailyDeal"); task.wait(0.3); fire("NPCS.UseDailyDealAll")
end

task.spawn(function()
    while not S.killed do
        if S.autoFarm or S.autoBuy     then pcall(stepBuy) end
        if S.autoFarm or S.autoPlant   then pcall(stepPlant) end
        if S.autoFarm or S.autoExpand  then pcall(stepExpand) end
        if S.autoFarm or S.autoDaily   then pcall(stepDaily) end
        task.wait(0.08)
    end
end)

-- dedicated harvest+sell loop: tight cycle so a big backlog drains at the server's max
-- collect rate (never blocked behind buy/plant/expand on the slow master loop).
task.spawn(function()
    while not S.killed do
        if S.autoFarm or S.autoHarvest then
            pcall(stepHarvest)
            task.wait(0.02)
        elseif S.autoSell then
            pcall(stepSell)
            task.wait(0.05)
        else
            task.wait(0.4)
        end
    end
end)

-- // ============================================================ \\ --
-- //                       BOOSTS (passive)                      \\ --
-- // ============================================================ \\ --
-- Auto-Sprinkler: place every owned sprinkler tool, spread across the plot
loopOn(function() return S.autoSprinkler end, function() return S.sprinklerInterval end, function()
    local pid = myPlotId(); if not pid then return end
    local placed = existingPlantPositions()  -- avoid clustering
    for _, t in ipairs(toolsByAttr("Sprinkler")) do
        if not S.autoSprinkler then break end
        local hum = humanoid(); if not hum then break end
        pcall(function() hum:EquipTool(t) end)
        task.wait(0.22)
        t = heldToolByAttr("Sprinkler"); if not t then break end
        local grid = plantGrid(8)
        for _, pos in ipairs(grid) do
            local far = true
            for _, op in ipairs(placed) do if (pos - op).Magnitude < 12 then far = false; break end end
            if far then
                fire("Place.PlaceSprinkler", pos, t:GetAttribute("Sprinkler"), t, pid)
                Stats.sprinklers += 1; placed[#placed + 1] = pos; task.wait(0.3)
                break
            end
        end
    end
    pcall(function() humanoid():UnequipTools() end)
end)

-- Auto-Water: use watering can over planted crops
loopOn(function() return S.autoWater end, function() return S.waterInterval end, function()
    local t = equipByAttr("WateringCan"); if not t then return end
    local name = t:GetAttribute("WateringCan")
    for _, pos in ipairs(existingPlantPositions()) do
        if not S.autoWater then break end
        fire("WateringCan.UseWateringCan", pos - Vector3.new(0, 0.3, 0), name, t)
        Stats.watered += 1; task.wait(jitter(0.15, 0.3))
    end
end)

-- Auto-Skill: keep spending skill points into the selected stats
loopOn(function() return S.autoSkill end, 6, function()
    if not picked(S.skillStats) then return end
    for stat in pairs(S.skillStats) do
        if not S.autoSkill then break end
        fire("SkillPoints.SpendSkillPoint", stat); task.wait(0.25)
    end
end)

-- // ============================================================ \\ --
-- //                          PETS                               \\ --
-- // ============================================================ \\ --
local function ownedPetNames()
    local names, seen = {}, {}
    for nm in pairs(invNames("Pets")) do if not seen[nm] then seen[nm] = true; names[#names + 1] = nm end end
    for _, t in ipairs(toolsByAttr("PetId")) do
        local nm = t:GetAttribute("PetName") or t.Name
        if nm and not seen[nm] then seen[nm] = true; names[#names + 1] = nm end
    end
    table.sort(names); return names
end
local function equippedPetCount()
    local ok, list = fire("Pets.GetEquippedPets")
    if ok and type(list) == "table" then
        local n = 0; for _ in pairs(list) do n += 1 end; return n
    end
    return 0
end
local function petToolsByName(name)
    local out = {}
    for _, t in ipairs(toolsByAttr("PetId")) do
        local nm = t:GetAttribute("PetName") or t.Name
        if (not name) or nm == name or t.Name == name then out[#out + 1] = t end
    end
    return out
end
local function doubleClickPetTool(tool)
    local hum = humanoid()
    if not (hum and tool) then return false end
    pcall(function() hum:EquipTool(tool) end)
    task.wait(0.18)
    pcall(function() tool:Activate() end)
    task.wait(0.12)
    pcall(function() tool:Activate() end)
    task.wait(0.2)
    return true
end
local petEquipCooldown = {}
local petMissingCooldown = {}
local function hasOwnedPet(name)
    if not name or name == "" then return false end
    if invNames("Pets")[name] then return true end
    return #petToolsByName(name) > 0
end
local function equipPetByName(name)
    if not hasOwnedPet(name) then
        if os.clock() - (petMissingCooldown[name] or 0) > 60 then
            petMissingCooldown[name] = os.clock()
            warn("[Pets] Skip equip; not in inventory: " .. tostring(name))
        end
        return false
    end
    if os.clock() - (petEquipCooldown[name] or 0) < 45 then return false end
    petEquipCooldown[name] = os.clock()
    -- Fast path: game's networking action, if it works for current runtime.
    fire("Pets.RequestEquipByName", name)
    task.wait(0.12)
    -- Fallback for runtimes where pet equip is client-tool driven: equip + double-click/activate pet tool.
    for _, tool in ipairs(petToolsByName(name)) do
        if doubleClickPetTool(tool) then return true end
    end
    return false
end
loopOn(function() return S.autoEquipPets end, 12, function()
    local cap = tonumber(LocalPlayer:GetAttribute("MaxEquippedPets")) or 3
    local have = equippedPetCount()
    if have >= cap then return end
    local order = {}
    if picked(S.equipPets) then for nm in pairs(S.equipPets) do if hasOwnedPet(nm) then order[#order + 1] = nm end end else order = ownedPetNames() end
    for _, nm in ipairs(order) do
        if not S.autoEquipPets or have >= cap then break end
        if equipPetByName(nm) then have += 1 end
        task.wait(0.35)
    end
end)
loopOn(function() return S.autoPetSlot end, 20, function()
    fire("Pets.RequestPurchasePetSlot")
end)
-- Auto-Buy world pets: scan all wild pets, filter by selected Pet to equip priority when set, then TP once.
-- In the stable GUI, the pet priority dropdown doubles as the world-pet buy target filter.
local petBuyCooldown = {}
loopOn(function() return S.autoBuyPets end, function() return S.petBuyInterval end, function()
    local cash = getSheckles()
    local best = nil
    local targetMap = picked(S.buyPets) and S.buyPets or S.equipPets
    local useTargets = picked(targetMap)
    for _, w in ipairs(wildPets()) do
        local petName = tostring(w.name or "")
        local targetOk = (not useTargets) or targetMap[petName]
        local key = petName .. ":" .. tostring(w.price or 0)
        local fresh = os.clock() - (petBuyCooldown[key] or 0) > math.max(8, S.petBuyInterval or 5)
        if targetOk and w.owner == 0 and w.price > 0 and w.price <= S.maxPetPrice and cash >= w.price and fresh then
            if (not best) or w.price < best.price then best = w end
        end
    end
    if not best then
        Stats.petLast = useTargets and ("no target from buy/equip list") or "no valid target"
        return
    end
    local key = tostring(best.name or "pet") .. ":" .. tostring(best.price or 0)
    petBuyCooldown[key] = os.clock()
    Stats.petLast = string.format("target %s @ %s", tostring(best.name or "?"), fmt(best.price or 0)); Stats.lastAction = "pet target " .. tostring(best.name or "?"); Stats.state = "PET"
    if S.petTeleport and best.pos then
        atPosition(best.pos, function() fire("Pets.WildPetTame", best.part) end)
    else
        fire("Pets.WildPetTame", best.part)
    end
    Stats.tamed += 1
end)
loopOn(function() return S.autoSellPets end, 4, function()
    if not picked(S.sellPets) then return end
    for _, t in ipairs(toolsByAttr("PetId")) do
        if not S.autoSellPets then break end
        local nm = t:GetAttribute("PetName") or t.Name
        if S.sellPets[nm] then
            -- Never sell a pet that was already held/equipped before this sell pass.
            local wasHeld = t.Parent == LocalPlayer.Character
            if wasHeld then task.wait(0.2); continue end
            local hum = humanoid()
            if hum then pcall(function() hum:EquipTool(t) end); task.wait(0.25) end
            fire("NPCS.SellPet", t:GetAttribute("PetId")); task.wait(0.3)
        end
    end
end)

-- // ============================================================ \\ --
-- //                  EGGS / CRATES / SEED PACKS                 \\ --
-- // ============================================================ \\ --
local function openAll(category, path)
    for nm, count in pairs(invNames(category)) do
        if S.killed then break end
        for _ = 1, math.min(count, 25) do
            local ok, res = fire(path, nm)
            if not ok then break end
            if type(res) == "table" and res.Success == false then break end
            Stats.opened += 1; task.wait(jitter(0.25, 0.5))
        end
    end
end
loopOn(function() return S.autoEgg  end, function() return S.openInterval end, function() openAll("Eggs", "Egg.OpenEgg") end)
loopOn(function() return S.autoCrate end, function() return S.openInterval end, function() openAll("Crates", "Crate.OpenCrate") end)
loopOn(function() return S.autoPack  end, function() return S.openInterval end, function() openAll("SeedPacks", "SeedPack.OpenSeedPack") end)

-- // ============================================================ \\ --
-- //                      SHOP (gear)                            \\ --
-- // ============================================================ \\ --
loopOn(function() return S.autoGear end, function() return S.gearInterval end, function()
    if not picked(S.gearBuy) then return end
    for name in pairs(S.gearBuy) do
        if not S.autoGear then break end
        local stock = stockOf("GearShop", name)
        if stock == nil or stock > 0 then
            fire("GearShop.PurchaseGear", name); task.wait(jitter(0.2, 0.4))
        end
    end
end)

-- // ============================================================ \\ --
-- //                     STEAL (PvP, night)                      \\ --
-- // ============================================================ \\ --
-- Instant steal: for HoldDuration==0 prompts the game fires BeginSteal+CompleteSteal
-- back-to-back (no hold). Server-side steal is proximity-gated like the prompt, so
-- teleport to the fruit unless disabled.
local function hrpNow() local c = LocalPlayer.Character; return c and c:FindFirstChild("HumanoidRootPart") end
loopOn(function() return S.autoSteal end, 1.5, function()
    if not isNight() then return end
    for _, f in ipairs(stealable()) do
        if not (S.autoSteal and isNight()) then break end
        -- 1) go to the fruit (proximity is server-gated) and steal it
        if S.stealTeleport and f.pos then
            local hrp = hrpNow(); if hrp then pcall(function() hrp.CFrame = CFrame.new(f.pos + Vector3.new(0, 4, 0)) end); task.wait(0.4) end
        end
        fire("Steal.BeginSteal", f.owner, f.plantId, f.fruitId)
        fire("Steal.CompleteSteal")
        Stats.stolen += 1
        -- 2) carry it home: standing in own garden zone banks it (CarryingStolenFruit clears)
        if S.stealReturnBase then
            local base = myBasePos()
            local hrp = hrpNow()
            if base and hrp then
                pcall(function() hrp.CFrame = CFrame.new(base + Vector3.new(0, 4, 0)) end)
                local t0 = os.clock()
                while LocalPlayer:GetAttribute("CarryingStolenFruit") and os.clock() - t0 < 3 and S.autoSteal do task.wait(0.15) end
            end
        end
        if (S.stealDelay or 0) > 0 then task.wait(S.stealDelay) end
    end
end)

-- // ============================================================ \\ --
-- //                  MISC (mail / gifts / hop / codes)          \\ --
-- // ============================================================ \\ --
loopOn(function() return S.autoMail end, 30, function()
    local ok, box = fire("Mailbox.OpenInbox")
    if ok and type(box) == "table" then
        local mb = box.Mailbox or box.Inbox or box
        for id, entry in pairs(mb) do
            if not S.autoMail then break end
            if type(entry) == "table" and (entry.Claimed == true or entry.IsClaimed == true) then
                -- skip already claimed
            else
                fire("Mailbox.Claim", id); task.wait(0.3)
            end
        end
    end
end)
loopOn(function() return S.autoMail and S.mailSendTo ~= "" and type(S.mailSend) == "table" and #S.mailSend > 0 end, function() return math.max(10, S.mailSendEvery or 45) end, function()
    -- Guarded best-effort mail send. If game args differ, it fails silently/logs instead of spamming.
    for _, item in ipairs(S.mailSend) do
        if S.mailSendTo == "" then break end
        local itemName = type(item) == "table" and item.Item or item
        local count = type(item) == "table" and (tonumber(item.Count) or 1) or 1
        if type(itemName) == "string" and itemName ~= "" then
            local ok = fire("Mailbox.Send", S.mailSendTo, itemName, count)
            if ok then Stats.Mailed = (Stats.Mailed or 0) + count; task.wait(0.5) else warn("[Mail] Send failed/unsupported for " .. itemName) end
        end
    end
end)
-- accept incoming gifts automatically
pcall(function()
    local g = action("Gifting.Prompted")
    if g and g.OnClientEvent then
        g.OnClientEvent:Connect(function(fromPlayer)
            if S.autoAcceptGift and fromPlayer then pcall(function() fire("Gifting.Response", fromPlayer, true) end) end
        end)
    end
end)
-- Server-hop is intentionally guarded: this remote can migrate/rejoin the player.
loopOn(function() return S.autoHop and S.allowServerHop end, function() return math.max(300, S.hopInterval) end, function()
    if S.hopInterval > 0 and S.allowServerHop then fire("AntiAfk.RequestHop") end
end)

-- Anti-AFK: two layers. Some executors miss LocalPlayer.Idled, so also pulse safely every 60s.
local lastAntiAfkPulse = 0
local function antiAfkPulse(reason)
    if S.killed or not S.antiAfk then return end
    local now = os.clock()
    if now - lastAntiAfkPulse < 8 then return end
    lastAntiAfkPulse = now
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
        VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame or CFrame.new())
        task.wait(0.05)
        VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame or CFrame.new())
    end)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
        task.wait(0.03)
        vim:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
    end)
    if reason then warn("[Anti-AFK] pulse: " .. tostring(reason)) end
end

if VirtualUser then
    LocalPlayer.Idled:Connect(function()
        antiAfkPulse("Idled")
    end)
end

task.spawn(function()
    while not S.killed do
        task.wait(60)
        antiAfkPulse("timer")
    end
end)
-- codes
local CODE_LIST = {}                  -- add known GAG2 codes here
local triedCodes = {}
local function redeemCodes(list)
    local n = 0
    for _, code in ipairs(list) do
        if code ~= "" and not triedCodes[code] then
            local ok, res = fire("Settings.SubmitCode", code)
            triedCodes[code] = true
            if ok and res == true then n += 1; Stats.codes += 1 end
            task.wait(0.4)
        end
    end
    return n
end
loopOn(function() return S.autoCodes end, 120, function() redeemCodes(CODE_LIST) end)

-- // ============================================================ \\ --
-- //                       PERFORMANCE                           \\ --
-- // ============================================================ \\ --
local _fpsApplied = false
local _ultraPerformanceApplied = false
local _ultraPerformanceGui = nil

local function getPlayerGuiSafe()
    return LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
end

function applyUltraPerformance(on)
    S.ultraPerformance = on == true
    if not S.ultraPerformance then
        pcall(function() RunService:Set3dRenderingEnabled(true) end)
        if _ultraPerformanceGui then pcall(function() _ultraPerformanceGui:Destroy() end); _ultraPerformanceGui = nil end
        if setfpscap then pcall(setfpscap, 30) end
        warn("[Performance] Ultra Performance OFF (3D restored if executor supports it)")
        return
    end

    if setfpscap then pcall(setfpscap, 10) end
    pcall(function() RunService:Set3dRenderingEnabled(false) end)
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1
        Lighting.Brightness = 0
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)

    pcall(function()
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") or d:IsA("Beam") then
                d.Enabled = false
            elseif d:IsA("BasePart") or d:IsA("Decal") or d:IsA("Texture") then
                d.Transparency = 1
            elseif d:IsA("SpecialMesh") then
                d.MeshId = ""
                d.TextureId = ""
            end
        end
    end)

    pcall(function()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                for _, d in ipairs(plr.Character:GetDescendants()) do
                    if d:IsA("BasePart") or d:IsA("Decal") then d.Transparency = 1 end
                end
            end
        end
    end)

    local pg = getPlayerGuiSafe()
    if pg and not _ultraPerformanceGui then
        _ultraPerformanceGui = Instance.new("ScreenGui")
        _ultraPerformanceGui.Name = "GAG_UltraPerformanceOverlay"
        _ultraPerformanceGui.IgnoreGuiInset = true
        _ultraPerformanceGui.ResetOnSpawn = false
        _ultraPerformanceGui.DisplayOrder = 998
        local bg = Instance.new("Frame")
        bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        bg.BorderSizePixel = 0
        bg.Size = UDim2.fromScale(1, 1)
        bg.Parent = _ultraPerformanceGui
        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.Text = "Ultra Performance ON\n3D disabled / hidden — GUI tetap aktif"
        label.TextColor3 = Color3.fromRGB(140, 255, 170)
        label.TextSize = 18
        label.TextWrapped = true
        label.Size = UDim2.new(1, -40, 0, 80)
        label.Position = UDim2.new(0, 20, 0.5, -40)
        label.Parent = bg
        _ultraPerformanceGui.Parent = pg
    end
    _ultraPerformanceApplied = true
    warn("[Performance] Ultra Performance ON: 3D disabled/hidden")
end

function applyFpsBoost(on)
    if on and not _fpsApplied then
        _fpsApplied = true
        pcall(function()
            Lighting.GlobalShadows = false; Lighting.FogEnd = 1e6
            for _, e in ipairs(Lighting:GetChildren()) do
                if e:IsA("BloomEffect") or e:IsA("SunRaysEffect") or e:IsA("DepthOfFieldEffect") or e:IsA("BlurEffect") then e.Enabled = false end
            end
            if sethiddenproperty then pcall(sethiddenproperty, Lighting, "Technology", 1) end
            settings().Rendering.QualityLevel = 1
        end)
        task.spawn(function()
            for _, d in ipairs(Workspace:GetDescendants()) do
                if not S.fpsBoost then break end
                if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") then d.Enabled = false
                elseif d:IsA("Texture") or d:IsA("Decal") then pcall(function() d.Transparency = 1 end) end
            end
        end)
    end
end

-- // ============================================================ \\ --
-- // ============================================================ \ --
-- //                    WEBHOOK REPORTING                        \ --
-- // ============================================================ \ --
local httpRequest = (syn and syn.request) or http_request or request or (http and http.request)
local function gardenScanSummary(limit)
    limit = limit or 6
    local plot = myPlot()
    local plants = plot and plot:FindFirstChild("Plants")
    if not plants then return "no plot/plants detected" end
    local counts, total = {}, 0
    for _, obj in ipairs(plants:GetDescendants()) do
        local name = obj:GetAttribute("PlantName") or obj:GetAttribute("SeedName") or obj:GetAttribute("Name")
        if not name and obj:IsA("Model") then name = obj.Name end
        if name and name ~= "" then counts[tostring(name)] = (counts[tostring(name)] or 0) + 1; total += 1 end
    end
    local rows = {}
    for name, count in pairs(counts) do rows[#rows + 1] = { name = name, count = count } end
    table.sort(rows, function(a, b) return a.count > b.count end)
    local out = {}
    for i = 1, math.min(limit, #rows) do out[#out + 1] = rows[i].name .. " x" .. tostring(rows[i].count) end
    return (#out > 0 and table.concat(out, ", ") or "empty") .. " | total " .. tostring(total)
end

local function hms(sec)
    sec = math.floor(sec); local h = sec//3600; local m = (sec%3600)//60
    if h > 0 then return string.format("%dh %dm", h, m) end
    if m > 0 then return string.format("%dm %ds", m, sec%60) end
    return sec .. "s"
end
local function webhookReady(silent)
    if not httpRequest then if not silent then warn("[Webhook] Executor exposes no HTTP request fn") end; return false end
    if not string.match(S.webhookUrl or "", "^https?://") then if not silent then warn("[Webhook] Set a valid webhook URL") end; return false end
    return true
end
local function webhookPost(payload, silent)
    if not webhookReady(silent) then return false end
    local ok, res = pcall(function()
        return httpRequest({ Url = S.webhookUrl, Method = "POST",
            Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode(payload) })
    end)
    local code = ok and res and (res.StatusCode or res.Status or res.status_code)
    local good = ok and (code == nil or code == 200 or code == 204)
    if not good and not silent then warn("[Webhook] Failed (" .. tostring(code) .. ")") end
    return good, code
end
local function sendWebhook(isTest)
    if not (isTest or S.webhookReport) then return false end
    local payload = { username = "Grow a Garden 2", embeds = { {
        title = (isTest and "🧪 Test Report — " or "🌱 Farm Report — ") .. LocalPlayer.Name, color = isTest and 3447003 or 5763719,
        fields = {
            { name = "💰 Sheckles", value = fmt(getSheckles()), inline = true },
            { name = "🪙 Tokens",   value = fmt(getTokens()),   inline = true },
            { name = "🌾 Plot",     value = tostring((myPlot() and myPlot().Name) or "?"), inline = true },
            { name = "📊 Session",  value = string.format("bought %d · planted %d · harvested %d · sold %d (+%s)",
                Stats.bought, Stats.planted, Stats.harvested, Stats.sold, fmt(Stats.earned)), inline = false },
            { name = "✨ Extras",   value = string.format("sprinklers %d · watered %d · tamed %d · opened %d · stolen %d",
                Stats.sprinklers, Stats.watered, Stats.tamed, Stats.opened, Stats.stolen), inline = false },
            { name = "⚙️ Runtime", value = string.format("preset %s · farm %s · fruit %s/%s", tostring(currentPreset), tostring(S.autoFarm or S.autoBuy or S.autoPlant or S.autoHarvest or S.autoSell), tostring(fruitCount()), tostring(maxFruitCap())), inline = false },
            { name = "Settings", value = string.format("seedBuy %s · plant %s · equipPets %s · worldPets %s · petTP %s · sellAt %s", tostring(S.autoBuy), tostring(S.autoPlant), tostring(S.autoEquipPets), tostring(S.autoBuyPets), tostring(S.petTeleport), tostring(S.sellAt)), inline = false },
            { name = "Garden Scan", value = gardenScanSummary(8), inline = false },
            { name = "⏱️ Uptime",   value = hms(os.clock() - Stats.startAt), inline = true },
        }, footer = { text = "WalkyHub · GAG2" },
    } } }
    local good, code = webhookPost(payload, false)
    if good then
        Stats.webhookLastOk = os.clock(); Stats.webhookLastError = "none"
    else
        Stats.webhookLastError = tostring(code or "request failed")
    end
    if isTest then warn("[Webhook] " .. (good and "Test sent ✅" or ("Failed (" .. tostring(code) .. ")"))) end
    return good
end
local _lastWebhookEventAt = {}
local function sendWebhookEvent(kind, title, description, color)
    if not (S.webhookEnabled and S.webhookEvents) then return false end
    if not webhookReady(true) then return false end
    local now = os.clock()
    if now - (_lastWebhookEventAt[kind] or 0) < 8 then return false end
    _lastWebhookEventAt[kind] = now
    return webhookPost({ username = "Grow a Garden 2", embeds = { {
        title = title, description = description, color = color or 5763719,
        fields = {
            { name = "Player", value = LocalPlayer.Name, inline = true },
            { name = "Preset", value = tostring(currentPreset), inline = true },
            { name = "Uptime", value = hms(os.clock() - Stats.startAt), inline = true },
        }, footer = { text = "WalkyHub · live event" },
    } } }, true)
end
task.spawn(function()
    local lastReport = 0
    while not S.killed do
        local interval = math.max(30, tonumber(S.webhookInterval) or 300)
        Stats.webhookNextAt = lastReport + interval
        if S.webhookEnabled and S.webhookReport and webhookReady(true) and os.clock() - lastReport >= interval then
            lastReport = os.clock()
            Stats.webhookNextAt = lastReport + interval
            sendWebhook(false)
        elseif S.webhookEnabled and S.webhookReport and not webhookReady(true) then
            Stats.webhookLastError = "webhook not ready"
        end
        task.wait(1)
    end
end)

-- lightweight live webhook event log (delta-based, low spam)
task.spawn(function()
    while not S.killed do
        if S.webhookEnabled and S.webhookEvents and webhookReady(true) then
            if Stats.bought > WebhookStats.bought then
                sendWebhookEvent("bought", "🛒 Seeds bought", "+" .. tostring(Stats.bought - WebhookStats.bought) .. " seeds bought (total " .. tostring(Stats.bought) .. ")", 5763719)
                WebhookStats.bought = Stats.bought
            end
            if Stats.planted > WebhookStats.planted then
                sendWebhookEvent("planted", "🌱 Seeds planted", "+" .. tostring(Stats.planted - WebhookStats.planted) .. " planted (total " .. tostring(Stats.planted) .. ")", 5763719)
                WebhookStats.planted = Stats.planted
            end
            if Stats.harvested > WebhookStats.harvested then
                sendWebhookEvent("harvested", "✅ Fruit harvested", "+" .. tostring(Stats.harvested - WebhookStats.harvested) .. " harvested (total " .. tostring(Stats.harvested) .. ")", 3066993)
                WebhookStats.harvested = Stats.harvested
            end
            if Stats.sold > WebhookStats.sold then
                sendWebhookEvent("sold", "💰 Fruit sold", "+" .. tostring(Stats.sold - WebhookStats.sold) .. " sold · earned +" .. fmt(Stats.earned), 16766720)
                WebhookStats.sold = Stats.sold
            end
            if Stats.opened > WebhookStats.opened then
                sendWebhookEvent("opened", "📦 Items opened", "+" .. tostring(Stats.opened - WebhookStats.opened) .. " opened (total " .. tostring(Stats.opened) .. ")", 10181046)
                WebhookStats.opened = Stats.opened
            end
            if Stats.stolen > WebhookStats.stolen then
                sendWebhookEvent("stolen", "🌙 Fruit stolen", "+" .. tostring(Stats.stolen - WebhookStats.stolen) .. " stolen (total " .. tostring(Stats.stolen) .. ")", 15158332)
                WebhookStats.stolen = Stats.stolen
            end
        end
        task.wait(10)
    end
end)

-- // ============================================================ \\ --
-- Create UI with KrassUI
local ui = KrassUI.new({
    Name = "Grow a Garden 2",
    Subtitle = "WalkyHub | Full Auto",
    Theme = "Black",
    Accent = Color3.fromRGB(145, 160, 255),
    Accent2 = Color3.fromRGB(95, 105, 255),
    Size = UDim2.fromOffset(860, 620),
    ToggleKey = Enum.KeyCode.LeftControl,
})

local dashboardTab = ui:Tab("Dashboard")
local farmTab = ui:Tab("Farm")
local boostsTab = ui:Tab("Boosts")
local petsTab = ui:Tab("Pets")
local openTab = ui:Tab("Eggs & Crates")
local shopTab = ui:Tab("Shop")
local stealTab = ui:Tab("Steal")
local miscTab = ui:Tab("Misc")
local settingsTab = ui:Tab("Settings")

-- Sidebar kiri sekarang scrollable: mouse wheel / drag di area tab untuk akses tab bawah.
local currentPreset = "Manual"
local function setManualOff()
    S.autoFarm = false; S.autoBuy = false; S.autoPlant = false; S.autoHarvest = false; S.autoSell = false
    S.autoExpand = false; S.autoDaily = false; S.autoSprinkler = false; S.autoWater = false; S.autoSkill = false
    S.autoEquipPets = false; S.autoPetSlot = false; S.autoBuyPets = false; S.autoSellPets = false
    for k in pairs(S.buyPets) do S.buyPets[k] = nil end
    S.autoEgg = false; S.autoCrate = false; S.autoPack = false; S.autoGear = false; S.autoSteal = false
    S.autoMail = false; S.autoAcceptGift = false; S.autoHop = false; S.allowServerHop = false; S.autoCodes = false; S.ultraPerformance = false
    currentPreset = "Manual"
    warn("[GAGConfig] Manual selected: all automation OFF")
end
local function applyGuiPreset(name)
    if name == "Manual" then
        setManualOff()
    else
        gagApplyConfig({ Preset = name })
        currentPreset = name
        warn("[GAGConfig] GUI preset selected: " .. tostring(name))
    end
    pcall(function() ui:Notify("Preset", currentPreset, 2.5) end)
end

local function copyDebugInfo()
    local result = string.format("[GAG DEBUG]\nPreset=%s\nFarm=%s AutoBuy=%s AutoEquipPets=%s\nBuySeeds=%s BuyInterval=%s BuyPerTick=%s\nEquipPets=%s OwnedPets=%s EquippedCount=%s\nSeedBuyActions=%s\nFruit=%s/%s\nStats=bought:%s planted:%s harvested:%s sold:%s earned:%s\nAutoHop=%s AllowServerHop=%s\nUltra=%s",
        tostring(currentPreset), tostring(S.autoFarm or S.autoBuy or S.autoPlant or S.autoHarvest or S.autoSell), tostring(S.autoBuy), tostring(S.autoEquipPets),
        selectedNames(S.buySeeds), tostring(S.buyInterval), tostring(S.buyPerTick),
        selectedNames(S.equipPets), table.concat(ownedPetNames(), ", "), tostring(equippedPetCount()),
        availableActions(SEED_BUY_ACTIONS),
        tostring(fruitCount()), tostring(maxFruitCap()),
        tostring(Stats.bought), tostring(Stats.planted), tostring(Stats.harvested), tostring(Stats.sold), tostring(Stats.earned),
        tostring(S.autoHop), tostring(S.allowServerHop), tostring(S.ultraPerformance))
    local ok = false
    if setclipboard then ok = pcall(setclipboard, result) elseif toclipboard then ok = pcall(toclipboard, result) end
    warn(ok and "[Debug] Copied debug info" or result)
    return result
end

-- ---- DASHBOARD ----
local secDash = dashboardTab:Section("Quick Status")
local dashPreset = secDash:Label("Preset: Manual")
local dashFarm = secDash:Label("Farm: OFF")
local dashCash = secDash:Label("Sheckles: …")
local dashStats = secDash:Label("bought 0 · planted 0 · harvested 0 · sold 0")

local secQuick = dashboardTab:Section("Quick Presets")
secQuick:Button("Manual / Stop All", function() applyGuiPreset("Manual") end)
secQuick:Button("Starter — akun baru", function() applyGuiPreset("Starter") end)
secQuick:Button("Balanced — umum", function() applyGuiPreset("Balanced") end)
secQuick:Button("Rich — akun besar", function() applyGuiPreset("Rich") end)
secQuick:Button("Alt → Main", function() applyGuiPreset("AltToMain") end)
secQuick:Button("Low PC / HP berat", function() applyGuiPreset("LowPC") end)
secQuick:Button("AFK Farm Mode", function()
    applyGuiPreset("Balanced")
    S.autoHop = false; S.allowServerHop = false; S.antiAfk = true; S.fpsBoost = true
    pcall(function() applyFpsBoost(true) end)
    pcall(function() applyUltraPerformance(true) end)
    warn("[Preset] AFK Farm Mode ON")
end)

local secDashTips = dashboardTab:Section("Alur Pakai")
secDashTips:Label("1) Pilih preset di atas, atau tetap Manual")
secDashTips:Label("2) Atur detail di tab Farm / Boosts / Pets")
secDashTips:Label("3) Server-hop = rejoin, biarkan OFF kalau AFK")
secDashTips:Button("Copy Debug Info", copyDebugInfo)

-- ---- FARM ----
local secStatus = farmTab:Section("Status")
local plotLabel = secStatus:Label("Plot: …")
local cashLabel = secStatus:Label("Sheckles: …")
local statLabel = secStatus:Label("—")

local secMaster = farmTab:Section("Auto-Farm (master)")
secMaster:Toggle("Auto-Farm (buy+plant+harvest+sell+expand)", false, function(v) S.autoFarm = v end)
secMaster:Toggle("Auto-Expand garden", false, function(v) S.autoExpand = v end)
secMaster:Toggle("Auto-Daily deals", false, function(v) S.autoDaily = v end)

local secBuy = farmTab:Section("Buy seeds")
secBuy:Dropdown("Seed to buy", SEED_NAMES, "Carrot", function(sel) pickMulti(sel, S.buySeeds) end)
secBuy:Toggle("Auto-Buy selected", false, function(v) S.autoBuy = v end)
secBuy:Slider("Buy interval (s)", 1, 0.2, 30, function(v) S.buyInterval = v end)
secBuy:Slider("Max buys / seed / pass", 8, 1, 50, function(v) S.buyPerTick = v end)

local secPlant = farmTab:Section("Plant / Harvest / Sell")
local plantOpts = { "Best owned" }; for _, n in ipairs(SEED_NAMES) do plantOpts[#plantOpts + 1] = n end
secPlant:Dropdown("Seed to plant", plantOpts, "Best owned", function(v) S.plantSeed = v end)
secPlant:Toggle("Auto-Plant (fill plot)", false, function(v) S.autoPlant = v end)
secPlant:Slider("Plant spacing (studs)", 4, 2, 10, function(v) S.plantSpacing = v end)
secPlant:Toggle("Auto-Harvest ripe fruit", false, function(v) S.autoHarvest = v end)
secPlant:Slider("Harvest pace (s/fruit · 0.02≈max)", 0.01, 0, 0.2, function(v) S.harvestDelay = v end)
secPlant:Toggle("Auto-Sell (sell when fruit >= Sell At)", false, function(v) S.autoSell = v end)
secPlant:Slider("Sell At fruit count", 85, 1, 200, function(v) S.sellAt = math.floor(v) end)
secPlant:Slider("Sell interval (s, sell-only mode)", 15, 3, 120, function(v) S.sellInterval = v end)
secPlant:Toggle("Auto-Pot grown plants", false, function(v) S.autoPot = v end)

-- ---- BOOSTS ----
local secSpr = boostsTab:Section("Sprinklers & Water")
secSpr:Toggle("Auto-place Sprinklers", false, function(v) S.autoSprinkler = v end)
secSpr:Slider("Sprinkler interval (s)", 30, 10, 120, function(v) S.sprinklerInterval = v end)
secSpr:Toggle("Auto-Watering Can", false, function(v) S.autoWater = v end)
secSpr:Slider("Water interval (s)", 8, 2, 60, function(v) S.waterInterval = v end)

local secSkill = boostsTab:Section("Skill points")
secSkill:Dropdown("Stats to level", { "BaseSpeed", "BaseJump", "ShovelPower", "MaxBackpack" }, {}, function(sel) pickMulti(sel, S.skillStats) end)
secSkill:Button("Auto Upgrade Inventory", function() S.skillStats = { MaxBackpack = true }; S.autoSkill = true; warn("[Skill] Auto Upgrade Inventory ON") end)
secSkill:Toggle("Auto-Spend skill points", false, function(v) S.autoSkill = v end)

-- ---- PETS ----
local secPet = petsTab:Section("Pets")
secPet:Dropdown("Pet to equip priority", ownedPetNames(), "", function(sel) pickMulti(sel, S.equipPets) end)
secPet:Toggle("Auto-Equip pets (to slot cap)", false, function(v) S.autoEquipPets = v end)
secPet:Toggle("Auto-Buy pet slots", false, function(v) S.autoPetSlot = v end)
secPet:Toggle("Auto-Buy world pets (walk up & buy)", false, function(v) S.autoBuyPets = v end)
secPet:Slider("Max pet price (Sheckles)", 25000, 1000, 1000000, function(v) S.maxPetPrice = v end)
secPet:Toggle("Teleport to pet (needed to buy)", true, function(v) S.petTeleport = v end)
secPet:Slider("Pet buy interval (s)", 5, 2, 60, function(v) S.petBuyInterval = v end)

local secPetSell = petsTab:Section("Sell pets")
secPetSell:Dropdown("Pets to sell", ownedPetNames(), {}, function(sel) pickMulti(sel, S.sellPets) end)
secPetSell:Toggle("Auto-Sell selected pets", false, function(v) S.autoSellPets = v end)

-- ---- EGGS & CRATES ----
local secOpen = openTab:Section("Auto-Open")
secOpen:Toggle("Auto-Open Eggs", false, function(v) S.autoEgg = v end)
secOpen:Toggle("Auto-Open Crates", false, function(v) S.autoCrate = v end)
secOpen:Toggle("Auto-Open Seed Packs", false, function(v) S.autoPack = v end)
secOpen:Slider("Open interval (s)", 4, 1, 30, function(v) S.openInterval = v end)
local secOpenInfo = openTab:Section("Info")
secOpenInfo:Label("Opens everything you own in each")
secOpenInfo:Label("category. Confirm is automatic.")

-- ---- SHOP ----
local secShop = shopTab:Section("Gear shop")
secShop:Dropdown("Gear to buy", GEAR_NAMES, {}, function(sel) pickMulti(sel, S.gearBuy) end)
secShop:Toggle("Auto-Buy selected gear", false, function(v) S.autoGear = v end)
secShop:Slider("Gear buy interval (s)", 10, 2, 60, function(v) S.gearInterval = v end)

-- ---- STEAL ----
local secSteal = stealTab:Section("Auto-Steal (night only)")
secSteal:Toggle("Auto-Steal others' ripe fruit", false, function(v) S.autoSteal = v end)
secSteal:Toggle("Teleport to fruit (needed to steal)", true, function(v) S.stealTeleport = v end)
secSteal:Toggle("Return to base after each fruit (banks it)", true, function(v) S.stealReturnBase = v end)
secSteal:Slider("Steal speed (delay/fruit, 0=instant)", 0.05, 0, 1, function(v) S.stealDelay = v end)
local secStealInfo = stealTab:Section("Info")
secStealInfo:Label("Night-only · TP to fruit, steal,")
secStealInfo:Label("then TP home to bank each one.")

-- ---- MISC ----
local secMail = miscTab:Section("Mail & Gifts")
secMail:Toggle("Auto-Claim mailbox", false, function(v) S.autoMail = v end)
secMail:Toggle("Auto-Accept gifts", false, function(v) S.autoAcceptGift = v end)

local secHop = miscTab:Section("Session")
secHop:Toggle("Anti-AFK (never idle-kicked)", true, function(v) S.antiAfk = v end)
secHop:Toggle("Auto server-hop (rejoin)", false, function(v) S.autoHop = v; S.allowServerHop = v end)
secHop:Slider("Hop every (min, 0=off)", 0, 0, 120, function(v) S.hopInterval = v * 60 end)

local secCode = miscTab:Section("Codes")
secCode:Textbox("Redeem a code", "enter code", function(text)
    if text and text ~= "" then
        local ok, res = fire("Settings.SubmitCode", text)
        warn("[Code] " .. ((ok and res == true) and ("Redeemed: " .. text) or ("Invalid: " .. text)))
    end
end)
secCode:Toggle("Auto-redeem code list", false, function(v) S.autoCodes = v end)

-- ---- SETTINGS ----
local secPreset = settingsTab:Section("Preset Farm")
secPreset:Label("Default Manual: pilih preset kalau mau auto-set farm")
secPreset:Dropdown("Select preset", { "Manual", "Starter", "Balanced", "Rich", "AltToMain", "LowPC" }, "Manual", applyGuiPreset)

local secPerf = settingsTab:Section("Performance & Interface")
secPerf:Toggle("FPS Boost (low graphics)", false, function(v) S.fpsBoost = v; applyFpsBoost(v) end)
secPerf:Toggle("Ultra Performance (Disable 3D)", false, function(v) applyUltraPerformance(v) end)
secPerf:Label("Ultra mode bikin layar hitam/minimal tapi GUI tetap jalan")
secPerf:Button("Unload hub (stops everything)", function() S.killed = true; pcall(function() applyUltraPerformance(false) end); pcall(function() ui:Destroy() end) end)

local secWeb = settingsTab:Section("Discord Webhook")
secWeb:Textbox("Webhook URL", "https://discord.com/api/webhooks/...", function(t) S.webhookUrl = t or "" end)
secWeb:Toggle("Enable webhook", false, function(v) S.webhookEnabled = v end)
secWeb:Toggle("Send live action logs", true, function(v) S.webhookEvents = v end)
secWeb:Toggle("Send interval reports", true, function(v) S.webhookReport = v end)
secWeb:Slider("Report interval (min)", 5, 1, 60, function(v) S.webhookInterval = math.max(30, v * 60) end)
secWeb:Button("Send test report", function() task.spawn(function() sendWebhook(true) end) end)

local secInfo = settingsTab:Section("Info")
secInfo:Label("Grow a Garden 2 · WalkyHub")
secInfo:Label("Hotkey: Left Ctrl toggles UI")

-- Apply _G.GAGConfig after UI controls finish their default callbacks.
task.defer(function()
    task.wait(0.25)
    local env = type(getgenv) == "function" and getgenv() or _G
    local cfg = env.GAGConfig or _G.GAGConfig or {}
    gagApplyConfig(cfg)
    currentPreset = cfg.Preset or cfg.preset or currentPreset
end)


-- Auto-Pot loop (own grown plants flagged via prompt tag is rare; pot all listed plants)
loopOn(function() return S.autoPot end, 10, function()
    local plot = myPlot(); local plants = plot and plot:FindFirstChild("Plants")
    if not plants then return end
    for _, m in ipairs(plants:GetChildren()) do
        if not S.autoPot then break end
        local pid = m:GetAttribute("PlantId") or m.Name
        if pid then fire("Garden.PotPlant", tostring(pid)); task.wait(0.3) end
    end
end)

-- live status
task.spawn(function()
    while not S.killed do
        local p = myPlot()
        local cashText = string.format("Sheckles: %s · Tokens: %s", fmt(getSheckles()), fmt(getTokens()))
        local statText = string.format("bought %d · planted %d · harvested %d · sold %d (+%s)",
            Stats.bought, Stats.planted, Stats.harvested, Stats.sold, fmt(Stats.earned))
        local farmOn = S.autoFarm or S.autoBuy or S.autoPlant or S.autoHarvest or S.autoSell or S.autoExpand or S.autoDaily
        pcall(function() plotLabel:Set("Plot: " .. (p and p.Name or "?")) end)
        pcall(function() cashLabel:Set(cashText) end)
        pcall(function() statLabel:Set(statText) end)
        pcall(function() dashPreset:Set("Preset: " .. tostring(currentPreset)) end)
        local webhookText = S.webhookEnabled and ("ON next " .. hms(math.max(0, (Stats.webhookNextAt or 0) - os.clock())) .. " err " .. tostring(Stats.webhookLastError or "none")) or "OFF"
        pcall(function() dashFarm:Set("Farm: " .. (farmOn and "ON" or "OFF")) end)
        pcall(function() dashCash:Set(cashText) end)
        pcall(function() dashState:Set("State: " .. tostring(Stats.state or "IDLE") .. " | Last: " .. tostring(Stats.lastAction or "idle") .. " | Webhook: " .. webhookText) end)
        pcall(function() dashFruit:Set("Fruit: " .. tostring(fruitCount()) .. "/" .. tostring(maxFruitCap())) end)
        pcall(function() dashPlants:Set("Plants: " .. gardenScanSummary(4)) end)
        pcall(function() dashSettings:Set("Settings: buy " .. tostring(S.autoBuy) .. " plant " .. tostring(S.autoPlant) .. " equipPet " .. tostring(S.autoEquipPets) .. " worldPet " .. tostring(S.autoBuyPets)) end)
        pcall(function() dashPets:Set("Pets: equipped " .. tostring(equippedPetCount()) .. " | buy " .. selectedNames(S.buyPets) .. " | " .. tostring(Stats.petLast or "idle")) end)
        pcall(function() dashStats:Set(statText) end)
        task.wait(2)
    end
end)

pcall(function()
    if getgenv then getgenv().WalkyGAG2 = {
        S = S, Stats = Stats, Net = Net, fire = fire, action = action,
        catalog = CATALOG, gearNames = GEAR_NAMES, myPlot = myPlot, replica = replica,
        ripeHarvests = ripeHarvests, stealable = stealable, wildPets = wildPets,
        toolsByAttr = toolsByAttr, plantGrid = plantGrid, ownedPetNames = ownedPetNames, myBasePos = myBasePos,
        stepHarvest = stepHarvest, fireFast = fireFast, fruitCount = fruitCount, sellAllNow = sellAllNow, maxFruitCap = maxFruitCap,
        unload = function() S.killed = true; pcall(function() ui:Destroy() end) end,
    } end
end)

warn("[WalkyHub] GAG2 full-auto loaded · " .. #SEED_NAMES .. " seeds · " .. #GEAR_NAMES .. " gear")
print("[WalkyHub] Grow a Garden 2 full-auto loaded.")
