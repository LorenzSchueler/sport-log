String formatWeight(double weight, [double? secondWeight]) =>
    secondWeight == null
        ? "${weight.toStringAsFixed(2)} kg"
        : "${weight.toStringAsFixed(2)}/${secondWeight.toStringAsFixed(2)} kg";
