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
import 'package:sport_log/widgets/provider_consumer.dart';

class TimerPage extends StatelessWidget {
  const TimerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child: ProviderConsumer<TimerState>(
        create: (_) => TimerState(),
        builder: (context, timerState, _) => DefaultTabController(
          length: 3,
          child: Builder(
            builder: (context) {
              final tabController = DefaultTabController.of(context)!;
              tabController.addListener(() {
                if (!tabController.indexIsChanging) {
                  switch (tabController.index) {
                    case 0:
                      timerState.timerType = TimerType.timer;
                      break;
                    case 1:
                      timerState.timerType = TimerType.interval;
                      break;
                    default:
                      timerState.timerType = TimerType.stopwatch;
                      break;
                  }
                }
              });

              return Scaffold(
                resizeToAvoidBottomInset: false,
                appBar: AppBar(
                  title: const Text("Timer"),
                  bottom: DeactivatableTabBar(
                    disabled: timerState.isRunning,
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
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      Column(
                        children: [
                          _timeFormField("Time", timerState),
                          Defaults.sizedBox.vertical.huge,
                          _startStopButton(context, timerState),
                          const SizedBox(height: 100),
                          timeText(timerState),
                        ],
                      ),
                      Column(
                        children: [
                          _timeFormField("Round Time", timerState),
                          _restTimeFormField(timerState),
                          _roundsFormField(timerState),
                          Defaults.sizedBox.vertical.huge,
                          _startStopButton(context, timerState),
                          const SizedBox(height: 100),
                          if (timerState.isRunning)
                            Text(
                              "Round ${timerState.currentRound}",
                              style: const TextStyle(fontSize: 50),
                            ),
                          timeText(timerState),
                        ],
                      ),
                      Column(
                        children: [
                          _timeFormField("Timecap", timerState),
                          Defaults.sizedBox.vertical.huge,
                          _startStopButton(context, timerState),
                          const SizedBox(height: 100),
                          timeText(timerState),
                        ],
                      ),
                    ],
                  ),
                ),
                drawer: const MainDrawer(selectedRoute: Routes.settings),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _timeFormField(String caption, TimerState timerState) {
    return EditTile(
      caption: caption,
      leading: AppIcons.timeInterval,
      child: DurationInput(
        setDuration: (d) => timerState.time = d,
        initialDuration: timerState.time,
      ),
    );
  }

  Widget _restTimeFormField(TimerState timerState) {
    return timerState.restTime == null
        ? EditTile(
            leading: AppIcons.timeInterval,
            child: ActionChip(
              avatar: const Icon(AppIcons.add),
              label: const Text("Rest Time"),
              onPressed: () => timerState.restTime = const Duration(minutes: 1),
            ),
          )
        : EditTile(
            caption: "Rest Time",
            leading: AppIcons.timeInterval,
            onCancel: () => timerState.restTime = null,
            child: DurationInput(
              setDuration: (d) => timerState.restTime = d,
              initialDuration: timerState.restTime,
            ),
          );
  }

  Widget _roundsFormField(TimerState timerState) {
    return EditTile(
      leading: AppIcons.repeat,
      caption: "Rounds",
      child: IntInput(
        initialValue: timerState.rounds,
        minValue: 1,
        setValue: (rounds) => timerState.rounds = rounds,
      ),
    );
  }

  Widget _startStopButton(BuildContext context, TimerState timerState) {
    return timerState.isRunning
        ? ElevatedButton(
            onPressed: timerState.stop,
            child: const Text(
              "Stop",
              style: TextStyle(fontSize: 40),
            ),
          )
        : ElevatedButton(
            onPressed: () => timerState.time.inSeconds > 0
                ? timerState.start()
                : showMessageDialog(
                    context: context,
                    text: "The time must be greater than 0.",
                  ),
            child: const Text(
              "Start",
              style: TextStyle(fontSize: 40),
            ),
          );
  }

  Text timeText(TimerState timerState) {
    const disabledStyle = TextStyle(
      fontSize: 120,
      color: Color.fromARGB(255, 150, 150, 150),
    );
    if (timerState.isNotRunning) {
      return const Text(
        "-- : --",
        style: disabledStyle,
      );
    } else {
      final displayTime = timerState.displayTime!;
      return displayTime.isNegative
          ? Text(
              displayTime.abs().formatTimeShort,
              style: disabledStyle,
            )
          : Text(
              displayTime.formatTimeShort,
              style: const TextStyle(fontSize: 120),
            );
    }
  }
}
