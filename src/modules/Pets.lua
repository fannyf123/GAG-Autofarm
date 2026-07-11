--[[
    Pets Module - Grow a Garden Autofarm
    Handles buying, equipping, and managing pets.
    
    Pet abilities:
      - Unicorn:        2x Rainbow mutation chance
      - GoldenDragonfly: 2x Gold mutation chance
      - Deer:           Faster crop growth
      - Robin:          Drops random seeds periodically
]]

local Pets = {}

-- Private state
local running = false
local currentSlots = 0
local maxSlots = 3

-- References (set on Init)
local GAG = nil
local Config = nil
local Utils = nil

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function Log(msg)
    if Utils and Utils.Log then
        Utils.Log("[Pets] " .. tostring(msg))
    end
end

local function GetConfig(key)
    if Config and Config.Get then
        return Config.Get(key)
    end
    return nil
end

local function GetNestedConfig(section, key)
    if Config and Config.GetNested then
        return Config.GetNested(section, key)
    end
    return nil
end

local function Sleep(seconds)
    if Utils and Utils.Sleep then
        Utils.Sleep(seconds)
    else
        task.wait(seconds or 1)
    end
end

local function FireRemote(remoteName, ...)
    if Utils and Utils.FireRemote then
        return Utils.FireRemote(remoteName, ...)
    end
    -- Fallback: try to find and fire directly
    local ok, err = pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        local remotes = rs:FindFirstChild("Remotes") or rs:FindFirstChild("Events")
        if remotes then
            local remote = remotes:FindFirstChild(remoteName)
            if remote and remote:IsA("RemoteEvent") then
                remote:FireServer(...)
            end
        end
    end)
    return ok
end

local function InvokeRemote(remoteName, ...)
    if Utils and Utils.InvokeRemote then
        return Utils.InvokeRemote(remoteName, ...)
    end
    local ok, result = pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        local remotes = rs:FindFirstChild("Remotes") or rs:FindFirstChild("Events")
        if remotes then
            local remote = remotes:FindFirstChild(remoteName)
            if remote and remote:IsA("RemoteFunction") then
                return remote:InvokeServer(...)
            end
        end
        return nil
    end)
    return ok and result or nil
end

---------------------------------------------------------------------------
-- GetOwnedPets
-- Returns a table of { petName = count } for all owned pets.
---------------------------------------------------------------------------

function Pets.GetOwnedPets()
    local owned = {}
    
    local ok = pcall(function()
        local player = GAG and GAG.Player
        if not player then return end
        
        -- Try multiple storage locations for pet data
        local petsFolder = player:FindFirstChild("Pets")
            or player:FindFirstChild("OwnedPets")
            or player:FindFirstChild("PetInventory")
        
        if petsFolder then
            for _, pet in ipairs(petsFolder:GetChildren()) do
                local petName = pet.Name
                local count = pet:GetAttribute("Count") or 1
                owned[petName] = (owned[petName] or 0) + count
            end
        end
        
        -- Also check leaderstats or data folders
        local data = player:FindFirstChild("Data") or player:FindFirstChild("PlayerData")
        if data then
            local petsData = data:FindFirstChild("Pets")
            if petsData and petsData:IsA("ModuleScript") then
                -- Some games store pet data in modules
                local modData = require(petsData)
                if type(modData) == "table" then
                    for petName, count in pairs(modData) do
                        owned[petName] = (owned[petName] or 0) + count
                    end
                end
            end
        end
        
        -- Check replicated pet data
        local petData = player:FindFirstChild("PetData")
        if petData and petData:IsA("ValueBase") then
            local dataValue = petData.Value
            if type(dataValue) == "string" then
                local decoded = game:GetService("HttpService"):JSONDecode(dataValue)
                if type(decoded) == "table" then
                    for petName, count in pairs(decoded) do
                        owned[petName] = (owned[petName] or 0) + count
                    end
                end
            end
        end
    end)
    
    if not ok then
        Log("Warning: Could not read owned pets data.")
    end
    
    return owned
end

---------------------------------------------------------------------------
-- GetEquippedPets
-- Returns a table of { petName = count } for currently equipped pets.
---------------------------------------------------------------------------

function Pets.GetEquippedPets()
    local equipped = {}
    
    local ok = pcall(function()
        local player = GAG and GAG.Player
        if not player then return end
        
        local char = GAG.Character or player.Character
        if not char then return end
        
        -- Look for equipped pets in character
        local petsFolder = char:FindFirstChild("EquippedPets")
            or char:FindFirstChild("ActivePets")
            or char:FindFirstChild("Pets")
        
        if petsFolder then
            for _, pet in ipairs(petsFolder:GetChildren()) do
                local petName = pet.Name
                equipped[petName] = (equipped[petName] or 0) + 1
            end
        end
        
        -- Also check player's equipped pets folder
        local playerEquipped = player:FindFirstChild("EquippedPets")
        if playerEquipped then
            for _, pet in ipairs(playerEquipped:GetChildren()) do
                local petName = pet.Name
                equipped[petName] = (equipped[petName] or 0) + 1
            end
        end
    end)
    
    return equipped
end

---------------------------------------------------------------------------
-- GetPetSlotCount
-- Returns { current = N, max = N } for pet slots.
---------------------------------------------------------------------------

function Pets.GetPetSlotCount()
    local result = { current = 0, max = 3 }
    
    local ok = pcall(function()
        local player = GAG and GAG.Player
        if not player then return end
        
        -- Try to get slot count from player data
        local slots = player:FindFirstChild("PetSlots")
            or player:FindFirstChild("MaxPetSlots")
        
        if slots and slots:IsA("ValueBase") then
            result.max = slots.Value
        end
        
        -- Count currently equipped
        local equipped = Pets.GetEquippedPets()
        local count = 0
        for _, c in pairs(equipped) do
            count = count + c
        end
        result.current = count
    end)
    
    -- Update module state
    currentSlots = result.current
    maxSlots = result.max
    
    return result
end

---------------------------------------------------------------------------
-- BuyPet
-- Attempts to buy a specific pet from the pet shop.
---------------------------------------------------------------------------

function Pets.BuyPet(petName)
    if not petName or petName == "" then return false end
    
    Log("Attempting to buy pet: " .. petName)
    
    -- Fire buy remote (common patterns for Grow a Garden)
    local success = FireRemote("WildPetTame", petName)
    
    if success ~= false then
        GAG.Stats.PetsBought = (GAG.Stats.PetsBought or 0) + 1
        Log("Bought pet: " .. petName .. " (Total: " .. GAG.Stats.PetsBought .. ")")
        return true
    end
    
    -- Try with table argument format
    success = success or FireRemote("WildPetTame", { PetName = petName })
    
    if success ~= false then
        GAG.Stats.PetsBought = (GAG.Stats.PetsBought or 0) + 1
        Log("Bought pet: " .. petName .. " (Total: " .. GAG.Stats.PetsBought .. ")")
        return true
    end
    
    Log("Failed to buy pet: " .. petName)
    return false
end

---------------------------------------------------------------------------
-- EquipPet
-- Attempts to equip a pet. Returns true if successful.
---------------------------------------------------------------------------

function Pets.EquipPet(petName)
    if not petName or petName == "" then return false end
    
    -- Check slot availability
    local slots = Pets.GetPetSlotCount()
    if slots.current >= slots.max then
        Log("No pet slots available! (" .. slots.current .. "/" .. slots.max .. ")")
        return false
    end
    
    Log("Equipping pet: " .. petName)
    
    -- Fire equip remote
    local success = FireRemote("EquipPet", petName)
    
    if success ~= false then
        currentSlots = currentSlots + 1
        Log("Equipped pet: " .. petName .. " (Slots: " .. currentSlots .. "/" .. maxSlots .. ")")
        return true
    end
    
    -- Try with index-based equip
    local equipIndex = slots.current + 1
    success = success or FireRemote("EquipPet", petName, equipIndex)
    
    if success ~= false then
        currentSlots = currentSlots + 1
        Log("Equipped pet: " .. petName .. " in slot " .. equipIndex)
        return true
    end
    
    Log("Failed to equip pet: " .. petName)
    return false
end

---------------------------------------------------------------------------
-- UnequipPet
-- Attempts to unequip a pet.
---------------------------------------------------------------------------

function Pets.UnequipPet(petName)
    if not petName or petName == "" then return false end
    
    Log("Unequipping pet: " .. petName)
    
    local success = FireRemote("UnequipPet", petName)
    
    if success ~= false then
        currentSlots = math.max(0, currentSlots - 1)
        Log("Unequipped pet: " .. petName)
        return true
    end
    
    Log("Failed to unequip pet: " .. petName)
    return false
end

---------------------------------------------------------------------------
-- BuyPetSlot
-- Buys an additional pet slot if conditions are met.
---------------------------------------------------------------------------

function Pets.BuyPetSlot()
    -- Check if auto buy slots is enabled
    local autoBuy = GetNestedConfig("Pets", "Auto Buy Slots")
    if not autoBuy then return false end
    
    -- Check current vs max slots
    local slots = Pets.GetPetSlotCount()
    local configMax = GetNestedConfig("Pets", "Max Pet Slots") or 6
    
    if slots.max >= configMax then
        Log("Already at max pet slots (" .. slots.max .. "/" .. configMax .. ")")
        return false
    end
    
    if slots.max >= 6 then
        Log("Cannot buy more slots — already at game max (6)")
        return false
    end
    
    Log("Buying pet slot... (Current max: " .. slots.max .. ")")
    
    -- Fire buy slot remote
    local success = FireRemote("BuyPetSlot")
    
    if success ~= false then
        maxSlots = maxSlots + 1
        Log("Pet slot purchased! New max: " .. maxSlots)
        return true
    end
    
    Log("Failed to buy pet slot.")
    return false
end

---------------------------------------------------------------------------
-- ProcessPetBuyConfig
-- Handles the "Pets.Buy" mixed config:
--   Plain names in array = buy unlimited (one per tick)
--   Map entries ["Name"] = N = stop at N owned
---------------------------------------------------------------------------

function Pets.ProcessPetBuyConfig()
    local buyConfig = GetNestedConfig("Pets", "Buy")
    if not buyConfig or type(buyConfig) ~= "table" then return end
    
    local owned = Pets.GetOwnedPets()
    
    for key, value in pairs(buyConfig) do
        if type(key) == "number" then
            -- Array entry: plain name, buy one at a time, keep buying
            local petName = value
            if type(petName) == "string" and petName ~= "" then
                Pets.BuyPet(petName)
                Sleep(0.5)
            end
        elseif type(key) == "string" then
            -- Map entry: ["PetName"] = targetCount
            local petName = key
            local targetCount = tonumber(value) or 0
            local currentCount = owned[petName] or 0
            
            if currentCount < targetCount then
                Log("Pet '" .. petName .. "': " .. currentCount .. "/" .. targetCount .. " — buying...")
                Pets.BuyPet(petName)
                Sleep(0.5)
            else
                Log("Pet '" .. petName .. "' already at target (" .. currentCount .. "/" .. targetCount .. ")")
            end
        end
    end
end

---------------------------------------------------------------------------
-- ProcessPetEquipConfig
-- Handles the "Pets.Equip" config:
--   Map of petName = count to equip
--   Equips pets in priority order, fills slots up to max
---------------------------------------------------------------------------

function Pets.ProcessPetEquipConfig()
    local equipConfig = GetNestedConfig("Pets", "Equip")
    if not equipConfig or type(equipConfig) ~= "table" then return end
    
    local owned = Pets.GetOwnedPets()
    local equipped = Pets.GetEquippedPets()
    local slots = Pets.GetPetSlotCount()
    
    -- Build equip queue with priority (order matters for Lua tables)
	local equipQueue = {}
	-- Preserve array order for the documented { "Unicorn", "Deer" } form.
	-- Each entry is a priority, so fill available slots with it before the next.
	for _, petName in ipairs(equipConfig) do
		if type(petName) == "string" and petName ~= "" then
			table.insert(equipQueue, { name = petName, target = slots.max })
		end
	end
	for petName, targetCount in pairs(equipConfig) do
		if type(petName) == "string" and type(targetCount) == "number" then
			table.insert(equipQueue, { name = petName, target = targetCount })
		end
	end
    
    -- Process each pet type
    for _, entry in ipairs(equipQueue) do
        local petName = entry.name
        local targetCount = entry.target
        local ownedCount = owned[petName] or 0
        local equippedCount = equipped[petName] or 0
        
        -- Skip if not owned
        if ownedCount <= 0 then
            Log("Cannot equip '" .. petName .. "': not owned")
            continue
        end
        
        -- Calculate how many more to equip
        local toEquip = math.min(targetCount - equippedCount, ownedCount - equippedCount)
        
        if toEquip <= 0 then
            Log("Pet '" .. petName .. "': already equipped " .. equippedCount .. "/" .. targetCount)
            continue
        end
        
        -- Check slot availability
        local availableSlots = slots.max - slots.current
        if availableSlots <= 0 then
            Log("No pet slots available! Cannot equip more pets.")
            break
        end
        
        -- Equip up to available slots
        local actualEquip = math.min(toEquip, availableSlots)
        for i = 1, actualEquip do
            if slots.current >= slots.max then
                Log("Pet slots full, stopping equip.")
                return
            end
            
            local success = Pets.EquipPet(petName)
            if success then
                slots.current = slots.current + 1
            end
            
            Sleep(0.3)
        end
    end
end

---------------------------------------------------------------------------
-- PrintPetStatus
-- Logs current pet inventory and equipped status.
---------------------------------------------------------------------------

function Pets.PrintPetStatus()
    local owned = Pets.GetOwnedPets()
    local equipped = Pets.GetEquippedPets()
    local slots = Pets.GetPetSlotCount()
    
    Log("=== Pet Status ===")
    Log("Slots: " .. slots.current .. "/" .. slots.max)
    
    Log("Owned pets:")
    local hasOwned = false
    for petName, count in pairs(owned) do
        Log("  " .. petName .. " x" .. count)
        hasOwned = true
    end
    if not hasOwned then
        Log("  (none)")
    end
    
    Log("Equipped pets:")
    local hasEquipped = false
    for petName, count in pairs(equipped) do
        Log("  " .. petName .. " x" .. count)
        hasEquipped = true
    end
    if not hasEquipped then
        Log("  (none)")
    end
    
    Log("==================")
end

---------------------------------------------------------------------------
-- Init
-- Called once to set up module references.
---------------------------------------------------------------------------

function Pets.Init(gag)
    GAG = gag
    Config = GAG and GAG.Modules and GAG.Modules.Config
    Utils = GAG and GAG.Modules and GAG.Modules.Utils
    
    -- Initialize stats if not present
    if GAG and GAG.Stats then
        GAG.Stats.PetsBought = GAG.Stats.PetsBought or 0
    end
    
    Log("Pets module initialized.")
end

---------------------------------------------------------------------------
-- Start
-- Main loop: buy pets, equip pets, buy slots, repeat.
---------------------------------------------------------------------------

function Pets.Start(gag)
    if running then
        Log("Already running!")
        return
    end
    
    if gag then
        Pets.Init(gag)
    end
    
    running = true
    Log("Pets loop started.")
    
    -- Initial status print
    Pets.PrintPetStatus()
    
    while running do
        pcall(function()
            -- 1. Process buy config
            Pets.ProcessPetBuyConfig()
            
            -- 2. Process equip config
            Pets.ProcessPetEquipConfig()
            
            -- 3. Buy slots if needed
            Pets.BuyPetSlot()
        end)
        
        -- Sleep between iterations (pets don't need to be as fast as harvesting)
        Sleep(3)
    end
    
    Log("Pets loop stopped.")
end

---------------------------------------------------------------------------
-- Stop
-- Gracefully stops the main loop.
---------------------------------------------------------------------------

function Pets.Stop()
    running = false
    Log("Pets stop requested.")
end

---------------------------------------------------------------------------
-- IsRunning
---------------------------------------------------------------------------

function Pets.IsRunning()
    return running
end

---------------------------------------------------------------------------
-- GetStatus
-- Returns a summary table for the stats display.
---------------------------------------------------------------------------

function Pets.GetStatus()
    local owned = Pets.GetOwnedPets()
    local equipped = Pets.GetEquippedPets()
    local slots = Pets.GetPetSlotCount()
    
    local ownedCount = 0
    for _, c in pairs(owned) do ownedCount = ownedCount + c end
    
    return {
        Owned = ownedCount,
        Equipped = slots.current,
        MaxSlots = slots.max,
        PetsBought = GAG and GAG.Stats and GAG.Stats.PetsBought or 0,
    }
end

return Pets
