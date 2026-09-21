import 'package:flutter/material.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';
import 'package:musical_note_calculator/extensions/app_localizations_extension.dart';

class NoteCard extends StatelessWidget {
  final Map<String, String> note;

  final VoidCallback onTap;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
  });

  static const _cardBorderRadius = BorderRadius.all(Radius.circular(16));
  static const _iconBorderRadius = BorderRadius.all(Radius.circular(12));
  static const _arrowBorderRadius = BorderRadius.all(Radius.circular(10));
  static const _cardPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 14,
  );
  static const _cardMargin = EdgeInsets.symmetric(vertical: 6, horizontal: 16);
  static const _iconSize = 44.0;
  // static const _musicIcon = Icon(Icons.music_note_rounded, size: 24); // Use directly
  // static const _arrowIcon = Icon(Icons.arrow_forward_ios_rounded, size: 16); // Use directly

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return RepaintBoundary(
      child: Container(
        margin: _cardMargin,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: _cardBorderRadius,
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: _cardBorderRadius,
            onTap: onTap,
            child: Padding(
              padding: _cardPadding,
              child: Row(
                children: [
                  // 音楽アイコン
                  Container(
                    width: _iconSize,
                    height: _iconSize,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: _iconBorderRadius,
                    ),
                    child: IconTheme(
                      data: IconThemeData(
                        color: colorScheme.onPrimaryContainer,
                      ),
                      child: const Icon(Icons.music_note_rounded, size: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // テキスト部分
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!
                              .getTranslation(note['name']!),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          note['duration']!,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // 矢印アイコン
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: _arrowBorderRadius,
                    ),
                    child: IconTheme(
                      data: IconThemeData(color: colorScheme.onSurfaceVariant),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
