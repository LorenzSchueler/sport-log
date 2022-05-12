import 'package:json_annotation/json_annotation.dart';

enum Weekday {
  @JsonValue("Monday")
  monday,
  @JsonValue("Tuesday")
  tuesday,
  @JsonValue("Wednesday")
  wednesday,
  @JsonValue("Thursday")
  thursday,
  @JsonValue("Friday")
  friday,
  @JsonValue("Saturday")
  saturday,
  @JsonValue("Sunday")
  sunday;

  @override
  String toString() {
    switch (this) {
      case Weekday.monday:
        return "Monday";
      case Weekday.tuesday:
        return "Tuesday";
      case Weekday.wednesday:
        return "Wednesday";
      case Weekday.thursday:
        return "Thursday";
      case Weekday.friday:
        return "Friday";
      case Weekday.saturday:
        return "Saturday";
      case Weekday.sunday:
        return "Sunday";
    }
  }
}
