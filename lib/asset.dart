import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart';

import 'lib.dart';
import 'logger.dart';
import 'options.dart';

// 表示一个asset资产的基本数据类
class AssetItem {
  // 生成list资产清单时资产的类名
  static const String className = 'AssetItem';

  // 通过文件地址path创建一个AssetItem资产项
  static Future<AssetItem?> readFile(String path, Lib lib, SharedOptions options) async {
    final File file = File(path);
    if (await file.exists()) {
      final Uint8List content = await file.readAsBytes();
      final Digest contentDigest = md5.convert(content);
      final Digest pathDigest = md5.convert(path.codeUnits);
      final Digest digest = md5.convert('$contentDigest$pathDigest'.codeUnits);
      final List<String> names = split(path.replaceFirst(rootPrefix(path), '').replaceAll(RegExp('[\\.\\_\\-\\s]+'), '/'));
      String name = names.removeAt(0) + names.map((String name) => name
        .toLowerCase()
        .replaceRange(0, 1, name
          .substring(0, 1)
          .toUpperCase()
        )
      ).join();
      for (final String key in options.nameReplaces.keys) {
        final RegExp re = RegExp('^$key');
        if (!re.hasMatch(name)) continue;
        name = name.replaceFirst(re, options.nameReplaces[key] ?? '');
        name = name.replaceRange(0, 1, name
          .substring(0, 1)
          .toLowerCase()
        );
        break;
      }
      return AssetItem(
        path: path,
        name: name,
        hash: digest.toString().substring(0, 8),
        lib: lib,
        options: options,
        content: content,
      );
    } else {
      return null;
    }
  }

  // asset资产所在原始路径
  final String path;
  // 生成list资产清单时的实例名
  final String name;
  // 当前asset资产的文件数据加原始路径的hash
  final String hash;
  // 一个符合lib匹配规则的文件数据缓存类实例
  final Lib lib;
  // 当前执行的命令所携带的参数集
  final SharedOptions options;

  // 当前asset资产的文件数据
  Uint8List? content;

  AssetItem({
    required this.path,
    required this.name,
    required this.hash,
    required this.lib,
    required this.options,
    this.content,
  });

  // 当asset资产被删除移到回收文件夹时的地址
  String get dustbinPath => join(
    options.dustbinPath,
    '$hash${extension(path)}'
  );

  // 判断符合lib匹配规则的文件数据中是否使用了该资产
  bool get isUse => lib.test('${AssetList.className}.$name');

  // 原始路径是否存在该asset资产文件
  Future<bool> get assetExists async => await File(path).exists();

  // 回收文件夹中是否存在该asset资产文件备份
  Future<bool> get dustbinExists async => await File(dustbinPath).exists();

  // 检查回收文件夹是否存在，没有就新建
  Future<void> get checkOrCreateDustbin async {
    final Directory dir = Directory(options.dustbinPath);
    if (await dir.exists()) return;
    await dir.create(recursive: true);
  }

  // 删除当前asset资产，将其移到回收文件夹
  Future<bool> remove({
    bool useMemory = false,
    bool isFailTip = true,
  }) async {
    await checkOrCreateDustbin;

    if (await assetExists) {
      if (useMemory) {
        await File(path).delete();
        if (content != null) {
          await File(dustbinPath).writeAsBytes(content!);
          return true;
        } else {
          return false;
        }
      } else {
        await File(path).rename(dustbinPath);
        return true;
      }
    } else if (content != null) {
      await File(dustbinPath).writeAsBytes(content!);
      return true;
    } else if (isFailTip) {
      logger.warning(className, 'remove失败，asset和memory中不存在$path', StackTrace.current);
    }
    return false;
  }

  // 从回收文件夹恢复当前asset资产，并将其从回收文件夹移除
  Future<bool> resume({
    bool useMemory = false,
    bool isFailTip = true,
  }) async {
    if (await dustbinExists) {
      if (useMemory) {
        await File(dustbinPath).delete();
        if (content != null) {
          await File(path).writeAsBytes(content!);
          return true;
        } else {
          return false;
        }
      } else {
        await File(dustbinPath).rename(path);
        return true;
      }
    } else if (content != null) {
      await File(path).writeAsBytes(content!);
      return true;
    } else if (isFailTip) {
      logger.warning(className, 'resume失败，dustbin和memory中不存在$path', StackTrace.current);
    }
    return false;
  }

  @override
  String toString() => '''/* $hash ${isUse ? 'Y' : 'N'} */ static const String $name = '$path';''';
}

// 表示一个图片asset资产的基本数据类
class ImageAssetItem extends AssetItem {
  // 扩展名符合exts的文件视为图片资产
  static const List<String> exts = ['png', 'jpg', 'jpeg', 'webp', 'gif'];

  // 生成list资产清单时资产的类名
  static const String className = 'ImageAssetItem';

  // 通过图片地址path创建一个ImageAssetItem资产项
  static Future<AssetItem?> readFile(String path, Lib lib, SharedOptions options) async {
    final AssetItem? asset = await AssetItem.readFile(path, lib, options);
    if (asset != null) {
      final Image? img = decodeImage(asset.content!);
      return img == null
        ? asset
        : ImageAssetItem(
          path: asset.path,
          name: asset.name,
          hash: asset.hash,
          lib: asset.lib,
          options: asset.options,
          content: asset.content,
          width: img.width,
          height: img.height,
        );
    } else {
      return null;
    }
  }

  // 图片的宽
  final int width;
  // 图片的高
  final int height;

  ImageAssetItem({
    required super.path,
    required super.name,
    required super.hash,
    required super.lib,
    required super.options,
    super.content,
    required this.width,
    required this.height,
  });

  String toSizeString() => ''''$path': Size($width, $height),''';
}

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

    // 解析AssetItem参数
    final String reArg = '[\'"]{0,1}([^\\s\\;\'"]+)[\'"]{0,1}';
    // 解析AssetItem备注
    final String reMark = '[\\n\\s]*\\/\\*\\s*([^\\s]+)\\s+(Y|N)\\s*\\*\\/';
    // 解析AssetItem数据
    final String reAssetItem = '$reMark\\s*static\\s+const\\s+String\\s+([\\w\\d]+)\\s*\\=\\s*$reArg\\s*;';
    // 解析AssetList数据
    final String reClass = 'abstract\\s+class\\s+$className\\s*\\{($reAssetItem)*[\\n\\s]*\\}';

    if (!RegExp(reClass).hasMatch(content)) return;

    content.replaceAllMapped(RegExp(reAssetItem), (Match match) {
      final String hash = match.group(1)!;
      final String name = match.group(3)!;
      final String path = match.group(4)!;

      // 解析Size参数
      final String reInt = '[\\n\\s]*(\\d+)\\s*,?';
      // 解析Size数据
      final String reSize = ''''$path'\\s*\\:\\s*Size\\($reInt$reInt[\\n\\s]*\\)\\s*,?''';

      if (RegExp(reSize).hasMatch(content)) {
        content.replaceAllMapped(RegExp(reSize), (Match match) {
          final int width = int.parse(match.group(1)!);
          final int height = int.parse(match.group(2)!);
          list[path] = ImageAssetItem(
            path: path,
            name: name,
            hash: hash,
            width: width,
            height: height,
            lib: lib,
            options: options,
          );
          return '';
        });
      } else {
        list[path] = AssetItem(
          path: path,
          name: name,
          hash: hash,
          lib: lib,
          options: options,
        );
      }
      return '';
    });
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
      list[path] = asset;
      if (await asset.dustbinExists) await File(asset.dustbinPath).delete();
      if (nowWrite) await writeListFile();
    }
  }

  // 删除资产
  Future<void> remove(
    String path, {
    bool useMemory = false,
    bool nowWrite = true,
    bool isFailTip = true,
  }) async {
    await list.remove(path)?.remove(
      useMemory: useMemory,
      isFailTip: isFailTip,
    );
    if (nowWrite) await writeListFile();
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

  @override
  String toString() {
    final List<AssetItem> assets = this.assets;
    final List<ImageAssetItem> imgs = [];
    final List<AssetItem> files = [];

    for (final AssetItem file in assets) {
      if (file is ImageAssetItem) {
        imgs.add(file);
      } else {
        files.add(file);
      }
    }

    return '''
abstract class $className {
${imgs.map((ImageAssetItem item) => '  $item').join('\n')}
${files.map((AssetItem item) => '  $item').join('\n')}
}

const Map<String, Size> _sizes = {
${imgs.map((ImageAssetItem item) => '  ${item.toSizeString()}').join('\n')}
};

extension AssetStringExtension on String {
  Size? get size => _sizes[this];
  int? get width => size?.width;
  int? get height => size?.height;
}

class Size {
  final int width;
  final int height;

  const Size(
    this.width,
    this.height,
  );
}
''';
  }
}
