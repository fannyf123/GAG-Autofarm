repeat task.wait() until game:IsLoaded()
task.wait(3)

local ok, err = pcall(function()
    local src = game:HttpGet("https://raw.githubusercontent.com/fannyf123/GAG-Autofarm/main/GAG_Autofarm_Delta.lua", false)
    local fn, compileErr = loadstring(src)
    if type(fn) == "function" then
        fn()
    else
        warn("[GAG] loader compile failed: " .. tostring(compileErr))
    end
end)

if not ok then
    warn("[GAG] delta-autoexec failed: " .. tostring(err))
end
