import 'package:flutter/material.dart';
import 'package:sport_log/helpers/formatting.dart';

class ValueUnitDescription extends StatelessWidget {
  final String value;
  final String? unit;
  final String? description;
  final double scale;

  const ValueUnitDescription({
    Key? key,
    required String? value,
    required this.unit,
    required this.description,
    this.scale = 1,
  })  : value = value ?? "--",
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: unit == null ? value : "$value ",
            style: TextStyle(fontSize: 20 * scale),
          ),
          if (unit != null)
            TextSpan(
              text: unit,
              style: TextStyle(fontSize: 14 * scale),
            ),
          if (description != null)
            TextSpan(
              text: "\n$description",
              style: TextStyle(fontSize: 12 * scale),
            ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  ValueUnitDescription.time(Duration? time, {Key? key})
      : this(
          value: time?.formatTime,
          unit: null,
          description: "Duration",
          scale: 1.3,
          key: key,
        );

  ValueUnitDescription.timeSmall(Duration? time, {Key? key})
      : this(
          value: time?.formatTime,
          unit: null,
          description: null,
          key: key,
        );

  ValueUnitDescription.distance(int? distance, {Key? key})
      : this(
          value: distance == null ? null : (distance / 1000).toStringAsFixed(3),
          unit: "km",
          description: "Distance",
          scale: 1.3,
          key: key,
        );

  ValueUnitDescription.distanceSmall(int? distance, {Key? key})
      : this(
          value: distance == null ? null : (distance / 1000).toStringAsFixed(3),
          unit: "km",
          description: null,
          key: key,
        );

  ValueUnitDescription.speed(double? speed, {Key? key})
      : this(
          value: speed?.toStringAsFixed(1),
          unit: "km/h",
          description: "Speed",
          scale: 1.3,
          key: key,
        );

  ValueUnitDescription.speedSmall(double? speed, {Key? key})
      : this(
          value: speed?.toStringAsFixed(1),
          unit: "km/h",
          description: null,
          key: key,
        );

  ValueUnitDescription.calories(int? calories, {Key? key})
      : this(
          value: calories?.toString(),
          unit: "cal",
          description: "Energy",
          scale: 1.3,
          key: key,
        );

  ValueUnitDescription.ascent(int? ascent, {Key? key})
      : this(
          value: ascent?.toString(),
          unit: "m",
          description: "Ascent",
          scale: 1.3,
          key: key,
        );

  ValueUnitDescription.ascentSmall(int? ascent, {Key? key})
      : this(
          value: ascent?.toString(),
          unit: "m",
          description: null,
          key: key,
        );

  ValueUnitDescription.descent(int? descent, {Key? key})
      : this(
          value: descent?.toString(),
          unit: "m",
          description: "Descent",
          scale: 1.3,
          key: key,
        );

  ValueUnitDescription.descentSmall(int? descent, {Key? key})
      : this(
          value: descent?.toString(),
          unit: "m",
          description: null,
          key: key,
        );

  ValueUnitDescription.avgCadence(int? avgCadence, {Key? key})
      : this(
          value: avgCadence?.toString(),
          unit: "rpm",
          description: "Cadence",
          scale: 1.3,
          key: key,
        );

  ValueUnitDescription.avgHeartRate(int? avgHeartRate, {Key? key})
      : this(
          value: avgHeartRate?.toString(),
          unit: "bpm",
          description: "Heart Rate",
          scale: 1.3,
          key: key,
        );

  const ValueUnitDescription.name(String? name, {Key? key})
      : this(
          value: name,
          unit: null,
          description: "Name",
          scale: 1.3,
          key: key,
        );
}
