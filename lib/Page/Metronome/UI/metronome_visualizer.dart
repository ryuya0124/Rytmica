import 'package:flutter/material.dart';

import 'dart:math' as math;

import 'metronome_painter.dart';

class MetronomeVisualizer extends StatelessWidget {
  final Animation<double> animation;

  const MetronomeVisualizer({
    super.key,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
            colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.7),
          width: 3,
        ),
      ),
      child: AspectRatio(
        aspectRatio: 3 / 2,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return CustomPaint(
              painter: MetronomePainter(
                angle: animation.value * (math.pi / 4), // ±45度 (π/4)
                color: colorScheme.primary,
                onSurfaceColor: colorScheme.onSurface,
              ),
            );
          },
        ),
      ),
    );
  }
}
