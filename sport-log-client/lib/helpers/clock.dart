/// Source of the current date and time.
///
/// `--dart-define NOW=<ISO 8601 datetime>` fixes the time, so that screenshots
/// do not depend on the date they are taken.
abstract final class Clock {
  // ignore: do_not_use_environment
  static const String _fixedNow = String.fromEnvironment("NOW");
  static final DateTime? _fixed = _fixedNow.isEmpty
      ? null
      : DateTime.parse(_fixedNow);

  static DateTime now() => _fixed ?? DateTime.now();
}
