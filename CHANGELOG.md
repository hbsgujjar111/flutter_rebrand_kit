# Changelog

## 1.1.0

### Highlights & New Features
- **All-Platform App Renaming:** Full support for updating App Name across **all 6 platforms** (Android, iOS, macOS, Web, Windows, and Linux).
- **All-Platform Package ID / Bundle ID Migration:** Updates application IDs across Android (Gradle Groovy & KTS), iOS (`project.pbxproj`), macOS (`AppInfo.xcconfig`), Linux (`CMakeLists.txt`), and Windows (`CMakeLists.txt`).
- **Full-Tree Android Code Refactoring:** Recursively relocates all Kotlin and Java files, updates `package` statements across sub-packages, rewrites internal project imports, safely ignores engine files (`GeneratedPluginRegistrant.java`), and prunes empty directories.
- **Android 13+ Themed / Monochromatic Icons:** Added Material You dynamic theming support by generating `ic_launcher_monochrome.png` and injecting `<monochrome>` tags into `res/mipmap-anydpi-v26/ic_launcher.xml`.
- **Adaptive Icon Image Backgrounds:** Added `launcher_icon_bg_image` property to allow custom image textures for Android adaptive backgrounds instead of solid hex colors.
- **Round Icon Generation:** Generates `ic_launcher_round.xml` and legacy round mipmap variants for OEM launchers that enforce circular icons.
- **Native Desktop & Web Metadata:**
    - Windows: Updates `Runner.rc` (`FileDescription`, `ProductName`, `InternalName`) and window title in `main.cpp`.
    - Linux: Updates both standard window title and GTK HeaderBar title in `linux/runner/my_application.cc`.
    - macOS: Updates `PRODUCT_NAME` and `PRODUCT_BUNDLE_IDENTIFIER` in `AppInfo.xcconfig`.
    - Web: Updates `<title>` and mobile meta tags in `index.html`, and `name` / `short_name` in `manifest.json`.

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