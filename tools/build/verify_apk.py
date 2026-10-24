import sys, zipfile
from pathlib import Path
apk = Path(sys.argv[1])
assert apk.stat().st_size > 1_000_000
with zipfile.ZipFile(apk) as z:
    names = z.namelist()
    assert not any(n.endswith((".keystore", ".jks", ".env")) or "/.tools/" in n or n.startswith(("assets/android/build/", "assetPackInstallTime/assets/android/build/", "base/assets/android/build/")) for n in names), "local build material included"
    assert 'AndroidManifest.xml' in names
    assert any(n.startswith('lib/arm64-v8a/') for n in names)
    assert any('data/buildings.json' in n for n in names), 'missing content definitions'
    assert z.testzip() is None
print(f'APK package verified: {apk} ({apk.stat().st_size:,} bytes)')
