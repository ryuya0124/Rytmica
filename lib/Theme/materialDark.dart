import 'package:material_ui/material_ui.dart';

ThemeData materialDarkTheme(ColorScheme darkColorScheme) {
  return ThemeData(
    colorScheme: darkColorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: darkColorScheme.surface,

    // アプリバーのテーマ
    appBarTheme: AppBarTheme(
      backgroundColor: darkColorScheme.primary,
      foregroundColor: darkColorScheme.onPrimary,
    ),

    // ボタンのテーマ
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkColorScheme.primary,
        foregroundColor: darkColorScheme.onPrimary,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: darkColorScheme.primary,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: darkColorScheme.primary,
        side: BorderSide(color: darkColorScheme.primary),
      ),
    ),

    // カードのテーマ
    cardTheme: CardThemeData(
      color: darkColorScheme.surface,
      shadowColor: darkColorScheme.shadow,
      elevation: 2,
    ),

    // スナックバーのテーマ
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkColorScheme.surface,
      contentTextStyle: TextStyle(color: darkColorScheme.onSurface),
    ),

    // テキストフィールドのテーマ
    inputDecorationTheme: InputDecorationTheme(
      fillColor: darkColorScheme.surface,
      focusColor: darkColorScheme.primary,
      labelStyle: TextStyle(color: darkColorScheme.onSurface),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: darkColorScheme.primary),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: darkColorScheme.secondary),
      ),
    ),

    // フローティングアクションボタンのテーマ
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: darkColorScheme.secondary,
      foregroundColor: darkColorScheme.onSecondary,
    ),

    // スイッチやチェックボックスのテーマ
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(darkColorScheme.primary),
      trackColor: WidgetStateProperty.all(darkColorScheme.primaryContainer),
    ),

    // テキストのテーマ
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: darkColorScheme.onSurface),
      titleLarge: TextStyle(color: darkColorScheme.primary),
      headlineSmall: TextStyle(color: darkColorScheme.onSurface),
    ),

    // アイコンのテーマ
    iconTheme: IconThemeData(
      color: darkColorScheme.onSurface,
    ),
    primaryIconTheme: IconThemeData(
      color: darkColorScheme.onPrimary,
    ),
  );
}
