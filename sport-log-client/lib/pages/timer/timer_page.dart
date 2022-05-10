import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/timer_utils.dart';
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
  Duration _time = Duration.zero;
  Duration? _restTime;
  int _rounds = 3;
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
              disabled: _timerUtils != null,
              child: TabBar(
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: const [
                  Tab(
                    text: "Timer",
                    icon: Icon(AppIcons.timeInterval),
                  ),
                  Tab(
                    text: "Interval",
                    icon: Icon(AppIcons.repeat),
                  ),
                  Tab(
                    text: "Stopwatch",
                    icon: Icon(AppIcons.stopwatch),
                  )
                ],
              ),
            ),
          ),
          body: Container(
            padding: Defaults.edgeInsets.normal,
            child: TabBarView(
              children: [
                Column(
                  children: [
                    _timeFormField(TimerType.timer),
                    Defaults.sizedBox.vertical.huge,
                    _startStopButton(TimerType.timer),
                    const SizedBox(height: 100),
                    if (_timerUtils != null) timeText(),
                  ],
                ),
                Column(
                  children: [
                    _timeFormField(TimerType.interval),
                    _restTimeFormField(),
                    _roundsFormField(),
                    Defaults.sizedBox.vertical.huge,
                    _startStopButton(TimerType.interval),
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
                    _timeFormField(TimerType.stopwatch),
                    Defaults.sizedBox.vertical.huge,
                    _startStopButton(TimerType.stopwatch),
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

  String _caption(TimerType timerType) {
    switch (timerType) {
      case TimerType.timer:
        return "Time";
      case TimerType.interval:
        return "Round Time";
      case TimerType.stopwatch:
        return "Timecap";
    }
  }

  Widget _timeFormField(TimerType timerType) {
    return EditTile(
      caption: _caption(timerType),
      leading: AppIcons.timeInterval,
      child: DurationInput(
        setDuration:
            _timerUtils != null ? null : (d) => setState(() => _time = d),
        initialDuration: _time,
      ),
    );
  }

  Widget _restTimeFormField() {
    return _restTime == null
        ? EditTile(
            leading: AppIcons.timeInterval,
            child: ActionChip(
              avatar: const Icon(AppIcons.add),
              label: const Text("Rest Time"),
              onPressed: () => setState(() {
                _restTime = const Duration(minutes: 1);
              }),
            ),
          )
        : EditTile(
            caption: "Rest Time",
            leading: AppIcons.timeInterval,
            onCancel: () => setState(() => _restTime = null),
            child: DurationInput(
              setDuration: _timerUtils != null
                  ? null
                  : (d) => setState(() => _restTime = d),
              initialDuration: _restTime,
            ),
          );
  }

  Widget _roundsFormField() {
    return EditTile(
      leading: AppIcons.repeat,
      caption: "Rounds",
      child: IntInput(
        initialValue: _rounds,
        minValue: 1,
        setValue: _timerUtils != null
            ? null
            : (rounds) => setState(() => _rounds = rounds),
      ),
    );
  }

  Widget _startStopButton(TimerType timerType) {
    return _timerUtils != null
        ? ElevatedButton(
            onPressed: () => setState(_timerUtils!.stopTimer),
            child: const Text(
              "Stop",
              style: TextStyle(fontSize: 40),
            ),
          )
        : ElevatedButton(
            onPressed: () => _time.inSeconds > 0
                ? setState(
                    () => _timerUtils = TimerUtils.startTimer(
                      timerType: timerType,
                      time: _time,
                      restTime: _restTime,
                      rounds: _rounds,
                      onTick: () => setState(() {}),
                      onStop: () => setState(() => _timerUtils = null),
                    ),
                  )
                : showMessageDialog(
                    context: context,
                    text: "The ${_caption(timerType)} must be greater than 0.",
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
