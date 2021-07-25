
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/pages/registration/registration_form.dart';
import 'package:sport_log/repositories/authentication_repository.dart';
import 'package:sport_log/authentication/authentication_bloc.dart';

import 'registration_bloc.dart';

class RegistrationPage extends StatelessWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(5),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500.0),
            child: BlocProvider<RegistrationBloc>(
              create: (context) {
                return RegistrationBloc(
                  authenticationBloc: context.read<AuthenticationBloc>(),
                  authenticationRepository: context.read<AuthenticationRepository?>(),
                );
              },
              child: const RegistrationForm(),
            ),
          ),
        ),
      ),
    );
  }
}
