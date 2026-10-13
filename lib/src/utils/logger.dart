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
  static const _gray = '\x1B[90m';

  static void banner() {
    _lap
      ..reset()
      ..start();
    stdout.writeln(
      '\n$_cyan$_bold=========================================$_reset',
    );
    stdout.writeln(
      '$_cyan$_bold    FLUTTER REBRAND KIT CLI (v1.3.0)    $_reset',
    );
    stdout.writeln(
      '$_cyan$_bold=========================================$_reset\n',
    );
  }

  /// Measures the time between two printed steps.
  static final Stopwatch _lap = Stopwatch();

  static void step(int step, int total, String title, String detail) {
    final stepStr = '[$step/$total]'.padRight(8);
    final millis = _lap.elapsedMilliseconds;
    _lap
      ..reset()
      ..start();
    final took = millis >= 100
        ? ' $_gray(${(millis / 1000).toStringAsFixed(1)}s)$_reset'
        : '';
    stdout.writeln(
      '$_bold$stepStr$_reset ${title.padRight(22)} ➜ $_green$detail$_reset$took',
    );
  }

  /// Indented detail line printed under a [step].
  static void subStep(String detail) {
    stdout.writeln('         $_cyan•$_reset $_gray$detail$_reset');
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
