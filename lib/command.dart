import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:watcher/watcher.dart';
import 'package:path/path.dart';

import 'asset.dart';
import 'lib.dart';
import 'logger.dart';
import 'options.dart';

abstract class RunnerCommand extends Command<int> {
  RunnerCommand() : super() {
    argParser
      ..addMultiOption(
        libPathOption.name,
        abbr: libPathOption.abbr,
        help: libPathOption.help,
        valueHelp: libPathOption.valueHelp ?? libPathOption.defaultsTo,
      )
      ..addMultiOption(
        assetPathOption.name,
        abbr: assetPathOption.abbr,
        help: assetPathOption.help,
        valueHelp: assetPathOption.valueHelp ?? assetPathOption.defaultsTo,
      )
      ..addOption(
        dustbinPathOption.name,
        abbr: dustbinPathOption.abbr,
        help: dustbinPathOption.help,
        valueHelp: dustbinPathOption.valueHelp ?? dustbinPathOption.defaultsTo,
      )
      ..addOption(
        listPathOption.name,
        abbr: listPathOption.abbr,
        help: listPathOption.help,
        valueHelp: listPathOption.valueHelp ?? listPathOption.defaultsTo,
      )
      ..addOption(
        configPathOption.name,
        help: configPathOption.help,
        valueHelp: configPathOption.valueHelp ?? configPathOption.defaultsTo,
      )
      ..addMultiOption(
        nameReplaceOption.name,
        abbr: nameReplaceOption.abbr,
        help: nameReplaceOption.help,
        valueHelp: nameReplaceOption.valueHelp ?? nameReplaceOption.defaultsTo,
      )
      ..addMultiOption(
        excludePathOption.name,
        abbr: excludePathOption.abbr,
        help: excludePathOption.help,
        valueHelp: excludePathOption.valueHelp ?? excludePathOption.defaultsTo,
      );
  }

  SharedOptions get sharedOptions => SharedOptions.create(argResults);

  @override
  Future<int> run() async {
    logger.info(sharedOptions.toString());
    return 0;
  }
}

class WatchCommand extends RunnerCommand {
  @override
  String get name => 'watch';

  @override
  String get description => '以asset资源为起点创建清单list数据，然后监听asset和清单list的修改重建list或删除asset';

  @override
  Future<int> run() async {
    await super.run();

    final Completer<int> completer = Completer();

    final Lib lib = Lib(sharedOptions);
    await lib.init();

    AssetList? list = await AssetList.readAssetDir(lib, sharedOptions);
    await list?.writeListFile();

    Watcher(current).events.listen((WatchEvent e) async {
      try {
        if (!isWithin(current, e.path)) return;
        final String changePath = relative(e.path, from: current);

        if (sharedOptions.isListPath(changePath)) {
          final AssetList? newList = await AssetList.readListFile(lib, sharedOptions);
          if (newList.toString() == list.toString()) return;

          await newList?.checkAsset(nowWrite: false);

          if (newList.toString() == list.toString()) return;

          await newList?.writeListFile();
          list = newList;
        } else if (sharedOptions.isAssetPath(changePath)) {
          if (e.type == ChangeType.REMOVE) {
            await list?.remove(changePath);
          } else if (e.type == ChangeType.ADD || e.type == ChangeType.MODIFY) {
            await list?.add(changePath);
          }
        } else if (sharedOptions.isLibPath(changePath)) {
          if (e.type == ChangeType.REMOVE) {
            await lib.remove(changePath);
          } else if (e.type == ChangeType.ADD || e.type == ChangeType.MODIFY) {
            await lib.add(changePath);
            await list?.writeListFile();
          }
        }
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    }).onError((error, stackTrace) {
      completer.completeError(error, stackTrace ?? StackTrace.current);
    });

    return await completer.future;
  }
}

class BuildAssetCommand extends RunnerCommand {
  @override
  String get name => 'build:asset';

  @override
  String get description => '以asset资源为起点创建清单list数据';

  @override
  Future<int> run() async {
    await super.run();

    final Lib lib = Lib(sharedOptions);
    await lib.init();

    final AssetList? list = await AssetList.readAssetDir(lib, sharedOptions);
    await list?.writeListFile();
    return 0;
  }
}

class BuildListCommand extends RunnerCommand {
  @override
  String get name => 'build:list';

  @override
  String get description => '以清单list数据为起点删除或恢复asset资源';

  @override
  Future<int> run() async {
    await super.run();

    final Lib lib = Lib(sharedOptions);
    await lib.init();

    final AssetList? list = await AssetList.readListFile(lib, sharedOptions);
    await list?.checkAsset();
    return 0;
  }
}

class BuildCleanCommand extends RunnerCommand {
  @override
  String get name => 'clean';

  @override
  String get description => '以清单list数据为起点清除未使用的asset资源';

  @override
  Future<int> run() async {
    await super.run();

    final Lib lib = Lib(sharedOptions);
    await lib.init();

    final AssetList? list = await AssetList.readListFile(lib, sharedOptions);
    await list?.checkAsset(nowWrite: false);
    await list?.clean();
    return 0;
  }
}
