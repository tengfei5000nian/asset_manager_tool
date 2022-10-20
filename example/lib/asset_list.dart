abstract class AssetList {
  /* 1f891afe N */ static const AssetItem fontsIconfontItalicTtf = AssetItem('lib/assets/fonts/iconfont-Italic.ttf');
  /* 9b024533 Y */ static const AssetItem fontsIconfontRegularTtf = AssetItem('lib/assets/fonts/iconfont-Regular.ttf');
  /* 24d8912f N */ static const ImageAssetItem imgCoverJpg = ImageAssetItem('lib/assets/img/cover.jpg', 1200, 799);
  /* 388ac2db Y */ static const ImageAssetItem imgLodingPng = ImageAssetItem('lib/assets/img/loding.png', 204, 204);
  /* 1757e9c5 N */ static const AssetItem optionsDataJson = AssetItem('lib/assets/options/data.json');
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
