
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/authentication/authentication_bloc.dart';
import 'package:sport_log/routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          IconButton(
            onPressed: () {
              context.read<AuthenticationBloc>().add(const LogoutEvent());
              Navigator.pushNamedAndRemoveUntil(
                  context, Routes.landing, (route) => false);
            },
            icon: const Icon(
              Icons.logout
            ),
          ),
        ],
      ),
      body: const Center(
        child: Text("Hi"),
      ),
    );
  }
}
