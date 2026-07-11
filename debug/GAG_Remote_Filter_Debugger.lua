-- GAG filtered remote debugger for Delta-compatible executors.
-- It reports the same action metadata as the raw captures and, when supported,
-- records real Fire() arguments for the plant and shovel actions.

repeat task.wait() until game:IsLoaded()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local sharedEnv = type(getgenv) == "function" and getgenv() or _G

if sharedEnv.GAGRemoteFilterDebugger and sharedEnv.GAGRemoteFilterDebugger.active then
    warn("[GAG Debug] Filter debugger is already active. Run GAGRemoteFilterCopy() to copy its report.")
    return
end

local TARGETS = {
    "Shovel.UseShovel",
    "Plant.PlantSeed",
    "Place.PlaceSprinkler",
}

local state = {
    active = true,
    lines = {},
    calls = {},
    targetByAction = {},
    hookedFunctions = {},
}
sharedEnv.GAGRemoteFilterDebugger = state

local function add(line)
    state.lines[#state.lines + 1] = tostring(line)
    warn("[GAG Debug] " .. tostring(line))
end

local function valueText(value, depth, seen)
    depth = depth or 0
    seen = seen or {}
    local kind = typeof(value)

    if kind == "nil" or kind == "boolean" or kind == "number" then
        return tostring(value)
    end
    if kind == "string" then
        return string.format("%q", value)
    end
    if kind == "Instance" then
        local ok, fullName = pcall(function() return value:GetFullName() end)
        return "Instance(" .. (ok and fullName or value.Name) .. ")"
    end
    if kind ~= "table" then
        return kind .. "(" .. tostring(value) .. ")"
    end
    if depth >= 2 then return "table(...)" end
    if seen[value] then return "table(<cycle>)" end

    seen[value] = true
    local entries = {}
    local count = 0
    for key, item in pairs(value) do
        count = count + 1
        if count > 8 then
            entries[#entries + 1] = "..."
            break
        end
        entries[#entries + 1] = "[" .. valueText(key, depth + 1, seen) .. "]=" .. valueText(item, depth + 1, seen)
    end
    seen[value] = nil
    return "{" .. table.concat(entries, ", ") .. "}"
end

local function resolve(path)
    local current = state.network
    for part in string.gmatch(path, "[^%.]+") do
        if type(current) ~= "table" then return nil end
        current = current[part]
    end
    return current
end

local function copyReport()
    local report = table.concat(state.lines, "\n")
    local clipboard = setclipboard or toclipboard
    if type(clipboard) == "function" then
        local ok, err = pcall(clipboard, report)
        add(ok and "Report copied to clipboard." or ("Clipboard failed: " .. tostring(err)))
    else
        add("Clipboard API is unavailable; copy this executor console output.")
    end
    return report
end

sharedEnv.GAGRemoteFilterCopy = copyReport
sharedEnv.GAGRemoteFilterStop = function()
    state.active = false
    add("Capture stopped. Existing hooks now pass through without logging.")
end

local function summarizeAction(path, action)
    if type(action) ~= "table" then
        add(path .. " | MISSING")
        return
    end

    add(path .. " | present | Fire=" .. tostring(type(action.Fire) == "function"))
    for _, field in ipairs({ "Name", "Id", "ResponseTimeout", "Reads", "Writes", "ResponseReads", "ResponseWrites", "OnClientEvent" }) do
        local value = action[field]
        if value ~= nil then
            add(path .. "." .. field .. " | " .. typeof(value) .. " | " .. valueText(value))
        end
    end
end

local function installHook(path, action)
    local fire = action and action.Fire
    if type(fire) ~= "function" then
        add(path .. " | cannot hook: Fire is unavailable")
        return
    end

    state.targetByAction[action] = path
    if state.hookedFunctions[fire] then
        add(path .. " | shares an existing Fire hook")
        return
    end
    if type(hookfunction) ~= "function" then
        add(path .. " | passive mode: executor has no hookfunction")
        return
    end

    local original
    local function wrapped(...)
        local args = table.pack(...)
        local targetPath = state.targetByAction[args[1]]
        local shouldLog = state.active and targetPath ~= nil

        if shouldLog then
            state.calls[targetPath] = (state.calls[targetPath] or 0) + 1
            if state.calls[targetPath] <= 30 then
                local rendered = {}
                for index = 2, args.n do
                    rendered[#rendered + 1] = "arg" .. (index - 1) .. "=" .. valueText(args[index])
                end
                add(targetPath .. " | CALL #" .. state.calls[targetPath] .. " | " .. table.concat(rendered, " | "))
            elseif state.calls[targetPath] == 31 then
                add(targetPath .. " | further calls suppressed after 30 entries")
            end
        end

        local results = table.pack(original(...))
        if shouldLog and state.calls[targetPath] <= 30 then
            add(targetPath .. " | RESULT | " .. valueText(results[1]))
        end
        return table.unpack(results, 1, results.n)
    end

    local replacement = type(newcclosure) == "function" and newcclosure(wrapped) or wrapped
    original = hookfunction(fire, replacement)
    state.hookedFunctions[fire] = true
    add(path .. " | active hook installed")
end

local sharedModules = ReplicatedStorage:WaitForChild("SharedModules", 15)
local networkingModule = sharedModules and sharedModules:FindFirstChild("Networking")
if not networkingModule then
    add("Networking module not found. Confirm this is the expected Grow a Garden runtime.")
    copyReport()
    return
end

local ok, networkOrError = pcall(require, networkingModule)
if not ok or type(networkOrError) ~= "table" then
    add("Could not require Networking: " .. tostring(networkOrError))
    copyReport()
    return
end

state.network = networkOrError
add("=== GAG FILTERED REMOTE DEBUG ===")
for _, path in ipairs(TARGETS) do
    local action = resolve(path)
    summarizeAction(path, action)
    installHook(path, action)
end
add("Trigger one manual shovel, PlantSeed, and sprinkler placement action, then run GAGRemoteFilterCopy().")
copyReport()
