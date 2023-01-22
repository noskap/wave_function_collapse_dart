import 'dart:core';
import 'dart:math';

import 'package:wave_function_collapse_dart/extension.dart';

enum Heuristic { Entropy, MRV, Scanline }

abstract class Model {
  late List<List<bool>> wave;

  late List<List<List<int>>> propagator;
  late List<List<List<num>>> compatible;
  late List<double> observed;

  late List<Map<int, int>> stack;
  late int stacksize;
  late int observedSoFar;

  late double MX, MY, T, N;
  late bool periodic, ground;

  late List<double> weights;
  late List<double> weightLogWeights, distribution;

  late List<int> sumsOfOnes;
  late double sumOfWeights, sumOfWeightLogWeights, startingEntropy;
  late List<double> sumsOfWeights, sumsOfWeightLogWeights, entropies;

  late Heuristic heuristic;

  Model(this.MX, this.MY, this.N, this.periodic, this.heuristic);

  void Init() {
    wave = [
      [bool.fromEnvironment((MX * MY).toString())]
    ];
    compatible = [
      [
        [wave.length]
      ]
    ];
    for (int i = 0; i < wave.length; i++) {
      wave[i] = [bool.fromEnvironment(T.toString())];
      compatible[i] = [
        [T]
      ];
      for (int t = 0; t < T; t++) {
        compatible[i][t] = [4];
      }
    }
    distribution = [double.parse(T.toString())];
    observed = [MX * MY];

    weightLogWeights = [double.parse(T.toString())];
    sumOfWeights = 0;
    sumOfWeightLogWeights = 0;

    for (int t = 0; t < T; t++) {
      weightLogWeights[t] = weights[t] * log(weights[t]);
      sumOfWeights += weights[t];
      sumOfWeightLogWeights += weightLogWeights[t];
    }

    startingEntropy = log(sumOfWeights) - sumOfWeightLogWeights / sumOfWeights;

    sumsOfOnes = [(MX * MY).toInt()];
    sumsOfWeights = [MX * MY];
    sumsOfWeightLogWeights = [MX * MY];
    entropies = [MX * MY];

    stack = List.generate((wave.length * T).toInt(), (index) => <int, int>{});
    stacksize = 0;
  }

  bool Run(int seed, int limit) {
    if (wave == null) {
      Init();
    }

    Clear();
    Random random = Random(seed);

    for (int l = 0; l < limit || limit < 0; l++) {
      int node = NextUnobservedNode(random);
      if (node >= 0) {
        Observe(node, random);
        bool success = Propagate();
        if (!success) return false;
      } else {
        for (int i = 0; i < wave.length; i++) {
          for (int t = 0; t < T; t++) {
            if (wave[i][t]) {
              observed[i] = t.toDouble();
              break;
            }
          }
          return true;
        }
      }
    }

    return true;
  }

  int NextUnobservedNode(Random random) {
    if (heuristic == Heuristic.Scanline) {
      for (int i = observedSoFar; i < wave.length; i++) {
        if (!periodic && (i % MX + N > MX || i / MX + N > MY)) continue;
        if (sumsOfOnes[i] > 1) {
          observedSoFar = i + 1;
          return i;
        }
      }
      return -1;
    }

    double min = 1E+4;
    int argmin = -1;
    for (int i = 0; i < wave.length; i++) {
      if (!periodic && (i % MX + N > MX || i / MX + N > MY)) continue;
      int remainingValues = sumsOfOnes[i];
      num entropy = heuristic == Heuristic.Entropy ? entropies[i] : remainingValues;
      if (remainingValues > 1 && entropy <= min) {
        double noise = 1E-6 * random.nextDouble();
        if (entropy + noise < min) {
          min = entropy + noise;
          argmin = i;
        }
      }
    }
    return argmin;
  }

  void Observe(int node, Random random) {
    List<bool> w = wave[node];
    for (int t = 0; t < T; t++) {
      distribution[t] = w[t] ? weights[t] : 0.0;
    }
    int r = distribution.Random(random.nextDouble());
    for (int t = 0; t < T; t++) {
      if (w[t] != (t == r)) {
        Ban(node, t);
      }
    }
  }

  bool Propagate() {
    while (stacksize > 0) {
      int i1 = stack.last.keys.first;
      int t1 = stack.last.values.first; // TODO check that values and keys are only 1 in length each
      stacksize--;

      int x1 = (i1 % MX).toInt();
      int y1 = (i1 / MX).toInt();

      for (int d = 0; d < 4; d++) {
        int x2 = x1 + dx[d];
        int y2 = y1 + dy[d];
        if (!periodic && (x2 < 0 || y2 < 0 || x2 + N > MX || y2 + N > MY)) continue;

        if (x2 < 0) {
          x2 += MX.toInt();
        } else if (x2 >= MX) {
          x2 -= MX.toInt();
        }
        if (y2 < 0) {
          y2 += MY.toInt();
        } else if (y2 >= MY) {
          y2 -= MY.toInt();
        }

        int i2 = (x2 + y2 * MX).toInt();
        List<int> p = propagator[d][t1];
        List<List<num>> compat = compatible[i2];

        for (int l = 0; l < p.length; l++) {
          int t2 = p[l];
          List<num> comp = compat[t2];

          comp[d]--;
          if (comp[d] == 0) {
            Ban(i2, t2);
          }
        }
      }
    }

    return sumsOfOnes[0] > 0;
  }

  void Ban(num i, num t) {
    wave[i.toInt()][t.toInt()] = false;

    List<num> comp = compatible[i.toInt()][t.toInt()];
    for (int d = 0; d < 4; d++) {
      comp[d] = 0;
    }
    stack[stacksize] = {i.toInt(): t.toInt()};
    stacksize++;

    sumsOfOnes[i.toInt()] -= 1;
    sumsOfWeights[i.toInt()] -= weights[t.toInt()];
    sumsOfWeightLogWeights[i.toInt()] -= weightLogWeights[t.toInt()];

    double sum = sumsOfWeights[i.toInt()];
    entropies[i.toInt()] = log(sum) - sumsOfWeightLogWeights[i.toInt()] / sum;
  }

  void Clear() {
    for (int i = 0; i < wave.length; i++) {
      for (int t = 0; t < T; t++) {
        wave[i][t] = true;
        for (int d = 0; d < 4; d++) {
          compatible[i][t][d] = propagator[opposite[d]][t].length;
        }
      }

      sumsOfOnes[i] = weights.length;
      sumsOfWeights[i] = sumOfWeights;
      sumsOfWeightLogWeights[i] = sumOfWeightLogWeights;
      entropies[i] = startingEntropy;
      observed[i] = -1;
    }
    observedSoFar = 0;

    if (ground) {
      for (int x = 0; x < MX; x++) {
        for (int t = 0; t < T - 1; t++) {
          Ban(x + (MY - 1) * MX, t);
        }
        for (int y = 0; y < MY - 1; y++) {
          Ban(x + y * MX, T - 1);
        }
      }
      Propagate();
    }
  }

  void Save(String filename);

  static List<int> dx = [-1, 0, 1, 0];
  static List<int> dy = [0, 1, 0, -1];
  static List<int> opposite = [2, 3, 0, 1];
}
