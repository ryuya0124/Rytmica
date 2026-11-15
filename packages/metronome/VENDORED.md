# Upstream baseline

Based on the pub.dev metronome 2.0.13 source archive (MIT).
The local package version is 2.0.13+rytmica.1.

The Windows implementation and Android reproducibility settings retain the existing Rytmica integrations. The existing Dart-to-JavaScript timeout conversion and iOS allowBluetoothHFP compatibility adjustment are retained.
The 2.0.13 Dart and Darwin sources, including audio route recovery and optional host-managed audio sessions, are synchronized from upstream. The upstream audio session method-channel regression test is included.
