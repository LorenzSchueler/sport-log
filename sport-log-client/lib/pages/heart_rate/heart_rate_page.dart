import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/heart_rate_utils.dart';
import 'package:sport_log/helpers/snackbar.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
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
  int? _battery;

  @override
  void dispose() {
    _heartRateUtils?.stopHeartRateStream();
    super.dispose();
  }

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
                        _heartRateUtils?.stopHeartRateStream();
                        setState(() {
                          _heartRateUtils = null;
                          _heartRateMonitorId = null;
                          _hr = null;
                          _battery = null;
                          _devices = null;
                          _isSearchingHRMonitor = true;
                        });
                        final devices = await HeartRateUtils.searchDevices();
                        setState(() {
                          _devices = devices;
                          _isSearchingHRMonitor = false;
                        });
                        if (devices == null || devices.isEmpty) {
                          showSimpleToast(context, "no devices found");
                        }
                      },
                child: Text(
                  _isSearchingHRMonitor ? "seaching..." : "search devices",
                ),
              ),
              Defaults.sizedBox.vertical.normal,
              if (_devices != null && _heartRateUtils == null) ...[
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
              if (_heartRateMonitorId != null && _heartRateUtils == null)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _heartRateUtils = HeartRateUtils(
                        deviceId: _heartRateMonitorId!,
                        onHeartRateEvent: (event) =>
                            setState(() => _hr = event.data.hr),
                        onBatteryEvent: (event) =>
                            setState(() => _battery = event.level),
                      );
                    });
                    _heartRateUtils?.startHeartRateStream();
                  },
                  child: const Text("connect"),
                ),
              Defaults.sizedBox.vertical.huge,
              if (_hr != null) ...[
                const Text(
                  "Heart Rate",
                  style: TextStyle(fontSize: 40),
                ),
                Text(
                  "$_hr",
                  style: const TextStyle(fontSize: 120),
                ),
              ],
              if (_battery != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(AppIcons.battery),
                    Text(
                      "$_battery%",
                      style: const TextStyle(fontSize: 24),
                    ),
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }
}
