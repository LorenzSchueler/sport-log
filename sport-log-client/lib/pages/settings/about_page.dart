import 'package:flutter/material.dart';
import 'package:sport_log/widgets/custom_icons.dart';
import 'package:sport_log/widgets/form_widgets/text_tile.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("About")),
      body: Container(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            TextTile(
              leading: CustomIcons.github,
              caption: "GitHub",
              child: GestureDetector(
                  child: const Icon(Icons.open_in_browser),
                  onTap: () =>
                      launch("https://github.com/LorenzSchueler/sport-log")),
            ),
            TextTile(
              leading: Icons.copyright_outlined,
              caption: "Copyright & License",
              child: GestureDetector(
                  child: const Text(
                    "GPLv3 license",
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  onTap: () =>
                      launch("https://www.gnu.org/licenses/gpl-3.0.html")),
            ),
          ],
        ),
      ),
    );
  }
}
