import 'package:flutter/foundation.dart';
import 'package:speak/speak.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/helpers/logger.dart';

enum TtsStatus { checking, noEngine, noOfflineEnglishVoice, available }

class TtsUtils {
  static final _logger = Logger("TtsUtils");

  static final status = ValueNotifier(TtsStatus.checking);

  static Speak? _speak;

  /// Why speech is not available, or null if it is.
  static String? get unavailableReason => switch (status.value) {
    TtsStatus.checking => "Checking text-to-speech...",
    TtsStatus.noEngine => "No text-to-speech engine installed.",
    TtsStatus.noOfflineEnglishVoice => "No offline English voice installed.",
    TtsStatus.available => null,
  };

  static Future<void> init() async {
    Speak? speak;
    try {
      if (!Speak.isSupported ||
          Config.isAndroid && (await Speak.androidEngines()).isEmpty) {
        status.value = TtsStatus.noEngine;
        return;
      }
      speak = Speak(audio: SpeakAudio.navigation);
      final voices = await speak.voices(language: "en-US");
      speak.voice = voices
          .where((voice) => voice.isInstalled && !voice.requiresNetwork)
          .firstOrNull;
    } catch (error) {
      _logger.w("tts init failed", error: error);
      status.value = TtsStatus.noEngine;
      await speak?.dispose();
      return;
    }
    if (speak.voice == null) {
      status.value = TtsStatus.noOfflineEnglishVoice;
      await speak.dispose();
      return;
    }
    _speak = speak;
    status.value = TtsStatus.available;
  }

  static Future<void> speak(String text) async {
    try {
      await _speak?.call(text);
    } catch (error) {
      _logger.w("speak failed", error: error);
    }
  }
}
