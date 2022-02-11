import 'package:flutter/material.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/sync.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/user/user.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _logger = Logger('LoginPage');
  final _formKey = GlobalKey<FormState>();
  String _username = "";
  String _password = "";
  bool _loginPending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(5),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500.0),
            child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _usernameInput(context),
                    Defaults.sizedBox.vertical.normal,
                    _passwordInput(context),
                    Defaults.sizedBox.vertical.normal,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_loginPending)
                          Container(
                            child: const CircularProgressIndicator(),
                            margin: const EdgeInsets.only(right: 20),
                          ),
                        _submitButton(context),
                      ],
                    )
                  ],
                )),
          ),
        ),
      ),
    );
  }

  Widget _usernameInput(
    BuildContext context,
  ) {
    return TextFormField(
      onChanged: (username) {
        setState(() {
          _username = username;
        });
      },
      decoration: InputDecoration(
        labelText: "Username",
        border: OutlineInputBorder(borderRadius: Defaults.borderRadius.big),
      ),
      validator: _usernameValidator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      enabled: !_loginPending,
      style: _loginPending
          ? TextStyle(color: Theme.of(context).disabledColor)
          : null,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _passwordInput(
    BuildContext context,
  ) {
    return TextFormField(
      onChanged: (password) {
        setState(() {
          _password = password;
        });
      },
      decoration: InputDecoration(
        labelText: "Password",
        border: OutlineInputBorder(borderRadius: Defaults.borderRadius.big),
      ),
      validator: _passwordValidator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      enabled: !_loginPending,
      style: _loginPending
          ? TextStyle(color: Theme.of(context).disabledColor)
          : null,
      textInputAction: TextInputAction.done,
      obscureText: true,
      onFieldSubmitted:
          (!_loginPending && _inputsAreValid) ? (_) => _submit(context) : null,
    );
  }

  Widget _submitButton(
    BuildContext context,
  ) {
    return ElevatedButton(
      child: const Text(
        "Login",
        style: TextStyle(fontSize: 18),
      ), // TODO: use theme for this
      onPressed:
          (!_loginPending && _inputsAreValid) ? () => _submit(context) : null,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: Defaults.borderRadius.big,
        ),
      ),
    );
  }

  bool get _formIsValid => _formKey.currentState!.validate();

  bool get _inputsAreValid =>
      _usernameValidator(_username) == null &&
      _passwordValidator(_password) == null;

  void _submit(BuildContext context) async {
    if (_formIsValid) {
      setState(() {
        _loginPending = true;
      });
      final result = await Api.instance.user.getSingle(_username, _password);
      if (result.isSuccess) {
        setState(() {
          _loginPending = false;
        });
        User user = result.success;
        Settings.instance.user = user;
        Sync.instance.startSync();
        Nav.changeNamed(context, Routes.timeline.overview);
      } else {
        final snackBar = SnackBar(
          content: Text(result.failure.toErrorMessage()),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        setState(() {
          _loginPending = false;
        });
      }
      _formKey.currentState!.deactivate();
    }
  }

  String? _usernameValidator(String? username) {
    if (username != null && username.isEmpty) {
      return "Username must not be empty.";
    } else if (username != null && username.contains(':')) {
      return "Username must not contain ':'.";
    } else {
      return null;
    }
  }

  String? _passwordValidator(String? password) {
    return password != null && password.isEmpty
        ? "Password must not be empty"
        : null;
  }
}
