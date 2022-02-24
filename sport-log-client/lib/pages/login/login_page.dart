import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/account.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
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
      onChanged: (username) async {
        final validated = Validator.validateUsername(username);
        if (validated == null) {
          setState(() => _username = username);
        }
      },
      decoration: const InputDecoration(
        icon: Icon(AppIcons.account),
        labelText: "Username",
        contentPadding: EdgeInsets.symmetric(vertical: 5),
      ),
      validator: Validator.validateUsername,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      enabled: !_loginPending,
      style: _loginPending
          ? TextStyle(color: Theme.of(context).disabledColor)
          : null,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _passwordInput(
    BuildContext context,
  ) {
    return TextFormField(
      onChanged: (password) async {
        final validated = Validator.validatePassword(password);
        if (validated == null) {
          setState(() => _password = password);
        }
      },
      decoration: const InputDecoration(
        icon: Icon(AppIcons.key),
        labelText: "Password",
        contentPadding: EdgeInsets.symmetric(vertical: 5),
      ),
      validator: Validator.validatePassword,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      enabled: !_loginPending,
      style: _loginPending
          ? TextStyle(color: Theme.of(context).disabledColor)
          : null,
      textInputAction: TextInputAction.done,
      obscureText: false,
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
      onPressed: (!_loginPending &&
              _formKey.currentContext != null &&
              _formKey.currentState!.validate())
          ? () => _submit(context)
          : null,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: Defaults.borderRadius.big,
        ),
      ),
    );
  }

  void _submit(BuildContext context) async {
    setState(() {
      _loginPending = true;
    });
    final result = await Account.login(_username, _password);
    setState(() {
      _loginPending = false;
    });
    if (result.isSuccess) {
      Nav.newBase(context, Routes.timeline.overview);
    } else {
      await showMessageDialog(context: context, text: result.failure);
    }
    _formKey.currentState!.deactivate();
  }
}
