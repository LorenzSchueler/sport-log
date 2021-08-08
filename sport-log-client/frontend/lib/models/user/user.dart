
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  User({
    required this.id,
    required this.username,
    required this.password,
    required this.email,
  });

  int id;
  String username;
  String password;
  String email;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable()
class NewUser {
  NewUser({
    required this.username,
    required this.password,
    required this.email,
  });

  String username;
  String password;
  String email;

  factory NewUser.fromJson(Map<String, dynamic> json) => _$NewUserFromJson(json);
  Map<String, dynamic> toJson() => _$NewUserToJson(this);
}
