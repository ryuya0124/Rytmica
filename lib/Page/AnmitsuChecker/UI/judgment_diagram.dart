import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';

import '../Logic/anmitsu_models.dart';

class JudgmentDiagram extends StatelessWidget {
  final AnmituCalcResult result;
  final int decimals;

  const JudgmentDiagram({
    super.key,
    required this.result,
    required this.decimals,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = result.isPossible
        ? colorScheme.primary
        : colorScheme.error;
    final statusText = result.isPossible
        ? loc.anmitsuPossible
        : loc.anmitsuImpossible;
    final detailText = result.isPossible
        ? '±${result.anmituValue.toStringAsFixed(decimals)} ms'
        : loc.millisecondsShort(result.shortfallMs.toStringAsFixed(decimals));

    return Semantics(
      label: '$statusText, $detailText',
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final height = (constraints.maxWidth * .68).clamp(280.0, 420.0);
              return Container(
                height: height,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.outlineVariant,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: CustomPaint(
                  painter: _TimelinePainter(
                    result: result,
                    decimals: decimals,
                    colorScheme: colorScheme,
                    textDirection: Directionality.of(context),
                    earlierLabel: loc.earlierNote,
                    laterLabel: loc.laterNote,
                    intervalLabel: loc.note_length,
                    overlapLabel: loc.actualOverlap,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _LegendChip(
                color: colorScheme.primary,
                label: loc.note1JudgmentWindow,
              ),
              _LegendChip(
                color: colorScheme.tertiary,
                label: loc.note2JudgmentWindow,
              ),
              _LegendChip(
                color: statusColor,
                label: result.isPossible
                    ? loc.overlapArea
                    : loc.millisecondsShort(
                        result.shortfallMs.toStringAsFixed(decimals),
                      ),
                outlined: !result.isPossible,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withValues(alpha: .28)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: .14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    result.isPossible
                        ? Icons.check_rounded
                        : Icons.close_rounded,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        result.isPossible
                            ? '${loc.actualOverlap}: '
                                  '${result.overlapDurationMs.toStringAsFixed(decimals)} ms  ·  '
                                  '${loc.anmitsu_value}: $detailText'
                            : '${loc.actualOverlap}: $detailText',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;
  final bool outlined;

  const _LegendChip({
    required this.color,
    required this.label,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: outlined ? .04 : .09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: outlined ? Colors.transparent : color,
              border: Border.all(color: color, width: 2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 7),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  final AnmituCalcResult result;
  final int decimals;
  final ColorScheme colorScheme;
  final TextDirection textDirection;
  final String earlierLabel;
  final String laterLabel;
  final String intervalLabel;
  final String overlapLabel;

  const _TimelinePainter({
    required this.result,
    required this.decimals,
    required this.colorScheme,
    required this.textDirection,
    required this.earlierLabel,
    required this.laterLabel,
    required this.intervalLabel,
    required this.overlapLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const top = 54.0;
    const bottom = 30.0;
    final plotHeight = math.max(1.0, size.height - top - bottom);
    final minTime = -result.earlierNoteEarlyWindow;
    final maxTime = result.noteLengthMs + result.laterNoteLateWindow;
    final timeRange = math.max(1, maxTime - minTime);
    double yFor(double time) => top + (time - minTime) / timeRange * plotHeight;

    final earlierX = size.width * .27;
    final laterX = size.width * .66;
    final arrowX = size.width * .9;
    final bandWidth = math.min(86.0, size.width * .2);
    final earlierTop = yFor(-result.earlierNoteEarlyWindow);
    final earlierBottom = yFor(result.earlierNoteLateWindow);
    final laterTop = yFor(
      result.noteLengthMs - result.laterNoteEarlyWindow,
    );
    final laterBottom = yFor(
      result.noteLengthMs + result.laterNoteLateWindow,
    );
    final firstY = yFor(0);
    final secondY = yFor(result.noteLengthMs);

    _drawGrid(canvas, size, top, plotHeight);
    _drawBand(
      canvas,
      x: earlierX,
      width: bandWidth,
      top: earlierTop,
      bottom: earlierBottom,
      noteY: firstY,
      color: colorScheme.primary,
      label: earlierLabel,
      value: result.earlyPresetLabel,
    );
    _drawBand(
      canvas,
      x: laterX,
      width: bandWidth,
      top: laterTop,
      bottom: laterBottom,
      noteY: secondY,
      color: colorScheme.tertiary,
      label: laterLabel,
      value: result.latePresetLabel,
    );
    _drawInterval(canvas, arrowX, firstY, secondY);

    if (result.isPossible) {
      _drawOverlap(
        canvas,
        earlierX,
        laterX,
        laterTop,
        earlierBottom,
      );
    } else {
      _drawShortfall(
        canvas,
        earlierX,
        laterX,
        earlierBottom,
        laterTop,
      );
    }
  }

  void _drawGrid(Canvas canvas, Size size, double top, double plotHeight) {
    final paint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: .55)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = top + plotHeight * i / 4;
      canvas.drawLine(Offset(18, y), Offset(size.width - 18, y), paint);
    }
  }

  void _drawBand(
    Canvas canvas, {
    required double x,
    required double width,
    required double top,
    required double bottom,
    required double noteY,
    required Color color,
    required String label,
    required String value,
  }) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTRB(x - width / 2, top, x + width / 2, bottom),
      const Radius.circular(12),
    );
    canvas.drawRRect(rect, Paint()..color = color.withValues(alpha: .13));
    canvas.drawRRect(
      rect,
      Paint()
        ..color = color.withValues(alpha: .55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawLine(
      Offset(x - width / 2 - 6, noteY),
      Offset(x + width / 2 + 6, noteY),
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(x, noteY), 6, Paint()..color = color);
    _paintText(
      canvas,
      label,
      Offset(x, 14),
      colorScheme.onSurface,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      maxWidth: width + 36,
      centered: true,
    );
    _paintText(
      canvas,
      value,
      Offset(x, 31),
      colorScheme.onSurfaceVariant,
      fontSize: 10,
      maxWidth: width + 38,
      centered: true,
    );
  }

  void _drawInterval(Canvas canvas, double x, double startY, double endY) {
    final paint = Paint()
      ..color = colorScheme.onSurfaceVariant
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(x, startY), Offset(x, endY), paint);
    const head = 5.0;
    canvas.drawLine(Offset(x, startY), Offset(x - head, startY + head), paint);
    canvas.drawLine(Offset(x, startY), Offset(x + head, startY + head), paint);
    canvas.drawLine(Offset(x, endY), Offset(x - head, endY - head), paint);
    canvas.drawLine(Offset(x, endY), Offset(x + head, endY - head), paint);
    _paintText(
      canvas,
      '${result.noteLengthMs.toStringAsFixed(decimals)} ms',
      Offset(x - 6, (startY + endY) / 2 - 8),
      colorScheme.onSurface,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      maxWidth: 76,
      alignRight: true,
    );
    _paintText(
      canvas,
      intervalLabel,
      Offset(x - 6, (startY + endY) / 2 + 8),
      colorScheme.onSurfaceVariant,
      fontSize: 9,
      maxWidth: 76,
      alignRight: true,
    );
  }

  void _drawOverlap(
    Canvas canvas,
    double earlierX,
    double laterX,
    double top,
    double bottom,
  ) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTRB(earlierX + 10, top, laterX - 10, bottom),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      rect,
      Paint()..color = colorScheme.primary.withValues(alpha: .2),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = colorScheme.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    _paintText(
      canvas,
      '$overlapLabel\n${result.overlapDurationMs.toStringAsFixed(decimals)} ms',
      Offset((earlierX + laterX) / 2, (top + bottom) / 2),
      colorScheme.primary,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      maxWidth: math.max(70, laterX - earlierX - 28),
      centered: true,
    );
  }

  void _drawShortfall(
    Canvas canvas,
    double earlierX,
    double laterX,
    double startY,
    double endY,
  ) {
    final x = (earlierX + laterX) / 2;
    final paint = Paint()
      ..color = colorScheme.error
      ..strokeWidth = 2;
    const dash = 5.0;
    for (double y = startY; y < endY; y += dash * 2) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, math.min(y + dash, endY)),
        paint,
      );
    }
    _paintText(
      canvas,
      '${result.shortfallMs.toStringAsFixed(decimals)} ms',
      Offset(x, (startY + endY) / 2),
      colorScheme.error,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      maxWidth: 88,
      centered: true,
      background: colorScheme.surfaceContainerLow,
    );
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset anchor,
    Color color, {
    required double fontSize,
    required double maxWidth,
    FontWeight fontWeight = FontWeight.w500,
    bool centered = false,
    bool alignRight = false,
    Color? background,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: 1.15,
          backgroundColor: background,
        ),
      ),
      textDirection: textDirection,
      textAlign: centered ? TextAlign.center : TextAlign.start,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    final dx = centered
        ? anchor.dx - painter.width / 2
        : alignRight
        ? anchor.dx - painter.width
        : anchor.dx;
    final dy = centered ? anchor.dy - painter.height / 2 : anchor.dy;
    painter.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) {
    return oldDelegate.result != result ||
        oldDelegate.decimals != decimals ||
        oldDelegate.colorScheme != colorScheme ||
        oldDelegate.textDirection != textDirection;
  }
}
