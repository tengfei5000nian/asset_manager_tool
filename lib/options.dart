import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';

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

const Option libPathOption = Option(
  name: 'lib-path',
  help: '监听的lib路径',
  defaultsTo: 'lib/**.dart',
);
const Option assetPathOption = Option(
  name: 'asset-path',
  help: '监听的asset资产路径',
  defaultsTo: 'lib/assets/*.*',
);
const Option dustbinPathOption = Option(
  name: 'dustbin-path',
  help: '删除的asset资产保存的垃圾箱文件夹dustbin路径',
  defaultsTo: '.asset_dustbin/',
);
const Option listPathOption = Option(
  name: 'list-path',
  help: '通过asset资产创建的清单list',
  defaultsTo: 'lib/asset_list.dart',
);
const Option configPathOption = Option(
  name: 'config-path',
  help: 'config文件路径',
  defaultsTo: 'pubspec.yaml',
);
const Option nameReplaceOption = Option(
  name: 'name-replace',
  help: 'asset资产实例名替换',
  defaultsTo: 'libAssets:',
);
const Option excludePathOption = Option(
  name: 'exclude-path',
  help: '排除监听的文件，可以包含lib-path、asset-path的路径',
  defaultsTo: '.*,.*/**.*,**/.*,**/.*/**.*',
);
const Option formatTypeOption = Option(
  name: 'format-type',
  help: 'asset_list.dart格式类型',
  defaultsTo: 'value',
);

enum FormatType { value, model }

// 执行命令需要携带的参数集
class SharedOptions {
  final List<String> libPaths;
  final List<String> assetPaths;
  final String dustbinPath;
  final String listPath;
  final String configPath;
  final Map<String, String?> nameReplaces;
  final List<String> excludePaths;
  final FormatType? formatType;

  SharedOptions({
    required this.libPaths,
    required this.assetPaths,
    required this.dustbinPath,
    required this.listPath,
    required this.configPath,
    required this.nameReplaces,
    required this.excludePaths,
    required this.formatType,
  });

  // 创建一个default参数的SharedOptions
  factory SharedOptions.defaults() {
    return SharedOptions(
      libPaths: libPathOption.defaultsTo.split(','),
      assetPaths: assetPathOption.defaultsTo.split(','),
      dustbinPath: dustbinPathOption.defaultsTo,
      listPath: listPathOption.defaultsTo,
      configPath: configPathOption.defaultsTo,
      nameReplaces: nameReplaceOption.defaultsTo.split(',').fold({}, (Map<String, String?> data, String item) {
        final List<String> value = item.split(':');
        data[value.first] = value.length >= 2 ? value[1] : null;
        return data;
      }),
      excludePaths: excludePathOption.defaultsTo.split(','),
      formatType: FormatType.values.firstWhere((FormatType type) => type.toString().contains(formatTypeOption.defaultsTo))
    );
  }

  // 创建一个参数从yaml文件获取的SharedOptions
  factory SharedOptions.formJSON(Map? json) {
    return SharedOptions(
      libPaths: json?[libPathOption.name] is List
        ? List<String>.from(json![libPathOption.name])
        : [],
      assetPaths: json?[assetPathOption.name] is List
        ? List<String>.from(json![assetPathOption.name])
        : [],
      dustbinPath: (json?[dustbinPathOption.name] as String?) ?? '',
      listPath: (json?[listPathOption.name] as String?) ?? '',
      configPath: (json?[configPathOption.name] as String?) ?? '',
      nameReplaces: json?[nameReplaceOption.name] is Map
        ? Map<String, String?>.from(json![nameReplaceOption.name])
        : {},
      excludePaths: json?[excludePathOption.name] is List
        ? List<String>.from(json![excludePathOption.name])
        : [],
      formatType: json?[formatTypeOption.name] is String
        ? FormatType.values.firstWhere((FormatType type) => type.toString().contains(json![formatTypeOption.name]))
        : null,
    );
  }

  // 创建一个参数从命令行获取的SharedOptions
  factory SharedOptions.formARG(ArgResults? argResults) {
    return SharedOptions(
      libPaths: argResults?[libPathOption.name] is List
        ? List<String>.from(argResults![libPathOption.name])
        : [],
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
      nameReplaces: argResults?[nameReplaceOption.name] is Map
        ? Map<String, String?>.from(argResults![nameReplaceOption.name])
        : {},
      excludePaths: argResults?[excludePathOption.name] is List
        ? List<String>.from(argResults![excludePathOption.name])
        : [],
        formatType: argResults?[formatTypeOption.name] is String
        ? FormatType.values.firstWhere((FormatType type) => type.toString().contains(argResults![formatTypeOption.name]))
        : null,
    );
  }

  // 创建一个参数优先级按命令行、asset_manager_tool.yaml、pubspec.yaml、flutter配置、default获取的SharedOptions
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
      libPaths: argOptions.libPaths.isNotEmpty
        ? argOptions.libPaths
        : toolOptions?.libPaths.isNotEmpty ?? false
          ? toolOptions!.libPaths
          : yamlOptions?.libPaths.isNotEmpty ?? false
            ? yamlOptions!.libPaths
            : defaultOptions.libPaths,
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
      nameReplaces: argOptions.nameReplaces.isNotEmpty
        ? argOptions.nameReplaces
        : toolOptions?.nameReplaces.isNotEmpty ?? false
          ? toolOptions!.nameReplaces
          : yamlOptions?.nameReplaces.isNotEmpty ?? false
            ? yamlOptions!.nameReplaces
            : defaultOptions.nameReplaces,
      excludePaths: argOptions.excludePaths.isNotEmpty
        ? argOptions.excludePaths
        : toolOptions?.excludePaths.isNotEmpty ?? false
          ? toolOptions!.excludePaths
          : yamlOptions?.excludePaths.isNotEmpty ?? false
            ? yamlOptions!.excludePaths
            : defaultOptions.excludePaths,
      formatType: argOptions.formatType != null
        ? argOptions.formatType!
        : toolOptions?.formatType != null
          ? toolOptions!.formatType
          : yamlOptions?.formatType != null
            ? yamlOptions!.formatType
            : defaultOptions.formatType!,
    );
  }

  // 是否是清单list文件地址
  bool isListPath(String path) {
    return equals(listPath, path);
  }

  // 地址是否符合asset资产路径
  bool isAssetPath(String path) {
    return assetPaths.any((String p) => !isExcludePath(path) && Glob(p).matches(path));
  }

  // 地址是否符合lib匹配规则
  bool isLibPath(String path) {
    return libPaths.any((String p) => !isExcludePath(path) && Glob(p).matches(path));
  }

  // 地址是否符合exclude匹配规则
  bool isExcludePath(String path) {
    return excludePaths.any((String p) => isListPath(path) || Glob(p).matches(path));
  }

  // 获取符合lib匹配规则的所有文件地址
  Future<List<String>> get findLibPaths async {
    final List<String> libPaths = [];

    await Future.wait(
      this.libPaths.map((String path) async {
        final Glob glob = Glob(path);
        await for (final FileSystemEntity entity in glob.list()) {
          if (!isExcludePath(entity.path)) libPaths.add(relative(entity.path, from: current));
        }
      })
    );

    return libPaths;
  }

  // 获取符合asset匹配规则的所有文件地址
  Future<List<String>> get findAssetPaths async {
    final List<String> assetPaths = [];

    await Future.wait(
      this.assetPaths.map((String path) async {
        final Glob glob = Glob(path);
        await for (final FileSystemEntity entity in glob.list()) {
          if (!isExcludePath(entity.path)) assetPaths.add(relative(entity.path, from: current));
        }
      })
    );

    return assetPaths;
  }

  @override
  String toString() {
    return '''

--------- Config Data ---------
lib-path: ${libPaths.join(', ')}
asset-path: ${assetPaths.join(', ')}
dustbin-path: $dustbinPath
list-path: $listPath
config-path: $configPath
name-replace: ${nameReplaces.keys.map((String key) => '$key:${nameReplaces[key]}').join(',')}
exclude-path: ${excludePaths.join(', ')}
format-type: ${formatType.toString().split('.').last}
-------------------------------''';
  }
}
