import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:wakelock/wakelock.dart';

enum TimerType {
  timer,
  interval,
  stopwatch,
}

class TimerState extends ChangeNotifier {
  Duration _time = Duration.zero;
  Duration? _restTime;
  int _rounds = 3;
  TimerUtils? _timerUtils;

  bool get isRunning => _timerUtils != null;
  bool get isNotRunning => !isRunning;

  Duration get time => _time;
  set time(Duration time) {
    if (isNotRunning) {
      _time = time;
      notifyListeners();
    }
  }

  Duration? get restTime => _restTime;
  set restTime(Duration? restTime) {
    if (isNotRunning) {
      _restTime = restTime;
      notifyListeners();
    }
  }

  int get rounds => _rounds;
  set rounds(int rounds) {
    if (isNotRunning) {
      _rounds = rounds;
      notifyListeners();
    }
  }

  Duration? get displayTime => _timerUtils?.displayTime;
  int? get currentRound => _timerUtils?.currentRound;

  void start(TimerType timerType) {
    _timerUtils = TimerUtils.startTimer(
      timerType: timerType,
      time: _time,
      restTime: _restTime,
      rounds: _rounds,
      onTick: notifyListeners,
      onStop: () {
        _timerUtils = null;
        notifyListeners();
      },
    );
    notifyListeners();
  }

  void stop() {
    _timerUtils?.stopTimer();
    notifyListeners();
  }

  @override
  void dispose() {
    _timerUtils?.dispose();
    super.dispose();
  }
}

class TimerUtils {
  TimerUtils.startTimer({
    required this.timerType,
    required this.time,
    required Duration? restTime,
    required this.rounds,
    required this.onTick,
    required this.onStop,
  }) : restTime = (timerType == TimerType.interval ? restTime : null) ??
            Duration.zero {
    totalTime = time + this.restTime;
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer t) => _tickCallback(),
    );
    Wakelock.enable();
  }

  final _player = AudioPlayer();
  static const _audioCtx = AudioContext(
    android: AudioContextAndroid(
      usageType: AndroidUsageType.alarm,
      audioFocus: AndroidAudioFocus.gainTransientMayDuck,
    ),
  );

  static const initialCountdown = Duration(seconds: 10);

  final TimerType timerType;
  final Duration time;
  final Duration restTime;
  final int rounds;
  final VoidCallback onTick;
  final VoidCallback onStop;

  late final Duration totalTime;
  late final Timer _timer;

  void dispose() {
    _timer.cancel();
    Wakelock.disable();
  }

  void stopTimer() {
    dispose();
    onStop();
  }

  Future<void> _tickCallback() async {
    onTick();
    if (_currentTime.inSeconds == 0) {
      await _player.play(Defaults.assets.beepLong, ctx: _audioCtx);
    } else if (_currentTime >=
        totalTime * (timerType == TimerType.interval ? rounds : 1)) {
      stopTimer();
      await _player.play(Defaults.assets.beepLong, ctx: _audioCtx);
    } else if (_currentTime.inSeconds > 0 && timerType == TimerType.interval) {
      final roundStart =
          Duration(seconds: _currentTime.inSeconds % totalTime.inSeconds)
                  .inSeconds ==
              0;
      final restStart = Duration(
            seconds: (_currentTime + restTime).inSeconds % totalTime.inSeconds,
          ).inSeconds ==
          0;
      if (roundStart || restStart) {
        await _player.play(Defaults.assets.beepShort, ctx: _audioCtx);
      }
    }
  }

  Duration get _currentTime =>
      Duration(seconds: _timer.tick) - initialCountdown;

  int get currentRound => _currentTime.isNegative || time.inSeconds == 0
      ? 0
      : min(
          ((_currentTime.inSeconds + 1) / totalTime.inSeconds).ceil(),
          rounds,
        );

  Duration get displayTime {
    if (_currentTime.isNegative) {
      return _currentTime;
    } else {
      switch (timerType) {
        case TimerType.timer:
          return time - _currentTime;
        case TimerType.interval:
          final roundTime = _currentTime.inSeconds % totalTime.inSeconds;
          return Duration(
            seconds: roundTime < time.inSeconds
                ? time.inSeconds - roundTime // round
                : roundTime - totalTime.inSeconds, // rest
          );
        case TimerType.stopwatch:
          return _currentTime;
      }
    }
  }
}
