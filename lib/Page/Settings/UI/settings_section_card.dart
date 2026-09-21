import 'package:flutter/material.dart';

class SettingsSectionCard extends StatelessWidget {
  static const _cardBorderRadius = BorderRadius.all(Radius.circular(20));
  static const _iconBorderRadius = BorderRadius.all(Radius.circular(10));
  static const _cardPadding = EdgeInsets.all(20);
  static const _headerPadding = EdgeInsets.all(8);
  static const _iconSize = 20.0;
  static const _defaultIcon = Icon(Icons.settings_rounded, size: 20);

  final String title;
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final IconData? icon;

  const SettingsSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.margin,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: Container(
        margin: margin ?? const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: _cardBorderRadius,
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: _cardBorderRadius,
          child: Padding(
            padding: _cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // タイトル行（アイコン + テキスト）
                Row(
                  children: [
                    Container(
                      padding: _headerPadding,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: _iconBorderRadius,
                      ),
                      child: IconTheme(
                        data: IconThemeData(
                          color: colorScheme.onPrimaryContainer,
                        ),
                        child: icon != null
                            ? Icon(icon, size: _iconSize)
                            : _defaultIcon,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
