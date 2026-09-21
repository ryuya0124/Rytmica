import 'package:flutter/material.dart';

import '../../UI/app_bar.dart';
import 'metronome_content.dart';

class MetronomePage extends StatefulWidget {
  final double bpm;
  final String note;
  final String interval;

  const MetronomePage({
    super.key,
    required this.bpm,
    required this.note,
    required this.interval,
  });

  @override
  MetronomePageState createState() => MetronomePageState();
}

class MetronomePageState extends State<MetronomePage> {
  final _selectedIndex = 4;
  bool _shouldPop = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;

    if (width >= 600) {
      if (!_shouldPop) {
        _shouldPop = true;
        // ポップ処理を少し遅らせることで、Navigatorのロック状態や競合を回避する
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && ModalRoute.of(context)?.isCurrent == true) {
            Navigator.of(context).pop({'switchToSplit': true});
          }
          if (mounted) {
            setState(() {
              _shouldPop = false;
            });
          } else {
            _shouldPop = false;
          }
        });
      }
    } else {
      _shouldPop = false;
    }

    return Scaffold(
      appBar: AppBarWidget(selectedIndex: _selectedIndex),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
              colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: MetronomeContent(
          bpm: widget.bpm,
          note: widget.note,
          interval: widget.interval,
        ),
      ),
    );
  }
}
