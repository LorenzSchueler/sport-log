import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
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

  @override
  bool isValid() {
    return validate(username.isNotEmpty, 'User: username is empty') &&
        validate(password.isNotEmpty, 'User: password is empty') &&
        validate(
            Validator.validateEmail(email) == null, 'User: email is not valid');
  }
}
