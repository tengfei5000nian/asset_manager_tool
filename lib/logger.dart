import 'package:io/ansi.dart';
import 'package:logging/logging.dart' as g;

// 日志输出类
class Logger {
  late g.Logger lg;

  Logger(String name) {
    g.Logger.root.level = g.Level.ALL;
    g.Logger.root.onRecord.listen((g.LogRecord record) {
      final String? tool = lightCyan.wrap('[${record.time}] ${record.loggerName}:');
      final String? stackTrace = record.stackTrace == null ? '' : darkGray.wrap('\n${record.stackTrace}');
      final String message = ' ${record.message}';
      if (record.level == g.Level.INFO) {
        print('$tool${white.wrap(message)}$stackTrace');
      } else if (record.level == g.Level.FINER) {
        print('$tool${green.wrap(message)}$stackTrace');
      } else if (record.level == g.Level.WARNING) {
        print('$tool${yellow.wrap(message)}$stackTrace');
      } else if (record.level == g.Level.SEVERE) {
        print('$tool${red.wrap(message)}$stackTrace');
      }
    });
    lg = g.Logger(name);
  }

  // 输出普通message
  void info(String message) => lg.info(message);

  // 输出通知message
  void notice(String message) => lg.finer(message);

  // 输出警示message
  void warning(String name, Object error, StackTrace stackTrace) => lg.warning('$name($error)', error, stackTrace);

  // 输出错误message
  void severe(String name, Object error, StackTrace stackTrace) => lg.severe('$name($error)', error, stackTrace);
}

final Logger logger = Logger('AssetManagerTool');
