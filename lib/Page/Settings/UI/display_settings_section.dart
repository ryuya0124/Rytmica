import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';

import '../../../ParamData/settings_model.dart';
import '../../../UI/unit_dropdown.dart';
import 'settings_section_card.dart';

class DisplaySettingsSection extends StatelessWidget {
  const DisplaySettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final settingsModel = context.watch<SettingsModel>();
    final List<String> units = ['auto', 's', 'ms', 'µs'];
    final List<String> timeScaleUnits = ['1s', '100ms', '10ms'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 時間単位セクション
        SettingsSectionCard(
          title: loc.time_unit,
          child: UnitDropdown(
            selectedUnit: settingsModel.selectedUnit,
            units: units,
            onChanged: (value) => context.read<SettingsModel>().setUnit(value),
          ),
        ),
        // タイムスケールセクション
        SettingsSectionCard(
          title: loc.timescale,
          child: UnitDropdown(
            selectedUnit: settingsModel.selectedTimeScale,
            units: timeScaleUnits,
            onChanged: (value) =>
                context.read<SettingsModel>().setTimeScale(value),
          ),
        ),
        // Material You セクション (Androidのみ)
        if (Platform.isAndroid && !settingsModel.isDynamicColorAvailable)
          SettingsSectionCard(
            title: loc.materialYou,
            child: SwitchListTile(
              title: Text(loc.materialYou),
              value: settingsModel.useMaterialYou,
              onChanged: (bool value) {
                context.read<SettingsModel>().setMaterialYou(value);
              },
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }
}
