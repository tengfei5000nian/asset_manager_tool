import 'package:io/ansi.dart';
import 'package:logging/logging.dart' as g;

// 日志输出类
class Logger {
  late g.Logger lg;

  Logger(String name) {
    g.Logger.root.level = g.Level.ALL;
    g.Logger.root.onRecord.listen((g.LogRecord record) {
      final String msg = '[${record.time}] ${record.loggerName}:${record.message}${record.stackTrace == null ? '' : '\n${record.stackTrace}'}';
      if (record.level == g.Level.INFO) {
        print(green.wrap(msg));
      } else if (record.level == g.Level.WARNING) {
        print(yellow.wrap(msg));
      } else if (record.level == g.Level.SEVERE) {
        print(red.wrap(msg));
      }
    });
    lg = g.Logger(name);
  }

  // 输出普通message
  void info(String message) => lg.info(message);

  // 输出警示message
  void warning(String name, Object error, StackTrace stackTrace) => lg.warning(' $name($error)', error, stackTrace);

  // 输出错误message
  void severe(String name, Object error, StackTrace stackTrace) => lg.severe(' $name($error)', error, stackTrace);
}

final Logger logger = Logger('AssetManagerTool');
