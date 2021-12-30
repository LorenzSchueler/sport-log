import 'package:flutter/material.dart';
import 'package:sport_log/widgets/custom_icons.dart';

class TimeFormField extends StatelessWidget {
  final int? hours;
  final int minutes;
  final int seconds;
  final Function(int)? onHoursSubmitted;
  final Function(int) onMinutesSubmitted;
  final Function(int) onSecondsSubmitted;

  const TimeFormField(
      {required this.hours,
      required this.minutes,
      required this.seconds,
      required this.onHoursSubmitted,
      required this.onMinutesSubmitted,
      required this.onSecondsSubmitted,
      Key? key})
      : super(key: key);

  const TimeFormField.minSec(
      {required this.minutes,
      required this.seconds,
      required this.onMinutesSubmitted,
      required this.onSecondsSubmitted,
      Key? key})
      : hours = null,
        onHoursSubmitted = null,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    const Icon icon = Icon(CustomIcons.timeInterval);

    return Row(
      children: [
        if (hours != null)
          SizedBox(
              width: 70,
              child: TextFormField(
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                onFieldSubmitted: (hours) =>
                    onHoursSubmitted!(int.parse(hours)),
                style: const TextStyle(height: 1),
                textInputAction: TextInputAction.next,
                initialValue: hours.toString().padLeft(2, "0"),
                decoration: const InputDecoration(
                  icon: icon,
                ),
              )),
        if (hours != null) const Text(":"),
        SizedBox(
          width: hours != null ? 30 : 70,
          child: TextFormField(
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            onFieldSubmitted: (minutes) =>
                onMinutesSubmitted(int.parse(minutes)),
            style: const TextStyle(height: 1),
            textInputAction: TextInputAction.next,
            initialValue: minutes.toString().padLeft(2, "0"),
            decoration: hours != null
                ? null
                : const InputDecoration(
                    icon: icon,
                  ),
          ),
        ),
        const Text(":"),
        SizedBox(
          width: 30,
          child: TextFormField(
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            onFieldSubmitted: (seconds) =>
                onSecondsSubmitted(int.parse(seconds)),
            style: const TextStyle(height: 1),
            initialValue: seconds.toString().padLeft(2, "0"),
          ),
        )
      ],
    );
  }
}
