import 'package:io/ansi.dart';
import 'package:logging/logging.dart' as g;

class Logger {
  late g.Logger lg;

  Logger(String name) {
    g.Logger.root.level = g.Level.ALL;
    g.Logger.root.onRecord.listen((g.LogRecord record) {
      String? msg;
      if (record.level == g.Level.WARNING) {
        msg = yellow.wrap('[${record.time}] ${record.loggerName}: ${record.message}');
      } else if (record.level == g.Level.SEVERE) {
        msg = red.wrap('[${record.time}] ${record.loggerName}: ${record.message}');
      }
      print(msg);
    });
    lg = g.Logger(name);
  }

  void warning(String name, String msg) => lg.warning('$name($msg)');

  void severe(String name, String msg) => lg.severe('$name($msg)');
}

final Logger logger = Logger('AssetManagerTool');
