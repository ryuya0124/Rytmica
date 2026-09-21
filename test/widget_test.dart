import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musical_note_calculator/UI/adaptive_layout.dart';

void main() {
  Widget buildProbe(MediaQueryData data) {
    return MediaQuery(
      data: data,
      child: Builder(
        builder: (context) {
          final layout = AdaptiveLayoutInfo.of(context);
          return Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              '${layout.sizeClass.name}|${layout.usesNavigationRail}|'
              '${layout.supportsInlinePanel}|${layout.foldGap}',
            ),
          );
        },
      ),
    );
  }

  testWidgets('uses compact navigation on a standard iPhone width', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildProbe(const MediaQueryData(size: Size(430, 932))),
    );

    expect(find.text('compact|false|false|0.0'), findsOneWidget);
  });

  testWidgets('uses an adaptive rail when iPhone Duo is unfolded', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildProbe(const MediaQueryData(size: Size(900, 720))),
    );

    expect(find.text('medium|true|true|0.0'), findsOneWidget);
  });

  testWidgets('reserves the physical hinge reported by a dual display', (
    tester,
  ) async {
    const hinge = DisplayFeature(
      bounds: Rect.fromLTWH(448, 0, 4, 720),
      type: DisplayFeatureType.hinge,
      state: DisplayFeatureState.postureFlat,
    );

    await tester.pumpWidget(
      buildProbe(
        const MediaQueryData(
          size: Size(900, 720),
          displayFeatures: [hinge],
        ),
      ),
    );

    expect(find.text('medium|true|true|4.0'), findsOneWidget);
  });
}
