
import 'package:flutter/material.dart';
import 'package:sport_log/home/home_page.dart';
import 'package:sport_log/landing/landing_page.dart';

import 'login/login_page.dart';
import 'registration/registrations_page.dart';
import 'routes.dart';

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => AppState();
}

class AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        Routes.landing: (_) => const LandingPage(),
        Routes.login: (_) => const LoginPage(),
        Routes.registration: (_) => const RegistrationPage(),
        Routes.home: (_) => const HomePage(),
      },
      initialRoute: Routes.landing,
      debugShowCheckedModeBanner: false,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.dark,
    );
  }
}