import 'package:flutter/material.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
import 'package:url_launcher/url_launcher_string.dart';

class _Contributor {
  _Contributor(this.name, this.github);

  final String name;
  final String github;

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
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("About")),
      body: Container(
        padding: Defaults.edgeInsets.normal,
        child: Column(
          children: [
            EditTile(
              leading: AppIcons.radio,
              caption: "Version",
              child: Text(
                Config.debugMode
                    ? "${Config.instance.version} [${Config.gitRef}] (debug build)"
                    : "${Config.instance.version} [${Config.gitRef}]",
              ),
            ),
            EditTile(
              leading: AppIcons.radio,
              caption: "Api Version",
              child: Text("${Config.apiVersion}"),
            ),
            EditTile(
              leading: AppIcons.github,
              caption: "GitHub",
              child: GestureDetector(
                child: Icon(
                  AppIcons.openInBrowser,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
                onTap: () => launchUrlString(
                  "https://github.com/LorenzSchueler/sport-log",
                ),
              ),
            ),
            EditTile(
              leading: AppIcons.copyright,
              caption: "Copyright & License",
              child: GestureDetector(
                child: const Text(
                  "GPLv3 license",
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                  ),
                ),
                onTap: () => launchUrlString(
                  "https://www.gnu.org/licenses/gpl-3.0.html",
                ),
              ),
            ),
            EditTile(
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
                      onTap: () => launchUrlString(c.github),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
