import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';
import 'package:musical_note_calculator/extensions/app_localizations_extension.dart';
import '../ParamData/notes.dart';
import '../ParamData/settings_model.dart';
import 'Metronome/metronome_page.dart';

class CalculatorPage extends StatefulWidget {
  final TextEditingController bpmController; // bpmControllerを保持
  final FocusNode bpmFocusNode; // bpmFocusNodeを保持
  final void Function(double bpm, String note, String interval)? onMetronomeRequest;

  const CalculatorPage({
    super.key,
    required this.bpmController, // requiredを使用して必須にする
    required this.bpmFocusNode,
    this.onMetronomeRequest,
  });

  @override
  CalculatorPageState createState() => CalculatorPageState();
}

class CalculatorPageState extends State<CalculatorPage> {
  late TextEditingController bpmController;
  late FocusNode bpmFocusNode;
  late StreamController<Map<String, List<Map<String, String>>>>
      _notesStreamController;
  final Map<String, StreamController<bool>> _expansionControllers = {};

  @override
  void initState() {
    super.initState();
    bpmController = widget.bpmController;
    bpmFocusNode = widget.bpmFocusNode;
    bpmController.addListener(_calculateNotes);
    _notesStreamController =
        StreamController<Map<String, List<Map<String, String>>>>();
    
    // 初期計算をトリガー
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateNotes();
    });
  }

  @override
  void dispose() {
    bpmController.removeListener(_calculateNotes); // リスナーを解除
    _notesStreamController.close();
    _expansionControllers.forEach((key, controller) {
      controller.close();
    });
    super.dispose();
  }

  // BPMと音符の計算
  void _calculateNotes() {
    final bpmInput = bpmController.text;
    if (bpmInput.isEmpty) {
      _notesStreamController.add({});
      return;
    }

    final bpm = double.tryParse(bpmInput);
    if (bpm == null || bpm <= 0) {
      _notesStreamController.add({});
      return;
    }

    final Map<String, List<Map<String, String>>> calculatedNotes = {};

    for (var baseNote in notes) {
      calculatedNotes[baseNote.name] = notes.map((targetNote) {
        final double targetBPM =
            calculateNoteBPM(bpm, baseNote, targetNote);
        return {
          'note': targetNote.name,
          'bpm': targetBPM
              .toStringAsFixed(context.read<SettingsModel>().numDecimal),
        };
      }).toList();
    }

    // 結果をStreamに送信
    _notesStreamController.add(calculatedNotes);
  }

  // パフォーマンス最適化: 静的定数
  static const _cardBorderRadius = BorderRadius.all(Radius.circular(16));
  static const _iconBorderRadius = BorderRadius.all(Radius.circular(12));
  static const _cardPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
  static const _cardMargin = EdgeInsets.symmetric(vertical: 6, horizontal: 16);
  static const _iconSize = 44.0;
  static const _calcIcon = Icon(Icons.calculate_rounded, size: 24);
  static const _speedIcon = Icon(Icons.speed_rounded, size: 14);


  Widget _buildNoteCard(String noteName, String bpm, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: _cardMargin,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: _cardBorderRadius,
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: _cardPadding,
        child: Row(
          children: [
            // 計算アイコン
            Container(
              width: _iconSize,
              height: _iconSize,
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: _iconBorderRadius,
              ),
              child: IconTheme(
                data: IconThemeData(color: colorScheme.onTertiaryContainer),
                child: _calcIcon,
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
                  Row(
                    children: [
                      IconTheme(
                        data: IconThemeData(color: colorScheme.tertiary),
                        child: _speedIcon,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'BPM: $bpm',
                          style: TextStyle(
                            color: colorScheme.tertiary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 展開状態を管理するStreamを返す
  Stream<bool> _getExpansionStream(String title) {
    if (!_expansionControllers.containsKey(title)) {
      _expansionControllers[title] = StreamController<bool>.broadcast();
    }
    return _expansionControllers[title]!.stream;
  }

  // 展開状態を更新するメソッド
  void _toggleExpansion(String title, bool expanded) {
    final controller = _expansionControllers[title];
    controller?.add(expanded); // 状態を更新
  }

  // 折りたたみボタン用のウィジェット
  Widget _buildNoteGroup(String title, List<Map<String, String>> notes,
      Map<String, bool> enabledNotes, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final List<Map<String, String>> enabledNotesList = notes.where((note) {
      return enabledNotes[note['note']] ?? false;
    }).toList();

    return RepaintBoundary(
      child: Card(
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: _cardBorderRadius,
        ),
        color: colorScheme.surfaceContainer,
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: StreamBuilder<bool>(
          stream: _getExpansionStream(title),
          initialData: false,
          builder: (context, snapshot) {
            final isExpanded = snapshot.data ?? false;

            return ExpansionTile(
              title: Text(
                AppLocalizations.of(context)!.getTranslation(title),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: colorScheme.onSurface,
                ),
              ),
              trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
              onExpansionChanged: (bool expanded) {
                _toggleExpansion(title, expanded);
              },
                children: [
                  Column(
                    children: enabledNotesList.map((note) {
                      return _buildNoteCard(note['note']!, note['bpm']!, context);
                    }).toList(),
                  ),
                ],
              );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabledNotes = context.watch<SettingsModel>().enabledNotes;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<Map<String, List<Map<String, String>>>>(
              stream: _notesStreamController.stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('エラーが発生しました'));
                }

                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  // 有効なノートのみをフィルタリング
                  final filteredEntries = snapshot.data!.entries
                      .where((entry) => enabledNotes[entry.key] ?? false)
                      .toList();

                  if (filteredEntries.isEmpty) {
                    return Center(
                      child: Text(
                        AppLocalizations.of(context)!.calculator_instruction,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      // 大画面では動的にグリッド表示
                      // 計算ページは内容が複雑なため、カードの最小幅を大きめに設定
                      const double minCardWidth = 350.0;
                      final int crossAxisCount = (constraints.maxWidth / minCardWidth).floor().clamp(1, 100);

                      if (crossAxisCount == 1) {
                        // 1列の場合は従来のListViewを使用
                        return ListView(
                          cacheExtent: 500,
                          children: filteredEntries
                              .map((entry) => _buildNoteGroup(
                                  entry.key, entry.value, enabledNotes, context))
                              .toList(),
                        );
                      }

                      // カラムごとにリストを分割して、それぞれのカラムで縦に並べる
                      final List<List<MapEntry<String, List<Map<String, String>>>>>
                          columns = List.generate(crossAxisCount, (_) => []);

                      for (var i = 0; i < filteredEntries.length; i++) {
                        columns[i % crossAxisCount].add(filteredEntries[i]);
                      }

                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(crossAxisCount, (colIndex) {
                            return Expanded(
                              child: Column(
                                children: columns[colIndex].map((entry) {
                                  return _buildNoteGroup(entry.key, entry.value,
                                      enabledNotes, context);
                                }).toList(),
                              ),
                            );
                          }),
                        ),
                      );
                    },
                  );
                } else {
                  return Center(
                    child: Text(
                      AppLocalizations.of(context)!.calculator_instruction,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

