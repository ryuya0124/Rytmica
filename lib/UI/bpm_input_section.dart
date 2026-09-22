import 'package:flutter/material.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../ParamData/settings_model.dart';

class BpmInputSection extends StatelessWidget {
  final TextEditingController bpmController;
  final FocusNode bpmFocusNode;
  final String? label;

  const BpmInputSection({
    super.key,
    required this.bpmController,
    required this.bpmFocusNode,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final labelText = label ?? AppLocalizations.of(context)!.bpm_input;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(Icons.speed_rounded, color: colors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: bpmController,
                    focusNode: bpmFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      labelText: labelText,
                      suffixText: 'BPM',
                      isDense: true,
                      filled: true,
                      fillColor: colors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: BorderSide(color: colors.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: BorderSide(color: colors.primary, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StepButton(
                  icon: Icons.remove_rounded,
                  tooltip: '-${context.read<SettingsModel>().deltaValue}',
                  onPressed: () => _changeValue(context, -1),
                ),
                const SizedBox(width: 6),
                _StepButton(
                  icon: Icons.add_rounded,
                  tooltip: '+${context.read<SettingsModel>().deltaValue}',
                  onPressed: () => _changeValue(context, 1),
                  emphasized: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _changeValue(BuildContext context, int direction) {
    final settings = context.read<SettingsModel>();
    final current = double.tryParse(bpmController.text) ?? 0;
    bpmController.text = (current + settings.deltaValue * direction)
        .clamp(0, double.infinity)
        .toStringAsFixed(settings.numDecimal);
    bpmController.selection = TextSelection.collapsed(
      offset: bpmController.text.length,
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool emphasized;

  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButton.filledTonal(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: emphasized
            ? colors.primaryContainer
            : colors.surfaceContainerHighest,
        foregroundColor: emphasized
            ? colors.onPrimaryContainer
            : colors.onSurfaceVariant,
        minimumSize: const Size(44, 44),
      ),
      icon: Icon(icon),
    );
  }
}
