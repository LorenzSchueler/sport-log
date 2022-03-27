import 'package:flutter_blue/flutter_blue.dart';
import 'package:polar/polar.dart';

class HeartRateUtils {
  static final _polar = Polar();
  static final FlutterBlue _flutterBlue = FlutterBlue.instance;

  final String _deviceId;

  HeartRateUtils(this._deviceId);

  static Future<HeartRateUtils?> searchDevice() async {
    await for (final r
        in _flutterBlue.scan(timeout: const Duration(seconds: 10))) {
      if (r.device.name.contains("Polar H10")) {
        return HeartRateUtils(r.device.id.toString());
      }
    }
    return null;
  }

  void startHeartRateStream(
    void Function(PolarHeartRateEvent event) listener,
  ) {
    _polar.heartRateStream.listen(listener);
    _polar.connectToDevice(_deviceId);
  }

  void stopHeartRateStream() {
    _polar.disconnectFromDevice(_deviceId);
  }
}
