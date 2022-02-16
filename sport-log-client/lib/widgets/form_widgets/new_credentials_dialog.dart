import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/app.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/account.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/models/user/user.dart';

Future<User?> showNewCredentialsDialog() async {
  return showDialog<User>(
    builder: (_) => const NewCredentialsDialog(),
    barrierDismissible: false,
    context: AppState.navigatorKey.currentContext!,
  );
}

class NewCredentialsDialog extends StatefulWidget {
  const NewCredentialsDialog({Key? key}) : super(key: key);

  @override
  State<NewCredentialsDialog> createState() => NewCredentialsDialogState();
}

class NewCredentialsDialogState extends State<NewCredentialsDialog> {
  final _formKey = GlobalKey<FormState>();
  String _username = "";
  String _password = "";
  bool _loginPending = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
        clipBehavior: Clip.antiAlias,
        child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(children: [
              const Text(
                  "Looks like you changed you credentials on another device.\nPlease update your credentials!"),
              Defaults.sizedBox.vertical.big,
              Form(
                  key: _formKey,
                  child: Column(
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
                  ))
            ])));
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
      onChanged: (password) {
        setState(() {
          _password = password;
        });
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
        Navigator.of(context).pop(result.success);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.failure),
        ));
      }
      _formKey.currentState!.deactivate();
    }
  }
}
