
import 'package:json_annotation/json_annotation.dart';

String _padToTwoDigits(int num) {
  assert(num >= 0);
  assert(num < 100);
  return (num <= 9) ? "0$num" : "$num";
}

class NaiveTime {
  NaiveTime({
    required this.hours,
    required this.minutes,
    required this.seconds,
  }) : assert(hours >= 0 && hours < 24),
       assert(minutes >= 0 && minutes < 60),
       assert(seconds >= 0 && seconds < 60);

  int hours;
  int minutes;
  int seconds;
  
  String toTimeString() {
    final hoursStr = _padToTwoDigits(hours);
    final minsStr = _padToTwoDigits(minutes);
    final secsStr = _padToTwoDigits(seconds);
    return hoursStr + ':' + minsStr + ':' + secsStr;
  }

  static NaiveTime? fromTimeString(String s) {
    final pattern = RegExp(r'(?<hour>\d+):(?<minute>\d+):(?<second>[\d.]+)');
    final match = pattern.firstMatch(s);

    final hoursStr = match?.namedGroup('hour');
    final minsStr = match?.namedGroup('minute');
    final secsStr = match?.namedGroup('second');

    if (hoursStr == null || minsStr == null || secsStr == null) {
      return null;
    }

    final hours = int.tryParse(hoursStr);
    final mins = int.tryParse(minsStr);
    final secs = double.tryParse(secsStr);

    if (hours == null || mins == null || secs == null
      || hours < 0 || hours >= 24
      || mins < 0 || mins >= 60
      || secs < 0 || secs >= 60) {
      return null;
    }

    return NaiveTime(hours: hours, minutes: mins, seconds: secs.round());
  }
}

class NaiveTimeSerde extends JsonConverter<NaiveTime, String> {
  const NaiveTimeSerde() : super();

  @override
  NaiveTime fromJson(String json) {
    final result = NaiveTime.fromTimeString(json);
    if (result == null) {
      throw ArgumentError.value(json, "Not able to parse naive time.");
    }
    return result;
  }

  @override
  String toJson(NaiveTime object) {
    return object.toTimeString();
  }
}