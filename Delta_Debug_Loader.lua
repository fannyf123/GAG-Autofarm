local URLS = {
    "https://raw.githubusercontent.com/fannyf123/GAG-Autofarm/main/GAG_Autofarm_Delta.lua",
    "https://cdn.jsdelivr.net/gh/fannyf123/GAG-Autofarm@main/GAG_Autofarm_Delta.lua",
    "https://fastly.jsdelivr.net/gh/fannyf123/GAG-Autofarm@main/GAG_Autofarm_Delta.lua",
    "https://raw.fastgit.org/fannyf123/GAG-Autofarm/main/GAG_Autofarm_Delta.lua",
}

local function copyResult(result)
    result = tostring(result or "")
    local ok = false
    if setclipboard then
        ok = pcall(setclipboard, result)
    elseif toclipboard then
        ok = pcall(toclipboard, result)
    end
    return ok
end

local function show(title, message)
    local result = "[" .. tostring(title) .. "]\n" .. tostring(message)
    copyResult(result)

    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local gui = Instance.new("ScreenGui")
    gui.Name = "GAG_Debug_Error"
    gui.ResetOnSpawn = false

    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(1, -24, 0, 330)
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

    local hint = Instance.new("TextLabel")
    hint.BackgroundTransparency = 1
    hint.Font = Enum.Font.SourceSans
    hint.Text = "Error otomatis dicopy kalau executor support. Klik COPY buat ulang."
    hint.TextColor3 = Color3.fromRGB(140, 220, 255)
    hint.TextSize = 14
    hint.TextXAlignment = Enum.TextXAlignment.Left
    hint.Size = UDim2.new(1, -20, 0, 22)
    hint.Position = UDim2.new(0, 10, 0, 38)
    hint.Parent = frame

    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.Font = Enum.Font.SourceSans
    text.Text = result
    text.TextColor3 = Color3.fromRGB(235, 235, 235)
    text.TextSize = 15
    text.TextWrapped = true
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.TextYAlignment = Enum.TextYAlignment.Top
    text.Size = UDim2.new(1, -20, 1, -104)
    text.Position = UDim2.new(0, 10, 0, 64)
    text.Parent = frame

    local copy = Instance.new("TextButton")
    copy.BackgroundColor3 = Color3.fromRGB(60, 120, 180)
    copy.BorderSizePixel = 0
    copy.Font = Enum.Font.SourceSansBold
    copy.Text = "COPY ERROR"
    copy.TextColor3 = Color3.fromRGB(255, 255, 255)
    copy.TextSize = 14
    copy.Size = UDim2.new(0, 120, 0, 30)
    copy.Position = UDim2.new(1, -220, 1, -40)
    copy.Parent = frame
    Instance.new("UICorner", copy).CornerRadius = UDim.new(0, 8)
    copy.MouseButton1Click:Connect(function()
        if copyResult(result) then
            copy.Text = "COPIED"
            task.delay(1.5, function()
                if copy then copy.Text = "COPY ERROR" end
            end)
        else
            copy.Text = "COPY FAILED"
        end
    end)

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

local function fetchFirst()
    local errors = {}
    for _, url in ipairs(URLS) do
        local ok, source = pcall(function()
            return game:HttpGet(url, true)
        end)
        if ok and type(source) == "string" and source:find("Grow a Garden", 1, true) then
            return source, url
        end
        errors[#errors + 1] = url .. " -> " .. tostring(source)
        task.wait(0.5)
    end
    return nil, table.concat(errors, "\n\n")
end

local source, info = fetchFirst()
if not source then
    show("GAG HTTP ERROR", info)
    return
end

local fn, compileErr = loadstring(source)
if not fn then
    show("GAG COMPILE ERROR", tostring(compileErr) .. "\n\nLoaded from: " .. tostring(info))
    return
end

local okRun, runErr = xpcall(fn, function(err)
    if debug and debug.traceback then
        return debug.traceback(err)
    end
    return tostring(err)
end)

if not okRun then
    show("GAG RUNTIME ERROR", tostring(runErr) .. "\n\nLoaded from: " .. tostring(info))
end
