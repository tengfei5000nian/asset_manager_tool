import 'dart:io';

import 'options.dart';

class Lib {
  final SharedOptions options;
  final Map<String, String> list = {};

  Lib(this.options);

  Future<void> init() async {
    final List<String> paths = await options.findLibPaths;
    await Future.wait(
      paths.map(add)
    );
  }

  Future<void> add(String path) async {
    final File file = File(path);
    if (!await file.exists()) return;

    final String content = await file.readAsString();
    list[path] = content;
  }

  Future<void> remove(String path) async {
    list.remove(path);
  }

  bool test(String text) {
    return list.values.any((String content) {
      return content.contains(text);
    });
  }
}