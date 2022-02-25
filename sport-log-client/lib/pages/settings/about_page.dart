import 'package:flutter/material.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/form_widgets/text_tile.dart';
import 'package:url_launcher/url_launcher.dart';

class _Contributor {
  final String name;
  final String github;

  _Contributor(this.name, this.github);

  static List<_Contributor> all = [
    _Contributor(
      "Lorenz Schüler",
      "https://github.com/LorenzSchueler",
    ),
    _Contributor(
      "Oliver Portee",
      "https://github.com/OliverPortee",
    )
  ];
}

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
              leading: AppIcons.github,
              caption: "GitHub",
              child: GestureDetector(
                child: const Icon(AppIcons.openInBrowser),
                onTap: () =>
                    launch("https://github.com/LorenzSchueler/sport-log"),
              ),
            ),
            TextTile(
              leading: AppIcons.copyright,
              caption: "Copyright & License",
              child: GestureDetector(
                child: const Text(
                  "GPLv3 license",
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                  ),
                ),
                onTap: () =>
                    launch("https://www.gnu.org/licenses/gpl-3.0.html"),
              ),
            ),
            TextTile(
                leading: AppIcons.contributors,
                caption: "Contributors",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._Contributor.all.map(
                      (c) => GestureDetector(
                        child: Text(
                          c.name,
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        onTap: () => launch(c.github),
                      ),
                    )
                  ],
                )),
          ],
        ),
      ),
    );
  }
}
