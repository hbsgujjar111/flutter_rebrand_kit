import 'dart:convert';
import 'dart:io';

import '../utils/logger.dart';

/// Service for scaffolding initial configuration files.
class InitService {
  InitService._();

  /// Generates a starter `rebrand_kit.yaml` template in the project root.
  static void createTemplate({bool overwrite = false}) {
    final file = File('rebrand_kit.yaml');
    if (file.existsSync() && !overwrite) {
      Logger.warn('rebrand_kit.yaml already exists in project root.');
      return;
    }

    const template = '''
# ==============================================================================
# FLUTTER REBRAND KIT CONFIGURATION (rebrand_kit.yaml)
# All properties are optional. Include only what you need.
# ==============================================================================

# 1. Application Identity (Android, iOS, macOS, Web, Windows, Linux)
app_name: "My App"
package_id: "com.example.myapp"
version: "1.0.0+1"

# 2. Launcher Icons (1024x1024 Transparent PNG recommended)
launcher_icon: "assets/logo.png"
launcher_icon_bg_color: "#FFFFFF"
# launcher_icon_bg_image: "assets/adaptive_bg.png"
# launcher_icon_monochrome: "assets/custom_mono.png"

# 3. Android Notification Silhouette
notification_icon: "assets/logo.png"
notification_icon_name: "ic_notification"

# 4. Native Splash Screen
splash_image: "assets/logo.png"
splash_color: "#FFFFFF"

# 5. Google Play Store Marketing Kit
play_store:
  generate: true
  background_color: "#1E1E2E"
  tagline: "Your App Tagline Here"
  

# Run the CLI command from your terminal to execute
# dart run flutter_rebrand_kit:rebrand_kit  
  
''';

    file.writeAsStringSync(template, encoding: utf8);
    Logger.success('Created "rebrand_kit.yaml" in project root');
  }
}
