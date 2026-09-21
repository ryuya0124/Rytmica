import 'dart:ui';

import 'package:flutter/widgets.dart';

enum RytmicaWindowSizeClass { compact, medium, expanded }

/// Centralized window classification for phones, foldables, tablets, and
/// desktop windows. Width is intentionally used instead of device type so the
/// UI follows the space that is actually available while a device unfolds,
/// rotates, or enters split view.
class AdaptiveLayoutInfo {
  const AdaptiveLayoutInfo({
    required this.size,
    required this.displayFeatures,
  });

  factory AdaptiveLayoutInfo.of(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return AdaptiveLayoutInfo(
      size: mediaQuery.size,
      displayFeatures: mediaQuery.displayFeatures,
    );
  }

  final Size size;
  final List<DisplayFeature> displayFeatures;

  RytmicaWindowSizeClass get sizeClass {
    if (size.width >= 1200) return RytmicaWindowSizeClass.expanded;
    if (size.width >= 720) return RytmicaWindowSizeClass.medium;
    return RytmicaWindowSizeClass.compact;
  }

  bool get usesNavigationRail => sizeClass != RytmicaWindowSizeClass.compact;

  bool get usesExtendedNavigationRail =>
      sizeClass == RytmicaWindowSizeClass.expanded;

  /// Enough room for the main workflow and the optional metronome panel.
  bool get supportsInlinePanel => size.width >= 840;

  Rect? get verticalFold {
    for (final feature in displayFeatures) {
      final bounds = feature.bounds;
      final isFold =
          feature.type == DisplayFeatureType.fold ||
          feature.type == DisplayFeatureType.hinge;
      if (isFold && bounds.height > bounds.width) return bounds;
    }
    return null;
  }

  double get foldGap => verticalFold?.width ?? 0;
}
