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
    '日本・英語・韓国・台湾版のデータをもとにした目安です。実際のプレイでの判定は未確認です。',
    'Based on data from the Japanese, English, Korean and Taiwanese versions. Timing in live play is unverified.',
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
        '通常タップの目安です。判定幅を広げるスキルの効果は含みません。',
        'Approximate values for normal taps, without skills that widen the timing window.',
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
        '押すタイミングの目安です。スライドを途中で離した場合の判定は別です。',
        'Use this for hit timing. Releasing a slide early has its own rules.',
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
        'D4U Editionの最高判定はPERFECTです。',
        'PERFECT is the highest grade in D4U Edition.',
      ),
    ),
  );
  final yumeste = _reference(
    '2.31.3',
    'タップとフリックでは判定幅が違います。ノーツに合う方を選んでください。',
    'Taps and flicks have different timing. Choose the preset for the note you’re playing.',
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
        '通常の打音を初期設定で叩くときの目安です。良は40 ms未満、可は90 ms未満です。',
        'For normal hits at default settings. 良 is under 40 ms and 可 is under 90 ms.',
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
        '通常モードでは、早く押したときだけBADが出ます。遅く押した場合は180 msまでがGOOD以上です。',
        'In Normal mode, only early hits can get BAD. Late hits within 180 ms can still get GOOD or better.',
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
        mode: '挑戦（$fps fps）',
        modeEn: 'Challenge ($fps fps)',
        grades: ['PERFECT', 'GOOD', 'BAD'],
        early: [40 + h, 90 + h, 140 + h],
        late: [40 + h, 90 + h, 90 + h],
        context: _reference(
          '4.0.1.2',
          '$fps fpsで安定しているときの目安です。判定幅は実際のフレームレートで変わります。BADが出るのは早押しだけです。',
          'Approximate values for a steady $fps fps. Timing varies with the actual frame rate. Only early hits can get BAD.',
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
        '判定は1 ms刻みです。ホールドや判定が変更された譜面では条件が異なります。',
        'Timing is judged in whole milliseconds. Holds and charts with custom timing use different rules.',
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
        '通常タップ用です。アークやホールドには、指を動かしたり押し続けたりする条件もあります。',
        'For normal taps. Arcs and holds also check how you move or hold your finger.',
      ),
      existingIds: {0: 'arcaea_internal_pure', 1: 'arcaea_pure'},
    ),
  );
  for (final row in [
    (
      'tap',
      'タップ',
      'Tap',
      <double>[1 * _frameMs, 50, 100, 150],
      <double>[1 * _frameMs, 50, 100, 150],
    ),
    (
      'hold',
      'ホールド',
      'Hold',
      <double>[1 * _frameMs, 50, 100, 150],
      <double>[1 * _frameMs, 8 * _frameMs, 11 * _frameMs, 14 * _frameMs],
    ),
    (
      'touch',
      'タッチ',
      'Touch',
      <double>[150, 150, 150, 150],
      <double>[150, 13 * _frameMs, 250, 300],
    ),
    (
      'slide_finish',
      'スライド終点',
      'Slide finish',
      <double>[14 * _frameMs, 26 * _frameMs, 600],
      <double>[14 * _frameMs, 26 * _frameMs, 600],
    ),
  ]) {
    presets.addAll(
      _series(
        id: 'astrodx_${row.$1}',
        game: 'AstroDX',
        mode: row.$2,
        modeEn: row.$3,
        grades: row.$1 == 'slide_finish'
            ? ['CRITICAL PERFECT', 'GREAT', 'GOOD']
            : ['CRITICAL PERFECT', 'PERFECT', 'GREAT', 'GOOD'],
        early: row.$4,
        late: row.$5,
        context: _reference(
          '2.0.0.beta.pre.96.exp.8',
          'ホールドは押し続けた長さも判定に入ります。スライド終点はCRITICAL PERFECTの次がGREATです。',
          'Hold also checks how long you held the note. For SlideFinish, GREAT comes right after CRITICAL PERFECT.',
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
        '曲の再生速度が等倍で、判定を初期設定のまま使う場合の目安です。',
        'For normal song speed with the default timing settings.',
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
        'プレイ中のGREATとGOODの目安です。',
        'Approximate timing for GREAT and GOOD during play.',
      ),
    ),
  );
  _addMillionLive(presets);
  for (final row in [
    (
      'regular',
      '通常・スライド始点・スキル・キメ',
      'Normal / Slide start / Skill / Kime',
      <double>[30, 50, 5 * _frameMs, 8 * _frameMs],
      <double>[30, 50, 5 * _frameMs, 8 * _frameMs],
    ),
    (
      'flick',
      'フリック',
      'Flick',
      <double>[5 * _frameMs, 5 * _frameMs, 5 * _frameMs, 5 * _frameMs],
      <double>[40, 50, 5 * _frameMs, 8 * _frameMs],
    ),
    (
      'slide_end',
      'スライド終点',
      'Slide end',
      <double>[5.5 * _frameMs, 5.5 * _frameMs, 0, 0],
      <double>[30, 50, 4 * _frameMs, 100],
    ),
    (
      'slide_joint',
      'スライド中継点',
      'Slide joint',
      <double>[2 * _frameMs, 2 * _frameMs, 0, 0],
      <double>[2 * _frameMs, 2 * _frameMs, 4 * _frameMs, 4 * _frameMs],
    ),
  ]) {
    presets.addAll(
      _series(
        id: 'shinycolors_${row.$1}',
        game: 'シャニソン',
        mode: row.$2,
        modeEn: row.$3,
        grades: ['SHINY', 'PERFECT', 'GREAT', 'GOOD'],
        early: row.$4,
        late: row.$5,
        context: _reference(
          '2.19.1',
          'SHINYを有効にしたときの判定幅です。スライドやフリックでは指の動きも判定されます。',
          'Timing with SHINY enabled. Slides and flicks also check finger movement.',
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
        '通常ノーツ用です。フリックは別の判定幅で、指の動きも判定されます。',
        'For normal notes. Flicks use their own timing and also check the gesture.',
      ),
    ),
  );
  for (final row in [
    (
      'normal',
      '通常・ロング始点',
      'Normal / Long start',
      ['PERFECT+', 'PERFECT', 'GREAT', 'GOOD', 'BAD'],
      <double>[25, 4 * _frameMs, 100, 8 * _frameMs, 150],
      <double>[25, 50, 5 * _frameMs, 7 * _frameMs, 8 * _frameMs],
    ),
    (
      'flick',
      'フリック・ロング終点フリック',
      'Flick / Long end flick',
      ['PERFECT+', 'PERFECT', 'BAD'],
      <double>[25, 100, 150],
      <double>[25, 5 * _frameMs, 8 * _frameMs],
    ),
    (
      'critical',
      'クリティカル（通常・ロング始点）',
      'Critical (Normal / Long start)',
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
        modeEn: row.$3,
        grades: row.$4,
        early: row.$5,
        late: row.$6,
        context: _reference(
          '1.2.101',
          'クリティカル対象のノーツでは、GREATやGOODのタイミングでもPERFECTになることがあります。',
          'On critical notes, a hit timed for GREAT or GOOD can count as PERFECT.',
        ),
      ),
    );
  }
  for (final row in [
    (
      'normal',
      '通常',
      'Normal',
      ['PERFECT', 'GREAT', 'GOOD', 'BAD'],
      <double>[45, 90, 120, 150],
    ),
    (
      'type21',
      '特殊ノーツ（ID 21）',
      'Special note (ID 21)',
      ['PERFECT', 'GREAT', 'GOOD', 'BAD'],
      <double>[90, 180, 240, 300],
    ),
    (
      'type30_32',
      '特殊ノーツ（ID 30〜32）',
      'Special note (IDs 30–32)',
      ['PERFECT'],
      <double>[90],
    ),
    (
      'type62',
      '特殊ノーツ（ID 62）',
      'Special note (ID 62)',
      ['PERFECT'],
      <double>[120],
    ),
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
          '特殊ノーツはゲーム内データの番号で表示しています。画面上のノーツ名との対応は未確認です。',
          'Special notes are listed by their data IDs. The matching in-game note names are unconfirmed.',
        ),
      ),
    );
  }
  for (final row in [
    (
      'tap',
      'タップ',
      'Tap',
      ['JUST PERFECT', 'PERFECT', 'GREAT', 'GOOD', 'BAD'],
      <double>[20, 50, 100, 150, 200],
    ),
    (
      'long_end_flick',
      'ロング終点フリック',
      'Long end flick',
      ['JUST PERFECT', 'PERFECT'],
      <double>[37.5, 75],
    ),
    (
      'sky_start',
      'Sky始点',
      'Sky start',
      ['JUST PERFECT', 'PERFECT', 'GREAT', 'GOOD'],
      <double>[25, 50, 100, 150],
    ),
    (
      'sky_end',
      'Sky終点',
      'Sky end',
      ['JUST PERFECT', 'PERFECT', 'GREAT', 'GOOD'],
      <double>[37.5, 75, 150, 175],
    ),
    (
      'other',
      'その他',
      'Other',
      ['JUST PERFECT', 'PERFECT', 'GREAT', 'GOOD', 'BAD'],
      <double>[37.5, 75, 150, 175, 200],
    ),
    (
      'classic',
      'Classicタップ',
      'Classic tap',
      ['PERFECT', 'GREAT', 'GOOD', 'BAD'],
      <double>[50.1, 100, 167, 234],
    ),
  ]) {
    presets.addAll(
      _series(
        id: 't7s_${row.$1}',
        game: 'Tokyo 7th シスターズ',
        mode: row.$2,
        modeEn: row.$3,
        grades: row.$4,
        early: row.$5,
        context: _reference(
          '13.0.3',
          '通常プレイとClassicでは判定幅が違います。Classicのタップには「Classicタップ」を選んでください。',
          'Normal play and Classic have different timing. Choose Classic tap for taps in Classic mode.',
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
        'LB JUSTとP JUSTの扱いは、ゲーム内の表示設定やスコア方式で変わります。',
        'How LB JUST and P JUST are counted depends on your display and scoring settings.',
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
        label: '${row.$3}（参考）',
        labelEn: '${row.$3} (estimate)',
        earlyMs: row.$4,
        lateMs: row.$4,
        context: const JudgmentPresetContext(
          version: '',
          noteJa: '以前からある参考値です。出典や対象バージョン、今の判定幅は未確認です。',
          noteEn: 'An older estimate. Its source, game version and current accuracy are unverified.',
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
      '強化前の判定幅です。アシストLvはゲーム内データの番号で、画面上の設定名との対応は未確認です。',
      'Timing before skill effects. Assist levels use numbers from the game data. The matching menu options are unconfirmed.',
    );
    for (final row in [
      (
        'normal',
        '通常・スライド始点',
        'Normal / Slide start',
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
        '通常・スライド始点（Easy）',
        'Normal / Slide start (Easy)',
        ['JUST (内部)', 'PERFECT'],
        <double>[2, 67.0 + 5 * level],
        <double>[2, 67.0 + 5 * level],
      ),
      (
        'flick',
        'フリック',
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
        'スライド終点フリック',
        'Slide end flick',
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
        'スライド終点',
        'Slide end',
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
          mode: '${row.$2}（アシストLv$level）',
          modeEn: '${row.$3} (Assist Lv $level)',
          grades: row.$4,
          early: row.$5,
          late: row.$6,
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
      '譜面 thanky（2レーン #0 / 4レーン #0〜3）',
      'Chart thanky (2 lanes #0 / 4 lanes #0–3)',
      <double>[5, 9, 14],
      16.0,
    ),
    (
      'thanky_2lane1_6lane0',
      '譜面 thanky（2レーン #1 / 6レーン #0）',
      'Chart thanky (2 lanes #1 / 6 lanes #0)',
      <double>[3, 6, 11],
      13.0,
    ),
    (
      'thanky_2lane23_6lane123',
      '譜面 thanky（2レーン #2〜3 / 6レーン #1〜3）',
      'Chart thanky (2 lanes #2–3 / 6 lanes #1–3)',
      <double>[3, 6, 9],
      11.0,
    ),
    (
      'bnthtr_6lane2',
      '譜面 bnthtr（6レーン #2）',
      'Chart bnthtr (6 lanes #2)',
      <double>[2, 6, 9],
      11.0,
    ),
  ]) {
    for (final release in [false, true]) {
      presets.addAll(
        _series(
          id: 'mltd_${row.$1}_${release ? 'release' : 'tap'}',
          game: 'ミリシタ',
          mode: '${row.$2} · ${release ? 'フリック／ホールド終点' : 'タップ'}',
          modeEn: '${row.$3} · ${release ? 'Flick / Hold end' : 'Tap'}',
          grades: ['PERFECT', 'GREAT', 'GOOD'],
          early: [
            for (final frames in row.$4)
              min(frames * _frameMs + (release ? 50 : 0), row.$5 * _frameMs),
          ],
          context: _reference(
            '9.0.350',
            'この曲・譜面だけの参考値です。譜面番号とゲーム内のコース名の対応は未確認です。',
            'These values apply only to this song and chart. The matching in-game course names are unconfirmed.',
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
          mode: '${row.$2}（設定 $setting）',
          modeEn: '${row.$2} (Setting $setting)',
          grades: ['BEST', 'COOL', 'GOOD'],
          early: [for (final value in row.$3) value + delta],
          context: _reference(
            '4.3.7',
            '判定設定はゲーム内データの番号で表示しています。画面上のA〜Eとの対応は未確認です。',
            'Timing settings use numbers from the game data. The matching A–E menu options are unconfirmed.',
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
        mode: 'LoveLive（設定 $setting）',
        modeEn: 'LoveLive (Setting $setting)',
        grades: ['BEST', 'COOL', 'GOOD'],
        early: [
          <double>[52, 46, 40, 36, 32][setting],
          <double>[130, 115, 100, 90, 80][setting],
          <double>[208, 184, 160, 144, 128][setting],
        ],
        context: _reference(
          '4.3.7',
          'LoveLiveモード用です。設定番号と画面上のA〜Eとの対応は未確認です。',
          'For LoveLive mode. The matching A–E menu options are unconfirmed.',
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
      '等速で、判定幅を変えるModを使わない場合の値です。',
      'For normal speed without mods that change timing.',
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
        context: _reference(
          context.version,
          'mania専用譜面を等速・判定変更Modなしで遊ぶ場合の値です。Classicの判定も対象外です。',
          'For native mania charts at normal speed with no timing mods or Classic settings.',
        ),
      ),
    );
  }
}
