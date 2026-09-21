import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';

import '../../../ParamData/settings_model.dart';
import '../../../UI/numeric_input_column.dart';
import 'settings_section_card.dart';

class AdvancedSettingsSection extends StatefulWidget {
  const AdvancedSettingsSection({super.key});

  @override
  State<AdvancedSettingsSection> createState() =>
      _AdvancedSettingsSectionState();
}

class _AdvancedSettingsSectionState extends State<AdvancedSettingsSection> {
  late int decimalValue;
  late TextEditingController decimalsController;
  final FocusNode decimalsFocusNode = FocusNode();

  late double deltaValue;
  late TextEditingController deltaValueController;
  final FocusNode deltaValueFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final settingsModel = context.read<SettingsModel>();
    decimalValue = settingsModel.numDecimal;
    decimalsController = TextEditingController(
      text: decimalValue.toStringAsFixed(0),
    );

    deltaValue = settingsModel.deltaValue;
    deltaValueController = TextEditingController(
      text: deltaValue.toStringAsFixed(settingsModel.numDecimal),
    );
  }

  @override
  void dispose() {
    decimalsController.dispose();
    decimalsFocusNode.dispose();
    deltaValueController.dispose();
    deltaValueFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 小数桁数セクション
        SettingsSectionCard(
          title: loc.decimal_places,
          child: NumericInputColumnWidget(
            controller: decimalsController,
            focusNode: decimalsFocusNode,
            titleText: '',
            onChanged: (value) {
              setState(() {
                decimalValue = int.tryParse(value) ?? 0;
              });
              if (decimalValue < 1000 && decimalValue >= 0) {
                context.read<SettingsModel>().setNumDecimal(decimalValue);
              }
            },
            onIncrement: () {
              setState(() {
                if (decimalValue < 1000) {
                  decimalValue++;
                  decimalsController.text = decimalValue.toString();
                }
              });
              context.read<SettingsModel>().setNumDecimal(decimalValue);
            },
            onDecrement: () {
              setState(() {
                if (decimalValue > 0) {
                  decimalValue--;
                  decimalsController.text = decimalValue.toString();
                }
              });
              context.read<SettingsModel>().setNumDecimal(decimalValue);
            },
          ),
        ),
        // 増減値セクション
        SettingsSectionCard(
          title: loc.deltaValue,
          child: NumericInputColumnWidget(
            controller: deltaValueController,
            focusNode: deltaValueFocusNode,
            titleText: '',
            onChanged: (value) {
              setState(() {
                deltaValue = double.tryParse(value) ?? 1;
              });
              context.read<SettingsModel>().setDeltaValue(deltaValue);
            },
            onIncrement: () {
              setState(() {
                deltaValue++;
                deltaValueController.text = deltaValue.toString();
              });
              context.read<SettingsModel>().setDeltaValue(deltaValue);
            },
            onDecrement: () {
              setState(() {
                if (deltaValue > 0) {
                  deltaValue--;
                  deltaValueController.text = deltaValue.toString();
                }
              });
              context.read<SettingsModel>().setDeltaValue(deltaValue);
            },
          ),
        ),
      ],
    );
  }
}
