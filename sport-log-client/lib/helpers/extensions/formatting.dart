String formatWeight(double weight, [double? secondWeight]) =>
    secondWeight == null ? "$weight kg" : "$weight/$secondWeight kg";
