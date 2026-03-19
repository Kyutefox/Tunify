import 'dart:io' as io;

import 'package:logger/logger.dart';

/// Logger config for VM platforms (mobile, desktop). Uses terminal columns and ANSI colors.
Logger createAppLogger() => Logger(
      filter: _AppLogFilter(),
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 6,
        lineLength: io.stdout.hasTerminal ? io.stdout.terminalColumns : 120,
        colors: io.stdout.supportsAnsiEscapes,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      output: ConsoleOutput(),
    );

class _AppLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => true;
}
