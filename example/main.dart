import 'dart:io';

import 'package:flutter_rebrand_kit/flutter_rebrand_kit.dart';

void main() {
  final config = RebrandConfig.load();

  stdout.writeln('Loaded App Name: ${config.appName}');
  stdout.writeln('Loaded Package ID: ${config.packageId}');
  stdout.writeln('Loaded Splash Color: ${config.splashColor}');
  stdout.writeln('Loaded Splash Dark Color: ${config.splashDarkColor}');
}
