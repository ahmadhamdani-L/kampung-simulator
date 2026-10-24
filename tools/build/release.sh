#!/usr/bin/env bash
# Requires an explicitly provisioned Kampung identity; never generates a release key.
set -euo pipefail
cd "$(dirname "$0")/../.."
: "${GODOT_BIN:=godot}"
: "${JAVA_HOME:?Set JDK 17 path}"
: "${ANDROID_HOME:?Set Android SDK path}"
: "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:?Provision Kampung release keystore}"
: "${GODOT_ANDROID_KEYSTORE_RELEASE_USER:?Provision release alias}"
: "${GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD:?Provision release password}"
: "${GODOT_ANDROID_TEMPLATE_SOURCE:?Path to matching android_source.zip}"
test -f "$GODOT_ANDROID_KEYSTORE_RELEASE_PATH"
test -f "$GODOT_ANDROID_TEMPLATE_SOURCE"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"
mkdir -p build/android android/build
if [[ ! -f android/build/build.gradle ]]; then
  unzip -q "$GODOT_ANDROID_TEMPLATE_SOURCE" -d android/build
fi
printf '4.7.2.stable\n' > android/.build_version
touch android/.gdignore
chmod +x android/build/gradlew
"$GODOT_BIN" --headless --path . --editor --import --quit
"$GODOT_BIN" --headless --path . --editor --script tools/configure_android.gd
"$GODOT_BIN" --headless --path . --export-release 'Android Release' build/android/kampung-simulator-release.apk
"$GODOT_BIN" --headless --path . --export-release 'Android Bundle' build/android/kampung-simulator-release.aab
APKSIGNER=$(find "$ANDROID_HOME/build-tools" -name apksigner | sort | tail -n 1)
"$APKSIGNER" verify build/android/kampung-simulator-release.apk
jarsigner -verify build/android/kampung-simulator-release.aab
python3 tools/build/verify_apk.py build/android/kampung-simulator-release.apk
python3 tools/build/verify_bundle.py build/android/kampung-simulator-release.aab
