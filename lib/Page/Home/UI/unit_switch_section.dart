import 'package:material_ui/material_ui.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';

import '../../../UI/unit_dropdown.dart';

class UnitSwitchSection extends StatelessWidget {
  final String selectedUnit;
  final List<String> units;
  final ValueChanged<String> onChanged;
  final String? label;
  final IconData icon;

  const UnitSwitchSection({
    super.key,
    required this.selectedUnit,
    required this.units,
    required this.onChanged,
    this.label,
    this.icon = Icons.straighten_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          color: colors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 9),
                        Flexible(
                          child: Text(
                            label ?? AppLocalizations.of(context)!.time_unit,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: UnitDropdown(
                          selectedUnit: selectedUnit,
                          units: units,
                          onChanged: onChanged,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
