# Flutter Rebrand Kit

[![Pub Version](https://img.shields.io/pub/v/flutter_rebrand_kit)](https://pub.dev/packages/flutter_rebrand_kit)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

An all-in-one developer CLI tool to rebrand Flutter applications. Update app names, package identifiers, bump versions, generate adaptive launcher icons, convert notification silhouettes, wire native splash screens, and export Google Play Store marketing assets using a single command.

---

## Architecture: Standalone Native Engine

Flutter Rebrand Kit is engineered from the ground up as an independent, single-pass Dart CLI tool. It operates entirely as a self-contained engine and does not execute, wrap, or invoke other third-party CLI packages under the hood:

- **Direct Native Operations:** Modifies native platform manifests, build scripts, resource catalogs, and source folders directly without spawning external package sub-processes.
- **In-Memory Image Pipeline:** Loads and decodes master graphic assets in memory once, processing all target resolutions, density variants, and platform formats in a single execution.
- **Zero Workspace Clutter:** Operates strictly through standard configuration files (`rebrand_kit.yaml` or embedded directly within `pubspec.yaml`) without injecting temporary packages or build scripts into your project.

---

## What This Tool Does

- ✓ **App Name:** Updates application titles across Android, iOS, macOS, Web, Windows, and Linux.
- ✓ **Package ID:** Updates bundle identifiers across Gradle (Groovy & Kotlin DSL), Xcode, and CMake build configurations.
- ✓ **Source Code Migration:** Physically relocates Kotlin and Java folder trees to match new package identifiers while updating package declarations and internal imports.
- ✓ **Launcher Icons:** Generates complete launcher icon sets across all 6 platforms (Android, iOS, macOS, Web, Windows, and Linux).
- ✓ **Themed & Dark Icons:** Generates Android 13+ Material You monochrome silhouettes and iOS 18 Dark & Tinted icons.
- ✓ **Notification Icons:** Generates anti-aliased white silhouettes with full-canvas resolution, custom drawable naming, and automatic stale asset cleanup.
- ✓ **Native Splash Screen:** Wires Android 12+ Splash API, Android legacy drawables, iOS Storyboards, and Web preloaders with dark mode and branding footer support.
- ✓ **Store Marketing Assets:** Exports a compliant 512×512 Google Play icon and a 1024×500 feature graphic banner with custom typography and taglines.

---

## Platform Support

| Feature                      | Android | iOS | macOS | Web | Windows | Linux |
|:-----------------------------|:-------:|:---:|:-----:|:---:|:-------:|:-----:|
| **App Name**                 |    ✅    |  ✅  |   ✅   |  ✅  |    ✅    |   ✅   |
| **Package / Bundle ID**      |    ✅    |  ✅  |   ✅   | N/A |    ✅    |   ✅   |
| **Version & Build**          |    ✅    |  ✅  |   ✅   |  ✅  |    ✅    |   ✅   |
| **Launcher Icons**           |    ✅    |  ✅  |   ✅   |  ✅  |    ✅    |   ✅   |
| **Notification Icons**       |    ✅    | N/A |  N/A  | N/A |   N/A   |  N/A  |
| **Native Splash Screen**     |    ✅    |  ✅  |  N/A  |  ✅  |   N/A   |  N/A  |
| **Play Store Marketing Kit** |    ✅    | N/A |  N/A  | N/A |   N/A   |  N/A  |

---

## Addressed Edge Cases & Platform Considerations

This tool addresses several real-world edge cases and native platform requirements encountered during project rebranding:

- **Complete Android Source Tree Migration:** Rather than only updating configuration strings in Gradle and Manifest files, the tool physically migrates your Kotlin and Java directory hierarchy, rewrites package headers, updates internal imports across sub-packages, and prunes orphaned directories.
- **Engine File Protection:** Explicitly identifies and preserves internal engine-generated files (such as `GeneratedPluginRegistrant.java`) to prevent compilation failures.
- **Full 6-Platform Launcher Icons:** Generates icons for Android, iOS, macOS, Web, Windows, and Linux, including platforms frequently omitted by traditional generators (such as Linux desktop launchers).
- **Built-In Windows Binary `.ico` Encoder:** Contains an internal multi-resolution binary encoder that stitches `16×16`, `32×32`, `48×48`, and `256×256` frames directly into `windows/runner/resources/app_icon.ico` using a pure-Dart binary packer without requiring external C libraries.
- **Full iOS Asset Coverage:** Generates all 20 standard iOS asset sizes (including legacy `@1x` slots: `20@1x`, `29@1x`, `40@1x`, and `76@1x`), ensuring icons render consistently in iPad search and the iOS App Switcher.
- **iOS 18 Dark & Tinted Variants:** Supports Xcode 16 / iOS 18 Dark Mode and Tinted home screen icons across all resolution variants with proper luminosity appearance tags.
- **Density-Scaled Splash Assets:** Generates splash and branding logos across all 5 Android density buckets (`mdpi` to `xxxhdpi`), preventing blurriness caused by OS image stretching.
- **Mathematical Splash Safe Boundaries:** Centers splash artwork within an inner 640px circle boundary ($160\text{dp}$ Android 12 window), preventing Google's circular mask from clipping logo edges.
- **Web Splash Auto-Dismissal:** Injects `pointer-events: none` and an automatic `flutter-first-frame` event listener into `web/index.html` so web splash screens cleanly dismiss without blocking user interaction.
- **Linux Runtime Window Icon Linkage:** Automatically injects `gtk_window_set_icon_from_file` into `linux/runner/my_application.cc` so icons appear in the Linux dock and window title bar.
- **Store-Compliant Alpha Management:** Automatically composites transparent source PNGs over solid backgrounds for Apple App Store and Google Play exports, preventing automated submission rejections.
- **Desktop Executable Metadata:** Updates Windows executable metadata (`FileDescription`, `ProductName`, `InternalName` in `Runner.rc`) and Linux GTK HeaderBar titles alongside primary window titles.
- **High-Fidelity Notification Rendering:** Avoids stroke loss on delicate line art by rendering to full canvas dimensions (`24` to `96px`), preserving anti-aliased subpixels, and supporting custom drawable names (`notification_icon_name`) while cleaning up stale default assets.
- **XML Entity & UTF-8 Encoding Safety:** Enforces UTF-8 across all file operations and automatically escapes XML entities (`&amp;`) for `AndroidManifest.xml` to avoid AAPT build errors.
- **iOS Extension Target Isolation:** Identifies extension and test targets in `project.pbxproj`, preserving distinct sub-identifiers to prevent code-signing issues.

---

## Quick Start

### 1. Installation
Add `flutter_rebrand_kit` to your `dev_dependencies`:

```bash
flutter pub add -d flutter_rebrand_kit
```

### 2. Scaffold Configuration
Generate a starter configuration file in your project root:

```bash
dart run flutter_rebrand_kit:init
```

### 3. Configure
Configure your properties using either a standalone file or directly within `pubspec.yaml`. All fields are optional.

#### Option A: Standalone File (Recommended)
Create or edit `rebrand_kit.yaml` in your project root:

```yaml
# ==============================================================================
# FLUTTER REBRAND KIT CONFIGURATION (rebrand_kit.yaml)
# ==============================================================================

# 1. Identity (Android, iOS, macOS, Web, Windows, Linux)
app_name: "My Awesome App"
package_id: "com.company.awesomeapp"
version: "1.0.0+1"

# 2. Launcher Icons (1024x1024 Transparent PNG recommended)
launcher_icon: "assets/branding/app_logo_1024.png"
launcher_icon_bg_color: "#FFFFFF"
# Optional: Use an image background instead of a solid color
# launcher_icon_bg_image: "assets/branding/adaptive_bg.png"
# Optional: Custom monochrome silhouette for Android 13+ (auto-derived if omitted)
# launcher_icon_monochrome: "assets/branding/custom_mono.png"

# 3. Android Notification Silhouette
notification_icon: "assets/branding/app_logo_1024.png"
notification_icon_name: "ic_stat_notification" # Optional (defaults to "ic_notification")

# 4. Native Splash Screen
splash_image: "assets/branding/app_logo_1024.png"
splash_color: "#1E1E2E"
# Optional: Dark mode splash
splash_dark_image: "assets/branding/app_logo_1024.png"
splash_dark_color: "#0F0F0F"
# Optional: Branding footer image (recommended: 800x320 PNG, 2.5:1 ratio)
splash_branding_image: "assets/branding/branding_footer.png"

# 5. Play Store Marketing Assets
play_store:
  generate: true
  background_color: "#1E1E2E"
  tagline: "Build better and ship faster"
```

#### Option B: Embedded in `pubspec.yaml`
Add the `rebrand_kit:` block at the bottom of your `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_rebrand_kit: ^1.3.0

rebrand_kit:
  app_name: "My Awesome App"
  package_id: "com.company.awesomeapp"
  version: "1.0.0+1"
  launcher_icon: "assets/branding/app_logo_1024.png"
  launcher_icon_bg_color: "#FFFFFF"
  notification_icon: "assets/branding/app_logo_1024.png"
  notification_icon_name: "ic_stat_notification"
  splash_image: "assets/branding/app_logo_1024.png"
  splash_color: "#1E1E2E"
  splash_dark_image: "assets/branding/app_logo_1024.png"
  splash_dark_color: "#0F0F0F"
  splash_branding_image: "assets/branding/branding_footer.png"
  play_store:
    generate: true
    background_color: "#1E1E2E"
    tagline: "Build better and ship faster"
```

### 4. Execute
Run the rebranding pipeline:

```bash
dart run flutter_rebrand_kit:rebrand_kit
```

#### Configuration Priority:
1. **`rebrand_kit.yaml`:** Checked first. If present, it will be used.
2. **`pubspec.yaml`:** Used if `rebrand_kit.yaml` is not found.

---

## Master Image Guidelines

> **Recommended Dimensions:**
> * **Master App Icon:** `1024×1024 px` PNG with a transparent background.
> * **Branding Footer Logo:** `800×320 px` PNG (2.5:1 ratio) with a transparent background.

### Why Transparency Matters:
* **Adaptive Icons & Splash:** The tool centers the transparent logo within safe boundaries over your configured background color (`launcher_icon_bg_color` or `splash_color`), preventing circular crop clipping on Android 12+.
* **Notification Silhouettes:** The alpha channel is used to extract clean white silhouettes (`#FFFFFF`) for Android status bars.
* **Store Compliance:** Google Play and Apple App Store require opaque app icons. The tool automatically composites transparent assets onto solid canvases to ensure store submission requirements are met.

---

## Configuration Reference

| Property                      | Type           | Required | Default             | Description                                                                                                     |
|:------------------------------|:---------------|:--------:|:--------------------|:----------------------------------------------------------------------------------------------------------------|
| `app_name`                    | `String`       |    No    | `null`              | Display name across Android, iOS, macOS, Web, Windows, and Linux.                                               |
| `package_id`                  | `String`       |    No    | `null`              | Application/Bundle ID. Updates build files and migrates Kotlin/Java folders.                                    |
| `version`                     | `String`       |    No    | `null`              | Version and build number in `pubspec.yaml` (`x.y.z+build`).                                                     |
| `launcher_icon`               | `String`       |    No    | `null`              | Master logo (**1024×1024 transparent PNG**). Exports icons across all 6 platforms.                              |
| `launcher_icon_bg_color`      | `String (Hex)` |    No    | `"#FFFFFF"`         | Background color for Android adaptive icons and fallback canvases.                                              |
| `launcher_icon_bg_image`      | `String`       |    No    | `null`              | Background image for Android adaptive icons (overrides `launcher_icon_bg_color`).                               |
| `launcher_icon_monochrome`    | `String`       |    No    | `null`              | Custom silhouette for Android 13+ theming (auto-generated from logo if omitted).                                |
| `notification_icon`           | `String`       |    No    | `null`              | Source logo. Auto-converts to an anti-aliased white silhouette (`drawable-*`).                                  |
| `notification_icon_name`      | `String`       |    No    | `"ic_notification"` | Custom output filename for Android notification drawables. Auto-cleans stale defaults.                          |
| `splash_image`                | `String`       |    No    | `null`              | Splash logo. Padded to safe boundaries to prevent circular crop issues.                                         |
| `splash_color`                | `String (Hex)` |    No    | `"#FFFFFF"`         | Background color for native splash screens on Android, iOS, and Web.                                            |
| `splash_dark_image`           | `String`       |    No    | `null`              | Optional dark mode splash logo for Android and iOS.                                                             |
| `splash_dark_color`           | `String (Hex)` |    No    | `null`              | Optional dark mode splash background color (`values-night`, iOS, and Web).                                      |
| `splash_branding_image`       | `String`       |    No    | `null`              | Optional branding footer logo for Android 12+, pre-12, iOS, and Web (**recommended: 800×320 px, 2.5:1 ratio**). |
| `play_store.generate`         | `bool`         |    No    | `false`             | Enables generating assets in `branding_assets/play_store/`.                                                     |
| `play_store.background_color` | `String (Hex)` |    No    | `"#1E1E2E"`         | Canvas color for the 512×512 store icon and 1024×500 feature graphic.                                           |
| `play_store.tagline`          | `String`       |    No    | `null`              | Subtitle printed on the 1024×500 feature graphic banner.                                                        |

---

## Generated File Destinations

| Asset                                   | Output Location                                                                       |
|:----------------------------------------|:--------------------------------------------------------------------------------------|
| **Android Legacy Icons**                | `android/app/src/main/res/mipmap-*/ic_launcher.png`, `ic_launcher_round.png`          |
| **Android Adaptive Icons**              | `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`, `ic_launcher_round.xml` |
| **Android 13+ Themed Icons**            | `android/app/src/main/res/mipmap-*/ic_launcher_monochrome.png`                        |
| **iOS App Icons (Light, Dark, Tinted)** | `ios/Runner/Assets.xcassets/AppIcon.appiconset/` *(Full catalog + Contents.json)*     |
| **macOS Desktop Icons**                 | `macos/Runner/Assets.xcassets/AppIcon.appiconset/` *(16px to 1024px)*                 |
| **Windows Application Icon**            | `windows/runner/resources/app_icon.ico` *(16, 32, 48, 256px multi-resolution)*        |
| **Linux Desktop Icon**                  | `linux/runner/assets/app_icon.png` *(256×256)*                                        |
| **Web Favicon & PWA Icons**             | `web/favicon.png`, `web/icons/Icon-*.png`, `web/icons/Icon-maskable-*.png`            |
| **Android Notification Icons**          | `android/app/src/main/res/drawable-*/<icon_name>.png`                                 |
| **Android Splash (Density Buckets)**    | `android/app/src/main/res/drawable-*/splash_logo.png`, `splash_branding.png`          |
| **Android Splash (<12)**                | `android/app/src/main/res/drawable/launch_background.xml` *(+ night variant)*         |
| **Android Splash (12+)**                | `android/app/src/main/res/values-v31/styles.xml` *(+ night variant)*                  |
| **iOS Launch Screen**                   | `ios/Runner/Assets.xcassets/LaunchImage.imageset/`, `BrandingImage.imageset/`         |
| **Web Splash Screen**                   | `web/splash/splash.png`, `web/splash/branding.png`, and `web/index.html`              |
| **Play Store Icon (512×512)**           | `branding_assets/play_store/play_store_512.png`                                       |
| **Feature Banner (1024×500)**           | `branding_assets/play_store/feature_graphic_1024x500.png`                             |

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.