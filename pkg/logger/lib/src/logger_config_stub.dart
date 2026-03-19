import 'package:logger/logger.dart';

/// Logger config for platforms without dart:io (e.g. web). No terminal sizing or ANSI.
Logger createAppLogger() => Logger(
      filter: _AppLogFilter(),
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 6,
        lineLength: 120,
        colors: false,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      output: ConsoleOutput(),
    );

class _AppLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => true;
}
