import 'dart:io';

import 'package:flutter_rebrand_kit/flutter_rebrand_kit.dart';

void main() {
  // Programmatically load configuration from rebrand_kit.yaml or pubspec.yaml
  final config = RebrandConfig.load();

  // Access loaded branding properties
  stdout.writeln('Loaded App Name: ${config.appName}');
  stdout.writeln('Loaded Package ID: ${config.packageId}');
  stdout.writeln(
    'Loaded Notification Icon Name: ${config.notificationIconName}',
  );

  // Typically, run the tool from the terminal:
  // dart run flutter_rebrand_kit:rebrand_kit
}
