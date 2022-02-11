import 'package:flutter/material.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/sync.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/models/user/user.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  // TODO: use User class
  String _username = "";
  String _email = "";
  String _password1 = "";
  String _password2 = "";

  bool _registrationPending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
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
                  _emailInput(context),
                  Defaults.sizedBox.vertical.normal,
                  _passwordInput1(context),
                  Defaults.sizedBox.vertical.normal,
                  _passwordInput2(context),
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
      ),
    );
  }

  Widget _usernameInput(BuildContext context) {
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
      enabled: !_registrationPending,
      style: _registrationPending
          ? TextStyle(color: Theme.of(context).disabledColor)
          : null,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _emailInput(BuildContext context) {
    return TextFormField(
      onChanged: (email) {
        setState(() {
          _email = email;
        });
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

  Widget _passwordInput1(BuildContext context) {
    return TextFormField(
      onChanged: (password) {
        setState(() {
          _password1 = password;
        });
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
      onChanged: (password) {
        setState(() {
          _password2 = password;
        });
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
      onFieldSubmitted: (!_registrationPending && _inputsAreValid)
          ? (_) => _submit(context)
          : null,
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

  bool get _formIsValid => _formKey.currentState!.validate();

  bool get _inputsAreValid =>
      Validator.validateUsername(_username) == null &&
      Validator.validateEmail(_email) == null &&
      Validator.validatePassword(_password1) == null &&
      Validator.validatePassword2(_password1, _password2) == null;

  void _submit(BuildContext context) async {
    if (_formIsValid) {
      setState(() {
        _registrationPending = true;
      });
      final user = User(
        id: randomId(),
        email: _email,
        username: _username,
        password: _password1,
      );
      final result = await Api.instance.user.postSingle(user);
      if (result.isSuccess) {
        setState(() {
          _registrationPending = false;
        });
        Settings.instance.user = user;
        Sync.instance.startSync();
        Nav.changeNamed(context, Routes.timeline.overview);
      } else {
        final snackBar = SnackBar(
          content: Text(result.failure.toErrorMessage()),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        setState(() {
          _registrationPending = false;
        });
      }
      _formKey.currentState!.deactivate();
    }
  }
}
