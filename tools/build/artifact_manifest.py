"""Record local delivery artifacts and their exact source commit without credentials."""
import hashlib, json, subprocess
from pathlib import Path
root = Path(__file__).resolve().parents[2]
items = []
for name in ('kampung-simulator-debug.apk', 'kampung-simulator-debug.aab'):
    p = root / 'build' / 'android' / name
    items.append({'path': str(p), 'bytes': p.stat().st_size,
                  'sha256': hashlib.sha256(p.read_bytes()).hexdigest(),
                  'signing': 'project development key (not release signing)'})
record = {'branch': subprocess.check_output(['git', 'branch', '--show-current'], cwd=root, text=True).strip(),
          'source_commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip(),
          'engine': '4.7.2.stable', 'package_id': 'com.dreamdevelopdigital.kampungsimulator',
          'release_ready': False, 'artifacts': items}
path = root / 'build' / 'android' / 'artifacts.json'
path.write_text(json.dumps(record, indent=2)+'\n')
print(json.dumps(record, indent=2))
