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
  abbr: 'a',
  help: '监听的asset资产路径，优先使用flutter中的asset，其次使用配置文件或命令行输入',
  valueHelp: 'flutter[assets] or assets/',
  defaultsTo: 'assets/',
);
const Option dustbinPathOption = Option(
  name: 'dustbin-path',
  abbr: 'c',
  help: '删除的asset资产垃圾箱文件夹dustbin路径',
  defaultsTo: '.asset_dustbin/',
);
const Option listPathOption = Option(
  name: 'list-path',
  abbr: 'm',
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
  abbr: 'e',
  help: '排除的asset资产文件',
  defaultsTo: '**/asset_list.dart',
);

class SharedOptions {
  final List<String> assetPaths;
  final String dustbinPath;
  final String listPath;
  final List<String> excludePaths;

  SharedOptions({
    required this.assetPaths,
    required this.dustbinPath,
    required this.listPath,
    required this.excludePaths,
  });

  factory SharedOptions.defaults() {
    return SharedOptions(
      assetPaths: dustbinPathOption.defaultsTo.split(','),
      dustbinPath: dustbinPathOption.defaultsTo,
      listPath: listPathOption.defaultsTo,
      excludePaths: excludePathOption.defaultsTo.split(','),
    );
  }

  factory SharedOptions.form(Map? json) {
    return SharedOptions(
      assetPaths: json?[assetPathOption.name] is List
        ? List<String>.from(json![assetPathOption.name])
        : [],
      dustbinPath: (json?[dustbinPathOption.name] as String?) ?? '',
      listPath: (json?[listPathOption.name] as String?) ?? '',
      excludePaths: json?[excludePathOption.name] is List
        ? List<String>.from(json![excludePathOption.name])
        : []
    );
  }

  factory SharedOptions.create(ArgResults? argResults) {
    final YamlMap? yaml = getConfig(configPathOption.defaultsTo);
    final SharedOptions? yamlOptions = formatToolOptions(yaml);

    final List<String>? flutterAssets = formatAssetList(yaml);

    final SharedOptions? toolOptions = formatToolOptions(
      getConfig(argResults?[configPathOption.name] as String?)
    );

    final SharedOptions defaultOptions = SharedOptions.defaults();

    return SharedOptions(
      assetPaths: flutterAssets?.isNotEmpty ?? false
        ? flutterAssets!
        : (
          yamlOptions?.assetPaths.isNotEmpty ?? false
            ? yamlOptions!.assetPaths
            : (
              toolOptions?.assetPaths.isNotEmpty ?? false
                ? toolOptions!.assetPaths
                : defaultOptions.assetPaths
            )
        ),
      dustbinPath: yamlOptions?.dustbinPath.isNotEmpty ?? false
        ? yamlOptions!.dustbinPath
        : (
          toolOptions?.dustbinPath.isNotEmpty ?? false
            ? toolOptions!.dustbinPath
            : defaultOptions.dustbinPath
        ),
      listPath: yamlOptions?.listPath.isNotEmpty ?? false
        ? yamlOptions!.listPath
        : (
          toolOptions?.listPath.isNotEmpty ?? false
            ? toolOptions!.listPath
            : defaultOptions.listPath
        ),
      excludePaths: yamlOptions?.excludePaths.isNotEmpty ?? false
        ? yamlOptions!.excludePaths
        : (
          toolOptions?.excludePaths.isNotEmpty ?? false
            ? toolOptions!.excludePaths
            : defaultOptions.excludePaths
        ),
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
    
    return data.toString();
  }
}
