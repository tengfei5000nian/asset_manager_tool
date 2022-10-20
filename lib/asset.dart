import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart';

import 'lib.dart';
import 'logger.dart';
import 'options.dart';

class AssetItem {
  static const String className = 'AssetItem';
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

  final String path;
  final String name;
  final String hash;
  final Lib lib;
  final SharedOptions options;

  Uint8List? content;

  AssetItem({
    required this.path,
    required this.name,
    required this.hash,
    required this.lib,
    required this.options,
    this.content,
  });

  String get dustbinPath => join(
    options.dustbinPath,
    '$hash${extension(path)}'
  );

  bool get isUse => lib.test('${AssetList.className}.$name');

  Future<bool> get assetExists async => await File(path).exists();

  Future<bool> get dustbinExists async => await File(dustbinPath).exists();

  Future<void> get checkOrCreateDustbin async {
    final Directory dir = Directory(options.dustbinPath);
    if (await dir.exists()) return;
    await dir.create(recursive: true);
  }

  Future<void> remove({
    bool useMemory = false,
    bool isFailTip = true,
  }) async {
    await checkOrCreateDustbin;

    if (await assetExists) {
      if (useMemory) {
        if (content != null) await File(dustbinPath).writeAsBytes(content!);
        await File(path).delete();
      } else {
        await File(path).rename(dustbinPath);
      }
    } else if (content != null) {
      await File(dustbinPath).writeAsBytes(content!);
    } else if (isFailTip) {
      logger.warning(className, 'remove失败，asset和memory中不存在$path');
    }
  }

  Future<void> resume({
    bool useMemory = false,
    bool isFailTip = true,
  }) async {
    if (await dustbinExists) {
      if (useMemory) {
        if (content != null) await File(path).writeAsBytes(content!);
        await File(dustbinPath).delete();
      } else {
        await File(dustbinPath).rename(path);
      }
    } else if (content != null) {
      await File(path).writeAsBytes(content!);
    } else if (isFailTip) {
      logger.warning(className, 'resume失败，dustbin和memory中不存在$path');
    }
  }

  @override
  String toString() => '''
/* $hash ${isUse ? 'Y' : 'N'} */ static const $className $name = $className('$path');''';
}

class ImageAssetItem extends AssetItem {
  static const List<String> exts = ['png', 'jpg', 'jpeg', 'webp', 'gif'];
  static const String className = 'ImageAssetItem';
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

  final int width;
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

  @override
  String toString() => '''
/* ${super.hash} ${isUse ? 'Y' : 'N'} */ static const $className $name = $className('${super.path}', $width, $height);''';
}

class AssetList {
  static const String className = 'AssetList';
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
  static Future<AssetList?> readAssetDir(Lib lib, SharedOptions options) async {
    if (options.assetPaths.isEmpty) return null;

    final AssetList list = AssetList(
      lib: lib,
      options: options,
    );

    final List<String> paths = await options.findAssetPaths;
    for (final String path in paths) {
      await list.add(path, nowWrite: false);
    }

    return list;
  }

  final Lib lib;
  final SharedOptions options;
  final Map<String, AssetItem> list = {};

  AssetList({
    required this.lib,
    required this.options,
    String? content,
  }) {
    if (content == null) return;

    final String reArg = '[\\n\\s\'"]*([^\\s\\,\'"]+)[\\s\'"]*,?';
    final String reMark = '[\\n\\s]*\\/\\*\\s*([^\\s]+)\\s*(Y|N)\\s*\\*\\/';
    final String reAssetItem = '$reMark[\\n\\s]+static\\s+const\\s+${AssetItem.className}\\s+([\\w\\d]+)\\s+\\=\\s+${AssetItem.className}\\($reArg[\\n\\s]*\\);';
    final String reImageAssetItem = '$reMark[\\n\\s]+static\\s+const\\s+${ImageAssetItem.className}\\s+([\\w\\d]+)\\s+\\=\\s+${ImageAssetItem.className}\\($reArg$reArg$reArg[\\n\\s]*\\);';
    final String reItem = '($reAssetItem|$reImageAssetItem)';
    final String reClass = 'abstract\\s+class\\s+$className\\s+\\{$reItem*[\\n\\s]*\\}';

    if (!RegExp(reClass).hasMatch(content)) return;

    content
      .replaceAllMapped(RegExp(reImageAssetItem), (Match match) {
        final String hash = match.group(1)!;
        final String name = match.group(3)!;
        final String path = match.group(4)!;
        final int width = int.parse(match.group(5)!);
        final int height = int.parse(match.group(6)!);
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
      })
      .replaceAllMapped(RegExp(reAssetItem), (Match match) {
        final String hash = match.group(1)!;
        final String name = match.group(3)!;
        final String path = match.group(4)!;
        list[path] = AssetItem(
          path: path,
          name: name,
          hash: hash,
          lib: lib,
          options: options,
        );
        return '';
      });
  }

  List<AssetItem> get assets {
    final List<AssetItem> data = list.values.toList();
    data.sort((a, b) => a.name.compareTo(b.name));
    return data;
  }

  Future<void> add(
    String path, {
    bool nowWrite = true,
    bool isFailTip = true,
  }) async {
    final AssetItem? asset = ImageAssetItem.exts.contains(extension(path).substring(1))
      ? await ImageAssetItem.readFile(path, lib, options)
      : await AssetItem.readFile(path, lib, options);
    if (asset == null) {
      if (isFailTip) logger.warning(className, 'add失败，asset中不存在$path');
    } else {
      list[path] = asset;
      if (await asset.dustbinExists) await File(asset.dustbinPath).delete();
      if (nowWrite) await writeListFile();
    }
  }

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

  Future<void> resume(
    AssetItem asset, {
    bool useMemory = false,
    bool nowWrite = true,
    bool isFailTip = true,
  }) async {
    await asset.resume(
      useMemory: useMemory,
      isFailTip: isFailTip,
    );
    if (nowWrite) await writeListFile();
  }

  AssetItem? get(AssetItem asset) {
    final AssetItem? item = list[asset.path];
    if (item?.hash == asset.hash) {
      return item;
    } else {
      return null;
    }
  }

  Future<void> writeListFile() async {
    final File file = File(options.listPath);
    final String content = toString();

    if (await file.exists() && await file.readAsString() == content) return;

    await file.writeAsString(content);
  }

  Future<void> checkAsset() async {
    final AssetList? assetList = await AssetList.readAssetDir(lib, options);
    if (assetList == null) {
      logger.warning(className, 'checkAsset失败，assetPaths不存在${options.assetPaths}');
    } else {
      for (final AssetItem item in list.values) {
        final AssetItem? asset = assetList.get(item);
        if (asset == null) {
          await item.resume();
        } else {
          item.content = asset.content;
        }
        assetList.list.remove(item.path);
      }

      for (final AssetItem item in assetList.list.values) {
        await item.remove();
      }
    }
  }

  @override
  String toString() => '''
abstract class $className {
${assets.map((AssetItem item) => '  $item'.replaceAll('\n', '\n  ')).join('\n')}
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
}
