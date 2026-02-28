import '../services/rice_inference.dart';

class GradingHelper {
  static Map<String, dynamic> generateReport(
      RiceInferenceResult result, int riceType) {
    double total = result.counts[0];
    double broken = result.counts[1];

    double black = result.counts[4];
    double chalky = riceType == 1 ? result.counts[5] : 0;
    double red = result.counts[6];
    double yellow = result.counts[7];
    double green = result.counts[8];

    double lwRatio = result.measures[2];

    double brokenPct = (total > 0) ? (broken / total) * 100 : 0;
    String grade;
    if (brokenPct < 5)
      grade = "Premium";
    else if (brokenPct <= 10)
      grade = "Grade 1";
    else if (brokenPct <= 15)
      grade = "Grade 2";
    else if (brokenPct <= 20)
      grade = "Grade 3";
    else
      grade = "Below Standard";

    String shape;
    if (lwRatio < 2.1)
      shape = "Bold";
    else if (lwRatio <= 2.9)
      shape = "Medium";
    else
      shape = "Slender";

    List<String> flags = [];
    if (total > 0) {
      if ((chalky / total) * 100 > 20) flags.add("High Chalkiness");
      if ((black / total) * 100 > 10) flags.add("Damaged/Defective");
      if ((green / total) * 100 > 10) flags.add("Immature Grains");
      if ((yellow / total) * 100 > 10) flags.add("Fermented");
      if ((red / total) * 100 > 10) flags.add("Red Strips");
    }

    return {
      "grade": grade,
      "shape": shape,
      "broken_pct": brokenPct.toStringAsFixed(1),
      "flags": flags,
      "total_grains": total.toInt(),
      "broken_grains": broken.toInt(),
      "dimensions": {
        "length": result.measures[0].toStringAsFixed(2),
        "width": result.measures[1].toStringAsFixed(2),
        "ratio": lwRatio.toStringAsFixed(2),
      }
    };
  }
}
