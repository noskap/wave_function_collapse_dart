import 'model.dart';

class SimpleTiledModel extends Model {
  SimpleTiledModel(super.MX, super.MY, super.N, super.periodic, super.heuristic);

  @override
  void Save(String filename) {
    // TODO: implement Save
  }

  String TextOutput() {
    // var result = new System.Text.StringBuilder();
    // for (int y = 0; y < MY; y++)
    // {
    //   for (int x = 0; x < MX; x++) result.Append($"{tilenames[observed[x + y * MX]]}, ");
    //   result.Append(Environment.NewLine);
    // }
    // return result.ToString();
    return 'TODO';
  }
}