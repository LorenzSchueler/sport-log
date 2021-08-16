
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:intl/intl.dart';

class IdConverter extends JsonConverter<Int64, String> {
  const IdConverter() : super();

  @override
  Int64 fromJson(String json) {
    return Int64.parseInt(json);
  }

  @override
  String toJson(Int64 object) {
    return object.toString();
  }
}

class OptionalIdConverter extends JsonConverter<Int64?, String?> {
  const OptionalIdConverter() : super();

  @override
  Int64? fromJson(String? json) {
    return (json == null) ? null : Int64.parseInt(json);
  }

  @override
  String? toJson(Int64? object) {
    return (object == null) ? null : object.toString();
  }
}

class DateConverter extends JsonConverter<DateTime, String> {
  const DateConverter() : super();

  @override
  DateTime fromJson(String json) {
    return DateTime.parse(json);
  }

  @override
  String toJson(DateTime object) {
    return DateFormat('yyyy-MM-dd').format(object);
  }
}

class DateTimeConverter extends JsonConverter<DateTime, String> {
  const DateTimeConverter() : super();

  @override
  DateTime fromJson(String json) {
    return DateTime.parse(json);
  }

  @override
  String toJson(DateTime object) {
    return object.toIso8601String() + '+00:00';
  }
}