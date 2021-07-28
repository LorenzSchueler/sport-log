
part of 'authentication_bloc.dart';

abstract class AuthenticationState extends Equatable {
  @override
  List<Object?> get props => [];
}

class Unauthenticated extends AuthenticationState {}

class Authenticated extends AuthenticationState {
  Authenticated({
    required this.user
  }) : super();

  final User user;

  @override
  List<Object?> get props => [user];
}