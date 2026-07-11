from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TEMPLATE = ROOT / "src" / "loader.lua"
OUT = ROOT / "dist" / "GAG_Autofarm_Modular.lua"
MODULES = (
    "Config", "Utils", "Harvest", "Plant", "BuySeeds",
    "Pets", "Gear", "Mail", "Misc", "Stats",
)


def lua_literal(text: str) -> str:
    """Choose a long-string delimiter that cannot terminate module source."""
    level = ""
    while f"]{level}]" in text:
        level += "="
    return f"[{level}[{text}]{level}]"


def build() -> Path:
    source = TEMPLATE.read_text(encoding="utf-8")
    for name in MODULES:
        marker = f"[[--#include {name}.lua]]"
        module = (ROOT / "src" / "modules" / f"{name}.lua").read_text(encoding="utf-8")
        if marker not in source:
            raise SystemExit(f"missing marker: {marker}")
        source = source.replace(marker, lua_literal(module), 1)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(source, encoding="utf-8", newline="\n")
    return OUT


if __name__ == "__main__":
    output = build()
    print(f"built {output}")
