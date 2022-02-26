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
  sunday,
}
