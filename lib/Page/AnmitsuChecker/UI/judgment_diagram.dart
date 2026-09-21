import 'package:flutter/material.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';

import '../Logic/anmitsu_models.dart';

/// 判定幅を図で表示するウィジェット
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 図の描画（モダンなグラデーション背景付き）
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.surfaceContainerHighest,
                colorScheme.surfaceContainer,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1.2,
              child: DiagramCanvas(
                result: result,
                decimals: decimals,
                colorScheme: colorScheme,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // 凡例（ピル型のモダンなデザイン）
        _buildLegend(context, colorScheme, loc),

        const SizedBox(height: 16),

        // 結果テキスト（グラデーション背景）
        _buildResultInfo(context, colorScheme, loc),
      ],
    );
  }

  Widget _buildLegend(
    BuildContext context,
    ColorScheme colorScheme,
    AppLocalizations loc,
  ) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        LegendItem(
          color: Colors.yellow.shade200,
          label: loc.note1JudgmentWindow,
        ),
        LegendItem(
          color: Colors.orange.shade200,
          label: loc.note2JudgmentWindow,
        ),
        LegendItem(
          color: Colors.red.shade300,
          label: loc.overlapArea,
        ),
      ],
    );
  }

  Widget _buildResultInfo(
    BuildContext context,
    ColorScheme colorScheme,
    AppLocalizations loc,
  ) {
    final theme = Theme.of(context);
    final isPositive = result.anmituValue > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            result.color.withValues(alpha: 0.15),
            result.color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: result.color.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: result.color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 結果アイコン
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: result.color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPositive
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  color: result.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.overlapArea,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '±${result.anmituValue.toStringAsFixed(decimals)} ms',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: result.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isPositive ? loc.anmitsuPossibleDesc : loc.anmitsuImpossibleDesc,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const LegendItem({
    super.key,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// 図の描画キャンバス（領域を完全に分離）
class DiagramCanvas extends StatelessWidget {
  final AnmituCalcResult result;
  final int decimals;
  final ColorScheme colorScheme;

  const DiagramCanvas({
    super.key,
    required this.result,
    required this.decimals,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        // ノーツ2の下端（遅判定 + ラベル用余白）を考慮した動的パディング
        const topPadding = 30.0;
        const labelSpace = 30.0; // ラベル用のスペース

        // ノーツ2の下端位置を計算（上部パディング + ノーツ間隔 + 遅判定幅）
        // これが図の下端からlabelSpace分上に収まるようにスケールを計算
        final totalContentMs =
            result.windowEarly + result.noteLengthMs + result.windowLate;
        final drawableHeight = availableHeight - topPadding - labelSpace;

        // 高さのスケール（ピクセル/ms）
        final scale = drawableHeight / (totalContentMs * 1.1);

        // ノーツ1の判定幅
        final note1EarlyHeight = result.windowEarly * scale;
        final note1LateHeight = result.windowLate * scale;

        // ノーツ間隔
        final noteIntervalHeight = result.noteLengthMs * scale;

        // ノーツ2の判定幅
        final note2EarlyHeight = note1EarlyHeight;
        final note2LateHeight = note1LateHeight;

        // 重なりの計算
        final overlapMs = result.anmituValue > 0 ? result.anmituValue : 0.0;
        final overlapHeight = overlapMs * scale;

        // ノーツ1の中心位置（上側に配置）
        final note1CenterY = topPadding + result.windowEarly * scale;
        // ノーツ2の中心位置
        final note2CenterY = note1CenterY + noteIntervalHeight;

        return CustomPaint(
          size: Size(availableWidth, availableHeight),
          painter: _JudgmentDiagramPainterVertical(
            note1CenterY: note1CenterY,
            note1EarlyHeight: note1EarlyHeight,
            note1LateHeight: note1LateHeight,
            note2CenterY: note2CenterY,
            note2EarlyHeight: note2EarlyHeight,
            note2LateHeight: note2LateHeight,
            overlapHeight: overlapHeight,
            overlapMs: overlapMs,
            result: result,
            decimals: decimals,
            colorScheme: colorScheme,
          ),
        );
      },
    );
  }
}

class _JudgmentDiagramPainterVertical extends CustomPainter {
  final double note1CenterY;
  final double note1EarlyHeight;
  final double note1LateHeight;
  final double note2CenterY;
  final double note2EarlyHeight;
  final double note2LateHeight;
  final double
  overlapHeight; // Unused but kept for consistency with original or future use
  final double overlapMs;
  final AnmituCalcResult result;
  final int decimals;
  final ColorScheme colorScheme;

  _JudgmentDiagramPainterVertical({
    required this.note1CenterY,
    required this.note1EarlyHeight,
    required this.note1LateHeight,
    required this.note2CenterY,
    required this.note2EarlyHeight,
    required this.note2LateHeight,
    required this.overlapHeight,
    required this.overlapMs,
    required this.result,
    required this.decimals,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ノーツは横に並べる（左: ノーツ1、右: ノーツ2）
    final note1X = size.width * 0.3;
    final note2X = size.width * 0.7;
    final noteWidth = 60.0;

    // ノーツ1の判定幅描画（縦向き）
    _drawJudgmentWindowVertical(
      canvas,
      note1X,
      note1CenterY,
      note1EarlyHeight,
      note1LateHeight,
      noteWidth,
      Colors.yellow.shade200,
      result.earlyPresetLabel,
      '1',
    );

    // ノーツ2の判定幅描画（縦向き）
    _drawJudgmentWindowVertical(
      canvas,
      note2X,
      note2CenterY,
      note2EarlyHeight,
      note2LateHeight,
      noteWidth,
      Colors.orange.shade200,
      result.latePresetLabel,
      '2',
    );

    // 重なりエリアの描画（モダンなグロー効果付き）
    if (overlapMs > 0) {
      final note1LateEnd = note1CenterY + note1LateHeight;
      final note2EarlyStart = note2CenterY - note2EarlyHeight;

      final overlapTop = note2EarlyStart;
      final overlapBottom = note1LateEnd;

      // 角丸矩形で重なりエリアを描画
      const overlapRadius = 8.0;
      final overlapRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          note1X - noteWidth / 2 + 4,
          overlapTop,
          note2X - note1X + noteWidth - 8,
          overlapBottom - overlapTop,
        ),
        const Radius.circular(overlapRadius),
      );

      // グロー効果（シャドウ）
      final glowPaint = Paint()
        ..color = Colors.red.shade400.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawRRect(overlapRRect, glowPaint);

      // グラデーション塗りつぶし
      final overlapGradient = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.red.shade300.withValues(alpha: 0.7),
            Colors.red.shade500.withValues(alpha: 0.5),
          ],
        ).createShader(overlapRRect.outerRect);
      canvas.drawRRect(overlapRRect, overlapGradient);

      // ボーダー
      final borderPaint = Paint()
        ..color = Colors.red.shade600
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(overlapRRect, borderPaint);

      // 許容範囲のms表示（バッジスタイル）
      final overlapText = '±${result.anmituValue.toStringAsFixed(decimals)} ms';
      final overlapTextPainter = TextPainter(
        text: TextSpan(
          text: overlapText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      overlapTextPainter.layout();

      // バッジの位置
      final badgeCenterX = (note1X + note2X) / 2;
      final badgeCenterY = (overlapTop + overlapBottom) / 2;

      // バッジ背景
      final badgeRRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(badgeCenterX, badgeCenterY),
          width: overlapTextPainter.width + 16,
          height: overlapTextPainter.height + 10,
        ),
        const Radius.circular(12),
      );

      // バッジシャドウ
      final badgeShadow = Paint()
        ..color = Colors.red.shade900.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRRect(badgeRRect.shift(const Offset(0, 2)), badgeShadow);

      // バッジ本体
      final badgePaint = Paint()..color = Colors.red.shade600;
      canvas.drawRRect(badgeRRect, badgePaint);

      overlapTextPainter.paint(
        canvas,
        Offset(
          badgeCenterX - overlapTextPainter.width / 2,
          badgeCenterY - overlapTextPainter.height / 2,
        ),
      );
    }

    // ノーツ間隔の矢印を描画（縦向き）
    _drawIntervalArrowVertical(canvas, size, note1CenterY, note2CenterY);
  }

  void _drawJudgmentWindowVertical(
    Canvas canvas,
    double x,
    double centerY,
    double earlyHeight,
    double lateHeight,
    double width,
    Color color,
    String label,
    String noteNumber,
  ) {
    // 角丸矩形の半径
    const borderRadius = 12.0;

    // 判定幅の角丸矩形（縦向き：上が早判定、下が遅判定）
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        x - width / 2,
        centerY - earlyHeight,
        width,
        earlyHeight + lateHeight,
      ),
      const Radius.circular(borderRadius),
    );

    // グラデーション塗りつぶし
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.9),
          color.withValues(alpha: 0.5),
        ],
      ).createShader(rrect.outerRect);

    // シャドウ効果
    final shadowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(
      rrect.shift(const Offset(0, 4)),
      shadowPaint,
    );

    // 背景を描画
    canvas.drawRRect(rrect, gradientPaint);

    // ボーダー（グロー効果）
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(rrect, borderPaint);

    // ノーツを角丸長方形で描画（グラデーション背景）
    const noteHeight = 18.0;
    final noteRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, centerY),
        width: width - 12,
        height: noteHeight,
      ),
      const Radius.circular(6),
    );

    // ノーツのグラデーション
    final noteGradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white,
          Colors.grey.shade200,
        ],
      ).createShader(noteRRect.outerRect);

    // ノーツのシャドウ
    final noteShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(noteRRect.shift(const Offset(0, 2)), noteShadow);

    canvas.drawRRect(noteRRect, noteGradient);

    final noteBorderPaint = Paint()
      ..color = colorScheme.outline
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(noteRRect, noteBorderPaint);

    // ノーツラベル（バッジスタイル）
    final labelText = 'Note $noteNumber';
    final textPainter = TextPainter(
      text: TextSpan(
        text: labelText,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // ラベルの背景バッジ
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, centerY - earlyHeight - 16),
        width: textPainter.width + 16,
        height: textPainter.height + 8,
      ),
      const Radius.circular(10),
    );
    final badgePaint = Paint()..color = colorScheme.surfaceContainerHighest;
    canvas.drawRRect(badgeRect, badgePaint);
    final badgeBorder = Paint()
      ..color = colorScheme.outline.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(badgeRect, badgeBorder);

    textPainter.paint(
      canvas,
      Offset(
        x - textPainter.width / 2,
        centerY - earlyHeight - 16 - textPainter.height / 2,
      ),
    );

    // プリセットラベル（下部）
    final presetPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    presetPainter.layout();
    presetPainter.paint(
      canvas,
      Offset(x - presetPainter.width / 2, centerY + lateHeight + 10),
    );
  }

  void _drawIntervalArrowVertical(
    Canvas canvas,
    Size size,
    double startY,
    double endY,
  ) {
    // 矢印を右側に配置（オーバーラップエリアと被らないように）
    final arrowX = size.width * 0.88;
    final arrowPaint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // ノーツ1の横線（短めに）
    final linePaint = Paint()
      // .withValues(alpha: 0.4) is Dart 3.x replacement for .withOpacity(0.4)
      // but let's stick to withOpacity if the project uses older flutter or just to be safe
      // Actually the original code used withValues. Let's use withOpacity for safety unless user is on very new flutter
      // wait, the original code I read in Step 16 `1369:       ..color = colorScheme.primary.withValues(alpha: 0.4)`
      // OK I will use withOpacity to be safe as I am not sure about the flutter version but withValues is safer for future.
      // Actually withOpacity is deprecated in newest flutter but let's see.
      // Re-reading original code: It used `withValues`. So I will use `withOpacity` which is standard in older versions too, or check if I should use `withValues`.
      // Let's stick to `withOpacity` which is safer for now, or just copy `withValues` if I want to match.
      // I'll use `withOpacity` for compatibility unless I see errors.
      ..color = colorScheme.primary.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // 点線風に短い線で描画
    canvas.drawLine(
      Offset(arrowX - 20, startY),
      Offset(arrowX + 20, startY),
      linePaint,
    );

    // ノーツ2の横線
    canvas.drawLine(
      Offset(arrowX - 20, endY),
      Offset(arrowX + 20, endY),
      linePaint,
    );

    // 矢印の線（縦向き）
    canvas.drawLine(
      Offset(arrowX, startY),
      Offset(arrowX, endY),
      arrowPaint,
    );

    // 矢印の先端（下向き）
    const arrowSize = 8.0;
    canvas.drawLine(
      Offset(arrowX, endY),
      Offset(arrowX - arrowSize, endY - arrowSize),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(arrowX, endY),
      Offset(arrowX + arrowSize, endY - arrowSize),
      arrowPaint,
    );

    // 間隔のテキスト（矢印の左側に配置）
    final intervalText = '${result.noteLengthMs.toStringAsFixed(decimals)} ms';
    final textPainter = TextPainter(
      text: TextSpan(
        text: intervalText,
        style: TextStyle(
          color: colorScheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // 矢印の左側に配置
    final textX = arrowX - textPainter.width - 12;
    final textY = (startY + endY) / 2 - textPainter.height / 2;

    // 背景を描画
    final bgPaint = Paint()
      ..color = colorScheme.surface
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        textX - 4,
        textY - 2,
        textPainter.width + 8,
        textPainter.height + 4,
      ),
      bgPaint,
    );

    textPainter.paint(canvas, Offset(textX, textY));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
