import 'dart:async';

import 'package:sport_log/helpers/pointer.dart';

/// Executes [callback] at most as frequent as specified by [timeout].
///
/// Each call of [callback] will be done with the most recently set argument.
class RateLimiter<A> {
  RateLimiter(this.callback, this.timeout);

  final void Function(A) callback;
  Pointer<A>? _argument; // pointer needed because A can be itself nullable
  final Duration timeout;
  Timer? _timer;

  void execute(A argument) {
    if (_timer == null) {
      _timer = Timer(timeout, onTimeout);
      callback(argument);
    } else {
      _argument = Pointer(argument);
    }
  }

  void onTimeout() {
    if (_argument != null) {
      _timer = Timer(timeout, onTimeout);
      final argument = _argument!.object;
      _argument = null;
      callback(argument);
    } else {
      _timer = null;
    }
  }
}
