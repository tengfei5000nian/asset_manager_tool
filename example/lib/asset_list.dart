abstract class AssetList {
  /* 1f891afead273988ca12cd1c5ab44c01 NO */
  static const AssetItem fontsIconfontItalicTtf = AssetItem('lib/assets/fonts/iconfont-Italic.ttf');
  /* 9b0245338081ab8a9ec34d45551ad00f YES */
  static const AssetItem fontsIconfontRegularTtf = AssetItem('lib/assets/fonts/iconfont-Regular.ttf');
  /* 24d8912f482f31710f6c742904ae896d NO */
  static const ImageAssetItem imgCoverJpg = ImageAssetItem('lib/assets/img/cover.jpg', 1200, 799);
  /* 388ac2db9da13f4d3fd3df237c26e879 YES */
  static const ImageAssetItem imgLodingPng = ImageAssetItem('lib/assets/img/loding.png', 204, 204);
  /* 1757e9c5210c28ee5c37b2bbf4c1599d NO */
  static const AssetItem optionsDataJson = AssetItem('lib/assets/options/data.json');
}

class AssetItem {
  final String path;

  const AssetItem(
    this.path,
  );
}

class ImageAssetItem extends AssetItem {
  final int width;
  final int height;

  const ImageAssetItem(
    super.path,
    this.width,
    this.height,
  );
}
