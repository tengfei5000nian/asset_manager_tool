在开发时你可能因为需求的不断修改需要反复的修改、删除、添加一些资产文件。在这个过程中可能遗留一些已经不需要的资产文件，但经过一段时间后你很难判断这些资产文件是否真的可以删除，可能在你不注意的角落仍然有功能需要它们。这个时候我们可能需要一个资产管理器能够去管理这些文件，并给出一点提示，让我们可以更好的判断资产文件是否在项目中使用到。

* [安装](#安装)
* [使用](#使用)
  * [内置命令](#内置命令)
  * [命令参数](#命令参数)
    * [在终端中设置参数](#在终端中设置参数示例优先级第一位)
    * [在asset_manager_tool.yaml中设置参数](#在asset_manager_toolyaml中设置参数示例优先级第二位)
    * [在pubspec.yaml中设置参数](#在pubspecyaml中设置参数示例优先级第三位)
  * [项目中使用](#项目中使用)
  * [资产管理和使用提示](#资产管理和使用提示)

## 安装

这个包的目的是帮助我们管理资产文件，并给出提示资产文件是否在项目中使用到。在一般情况下，把它放在[dev_dependencies][]下，在你的[`pubspec.yaml`][pubspec]中。

```yaml
dev_dependencies:
  asset_manager_tool:
```

## 使用

### 内置命令

asset_manager_tool包暴露了一个binary文件，它可以使用`dart run asset_manager_tool <command>`执行命令。

可用的命令有watch，build:asset，build:list，clean。

> 注意: 安装后第一次运行命令应该是watch或build:asset以生成资产清单文件，默认它是`asset_list.dart`。

- `watch`: 以asset资源为起点创建清单list数据，然后监听asset和清单list的修改重建list或删除asset。
- `build:asset`: 以asset资源为起点创建清单list数据。
- `build:list`: 以清单list数据为起点删除或恢复asset资源。
- `clean`: 以清单list数据为起点清除未使用的asset资源。

### 命令参数

- `--help`: 打印帮助信息。
- `--lib-path`: `['lib/**.dart']` 监听的lib路径。
- `--asset-path`: `['lib/assets/*.*']` 监听的asset资产路径。当是flutter项目并且没有配置asset-path时，会取flutter:assets和flutter:fonts的资产路径。
- `--dustbin-path`: `'.asset_dustbin/'` 删除的asset资产保存的垃圾箱文件夹dustbin路径。
- `--list-path`: `'lib/asset_list.dart'` 通过asset资产创建的清单list。
- `--config-path`: `'pubspec.yaml'` config文件路径。
- `--name-replace`: `{'libAssets':''}` asset资产实例名替换。

##### 在终端中设置参数示例，优先级第一位

```sh
$ dart run asset_manager_tool watch --dustbin-path=.asset_dustbin/ --list-path=lib/asset_list.dart --name-replace=libAssets:
$ dart run asset_manager_tool build:asset --dustbin-path=.asset_dustbin/ --list-path=lib/asset_list.dart --name-replace=libAssets:
$ dart run asset_manager_tool build:list --dustbin-path=.asset_dustbin/ --list-path=lib/asset_list.dart --name-replace=libAssets:
$ dart run asset_manager_tool clean --dustbin-path=.asset_dustbin/ --list-path=lib/asset_list.dart --name-replace=libAssets:
```

##### 在asset_manager_tool.yaml中设置参数示例，优先级第二位

```yaml
asset_manager_tool:
  dustbin-path: .asset_dustbin/
  list-path: lib/asset_list.dart
  name-replace:
    libAssets:
```

##### 在pubspec.yaml中设置参数示例，优先级第三位

> 注意: 当是flutter项目并且没有配置asset-path时，会取flutter:assets和flutter:fonts的资产路径。

```yaml
flutter:
  assets:
    - lib/assets/options/
    - lib/assets/img/

  fonts:
    - family: Iconfont
      fonts:
        - asset: lib/assets/fonts/iconfont.ttf
          style: italic

asset_manager_tool:
  dustbin-path: .asset_dustbin/
  list-path: lib/asset_list.dart
  name-replace:
    libAssets:
```

### 项目中使用

```dart
// asset_list.dart文件由参数list-path决定
import 'asset_list.dart';

void main() {
  // 资产路径，assetName由资产路径和参数name-replace决定
  print(AssetList.assetName.path);
  // 如果是图片，你还可以获得宽、高
  print(AssetList.assetName.width);
  print(AssetList.assetName.height);
}
```

### 资产管理和使用提示

- 修改资产文件: 当添加、删除、修改资产文件时`asset_list.dart`中的资产清单也会跟随修改。
- 修改`asset_list.dart`中的资产: 当删除、恢复资产信息实例时，资产文件会被移到、移出垃圾箱文件夹`.asset_dustbin/`。
- 是否使用: `asset_list.dart`中的每条资产信息实例前都有一段注释，里面备注了hash和是否使用，`Y`有使用，`N`没使用。

[dev_dependencies]: https://dart.dev/tools/pub/dependencies#dev-dependencies
[pubspec]: https://dart.dev/tools/pub/pubspec
