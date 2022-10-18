import 'package:logging/logging.dart' as g;

class Logger {
  late g.Logger lg;

  Logger(String name) {
    g.Logger.root.level = g.Level.ALL;
    g.Logger.root.onRecord.listen((g.LogRecord record) {
      print('[${record.time}]${record.loggerName} ${record.level}: ${record.message}');
    });
    lg = g.Logger(name);
  }

  void warning(String name, String msg) => lg.warning('$name($msg)');

  void severe(String name, String msg) => lg.severe('$name($msg)');
}

final Logger logger = Logger('AssetManagerTool');
