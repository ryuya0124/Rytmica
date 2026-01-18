import 'dart:async';
import 'package:flutter/material.dart';
import 'package:metronome/metronome.dart';
import '../../ParamData/notes.dart';
import 'UI/metronome_visualizer.dart';
import 'UI/metronome_display.dart';
import 'UI/metronome_controls.dart';

class MetronomeContent extends StatefulWidget {
  final double bpm;
  final String note;
  final String interval;

  const MetronomeContent({
    super.key,
    required this.bpm,
    required this.note,
    required this.interval,
  });

  @override
  MetronomeContentState createState() => MetronomeContentState();
}

class MetronomeContentState extends State<MetronomeContent>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final metronome = Metronome();
  late double _currentQuarterBpm;
  late String note;
  late String intervalTime;
  int vol = 100;
  bool isPlaying = false;
  bool _wasPlayingBeforePause = false;

  // 拍関連
  final List<int> beatOptions = [1, 2, 3, 4, 5, 6];
  static const int customBeatSentinel = -1;
  int selectedBeatOption = 4;
  int? customBeats;

  final _isPlayingController = StreamController<bool>.broadcast();
  late AnimationController _animationController;
  late Animation<double> _animation;


  // 音源のパス
  final String strongTick = 'metronome/metronome_tick_strong_48k_mono.wav';
  final String weakTick = 'metronome/metronome_tick_weak_48k_mono.wav';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // ウィジェットのパラメータで初期化
    note = widget.note;
    intervalTime = widget.interval;
    _currentQuarterBpm = convertNoteDurationToBPM(widget.bpm, note);
    if (_currentQuarterBpm <= 0) {
      _currentQuarterBpm = 1;
    }

    // アニメーション初期化
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (60000 / _currentQuarterBpm).round()),
      value: 0.5, // 初期位置を中央に設定
    );
    // 振り子の動き: -1.0 (左) <-> 1.0 (右)
    // easeInOutSine で自然な減速・加速を表現
    _animation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutSine,
      ),
    );

    _initMetronome();
  }

  @override
  void didUpdateWidget(MetronomeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bpm != oldWidget.bpm || widget.note != oldWidget.note) {
      note = widget.note;
      intervalTime = widget.interval;
      _currentQuarterBpm = convertNoteDurationToBPM(widget.bpm, note);
      if (_currentQuarterBpm <= 0) {
        _currentQuarterBpm = 1;
      }
      
      // アニメーション速度更新
      _animationController.duration = Duration(milliseconds: (60000 / _currentQuarterBpm).round());
      if (isPlaying) {
        _animationController.repeat(reverse: true);
        metronome.setBPM(_currentQuarterBpm.toInt());
      } else {
        metronome.setBPM(_currentQuarterBpm.toInt());
      }
    }
  }

  void _initMetronome() {
    try {
      metronome.init(
        'assets/$weakTick', // 弱拍
        accentedPath: 'assets/$strongTick', // 強拍（1拍目）
        bpm: _currentQuarterBpm.toInt(),
        volume: vol,
        enableTickCallback: true, // 音源修正済みのため有効化
        timeSignature: selectedBeatOption,
        sampleRate: 48000, // Assets (weak) に合わせて48000に変更
      );
      debugPrint('Metronome initialized successfully');
    } catch (e) {
      debugPrint('Metronome initialization failed: $e');
    }
  }

  @override
  void dispose() {
    stopMetronome();
    metronome.destroy();
    _isPlayingController.close();
    _animationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.inactive:
        _handleBackgroundTransition();
        break;

      case AppLifecycleState.paused:
        _handleBackgroundTransition();
        break;

      case AppLifecycleState.resumed:
        if (_wasPlayingBeforePause) {
          startMetronome();
        }
        _wasPlayingBeforePause = false;
        break;

      case AppLifecycleState.detached:
        dispose();
        break;

      case AppLifecycleState.hidden:
        _handleBackgroundTransition();
        break;
    }
  }

  void _handleBackgroundTransition() {
    if (isPlaying) {
      _wasPlayingBeforePause = true;
      stopMetronome();
    }
  }

  void toggleMetronome() {
    if (isPlaying) {
      stopMetronome();
    } else {
      startMetronome();
    }
  }

  void startMetronome() {
    if (isPlaying) return;

    debugPrint('Starting metronome...');
    _currentQuarterBpm = convertNoteDurationToBPM(widget.bpm, note);
    if (_currentQuarterBpm <= 0) {
      _currentQuarterBpm = 1;
    }
    
    final beats = _currentBeats;
    metronome.setBPM(_currentQuarterBpm.toInt());
    metronome.setTimeSignature(beats);
    debugPrint('Calling metronome.play() with BPM=${_currentQuarterBpm.toInt()}, beats=$beats');
    metronome.play();
    debugPrint('metronome.play() called');

    // アニメーション開始 (Duration設定 -> Repeat)
    _animationController.duration = Duration(milliseconds: (60000 / _currentQuarterBpm).round());
    _animationController.repeat(reverse: true);

    setState(() {
      isPlaying = true;
    });
    _isPlayingController.sink.add(true);
  }

  void stopMetronome() {
    if (!isPlaying) return;
    debugPrint('Stopping metronome...');
    metronome.stop();
    debugPrint('metronome.stop() called');

    _animationController.stop();
    // 現在のBPMに基づいて戻る時間を計算 (例: 4分音符の時間の半分)
    // 速いBPMなら速く、遅いBPMならゆっくり戻る
    final returnDurationMs = (30000 / _currentQuarterBpm).round();
    
    _animationController.animateTo(
      0.5,
      // 極端に遅くならないように上限などを設けても良いが、まずはBPMに忠実に従う
      duration: Duration(milliseconds: returnDurationMs),
      curve: Curves.easeOut,
    );

    setState(() {
      isPlaying = false;
    });
    _isPlayingController.sink.add(false);
  }

  @override
  Widget build(BuildContext context) {
    // LayoutBuilderを使用して、親ウィジェットの実際の幅に基づいてレイアウトを決定
    // Split Viewでは親の幅が制限されるため、MediaQueryではなくLayoutBuilderを使用
    return LayoutBuilder(
      builder: (context, constraints) {
        // 親の幅に基づいてレイアウトを決定
        // Split Viewパネルは通常400px程度なので、700px以上の場合のみ横並びレイアウト
        final isWide = constraints.maxWidth >= 700;

        return Container(
          color: Colors.transparent,
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 24.0 : 16.0,
                vertical: 24.0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 900 : 500),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 左側: メトロノームビジュアライザー
                          Expanded(
                            flex: 1,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                MetronomeVisualizer(animation: _animation),
                                const SizedBox(height: 20),
                                MetronomeDisplay(
                                  bpm: widget.bpm,
                                  note: note,
                                  intervalTime: intervalTime,
                                  quarterNoteBpm: convertNoteDurationToBPM(widget.bpm, note),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),
                          // 右側: コントロールパネル
                          Expanded(
                            flex: 1,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildControls(),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MetronomeVisualizer(animation: _animation),
                          const SizedBox(height: 20),
                          MetronomeDisplay(
                            bpm: widget.bpm,
                            note: note,
                            intervalTime: intervalTime,
                            quarterNoteBpm: convertNoteDurationToBPM(widget.bpm, note),
                          ),
                          const SizedBox(height: 28),
                          _buildControls(),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
      return MetronomeControls(
        vol: vol,
        isPlaying: isPlaying,
        selectedBeatOption: selectedBeatOption,
        customBeats: customBeats,
        note: note,
        beatOptions: beatOptions,
        onVolumeChanged: (val) {
          setState(() {
            vol = val;
          });
          metronome.setVolume(vol);
        },
        onToggle: toggleMetronome,
        onBeatOptionChanged: (val) {
          setState(() {
            selectedBeatOption = val;
          });
          if (isPlaying) {
            stopMetronome();
            startMetronome();
          }
        },
        onCustomBeatsChanged: (val) {
          setState(() {
            customBeats = val;
          });
          if (isPlaying && val > 0) {
            stopMetronome();
            startMetronome();
          }
        },
      );
  }

  double convertNoteDurationToBPM(double bpm, String note) {
    final noteData = findNoteData(note);
    // 4分音符基準でBPMを計算
    final quarterNote = findNoteData('quarter_note');
    return calculateNoteBPM(bpm, noteData, quarterNote);
  }

  int get _currentBeats {
    if (selectedBeatOption == customBeatSentinel) {
      return (customBeats != null && customBeats! > 0) ? customBeats! : 4;
    }
    return selectedBeatOption;
  }
}
