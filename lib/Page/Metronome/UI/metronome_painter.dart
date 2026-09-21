import 'package:flutter/material.dart';

class MetronomePainter extends CustomPainter {
  final double angle;
  final Color color;
  final Color onSurfaceColor;

  MetronomePainter({
    required this.angle,
    required this.color,
    required this.onSurfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 描画の中心（支点）
    final center = Offset(size.width / 2, size.height * 0.95);
    final rodLength = size.height * 0.85;

    // --- メトロノーム本体 (Body) ---
    final bodyPath = Path();
    final double bodyBottomWidth = size.width * 0.6;
    final double bodyTopWidth = size.width * 0.25;
    final double bodyHeight = size.height * 0.9;
    final double bodyBottomY = size.height;

    bodyPath.moveTo(
      size.width / 2 - bodyTopWidth / 2,
      size.height - bodyHeight,
    ); // Top Left
    bodyPath.lineTo(
      size.width / 2 + bodyTopWidth / 2,
      size.height - bodyHeight,
    ); // Top Right
    bodyPath.lineTo(
      size.width / 2 + bodyBottomWidth / 2,
      bodyBottomY,
    ); // Bottom Right
    bodyPath.lineTo(
      size.width / 2 - bodyBottomWidth / 2,
      bodyBottomY,
    ); // Bottom Left
    bodyPath.close();

    // 本体の塗りと枠線
    final Paint bodyPaint = Paint()
      ..color = onSurfaceColor.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawPath(bodyPath, bodyPaint);

    final Paint bodyBorderPaint = Paint()
      ..color = onSurfaceColor.withValues(alpha: 0.1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(bodyPath, bodyBorderPaint);

    // --- 振り子 (Pendulum) ---
    // 棒 (Rod) のスタイル
    final Paint rodPaint = Paint()
      ..color = onSurfaceColor.withValues(alpha: 0.8)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    // 1. 棒を描画
    canvas.drawLine(const Offset(0, 0), Offset(0, -rodLength), rodPaint);

    // 2. 支点 (Pivot) を描画
    final Paint pivotPaint = Paint()
      ..color = onSurfaceColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(0, 0), 6, pivotPaint);

    // 3. 重り (Bob) の位置計算
    final double bobY = -rodLength * 0.8;
    final double bobWidth = 24.0;
    final double bobHeight = 36.0;

    final RRect bobRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, bobY),
        width: bobWidth,
        height: bobHeight,
      ),
      const Radius.circular(6),
    );

    // 影
    canvas.drawShadow(
      Path()..addRRect(bobRRect),
      Colors.black.withValues(alpha: 0.3),
      4.0,
      true,
    );

    // 重りの本体
    final Paint bobPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRRect(bobRRect, bobPaint);

    // 重りの枠線
    final Paint bobBorderPaint = Paint()
      ..color = onSurfaceColor.withValues(alpha: 0.9)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(bobRRect, bobBorderPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MetronomePainter oldDelegate) {
    return oldDelegate.angle != angle ||
        oldDelegate.color != color ||
        oldDelegate.onSurfaceColor != onSurfaceColor;
  }
}
