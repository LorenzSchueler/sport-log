import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/formatting.dart';
import 'package:sport_log/helpers/map_utils.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';
import 'package:sport_log/pages/workout/cardio/cardio_value_unit_description_table.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';

class CardioDetailsPage extends StatefulWidget {
  final CardioSessionDescription cardioSessionDescription;

  const CardioDetailsPage({Key? key, required this.cardioSessionDescription})
      : super(key: key);

  @override
  State<CardioDetailsPage> createState() => CardioDetailsPageState();
}

class CardioDetailsPageState extends State<CardioDetailsPage> {
  late CardioSessionDescription _cardioSessionDescription;

  @override
  void initState() {
    _cardioSessionDescription = widget.cardioSessionDescription;
    super.initState();
  }

  late MapboxMapController _mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: _cardioSessionDescription.movement.name + "  ",
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: describeEnum(
                  _cardioSessionDescription.cardioSession.cardioType,
                ),
                style: const TextStyle(fontSize: 14),
              )
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final returnObj = await Navigator.pushNamed(
                context,
                Routes.cardio.cardioEdit,
                arguments: _cardioSessionDescription,
              );
              if (returnObj is ReturnObject<CardioSessionDescription>) {
                if (returnObj.action == ReturnAction.deleted) {
                  Navigator.pop(context);
                } else {
                  setState(() {
                    _cardioSessionDescription = returnObj.payload;
                  });
                }
              }
            },
            icon: const Icon(AppIcons.edit),
          )
        ],
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cardioSessionDescription.cardioSession.track != null
                  ? Expanded(
                      child: MapboxMap(
                        accessToken: Defaults.mapbox.accessToken,
                        styleString: Defaults.mapbox.style.outdoor,
                        initialCameraPosition: Settings.lastMapPosition,
                        onMapCreated: (MapboxMapController controller) =>
                            _mapController = controller,
                        onStyleLoadedCallback: () {
                          _mapController.setBounds(
                            _cardioSessionDescription.cardioSession.track,
                            _cardioSessionDescription.route?.track,
                          );
                          if (_cardioSessionDescription.cardioSession.track !=
                              null) {
                            _mapController.addTrackLine(
                              _cardioSessionDescription.cardioSession.track!,
                            );
                          }
                          if (_cardioSessionDescription.route?.track != null) {
                            _mapController.addRouteLine(
                              _cardioSessionDescription.route!.track!,
                            );
                          }
                        },
                      ),
                    )
                  : Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(AppIcons.route),
                          Text(" no track available"),
                        ],
                      ),
                    ),
              Container(
                padding: Defaults.edgeInsets.normal,
                color: Theme.of(context).colorScheme.background,
                child: Column(
                  children: [
                    CardioValueUnitDescriptionTable(
                      cardioSessionDescription: _cardioSessionDescription,
                    ),
                    if (_cardioSessionDescription.cardioSession.comments !=
                        null) ...[
                      Defaults.sizedBox.vertical.normal,
                      Text(
                        _cardioSessionDescription.cardioSession.comments!,
                        textAlign: TextAlign.left,
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 5,
            ),
            child: Text(
              _cardioSessionDescription.cardioSession.datetime.formatDatetime,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _cardioSessionDescription.cardioSession.track != null
                    ? Theme.of(context).colorScheme.background
                    : Theme.of(context).colorScheme.onBackground,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
