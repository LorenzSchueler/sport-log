
import 'package:flutter/material.dart';
import 'package:sport_log/authentication/protected_route.dart';
import 'package:sport_log/helpers/material_color_generator.dart';
import 'package:sport_log/pages/home/home_page.dart';
import 'package:sport_log/pages/landing/landing_page.dart';
import 'package:sport_log/pages/login/login_page.dart';
import 'package:sport_log/pages/registration/registrations_page.dart';
import 'routes.dart';

class App extends StatefulWidget {
  const App({
    Key? key,
    required this.isAuthenticatedAtStart,
  }) : super(key: key);
  final bool isAuthenticatedAtStart;

  @override
  State<StatefulWidget> createState() => AppState();
}

class AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    final primarySwatch = generateMaterialColor(const Color(0xff55d2db));
    return MaterialApp(
      routes: {
        Routes.landing: (_) => const LandingPage(),
        Routes.login: (_) => const LoginPage(),
        Routes.registration: (_) => const RegistrationPage(),
        Routes.home: (_) => ProtectedRoute(builder: (_) => const HomePage()),
      },
      initialRoute: widget.isAuthenticatedAtStart ? Routes.home : Routes.landing,
      debugShowCheckedModeBanner: false,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: primarySwatch,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.dark,
    );
  }
}