import 'package:flutter/material.dart';

/// セグメントボタンスタイルの単位選択ウィジェット
class UnitDropdown extends StatefulWidget {
  final String selectedUnit;
  final List<String> units;
  final ValueChanged<String> onChanged;

  const UnitDropdown({
    super.key,
    required this.selectedUnit,
    required this.units,
    required this.onChanged,
  });

  @override
  UnitDropdownState createState() => UnitDropdownState();
}

class UnitDropdownState extends State<UnitDropdown> {
  late String _currentSelectedUnit;

  @override
  void initState() {
    super.initState();
    _currentSelectedUnit = widget.selectedUnit;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SegmentedButton<String>(
      segments: widget.units.map((unit) {
        return ButtonSegment<String>(
          value: unit,
          label: Text(
            unit,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        );
      }).toList(),
      selected: {_currentSelectedUnit},
      onSelectionChanged: (Set<String> newSelection) {
        setState(() {
          _currentSelectedUnit = newSelection.first;
        });
        widget.onChanged(newSelection.first);
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primaryContainer;
          }
          return colorScheme.surfaceContainerHighest;
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimaryContainer;
          }
          return colorScheme.onSurfaceVariant;
        }),
        side: WidgetStateProperty.all(
          BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      showSelectedIcon: false,
    );
  }
}
