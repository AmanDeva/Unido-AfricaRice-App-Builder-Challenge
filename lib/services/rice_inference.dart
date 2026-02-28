import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class RiceInferenceResult {
  final List<double> counts;
  final List<double> measures;
  RiceInferenceResult(this.counts, this.measures);
}

// -------------------------------------------------------------------
// 🚀 BACKGROUND ISOLATE: Blazing Fast Image Math
// Must be a top-level function to run on a separate CPU thread
// -------------------------------------------------------------------
Future<Float32List> _buildImageBuffer(String imagePath) async {
  print(">>> [ISOLATE] 1. Decoding Image...");
  var bytes = File(imagePath).readAsBytesSync();
  var rawImage = img.decodeImage(bytes)!;

  // 🚨 FIX: Free up memory immediately to prevent RAM crashes
  bytes = Uint8List(0);

  print(">>> [ISOLATE] 2. Resizing Image...");
  final resizedImage = img.copyResize(rawImage, width: 2048, height: 1536);

  // 🚨 FIX: Free up the raw 12MP image memory before math starts!
  rawImage = img.Image(width: 1, height: 1);

  print(">>> [ISOLATE] 3. Writing to Flat Memory Buffer...");
  int H = 512;
  int W = 512;
  int T = 12;

  var inputBuffer = Float32List(3 * H * W * T);
  int tileIdx = 0;

  for (int row = 0; row < 3; row++) {
    for (int col = 0; col < 4; col++) {
      int startX = col * 512;
      int startY = row * 512;

      for (int y = 0; y < 512; y++) {
        for (int x = 0; x < 512; x++) {
          img.Pixel pixel = resizedImage.getPixel(startX + x, startY + y);

          double r = ((pixel.r / 255.0) - 0.485) / 0.229;
          double g = ((pixel.g / 255.0) - 0.456) / 0.224;
          double b = ((pixel.b / 255.0) - 0.406) / 0.225;

          int baseIndex = y * (W * T) + x * T + tileIdx;
          inputBuffer[0 * (H * W * T) + baseIndex] = r;
          inputBuffer[1 * (H * W * T) + baseIndex] = g;
          inputBuffer[2 * (H * W * T) + baseIndex] = b;
        }
      }
      tileIdx++;
    }
  }
  print(">>> [ISOLATE] 4. Buffer Complete!");
  return inputBuffer;
}

class RiceClassifier {
  Interpreter? _interpreter;

  final List<double> _meanMeas = [
    7.64838123,
    2.56411529,
    3.06469274,
    64.19993591,
    2.80723953,
    15.47008801
  ];
  final List<double> _stdMeas = [
    1.22484839,
    0.37814495,
    0.3465732,
    6.3935771,
    5.45056963,
    14.53563499
  ];

  Future<void> loadModel() async {
    try {
      // 🚀 OPTIMIZATION: Target only the 2 high-performance Cortex-A75 cores
      var interpreterOptions = InterpreterOptions()..threads = 2;

      // 🚨 Ensure your asset name matches the newly quantized file!
      // If you are still using the older one, change this back to 'rice_quality_model_fixed.tflite'
      _interpreter = await Interpreter.fromAsset(
        'assets/rice_quality_model.tflite',
        options: interpreterOptions,
      );
      print('✅ Model Loaded Successfully with 2 CPU Threads (High-Speed Mode)');
    } catch (e) {
      print('❌ Failed to load model: $e');
    }
  }

  Future<RiceInferenceResult> predict(File imageFile, int riceTypeIndex) async {
    if (_interpreter == null) await loadModel();

    // 🛡️ DYNAMIC TENSOR ROUTING
    var inputTensors = _interpreter!.getInputTensors();
    var outputTensors = _interpreter!.getOutputTensors();

    int imageInputIdx =
        inputTensors[0].shape.reduce((a, b) => a * b) > 100 ? 0 : 1;
    int metaInputIdx = imageInputIdx == 0 ? 1 : 0;

    int countsOutputIdx = outputTensors[0].shape.last == 9 ? 0 : 1;
    int measuresOutputIdx = countsOutputIdx == 0 ? 1 : 0;

    // 🚀 OFF-LOAD HEAVY MATH TO BACKGROUND CORE
    print(">>> 1. Handing image to background thread...");
    final stopwatch = Stopwatch()..start();

    Float32List input0 = await compute(_buildImageBuffer, imageFile.path);

    print(
        ">>> 2. Background preprocessing took: ${stopwatch.elapsedMilliseconds} ms");

    // 🌾 METADATA FIX: Properly Maps Paddy(0), Brown(1), White(2)
    var inputMeta = [
      [0.0, 0.0, 0.0]
    ];
    // This dynamically turns on the correct index based on the dropdown!
    inputMeta[0][riceTypeIndex] = 1.0;

    var outputCounts = [List<double>.filled(9, 0.0)];
    var outputMeasures = [List<double>.filled(6, 0.0)];

    List<Object> inputs = [];
    if (imageInputIdx == 0) {
      inputs = [input0.buffer, inputMeta];
    } else {
      inputs = [inputMeta, input0.buffer];
    }

    Map<int, Object> outputs = {
      countsOutputIdx: outputCounts,
      measuresOutputIdx: outputMeasures,
    };

    print(">>> 3. Running AI Inference on 2 Fast Cores...");
    stopwatch.reset();
    try {
      _interpreter!.runForMultipleInputs(inputs, outputs);
    } catch (e) {
      print("❌ INFERENCE CRASHED: $e");
      rethrow;
    }
    print(">>> 4. Inference took: ${stopwatch.elapsedMilliseconds} ms");
    stopwatch.stop();

    List<double> finalCounts = [];
    for (int i = 0; i < 9; i++) {
      double rawCount = outputCounts[0][i] / 100.0;
      finalCounts.add(rawCount < 0 ? 0 : rawCount.roundToDouble());
    }

    List<double> finalMeasures = [];
    for (int i = 0; i < 6; i++) {
      double rawMeas = outputMeasures[0][i];
      double actualMeas = rawMeas * (_stdMeas[i] + 1e-8) + _meanMeas[i];
      finalMeasures.add(actualMeas);
    }

    return RiceInferenceResult(finalCounts, finalMeasures);
  }
}
