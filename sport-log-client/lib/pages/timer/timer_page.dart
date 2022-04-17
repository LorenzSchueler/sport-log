import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart' hide Logger;
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/models/metcon/metcon.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';
import 'package:sport_log/widgets/input_fields/duration_input.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/never_pop.dart';
import 'package:wakelock/wakelock.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({Key? key}) : super(key: key);

  @override
  State<TimerPage> createState() => TimerPageState();
}

class TimerPageState extends State<TimerPage> {
  final _logger = Logger('TimerPage');

  Duration _totalTime = Duration.zero;
  Duration _currentTime = Duration.zero;
  int _totalRounds = 3;
  Timer? _timer;

  late AudioCache _player;

  @override
  void initState() {
    _player = AudioCache(prefix: "assets/audio/");
    _player.loadAll(['beep_long.mp3', 'beep_short.mp3']);
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    Wakelock.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            title: const Text("Timer"),
            bottom: TabBar(
              onTap: (index) {
                setState(() {
                  _logger.i("ontap");
                  _currentTime = Duration.zero;
                });
              },
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: [
                Tab(
                  text: "AMRAP",
                  icon: Icon(
                    MetconType.amrap.icon,
                  ),
                ),
                Tab(
                  text: "EMOM",
                  icon: Icon(
                    MetconType.emom.icon,
                  ),
                ),
                Tab(
                  text: "FOR TIME",
                  icon: Icon(
                    MetconType.forTime.icon,
                  ),
                )
              ],
            ),
          ),
          body: Container(
            padding: Defaults.edgeInsets.normal,
            child: TabBarView(
              children: [
                Column(
                  children: [
                    _timeFormField(MetconType.amrap),
                    Defaults.sizedBox.vertical.huge,
                    _startStopButton(MetconType.amrap),
                    const SizedBox(
                      height: 100,
                    ),
                    _timeText(MetconType.amrap),
                  ],
                ),
                Column(
                  children: [
                    _timeFormField(MetconType.emom),
                    TextFormField(
                      keyboardType: TextInputType.number,
                      onChanged: (rounds) {
                        if (Validator.validateIntGtZero(rounds) == null) {
                          setState(() => _totalRounds = int.parse(rounds));
                        }
                      },
                      initialValue: _totalRounds.toString(),
                      validator: Validator.validateIntGtZero,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: const InputDecoration(
                        icon: Icon(AppIcons.repeat),
                        labelText: "Rounds",
                        contentPadding: EdgeInsets.symmetric(vertical: 5),
                      ),
                    ),
                    Defaults.sizedBox.vertical.huge,
                    _startStopButton(MetconType.emom),
                    const SizedBox(
                      height: 100,
                    ),
                    _roundText(),
                    _timeText(MetconType.emom),
                  ],
                ),
                Column(
                  children: [
                    _timeFormField(MetconType.forTime),
                    Defaults.sizedBox.vertical.huge,
                    _startStopButton(MetconType.forTime),
                    const SizedBox(
                      height: 100,
                    ),
                    _timeText(MetconType.forTime),
                  ],
                ),
              ],
            ),
          ),
          drawer: const MainDrawer(selectedRoute: Routes.settings),
        ),
      ),
    );
  }

  String _caption(MetconType metconType) {
    switch (metconType) {
      case MetconType.amrap:
        return "Time";
      case MetconType.emom:
        return "Round Time";
      case MetconType.forTime:
        return "Timecap";
    }
  }

  Widget _timeFormField(MetconType metconType) {
    return EditTile(
      caption: _caption(metconType),
      child: DurationInput(
        setDuration:
            _timer != null ? null : (d) => setState(() => _totalTime = d),
        initialDuration: _totalTime,
      ),
      leading: AppIcons.timeInterval,
    );
  }

  Widget _startStopButton(MetconType metconType) {
    return _timer == null
        ? ElevatedButton(
            onPressed: () => _totalTime.inSeconds > 0
                ? _startTimer(metconType)
                : showMessageDialog(
                    context: context,
                    text: "The ${_caption(metconType)} must be greater than 0.",
                  ),
            child: const Text(
              "Start",
              style: TextStyle(fontSize: 40),
            ),
          )
        : ElevatedButton(
            onPressed: _stopTimer,
            child: const Text(
              "Stop",
              style: TextStyle(fontSize: 40),
            ),
          );
  }

  Text _roundText() {
    int currentRound = _currentTime.isNegative ||
            _totalTime.inSeconds == 0 ||
            _timer == null && _currentTime.inSeconds == 0
        ? 0
        : min(
            ((_currentTime.inSeconds + 1) / _totalTime.inSeconds).ceil(),
            _totalRounds,
          );
    return Text(
      "Round $currentRound",
      style: const TextStyle(fontSize: 50),
    );
  }

  Text _timeText(MetconType metconType) {
    Duration displayTime;
    if (_currentTime.isNegative) {
      displayTime = _currentTime;
    } else {
      switch (metconType) {
        case MetconType.amrap:
          displayTime = _totalTime - _currentTime;
          break;
        case MetconType.emom:
          displayTime = _currentTime == _totalTime * _totalRounds
              ? Duration(seconds: _totalTime.inSeconds)
              : Duration(
                  seconds: _currentTime.inSeconds % _totalTime.inSeconds,
                );
          break;
        case MetconType.forTime:
          displayTime = _currentTime;
          break;
      }
    }
    return displayTime.isNegative
        ? Text(
            displayTime.abs().formatTimeShort,
            style: const TextStyle(
              fontSize: 120,
              color: Color.fromARGB(255, 150, 150, 150),
            ),
          )
        : Text(
            displayTime.formatTimeShort,
            style: const TextStyle(fontSize: 120),
          );
  }

  void _startTimer(MetconType metconType) {
    _timer?.cancel();
    setState(() => _currentTime = const Duration(seconds: -10));
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() => _currentTime += const Duration(seconds: 1));
      _tickCallback(metconType);
    });
    Wakelock.enable();
  }

  void _tickCallback(MetconType metconType) {
    if (_currentTime.inSeconds == 0) {
      _player.play('beep_long.mp3');
    } else if (_currentTime >=
        _totalTime * (metconType == MetconType.emom ? _totalRounds : 1)) {
      _stopTimer();
      _player.play('beep_long.mp3');
    } else if (_currentTime.inSeconds > 0 && metconType == MetconType.emom) {
      final roundTime =
          Duration(seconds: _currentTime.inSeconds % _totalTime.inSeconds);
      if (roundTime.inSeconds == 0) {
        _player.play('beep_short.mp3');
      }
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _timer = null;
    });
    Wakelock.disable();
  }
}
