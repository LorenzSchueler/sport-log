import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/timer_utils.dart';
import 'package:sport_log/models/metcon/metcon.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';
import 'package:sport_log/widgets/disable_tab_bar.dart';
import 'package:sport_log/widgets/input_fields/duration_input.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
import 'package:sport_log/widgets/input_fields/int_input.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/pop_scopes.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({Key? key}) : super(key: key);

  @override
  State<TimerPage> createState() => TimerPageState();
}

class TimerPageState extends State<TimerPage> {
  Duration _totalTime = Duration.zero;
  int _totalRounds = 3;
  TimerUtils? _timerUtils;

  @override
  void dispose() {
    _timerUtils?.dispose();
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
            bottom: DeactivatableTabBar(
              child: TabBar(
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
              disabled: _timerUtils != null,
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
                    const SizedBox(height: 100),
                    if (_timerUtils != null) timeText(),
                  ],
                ),
                Column(
                  children: [
                    _timeFormField(MetconType.emom),
                    _roundsFormField(),
                    Defaults.sizedBox.vertical.huge,
                    _startStopButton(MetconType.emom),
                    const SizedBox(height: 100),
                    if (_timerUtils != null)
                      Text(
                        "Round ${_timerUtils!.currentRound}",
                        style: const TextStyle(fontSize: 50),
                      ),
                    if (_timerUtils != null) timeText(),
                  ],
                ),
                Column(
                  children: [
                    _timeFormField(MetconType.forTime),
                    Defaults.sizedBox.vertical.huge,
                    _startStopButton(MetconType.forTime),
                    const SizedBox(height: 100),
                    if (_timerUtils != null) timeText(),
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
            _timerUtils != null ? null : (d) => setState(() => _totalTime = d),
        initialDuration: _totalTime,
      ),
      leading: AppIcons.timeInterval,
    );
  }

  Widget _roundsFormField() {
    return EditTile(
      leading: AppIcons.repeat,
      caption: "Rounds",
      child: IntInput(
        initialValue: _totalRounds,
        minValue: 1,
        setValue: _timerUtils != null
            ? null
            : (rounds) => setState(() => _totalRounds = rounds),
      ),
    );
  }

  Widget _startStopButton(MetconType metconType) {
    return _timerUtils != null
        ? ElevatedButton(
            onPressed: () => setState(_timerUtils!.stopTimer),
            child: const Text(
              "Stop",
              style: TextStyle(fontSize: 40),
            ),
          )
        : ElevatedButton(
            onPressed: () => _totalTime.inSeconds > 0
                ? setState(
                    () => _timerUtils = TimerUtils.startTimer(
                      metconType: metconType,
                      totalTime: _totalTime,
                      totalRounds: _totalRounds,
                      onTick: () => setState(() {}),
                      onStop: () => setState(() => _timerUtils = null),
                    ),
                  )
                : showMessageDialog(
                    context: context,
                    text: "The ${_caption(metconType)} must be greater than 0.",
                  ),
            child: const Text(
              "Start",
              style: TextStyle(fontSize: 40),
            ),
          );
  }

  Text timeText() {
    final displayTime = _timerUtils!.displayTime;
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
}
