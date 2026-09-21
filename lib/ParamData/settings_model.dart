import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notes.dart';
import 'judgment.dart';

class SettingsModel extends ChangeNotifier {
  String selectedUnit = 'auto';
  String selectedTimeScale = '1s';
  //小数の桁数設定
  int numDecimal = 2;
  //+-ボタンの増減値
  double deltaValue = 1;
  //Material You
  bool useMaterialYou = false;
  bool isDynamicColorAvailable = false;

  // 判定プリセット
  List<JudgmentPreset> customJudgmentPresets = [];
  Set<String> hiddenJudgmentPresetIds = {};

  // 動的カラー利用可否を設定
  void setDynamicColorAvailability(bool isAvailable) {
    isDynamicColorAvailable = !isAvailable;
  }

  // カスタムノートのリストを保持
  List<NoteData> customNotes = [];

  Map<String, bool> enabledNotes = {
    'maxima': true,
    'longa': true,
    'double_whole_note': true,
    'whole_note': true,
    'dotted_half_note': true,
    'half_note': true,
    'fourBeatsThreeConsecutive': true,
    'dotted_quarter_note': true,
    'quarter_note': true,
    'dotted_eighth_note': true,
    'twoBeatsTriplet': true,
    'eighth_note': true,
    'dotted_sixteenth_note': true,
    'oneBeatTriplet': true,
    'sixteenth_note': true,
    'oneBeatQuintuplet': true,
    'oneBeatSextuplet': true,
    'thirty_second_note': true,
  };

  SettingsModel();

  // 初期化メソッド（外部から呼び出す）
  Future<void> initialize() async {
    await _loadSettings();
  }

  List<JudgmentPreset> get allJudgmentPresets => [
    ...defaultJudgmentPresets,
    ...customJudgmentPresets,
  ];

  List<JudgmentPreset> get visibleJudgmentPresets => allJudgmentPresets
      .where((preset) => !hiddenJudgmentPresetIds.contains(preset.id))
      .toList();

  Map<String, List<JudgmentPreset>> get judgmentPresetsByGame =>
      _groupPresets(allJudgmentPresets);

  Map<String, List<JudgmentPreset>> get visibleJudgmentPresetsByGame =>
      _groupPresets(visibleJudgmentPresets);

  Map<String, List<JudgmentPreset>> _groupPresets(
    List<JudgmentPreset> presets,
  ) {
    final Map<String, List<JudgmentPreset>> grouped = {};
    for (final preset in presets) {
      grouped.putIfAbsent(preset.game, () => []).add(preset);
    }
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final Map<String, List<JudgmentPreset>> sorted = {};
    for (final key in sortedKeys) {
      final entries = grouped[key]!
        ..sort(
          (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
        );
      sorted[key] = entries;
    }
    return sorted;
  }

  JudgmentPreset? findJudgmentPresetById(String? id) {
    if (id == null) return null;
    for (final preset in allJudgmentPresets) {
      if (preset.id == id) {
        return preset;
      }
    }
    return null;
  }

  // カスタムノートと設定を保存
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // カスタムノートの保存
    final List<String> customNoteNames = customNotes
        .map((note) => note.name)
        .toList();
    final List<String> customNoteValues = customNotes
        .map((note) => note.note.toString())
        .toList();
    final List<String> customNoteDotted = customNotes
        .map((note) => note.dotted.toString())
        .toList();

    prefs.setStringList('customNoteNames', customNoteNames);
    prefs.setStringList('customNoteValues', customNoteValues);
    prefs.setStringList('customNoteDotted', customNoteDotted);

    // 音符の状態を保存
    final List<String> noteKeys = enabledNotes.keys.toList();
    final List<String> noteValues = enabledNotes.values
        .map((e) => e.toString())
        .toList();

    prefs.setStringList('enabledNotesKeys', noteKeys);
    prefs.setStringList('enabledNotesValues', noteValues);

    // 時間単位の保存
    prefs.setString('selectedUnit', selectedUnit);
    prefs.setString('selectedTimeScale', selectedTimeScale);

    //小数の桁数の保存
    prefs.setInt('numDecimal', numDecimal);

    //+-ボタンの増減値
    prefs.setDouble('deltaValue', deltaValue);

    //Material You
    prefs.setBool('useMaterialYou', useMaterialYou);

    // 判定プリセット
    prefs.setStringList(
      'customJudgmentPresets',
      customJudgmentPresets
          .map((preset) => jsonEncode(preset.toJson()))
          .toList(),
    );
    prefs.setStringList(
      'hiddenJudgmentPresetIds',
      hiddenJudgmentPresetIds.toList(),
    );
  }

  // SharedPreferencesから設定を読み込む
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // カスタムノートの読み込み
    final List<String>? customNoteNames = prefs.getStringList(
      'customNoteNames',
    );
    final List<String>? customNoteValues = prefs.getStringList(
      'customNoteValues',
    );
    final List<String>? customNoteDotted = prefs.getStringList(
      'customNoteDotted',
    );

    if (customNoteNames != null &&
        customNoteValues != null &&
        customNoteDotted != null) {
      customNotes = [];
      for (int i = 0; i < customNoteNames.length; i++) {
        final double noteValue = double.tryParse(customNoteValues[i]) ?? 4;
        final bool noteDotted = stringToBool(customNoteDotted[i]);
        customNotes.add(NoteData(customNoteNames[i], noteValue, noteDotted));
        registerNoteData(customNoteNames[i], noteValue, noteDotted);
      }
    }

    // 時間単位を読み込む
    selectedUnit = prefs.getString('selectedUnit') ?? 'auto';

    selectedTimeScale = prefs.getString('selectedTimeScale') ?? '1s';

    // 音符の状態を読み込む
    final List<String>? noteKeys = prefs.getStringList('enabledNotesKeys');
    final List<String>? noteValues = prefs.getStringList('enabledNotesValues');

    if (noteKeys != null && noteValues != null) {
      enabledNotes = {};
      for (int i = 0; i < noteKeys.length; i++) {
        enabledNotes[noteKeys[i]] = noteValues[i] == 'true';
      }
    }

    //小数の桁数を読み込む
    numDecimal = prefs.getInt('numDecimal') ?? 2;

    //+-ボタンの増減値
    deltaValue = prefs.getDouble('deltaValue') ?? 1;

    //Material You
    if (isDynamicColorAvailable) {
      useMaterialYou = prefs.getBool('useMaterialYou') ?? true;
    } else {
      useMaterialYou = prefs.getBool('useMaterialYou') ?? false;
    }

    final List<String>? presetJson = prefs.getStringList(
      'customJudgmentPresets',
    );
    customJudgmentPresets = [];
    if (presetJson != null) {
      customJudgmentPresets = presetJson
          .map(
            (entry) => JudgmentPreset.fromJson(
              jsonDecode(entry) as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    hiddenJudgmentPresetIds =
        prefs.getStringList('hiddenJudgmentPresetIds')?.toSet() ?? {};

    notifyListeners();
  }

  // 時間単位の変更
  void setUnit(String unit) {
    selectedUnit = unit;
    _saveSettings(); // 設定を保存
    notifyListeners();
  }

  // 時間単位の変更(2ページ目)
  void setTimeScale(String unit) {
    selectedTimeScale = unit;
    _saveSettings(); // 設定を保存
    notifyListeners();
  }

  // 小数の桁数の変更
  void setNumDecimal(int num) {
    numDecimal = num;
    _saveSettings(); // 設定を保存
    notifyListeners();
  }

  // +/-ボタンの増減値変更
  void setDeltaValue(double num) {
    deltaValue = num;
    _saveSettings(); // 設定を保存
    notifyListeners();
  }

  // Material You変更
  void setMaterialYou(bool isMaterialYou) {
    useMaterialYou = isMaterialYou;
    _saveSettings(); // 設定を保存
    notifyListeners();
  }

  // 音符の有効/無効を切り替え
  void toggleNoteEnabled(String note) {
    enabledNotes[note] = !enabledNotes[note]!;
    _saveSettings(); // 設定を保存
    notifyListeners();
  }

  // 音符の状態を一括変更
  void setEnabledNotes(Map<String, bool> newEnabledNotes) {
    enabledNotes = newEnabledNotes;
    _saveSettings(); // 設定を保存
    notifyListeners();
  }

  // カスタムノートの追加
  void addCustomNote(String name, double value, [bool dotted = false]) {
    customNotes.add(NoteData(name, value, dotted)); // カスタムノートを追加
    enabledNotes[name] = true; // enabledNotesに登録し、デフォルトでtrueに設定
    registerNoteData(name, value, dotted);
    _saveSettings(); // 保存
    notifyListeners();
  }

  // カスタムノートの削除
  void removeCustomNote(String noteName) {
    customNotes.removeWhere((note) => note.name == noteName); // カスタムノートリストから削除
    enabledNotes.remove(noteName); // enabledNotesからも削除
    removeNoteData(noteName);
    _saveSettings(); // 保存
    notifyListeners();
  }

  void addCustomJudgmentPreset({
    required String game,
    required String label,
    required double earlyMs,
    required double lateMs,
  }) {
    final preset = JudgmentPreset.custom(
      game: game.trim(),
      label: label.trim(),
      earlyMs: earlyMs,
      lateMs: lateMs,
    );
    customJudgmentPresets.add(preset);
    hiddenJudgmentPresetIds.remove(preset.id);
    _saveSettings();
    notifyListeners();
  }

  void removeCustomJudgmentPreset(String presetId) {
    customJudgmentPresets.removeWhere(
      (preset) => preset.id == presetId && preset.isCustom,
    );
    hiddenJudgmentPresetIds.remove(presetId);
    _saveSettings();
    notifyListeners();
  }

  void setPresetVisibility(String presetId, bool isVisible) {
    if (isVisible) {
      hiddenJudgmentPresetIds.remove(presetId);
    } else {
      hiddenJudgmentPresetIds.add(presetId);
    }
    _saveSettings();
    notifyListeners();
  }

  bool isPresetHidden(String presetId) {
    return hiddenJudgmentPresetIds.contains(presetId);
  }

  void updateCustomJudgmentPreset({
    required String presetId,
    required String game,
    required String label,
    required double earlyMs,
    required double lateMs,
  }) {
    for (int i = 0; i < customJudgmentPresets.length; i++) {
      if (customJudgmentPresets[i].id == presetId) {
        customJudgmentPresets[i] = customJudgmentPresets[i].copyWith(
          label: label.trim(),
          earlyMs: earlyMs,
          lateMs: lateMs,
        );
        _saveSettings();
        notifyListeners();
        break;
      }
    }
  }

  bool stringToBool(String input) {
    if (input.toLowerCase() == 'true') {
      return true;
    } else if (input.toLowerCase() == 'false') {
      return false;
    } else {
      throw ArgumentError('Invalid boolean string: $input');
    }
  }
}
