import 'package:flutter/material.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/heart_rate_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/provider_consumer.dart';
import 'package:sport_log/widgets/snackbar.dart';

class HeartRatePage extends StatelessWidget {
  const HeartRatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child: Scaffold(
        appBar: AppBar(title: const Text("Heart Rate")),
        drawer: const MainDrawer(selectedRoute: Routes.heartRate),
        body: Container(
          padding: Defaults.edgeInsets.normal,
          child: Center(
            child: ProviderConsumer<HeartRateUtils>(
              create: (_) => HeartRateUtils(),
              builder: (_, heartRateUtils, __) => Column(
                children: [
                  ElevatedButton(
                    onPressed: heartRateUtils.isSearching
                        ? null
                        : () async {
                            await heartRateUtils.searchDevices();
                            final context = App.globalContext;
                            if (context.mounted &&
                                heartRateUtils.devices.isEmpty) {
                              showSimpleToast(
                                context,
                                "No devices found.",
                              );
                            }
                          },
                    child: Text(
                      heartRateUtils.isSearching
                          ? "Searching..."
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
                          onChanged: (deviceId) {
                            if (deviceId != null) {
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
                      onPressed: () =>
                          heartRateUtils.startHeartRateStream(null, hrv: true),
                      child: const Text("Connect"),
                    ),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (heartRateUtils.isWaiting)
                          const CircularProgressIndicator(),
                        if (heartRateUtils.hr != null) ...[
                          const Text(
                            "Heart Rate",
                            style: TextStyle(fontSize: 40),
                          ),
                          Text(
                            "${heartRateUtils.hr}",
                            style: const TextStyle(fontSize: 120),
                          ),
                          if (heartRateUtils.hrv != null) ...[
                            Text(
                              "HRV: ${heartRateUtils.hrv} ms",
                              style: const TextStyle(fontSize: 20),
                            ),
                            Defaults.sizedBox.vertical.normal,
                          ],
                          if (heartRateUtils.battery != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(AppIcons.battery),
                                Text(
                                  "${heartRateUtils.battery}%",
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            )
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
