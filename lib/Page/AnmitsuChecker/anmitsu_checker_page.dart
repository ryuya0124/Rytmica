import 'package:flutter/material.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../ParamData/judgment.dart';
import '../../ParamData/settings_model.dart';
import '../../UI/bpm_input_section.dart';
import 'Logic/anmitsu_logic.dart';
import 'Logic/anmitsu_models.dart';
import 'UI/judgment_diagram.dart';
import 'UI/result_display.dart';

class AnmituCheckerPage extends StatefulWidget {
  final TextEditingController bpmController;
  final FocusNode bpmFocusNode;

  const AnmituCheckerPage({
    super.key,
    required this.bpmController,
    required this.bpmFocusNode,
  });

  @override
  State<AnmituCheckerPage> createState() => AnmituCheckerPageState();
}

class AnmituCheckerPageState extends State<AnmituCheckerPage> {
  // 状態変数
  String? selectedGame;
  String? selectedEarlyPresetId;
  String? selectedLatePresetId;

  bool isDotted = false;
  final TextEditingController noteController = TextEditingController(
    text: '16',
  );
  final FocusNode noteFocusNode = FocusNode();

  // 表示モード (0: Table, 1: Diagram)
  int _selectedViewIndex = 0;

  // 計算結果
  AnmituCalcResult? _calcResult;
  List<ResultRow> _resultRows = [];
  String? _statusMessage;

  TextEditingController get bpmController => widget.bpmController;

  @override
  void initState() {
    super.initState();
    // 初期計算
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateAnmitu();
    });

    // リスナー登録
    bpmController.addListener(_calculateAnmitu);
    noteController.addListener(_calculateAnmitu);
  }

  @override
  void dispose() {
    bpmController.removeListener(_calculateAnmitu);
    noteController.removeListener(_calculateAnmitu);
    noteController.dispose();
    noteFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsModel = context.watch<SettingsModel>();
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    // プリセットの変更を監視して同期
    final selection = AnmitsuLogic.resolveSelection(
      settingsModel.visibleJudgmentPresetsByGame,
      selectedGame,
      selectedEarlyPresetId,
      selectedLatePresetId,
      syncState: true,
      onSync: (nextGame, nextEarly, nextLate) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            selectedGame = nextGame;
            selectedEarlyPresetId = nextEarly?.id;
            selectedLatePresetId = nextLate?.id;
          });
          _calculateAnmitu();
        });
      },
    );

    return Scaffold(
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 画面幅が800px以上の場合は横並びレイアウト
            final isWideScreen = constraints.maxWidth >= 800;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWideScreen ? double.infinity : 800,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ノーツ入力セクション
                      buildNoteInputSection(),
                      const SizedBox(height: 16),
                      // ゲーム・プリセット切り替えセクション
                      buildGameSwitchSection(
                        selection,
                        settingsModel.visibleJudgmentPresetsByGame,
                      ),
                      const SizedBox(height: 16),
                      // 広い画面では横並び、狭い画面ではタブ切り替え
                      if (isWideScreen) ...[
                        // 横並びレイアウト
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: buildResultSection(colorScheme),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: buildDiagramSection(
                                colorScheme,
                                settingsModel.numDecimal,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // タブ切り替えレイアウト
                        buildViewToggle(loc, colorScheme),
                        const SizedBox(height: 16),
                        if (_selectedViewIndex == 0)
                          buildResultSection(colorScheme)
                        else
                          buildDiagramSection(
                            colorScheme,
                            settingsModel.numDecimal,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildViewToggle(AppLocalizations loc, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SegmentedButton<int>(
          segments: [
            ButtonSegment(
              value: 0,
              icon: const Icon(Icons.table_chart),
              label: Text(loc.viewTable),
            ),
            ButtonSegment(
              value: 1,
              icon: const Icon(Icons.schema),
              label: Text(loc.viewDiagram),
            ),
          ],
          selected: {_selectedViewIndex},
          onSelectionChanged: (Set<int> selected) {
            setState(() {
              _selectedViewIndex = selected.first;
            });
          },
        ),
      ),
    );
  }

  Widget buildNoteInputSection() {
    final loc = AppLocalizations.of(context)!;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          BpmInputSection(
            bpmController: noteController,
            bpmFocusNode: noteFocusNode,
            label: loc.input_notes,
          ),
          SwitchListTile(
            value: isDotted,
            onChanged: (value) {
              setState(() {
                isDotted = value;
              });
              _calculateAnmitu();
            },
            title: Text(loc.dotted_note),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildGameSwitchSection(
    SelectionSnapshot selection,
    Map<String, List<JudgmentPreset>> grouped,
  ) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final gameItems = grouped.keys.toList();
    final hasPresets = selection.game != null && selection.presets.isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.judgment_presets,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (hasPresets) ...[
              DropdownButtonFormField<String>(
                initialValue: selection.game,
                decoration: InputDecoration(
                  labelText: loc.select_game,
                  border: const OutlineInputBorder(),
                ),
                items: gameItems
                    .map(
                      (game) => DropdownMenuItem(
                        value: game,
                        child: Text(game),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedGame = value;
                    selectedEarlyPresetId = null;
                    selectedLatePresetId = null;
                  });
                  _calculateAnmitu();
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selection.earlyPreset?.id,
                decoration: InputDecoration(
                  labelText: loc.early_window_label,
                  border: const OutlineInputBorder(),
                ),
                items: selection.presets
                    .map(
                      (preset) => DropdownMenuItem(
                        value: preset.id,
                        child: Text(preset.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedEarlyPresetId = value;
                  });
                  _calculateAnmitu();
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selection.latePreset?.id,
                decoration: InputDecoration(
                  labelText: loc.late_window_label,
                  border: const OutlineInputBorder(),
                ),
                items: selection.presets
                    .map(
                      (preset) => DropdownMenuItem(
                        value: preset.id,
                        child: Text(preset.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedLatePresetId = value;
                  });
                  _calculateAnmitu();
                },
              ),
            ] else ...[
              Text(
                loc.no_presets_available,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(
                loc.custom_preset_section_title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildResultSection(ColorScheme colorScheme) {
    final loc = AppLocalizations.of(context)!;
    final message =
        _statusMessage ??
        (_resultRows.isEmpty ? loc.no_Results_Available : null);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.3),
            colorScheme.secondaryContainer.withValues(alpha: 0.2),
          ],
        ),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: message != null
              ? _buildPlaceholder(message, colorScheme)
              : Column(
                  children: [
                    for (int i = 0; i < _resultRows.length; i++) ...[
                      ResultTile(row: _resultRows[i]),
                      if (i < _resultRows.length - 1)
                        Divider(
                          height: 24,
                          thickness: 0.5,
                          color: colorScheme.outline.withValues(alpha: 0.3),
                        ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget buildDiagramSection(ColorScheme colorScheme, int decimals) {
    final loc = AppLocalizations.of(context)!;

    if (_calcResult == null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.tertiaryContainer.withValues(alpha: 0.3),
              colorScheme.secondaryContainer.withValues(alpha: 0.2),
            ],
          ),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildPlaceholder(loc.no_Results_Available, colorScheme),
          ),
        ),
      );
    }

    final result = _calcResult!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.tertiaryContainer.withValues(alpha: 0.3),
            colorScheme.secondaryContainer.withValues(alpha: 0.2),
          ],
        ),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.viewDiagram,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              JudgmentDiagram(
                result: result,
                decimals: decimals,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String message, ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
    );
  }

  void _calculateAnmitu() {
    if (!mounted) return;
    final settingsModel = context.read<SettingsModel>();
    final selection = AnmitsuLogic.resolveSelection(
      settingsModel.visibleJudgmentPresetsByGame,
      selectedGame,
      selectedEarlyPresetId,
      selectedLatePresetId,
    );

    final bpm = double.tryParse(bpmController.text) ?? 0;
    final noteType = double.tryParse(noteController.text) ?? 0;

    final result = AnmitsuLogic.calculateResult(
      selection: selection,
      bpm: bpm,
      noteType: noteType,
      isDotted: isDotted,
    );

    if (result == null) {
      setState(() {
        _statusMessage =
            (selection.earlyPreset == null || selection.latePreset == null)
            ? AppLocalizations.of(context)!.no_presets_available
            : AppLocalizations.of(context)!.invalid_BPM_or_Note_Type;
        _resultRows = [];
        _calcResult = null;
      });
      return;
    }

    final loc = AppLocalizations.of(context)!;
    final decimals = settingsModel.numDecimal;

    setState(() {
      _statusMessage = null;
      _calcResult = result;
      _resultRows = [
        ResultRow(
          title: loc.selected_preset,
          value:
              '${result.gameName}\n${result.earlyPresetLabel} / ${result.latePresetLabel}',
        ),
        ResultRow(
          title: loc.timingWindow,
          value:
              '-${result.windowEarly.toStringAsFixed(decimals)} ms / +${result.windowLate.toStringAsFixed(decimals)} ms',
        ),
        ResultRow(
          title: loc.early_window_label,
          value:
              '-${result.windowEarly.toStringAsFixed(decimals)} ms (${result.earlyPresetLabel})',
        ),
        ResultRow(
          title: loc.late_window_label,
          value:
              '+${result.windowLate.toStringAsFixed(decimals)} ms (${result.latePresetLabel})',
        ),
        ResultRow(
          title: loc.total_window_label,
          value: '${result.totalWindow.toStringAsFixed(decimals)} ms',
        ),
        ResultRow(
          title: loc.note_length,
          value: '${result.noteLengthMs.toStringAsFixed(decimals)} ms',
        ),
        ResultRow(
          title: loc.anmitsu_value,
          value: '±${result.anmituValue.toStringAsFixed(decimals)} ms',
          valueColor: result.color,
        ),
        ResultRow(
          title: loc.difficulty,
          value: AnmitsuLogic.getResultText(context, result.anmituValue),
          valueColor: result.color,
        ),
      ];
    });
  }
}
