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

  final AudioCache _player = AudioCache(prefix: "assets/audio/")
    ..loadAll(['beep_long.mp3', 'beep_short.mp3']);

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
    _timer.cancel();
    Wakelock.disable();
    onStop();
  }

  void _tickCallback() {
    onTick();
    if (_currentTime.inSeconds == 0) {
      _player.play('beep_long.mp3');
    } else if (_currentTime >=
        totalTime * (timerType == TimerType.interval ? rounds : 1)) {
      stopTimer();
      _player.play('beep_long.mp3');
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
        _player.play('beep_short.mp3');
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
