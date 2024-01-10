// 表示一个asset资产的基本数据类
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../context.dart';
import '../lib.dart';
import '../logger.dart';
import '../options.dart';
import 'asset_list.dart';

class AssetItem {
  // 生成list资产清单时资产的类名
  static const String className = 'AssetItem';

  // 通过文件地址path创建一个AssetItem资产项
  static Future<AssetItem?> readFile(String path, Lib lib, SharedOptions options) async {
    final File file = File(path);
    if (await file.exists()) {
      final List<String> names = context.split(path.replaceFirst(context.rootPrefix(path), '').replaceAll(RegExp('[\\.\\_\\-\\s]+'), '/'));
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

      final Digest digest = md5.convert(path.codeUnits);
      final asset = AssetItem(
        path: path,
        name: name,
        hash: digest.toString().substring(0, 16),
        lib: lib,
        options: options,
      );

      await asset.updateConttent();

      return asset;
    } else {
      return null;
    }
  }

  static String explainValue({
    required Lib lib,
    required SharedOptions options,
    required String content,
    required void Function(AssetItem asset) callback
  }) {
    // 解析AssetItem参数
    final String reArg = '[\'"]{0,1}([^\\s\\;\'"]+)[\'"]{0,1}';
    // 解析AssetItem备注
    final String reMark = '[\\n\\s]*\\/\\*\\s*([^\\s]+)\\s+(Y|N)\\s*\\*\\/';
    // 解析AssetItem数据
    final String reAssetItem = '$reMark[\\n\\s]+static\\s+const\\s+String\\s+([\\w\\d]+)\\s*\\=\\s*$reArg\\s*;';
    return content.replaceAllMapped(RegExp(reAssetItem), (Match match) {
      final String hash = match.group(1)!;
      final String name = match.group(3)!;
      final String path = match.group(4)!;
      callback(
        AssetItem(
          path: path,
          name: name,
          hash: hash,
          lib: lib,
          options: options,
        ),
      );
      return '';
    });
  }

  static String explainModel({
    required Lib lib,
    required SharedOptions options,
    required String content,
    required void Function(AssetItem asset) callback
  }) {
    // 解析AssetItem参数
    final String reArg = '[\\n\\s\'"]*([^\\s\\,\'"]+)[\\s\'"]*,?';
    // 解析AssetItem备注
    final String reMark = '[\\n\\s]*\\/\\*\\s*([^\\s]+)\\s+(Y|N)\\s*\\*\\/';
    // 解析AssetItem数据
    final String reAssetItem = '$reMark[\\n\\s]+static\\s+const\\s+$className\\s+([\\w\\d]+)\\s+\\=\\s+$className\\($reArg[\\n\\s]*\\);';
    return content.replaceAllMapped(RegExp(reAssetItem), (Match match) {
      final String hash = match.group(1)!;
      final String name = match.group(3)!;
      final String path = match.group(4)!;
      callback(
        AssetItem(
          path: path,
          name: name,
          hash: hash,
          lib: lib,
          options: options,
        ),
      );
      return '';
    });
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
  String get dustbinPath => context.join(
    options.dustbinPath,
    '$hash${context.extension(path)}'
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

    final bool exists = await assetExists;

    if (exists && !useMemory) {
      await File(path).rename(dustbinPath);
      logger.info('remove $path to $dustbinPath');
      return true;
    } else if (exists && useMemory && content != null) {
      await Future.wait([
        File(path).delete(),
        File(dustbinPath).writeAsBytes(content!),
      ]);
      logger.info('remove $path to $dustbinPath');
      return true;
    } else if (content != null) {
      await File(dustbinPath).writeAsBytes(content!);
      logger.info('remove $path to $dustbinPath');
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
    await checkOrCreateDustbin;

    final bool exists = await dustbinExists;

    if (exists && !useMemory) {
      await File(dustbinPath).rename(path);
      logger.info('resume $path from $dustbinPath');
      return true;
    } else if (exists && useMemory && content != null) {
      await Future.wait([
        File(dustbinPath).delete(),
        File(path).writeAsBytes(content!),
      ]);
      logger.info('resume $path from $dustbinPath');
      return true;
    } else if (content != null) {
      await File(path).writeAsBytes(content!);
      logger.info('resume $path from $dustbinPath');
      return true;
    } else if (isFailTip) {
      logger.warning(className, 'resume失败，dustbin和memory中不存在$path', StackTrace.current);
    }
    return false;
  }

  // 从asset资产所在原始路径或回收文件夹更新当前asset资产的文件数据
  Future<void> updateConttent() async {
    late File file = File(path);

    if (await file.exists()) {
      content = await file.readAsBytes();
    } else {
      file = File(dustbinPath);

      if (await file.exists()) {
        content = await file.readAsBytes();
      } else {
        logger.warning(className, 'updateConttent失败，path和dustbinPath中不存在$path', StackTrace.current);
      }
    }
  }

  String toValueString() => '''
/* $hash ${isUse ? 'Y' : 'N'} */
static const String $name = '$path';''';

  String toModelString() => '''
/* $hash ${isUse ? 'Y' : 'N'} */ static const $className $name = $className('$path');''';
}
