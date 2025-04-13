import 'package:flutter/foundation.dart';
import 'package:metronome/metronome.dart';
import 'package:sport_log/defaults.dart';

enum MetronomeAdjustment { increase, decrease, stop }

class MetronomeUtils extends ChangeNotifier {
  final Metronome _metronome =
      Metronome()..init(Defaults.assets.beepMetronomeFile, bpm: 180);

  int _cadence = 180;
  int get cadence => _cadence;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  @override
  void dispose() {
    _metronome.destroy();
    super.dispose();
  }

  Future<void> startTimer() async {
    _isPlaying = true;
    notifyListeners();
    await _metronome.setBPM(_cadence);
    await _metronome.play();
  }

  Future<void> adjustTimer(MetronomeAdjustment change) async {
    switch (change) {
      case MetronomeAdjustment.stop:
        _isPlaying = false;
        notifyListeners();
        await _metronome.stop();
        break;
      case MetronomeAdjustment.increase:
        _cadence += 1;
        notifyListeners();
        await _metronome.setBPM(_cadence);
        break;
      case MetronomeAdjustment.decrease:
        if (_cadence > 1) {
          _cadence -= 1;
          notifyListeners();
          await _metronome.setBPM(_cadence);
        }
    }
  }
}
