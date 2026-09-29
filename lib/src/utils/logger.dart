import 'dart:io';

/// Terminal logger utility for formatting CLI output.
class Logger {
  Logger._();

  static const _reset = '\x1B[0m';
  static const _green = '\x1B[32m';
  static const _cyan = '\x1B[36m';
  static const _yellow = '\x1B[33m';
  static const _red = '\x1B[31m';
  static const _bold = '\x1B[1m';

  static void banner() {
    stdout.writeln(
      '\n$_cyan$_bold=========================================$_reset',
    );
    stdout.writeln(
      '$_cyan$_bold    FLUTTER REBRAND KIT CLI (v1.2.0)    $_reset',
    );
    stdout.writeln(
      '$_cyan$_bold=========================================$_reset\n',
    );
  }

  static void step(int step, int total, String title, String detail) {
    final stepStr = '[$step/$total]'.padRight(8);
    stdout.writeln(
      '$_bold$stepStr$_reset ${title.padRight(22)} ➜ $_green$detail$_reset',
    );
  }

  static void warn(String message) {
    stdout.writeln('$_yellow$_bold⚠ WARNING:$_reset $_yellow$message$_reset');
  }

  static void error(String message) {
    stderr.writeln('$_red$_bold✖ ERROR:$_reset $_red$message$_reset');
  }

  static void success(String message) {
    stdout.writeln('\n$_green$_bold✨ $message$_reset\n');
  }
}
