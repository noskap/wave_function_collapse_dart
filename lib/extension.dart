import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

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

class BitmapHelper {
  static List LoadBitmap(String filename) {
    final File file = File('samples.xml');
    Uint8List values = file.readAsBytesSync();
    img.Image? photo = img.decodeImage(values);
    int width = photo?.width ?? 0;
    int height = photo?.height ?? 0;
    int result = width * height;
// photo.CopyPixelDataTo(MemoryMarshal.Cast<int, Bgra32>(result));
    return [result, width, height];
  }

  static void SaveBitmap(List<int> data, int width, int height, String filename) {
    // using var image = Image.WrapMemory<Bgra32>(pData, width, height);
    // image.SaveAsPng(filename);
    var file = File(filename);
    file.writeAsBytesSync(data);
  }
}
