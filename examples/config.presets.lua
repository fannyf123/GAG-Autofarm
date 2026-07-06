-- Preset siap pakai untuk GAG Autofarm
-- Copy salah satu blok ke atas script sebelum run.

-- Starter — akun baru, biar duit cepet ngalir
_G.GAGConfig = {
    Preset = "Starter",
}

-- Balanced — cocok buat kebanyakan orang
-- _G.GAGConfig = {
--     Preset = "Balanced",
-- }

-- Rich — cari nilai gede, plot dibatasi biar nggak lag
-- _G.GAGConfig = {
--     Preset = "Rich",
-- }

-- Alt ke Main — farm + kirim otomatis
-- _G.GAGConfig = {
--     Preset = "AltToMain",
--     ["Mail"] = {
--         ["Send To"] = "USERNAME_AKUN_UTAMAMU",
--     },
-- }

-- PC Berat — tampilan paling ringan
-- _G.GAGConfig = {
--     Preset = "LowPC",
-- }

-- Contoh override lengkap
-- _G.GAGConfig = {
--     Preset = "Balanced",
--     ["Harvest"]  = { ["Sell At"] = 85, ["Sell Every"] = 40 },
--     ["Planting"] = {
--         ["Layout"] = "compact",
--         ["Minimum Seed"] = "Bamboo",
--         ["Keep Seeds"] = {
--             ["Dragon's Breath"] = 5,
--             ["Moon Bloom"] = 5,
--             ["Gold"] = 5,
--             ["Rainbow"] = 5,
--         },
--     },
--     ["Money"] = {
--         ["Keep Cash"] = 15000,
--         ["Auto Expand Plot"] = true,
--         ["Expand If Over"] = 1500000,
--         ["Auto Replace Plants"] = true,
--     },
--     ["Pets"] = {
--         ["Buy"] = { "Unicorn", "GoldenDragonfly", ["Deer"] = 6 },
--         ["Equip"] = { "Unicorn", "GoldenDragonfly", "Deer" },
--         ["Auto Buy Slots"] = true,
--     },
--     ["Gear"] = {
--         ["Keep Cash"] = 15000,
--         ["Sprinkler Coverage"] = "concentrate",
--         ["Place Sprinklers"] = { ["best"] = 4 },
--         ["Best Sprinkler Up To"] = "Rare Sprinkler",
--     },
--     ["Mail"] = {
--         ["Auto Claim"] = true,
--         ["Send To"] = "",
--         ["Send"] = {},
--     },
--     ["Performance"] = {
--         ["FPS Cap"] = 30,
--         ["Low Graphics"] = true,
--         ["Remove Other Gardens"] = true,
--         ["Hide Crop Visuals"] = true,
--         ["Hide Fruit Visuals"] = true,
--         ["Hide Players"] = true,
--     },
-- }
