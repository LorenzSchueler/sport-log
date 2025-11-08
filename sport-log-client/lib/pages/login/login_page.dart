import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/account.dart';
import 'package:sport_log/helpers/bool_toggle.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/models/user/user.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';
import 'package:sport_log/widgets/provider_consumer.dart';

enum LoginType {
  login,
  register;

  bool get isLogin => this == LoginType.login;
  bool get isRegister => this == LoginType.register;
}

class LoginPage extends StatefulWidget {
  const LoginPage({required this.loginType, super.key});

  final LoginType loginType;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _serverUrlInputController =
      TextEditingController(text: _serverUrl);

  String _serverUrl = Settings.instance.serverUrl;

  final _user = User(id: randomId(), email: "", username: "", password: "");

  bool _loginPending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.loginType.isRegister ? "Register" : "Login"),
      ),
      body: Padding(
        padding: Defaults.edgeInsets.normal,
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              _serverUrlInput(),
              Defaults.sizedBox.vertical.normal,
              _usernameInput(),
              Defaults.sizedBox.vertical.normal,
              _passwordInput(),
              Defaults.sizedBox.vertical.normal,
              if (widget.loginType.isRegister) ...[
                _passwordInput2(),
                Defaults.sizedBox.vertical.normal,
                _emailInput(),
                Defaults.sizedBox.vertical.normal,
              ],
              _loginPending
                  ? const Align(child: CircularProgressIndicator())
                  : _submitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _serverUrlInput() {
    return TextFormField(
      controller: _serverUrlInputController,
      onChanged: (serverUrl) {
        final validated = Validator.validateUrl(serverUrl);
        if (validated == null) {
          setState(() => _serverUrl = serverUrl);
        }
      },
      decoration: InputDecoration(
        icon: const Icon(AppIcons.cloudUpload),
        labelText: "Server URL",
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _serverUrl = context.read<Settings>().getDefaultServerUrl();
              _serverUrlInputController.text = _serverUrl;
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

  Widget _usernameInput() {
    return TextFormField(
      onChanged: (username) {
        final validated = Validator.validateUsername(username);
        if (validated == null) {
          setState(() => _user.username = username);
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
    );
  }

  Widget _passwordInput() {
    return ProviderConsumer(
      create: (_) => BoolToggle.on(),
      builder: (context, obscure, _) => TextFormField(
        onChanged: (password) {
          final validated = Validator.validatePassword(password);
          if (validated == null) {
            setState(() => _user.password = password);
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
        textInputAction: widget.loginType.isLogin
            ? TextInputAction.done
            : TextInputAction.next,
        obscureText: obscure.isOn,
      ),
    );
  }

  Widget _passwordInput2() {
    return TextFormField(
      decoration: const InputDecoration(
        icon: Icon(AppIcons.key),
        labelText: "Repeat password",
      ),
      validator: (password2) =>
          Validator.validatePassword2(_user.password, password2),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      enabled: !_loginPending,
      style: _loginPending
          ? TextStyle(color: Theme.of(context).disabledColor)
          : null,
      textInputAction: TextInputAction.next,
      obscureText: true,
    );
  }

  Widget _emailInput() {
    return TextFormField(
      onChanged: (email) {
        final validated = Validator.validateEmail(email);
        if (validated == null) {
          setState(() => _user.email = email);
        }
      },
      decoration: const InputDecoration(
        icon: Icon(AppIcons.email),
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

  Widget _submitButton() {
    return FilledButton(
      onPressed:
          (!_loginPending &&
              _formKey.currentContext != null &&
              _formKey.currentState!.validate())
          ? _submit
          : null,
      child: Text(widget.loginType.isRegister ? "Register" : "Login"),
    );
  }

  Future<void> _submit() async {
    setState(() => _loginPending = true);
    final result = widget.loginType.isRegister
        ? await Account.register(_serverUrl, _user)
        : await Account.login(_serverUrl, _user.username, _user.password);
    if (mounted) {
      setState(() => _loginPending = false);
      if (result.isOk) {
        await Navigator.of(context).newBase(Routes.defaultWorkoutTracking);
      } else {
        await showMessageDialog(
          context: context,
          title: "An Error Occurred",
          text: result.err.toString(),
        );
      }
    }
  }
}
