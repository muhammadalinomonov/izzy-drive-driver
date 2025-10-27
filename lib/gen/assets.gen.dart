// dart format width=80

/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: deprecated_member_use,directives_ordering,implicit_dynamic_list_literal,unnecessary_import

import 'package:flutter/widgets.dart';

class $AssetsIconsGen {
  const $AssetsIconsGen();

  /// File path: assets/icons/Apple Pay Logo.svg
  String get applePayLogo => 'assets/icons/Apple Pay Logo.svg';

  /// File path: assets/icons/Quadrix Ai Pending.svg
  String get quadrixAiPending => 'assets/icons/Quadrix Ai Pending.svg';

  /// File path: assets/icons/about.svg
  String get about => 'assets/icons/about.svg';

  /// File path: assets/icons/add_image_icon.svg
  String get addImageIcon => 'assets/icons/add_image_icon.svg';

  /// File path: assets/icons/apple_icon.svg
  String get appleIcon => 'assets/icons/apple_icon.svg';

  /// File path: assets/icons/back.svg
  String get back => 'assets/icons/back.svg';

  /// File path: assets/icons/bell.svg
  String get bell => 'assets/icons/bell.svg';

  /// File path: assets/icons/call.svg
  String get call => 'assets/icons/call.svg';

  /// File path: assets/icons/close.svg
  String get close => 'assets/icons/close.svg';

  /// File path: assets/icons/finshflag.svg
  String get finshflag => 'assets/icons/finshflag.svg';

  /// File path: assets/icons/gmail_icon.svg
  String get gmailIcon => 'assets/icons/gmail_icon.svg';

  /// File path: assets/icons/google_icon.svg
  String get googleIcon => 'assets/icons/google_icon.svg';

  /// File path: assets/icons/google_play.svg
  String get googlePlay => 'assets/icons/google_play.svg';

  /// File path: assets/icons/home.svg
  String get home => 'assets/icons/home.svg';

  /// File path: assets/icons/ic_down.svg
  String get icDown => 'assets/icons/ic_down.svg';

  /// File path: assets/icons/ic_up.svg
  String get icUp => 'assets/icons/ic_up.svg';

  /// File path: assets/icons/location.svg
  String get location => 'assets/icons/location.svg';

  /// File path: assets/icons/maploc.svg
  String get maploc => 'assets/icons/maploc.svg';

  /// File path: assets/icons/mastericon.png
  AssetGenImage get mastericon =>
      const AssetGenImage('assets/icons/mastericon.png');

  /// File path: assets/icons/masters.svg
  String get masters => 'assets/icons/masters.svg';

  /// File path: assets/icons/mic.svg
  String get mic => 'assets/icons/mic.svg';

  /// File path: assets/icons/pair.svg
  String get pair => 'assets/icons/pair.svg';

  /// File path: assets/icons/paperclip.svg
  String get paperclip => 'assets/icons/paperclip.svg';

  /// File path: assets/icons/pending.svg
  String get pending => 'assets/icons/pending.svg';

  /// File path: assets/icons/phone.svg
  String get phone => 'assets/icons/phone.svg';

  /// File path: assets/icons/profile.svg
  String get profile => 'assets/icons/profile.svg';

  /// File path: assets/icons/rocket.svg
  String get rocket => 'assets/icons/rocket.svg';

  /// File path: assets/icons/search.svg
  String get search => 'assets/icons/search.svg';

  /// File path: assets/icons/services.svg
  String get services => 'assets/icons/services.svg';

  /// File path: assets/icons/truck.svg
  String get truck => 'assets/icons/truck.svg';

  /// File path: assets/icons/x_mark.svg
  String get xMark => 'assets/icons/x_mark.svg';

  /// List of all assets
  List<dynamic> get values => [
    applePayLogo,
    quadrixAiPending,
    about,
    addImageIcon,
    appleIcon,
    back,
    bell,
    call,
    close,
    finshflag,
    gmailIcon,
    googleIcon,
    googlePlay,
    home,
    icDown,
    icUp,
    location,
    maploc,
    mastericon,
    masters,
    mic,
    pair,
    paperclip,
    pending,
    phone,
    profile,
    rocket,
    search,
    services,
    truck,
    xMark,
  ];
}

class $AssetsImagesGen {
  const $AssetsImagesGen();

  /// File path: assets/images/activities.png
  AssetGenImage get activities =>
      const AssetGenImage('assets/images/activities.png');

  /// File path: assets/images/cardio.png
  AssetGenImage get cardio => const AssetGenImage('assets/images/cardio.png');

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

  /// File path: assets/images/gym.png
  AssetGenImage get gym => const AssetGenImage('assets/images/gym.png');

  /// File path: assets/images/kfc.jpg
  AssetGenImage get kfc => const AssetGenImage('assets/images/kfc.jpg');

  /// File path: assets/images/loginbg.png
  AssetGenImage get loginbg => const AssetGenImage('assets/images/loginbg.png');

  /// File path: assets/images/massage.png
  AssetGenImage get massage => const AssetGenImage('assets/images/massage.png');

  /// File path: assets/images/truck.png
  AssetGenImage get truck => const AssetGenImage('assets/images/truck.png');

  /// List of all assets
  List<AssetGenImage> get values => [
    activities,
    cardio,
    deliver,
    food,
    gradient1,
    gradient2,
    grocery,
    gym,
    kfc,
    loginbg,
    massage,
    truck,
  ];
}

class Assets {
  const Assets._();

  static const String aEnv = '.env';
  static const $AssetsIconsGen icons = $AssetsIconsGen();
  static const $AssetsImagesGen images = $AssetsImagesGen();

  /// List of all assets
  static List<String> get values => [aEnv];
}

class AssetGenImage {
  const AssetGenImage(
    this._assetName, {
    this.size,
    this.flavors = const {},
    this.animation,
  });

  final String _assetName;

  final Size? size;
  final Set<String> flavors;
  final AssetGenImageAnimation? animation;

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

class AssetGenImageAnimation {
  const AssetGenImageAnimation({
    required this.isAnimation,
    required this.duration,
    required this.frames,
  });

  final bool isAnimation;
  final Duration duration;
  final int frames;
}
