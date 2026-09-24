# Flutter Rebrand Kit

[![Pub Version](https://img.shields.io/pub/v/flutter_rebrand_kit)](https://pub.dev/packages/flutter_rebrand_kit)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

An all-in-one developer CLI tool to rebrand Flutter applications in seconds. Update app names, package identifiers, bump versions, generate adaptive launcher icons, convert notification silhouettes, wire native splash screens, and export Google Play Store marketing assets using **a single command**.

---

## ⚡ Platform Support Matrix

| Feature | Android | iOS | Web | macOS | Windows | Linux |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **App Name** | ✅ | ✅ | ⏳ *v1.1* | ⏳ *v1.1* | ⏳ *v1.2* | ⏳ *v1.2* |
| **Package / Bundle ID** | ✅ | ✅ | N/A | ⏳ *v1.1* | N/A | N/A |
| **Version & Build** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Launcher Icons** | ✅ *(Adaptive + Legacy)* | ✅ *(Universal + Legacy)* | ⏳ *v1.1* | ⏳ *v1.1* | ⏳ *v1.2* | ⏳ *v1.2* |
| **Notification Icons** | ✅ *(White Silhouette)* | N/A | N/A | N/A | N/A | N/A |
| **Native Splash Screen** | ✅ *(API 31+ & Legacy)* | ✅ *(Storyboard Asset)* | ⏳ *v1.1* | N/A | N/A | N/A |
| **Play Store Marketing Kit** | ✅ *(512px & Banner)* | N/A | N/A | N/A | N/A | N/A |

> **Note:** Desktop (macOS, Windows, Linux) and Web support are actively roadmapped for upcoming releases.

---

## 📐 Master Image Guidelines (Crucial)

> **Recommendation:** Always use a **1024×1024 PNG with a TRANSPARENT background**.

### Why Transparency Matters:
* **Adaptive Icons & Splash:** The tool centers your transparent logo within safe zones and composites it over your chosen background color (`launcher_icon_bg_color` or `splash_color`), preventing Android 12+ circular crop clipping.
* **Notification Silhouettes:** The engine uses the transparency layer to craft pure white vector-style silhouettes (`#FFFFFF`) for Android status bars.
* **Store Guidelines:** Google Play and Apple App Store strictly forbid transparency in app icons. When using a transparent source PNG, the CLI automatically fills the background with a solid color so your assets are never rejected by store review bots.

---

## 🔧 Installation

Add `flutter_rebrand_kit` to your `dev_dependencies`:

```bash
flutter pub add -d flutter_rebrand_kit
```

---

## ⚙️ Configuration

You can configure your branding using either a standalone file (recommended) or directly inside `pubspec.yaml`.

### Option A: Standalone File (Recommended)
Create a file named `rebrand_kit.yaml` in your project root:

```yaml
# ==============================================================================
# FLUTTER REBRAND KIT CONFIGURATION (rebrand_kit.yaml)
# ==============================================================================

# 1. Identity & Manifests
app_name: "My Awesome App"
package_id: "com.company.awesomeapp"
version: "1.2.0+15"

# 2. Launcher Icons (1024x1024 Transparent PNG recommended)
launcher_icon: "assets/branding/app_logo_1024.png"
launcher_icon_bg_color: "#FFFFFF"

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

---

### Option B: Directly in `pubspec.yaml`
Add the `rebrand_kit:` block at the end of your `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_rebrand_kit: ^1.0.0

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

## 📋 Configuration Properties Reference

**Every property is optional.** Only provide the properties you want to update.

| Property | Type | Required? | Default | Description |
| :--- | :--- | :---: | :--- | :--- |
| `app_name` | `String` | **No** | `null` | Visible title on OS home screens (`AndroidManifest.xml`, `Info.plist`, web, and desktop). |
| `package_id` | `String` | **No** | `null` | Application/Bundle ID. Updates Gradle, Xcode, CMakeLists, and relocates `MainActivity`. |
| `version` | `String` | **No** | `null` | App version and build number in `pubspec.yaml` (format: `x.y.z+build`). |
| `launcher_icon` | `String` | **No** | `null` | Path to master logo (**1024×1024 transparent PNG**). Exports Android mipmaps & 20 iOS icons. |
| `launcher_icon_bg_color` | `String (Hex)` | **No** | `"#FFFFFF"` | Background color for Android adaptive icons (`mipmap-anydpi-v26`) and fallback canvases. |
| `notification_icon` | `String` | **No** | `null` | Path to source logo. Auto-converts to an anti-aliased white silhouette (`drawable-*`). |
| `splash_image` | `String` | **No** | `null` | Path to splash logo. Auto-padded to safe boundaries to prevent Android 12 circle cropping. |
| `splash_color` | `String (Hex)` | **No** | `"#FFFFFF"` | Background color for native splash screens on Android and iOS. |
| `play_store.generate` | `bool` | **No** | `false` | Enables generation of store graphics inside `branding_assets/play_store/`. |
| `play_store.background_color` | `String (Hex)` | **No** | `"#1E1E2E"` | Solid background color for the 512×512 store icon and 1024×500 feature graphic banner. |
| `play_store.tagline` | `String` | **No** | `null` | Subtitle or slogan printed on the 1024×500 feature graphic banner. |

---

## 🔨 Execution

Run the CLI command from your terminal:

```bash
dart run flutter_rebrand_kit:rebrand_kit
```

### Configuration Resolution Priority:
1. **Checks `rebrand_kit.yaml` first:** If present, the tool executes this configuration.
2. **Falls back to `pubspec.yaml`:** If `rebrand_kit.yaml` is not found, the tool reads the `rebrand_kit:` block inside `pubspec.yaml`.

---

## 📁 Generated Output Locations

| Asset | Target Destination |
| :--- | :--- |
| **Android Legacy Icons** | `android/app/src/main/res/mipmap-*/ic_launcher.png` |
| **Android Adaptive Icons** | `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` |
| **iOS Universal & Legacy Icons** | `ios/Runner/Assets.xcassets/AppIcon.appiconset/` *(20 sizes + Contents.json)* |
| **Android Notification Icons** | `android/app/src/main/res/drawable-*/ic_notification.png` |
| **Android Native Splash (<12)** | `android/app/src/main/res/drawable/launch_background.xml` |
| **Android Native Splash (12+)** | `android/app/src/main/res/values-v31/styles.xml` |
| **iOS Launch Screen Image** | `ios/Runner/Assets.xcassets/LaunchImage.imageset/` |
| **Play Store Icon (512×512)** | `branding_assets/play_store/play_store_512.png` |
| **Feature Banner (1024×500)** | `branding_assets/play_store/feature_graphic_1024x500.png` |

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.