import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';
import 'package:musical_note_calculator/extensions/app_localizations_extension.dart';

import '../ParamData/settings_model.dart';
import '../UI/unit_dropdown.dart';
import '../ParamData/notes.dart';
import '../UI/page_intro_banner.dart';

class NotePage extends StatefulWidget {
  final TextEditingController bpmController; // bpmControllerを保持
  final FocusNode bpmFocusNode; // bpmFocusNodeを保持
  final void Function(double bpm, String note, String interval)?
  onMetronomeRequest;

  const NotePage({
    super.key,
    required this.bpmController, // requiredを使用して必須にする
    required this.bpmFocusNode,
    this.onMetronomeRequest,
  });

  @override
  NotePageState createState() => NotePageState();
}

class NotePageState extends State<NotePage> {
  late TextEditingController bpmController;
  late FocusNode bpmFocusNode;
  late String selectedTimeScale;
  late StreamController<List<Map<String, String>>> _notesStreamController;
  //単位選択
  List<String> units = ['1s', '100ms', '10ms'];

  void _handleUnitChange(String newUnit) {
    setState(() {
      selectedTimeScale = newUnit;
    });
    context.read<SettingsModel>().setTimeScale(newUnit);
    _calculateNotes();
  }

  @override
  void initState() {
    super.initState();
    bpmController = widget.bpmController;
    bpmFocusNode = widget.bpmFocusNode;
    selectedTimeScale = context.read<SettingsModel>().selectedTimeScale;
    bpmController.addListener(_calculateNotes);
    _notesStreamController = StreamController<List<Map<String, String>>>();

    // 初期計算をトリガー
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateNotes();
    });
  }

  @override
  void dispose() {
    bpmController.removeListener(_calculateNotes); // リスナーを解除
    _notesStreamController.close(); // ストリームのクローズ
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appBarColor = Theme.of(context).primaryColor;
    final enabledNotes = context.watch<SettingsModel>().enabledNotes;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: PageIntroBanner(
                    icon: Icons.repeat_rounded,
                    title: AppLocalizations.of(context)!.note_count,
                    subtitle: AppLocalizations.of(context)!.notePageSubtitle,
                  ),
                ),
              ),
            ),
            buildUnitSwitchSection(context),
            // StreamBuilderを使用して状態を監視
            StreamBuilder<List<Map<String, String>>>(
              stream: _notesStreamController.stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // エラーが発生した場合
                  return Center(
                    child: Text(
                      AppLocalizations.of(context)!.error,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return buildNotesList(
                    enabledNotes,
                    appBarColor,
                    snapshot.data!,
                  );
                } else {
                  // データがない場合、縦方向にも中央にメッセージを表示
                  return Expanded(
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.note_instruction,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ユニット切り替えセクション
  Widget buildUnitSwitchSection(BuildContext context) {
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
            child: Row(
              children: [
                Icon(Icons.timelapse_rounded, color: colors.primary, size: 20),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.timescale,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                UnitDropdown(
                  selectedUnit: selectedTimeScale,
                  units: units,
                  onChanged: _handleUnitChange,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildNotesList(
    Map<String, bool> enabledNotes,
    Color appBarColor,
    List<Map<String, String>> notes,
  ) {
    // 有効な音符のみをフィルタリング
    final filteredNotes = notes
        .where((note) => enabledNotes[note['name']] == true)
        .toList();

    return Expanded(
      child: bpmController.text.isEmpty || filteredNotes.isEmpty
          ? Center(child: Text(AppLocalizations.of(context)!.note_instruction))
          : LayoutBuilder(
              builder: (context, constraints) {
                // 画面幅（constraints.maxWidth）に基づいて列数を決定
                // カードの最小幅を基準に動的に計算
                final double width = constraints.maxWidth;
                const double minCardWidth = 280.0;
                final int crossAxisCount = (width / minCardWidth).floor().clamp(
                  1,
                  4,
                );

                // カラムごとにリストを分割して、それぞれのカラムで縦に並べる
                final List<List<Map<String, String>>> columns = List.generate(
                  crossAxisCount,
                  (_) => [],
                );

                for (var i = 0; i < filteredNotes.length; i++) {
                  columns[i % crossAxisCount].add(filteredNotes[i]);
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1240),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(crossAxisCount, (colIndex) {
                          return Expanded(
                            child: Column(
                              children: columns[colIndex].map((note) {
                                return buildNoteCard(
                                  note,
                                  appBarColor,
                                  context,
                                );
                              }).toList(),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  // パフォーマンス最適化: 静的定数
  static const _cardBorderRadius = BorderRadius.all(Radius.circular(16));
  static const _iconBorderRadius = BorderRadius.all(Radius.circular(12));
  static const _cardPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 14,
  );
  static const _cardMargin = EdgeInsets.symmetric(vertical: 4, horizontal: 4);
  static const _iconSize = 44.0;
  static const _frequencyIcon = Icon(Icons.graphic_eq_rounded, size: 24);

  Widget buildNoteCard(
    Map<String, String> note,
    Color appBarColor,
    BuildContext context,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    // noteマップから必要な情報を取得 (idがない場合はデフォルトで'4'を使用などの安全策)
    final noteName = note['name']!;
    final duration = note['duration']!;

    return Container(
      margin: _cardMargin,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: _cardBorderRadius,
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: _cardPadding,
        child: Row(
          children: [
            // 周波数アイコン
            Container(
              width: _iconSize,
              height: _iconSize,
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: _iconBorderRadius,
              ),
              child: IconTheme(
                data: IconThemeData(color: colorScheme.onSecondaryContainer),
                child: _frequencyIcon,
              ),
            ),
            const SizedBox(width: 14),
            // テキスト部分
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.getTranslation(noteName),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: colorScheme.onSurface,
                      letterSpacing: 0.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    duration,
                    style: TextStyle(
                      color: colorScheme.secondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _calculateNotes() {
    final bpmInput = bpmController.text;
    if (bpmInput.isEmpty) {
      _notesStreamController.sink.add([]);
      return;
    }

    final bpm = double.tryParse(bpmInput);
    if (bpm == null || bpm <= 0) {
      _notesStreamController.sink.add([]);
      return;
    }

    final conversionFactor = selectedTimeScale == '1s'
        ? 60.0 // 1秒の場合は60
        : selectedTimeScale == '100ms'
        ? 10 *
              60 // 1ms
        : selectedTimeScale == '10ms'
        ? 100 *
              60 // 1µs
        : 60.0; // その他の場合は60.0

    final notesList = notes.map((note) {
      // ノートの間隔を計算
      final noteLength = calculateNoteFrequency(
        bpm,
        conversionFactor,
        note.note,
        isDotted: note.dotted,
      );

      // フォーマットしてリストに追加
      return <String, String>{
        'name': note.name,
        'id': note.note.toString(),
        'duration': _formatDuration(noteLength),
      };
    }).toList();

    _notesStreamController.sink.add(notesList);
  }

  String _formatDuration(double duration) {
    final value = duration.toStringAsFixed(
      context.read<SettingsModel>().numDecimal,
    );
    return AppLocalizations.of(context)!.noteCountValue(value);
  }
}
