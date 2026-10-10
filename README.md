# Flutter Rebrand Kit

[![Pub Version](https://img.shields.io/pub/v/flutter_rebrand_kit)](https://pub.dev/packages/flutter_rebrand_kit)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A single-command CLI to rebrand Flutter apps: app name, package/bundle ID, version, launcher icons for all six platforms, Android notification icons, native splash screens and Google Play graphics. Pure Dart, no other CLI tools are invoked.

> ⚠️ **Commit or stash your work first.** The tool edits native files (Android, iOS, macOS, Windows, Linux, Web) and moves Kotlin/Java source folders in place. There is no dry-run or rollback yet (planned for 1.4.0), so review the diff after every run.

---

## What it does

| Area                    | What happens                                                                                                                                                                                                                                                            |
|:------------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **App name**            | Android `<application>` label, iOS `Info.plist`, macOS `PRODUCT_NAME`, Web `index.html` + `manifest.json`, Windows window title + `Runner.rc`, Linux GTK titles. Names are escaped for each file format (`&`, quotes, `<`, non-ASCII).                                  |
| **Package / bundle ID** | Gradle (Groovy & Kotlin DSL), Android manifests, iOS/macOS Xcode projects, macOS `AppInfo.xcconfig`, Windows binary name, Linux `APPLICATION_ID`. Kotlin/Java sources are moved to the new package and `package`/`import` lines are rewritten. IDs are validated first. |
| **Version**             | Updates `version:` in `pubspec.yaml` (`x.y.z` or `x.y.z+build`). Flutter propagates it to the platforms at build time.                                                                                                                                                  |
| **Launcher icons**      | Android (legacy, circular round, adaptive, Android 13+ monochrome), iOS (full iPhone/iPad catalog + iOS 18 Dark & Tinted), macOS, Web (favicon, PWA, maskable), Windows (`.ico`), Linux (PNG). Platforms whose folder is missing are skipped.                           |
| **Notification icons**  | Android white silhouettes (24–96 px) with a custom drawable name.                                                                                                                                                                                                       |
| **Native splash**       | Android (density assets, `drawable` + `drawable-v21`, Android 12+ `values-v31`), iOS (`LaunchImage` + storyboard background color).                                                                                                                                     |
| **Play Store assets**   | 512×512 icon and 1024×500 feature graphic.                                                                                                                                                                                                                              |

## Platform support

| Feature             |            Android            |            iOS            | macOS |             Web              |      Windows      |         Linux         |
|:--------------------|:-----------------------------:|:-------------------------:|:-----:|:----------------------------:|:-----------------:|:---------------------:|
| App name            |               ✓               |             ✓             |   ✓   |              ✓               |         ✓         |           ✓           |
| Package / bundle ID |   ✓ *(+ source migration)*    |             ✓             |   ✓   |             N/A              | ✓ *(binary name)* |     ✓ *(app ID)*      |
| Version             |               ✓               |             ✓             |   ✓   |              ✓               |         ✓         |           ✓           |
| Launcher icons      | ✓ *(adaptive, round, themed)* | ✓ *(light, dark, tinted)* |   ✓   | ✓ *(favicon, PWA, maskable)* |    ✓ *(.ico)*     | ✓ *(PNG, see limits)* |
| Notification icons  |               ✓               |            N/A            |  N/A  |             N/A              |        N/A        |          N/A          |
| Native splash       |               ✓               |             ✓             |  N/A  |          ⏳ Planned           |        N/A        |          N/A          |
| Play Store graphics |               ✓               |            N/A            |  N/A  |             N/A              |        N/A        |          N/A          |

---

## Quick start

```bash
flutter pub add -d flutter_rebrand_kit
dart run flutter_rebrand_kit:rebrand_kit init   # creates rebrand_kit.yaml (or: dart run flutter_rebrand_kit:init)
# edit rebrand_kit.yaml, then:
dart run flutter_rebrand_kit:rebrand_kit
```

The command exits with a non-zero code when something fails, so it can be used in scripts and CI.

### Configuration

Use **either** `rebrand_kit.yaml` in the project root (checked first) **or** a `rebrand_kit:` block in `pubspec.yaml`. Every field is optional.

```yaml
app_name: "My Awesome App"
package_id: "com.company.awesomeapp"
version: "1.2.0+15"

launcher_icon: "assets/branding/app_logo_1024.png"   # 1024x1024 transparent PNG recommended
launcher_icon_bg_color: "#FFFFFF"
# launcher_icon_bg_image: "assets/branding/adaptive_bg.png"
# launcher_icon_monochrome: "assets/branding/custom_mono.png"

notification_icon: "assets/branding/app_logo_1024.png"   # transparent PNG
notification_icon_name: "ic_stat_notification"           # default: ic_notification

splash_image: "assets/branding/app_logo_1024.png"
splash_color: "#1E1E2E"

play_store:
  generate: true            # requires launcher_icon
  background_color: "#1E1E2E"
  tagline: "Build better and ship faster"
```

| Property                      | Default           | Description                                                                                                          |
|:------------------------------|:------------------|:---------------------------------------------------------------------------------------------------------------------|
| `app_name`                    | –                 | Display name on all platforms.                                                                                       |
| `package_id`                  | –                 | Application/bundle ID. At least two dot-separated segments; letters, digits, `_`; each segment starts with a letter. |
| `version`                     | –                 | `x.y.z` or `x.y.z+build`, written to `pubspec.yaml`.                                                                 |
| `launcher_icon`               | –                 | Master logo used for all platforms. Non-square images are centered on a transparent square (never stretched).        |
| `launcher_icon_bg_color`      | `#FFFFFF`         | Background for Android icons, iOS/macOS/Web/Linux icons and Play Store. `#RGB` or `#RRGGBB`.                         |
| `launcher_icon_bg_image`      | –                 | Image background instead of a color.                                                                                 |
| `launcher_icon_monochrome`    | –                 | Custom Android 13+ silhouette (derived from the logo when omitted).                                                  |
| `notification_icon`           | –                 | Source for the white status-bar silhouette.                                                                          |
| `notification_icon_name`      | `ic_notification` | Lowercase letters, digits, `_`. When not the default, a leftover `ic_notification.png` is deleted.                   |
| `splash_image`                | –                 | Splash logo.                                                                                                         |
| `splash_color`                | `#FFFFFF`         | Splash background (Android and iOS).                                                                                 |
| `play_store.generate`         | `false`           | Writes to `branding_assets/play_store/`.                                                                             |
| `play_store.background_color` | `#1E1E2E`         | Canvas color of the store icon and banner.                                                                           |
| `play_store.tagline`          | –                 | Subtitle on the banner (basic ASCII only).                                                                           |

## Master image tips

- Use a **1024×1024 PNG with a transparent background**. A different size works but triggers a warning.
- iOS icons (light and dark) are written **without an alpha channel**, as the App Store requires.
- Android 13+ themed icons and notification icons are built from the logo's alpha channel. An opaque logo produces a solid white square, so the tool warns you. Provide `launcher_icon_monochrome` or a transparent PNG.

## Generated files

| Asset                           | Location                                                                                                                                                           |
|:--------------------------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Android legacy + round icons    | `android/app/src/main/res/mipmap-*/ic_launcher.png`, `ic_launcher_round.png`                                                                                       |
| Android adaptive / themed icons | `mipmap-anydpi-v26/ic_launcher.xml`, `ic_launcher_round.xml`, `mipmap-*/ic_launcher_foreground.png`, `ic_launcher_monochrome.png`                                  |
| Android manifest                | `android:icon` and `android:roundIcon` are added to `<application>` only when missing                                                                              |
| iOS icons                       | `ios/Runner/Assets.xcassets/AppIcon.appiconset/` (standard iPhone/iPad set, `Icon-App-Dark-1024x1024@1x.png`, `Icon-App-Tinted-1024x1024@1x.png`, `Contents.json`) |
| macOS icons                     | `macos/Runner/Assets.xcassets/AppIcon.appiconset/` (16–1024 px)                                                                                                    |
| Windows icon                    | `windows/runner/resources/app_icon.ico` (16, 32, 48, 256 px, transparent)                                                                                          |
| Linux icon                      | `linux/runner/assets/app_icon.png` (256×256)                                                                                                                       |
| Web icons                       | `web/favicon.png`, `web/icons/Icon-192.png`, `Icon-512.png`, `Icon-maskable-192.png`, `Icon-maskable-512.png`                                                      |
| Notification icons              | `android/app/src/main/res/drawable-*/<icon_name>.png`                                                                                                              |
| Android splash                  | `drawable-{mdpi..xxxhdpi}/splash_logo.png`, `drawable/launch_background.xml`, `drawable-v21/launch_background.xml`, `values/colors.xml`, `values-v31/styles.xml`   |
| iOS splash                      | `ios/Runner/Assets.xcassets/LaunchImage.imageset/`, background color in `Base.lproj/LaunchScreen.storyboard`                                                       |
| Play Store                      | `branding_assets/play_store/play_store_512.png`, `feature_graphic_1024x500.png`                                                                                    |

## Behavior worth knowing

- **Existing files are edited, not replaced, where possible:** `colors.xml` entries are updated in place, `values-v31/styles.xml` is merged into an existing `LaunchTheme`, `<application>` icon attributes are only added when absent, iOS/macOS test targets and app extensions keep their bundle-ID suffix (`.RunnerTests`, `.ShareExtension`, …).
- **Package IDs:** only the first `applicationId` and `namespace` assignment in Gradle is rewritten (the `defaultConfig` one), so product flavors keep their own IDs. Sources under `io/flutter` (engine files) and code from unrelated packages are left alone.
- **Re-running is safe:** running the tool twice with the same configuration produces the same result.
- **Missing platforms are skipped:** no `ios/` folder means no iOS files are created.

---

## Known limitations (v1.2.0)

- **No dry-run or rollback yet.** Commit before running. (Planned for 1.4.0.)
- **Flavors:** no per-flavor names, IDs or icons. Flavor-specific `applicationId` values are left untouched. (Planned.)
- **One master image for all platforms.** iOS Dark and Tinted icons are generated automatically (Dark: the logo on `#1A1A1A`, Tinted: a grayscale copy of the light icon). Per-platform and custom Dark/Tinted images are planned.
- **Splash:** no Web splash and no dark-mode splash yet. (Planned.)
- **Localized app names** (`strings.xml` translations, `InfoPlist.strings`) and Windows `CompanyName` / `LegalCopyright` are not changed.

### Good to know

- **Linux:** the icon is exported to `linux/runner/assets/app_icon.png`, but the default runner does not load it. Add `gtk_window_set_icon_from_file` in `my_application.cc` if you want it as the window icon.
- **After changing the package ID,** also update anything tied to the old ID: Firebase config files, signing configs, deep links and intent filters, and ProGuard rules.

---

## License

MIT, see [LICENSE](LICENSE).
