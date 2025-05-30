import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/timer_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';
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
            // needed in order for context to contain DefaultTabController
            builder: (context) => Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: AppBar(
                title: const Text("Timer"),
                bottom: DeactivatableTabBar(
                  disabled: timerState.isRunning,
                  child: TabBar(
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    tabs: const [
                      Tab(text: "Timer", icon: Icon(AppIcons.timeInterval)),
                      Tab(text: "Interval", icon: Icon(AppIcons.repeat)),
                      Tab(text: "Stopwatch", icon: Icon(AppIcons.stopwatch)),
                    ],
                  ),
                ),
              ),
              body: Padding(
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
                        _timeText(timerState),
                      ],
                    ),
                    Column(
                      children: [
                        _timeFormField("Round Time", timerState),
                        _restTimeFormField(timerState),
                        _roundsFormField(timerState),
                        Defaults.sizedBox.vertical.huge,
                        _startStopButton(context, timerState),
                        const SizedBox(height: 50),
                        FittedBox(
                          child: Text(
                            "Round ${timerState.currentRound ?? '0'}",
                            softWrap: false,
                            style: const TextStyle(fontSize: 80, height: 1),
                          ),
                        ),
                        _timeText(timerState),
                      ],
                    ),
                    Column(
                      children: [
                        _timeFormField("Timecap", timerState),
                        Defaults.sizedBox.vertical.huge,
                        _startStopButton(context, timerState),
                        const SizedBox(height: 100),
                        _timeText(timerState),
                      ],
                    ),
                  ],
                ),
              ),
              drawer: const MainDrawer(selectedRoute: Routes.timer),
            ),
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
        onUpdate: (d) => timerState.time = d,
        initialDuration: timerState.time,
        minDuration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _restTimeFormField(TimerState timerState) {
    return EditTile.optionalButton(
      caption: "Rest Time",
      leading: AppIcons.timeInterval,
      showButton: timerState.restTime == null,
      onButtonPressed: () {
        timerState.restTime = const Duration(minutes: 1);
      },
      onTrailingTap: () => timerState.restTime = null,
      builder: () => DurationInput(
        onUpdate: (d) => timerState.restTime = d,
        initialDuration: timerState.restTime!,
        minDuration: const Duration(seconds: 1),
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
        maxValue: 99,
        onUpdate: (rounds) => timerState.rounds = rounds,
      ),
    );
  }

  Widget _startStopButton(BuildContext context, TimerState timerState) {
    return timerState.isRunning
        ? FilledButton(
            onPressed: timerState.stop,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text("Stop", style: TextStyle(fontSize: 50)),
          )
        : FilledButton(
            onPressed: () => timerState.time.inSeconds > 0
                ? timerState.start(
                    TimerType.values[DefaultTabController.of(context).index],
                  )
                : showMessageDialog(
                    context: context,
                    title: "Invalid Time",
                    text: "The time must be greater than 0.",
                  ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
            ),
            child: const Text("Start", style: TextStyle(fontSize: 50)),
          );
  }

  Widget _timeText(TimerState timerState) {
    final timeText = timerState.isRunning
        ? timerState.displayTime!.abs().formatTimeShort
        : "00:10";
    final color = timerState.isNotRunning || timerState.displayTime!.isNegative
        ? const Color.fromARGB(255, 150, 150, 150)
        : null;
    return FittedBox(
      child: Text(
        timeText,
        softWrap: false,
        style: TextStyle(fontSize: 200, height: 1, color: color),
      ),
    );
  }
}
