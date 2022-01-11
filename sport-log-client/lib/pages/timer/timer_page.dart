import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/models/metcon/metcon.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/form_widgets/time_form_field.dart';
import 'package:sport_log/widgets/main_drawer.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({Key? key}) : super(key: key);

  @override
  State<TimerPage> createState() => TimerPageState();
}

class TimerPageState extends State<TimerPage> {
  final _logger = Logger('TimerPage');

  int _minutes = 0;
  int _seconds = 0;
  int _rounds = 3;
  int _currentRound = 0;
  Duration _currentTime = const Duration();
  Duration _duration = const Duration();
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
              Column(children: [
                timeFormField(MetconType.amrap),
                Defaults.sizedBox.vertical.huge,
                startStopButton(MetconType.amrap),
                const SizedBox(
                  height: 100,
                ),
                timeText,
              ]),
              Column(children: [
                timeFormField(MetconType.emom),
                TextFormField(
                  keyboardType: TextInputType.number,
                  onFieldSubmitted: (rounds) => setState(() {
                    _rounds = (int.parse(rounds));
                  }),
                  style: const TextStyle(height: 1),
                  initialValue: _rounds.toString(),
                  decoration: const InputDecoration(
                    icon: Icon(Icons.crop),
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
              ]),
              Column(children: [
                timeFormField(MetconType.forTime),
                Defaults.sizedBox.vertical.huge,
                startStopButton(MetconType.forTime),
                const SizedBox(
                  height: 100,
                ),
                timeText,
              ]),
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
    return TimeFormField.minSec(
      minutes: _minutes,
      seconds: _seconds,
      onMinutesSubmitted: (minutes) => _minutes = minutes,
      onSecondsSubmitted: (seconds) => _seconds = seconds,
      caption: caption,
    );
  }

  Widget startStopButton(MetconType metconType) {
    return timer == null
        ? ElevatedButton(
            onPressed: () => startTimerCallback(metconType),
            child: const Text(
              "Start",
              style: TextStyle(fontSize: 40),
            ))
        : ElevatedButton(
            onPressed: stopTimerCallback,
            child: const Text(
              "Stop",
              style: TextStyle(fontSize: 40),
            ));
  }

  Widget get timeText {
    return Text(
      formatTime(_currentTime, short: true),
      style: const TextStyle(fontSize: 120),
    );
  }

  void startTimerCallback(MetconType metconType) {
    setState(() {
      _duration = Duration(minutes: _minutes, seconds: _seconds);
      switch (metconType) {
        case MetconType.amrap:
          _currentTime = Duration(minutes: _minutes, seconds: _seconds);
          break;
        case MetconType.emom:
          _currentTime = Duration(minutes: _minutes, seconds: _seconds);
          _currentRound = 1;
          break;
        case MetconType.forTime:
          _currentTime = const Duration(seconds: 0);
          break;
      }
    });
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {
        switch (metconType) {
          case MetconType.amrap:
            _currentTime -= const Duration(seconds: 1);
            break;
          case MetconType.emom:
            _currentTime -= const Duration(seconds: 1);
            break;
          case MetconType.forTime:
            _currentTime += const Duration(seconds: 1);
            break;
        }
      });
      switch (metconType) {
        case MetconType.amrap:
          if (_currentTime <= const Duration(seconds: 0)) {
            stopTimerCallback();
            FlutterBeep.playSysSound(AndroidSoundIDs.TONE_CDMA_ABBR_ALERT);
          }
          break;
        case MetconType.emom:
          if (_currentTime <= const Duration(seconds: 0)) {
            if (_currentRound == _rounds) {
              stopTimerCallback();
              FlutterBeep.playSysSound(AndroidSoundIDs.TONE_CDMA_ABBR_ALERT);
            } else {
              _currentRound += 1;
              _currentTime = _duration;
              FlutterBeep.playSysSound(AndroidSoundIDs.TONE_CDMA_ANSWER);
            }
          }
          break;
        case MetconType.forTime:
          if (_currentTime >= _duration) {
            stopTimerCallback();
            FlutterBeep.playSysSound(AndroidSoundIDs.TONE_CDMA_ABBR_ALERT);
          }
          break;
      }
    });
  }

  void stopTimerCallback() {
    setState(() {
      timer!.cancel();
      timer = null;
    });
  }
}
