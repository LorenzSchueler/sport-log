import 'package:flutter/material.dart' hide Route;
import 'package:provider/provider.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/account.dart';
import 'package:sport_log/helpers/bool_toggle.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/models/user/user.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/provider_consumer.dart';

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
    return AlertDialog(
      clipBehavior: Clip.antiAlias,
      title: const Text("Update Credentials"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Looks like you changed your credentials."),
            Defaults.sizedBox.vertical.big,
            _usernameInput(),
            Defaults.sizedBox.vertical.normal,
            _passwordInput(),
            Defaults.sizedBox.vertical.normal,
            Row(
              children: [
                FilledButton(
                  onPressed: Navigator.of(context).pop,
                  child: const Text("Ignore"),
                ),
                const Spacer(),
                if (_loginPending)
                  Container(
                    margin: const EdgeInsets.only(right: 20),
                    child: const CircularProgressIndicator(),
                  ),
                _submitButton(),
              ],
            ),
            if (_errorMessage != null) ...[
              Defaults.sizedBox.vertical.big,
              Text(_errorMessage!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _usernameInput() {
    return TextFormField(
      onChanged: (username) {
        final validated = Validator.validateUsername(username);
        if (validated == null) {
          setState(() => _username = username);
        }
      },
      decoration: const InputDecoration(
        icon: Icon(AppIcons.account),
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

  Widget _passwordInput() {
    return ProviderConsumer(
      create: (_) => BoolToggle.on(),
      builder: (context, obscure, _) => TextFormField(
        onChanged: (password) {
          final validated = Validator.validatePassword(password);
          if (validated == null) {
            setState(() => _password = password);
          }
        },
        decoration: InputDecoration(
          icon: const Icon(AppIcons.key),
          labelText: "Password",
          suffixIcon: IconButton(
            icon: obscure.isOn
                ? const Icon(AppIcons.visibility)
                : const Icon(AppIcons.visibilityOff),
            onPressed: obscure.toggle,
          ),
        ),
        validator: Validator.validatePassword,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        enabled: !_loginPending,
        style: _loginPending
            ? TextStyle(color: Theme.of(context).disabledColor)
            : null,
        textInputAction: TextInputAction.done,
        obscureText: obscure.isOn,
      ),
    );
  }

  Widget _submitButton() {
    return FilledButton(
      onPressed:
          (!_loginPending &&
              _formKey.currentContext != null &&
              _formKey.currentState!.validate())
          ? _submit
          : null,
      child: const Text("Update"),
    );
  }

  Future<void> _submit() async {
    setState(() => _loginPending = true);
    final result = await Account.login(
      context.read<Settings>().serverUrl,
      _username,
      _password,
    );
    if (mounted) {
      setState(() => _loginPending = false);
      if (result.isOk) {
        Navigator.pop(context, result.ok);
      } else {
        setState(() => _errorMessage = result.err.toString());
      }
    }
  }
}
