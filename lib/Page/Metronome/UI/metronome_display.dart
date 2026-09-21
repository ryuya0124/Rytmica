import 'package:flutter/material.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';
import 'package:musical_note_calculator/extensions/app_localizations_extension.dart';
import 'package:provider/provider.dart';

import '../../../ParamData/settings_model.dart';

class MetronomeDisplay extends StatelessWidget {
  final double bpm;
  final String note;
  final String intervalTime;
  final double quarterNoteBpm;

  const MetronomeDisplay({
    super.key,
    required this.bpm,
    required this.note,
    required this.intervalTime,
    required this.quarterNoteBpm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildBpmDisplay(context),
        const SizedBox(height: 12),
        _buildNoteDisplay(context),
        const SizedBox(height: 16),
        _buildQuarterNoteEquivalent(context),
      ],
    );
  }

  Widget _buildBpmDisplay(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bpmValue = bpm.toStringAsFixed(
      context.read<SettingsModel>().numDecimal,
    );

    return Column(
      children: [
        Text(
          AppLocalizations.of(context)!.bpm,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            bpmValue,
            key: ValueKey<String>(bpmValue),
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteDisplay(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildInfoBadge(
          context,
          icon: Icons.music_note_rounded,
          label: AppLocalizations.of(context)!.getTranslation(note),
        ),
        _buildInfoBadge(
          context,
          icon: Icons.timelapse_rounded,
          label: intervalTime,
        ),
      ],
    );
  }

  Widget _buildQuarterNoteEquivalent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final equivalent = quarterNoteBpm.toStringAsFixed(
      context.read<SettingsModel>().numDecimal,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: [
          Icon(Icons.graphic_eq_rounded, size: 20, color: colorScheme.primary),
          Text(
            AppLocalizations.of(context)!.quarterNoteEquivalent(equivalent),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
