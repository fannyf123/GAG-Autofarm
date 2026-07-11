# GAG-Autofarm

Roblox/Delta single-file runtime, with modular source and local build tooling.

## Quick use

The stable public runtime URL remains root-level for compatibility:

```lua
loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/fannyf123/GAG-Autofarm@main/GAG_Autofarm_Delta.lua"))()
```

## Workspace layout

- `GAG_Autofarm_Delta.lua` — canonical pasteable runtime / public loader target.
- `dist/` — generated Delta mirrors, including the optional modular build.
- `src/` — modular authoring source (`loader.lua`, modules); build it before pasting.
- `tools/` — build and static validation scripts.
- `debug/` — diagnostic loader utilities.
- `docs/` — configuration guide and examples.
- `archive/` — known working baseline kept for reference.
- `scripts/` — optional local loader/autoexec helpers.
- `memory/` — local session notes; ignored by Git.

## Validate

```bash
python tools/gag_static_check.py
python tools/build_delta.py
python tools/build_modular_source.py
```

Do not edit `dist/GAG_Autofarm_Delta_FINAL.lua` directly; generate it with the builder.
`dist/GAG_Autofarm_Modular.lua` is generated from `src/loader.lua` and its modules.
