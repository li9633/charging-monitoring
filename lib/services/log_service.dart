// =================================================================
// 全局日志服务：记录程序运行日志，支持 info/warning/error/debug 四级
// =================================================================

import 'dart:async';

enum LogLevel { debug, info, warning, error }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
  });

  String get levelLabel {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
    }
  }
}

class LogService {
  static final LogService _instance = LogService._();
  factory LogService() => _instance;
  LogService._();

  final List<LogEntry> _logs = [];
  final StreamController<LogEntry> _controller =
      StreamController<LogEntry>.broadcast();

  List<LogEntry> get logs => List.unmodifiable(_logs);
  Stream<LogEntry> get onLog => _controller.stream;

  void debug(String message) => _add(LogLevel.debug, message);
  void info(String message) => _add(LogLevel.info, message);
  void warning(String message) => _add(LogLevel.warning, message);
  void error(String message) => _add(LogLevel.error, message);

  void _add(LogLevel level, String message) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
    );
    _logs.add(entry);
    _controller.add(entry);
  }

  void clear() {
    _logs.clear();
  }
}