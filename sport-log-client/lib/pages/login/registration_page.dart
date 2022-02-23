import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/account.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/models/user/user.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/message_dialog.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  String _serverUrl = Settings.serverUrl;
  String _username = "";
  String _password1 = "";
  String _password2 = "";
  String _email = "";

  bool _registrationPending = false;

  late TextEditingController _serverUrlInputController;

  @override
  void initState() {
    super.initState();
    _serverUrlInputController = TextEditingController(text: _serverUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Container(
        padding: const EdgeInsets.all(5),
        child: Center(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _serverUrlInput(context),
                Defaults.sizedBox.vertical.normal,
                _usernameInput(context),
                Defaults.sizedBox.vertical.normal,
                _passwordInput1(context),
                Defaults.sizedBox.vertical.normal,
                _passwordInput2(context),
                Defaults.sizedBox.vertical.normal,
                _emailInput(context),
                Defaults.sizedBox.vertical.normal,
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_registrationPending)
                      Container(
                        child: const CircularProgressIndicator(),
                        margin: const EdgeInsets.only(right: 20),
                      ),
                    _submitButton(context),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _serverUrlInput(BuildContext context) {
    return Row(children: [
      Expanded(
        child: TextFormField(
          onFieldSubmitted: (serverUrl) async {
            final validated = Validator.validateUrl(serverUrl);
            if (validated == null) {
              setState(() => _serverUrl = serverUrl);
            } else {
              await showMessageDialog(context: context, text: validated);
            }
          },
          controller: _serverUrlInputController,
          decoration: InputDecoration(
            labelText: "Server URL",
            border: OutlineInputBorder(borderRadius: Defaults.borderRadius.big),
          ),
          validator: Validator.validateUrl,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          enabled: !_registrationPending,
          style: _registrationPending
              ? TextStyle(color: Theme.of(context).disabledColor)
              : null,
          textInputAction: TextInputAction.next,
        ),
      ),
      IconButton(
          onPressed: () async {
            await Settings.setDefaultServerUrl();
            setState(() {
              _serverUrlInputController.text = Settings.serverUrl;
            });
          },
          icon: const Icon(Icons.settings_backup_restore))
    ]);
  }

  Widget _usernameInput(BuildContext context) {
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
      enabled: !_registrationPending,
      style: _registrationPending
          ? TextStyle(color: Theme.of(context).disabledColor)
          : null,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _passwordInput1(BuildContext context) {
    return TextFormField(
      onFieldSubmitted: (password) async {
        final validated = Validator.validatePassword(password);
        if (validated == null) {
          setState(() => _password1 = password);
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
      enabled: !_registrationPending,
      style: _registrationPending
          ? TextStyle(color: Theme.of(context).disabledColor)
          : null,
      textInputAction: TextInputAction.next,
      obscureText: true,
    );
  }

  Widget _passwordInput2(BuildContext context) {
    return TextFormField(
      onFieldSubmitted: (password2) async {
        final validated = Validator.validatePassword2(_password1, password2);
        if (validated == null) {
          setState(() => _password2 = password2);
        } else {
          await showMessageDialog(context: context, text: validated);
        }
      },
      decoration: InputDecoration(
        labelText: "Repeat password",
        border: OutlineInputBorder(borderRadius: Defaults.borderRadius.big),
      ),
      validator: (password2) =>
          Validator.validatePassword2(_password1, password2),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      enabled: !_registrationPending,
      style: _registrationPending
          ? TextStyle(color: Theme.of(context).disabledColor)
          : null,
      textInputAction: TextInputAction.done,
      obscureText: true,
    );
  }

  Widget _emailInput(BuildContext context) {
    return TextFormField(
      onFieldSubmitted: (email) async {
        final validated = Validator.validateEmail(email);
        if (validated == null) {
          setState(() => _email = email);
        } else {
          await showMessageDialog(context: context, text: validated);
        }
      },
      decoration: InputDecoration(
        labelText: "Email",
        border: OutlineInputBorder(borderRadius: Defaults.borderRadius.big),
      ),
      validator: Validator.validateEmail,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      enabled: !_registrationPending,
      style: _registrationPending
          ? TextStyle(color: Theme.of(context).disabledColor)
          : null,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _submitButton(BuildContext context) {
    return ElevatedButton(
      child: const Text(
        "Register",
        style: TextStyle(fontSize: 18),
      ), // TODO: use theme for this
      onPressed: (!_registrationPending && _inputsAreValid)
          ? () => _submit(context)
          : null,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: Defaults.borderRadius.big,
        ),
      ),
    );
  }

  bool get _inputsAreValid =>
      Validator.validateUrl(_serverUrl) == null &&
      Validator.validateUsername(_username) == null &&
      Validator.validateEmail(_email) == null &&
      Validator.validatePassword(_password1) == null &&
      Validator.validatePassword2(_password1, _password2) == null;

  void _submit(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _registrationPending = true;
      });
      Settings.serverUrl = _serverUrl;
      final user = User(
        id: randomId(),
        email: _email,
        username: _username,
        password: _password1,
      );
      final result = await Account.register(user);
      setState(() {
        _registrationPending = false;
      });
      if (result.isSuccess) {
        Nav.changeNamed(context, Routes.timeline.overview);
      } else {
        await showMessageDialog(context: context, text: result.failure);
      }
      _formKey.currentState!.deactivate();
    }
  }
}
