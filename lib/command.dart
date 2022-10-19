import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:watcher/watcher.dart';
import 'package:path/path.dart';

import 'asset.dart';
import 'options.dart';

abstract class RunnerCommand extends Command<int> {
  RunnerCommand() : super() {
    argParser
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
        excludePathOption.name,
        abbr: excludePathOption.abbr,
        help: excludePathOption.help,
        valueHelp: excludePathOption.valueHelp ?? excludePathOption.defaultsTo,
      )
      ..addMultiOption(
        nameReplaceOption.name,
        abbr: nameReplaceOption.abbr,
        help: nameReplaceOption.help,
        valueHelp: nameReplaceOption.valueHelp ?? nameReplaceOption.defaultsTo,
      );
  }

  SharedOptions get sharedOptions => SharedOptions.create(argResults);
}

class WatchCommand extends RunnerCommand {
  WatchCommand() : super();

  @override
  String get name => 'watch';

  @override
  String get description => '以asset资源为起点创建清单list数据，然后监听asset和清单list的修改重建list或删除asset';

  @override
  Future<int> run() async {
    final Completer<int> completer = Completer();

    AssetList? list = await AssetList.readAssetDir(sharedOptions);
    await list?.writeListFile();

    Watcher(current).events.listen((WatchEvent e) async {
      try {
        if (!isWithin(current, e.path)) return;
        final String changePath = relative(e.path, from: current);

        if (equals(sharedOptions.listPath, changePath)) {
          final AssetList? newList = await AssetList.readListFile(sharedOptions);
          if (newList.toString() == list.toString()) return;

          await newList?.checkAsset();

          if (newList.toString() == list.toString()) return;

          await newList?.writeListFile();
          list = newList;
        } else {
          for (final String path in sharedOptions.assetPaths) {
            if (!(
              (isWithin(path, changePath) && split(changePath).length - split(path).length == 1) ||
              equals(path, changePath)
            )) continue;
            if (sharedOptions.isExcludePath(changePath)) continue;
            if (extension(changePath).isEmpty) continue;

            if (e.type == ChangeType.REMOVE) {
              await list?.remove(changePath);
            } else if (e.type == ChangeType.ADD || e.type == ChangeType.MODIFY) {
              await list?.add(changePath);
            }
          }
        }
      } catch (err) {
        completer.completeError(err);
      }
    }).onError((err) {
      completer.completeError(err);
    });

    return await completer.future;
  }
}

class BuildAssetCommand extends RunnerCommand {
  BuildAssetCommand() : super();

  @override
  String get name => 'build:asset';

  @override
  String get description => '以asset资源为起点创建清单list数据';

  @override
  Future<int> run() async {
    final AssetList? list = await AssetList.readAssetDir(sharedOptions);
    await list?.writeListFile();
    return 0;
  }
}

class BuildListCommand extends RunnerCommand {
  BuildListCommand() : super();

  @override
  String get name => 'build:list';

  @override
  String get description => '以清单list数据为起点删除或恢复asset资源';

  @override
  Future<int> run() async {
    final AssetList? list = await AssetList.readListFile(sharedOptions);
    await list?.checkAsset();
    await list?.writeListFile();
    return 0;
  }
}
