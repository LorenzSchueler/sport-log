import 'package:flutter/material.dart';
import 'package:polar/polar.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/heart_rate_utils.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/main_drawer.dart';

class HeartRatePage extends StatefulWidget {
  const HeartRatePage({Key? key}) : super(key: key);

  @override
  State<HeartRatePage> createState() => _HeartRatePageState();
}

class _HeartRatePageState extends State<HeartRatePage> {
  bool _isSearchingHRMonitor = false;
  Map<String, String>? _devices;
  String? _heartRateMonitorId;
  HeartRateUtils? _heartRateUtils;
  int? _hr;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Heart Rate")),
      drawer: const MainDrawer(selectedRoute: Routes.heartRate),
      body: Container(
        padding: Defaults.edgeInsets.normal,
        child: Center(
          child: Column(
            children: [
              ElevatedButton(
                onPressed: _isSearchingHRMonitor
                    ? null
                    : () async {
                        setState(() => _isSearchingHRMonitor = true);
                        final devices = await HeartRateUtils.searchDevices();
                        setState(() {
                          _devices = devices;
                          _isSearchingHRMonitor = false;
                        });
                      },
                child: Text(
                  _isSearchingHRMonitor ? "seaching..." : "search devices",
                ),
              ),
              Defaults.sizedBox.vertical.normal,
              if (_devices != null) ...[
                const Text(
                  "Heart Rate Monitors",
                ),
                SizedBox(
                  height: 24,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton(
                      value: _heartRateMonitorId,
                      items: _devices!.entries
                          .map(
                            (d) => DropdownMenuItem(
                              value: d.value,
                              child: Text(d.key),
                            ),
                          )
                          .toList(),
                      underline: null,
                      onChanged: (deviceId) {
                        if (deviceId != null && deviceId is String) {
                          setState(() => _heartRateMonitorId = deviceId);
                        }
                      },
                    ),
                  ),
                ),
              ],
              Defaults.sizedBox.vertical.normal,
              if (_heartRateMonitorId != null)
                ElevatedButton(
                  onPressed: () async {
                    _heartRateUtils = HeartRateUtils(
                        _heartRateMonitorId!, _onHeartRateUpdate);
                    _heartRateUtils?.startHeartRateStream();
                  },
                  child: const Text("select"),
                ),
              Defaults.sizedBox.vertical.huge,
              if (_hr != null) ...[
                const Text(
                  "Heart Rate",
                  style: const TextStyle(fontSize: 40),
                ),
                Text(
                  "$_hr",
                  style: const TextStyle(fontSize: 120),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  void _onHeartRateUpdate(PolarHeartRateEvent event) {
    setState(() => _hr = event.data.hr);
  }
}
