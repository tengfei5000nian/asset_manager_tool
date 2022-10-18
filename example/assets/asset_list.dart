abstract class AssetList {
  static const AssetItem assetsFontsIconfontItalicTtf = AssetItem(
    'assets/fonts/iconfont-Italic.ttf',
    '21c761507ccc86c1794f37c0f0a92b66',
  );

  static const AssetItem assetsFontsIconfontRegularTtf = AssetItem(
    'assets/fonts/iconfont-Regular.ttf',
    '21c761507ccc86c1794f37c0f0a92b66',
  );

  static const ImageAssetItem assetsImgCoverJpg = ImageAssetItem(
    'assets/img/cover.jpg',
    '505c2ba60f506c594e8e4aec20d40836',
    1200,
    799,
  );

  static const ImageAssetItem assetsImgLodingPng = ImageAssetItem(
    'assets/img/loding.png',
    'af4d5382e4b103f8d2cf48cf21559da4',
    204,
    204,
  );

  static const AssetItem assetsOptionsDataJson = AssetItem(
    'assets/options/data.json',
    '1d12b4593d8498837edfd2fa0efdd118',
  );
}

class AssetItem {
  final String path;
  final String hash;

  const AssetItem(
    this.path,
    this.hash,
  );
}

class ImageAssetItem extends AssetItem {
  final int width;
  final int height;

  const ImageAssetItem(
    super.path,
    super.hash,
    this.width,
    this.height,
  );
}
