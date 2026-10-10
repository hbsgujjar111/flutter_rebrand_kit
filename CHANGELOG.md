# Changelog

## 1.2.0

### Added
- **`init` command:** `dart run flutter_rebrand_kit:rebrand_kit init` (or `dart run flutter_rebrand_kit:init`) creates a commented `rebrand_kit.yaml`. An existing file is never overwritten.
- **Launcher icons for all 6 platforms** from one master image: Android, iOS, macOS, Web, Windows and Linux. Platform folders that do not exist are skipped.
- **Android round icons:** circular legacy `ic_launcher_round.png` plus `ic_launcher_round.xml`. `android:icon` / `android:roundIcon` are added to `<application>` when missing.
- **iOS 18 Dark and Tinted icons** (1024 px, `Icon-App-Dark-1024x1024@1x.png`, `Icon-App-Tinted-1024x1024@1x.png`) next to the standard iPhone/iPad icon set.
- **Windows `.ico`:** 16, 32, 48 and 256 px frames with transparency, written by a pure-Dart encoder to `windows/runner/resources/app_icon.ico`.
- **Linux icon:** `linux/runner/assets/app_icon.png` (256×256).
- **Web icons:** `web/favicon.png`, `web/icons/Icon-192.png` / `Icon-512.png` and maskable `Icon-maskable-192.png` / `Icon-maskable-512.png`.
- **Input validation** before any file is modified: package ID, version, hex colors, notification icon name.
- **Non-zero exit code** when the CLI fails; the launcher icon step reports which platforms were generated.
- Warnings for opaque logos that would turn into solid white squares (themed and notification icons) and for non-square master images.

### Fixed
- **Names are escaped per file format.** App names containing `&`, quotes or `<` no longer break `Info.plist`, `manifest.json`, the Windows `.rc`/`main.cpp` or the Linux runner; non-ASCII names are written as C++ universal character names on Windows.
- **Windows runner:** `window.CreateAndShow(...)` is no longer rewritten to `window.Create(...)` (broke older templates); `InternalName` and `OriginalFilename` now follow the new binary name.
- **Android package ID:**
  - only the first `applicationId` / `namespace` is rewritten (flavors keep theirs), commented-out lines are ignored, `applicationId = "…"` is supported in Groovy;
  - the old base package is detected from `namespace` / `applicationId` / manifest instead of the first file found;
  - a package such as `com.studio.flutterapp` is no longer mistaken for Flutter engine code;
  - unrelated packages are not moved, files are placed by their declared package, debug/profile manifests are updated;
  - only the `<application>` label changes, activity labels are kept.
- **iOS / macOS bundle IDs:** test targets and extensions are detected from the project instead of a name heuristic, so an ID containing "widget" or "extension" is safe, re-running is idempotent, and the macOS `RunnerTests` target is no longer collapsed onto the main ID.
- **`ic_launcher_background` color** is updated on every run (it used to keep the first value); `colors.xml` is edited in place and self-closing `<resources/>` files are handled.
- **iOS icon catalog** now uses Apple's standard iPhone/iPad entries (including the iPad `@1x` slots); stale `Icon-App-*` files are removed.
- **Native splash (Android):** `drawable-v21/launch_background.xml` is written (it overrides `drawable` on API 21+); logo assets are density-specific and sized for the Android 12 splash circle instead of a single oversized image; `values-v31/styles.xml` is merged instead of overwritten; `splash_color` replaced reliably.
- **Native splash (iOS):** `splash_color` is applied to `LaunchScreen.storyboard`; launch images are properly scaled 1x/2x/3x.
- No stray `android/` or `ios/` folders are created in projects that do not have them.
- Non-square, palette, grayscale and 16-bit master images are normalized instead of being stretched or mis-rendered.
- Play Store banner: font size adapts to long names and taglines; non-ASCII text no longer renders as gaps.

### Changed
- Upgrading: if `launcher_icon` is set, macOS, Web, Windows and Linux icons are now generated and overwritten too (when those folders exist). Commit before running.
- Internal code reorganized into `renamers/`, `icons/`, `splash/`, `marketing/` and `utils/`.

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
  - Windows: Updates `Runner.rc` (`FileDescription`, `ProductName`) and window title in `main.cpp`.
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
