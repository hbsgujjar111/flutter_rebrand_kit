# Flutter Rebrand Kit

[![Pub Version](https://img.shields.io/pub/v/flutter_rebrand_kit)](https://pub.dev/packages/flutter_rebrand_kit)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

An all-in-one developer CLI tool to rebrand Flutter applications in seconds. Update app names, package identifiers, bump versions, generate adaptive launcher icons, convert notification silhouettes, wire native splash screens, and export Google Play Store marketing assets using **a single command**.

---

## ⚡ Standalone Native Engine

Flutter Rebrand Kit is engineered from the ground up as an independent, pure Dart tool. It operates entirely on its own and **does not run, wrap, or invoke other third-party packages under the hood**:

- **True Standalone Execution:** Directly manipulates native manifests, build scripts, and asset trees without spawning external package sub-processes.
- **In-Memory Image Pipeline:** Loads and decodes master artwork into memory once, processing all target resolutions and densities in a single, high-speed execution.
- **Clean Workspace:** Never injects temporary dependencies or scripts into your project, keeping your `pubspec.lock` and environment clean.

---

## 📋 What This Tool Does

- ✅ **App Name:** Updates application titles across Android, iOS, macOS, Web, Windows, and Linux.
- ✅ **Package ID:** Updates bundle identifiers across Gradle, Xcode, and CMake build targets.
- ✅ **Source Code Migration:** Physically relocates Kotlin/Java folder trees and updates package and import lines.
- ✅ **Launcher Icons:** Generates Android adaptive/legacy icons and the full 20-asset iOS catalog.
- ✅ **Themed Icons:** Generates Android 13+ Material You monochrome silhouettes.
- ✅ **Notification Icons:** Generates anti-aliased white silhouettes with Material safe-zone padding.
- ✅ **Native Splash Screen:** Wires Android 12+ Splash API, Android legacy drawables, and iOS Storyboards.
- ✅ **Store Marketing Assets:** Exports a 512×512 Google Play icon and a 1024×500 feature graphic banner.

---

## ⚡ Platform Support Matrix

| Feature | Android | iOS | macOS | Web | Windows | Linux |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **App Name** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Package / Bundle ID** | ✅ *(Tree Migration)* | ✅ | ✅ | N/A | ✅ *(Binary Name)* | ✅ *(App ID)* |
| **Version & Build** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Launcher Icons** | ✅ *(Adaptive + Themed)* | ✅ *(20 Sizes)* | ⏳ *v1.2* | ⏳ *v1.2* | ⏳ *v1.2* | ⏳ *v1.2* |
| **Notification Icons** | ✅ *(White Silhouette)* | N/A | N/A | N/A | N/A | N/A |
| **Native Splash Screen** | ✅ *(API 31+ & Legacy)* | ✅ *(Storyboard Asset)* | N/A | ⏳ *v1.3* | N/A | N/A |
| **Play Store Marketing Kit** | ✅ *(512px & Banner)* | N/A | N/A | N/A | N/A | N/A |

---

## 🛠️ Addressed Edge Cases & Platform Enhancements

Standard standalone packages often miss critical platform requirements or contain known limitations. Flutter Rebrand Kit directly addresses and resolves these gaps:

- **Full-Tree Source Code Relocation (Addressed from `rename`):**  
  Traditional renaming tools only update strings in Gradle and Manifest files, leaving Kotlin/Java source files stranded in the old directory path. This tool physically migrates the entire source tree, updates package headers, rewires internal imports across sub-packages, and prunes orphaned directories.
- **Engine File Protection:**  
  Custom renaming scripts frequently relocate internal engine files like `GeneratedPluginRegistrant.java`, resulting in broken Android builds. This engine explicitly identifies, isolates, and preserves all `io.flutter` files.
- **Complete iOS Asset Catalog (Addressed from `flutter_launcher_icons`):**  
  Standard icon generators frequently omit 4 legacy asset slots (`20@1x`, `29@1x`, `40@1x`, and `76@1x`), which causes default Flutter icons to appear in iPad spotlight and the iOS App Switcher. This tool generates the complete 20-asset catalog alongside modern universal slots.
- **Desktop Executable Metadata (Addressed from `rename`):**  
  Existing tools update window titles but miss native binary metadata. This tool updates Windows `Runner.rc` (`FileDescription`, `ProductName`, `InternalName`) and Linux GTK HeaderBar titles alongside primary window titles.
- **Android 13+ Themed Icons Out of the Box:**  
  Rather than requiring manual authoring of monochrome XML assets, this engine automatically derives an anti-aliased Material You silhouette directly from your master logo if a custom asset is not provided.
- **Store-Compliant Alpha Stripping:**  
  Google Play and the App Store reject app icons with transparent pixels. The tool automatically composites transparent source PNGs over solid backgrounds for store exports, preventing automated submission rejections.

---

## 📐 Master Image Guidelines

> **Recommendation:** Supply a **1024×1024 PNG with a TRANSPARENT background**.

* **Adaptive Icons & Splash:** The tool centers the transparent logo within safe boundaries over your configured background color (`launcher_icon_bg_color` or `splash_color`), preventing Android 12+ circular crop clipping.
* **Notification Silhouettes:** The alpha channel is used to generate white vector-style silhouettes (`#FFFFFF`) for Android status bars.
* **Store Guidelines:** Google Play and Apple App Store require opaque app icons. The tool automatically composites transparent assets onto solid canvases to ensure store compliance.

---

## 🔧 Installation

Add `flutter_rebrand_kit` to your `dev_dependencies`:

```bash
flutter pub add -d flutter_rebrand_kit
```

---

## ⚙️ Configuration

Choose **one** of the two configuration styles below. All fields are optional.

### Option A: Standalone File (Recommended)
Create `rebrand_kit.yaml` in your project root:

```yaml
# ==============================================================================
# FLUTTER REBRAND KIT CONFIGURATION (rebrand_kit.yaml)
# ==============================================================================

# 1. Identity (Android, iOS, macOS, Web, Windows, Linux)
app_name: "My Awesome App"
package_id: "com.company.awesomeapp"
version: "1.2.0+15"

# 2. Launcher Icons (1024x1024 Transparent PNG recommended)
launcher_icon: "assets/branding/app_logo_1024.png"
launcher_icon_bg_color: "#FFFFFF"
# Optional: Use an image background instead of a solid color
# launcher_icon_bg_image: "assets/branding/adaptive_bg.png"
# Optional: Custom monochrome silhouette for Android 13+ (auto-derived if omitted)
# launcher_icon_monochrome: "assets/branding/custom_mono.png"

# 3. Android Notification Silhouette
notification_icon: "assets/branding/app_logo_1024.png"

# 4. Native Splash Screen
splash_image: "assets/branding/app_logo_1024.png"
splash_color: "#1E1E2E"

# 5. Play Store Marketing Assets
play_store:
  generate: true
  background_color: "#1E1E2E"
  tagline: "Build better and ship faster"
```

### Option B: Embedded in `pubspec.yaml`
Add the `rebrand_kit:` block at the bottom of your `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_rebrand_kit: ^1.1.0

rebrand_kit:
  app_name: "My Awesome App"
  package_id: "com.company.awesomeapp"
  version: "1.2.0+15"
  launcher_icon: "assets/branding/app_logo_1024.png"
  launcher_icon_bg_color: "#FFFFFF"
  notification_icon: "assets/branding/app_logo_1024.png"
  splash_image: "assets/branding/app_logo_1024.png"
  splash_color: "#1E1E2E"
  play_store:
    generate: true
    background_color: "#1E1E2E"
    tagline: "Build better and ship faster"
```

---

## 🔨 Execution

Run the CLI command from your terminal:

```bash
dart run flutter_rebrand_kit:rebrand_kit
```

### Configuration Priority:
1. **`rebrand_kit.yaml`:** Checked first. If present, it will be used.
2. **`pubspec.yaml`:** Used if `rebrand_kit.yaml` is not found.

---

## 📋 Configuration Reference

| Property | Type | Required | Default | Description |
| :--- | :--- | :---: | :--- | :--- |
| `app_name` | `String` | No | `null` | Display name across Android, iOS, macOS, Web, Windows, and Linux. |
| `package_id` | `String` | No | `null` | Application/Bundle ID. Updates build files and migrates Kotlin/Java folders. |
| `version` | `String` | No | `null` | Version and build number in `pubspec.yaml` (`x.y.z+build`). |
| `launcher_icon` | `String` | No | `null` | Master logo (**1024×1024 transparent PNG**). Exports Android mipmaps & 20 iOS sizes. |
| `launcher_icon_bg_color` | `String (Hex)` | No | `"#FFFFFF"` | Background color for Android adaptive icons and fallback canvases. |
| `launcher_icon_bg_image` | `String` | No | `null` | Background image for Android adaptive icons (overrides `launcher_icon_bg_color`). |
| `launcher_icon_monochrome` | `String` | No | `null` | Custom silhouette for Android 13+ theming (auto-generated from logo if omitted). |
| `notification_icon` | `String` | No | `null` | Source logo. Auto-converts to an anti-aliased white silhouette (`drawable-*`). |
| `splash_image` | `String` | No | `null` | Splash logo. Padded to safe boundaries to prevent circular crop issues. |
| `splash_color` | `String (Hex)` | No | `"#FFFFFF"` | Background color for native splash screens on Android and iOS. |
| `play_store.generate` | `bool` | No | `false` | Enables generating assets in `branding_assets/play_store/`. |
| `play_store.background_color` | `String (Hex)` | No | `"#1E1E2E"` | Canvas color for the 512×512 store icon and 1024×500 feature graphic. |
| `play_store.tagline` | `String` | No | `null` | Subtitle printed on the 1024×500 feature graphic banner. |

---

## 📁 Generated File Destinations

| Asset | Output Location |
| :--- | :--- |
| **Android Legacy Icons** | `android/app/src/main/res/mipmap-*/ic_launcher.png` |
| **Android Adaptive Icons** | `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` |
| **Android 13+ Themed Icons** | `android/app/src/main/res/mipmap-*/ic_launcher_monochrome.png` |
| **iOS App Icons** | `ios/Runner/Assets.xcassets/AppIcon.appiconset/` *(20 sizes + Contents.json)* |
| **Android Notification Icons** | `android/app/src/main/res/drawable-*/ic_notification.png` |
| **Android Splash (<12)** | `android/app/src/main/res/drawable/launch_background.xml` |
| **Android Splash (12+)** | `android/app/src/main/res/values-v31/styles.xml` |
| **iOS Launch Screen** | `ios/Runner/Assets.xcassets/LaunchImage.imageset/` |
| **Play Store Icon (512×512)** | `branding_assets/play_store/play_store_512.png` |
| **Feature Banner (1024×500)** | `branding_assets/play_store/feature_graphic_1024x500.png` |

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

