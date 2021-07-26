
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/routes.dart';

import 'login_bloc.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => LoginFormState();
}

class LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  String _username = "";
  String _password = "";

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: BlocConsumer<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state == LoginState.successful) {
            Navigator.of(context).pushNamedAndRemoveUntil(Routes.home,
                    (route) => false);
          } else if (state == LoginState.failed) {

          }
        },
        builder: (context, LoginState state) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _usernameInput(context, state),
              _padding,
              _passwordInput(context, state),
              _padding,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (state == LoginState.pending)
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

  Widget _usernameInput(BuildContext context, LoginState state) {
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

  Widget _passwordInput(BuildContext context, LoginState state) {
    return TextFormField(
      onChanged: (password) {
        setState(() {
          _password = password;
        });
      },
      decoration: const InputDecoration(
        labelText: "Password",
        border: OutlineInputBorder(
          borderRadius: _borderRadius
        ),
      ),
      validator: _passwordValidator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      enabled: _inputsEnabled(state),
      style: _inputsEnabled(state) ? null : TextStyle(
          color: Theme.of(context).disabledColor
      ),
      textInputAction: TextInputAction.done,
      obscureText: true,
      onFieldSubmitted: (state != LoginState.pending && _inputsAreValid)
          ? (_) => _submit(context) : null,
    );
  }

  Widget _submitButton(BuildContext context, LoginState state) {
    return ElevatedButton(
      child: const Text("Login", style: TextStyle(fontSize: 18),), // TODO: use theme for this
      onPressed: (state != LoginState.pending && _inputsAreValid)
          ? () => _submit(context) : null,
      style: ElevatedButton.styleFrom(
        shape: const RoundedRectangleBorder(
          borderRadius: _borderRadius,
        ),
      ),
    );
  }

  bool _inputsEnabled(LoginState state) {
    return state != LoginState.pending;
  }

  bool get _formIsValid => _formKey.currentState!.validate();

  void _submit(BuildContext context) {
    if (_formIsValid) {
      context.read<LoginBloc>().add(SubmitLogin(
          username: _username,
          password: _password
      ));
      _formKey.currentState!.deactivate();
    }
  }

  String? _usernameValidator(String? username) {
    if (username != null && username.isEmpty) {
      return "Username must not be empty.";
    }
  }

  String? _passwordValidator(String? password) {
    if (password != null && password.isEmpty) {
      return "Password must not be empty";
    }
  }

  bool get _inputsAreValid =>
    _usernameValidator(_username) == null
    && _passwordValidator(_password) == null;

  static const Widget _padding = Padding(
      padding: EdgeInsets.all(10),
  );
  
  static const BorderRadius _borderRadius = BorderRadius.all(Radius.circular(20));
}