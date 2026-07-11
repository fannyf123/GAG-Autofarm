# Local Debug Captures

Raw captures imported from `D:/tmp_claude` are stored under `debug/captures/`.
They are intentionally Git-ignored: captures can contain transient player/world state and are useful locally for reverse-engineering and troubleshooting, but should not be published by default.

## Included capture roles

- `record.txt` — broad runtime/remote event capture.
- `pet.txt` — pet inventory, equip, and wild-pet events.
- `plant.txt` — planting-related capture used to validate `Plant.PlantSeed`.
- `mail.txt` — mailbox/claim events.
- `gearshop.txt` — gear shop events.
- `auctioneer.txt` — auctioneer/shop-related capture.
- `seedpack.txt` — seed-pack/opening events.

Before sharing any raw capture, scan it again for credentials, cookies, webhook URLs, and personally identifying state.

## Filtered live debugger

`GAG_Remote_Filter_Debugger.lua` is a targeted executor-side debugger for the
`Shovel.UseShovel`, `Plant.PlantSeed`, and `Place.PlaceSprinkler` call contracts. It copies a
filtered metadata report at startup and hooks real `Fire()` calls when the
executor supports `hookfunction`. After reproducing the action, run
`GAGRemoteFilterCopy()` and share the copied report.

The captured successful shovel call is
`Shovel.UseShovel(plantId, fruitId, shovelName, shovelTool)`; an empty string
is valid for `fruitId` when the target has no associated fruit.
