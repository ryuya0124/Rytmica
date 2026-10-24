import 'package:material_ui/material_ui.dart';

ThemeData materialLightTheme(ColorScheme lightColorScheme) {
  return ThemeData(
    colorScheme: lightColorScheme,
    useMaterial3: true,

    // アプリバーのテーマ
    appBarTheme: AppBarTheme(
      backgroundColor: lightColorScheme.primary,
      foregroundColor: lightColorScheme.onPrimary,
    ),

    // ボタンのテーマ
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightColorScheme.primary,
        foregroundColor: lightColorScheme.onPrimary,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: lightColorScheme.primary,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: lightColorScheme.primary,
        side: BorderSide(color: lightColorScheme.primary),
      ),
    ),

    // カードのテーマ
    cardTheme: CardThemeData(
      color: lightColorScheme.surface,
      shadowColor: lightColorScheme.shadow,
      elevation: 2,
    ),

    // スナックバーのテーマ
    snackBarTheme: SnackBarThemeData(
      backgroundColor: lightColorScheme.surface,
      contentTextStyle: TextStyle(color: lightColorScheme.onSurface),
    ),

    // テキストフィールドのテーマ
    inputDecorationTheme: InputDecorationTheme(
      fillColor: lightColorScheme.surface,
      focusColor: lightColorScheme.primary,
      labelStyle: TextStyle(color: lightColorScheme.onSurface),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: lightColorScheme.primary),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: lightColorScheme.secondary),
      ),
    ),

    // フローティングアクションボタンのテーマ
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: lightColorScheme.secondary,
      foregroundColor: lightColorScheme.onSecondary,
    ),

    // スイッチやチェックボックスのテーマ
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(lightColorScheme.primary),
      trackColor: WidgetStateProperty.all(lightColorScheme.primaryContainer),
    ),

    // テキストのテーマ
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: lightColorScheme.onSurface),
      titleLarge: TextStyle(color: lightColorScheme.primary),
      headlineSmall: TextStyle(color: lightColorScheme.onSurface),
    ),

    // アイコンのテーマ
    iconTheme: IconThemeData(
      color: lightColorScheme.onSurface,
    ),
    primaryIconTheme: IconThemeData(
      color: lightColorScheme.onPrimary,
    ),
  );
}
