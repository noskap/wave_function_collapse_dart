extension Helper on List<double> {
  int Random(double r) {
    List<double> weights = this;
    double sum = 0;
    for (int i = 0; i < weights.length; i++) {
      sum += weights[i];
    }
    double threshold = r * sum;

    double partialSum = 0;
    for (int i = 0; i < weights.length; i++) {
      partialSum += weights[i];
      if (partialSum >= threshold) return i;
    }
    return 0;
  }
}
