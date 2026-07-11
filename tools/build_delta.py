from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUNTIME = ROOT / 'GAG_Autofarm_Delta.lua'
OUT_DIR = ROOT / 'dist'
OUT = OUT_DIR / 'GAG_Autofarm_Delta_FINAL.lua'


def build() -> Path:
    """Sync the tested canonical Delta runtime into the distributable artifact.

    The modular files in src/ are retained as source/reference material, but the
    executor-compatible root runtime is the release authority because it is the
    file referenced by the public GitHub/jsDelivr loadstrings.
    """
    if not RUNTIME.is_file():
        raise SystemExit(f'missing canonical runtime: {RUNTIME}')
    text = RUNTIME.read_text(encoding='utf-8').replace('\r\n', '\n')
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    OUT.write_text(text, encoding='utf-8', newline='\n')
    return OUT


if __name__ == '__main__':
    out = build()
    text = out.read_text(encoding='utf-8')
    print(f'built {out}')
    print(f'bytes={out.stat().st_size} lines={text.count(chr(10)) + 1}')
