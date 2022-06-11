import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/heart_rate_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/snackbar.dart';

class HeartRatePage extends StatelessWidget {
  const HeartRatePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child: Scaffold(
        appBar: AppBar(title: const Text("Heart Rate")),
        drawer: const MainDrawer(selectedRoute: Routes.heartRate),
        body: Container(
          padding: Defaults.edgeInsets.normal,
          child: Center(
            child: ChangeNotifierProvider<HeartRateUtils>(
              create: (_) => HeartRateUtils(),
              child: Consumer<HeartRateUtils>(
                builder: (_, heartRateUtils, __) => Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: Column(
                        children: [
                          ElevatedButton(
                            onPressed: heartRateUtils.isSearching
                                ? null
                                : () async {
                                    heartRateUtils.stopHeartRateStream();
                                    await heartRateUtils.searchDevices();
                                    if (heartRateUtils.devices.isEmpty) {
                                      // ignore: use_build_context_synchronously
                                      showSimpleToast(
                                        App.globalContext,
                                        "No devices found.",
                                      );
                                    }
                                  },
                            child: Text(
                              heartRateUtils.isSearching
                                  ? "Seaching..."
                                  : "Search Devices",
                            ),
                          ),
                          if (!heartRateUtils.isSearching &&
                              !heartRateUtils.isActive &&
                              heartRateUtils.devices.isNotEmpty) ...[
                            Defaults.sizedBox.vertical.normal,
                            const Text("Heart Rate Monitors"),
                            SizedBox(
                              height: 24,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton(
                                  value: heartRateUtils.deviceId,
                                  items: heartRateUtils.devices.entries
                                      .map(
                                        (d) => DropdownMenuItem(
                                          value: d.value,
                                          child: Text(d.key),
                                        ),
                                      )
                                      .toList(),
                                  underline: null,
                                  onChanged: (deviceId) {
                                    if (deviceId != null &&
                                        deviceId is String) {
                                      heartRateUtils.deviceId = deviceId;
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                          if (!heartRateUtils.isActive &&
                              heartRateUtils.canStartStream) ...[
                            Defaults.sizedBox.vertical.normal,
                            ElevatedButton(
                              onPressed: heartRateUtils.startHeartRateStream,
                              child: const Text("Connect"),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Text(
                      "Heart Rate",
                      style: TextStyle(fontSize: 40),
                    ),
                    Text(
                      heartRateUtils.hr != null ? "${heartRateUtils.hr}" : "--",
                      style: const TextStyle(fontSize: 120),
                    ),
                    if (heartRateUtils.battery != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(AppIcons.battery),
                          Text(
                            "${heartRateUtils.battery}%",
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                        ],
                      )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
