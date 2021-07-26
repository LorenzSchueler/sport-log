
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/pages/login/login_form.dart';
import 'package:sport_log/repositories/authentication_repository.dart';
import 'package:sport_log/authentication/authentication_bloc.dart';
import 'package:sport_log/pages/login/login_bloc.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(5),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500.0),
            child: BlocProvider<LoginBloc>(
              create: (context) {
                return LoginBloc(
                  authenticationBloc: context.read<AuthenticationBloc>(),
                  authenticationRepository: context.read<AuthenticationRepository?>(),
                  api: context.read<Api>(),
                  showErrorSnackBar: (text) {
                    final snackBar = SnackBar(
                      content: Text(text),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  },
                );
              },
              child: const LoginForm(),
            ),
          ),
        ),
      ),
    );
  }
}
