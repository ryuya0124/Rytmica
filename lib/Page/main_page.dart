import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:musical_note_calculator/l10n/app_localizations.dart';

import '../UI/adaptive_layout.dart';
import '../UI/app_bar.dart';
import '../UI/bottom_navigation_bar.dart';
import '../UI/bpm_input_section.dart';
import '../UI/modern_side_bar.dart';
import 'AnmitsuChecker/anmitsu_checker_page.dart';
import 'Home/home_page.dart';
import 'Metronome/metronome_content.dart';
import 'calculator_page.dart';
import 'note_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = const int.fromEnvironment(
    'RYTMICA_SCREENSHOT_PAGE',
    defaultValue: 0,
  );
  late final TextEditingController bpmController;
  final FocusNode bpmFocusNode = FocusNode();
  late final List<Widget> _pages;
  bool _showMetronomePanel = false;
  double _metronomeBpm = 120;
  String _metronomeNote = 'quarter_note';
  String _metronomeInterval = '0';

  @override
  void initState() {
    super.initState();
    bpmController = TextEditingController(
      text: const String.fromEnvironment('RYTMICA_SCREENSHOT_BPM'),
    );
    _pages = [
      HomePage(
        bpmController: bpmController,
        bpmFocusNode: bpmFocusNode,
        onMetronomeRequest: _openMetronomePanel,
      ),
      NotePage(
        bpmController: bpmController,
        bpmFocusNode: bpmFocusNode,
        onMetronomeRequest: _openMetronomePanel,
      ),
      CalculatorPage(
        bpmController: bpmController,
        bpmFocusNode: bpmFocusNode,
        onMetronomeRequest: _openMetronomePanel,
      ),
      AnmituCheckerPage(
        bpmController: bpmController,
        bpmFocusNode: bpmFocusNode,
      ),
    ];
  }

  @override
  void dispose() {
    bpmController.dispose();
    bpmFocusNode.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
      _showMetronomePanel = false;
    });
  }

  void _toggleMetronomePanel() {
    setState(() {
      if (!_showMetronomePanel) {
        _metronomeBpm = double.tryParse(bpmController.text) ?? 120;
      }
      _showMetronomePanel = !_showMetronomePanel;
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

  List<ModernSideBarItem> _destinations(BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    // Let Flutter select a usable sub-screen when a physical hinge or a
    // separating fold exists. The continuous iPhone Duo display uses the
    // whole window, with its asymmetric camera/status-bar insets.
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: DisplayFeatureSubScreen(
        child: SafeArea(
          top: false,
          bottom: false,
          child: LayoutBuilder(
            builder: (context, viewport) {
              final layout = AdaptiveLayoutInfo(
                size: Size(viewport.maxWidth, viewport.maxHeight),
                displayFeatures: const [],
              );
              final useRail = layout.usesNavigationRail;
              final extended = layout.usesExtendedNavigationRail;
              final colors = Theme.of(context).colorScheme;
              final destinations = _destinations(context);
              final railWidth = useRail ? (extended ? 241.0 : 89.0) : 0.0;
              final panelWidth = layout.supportsInlinePanel
                  ? math.min(400.0, viewport.maxWidth - railWidth - 360.0)
                  : viewport.maxWidth;
              final inlinePanel =
                  _showMetronomePanel && layout.supportsInlinePanel;
              final overlayPanel = _showMetronomePanel && !inlinePanel;

              // Keep the scaffold, input, and page subtree at the same element
              // positions on resize. Folding must not dispose page controllers,
              // selection, scroll positions, focus, or the playing metronome.
              return Scaffold(
                appBar: AppBarWidget(
                  selectedIndex: _selectedIndex,
                  actions: [
                    if (_selectedIndex == 0 || _showMetronomePanel)
                      IconButton(
                        key: const ValueKey('metronome-toggle'),
                        icon: Icon(
                          _showMetronomePanel
                              ? Icons.close
                              : Icons.av_timer_outlined,
                        ),
                        onPressed: _toggleMetronomePanel,
                        tooltip: AppLocalizations.of(context)!.metronome,
                      ),
                  ],
                ),
                body: SafeArea(
                  top: false,
                  child: Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          right: inlinePanel ? panelWidth : 0,
                        ),
                        child: ExcludeFocus(
                          excluding: overlayPanel,
                          child: ExcludeSemantics(
                            excluding: overlayPanel,
                            child: IgnorePointer(
                              ignoring: overlayPanel,
                              child: Row(
                                children: [
                                  Offstage(
                                    offstage: !useRail,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ModernSideBar(
                                          selectedIndex: _selectedIndex,
                                          onDestinationSelected: _onTabSelected,
                                          isExtended: extended,
                                          destinations: destinations,
                                        ),
                                        VerticalDivider(
                                          width: 1,
                                          thickness: 1,
                                          color: colors.outlineVariant,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        if (useRail &&
                                            !extended &&
                                            viewport.maxHeight >= 600)
                                          Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                destinations[_selectedIndex]
                                                    .label,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge,
                                              ),
                                            ),
                                          ),
                                        // A key preserves this subtree when the
                                        // optional heading above is inserted.
                                        Expanded(
                                          key: const ValueKey('main-workflow'),
                                          child: Column(
                                            children: [
                                              BpmInputSection(
                                                bpmController: bpmController,
                                                bpmFocusNode: bpmFocusNode,
                                              ),
                                              Expanded(
                                                child: LayoutBuilder(
                                                  builder: (context, bounds) {
                                                    return SingleChildScrollView(
                                                      child: SizedBox(
                                                        height: math.max(
                                                          bounds.maxHeight,
                                                          520,
                                                        ),
                                                        child: IndexedStack(
                                                          index: _selectedIndex,
                                                          children: _pages,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_showMetronomePanel)
                        Positioned(
                          key: const ValueKey('metronome-panel'),
                          top: 0,
                          bottom: 0,
                          right: 0,
                          width: panelWidth,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.surface,
                              border: Border(
                                left: BorderSide(color: colors.outlineVariant),
                              ),
                            ),
                            child: MetronomeContent(
                              bpm: _metronomeBpm,
                              note: _metronomeNote,
                              interval: _metronomeInterval,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                bottomNavigationBar: useRail
                    ? null
                    : BottomNavigationBarWidget(
                        selectedIndex: _selectedIndex,
                        onTabSelected: _onTabSelected,
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}
