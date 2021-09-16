
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/blocs/authentication/authentication_bloc.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/routes.dart';

class ProtectedRoute extends StatelessWidget {
  const ProtectedRoute({
    Key? key,
    required this.builder,
  }) : super(key: key);

  final Widget Function(BuildContext) builder;

  @override
  Widget build(BuildContext context) {
    if (BlocProvider.of<AuthenticationBloc>(context).state == Unauthenticated()) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Not logged in"),
        ),
        body: Align(
          alignment: Alignment.center,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text("You're currently not logged in.") ,
                const Padding(
                  padding: EdgeInsets.all(12),
                ),
                ElevatedButton(
                  onPressed: () {
                    Nav.changeNamed(context, Routes.landing);
                  },
                  child: const Text("Go back..."),
                ),
              ]
          ),
        )
      );
    }
    return builder(context);
  }
}