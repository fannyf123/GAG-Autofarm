local URL = "https://raw.githubusercontent.com/fannyf123/GAG-Autofarm/main/GAG_Autofarm_Delta.lua"

local function show(title, message)
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local gui = Instance.new("ScreenGui")
    gui.Name = "GAG_Debug_Error"
    gui.ResetOnSpawn = false

    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(1, -24, 0, 260)
    frame.Position = UDim2.new(0, 12, 0, 80)
    frame.Parent = gui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local header = Instance.new("TextLabel")
    header.BackgroundTransparency = 1
    header.Font = Enum.Font.SourceSansBold
    header.Text = title
    header.TextColor3 = Color3.fromRGB(255, 100, 100)
    header.TextSize = 20
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Size = UDim2.new(1, -20, 0, 34)
    header.Position = UDim2.new(0, 10, 0, 8)
    header.Parent = frame

    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.Font = Enum.Font.SourceSans
    text.Text = tostring(message)
    text.TextColor3 = Color3.fromRGB(235, 235, 235)
    text.TextSize = 15
    text.TextWrapped = true
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.TextYAlignment = Enum.TextYAlignment.Top
    text.Size = UDim2.new(1, -20, 1, -58)
    text.Position = UDim2.new(0, 10, 0, 48)
    text.Parent = frame

    local close = Instance.new("TextButton")
    close.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
    close.BorderSizePixel = 0
    close.Font = Enum.Font.SourceSansBold
    close.Text = "CLOSE"
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
    close.TextSize = 14
    close.Size = UDim2.new(0, 80, 0, 30)
    close.Position = UDim2.new(1, -90, 1, -40)
    close.Parent = frame
    Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)
    close.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)

    gui.Parent = player:WaitForChild("PlayerGui")
end

local okHttp, source = pcall(function()
    return game:HttpGet(URL, true)
end)

if not okHttp or type(source) ~= "string" or #source < 10 then
    show("GAG HTTP ERROR", source)
    return
end

local fn, compileErr = loadstring(source)
if not fn then
    show("GAG COMPILE ERROR", compileErr)
    return
end

local okRun, runErr = xpcall(fn, function(err)
    if debug and debug.traceback then
        return debug.traceback(err)
    end
    return tostring(err)
end)

if not okRun then
    show("GAG RUNTIME ERROR", runErr)
end
