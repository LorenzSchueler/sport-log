
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/routes.dart';

import 'registration_bloc.dart';

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RegistrationFormState();
}

class RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  String _username = "";
  String _email = "";
  String _password1 = "";
  String _password2 = "";

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: BlocConsumer<RegistrationBloc, RegistrationState>(
        listener: (context, state) {
          if (state == RegistrationState.successful) {
            Navigator.of(context).pushNamedAndRemoveUntil(Routes.home,
                    (route) => false);
          } else if (state == RegistrationState.failed) {
            const snackBar = SnackBar(
                content: Text("Username already registered. Use login instead."),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        },
        builder: (context, RegistrationState state) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _usernameInput(context, state),
              _padding,
              _emailInput(context, state),
              _padding,
              _passwordInput1(context, state),
              _padding,
              _passwordInput2(context, state),
              _padding,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (state == RegistrationState.pending)
                    Container(
                      child: const CircularProgressIndicator(),
                      margin: const EdgeInsets.only(right: 20),
                    ),
                  _submitButton(context, state),
                ],
              )
            ],
          );
        }
      ),
    );
  }

  Widget _usernameInput(BuildContext context, RegistrationState state) {
    return TextFormField(
      onChanged: (username) {
        setState(() {
          _username = username;
        });
      },
      decoration: const InputDecoration(
        labelText: "Username",
        border: OutlineInputBorder(
            borderRadius: _borderRadius
        ),
      ),
      validator: _usernameValidator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      enabled: _inputsEnabled(state),
      style: _inputsEnabled(state) ? null : TextStyle(
        color: Theme.of(context).disabledColor
      ),
      textInputAction: TextInputAction.next,
    );
  }

  Widget _emailInput(BuildContext context, RegistrationState state) {
    return TextFormField(
      onChanged: (email) {
        setState(() {
          _email = email;
        });
      },
      decoration: const InputDecoration(
        labelText: "Email",
        border: OutlineInputBorder(
            borderRadius: _borderRadius
        ),
      ),
      validator: _emailValidator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      enabled: _inputsEnabled(state),
      style: _inputsEnabled(state) ? null : TextStyle(
          color: Theme.of(context).disabledColor
      ),
      textInputAction: TextInputAction.next,
    );
  }

  Widget _passwordInput1(BuildContext context, RegistrationState state) {
    return TextFormField(
      onChanged: (password) {
        setState(() {
          _password1 = password;
        });
      },
      decoration: const InputDecoration(
        labelText: "Password",
        border: OutlineInputBorder(
          borderRadius: _borderRadius
        ),
      ),
      validator: _password1Validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      enabled: _inputsEnabled(state),
      style: _inputsEnabled(state) ? null : TextStyle(
          color: Theme.of(context).disabledColor
      ),
      textInputAction: TextInputAction.next,
      obscureText: true,
    );
  }

  Widget _passwordInput2(BuildContext context, RegistrationState state) {
    return TextFormField(
      onChanged: (password) {
        setState(() {
          _password2 = password;
        });
      },
      decoration: const InputDecoration(
        labelText: "Repeat password",
        border: OutlineInputBorder(
            borderRadius: _borderRadius
        ),
      ),
      validator: _password2Validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      enabled: _inputsEnabled(state),
      style: _inputsEnabled(state) ? null : TextStyle(
          color: Theme.of(context).disabledColor
      ),
      textInputAction: TextInputAction.done,
      obscureText: true,
      onFieldSubmitted: (state != RegistrationState.pending && _inputsAreValid)
          ? (_) => _submit(context) : null,
    );
  }

  Widget _submitButton(BuildContext context, RegistrationState state) {
    return ElevatedButton(
      child: const Text("Register", style: TextStyle(fontSize: 18),), // TODO: use theme for this
      onPressed: (state != RegistrationState.pending && _inputsAreValid)
          ? () => _submit(context) : null,
      style: ElevatedButton.styleFrom(
        shape: const RoundedRectangleBorder(
          borderRadius: _borderRadius,
        ),
      ),
    );
  }

  bool _inputsEnabled(RegistrationState state) {
    return state != RegistrationState.pending;
  }

  bool get _formIsValid => _formKey.currentState!.validate();

  void _submit(BuildContext context) {
    if (_formIsValid) {
      context.read<RegistrationBloc>().add(SubmitRegistration(
          username: _username,
          email: _email,
          password: _password1
      ));
      _formKey.currentState!.deactivate();
    }
  }

  String? _usernameValidator(String? username) {
    if (username != null && username.isEmpty) {
      return "Username must not be empty.";
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
    _usernameValidator(_username) == null
    && _emailValidator(_email) == null
    && _password1Validator(_password1) == null
    && _password2Validator(_password2) == null;

  static const Widget _padding = Padding(
      padding: EdgeInsets.all(10),
  );
  
  static const BorderRadius _borderRadius = BorderRadius.all(Radius.circular(20));
}