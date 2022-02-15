import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("About")),
        body: Container(
            padding: const EdgeInsets.all(10),
            child: Column(children: [
              RichText(
                  text: TextSpan(children: [
                const TextSpan(
                    text:
                        "This App and the whole Sport-Log project is licensed unter the "),
                TextSpan(
                    text: "GPLv3 license",
                    style:
                        const TextStyle(decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () =>
                          launch("https://www.gnu.org/licenses/gpl-3.0.html")),
                const TextSpan(text: "."),
              ])),
              RichText(
                  text: TextSpan(children: [
                const TextSpan(text: "Contributions are always welcome: "),
                TextSpan(
                    text: "GitHub",
                    style:
                        const TextStyle(decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => launch(
                          "https://github.com/LorenzSchueler/sport-log")),
              ]))
            ])));
  }
}
