abstract class AssetList {
  static const AssetItem fontsIconfontItalicTtf = AssetItem(
    'assets/fonts/iconfont-Italic.ttf',
    '0698e937b791f8d530cf779f9ba7db0b',
  );

  static const AssetItem fontsIconfontRegularTtf = AssetItem(
    'assets/fonts/iconfont-Regular.ttf',
    '4959c8a0be9096f901f43fc315a390c2',
  );

  static const ImageAssetItem imgCoverJpg = ImageAssetItem(
    'assets/img/cover.jpg',
    '68d6cda50b4b904fb05e1fc0d7728e76',
    1200,
    799,
  );

  static const ImageAssetItem imgLodingPng = ImageAssetItem(
    'assets/img/loding.png',
    'e1ea293bcdc8441e74bbd88bbe2177ec',
    204,
    204,
  );

  static const AssetItem optionsDataJson = AssetItem(
    'assets/options/data.json',
    'e50c38a7550826620d721e69d7f189c7',
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
