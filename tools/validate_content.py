"""Validate cross references and actionable content; stdlib only."""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
data = {p.stem: json.loads(p.read_text()) for p in (root / 'data').glob('*.json')}
buildings = data['buildings']
assert len(buildings) >= 50
assert len(data['quests']) >= 20
assert len(data['levels']) >= 250
for key, b in buildings.items():
    assert key == b['id'] and b['price'] >= 0 and b['level'] >= 1
    assert len(b['footprint']) == 2 and all(0 < n <= 8 for n in b['footprint'])
    assert all(k in data['products'] and v >= 0 for k, v in b['resources'].items())
for table in ('crops', 'livestock', 'recipes'):
    for key, item in data[table].items():
        assert key in buildings and item['seconds'] > 0
        if 'product' in item:
            assert item['product'] in data['products']
        else:
            assert all(k in data['products'] and v > 0 for side in ('input', 'output') for k, v in item[side].items())
for key, tech in data['technologies'].items():
    assert all(d in data['technologies'] and d != key for d in tech['dependencies'])
    def walk(node, seen):
        assert node not in seen, 'research dependency cycle'
        for dep in data['technologies'][node]['dependencies']:
            walk(dep, seen | {node})
    walk(key, set())
known = set()
for q in data['quests']:
    assert q['id'] not in known
    assert all(dep in known for dep in q['prerequisites'])
    assert all(o['count'] > 0 for o in q['objectives'])
    known.add(q['id'])
assert all(data['levels'][i]['xp'] < data['levels'][i+1]['xp'] for i in range(len(data['levels'])-1))
print(f"Content valid: {len(buildings)} buildings, {len(known)} quests, {len(data['levels'])} levels")
