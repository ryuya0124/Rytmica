import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metronome/metronome_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'iOS audio session management is enabled by default and can be disabled by the host',
      () async {
    final calls = <MethodCall>[];
    final platform = MethodChannelMetronome();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      platform.methodChannel,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        platform.methodChannel,
        null,
      ),
    );

    // Use temporary audio bytes to verify the MethodChannel argument without adding a test asset.
    final directory =
        await Directory.systemTemp.createTemp('metronome_audio_session_');
    final audioFile = File('${directory.path}/tick.wav');
    await audioFile.writeAsBytes(const [0]);
    addTearDown(() => directory.delete(recursive: true));

    await platform.init(audioFile.path);
    expect(
        (calls.last.arguments as Map<Object?, Object?>)['manageAudioSession'],
        isTrue);

    await platform.init(audioFile.path, manageAudioSession: false);
    expect(
        (calls.last.arguments as Map<Object?, Object?>)['manageAudioSession'],
        isFalse);
  });
}
