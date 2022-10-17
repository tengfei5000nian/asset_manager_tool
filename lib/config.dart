import 'dart:io';

import 'package:yaml/yaml.dart';

Map<String, dynamic>? getConfig(String configFile, [String key = 'asset_manager_tool']) {
  if (!File(configFile).existsSync()) {
    throw Exception('The config file `$configFile` was not found.');
  }

  final Map yamlMap = loadYaml(File(configFile).readAsStringSync()) as Map;

  if (yamlMap[key] is! Map) {
    return null;
  }

  return _yamlToMap(yamlMap[key] as YamlMap);
}

Map<String, dynamic> _yamlToMap(YamlMap yamlMap) {
  final Map<String, dynamic> map = <String, dynamic>{};
  for (final MapEntry<dynamic, dynamic> entry in yamlMap.entries) {
    if (entry.value is YamlList) {
      final list = <String>[];
      for (final value in entry.value as YamlList) {
        if (value is String) {
          list.add(value);
        }
      }
      map[entry.key as String] = list;
    } else if (entry.value is YamlMap) {
      map[entry.key as String] = _yamlToMap(entry.value as YamlMap);
    } else {
      map[entry.key as String] = entry.value;
    }
  }
  return map;
}
