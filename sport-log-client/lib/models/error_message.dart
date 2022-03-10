import 'package:json_annotation/json_annotation.dart';

part 'error_message.g.dart';

@JsonSerializable()
class ErrorMessage extends JsonSerializable {
  ErrorMessage({required this.status, required this.message});

  int status;
  Map<String, String>? message;

  factory ErrorMessage.fromJson(Map<String, dynamic> json) =>
      _$ErrorMessageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ErrorMessageToJson(this);
}
