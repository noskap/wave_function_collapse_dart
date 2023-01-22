import 'extension.dart';
import 'model.dart';

class OverlappingModel extends Model {
  late List<List<int>> patterns;
  late List<int> colors;

  OverlappingModel(String name, int N, int width, int height, bool periodicInput, bool periodic, int symmetry, bool ground, Heuristic heuristic)
      : super(width.toDouble(), height.toDouble(), N.toDouble(), periodic, heuristic) {
    // var (bitmap, SX, SY) = BitmapHelper.LoadBitmap($"samples/{name}.png");
    List li = BitmapHelper.LoadBitmap("samples/${name}.png");
    List<int> bitmap = li[0];
    int SX = li[1];
    int SY = li[2];
    List<int> sample = [bitmap.length];
    colors = [];
    for (int i = 0; i < sample.length; i++) {
      int color = bitmap[i];
      int k = 0;
      for (; k < colors.length; k++) {
        if (colors[k] == color) break;
      }
      if (k == colors.length) {
        colors.add(color);
      }
      sample[i] = k;
    }

// static List< int> pattern(Function<int, int, int> f, int N)
    List<int> pattern(dynamic f, int N) {
      List<int> result = [N * N];
      for (int y = 0; y < N; y++) {
        for (int x = 0; x < N; x++) {
          result[x + y * N] = f(x, y);
        }
      }
      return result;
    }

    ;
    List<int> rotate(List<int> p, int N) => pattern((x, y) => p[(N - 1 - y + x * N).toInt()], N);
    List<int> reflect(List<int> p, int N) => pattern((x, y) => p[(N - 1 - x + y * N).toInt()], N);

    int hash(List<int> p, int C) {
      int result = 0, power = 1;
      for (int i = 0; i < p.length; i++) {
        result += p[p.length - 1 - i] * power;
        power *= C;
      }
      return result;
    }

    patterns = [];
    Map<int, int> patternIndices = {};
    List<double> weightList = [];

    int C = colors.length;
    int xmax = periodicInput ? SX : SX - N + 1;
    int ymax = periodicInput ? SY : SY - N + 1;
    for (int y = 0; y < ymax; y++) {
      for (int x = 0; x < xmax; x++) {
        List<List<int>> ps = [
          [8]
        ];

        ps[0] = pattern((dx, dy) => sample[((x + dx) % SX + (y + dy) % SY * SX).toInt()], N);
        ps[1] = reflect(ps[0], N);
        ps[2] = rotate(ps[0], N);
        ps[3] = reflect(ps[2], N);
        ps[4] = rotate(ps[2], N);
        ps[5] = reflect(ps[4], N);
        ps[6] = rotate(ps[4], N);
        ps[7] = reflect(ps[6], N);

        for (int k = 0; k < symmetry; k++) {
          List<int> p = ps[k];
          int h = hash(p, C);
          if (patternIndices[h] != null) {
            int index = patternIndices[h] ?? 0;
            weightList[index] = weightList[index] + 1;
          } else {
            patternIndices[h] = weightList.length;
            weightList.add(1.0);
            patterns.add(p);
          }
        }
      }
    }

    weights = weightList.toList();
    T = weights.length.toDouble();
    this.ground = ground;

    bool agrees(List<int> p1, List<int> p2, int dx, int dy, int N) {
      int xmin = dx < 0 ? 0 : dx, xmax = dx < 0 ? dx + N : N, ymin = dy < 0 ? 0 : dy, ymax = dy < 0 ? dy + N : N;
      for (int y = ymin; y < ymax; y++) {
        for (int x = xmin; x < xmax; x++) {
          if (p1[x + N * y] != p2[x - dx + N * (y - dy)]) return false;
        }
      }
      return true;
    }

    ;

    propagator = [
      [
        [4]
      ]
    ];
    for (int d = 0; d < 4; d++) {
      propagator[d] = [
        [T.toInt()]
      ];
      for (int t = 0; t < T; t++) {
        List<int> list = [];
        for (int t2 = 0; t2 < T; t2++) {
          if (agrees(patterns[t], patterns[t2], Model.dx[d], Model.dy[d], N)) list.add(t2);
        }
        propagator[d][t] = [list.length];
        for (int c = 0; c < list.length; c++) {
          propagator[d][t][c] = list[c];
        }
      }
    }
  }

  void Save(String filename) {
    List<int> bitmap = [(MX * MY).toInt()];
    if (observed[0] >= 0) {
      for (int y = 0; y < MY; y++) {
        num dy = y < MY - N + 1 ? 0 : N - 1;
        for (int x = 0; x < MX; x++) {
          num dx = x < MX - N + 1 ? 0 : N - 1;
          bitmap[(x + y * MX).toInt()] = colors[patterns[observed[(x - dx + (y - dy) * MX).toInt()].toInt()][(dx + dy * N).toInt()]];
        }
      }
    } else {
      for (int i = 0; i < wave.length; i++) {
        int contributors = 0, r = 0, g = 0, b = 0;
        int x = (i % MX).toInt(), y = (i / MX).toInt();
        for (int dy = 0; dy < N; dy++) {
          for (int dx = 0; dx < N; dx++) {
            int sx = x - dx;
            if (sx < 0) sx += MX.toInt();

            int sy = y - dy;
            if (sy < 0) sy += MY.toInt();

            int s = (sx + sy * MX).toInt();
            if (!periodic && (sx + N > MX || sy + N > MY || sx < 0 || sy < 0)) continue;
            for (int t = 0; t < T; t++) {
              if (wave[s][t]) {
                contributors++;
                int argb = colors[patterns[t][(dx + dy * N).toInt()]];
                r += (argb & 0xff0000) >> 16;
                g += (argb & 0xff00) >> 8;
                b += argb & 0xff;
              }
            }
          }
        }
        // bitmap[i] = unchecked((int)0xff000000 | ((r / contributors) << 16) | ((g / contributors) << 8) | b / contributors);
        bitmap[i] = 0xff000000 | ((r ~/ contributors) << 16) | ((g ~/ contributors) << 8) | (b ~/ contributors);
      }
    }
    BitmapHelper.SaveBitmap(bitmap, MX.toInt(), MY.toInt(), filename);
  }
}
