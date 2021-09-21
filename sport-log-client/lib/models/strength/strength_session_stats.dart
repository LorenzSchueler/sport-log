class StrengthSessionStats {
  StrengthSessionStats({
    required this.numSets,
    required this.minCount,
    required this.maxCount,
    required this.sumCount,
    required this.maxEorm,
    required this.sumVolume,
    required this.maxWeight,
  });

  StrengthSessionStats.unsafeDefault()
      : numSets = 0,
        minCount = -1,
        maxCount = -1,
        sumCount = 0,
        maxEorm = null,
        sumVolume = null,
        maxWeight = null;

  int numSets;
  int minCount;
  int maxCount;
  int sumCount;
  double? maxEorm;
  double? sumVolume;
  double? maxWeight;
}
