import 'dart:io';

import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

import 'options.dart';

SharedOptions? formatToolOptions(YamlMap? data) {
  if (data == null) return null;

  final config = data['asset_manager_tool'];
  if (config is! YamlMap) return null;

  return SharedOptions.formJSON(config.value);
}

List<String>? formatAssetList(YamlMap? data) {
  if (data == null) return null;

  final List<String> list = [];

  final config = data['flutter'];
  if (config is! YamlMap) return null;

  final assets = config['assets'];
  if (assets is YamlList) list.addAll(List<String>.from(assets.value));

  final fonts = config['fonts'];
  if (fonts is! YamlList) return list;

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

  return list.map((String path) {
    if (extension(path).isEmpty) {
      return join(path, '*.*');
    } else {
      return path;
    }
  }).toList();
}

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
