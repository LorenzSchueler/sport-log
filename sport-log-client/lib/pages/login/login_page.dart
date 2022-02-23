import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/account.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/message_dialog.dart';

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
      onFieldSubmitted: (username) async {
        final validated = Validator.validateUsername(username);
        if (validated == null) {
          setState(() => _username = username);
        } else {
          await showMessageDialog(context: context, text: validated);
        }
      },
      decoration: InputDecoration(
        labelText: "Username",
        border: OutlineInputBorder(borderRadius: Defaults.borderRadius.big),
      ),
      validator: Validator.validateUsername,
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
      onFieldSubmitted: (password) async {
        final validated = Validator.validatePassword(password);
        if (validated == null) {
          setState(() => _password = password);
        } else {
          await showMessageDialog(context: context, text: validated);
        }
      },
      decoration: InputDecoration(
        labelText: "Password",
        border: OutlineInputBorder(borderRadius: Defaults.borderRadius.big),
      ),
      validator: Validator.validatePassword,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      enabled: !_loginPending,
      style: _loginPending
          ? TextStyle(color: Theme.of(context).disabledColor)
          : null,
      textInputAction: TextInputAction.done,
      obscureText: true,
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

  bool get _inputsAreValid =>
      Validator.validateUsername(_username) == null &&
      Validator.validatePassword(_password) == null;

  void _submit(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _loginPending = true;
      });
      final result = await Account.login(_username, _password);
      setState(() {
        _loginPending = false;
      });
      if (result.isSuccess) {
        Nav.changeNamed(context, Routes.timeline.overview);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.failure),
        ));
      }
      _formKey.currentState!.deactivate();
    }
  }
}
