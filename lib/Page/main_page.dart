import 'package:flutter/material.dart';
import 'package:musical_note_calculator/Page/AnmitsuChecker/anmitsu_checker_page.dart';

import 'Home/home_page.dart';
import 'note_page.dart';
import 'calculator_page.dart';
import '../UI/bottom_navigation_bar.dart'; // ナビゲーションバーをインポート
import '../UI/app_bar.dart';
import '../UI/bpm_input_section.dart';

import 'package:flutter/services.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';

import 'Metronome/metronome_content.dart';
import '../UI/modern_side_bar.dart'; // import追加
import '../UI/adaptive_layout.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // 現在選択されているタブのインデックス
  late TextEditingController bpmController;
  late FocusNode bpmFocusNode;
  late List<Widget> _pages;

  // Split View用の状態
  bool _showMetronomePanel = false;
  double _metronomeBpm = 120.0;
  String _metronomeNote = '4';
  String _metronomeInterval = '0';

  // タブ選択時の処理
  void _onTabSelected(int index) {
    if (_selectedIndex == index) {
      return; // 同じタブが選択された場合は何もしない
    }
    setState(() {
      _selectedIndex = index; // 選択されたインデックスを更新
      _showMetronomePanel = false; // タブ切り替え時にメトロノームパネルを閉じる (UX改善)
    });
  }

  void _toggleMetronomePanel() {
    setState(() {
      _showMetronomePanel = !_showMetronomePanel;
      // パネルを開くとき、もしBPMがデフォルトのままなら現在の入力値をセットするなどの配慮も可能だが、
      // ここでは前回の状態または初期値を維持する。
      // ただし、初めて開くときは入力欄の値を反映させたい場合はここで処理する。
      if (_showMetronomePanel) {
        final currentInputBpm = double.tryParse(bpmController.text);
        if (currentInputBpm != null) {
          _metronomeBpm = currentInputBpm;
        }
      }
    });
  }

  void _openMetronomePanel(double bpm, String note, String interval) {
    setState(() {
      _metronomeBpm = bpm;
      _metronomeNote = note;
      _metronomeInterval = interval;
      _showMetronomePanel = true;
    });
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    bpmFocusNode = FocusNode();
    bpmController = TextEditingController();

    // 各タブに対応するページリスト
    // GlobalKeyを使って状態を保持し、レイアウト変更時のリビルドによるFocusNode破棄エラーを防ぐ
    _pages = [
      HomePage(
        bpmController: bpmController,
        bpmFocusNode: bpmFocusNode,
        onMetronomeRequest: _openMetronomePanel,
      ), // ホームページ
      NotePage(
        bpmController: bpmController,
        bpmFocusNode: bpmFocusNode,
        onMetronomeRequest: _openMetronomePanel,
      ), // ノートページ
      CalculatorPage(
        bpmController: bpmController,
        bpmFocusNode: bpmFocusNode,
        onMetronomeRequest: _openMetronomePanel,
      ), // 計算機ページ
      AnmituCheckerPage(
        bpmController: bpmController,
        bpmFocusNode: bpmFocusNode,
      ), // 餡蜜チェッカーページ
    ];
  }

  @override
  void dispose() {
    bpmController.dispose();
    bpmFocusNode.dispose();
    super.dispose();
  }

  /// ModernSideBar用のアイテムリストを構築
  List<ModernSideBarItem> _buildSideBarItems(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return [
      ModernSideBarItem(
        icon: Icons.music_note,
        selectedIcon: Icons.music_note,
        label: loc.note_spacing,
      ),
      ModernSideBarItem(
        icon: Icons.music_note_outlined,
        selectedIcon: Icons.music_note_outlined,
        label: loc.note_count,
      ),
      ModernSideBarItem(
        icon: Icons.calculate_outlined,
        selectedIcon: Icons.calculate,
        label: loc.calculator,
      ),
      ModernSideBarItem(
        icon: Icons.music_note_sharp,
        selectedIcon: Icons.music_note_sharp,
        label: loc.anmitu,
      ),
    ];
  }

  /// メインコンテンツ部分を構築
  Widget _buildMainContent() {
    return Column(
      children: [
        // BpmInputSection をページリストの上に追加
        BpmInputSection(
          bpmController: bpmController,
          bpmFocusNode: bpmFocusNode,
        ),
        Expanded(
          // ページリスト
          child: Stack(
            children: List.generate(_pages.length, (index) {
              return Offstage(
                offstage: _selectedIndex != index,
                child: _pages[index], // 現在選択されているページのみ表示
              );
            }),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final layout = AdaptiveLayoutInfo.of(context);
    final isExtendedRail = layout.usesExtendedNavigationRail;
    final colorScheme = Theme.of(context).colorScheme;

    // Medium/expanded windows: NavigationRail + main content. This also
    // responds correctly while an iPhone Duo unfolds or rotates.
    if (layout.usesNavigationRail) {
      return Scaffold(
        appBar: AppBarWidget(
          selectedIndex: _selectedIndex,
          actions: [
            // メトロノームパネルの表示切り替えボタン（音価計算タブ表示中 または パネル展開中のみ表示）
            if (_selectedIndex == 0 || _showMetronomePanel)
              IconButton(
                icon: Icon(
                  _showMetronomePanel
                      ? Icons.av_timer_rounded
                      : Icons.av_timer_outlined,
                  color: _showMetronomePanel
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
                onPressed: _toggleMetronomePanel,
                tooltip: AppLocalizations.of(context)!.metronome,
              ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth - layout.foldGap;
            final railWidth = isExtendedRail ? 240.0 : 88.0;
            // コンテンツエリアの最小幅を確保 (例: 320px)
            const minContentWidth = 320.0;

            // パネルの目標幅
            const targetPanelWidth = 400.0;

            // パネルに割り当て可能な最大幅
            final maxPanelWidth = availableWidth - railWidth - minContentWidth;

            // 実際のパネル幅 (目標幅と最大幅の小さい方、かつ0以上)
            // ただし、パネル幅が極端に小さくなる場合は、OverflowBoxで中身は固定幅を維持しつつ、
            // コンテナ自体の幅を縮小して、メインコンテンツを優先する。
            final panelWidth = _showMetronomePanel && layout.supportsInlinePanel
                ? (maxPanelWidth < targetPanelWidth
                      ? (maxPanelWidth > 0 ? maxPanelWidth : 0.0)
                      : targetPanelWidth)
                : 0.0;

            return Row(
              children: [
                ModernSideBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onTabSelected,
                  isExtended: isExtendedRail,
                  destinations: _buildSideBarItems(context),
                ),
                VerticalDivider(
                  thickness: 1,
                  width: 1,
                  color: colorScheme.outlineVariant,
                ),

                // メインコンテンツエリア
                Expanded(
                  flex: 2, // メイン画面の比率 (パネル幅が固定/計算済みなのでflexはあまり意味を持たないが、Expandedで残り埋める)
                  child: Column(
                    children: [
                      // サイドバーが折り畳まれている時のみタブ名を表示（アニメーション付き）
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, animation) {
                          return SizeTransition(
                            sizeFactor: animation,
                            alignment: Alignment.topCenter,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: !isExtendedRail
                            ? Container(
                                key: const ValueKey('tabTitle'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                alignment: Alignment.centerLeft,
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: colorScheme.outlineVariant,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _buildSideBarItems(
                                    context,
                                  )[_selectedIndex].label,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              )
                            : const SizedBox.shrink(key: ValueKey('empty')),
                      ),
                      Expanded(child: _buildMainContent()),
                    ],
                  ),
                ),

                if (layout.foldGap > 0) SizedBox(width: layout.foldGap),

                // メトロノームパネル (Split View)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: panelWidth, // 計算した幅を使用
                  child: ClipRect(
                    // 幅0の時の中身をクリップして非表示に
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: colorScheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        color: colorScheme.surfaceContainerLowest, // 少し背景色を変える
                      ),
                      child: OverflowBox(
                        // 幅が小さくなってもレイアウトを崩さない
                        minWidth: 400,
                        maxWidth: 400,
                        child: MetronomeContent(
                          // コントローラーの値を使って初期化。
                          bpm: _metronomeBpm,
                          note: _metronomeNote,
                          interval: _metronomeInterval,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    // Compact windows: bottom navigation. SafeArea keeps controls clear of
    // the home indicator and the rounded corners on iPhone models.
    return Scaffold(
      appBar: AppBarWidget(
        selectedIndex: _selectedIndex,
      ),
      body: SafeArea(top: false, child: _buildMainContent()),
      bottomNavigationBar: BottomNavigationBarWidget(
        selectedIndex: _selectedIndex,
        onTabSelected: _onTabSelected, // コールバックを渡す
      ),
    );
  }
}
