import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:wakelock/wakelock.dart';

enum TimerType {
  timer,
  interval,
  stopwatch,
}

class TimerUtils {
  final AudioCache _player = AudioCache(prefix: "assets/audio/")
    ..loadAll(['beep_long.mp3', 'beep_short.mp3']);

  final TimerType timerType;
  final Duration totalTime;
  final int totalRounds;
  final VoidCallback onTick;
  final VoidCallback onStop;

  late final Timer _timer;

  void dispose() {
    _timer.cancel();
    Wakelock.disable();
  }


  TimerUtils.startTimer({
    required this.timerType,
    required this.totalTime,
    required this.totalRounds,
    required this.onTick,
    required this.onStop,
  }) {
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer t) => _tickCallback(),
    );
    Wakelock.enable();
  }

  void stopTimer() {
    _timer.cancel();
    Wakelock.disable();
    onStop();
  }

  void _tickCallback() {
    onTick();
    if (_currentTime.inSeconds == 0) {
      _player.play('beep_long.mp3');
    } else if (_currentTime >=
        totalTime * (timerType == TimerType.interval ? totalRounds : 1)) {
      stopTimer();
      _player.play('beep_long.mp3');
    } else if (_currentTime.inSeconds > 0 && timerType == TimerType.interval) {
      final roundTime =
          Duration(seconds: _currentTime.inSeconds % totalTime.inSeconds);
      if (roundTime.inSeconds == 0) {
        _player.play('beep_short.mp3');
      }
    }
  }

  Duration get _currentTime => Duration(seconds: _timer.tick - 10);

  int get currentRound => _currentTime.isNegative || totalTime.inSeconds == 0
      ? 0
      : min(
          ((_currentTime.inSeconds + 1) / totalTime.inSeconds).ceil(),
          totalRounds,
        );

  Duration get displayTime {
    if (_currentTime.isNegative) {
      return _currentTime;
    } else {
      switch (timerType) {
        case TimerType.timer:
          return totalTime - _currentTime;
        case TimerType.interval:
          return Duration(
            seconds: totalTime.inSeconds -
                _currentTime.inSeconds % totalTime.inSeconds,
          );
        case TimerType.stopwatch:
          return _currentTime;
      }
    }
  }
}
