import 'package:audio_session/audio_session.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsUtils {
  factory TtsUtils() {
    final instance = TtsUtils._();
    instance._tts.setVoice({"name": "en-US-language", "locale": "en-US"});
    instance._tts.awaitSpeakCompletion(true);

    // ignore: prefer-async-await
    AudioSession.instance.then((session) {
      instance._session = session;

      session.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.duckOthers,
          avAudioSessionMode: AVAudioSessionMode.spokenAudio,
          avAudioSessionSetActiveOptions:
              AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.speech,
            usage: AndroidAudioUsage.assistanceNavigationGuidance,
          ),
          androidAudioFocusGainType:
              AndroidAudioFocusGainType.gainTransientExclusive,
          androidWillPauseWhenDucked: true,
        ),
      );
    });

    return instance;
  }

  TtsUtils._();

  final FlutterTts _tts = FlutterTts();
  AudioSession? _session;

  Future<void> speak(String text) async {
    await _session?.setActive(true);
    await _tts.speak(text);
    await _session?.setActive(false);
  }
}
