from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
LOADER = ROOT / 'loader.lua'
MODULE_DIR = ROOT / 'modules'
OUT_DIR = ROOT / 'dist'
OUT = OUT_DIR / 'GAG_Autofarm_Delta_FINAL.lua'

MODULES = [
    'Config',
    'Utils',
    'Harvest',
    'Plant',
    'BuySeeds',
    'Pets',
    'Gear',
    'Mail',
    'Misc',
    'Stats',
]


def lua_long_string(source: str) -> str:
    level = 0
    while True:
        eq = '=' * level
        close = ']' + eq + ']'
        if close not in source:
            return '[' + eq + '[' + source + ']' + eq + ']'
        level += 1


def build() -> Path:
    src = LOADER.read_text(encoding='utf-8')
    for name in MODULES:
        mod_path = MODULE_DIR / f'{name}.lua'
        mod_src = mod_path.read_text(encoding='utf-8').replace('\r\n', '\n')
        placeholder = f'[[--#include {name}.lua]]'
        replacement = lua_long_string(mod_src)
        if placeholder not in src:
            raise SystemExit(f'missing placeholder: {placeholder}')
        src = src.replace(placeholder, replacement, 1)

    banner = '-- Built by tools/build_delta.py. Do not edit generated output directly.\n'
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    OUT.write_text(banner + src, encoding='utf-8', newline='\n')
    return OUT


if __name__ == '__main__':
    out = build()
    text = out.read_text(encoding='utf-8')
    print(f'built {out}')
    print(f'bytes={out.stat().st_size} lines={text.count(chr(10)) + 1}')
