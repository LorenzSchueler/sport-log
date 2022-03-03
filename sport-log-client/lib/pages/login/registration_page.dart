import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/account.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/models/user/user.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';

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
    return TextFormField(
      onChanged: (serverUrl) async {
        final validated = Validator.validateUrl(serverUrl);
        if (validated == null) {
          setState(() => _serverUrl = serverUrl);
        }
      },
      controller: _serverUrlInputController,
      decoration: InputDecoration(
        icon: const Icon(AppIcons.cloudUpload),
        labelText: "Server URL",
        contentPadding: const EdgeInsets.symmetric(vertical: 5),
        suffixIcon: IconButton(
          onPressed: () async {
            await Settings.setDefaultServerUrl();
            setState(() {
              _serverUrlInputController.text = Settings.serverUrl;
            });
          },
          icon: const Icon(AppIcons.restore),
        ),
      ),
      validator: Validator.validateUrl,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      enabled: !_registrationPending,
      style: _registrationPending
          ? TextStyle(color: Theme.of(context).disabledColor)
          : null,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _usernameInput(BuildContext context) {
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
      enabled: !_registrationPending,
      style: _registrationPending
          ? TextStyle(color: Theme.of(context).disabledColor)
          : null,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _passwordInput1(BuildContext context) {
    return TextFormField(
      onChanged: (password) async {
        final validated = Validator.validatePassword(password);
        if (validated == null) {
          setState(() => _password1 = password);
        }
      },
      decoration: const InputDecoration(
        icon: Icon(AppIcons.key),
        labelText: "Password",
        contentPadding: EdgeInsets.symmetric(vertical: 5),
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
      onChanged: (password2) async {
        final validated = Validator.validatePassword2(_password1, password2);
        if (validated == null) {
          setState(() => _password2 = password2);
        }
      },
      decoration: const InputDecoration(
        icon: Icon(AppIcons.key),
        labelText: "Repeat password",
        contentPadding: EdgeInsets.symmetric(vertical: 5),
      ),
      validator: (password2) =>
          Validator.validatePassword2(_password1, password2),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      enabled: !_registrationPending,
      style: _registrationPending
          ? TextStyle(color: Theme.of(context).disabledColor)
          : null,
      textInputAction: TextInputAction.next,
      obscureText: true,
    );
  }

  Widget _emailInput(BuildContext context) {
    return TextFormField(
      onChanged: (email) async {
        final validated = Validator.validateEmail(email);
        if (validated == null) {
          setState(() => _email = email);
        }
      },
      decoration: const InputDecoration(
        icon: Icon(AppIcons.email),
        labelText: "Email",
        contentPadding: EdgeInsets.symmetric(vertical: 5),
      ),
      validator: Validator.validateEmail,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      enabled: !_registrationPending,
      style: _registrationPending
          ? TextStyle(color: Theme.of(context).disabledColor)
          : null,
      textInputAction: TextInputAction.done,
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _submitButton(BuildContext context) {
    return ElevatedButton(
      child: const Text(
        "Register",
        style: TextStyle(fontSize: 18),
      ), // TODO: use theme for this
      onPressed: (!_registrationPending &&
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

  Future<void> _submit(BuildContext context) async {
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
      Nav.newBase(context, Routes.timeline.overview);
    } else {
      await showMessageDialog(context: context, text: result.failure);
    }
    _formKey.currentState!.deactivate();
  }
}
