# Changelog

## 1.3.0

### Native Splash Engine Overhaul
- **System Dark Mode Splash:** Added `splash_dark_color` and `splash_dark_image` support across Android `values-night` resources and iOS Storyboard dark asset catalogs.
- **Android 12+ Branding Footer:** Added `splash_branding_image` support via `windowSplashScreenBrandingImage` on Android 12+, pre-12 bottom gravity in `launch_background.xml`, and iOS `BrandingImage.imageset`.
- **Density-Scaled Splash Assets:** Generates splash and branding assets across all 5 Android density buckets (`drawable-mdpi` to `drawable-xxxhdpi`) to prevent downscaling blurriness on high-DPI screens.
- **Mathematical 60% Safe-Zone Scaling:** Aligned splash logo sizing with Android 12 specifications, ensuring logos fit within a 640px circle diameter to prevent circular crop clipping.
- **Web Splash Preloader & Auto-Dismiss:** Injects a responsive CSS/HTML preloader into `web/index.html` with dark mode support, click/drag protection (`pointer-events: none`), and an automatic `flutter-first-frame` listener to cleanly dismiss the overlay once Flutter mounts.

### Linux Runtime Linkage & Desktop Fixes
- **GTK Window Icon Runtime Loading:** Injects `gtk_window_set_icon_from_file` into `linux/runner/my_application.cc` so the application icon displays on the Linux dock and window title bar.
- **CMake Binary Output Synchronization:** Updates `set(BINARY_NAME ...)` in `linux/CMakeLists.txt` alongside `APPLICATION_ID`.

### CLI Experience & Performance
- **Interactive Multi-Step Logging:** Replaced generic CLI messages with detailed, transparent sub-step logs across all 7 rebranding tasks.
- **Asynchronous Parallel Processing:** Implemented parallel PNG encoding for multi-density splash assets, reducing execution time to ~1–2 seconds.

---

## 1.2.0

### All-Platform Launcher Icon Engine
- **CLI Configuration Scaffolding (`init` command):** Added `init` command support (`dart run flutter_rebrand_kit:rebrand_kit init`) to automatically generate a pre-commented `rebrand_kit.yaml` starter template in the project root.
- **6-Platform Icon Generation:** Generates launcher icons across Android, iOS, macOS, Web, Windows, and Linux from a single master asset.
- **iOS 18 Dark & Tinted Variants:** Added support for Xcode 16 / iOS 18 Dark Mode and Tinted home screen icons (`Icon-App-Dark-*`, `Icon-App-Tinted-*`) with full scale coverage across all legacy and modern slots.
- **Pure-Dart Windows `.ico` Encoder:** Encodes and packs 4 resolutions (`16×16`, `32×32`, `48×48`, `256×256`) directly into a valid Win32 binary container at `windows/runner/resources/app_icon.ico` without external tools.
- **Android Round Icon Support:** Generates `ic_launcher_round.xml` and legacy round mipmap variants (`mipmap-*/ic_launcher_round.png`) for OEM launchers that enforce circular masks.
- **Linux Desktop Icons:** Exports `linux/runner/assets/app_icon.png` (256×256) with solid background compositing for `.desktop` window managers.
- **PWA-Compliant Web Icons:** Exports `web/favicon.png`, standard PWA icons (`192px`, `512px`), and full-bleed maskable icons (`Icon-maskable-192.png`, `Icon-maskable-512.png`) aligned with Google PWA specifications.
- **Modular Architecture Refactor:** Refactored internal architecture into focused modules (`renamers/`, `icons/`, `splash/`, `marketing/`, `utils/`) for improved reliability and maintainability.

---

## 1.1.0

### Highlights & New Features
- **All-Platform App Renaming:** Full support for updating App Name across **all 6 platforms** (Android, iOS, macOS, Web, Windows, and Linux).
- **All-Platform Package ID / Bundle ID Migration:** Updates application IDs across Android (Gradle Groovy & KTS), iOS (`project.pbxproj`), macOS (`AppInfo.xcconfig`), Linux (`CMakeLists.txt`), and Windows (`CMakeLists.txt`).
- **Full-Tree Android Code Refactoring:** Recursively relocates all Kotlin and Java files, updates `package` statements across sub-packages, rewrites internal project imports, safely ignores engine files (`GeneratedPluginRegistrant.java`), and prunes empty directories.
- **High-Fidelity Notification Engine:**
  - Renders notification icons at 100% full-canvas scale (`24` to `96px`), preserving fine strokes and delicate line art.
  - Added optional `notification_icon_name` property (defaults to `ic_notification`) to support custom drawable filenames.
  - Automatically deletes stale default `ic_notification.png` assets when a custom name is configured to prevent APK bloat.
  - Universal image format support: automatically normalizes 8-bit paletted PNGs, 24-bit RGB, and 32-bit RGBA into a 4-channel buffer.
  - Preserves subpixel antialiasing curves without destructive alpha thresholding.
- **Android 13+ Themed / Monochromatic Icons:** Added Material You dynamic theming support by generating `ic_launcher_monochrome.png` and injecting `<monochrome>` tags into `res/mipmap-anydpi-v26/ic_launcher.xml`.
- **Adaptive Icon Image Backgrounds:** Added `launcher_icon_bg_image` property to allow custom image textures for Android adaptive backgrounds instead of solid hex colors.
- **Round Icon Generation:** Generates `ic_launcher_round.xml` and legacy round mipmap variants for OEM launchers that enforce circular icons.
- **Native Desktop & Web Metadata:**
  - Windows: Updates `Runner.rc` (`FileDescription`, `ProductName`, `InternalName`) and window title in `main.cpp`.
  - Linux: Updates both standard window title and GTK HeaderBar title in `linux/runner/my_application.cc`.
  - macOS: Updates `PRODUCT_NAME` and `PRODUCT_BUNDLE_IDENTIFIER` in `AppInfo.xcconfig`.
  - Web: Updates `<title>` and mobile meta tags in `index.html`, and `name` / `short_name` in `manifest.json`.

### Edge Cases & Reliability Fixes
- **XML Entity Escaping:** Automatically escapes special characters (e.g., `&` to `&amp;`) in `AndroidManifest.xml` to prevent AAPT build failures with titles containing ampersands.
- **Universal UTF-8 Encoding:** Enforces `utf8` across all file read/write operations to prevent character corruption on Windows for non-ASCII titles, accents, and German umlauts.
- **iOS Extension Target Protection:** Preserves distinct bundle identifier suffixes for iOS extensions and test targets (`RunnerTests`, widgets, share extensions) in Xcode rather than causing code-signing collisions.
- **Windows Runner Compatibility:** Added regex flexibility to match both `window.Create` and `window.CreateAndShow` across different Flutter Windows C++ runner templates.

---

## 1.0.1

- Added a runnable example in `example/main.dart`.
- Refined image interpolation with `Interpolation.average` and added an 80% safe-zone margin for Android notification icons.
- Added full 20-asset iOS catalog generation to resolve missing icon slots.

---

## 1.0.0

- Initial stable release.
- Standalone native engine (zero wrapper bloat).
- Launcher icons for Android & iOS.
- Native splash screen wiring for Android 12+ Splash API, Android <12, and iOS Storyboards.
- Monochrome notification silhouette generator with automatic luminance inversion.
- Google Play Store marketing kit (512×512 solid icon + 1024×500 feature graphic banner).
- Standalone `rebrand_kit.yaml` configuration support.