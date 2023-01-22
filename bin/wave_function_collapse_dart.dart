import 'dart:io';
import 'dart:math';

import 'package:wave_function_collapse_dart/model.dart';
import 'package:wave_function_collapse_dart/overlapping_model.dart';
import 'package:wave_function_collapse_dart/simple_tiled_model.dart';
import 'package:xml/xml.dart';

void main(List<String> arguments) async {
  print("The time has come to collapse some waves");
  Stopwatch sw = Stopwatch();
  sw.start();
  Directory folder = await Directory("output").create();
  for (var file in folder.listSync()) {
    await file.delete();
  }

  Random random = Random();
  final File file = File('samples.xml');
  final XmlDocument xdoc = XmlDocument.parse(file.readAsStringSync());

  for (XmlElement xelem in xdoc.root.findAllElements("overlapping").followedBy(xdoc.root.findAllElements("simpletiled"))) {
    Model model;
    String name = xelem.getAttribute("name") ?? '';
    print("< $name");

    bool isOverlapping = xelem.name.qualified == "overlapping";
    int size = int.parse((xelem.getAttribute("size") ?? (isOverlapping ? 48 : 24)).toString());
    int width = int.parse(xelem.getAttribute("width") ?? size.toString());
    int height = int.parse(xelem.getAttribute("height") ?? size.toString());
    bool periodic = bool.fromEnvironment(xelem.getAttribute("periodic") ?? '', defaultValue: false);
    String heuristicString = xelem.getAttribute("heuristic") ?? '';
    Heuristic heuristic = heuristicString == "Scanline" ? Heuristic.Scanline : (heuristicString == "MRV" ? Heuristic.MRV : Heuristic.Entropy);
    if (isOverlapping) // TODO
    {
      int N = int.parse(xelem.getAttribute("N") ?? 3.toString());
      bool periodicInput = bool.fromEnvironment(xelem.getAttribute("periodicInput") ?? '', defaultValue: true);
      int symmetry = int.parse(xelem.getAttribute("symmetry") ?? 8.toString());
      bool ground = bool.fromEnvironment(xelem.getAttribute("ground") ?? '', defaultValue: false);

      model = OverlappingModel(name, N, width, height, periodicInput, periodic, symmetry, ground, heuristic);
      // }
      // else
      // {
      // String subset = xelem.getAttribute<String>("subset");
      // bool blackBackground = xelem.getAttribute("blackBackground", false);

      // model = new SimpleTiledModel(name, subset, width, height, periodic, blackBackground, heuristic);
      // }
      for (int i = 0; i < (int.parse((xelem.getAttribute("screenshots") ?? 2).toString())); i++) {
        for (int k = 0; k < 10; k++) {
          print("> ");
          int seed = random.nextDouble().toInt();
          bool success = await model.Run(seed, int.parse((xelem.getAttribute("limit") ?? -1).toString()));
          print('success? $success');
          if (success) {
            print("DONE");
            model.Save("output/$name $seed.png");
            if (model is SimpleTiledModel && bool.fromEnvironment(xelem.getAttribute("textOutput") ?? false.toString())) {
              // System.IO.File.WriteAllText($"output/{name} {seed}.txt", model.TextOutput());
              print('writing file: output/$name $seed.txt');
              File file = File('output/$name $seed.txt');
              file.writeAsStringSync(model.TextOutput());
            }
            break;
          } else {
            print("CONTRADICTION");
          }
        }
      }
    }
  }

  print("time = ${sw.elapsedMilliseconds}");
}
