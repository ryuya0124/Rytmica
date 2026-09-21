import 'package:flutter/material.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';

import '../../../UI/unit_dropdown.dart';

class UnitSwitchSection extends StatelessWidget {
  final String selectedUnit;
  final List<String> units;
  final ValueChanged<String> onChanged;

  const UnitSwitchSection({
    super.key,
    required this.selectedUnit,
    required this.units,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 画面幅が狭い場合は縦並び、広い場合は横並び
          final isNarrow = constraints.maxWidth < 300;

          if (isNarrow) {
            // 縦並び: テキスト左寄せ、ボタン右寄せ
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppLocalizations.of(context)!.time_unit,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: UnitDropdown(
                    selectedUnit: selectedUnit,
                    units: units,
                    onChanged: onChanged,
                  ),
                ),
              ],
            );
          } else {
            // 横並び: 全体右寄せ
            return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  AppLocalizations.of(context)!.time_unit,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                UnitDropdown(
                  selectedUnit: selectedUnit,
                  units: units,
                  onChanged: onChanged,
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
