part of 'judgment.dart';

// Source: Galaxy_Judgment_Windows_2026-11-02.md supplied by the project owner.
// Values describe internal timing, not measured touch/audio latency. Frame
// fractions retain precision; the UI rounds them only when displaying them.
const _frameMs = 1000.0 / 60;
const judgmentPresetReviewDate = '2026-11-02';

final List<JudgmentPreset> defaultJudgmentPresets = List.unmodifiable(
  _buildJudgmentCatalog(),
);

JudgmentPresetContext _reference(
  String version,
  String ja,
  String en,
) => JudgmentPresetContext(
  version: version,
  noteJa: ja,
  noteEn: en,
  checkedOn: judgmentPresetReviewDate,
);

/// A lower target grade includes higher grades. In particular, a zero or
/// repeated early threshold does not erase the higher grade's early window.
/// MISS/LOST deadlines, contact latches and non-monotonic custom settings must
/// not be passed in as ordinary cumulative success grades.
List<JudgmentPreset> _series({
  required String id,
  required String game,
  required List<String> grades,
  required List<double> early,
  List<double>? late,
  String mode = '',
  String? modeEn,
  required JudgmentPresetContext context,
  Map<int, String> existingIds = const {},
}) {
  assert(grades.length == early.length);
  assert(late == null || late.length == grades.length);
  double earlyLimit = 0;
  double lateLimit = 0;
  return [
    for (var index = 0; index < grades.length; index++)
      JudgmentPreset(
        id: existingIds[index] ?? '${id}_$index',
        game: game,
        label: [
          if (mode.isNotEmpty) mode,
          '${grades[index]}${index == 0 ? '' : '以上'}',
        ].join(' · '),
        labelEn: [
          if (mode.isNotEmpty) modeEn ?? mode,
          '${grades[index]}${index == 0 ? '' : ' or better'}',
        ].join(' · '),
        earlyMs: earlyLimit = max(earlyLimit, early[index]),
        lateMs: lateLimit = max(lateLimit, (late ?? early)[index]),
        context: context,
      ),
  ];
}

List<JudgmentPreset> _buildJudgmentCatalog() {
  final presets = <JudgmentPreset>[];
  final sekai = _reference(
    'JP 7.1.0 / EN 6.1.0 / KR・TW 6.4.0',
    '保存マスターの参照値。現在の演奏中の適用値は未確認。CN・体験版の実ロード値を保証しません。接触・方向・保持条件は別です。',
    'Saved-master reference; live values are unconfirmed. Not a verified live value for CN or the trial. Contact, direction and hold conditions are separate.',
  );
  for (final row in [
    ('white_notes', '通常タップ', 'Normal tap', 2.5 * _frameMs),
    ('green_long_start', 'ロング始点', 'Long start', 2.5 * _frameMs),
    ('yellow_notes', '黄色タップ', 'Yellow tap', 55.0),
    ('yellow_long_start', '黄色ロング始点', 'Yellow long start', 55.0),
  ]) {
    presets.addAll(
      _series(
        id: 'proseca_${row.$1}',
        game: 'プロセカ',
        mode: row.$2,
        modeEn: row.$3,
        grades: ['PERFECT', 'GREAT', 'GOOD', 'BAD'],
        early: [row.$4, row.$4 == 55 ? 75 : 5 * _frameMs, 6.5 * _frameMs, 125],
        context: sekai,
        existingIds: {0: 'proseca_${row.$1}'},
      ),
    );
  }
  for (final row in [
    ('red_flick', 'フリック', 'Flick', 2.5 * _frameMs),
    ('yellow_flick', '黄色フリック', 'Yellow flick', 3.5 * _frameMs),
  ]) {
    presets.addAll(
      _series(
        id: 'proseca_${row.$1}',
        game: 'プロセカ',
        mode: row.$2,
        modeEn: row.$3,
        grades: ['PERFECT', 'GREAT', 'GOOD', 'BAD'],
        early: [row.$4, 6.5 * _frameMs, 7 * _frameMs, 125],
        late: [row.$4, 125, 8 * _frameMs, 8.5 * _frameMs],
        context: sekai,
        existingIds: {0: 'proseca_${row.$1}'},
      ),
    );
  }
  for (final row in [
    ('green_long_end', 'ロング終点', 'Long end'),
    ('green_long_end_flick', '終点フリック', 'End flick'),
    ('yellow_long_end', '黄色ロング終点', 'Yellow long end'),
    ('yellow_long_end_flick', '黄色終点フリック', 'Yellow end flick'),
  ]) {
    presets.addAll(
      _series(
        id: 'proseca_${row.$1}',
        game: 'プロセカ',
        mode: row.$2,
        modeEn: row.$3,
        grades: ['PERFECT', 'GREAT', 'GOOD', 'BAD'],
        early: [3.5 * _frameMs, 6.5 * _frameMs, 125, 125],
        late: [4 * _frameMs, 8 * _frameMs, 8.5 * _frameMs, 8.5 * _frameMs],
        context: sekai,
        existingIds: {0: 'proseca_${row.$1}'},
      ),
    );
  }
  // Trace latch/arrival tables and the internal JustPerfect counter are not
  // ordinary tap acceptance windows; do not substitute them for trace input.
  presets.addAll(
    _series(
      id: 'garupa',
      game: 'ガルパ',
      mode: '通常タップ',
      modeEn: 'Normal tap',
      grades: ['PERFECT', 'GREAT', 'GOOD', 'BAD'],
      early: [2.5 * _frameMs, 5.5 * _frameMs, 6.5 * _frameMs, 7.5 * _frameMs],
      context: _reference(
        'JP 10.2.0 / EN 9.4.0 / TW 10.1.0',
        'sweetFrame=0。フレーム丸めを考慮した境界の近似値。端点の包含は段階ごとに異なり、強化・特殊ノーツは別です。',
        'sweetFrame=0. Approximate boundaries after frame rounding; endpoint inclusion differs by rank. Skills and special notes are separate.',
      ),
      existingIds: {0: 'garupa_perfect'},
    ),
  );
  presets.addAll(
    _series(
      id: 'd4dj',
      game: 'D4DJ グルミク',
      grades: ['JUST PERFECT', 'PERFECT', 'GREAT', 'GOOD', 'BAD'],
      early: [25, 50, 100, 150, 200],
      context: _reference(
        'JP 11.0.1 / EN 10.8.00',
        '基本の時間差評価。スライドの保持・回復時間は別条件です。',
        'Base timing evaluation. Slide holding and recovery use separate conditions.',
      ),
      existingIds: {0: 'd4dj_internal_perfect', 1: 'd4dj_perfect'},
    ),
  );
  presets.addAll(
    _series(
      id: 'd4u',
      game: 'D4DJ D4U Edition',
      grades: ['PERFECT', 'GREAT', 'GOOD', 'BAD'],
      early: [50, 100, 150, 200],
      context: _reference(
        '1.2.1',
        'JUST PERFECTの独立段階はありません。',
        'There is no separate JUST PERFECT rank.',
      ),
    ),
  );
  final yumeste = _reference(
    '2.31.3',
    '基本設定。タップとフリックは別テーブル。動作・ホールド・スクラッチの条件は別です。',
    'Base settings. Tap and flick use different tables; gestures, holds and scratches have additional conditions.',
  );
  presets.addAll(
    _series(
      id: 'yumeste_tap',
      game: 'ユメステ',
      mode: 'タップ',
      modeEn: 'Tap',
      grades: ['PERFECT★', 'PERFECT', 'GREAT', 'GOOD', 'BAD'],
      early: [25, 40, 70, 100, 125],
      context: yumeste,
      existingIds: {0: 'yumeste_perfect_plus', 1: 'yumeste_perfect'},
    ),
  );
  presets.addAll(
    _series(
      id: 'yumeste_flick',
      game: 'ユメステ',
      mode: 'フリック',
      modeEn: 'Flick',
      grades: ['PERFECT★', 'GREAT'],
      early: [70, 100],
      context: yumeste,
    ),
  );
  presets.addAll(
    _series(
      id: 'taiko3',
      game: '太鼓さん大次郎3',
      grades: ['良', '可'],
      early: [40, 90],
      context: _reference(
        '2.0.5',
        '通常打音の初期値・保存値。厳密な未満比較。不可140msは成功判定に含めず、候補ノーツ選択も別条件です。',
        'Normal hit defaults and saved values; strict comparisons. The 140 ms failure window is excluded. Candidate-note selection is separate.',
      ),
    ),
  );
  _addOurNotes(presets);
  presets.addAll(
    _series(
      id: 'phigros_normal',
      game: 'Phigros',
      mode: '通常',
      modeEn: 'Normal',
      grades: ['PERFECT', 'GOOD', 'BAD'],
      early: [80, 180, 220],
      late: [80, 180, 180],
      context: _reference(
        '4.0.1.2',
        '取得版の通常設定。BADは早側のみ。BAD以上の遅側はGOOD期限180msまでとし、未接触の遅MISS領域を含めません。ドラッグ・フリックの接触記憶は別処理です。',
        'Normal settings in the inspected version. BAD is early-only; its or-better late side stops at the 180 ms GOOD deadline, excluding late MISS. Drag/flick contact memory is separate.',
      ),
      existingIds: {0: 'phigros_normal_perfect'},
    ),
  );
  for (final fps in [60, 120]) {
    final h = 1000 / fps / 2;
    presets.addAll(
      _series(
        id: 'phigros_challenge_$fps',
        game: 'Phigros',
        mode: '挑戦・安定${fps}fps参考',
        modeEn: 'Challenge · stable $fps fps reference',
        grades: ['PERFECT', 'GOOD', 'BAD'],
        early: [40 + h, 90 + h, 140 + h],
        late: [40 + h, 90 + h, 90 + h],
        context: _reference(
          '4.0.1.2',
          '各基準値に直近最大10フレームの平均deltaTime÷2を加算。安定${fps}fpsの参考値で表示Hzだけでは決まりません。BADは早側のみで、遅側はGOOD期限までです。',
          'Base values plus half the average deltaTime of up to 10 recent frames. A stable $fps fps reference, not inferred from display Hz. BAD is early-only; the late side stops at the GOOD deadline.',
        ),
        existingIds: fps == 60 ? {0: 'phigros_challenge_perfect'} : const {},
      ),
    );
  }
  presets.addAll(
    _series(
      id: 'arccreate',
      game: 'ArcCreate',
      grades: ['MAX', 'PERFECT', 'GOOD'],
      early: [25, 50, 100],
      late: [24, 49, 99],
      context: _reference(
        '1.2.68',
        '整数msの実区間はMAX −25〜+24、PERFECT −50〜+49、GOOD −100〜+99。譜面リマップ・保持受付は別です。',
        'Integer intervals: MAX −25…+24, PERFECT −50…+49, GOOD −100…+99 ms. Chart remaps and hold acceptance are separate.',
      ),
    ),
  );
  presets.addAll(
    _series(
      id: 'arcaea',
      game: 'Arcaea',
      grades: ['小PURE', 'PURE', 'FAR'],
      early: [25, 50, 100],
      context: _reference(
        '7.1.0',
        '通常タップの時間分類。120msのLOST外周は成功判定に含めません。アーク・ホールドの追従条件は別です。',
        'Normal tap timing. The 120 ms LOST perimeter is excluded. Arc/hold tracking uses separate conditions.',
      ),
      existingIds: {0: 'arcaea_internal_pure', 1: 'arcaea_pure'},
    ),
  );
  for (final row in [
    (
      'tap',
      'Tap',
      <double>[1 * _frameMs, 50, 100, 150],
      <double>[1 * _frameMs, 50, 100, 150],
    ),
    (
      'hold',
      'Hold',
      <double>[1 * _frameMs, 50, 100, 150],
      <double>[1 * _frameMs, 8 * _frameMs, 11 * _frameMs, 14 * _frameMs],
    ),
    (
      'touch',
      'Touch',
      <double>[150, 150, 150, 150],
      <double>[150, 13 * _frameMs, 250, 300],
    ),
    (
      'slide_finish',
      'SlideFinish',
      <double>[14 * _frameMs, 26 * _frameMs, 600],
      <double>[14 * _frameMs, 26 * _frameMs, 600],
    ),
  ]) {
    presets.addAll(
      _series(
        id: 'astrodx_${row.$1}',
        game: 'AstroDX',
        mode: row.$2,
        grades: row.$1 == 'slide_finish'
            ? ['CRITICAL PERFECT', 'GREAT', 'GOOD']
            : ['CRITICAL PERFECT', 'PERFECT', 'GREAT', 'GOOD'],
        early: row.$3,
        late: row.$4,
        context: _reference(
          '2.0.0.beta.pre.96.exp.8',
          'ノーツ別の時間表。境界では評価順が影響します。Holdの最終成績は保持時間も使用。SlideFinishに独立したPERFECT段階はありません。',
          'Note-specific timing table; evaluation order matters at shared boundaries. Hold also evaluates duration. SlideFinish has no separate PERFECT rank.',
        ),
      ),
    );
  }
  presets.addAll(
    _series(
      id: 'dankaglike',
      game: 'ダンカグライク',
      mode: '初期設定',
      modeEn: 'Defaults',
      grades: ['BRILLIANT', 'GREAT', 'FAST/SLOW', 'BAD'],
      early: [50, 100, 120, 150],
      context: _reference(
        '1.1.8',
        'APK初期値・MusicRate=1。端末の変更済み設定50/33/41/50msは非単調のため収録しません。ファジー軽減・離し補正は別です。',
        'APK defaults, MusicRate=1. The device-specific non-monotonic 50/33/41/50 ms settings are excluded. Fuzzy and release corrections are separate.',
      ),
    ),
  );
  presets.addAll(
    _series(
      id: 'ekscita',
      game: 'Ekscita',
      grades: ['GREAT', 'GOOD'],
      early: [50, 200],
      context: _reference(
        '1.0.6',
        '演奏シーンの値。コンストラクタ値ではありません。POOR期限400msは通常の成功グレードに含めません。',
        'Gameplay-scene values, not constructor defaults. The 400 ms POOR deadline is not an ordinary success grade.',
      ),
    ),
  );
  _addMillionLive(presets);
  for (final row in [
    (
      'regular',
      'Regular/SlideStart/Skill/Kime',
      <double>[30, 50, 5 * _frameMs, 8 * _frameMs],
      <double>[30, 50, 5 * _frameMs, 8 * _frameMs],
    ),
    (
      'flick',
      'Flick',
      <double>[5 * _frameMs, 5 * _frameMs, 5 * _frameMs, 5 * _frameMs],
      <double>[40, 50, 5 * _frameMs, 8 * _frameMs],
    ),
    (
      'slide_end',
      'SlideEnd',
      <double>[5.5 * _frameMs, 5.5 * _frameMs, 0, 0],
      <double>[30, 50, 4 * _frameMs, 100],
    ),
    (
      'slide_joint',
      'SlideJoint',
      <double>[2 * _frameMs, 2 * _frameMs, 0, 0],
      <double>[2 * _frameMs, 2 * _frameMs, 4 * _frameMs, 4 * _frameMs],
    ),
  ]) {
    presets.addAll(
      _series(
        id: 'shinycolors_${row.$1}',
        game: 'シャニソン',
        mode: row.$2,
        grades: ['SHINY', 'PERFECT', 'GREAT', 'GOOD'],
        early: row.$3,
        late: row.$4,
        context: _reference(
          '2.19.1',
          'SHINY有効時。以上の範囲は上位判定を含むため、マスターの0を上位の早判定から除きません。保持・動作条件は別です。',
          'SHINY enabled. “Or better” includes higher ranks, so a raw zero does not remove their early acceptance. Hold/gesture conditions are separate.',
        ),
      ),
    );
  }
  presets.addAll(
    _series(
      id: 'rotaeno',
      game: 'Rotaeno',
      mode: '通常',
      modeEn: 'Normal',
      grades: ['PERFECT+', 'PERFECT', 'GOOD'],
      early: [40, 80, 130],
      context: _reference(
        '2.99.0',
        '通常ノーツ。フリックは動作条件と専用判定が別です。',
        'Normal notes; flick gestures have separate conditions and timing.',
      ),
    ),
  );
  for (final row in [
    (
      'normal',
      'Normal/LongStart',
      ['PERFECT+', 'PERFECT', 'GREAT', 'GOOD', 'BAD'],
      <double>[25, 4 * _frameMs, 100, 8 * _frameMs, 150],
      <double>[25, 50, 5 * _frameMs, 7 * _frameMs, 8 * _frameMs],
    ),
    (
      'flick',
      'Flick/LongFlickEnd',
      ['PERFECT+', 'PERFECT', 'BAD'],
      <double>[25, 100, 150],
      <double>[25, 5 * _frameMs, 8 * _frameMs],
    ),
    (
      'critical',
      'Critical Normal/LongStart',
      ['PERFECT+', 'PERFECT', 'BAD'],
      <double>[25, 8 * _frameMs, 150],
      <double>[25, 7 * _frameMs, 8 * _frameMs],
    ),
  ]) {
    presets.addAll(
      _series(
        id: 'holodori_${row.$1}',
        game: 'ホロライブ ドリームス',
        mode: row.$2,
        grades: row.$3,
        early: row.$4,
        late: row.$5,
        context: _reference(
          '1.2.101',
          '端末で選択されたマスターDBの値。CriticalType=1はGreat/GoodをPerfectへ昇格。中継・継続・終点の到達確定や接触維持は別です。',
          'Selected on-device master DB. CriticalType=1 promotes Great/Good to Perfect. Relay, continuation, end arrival and sustained contact are separate.',
        ),
      ),
    );
  }
  for (final row in [
    (
      'normal',
      '標準分岐',
      'Standard branch',
      ['PERFECT', 'GREAT', 'GOOD', 'BAD'],
      <double>[45, 90, 120, 150],
    ),
    (
      'type21',
      '内部type21',
      'Internal type21',
      ['PERFECT', 'GREAT', 'GOOD', 'BAD'],
      <double>[90, 180, 240, 300],
    ),
    (
      'type30_32',
      '内部type30/31/32',
      'Internal type30/31/32',
      ['PERFECT'],
      <double>[90],
    ),
    ('type62', '内部type62', 'Internal type62', ['PERFECT'], <double>[120]),
  ]) {
    presets.addAll(
      _series(
        id: 'chainbeet_${row.$1}',
        game: 'ChainBeeT',
        mode: row.$2,
        modeEn: row.$3,
        grades: row.$4,
        early: row.$5,
        context: _reference(
          '4.22.3',
          '特殊type IDと画面上のノーツ名は未対応づけ。MISS入力外周200msは除外。特殊ノーツの接触・自動判定は別です。',
          'Special type IDs are not mapped to UI note names. The 200 ms MISS perimeter is excluded. Contact and automatic judgments are separate.',
        ),
      ),
    );
  }
  for (final row in [
    (
      'tap',
      'Tap',
      ['JUST PERFECT', 'PERFECT', 'GREAT', 'GOOD', 'BAD'],
      <double>[20, 50, 100, 150, 200],
    ),
    (
      'long_end_flick',
      'LongEndFlick',
      ['JUST PERFECT', 'PERFECT'],
      <double>[37.5, 75],
    ),
    (
      'sky_start',
      'SkyStart',
      ['JUST PERFECT', 'PERFECT', 'GREAT', 'GOOD'],
      <double>[25, 50, 100, 150],
    ),
    (
      'sky_end',
      'SkyEnd',
      ['JUST PERFECT', 'PERFECT', 'GREAT', 'GOOD'],
      <double>[37.5, 75, 150, 175],
    ),
    (
      'other',
      'Other',
      ['JUST PERFECT', 'PERFECT', 'GREAT', 'GOOD', 'BAD'],
      <double>[37.5, 75, 150, 175, 200],
    ),
    (
      'classic',
      'Classic Tap',
      ['PERFECT', 'GREAT', 'GOOD', 'BAD'],
      <double>[50.1, 100, 167, 234],
    ),
  ]) {
    presets.addAll(
      _series(
        id: 't7s_${row.$1}',
        game: 'Tokyo 7th シスターズ',
        mode: row.$2,
        grades: row.$3,
        early: row.$4,
        context: _reference(
          '13.0.3',
          '現行とClassicを区別。Soloの内部時刻換算とClassic特殊配列の段階対応は未確定のため除外。MISS外周も含めません。',
          'Current and Classic tables are separate. Solo time conversion, Classic special-array rank mapping and MISS perimeters are excluded.',
        ),
      ),
    );
  }
  _addMalody(presets);
  _addOsu(presets);
  presets.addAll(
    _series(
      id: 'takumi',
      game: 'TAKUMI³',
      grades: ['LB JUST', 'P JUST', 'JUST', 'GOOD', 'OK'],
      early: [25, 2.5 * _frameMs, 60, 82.5, 110],
      context: _reference(
        '7.7.5',
        'LB/Pの表示オプション・スコア方式で上位段階の扱いが変化。MISS外周120msと保持用定数は除外。旧「虹JUST 40ms」はP JUST約41.67msに訂正。',
        'LB/P display options and scoring mode affect top ranks. The 120 ms MISS perimeter and hold constants are excluded. The old 40 ms rainbow preset is corrected to P JUST ≈41.67 ms.',
      ),
      existingIds: {1: 'takumi_rainbow_just', 2: 'takumi_just'},
    ),
  );
  // These four existing games were not researched in the supplied document.
  // Preserve users' IDs and values, but explicitly avoid presenting them as
  // verified by the new survey. Sonolus/Piano Tiles have no fixed tap table.
  for (final row in [
    ('deemo_default', 'Deemo', 'Default', 50.0),
    ('cytus_tp_perfect', 'Cytus/Cytus II', 'TP PERFECT', 70.0),
    ('kalpa_perfect', 'KALPA', 'PERFECT', 67.0),
    ('deresute_perfect', 'デレステ', 'PERFECT (Mas以上)', 70.0),
  ]) {
    presets.add(
      JudgmentPreset(
        id: row.$1,
        game: row.$2,
        label: '${row.$3}・従来値',
        labelEn: '${row.$3} · legacy reference',
        earlyMs: row.$4,
        lateMs: row.$4,
        context: const JudgmentPresetContext(
          version: '',
          noteJa: '今回の資料の調査対象外です。従来値を保持していますが、出所・対象版・現在の適用値は未確認です。',
          noteEn: 'Not covered by this survey. Retained legacy value; source, version and current applicability are unverified.',
        ),
      ),
    );
  }
  return presets;
}

void _addOurNotes(List<JudgmentPreset> presets) {
  for (var level = 0; level <= 5; level++) {
    final context = _reference(
      '1.1.0',
      '実行中マスター・内部アシストLv$level・強化前。UI上のアシスト名との対応は未確認。以上は上位判定を含む範囲。MISS用の窓・別集計EXCELLENT・接触ラッチは除外。',
      'Runtime master, internal assist Lv$level, before skills. UI assist-name mapping is unconfirmed. “Or better” includes higher ranks. MISS windows, separate EXCELLENT counters and contact latches are excluded.',
    );
    for (final row in [
      (
        'normal',
        'Normal/SlideBegin',
        ['JUST (内部)', 'PERFECT', 'GREAT', 'GOOD', 'BAD'],
        <double>[
          2,
          50,
          83,
          <double>[100, 111, 114, 118, 124, 129][level],
          <double>[125, 128, 132, 137, 143, 150][level],
        ],
        <double>[
          2,
          50,
          83,
          <double>[100, 111, 114, 118, 124, 129][level],
          <double>[125, 128, 132, 137, 143, 150][level],
        ],
      ),
      (
        'easy',
        'EasyNormal/SlideBeginEasy',
        ['JUST (内部)', 'PERFECT'],
        <double>[2, 67.0 + 5 * level],
        <double>[2, 67.0 + 5 * level],
      ),
      (
        'flick',
        'Flick',
        ['JUST (内部)', 'PERFECT', 'GREAT', 'GOOD', 'BAD'],
        <double>[2, 83.0 + 5 * level, 0, 0, 0],
        <double>[
          2,
          67,
          83,
          <double>[117, 120, 124, 128, 133, 139][level],
          <double>[125, 130, 135, 140, 146, 153][level],
        ],
      ),
      (
        'end_flick',
        'SlideEndFlick',
        ['JUST (内部)', 'PERFECT', 'GREAT', 'GOOD', 'BAD'],
        <double>[2, 83.0 + 5 * level, 0, 0, 0],
        <double>[
          2,
          level == 3 ? 58 : 67,
          83,
          <double>[117, 120, 124, 128, 133, 139][level],
          <double>[125, 130, 135, 140, 146, 153][level],
        ],
      ),
      (
        'end',
        'SlideEnd',
        ['PERFECT', 'GREAT', 'GOOD', 'BAD'],
        <double>[84, 0, 0, 0],
        <double>[
          66,
          166,
          <double>[191, 196, 202, 210, 219, 229][level],
          <double>[208, 214, 220, 229, 239, 249][level],
        ],
      ),
    ]) {
      presets.addAll(
        _series(
          id: 'ournotes_${row.$1}_assist$level',
          game: 'アワーノーツ',
          mode: '${row.$2} · Lv$level',
          grades: row.$3,
          early: row.$4,
          late: row.$5,
          context: context,
        ),
      );
    }
    // Trace/SlideEndTrace tables require contact latching and arrival logic;
    // a raw 67…92 ms master row is not a standalone tap-input window.
  }
}

void _addMillionLive(List<JudgmentPreset> presets) {
  // Internal difficulty IDs are deliberately not called OM/MM (unverified).
  for (final row in [
    (
      'thanky_2lane0_4lane',
      'thanky · 2L index0 / 4L index0–3',
      <double>[5, 9, 14],
      16.0,
    ),
    (
      'thanky_2lane1_6lane0',
      'thanky · 2L index1 / 6L index0',
      <double>[3, 6, 11],
      13.0,
    ),
    (
      'thanky_2lane23_6lane123',
      'thanky · 2L index2–3 / 6L index1–3',
      <double>[3, 6, 9],
      11.0,
    ),
    ('bnthtr_6lane2', 'bnthtr · 6L index2', <double>[2, 6, 9], 11.0),
  ]) {
    for (final release in [false, true]) {
      presets.addAll(
        _series(
          id: 'mltd_${row.$1}_${release ? 'release' : 'tap'}',
          game: 'ミリシタ',
          mode: '${row.$2} · ${release ? 'Flick/HoldEnd' : 'Tap'}',
          grades: ['PERFECT', 'GREAT', 'GOOD'],
          early: [
            for (final frames in row.$3)
              min(frames * _frameMs + (release ? 50 : 0), row.$4 * _frameMs),
          ],
          context: _reference(
            '9.0.350',
            '取得キャッシュ譜面${row.$1.startsWith('bnthtr') ? 'bnthtr' : 'thanky'}限定の参考値。内部difficultyとUIコース名は未対応づけ。全曲共通ではありません。上位3段は厳密な未満比較。終点加算は入力外周で制限済み。',
            'Reference for the sampled ${row.$1.startsWith('bnthtr') ? 'bnthtr' : 'thanky'} chart only. Internal difficulty IDs are not mapped to UI courses; not universal across songs. Top ranks use strict comparisons. Release bonuses are capped by the input perimeter.',
          ),
        ),
      );
    }
  }
}

void _addMalody(List<JudgmentPreset> presets) {
  for (final row in [
    ('key', 'Key', <double>[45, 85, 130]),
    ('key_fair', 'Key Fair', <double>[45, 85, 120]),
    ('pad', 'Pad', <double>[45, 85, 130]),
    ('jubeat', 'Jubeat', <double>[40, 80, 160]),
    ('iidx', 'IIDX', <double>[20, 40, 105]),
    ('taiko', 'Taiko/Taiko Fair', <double>[34, 84, 128]),
    ('slide', 'Slide', <double>[45, 85, 130]),
    ('slide_fair', 'Slide Fair', <double>[45, 85, 120]),
  ]) {
    // Only Key's 0…4 corrections were verified. Do not apply them to Pad etc.
    for (final setting
        in row.$1 == 'key' || row.$1 == 'key_fair' ? [0, 1, 2, 3, 4] : [2]) {
      final delta = row.$1.startsWith('key')
          ? [20.0, 10, 0, -8, -16][setting]
          : 0.0;
      presets.addAll(
        _series(
          id: 'malody_${row.$1}_$setting',
          game: 'Malody',
          mode: '${row.$2} · setting $setting',
          grades: ['BEST', 'COOL', 'GOOD'],
          early: [for (final value in row.$3) value + delta],
          context: _reference(
            '4.3.7',
            '内部モード名・内部設定番号。UI表示やA〜Eとの対応は未確認。Keyのみ設定補正を確認済み。Fairは別表です。',
            'Internal mode and setting IDs; UI names and A–E mapping are unconfirmed. Setting corrections are verified only for Key; Fair has its own table.',
          ),
        ),
      );
    }
  }
  for (var setting = 0; setting <= 4; setting++) {
    presets.addAll(
      _series(
        id: 'malody_lovelive_$setting',
        game: 'Malody',
        mode: 'LoveLive · setting $setting',
        grades: ['BEST', 'COOL', 'GOOD'],
        early: [
          <double>[52, 46, 40, 36, 32][setting],
          <double>[130, 115, 100, 90, 80][setting],
          <double>[208, 184, 160, 144, 128][setting],
        ],
        context: _reference(
          '4.3.7',
          'LoveLive専用の内部設定0〜4。UIのA〜Eへの対応は未確認です。',
          'LoveLive-specific internal settings 0–4; the UI A–E mapping is unconfirmed.',
        ),
      ),
    );
  }
}

void _addOsu(List<JudgmentPreset> presets) {
  // Common OD values; speed=1, no timing-changing mods, no Classic/converted
  // mania branch. Do not add catch: its acceptance depends on position.
  for (final od in [0, 5, 10]) {
    final context = _reference(
      '2026.1005.0-lazer',
      '同版タグの公式ソース参照・OD$od・速度1・判定変更Modなし。maniaはClassic・コンバート分岐を除外。MISS外周とcatchは含めません。',
      'Official source at the matching tag; OD$od, speed=1, no timing-changing mods. Mania excludes Classic/converted branches. MISS perimeters and catch are excluded.',
    );
    presets.addAll(
      _series(
        id: 'osu_standard_od$od',
        game: 'osu!lazer',
        mode: 'osu!standard · OD$od',
        grades: ['300', '100', '50'],
        early: [
          for (final value in [80 - 6 * od, 140 - 8 * od, 200 - 10 * od])
            value.floorToDouble() - 0.5,
        ],
        context: context,
      ),
    );
    presets.addAll(
      _series(
        id: 'osu_taiko_od$od',
        game: 'osu!lazer',
        mode: 'osu!taiko · OD$od',
        grades: ['Great', 'Ok'],
        early: [
          (50 - 3 * od).floorToDouble() - 0.5,
          (od <= 5 ? 120 - 8 * od : 80 - 6 * (od - 5)).floorToDouble() - 0.5,
        ],
        context: context,
      ),
    );
    presets.addAll(
      _series(
        id: 'osu_mania_od$od',
        game: 'osu!lazer',
        mode: 'osu!mania · OD$od',
        grades: ['MAX/Perfect', '300/Great', '200/Good', '100/Ok', '50/Meh'],
        early: [
          for (final value in [
            od <= 5 ? 22.4 - 0.6 * od : 19.4 - 1.1 * (od - 5),
            64 - 3.0 * od,
            97 - 3.0 * od,
            127 - 3.0 * od,
            151 - 3.0 * od,
          ])
            value.floorToDouble() + 0.5,
        ],
        context: context,
      ),
    );
  }
}
