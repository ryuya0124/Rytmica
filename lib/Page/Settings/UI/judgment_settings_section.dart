import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';

import '../../../ParamData/settings_model.dart';
import '../../../ParamData/judgment.dart';
import 'settings_section_card.dart';

class JudgmentSettingsSection extends StatelessWidget {
  const JudgmentSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionCard(
          title: loc.judgment_presets,
          child: const JudgmentPresetContent(),
        ),
        SettingsSectionCard(
          title: loc.custom_preset_section_title,
          child: const CustomPresetForm(),
        ),
      ],
    );
  }
}

class JudgmentPresetContent extends StatelessWidget {
  const JudgmentPresetContent({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsModel = context.watch<SettingsModel>();
    final grouped = settingsModel.judgmentPresetsByGame;
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final decimals = settingsModel.numDecimal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (grouped.isEmpty)
          Text(
            loc.no_presets_available,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ...grouped.entries.map(
          (MapEntry<String, List<JudgmentPreset>> entry) => RepaintBoundary(
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              color: colorScheme.surfaceContainer,
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                title: Text(entry.key),
                children: entry.value
                    .map(
                      (preset) => ListTile(
                        title: Text(preset.label),
                        subtitle: Text(
                          preset.isCustom
                              ? 'Late +${preset.lateMs.toStringAsFixed(decimals)} ms / Early -${preset.earlyMs.toStringAsFixed(decimals)} ms | ${loc.total_window_label}: ${preset.totalWindowMs.toStringAsFixed(decimals)} ms'
                              : 'Late +${preset.lateMs.toStringAsFixed(decimals)} ms / Early -${preset.earlyMs.toStringAsFixed(decimals)} ms',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Tooltip(
                              message: loc.preset_visibility_toggle,
                              child: Switch.adaptive(
                                value: !context
                                    .watch<SettingsModel>()
                                    .isPresetHidden(preset.id),
                                onChanged: (value) {
                                  context
                                      .read<SettingsModel>()
                                      .setPresetVisibility(preset.id, value);
                                },
                                activeTrackColor: colorScheme.primary,
                              ),
                            ),
                            if (preset.isCustom) ...[
                              IconButton(
                                tooltip: loc.edit_preset,
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _showEditPresetDialog(context, preset);
                                },
                              ),
                              IconButton(
                                tooltip: loc.delete,
                                icon: Icon(
                                  Icons.delete,
                                  color: colorScheme.error,
                                ),
                                onPressed: () {
                                  context
                                      .read<SettingsModel>()
                                      .removeCustomJudgmentPreset(preset.id);
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showEditPresetDialog(BuildContext context, JudgmentPreset preset) {
    final loc = AppLocalizations.of(context)!;

    final gameController = TextEditingController(text: preset.game);
    final labelController = TextEditingController(text: preset.label);
    final earlyController = TextEditingController(
      text: preset.earlyMs.toString(),
    );
    final lateController = TextEditingController(
      text: preset.lateMs.toString(),
    );
    bool linkWindowValues = preset.earlyMs == preset.lateMs;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(loc.edit_preset),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: gameController,
                      decoration: InputDecoration(
                        labelText: loc.game_name_label,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: labelController,
                      decoration: InputDecoration(
                        labelText: loc.judgment_name_label,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: Text(loc.link_early_late_values),
                      value: linkWindowValues,
                      onChanged: (value) {
                        setState(() {
                          linkWindowValues = value ?? false;
                          if (linkWindowValues) {
                            lateController.text = earlyController.text;
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: earlyController,
                            decoration: InputDecoration(
                              labelText: linkWindowValues
                                  ? loc.timingWindow
                                  : loc.early_window_label,
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (text) {
                              if (linkWindowValues) {
                                lateController.text = text;
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (!linkWindowValues)
                          Expanded(
                            child: TextField(
                              controller: lateController,
                              decoration: InputDecoration(
                                labelText: loc.late_window_label,
                                border: const OutlineInputBorder(),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(loc.cancel),
                ),
                TextButton(
                  onPressed: () {
                    final game = gameController.text.trim();
                    final label = labelController.text.trim();
                    final early = double.tryParse(earlyController.text);
                    final late = double.tryParse(lateController.text);

                    if (game.isNotEmpty &&
                        label.isNotEmpty &&
                        early != null &&
                        late != null) {
                      context.read<SettingsModel>().updateCustomJudgmentPreset(
                        presetId: preset.id,
                        game: game,
                        label: label,
                        earlyMs: early,
                        lateMs: late,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: Text(loc.save_changes),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class CustomPresetForm extends StatefulWidget {
  const CustomPresetForm({super.key});

  @override
  State<CustomPresetForm> createState() => _CustomPresetFormState();
}

class _CustomPresetFormState extends State<CustomPresetForm> {
  final TextEditingController presetGameController = TextEditingController();
  final TextEditingController presetLabelController = TextEditingController();
  final TextEditingController presetEarlyController = TextEditingController(
    text: '50',
  );
  final TextEditingController presetLateController = TextEditingController(
    text: '50',
  );
  bool linkWindowValues = true;

  @override
  void dispose() {
    presetGameController.dispose();
    presetLabelController.dispose();
    presetEarlyController.dispose();
    presetLateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final bool isButtonEnabled =
        presetGameController.text.trim().isNotEmpty &&
        presetLabelController.text.trim().isNotEmpty &&
        double.tryParse(presetEarlyController.text.trim()) != null &&
        (linkWindowValues ||
            double.tryParse(presetLateController.text.trim()) != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: presetGameController,
          decoration: InputDecoration(
            labelText: loc.game_name_label,
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: colorScheme.primary),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: presetLabelController,
          decoration: InputDecoration(
            labelText: loc.judgment_name_label,
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: colorScheme.primary),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: presetEarlyController,
                decoration: InputDecoration(
                  labelText: linkWindowValues
                      ? loc.timingWindow
                      : loc.early_window_label,
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: colorScheme.primary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) {
                  if (linkWindowValues) {
                    presetLateController.text = presetEarlyController.text;
                  }
                  setState(() {});
                },
              ),
            ),
            const SizedBox(width: 12),
            if (!linkWindowValues)
              Expanded(
                child: TextField(
                  controller: presetLateController,
                  decoration: InputDecoration(
                    labelText: loc.late_window_label,
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: colorScheme.primary),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
          ],
        ),
        CheckboxListTile(
          title: Text(loc.link_early_late_values),
          value: linkWindowValues,
          onChanged: (value) {
            setState(() {
              linkWindowValues = value ?? true;
              if (linkWindowValues) {
                presetLateController.text = presetEarlyController.text;
              }
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: isButtonEnabled
                ? () {
                    final game = presetGameController.text.trim();
                    final label = presetLabelController.text.trim();
                    final early = double.tryParse(
                      presetEarlyController.text.trim(),
                    );
                    final late = linkWindowValues
                        ? early
                        : double.tryParse(presetLateController.text.trim());

                    if (game.isNotEmpty &&
                        label.isNotEmpty &&
                        early != null &&
                        late != null) {
                      context.read<SettingsModel>().addCustomJudgmentPreset(
                        game: game,
                        label: label,
                        earlyMs: early,
                        lateMs: late,
                      );

                      // フォームのクリア
                      presetGameController.clear();
                      presetLabelController.clear();
                      presetEarlyController.text = '50';
                      presetLateController.text = '50';
                      setState(() {});

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(loc.preset_added)),
                      );
                    }
                  }
                : null,
            icon: const Icon(Icons.add),
            label: Text(loc.add_preset),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
