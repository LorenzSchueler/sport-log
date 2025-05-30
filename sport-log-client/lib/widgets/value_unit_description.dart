import 'package:flutter/material.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/models/cardio/cardio_session.dart';

class ValueUnitDescription extends StatelessWidget {
  const ValueUnitDescription({
    required String? value,
    required this.unit,
    required this.description,
    this.scale = 1,
    this.smallValue = false,
    super.key,
  }) : value = value ?? "--";

  ValueUnitDescription.ascent(int? ascent, {Key? key})
    : this(
        value: ascent?.toString(),
        unit: "m",
        description: "Ascent",
        scale: 1.3,
        key: key,
      );

  ValueUnitDescription.ascentSmall(int? ascent, {Key? key})
    : this(value: ascent?.toString(), unit: "m", description: null, key: key);

  ValueUnitDescription.avgCadence(
    int? avgCadence, {
    bool current = false,
    Key? key,
  }) : this(
         value: avgCadence?.toString(),
         unit: "rpm",
         description: current ? "Current Cadence" : "Cadence",
         scale: 1.3,
         key: key,
       );

  ValueUnitDescription.avgHeartRate(
    int? avgHeartRate, {
    bool current = false,
    Key? key,
  }) : this(
         value: avgHeartRate?.toString(),
         unit: "bpm",
         description: current ? "Current Heart Rate" : "Heart Rate",
         scale: 1.3,
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

  ValueUnitDescription.cardioType(CardioType cardioType, {Key? key})
    : this(
        value: cardioType.name,
        unit: null,
        description: "Type",
        scale: 1.3,
        smallValue: true,
        key: key,
      );

  ValueUnitDescription.datetime(DateTime datetime, {Key? key})
    : this(
        value: datetime.humanDateTime,
        unit: null,
        description: "Date",
        scale: 1.3,
        smallValue: true,
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
    : this(value: descent?.toString(), unit: "m", description: null, key: key);

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

  ValueUnitDescription.elevation(int? elevation, {Key? key})
    : this(
        value: elevation?.toString(),
        unit: "m",
        description: "Elevation",
        scale: 1.3,
        key: key,
      );

  ValueUnitDescription.position(LatLng? latLng, {Key? key})
    : this(
        value: latLng?.toString(),
        unit: null,
        description: "Position",
        scale: 1.3,
        key: key,
      );

  const ValueUnitDescription.name(String? name, {Key? key})
    : this(value: name, unit: null, description: "Name", scale: 1.3, key: key);

  ValueUnitDescription.speed(double? speed, {bool current = false, Key? key})
    : this(
        value: speed?.toStringAsFixed(1),
        unit: "km/h",
        description: current ? "Current Speed" : "Speed",
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

  ValueUnitDescription.tempo(Duration? tempo, {bool current = false, Key? key})
    : this(
        value: tempo?.formatTimeShort,
        unit: "/km",
        description: current ? "Current Tempo" : "Tempo",
        scale: 1.3,
        key: key,
      );

  ValueUnitDescription.time(Duration? time, {Key? key})
    : this(
        value: time?.formatHms,
        unit: null,
        description: "Duration",
        scale: 1.3,
        key: key,
      );

  ValueUnitDescription.timeSmall(Duration? time, {Key? key})
    : this(value: time?.formatHms, unit: null, description: null, key: key);

  final String value;
  final String? unit;
  final String? description;
  final double scale;
  final bool smallValue;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: unit == null ? value : "$value ",
            style: TextStyle(fontSize: scale * (smallValue ? 14 : 20)),
          ),
          if (unit != null)
            TextSpan(
              text: unit,
              style: TextStyle(fontSize: scale * 14),
            ),
          if (description != null)
            TextSpan(
              text: "\n$description",
              style: TextStyle(fontSize: scale * 12),
            ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
