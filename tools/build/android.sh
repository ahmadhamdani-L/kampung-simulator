#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
: "${GODOT_BIN:=godot}"
: "${JAVA_HOME:?Set JAVA_HOME to JDK 17}"
: "${ANDROID_HOME:?Set ANDROID_HOME}"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"
mkdir -p build/android
# A project-specific debug identity, never a release identity.
export GODOT_ANDROID_KEYSTORE_DEBUG_PATH="${GODOT_ANDROID_KEYSTORE_DEBUG_PATH:-$PWD/.tools/kampung-debug.keystore}"
export GODOT_ANDROID_KEYSTORE_DEBUG_USER=androiddebugkey
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD=android
if [[ ! -f "$GODOT_ANDROID_KEYSTORE_DEBUG_PATH" ]]; then
  mkdir -p "$(dirname "$GODOT_ANDROID_KEYSTORE_DEBUG_PATH")"
  keytool -genkeypair -keystore "$GODOT_ANDROID_KEYSTORE_DEBUG_PATH" -storepass android -keypass android -alias androiddebugkey -dname 'CN=Kampung Simulator Debug,O=Development,C=ID' -keyalg RSA -keysize 2048 -validity 10000 >/dev/null 2>&1
fi
"$GODOT_BIN" --headless --path . --editor --import --quit
"$GODOT_BIN" --headless --path . --editor --script tools/configure_android.gd
"$GODOT_BIN" --headless --path . --export-debug 'Android Debug' build/android/kampung-simulator-debug.apk
APKSIGNER=$(find "$ANDROID_HOME/build-tools" -name apksigner | sort | tail -n 1)
"$APKSIGNER" verify build/android/kampung-simulator-debug.apk
python3 tools/build/verify_apk.py build/android/kampung-simulator-debug.apk
