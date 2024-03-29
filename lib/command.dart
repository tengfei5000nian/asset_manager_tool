import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:watcher/watcher.dart';

import 'asset/asset_list.dart';
import 'context.dart';
import 'lib.dart';
import 'logger.dart';
import 'options.dart';
import 'queue.dart';

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
      )
      ..addOption(
        formatTypeOption.name,
        help: formatTypeOption.help,
        valueHelp: formatTypeOption.valueHelp ?? formatTypeOption.defaultsTo,
        allowed: FormatType.values.map((FormatType type) => type.toString().split('.').last)
      );
  }

  SharedOptions get sharedOptions => SharedOptions.create(argResults);

  @override
  Future<int> run() async {
    logger.notice(sharedOptions.toString());
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

    AssetList? newList;

    Watcher(context.current).events.listen((WatchEvent e) {
      queue.add(() async {
        if (!context.isWithin(context.current, e.path)) return;
        final String changePath = context.prettyUri(e.path);

        if (sharedOptions.isListPath(changePath)) {
          newList = await AssetList.readListFile(lib, sharedOptions);
          if (newList.toString() == list.toString()) return;

          await newList?.checkAsset(
            oldList: list,
            nowWrite: false,
          );

          if (newList.toString() == list.toString()) return;

          list = newList;
          newList = null;
          await list?.writeListFile();
        } else if (sharedOptions.isAssetPath(changePath)) {
          if (e.type == ChangeType.REMOVE) {
            if (list?.list[changePath] == null) return;

            await list?.remove(changePath);
          } else if (e.type == ChangeType.ADD || e.type == ChangeType.MODIFY) {
            if (list?.list[changePath] != null) return;

            await list?.add(changePath);
          }
        } else if (sharedOptions.isLibPath(changePath)) {
          if (e.type == ChangeType.REMOVE) {
            await lib.remove(changePath);
            await list?.writeListFile();
          } else if (e.type == ChangeType.ADD || e.type == ChangeType.MODIFY) {
            await lib.add(changePath);
            await list?.writeListFile();
          }
        }
      }).catchError((error, stackTrace) {
        completer.completeError(error, stackTrace);
      });
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
    final int code = await super.run();

    final Lib lib = Lib(sharedOptions);
    await lib.init();

    final AssetList? list = await AssetList.readAssetDir(lib, sharedOptions);
    await list?.writeListFile();

    return code;
  }
}

class BuildListCommand extends RunnerCommand {
  @override
  String get name => 'build:list';

  @override
  String get description => '以清单list数据为起点删除或恢复asset资源';

  @override
  Future<int> run() async {
    final int code = await super.run();

    final Lib lib = Lib(sharedOptions);
    await lib.init();

    final List<AssetList?> assetList = await Future.wait([
      AssetList.readAssetDir(lib, sharedOptions),
      AssetList.readListFile(lib, sharedOptions),
    ]);

    final AssetList? oldList = assetList.first;
    final AssetList? list = assetList.last;

    await list?.checkAsset(
      oldList: oldList,
    );

    return code;
  }
}

class BuildCleanCommand extends RunnerCommand {
  @override
  String get name => 'clean';

  @override
  String get description => '以清单list数据为起点清除未使用的asset资源';

  @override
  Future<int> run() async {
    final int code = await super.run();

    final Lib lib = Lib(sharedOptions);
    await lib.init();

    final List<AssetList?> assetList = await Future.wait([
      AssetList.readAssetDir(lib, sharedOptions),
      AssetList.readListFile(lib, sharedOptions),
    ]);

    final AssetList? oldList = assetList.first;
    final AssetList? list = assetList.last;

    await list?.checkAsset(
      oldList: oldList,
      nowWrite: false,
    );
    await list?.clean();

    return code;
  }
}
