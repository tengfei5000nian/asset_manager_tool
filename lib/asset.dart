import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart';

import 'logger.dart';
import 'options.dart';

class AssetItem {
  static const String className = 'AssetItem';
  static Future<AssetItem?> readFile(String path) async {
    final File file = File(path);
    if (await file.exists()) {
      final Uint8List content = await file.readAsBytes();
      final Digest digest = md5.convert(content);
      final List<String> names = split(rootPrefix(path).replaceAll(RegExp('[\\.\\_\\-\\s]+'), '/'));
      final String name = names.removeAt(0) + names.map((String name) => name
        .toLowerCase()
        .replaceRange(0, 1, name
          .substring(0, 1)
          .toUpperCase()
        )
      ).join();
      return AssetItem(
        path: path,
        name: name,
        hash: digest.toString(),
        content: content,
      );
    } else {
      return null;
    }
  }

  final String path;
  final String name;
  final String hash;
  final Uint8List? content;

  const AssetItem({
    required this.path,
    required this.name,
    required this.hash,
    this.content,
  });

  String dustbinPath(SharedOptions sharedOptions) => join(
    sharedOptions.dustbinUri.toString(),
    '$hash${extension(path)}'
  );

  Future<bool> assetExists() async => await File(path).exists();

  Future<bool> dustbinExists(SharedOptions sharedOptions) async => await File(dustbinPath(sharedOptions)).exists();

  Future<void> remove(SharedOptions sharedOptions, [bool useMemory = false]) async {
    if (!useMemory && await assetExists()) {
      await File(path).rename(dustbinPath(sharedOptions));
    } else if (content != null) {
      await File(dustbinPath(sharedOptions)).writeAsBytes(content!);
    } else {
      logger.warning('$className remove失败，asset和memory中不存在:$path');
    }
  }

  Future<void> resume(SharedOptions sharedOptions, [bool useMemory = false]) async {
    if (!useMemory && await dustbinExists(sharedOptions)) {
      await File(dustbinPath(sharedOptions)).rename(path);
    } else if (content != null) {
      await File(path).writeAsBytes(content!);
    } else {
      logger.warning('$className resume失败，dustbin和memory中不存在:$path');
    }
  }

  @override
  String toString() => '''
const $className $name = $className(
  $path,
  $hash,
);''';
}

class ImageAssetItem extends AssetItem {
  static const List<String> exts = ['png', 'jpg', 'jpeg', 'webp', 'gif'];
  static const String className = 'ImageAssetItem';
  static Future<AssetItem?> readFile(String path) async {
    final AssetItem? asset = await AssetItem.readFile(path);
    if (asset != null) {
      final Image? img = decodeImage(asset.content!);
      return img == null
        ? asset
        : ImageAssetItem(
          path: asset.path,
          name: asset.name,
          hash: asset.hash,
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
    super.content,
    required this.width,
    required this.height,
  });

  @override
  String toString() => '''
const $className $name = $className(
  ${super.path},
  ${super.hash},
  $width,
  $height,
);''';
}

class AssetList {
  static const String className = 'AssetList';
  static Future<AssetList?> readListFile(String path) async {
    final File file = File(path);
    if (await file.exists()) {
      final String content = await file.readAsString();
      return AssetList(
        path: path,
        content: content
      );
    } else {
      return null;
    }
  }
  static Future<AssetList?> readAssetDir(String listPath, List<String> assetPaths) async {
    if (await File(listPath).exists()) {
      final AssetList list = AssetList(path: listPath);
      return list;
    } else {
      return null;
    }
  }

  final String path;
  final Map<String, AssetItem> list = {};

  AssetList({
    required this.path,
    String? content,
  }) {
    if (content == null) return;

    final String reArg = '[\\n\\s]*([^\\s\\,]+)\\s*,?';
    final String reAssetItem = '[\\n\\s]+static\\s+const\\s+${AssetItem.className}\\s+([\\w\\d]+)\\s+\\=\\s+${AssetItem.className}\\($reArg$reArg[\\n\\s]+\\);';
    final String reImageAssetItem = '[\\n\\s]+static\\s+const\\s+${ImageAssetItem.className}\\s+([\\w\\d]+)\\s+\\=\\s+${ImageAssetItem.className}\\($reArg$reArg$reArg$reArg[\\n\\s]+\\);';
    final String reItem = '($reAssetItem|$reImageAssetItem)';
    final String reClass = 'abstract\\s+class\\s+$className\\s+\\{$reItem*[\\n\\s]+\\}';

    if (!RegExp(reClass).hasMatch(content)) return;

    content
      .replaceAllMapped(RegExp(reImageAssetItem), (Match match) {
        final String name = match.group(1)!;
        final String path = match.group(2)!;
        final String hash = match.group(3)!;
        final int width = int.parse(match.group(4)!);
        final int height = int.parse(match.group(5)!);
        list[path] = ImageAssetItem(
          path: path,
          name: name,
          hash: hash,
          width: width,
          height: height,
        );
        return '';
      })
      .replaceAllMapped(RegExp(reAssetItem), (Match match) {
        final String name = match.group(1)!;
        final String path = match.group(2)!;
        final String hash = match.group(3)!;
        list[path] = AssetItem(
          path: path,
          name: name,
          hash: hash,
        );
        return '';
      });
  }

  Future<void> add(
    String path, {
    bool nowWrite = true,
  }) async {
    final AssetItem? asset = ImageAssetItem.exts.contains(extension(path).substring(1))
      ? await ImageAssetItem.readFile(path)
      : await AssetItem.readFile(path);
    if (asset == null) {
      logger.warning('$className add失败，asset中不存在:$path');
    } else {
      list[path] = asset;
      if (nowWrite) await writeListFile();
    }
  }

  Future<void> remove(
    String path,
    SharedOptions sharedOptions, {
    bool useMemory = false,
    bool nowWrite = true,
  }) async {
    final AssetItem? asset = list.remove(path);
    if (asset == null) {
      logger.warning('$className remove失败，list中不存在:$path');
    } else {
      await asset.remove(sharedOptions, useMemory);
      if (nowWrite) await writeListFile();
    }
  }

  Future<void> resume(
    AssetItem asset,
    SharedOptions sharedOptions, {
    bool useMemory = false,
    bool nowWrite = true,
  }) async {
    await asset.resume(sharedOptions, useMemory);
    if (nowWrite) await writeListFile();
  }

  Future<void> writeListFile() async {
    await File(path).writeAsString(toString());
  }

  Future<void> checkListAsset() async {
    
  }

  @override
  String toString() => '''
abstract class $className {
${list.values.map((AssetItem item) => '  static $item'.replaceAll('\n', '\n  ')).join('\n\n')}
}

class ${AssetItem.className} {
  final String path;
  final String hash;

  const ${AssetItem.className}(
    this.path,
    this.hash,
  );
}

class ${ImageAssetItem.className} extends ${AssetItem.className} {
  final int width;
  final int height;

  const ${ImageAssetItem.className}(
    super.path,
    super.hash,
    this.width,
    this.height,
  );
}
''';
}
