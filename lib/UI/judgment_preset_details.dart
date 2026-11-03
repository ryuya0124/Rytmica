import 'package:material_ui/material_ui.dart';

import '../ParamData/judgment.dart';
import '../l10n/app_localizations.dart';

/// Keep a reference's conditions beside the value, including on small screens.
class JudgmentPresetDetails extends StatelessWidget {
  final JudgmentPreset preset;
  final int decimals;

  const JudgmentPresetDetails({
    super.key,
    required this.preset,
    required this.decimals,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final reference = preset.context;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.preset_window_range(
            preset.earlyMs.toStringAsFixed(decimals),
            preset.lateMs.toStringAsFixed(decimals),
          ),
        ),
        if (preset.isCustom)
          Text(
            '${loc.total_window_label}: ${preset.totalWindowMs.toStringAsFixed(decimals)} ms',
          ),
        if (reference != null) ...[
          const SizedBox(height: 4),
          Text(
            reference.describe(Localizations.localeOf(context).languageCode),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
