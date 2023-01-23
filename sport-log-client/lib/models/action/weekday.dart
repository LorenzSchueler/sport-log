import 'package:json_annotation/json_annotation.dart';

enum Weekday {
  @JsonValue("Monday")
  monday("Monday"),
  @JsonValue("Tuesday")
  tuesday("Tuesday"),
  @JsonValue("Wednesday")
  wednesday("Wednesday"),
  @JsonValue("Thursday")
  thursday("Thursday"),
  @JsonValue("Friday")
  friday("Friday"),
  @JsonValue("Saturday")
  saturday("Saturday"),
  @JsonValue("Sunday")
  sunday("Sunday");

  const Weekday(this.name);
  final String name;
}
