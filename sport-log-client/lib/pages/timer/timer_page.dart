import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/models/metcon/metcon.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/custom_icons.dart';
import 'package:sport_log/widgets/form_widgets/duration_picker.dart';
import 'package:sport_log/widgets/form_widgets/edit_tile.dart';
import 'package:sport_log/widgets/main_drawer.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({Key? key}) : super(key: key);

  @override
  State<TimerPage> createState() => TimerPageState();
}

class TimerPageState extends State<TimerPage> {
  final _logger = Logger('TimerPage');

  int _rounds = 3;
  Duration _totalTime = const Duration();
  Duration _currentTime = const Duration();
  int _currentRound = 0;
  Timer? timer;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Timer"),
            bottom: TabBar(
                indicatorColor: primaryColorOf(context),
                labelColor: Colors.white,
                tabs: [
                  Tab(
                      text: "AMRAP",
                      icon: Icon(
                        MetconType.amrap.icon,
                      )),
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
                ]),
          ),
          body: Container(
            padding: const EdgeInsets.all(10),
            child: SizedBox(
                child: TabBarView(children: [
              SingleChildScrollView(
                  child: Column(children: [
                timeFormField(MetconType.amrap),
                Defaults.sizedBox.vertical.huge,
                startStopButton(MetconType.amrap),
                const SizedBox(
                  height: 100,
                ),
                timeText,
              ])),
              SingleChildScrollView(
                  child: Column(children: [
                timeFormField(MetconType.emom),
                TextFormField(
                  keyboardType: TextInputType.number,
                  onChanged: (rounds) {
                    if (Validator.validateIntGtZero(rounds) == null) {
                      setState(() => _rounds = int.parse(rounds));
                    }
                  },
                  style: const TextStyle(height: 1),
                  initialValue: _rounds.toString(),
                  validator: Validator.validateIntGtZero,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    icon: Icon(CustomIcons.cw),
                    labelText: "Rounds",
                    contentPadding: EdgeInsets.symmetric(vertical: 5),
                  ),
                ),
                Defaults.sizedBox.vertical.huge,
                startStopButton(MetconType.emom),
                const SizedBox(
                  height: 100,
                ),
                Text(
                  "Round $_currentRound",
                  style: const TextStyle(fontSize: 50),
                ),
                timeText,
              ])),
              SingleChildScrollView(
                  child: Column(children: [
                timeFormField(MetconType.forTime),
                Defaults.sizedBox.vertical.huge,
                startStopButton(MetconType.forTime),
                const SizedBox(
                  height: 100,
                ),
                timeText,
              ])),
            ])),
          ),
          drawer: const MainDrawer(selectedRoute: Routes.settings),
        ));
  }

  Widget timeFormField(MetconType metconType) {
    String caption;
    switch (metconType) {
      case MetconType.amrap:
        caption = "Time";
        break;
      case MetconType.emom:
        caption = "Round Time";
        break;
      case MetconType.forTime:
        caption = "Timecap";
        break;
    }
    return EditTile(
      caption: caption,
      child: DurationPicker(
          setDuration: (d) => setState(() => _totalTime = d),
          initialDuration: _totalTime),
      leading: CustomIcons.time_interval,
    );
  }

  Widget startStopButton(MetconType metconType) {
    return timer == null
        ? ElevatedButton(
            onPressed: () => startTimer(metconType),
            child: const Text(
              "Start",
              style: TextStyle(fontSize: 40),
            ))
        : ElevatedButton(
            onPressed: stopTimer,
            child: const Text(
              "Stop",
              style: TextStyle(fontSize: 40),
            ));
  }

  Text get timeText {
    return _currentTime.isNegative
        ? Text(
            formatTime(_currentTime.abs(), short: true),
            style: const TextStyle(
                fontSize: 120, color: Color.fromARGB(255, 150, 150, 150)),
          )
        : Text(
            formatTime(_currentTime, short: true),
            style: const TextStyle(fontSize: 120),
          );
  }

  void startTimer(MetconType metconType) {
    timer?.cancel();
    Duration time = const Duration(seconds: -10);
    setState(() {
      _currentTime = time;
      _currentRound = 0;
    });
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      time += const Duration(seconds: 1);
      tickCallback(time, metconType);
    });
  }

  void tickCallback(Duration time, MetconType metconType) {
    if (time.isNegative) {
      setState(() {
        _currentTime = time;
      });
    } else {
      if (time.inSeconds == 0) {
        FlutterBeep.playSysSound(AndroidSoundIDs.TONE_CDMA_ABBR_ALERT);
      }
      setState(() {
        switch (metconType) {
          case MetconType.amrap:
            _currentTime = _totalTime - time;
            break;
          case MetconType.emom:
            Duration roundTime =
                Duration(seconds: time.inSeconds % _totalTime.inSeconds);
            _currentRound = min(
                ((time.inSeconds + 1) / _totalTime.inSeconds).ceil(), _rounds);
            _currentTime = time == _totalTime * _rounds
                ? Duration(seconds: _totalTime.inSeconds)
                : roundTime;
            if (roundTime.inSeconds == 0) {
              FlutterBeep.playSysSound(AndroidSoundIDs.TONE_CDMA_ANSWER);
            }
            break;
          case MetconType.forTime:
            _currentTime = time;
            break;
        }
      });
      if (metconType == MetconType.emom) {
        _totalTime *= _rounds;
      }
      if (time >= _totalTime) {
        stopTimer();
      }
    }
  }

  void stopTimer() {
    timer?.cancel();
    setState(() {
      timer = null;
    });
    FlutterBeep.playSysSound(AndroidSoundIDs.TONE_CDMA_ABBR_ALERT);
  }
}
