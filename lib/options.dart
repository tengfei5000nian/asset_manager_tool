import 'package:args/args.dart';
import 'package:glob/glob.dart';
import 'package:yaml/yaml.dart';

import 'config.dart';

class Option {
  final String name;
  final String? abbr;
  final String help;
  final String? valueHelp;
  final String defaultsTo;

  const Option({
    required this.name,
    this.abbr,
    required this.help,
    this.valueHelp,
    required this.defaultsTo,
  });
}

const Option assetPathOption = Option(
  name: 'asset-path',
  help: '监听的asset资产路径',
  defaultsTo: 'assets/',
);
const Option dustbinPathOption = Option(
  name: 'dustbin-path',
  help: '删除的asset资产垃圾箱文件夹dustbin路径',
  defaultsTo: '.asset_dustbin/',
);
const Option listPathOption = Option(
  name: 'list-path',
  help: '通过asset资产创建的清单list',
  defaultsTo: 'asset_list.dart',
);
const Option configPathOption = Option(
  name: 'config-path',
  help: 'config文件路径',
  defaultsTo: 'pubspec.yaml',
);
const Option excludePathOption = Option(
  name: 'exclude-path',
  help: '排除的asset资产文件',
  defaultsTo: '**/asset_list.dart',
);
const Option nameReplaceOption = Option(
  name: 'name-replace',
  help: 'asset资产实例名替换',
  defaultsTo: 'assets:',
);

class SharedOptions {
  final List<String> assetPaths;
  final String dustbinPath;
  final String listPath;
  final String configPath;
  final List<String> excludePaths;
  final Map<String, String?> nameReplaces;

  SharedOptions({
    required this.assetPaths,
    required this.dustbinPath,
    required this.listPath,
    required this.configPath,
    required this.excludePaths,
    required this.nameReplaces,
  });

  factory SharedOptions.defaults() {
    return SharedOptions(
      assetPaths: assetPathOption.defaultsTo.split(','),
      dustbinPath: dustbinPathOption.defaultsTo,
      listPath: listPathOption.defaultsTo,
      configPath: configPathOption.defaultsTo,
      excludePaths: excludePathOption.defaultsTo.split(','),
      nameReplaces: nameReplaceOption.defaultsTo.split(',').fold({}, (Map<String, String?> data, String item) {
        final List<String> value = item.split(':');
        data[value.first] = value.length >= 2 ? value[1] : null;
        return data;
      }),
    );
  }

  factory SharedOptions.formJSON(Map? json) {
    return SharedOptions(
      assetPaths: json?[assetPathOption.name] is List
        ? List<String>.from(json![assetPathOption.name])
        : [],
      dustbinPath: (json?[dustbinPathOption.name] as String?) ?? '',
      listPath: (json?[listPathOption.name] as String?) ?? '',
      configPath: (json?[configPathOption.name] as String?) ?? '',
      excludePaths: json?[excludePathOption.name] is List
        ? List<String>.from(json![excludePathOption.name])
        : [],
      nameReplaces: json?[nameReplaceOption.name] is Map
        ? Map<String, String?>.from(json![nameReplaceOption.name])
        : {},
    );
  }

  factory SharedOptions.formARG(ArgResults? argResults) {
    return SharedOptions(
      assetPaths: argResults?[assetPathOption.name] is List
        ? List<String>.from(argResults![assetPathOption.name])
        : [],
      dustbinPath: argResults?[dustbinPathOption.name] is String
        ? argResults![dustbinPathOption.name]
        : '',
      listPath: argResults?[listPathOption.name] is String
        ? argResults![listPathOption.name]
        : '',
      configPath: argResults?[configPathOption.name] is String
        ? argResults![configPathOption.name]
        : '',
      excludePaths: argResults?[excludePathOption.name] is List
        ? List<String>.from(argResults![excludePathOption.name])
        : [],
      nameReplaces: argResults?[nameReplaceOption.name] is Map
        ? Map<String, String?>.from(argResults![nameReplaceOption.name])
        : {},
    );
  }

  factory SharedOptions.create(ArgResults? argResults) {
    final SharedOptions defaultOptions = SharedOptions.defaults();

    final YamlMap? yaml = getConfig(configPathOption.defaultsTo);
    final SharedOptions? yamlOptions = formatToolOptions(yaml);
    final List<String>? flutterAssets = formatAssetList(yaml);

    final SharedOptions argOptions = SharedOptions.formARG(argResults);

    final SharedOptions? toolOptions = formatToolOptions(
      getConfig(
        argOptions.configPath.isNotEmpty
          ? argOptions.configPath
          : (
            yamlOptions?.configPath.isNotEmpty ?? false
              ? yamlOptions!.configPath
              : defaultOptions.configPath
          )
      )
    );

    return SharedOptions(
      assetPaths: argOptions.assetPaths.isNotEmpty
        ? argOptions.assetPaths
        : toolOptions?.assetPaths.isNotEmpty ?? false
          ? toolOptions!.assetPaths
          : yamlOptions?.assetPaths.isNotEmpty ?? false
            ? yamlOptions!.assetPaths
            : flutterAssets?.isNotEmpty ?? false
              ? flutterAssets!
              : defaultOptions.assetPaths,
      dustbinPath: argOptions.dustbinPath.isNotEmpty
        ? argOptions.dustbinPath
        : toolOptions?.dustbinPath.isNotEmpty ?? false
          ? toolOptions!.dustbinPath
          : yamlOptions?.dustbinPath.isNotEmpty ?? false
            ? yamlOptions!.dustbinPath
            : defaultOptions.dustbinPath,
      listPath: argOptions.listPath.isNotEmpty
        ? argOptions.listPath
        : toolOptions?.listPath.isNotEmpty ?? false
          ? toolOptions!.listPath
          : yamlOptions?.listPath.isNotEmpty ?? false
            ? yamlOptions!.listPath
            : defaultOptions.listPath,
      configPath: argOptions.configPath.isNotEmpty
        ? argOptions.configPath
        : toolOptions?.configPath.isNotEmpty ?? false
          ? toolOptions!.configPath
          : yamlOptions?.configPath.isNotEmpty ?? false
            ? yamlOptions!.configPath
            : defaultOptions.configPath,
      excludePaths: argOptions.excludePaths.isNotEmpty
        ? argOptions.excludePaths
        : toolOptions?.excludePaths.isNotEmpty ?? false
          ? toolOptions!.excludePaths
          : yamlOptions?.excludePaths.isNotEmpty ?? false
            ? yamlOptions!.excludePaths
            : defaultOptions.excludePaths,
      nameReplaces: argOptions.nameReplaces.isNotEmpty
        ? argOptions.nameReplaces
        : toolOptions?.nameReplaces.isNotEmpty ?? false
          ? toolOptions!.nameReplaces
          : yamlOptions?.nameReplaces.isNotEmpty ?? false
            ? yamlOptions!.nameReplaces
            : defaultOptions.nameReplaces,
    );
  }

  bool isExcludePath(String path) {
    return excludePaths.every((String p) => Glob(p).matches(path));
  }

  @override
  String toString() {
    final Map<String, String> data = {};

    data['assetPaths'] = assetPaths.join(',');
    data['dustbinPath'] = dustbinPath;
    data['listPath'] = listPath;
    data['excludePaths'] = excludePaths.join(',');
    data['nameReplaces'] = nameReplaces.keys.map((String key) {
      return '$key:${nameReplaces[key]}';
    }).join(',');
    
    return data.toString();
  }
}
