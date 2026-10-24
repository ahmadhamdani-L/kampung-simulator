# Android build

Pinned engine: Godot 4.7.2 stable with matching templates. JDK 17, Android SDK platform 36. The prebuilt engine template declares minimum API 24 and target API 36 (verified with aapt). A non-Gradle export cannot override those template SDK values.

```sh
export JAVA_HOME=/path/to/jdk17
export ANDROID_HOME=/path/to/android-sdk
export GODOT_BIN=/path/to/godot
tools/build/android.sh
```

This imports resources, sets Godot's editor Android SDK/JDK paths, creates a project-specific ignored debug keystore if missing, exports `build/android/kampung-simulator-debug.apk`, verifies APK signing and checks ZIP/content/ABI integrity. JDK and SDK paths are settings; no reference-project signing secrets are read.

Release signing must be explicitly provisioned using `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER`, `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`. No release identity has been supplied. Do not label a debug-signed artifact as a release build.

AAB requires Godot's Gradle build template and a release signing identity for distribution. The default manual CI workflow builds a debug APK and debug-signed development AAB. `tools/build/debug_bundle.sh` uses matching `GODOT_ANDROID_TEMPLATE_SOURCE` and verifies both artifacts. Release delivery remains blocked until a project signing identity is provisioned and the secret-gated release pipeline is executed and verified. A debug-signed AAB is not a Play publication artifact. No Play upload occurs.

Provisional app ID: `com.dreamdevelopdigital.kampungsimulator`. Availability must be checked in the owner's Play Console; public search cannot verify registration eligibility.

Official references reviewed 2026-10-24: [Godot Android export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html), [Google Play target API rules](https://support.google.com/googleplay/android-developer/answer/11926878). Current Play requirements must be checked again at submission; target API 36 is selected for this candidate.

For an authorized release, use `tools/build/release.sh` with the three release identity variables and `GODOT_ANDROID_TEMPLATE_SOURCE`. CI secrets are `KAMPUNG_RELEASE_KEYSTORE_BASE64`, `KAMPUNG_RELEASE_ALIAS`, and `KAMPUNG_RELEASE_PASSWORD`; choose the manual workflow release input only after provisioning them. The keystore is decoded into runner temporary storage and removed on exit. Release exports remain unexecuted without those credentials.
