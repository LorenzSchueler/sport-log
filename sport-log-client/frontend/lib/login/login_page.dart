
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/authentication/authentication_bloc.dart';
import 'package:models/authentication_state.dart';
import 'package:sport_log/routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  bool _usernameIsPure = true;
  final TextEditingController _usernameController = TextEditingController();

  bool _passwordIsPure = true;
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: EdgeInsets.all(5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: _usernameController,
              onChanged: (username) {
                setState(() {
                  _usernameIsPure = false;
                });
              },
              decoration: InputDecoration(
                labelText: "Username",
                errorText: (!_usernameIsPure && _usernameController.text.isEmpty)
                    ? "Username must not be empty." : null,
              ),
            ),
            const Padding(padding: EdgeInsets.all(12)),
            TextFormField(
              controller: _passwordController,
              onChanged: (username) {
                setState(() {
                  _passwordIsPure = false;
                });
              },
              decoration: InputDecoration(
                labelText: "Password",
                errorText: (!_passwordIsPure && _passwordController.text.isEmpty)
                    ? "Password must not be empty." : null,
              ),
              obscureText: true,
            ),
            const Padding(padding: EdgeInsets.all(12)),
            ElevatedButton(
              onPressed: () {
                debugPrint("pressed1");
                // context.read<AuthenticationBloc>().add(
                //   LoginEvent(
                //     username: _usernameController.text,
                //     password: _passwordController.text
                //   )
                // );
                debugPrint("pressed2");
                Navigator.of(context).pushNamed(Routes.home);
              },
              child: const Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}