import 'package:audio_session/audio_session.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsUtils {
  /// TtsUtils creates unawaited future in factory.
  ///
  /// Therefore, it should not be used directly in order to allow the future to complete before the first use.
  factory TtsUtils() {
    final instance = TtsUtils._();

    //Future(() async {
    //if (await instance._tts.getDefaultEngine == null) {
    //final engines = (await instance._tts.getEngines) as List;
    //if (engines.isNotEmpty) {
    //await instance._tts.setEngine(engines[0] as String);
    //}
    //}

    //await instance._tts.setVoice({
    //"name": "en-US-language",
    //"locale": "en-US",
    //}); // ignored if not available
    //await instance._tts.awaitSpeakCompletion(true);
    //});

    //// ignore: prefer-async-await
    //AudioSession.instance.then((session) {
    //instance._session = session;

    //session.configure(
    //const AudioSessionConfiguration(
    //avAudioSessionCategory: AVAudioSessionCategory.playback,
    //avAudioSessionCategoryOptions:
    //AVAudioSessionCategoryOptions.duckOthers,
    //avAudioSessionMode: AVAudioSessionMode.spokenAudio,
    //avAudioSessionSetActiveOptions:
    //AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
    //androidAudioAttributes: AndroidAudioAttributes(
    //contentType: AndroidAudioContentType.speech,
    //usage: AndroidAudioUsage.assistanceNavigationGuidance,
    //),
    //androidAudioFocusGainType:
    //AndroidAudioFocusGainType.gainTransientMayDuck,
    //androidWillPauseWhenDucked: true,
    //),
    //);
    //});

    return instance;
  }

  TtsUtils._();

  // ignore: unused_field
  final FlutterTts _tts = FlutterTts();
  // ignore: unused_field, use_late_for_private_fields_and_variables
  AudioSession? _session;

  Future<void> speak(String text) async {
    //await _session?.setActive(true);
    //await _tts.speak(text);
    //await _session?.setActive(false);
  }
}
