import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../ParamData/settings_model.dart';
import '../Metronome/metronome_page.dart';
import '../../ParamData/notes.dart';
import 'UI/unit_switch_section.dart';
import 'UI/notes_list.dart';
import '../../UI/adaptive_layout.dart';

class HomePage extends StatefulWidget {
  final TextEditingController bpmController; // bpmControllerを保持
  final FocusNode bpmFocusNode; // bpmFocusNodeを保持
  final void Function(double bpm, String note, String interval)?
  onMetronomeRequest;

  const HomePage({
    super.key,
    required this.bpmController,
    required this.bpmFocusNode,
    this.onMetronomeRequest,
  });
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late TextEditingController bpmController;
  late FocusNode bpmFocusNode;
  late String selectedUnit;
  late StreamController<List<Map<String, String>>> _notesStreamController;
  List<String> units = ['auto', 's', 'ms', 'µs'];

  @override
  void initState() {
    super.initState();
    selectedUnit = context.read<SettingsModel>().selectedUnit;
    bpmController = widget.bpmController;
    bpmFocusNode = widget.bpmFocusNode;

    bpmController.addListener(_calculateNotes);
    _notesStreamController =
        StreamController<List<Map<String, String>>>.broadcast();
    WidgetsBinding.instance.addObserver(this);

    // 初期計算をトリガー
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateNotes();
    });
  }

  @override
  void dispose() {
    bpmController.removeListener(_calculateNotes); // リスナーを解除
    _notesStreamController.close(); // StreamControllerを閉じる
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final appBarColor = Theme.of(context).primaryColor; // Unused
    final enabledNotes = context.watch<SettingsModel>().enabledNotes;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: Column(
          children: [
            UnitSwitchSection(
              selectedUnit: selectedUnit,
              units: units,
              onChanged: _handleUnitChange,
            ),
            NotesList(
              notesStream: _notesStreamController.stream,
              enabledNotes: enabledNotes,
              onNoteTap: (note) {
                final bpm = double.tryParse(bpmController.text) ?? 120.0;
                final supportsInlinePanel = AdaptiveLayoutInfo.of(context)
                    .supportsInlinePanel;

                if (supportsInlinePanel && widget.onMetronomeRequest != null) {
                  widget.onMetronomeRequest!(
                    bpm,
                    note['name']!,
                    note['duration']!,
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MetronomePage(
                        bpm: bpm,
                        note: note['name']!,
                        interval: note['duration']!,
                      ),
                    ),
                  ).then((result) {
                    if (!mounted) return;
                    if (result != null &&
                        result is Map &&
                        result['switchToSplit'] == true) {
                      if (widget.onMetronomeRequest != null) {
                        widget.onMetronomeRequest!(
                          bpm,
                          note['name']!,
                          note['duration']!,
                        );
                      }
                    }
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleUnitChange(String newUnit) {
    // selectedUnitの変更を直接StreamControllerに反映
    selectedUnit = newUnit;
    _calculateNotes(); // ユニット変更後にノートの計算を再実行
  }

  void _calculateNotes() {
    final bpmInput = bpmController.text;
    if (bpmInput.isEmpty) {
      _notesStreamController.add([]);
      return;
    }

    final bpm = double.tryParse(bpmInput);
    if (bpm == null || bpm <= 0) {
      _notesStreamController.add([]);
      return;
    }

    final quarterNoteLengthMs = 60000.0 / bpm;

    final notesList = notes.map((note) {
      final double durationMs = calculateNoteLength(
        quarterNoteLengthMs,
        note.note,
        isDotted: note.dotted,
      );

      // auto選択時は値に応じて適切な単位を自動選択
      String displayUnit;
      double conversionFactor;
      if (selectedUnit == 'auto') {
        if (durationMs >= 1000) {
          displayUnit = 's';
          conversionFactor = 1 / 1000.0;
        } else if (durationMs >= 1) {
          displayUnit = 'ms';
          conversionFactor = 1.0;
        } else {
          displayUnit = 'µs';
          conversionFactor = 1000.0;
        }
      } else {
        displayUnit = selectedUnit;
        conversionFactor = selectedUnit == 's'
            ? 1 / 1000.0
            : selectedUnit == 'µs'
            ? 1000.0
            : 1.0;
      }

      return {
        'name': note.name,
        'duration':
            '${(durationMs * conversionFactor).toStringAsFixed(context.read<SettingsModel>().numDecimal)} $displayUnit',
      };
    }).toList();

    _notesStreamController.add(notesList);
  }
}
