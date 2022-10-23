abstract class AssetList {
  /* 24d8912f N */ static const String imgCoverJpg = 'lib/assets/img/cover.jpg';
  /* 388ac2db N */ static const String imgLodingPng = 'lib/assets/img/loding.png';
  /* 1f891afe N */ static const String fontsIconfontItalicTtf = 'lib/assets/fonts/iconfont-Italic.ttf';
  /* 9b024533 Y */ static const String fontsIconfontRegularTtf = 'lib/assets/fonts/iconfont-Regular.ttf';
  /* 1757e9c5 N */ static const String optionsDataJson = 'lib/assets/options/data.json';
}

const Map<String, Size> _sizes = {
  'lib/assets/img/cover.jpg': Size(1200, 799),
  'lib/assets/img/loding.png': Size(204, 204),
};

extension AssetStringExtension on String {
  Size? get size => _sizes[this];
  int? get width => size?.width;
  int? get height => size?.height;
}

class Size {
  final int width;
  final int height;

  const Size(
    this.width,
    this.height,
  );
}
