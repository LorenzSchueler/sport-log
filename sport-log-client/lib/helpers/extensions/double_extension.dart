extension RoundExtension on double {
  /// (0.123).toStringMaxFixed(3) == "0.123"
  /// (0.120).toStringMaxFixed(3) == "0.12"
  /// (0.100).toStringMaxFixed(3) == "0.1"
  /// (0.000).toStringMaxFixed(3) == "0"
  String toStringMaxFixed(int maxFractionDigits) {
    var string = toStringAsFixed(maxFractionDigits);
    while (string.contains(".") && string.endsWith("0") ||
        string.endsWith(".")) {
      string = string.substring(0, string.length - 1);
    }
    return string;
  }
}
