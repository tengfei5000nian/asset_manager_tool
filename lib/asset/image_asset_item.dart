import 'package:image/image.dart';

import '../lib.dart';
import '../options.dart';
import 'asset_item.dart';

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

  static String explainValue({
    required Lib lib,
    required SharedOptions options,
    required String content,
    required void Function(ImageAssetItem asset) callback
  }) {
    // 解析AssetItem参数
    final String reArg = '[\'"]{0,1}([^\\s\\;\'"]+)[\'"]{0,1}';
    // 解析AssetItem备注
    final String reMark = '[\\n\\s]*\\/\\*\\s*([^\\s]+)\\s+(Y|N)\\s*\\*\\/';
    // 解析AssetItem数据
    final String reAssetItem = '$reMark[\\n\\s]+static\\s+const\\s+String\\s+([\\w\\d]+)\\s*\\=\\s*$reArg\\s*;[\\n\\s]+static\\s+const\\s+int\\s+[\\w\\d]+\\\$width\\s*\\=\\s*$reArg\\s*;[\\n\\s]+static\\s+const\\s+int\\s+[\\w\\d]+\\\$height\\s*\\=\\s*$reArg\\s*;';
    return content.replaceAllMapped(RegExp(reAssetItem), (Match match) {
      final String hash = match.group(1)!;
      final String name = match.group(3)!;
      final String path = match.group(4)!;
      final int width = int.parse(match.group(5)!);
      final int height = int.parse(match.group(6)!);
      callback(
        ImageAssetItem(
          path: path,
          name: name,
          hash: hash,
          width: width,
          height: height,
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
    required void Function(ImageAssetItem asset) callback
  }) {
    // 解析AssetItem参数
    final String reArg = '[\\n\\s\'"]*([^\\s\\,\'"]+)[\\s\'"]*,?';
    // 解析AssetItem备注
    final String reMark = '[\\n\\s]*\\/\\*\\s*([^\\s]+)\\s*(Y|N)\\s*\\*\\/';
    // 解析AssetItem数据
    final String reAssetItem = '$reMark[\\n\\s]+static\\s+const\\s+$className\\s+([\\w\\d]+)\\s+\\=\\s+$className\\($reArg$reArg$reArg[\\n\\s]*\\);';
    return content.replaceAllMapped(RegExp(reAssetItem), (Match match) {
      final String hash = match.group(1)!;
      final String name = match.group(3)!;
      final String path = match.group(4)!;
      final int width = int.parse(match.group(5)!);
      final int height = int.parse(match.group(6)!);
      callback(
        ImageAssetItem(
          path: path,
          name: name,
          hash: hash,
          width: width,
          height: height,
          lib: lib,
          options: options,
        ),
      );
      return '';
    });
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

  @override
  String toValueString() => '''
${super.toValueString()}
static const int $name\$width = $width;
static const int $name\$height = $height;''';

  @override
  String toModelString() => '''
/* ${super.hash} ${isUse ? 'Y' : 'N'} */ static const $className $name = $className('${super.outPath}', $width, $height);''';
}
