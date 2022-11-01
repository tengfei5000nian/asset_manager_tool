import 'dart:io';

import 'package:path/path.dart';

import '../lib.dart';
import '../logger.dart';
import '../options.dart';
import 'asset_item.dart';
import 'image_asset_item.dart';

// 表示asset资产清单的类
class AssetList {
  // 生成list资产清单时资产清单的类名
  static const String className = 'AssetList';

  // 通过解析list清单文件创建一个AssetList实例
  static Future<AssetList?> readListFile(Lib lib, SharedOptions options) async {
    final File file = File(options.listPath);
    if (await file.exists()) {
      final String content = await file.readAsString();
      final AssetList list = AssetList(
        lib: lib,
        options: options,
        content: content,
      );
      return list;
    } else {
      return null;
    }
  }

  // 通过监听的asset资产路径创建一个AssetList实例
  static Future<AssetList?> readAssetDir(Lib lib, SharedOptions options) async {
    if (options.assetPaths.isEmpty) return null;

    final AssetList list = AssetList(
      lib: lib,
      options: options,
    );

    final List<String> paths = await options.findAssetPaths;
    await Future.wait(
      paths.map((String path) async {
        await list.add(path, nowWrite: false);
      })
    );

    return list;
  }

  // 一个符合lib匹配规则的文件数据缓存类实例
  final Lib lib;
  // 当前执行的命令所携带的参数集
  final SharedOptions options;
  // 以path:AssetItem的方式缓存asset资产
  final Map<String, AssetItem> list = {};

  AssetList({
    required this.lib,
    required this.options,
    String? content,
  }) {
    if (content == null) return;

    switch (options.formatType) {
      case FormatType.value:
        content = ImageAssetItem.explainValue(
          lib: lib,
          options: options,
          content: content,
          callback: (ImageAssetItem item) => list[item.path] = item,
        );
        content = AssetItem.explainValue(
          lib: lib,
          options: options,
          content: content,
          callback: (AssetItem item) => list[item.path] = item,
        );
        break;
      case FormatType.model:
        content = ImageAssetItem.explainModel(
          lib: lib,
          options: options,
          content: content,
          callback: (ImageAssetItem item) => list[item.path] = item,
        );
        content = AssetItem.explainModel(
          lib: lib,
          options: options,
          content: content,
          callback: (AssetItem item) => list[item.path] = item,
        );
        break;
      default:
        break;
    }
  }

  // 从list中获取AssetItem列表并根据assetItem.name排序
  List<AssetItem> get assets {
    final List<AssetItem> data = list.values.toList();
    data.sort((a, b) => a.name.compareTo(b.name));
    return data;
  }

  // 添加资产
  Future<void> add(
    String path, {
    bool nowWrite = true,
    bool isFailTip = true,
  }) async {
    final AssetItem? asset = ImageAssetItem.exts.contains(extension(path).substring(1))
      ? await ImageAssetItem.readFile(path, lib, options)
      : await AssetItem.readFile(path, lib, options);

    if (asset == null) {
      if (isFailTip) logger.warning(className, 'add失败，asset中不存在$path', StackTrace.current);
    } else {
      final AssetItem? oldAsset = list[path];
      if (oldAsset?.hash == asset.hash) return;

      list[path] = asset;

      await Future.wait([
        asset.dustbinExists.then((bool exists) async {
          if (exists) await File(asset.dustbinPath).delete();
        }),
        if (nowWrite) writeListFile(),
      ]);
    }
  }

  // 删除资产
  Future<void> remove(
    String path, {
    bool useMemory = false,
    bool nowWrite = true,
    bool isFailTip = true,
  }) async {
    final AssetItem? asset = list.remove(path);
    if (asset == null) return;

    await Future.wait([
      asset.remove(
        useMemory: useMemory,
        isFailTip: isFailTip,
      ),
      if (nowWrite) writeListFile(),
    ]);
  }

  // 从当前list清单中获取assetItem
  AssetItem? get(AssetItem asset) {
    final AssetItem? item = list[asset.path];
    if (item?.hash == asset.hash) {
      return item;
    } else {
      return null;
    }
  }

  // 写入list清单文件
  Future<void> writeListFile() async {
    final File file = File(options.listPath);
    final String content = toString();

    if (await file.exists() && await file.readAsString() == content) return;

    await file.writeAsString(content);
  }

  // 检查资产清单中的资产，判断是否实际存在或有无用资产，同步数据
  Future<void> checkAsset({
    AssetList? oldList,
    bool nowWrite = true,
  }) async {
    final AssetList? assetList = await AssetList.readAssetDir(lib, options);
    if (assetList == null) {
      logger.warning(className, 'checkAsset失败，assetPaths不存在${options.assetPaths}', StackTrace.current);
    } else {
      await Future.wait(
        list.values.map((AssetItem item) async {
          final AssetItem? asset = assetList.get(item);
          if (asset == null) {
            await item.resume();
          } else {
            item.content = asset.content;
            if (oldList?.get(item) == null) logger.info('add ${item.path}');
          }
          assetList.list.remove(item.path);
        })
      );

      await Future.wait(
        assetList.list.values.map((AssetItem item) async {
          await item.remove();
        })
      );
    }
    if (nowWrite) await writeListFile();
  }

  // 清除未使用的asset资源
  Future<void> clean({
    bool nowWrite = true,
  }) async {
    final List<AssetItem> items = list.values.toList();
    await Future.wait(
      items.map((AssetItem item) async {
        if (item.isUse) return;
        await remove(item.path, nowWrite: false);
      })
    );
    if (nowWrite) await writeListFile();
  }

  String toValueString() => '''
abstract class $className {
${assets.map((AssetItem item) => '  ${item.toValueString()}'.replaceAll('\n', '\n  ')).join('\n\n')}
}
''';

  String toModelString() => '''
abstract class $className {
${assets.map((AssetItem item) => '  ${item.toModelString()}').join('\n')}
}

class ${AssetItem.className} {
  final String path;

  const ${AssetItem.className}(
    this.path,
  );
}

class ${ImageAssetItem.className} extends ${AssetItem.className} {
  final int width;
  final int height;

  const ${ImageAssetItem.className}(
    super.path,
    this.width,
    this.height,
  );
}
''';

  @override
  String toString() {
    switch (options.formatType) {
      case FormatType.value:
        return toValueString();
      case FormatType.model:
        return toModelString();
      default:
        return super.toString();
    }
  }
}
