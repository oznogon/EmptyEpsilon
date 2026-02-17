# EmptyEpsilon Android Build - Gradle

_As of 16 Feb 2026._

This directory contains the Android Gradle build system for EmptyEpsilon.

## Prerequisites

- **JDK 17 or newer** (OpenJDK or Oracle JDK)

  ```bash
  java -version  # Should show version 17 or higher
  ```
- **Android SDK**, either Android Studio or  Android command-line tools
- **Android NDK 26.3.11579264**, automatically installed by Gradle or manually via SDK Manager
- **CMake 3.22.1+**, automatically installed by Gradle or manually via SDK Manager

Symlink support is required to build on Windows. See [Symlinks on Windows](#symlinks-on-windows).

### Versions in use

- **Minimum Android version**: 8.0 (API 26)
- **Target Android version**: 14 (API 34)
- **Gradle version**: 8.9
- **Android Gradle plugin**: 8.5.0
- **Kotlin version**: 1.9.24
- **NDK version**: 26.3.11579264
- **CMake version**: 3.22.1
- **SDL2 version**: 2.32.8

## Quick start

### Command-line

1. Navigate to the android directory:

   ```bash
   cd EmptyEpsilon/android
   ```
1. Build a debug APK (without 3D model packs):

   ```bash
   ./gradlew assembleWithoutPacksDebug
   ```

   The APK will be created at: `app/build/outputs/apk/withoutPacks/debug/app-withoutPacks-debug.apk`
1. Install on a connected device:

   ```bash
   ./gradlew installWithoutPacksDebug
   ```
1. Launch the app:

   ```bash
   adb shell am start -n eu.daid.emptyepsilon/.EmptyEpsilonActivity
   ```

### Android Studio

1. Open Android Studio.
1. Select **File > Open** and choose the `EmptyEpsilon/android` directory.
1. Wait for Gradle sync to complete.
1. Select a [Build Variant](#build-variants).
1. Click **Run > Run 'app'** (or press <kbd>Shift+F10</kbd>)

## Build variants

Gradle **product flavors** control asset inclusion:

| Variant               | Description                | Usage                             |
| --------------------- | -------------------------- | --------------------------------- |
| `withoutPacksDebug`   | Debug build, no 3D models  | Fast iteration during development |
| `withPacksDebug`      | Debug build with 3D models | Testing with full assets          |
| `withoutPacksRelease` | Release build, no models   | Distribution for low-end devices  |
| `withPacksRelease`    | Release build with models  | Full production release           |

### Command-line

```bash
# Debug variants
./gradlew assembleWithoutPacksDebug
./gradlew assembleWithPacksDebug

# Release variants (requires signing config)
./gradlew assembleWithoutPacksRelease
./gradlew assembleWithPacksRelease
```

### Android Studio

Use the **Build Variants** panel (**View > Tool Windows > Build Variants**).

## Multi-ABI configuration

EmptyEpsilon targets four Android ABIs by default:

- `armeabi-v7a` - 32-bit ARM (older ARM devices)
- `arm64-v8a` - 64-bit ARM (modern ARM devices)
- `x86` - 32-bit Intel (emulators)
- `x86_64` - 64-bit Intel (modern ARM devices)

### Building for a single ABI

To speed up development builds, you can target only one ABI:

```bash
# Example: Build only for arm64-v8a
./gradlew assembleWithoutPacksDebug -Pandroid.injected.build.abi=arm64-v8a
```

To find your device ABI, run:

```bash
adb shell getprop ro.product.cpu.abi
```

### ABI filtering in build.gradle.kts

To permanently disable ABIs, edit `app/build.gradle.kts`:

```kotlin
ndk {
    abiFilters += listOf("arm64-v8a")  // Build only arm64-v8a
}
```

## Release Signing

Release builds require a signing configuration.

### Option 1: local.properties

Create `android/local.properties` (ignored by git), replacing each value:

```properties
sdk.dir=</PATH/TO/ANDROID/SDK>
keystorePath=</PATH/TO/KEYSTORE.JKS>
keystorePassword=<STORE_PASSWORD>
keyAlias=<KEY_ALIAS>
keyPassword=<KEY_PASSWORD>
```

### Option 2: Environment variables

Set these environment variables:

```bash
export RELEASE_STORE_FILE=</PATH/TO/KEYSTORE.JKS>
export RELEASE_STORE_PASSWORD=<STORE_PASSWORD>
export RELEASE_KEY_ALIAS=<KEY_ALIAS>
export RELEASE_KEY_PASSWORD=<KEY_PASSWORD>
```

### Generate a keystore

To generate a keystore, use `keytool`:

```bash
keytool -genkey -v -keystore emptyepsilon-release.jks \
  -alias emptyepsilon -keyalg RSA -keysize 2048 -validity 10000
```

Back up your keystore or you won't be able to update an app published with it.

## Build commands

### Build app bundle (aab)

```bash
./gradlew bundleWithPacksRelease
```

Output: `app/build/outputs/bundle/withPacksRelease/app-withPacksRelease.aab`

### Clean build

```bash
./gradlew clean assembleWithPacksDebug
```

### View build tasks

```bash
./gradlew tasks --all
```

### Build with specific Gradle version

```bash
./gradlew wrapper --gradle-version=8.9
```

## Project Structure

```
android/
    build.gradle.kts        # Root build configuration
    settings.gradle.kts     # Project settings
    gradle.properties       # Build properties
    gradlew / gradlew.bat   # Gradle wrapper scripts
    app/
        build.gradle.kts    # App module build script
        proguard-rules.pro  # ProGuard/R8 configuration
        src/
            main/
                AndroidManifest.xml
                java/
                    eu/daid/emptyepsilon/EmptyEpsilonActivity.kt
                    org/libsdl/app/      # SDL2 Java classes
                cpp/
                    CMakeLists.txt       # CMake wrapper
                    EmptyEpsilon -> ../../../../../../  # Symlink to source
                    SeriousProton -> ../../../../../../../SeriousProton
                    cmake/FindSDL2.cmake # Custom SDL2 finder module
                res/                     # Android resources
                    values/strings.xml
                    mipmap-*/ic_launcher.png
                assets/                  # Game assets (symlinked)
                    resources -> ../../../../../resources
                    scripts -> ../../../../../scripts
                    packs -> ../../../../../packs  # Only included in withPacks
```

## CMake integration

The Gradle build integrates CMake to compile C++:

- **android/app/src/main/cpp/CMakeLists.txt** downloads SDL2 via CMake FetchContent, sets the SeriousProton path, and includes the main EmptyEpsilon CMakeLists.txt via symlink
- **Symlinks** point to the repo root and SeriousProton in a sibling path to EmptyEpsilon.
- **SDL2** (2.32.8) is downloaded from GitHub automatically during the first CMake configuration

## Asset management

Game assets in `resources`, `scripts`, and `packs` are symlinked to avoid duplication:

- `resources/` - Always included
- `scripts/` - Always included
- `packs/` - Only included in `withPacks` build flavors

Gradle follows symlinks automatically during APK packaging.

## Troubleshooting

### Symlinks on Windows

Symlinks require Developer Mode in Windows 10/11. Enable **Settings > Update & Security > For Developers > Developer Mode: ON** or run Git Bash / WSL as Administrator.

If symlinks fail, Gradle will error. Ensure symlinks are created correctly:

```bash
ls -la app/src/main/assets/
ls -la app/src/main/cpp/
```

### Gradle Sync Failed

**Symptom**: `Could not resolve dependencies`

**Solutions**:

- Check internet connection (Gradle needs to download dependencies)
- Update SDK/NDK in Android Studio: **Tools > SDK Manager**
- Invalidate caches: **File > Invalidate Caches / Restart** in Android Studio, or clean and rebuild

### CMake Build Failed

**Symptom**: `Execution failed for task ':app:externalNativeBuildDebug'`

**Solutions**:

- Verify symlinks exist:

  ```bash
  ls -l app/src/main/cpp/EmptyEpsilon
  ls -l app/src/main/cpp/SeriousProton
  ```
- Check CMake version (requires 3.22.1+):

  ```bash
  cmake --version
  ```
- Clean and rebuild:

  ```bash
  ./gradlew clean
  rm -rf app/.cxx
  ./gradlew assembleWithoutPacksDebug
  ```

### APK is too large

**Symptom**: APK exceeds 100MB limit for some distribution methods

**Solutions**:

- Try building the `withoutPacks` variant.
- Enable App Bundles, which splits APKs.
- Build single ABI APKs.

### Install over ADB failed

**Symptom**: `INSTALL_FAILED_INSUFFICIENT_STORAGE`

**Solution**: Large APK requires ~1GB free space on device. Clear space or use `withoutPacks`.

**Symptom**: `INSTALL_FAILED_UPDATE_INCOMPATIBLE`

**Solution**: Uninstall EmptyEpsilon first. With `adb`:

```bash
adb uninstall eu.daid.emptyepsilon
```

### Signing configuration is missing

**Symptom**: Release build produces unsigned APK

**Solution**: [Configure signing](#release-signing)

## GitHub Actions example

```yaml
- name: Set up JDK 17
  uses: actions/setup-java@v4
  with:
    java-version: '17'
    distribution: 'temurin'

- name: Setup Android SDK
  uses: android-actions/setup-android@v3

- name: Build APK
  run: ./gradlew assembleWithPacksRelease
  working-directory: EmptyEpsilon/android

- name: Upload APK
  uses: actions/upload-artifact@v4
  with:
    name: app-release
    path: EmptyEpsilon/android/app/build/outputs/apk/**/*.apk
```
