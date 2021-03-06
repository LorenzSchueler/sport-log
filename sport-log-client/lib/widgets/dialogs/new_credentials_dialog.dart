import 'package:flutter/material.dart' hide Route;
import 'package:provider/provider.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/account.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/models/user/user.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/theme.dart';
import 'package:sport_log/widgets/app_icons.dart';

Future<void> showNewCredentialsDialog() async {
  if (!NewCredentialsDialog.isShown) {
    NewCredentialsDialog.isShown = true;
    await showDialog<User>(
      builder: (_) => const NewCredentialsDialog(),
      context: App.globalContext,
    );
    NewCredentialsDialog.isShown = false;
  }
}

class NewCredentialsDialog extends StatefulWidget {
  const NewCredentialsDialog({super.key});

  static bool isShown = false;

  @override
  State<NewCredentialsDialog> createState() => _NewCredentialsDialogState();
}

class _NewCredentialsDialogState extends State<NewCredentialsDialog> {
  final _formKey = GlobalKey<FormState>();
  String _username = "";
  String _password = "";
  bool _loginPending = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: Defaults.edgeInsets.normal,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Looks like you changed your credentials on another device.\nPlease update them below!",
              style: Theme.of(context).textTheme.subtitle1,
            ),
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
                    children: [
                      ElevatedButton(
                        onPressed: Navigator.of(context).pop,
                        child: const Text("Ignore"),
                      ),
                      const Spacer(),
                      if (_loginPending)
                        Container(
                          margin: const EdgeInsets.only(right: 20),
                          child: const CircularProgressIndicator(),
                        ),
                      _submitButton(context),
                    ],
                  )
                ],
              ),
            ),
            Defaults.sizedBox.vertical.big,
            if (_errorMessage != null) Text(_errorMessage!)
          ],
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
      decoration: Theme.of(context).textFormFieldDecoration.copyWith(
            icon: const Icon(AppIcons.account),
            labelText: "Username",
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
      onChanged: (password) async {
        final validated = Validator.validatePassword(password);
        if (validated == null) {
          setState(() => _password = password);
        }
      },
      decoration: Theme.of(context).textFormFieldDecoration.copyWith(
            icon: const Icon(AppIcons.key),
            labelText: "Password",
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
      onPressed: (!_loginPending &&
              _formKey.currentContext != null &&
              _formKey.currentState!.validate())
          ? () => _submit(context)
          : null,
      child: const Text("Update"),
    );
  }

  Future<void> _submit(BuildContext context) async {
    setState(() {
      _loginPending = true;
    });
    final result = await Account.login(
      context.read<Settings>().serverUrl,
      _username,
      _password,
    );
    setState(() {
      _loginPending = false;
    });
    if (result.isSuccess) {
      if (mounted) {
        Navigator.pop(context, result.success);
      }
    } else {
      setState(() {
        _errorMessage = result.failure.toString();
      });
    }
    _formKey.currentState!.deactivate();
  }
}
