import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'Page/main_page.dart'; // MainScreenのインポート
import 'ParamData/settings_model.dart'; // SettingsModelのインポート

import 'package:musical_note_calculator/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dynamic_color/dynamic_color.dart';

import 'Theme/custom_theme.dart';
import 'Theme/materialDark.dart';
import 'Theme/materialLight.dart';

import 'dart:async';

void main() async {
  debugPrint('Rytmica: Start main()');
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('Rytmica: WidgetsFlutterBinding initialized');

  // SettingsModelを作成して初期化
  final settingsModel = SettingsModel();

  try {
    // 10秒でタイムアウトするように設定
    await settingsModel.initialize().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('Settings initialization timed out');
      },
    );
  } catch (e) {
    // エラーが発生した場合はエラー画面を表示
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 20),
                  const Text(
                    'Initialization Error',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Failed to initialize settings.\n$e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      // 再試行などの処理（現状はアプリ再起動が必要）
                    },
                    child: const Text('Please restart the app'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    // 元のmain処理を中断
    return;
  }

  runApp(
    ChangeNotifierProvider.value(
      value: settingsModel,
      child: const MyApp(),
    ),
  );
}

/// 画面回転の制御を行うウィジェット
class OrientationController extends StatefulWidget {
  final Widget child;
  const OrientationController({super.key, required this.child});

  @override
  State<OrientationController> createState() => _OrientationControllerState();
}

class _OrientationControllerState extends State<OrientationController> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setOrientations();
  }

  void _setOrientations() {
    // Foldables (including iPhone Duo), tablets, and resizable desktop
    // windows must be able to transition between every orientation. The
    // layout itself responds to the available width.
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsModel>(
      builder: (context, settings, child) {
        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            final bool isDynamicColorAvailable =
                lightDynamic != null && darkDynamic != null;
            context.read<SettingsModel>().setDynamicColorAvailability(
              isDynamicColorAvailable,
            );

            return MaterialApp(
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                AppLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en', 'US'),
                Locale('ja', 'JP'),
              ],
              title: 'MyApp',
              theme:
                  context.read<SettingsModel>().useMaterialYou &&
                      isDynamicColorAvailable
                  ? materialLightTheme(lightDynamic) // Dynamic Theme 有効かつ利用可能
                  : ThemeData.from(colorScheme: MaterialTheme.lightScheme())
                        .copyWith(
                          pageTransitionsTheme: const PageTransitionsTheme(
                            builders: {
                              TargetPlatform.android:
                                  PredictiveBackPageTransitionsBuilder(), // Androidで予測型戻るジェスチャーを有効化
                            },
                          ),
                        ),
              darkTheme:
                  context.read<SettingsModel>().useMaterialYou &&
                      isDynamicColorAvailable
                  ? materialDarkTheme(darkDynamic) // Dynamic Theme 有効かつ利用可能
                  : ThemeData.from(colorScheme: MaterialTheme.darkScheme())
                        .copyWith(
                          pageTransitionsTheme: const PageTransitionsTheme(
                            builders: {
                              TargetPlatform.android:
                                  PredictiveBackPageTransitionsBuilder(), // Androidで予測型戻るジェスチャーを有効化
                            },
                          ),
                        ),
              debugShowCheckedModeBanner: false,
              home: const OrientationController(
                child: MainScreen(),
              ),
            );
          },
        );
      },
    );
  }
}
