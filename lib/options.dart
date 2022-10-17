import 'package:args/args.dart';

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
const Option includeExtOption = Option(
  name: 'include-ext',
  abbr: 'i',
  help: '跟踪的asset资产文件扩展名',
  defaultsTo: 'png,jpg,jpeg,webp,gif,ttf,txt,json',
);

class SharedOptions {
  final List<Uri> assetUri;
  final Uri dustbinUri;
  final Uri listUri;
  final List<String> includeExt;

  SharedOptions({
    required this.assetUri,
    required this.dustbinUri,
    required this.listUri,
    required this.includeExt,
  });

  factory SharedOptions.create(ArgResults? argResults) {
    final Map<String, dynamic>? flutter = getConfig(configPathOption.defaultsTo);
    final Map<String, dynamic>? config = getConfig((argResults?[configPathOption.name] as String?) ?? configPathOption.defaultsTo);
    return SharedOptions(
      assetUri: (
        (flutter?['assets'] as List<String>?) ?? (
          (argResults?[assetPathOption.name] as List<String>?)?.isNotEmpty ?? false
          ? (argResults?[assetPathOption.name] as List<String>)
          : [(config?[assetPathOption.name] as String?) ?? assetPathOption.defaultsTo]
        )
      ).map(Uri.parse).toList(),
      dustbinUri: Uri.parse((argResults?[dustbinPathOption.name] as String?) ?? (config?[dustbinPathOption.name] as String?) ?? dustbinPathOption.defaultsTo),
      listUri: Uri.parse((argResults?[listPathOption.name] as String?) ?? (config?[listPathOption.name] as String?) ?? listPathOption.defaultsTo),
      includeExt: (argResults?[includeExtOption.name] as List<String>?)?.isNotEmpty ?? false
        ? (argResults?[includeExtOption.name] as List<String>)
        : ((config?[includeExtOption.name] as String?) ?? includeExtOption.defaultsTo).split(','),
    );
  }

  @override
  String toString() {
    final Map<String, String> data = {};

    data['assetUri'] = assetUri.map((Uri uri) => uri.toString()).join(',');
    data['dustbinUri'] = dustbinUri.toString();
    data['listUri'] = listUri.toString();
    data['includeExt'] = includeExt.join(',');
    
    return data.toString();
  }
}
