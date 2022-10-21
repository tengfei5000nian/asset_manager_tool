## 项目中使用

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