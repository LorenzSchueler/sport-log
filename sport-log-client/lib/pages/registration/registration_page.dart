import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/sync.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/helpers/id_generation.dart';
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
      validator: _usernameValidator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      enabled: !_registrationPending,
      style: !_registrationPending
          ? null
          : TextStyle(color: Theme.of(context).disabledColor),
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
      validator: _emailValidator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      enabled: !_registrationPending,
      style: !_registrationPending
          ? null
          : TextStyle(color: Theme.of(context).disabledColor),
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
      validator: _password1Validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      enabled: !_registrationPending,
      style: !_registrationPending
          ? null
          : TextStyle(color: Theme.of(context).disabledColor),
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
      validator: _password2Validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      enabled: !_registrationPending,
      style: !_registrationPending
          ? null
          : TextStyle(color: Theme.of(context).disabledColor),
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

  void _submit(BuildContext context) async {
    if (_formIsValid) {
      //context.read<RegistrationBloc>().add(SubmitRegistration(
      //username: _username, email: _email, password: _password1));
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

  String? _usernameValidator(String? username) {
    if (username != null && username.isEmpty) {
      return "Username must not be empty.";
    }
    if (username != null && username.contains(':')) {
      return "Username must not contain ':'.";
    }
  }

  String? _emailValidator(String? email) {
    if (email != null) {
      if (email.isEmpty) {
        return "Email must not be empty.";
      }
      if (!EmailValidator.validate(email)) {
        return "Input is not a valid email.";
      }
    }
  }

  String? _password1Validator(String? password) {
    if (password != null && password.isEmpty) {
      return "Password must not be empty";
    }
  }

  String? _password2Validator(String? password) {
    if (password != null && password != _password1) {
      return "Passwords do not match.";
    }
  }

  bool get _inputsAreValid =>
      _usernameValidator(_username) == null &&
      _emailValidator(_email) == null &&
      _password1Validator(_password1) == null &&
      _password2Validator(_password2) == null;

  static const Widget _padding = Padding(
    padding: EdgeInsets.all(10),
  );
}
