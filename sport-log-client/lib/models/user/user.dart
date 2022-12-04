import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/models/clone_extensions.dart';
import 'package:sport_log/models/entity_interfaces.dart';

part 'user.g.dart';

@JsonSerializable()
class User extends NonDeletableAtomicEntity {
  User({
    required this.id,
    required this.username,
    required this.password,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  @override
  @IdConverter()
  Int64 id;
  String username;
  String password;
  String email;

  @override
  Map<String, dynamic> toJson() => _$UserToJson(this);

  @override
  User clone() => User(
        id: id.clone(),
        username: username,
        password: password,
        email: email,
      );

  @override
  bool isValidBeforeSanitation() {
    return validate(username.isNotEmpty, 'User: username is empty') &&
        validate(username.length >= 2, 'User: username.length < 2') &&
        validate(password.isNotEmpty, 'User: password is empty') &&
        validate(
          Validator.validateEmail(email) == null,
          'User: email is not valid',
        );
  }

  @override
  bool isValid() {
    return isValidBeforeSanitation();
  }

  @override
  void sanitize() {}
}
