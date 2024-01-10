import 'dart:io';

import 'package:yaml/yaml.dart';

import 'context.dart';
import 'options.dart';

// 将项目中yaml文件里的asset_manager_tool配置解析成SharedOptions参数集
SharedOptions? formatToolOptions(YamlMap? data) {
  if (data == null) return null;

  final config = data['asset_manager_tool'];
  if (config is! YamlMap) return null;

  return SharedOptions.formJSON(config.value);
}

// 读取flutter项目yaml文件里配置的所有asset文件路径
List<String>? formatAssetList(YamlMap? data) {
  if (data == null) return null;

  final List<String> list = [];

  final config = data['flutter'];
  if (config is! YamlMap) return null;

  final assets = config['assets'];
  if (assets is YamlList) list.addAll(List<String>.from(assets.value));

  final fonts = config['fonts'];
  if (fonts is YamlList) {
    for (final font in fonts) {
      if (font is! YamlMap) continue;

      final fontAssets = font['fonts'];
      if (fontAssets is! YamlList) continue;

      for (final fontAsset in fontAssets) {
        if (fontAsset is! YamlMap) continue;

        final asset = fontAsset['asset'];
        if (asset is String) list.add(asset);
      }
    }
  }

  return list.map((String path) {
    if (context.extension(path).isEmpty) {
      return context.join(path, '*.*');
    } else {
      return path;
    }
  }).toList();
}

// 读取yaml文件数据
YamlMap? getConfig(String? yamlFile) {
  if (yamlFile == null) return null;

  final File file = File(yamlFile);

  if (!file.existsSync()) {
    throw Exception('The config file `$yamlFile` was not found.');
  }

  final yamlMap = loadYaml(file.readAsStringSync());
  if (yamlMap is! YamlMap) return null;

  return yamlMap;
}
