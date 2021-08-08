
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
      final id = int.tryParse(map[idKey]!);
      if (id == null) {
        return null;
      }
      return User(
          id: id,
          username: map[usernameKey]!,
          password: map[passwordKey]!,
          email: map[emailKey]!
      );
    }
    return null;
  }
}