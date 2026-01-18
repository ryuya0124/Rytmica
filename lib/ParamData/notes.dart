// ノートデータのクラス定義
class NoteData {
  final String name;       // ノートの名前
  final double note; // 元のノートの比率
  final bool dotted;       // ドット付きかどうか

  NoteData(this.name, this.note, this.dotted);
}

// データ: 各ノートの定義
final List<NoteData> notes = [
  NoteData('maxima', 1 / 8, false),
  NoteData('longa', 1 / 4, false),
  NoteData('double_whole_note', 1 / 2, false),
  NoteData('whole_note', 1, false),
  NoteData('dotted_half_note', 2, true),
  NoteData('half_note', 2, false),
  NoteData('fourBeatsThreeConsecutive', 3, false),
  NoteData('dotted_quarter_note', 4, true),
  NoteData('quarter_note', 4, false),
  NoteData('dotted_eighth_note', 8, true),
  NoteData('twoBeatsTriplet', 6, false),
  NoteData('eighth_note', 8, false),
  NoteData('dotted_sixteenth_note', 16, true),
  NoteData('oneBeatTriplet', 12, false),
  NoteData('sixteenth_note', 16, false),
  NoteData('oneBeatQuintuplet', 20, false),
  NoteData('oneBeatSextuplet', 24, false),
  NoteData('thirty_second_note', 32, false),
];

/// 該当するノートを検索する関数
NoteData findNoteData(String name) {
  return notes.firstWhere(
        (n) => n.name == name,
    orElse: () => NoteData('default', 4, false), // デフォルト値
  );
}

/// ノートをn分音符に換算した場合のBPMを計算する関数
/// [bpm] 元のBPM
/// [baseNote] 元の音符
/// [targetNote] 換算先の音符
double calculateNoteBPM(double bpm, NoteData baseNote, NoteData targetNote) {
  // 基本計算: BPM * (元の音符比率 / 換算先の音符比率)
  double result = bpm * (baseNote.note / targetNote.note);
  
  // 元の音符が付点の場合、1.5倍長いので割る
  if (baseNote.dotted) {
    result /= 1.5;
  }
  
  // 換算先の音符が付点の場合、1.5倍長いので掛ける
  if (targetNote.dotted) {
    result *= 1.5;
  }
  
  return result;
}

/// ノートの長さを計算
double calculateNoteLength(double quarterNoteLength, double noteRatio, {bool isDotted = false}) {
  final double baseLength = quarterNoteLength / noteRatio * 4;
  return isDotted ? baseLength * 1.5 : baseLength;
}

/// 指定された時間 / ノーツの長さ (秒単位)
double calculateNoteFrequency(double bpm, num unit, double note, {bool isDotted = false}) {
  //4分音符基準(計算式的に)
  note = note / 4;
  //付点を考慮
  if(isDotted){
    return bpm / (unit / note) / 1.5;
  } else {
    return bpm / (unit / note);
  }
}

/// Noteリストに音符を追加
void registerNoteData(String name, double value, bool isDotted) {
  notes.add(NoteData(name, value, isDotted));
}

/// Noteリストから音符を削除
void removeNoteData(String name) {
  notes.removeWhere((note) => note.name == name);
}