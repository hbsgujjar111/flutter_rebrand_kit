import 'dart:io';

import 'package:flutter_rebrand_kit/flutter_rebrand_kit.dart';

void main() {
  // Load configuration from rebrand_kit.yaml or pubspec.yaml
  final config = RebrandConfig.load();

  // Access loaded branding properties
  stdout.writeln('Configured App Name: ${config.appName}');
  stdout.writeln('Configured Package ID: ${config.packageId}');

  // Typically, run the tool from the terminal:
  // dart run flutter_rebrand_kit:rebrand_kit
}
