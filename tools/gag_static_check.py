from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
LUA_FILES = sorted([p for p in ROOT.rglob('*.lua') if '.git' not in p.parts])

BAD_PATTERNS = {
    'FindFirstChildWhichAisa typo': r'FindFirstChildWhichAisa',
    'missing GAG.Modules.Log call': r'GAG\.Modules\.Log\s*\(',
    'old compact key PlantPlan': r'Config\.Get\("PlantPlan"\)|GAG\.Config\.Get\("PlantPlan"\)',
    'old compact key ShouldPlant': r'Config\.Get\("ShouldPlant"\)|GAG\.Config\.Get\("ShouldPlant"\)',
    'old compact key AutoExpandPlot': r'Config\.Get\("AutoExpandPlot"\)|GAG\.Config\.Get\("AutoExpandPlot"\)',
    'old compact key NeverSell': r'Config\.Get\("NeverSell"\)|GAG\.Config\.Get\("NeverSell"\)',
    'old compact key WaitForMutation': r'Config\.Get\("WaitForMutation"\)|GAG\.Config\.Get\("WaitForMutation"\)',
    'old compact key BuySeeds': r'Config\.Get\("BuySeeds"\)|GAG\.Config\.Get\("BuySeeds"\)',
    'old compact key AutoPlant': r'Config\.Get\("AutoPlant"\)|GAG\.Config\.Get\("AutoPlant"\)',
    'old compact key KeepCash': r'Config\.Get\("KeepCash"\)|GAG\.Config\.Get\("KeepCash"\)',
}

errors = []
for path in LUA_FILES:
    text = path.read_text(encoding='utf-8', errors='replace')
    rel = path.relative_to(ROOT)
    for label, pattern in BAD_PATTERNS.items():
        for m in re.finditer(pattern, text):
            line = text.count('\n', 0, m.start()) + 1
            errors.append(f'{rel}:{line}: {label}: {m.group(0)[:80]}')

if errors:
    print('STATIC CHECK FAILED')
    for e in errors:
        print(e)
    sys.exit(1)

print(f'STATIC CHECK OK ({len(LUA_FILES)} lua files)')
