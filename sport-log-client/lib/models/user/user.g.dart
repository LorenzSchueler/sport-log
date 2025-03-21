// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: const IdConverter().fromJson(json['id'] as String),
  username: json['username'] as String,
  password: json['password'] as String,
  email: json['email'] as String,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'username': instance.username,
  'password': instance.password,
  'email': instance.email,
};
