
part of 'authentication_bloc.dart';

abstract class AuthenticationState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UnauthenticatedAuthenticationState extends AuthenticationState {}

class AuthenticatedAuthenticationState extends AuthenticationState {
  AuthenticatedAuthenticationState({
    required this.user
  }) : super();

  final User user;

  @override
  List<Object?> get props => [user];
}