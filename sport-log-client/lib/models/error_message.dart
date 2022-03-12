import 'package:json_annotation/json_annotation.dart';

part 'error_message.g.dart';

@JsonSerializable()
class ConflictDescriptor extends JsonSerializable {
  String table;
  List<String> columns;

  ConflictDescriptor({required this.table, required this.columns});

  factory ConflictDescriptor.fromJson(Map<String, dynamic> json) =>
      _$ConflictDescriptorFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ConflictDescriptorToJson(this);
}

@JsonSerializable()
class ErrorMessage extends JsonSerializable {
  ErrorMessage({required this.status, required this.message});

  int status;
  Map<String, ConflictDescriptor>? message;

  factory ErrorMessage.fromJson(Map<String, dynamic> json) =>
      _$ErrorMessageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ErrorMessageToJson(this);
}
