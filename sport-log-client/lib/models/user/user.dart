import 'package:email_validator/email_validator.dart';
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/helpers/validation.dart';

part 'user.g.dart';

final _logger = Logger('USER');

@JsonSerializable()
class User implements Validatable {
  User({
    required this.id,
    required this.username,
    required this.password,
    required this.email,
  });

  @IdConverter()
  Int64 id;
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

  static const List<String> allKeys = [
    idKey,
    usernameKey,
    passwordKey,
    emailKey
  ];

  /// used for storing key value pairs in local storage
  Map<String, String> toMap() => {
        idKey: id.toString(),
        usernameKey: username,
        passwordKey: password,
        emailKey: email,
      };

  /// used for storing key value pairs in local storage
  static User? fromMap(Map<String, String> map) {
    if (map.containsKey(idKey) &&
        map.containsKey(usernameKey) &&
        map.containsKey(passwordKey) &&
        map.containsKey(emailKey)) {
      try {
        final id = Int64.parseInt(map[idKey]!);
        return User(
            id: id,
            username: map[usernameKey]!,
            password: map[passwordKey]!,
            email: map[emailKey]!);
      } on FormatException catch (e) {
        _logger.e("Id parsing error: " + e.toString());
        return null;
      }
    }
    return null;
  }

  @override
  bool isValid() {
    return username.isNotEmpty &&
        password.isNotEmpty &&
        EmailValidator.validate(email);
  }
}
