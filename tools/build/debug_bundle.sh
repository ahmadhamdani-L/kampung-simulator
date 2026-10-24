#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
: "${GODOT_BIN:=godot}"
: "${JAVA_HOME:?Set JDK 17 path}"
: "${ANDROID_HOME:?Set Android SDK path}"
: "${GODOT_ANDROID_TEMPLATE_SOURCE:?Path to Godot 4.7.2 android_source.zip}"
export GODOT_ANDROID_KEYSTORE_DEBUG_PATH="${GODOT_ANDROID_KEYSTORE_DEBUG_PATH:-$PWD/.tools/kampung-debug.keystore}"
export GODOT_ANDROID_KEYSTORE_DEBUG_USER=androiddebugkey
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD=android
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"
tools/build/android.sh
mkdir -p android/build
if [[ ! -f android/build/build.gradle ]]; then
  unzip -q "$GODOT_ANDROID_TEMPLATE_SOURCE" -d android/build
fi
printf '4.7.2.stable\n' > android/.build_version
touch android/.gdignore
chmod +x android/build/gradlew
"$GODOT_BIN" --headless --path . --export-debug 'Android Bundle Debug' build/android/kampung-simulator-debug.aab
# Some template/Gradle combinations leave debug bundles unsigned. Sign only
# with this project's development identity, never with a generated release key.
if ! unzip -l build/android/kampung-simulator-debug.aab | grep 'META-INF/MANIFEST.MF' >/dev/null; then
  jarsigner -keystore "$GODOT_ANDROID_KEYSTORE_DEBUG_PATH" -storepass:env GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD -keypass:env GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD build/android/kampung-simulator-debug.aab "$GODOT_ANDROID_KEYSTORE_DEBUG_USER"
fi
jarsigner -verify build/android/kampung-simulator-debug.aab
python3 tools/build/verify_bundle.py build/android/kampung-simulator-debug.aab
