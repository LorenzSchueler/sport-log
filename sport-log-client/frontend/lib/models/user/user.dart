
import 'dart:developer';

import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/helpers/json_serialization.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  User({
    required this.id,
    required this.username,
    required this.password,
    required this.email,
  });

  @IdConverter() Int64 id;
  String username;
  String password;
  String email;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  @override
  String toString() {
    return 'User(id: $id, username: $username, password: $password, email: $email)';
  }

  static const idKey = 'id';
  static const usernameKey = 'username';
  static const passwordKey = 'password';
  static const emailKey = 'email';

  static const List<String> allKeys = [idKey, usernameKey, passwordKey, emailKey];

  /// used for storing key value pairs in local storage
  Map<String, String> toMap() => {
    idKey: id.toString(),
    usernameKey: username,
    passwordKey: password,
    emailKey: email,
  };

  /// used for storing key value pairs in local storage
  static User? fromMap(Map<String, String> map) {
    if (map.containsKey(idKey) && map.containsKey(usernameKey)
        && map.containsKey(passwordKey) && map.containsKey(emailKey)) {
      try {
        final id = Int64.parseInt(map[idKey]!);
        return User(
            id: id,
            username: map[usernameKey]!,
            password: map[passwordKey]!,
            email: map[emailKey]!
        );
      } on FormatException catch (e) {
        log("Id parsing error.", error: e);
        return null;
      }
    }
    return null;
  }
}