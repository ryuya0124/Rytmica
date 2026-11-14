# Windows maintenance — 2026-11-14

Updated the Windows build to Flutter 3.50.0 / Dart 3.14.0 and refreshed resolvable pub dependencies. Removed redundant rendering imports. Excluded the generated localization output from analyzer linting because Flutter 3.50's own generator still references deprecated compatibility exports; application code, widget tests and Release compilation remain checked.

Verification: flutter analyze passed, 31 widget/unit tests passed, Windows Release build passed. Version 2.5.3+39 is prepared locally. The installed Microsoft Store package is still 2.5.2.0; no Store submission or signing/trust changes were performed.
