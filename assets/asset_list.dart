abstract class AssetList {
  static const ImageAssetItem asdas = ImageAssetItem(
    'assets/img/logo-bg2.jpg',
    'asdasd32423424',
    100,
    100,
  );

  static const AssetItem loading = AssetItem(
    'assets/img/loading.png',
    'fghgh32423423',
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
