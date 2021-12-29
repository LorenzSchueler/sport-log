import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/state/page_return.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/routes.dart';

class MetconSessionDetailsPage extends StatefulWidget {
  final MetconSessionDescription metconSessionDescription;

  const MetconSessionDetailsPage(
      {Key? key, required this.metconSessionDescription})
      : super(key: key);

  @override
  State<MetconSessionDetailsPage> createState() =>
      MetconSessionDetailsPageState();
}

class MetconSessionDetailsPageState extends State<MetconSessionDetailsPage> {
  final _logger = Logger('MetconSessionDetailsPage');

  @override
  Widget build(BuildContext context) {
    MetconSessionDescription metconSessionDescription =
        widget.metconSessionDescription;

    TableRow rowSpacer = TableRow(children: [
      Defaults.sizedBox.vertical.normal,
      Defaults.sizedBox.vertical.normal,
    ]);

    return Scaffold(
        appBar: AppBar(
          title: Text(metconSessionDescription.name),
          actions: [
            IconButton(
                onPressed: () => Navigator.of(context)
                        .pushNamed(Routes.metcon.sessionEdit,
                            arguments: metconSessionDescription)
                        .then((returnObj) {
                      if (returnObj is ReturnObject<MetconSessionDescription>) {
                        setState(() {
                          metconSessionDescription = returnObj.payload;
                        });
                      }
                    }),
                icon: const Icon(Icons.edit))
          ],
        ),
        body: Text("not implemented"));
  }
}
