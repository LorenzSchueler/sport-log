import 'package:audio_session/audio_session.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsUtils {
  static Future<void> init() async {
    final tts = FlutterTts();

    final engines = (await tts.getEngines) as List;
    if (engines.isEmpty) {
      return;
    }
    await tts.setEngine(engines[0] as String);

    final voices = (await tts.getVoices as List).cast<Map<dynamic, dynamic>>();
    if (voices.isEmpty) {
      return;
    }
    Map<String, String>? prevVoice;
    for (final v in voices) {
      final voice = v.cast<String, String>();
      if (voice["locale"] == "en-US") {
        prevVoice = voice;
      }
    }
    await tts.setVoice(prevVoice ?? voices[0].cast<String, String>());

    await tts.awaitSpeakCompletion(true);

    final session = await AudioSession.instance;

    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        avAudioSessionSetActiveOptions:
            AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.assistanceNavigationGuidance,
        ),
        androidAudioFocusGainType:
            AndroidAudioFocusGainType.gainTransientMayDuck,
        androidWillPauseWhenDucked: true,
      ),
    );

    TtsUtils._tts = tts;
    TtsUtils._session = session;
  }

  static FlutterTts? _tts;
  static AudioSession? _session;

  static bool get ttsEngineFound => _tts != null && _session != null;

  static Future<void> speak(String text) async {
    await _session?.setActive(true);
    await _tts?.speak(text);
    await _session?.setActive(false);
  }
}
