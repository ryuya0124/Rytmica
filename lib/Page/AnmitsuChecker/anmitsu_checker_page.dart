import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../ParamData/judgment.dart';
import '../../ParamData/settings_model.dart';
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
  static const _quickNotes = [4, 8, 12, 16, 24, 32];

  String? selectedGame;
  String? selectedEarlyPresetId;
  String? selectedLatePresetId;
  bool isDotted = false;
  int _selectedViewIndex = const int.fromEnvironment(
    'RYTMICA_SCREENSHOT_ANMITSU_VIEW',
    defaultValue: 0,
  );

  final TextEditingController noteController = TextEditingController(
    text: '16',
  );
  final FocusNode noteFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  static const bool _screenshotScrollToResult = bool.fromEnvironment(
    'RYTMICA_SCREENSHOT_SCROLL_RESULT',
  );

  AnmituCalcResult? _calcResult;
  List<ResultRow> _resultRows = [];
  String? _statusMessage;

  TextEditingController get bpmController => widget.bpmController;

  @override
  void initState() {
    super.initState();
    bpmController.addListener(_calculateAnmitu);
    noteController.addListener(_calculateAnmitu);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateAnmitu();
      if (_screenshotScrollToResult) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients) {
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    bpmController.removeListener(_calculateAnmitu);
    noteController.removeListener(_calculateAnmitu);
    noteController.dispose();
    noteFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsModel>();
    final loc = AppLocalizations.of(context)!;
    final grouped = settings.visibleJudgmentPresetsByGame;
    final selection = AnmitsuLogic.resolveSelection(
      grouped,
      selectedGame,
      selectedEarlyPresetId,
      selectedLatePresetId,
      syncState: true,
      onSync: _syncSelection,
    );

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 960;
            return SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                isWide ? 28 : 16,
                20,
                isWide ? 28 : 16,
                40,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHero(loc),
                      const SizedBox(height: 20),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 390,
                              child: _buildControls(selection, grouped, loc),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildResultSection(loc),
                                  const SizedBox(height: 20),
                                  _buildDiagramSection(
                                    loc,
                                    settings.numDecimal,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      else ...[
                        _buildControls(selection, grouped, loc),
                        const SizedBox(height: 20),
                        _buildViewToggle(loc),
                        const SizedBox(height: 12),
                        if (_selectedViewIndex == 0)
                          _buildResultSection(loc)
                        else
                          _buildDiagramSection(loc, settings.numDecimal),
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

  Widget _buildHero(AppLocalizations loc) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bpm = bpmController.text.trim().isEmpty
        ? '—'
        : bpmController.text.trim();
    final result = _calcResult;
    final statusColor = result == null
        ? colors.onSurfaceVariant
        : result.isPossible
        ? colors.primary
        : colors.error;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: .42),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.primary.withValues(alpha: .16)),
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 18,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.layers_rounded, color: colors.primary),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        loc.anmitu,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  loc.anmitsuPageSubtitle,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  loc.anmitsuHowTo,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: .74),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.speed_rounded, color: colors.primary),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.currentBpm, style: theme.textTheme.labelMedium),
                    Text(
                      bpm,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                if (result != null) ...[
                  const SizedBox(width: 16),
                  Container(width: 1, height: 34, color: colors.outlineVariant),
                  const SizedBox(width: 16),
                  Icon(
                    result.isPossible ? Icons.check_circle : Icons.cancel,
                    color: statusColor,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    result.isPossible
                        ? loc.anmitsuPossible
                        : loc.anmitsuImpossible,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(
    SelectionSnapshot selection,
    Map<String, List<JudgmentPreset>> grouped,
    AppLocalizations loc,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          title: loc.noteSubdivision,
          icon: Icons.music_note_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const ValueKey('anmitsu-note-input'),
                controller: noteController,
                focusNode: noteFocusNode,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  labelText: loc.input_notes,
                  prefixText: '1 / ',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                loc.quickSelect,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickNotes.map((note) {
                  final selected = noteController.text == '$note';
                  return ChoiceChip(
                    label: Text('1/$note'),
                    selected: selected,
                    onSelected: (_) {
                      noteController.text = '$note';
                      noteController.selection = TextSelection.collapsed(
                        offset: noteController.text.length,
                      );
                      setState(() {});
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Material(
                color: Colors.transparent,
                child: SwitchListTile.adaptive(
                  value: isDotted,
                  contentPadding: EdgeInsets.zero,
                  title: Text(loc.dotted_note),
                  onChanged: (value) {
                    setState(() => isDotted = value);
                    _calculateAnmitu();
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: loc.judgment_presets,
          icon: Icons.tune_rounded,
          child: _buildPresetFields(selection, grouped, loc),
        ),
      ],
    );
  }

  Widget _buildPresetFields(
    SelectionSnapshot selection,
    Map<String, List<JudgmentPreset>> grouped,
    AppLocalizations loc,
  ) {
    if (selection.game == null || selection.presets.isEmpty) {
      return Text(
        loc.no_presets_available,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }

    return Column(
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('game-${selection.game}'),
          initialValue: selection.game,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: loc.select_game,
            border: const OutlineInputBorder(),
          ),
          items: grouped.keys
              .map((game) => DropdownMenuItem(value: game, child: Text(game)))
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
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          key: ValueKey(
            'earlier-${selection.game}-${selection.earlyPreset?.id}',
          ),
          initialValue: selection.earlyPreset?.id,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: loc.earlierNotePreset,
            prefixIcon: const Icon(Icons.looks_one_outlined),
            border: const OutlineInputBorder(),
          ),
          items: _presetItems(selection.presets),
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedEarlyPresetId = value);
            _calculateAnmitu();
          },
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          key: ValueKey('later-${selection.game}-${selection.latePreset?.id}'),
          initialValue: selection.latePreset?.id,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: loc.laterNotePreset,
            prefixIcon: const Icon(Icons.looks_two_outlined),
            border: const OutlineInputBorder(),
          ),
          items: _presetItems(selection.presets),
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedLatePresetId = value);
            _calculateAnmitu();
          },
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _presetItems(List<JudgmentPreset> presets) {
    return presets
        .map(
          (preset) => DropdownMenuItem(
            value: preset.id,
            child: Text(preset.label, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList();
  }

  Widget _buildViewToggle(AppLocalizations loc) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<int>(
        segments: [
          ButtonSegment(
            value: 0,
            icon: const Icon(Icons.table_rows_rounded),
            label: Text(loc.viewTable),
          ),
          ButtonSegment(
            value: 1,
            icon: const Icon(Icons.timeline_rounded),
            label: Text(loc.viewDiagram),
          ),
        ],
        selected: {_selectedViewIndex},
        showSelectedIcon: false,
        onSelectionChanged: (selection) {
          setState(() => _selectedViewIndex = selection.first);
        },
      ),
    );
  }

  Widget _buildResultSection(AppLocalizations loc) {
    final colors = Theme.of(context).colorScheme;
    final message =
        _statusMessage ??
        (_resultRows.isEmpty ? loc.no_Results_Available : null);

    return _SectionCard(
      title: loc.viewTable,
      icon: Icons.analytics_outlined,
      trailing: _buildStatusBadge(loc),
      child: message != null
          ? _buildPlaceholder(message)
          : Column(
              children: [
                for (var i = 0; i < _resultRows.length; i++) ...[
                  ResultTile(row: _resultRows[i]),
                  if (i < _resultRows.length - 1)
                    Divider(height: 24, color: colors.outlineVariant),
                ],
              ],
            ),
    );
  }

  Widget? _buildStatusBadge(AppLocalizations loc) {
    final result = _calcResult;
    if (result == null) return null;
    final colors = Theme.of(context).colorScheme;
    final color = result.isPossible ? colors.primary : colors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        result.isPossible ? loc.anmitsuPossible : loc.anmitsuImpossible,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildDiagramSection(AppLocalizations loc, int decimals) {
    return _SectionCard(
      title: loc.viewDiagram,
      icon: Icons.timeline_rounded,
      child: _calcResult == null
          ? _buildPlaceholder(_statusMessage ?? loc.no_Results_Available)
          : JudgmentDiagram(result: _calcResult!, decimals: decimals),
    );
  }

  Widget _buildPlaceholder(String message) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          Icon(Icons.info_outline_rounded, color: colors.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  void _syncSelection(
    String? game,
    JudgmentPreset? earlierPreset,
    JudgmentPreset? laterPreset,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        selectedGame = game;
        selectedEarlyPresetId = earlierPreset?.id;
        selectedLatePresetId = laterPreset?.id;
      });
      _calculateAnmitu();
    });
  }

  void _calculateAnmitu() {
    if (!mounted) return;
    final settings = context.read<SettingsModel>();
    final selection = AnmitsuLogic.resolveSelection(
      settings.visibleJudgmentPresetsByGame,
      selectedGame,
      selectedEarlyPresetId,
      selectedLatePresetId,
    );
    final result = AnmitsuLogic.calculateResult(
      selection: selection,
      bpm: double.tryParse(bpmController.text) ?? 0,
      noteType: double.tryParse(noteController.text) ?? 0,
      isDotted: isDotted,
    );
    final loc = AppLocalizations.of(context)!;

    if (result == null) {
      setState(() {
        _statusMessage =
            selection.earlyPreset == null || selection.latePreset == null
            ? loc.no_presets_available
            : loc.invalid_BPM_or_Note_Type;
        _resultRows = [];
        _calcResult = null;
      });
      return;
    }

    final decimals = settings.numDecimal;
    final statusColor = result.isPossible
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;
    String ms(double value) => '${value.toStringAsFixed(decimals)} ms';

    setState(() {
      _statusMessage = null;
      _calcResult = result;
      _resultRows = [
        ResultRow(
          title: loc.earlierNotePreset,
          value: '${result.gameName} · ${result.earlyPresetLabel}',
        ),
        ResultRow(
          title: loc.laterNotePreset,
          value: '${result.gameName} · ${result.latePresetLabel}',
        ),
        ResultRow(
          title: loc.relevantLateWindow,
          value: '+${ms(result.earlierNoteLateWindow)}',
        ),
        ResultRow(
          title: loc.relevantEarlyWindow,
          value: '-${ms(result.laterNoteEarlyWindow)}',
        ),
        ResultRow(
          title: loc.total_window_label,
          value: ms(result.relevantWindowTotal),
        ),
        ResultRow(title: loc.note_length, value: ms(result.noteLengthMs)),
        ResultRow(
          title: loc.actualOverlap,
          value: result.isPossible
              ? ms(result.overlapDurationMs)
              : loc.millisecondsShort(
                  result.shortfallMs.toStringAsFixed(decimals),
                ),
          valueColor: statusColor,
        ),
        ResultRow(
          title: loc.anmitsu_value,
          value: result.isPossible ? '±${ms(result.anmituValue)}' : '—',
          valueColor: statusColor,
        ),
        ResultRow(
          title: loc.difficulty,
          value: AnmitsuLogic.getResultText(context, result.anmituValue),
          valueColor: statusColor,
        ),
      ];
    });
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colors.primary),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}
