/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: directives_ordering,unnecessary_import,implicit_dynamic_list_literal,deprecated_member_use

import 'package:flutter/widgets.dart';

class $AssetsIconsGen {
  const $AssetsIconsGen();

  /// File path: assets/icons/add_image_icon.svg
  String get addImageIcon => 'assets/icons/add_image_icon.svg';

  /// File path: assets/icons/apple_icon.svg
  String get appleIcon => 'assets/icons/apple_icon.svg';

  /// File path: assets/icons/back.svg
  String get back => 'assets/icons/back.svg';

  /// File path: assets/icons/gmail_icon.svg
  String get gmailIcon => 'assets/icons/gmail_icon.svg';

  /// File path: assets/icons/google_icon.svg
  String get googleIcon => 'assets/icons/google_icon.svg';

  /// File path: assets/icons/home.svg
  String get home => 'assets/icons/home.svg';

  /// File path: assets/icons/masters.svg
  String get masters => 'assets/icons/masters.svg';

  /// File path: assets/icons/pending.svg
  String get pending => 'assets/icons/pending.svg';

  /// File path: assets/icons/profile.svg
  String get profile => 'assets/icons/profile.svg';

  /// File path: assets/icons/services.svg
  String get services => 'assets/icons/services.svg';

  /// List of all assets
  List<String> get values => [
    addImageIcon,
    appleIcon,
    back,
    gmailIcon,
    googleIcon,
    home,
    masters,
    pending,
    profile,
    services,
  ];
}

class $AssetsImagesGen {
  const $AssetsImagesGen();

  /// File path: assets/images/activities.png
  AssetGenImage get activities =>
      const AssetGenImage('assets/images/activities.png');

  /// File path: assets/images/deliver.png
  AssetGenImage get deliver => const AssetGenImage('assets/images/deliver.png');

  /// File path: assets/images/food.png
  AssetGenImage get food => const AssetGenImage('assets/images/food.png');

  /// File path: assets/images/gradient1.png
  AssetGenImage get gradient1 =>
      const AssetGenImage('assets/images/gradient1.png');

  /// File path: assets/images/gradient2.png
  AssetGenImage get gradient2 =>
      const AssetGenImage('assets/images/gradient2.png');

  /// File path: assets/images/grocery.png
  AssetGenImage get grocery => const AssetGenImage('assets/images/grocery.png');

  /// File path: assets/images/loginbg.png
  AssetGenImage get loginbg => const AssetGenImage('assets/images/loginbg.png');

  /// File path: assets/images/massage.png
  AssetGenImage get massage => const AssetGenImage('assets/images/massage.png');

  /// List of all assets
  List<AssetGenImage> get values => [
    activities,
    deliver,
    food,
    gradient1,
    gradient2,
    grocery,
    loginbg,
    massage,
  ];
}

class Assets {
  const Assets._();

  static const $AssetsIconsGen icons = $AssetsIconsGen();
  static const $AssetsImagesGen images = $AssetsImagesGen();
}

class AssetGenImage {
  const AssetGenImage(this._assetName, {this.size, this.flavors = const {}});

  final String _assetName;

  final Size? size;
  final Set<String> flavors;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({AssetBundle? bundle, String? package}) {
    return AssetImage(_assetName, bundle: bundle, package: package);
  }

  String get path => _assetName;

  String get keyName => _assetName;
}
