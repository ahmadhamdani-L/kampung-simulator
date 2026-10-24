import sys, zipfile
from pathlib import Path
bundle = Path(sys.argv[1])
with zipfile.ZipFile(bundle) as z:
    names = z.namelist()
    assert not any(n.endswith((".keystore", ".jks", ".env")) or "/.tools/" in n or n.startswith(("assets/android/build/", "assetPackInstallTime/assets/android/build/", "base/assets/android/build/")) for n in names), "local build material included"
    assert z.testzip() is None
    assert 'BundleConfig.pb' in names
    assert 'base/manifest/AndroidManifest.xml' in names
    assert 'META-INF/MANIFEST.MF' in names, 'bundle is unsigned'
    assert any(n.endswith(('.RSA', '.DSA', '.EC')) and n.startswith('META-INF/') for n in names)
    assert any('data/buildings.json' in n for n in names)
    assert any('/lib/arm64-v8a/' in n for n in names)
print(f'Bundle package verified: {bundle} ({bundle.stat().st_size:,} bytes)')
