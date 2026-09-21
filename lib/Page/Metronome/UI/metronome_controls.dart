import 'package:flutter/material.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';

import '../../../ParamData/notes.dart';

class MetronomeControls extends StatelessWidget {
  final int vol;
  final bool isPlaying;
  final int selectedBeatOption;
  final int? customBeats;
  final String note;
  final List<int> beatOptions;
  final ValueChanged<int> onVolumeChanged;
  final VoidCallback onToggle;
  final ValueChanged<int> onBeatOptionChanged;
  final ValueChanged<int> onCustomBeatsChanged;

  static const int customBeatSentinel = -1;

  const MetronomeControls({
    super.key,
    required this.vol,
    required this.isPlaying,
    required this.selectedBeatOption,
    required this.customBeats,
    required this.note,
    required this.beatOptions,
    required this.onVolumeChanged,
    required this.onToggle,
    required this.onBeatOptionChanged,
    required this.onCustomBeatsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.55)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.85);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.35),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.35 : 0.15),
            blurRadius: 45,
            spreadRadius: 1,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 拍子セレクター
          _buildBeatSelector(context),
          const SizedBox(height: 20),
          // ボリュームセクション
          Row(
            children: [
              Text(
                localizations.volumeLabel.toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 1.2,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                '$vol%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildVolumeBar(context),
          const SizedBox(height: 24),
          _buildToggleButton(context),
        ],
      ),
    );
  }

  Widget _buildBeatSelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;

    final noteData = findNoteData(note);
    final int baseDenom = noteData.note.toInt();
    final bool isDottedNote = noteData.dotted;

    String formatBeatLabel(int beats) {
      if (!isDottedNote) {
        return '$beats/$baseDenom';
      } else {
        final int top = beats * 3;
        final int bottom = baseDenom * 2;
        return '$top/$bottom';
      }
    }

    // 現在の選択表示用のラベル
    String currentLabel;
    if (selectedBeatOption == customBeatSentinel) {
      currentLabel = localizations.otherOption;
    } else {
      currentLabel = formatBeatLabel(selectedBeatOption);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.timeSignatureLabel.toUpperCase(),
          style: TextStyle(
            fontSize: 14,
            letterSpacing: 1.2,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Theme(
                data: Theme.of(context).copyWith(
                  popupMenuTheme: PopupMenuThemeData(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                    color: colorScheme.surfaceContainerHighest,
                  ),
                ),
                child: PopupMenuButton<int>(
                  offset: const Offset(0, 8),
                  itemBuilder: (context) {
                    return [
                      ...beatOptions.map(
                        (b) => PopupMenuItem(
                          value: b,
                          child: Text(
                            formatBeatLabel(b),
                            style: TextStyle(
                              fontWeight: selectedBeatOption == b
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: selectedBeatOption == b
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      PopupMenuItem(
                        value: customBeatSentinel,
                        child: Text(
                          localizations.otherOption,
                          style: TextStyle(
                            fontWeight: selectedBeatOption == customBeatSentinel
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: selectedBeatOption == customBeatSentinel
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ];
                  },
                  onSelected: onBeatOptionChanged,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 14.0,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          currentLabel,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (selectedBeatOption == customBeatSentinel) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 72,
                child: TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  controller: TextEditingController(
                    text: customBeats?.toString() ?? '',
                  ),
                  decoration: InputDecoration(
                    labelText: localizations.beatLabel,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.5),
                      ),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHigh.withValues(
                      alpha: 0.3,
                    ),
                  ),
                  onChanged: (val) {
                    final parsed = int.tryParse(val);
                    if (parsed != null) {
                      onCustomBeatsChanged(parsed);
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildVolumeBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 14,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
        overlayShape: SliderComponentShape.noOverlay,
        activeTrackColor: colorScheme.secondary,
        inactiveTrackColor: colorScheme.onSurface.withValues(alpha: 0.15),
        thumbColor: colorScheme.secondary,
      ),
      child: Slider(
        value: vol.toDouble(),
        min: 0,
        max: 100,
        divisions: 100,
        label: '$vol%',
        onChanged: (val) {
          onVolumeChanged(val.toInt());
        },
      ),
    );
  }

  Widget _buildToggleButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttonColor = isPlaying
        ? colorScheme.error
        : colorScheme.secondaryContainer;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onToggle,
        icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow_rounded),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Text(
            isPlaying
                ? AppLocalizations.of(context)!.stop
                : AppLocalizations.of(context)!.start,
            style: const TextStyle(fontSize: 18, letterSpacing: 1.2),
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
          backgroundColor: buttonColor,
          foregroundColor: isPlaying
              ? colorScheme.onError
              : colorScheme.onSecondaryContainer,
          elevation: 0,
        ),
      ),
    );
  }
}
