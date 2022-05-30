import 'package:flutter/material.dart';
import 'package:result_type/result_type.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/account.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/models/user/user.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/theme.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';

enum LoginType {
  login,
  register,
  noAccount;

  bool get isLogin => this == LoginType.login;
  bool get isRegister => this == LoginType.register;
  bool get isNoAccount => this == LoginType.noAccount;
}

class LoginPage extends StatefulWidget {
  const LoginPage({required this.loginType, Key? key}) : super(key: key);

  final LoginType loginType;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  String _serverUrl = Settings.serverUrl;
  String _username = "";
  String _password = "";
  // ignore: unused_field
  String _password2 = "";
  String _email = "";

  User get user => User(
        id: randomId(),
        email: _email,
        username: _username,
        password: _password,
      );

  bool _loginPending = false;

  late TextEditingController _serverUrlInputController;

  @override
  void initState() {
    super.initState();
    _serverUrlInputController = TextEditingController(text: _serverUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.loginType.isRegister ? "Register" : "Login"),
      ),
      body: Container(
        padding: Defaults.edgeInsets.normal,
        child: Center(
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                if (!widget.loginType.isNoAccount) ...[
                  _serverUrlInput(context),
                  Defaults.sizedBox.vertical.normal,
                ],
                _usernameInput(context),
                Defaults.sizedBox.vertical.normal,
                _passwordInput(context),
                Defaults.sizedBox.vertical.normal,
                if (!widget.loginType.isLogin) ...[
                  _passwordInput2(context),
                  Defaults.sizedBox.vertical.normal,
                  _emailInput(context),
                  Defaults.sizedBox.vertical.normal,
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _loginPending
                        ? const CircularProgressIndicator()
                        : _submitButton(context),
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
      decoration: Theme.of(context).textFormFieldDecoration.copyWith(
            icon: const Icon(AppIcons.cloudUpload),
            labelText: "Server URL",
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
      enabled: !_loginPending,
      style: _loginPending
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
    );
  }

  Widget _passwordInput(BuildContext context) {
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
      textInputAction: widget.loginType.isLogin
          ? TextInputAction.done
          : TextInputAction.next,
      obscureText: true,
    );
  }

  Widget _passwordInput2(BuildContext context) {
    return TextFormField(
      onChanged: (password2) async {
        final validated = Validator.validatePassword2(_password, password2);
        if (validated == null) {
          setState(() => _password2 = password2);
        }
      },
      decoration: Theme.of(context).textFormFieldDecoration.copyWith(
            icon: const Icon(AppIcons.key),
            labelText: "Repeat password",
          ),
      validator: (password2) =>
          Validator.validatePassword2(_password, password2),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      enabled: !_loginPending,
      style: _loginPending
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
      decoration: Theme.of(context).textFormFieldDecoration.copyWith(
            icon: const Icon(AppIcons.email),
            labelText: "Email",
          ),
      validator: Validator.validateEmail,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      enabled: !_loginPending,
      style: _loginPending
          ? TextStyle(color: Theme.of(context).disabledColor)
          : null,
      textInputAction: TextInputAction.done,
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _submitButton(BuildContext context) {
    return ElevatedButton(
      onPressed: (!_loginPending &&
              _formKey.currentContext != null &&
              _formKey.currentState!.validate())
          ? () => _submit(context)
          : null,
      child: Text(widget.loginType.isRegister ? "Register" : "Login"),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (widget.loginType.isNoAccount) {
      Account.noAccount(user);
      await Navigator.of(context).newBase(Routes.timeline.overview);
      return;
    }
    setState(() {
      _loginPending = true;
    });
    Settings.serverUrl = _serverUrl;
    final Result<User, ApiError> result;
    result = widget.loginType.isRegister
        ? await Account.register(user)
        : await Account.login(_username, _password);
    if (mounted) {
      setState(() {
        _loginPending = false;
      });
    }
    if (result.isSuccess) {
      if (mounted) {
        await Navigator.of(context).newBase(Routes.timeline.overview);
      }
    } else {
      await showMessageDialog(
        context: context,
        text: result.failure.toString(),
      );
    }
    _formKey.currentState!.deactivate();
  }
}
