import 'dart:io';

import 'options.dart';

// 符合lib匹配规则的文件数据缓存类
class Lib {
  final SharedOptions options;
  final Map<String, String> list = {};

  Lib(this.options);

  // 缓存所有符合lib匹配规则的文件数据
  Future<void> init() async {
    final List<String> paths = await options.findLibPaths;
    await Future.wait(
      paths.map(add)
    );
  }

  // 缓存地址为path的文件数据
  Future<void> add(String path) async {
    final File file = File(path);
    if (!await file.exists()) return;

    final String content = await file.readAsString();
    list[path] = content;
  }

  // 删除地址为path的文件数据缓存
  Future<void> remove(String path) async {
    list.remove(path);
  }

  // 判断符合lib匹配规则的文件数据中是否包含有text字符串
  bool test(String text) {
    return list.values.any((String content) {
      return content.contains(text);
    });
  }
}