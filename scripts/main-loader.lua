local URL = "https://raw.githubusercontent.com/fannyf123/GAG-Autofarm/main/GAG_Autofarm_Delta.lua"

local function show(title, message)
    warn("[GAG] " .. tostring(title) .. ": " .. tostring(message))

    local ok = pcall(function()
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        if not player then return end

        local gui = Instance.new("ScreenGui")
        gui.Name = "GAG_Loader_Status"
        gui.ResetOnSpawn = false

        local frame = Instance.new("Frame")
        frame.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
        frame.BorderSizePixel = 0
        frame.Size = UDim2.new(1, -24, 0, 210)
        frame.Position = UDim2.new(0, 12, 0, 70)
        frame.Parent = gui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = frame

        local header = Instance.new("TextLabel")
        header.BackgroundTransparency = 1
        header.Font = Enum.Font.SourceSansBold
        header.Text = tostring(title)
        header.TextColor3 = Color3.fromRGB(255, 120, 120)
        header.TextSize = 20
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.Size = UDim2.new(1, -20, 0, 34)
        header.Position = UDim2.new(0, 10, 0, 8)
        header.Parent = frame

        local body = Instance.new("TextLabel")
        body.BackgroundTransparency = 1
        body.Font = Enum.Font.SourceSans
        body.Text = tostring(message)
        body.TextColor3 = Color3.fromRGB(235, 235, 235)
        body.TextSize = 15
        body.TextWrapped = true
        body.TextXAlignment = Enum.TextXAlignment.Left
        body.TextYAlignment = Enum.TextYAlignment.Top
        body.Size = UDim2.new(1, -20, 1, -54)
        body.Position = UDim2.new(0, 10, 0, 46)
        body.Parent = frame

        gui.Parent = player:WaitForChild("PlayerGui")
    end)

    return ok
end

repeat task.wait() until game:IsLoaded()
task.wait(2)

if type(loadstring) ~= "function" then
    show("GAG LOAD ERROR", "Executor tidak menyediakan loadstring.")
    return
end

local okHttp, source = pcall(function()
    -- Disable executor-side HTTP caching so each run receives the latest build.
    return game:HttpGet(URL, false)
end)

if not okHttp or type(source) ~= "string" or #source < 20 then
    show("GAG HTTP ERROR", source)
    return
end

local runner, compileError = loadstring(source)
if type(runner) ~= "function" then
    show("GAG COMPILE ERROR", compileError)
    return
end

local okRun, runError = pcall(runner)
if not okRun then
    show("GAG RUNTIME ERROR", runError)
end
